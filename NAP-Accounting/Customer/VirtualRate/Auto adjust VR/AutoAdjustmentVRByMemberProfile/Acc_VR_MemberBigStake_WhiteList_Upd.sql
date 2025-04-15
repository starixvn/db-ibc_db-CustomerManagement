/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Acc_VR_MemberBigStake_WhiteList_Upd 
	 @CustIDList VARCHAR(max)
	,@Type TINYINT
	,@UpdateType TINYINT = 0 
	,@UserID INT = 0
	,@IsTest BIT = 0
AS  
/*  
	Created:	20210219@Eden:	
	Task:		Update Status = 1 (white list) of customers in VRMemberBigStake table 
	DB:			DBCUST/CustDB
	Original:	
  
	Revisions:  
	    - 20210219@Eden: First commit [#150298]
		- 20210301@Eden: Check if member soccer hdp vr >= site value then remove the member from VRMemberBigStake table [#150298]
		- 20210323@Eden: Enhancement for VR Member Big Stake [Redmine:#149372]
		- 20220105@Eden: Enhance to write more logs for Virtual Rate jobs [Redmine:#166626]
		- 20250121@Winfred: [NAP CM] Scale Out DBCUST - Apply Inhouse replication for Customer Class[Redmine: #214119]
		
	Param's Explanation:  
		@Type = 
			1: All VR sport exclude BasketBall and Esport

		@UpdateType =
			0: Update status = 1 when check performance
			1: Update when check Credit <= config credit
			2: Manual
			3: High VR

	Examples:
		EXEC Acc_VR_MemberBigStake_WhiteList_Upd 
			@CustIDList  = '<Root>
								<Row CustID="1" WL="1000" Credit="1000" SoccerHDPVR="1.00" />	
							</Root>'
			,@Type = 1

	
*/  
BEGIN  
	SET NOCOUNT ON  
	DECLARE @startRun datetime  
	DECLARE @endRun datetime  
	DECLARE @duration int 
	SET @startRun = getdate()

	DECLARE @CustTbl TABLE ( 
		CustID		INT PRIMARY KEY,
		WL			DECIMAL (19, 4),
		Credit		MONEY,
		SoccerHDPVR SMALLMONEY
	)
	DECLARE @Whitelist_TBL TABLE (
		CustID INT PRIMARY KEY,
		WL			DECIMAL (19, 4),
		Credit		MONEY,
		SoccerHDPVR SMALLMONEY,
		IsLog		BIT Default 0
	)

	DECLARE @DocHandler INT	

	--Parse input XML
	IF @CustIDList <> ''
	BEGIN				
		EXEC sp_xml_preparedocument @DocHandler OUTPUT, @CustIDList

		INSERT INTO @CustTbl(CustID,WL,Credit,SoccerHDPVR)
		SELECT DISTINCT Data.CustID,
			Data.WL,
			Data.Credit,
			Data.SoccerHDPVR
		FROM OPENXML (@DocHandler, '/Root/Row',1) 
		WITH (
			CustID		INT,
			WL			DECIMAL (19, 4),
			Credit		MONEY,
			SoccerHDPVR SMALLMONEY
		) AS Data

		EXEC sp_xml_removedocument @DocHandler
	END	

	IF @IsTest = 1 -- UUS only 
	BEGIN
		DELETE t
		FROM @CustTbl t
			INNER JOIN custInfo ci WITH(NOLOCK) ON t.CustID = ci.custid
		WHERE ci.currency <> 20
	END

	--> Update Status = 1
	UPDATE v
	SET v.Status = 1,
		v.RepUpdateTime = [dbo].[f_GetDateTime2]() 
	OUTPUT deleted.CustID INTO @Whitelist_TBL(CustID)
	FROM VRMemberBigStake v WITH(ROWLOCK)
		INNER JOIN @CustTbl t ON v.CustID = t.CustID
	WHERE v.Type = @Type
		AND v.Status <> 1
		AND (v.FirstBetDate IS NOT NULL 
				OR @UpdateType IN (2,3) --White list  by Manual or HighVR no need Bet ticket 
			)
	
	IF @UpdateType IN (2,3) --White list  by Manual or HighVR no need Bet ticket
	BEGIN
		INSERT INTO VRMemberBigStake (CustID,Type,Status, RepUpdateTime)
		OUTPUT inserted.CustID INTO @Whitelist_TBL(CustID)
		SELECT t.CustID, @Type, 1, [dbo].[f_GetDateTime2]() 
		FROM @CustTbl t 
			INNER JOIN Customer c WITH(NOLOCK) ON t.CustID = c.custid
			INNER JOIN dbo.f_GetVRBigStakeConfig(NULL) p ON p.site = c.site
			LEFT JOIN VRMemberBigStake v WITH(NOLOCK) ON v.CustID = t.CustID AND v.Type = p.Type
		WHERE v.CustID IS NULL
			AND c.creatdate >= p.ReleasedDate
			AND p.type = @type
	END

	IF NOT EXISTS( SELECT 1 FROM @Whitelist_TBL)
		RETURN 

	UPDATE t
	SET t.WL = m.WL,
		t.SoccerHDPVR = m.SoccerHDPVR,
		t.Credit = m.Credit
	FROM @Whitelist_TBL t
		INNER JOIN @CustTbl m ON t.CustID = m.CustID

	DECLARE @NewLogData VARCHAR(MAX)
	DECLARE @custID		INT,
			@WL			DECIMAL (19, 4),
			@Credit		MONEY,
			@SoccerHDPVR SMALLMONEY

	--Log Update VR for each customer
	BEGIN
		WHILE 1 = 1
		BEGIN
			UPDATE TOP(1)  c
			SET c.islog = 1,
				@custID = c.CustID,
				@WL = c.WL,
				@Credit = c.Credit,
				@SoccerHDPVR = c.SoccerHDPVR
			FROM @Whitelist_TBL c
			WHERE Islog = 0

			IF @@ROWCOUNT = 0 BREAK;

			SELECT @NewLogData = '<R '
								+ 'Type="'
										+ CASE	WHEN @Type = 1 THEN 'Sportsbook except Basketball and Esports' 
												ELSE space(1) 
											END+ '" '
								+ 'Reason="'
										+ CASE	WHEN @UpdateType = 1 THEN 'Credit' 
												WHEN @UpdateType = 2 THEN 'Manual'
												WHEN @UpdateType = 3 THEN 'High VR'
												ELSE 'Winloss'
											END+ '" '
								+ CASE	WHEN @UpdateType = 1 THEN 'Credit="' + coalesce(cast(@Credit as varchar(50)),space(1)) + '" '
												WHEN @UpdateType = 3 THEN 'SoccerHdpVirtualMultiplier="' + coalesce(cast(@SoccerHDPVR as varchar(50)),space(1)) + '" '
												WHEN @UpdateType = 0 THEN 'WinLoss="' + coalesce(cast(@WL as varchar(50)),space(1)) + '" '
												ELSE ''
											END
								+ ' />'
	
			EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
				@UserId				= @UserId,
				@custID				= @custID,
				@ActionId			= 828,
				@TrackingValue		= @NewLogData
		END
	END

	set @endRun = getdate()  
	set @duration  = datediff (millisecond,@startRun,@endRun) 

	SELECT @NewLogData = CONVERT( VARCHAR(MAX), 
			(	SELECT  CustID AS '@CustID',
						@Type AS '@Type', 
						CASE WHEN @UpdateType  = 1 THEN 'WhiteListByCredit' 
							WHEN @UpdateType  = 2 THEN 'WhiteListByManual'
							WHEN @UpdateType  = 3 THEN 'WhiteListByHighVR'
							ELSE 'WhiteListByWinLoss' 
						END AS '@Action',
						CASE WHEN @UpdateType  = 1 THEN Credit
							WHEN @UpdateType  = 0 THEN WL
							WHEN @UpdateType  = 3 THEN SoccerHDPVR
						END AS '@Value'
				FROM @Whitelist_TBL
				FOR XML PATH('Row'), ROOT ('R'), TYPE)
			)

	EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
		@UserId				= @UserId,
		@ActionId			= 827,
		@TrackingValue		= @NewLogData,
		@Duration			= @Duration

END
GO
