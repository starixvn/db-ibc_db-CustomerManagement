/*<info serverAlias="DBPOL-NAP_UserControl" executers="bodbExtAccNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_MenuDel]
	@UserID		INT,
	@MenuID		INT,		
	@IP			VARCHAR(50) = '',
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		VARCHAR(500) = '' OUTPUT
AS
	/*
		Created: Dan
		Date: 2012-11-21
		Task: Delete menu
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
	
	EXEC dbo.EAS_UserCheckPermission @UserID = @UserID ,@FuncKey = 'ManageMenu', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT
	
	IF @ErrCode > 0
		RETURN
			
	DELETE eaMenu WITH (ROWLOCK)	
	WHERE MenuID = @MenuID
	
	DELETE eaMenu WITH (ROWLOCK)	
	WHERE ParentID = @MenuID
	
	DECLARE @LogData NVARCHAR(500)
	SELECT @LogData = '<EAS_MenuDel>' +  
							'<MenuID>'+ ISNULL(CONVERT(VARCHAR(20),@MenuID),'') + '</MenuID>'+							
							'<IP>' + COALESCE(@IP,'') + '</IP>'+
						'</EAS_MenuDel>'
	
	SET @endRun = GETDATE()  
	SET @duration  = DATEDIFF (MILLISECOND,@startRun,@endRun)   

	EXEC [dbo].[EAS_WriteLog_UserLog_UserControl_Wrapper]
			@custID = @MenuID,
			@TrackingValue = @LogData,
			@userid = @UserID,
			@TypeID = 2,
			@actionid = 20106,
			@duration = @duration 
	
GO
