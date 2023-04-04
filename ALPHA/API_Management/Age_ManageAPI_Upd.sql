/*<info serverAlias="DBCUST-CustDB" executers="bodbDownlineNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_ManageAPI_Upd]
	-- Add the parameters for the stored procedure here
	  @CustID		INT
	, @APIkey		VARCHAR(200)
	, @APIName		VARCHAR(50)
	, @ExpiredDate	DATETIME=NULL
	, @ScopeIDList	VARCHAR(50)
	, @Language VARCHAR(2) = 'E'
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
	
	IF @APIkey IS NULL OR @APIkey=''
		RETURN

	DECLARE   @StartRun		DATETIME
			, @EndRun		DATETIME
			, @Duration		INT
			, @logSpData	NVARCHAR(MAX)
			, @logSpData_Old NVARCHAR(MAX)=NULL
			, @APIName_old	VARCHAR(50)

	SET @StartRun=GETDATE()

	SELECT @APIName_old=APIName
	FROM APIInfo WITH (NOLOCK)
	WHERE APIKey=@APIkey

	--Exists APIName
	IF (@APIName_old<>@APIName AND EXISTS (SELECT 1 FROM APIInfo WITH (NOLOCK) WHERE CustID=@CustID AND APIName=@APIName))
	BEGIN
		SET @ErrCode=100
		SELECT @ErrMsg = CASE @Language WHEN 'E' THEN  'The API Name already exists.' 
												ELSE [dbo].[f_Get_MsgNamebyMsgID](90018,@Language)    
												END
		RETURN
	END

	BEGIN TRY
		SELECT @logSpData_Old = (
			SELECT DISTINCT 
					APIName, CreatedDate, 
					CASE WHEN ExpiredDate IS NULL THEN 'NULL' ELSE CAST(ExpiredDate AS varchar) END ExpiredDate,
					APIKey, REPLACE(ScopeIDList,',',';') AS ScopeName,
					COALESCE (CAST (@IP AS VARCHAR(20)), SPACE (1)) AS IP
			FROM APIInfo api WITH (NOLOCK) 
			WHERE APIKey=@APIkey
			FOR XML RAW('API'))

		UPDATE APIInfo WITH (ROWLOCK, UPDLOCK)
		SET	  APIName=@APIName
			, ExpiredDate=@ExpiredDate
			, ScopeIDList=@ScopeIDList
		WHERE APIKey=@APIkey
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
				APIKey, REPLACE(@ScopeIDList,',',';') AS ScopeName,
				COALESCE (CAST (@IP AS VARCHAR(20)), SPACE (1)) AS IP
		FROM APIInfo api WITH (NOLOCK) 
		WHERE APIKey=@APIkey
		FOR XML RAW('API'))

	SELECT @EndRun	= GETDATE(), @Duration = DATEDIFF(MILLISECOND, @StartRun, @EndRun)

	EXEC  Acc_WriteLog_UserLog_RunSP_Wrapper
					@UserID = @CustID,
					@CustID = @CustID,
					@ActionID = 6101,
					@TrackingValue = @LogSPData,
					@TrackingValue2 = @logSpData_Old,
					@duration = @Duration
END
GO
