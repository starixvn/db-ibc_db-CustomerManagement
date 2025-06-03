/*<info serverAlias="DBCUST-AgencyCashService" executers="wsv_CashService"  viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Age_CashService_PaymentProviderDetail_Sel
	@ProviderID			SMALLINT		= 0,
	@CustID			INT,
	@PaymentMethodID		SMALLINT		= 0,
	@PaymentMethodStatus	TINYINT		= 0,
	@TransactionType		TINYINT		= 0
AS 
/*  
	Created By: Helios
	Created Date: 2025-04-18
	Description: Agency Cash Service - Get detail payment Provider [Redmine #223896]
	DB: DBCust.AgencyCashService
	
	Revisions:
		- 20250321@Helios: Agency Cash Service [Redmine: #223896]

	Param:
		exec Age_CashService_PaymentProviderDetail_Sel	@ProviderID =  1 , 
										@CustID = 14373905,
										@PaymentMethodID		= 0,
										@PaymentMethodStatus	= 0,
										@TransactionType		= 2

	

	@PaymentMethodStatus :	0 : Get ALL
					1 = Processing
					2 = Completed
					3 = Fail
					4 = Maintenance
	@TransactionType:		0 : Get ALL
					1 : Deposit
					2: Withdrawal
*/  
BEGIN
	SET NOCOUNT ON;
	
	SELECT
		cpm.PaymentMethodID,
		cpm.MethodName,
		cpc.PaymentMethodStatus,
		cpc.TransactionType,
		cpp.MinAmount,
		cpp.MaxAmount,
		cpl.MinAmountTrans,
		cpl.MaxAmountTrans,
		cpp.PaymentMethodEnable,
		CASE
			WHEN cpc.PaymentMethodID = 6  THEN 1		-- Bank Transfer : Is RequiresBank
			ELSE 0
		END RequiresBank
	FROM CashPaymentMethod cpm WITH (NOLOCK)
	INNER JOIN CashPaymentProviderAPIConfig cpc WITH (NOLOCK) ON cpm.PaymentMethodID = cpc.PaymentMethodID
	INNER JOIN CashAgentPaymentMethod cpp WITH (NOLOCK) ON cpc.ProviderID = cpp.ProviderID AND cpm.PaymentMethodID = cpp.PaymentMethodID AND cpc.AgentID = cpp.AgentID AND cpc.TransactionType = cpp.TransactionType
	INNER JOIN CashPaymentProviderInfo cpl WITH (NOLOCK) ON cpp.ProviderID = cpl.ProviderID AND cpp.PaymentMethodID = cpl.PaymentMethodID AND cpp.TransactionType = cpl.TransactionType
	WHERE cpp.ProviderID = @ProviderID
	AND cpp.AgentID = @CustID
	AND (@PaymentMethodID		= 0	OR cpp.PaymentMethodID = @PaymentMethodID)
	AND (@PaymentMethodStatus	= 0	OR cpc.PaymentMethodStatus = @PaymentMethodStatus)
	AND (@TransactionType		= 0	OR cpc.TransactionType = @TransactionType)
END
