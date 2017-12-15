/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_TOControl_CurrencySelect] 
(
	@ExchangeID INT = 0
)
AS
/*
	Created: Helen
	Date: 2017-12-12
	Task: Retrieve list of currency
	DB: DBCUST/CUSTDB

	Revisions:
			- 20171212@Helen: Implement some change request from OPS Team - [Redmine: 85638]
			
	Parameter's explaination: 
		
*/
BEGIN
	SET NOCOUNT ON
	SELECT ExchangeID, Currency
	FROM dbo.Exchange WITH (NOLOCK)
	WHERE ExchangeID NOT IN (27,28)
		AND 1 = CASE WHEN @ExchangeID = 0 THEN 1
					 WHEN @ExchangeID <> 0 AND exchangeid = @ExchangeID THEN 1 
					 ELSE 0 END 
	
END
GO
GRANT EXECUTE ON [dbo].[NAP_TOControl_CurrencySelect] TO [bodbAdminNet]
GO