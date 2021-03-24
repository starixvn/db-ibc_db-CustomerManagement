/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Acc_VR_MemberBigStake_FirstBetDate_Upd   
	 @CustIDList VARCHAR(max)
	,@Type TINYINT
	,@BetDate	DATE
AS  
/*  
	Created:	20210219@Eden:	
	Task:		Update FirstBetDate of customers after existed in VRMemberBigStake table , Update Status = 1 for members with credit < RMCredit Config
	DB:			DBCUST/CustDB
	Original:	
  
	Revisions:  
	    - 20210219@Eden: First commit [#150298]
		- 20210301@Eden: Check if member soccer hdp vr >= site value then remove the member from VRMemberBigStake table [#152095]
		- 20210323@Eden: Enhancement for VR Member Big Stake [#150298]

	Param's Explanation:  
		@Type = 
			1: All VR sport exxclude BasketBall and Esport
	Examples:
		EXEC Acc_VR_MemberBigStake_FirstBetDate_Upd @CustIDList = '1,4935,5029'
		,@Type = 1
		,@BetDate = '2021/02/19'
*/  
BEGIN  
	SET NOCOUNT ON  
	DECLARE @startRun datetime  
	DECLARE @endRun datetime  
	DECLARE @duration int 
	DECLARE @DeletedCount INT
	DECLARE @UpdatedCount INT
	SET @startRun = getdate()

	DECLARE @InputCustTbl TABLE (CustID INT)
	DECLARE @UpdatedCustTbl TABLE (CustID INT)
	DECLARE @DeletedCustTbl TABLE (CustID INT)

	INSERT INTO @InputCustTbl(CustID)
	SELECT DISTINCT p.val
	FROM dbo.f_StringSplit(@CustIDList,',') p
	OPTION (MAXRECURSION 0)

	--- Check if member soccer hdp vr >= site value then remove the member from VRMemberBigStake table
	DELETE t 
	OUTPUT deleted.CustID INTO @DeletedCustTbl(CustID)
	FROM @InputCustTbl t
		INNER JOIN customer c WITH(NOLOCK) ON c.custid = t.custid
		INNER JOIN VRMemberBigStake v (NOLOCK) ON c.custid = v.CustID
		INNER JOIN dbo.f_GetVRBigStakeConfig(NULL) p ON p.site = c.site
		INNER JOIN CustVirtualSetting cvs WITH(NOLOCK) ON cvs.custid = t.custid
		INNER JOIN  ProfileVirtualSetting pvs WITH(NOLOCK) ON  cvs.seqNo = pvs.seqNo
	WHERE pvs.isActive = 1
		AND pvs.sporttype = 1 AND pvs.bettype = 1 AND pvs.islive = 1
		AND dbo.f_GetVirtualSetting(cvs.bitmapVirtual, pvs.profileID) >= p.VRValue
		AND v.Status <> 1

	DELETE v
	FROM VRMemberBigStake v WITH(ROWLOCK)
		INNER JOIN @DeletedCustTbl t ON v.CustID = t.CustID
	WHERE v.Type = @Type
		AND v.FirstBetDate IS NULL

	SET @DeletedCount = @@ROWCOUNT
	  
	UPDATE v
	SET v.FirstBetDate = @BetDate
	OUTPUT deleted.CustID INTO @UpdatedCustTbl(CustID)
	FROM VRMemberBigStake v WITH(ROWLOCK)
		INNER JOIN @InputCustTbl t ON v.CustID = t.CustID
	WHERE v.Type = @Type
		AND v.FirstBetDate IS NULL

	SET @UpdatedCount = @@ROWCOUNT

	IF @UpdatedCount > 0
	BEGIN
		--Update Status = 1 for members with credit < RMCredit Config
		DECLARE @UpdateWL_CustIDList VARCHAR(MAX) = ''
		SELECT @UpdateWL_CustIDList = @UpdateWL_CustIDList + ',' + CONVERT(varchar,c.custid) 
		FROM Customer c WITH(NOLOCK)
			INNER JOIN custinfo ci WITH(NOLOCK) ON c.custid = ci.custid
			INNER JOIN @UpdatedCustTbl t ON c.CustID = t.CustID
			INNER JOIN dbo.f_GetVRBigStakeConfig(NULL) p ON p.site = c.site
			INNER JOIN exchange e WITH(NOLOCK) On ci.currency = e.ExchangeId
			INNER JOIN VRMemberBigStake v WITH(NOLOCK) ON v.custid = c.custid AND v.Type = p.Type
		WHERE ci.credit <= p.credit / (CASE WHEN ci.currency <> 20 THEN  e.actualrate ELSE 1 END)
			AND v.FirstBetDate IS NOT NULL
		
		SELECT @UpdateWL_CustIDList = ISNULL(STUFF(@UpdateWL_CustIDList,1,1,''),'')

		IF @UpdateWL_CustIDList <> ''
			EXEC Acc_VR_MemberBigStake_WhiteList_Upd 
				@CustIDList = @UpdateWL_CustIDList,
				@Type = @Type,
				@UpdateType = 1
	END

	IF @UpdatedCount + @DeletedCount = 0
		RETURN -- nothing to log

	DECLARE @UpdatedCustTbl_NotWL TABLE (CustID INT, Islog BIT DEFAULT 0)

	DECLARE @LogData VARCHAR(MAX)
	DECLARE @custID INT
	--Log Update VR for each customer

	INSERT INTO @UpdatedCustTbl_NotWL(CustID)
	SELECT t.CustID
	FROM @UpdatedCustTbl t
	WHERE t.CustID NOT IN (SELECT p.val FROM dbo.f_StringSplit(@UpdateWL_CustIDList,',') p )
	OPTION (MAXRECURSION 0)
	
	BEGIN
		WHILE 1 = 1
		BEGIN
			UPDATE TOP(1)  c
			SET c.islog = 1,
				@custID = c.CustID
			FROM @UpdatedCustTbl_NotWL c
			WHERE Islog = 0

			IF @@ROWCOUNT = 0 BREAK;

			SELECT @LogData = '<R '
								+ 'Type="'
										+ CASE	WHEN @Type = 1 THEN 'Sportsbook except Basketball and Esports' 
												ELSE space(1) 
											END+ '" '
								--+ 'BetDate="' + ISNULL(CONVERT(VARCHAR(10),@BetDate),'') +  '" '
								+ ' />'
	
			EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
				@UserId				= 0,
				@custID				= @custID,
				@ActionId			= 831,
				@TrackingValue		= @LogData
		END
	END

	set @endRun = getdate()  
	set @duration  = datediff (millisecond,@startRun,@endRun) 

	DECLARE @NewLogData VARCHAR(MAX)
	
	SELECT @NewLogData = CONVERT( VARCHAR(MAX), 
			(	SELECT *
				FROM
					(SELECT  CustID AS '@CustID',
							@Type AS '@Type', 
							@BetDate AS '@BetDate',
							'Updated' AS '@Action'
					FROM @UpdatedCustTbl
					UNION ALL
					SELECT  CustID AS '@CustID',
							@Type AS '@Type', 
							@BetDate AS '@BetDate',
							'Removed' AS '@Action'
					FROM @DeletedCustTbl
					) t
				FOR XML PATH('Row'), ROOT ('R'), TYPE)
			)

	EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
		@UserId				= 0,
		@ActionId			= 826,
		@TrackingValue		= @NewLogData,
		@Duration			= @Duration

END
GO
