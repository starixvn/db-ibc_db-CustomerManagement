/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,wsv_nap,wsv_lap" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE	dbo.Acc_VR_AgentUpdFirstBetDate   
	 @CustIDList VARCHAR(max)
	,@Type TINYINT
	,@BetDate	DATE
AS  
/*  
	Created:	20200827@Eden:	
	Task:		Update FirstBetDate of VRAgentAutoAdjustment table
	DB:			DBCUST/CustDB
	Original:	
  
	Revisions:  
	    - 20200827@Eden: First commit [#140421]
		- 20220105@Eden: unused SP [Redmine:#166626]

	Param's Explanation:  
		@Type = 
			1: All VR sport exxclude BasketBall and Esport
	Examples:
		EXEC Acc_VR_AgentUpdFirstBetDate @CustIDList = '1,2'
		,@Type = 1
		,@BetDate = '2020/08/05'
*/  
BEGIN  
	/*
	SET NOCOUNT ON  
	DECLARE @startRun datetime  
	DECLARE @endRun datetime  
	DECLARE @duration int 
	SET @startRun = getdate()

	DECLARE @CustTbl TABLE ( CustID INT)
	INSERT INTO @CustTbl(CustID)
	SELECT DISTINCT p.val
	FROM dbo.f_StringSplit(@CustIDList,',') p
	OPTION (MAXRECURSION 0)
	  
	UPDATE v
	SET v.FirstBetDate = @BetDate,
		v.Status = CASE WHEN v.status = 0 THEN 1 ELSE v.Status END
	FROM VRAgentAutoAdjustment v WITH(ROWLOCK)
		INNER JOIN @CustTbl t ON v.AgentID = t.CustID
	WHERE v.Type = @Type
		AND v.FirstBetDate IS NULL

	set @endRun = getdate()  
	set @duration  = datediff (millisecond,@startRun,@endRun) 
	DECLARE @NewLogData VARCHAR(MAX)
	SELECT @NewLogData = '<R '
						+ 'CustIDList="'+ coalesce(cast(@CustIDList as varchar(MAX)),space(1)) + '" '
						+ 'Type="'+ coalesce(cast(@Type as varchar(50)),space(1)) + '" ' 
						+ 'BetDate="' + coalesce(cast(@BetDate as varchar(50)),space(1)) + '" '
						+ ' />'

	EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
		@UserId				= 0,
		@ActionId			= 818,
		@TrackingValue		= @NewLogData,
		@Duration			= @Duration
	*/
	RETURN
END
GO
