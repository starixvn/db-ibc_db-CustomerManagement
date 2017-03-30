/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
USE CustDB
GO 

ALTER PROCEDURE [dbo].[NAP_TOControl_GlobalSettingDelete]
	@CustID INT,
	@UserID INT,
	@IP	VARCHAR(40),
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS

/*
	Created: Don
	Date: 2017-03-27
	Task: Delete one Gobal Setting
	DB: DBCUST.CustDB

	Revisions:

	Parameter's explaination:
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @MatchList TABLE(matchid INT, homeid INT, awayid INT, eventdate DATETIME, sporttype INT, leagueid INT)

	DECLARE @MaxTurnover_Old MONEY, @AffectedMatch VARCHAR(1000)=''
	DECLARE @startRun	DATETIME,
			@endRun		DATETIME,
			@duration	INT
	SET	@startRun = GETDATE()

	--Check permission 
	EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID, @funcname='[GlobalSetting]', @ErrCode=@ErrCode OUTPUT, @ErrMsg=@ErrMsg OUTPUT
	IF @ErrCode <> 0
		RETURN

	INSERT INTO @MatchList(matchid, homeid, awayid, eventdate, sporttype, leagueid)
		SELECT m.matchid, m.homeid, m.awayid, m.eventdate, m.sporttype, m.leagueid
		FROM DBAGE.bodb02.dbo.match m WITH(NOLOCK)
		WHERE m.eventstatus <> 'completed'

	SELECT @MaxTurnover_Old = t.MaxTurnover 
	FROM dbo.TOControl_Setting t WITH(NOLOCK) 
		INNER JOIN @MatchList m ON t.matchid = m.matchid
	WHERE t.CustID = @CustID
	
	SELECT @AffectedMatch = @AffectedMatch + CAST(t.MatchID AS VARCHAR(20)) + ',' 
	FROM dbo.TOControl_Setting t WITH(NOLOCK) 
		INNER JOIN @MatchList m ON m.matchid = t.matchid
	WHERE t.CustID = @CustID

	IF(LEN(ISNULL(@AffectedMatch,'')) > 0)
	BEGIN
		SELECT @AffectedMatch = LEFT(@AffectedMatch, LEN(@AffectedMatch)-1)
	END

	DELETE dbo.TOControl_GlobalSetting WITH(ROWLOCK, UPDLOCK) 
	WHERE CustID=@CustID
	
	DELETE t
	FROM dbo.TOControl_Setting t WITH(ROWLOCK, UPDLOCK)
		INNER JOIN @MatchList m ON m.matchid = t.matchid
	WHERE t.CustID = @CustID

	DECLARE @TrackingValue2 NVARCHAR(4000)

	SET @endRun = GETDATE()
	SET @duration  = DATEDIFF(millisecond,@startRun,@endRun)
	SELECT @TrackingValue2 = '<NAP_TOControl_GlobalSettingDelete CustID="' + COALESCE(CAST(@CustID AS VARCHAR(10)), SPACE(1)) + '" ' 					
					+ 'MaxTurnover="' + COALESCE(CAST(@MaxTurnover_Old AS VARCHAR(20)), SPACE(1)) + '" ' 
					+ 'IP="'+ COALESCE(CAST(@IP as varchar(15)),space(1)) + '" '
					+ 'AffectedMatch="' + COALESCE(@AffectedMatch,space(1)) + '" '
					+ 'ErrCode="'+ COALESCE(CAST(@ErrCode as varchar(50)),space(1)) + '" '
					+ 'ErrMsg="'+ COALESCE(CAST(@ErrMsg as varchar(200)),space(1)) + '" />'
	
	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
				@Userid = @UserID,
				@ActionID = 670,
				@TrackingValue2 = @TrackingValue2,
				@Duration = @duration
				
	IF @@SERVERNAME = 'DBCUST' 
		EXEC DBAGE.bodb02.dbo.NAP_TOControl_GlobalSettingDelete 
			@CustID = @CustID,
			@UserID = @UserID,
			@IP	= @IP
			
END
GO