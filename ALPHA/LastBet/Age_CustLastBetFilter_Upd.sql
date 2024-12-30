/*<info serverAlias="DBCUST-CustDB" executers="wsv_alp,wsv_alpv" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CustLastBetFilter_Upd]
	-- Add the parameters for the stored procedure here
	  @CustID		INT
	, @SubAccId		INT = 0
	, @FilterID		INT
	, @FilterName	NVARCHAR(50)
	, @IsDefault	BIT=0
	, @IsNotify		BIT
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
		- 20240223@Luke: Telegram Chatbot - Notify Member Last bets [Redmine: #193689]
		- 20241230@Aries: Scale Out DBCUST - Apply Inhouse replication for the remaning tables [Redmine: #215627]

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

	--Check if enable Telegram notification for more than 3 filters 
	DECLARE @IsNotify_Old BIT = 0
	SELECT @IsNotify_Old = IsNotify 
	FROM Cust_LastBetFilter WITH (NOLOCK)
	WHERE CustID = @CustID AND SubAccID = @SubAccId AND FilterID = @FilterID

	IF @IsNotify = 1 AND @IsNotify <> @IsNotify_Old
		AND EXISTS (
			SELECT COUNT(1) AS NotifyCount
			FROM Cust_LastBetFilter WITH (NOLOCK)
			WHERE CustID = @CustID AND SubAccID = @SubAccId AND IsNotify = 1
			HAVING COUNT(1) > 2
		)
	BEGIN
		SELECT @ErrCode = 90027
				,@ErrMsg = CASE @Language WHEN 'E' THEN 'The number of notification filters has exceeded the maximum limit of 3.'
												 ELSE [dbo].[f_Get_MsgNamebyMsgID](90027,@Language)
												 END
		RETURN
	END
	
	SELECT @logSpData_old = (
		SELECT CustID
			, SubAccId
			, FilterName
			, FilterValue
			, IsDefault
			, IsNotify
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
			   ,RepUpdateTime = dbo.f_GetDateTime2()
			WHERE CustID=@CustID AND SubAccId=@SubAccId AND IsDefault=1
		END
		
		UPDATE Cust_LastBetFilter WITH (ROWLOCK, UPDLOCK)
		SET FilterName=@FilterName, IsDefault=@IsDefault, IsNotify = @IsNotify,RepUpdateTime = dbo.f_GetDateTime2()
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
			, IsNotify
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