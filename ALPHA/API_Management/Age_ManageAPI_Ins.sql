/*<info serverAlias="DBCUST-CustDB" executers="bodbDownlineNet,wsv_alp" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_ManageAPI_Ins]
	-- Add the parameters for the stored procedure here
	  @CustID		INT
	, @APIName		VARCHAR(50)
	, @PassPhrase	VARCHAR(200)
	, @ExpiredDate	DATETIME=NULL
	, @ScopeIDList	VARCHAR(50)
	, @APIkey		VARCHAR(200)
	, @APIsecret	VARCHAR(200)
	, @Language		VARCHAR(2) = 'E'
	, @ErrCode		INT				= 0		OUTPUT
	, @ErrMsg		NVARCHAR(200)	= ''	OUTPUT
	, @IP			VARCHAR(20)		= ''
AS
/*
	Task : Alpha - API Management - Support data through API
	DB: DBCUST/CustDB
	Original: 
	Revisions:
		- 20221026@Tacy: Create SP [Redmine: #171247]

	Param's Explanation: 
		- @ScopeIDList:	1 - Outstanding Report
						2 - Win Loss Detail Report
*/
BEGIN
	SET NOCOUNT ON;
	
	IF @CustID IS NULL OR @APIkey IS NULL
		RETURN

	DECLARE   @cnt			TINYINT
			, @StartRun		DATETIME
			, @EndRun		DATETIME
			, @Duration		INT
			, @logSpData	NVARCHAR(MAX)

	SET @StartRun=GETDATE()
	
	--Exists APIName
	IF EXISTS (SELECT 1 FROM APIInfo WITH (NOLOCK) WHERE CustID=@CustID AND APIName=@APIName)
	BEGIN
		SET @ErrCode=100
		SELECT @ErrMsg = CASE @Language WHEN 'E' THEN  'The API Name already exists.' 
												ELSE [dbo].[f_Get_MsgNamebyMsgID](90018,@Language)    
												END 
		RETURN
	END

	--maximum number of APIkey
	SELECT @cnt=COUNT(APIKey)
	FROM APIInfo WITH (NOLOCK) 
	WHERE CustID=@CustID

	IF @cnt=5
	BEGIN
		SET @ErrCode=101
		SELECT @ErrMsg = CASE @Language WHEN 'E' THEN  'The maximum number of API keys has been exceeded.' 
												ELSE [dbo].[f_Get_MsgNamebyMsgID](90019,@Language)    
												END 
		RETURN
	END

	BEGIN TRY
		INSERT INTO APIInfo ([CustID], [APIName], [CreatedDate], [ExpiredDate], [ScopeIDList], [APIKey], [APISecret], [Passphrase])
		SELECT @CustID, @APIName, GETDATE(), @ExpiredDate, @ScopeIDList, @APIkey, @APIsecret, @PassPhrase
	END TRY
	BEGIN CATCH
		SELECT  @ErrCode = ERROR_NUMBER(),@ErrMsg = ERROR_MESSAGE();		
		RETURN
	END CATCH

	--Write log
	SELECT @logSpData = (
		SELECT DISTINCT 
				APIName, CreatedDate, 
				CASE WHEN ExpiredDate IS NULL THEN 'NULL' ELSE CAST(ExpiredDate AS varchar) END ExpiredDate,
				APIKey, REPLACE(ScopeIDList,',',';') AS ScopeName,
				COALESCE (CAST (@IP AS VARCHAR(20)), SPACE (1)) AS IP
		FROM APIInfo WITH (NOLOCK) 
		WHERE APIKey=@APIkey
		FOR XML RAW('API'))

	SELECT @EndRun	= GETDATE(), @Duration = DATEDIFF(MILLISECOND, @StartRun, @EndRun)

	EXEC  Acc_WriteLog_UserLog_RunSP_Wrapper
					@UserID = @CustID,
					@CustID = @CustID,
					@ActionID = 6100,
					@TrackingValue = @LogSPData,
					@duration = @Duration
END
GO
