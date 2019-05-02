/*<info serverAlias="DBPOL-NAP_UserControl" executers="bodbExtAccNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_GroupInfoIns]
	@UserID		INT,
	@GroupName		VARCHAR(100),
	@Description	VARCHAR(200) = NULL,
	@IP				VARCHAR(50),
	@GroupID		INT = 0 OUTPUT,
	@ErrCode		INT = 0 OUTPUT,
	@ErrMsg			VARCHAR(500) = '' OUTPUT
AS
	/*
		Created: Dan
		Date: 2012-11-15
		Task: Create new group
		DB: DBPOL/NAP_UserControl
		
		Revisions:
			- 20190426@Kan: DBPOL/NAP_UserControl Migration, Move sp from DBEAS/bodb_EAS to DBPOL/NAP_UserControl [Redmine: #111865]
			
		Parameter's Explanation:
	*/
SET NOCOUNT ON

	DECLARE @startRun datetime,
			@endRun datetime,
			@duration int
	
	SET @startRun=GETDATE()
	
	EXEC dbo.EAS_UserCheckPermission @UserID = @UserID ,@FuncKey = 'ManageGroup', @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT
	
	IF @ErrCode > 0
		RETURN
	
	IF EXISTS (SELECT 1 FROM eaGroup WITH(NOLOCK) WHERE GroupName = @GroupName)
	BEGIN
		SELECT @ErrMsg = 'This group''s name is in use.',
				@ErrCode = 100
		RETURN
	END
	
	INSERT INTO eaGroup (GroupName, Description, CreatedDate, Creator)
	VALUES (@GroupName, @Description, GETDATE(), @UserID)
	
	SELECT @GroupID = SCOPE_IDENTITY()
	
	--Initial group policy
	INSERT INTO eaGroupPolicy (GroupID, FuncID, Policy)
	SELECT @GroupID, funcid, 0
	FROM eaFunction WITH(NOLOCK)	
	
	DECLARE @LogData nvarchar(500)	
	SELECT @LogData = '<EAS_GroupInfoIns><GroupName>' + ISNULL([dbo].[f_EncodeXMLValue](@GroupName),'') + '</GroupName>' +
										'<Description>' + ISNULL([dbo].[f_EncodeXMLValue](@Description),'') + '</Description>'  +
										'<IP>' + ISNULL(@IP,'') + '</IP>' 
					+ '</EAS_GroupInfoIns>'

	SET @endRun = getdate()  
	SET @duration  = datediff (millisecond,@startRun,@endRun)   

	EXEC [dbo].[EAS_WriteLog_UserLog_UserControl_Wrapper]
			@custID = @GroupID,
			@TrackingValue = @LogData,
			@userid = @UserID,
			@TypeID = 0,
			@actionid = 20000,
			@duration = @duration  

GO 
