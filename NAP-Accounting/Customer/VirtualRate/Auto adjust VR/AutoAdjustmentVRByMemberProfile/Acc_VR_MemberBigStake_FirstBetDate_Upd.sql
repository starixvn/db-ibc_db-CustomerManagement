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
	SET @startRun = getdate()

	DECLARE @InputCustTbl TABLE (CustID INT)
	DECLARE @UpdatedCustTbl TABLE (CustID INT)

	INSERT INTO @InputCustTbl(CustID)
	SELECT DISTINCT p.val
	FROM dbo.f_StringSplit(@CustIDList,',') p
	OPTION (MAXRECURSION 0)
	  
	UPDATE v
	SET v.FirstBetDate = @BetDate
	OUTPUT deleted.CustID INTO @UpdatedCustTbl(CustID)
	FROM VRMemberBigStake v WITH(ROWLOCK)
		INNER JOIN @InputCustTbl t ON v.CustID = t.CustID
	WHERE v.Type = @Type
		AND v.FirstBetDate IS NULL

	IF @@ROWCOUNT = 0
		RETURN

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

	EXEC Acc_VR_MemberBigStake_WhiteList_Upd 
		@CustIDList = @UpdateWL_CustIDList,
		@Type = @Type,
		@IsUpdateByCredit = 1

	set @endRun = getdate()  
	set @duration  = datediff (millisecond,@startRun,@endRun) 

	DECLARE @NewLogData VARCHAR(MAX)
	
	SELECT @NewLogData = CONVERT( VARCHAR(MAX), 
			(	SELECT  CustID AS '@CustID',
						@Type AS '@Type', 
						@BetDate AS '@BetDate'
				FROM @UpdatedCustTbl
				FOR XML PATH('Row'), ROOT ('R'), TYPE)
		)

	EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
		@UserId				= 0,
		@ActionId			= 826,
		@TrackingValue		= @NewLogData,
		@Duration			= @Duration

END
GO
