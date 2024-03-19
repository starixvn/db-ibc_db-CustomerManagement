/*<info serverAlias="DBCUST-CustDB" executers="bodbDownlineNet,wsv_alp,bodbDownlineNetView,wsv_alpv" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CustLastBetFilter_Upd]
	-- Add the parameters for the stored procedure here
	  @CustID		INT
	, @SubAccId		INT = 0
	, @FilterID		INT
	, @FilterName	NVARCHAR(50)
	, @IsDefault	BIT=0
	, @Language		VARCHAR(2) = 'E'
	, @ErrCode		INT				= 0		OUTPUT
	, @ErrMsg		NVARCHAR(200)	= ''	OUTPUT
	, @IP			VARCHAR(20)		= ''
AS
/*
	Creator: 20230608@Tacy  
	Task : Update filter name and default filter on Last Bet func
	DB: DBCUST/CustDB

	Revisions:  
		- 20230608@Tacy: Alpha - Bet List - Enhance Last bet function [Redmine:#186142]

	Param's Explanation: 
*/
BEGIN
	SET NOCOUNT ON;

	--Not input filter name
	IF @FilterName=''
	BEGIN
		SELECT @ErrCode=90023
		SELECT @ErrMsg = CASE @Language WHEN 'E' THEN 'Please enter filter name' 
												 ELSE [dbo].[f_Get_MsgNamebyMsgID](90023,@Language)    
												 END 
		RETURN
	END

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
			, @logSpData_old NVARCHAR(MAX)
			, @FilterName_old NVARCHAR(50)

	SET @StartRun=GETDATE()

	SELECT @FilterName_old=FilterName
	FROM Cust_LastBetFilter WITH (NOLOCK)
	WHERE CustID=@CustID AND SubAccId=@SubAccId AND FilterID=@FilterID

	--Exists @FilterName
	IF (@FilterName_old<>@FilterName 
		AND EXISTS (SELECT 1 FROM Cust_LastBetFilter WITH (NOLOCK) WHERE CustID=@CustID AND SubAccId=@SubAccId AND FilterName=@FilterName))
	BEGIN
		SELECT @ErrCode=90020
		SELECT @ErrMsg = CASE @Language WHEN 'E' THEN 'Filter name already exists.' 
												 ELSE [dbo].[f_Get_MsgNamebyMsgID](90020,@Language)    
												 END 
		RETURN
	END
	
	SELECT @logSpData_old = (
		SELECT CustID
			, SubAccId
			, FilterName
			, FilterValue
			, IsDefault
			, COALESCE (CAST (@IP AS VARCHAR(20)), SPACE (1)) AS IP
		FROM Cust_LastBetFilter WITH (NOLOCK)
		WHERE CustID=@CustID AND SubAccId=@SubAccId AND FilterID=@FilterID
		FOR XML RAW('Root'))

	BEGIN TRY
		IF @IsDefault=1
		AND EXISTS (SELECT 1 FROM Cust_LastBetFilter WITH (NOLOCK) WHERE CustID=@CustID AND SubAccId=@SubAccId AND IsDefault=1)
		BEGIN
			UPDATE Cust_LastBetFilter WITH (ROWLOCK, UPDLOCK)
			SET IsDefault=0
			WHERE CustID=@CustID AND SubAccId=@SubAccId AND IsDefault=1
		END
		
		UPDATE Cust_LastBetFilter WITH (ROWLOCK, UPDLOCK)
		SET FilterName=@FilterName, IsDefault=@IsDefault
		WHERE CustID=@CustID AND SubAccId=@SubAccId AND FilterID=@FilterID
	END TRY
	BEGIN CATCH
		SELECT  @ErrCode = ERROR_NUMBER(),@ErrMsg = ERROR_MESSAGE();		
		RETURN
	END CATCH

	SELECT @logSpData = (
		SELECT CustID
			, SubAccId
			, FilterName
			, FilterValue
			, IsDefault
			, COALESCE (CAST (@IP AS VARCHAR(20)), SPACE (1)) AS IP
		FROM Cust_LastBetFilter WITH (NOLOCK)
		WHERE CustID=@CustID AND SubAccId=@SubAccId AND FilterID=@FilterID
		FOR XML RAW('Root'))

	--Write Log:
	SELECT @EndRun	= GETDATE(), @Duration = DATEDIFF(MILLISECOND, @StartRun, @EndRun)
	
	EXEC  Acc_WriteLog_UserLog_RunSP_Wrapper
					@UserID = @CustID,
					@CustID = @CustID,
					@ActionID = 6104,
					@TrackingValue = @LogSPData,
					@TrackingValue2 = @logSpData_old,
					@duration = @Duration
END
GO