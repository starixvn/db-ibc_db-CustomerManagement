/*<info serverAlias="DBCUST-AgencyCashService" executers="wsv_CashService"  viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Age_CashService_PaymentMethod_Upd
	@CustID			INT,			-- SMA_ID Input
	@ProviderID			SMALLINT,			
	@PaymentMethods		VARCHAR(MAX)		,
	@SubAccID			INT				= 0,
	@IP				VARCHAR(50)			= '',
	@Language			VARCHAR(2)			= 'E',
	@ErrCode			INT				= 0		OUTPUT,
	@ErrMsg			NVARCHAR(1000)		= ''		OUTPUT
AS 
/*  
	Created By: Helios
	Created Date: 2025-04-18
	Description: Agency Cash Service - Update Min - Max - Status Of Payment Methods, Manage for your member [Redmine #223896]
	DB: DBCust.AgencyCashService
	
	Revisions:
		- 20250321@Helios: Agency Cash Service [Redmine: #223896]

	Param:
		DECLARE @p4 INT , @p5 NVARCHAR(1000)

		exec Age_CashService_PaymentMethod_Upd		@CustID		= 1176086 , 
										@ProviderID		= 1,
										@PaymentMethods	= '[
														  {"MethodID": "1", "TransactionType": 1, "MinAmount": 100.00, "MaxAmount": 1000.00, "Enabled": 1},
														  {"MethodID": "2", "TransactionType": 1, "MinAmount": 100.00, "MaxAmount": 2000.00, "Enabled": 1},
														  {"MethodID": "6", "TransactionType": 2, "MinAmount": 100.00, "MaxAmount": 3000.00, "Enabled": 1}
														]' ,
										@ErrCode		= @p4 OUTPUT,
										@ErrMsg		= @p5 OUTPUT

		SELECT @p4 , @p5

	@PaymentMethods: [
				   {"MethodID": "1", "TransactionType": 1, "MinAmount": 100.00, "MaxAmount": 1000.00, "Enabled": 1},
				   {"MethodID": "2", "TransactionType": 1, "MinAmount": 100.00, "MaxAmount": 2000.00, "Enabled": 1},
				   {"MethodID": "6", "TransactionType": 2, "MinAmount": 100.00, "MaxAmount": 3000.00, "Enabled": 1}
				]
	Status: 0 = Processing - 1 = Completed - 2 = Fail - 3 = Maintenance

*/  
BEGIN
	SET NOCOUNT ON;

	DECLARE 
		@startRun		DATETIME ,
		@endRun		DATETIME ,
		@DurationTime	INT
	
	SET @startRun = GETDATE ()
	SELECT @ErrCode = 0 , @ErrMsg = '' 

	IF dbo.f_IsValidProvider(@ProviderID) = 0
	BEGIN
		SET @ErrCode = 100;
		SET @ErrMsg = N'Invalid parameters.';
		RETURN;
	END
	
	-- Check if XML is null or empty
	IF @ProviderID IS NULL OR @PaymentMethods IS NULL OR @PaymentMethods = ''
	BEGIN
		SELECT  @ErrMsg = N'Invalid parameters.' , @ErrCode = 100;
		RETURN
	END

	-- write log
	DECLARE @old_PaymentMethods TABLE (
		MethodID				SMALLINT,
		TransactionType			TINYINT,
		MinAmount				MONEY,
		MaxAmount				MONEY,
		PaymentMethodEnable			BIT
	);

	
	--get global config
	DECLARE @tmp_global_PaymentMethods TABLE (
		ProviderID				SMALLINT,
		MethodID				SMALLINT,
		TransactionType			TINYINT,
		MinAmount				MONEY,
		MaxAmount				MONEY
	);

	--parse new data
	DECLARE @tmp_PaymentMethods TABLE (
		MethodID				SMALLINT,
		TransactionType			TINYINT,
		MinAmount				MONEY,
		MaxAmount				MONEY,
		PaymentMethodEnable			BIT
	);
	INSERT INTO @tmp_PaymentMethods 
	(
		MethodID
		, TransactionType
		, MinAmount
		, MaxAmount
		, PaymentMethodEnable
	)
	SELECT MethodID , TransactionType, MinAmount, MaxAmount, PaymentMethodEnable
	FROM OPENJSON(@PaymentMethods) WITH (
		MethodID			SMALLINT	'$.MethodID',
		TransactionType		TINYINT	'$.TransactionType',
		MinAmount			MONEY		'$.MinAmount',
		MaxAmount			MONEY		'$.MaxAmount',
		PaymentMethodEnable	BIT		'$.Enabled'
	)
		
	--check parse data is exist ?
	IF NOT EXISTS( SELECT 1 FROM @tmp_PaymentMethods)
	BEGIN
		--SELECT @ErrCode = 90017,
		--	 @ErrMsg =  [dbo].[f_Get_MsgNamebyMsgID](90017,'E')
		SELECT  @ErrMsg = N'Invalid values input.' , @ErrCode = 100;
			RETURN
	END

	INSERT INTO @tmp_global_PaymentMethods 
	(
		ProviderID
		, MethodID
		, TransactionType
		, MinAmount
		, MaxAmount
	)
	SELECT
		cppi.ProviderID
		, cppi.PaymentMethodID
		, cppi.TransactionType
		, cppi.MinAmountTrans
		, cppi.MaxAmountTrans
	FROM CashPaymentProviderInfo cppi WITH (NOLOCK)
	INNER JOIN @tmp_PaymentMethods old ON cppi.PaymentMethodID = old.MethodID AND cppi.TransactionType = old.TransactionType
	WHERE cppi.ProviderID = @ProviderID

	-- remove data don't changed
	DELETE tmp
	FROM @tmp_PaymentMethods tmp
	INNER JOIN CashAgentPaymentMethod capm WITH (NOLOCK) ON tmp.MethodID = capm.PaymentMethodID AND tmp.TransactionType = capm.TransactionType
	WHERE capm.AgentID = @CustID
	AND capm.ProviderID = @ProviderID
	AND ISNULL(tmp.MinAmount , 0) = ISNULL(capm.MinAmount,0)
	AND ISNULL(tmp.MaxAmount , 0) = ISNULL(capm.MaxAmount,0)
	AND ISNULL(tmp.PaymentMethodEnable , 0) = ISNULL(capm.PaymentMethodEnable,0)	

	--validate parse data with current data setting is changed
	IF NOT EXISTS (SELECT TOP 1 1 FROM @tmp_PaymentMethods tmp)
	BEGIN
		SELECT  @ErrMsg = N'No changes detected.' , @ErrCode = 0;
			RETURN
	END

	--validate parse data input with global setting
	IF EXISTS ( SELECT 1
			FROM @tmp_PaymentMethods pm
			INNER JOIN @tmp_global_PaymentMethods gpm ON pm.MethodID = gpm.MethodID AND pm.TransactionType = gpm.TransactionType
			WHERE gpm.ProviderID = @ProviderID
			AND (pm.MinAmount IS NULL OR pm.MaxAmount IS NULL
			OR pm.MinAmount < 0 OR pm.MaxAmount < 0
			OR pm.MaxAmount < pm.MinAmount
			OR pm.MinAmount < gpm.MinAmount OR pm.MaxAmount > gpm.MaxAmount)
	)
	BEGIN
		--SELECT @ErrCode = 90017,
		--	 @ErrMsg =  [dbo].[f_Get_MsgNamebyMsgID](90017,'E')
		SELECT  @ErrMsg = N'Incorrect Min/Max value.' , @ErrCode = 101;
		RETURN
	END

	DECLARE @PaymentMethodStatus BIT = NULL

	SELECT @PaymentMethodStatus = (SELECT TOP 1 1
				FROM CashPaymentProviderAPIConfig cppa WITH (NOLOCK)
				INNER JOIN @tmp_PaymentMethods tmp ON  cppa.PaymentMethodID = tmp.MethodID AND cppa.TransactionType = tmp.TransactionType
				WHERE cppa.AgentID = @CustID
				AND cppa.ProviderID = @ProviderID
				AND cppa.PaymentMethodStatus = 2	)		-- Status of payment method is Completed)

	-- Check if payment method status is already 'completed'
	IF ISNULL(@PaymentMethodStatus, 0) = 0
	BEGIN
		SELECT  @ErrMsg = N'Payment method is incomplete.' , @ErrCode = 102;
			RETURN
	END
	
	IF EXISTS (SELECT TOP 1 1 FROM CashAgentPaymentMethod cpp WITH (NOLOCK)
					  INNER JOIN @tmp_PaymentMethods tmp ON cpp.PaymentMethodID = tmp.MethodID AND cpp.TransactionType = tmp.TransactionType
					  WHERE cpp.AgentID = @CustID
					  AND cpp.ProviderID = @ProviderID)
	AND @PaymentMethodStatus = 1
	BEGIN
		-- write Log
		INSERT INTO @old_PaymentMethods 
		(
			MethodID
			, TransactionType
			, MinAmount
			, MaxAmount
			, PaymentMethodEnable
		)
		SELECT 
			cpp.PaymentMethodID,
			cpp.TransactionType,
			cpp.MinAmount,
			cpp.MaxAmount,
			cpp.PaymentMethodEnable
		FROM CashAgentPaymentMethod cpp WITH (NOLOCK)
		INNER JOIN @tmp_PaymentMethods tmp ON cpp.PaymentMethodID = tmp.MethodID
		WHERE cpp.AgentID = @CustID
		AND cpp.ProviderID = @ProviderID

		-- Update Payment Provider info
		UPDATE cpp
			SET cpp.MinAmount = tmp.MinAmount
			,   cpp.MaxAmount = tmp.MaxAmount
			,   cpp.PaymentMethodEnable = tmp.PaymentMethodEnable
			,   cpp.RepUpdateTime = dbo.f_GetDateTime2()
		FROM CashAgentPaymentMethod cpp WITH (ROWLOCK , UPDLOCK)
		INNER JOIN @tmp_PaymentMethods tmp ON cpp.PaymentMethodID = tmp.MethodID
		WHERE cpp.AgentID = @CustID
		AND cpp.ProviderID = @ProviderID
	END
	
	IF (@@error = 0)
	BEGIN
		SELECT  
			@ErrMsg = N'Update successful.',
			@ErrCode = 0;
	END

	--START LOG
	DECLARE @LogInfo_Tbl TABLE(UserID INT, CustID INT, ActionID INT, TrackingValue VARCHAR(MAX), TrackingValue2 VARCHAR(MAX) , Duration INT )
	DECLARE @TrackingValue VARCHAR(MAX), @TrackingValue2 VARCHAR(MAX)
	DECLARE @xml XML , @UserName NVARCHAR(50) , @ActionID INT = 305002
		SET @endRun = GETDATE ()
		SET @DurationTime = datediff (millisecond,@startRun,@endRun)


	-- LOG NEW VALUES
	SET @xml = (
		SELECT	
				@CustID									AS '@CustID',
				CustDB.dbo.f_GetSubUsername(@SubAccID)	AS '@SubAccName',
				@IP									AS '@IP',
				a.MethodID							AS '@PaymentMethodID',
				a.TransactionType					AS '@TransactionType',
				CONVERT(DECIMAL(20,2), a.MinAmount)	AS '@MinAmount',
				CONVERT(DECIMAL(20,2), a.MaxAmount)	AS '@MaxAmount',
				a.PaymentMethodEnable				AS '@PaymentMethodEnable'
		FROM @tmp_PaymentMethods a
		FOR XML PATH('Age_CashService_PaymentMethod_Upd'), 
		TYPE
	);
	SET @TrackingValue = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')

	-- LOG OLD VALUES
	SET @xml = (
		SELECT	
				@CustID									AS '@CustID',
				CustDB.dbo.f_GetSubUsername(@SubAccID)	AS '@SubAccName',
				@IP									AS '@IP',
				a.MethodID							AS '@PaymentMethodID',
				a.TransactionType					AS '@TransactionType',
				CONVERT(DECIMAL(20,2), a.MinAmount)	AS '@MinAmount',
				CONVERT(DECIMAL(20,2), a.MaxAmount)	AS '@MaxAmount',
				a.PaymentMethodEnable				AS '@PaymentMethodEnable'
		FROM @old_PaymentMethods a
		FOR XML PATH('Age_CashService_PaymentMethod_Upd'), 
		TYPE
	);
	SET @TrackingValue2 = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')

	INSERT INTO @LogInfo_Tbl (UserID, CustID, ActionID, TrackingValue, TrackingValue2, Duration)
	SELECT @CustID ,  @CustID , @ActionID , @TrackingValue , @TrackingValue2 , @DurationTime


	-- Return Data Object
	SELECT UserID, CustID, ActionID, TrackingValue, TrackingValue2 , TrackingValue AS TrackingValueMask, TrackingValue2 AS  TrackingValueMask2 , Duration FROM @LogInfo_Tbl
END
