/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_TOControl_MatchTurnoverUpdate]
	@CustID INT,
	@MatchID INT,
	@SportType SMALLINT = 1,
	@IsGroupHeadline BIT = 0,
	@MaxTurnover MONEY,
	@UserID INT,
	@IP	VARCHAR(40),
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(200) = '' OUTPUT
AS
/*
	Created: Don
	Date: 2017-03-23
	Task: Update MaxTurnover for Super/Master/Agent
	DB: DBCUST/CustDB

	Revisions:
		- 20170920@Helen: TO Control Phase 3 - [Redmine: 75557]
		- 20171115@Vicky: change location check permission [RedmineID: #86455]
		- 20171212@Helen: Implement some change request from OPS Team - [Redmine: 85638]
		
	Parameter's explaination:
		
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @LogData			NVARCHAR(4000),
			@TrackingValue2		NVARCHAR(4000),
			@startRun			DATETIME,
			@endRun				DATETIME,
			@duration			INT,
			@MaxTurnover_old	MONEY,
			@FunctionKey		NVARCHAR(50)
			
	SET	@startRun = GETDATE()

	IF @SportType = 1 
		SET @FunctionKey = 'TurnoverMonitor_Soccer'
	ELSE
		SET @FunctionKey = 'TurnoverMonitor_OtherSports'
		
	
	--Check permission 
	EXEC DBNAP.bodb_NAP.dbo.NAP_User_CheckPermission @UserId=@UserID,@SiteKey='CustomerManagement',@FunctionKey=@FunctionKey,@ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
	IF @ErrCode <> 0
		RETURN
	
	IF EXISTS (SELECT 1 FROM DBAGE.bodb02.dbo.match WITH (NOLOCK) WHERE matchid = @MatchID AND eventstatus = 'completed')
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'You are not allowed to update max turnover of a settled match.'
		RETURN
	END

	SELECT @MaxTurnover_old = MaxTurnover
	FROM dbo.TOControl_Setting WITH (NOLOCK)
	WHERE CustID = @CustID AND matchid = @MatchID AND IsGroupHeadLine = @IsGroupHeadline
	
	IF @MaxTurnover = 0
	BEGIN
		UPDATE dbo.TOControl_Setting WITH(ROWLOCK, UPDLOCK)
		SET 
			MaxTurnover = @MaxTurnover,
			IsNotified = 0
		WHERE CustID = @CustID AND matchid = @MatchID AND IsGroupHeadLine = @IsGroupHeadline
	END
	ELSE
	BEGIN
		UPDATE dbo.TOControl_Setting WITH(ROWLOCK, UPDLOCK)
			SET 
				MaxTurnover = @MaxTurnover,
				IsNotified =  ISNULL((SELECT MAX(PercentValue) FROM dbo.TOControl_LevelSetting WITH(NOLOCK) WHERE (HouseTurnOver*100/@MaxTurnover) >= PercentValue AND IsNotified = 1),0),
				PercentLevel = ISNULL((SELECT MAX(PercentLevel) FROM dbo.TOControl_LevelSetting WITH (NOLOCK) WHERE (HouseTurnOver*100/@MaxTurnover) >= PercentValue),0) 
						
		WHERE CustID = @CustID AND matchid = @MatchID AND IsGroupHeadLine = @IsGroupHeadline
	END

	SELECT @LogData = '<NAP_TOControl_MatchTurnoverUpdate CustID="' + COALESCE(CAST(@CustID AS VARCHAR(10)), SPACE(1)) + '" ' 					
					+ 'SportType="' + COALESCE(CAST(@SportType AS VARCHAR(20)), SPACE(1)) + '" ' 
					+ 'IsGroupHeadline="' + COALESCE(CAST(@IsGroupHeadline AS VARCHAR(10)), SPACE(1)) + '" ' 
					+ 'MatchID="' + COALESCE(CAST(@MatchID AS VARCHAR(10)), SPACE(1)) + '" ' 
					+ 'MaxTurnover="' + COALESCE(CAST(@MaxTurnover AS VARCHAR(20)), SPACE(1)) + '" ' 
					+ 'ErrCode="'+ COALESCE(CAST(@ErrCode as varchar(50)),space(1)) + '" '
					+ 'ErrMsg="'+ COALESCE(CAST(@ErrMsg as varchar(200)),space(1)) + '" '
					+ 'IP="'+ COALESCE(CAST(@IP as varchar(15)),space(1))+ '" />'
							
	-- For Old value
	SELECT @TrackingValue2 = '<NAP_TOControl_MatchTurnoverUpdate CustID="' + COALESCE(CAST(@CustID AS VARCHAR(10)), SPACE(1)) + '" ' 					
					+ 'SportType="' + COALESCE(CAST(@SportType AS VARCHAR(20)), SPACE(1)) + '" ' 
					+ 'IsGroupHeadline="' + COALESCE(CAST(@IsGroupHeadline AS VARCHAR(10)), SPACE(1)) + '" ' 
					+ 'MatchID="' + COALESCE(CAST(@MatchID AS VARCHAR(10)), SPACE(1)) + '" ' 
					+ 'MaxTurnover="' + COALESCE(CAST(@MaxTurnover_old AS VARCHAR(20)), SPACE(1)) + '" ' 
					+ 'ErrCode="'+ COALESCE(CAST(@ErrCode as varchar(50)),space(1)) + '" '
					+ 'ErrMsg="'+ COALESCE(CAST(@ErrMsg as varchar(200)),space(1)) + '" '
					+ 'IP="'+ COALESCE(CAST(@IP as varchar(15)),space(1))+ '" />'
					
	SET @endRun = GETDATE()
	SET @duration  = DATEDIFF(millisecond,@startRun,@endRun)
	
	
	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		@Userid = @UserID,
		@Custid = @CustID,
		@ActionID = 671,
		@TrackingValue = @LogData,
		@TrackingValue2 = @TrackingValue2,
		@Duration = @duration					
						
END
GO

GRANT EXECUTE ON [dbo].[NAP_TOControl_MatchTurnoverUpdate] TO [bodbAdminNet]
GO

