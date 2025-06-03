/*<info serverAlias="DBCUST-AgencyCashService" executers="wsv_CashService"  viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE dbo.Age_CashService_PaymentProviderFee_Sel
	@ProviderID    SMALLINT			
AS 
/*  
	Created By: Helios
	Created Date: 2025-04-18
	Description: Agency Cash Service - Get list payment Provider Fee  [Redmine #223896]
	DB: DBCust.AgencyCashService 
	
	Revisions:
		- 20250321@Helios: Agency Cash Service [Redmine: #223896]

	Param:
		exec Age_CashService_PaymentProviderFee_Sel @ProviderID = 1
*/  
BEGIN
	SET NOCOUNT ON;

	SELECT cpf.PaymentMethodID , cpf.TransactionType ,cpm.MethodName , cpf.FeeRate
	FROM CashPaymentProviderInfo cpf WITH (NOLOCK) 
	INNER JOIN CashPaymentMethod cpm WITH (NOLOCK) ON  cpf.PaymentMethodID = cpm.PaymentMethodID
	WHERE cpf.ProviderID = @ProviderID
END
