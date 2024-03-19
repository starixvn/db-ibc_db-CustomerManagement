/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet,wsv_nap" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_ExchangeDailyIns_Crypto] 
	@Code VARCHAR(12)
	, @MYR FLOAT
	, @USD FLOAT
	, @EUR FLOAT
	, @CNY FLOAT
	, @IDR FLOAT
	, @AUD FLOAT
	, @CHF FLOAT
	, @GBP FLOAT
	, @SGD FLOAT
	, @THB FLOAT
	, @VND FLOAT
	, @KRW FLOAT
	, @JPY FLOAT
	, @HKD FLOAT
	, @TWD FLOAT
	, @PHP FLOAT
	, @BDT FLOAT
	, @INR FLOAT
	, @TRY FLOAT
	, @NPR FLOAT
	, @rundate DATETIME = NULL
	, @ErrCode INT = 0 OUTPUT
	, @ErrMsg NVARCHAR(200) = '' OUTPUT
AS
/*
Created: Evan
Task : Insert the rate daily
DB: DBCUST.CustDB
Original: Acc_ExchangeDailyIns
Revisions:
	- 20220908@Evan: Support crypto  [Redmine: #177481]  
	- 20221115@Evan: Extend datatype @Code to varchar(12) [Redmine: #180168]  
	- 20240112@Evan: Add 2 more base currencies TRY & NPR - [RedmineID: #197693]
*/
BEGIN

	SET NOCOUNT ON

	DECLARE @exchange TABLE (
		id INT IDENTITY(1, 1)
		, exchangeid INT
		, MultipliedBy FLOAT
		)
	DECLARE @date SMALLDATETIME
			, @i INT
			, @max INT
			, @ExchangeId INT
			, @MultipliedBy FLOAT

	IF @rundate IS NULL
		SET @date = CONVERT(SMALLDATETIME, CONVERT(VARCHAR(20), GETDATE(), 101))
	ELSE
		SET @date = CONVERT(SMALLDATETIME, CONVERT(VARCHAR(20), @rundate, 101))
	
	INSERT INTO @exchange (
		exchangeid
		, MultipliedBy
		)
	SELECT exchangeid
		, MultipliedBy
	FROM exchange WITH(NOLOCK)
	WHERE Code = @Code
		AND	CurrencyType = 1
	IF @@ROWCOUNT > 0
	BEGIN
		SET @i = 1

		SELECT @max = count(1)
		FROM @exchange

		WHILE (@i <= @max)
		BEGIN
			SELECT @ExchangeId = exchangeid
				,@MultipliedBy = MultipliedBy
			FROM @exchange
			WHERE id = @i

			--Check exist, if false then insert 
			IF NOT EXISTS (
					SELECT 1
					FROM ExchangeDailyOanda WITH(NOLOCK)
					WHERE ExchangeId = @ExchangeId
						AND ExchangeDate = @date
						AND Code = @Code
					)
			BEGIN
				INSERT INTO ExchangeDailyOanda (
					ExchangeId
					, ExchangeDate
					, Code
					, MYR
					, USD
					, EUR
					, CNY
					, IDR
					, AUD
					, CHF
					, GBP
					, SGD
					, THB
					, VND
					, KRW
					, JPY
					, HKD
					, TWD
					, PHP
					, BDT
					, INR
					, TRY
					, NPR
					, ActualRate
					)
				VALUES (
					@ExchangeId
					, @date
					, @Code
					, @MYR * @MultipliedBy
					, @USD * @MultipliedBy
					, @EUR * @MultipliedBy
					, @CNY * @MultipliedBy
					, @IDR * @MultipliedBy
					, @AUD * @MultipliedBy
					, @CHF * @MultipliedBy
					, @GBP * @MultipliedBy
					, @SGD * @MultipliedBy
					, @THB * @MultipliedBy
					, @VND * @MultipliedBy
					, @KRW * @MultipliedBy
					, @JPY * @MultipliedBy
					, @HKD * @MultipliedBy
					, @TWD * @MultipliedBy
					, @PHP * @MultipliedBy
					, @BDT * @MultipliedBy
					, @INR * @MultipliedBy
					, @TRY * @MultipliedBy
					, @NPR * @MultipliedBy
					, @MYR * @MultipliedBy
					)
			END
			ELSE
			BEGIN
				UPDATE ExchangeDailyOanda WITH (ROWLOCK, UPDLOCK)
				SET MYR = @MYR * @MultipliedBy
					, USD = @USD * @MultipliedBy
					, EUR = @EUR * @MultipliedBy
					, CNY = @CNY * @MultipliedBy
					, IDR = @IDR * @MultipliedBy
					, AUD = @AUD * @MultipliedBy
					, CHF = @CHF * @MultipliedBy
					, GBP = @GBP * @MultipliedBy
					, SGD = @SGD * @MultipliedBy
					, THB = @THB * @MultipliedBy
					, VND = @VND * @MultipliedBy
					, KRW = @KRW * @MultipliedBy
					, JPY = @JPY * @MultipliedBy
					, HKD = @HKD * @MultipliedBy
					, TWD = @TWD * @MultipliedBy
					, PHP = @PHP * @MultipliedBy
					, BDT = @BDT * @MultipliedBy
					, INR = @INR * @MultipliedBy
					, TRY = @TRY * @MultipliedBy
					, NPR = @NPR * @MultipliedBy
					, ActualRate = @MYR * @MultipliedBy
				WHERE ExchangeId = @ExchangeId
					AND ExchangeDate = @date
					AND Code = @Code
			END

			IF @@Error <> 0
			BEGIN
				SELECT @ErrMsg = 'Exchange rate insert fail.'
					, @ErrCode = 100

				RETURN
			END

			-- Insert into ExchangeDaily_Crypto - base to USDT
			IF NOT EXISTS (	SELECT 1 
						FROM ExchangeDaily_Crypto WITH(NOLOCK) 
						WHERE ExchangeId = @ExchangeId AND ExchangeDate = @date)
			BEGIN
				INSERT INTO ExchangeDaily_Crypto (ExchangeDate, ExchangeId, USDT)
				SELECT	@date AS ExchangeDate, ExchangeId, USDT 
				FROM	ExchangeDaily_Crypto WITH(NOLOCK)
				WHERE	ExchangeId = @ExchangeId AND ExchangeDate = DATEADD(dd,-1,@date)
			END		
				
			SET @i = @i + 1
		END
	END

	-- Update ExchangeDailyOanda.MYR to Exchange.ActualRate
	UPDATE	a
	SET		a.actualrate = b.MYR
	FROM	exchange a WITH(ROWLOCK) 
			INNER JOIN ExchangeDailyOanda b WITH(NOLOCK) on a.ExchangeId = b.exchangeid  
	WHERE	b.ExchangeDate = @date AND a.Code = @Code

END
GO