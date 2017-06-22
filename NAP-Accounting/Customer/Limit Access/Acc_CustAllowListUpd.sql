ALTER PROCEDURE [dbo].[Acc_CustAllowListUpd]
(
	@CustID				INT,
	@IsAllowed			BIT				= 0,
	@LastModifiedBy		INT				= NULL,
	@Remark				NVARCHAR(50)	= NULL,
	@IP					VARCHAR(15),
	@ErrCode			INT				= 0 OUTPUT,
	@ErrMsg				NVARCHAR(4000)	= '' OUTPUT	
)
AS
/*
	Created: Elodie
	Date: 20120301
	Task : update test accounts in monitoring list
	DB: DBTXN/bodb02
	Original:

	Revisions:
		- 20130310@Lukas: Change linked-server alias & add more write log section
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

	IF NOT EXISTS (SELECT 1 FROM Acc_CustAllowList WITH(NOLOCK) WHERE CustID = @CustID)
	BEGIN
		SELECT @ErrCode = 100
		SELECT @ErrMsg = 'This account doesn''t exist in the monitoring list.'
		RETURN
	END

	DECLARE @O_IsAllowed BIT, @O_Remark NVARCHAR(50)

	SELECT @O_IsAllowed = IsAllowed, @O_Remark = Remark 
	FROM Acc_CustAllowList WITH(NOLOCK) 
	WHERE CustID = @CustID

	UPDATE Acc_CustAllowList WITH(ROWLOCK,UPDLOCK)
	SET
		IsAllowed = @IsAllowed,
		LastModifiedTime = GETDATE(),
		LastModifiedBy = @LastModifiedBy,
		Remark = @Remark
	WHERE CustID = @CustID
		
	IF @@ERROR <> 0
	BEGIN
		SELECT @ErrCode = 103
		SELECT @ErrMsg = 'Update account unsuccessfuly.'
		RETURN
	END

	-- write log
	DECLARE @LogData VARCHAR(4000),	
			@LogData_Old VARCHAR(4000)

	SELECT @LogData = '<Acc_CustAllowListUpd CustID="' + COALESCE(CAST(@CustID AS VARCHAR(50)),SPACE(1)) + '" ' 
							+ 'IsAllowed="' + COALESCE(CAST(@IsAllowed AS VARCHAR(1)),SPACE(1)) + '" ' 
							+ 'Remark="' + COALESCE(@Remark,SPACE(1)) + '" '
							+ 'ErrCode="' + coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" '
							+ 'ErrMsg="' + coalesce(@ErrMsg,space(1))+'" '
							+ 'IP="' + COALESCE(@IP,SPACE(1)) + '" />'																		

	SELECT @LogData_Old = '<Acc_CustAllowListUpd CustID="' + COALESCE(CAST(@CustID AS VARCHAR(50)),SPACE(1)) + '" ' 
							+ 'IsAllowed="' + COALESCE(CAST(@O_IsAllowed AS VARCHAR(1)),SPACE(1)) + '" ' 
							+ 'Remark="' + COALESCE(@O_Remark,SPACE(1)) + '" '	
							+ 'ErrCode="' + coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" '
							+ 'ErrMsg="' + coalesce(@ErrMsg,space(1))+'" '
							+ 'IP="' + COALESCE(@IP,SPACE(1)) + '" />'
	
	SET @endRun = GETDATE()
	SET @duration  = DATEDIFF(millisecond,@startRun,@endRun)
	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
			@Userid = @LastModifiedBy,
			@Custid = @CustID,
			@ActionID = 6001,
			@TrackingValue = @LogData,
			@TrackingValue2 = @LogData_Old,
			@Duration = @duration
	END TRY
	BEGIN CATCH
		SELECT @LogData = '<Acc_CustAllowListUpd CustID="' + COALESCE(CAST(@CustID AS VARCHAR(50)),SPACE(1)) + '" ' 
							+ 'IsAllowed="' + COALESCE(CAST(@IsAllowed AS VARCHAR(1)),SPACE(1)) + '" ' 
							+ 'Remark="' + COALESCE(@Remark,SPACE(1)) + '" '
							+ 'ErrCode="' + coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" '
							+ 'ErrMsg="' + coalesce(ERROR_MESSAGE(),space(1))+'" '
							+ 'IP="' + COALESCE(@IP,SPACE(1)) + '" />'																		

		SELECT @LogData_Old = '<Acc_CustAllowListUpd CustID="' + COALESCE(CAST(@CustID AS VARCHAR(50)),SPACE(1)) + '" ' 
							+ 'IsAllowed="' + COALESCE(CAST(@O_IsAllowed AS VARCHAR(1)),SPACE(1)) + '" ' 
							+ 'Remark="' + COALESCE(@O_Remark,SPACE(1)) + '" '	
							+ 'ErrCode="' + coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" '
							+ 'ErrMsg="' + coalesce(ERROR_MESSAGE(),space(1))+'" '
							+ 'IP="' + COALESCE(@IP,SPACE(1)) + '" />'
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
			@Userid = @LastModifiedBy,
			@Custid = @CustID,
			@ActionID = 6001,
			@TrackingValue = @LogData,
			@TrackingValue2 = @LogData_Old,
			@Duration = @duration
	END CATCH
END


GO
GRANT EXECUTE ON [dbo].[Acc_CustAllowListUpd] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustAllowListUpd] TO [vnteam]




