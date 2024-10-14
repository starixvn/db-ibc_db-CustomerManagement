/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap,wsv_lap" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE	dbo.Acc_VR_CustomerUpdFirstBetDate   
	@CustIDList VARCHAR(max)
	,@Sporttype INT
	,@BetDate	DATE
	,@IsTest BIT = 0
AS  
/*  
	Created:	
	Task:		Update FirstBetDate of VRCustAutoAdjustment table
	DB:			DBCUST/CustDB
	Original:	
  
	Revisions:  
	    - 20200805@Eden: First commit [#138168]
		- 20220105@Eden: Enhance to write more logs for Virtual Rate jobs [Redmine:#166626]
		- 20220614@Eden: DBCUST - modify sp syntax to adapt with the SQL Server upgrade to 2019 [Redmine: #171831] 
		- 20240701@Winfred: Scale Out DBCUST - Apply In-house Replication for Virtual Rate Setting  [redmine: #207029]

	Param's Explanation:  
	Examples:
		EXEC Acc_VR_CustomerUpdFirstBetDate
		 @CustIDList = '1,2'
		,@Sporttype = 2
		,@BetDate = '2020/08/05'
		,@IsTest = 1
*/  
BEGIN  
	SET NOCOUNT ON  
	DECLARE @startRun datetime  
	DECLARE @endRun datetime  
	DECLARE @duration int 
	SET @startRun = getdate()

	DECLARE @CustTbl TABLE ( CustID INT)
	INSERT INTO @CustTbl(CustID)
	SELECT p.value
	FROM STRING_SPLIT(@CustIDList,',') p
	WHERE value <> ''

	IF @IsTest = 1 -- UUS only 
	BEGIN
		DELETE t
		FROM @CustTbl t
			INNER JOIN custInfo ci WITH(NOLOCK) ON t.CustID = ci.custid
		WHERE ci.currency <> 20
	END
	  
	UPDATE v
	SET v.FirstBetDate = @BetDate
		,v.RepUpdateTime = [dbo].[f_GetDateTime2]()
	FROM VRCustAutoAdjustment v WITH(ROWLOCK)
		INNER JOIN @CustTbl t ON v.CustID = t.CustID
	WHERE v.SportType = @Sporttype
		AND v.FirstBetDate IS NULL

	set @endRun = getdate()  
	set @duration  = datediff (millisecond,@startRun,@endRun) 
	DECLARE @NewLogData VARCHAR(MAX)
	SELECT @NewLogData = '<R '
						+ 'CustIDList="'+ coalesce(cast(@CustIDList as varchar(MAX)),space(1)) + '" '
						+ 'Sporttype="'+ coalesce(cast(@Sporttype as varchar(50)),space(1)) + '" ' 
						+ 'BetDate="' + coalesce(cast(@BetDate as varchar(50)),space(1)) + '" '
						+ ' />'

	EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
		@UserId				= 0,
		@ActionId			= 814,
		@TrackingValue		= @NewLogData,
		@Duration			= @Duration

END
GO
