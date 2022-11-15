/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_ExchangeDailySel_Crypto] 
	@Code VARCHAR(12)
	, @MYR FLOAT OUTPUT
	, @CNY FLOAT OUTPUT

AS
/*
Created: Evan
Task : Get rate for inactive crypto currency
DB: DBCUST.CustDB
Revisions:
	- 20220908@Evan: Initialize sp  [Redmine: #180168]  
*/
BEGIN

	SET NOCOUNT ON
	
	SELECT TOP 1 @MYR = a.MYR / b.MultipliedBy,
			@CNY = a.CNY / b.MultipliedBy
	FROM ExchangeDailyOanda a WITH(NOLOCK) 
		INNER JOIN exchange b WITH(NOLOCK) ON a.ExchangeId = b.ExchangeId
	WHERE  b.Code = @Code
	ORDER BY ExchangeDate DESC

END
GO
