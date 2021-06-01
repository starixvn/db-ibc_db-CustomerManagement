/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_BettingMonitor_SettingUpd]
	@MinimumTickets SMALLINT,
	@Threshold TINYINT,
	@UserID	INT,  
	@IP	VARCHAR(15) = '',
	@ErrCode INT = 0 OUTPUT, 
	@ErrMsg	NVARCHAR(4000) = ''	OUTPUT  
AS
/*  
	Creator: Elodie
	Date: 20160705
	Task: Get customer list to send email - [Redmine:#58401]
	DB: DBACC/bodb02
  
	Revisions:		
		- 20210512@Eden: Migrate bodb_Acc to main server [#152636]  

	Example: EXEC NAP_BettingMonitor_SettingUpd @MinimumTickets = 200, @Threshold = 100, @UserID = 8

*/
BEGIN
	SET NOCOUNT ON

	DECLARE @startRun		DATETIME,
			@endRun			DATETIME,
			@duration		INT,
			@logSpData		NVARCHAR(MAX),
			@logSpData_Old	NVARCHAR(MAX)

	DECLARE @Old_Threshold TINYINT, @Old_MinimumTickets SMALLINT, @TimeStamp VARCHAR(200), 
			@His_Threshold TINYINT, @His_MinimumTickets SMALLINT, @His_TimeStamp VARCHAR(200)

	SELECT @Old_Threshold = CONVERT(TINYINT,Value) FROM dbo.BetMonitoring_Setting WITH (NOLOCK) WHERE SettingName = 'Threshold'
	SELECT @Old_MinimumTickets = CONVERT(SMALLINT,Value) FROM dbo.BetMonitoring_Setting WITH (NOLOCK) WHERE SettingName = 'MinimumTickets'

	IF @Old_Threshold = @Threshold AND @Old_MinimumTickets = @MinimumTickets
		RETURN

	UPDATE s
	SET s.Value = CONVERT(VARCHAR(200),@MinimumTickets)
	FROM dbo.BetMonitoring_Setting s WITH (ROWLOCK,UPDLOCK)
	WHERE SettingName = 'MinimumTickets'
	
	UPDATE s
	SET s.Value = CONVERT(VARCHAR(200),@Threshold)
	FROM dbo.BetMonitoring_Setting s WITH (ROWLOCK,UPDLOCK)
	WHERE SettingName = 'Threshold'
	
	IF @MinimumTickets > @Old_MinimumTickets OR @Threshold > @Old_Threshold -- increase setting
	BEGIN
		UPDATE his
		SET his.NotifiedStatus = 0
		FROM dbo.BetMonitoring_CustTotalBet_History his WITH (ROWLOCK,UPDLOCK)
	END
	
	UPDATE s
	SET s.Value = '1900-01-01 00:00:00'
	FROM dbo.BetMonitoring_Setting s WITH (ROWLOCK,UPDLOCK)
	WHERE SettingName = 'MinDate'

	Select @LogSPData = '<NAP_BettingMonitor_SettingUpd Threshold="' + coalesce(cast(@Threshold as varchar(5)),space(1)) + '"'
						+ ' MinimumTickets="' + coalesce(cast(@MinimumTickets as varchar(5)),space(1)) + '"' 
						+ ' ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '"'
						+ ' ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(400)),space(1))+'"'
						+ ' IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+'" />'

	Select @logSpData_Old = '<NAP_BettingMonitor_SettingUpd Threshold="' + coalesce(cast(@Old_Threshold as varchar(5)),space(1)) + '"'
						+ ' MinimumTickets="' + coalesce(cast(@Old_MinimumTickets as varchar(5)),space(1)) + '"' 
						+ ' ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '"'
						+ ' ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(400)),space(1))+'"'
						+ ' IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+'" />'

	set @endRun = getdate()
	set @duration  = datediff (millisecond,@startRun,@endRun)

	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
			@UserID = @UserID,
			@ActionID = 31402,
			@TrackingValue = @LogSPData,
			@TrackingValue2 = @logSpData_Old,
			@duration = @duration
	END TRY
	BEGIN CATCH
		Select @LogSPData = '<NAP_BettingMonitor_SettingUpd Threshold="' + coalesce(cast(@Threshold as varchar(5)),space(1)) + '"'
						+ ' MinimumTickets="' + coalesce(cast(@MinimumTickets as varchar(5)),space(1)) + '"' 
						+ ' ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '"'
						+ ' ErrMsg="'+ coalesce(cast(ERROR_MESSAGE() as varchar(400)),space(1))+'"'
						+ ' IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+'" />'

		Select @logSpData_Old = '<NAP_BettingMonitor_SettingUpd Threshold="' + coalesce(cast(@Old_Threshold as varchar(5)),space(1)) + '"'
							+ ' MinimumTickets="' + coalesce(cast(@Old_MinimumTickets as varchar(5)),space(1)) + '"' 
							+ ' ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '"'
							+ ' ErrMsg="'+ coalesce(cast(ERROR_MESSAGE() as varchar(400)),space(1))+'"'
							+ ' IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+'" />'			

		EXEC DBCUST.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
			@UserID = @UserID,
			@ActionID = 31402,
			@TrackingValue = @LogSPData,
			@TrackingValue2 = @logSpData_Old,
			@duration = @duration
	END CATCH
END
GO