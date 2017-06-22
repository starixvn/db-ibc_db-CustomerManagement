ALTER PROCEDURE [dbo].[Acc_ExchangeDailyIns]
	@Code varchar(5),
	@MYR float,
	@USD float,
	@EUR float,
	@CNY float,
	@IDR float,
	@AUD float,
	@CHF float,
	@GBP float,
	@SGD float,
	@THB float,
	@VND float,
	@KRW float,
	@JPY float,
	@rundate datetime = null,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
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
*/		
SET NOCOUNT ON
DECLARE @exchange TABLE(id int identity(1,1), exchangeid int,MultipliedBy int)
DECLARE @date datetime

IF @rundate is null
	set @date = convert(datetime,convert(nvarchar(20), getdate(), 101))
ELSE
	set @date = convert(datetime,convert(nvarchar(20), @rundate, 101))


IF @Code = 'UUS'
BEGIN
	IF NOT EXISTS (SELECT 1 FROM ExchangeDailyOanda (nolock) WHERE ExchangeDate=@date AND ExchangeId = 20  )
	BEGIN
		INSERT INTO ExchangeDailyOanda (ExchangeId,ExchangeDate,Code,MYR,USD,EUR,CNY,IDR,AUD,CHF,GBP,SGD,THB,VND,KRW,JPY)
		VALUES (20,@date,'UUS',2E-101,2E-101,2E-101,2E-101,2E-101,2E-101,2E-101,2E-101,2E-101,2E-101,2E-101,2E-101,2E-101)
	END
	ELSE
	BEGIN
		UPDATE ExchangeDailyOanda with (rowlock,updlock)
		SET 
			MYR = 2E-101,
			USD = 2E-101,
			EUR = 2E-101,
			CNY = 2E-101,
			IDR = 2E-101,
			AUD = 2E-101,
			CHF = 2E-101,
			GBP = 2E-101,
			SGD = 2E-101,
			THB = 2E-101,
			VND = 2E-101,
			KRW = 2E-101,
			JPY = 2E-101
		WHERE ExchangeId = 20 AND ExchangeDate=@date 
	END
	
	RETURN
END

INSERT INTO @exchange(exchangeid, MultipliedBy)
SELECT 
	exchangeid, MultipliedBy 
FROM exchange (nolock)
WHERE Code = @Code

IF @@ROWCOUNT > 0
BEGIN
	DECLARE @i int, @max int, @ExchangeId int, @MultipliedBy int
	SET @i = 1
	SELECT @max = count(1) from @exchange
	
	WHILE (@i<=@max)
	BEGIN
		SELECT 
			@ExchangeId = exchangeid , 
			@MultipliedBy = MultipliedBy 
		FROM @exchange
		WHERE id = @i
		
		--Check exist, if false then insert 
		IF NOT EXISTS (SELECT 1 FROM ExchangeDailyOanda (nolock) WHERE ExchangeId = @ExchangeId AND ExchangeDate=@date AND Code=@Code )
		BEGIN
			INSERT INTO ExchangeDailyOanda (ExchangeId,ExchangeDate,Code,MYR,USD,EUR,CNY,IDR,AUD,CHF,GBP,SGD,THB,VND,KRW,JPY)
			VALUES (@ExchangeId,@date,@Code,@MYR * @MultipliedBy,@USD * @MultipliedBy,@EUR * @MultipliedBy,@CNY * @MultipliedBy
											,@IDR * @MultipliedBy
											,@AUD * @MultipliedBy
											,@CHF * @MultipliedBy
											,@GBP * @MultipliedBy
											,@SGD * @MultipliedBy
											,@THB * @MultipliedBy
											,@VND * @MultipliedBy
											,@KRW * @MultipliedBy
											,@JPY * @MultipliedBy
											)
		END
		ELSE
		BEGIN
			UPDATE ExchangeDailyOanda with (rowlock,updlock)
			SET 
				MYR = @MYR * @MultipliedBy,
				USD = @USD * @MultipliedBy,
				EUR = @EUR * @MultipliedBy,
				CNY = @CNY * @MultipliedBy,
				IDR = @IDR * @MultipliedBy,
				AUD = @AUD * @MultipliedBy,
				CHF = @CHF * @MultipliedBy,
				GBP = @GBP * @MultipliedBy,
				SGD = @SGD * @MultipliedBy,
				THB = @THB * @MultipliedBy,
				VND = @VND * @MultipliedBy,
				KRW = @KRW * @MultipliedBy,
				JPY = @JPY * @MultipliedBy				
			WHERE ExchangeId = @ExchangeId AND ExchangeDate=@date AND Code=@Code
		END
		
		if @@Error <> 0
		BEGIN
			Select @ErrMsg = 'Exchange rate insert fail.'
				 ,@ErrCode = 100
			return
		END
		
		SET @i = @i + 1
	END
	
END

GO
GRANT EXECUTE ON [dbo].[Acc_ExchangeDailyIns] TO [bodbAdminNet] 
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_ExchangeDailyIns] TO [vnteam]