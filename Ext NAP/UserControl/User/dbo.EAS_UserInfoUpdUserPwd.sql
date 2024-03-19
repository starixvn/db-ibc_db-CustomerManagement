/*<info serverAlias="DBCUST-CUSTDB" executers="bodbExtAccNet,wsv_xnap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_UserInfoUpdUserPwd]
	@UserID		INT,
	@CustID		INT,		
	@UserPwd	nvarchar(50),		
	@IP			VARCHAR(50),
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		VARCHAR(500) = '' OUTPUT
AS
	/*
		Created: Dan
		Date: 2012-05-11
		Task: Update user info 
		DB: DBCUST/CUSTDB
		
		Revisions:
			- 20130121@Dan: change linked server DB052 to DBEAS, Write log on DBTXN server in case of DBLOG server failure
			- 20130513@Lukas: fix bug - admin cannot reset his password because of checking permission
			- 20190502@Kan: DBPOL/NAP_UserControl Migration, Move sp from DBEAS/bodb_EAS to DBPOL/NAP_UserControl [Redmine: #111865]

		Parameter's Explanation:
	*/
SET NOCOUNT ON

	DECLARE @startRun datetime  
		,@endRun datetime  
		,@duration int		
	
	SET @startRun=GETDATE()
	
	IF @UserID <> @CustID
	BEGIN
		EXEC NAP_UserControl.dbo.EAS_UserCheckPermission @UserID = @userID ,@FuncKey = 'ManageUser', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT	
		IF @ErrCode > 0
			RETURN
	END

	DECLARE @db_userpwd NVARCHAR(50)
	
	SELECT @db_userpwd = userpwd FROM Customer WITH(NOLOCK) WHERE custid = @custid
	
	IF @@ROWCOUNT = 0
	BEGIN
		SELECT @ErrMsg = 'This user does not exist',
				@ErrCode = 100
		RETURN		
	END
	
	IF @db_userpwd = @userpwd
		RETURN	
					
	DECLARE @PwdExpiry DATETIME

	SELECT @pwdexpiry = DATEADD(dd, 30, GETDATE())

	UPDATE customer  with (ROWLOCK, UPDLOCK)
	SET userpwd=@UserPwd, pwdexpiry=@PwdExpiry 
	WHERE custid=@CustID
		
	DECLARE @LogData NVARCHAR(MAX)
	SELECT @LogData = '<EAS_UserInfoUpdUserPwd>' + 				
						'<CustID>' + COALESCE(CAST(@CustID AS Varchar(50)),'') + '</CustID>' + 
						'<IP>' + COALESCE(@IP,'') + '</IP>' + 
					'</EAS_UserInfoUpdUserPwd>'
				
	SET @endRun = GETDATE()  
	SET @duration  = DATEDIFF (MILLISECOND,@startRun,@endRun)

	--Write log in IBC
	EXEC NAP_UserControl.[dbo].[WriteLog_UserLog_RunSP_Wrapper]
		@UserID			= @UserID, 
		@CustID			= @CustID,				
		@ActionID		= 20301, 
		@TrackingValue	= @LogData, 
		@duration		= @duration

	--Write log in EAS
	EXEC NAP_UserControl.[dbo].[EAS_WriteLog_UserLog_RunSP_Wrapper]
		@UserID			= @UserID, 
		@CustID			= @CustID,				
		@ActionID		= 20301, 
		@TrackingValue	= @LogData, 
		@duration		= @duration
GO
