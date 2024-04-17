/*<info serverAlias="DBCUST-CustDB" executers="wsv_alp" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_ManageAPI_Del]
	-- Add the parameters for the stored procedure here
	  @CustID		INT
	, @APIkey	VARCHAR(200)
	, @ErrCode	INT				= 0		OUTPUT
	, @ErrMsg	NVARCHAR(200)	= ''	OUTPUT
	, @IP		VARCHAR(20)		= ''
AS
/*
	Task : Alpha - API Management - Support data through API
	DB: DBCUST/CustDB
	Original: 
	Revisions:
		- 20221026@Tacy: Create SP [Redmine: #171247]

	Param's Explanation: 
		- @ScopeList:	1 - Outstanding Report
						2 - Win Loss Detail Report
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE	  @StartRun		DATETIME
			, @EndRun		DATETIME
			, @Duration		INT
			, @logSpData	NVARCHAR(MAX)

	IF @APIkey IS NULL
		RETURN

	SET @StartRun=GETDATE()

	SELECT @logSpData = (
		SELECT DISTINCT 
				APIName, CreatedDate, 
				CASE WHEN ExpiredDate IS NULL THEN 'NULL' ELSE CAST(ExpiredDate AS varchar) END ExpiredDate,
				APIKey, REPLACE(ScopeIDList,',',';') AS ScopeName,
				COALESCE (CAST (@IP AS VARCHAR(20)), SPACE (1)) AS IP
		FROM APIInfo WITH (NOLOCK) 
		WHERE APIKey=@APIkey
		FOR XML RAW('API'))

	--Revoke exists API
	BEGIN TRY
		IF EXISTS (SELECT 1 FROM APIInfo WITH (NOLOCK) WHERE APIKey=@APIkey)
		BEGIN
			DELETE FROM APIInfo WITH (ROWLOCK) WHERE APIKey=@APIkey
		END
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = @@ERROR, @ErrMsg = ERROR_MESSAGE()
		RETURN
	END CATCH

	--Write Log:
	SELECT @EndRun	= GETDATE(), @Duration = DATEDIFF(MILLISECOND, @StartRun, @EndRun)
	
	EXEC  Acc_WriteLog_UserLog_RunSP_Wrapper
					@UserID = @CustID,
					@CustID = @CustID,
					@ActionID = 6102,
					@TrackingValue = @LogSPData,
					@duration = @Duration

END
GO