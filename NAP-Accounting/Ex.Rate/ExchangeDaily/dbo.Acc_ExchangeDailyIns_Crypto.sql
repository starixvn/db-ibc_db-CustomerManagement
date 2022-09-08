/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Acc_ExchangeDailyIns_Crypto] 
	@Code VARCHAR(5)
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
*/

SET NOCOUNT ON

DECLARE @exchange TABLE (
	id INT IDENTITY(1, 1)
	, exchangeid INT
	, MultipliedBy FLOAT
	)
DECLARE @date DATETIME
		, @i INT
		, @max INT
		, @ExchangeId INT
		, @MultipliedBy FLOAT
IF @rundate IS NULL
	SET @date = convert(DATETIME, convert(NVARCHAR(20), getdate(), 101))
ELSE
	SET @date = convert(DATETIME, convert(NVARCHAR(20), @rundate, 101))

INSERT INTO @exchange (
	exchangeid
	, MultipliedBy
	)
SELECT exchangeid
	, MultipliedBy
FROM exchange(NOLOCK)
WHERE Code = @Code

IF @@ROWCOUNT > 0
BEGIN
	SET @i = 1

	SELECT @max = count(1)
	FROM @exchange

	WHILE (@i <= @max)
	BEGIN
		SELECT @ExchangeId = exchangeid
			, @MultipliedBy = MultipliedBy
		FROM @exchange
		WHERE id = @i

		--Check exist, if false then insert 
		IF NOT EXISTS (
				SELECT 1
				FROM ExchangeDailyOanda(NOLOCK)
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
				, @MYR * @MultipliedBy
				)
		END
		ELSE
		BEGIN
			UPDATE ExchangeDailyOanda
			WITH (
					ROWLOCK
					, UPDLOCK
					)

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

		SET @i = @i + 1
	END
END

-- Update ExchangeDailyOanda.MYR to Exchange.ActualRate
UPDATE a
SET a.actualrate = b.MYR
FROM exchange a WITH(ROWLOCK) 
	INNER JOIN ExchangeDailyOanda b WITH(NOLOCK) on a.ExchangeId = b.exchangeid AND b.ExchangeDate = @date
WHERE a.Code = @Code

GO