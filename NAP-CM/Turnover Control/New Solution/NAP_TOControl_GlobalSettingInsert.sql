/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/

CREATE PROCEDURE [dbo].[NAP_TOControl_GlobalSettingInsert]
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

	IF EXISTS (SELECT 1 FROM dbo.TOControl_Setting WITH(NOLOCK) WHERE CustID = @CustID)
	BEGIN
			SELECT @ErrCode = 102, @ErrMsg = 'The setting of this customer already existed!'
			RETURN
	END

	---- Process to get information about turnover (running events) for @CustID
	--INSERT INTO @MatchList(matchid, homeid, awayid, eventdate, sporttype, leagueid)
	--	SELECT m.matchid, m.homeid, m.awayid, m.eventdate, m.sporttype, m.leagueid
	--	FROM DBAGE.bodb02.dbo.match m WITH(NOLOCK)
	--	WHERE m.eventstatus <> 'completed'

	INSERT INTO dbo.TOControl_Setting VALUES(@CustID, @MaxTurnover)

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


END
GO