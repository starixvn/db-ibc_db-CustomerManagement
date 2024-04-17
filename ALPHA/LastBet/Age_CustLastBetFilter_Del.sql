/*<info serverAlias="DBCUST-CustDB" executers="wsv_alp,wsv_alpv" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CustLastBetFilter_Del]
	-- Add the parameters for the stored procedure here
	  @CustID		INT
	, @SubAccId		INT = 0
	, @FilterID		INT
	, @Language		VARCHAR(2) = 'E'
	, @ErrCode		INT				= 0		OUTPUT
	, @ErrMsg		NVARCHAR(200)	= ''	OUTPUT
	, @IP			VARCHAR(20)		= ''
AS
/*
	Creator: 20230608@Tacy  
	Task : Delete filter on Last Bet func
	DB: DBCUST/CustDB

	Revisions:  
		- 20230608@Tacy: Alpha - Bet List - Enhance Last bet function [Redmine:#186142]

	Param's Explanation: 
*/
BEGIN
	SET NOCOUNT ON;

	IF @FilterID IS NULL OR @FilterID=0
		RETURN
	
	--not agent's filter
	IF NOT EXISTS (SELECT 1 FROM Cust_LastBetFilter WITH (NOLOCK) WHERE CustID=@CustID AND SubAccId=@SubAccId AND FilterID=@FilterID)
	BEGIN
		SELECT @ErrCode=90026
		SELECT @ErrMsg = CASE @Language WHEN 'E' THEN 'This filter is not available' 
												 ELSE [dbo].[f_Get_MsgNamebyMsgID](90026,@Language)    
												 END 
		RETURN
	END

	DECLARE	  @StartRun		DATETIME
			, @EndRun		DATETIME
			, @Duration		INT
			, @logSpData	NVARCHAR(MAX)
	
	SET @StartRun=GETDATE()

	SELECT @logSpData = (
		SELECT CustID
			, SubAccId
			, FilterName
			, FilterValue
			, IsDefault
			, COALESCE (CAST (@IP AS VARCHAR(20)), SPACE (1)) AS IP
		FROM Cust_LastBetFilter WITH (NOLOCK)
		WHERE CustID=@CustID AND SubAccID=@SubAccId AND FilterID=@FilterID
		FOR XML RAW('Root'))

	BEGIN TRY
		DELETE FROM Cust_LastBetFilter WITH (ROWLOCK)
		WHERE CustID=@CustID AND SubAccID=@SubAccId AND FilterID=@FilterID
	END TRY
	BEGIN CATCH
		SELECT  @ErrCode = ERROR_NUMBER(),@ErrMsg = ERROR_MESSAGE();		
		RETURN
	END CATCH

	--Write Log:
	SELECT @EndRun	= GETDATE(), @Duration = DATEDIFF(MILLISECOND, @StartRun, @EndRun)
	
	EXEC  Acc_WriteLog_UserLog_RunSP_Wrapper
					@UserID = @CustID,
					@CustID = @CustID,
					@ActionID = 6105,
					@TrackingValue = @LogSPData,
					@duration = @Duration
END
GO