/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet,wsv_nap" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [Acc_ExchangeDailySel_Crypto] 
	@Code VARCHAR(12)
	, @RunDate DATE = NULL
	, @MYR FLOAT OUTPUT
	, @CNY FLOAT OUTPUT
	, @EUR FLOAT OUTPUT
	, @USD FLOAT OUTPUT

AS
/*
Created: Evan
Task : Get rate for inactive crypto currency
DB: DBCUST.CustDB
Revisions:
	- 20221115@Evan: Initialize sp  [Redmine: #180168]  
	- 20230807@Evan: Support EUR rate  [Redmine: #192369]  
	- 20240128@Evan: Support USD rate  [Redmine: #200341]  

Note: In case if coinmarketcap does not have the rate of the currency, the web will call this SP to get the latest rate in table ExchangeDailyOanda to call API keep running. 

*/
BEGIN

	SET NOCOUNT ON
	SET @RunDate = ISNULL(@RunDate,GETDATE());
	
	DECLARE @Yesterday SMALLDATETIME;
	SELECT	@Yesterday = DATEADD(dd,-1,@RunDate)

	SELECT	@MYR = a.MYR / b.MultipliedBy,
			@CNY = a.CNY / b.MultipliedBy,
			@EUR = a.EUR / b.MultipliedBy,
			@USD = a.USD / b.MultipliedBy
	FROM dbo.ExchangeDailyOanda a WITH(NOLOCK) 
		INNER JOIN dbo.exchange b WITH(NOLOCK) ON a.ExchangeId = b.ExchangeId
	WHERE a.ExchangeDate = @Yesterday AND b.Code = @Code
	
	IF @@ROWCOUNT = 0
	BEGIN
		SELECT TOP 1 @MYR = a.MYR / b.MultipliedBy,
				@CNY = a.CNY / b.MultipliedBy,
				@EUR = a.EUR / b.MultipliedBy,
				@USD = a.USD / b.MultipliedBy
		FROM dbo.ExchangeDailyOanda a WITH(NOLOCK) 
			INNER JOIN dbo.exchange b WITH(NOLOCK) ON a.ExchangeId = b.ExchangeId
		WHERE  b.Code = @Code
		ORDER BY ExchangeDate DESC
	END

END
