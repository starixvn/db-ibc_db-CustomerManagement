/*<info serverAlias="DBCUST-AgencyCashService" executers="wsv_CashService"  viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Age_CashService_PaymentMethod_Config
	@CustID			INT,			-- SMA_ID Input
	@ProviderID			SMALLINT,
	@TransactionType		TINYINT,
	@PaymentMethodID		SMALLINT,
	@SubAccID			INT				= 0,
	@IP				VARCHAR(50)			= '',
	@Language			VARCHAR(2)			= 'E',
	@APIConfig			VARCHAR(500)		= NULL,
	@ErrCode			INT				= 0		OUTPUT,
	@ErrMsg			NVARCHAR(1000)		= ''		OUTPUT
AS 
/*  
	Created By: Helios
	Created Date: 2025-04-18
	Description: Agency Cash Service - Insert Payment Methods
	DB: DBCust.AgencyCashService
	
	Revisions:
		- 20250321@Helios: Agency Cash Service [Redmine: #223896]

	Param:
		DECLARE @p4 INT , @p5 NVARCHAR(1000)

		exec Age_CashService_PaymentMethod_Config_UAT2	@CustID		= 112768911 , 
										@ProviderID		= 1,
										@TransactionType  = 0,
										@PaymentMethodID	= 1,
										@APIConfig		= 'Xg7@bW#9!vLp$qMz*T',
										@ErrCode		= @p4 OUTPUT,
										@ErrMsg		= @p5 OUTPUT

		SELECT @p4 , @p5

*/  
BEGIN
	SET NOCOUNT ON;

	DECLARE 
		@startRun		DATETIME ,
		@endRun		DATETIME ,
		@DurationTime	INT
	
	SET @startRun = GETDATE ()
	SELECT @ErrCode = 0 , @ErrMsg = '' 

	DECLARE @CheckExists_ProviderAPIConfig INT = NULL , @CheckExists_AgentPaymentMethod INT = NULL
	
	DECLARE @PaymentMethodStatus TINYINT
	DECLARE @MinAmount MONEY , @MaxAmount MONEY , @PaymentMethodEnable BIT

	DECLARE @old_RetryAPIConfig TABLE (
		AgentID			INT,
		ProviderID			SMALLINT,
		MethodID			SMALLINT,
		TransactionType		TINYINT,
		APIConfig			VARCHAR(500),
		PaymentMethodStatus	TINYINT
	)

	--hard code
	SELECT 
		@PaymentMethodStatus	= 1,		-- 1 AS Processing
		@MinAmount			= 100,
		@MaxAmount			= 5000,
		@PaymentMethodEnable	= 0


	IF NOT EXISTS (SELECT TOP 1 1 FROM CashPaymentProvider cpp WITH (NOLOCK) WHERE cpp.ProviderID = @ProviderID)
	BEGIN
		SELECT  @ErrMsg = N'Invalid Provider Input' , @ErrCode = 100 ;	
		RETURN
	END

	IF dbo.f_IsValidProvider(@ProviderID) = 0
	BEGIN
	    SET @ErrCode = 100;
	    SET @ErrMsg = N'Invalid Provider Input';
	    RETURN;
	END
	
	IF dbo.f_IsValidPaymentMethod(@PaymentMethodID) = 0
	BEGIN
	    SET @ErrCode = 100;
	    SET @ErrMsg = N'Invalid PaymentMethod Input';
	    RETURN;
	END
		
	SELECT @CheckExists_ProviderAPIConfig = (SELECT PaymentMethodStatus FROM CashPaymentProviderAPIConfig WITH (NOLOCK) WHERE AgentID = @CustID AND ProviderID = @ProviderID AND PaymentMethodID = @PaymentMethodID AND TransactionType = @TransactionType)
	SELECT @CheckExists_AgentPaymentMethod = (SELECT TOP 1 1 FROM CashAgentPaymentMethod WITH (NOLOCK) WHERE AgentID = @CustID AND ProviderID = @ProviderID AND PaymentMethodID = @PaymentMethodID  AND TransactionType = @TransactionType)

	-- Data Exists , so return
	IF @CheckExists_ProviderAPIConfig IN (1,2,4) AND @CheckExists_AgentPaymentMethod = 1
	BEGIN
		SELECT  @ErrMsg = N'Invalid Values Input or Data Existing'	, @ErrCode = 101 ;	
		RETURN
	END

	-- Existing record found with status 'Fail' — status has been updated.
	IF @CheckExists_ProviderAPIConfig = 3 AND @CheckExists_AgentPaymentMethod = 1
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
		AND cppa.PaymentMethodStatus = @CheckExists_ProviderAPIConfig


		--update values
		UPDATE cppa
			SET cppa.PaymentMethodStatus = @PaymentMethodStatus,
			    cppa.APIConfig = @APIConfig,
			    RepUpdateTime = dbo.f_GetDateTime2()
		FROM CashPaymentProviderAPIConfig cppa WITH (NOLOCK)
		WHERE AgentID = @CustID 
		AND ProviderID = @ProviderID 
		AND PaymentMethodID = @PaymentMethodID 
		AND TransactionType = @TransactionType
		AND cppa.PaymentMethodStatus = @CheckExists_ProviderAPIConfig
	END

	-- No existing data found — proceeding to insert a new payment method
	IF ISNULL(@CheckExists_ProviderAPIConfig, 0) = 0 AND ISNULL(@CheckExists_AgentPaymentMethod, 0) = 0
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

	IF (@@error = 0)
	BEGIN
		SELECT  
			@ErrMsg = N'Update Successful!',
			@ErrCode = 0 ;
	END

	--START LOG 
	DECLARE @LogInfo_Tbl TABLE(UserID INT, CustID INT, ActionID INT, TrackingValue VARCHAR(MAX), TrackingValue2 VARCHAR(MAX) , Duration INT )
	DECLARE @TrackingValue VARCHAR(MAX), @TrackingValue2 VARCHAR(MAX)
	DECLARE @xml XML, @ActionID INT
		SET @endRun = GETDATE ()
		SET @DurationTime = datediff (millisecond,@startRun,@endRun)

	
	-- Existing record found with status 'Fail' — status has been updated.
	IF @CheckExists_ProviderAPIConfig = 3 AND @CheckExists_AgentPaymentMethod = 1
	BEGIN
		SET @ActionID = 305004

		-- LOG NEW VALUES FOR PAYMENT METHOD API CONFIG 
		SET @xml = (
		SELECT	@CustID                         AS '@CustID',
				CustDB.dbo.f_GetSubUsername(@SubAccID) AS '@SubAccName',
				@IP                             AS '@IP',
				(
					SELECT	rt.AgentID					 AS '@CustID',
							rt.ProviderID				 AS '@ProviderID',
							rt.MethodID					 AS '@PaymentMethodID',
							rt.TransactionType			 AS '@TransactionType',
							rt.APIConfig				 AS '@APIConfig',
							rt.PaymentMethodStatus			 AS '@PaymentMethodStatus'
					FROM @old_RetryAPIConfig rt
					FOR XML PATH('PaymentProviderAPIConfig'), 
					TYPE
				)
		FOR XML PATH('ROOT'), TYPE
		);
		SET @TrackingValue = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')

		-- LOG NEW VALUES FOR SETTING PAYMENT METHOD
		SET @xml = (
		SELECT	@CustID                         AS '@CustID',
				CustDB.dbo.f_GetSubUsername(@SubAccID) AS '@SubAccName',
				@IP                             AS '@IP',
				(
					SELECT	@CustID					 AS '@CustID',
							@ProviderID					 AS '@ProviderID',
							@PaymentMethodID				 AS '@PaymentMethodID',
							@TransactionType				 AS '@TransactionType',
							@APIConfig					 AS '@APIConfig',
							@PaymentMethodStatus			 AS '@PaymentMethodStatus'
					FOR XML PATH('PaymentProviderAPIConfig'), 
					TYPE
				)
		FOR XML PATH('ROOT'), TYPE
		);
		SET @TrackingValue2 = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')

	
		INSERT INTO @LogInfo_Tbl (UserID, CustID, ActionID, TrackingValue, TrackingValue2, Duration)
		SELECT @CustID ,  @CustID , @ActionID , @TrackingValue , @TrackingValue2 , @DurationTime
	END

	IF ISNULL(@CheckExists_ProviderAPIConfig, 0) = 0  AND ISNULL(@CheckExists_AgentPaymentMethod, 0) = 0
	BEGIN
		SET @ActionID = 305005

		-- LOG NEW VALUES FOR PAYMENT METHOD API CONFIG 
		SET @xml = (
		SELECT	@CustID                         AS '@CustID',
				CustDB.dbo.f_GetSubUsername(@SubAccID) AS '@SubAccName',
				@IP                             AS '@IP',
				(
					SELECT	@CustID					 AS '@CustID',
							@ProviderID					 AS '@ProviderID',
							@PaymentMethodID				 AS '@PaymentMethodID',
							@TransactionType				 AS '@TransactionType',
							@APIConfig					 AS '@APIConfig',
							@PaymentMethodStatus			 AS '@PaymentMethodStatus'
					FOR XML PATH('PaymentProviderAPIConfig'), 
					TYPE
				)
		FOR XML PATH('ROOT'), TYPE
		);
		SET @TrackingValue = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')

	
		INSERT INTO @LogInfo_Tbl (UserID, CustID, ActionID, TrackingValue, TrackingValue2, Duration)
		SELECT @CustID ,  @CustID , @ActionID , @TrackingValue , NULL , @DurationTime
	

		-- LOG NEW VALUES FOR SETTING PAYMENT METHOD
		SET @xml = (
		SELECT	@CustID                         AS '@CustID',
				CustDB.dbo.f_GetSubUsername(@SubAccID) AS '@SubAccName',
				@IP                             AS '@IP',
				(
					SELECT	@CustID					 AS '@CustID',
							@ProviderID					 AS '@ProviderID',
							@PaymentMethodID				 AS '@PaymentMethodID',
							@TransactionType				 AS '@TransactionType',
							CONVERT(DECIMAL(20,2), @MinAmount)	 AS '@MinAmount',
							CONVERT(DECIMAL(20,2), @MaxAmount)	 AS '@MaxAmount',
							@PaymentMethodEnable			 AS '@PaymentMethodEnable'
					FOR XML PATH('AgentPaymentMethod'), 
					TYPE
				)
		FOR XML PATH('ROOT'), TYPE
		);
		SET @TrackingValue = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')

	
		INSERT INTO @LogInfo_Tbl (UserID, CustID, ActionID, TrackingValue, TrackingValue2, Duration)
		SELECT @CustID ,  @CustID , @ActionID , @TrackingValue , NULL , @DurationTime
	END
	
	-- Return Data Object
	SELECT UserID, CustID, ActionID, TrackingValue, TrackingValue2 , TrackingValue AS TrackingValueMask, TrackingValue2 AS  TrackingValueMask2 , Duration FROM @LogInfo_Tbl
	
END
