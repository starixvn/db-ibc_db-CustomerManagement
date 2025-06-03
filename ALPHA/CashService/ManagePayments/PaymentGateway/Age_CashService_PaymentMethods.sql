/*<info serverAlias="DBCUST-AgencyCashService" executers="wsv_CashService"  viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Age_CashService_PaymentMethods
	@TransactionType			TINYINT = 0,
	@ProviderID				SMALLINT = 0,
	@CustID				INT,
	@ChannelContact			NVARCHAR(500) ='' OUTPUT
AS 
/*  
	Created By: Helios
	Created Date: 2025-04-18
	Description: Agency Cash Service - Get Drop Down List Payment Methods [Redmine #223896]
	DB: DBCust.AgencyCashService
	
	Revisions:
		- 20250321@Helios: Agency Cash Service [Redmine: #223896]

	Param:

	@TransactionType :
		0 = Get ALL Payment method : Drop Down List Payment Methods
		1 = deposit
		2 = withdraw
		
		DECLARE @p1 NVARCHAR(500)
		exec Age_CashService_PaymentMethods_UAT2  @TransactionType = 1 , @ProviderID = 1 , @CustID = 14373905 , @ChannelContact = @p1 OUTPUT
		SELECT @p1

	OUTPUT : PaymentMethodStatus  0: Config has not been added yet
						3: Fail
						4: Under Maintaince
*/  
BEGIN
	SET NOCOUNT ON;

	--Drop Down List Payment Methods : Get ALL Payment method
	IF @TransactionType = 0
	BEGIN
		SELECT cpm.PaymentMethodID, cpm.MethodName
		FROM CashPaymentMethod cpm WITH (NOLOCK)

	END
	ELSE
	--Drop Down List Payment Methods : Get payment methods not yet assigned to the agent
	BEGIN
		SELECT DISTINCT
		    pm.PaymentMethodID,
		    pm.MethodName,
		    ISNULL(api_config.PaymentMethodStatus , 0) AS PaymentMethodStatus
		FROM CashPaymentMethod pm WITH (NOLOCK)
		INNER JOIN CashPaymentProviderInfo cppi WITH (NOLOCK) ON pm.PaymentMethodID = cppi.PaymentMethodID
		-- Use OUTER APPLY to fetch the API config per provider, method, transaction, and agent
		OUTER APPLY (
		    SELECT TOP 1 cppa.PaymentMethodStatus
		    FROM CashPaymentProviderAPIConfig cppa WITH (NOLOCK)
		    WHERE cppa.ProviderID = cppi.ProviderID
			AND cppa.PaymentMethodID = cppi.PaymentMethodID
			AND cppa.TransactionType = cppi.TransactionType
			AND cppa.AgentID = @CustID
		    ORDER BY cppa.PaymentMethodStatus
		) AS api_config
		WHERE 
		    cppi.TransactionType = @TransactionType
		    AND cppi.ProviderID = @ProviderID
		    AND (
			  api_config.PaymentMethodStatus IS NULL -- No matching config found
			  OR api_config.PaymentMethodStatus IN (3,4)  -- Matching config with status "Under Maintaince"
		    )
	END

	-- Get Channel
	SELECT @ChannelContact  = capc.ChannelContact
	FROM CashAgentProviderConfig capc WITH (NOLOCK)
	WHERE AgentID = @CustID
	AND ProviderID = @ProviderID
END
