/*<info serverAlias="DBCUST-AgencyCashService" executers="wsv_CashService"  viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Age_CashService_PaymentMethod_Config
	@CustID                 INT,            -- SMA_ID Input
	@ProviderID             SMALLINT,
	@TransactionType        TINYINT,
	@PaymentMethodID        SMALLINT,
	@ValidationResult       BIT,
	@SubAccID               INT             = 0,
	@IP                     VARCHAR(50)     = '',
	@Language               VARCHAR(2)      = 'E',
	@APIConfig              VARCHAR(500)    = NULL,
	@ErrCode                INT             = 0 OUTPUT,
	@ErrMsg                 NVARCHAR(1000)  = '' OUTPUT
AS
/*  
	Created By: Helios
	Created Date: 2025-04-18
	Description: Agency Cash Service - Insert Payment Methods
	DB: DBCust.AgencyCashService
	
	Revisions:
		- 20250321@Helios: Agency Cash Service [Redmine: #223896]
		- 20250724@Helios: Agency Cash Service -Customer Setting Sprint 7 [redmine: #233474]
		- 20250724@Helios: Agency Cash Service -Customer Setting Sprint 8 [redmine: #235266]  
	Param:
		DECLARE @p1 INT
		DECLARE @p2 NVARCHAR(1000)
		EXEC Age_CashService_PaymentMethod_Config @ErrCode	     =@p1 OUTPUT
									, @ErrMsg	     =@p2 OUTPUT
									, @ProviderID	     =1
									, @TransactionType =1
									, @PaymentMethodID =1
									, @ValidationResult=1
									, @APIConfig	     ='{"APIMethodKey":"5bxr2v89pUyN9qjUAUT9YQ","MerchantID":"3q423423423","AppSecret":"dasdasdsad"}'
									, @CustID	     =249550999
									, @SubAccID	     =0
									, @IP		     ='10.0.0.112'
									, @Language	     ='E'
		SELECT @p1 , @p2


*/  
BEGIN
	SET NOCOUNT ON;
	DECLARE
		@startRun           DATETIME,
		@endRun             DATETIME,
		@DurationTime       INT;

	SET @startRun = GETDATE();
	SELECT @ErrCode = 0, @ErrMsg = '';

	DECLARE
		@CheckExists_ProviderAPIConfig   INT = NULL,
		@CheckExists_AgentPaymentMethod  INT = NULL,
		@PaymentMethodStatus		   TINYINT = NULL;

	DECLARE
		@MinAmount          MONEY,
		@MaxAmount          MONEY,
		@PaymentMethodEnable BIT;

	DECLARE @old_RetryAPIConfig TABLE
	(
		AgentID             INT,
		ProviderID          SMALLINT,
		MethodID            SMALLINT,
		TransactionType     TINYINT,
		APIConfig           VARCHAR(500),
		PaymentMethodStatus TINYINT
	);

	-- Hard code min/max/enable
	SELECT
		@MinAmount              = 100,
		@MaxAmount              = 5000,
		@PaymentMethodEnable    = 0;


	IF NOT EXISTS (SELECT TOP 1 1 FROM CashPaymentProvider cpp WITH (NOLOCK) WHERE cpp.ProviderID = @ProviderID)
	BEGIN
		SELECT  @ErrMsg = N'Invalid parameters', @ErrCode = 100;
		RETURN
	END

	IF dbo.f_IsValidProvider(@ProviderID) = 0
	BEGIN
		SET @ErrCode = 100;
		SET @ErrMsg = N'Invalid parameters';
		RETURN;
	END
	
	IF dbo.f_IsValidPaymentMethod(@PaymentMethodID) = 0
	BEGIN
		SET @ErrCode = 100;
		SET @ErrMsg = N'Invalid parameters';
		RETURN;
	END

	IF @ValidationResult IS NULL
	BEGIN
		SET @ErrCode = 100;
		SET @ErrMsg = N'Invalid parameters';
		RETURN;
	END
		
	-- Status API Payment Gateway return
	SELECT @PaymentMethodStatus = CASE 
							WHEN @ValidationResult = 0 THEN 2		-- API validate is 0 : Status Completed
							ELSE 3						-- API validate is <> 0 : Status Fail
						END

	SELECT @CheckExists_ProviderAPIConfig =  (SELECT Top 1 1 FROM CashPaymentProviderAPIConfig WITH (NOLOCK) WHERE AgentID = @CustID AND ProviderID = @ProviderID AND PaymentMethodID = @PaymentMethodID AND TransactionType = @TransactionType)
	SELECT @CheckExists_AgentPaymentMethod = (SELECT TOP 1 1 FROM CashAgentPaymentMethod WITH (NOLOCK) WHERE AgentID = @CustID AND ProviderID = @ProviderID AND PaymentMethodID = @PaymentMethodID  AND TransactionType = @TransactionType)

	-- Data not Exists , so return
	IF @CheckExists_ProviderAPIConfig IS NULL AND @CheckExists_AgentPaymentMethod IS NOT NULL
	BEGIN
		SELECT  @ErrMsg = N'Invalid parameters', @ErrCode = 101;
		RETURN
	END

	-- Existing record status has been updated.
	IF @CheckExists_ProviderAPIConfig IS NOT NULL AND @CheckExists_AgentPaymentMethod IS NOT NULL
	BEGIN
		-- Write log
		INSERT INTO @old_RetryAPIConfig 
		(
			  AgentID
			, ProviderID
			, MethodID
			, TransactionType
			, APIConfig
			, PaymentMethodStatus
		)
		SELECT
			AgentID
			, ProviderID
			, PaymentMethodID
			, TransactionType
			, APIConfig
			, PaymentMethodStatus
		FROM CashPaymentProviderAPIConfig cppa WITH (NOLOCK)
		WHERE AgentID = @CustID 
		AND ProviderID = @ProviderID 
		AND PaymentMethodID = @PaymentMethodID 
		AND TransactionType = @TransactionType


		--update values
		UPDATE cppa
			SET   cppa.PaymentMethodStatus = @PaymentMethodStatus,
				cppa.APIConfig = @APIConfig,
				RepUpdateTime = dbo.f_GetDateTime2()
		FROM CashPaymentProviderAPIConfig cppa WITH (NOLOCK)
		WHERE AgentID = @CustID 
		AND ProviderID = @ProviderID 
		AND PaymentMethodID = @PaymentMethodID 
		AND TransactionType = @TransactionType
	END

	-- No existing data found — proceeding to insert a new payment method
	IF @CheckExists_ProviderAPIConfig IS NULL AND @CheckExists_AgentPaymentMethod IS NULL
	BEGIN
		BEGIN TRY
			-- INIT FOR PAYMENT METHOD API CONFIG
			INSERT INTO CashPaymentProviderAPIConfig 
			(
				  AgentID
				, ProviderID
				, PaymentMethodID
				, TransactionType
				, APIConfig
				, PaymentMethodStatus
				, RepUpdateTime
			)
			SELECT
				@CustID,
				@ProviderID,
				@PaymentMethodID,
				@TransactionType,
				@APIConfig,
				@PaymentMethodStatus,
				dbo.f_GetDateTime2()
	
			-- INIT FOR SETTING PAYMENT METHOD
			INSERT INTO CashAgentPaymentMethod 
			(
				  ProviderID
				, PaymentMethodID
				, AgentID
				, TransactionType
				, MinAmount
				, MaxAmount
				, PaymentMethodEnable
				, RepUpdateTime
			)
			SELECT 
				@ProviderID				AS ProviderID,
				@PaymentMethodID			AS PaymentMethodID,
				@CustID				AS AgentID,
				@TransactionType			AS TransactionType,
				@MinAmount				AS MinAmount,
				@MaxAmount				AS MaxAmount,
				@PaymentMethodEnable		AS PaymentMethodEnable,
				dbo.f_GetDateTime2()
		END TRY
		BEGIN CATCH
			SELECT  @ErrMsg = N'Error when adding a new payment method'	, @ErrCode = 102 ;
			RETURN
		END CATCH
	END

	-- Insert Config Success
	IF (@@error = 0)
	BEGIN
		IF @PaymentMethodStatus = 3
		BEGIN
			SELECT  
				@ErrMsg = N'Payment provider is currently unavailable. Please try again later.',
				@ErrCode = 200 ;
		END
		ELSE
		BEGIN
			SELECT  
					@ErrMsg = N'Update Successful!',
					@ErrCode = 0 ;
		END
	END

	--START LOG 
	DECLARE @LogInfo_Tbl TABLE(UserID INT, CustID INT, ActionID INT, TrackingValue NVARCHAR(MAX), TrackingValue2 NVARCHAR(MAX), TrackingValueMask NVARCHAR(MAX), TrackingValueMask2 NVARCHAR(MAX), Duration INT)
	DECLARE @TrackingValue NVARCHAR(MAX), @TrackingValue2 NVARCHAR(MAX), @TrackingValueMask NVARCHAR(MAX), @TrackingValueMask2 NVARCHAR(MAX)
	DECLARE @xml XML, @ActionID INT
		SET @endRun = GETDATE ()
		SET @DurationTime = datediff (millisecond,@startRun,@endRun)

	DECLARE 
		@APIConfigXML	VARCHAR(1000),
		@APIConfigXML2	VARCHAR(1000),
		@ProviderName	NVARCHAR(100);

	SELECT @ProviderName = (SELECT ProviderName FROM CashPaymentProvider WITH (NOLOCK) WHERE ProviderID = @ProviderID)
	
	-- Existing record And Retry or Changed API Connection.
	IF @CheckExists_ProviderAPIConfig IS NOT NULL AND @CheckExists_AgentPaymentMethod IS NOT NULL
	BEGIN
		SET @ActionID = 305004

		-- LOG NEW VALUES FOR SETTING PAYMENT METHOD (XML style, always encode, handle empty APIConfig by REPLACE)
		SET @APIConfigXML = REPLACE(REPLACE(ISNULL(@APIConfig, ''), '"', '&quot;'), '"', '&quot;');
		SELECT @TrackingValueMask = '<Age_CashService_PaymentMethod_Config 
									CustID="' + CONVERT(VARCHAR(20), @CustID) + '" 
									SubAccName="' + CustDB.dbo.f_GetSubUsername(@SubAccID) + '" 
									IP="' + CONVERT(VARCHAR(50), @IP) + '" 
									AgentID="' + CONVERT(VARCHAR(20), @CustID) + '" 
									ProviderID="' + CONVERT(VARCHAR(10), @ProviderID) + '" 
									ProviderName="' + CONVERT(NVARCHAR(100), @ProviderName) + '" 
									PaymentMethodID="' + CONVERT(VARCHAR(10), @PaymentMethodID) + '" 
									TransactionType="' + CONVERT(VARCHAR(10), @TransactionType) + '" 
									APIConfig="' + @APIConfigXML + '" 
									PaymentMethodStatus="' + CONVERT(VARCHAR(10), @PaymentMethodStatus) + '" 
								/>';
		SET @TrackingValue = @TrackingValueMask;
		SELECT @TrackingValue = REPLACE(@TrackingValue, ISNULL(@APIConfigXML, ''), '');

		-- LOG NEW VALUES FOR PAYMENT METHOD API CONFIG (XML style, encode &quot;)
		SELECT @APIConfigXML2 = REPLACE(REPLACE((SELECT rt.APIConfig FROM @old_RetryAPIConfig rt), '"', '&quot;'), '"', '&quot;');
		SELECT @TrackingValueMask2 = '<Age_CashService_PaymentMethod_Config 
									CustID="' + CONVERT(VARCHAR(20), @CustID) + '" 
									SubAccName="' + CustDB.dbo.f_GetSubUsername(@SubAccID) + '" 
									IP="' + CONVERT(VARCHAR(50), @IP) + '" 
									AgentID="' + CONVERT(VARCHAR(20), (SELECT rt.AgentID FROM @old_RetryAPIConfig rt)) + '" 
									ProviderID="' + CONVERT(VARCHAR(10), (SELECT rt.ProviderID FROM @old_RetryAPIConfig rt)) + '" 
									ProviderName="' + CONVERT(NVARCHAR(100), @ProviderName) + '" 
									PaymentMethodID="' + CONVERT(VARCHAR(10), (SELECT rt.MethodID FROM @old_RetryAPIConfig rt)) + '" 
									TransactionType="' + CONVERT(VARCHAR(10), (SELECT rt.TransactionType FROM @old_RetryAPIConfig rt)) + '" 
									APIConfig="' + @APIConfigXML2 + '" 
									PaymentMethodStatus="' + CONVERT(VARCHAR(10), (SELECT rt.PaymentMethodStatus FROM @old_RetryAPIConfig rt)) + '" 
								/>';
		SET @TrackingValue2 = @TrackingValueMask2;
		SELECT @TrackingValue2 = REPLACE(@TrackingValue2, ISNULL(@APIConfigXML2, ''), '');

		INSERT INTO @LogInfo_Tbl (UserID, CustID, ActionID, TrackingValue, TrackingValue2 , TrackingValueMask, TrackingValueMask2, Duration)
		SELECT @CustID ,  @CustID , @ActionID , @TrackingValue , @TrackingValue2 , @TrackingValueMask , @TrackingValueMask2 , @DurationTime
	END

	-- New Connection API
	IF @CheckExists_ProviderAPIConfig IS NULL AND @CheckExists_AgentPaymentMethod IS NULL
	BEGIN
		SET @ActionID = 305005

		-- Log new values for Payment Method API Config (XML style, encode &quot;)
		SELECT @APIConfigXML = REPLACE(REPLACE(@APIConfig, '"', '&quot;'), '"', '&quot;');
		SELECT @TrackingValueMask = '<Age_CashService_PaymentMethod_Config 
									CustID="' + CONVERT(VARCHAR(20), @CustID) + '" 
									SubAccName="' + CustDB.dbo.f_GetSubUsername(@SubAccID) + '" 
									IP="' + CONVERT(VARCHAR(50), @IP) + '" 
									AgentID="' + CONVERT(VARCHAR(20), @CustID) + '" 
									ProviderID="' + CONVERT(VARCHAR(10), @ProviderID) + '" 
									ProviderName="' + CONVERT(NVARCHAR(100), @ProviderName) + '" 
									PaymentMethodID="' + CONVERT(VARCHAR(10), @PaymentMethodID) + '" 
									TransactionType="' + CONVERT(VARCHAR(10), @TransactionType) + '" 
									APIConfig="' + @APIConfigXML + '" 
									PaymentMethodStatus="' + CONVERT(VARCHAR(10), @PaymentMethodStatus) + '" 
								/>';

		SET @TrackingValue = @TrackingValueMask;
		SELECT @TrackingValue = REPLACE(@TrackingValue, ISNULL(@APIConfigXML, ''), '');

		INSERT INTO @LogInfo_Tbl (UserID, CustID, ActionID, TrackingValue, TrackingValue2 , TrackingValueMask, TrackingValueMask2, Duration)
		SELECT @CustID ,  @CustID , @ActionID , @TrackingValue , NULL , @TrackingValueMask , NULL , @DurationTime

		-- Log new values for setting Payment Method (XML style)
		SELECT @TrackingValueMask = '<Age_CashService_PaymentMethod_Config 
									CustID="' + CONVERT(VARCHAR(20), @CustID) + '" 
									SubAccName="' + CustDB.dbo.f_GetSubUsername(@SubAccID) + '" 
									IP="' + CONVERT(VARCHAR(50), @IP) + '" 
									AgentID="' + CONVERT(VARCHAR(20), @CustID) + '" 
									ProviderID="' + CONVERT(VARCHAR(10), @ProviderID) + '" 
									ProviderName="' + CONVERT(NVARCHAR(100), @ProviderName) + '" 
									PaymentMethodID="' + CONVERT(VARCHAR(10), @PaymentMethodID) + '" 
									TransactionType="' + CONVERT(VARCHAR(10), @TransactionType) + '" 
									MinAmount="' + CONVERT(VARCHAR(20), @MinAmount) + '" 
									MaxAmount="' + CONVERT(VARCHAR(20), @MaxAmount) + '" 
									PaymentMethodEnable="' + CONVERT(VARCHAR(10), @PaymentMethodEnable) + '" 
								/>';

	
		INSERT INTO @LogInfo_Tbl (UserID, CustID, ActionID, TrackingValue, TrackingValue2 , TrackingValueMask, TrackingValueMask2, Duration)
		SELECT @CustID ,  @CustID , @ActionID , @TrackingValueMask , NULL , @TrackingValueMask , NULL , @DurationTime
	END
	
	-- Return Data Object
	SELECT UserID, CustID, ActionID, TrackingValue, TrackingValue2, TrackingValueMask, TrackingValueMask2 , Duration
	FROM @LogInfo_Tbl
	
END
