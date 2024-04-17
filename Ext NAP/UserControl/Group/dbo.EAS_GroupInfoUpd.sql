/*<info serverAlias="DBPOL-NAP_UserControl" executers="wsv_xnap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_GroupInfoUpd]
	@UserID		INT,
	@GroupID		INT,
	@GroupName		NVARCHAR(100) = '',
	@Description	NVARCHAR(200) = NULL,
	@IP				VARCHAR(50),
	@ErrCode		INT = 0 OUTPUT,
	@ErrMsg			VARCHAR(500) = '' OUTPUT
AS
	/*
		Created: Dan
		Date: 2012-11-15
		Task: Update group info
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
	
	EXEC dbo.EAS_UserCheckPermission @UserID = @UserID ,@FuncKey = 'ManageGroup', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT
	
	IF @ErrCode > 0
		RETURN
		
	DECLARE @db_GroupName VARCHAR(100),
			@db_Description VARCHAR(200)	
	
	IF EXISTS (SELECT 1 
			FROM eaGroup WITH(NOLOCK)
			WHERE GroupName = @GroupName AND GroupID <> @GroupID
	)
	BEGIN
		SELECT @ErrMsg = 'This group''s name is in use',
				@ErrCode = 100
		RETURN
	END
	
	SELECT @db_GroupName = GroupName, @db_Description = Description
	FROM eaGroup WITH(NOLOCK)
	WHERE GroupID = @GroupID
		
	UPDATE eaGroup WITH(UPDLOCK,ROWLOCK)
	SET GroupName	 = @GroupName,
		Description = @Description		
	WHERE GroupID	 = @GroupID
	
	DECLARE @LogData NVARCHAR(500)	
	
	SELECT @LogData = 
					'<EAS_GroupInfoUpd>'+
						'<Groupname>'+
							'<Old>' + ISNULL([dbo].[f_EncodeXMLValue](@db_GroupName),'') + '</Old>' +
							'<New>' + ISNULL([dbo].[f_EncodeXMLValue](@GroupName),'') + '</New>' +
						'</Groupname>'+
						'<GroupDescription>'+
							'<Old>' + ISNULL([dbo].[f_EncodeXMLValue](@db_Description),'') + '</Old>' +
							'<New>' + ISNULL([dbo].[f_EncodeXMLValue](@Description),'') + '</New>' +
						'</GroupDescription>'+
					'</EAS_GroupInfoUpd>'				

	SET @endRun = GETDATE()  
	SET @duration  = DATEDIFF (MILLISECOND,@startRun,@endRun)   

	EXEC [dbo].[EAS_WriteLog_UserLog_UserControl_Wrapper]
			@custID = @GroupID,
			@TrackingValue = @LogData,
			@userid = @UserID,
			@TypeID = 0,
			@actionid = 20001,
			@duration = @Duration  
	
GO
