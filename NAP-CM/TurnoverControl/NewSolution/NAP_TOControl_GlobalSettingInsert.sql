/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
USE CustDB
GO 

ALTER PROCEDURE [dbo].[NAP_TOControl_GlobalSettingInsert]
	@UserName NVARCHAR(30),
	@MaxTurnover MONEY,
	@UserID INT,
	@IP	VARCHAR(40),
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(200) = '' OUTPUT
AS

/*
	Created: Don
	Date: 2017-03-24
	Task: Insert new CustId to Gobal setting
	DB: DBCUST.CustDB

	Revisions:

	Parameter's explaination:
*/
BEGIN 
	SET NOCOUNT ON

	DECLARE @startRun	DATETIME,
			@endRun		DATETIME,
			@duration	INT
	DECLARE @roleid INT
	SET	@startRun = GETDATE()

	--Check permission 
	EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[GlobalSetting]',@ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
	IF @ErrCode <> 0
		RETURN

	DECLARE @CustID INT
	SELECT @CustID = CustID, @roleid = RoleID FROM dbo.CustInfo WITH(NOLOCK) WHERE UserName = @UserName

	IF @CustID IS NULL OR @roleid = 1
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'Invalid Super/Master/Agent.'
		RETURN
	END

	IF EXISTS (SELECT 1 FROM dbo.TOControl_GlobalSetting WITH(NOLOCK) WHERE CustID = @CustID)
	BEGIN
			SELECT @ErrCode = 102, @ErrMsg = 'The setting of this customer already existed!'
			RETURN
	END

	CREATE TABLE #tmpTurnover(MatchId INT, SumOfStake MONEY, HouseTurnover MONEY)
	INSERT INTO #tmpTurnover(MatchId, SumOfStake, HouseTurnover)
		EXECUTE DBAGE.bodb02.dbo.NAP_TOControl_MatchTurnoverByCustomerSelect @CustID = @CustID, @RoleID = @roleid
		
	INSERT INTO dbo.TOControl_Setting(CustID, matchid, MaxTurnOver, TotalTurnOver, HouseTurnover, PercentLevel, IsNotified)
		SELECT
			@CustID, t.MatchId, @MaxTurnover AS MaxTurnOver, t.SumOfStake AS TotalTurnOver, t.HouseTurnover, 
			CASE
				WHEN PercentUsed < 10 THEN 0
				WHEN PercentUsed < 20 THEN 1
				WHEN PercentUsed < 30 THEN 2
				WHEN PercentUsed < 40 THEN 3
				WHEN PercentUsed < 50 THEN 4
				WHEN PercentUsed < 60 THEN 5
				WHEN PercentUsed < 70 THEN 6
				WHEN PercentUsed < 80 THEN 7
				WHEN PercentUsed < 90 THEN 8
				WHEN PercentUsed < 100 THEN 9
				ELSE 10
			END AS PercentLevel, 
			0 AS IsNotified
		FROM #tmpTurnover t
			CROSS APPLY (SELECT CASE WHEN @MaxTurnover = 0 THEN 0 ELSE (HouseTurnover*100)/@MaxTurnover END) _(PercentUsed)

	IF @@ERROR > 0 
	BEGIN
		SELECT @ErrCode = 103, @ErrMsg = 'Adding failed.'
		RETURN;
		
	END
	
	INSERT INTO dbo.TOControl_GlobalSetting(CustID, MaxTurnOver) 
		VALUES(@CustID, @MaxTurnover)

	SET @endRun = GETDATE()
	SET @duration  = DATEDIFF(millisecond, @startRun, @endRun)

	DECLARE @LogData NVARCHAR(4000)
	SELECT @LogData = '<NAP_TOControl_GlobalSettingInsert CustID="' + COALESCE(CAST(@CustID as varchar(50)),space(1)) + '" ' 					
					+ 'MaxTuronver="' + COALESCE(CAST(@MaxTurnover AS VARCHAR(50)), SPACE(1)) + '" ' 
					+ 'IP="'+ COALESCE(CAST(@IP as varchar(15)),space(1)) + '" '
					+ 'ErrCode="'+ COALESCE(CAST(@ErrCode as varchar(50)),space(1)) + '" '
					+ 'ErrMsg="'+ COALESCE(CAST(@ErrMsg as varchar(200)),space(1)) + '" />'
														
	SET @endRun = GETDATE()
	SET @duration  = DATEDIFF(millisecond,@startRun,@endRun)

	-- WRITE LOG
	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
				@Userid = @UserID,
				@ActionID = 668,
				@TrackingValue = @LogData,
				@Duration = @duration

	IF @@SERVERNAME = 'DBCUST' 
		EXEC DBAGE.bodb02.dbo.NAP_TOControl_GlobalSettingInsert 
			@UserName = @UserName,
			@MaxTurnover = @MaxTurnover,
			@UserID = @UserID,
			@IP	= @IP
	
END
GO