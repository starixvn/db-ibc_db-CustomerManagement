/*<info serverAlias="DBPOL-NAP_UserControl" executers="bodbExtAccNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_UserInfoUpdStatus]
	@userID	INT,
	@CustID		INT,
	@Enabled BIT, 	
	@IP			VARCHAR(50),
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		VARCHAR(500) = '' OUTPUT
AS
	/*
		Created: Dan
		Date: 2012-11-20
		Task: Update user's enable status
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
	
	DECLARE @db_enabled BIT
	
	SELECT @db_enabled = enabled FROM eaUserInfo WITH(NOLOCK) WHERE userid = @CustID
	
	IF @@ROWCOUNT = 0
	BEGIN
		SELECT @ErrMsg = 'This user does not exist',
				@ErrCode = 100
		RETURN		
	END
	
	IF @db_enabled = @enabled
		RETURN			
	
	UPDATE eaUserInfo WITH(UPDLOCK,ROWLOCK) 
	SET Enabled = @Enabled
	WHERE UserID = @CustID
	
	DECLARE @LogData NVARCHAR(500)
    SELECT @LogData =	'<EAS_UserInfoUpdStatus>' + 
							'<Enabled>'+ 
								'<Old>' + COALESCE(CONVERT(VARCHAR(10),@db_Enabled),'') + '</Old>' +
								'<New>' + COALESCE(CONVERT(VARCHAR(10),@Enabled),'') + '</New>' +
							'</Enabled>'+ 
							'<IP>' + COALESCE(@IP,'') + '</IP>' + 
						'</EAS_UserInfoUpdStatus>'

    SET @endRun = GETDATE();
    SET @Duration = DATEDIFF(millisecond, @startRun, @endRun);

    EXEC [dbo].[EAS_WriteLog_UserLog_UserControl_Wrapper] 
		@custID = @CustID, 
		@TrackingValue = @LogData, 
		@userid = @userID, 
		@TypeID = 1, 
		@actionid = 20300, 
		@duration = @Duration
	
GO
