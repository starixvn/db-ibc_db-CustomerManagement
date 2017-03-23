/*<info serverAlias="DBAGE-bodb02" executers="bodbAdminNet" viewers="vnteam" isFunction="0"></info>*/
USE [bodb02]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE NAP_TOControl_GlobalSettingDelete
	@CustID INT,
	@UserID INT,
	@IP	VARCHAR(40),
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS

/*
	Created: 20170324@Francis
	Task: Delete CustID from TOControl_GlobalSetting [Feature #72812]
	DB: DBCUST/CustDB
	
	Revisions:
		

*/
BEGIN
	SET NOCOUNT ON;

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

	DELETE DownlineTurnOver_GlobalSetting WITH(ROWLOCK,UPDLOCK) WHERE CustID=@CustID
	DELETE st
	FROM DownlineTurnover_Setting st WITH(ROWLOCK,UPDLOCK)
	INNER JOIN Match m WITH(NOLOCK) ON m.matchid = st.matchid
	WHERE CustID = @CustID
		AND m.eventstatus <> 'completed'

	DECLARE @TrackingValue2 NVARCHAR(4000)

	SET @endRun = GETDATE()
	SET @duration  = DATEDIFF(millisecond,@startRun,@endRun)
	SELECT @TrackingValue2 = '<NAP_SMATurnoverGlobalSettingDel CustID="' + COALESCE(CAST(@CustID AS VARCHAR(10)), SPACE(1)) + '" ' 					
					+ 'MaxTurnover="' + COALESCE(CAST(@MaxTurnover_Old AS VARCHAR(20)), SPACE(1)) + '" ' 
					+ 'IP="'+ COALESCE(CAST(@IP as varchar(15)),space(1)) + '" '
					+ 'AffectedMatch="' + COALESCE(@AffectedMatch,space(1)) + '" '
					+ 'ErrCode="'+ COALESCE(CAST(@ErrCode as varchar(50)),space(1)) + '" '
					+ 'ErrMsg="'+ COALESCE(CAST(@ErrMsg as varchar(200)),space(1)) + '" />'
	
	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
				@Userid = @UserID,
				@ActionID = 658,
				@TrackingValue2 = @TrackingValue2,
				@Duration = @duration
END

GO
GRANT EXECUTE ON [dbo].[NAP_SMATurnoverGlobalSettingDel] TO [bodbadminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_SMATurnoverGlobalSettingDel] TO [vnteam]