/*<info serverAlias="DBCUST-AgencyCashService" executers="" viewers="" isFunction="1"></info>*/
CREATE FUNCTION [dbo].[f_IsValidPaymentMethod](@PaymentMethodID SMALLINT)
RETURNS BIT
AS
/*
	Created: 20250321@Helios
	Revision:      
		- 20250321@Helios: Agency Cash Service [Redmine: #223896]
*/ 
BEGIN
	DECLARE @Exists BIT = 0;

	IF EXISTS (
		SELECT 1
		FROM CashPaymentMethod WITH (NOLOCK)
		WHERE PaymentMethodID = @PaymentMethodID
	)
	SET @Exists = 1;

	RETURN @Exists;
END