/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap,wsv_lap" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE	dbo.Acc_VR_AgentAutoAdjustment_Ins
	@IsTest BIT = 0 
AS  
/*  
	Created:	20200827@Eden:	
	Task:		Insert new agent to VRAgentAutoAdjustment table
	DB:			DBCUST/CustDB
	Original:	
  
	Revisions:  
	    - 20200827@Eden: First commit [#140421]
		- 20220105@Eden: Enhance to write more logs for Virtual Rate jobs [Redmine:#166626]
		- 20240701@Winfred: Scale Out DBCUST - Apply In-house Replication for Virtual Rate Setting  [redmine: #207029]
		- 202401021@Winfred: Fix While Loop  [redmine: #212439]

	Param's Explanation:  
	Examples:
		EXEC Acc_VR_AgentAutoAdjustment_Ins
*/  
BEGIN  
	SET NOCOUNT ON  
	DECLARE @startRun datetime  
	DECLARE @endRun datetime  
	DECLARE @duration int 
	SET @startRun = getdate()

	DECLARE @Inserted_Agent TABLE (AgentID INT, Type TINYINT,Islog BIT DEFAULT 0)
	DECLARE @tblCust TABLE (CustID INT, Type TINYINT, IsFinished BIT DEFAULT (0))
	DECLARE @tblCust_tmp TABLE (CustID INT, Type TINYINT)
	
	INSERT INTO @tblCust(CustID,Type)
	SELECT c.custid, p.Type
	FROM Customer c WITH(NOLOCK)
		INNER JOIN Site s WITH(NOLOCK) ON c.site = s.site
		INNER JOIN VRAgentProfile p WITH(NOLOCK) ON p.siteID = s.Siteid
	WHERE c.roleid = 2 
		AND c.creatdate BETWEEN DATEADD(hh,-25,GETDATE()) AND GETDATE()
		AND NOT EXISTS( SELECT 1 FROM VRAgentAutoAdjustment v WITH(NOLOCK) WHERE v.AgentID = c.custid AND v.Type = p.Type)
		AND c.creatdate >= p.ReleaseDate
		AND c.currency = CASE WHEN @IsTest = 1 THEN 20 ELSE c.currency END

	WHILE (1 = 1)
	BEGIN
		UPDATE TOP (2000) c
		SET isFinished = 1
		OUTPUT DELETED.CustID, DELETED.Type
		INTO @tblCust_tmp(CustID,Type)
		FROM @tblCust c	
		WHERE isFinished = 0
			
		IF @@ROWCOUNT = 0 BREAK 

		INSERT INTO VRAgentAutoAdjustment(AgentID,Type,Status,RepUpdateTime)
		OUTPUT inserted.AgentID,inserted.Type INTO @Inserted_Agent(AgentID,Type)
		SELECT c.custid, c.Type, 0, [dbo].[f_GetDateTime2]() AS RepUpdateTime
		FROM @tblCust_tmp c 
		WHERE NOT EXISTS( SELECT 1 FROM VRAgentAutoAdjustment v WITH(NOLOCK) WHERE v.AgentID = c.custid AND v.Type = c.Type)

	END
	
	IF NOT EXISTS( SELECT 1 FROM @Inserted_Agent)
		RETURN

	DECLARE @AgentID INT, @Type TINYINT
	DECLARE @NewLogData VARCHAR(MAX)

	SET @endRun = getdate()  
	SET @duration  = datediff (millisecond,@startRun,@endRun) 
	
	SELECT @NewLogData = CONVERT( VARCHAR(MAX), 
			(	SELECT AgentID AS '@AgentID',
						Type AS '@Type' 
				FROM @Inserted_Agent
				FOR XML PATH('Row'), ROOT ('R'), TYPE)
		)

	EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
			@UserId				= 0,
			@ActionId			= 820,
			@TrackingValue		= @NewLogData,
			@Duration			= @Duration
END
GO
