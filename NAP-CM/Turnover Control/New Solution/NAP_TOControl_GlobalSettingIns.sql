/*<info serverAlias="DBAGE-bodb02" executers="bodbAdminNet" viewers="vnteam" isFunction="0"></info>*/
USE [bodb02]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE NAP_TOControl_GlobalSettingIns
	@UserName NVARCHAR(30),
	@MaxTurnover MONEY,
	@UserID INT,
	@IP	VARCHAR(40),
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS

/*
	Created: 20170324@Francis
	Task: Insert new CustID into TOControl_GlobalSetting [Feature #72812]
	DB: DBCUST/CustDB
	
	Revisions:
		

*/
BEGIN 
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
	SELECT @CustID = CustID,@roleid=RoleID FROM CustInfo WITH(NOLOCK) WHERE UserName = @UserName

	IF @CustID IS NULL OR @roleid=1
	BEGIN
			SELECT @ErrCode = 101, @ErrMsg = 'Invalid Super/Master/Agent.'
			RETURN
	END

	IF EXISTS (SELECT 1 FROM DownlineTurnOver_GlobalSetting WHERE CustID = @CustID)
	BEGIN
			SELECT @ErrCode = 102, @ErrMsg = 'The setting of this customer already existed!'
			RETURN
	END

	INSERT INTO DownlineTurnOver_GlobalSetting VALUES(@CustID,@MaxTurnover)

	SET @endRun = GETDATE()
	SET @duration  = DATEDIFF(millisecond,@startRun,@endRun)

	DECLARE @LogData NVARCHAR(4000)
	SELECT @LogData = '<NAP_SMATurnoverGlobalSettingIns CustID="' + COALESCE(CAST(@CustID as varchar(50)),space(1)) + '" ' 					
					+ 'MaxTuronver="' + COALESCE(CAST(@MaxTurnover AS VARCHAR(50)), SPACE(1)) + '" ' 
					+ 'IP="'+ COALESCE(CAST(@IP as varchar(15)),space(1)) + '" '
					+ 'ErrCode="'+ COALESCE(CAST(@ErrCode as varchar(50)),space(1)) + '" '
					+ 'ErrMsg="'+ COALESCE(CAST(@ErrMsg as varchar(200)),space(1)) + '" />'
														
	SET @endRun = GETDATE()
	SET @duration  = DATEDIFF(millisecond,@startRun,@endRun)

	-- WRITE LOG
	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
				@Userid = @UserID,
				@ActionID = 656,
				@TrackingValue = @LogData,
				@Duration = @duration
END

GO
GRANT EXECUTE ON [dbo].[NAP_SMATurnoverGlobalSettingIns] TO [bodbadminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_SMATurnoverGlobalSettingIns] TO [vnteam]
