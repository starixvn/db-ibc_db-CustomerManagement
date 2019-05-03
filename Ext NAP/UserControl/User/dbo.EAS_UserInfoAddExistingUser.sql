/*<info serverAlias="DBPOL-NAP_UserControl" executers="bodbExtAccNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_UserInfoAddExistingUser]
	@userID		INT,
	@Username	VARCHAR(50),
	@custid		INT = 0 OUTPUT,
	@groupid	INT,
	@IP			VARCHAR(50),
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		VARCHAR(500) = '' OUTPUT
AS
/*
	Created: Dan
	Date: 2012-11-19
	Task: Add EAS's user from IBC
	DB: DBPOL/NAP_UserControl
	
	Revisions:
		- 20190502@Kan: DBPOL/NAP_UserControl Migration, Move sp from DBEAS/bodb_EAS to DBPOL/NAP_UserControl [Redmine: #111865]
		
	Parameter's Explanation:
*/
SET NOCOUNT ON

	DECLARE @startRun datetime  
		,@endRun datetime  
		,@duration int		
	
	SET @startRun=GETDATE()
	
	EXEC dbo.EAS_UserCheckPermission @UserID = @userID ,@FuncKey = 'ManageUser', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT
	
	IF @ErrCode > 0
		RETURN
	DECLARE @roleid INT
	
	SELECT @custid = custid, @roleid = roleid
	FROM CUSTDB.dbo.Customer WITH(NOLOCK) 
	WHERE username = @username
	
	IF ISNULL(@custid,0) = 0
	BEGIN
		SELECT @ErrMsg = 'Invalid username.',
				@ErrCode = 100
		RETURN
	END
	
	IF @roleid < 5
	BEGIN
		SELECT @ErrMsg = 'This user is not admin',
			@ErrCode = 101
		RETURN
	END
	
	IF EXISTS (SELECT 1 FROM eaUserInfo WITH(NOLOCK) WHERE UserID = @CustID)
	BEGIN
		SELECT @ErrMsg = 'This user exists in system',
				@ErrCode = 102
		RETURN		
	END
	
	IF NOT EXISTS (SELECT 1 FROM eaGroup WITH(NOLOCK) WHERE GroupID = @GroupID)
	BEGIN
		SELECT @ErrMsg = 'Invalid group',
				@ErrCode = 103
		RETURN
	END
	
	INSERT INTO eaUserInfo (UserID, GroupID, enabled, creator, CreatedDate)
	VALUES (@custid, @groupid, 1, @userID, current_timestamp)
	
	
	DECLARE @LogData NVARCHAR(500)
	
	SELECT @LogData = '<EAS_UserInfoAddExistingUser>'+
						'<GroupID>' + COALESCE(CONVERT(VARCHAR(10),@GroupID),'') + '</GroupID>'+
						'<IP>' + COALESCE(@IP,'') + '</IP>' +
				  '</EAS_UserInfoAddExistingUser>'				

	SET @endRun = GETDATE()  
	SET @duration  = DATEDIFF (MILLISECOND,@startRun,@endRun)   

	EXEC [dbo].[EAS_WriteLog_UserLog_UserControl_Wrapper] 
		@custID = @custid, 
		@TrackingValue = @LogData, 
		@userid = @userID, 
		@TypeID = 1, 
		@actionid = 20005, 
		@duration = @duration
	
GO
