ALTER PROCEDURE [dbo].[Acc_CustAllowListIns]
(
	@UserName			VARCHAR(30),
	@Creator			INT,
	@Remark				NVARCHAR(200)	= NULL,
	@IP					VARCHAR(15),
	@ErrCode			INT				= 0 OUTPUT,
	@ErrMsg				NVARCHAR(4000)	= '' OUTPUT	
)
AS
/*
	Created: Elodie
	Date: 20120301
	Task : insert test accounts in monitoring list
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

	Declare @CustID int,
			@RoleID tinyint,
			@Currency int,
			@role nvarchar(20)

	SELECT	@CustID = 0,
			@RoleID = 0,
			@Currency = 0
	--Check permission
	EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@Creator,@funcname='[ManageAgentSiteAccess]',@ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
	IF @ErrCode <> 0
		RETURN

	EXEC DBACC.bodb02.dbo.Acc_CustomerSelInfoByUsername 
		@UserName = @UserName,
		@CustID = @CustID OUTPUT,
		@RoleID = @RoleID OUTPUT,
		@Currency = @Currency OUTPUT

	IF @CustID = 0
	BEGIN
		SELECT @ErrCode = 100
		SELECT @ErrMsg = 'This account doesn''t exist in IBC system.'
		RETURN
	END

	IF @RoleID > 4
	BEGIN
		SELECT @ErrCode = 102
		SELECT @ErrMsg = 'This account is the admin account.'
		RETURN
	END
	
	IF @Currency <> 20
	BEGIN
		SELECT @ErrCode = 101
		SELECT @ErrMsg = 'This account isn''t a test account.'
		RETURN
	END	

	IF @RoleID = 1
	BEGIN
		SELECT @ErrCode = 103
		SELECT @ErrMsg = 'This account isn''t an agent.'
		RETURN
	END	 

	IF EXISTS (SELECT 1 FROM Acc_CustAllowList WITH(NOLOCK) WHERE CustID = @CustID)
	BEGIN
		SELECT @ErrCode = 104
		SELECT @ErrMsg = 'This account is already existed in the monitoring list.'
		RETURN
	END	

	INSERT INTO Acc_CustAllowList
		(	
			CustID,
			RoleID, 
			isAllowed, 
			Creator,
			CreatedDate,
			Remark			
		)
	VALUES
		(		
			@CustID,
			@RoleID, 		
			1, 
			@Creator,
			GETDATE(),						
			@Remark
		)
	
	IF @@ERROR <> 0
	BEGIN
		SELECT @ErrCode = 103
		SELECT @ErrMsg = 'Add new account unsuccessfuly.'
		RETURN
	END

	-- write log
	DECLARE @LogData NVARCHAR(4000)
	SELECT @LogData = '<Acc_CustAllowListIns UserName="' + COALESCE(@UserName,SPACE(1)) + '" ' 
							+ 'Remark="' + COALESCE(@Remark,SPACE(1)) + '" '	
							+ 'ErrCode="' + coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" '
							+ 'ErrMsg="' + coalesce(@ErrMsg,space(1))+'" '
							+ 'IP="' + COALESCE(@IP,SPACE(1)) + '" />'																		

	SET @endRun = GETDATE()
	SET @duration  = DATEDIFF(millisecond,@startRun,@endRun)
	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
			@Userid = @Creator,
			@Custid = @CustID,
			@ActionID = 6000,
			@TrackingValue = @LogData,
			@Duration = @duration
	END TRY
	BEGIN CATCH
		SELECT @LogData = '<Acc_CustAllowListIns UserName="' + COALESCE(@UserName,SPACE(1)) + '" ' 
							+ 'Remark="' + COALESCE(@Remark,SPACE(1)) + '" '	
							+ 'ErrCode="' + coalesce(cast(ERROR_MESSAGE() as varchar(50)),space(1)) + '" '
							+ 'ErrMsg="' + coalesce(@ErrMsg,space(1))+'" '
							+ 'IP="' + COALESCE(@IP,SPACE(1)) + '" />'	
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
			@Userid = @Creator,
			@Custid = @CustID,
			@ActionID = 6000,
			@TrackingValue = @LogData,
			@Duration = @duration
	END CATCH
END


GO
GRANT EXECUTE ON [dbo].[Acc_CustAllowListIns] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustAllowListIns] TO [vnteam]