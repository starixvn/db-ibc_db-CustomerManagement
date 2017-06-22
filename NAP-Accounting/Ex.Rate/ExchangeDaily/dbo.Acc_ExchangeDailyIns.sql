USE [CustDB]
GO
ALTER PROCEDURE [dbo].[Acc_ExchangeDailyIns] @Code VARCHAR(5)
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
	, @rundate DATETIME = NULL
	, @ErrCode INT = 0 OUTPUT
	, @ErrMsg NVARCHAR(200) = '' OUTPUT
AS
/*
Created: Henry
Task : Insert the rate daily
DB: DBCUST.CustDB
Revisions:
	-  20110215@Henry: add to insert currency UUS to exchangedaily
	-  20110322@Henry: add one more base currency: CNY
	-  20120427@Henry: add to new table ExchangeDailyOanda instead of ExchangeDaily	
	-  20120427@Dan: add new currency KRW and JPY
	-  20160914@Jim:  Add HKD base currency into OANDA Exchange rate [RedmineID : #63975]
	-  20160920@Jim:  Add YNG currency [RedmineID : #64385]
*/
/*
declare @p3 nvarchar(200)
set @p3=N''
declare @p13 int
set @p13=0
exec Acc_ExchangeDailyIns_xtest  @rundate='2016-09-23 06:19:03.143',@VND=17263.400000000001,@ErrMsg=@p3 output,@THB=26.5307,@AUD=1,@KRW=844.46199999999999
,@Code='AUD',@CNY=5.0996800000000002,@IDR=10008.6,@CHF=0.74219999999999997,@hkd=0.58535000000000004,@GBP=0.58535000000000004,@ErrCode=@p13 output
,@SGD=1.0356399999999999,@USD=0.76466000000000001,@JPY=76.904399999999995,@MYR=3.14269,@EUR=0.68181999999999998
select @p3, @p13
*/

SET NOCOUNT ON

DECLARE @exchange TABLE (
	id INT identity(1, 1)
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

IF @Code = 'UUS'
BEGIN
	IF NOT EXISTS (
			SELECT 1
			FROM ExchangeDailyOanda(NOLOCK)
			WHERE ExchangeDate = @date
				AND ExchangeId = 20
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
			)
		VALUES (
			20
			, @date
			, 'UUS'
			, 2e-101
			, 2e-101
			, 2e-101
			, 2e-101
			, 2e-101
			, 2e-101
			, 2e-101
			, 2e-101
			, 2e-101
			, 2e-101
			, 2e-101
			, 2e-101
			, 2e-101
			, 2e-101
			)
	END
	ELSE
	BEGIN
		UPDATE ExchangeDailyOanda
		WITH (
				ROWLOCK
				, UPDLOCK
				)

		SET MYR = 2e-101
			, USD = 2e-101
			, EUR = 2e-101
			, CNY = 2e-101
			, IDR = 2e-101
			, AUD = 2e-101
			, CHF = 2e-101
			, GBP = 2e-101
			, SGD = 2e-101
			, THB = 2e-101
			, VND = 2e-101
			, KRW = 2e-101
			, JPY = 2e-101
			, HKD = 2e-101
		WHERE ExchangeId = 20
			AND ExchangeDate = @date
	END

	RETURN
END

INSERT INTO @exchange (
	exchangeid
	, MultipliedBy
	)
SELECT exchangeid
	, MultipliedBy
FROM exchange(NOLOCK)
WHERE Code = @Code

IF @@ROWCOUNT > 0
	AND @Code <> 'YNG'
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

IF @Code = 'YNG'
BEGIN
	IF NOT EXISTS (
			SELECT 1
			FROM dbo.ExchangeDailyOanda(NOLOCK)
			WHERE  ExchangeDate = @date
				AND Code = 'VND'
			)
		RETURN;
	SET @i = 1

	SELECT @max = count(1)
	FROM @exchange

	WHILE (@i <= @max)
	BEGIN
		SELECT @ExchangeId = exchangeid
		FROM @exchange
		WHERE id = @i
		
		SET @MultipliedBy = 0.001
		
		SELECT @MYR = MYR
			, @USD = USD
			, @EUR = EUR
			, @CNY = CNY
			, @IDR = IDR
			, @AUD = AUD
			, @CHF = CHF
			, @GBP = GBP
			, @SGD = SGD
			, @THB = THB
			, @VND = VND
			, @KRW = KRW
			, @JPY = JPY
			, @HKD = HKD
		FROM dbo.ExchangeDailyOanda WITH (NOLOCK)
		WHERE Code = 'VND'
			AND ExchangeDate = @Date

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
				)
			VALUES (
				@ExchangeId
				, @date
				, @Code
				,  @MYR * @MultipliedBy 
				,  @USD * @MultipliedBy 
				,  @EUR * @MultipliedBy 
				,  @CNY * @MultipliedBy 
				,  @IDR * @MultipliedBy 
				,  @AUD * @MultipliedBy 
				,  @CHF * @MultipliedBy 
				,  @GBP * @MultipliedBy 
				,  @SGD * @MultipliedBy 
				,  @THB * @MultipliedBy 
				,  @VND * @MultipliedBy 
				,  @KRW * @MultipliedBy 
				,  @JPY * @MultipliedBy 
				,  @HKD * @MultipliedBy 
				)	
		END
		ELSE
		BEGIN
			UPDATE ExchangeDailyOanda
			WITH (
					ROWLOCK
					, UPDLOCK
					)
			SET MYR =  @MYR * @MultipliedBy 
				, USD =  @USD * @MultipliedBy 
				, EUR =  @EUR * @MultipliedBy 
				, CNY =  @CNY * @MultipliedBy 
				, IDR =  @IDR * @MultipliedBy 
				, AUD =  @AUD * @MultipliedBy 
				, CHF =  @CHF * @MultipliedBy 
				, GBP =  @GBP * @MultipliedBy 
				, SGD =  @SGD * @MultipliedBy 
				, THB =  @THB * @MultipliedBy 
				, VND =  @VND * @MultipliedBy 
				, KRW =  @KRW * @MultipliedBy 
				, JPY =  @JPY * @MultipliedBy 
				, HKD =  @HKD * @MultipliedBy 
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
GO
GRANT EXECUTE
	ON [dbo].[Acc_ExchangeDailyIns]
	TO [bodbAdminNet]
GO

GRANT VIEW DEFINITION
	ON [dbo].[Acc_ExchangeDailyIns]
	TO [vnteam]
