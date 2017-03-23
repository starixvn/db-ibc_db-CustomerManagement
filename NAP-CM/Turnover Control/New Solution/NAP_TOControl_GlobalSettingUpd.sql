/*<info serverAlias="DBAGE-bodb02" executers="bodbAdminNet" viewers="vnteam" isFunction="0"></info>*/
USE [bodb02]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE NAP_TOControl_GlobalSettingUpd
	@CustID INT,
	@MaxTurnover MONEY,
	@UserID INT,
	@IP	VARCHAR(40),
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS

/*
	Created: 20170324@Francis
	Task: Update MaxTurnOver in TOControl_GlobalSetting for a CustID [Feature #72812]
	DB: DBCUST/CustDB
	
	Revisions:
		- 20170324@Don: add more specific levels for notification - [Redmine:#72812]

*/


BEGIN 
	SET NOCOUNT ON

	DECLARE @startRun	DATETIME,
			@endRun		DATETIME,
			@duration	INT
	SET	@startRun = GETDATE()

	--Check permission 
	EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[GlobalSetting]',@ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
	IF @ErrCode <> 0
		RETURN

	DECLARE @MaxTurnover_Old MONEY, @AffectedMatch VARCHAR(1000)=''
	SELECT @MaxTurnover_Old=MaxTurnover FROM DownlineTurnOver_GlobalSetting WITH(NOLOCK) WHERE CustID=@CustID
	SELECT @AffectedMatch = @AffectedMatch + CAST(st.MatchID AS VARCHAR(20)) +',' 
	FROM DownlineTurnOver_Setting st WITH(NOLOCK) 
	INNER JOIN Match m WITH(NOLOCK) ON m.matchid = st.matchid
	WHERE CustID=@CustID
		AND m.eventstatus <> 'completed'

	IF(LEN(ISNULL(@AffectedMatch,'')) > 0)
	BEGIN
		SELECT @AffectedMatch = LEFT(@AffectedMatch,LEN(@AffectedMatch)-1)
	END

	IF @CustID <= 0
	BEGIN
		SELECT @ErrCode = 101, @ErrMsg = 'Invalid Super/Master/Agent.'
		RETURN
	END

	IF @MaxTurnover <= 0
	BEGIN
		SELECT @ErrCode = 102, @ErrMsg = 'Invalid MaxTurnover.'
		RETURN
	END

	UPDATE DownlineTurnOver_GlobalSetting WITH(ROWLOCK,UPDLOCK) SET MaxTurnOver = @MaxTurnover WHERE CustID=@CustID
	UPDATE st
	SET MaxTurnover = @MaxTurnover,
		IsNotified = CASE WHEN @MaxTurnover <> 0 AND @MaxTurnover > MaxTurnover THEN   --- reset isNotified only in case of increasing maxturnover
								CASE	WHEN (HouseTurnOver/@MaxTurnover)*100 >= 100 THEN 100
										WHEN (HouseTurnOver/@MaxTurnover)*100 >= 80 THEN 80
										WHEN (HouseTurnOver/@MaxTurnover)*100 >= 60 THEN 60
										WHEN (HouseTurnOver/@MaxTurnover)*100 >= 40 THEN 40
										ELSE 0
								END 
							ELSE IsNotified 
					END
	FROM DownlineTurnover_Setting st WITH(ROWLOCK,UPDLOCK)
		INNER JOIN Match m WITH(NOLOCK) ON m.matchid = st.matchid
	WHERE CustID = @CustID
		AND m.eventstatus <> 'completed'

	DECLARE @LogData NVARCHAR(4000), @TrackingValue2 NVARCHAR(4000)

	SET @endRun = GETDATE()
	SET @duration  = DATEDIFF(millisecond,@startRun,@endRun)

	SELECT @LogData = '<NAP_SMATurnoverGlobalSettingUpd CustID="' + COALESCE(CAST(@CustID AS VARCHAR(10)), SPACE(1)) + '" ' 					
					+ 'MaxTurnover="' + COALESCE(CAST(@MaxTurnover AS VARCHAR(20)), SPACE(1)) + '" ' 
					+ 'IP="'+ COALESCE(CAST(@IP as varchar(15)),space(1)) + '" '
					+ 'AffectedMatch="' + COALESCE(@AffectedMatch,space(1)) + '" '
					+ 'ErrCode="'+ COALESCE(CAST(@ErrCode as varchar(50)),space(1)) + '" '
					+ 'ErrMsg="'+ COALESCE(CAST(@ErrMsg as varchar(200)),space(1)) + '" />'

	SELECT @TrackingValue2 = '<NAP_SMATurnoverGlobalSettingUpd CustID="' + COALESCE(CAST(@CustID AS VARCHAR(10)), SPACE(1)) + '" ' 					
					+ 'MaxTurnover="' + COALESCE(CAST(@MaxTurnover_Old AS VARCHAR(20)), SPACE(1)) + '" ' 
					+ 'IP="'+ COALESCE(CAST(@IP as varchar(15)),space(1)) + '" '
					+ 'AffectedMatch="' + COALESCE(@AffectedMatch,space(1)) + '" '
					+ 'ErrCode="'+ COALESCE(CAST(@ErrCode as varchar(50)),space(1)) + '" '
					+ 'ErrMsg="'+ COALESCE(CAST(@ErrMsg as varchar(200)),space(1)) + '" />'
	
	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
				@Userid = @UserID,
				@ActionID = 657,
				@TrackingValue = @LogData,
				@TrackingValue2 = @TrackingValue2,
				@Duration = @duration
END

