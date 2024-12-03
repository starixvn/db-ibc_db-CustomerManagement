/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_xnap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_UserInfoUpdAll]
	@userID	INT,
	@CustID		INT,		
	@firstname	NVARCHAR(50),
	@lastname	NVARCHAR(50),	
	@GroupID	INT,	
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
			- 20190502@Kan: DBPOL/NAP_UserControl Migration, Move sp from DBEAS/bodb_EAS to DBPOL/NAP_UserControl [Redmine: #111865]
			- 20240812@Tacy: Remove check permission on function [redmineID: #208402]
			- 20241210@Johnson: Apply In-house replication for Credit Setting [RedmineID: #212684]
		Parameter's Explanation:
	*/
SET NOCOUNT ON

	DECLARE @startRun datetime  
		,@endRun datetime  
		,@duration int		
	
	SET @startRun=GETDATE()
			
	DECLARE @db_firstname	NVARCHAR(50),			
			@db_lastname	NVARCHAR(50)
	
	SELECT @db_firstname = firstname, 
		@db_lastname = lastname
	FROM Customer WITH(NOLOCK)
	WHERE CustID = @CustID
	
	IF @@ROWCOUNT = 0 
	BEGIN
		SELECT @ErrMsg = 'This user does not exist',
				@ErrCode = 100
		RETURN
	END		
		
	EXEC NAP_UserControl.dbo.EAS_UserInfoUpdUserGroup 
		@userID = @userID,
		@CustID	 = @CustID,
		@GroupID = @GroupID,
		@IP		 = @IP,
		@ErrCode = @ErrCode OUTPUT,
		@ErrMsg	 = @ErrMsg OUTPUT
	
	IF @ErrCode > 0
		RETURN	
	
	IF @db_firstname != @firstname OR @db_lastname != @lastname
	BEGIN				
		UPDATE Customer WITH(UPDLOCK,ROWLOCK)
		SET firstname = @firstname,
			lastname = @lastname,
			RepUpdateTime = dbo.f_GetDateTime2()
		WHERE CustID = @CustID
	END	
	
	DECLARE @LogData NVARCHAR(500)
	SELECT @LogData = '<EAS_UserInfoUpdAll>' + 
						'<FirstName>' + 
							'<Old>' + COALESCE(@db_firstname,'') + '</Old>' +
							'<New>' + COALESCE(@firstname,'') + '</New>' +
						'</FirstName>' + 	
						'<LastName>' + 
							'<Old>' + COALESCE(@db_lastname,'') + '</Old>' +
							'<New>' + COALESCE(@lastname,'') + '</New>' +
						'</LastName>' + 
						'<IP>' + COALESCE(@IP,'') + '</IP>' + 
					'</EAS_UserInfoUpdAll>'
				
	SET @endRun = GETDATE()  
	SET @duration  = DATEDIFF (MILLISECOND,@startRun,@endRun)   
	
	EXEC NAP_UserControl.[dbo].[EAS_WriteLog_UserLog_UserControl_Wrapper]
		@custID = @CustID, 
		@TrackingValue = @LogData, 
		@userid = @userID, 
		@TypeID = 1, 
		@actionid = 20007, 
		@duration = @duration
GO 
