/*<info serverAlias="DBCUST-CustDB" executers="wsv_nap" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_ExchangeDailyIns]
(
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
	, @MXN FLOAT
	, @NGN FLOAT
	, @BRL FLOAT
	, @rundate DATETIME = NULL
	, @ErrCode INT = 0 OUTPUT
	, @ErrMsg NVARCHAR(200) = '' OUTPUT
)
AS
/*
	Created: Henry
	Task : Insert the rate daily
	DB: DBCUST.CustDB
	Revisions:
		- 20110215@Henry: add to insert currency UUS to exchangedaily
		- 20110322@Henry: add one more base currency: CNY
		- 20120427@Henry: add to new table ExchangeDailyOanda instead of ExchangeDaily	
		- 20120427@Dan: add new currency KRW and JPY
		- 20160914@Jim:  Add HKD base currency into OANDA Exchange rate [RedmineID : #63975]
		- 20160920@Jim:  Add YNG currency [RedmineID : #64385]
		- 20171124@Harper: Add 2 more base currencies TWD and PHP into OANDA service [RedmineID: #87042]
		- 20210223@Sol: Add 2 more base currencies BDT and INR into OANDA service - [RedmineID: #150479]
		- 20221115@Evan: Extend datatype @Code to varchar(12) [Redmine: #180168]  	
		- 20240112@Evan: Add 2 more base currencies TRY & NPR into OANDA service - [RedmineID: #197693]
		- 20240401@Lewis: Support new currency SBC, DIA - [RedmineID: #202273] + [RedmineID: #203096]
		- 20240507@Kelvin: LAP - Support based currency JPY, MXN, NGN [RedmineID: #200904]
		- 20240828@Lewis: Support new currency BTS - [RedmineID: #209780]
		- 20241001@Eddie: Update exchange code of HKK and remove this hard code after done [RedmineID: #211537]
		- 20241111@Kelvin: LAP - Support BRL base currency [RedmineID: #208662]  
		- 20250114@Lewis: Apply Rep-Inhouse [RedmineID: #215883]
		
	Parameter's Explaination:
	/*
	declare @p3 nvarchar(200)
	set @p3=N''
	declare @p13 int
	set @p13=0
	exec Acc_ExchangeDailyIns  @rundate='2016-09-23 06:19:03.143',@VND=17263.400000000001,@ErrMsg=@p3 output,@THB=26.5307,@AUD=1,@KRW=844.46199999999999
	,@Code='AUD',@CNY=5.0996800000000002,@IDR=10008.6,@CHF=0.74219999999999997,@hkd=0.58535000000000004,@GBP=0.58535000000000004,@ErrCode=@p13 output
	,@SGD=1.0356399999999999,@USD=0.76466000000000001,@JPY=76.904399999999995,@MYR=3.14269,@EUR=0.68181999999999998
	select @p3, @p13
	*/
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @exchange TABLE ( id INT IDENTITY(1, 1), exchangeid INT, MultipliedBy FLOAT)

	DECLARE @date DATETIME
		  , @i INT
		  , @max INT
		  , @ExchangeId INT
		  , @MultipliedBy FLOAT

	IF @rundate IS NULL
		SET @date = CONVERT(DATETIME, CONVERT(NVARCHAR(20), GETDATE(), 101))
	ELSE
		SET @date = CONVERT(DATETIME, CONVERT(NVARCHAR(20), @rundate, 101))

	INSERT INTO @exchange (exchangeid, MultipliedBy)
	SELECT exchangeid, MultipliedBy
	FROM exchange WITH (NOLOCK)
	WHERE Code = @Code

	IF @@ROWCOUNT > 0
	BEGIN
		SET @i = 1

		SELECT @max = COUNT(1)
		FROM @exchange

		WHILE (@i <= @max)
		BEGIN
			SELECT @ExchangeId = exchangeid
				 , @MultipliedBy = MultipliedBy
			FROM @exchange
			WHERE id = @i

			--Check exist, if false then insert 
			IF NOT EXISTS ( SELECT 1
							FROM ExchangeDailyOanda WITH (NOLOCK)
							WHERE ExchangeId = @ExchangeId
							  AND ExchangeDate = @date
							  AND Code = @Code )
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
					, MXN
					, NGN
					, BRL
					, RepUpdateTime
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
					, @MXN * @MultipliedBy
					, @NGN * @MultipliedBy
					, @BRL * @MultipliedBy
					, dbo.f_GetDateTime2()
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
					, MXN = @MXN * @MultipliedBy
					, NGN = @NGN * @MultipliedBy
					, BRL = @BRL * @MultipliedBy
					, RepUpdateTime = dbo.f_GetDateTime2()
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

	-- Insert UUS
	IF NOT EXISTS ( SELECT 1
					FROM ExchangeDailyOanda WITH (NOLOCK)
					WHERE ExchangeDate = @date
					  AND ExchangeId = 20
					  AND Code = 'UUS')
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
			, MXN
			, NGN
			, BRL
			, RepUpdateTime
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
			, 2e-101
			, 2e-101
			, 2e-101
			, 2e-101
			, 2e-101
			, 2e-101
			, 2e-101
			, 2e-101
			, 2e-101
			, dbo.f_GetDateTime2()
		)
	END

	-- Insert BTS
	IF NOT EXISTS ( SELECT 1
					FROM ExchangeDailyOanda WITH (NOLOCK)
					WHERE ExchangeDate = @date
					  AND ExchangeId = 218
					  AND Code = 'BTS')
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
			, MXN
			, NGN
			, BRL
			, RepUpdateTime
		)
		VALUES (
			218
			, @date
			, 'BTS'
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
			, 2e-101
			, 2e-101
			, 2e-101
			, 2e-101
			, 2e-101
			, 2e-101
			, 2e-101
			, 2e-101
			, 2e-101
			, dbo.f_GetDateTime2()
		)
	END

	-- Insert YNG
	IF @Code = 'VND'
	BEGIN
		SELECT @ExchangeId = ExchangeId
			 , @MultipliedBy = 1
		FROM Exchange WITH (NOLOCK) 
		WHERE Code = 'YNG'

		IF NOT EXISTS ( SELECT 1
						FROM ExchangeDailyOanda WITH (NOLOCK)
						WHERE ExchangeId = @ExchangeId
						  AND ExchangeDate = @date
						  AND Code = 'YNG')
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
				, MXN
				, NGN
				, BRL
				, RepUpdateTime
			)
			VALUES (
				@ExchangeId
				, @date
				, 'YNG'
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
				, @MXN * @MultipliedBy
				, @NGN * @MultipliedBy
				, @BRL * @MultipliedBy
				, dbo.f_GetDateTime2()
			)
		END
		ELSE
		BEGIN
			UPDATE ExchangeDailyOanda WITH (ROWLOCK , UPDLOCK)
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
				, MXN = @MXN * @MultipliedBy
				, NGN = @NGN * @MultipliedBy
				, BRL = @BRL * @MultipliedBy
				, RepUpdateTime = dbo.f_GetDateTime2()
			WHERE ExchangeId = @ExchangeId
			  AND ExchangeDate = @date
			  AND Code = 'YNG'
		END

		IF @@Error <> 0
		BEGIN
			SELECT @ErrMsg = 'Exchange rate insert fail.'
				 , @ErrCode = 100

			RETURN
		END
	END

	-- Insert SBC
	IF @Code = 'USD'
	BEGIN
		SELECT @ExchangeId = ExchangeId
			  ,@MultipliedBy = 0.01 
		FROM Exchange WITH (NOLOCK) 
		WHERE Code = 'SBC'

		IF NOT EXISTS ( SELECT 1
						FROM ExchangeDailyOanda WITH (NOLOCK)
						WHERE ExchangeId = @ExchangeId
						  AND ExchangeDate = @date
						  AND Code = 'SBC')
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
				, MXN
				, NGN
				, BRL
				, RepUpdateTime
			)
			VALUES (
				@ExchangeId
				, @date
				, 'SBC'
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
				, @MXN * @MultipliedBy
				, @NGN * @MultipliedBy
				, @BRL * @MultipliedBy
				, dbo.f_GetDateTime2()
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
				, MXN = @MXN * @MultipliedBy
				, NGN = @NGN * @MultipliedBy
				, BRL = @BRL * @MultipliedBy
				, RepUpdateTime = dbo.f_GetDateTime2()
			WHERE ExchangeId = @ExchangeId
			  AND ExchangeDate = @date
			  AND Code = 'SBC'
		END

		IF @@Error <> 0
		BEGIN
			SELECT @ErrMsg = 'Exchange rate insert fail.'
				 , @ErrCode = 100

			RETURN
		END
	END

	-- Insert DIA
	IF @Code = 'CNY'
	BEGIN
		SELECT @ExchangeId = ExchangeId
			  ,@MultipliedBy = 0.125 
		FROM Exchange WITH (NOLOCK) 
		WHERE Code = 'DIA'

		IF NOT EXISTS ( SELECT 1
						FROM ExchangeDailyOanda WITH (NOLOCK)
						WHERE ExchangeId = @ExchangeId
						  AND ExchangeDate = @date
						  AND Code = 'DIA' )
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
				, MXN
				, NGN
				, BRL
				, RepUpdateTime
			)
			VALUES (
				@ExchangeId
				, @date
				, 'DIA'
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
				, @MXN * @MultipliedBy
				, @NGN * @MultipliedBy
				, @BRL * @MultipliedBy
				, dbo.f_GetDateTime2()
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
				, MXN = @MXN * @MultipliedBy
				, NGN = @NGN * @MultipliedBy
				, BRL = @BRL * @MultipliedBy
				, RepUpdateTime = dbo.f_GetDateTime2()
			WHERE ExchangeId = @ExchangeId
			  AND ExchangeDate = @date
			  AND Code = 'DIA'
		END

		IF @@Error <> 0
		BEGIN
			SELECT @ErrMsg = 'Exchange rate insert fail.'
				 , @ErrCode = 100

			RETURN
		END
	END
END
GO