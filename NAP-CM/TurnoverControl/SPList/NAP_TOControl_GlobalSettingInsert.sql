/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_TOControl_GlobalSettingInsert]
	@UserName NVARCHAR(30),
	@MaxTurnover MONEY,
	@IsGroupHeadline BIT = 0,
	@SportType SMALLINT = 1,
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
		- 20170920@Helen: TO Control Phase 3 - [Redmine: 75557]
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

	IF EXISTS (SELECT 1 FROM dbo.TOControl_GlobalSetting WITH(NOLOCK) WHERE CustID = @CustID AND IsGroupHeadLine = @IsGroupHeadline AND Sporttype = @SportType)
	BEGIN
			SELECT @ErrCode = 102, @ErrMsg = 'The setting of this customer already existed!'
			RETURN
	END

	CREATE TABLE #tmpTurnover(MatchId INT, SumOfStake MONEY, HouseTurnover MONEY)
	
	INSERT INTO #tmpTurnover(MatchId, SumOfStake, HouseTurnover)
	EXECUTE DBAGE.bodb02.dbo.NAP_TOControl_MatchTurnoverByCustomerSelect @CustID = @CustID, @RoleID = @roleid, @IsGroupHeadline = @IsGroupHeadline, @SportType = @SportType
	
	
	INSERT INTO dbo.TOControl_Setting(CustID, matchid, MaxTurnOver, TotalTurnOver, HouseTurnover, PercentLevel, IsNotified,IsGroupHeadline)
	SELECT
		@CustID, t.MatchId, @MaxTurnover AS MaxTurnOver, t.SumOfStake AS TotalTurnOver, t.HouseTurnover
		,	CASE	WHEN @MaxTurnover = 0 THEN 10 
					ELSE (SELECT MAX(PercentLevel) FROM dbo.TOControl_LevelSetting (NOLOCK) WHERE ((HouseTurnover*100)/@MaxTurnover) >= PercentValue)
			END AS PercentLevel
			
		, 0 AS IsNotified
		, @IsGroupHeadline AS IsGroupHeadline
	FROM #tmpTurnover t WITH (NOLOCK)
		
	IF @@ERROR > 0 
	BEGIN
		SELECT @ErrCode = 103, @ErrMsg = 'Adding failed.'
		RETURN;
		
	END
	
	INSERT INTO dbo.TOControl_GlobalSetting(CustID, MaxTurnOver,SportType,IsGroupHeadLine) 
	VALUES(@CustID, @MaxTurnover, @SportType,@IsGroupHeadline)

	SET @endRun = GETDATE()
	SET @duration  = DATEDIFF(millisecond, @startRun, @endRun)

	DECLARE @LogData NVARCHAR(4000)
	SELECT @LogData = '<NAP_TOControl_GlobalSettingInsert CustID="' + COALESCE(CAST(@CustID as varchar(50)),space(1)) + '" ' 					
					+ 'MaxTuronver="' + COALESCE(CAST(@MaxTurnover AS VARCHAR(50)), SPACE(1)) + '" ' 
					+ 'IsGroupHeadline="' + COALESCE(CAST(@IsGroupHeadline AS VARCHAR(50)), SPACE(1)) + '" ' 
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

END
GO
GRANT EXECUTE ON [dbo].[NAP_TOControl_GlobalSettingInsert] TO [bodbAdminNet]
