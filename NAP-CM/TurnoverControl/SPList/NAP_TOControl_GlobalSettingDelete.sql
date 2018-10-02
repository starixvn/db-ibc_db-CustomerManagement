/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_TOControl_GlobalSettingDelete]
	@CustID INT,
	@UserID INT,
	@SportType SMALLINT = 1,
	@IsGroupHeadline BIT = 0,
	@IP	VARCHAR(40),
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
	
/*
	Created: Don
	Date: 2017-03-27
	Task: Delete one Gobal Setting
	DB: DBCUST/CustDB

	Revisions:
		- 20170920@Helen: TO Control Phase 3 - [Redmine: 75557]
		- 20171115@Vicky: change location check permission [RedmineID: #86455]
		- 20171212@Helen: Implement some change request from OPS Team - [Redmine: 85638]
		- 20180925@Helen: DB052.bodb_NAP Migration to DBCust - [Redmine:100493]
		
	Parameter's explaination:
	
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @MatchList TABLE(matchid INT, homeid INT, awayid INT, eventdate DATETIME, sporttype INT, leagueid INT)

	DECLARE @MaxTurnover_Old MONEY, @AffectedMatch VARCHAR(1000)=''
	DECLARE @startRun	DATETIME,
			@endRun		DATETIME,
			@duration	INT,
			@FunctionKey NVARCHAR(50)
			
	SET	@startRun = GETDATE()

	IF @SportType = 1 
		SET @FunctionKey = 'GlobalSetting_Soccer'
	ELSE
		SET @FunctionKey = 'GlobalSetting_OtherSports'
		
	--Check permission 
	EXEC NAP_UserControl.dbo.NAP_User_CheckPermission @UserId=@UserID,@SiteKey='CustomerManagement',@FunctionKey=@FunctionKey,@ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
	
	IF @ErrCode <> 0
		RETURN
	
	INSERT INTO @MatchList(matchid, homeid, awayid, eventdate, sporttype, leagueid)
	SELECT m.matchid, m.homeid, m.awayid, m.eventdate, m.sporttype, m.leagueid
	FROM DBAGE.bodb02.dbo.match m WITH(NOLOCK)
	WHERE m.eventstatus <> 'completed'
		AND (
				-- Soccer
				(@SportType = 1 AND sporttype = 1) 
				OR 
				-- Other sports
				(@SportType = 99 AND sporttype > 1 AND sporttype <=99 )
			 )

	SELECT @MaxTurnover_Old = t.MaxTurnover 
	FROM dbo.TOControl_Setting t WITH(NOLOCK) 
		INNER JOIN @MatchList m ON t.matchid = m.matchid
	WHERE t.CustID = @CustID AND t.IsGroupHeadLine = @IsGroupHeadline
	
	SELECT @AffectedMatch = @AffectedMatch + CAST(t.MatchID AS VARCHAR(20)) + ',' 
	FROM dbo.TOControl_Setting t WITH(NOLOCK) 
		INNER JOIN @MatchList m ON m.matchid = t.matchid
	WHERE t.CustID = @CustID AND t.IsGroupHeadLine = @IsGroupHeadline

	IF(LEN(ISNULL(@AffectedMatch,'')) > 0)
	BEGIN
		SELECT @AffectedMatch = LEFT(@AffectedMatch, LEN(@AffectedMatch)-1)
	END

	DELETE dbo.TOControl_GlobalSetting WITH(ROWLOCK, UPDLOCK) 
	WHERE CustID=@CustID AND SportType = @SportType AND IsGroupHeadLine = @IsGroupHeadline
	
	DELETE t
	FROM dbo.TOControl_Setting t WITH(ROWLOCK, UPDLOCK)
		INNER JOIN @MatchList m ON m.matchid = t.matchid
	WHERE t.CustID = @CustID AND IsGroupHeadLine = @IsGroupHeadline

	DECLARE @TrackingValue2 NVARCHAR(4000)

	SET @endRun = GETDATE()
	SET @duration  = DATEDIFF(millisecond,@startRun,@endRun)
	SELECT @TrackingValue2 = '<NAP_TOControl_GlobalSettingDelete CustID="' + COALESCE(CAST(@CustID AS VARCHAR(10)), SPACE(1)) + '" ' 					
					+ 'SportType="' + COALESCE(CAST(@SportType AS VARCHAR(20)), SPACE(1)) + '" ' 
					+ 'MaxTurnover="' + COALESCE(CAST(@MaxTurnover_Old AS VARCHAR(20)), SPACE(1)) + '" ' 
					+ 'IsGroupHeadLine="' + COALESCE(CAST(@IsGroupHeadline AS VARCHAR(20)), SPACE(1)) + '" ' 
					+ 'IP="'+ COALESCE(CAST(@IP as varchar(15)),space(1)) + '" '
					+ 'AffectedMatch="' + COALESCE(@AffectedMatch,space(1)) + '" '
					+ 'ErrCode="'+ COALESCE(CAST(@ErrCode as varchar(50)),space(1)) + '" '
					+ 'ErrMsg="'+ COALESCE(CAST(@ErrMsg as varchar(200)),space(1)) + '" />'
	
	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
				@Userid = @UserID,
				@CustID = @CustID,
				@ActionID = 670,
				@TrackingValue2 = @TrackingValue2,
				@Duration = @duration
END
GO
GRANT EXECUTE ON [dbo].[NAP_TOControl_GlobalSettingDelete] TO [bodbAdminNet]
GO
