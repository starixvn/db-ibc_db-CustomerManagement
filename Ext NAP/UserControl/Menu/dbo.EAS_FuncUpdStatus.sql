/*<info serverAlias="DBPOL-NAP_UserControl" executers="bodbExtAccNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_FuncUpdStatus]
	@UserID	INT,
	@FuncID		INT,
	@isTest	BIT,
	@IP			VARCHAR(50),
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		VARCHAR(500) = '' OUTPUT
AS
	/*
		Created: Dan
		Date: 2012-11-21
		Task: Update status of function
		DB: DBPOL/NAP_UserControl
		
		Revisions:
			- 20190426@Kan: DBPOL/NAP_UserControl Migration, Move sp from DBEAS/bodb_EAS to DBPOL/NAP_UserControl [Redmine: #111865]
			
		Parameter's Explanation:
	*/
SET NOCOUNT ON
	DECLARE @startRun datetime  
		,@endRun datetime  
		,@duration int		
	
	SET @startRun=GETDATE()
	
	EXEC dbo.EAS_UserCheckPermission @UserID = @UserID ,@FuncKey = 'ManageMenu', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT
	
	IF @ErrCode > 0
		RETURN
	
	DECLARE @db_isTest BIT
	
	SELECT @db_isTest = isTest FROM dbo.eaFunction WITH(NOLOCK) WHERE FuncID = @FuncID
	
	IF @@ROWCOUNT = 0 OR @isTest = @db_isTest
		RETURN
		
	UPDATE eaFunction WITH(UPDLOCK,ROWLOCK)
	SET isTest = @isTest
	WHERE FuncID = @FuncID
	
	DECLARE @LogData NVARCHAR(500)
	SELECT @LogData = '<EAS_FuncUpdStatus>' +  
							'<FuncID>'+ ISNULL(CONVERT(VARCHAR(20),@FuncID),'') + '</FuncID>'+
							'<isTest>'+ 
								'<Old>' + ISNULL(cast(@db_isTest as varchar(10)),'') + '</Old>' +
								'<New>' + ISNULL(cast(@isTest as varchar(10)),'') + '</New>' +
							'</isTest>'+ 
							'<IP>' + COALESCE(@IP,'') + '</IP>'+
						'</EAS_FuncUpdStatus>'
	
	SET @endRun = GETDATE()  
	SET @duration  = DATEDIFF (MILLISECOND,@startRun,@endRun)   

	EXEC [dbo].[EAS_WriteLog_UserLog_UserControl_Wrapper]
			@custID = @FuncID,
			@TrackingValue = @LogData,
			@userid = @UserID,
			@TypeID = 2,
			@actionid = 20102,
			@duration = @duration 					
	
GO
