ALTER PROCEDURE [dbo].[Acc_CustAllowListDel]
(
	@CustID				INT,
	@LastModifiedBy		INT				= NULL,
	@IP					VARCHAR(15),
	@ErrCode			INT				= 0 OUTPUT,
	@ErrMsg				NVARCHAR(4000)	= '' OUTPUT	
)
AS
/*
	Created: Elodie
	Date: 20120301
	Task : delete test accounts in monitoring list
	DB: DBTXN/bodb02
	Original:

	Revisions:
		20130310@Lukas: Change linked-server alias & add more write log section
	Param's Explanation:
	
*/
BEGIN	
	SET NOCOUNT ON

	DECLARE @startRun	DATETIME,
			@endRun		DATETIME,
			@duration	INT
	SET	@startRun = GETDATE()

	SELECT	@ErrCode	= 0,
			@ErrMsg		= ''

	--Check permission
	EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@LastModifiedBy,@funcname='[ManageAgentSiteAccess]',@ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
	IF @ErrCode <> 0
		RETURN

	IF NOT EXISTS (SELECT 1 FROM Acc_CustAllowList WITH (NOLOCK) WHERE CustID = @CustID)
	BEGIN
		SELECT @ErrCode = 101
		SELECT @ErrMsg = 'This account doesn''t exist in the monitoring list.'
		RETURN
	END

	DELETE Acc_CustAllowList  WITH (ROWLOCK) WHERE CustID = @CustID
			
	IF @@ERROR <> 0
	BEGIN
		SELECT @ErrCode = 102
		SELECT @ErrMsg = 'Delete account unsuccessfuly.'
		RETURN
	END

	-- write log
	DECLARE @LogData NVARCHAR(4000)
	SELECT @LogData = '<Acc_CustAllowListDel ErrCode="' + coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" '												
					+ 'ErrMsg="' + coalesce(@ErrMsg,space(1))+'" '
					+ 'IP="' + COALESCE(@IP,SPACE(1)) + '" />'
					
	SET @endRun = GETDATE()
	SET @duration  = DATEDIFF(millisecond,@startRun,@endRun)
	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
			@Userid = @LastModifiedBy,
			@Custid = @CustID,
			@ActionID = 6002,
			@TrackingValue = @LogData,
			@Duration = @duration
	END TRY
	BEGIN CATCH
		SELECT @LogData = '<Acc_CustAllowListDel ErrCode="' + coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" '												
					+ 'ErrMsg="' + coalesce(ERROR_MESSAGE(),space(1))+'" '
					+ 'IP="' + COALESCE(@IP,SPACE(1)) + '" />'
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
			@Userid = @LastModifiedBy,
			@Custid = @CustID,
			@ActionID = 6002,
			@TrackingValue = @LogData,
			@Duration = @duration
	END CATCH
END


GO
GRANT EXECUTE ON [dbo].[Acc_CustAllowListDel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustAllowListDel] TO [vnteam]




 