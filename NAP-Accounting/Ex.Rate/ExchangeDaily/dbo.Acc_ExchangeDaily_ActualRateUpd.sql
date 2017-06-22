USE [CustDB]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Acc_ExchangeDaily_ActualRateUpd]
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
/*
Created: Henry
Task : Daily update ActualRate of ExchangeDaily
DB: DBTRANS.BODB02 
Revisions:
	- 20120427@Henry: get data from ExchangeDailyOanda instead of ExchangeDaily
	- 20120516@Henry: raise error when a currency got more than 1 actual rate in bettrans table
	- 20131108@Elodie: Splitting bodb02 into CustDB (call bettrans by link database)
	- 20140625@Jim: fix bug Conversion failed when converting character string to smalldatetime data type. (hot fix #18216)
*/		
SET NOCOUNT ON
DECLARE @exchange TABLE(id int identity(1,1), exchangeid int,MultipliedBy int)
DECLARE @date smalldatetime
DECLARE @tmpTable TABLE(currency INT, actualrate FLOAT)
set @date = CONVERT(VARCHAR(10), CURRENT_TIMESTAMP, 120)


--1 update ExchangeDaily actualrate from table exchange for tomorrow
UPDATE e
SET e.actualrate = ex.actualrate
FROM
    ExchangeDailyOanda e WITH (ROWLOCK,UPDLOCK)
    INNER JOIN exchange ex (NOLOCK) ON e.ExchangeId = ex.exchangeid AND e.ExchangeDate =DATEADD(dd,1,@date)

--2 update ExchangeDaily actualrate from table exchange for today
UPDATE e
SET e.actualrate = ex.actualrate
FROM
    ExchangeDailyOanda e WITH (ROWLOCK,UPDLOCK)
    INNER JOIN exchange ex (NOLOCK) ON e.ExchangeId = ex.exchangeid AND e.ExchangeDate = @date

/* --20140625@jim: no need update old-data, we'll correct it by manually

--3 update yesterday actualrate  from bettrans
INSERT INTO @tmpTable(currency,actualrate)
select distinct currency, actualrate
		from bodb02.dbo.bettrans with (nolock) where winlostdate = DATEADD(dd,-1,@date) 

IF EXISTS(
	select currency FROM @tmpTable
	group by currency
	having count(currency) > 1
	)
BEGIN
	Select @ErrMsg = 'There are more than 1 actual rate for a currency in bettrans table on date: ' + CONVERT(VARCHAR(50),DATEADD(dd,-1,@date))
				 ,@ErrCode = 100
			return
	RETURN
END	

UPDATE e
SET e.actualrate = b.actualrate
	FROM ExchangeDailyOanda e WITH (ROWLOCK,UPDLOCK) INNER JOIN 
	@tmpTable b
	ON e.ExchangeId = b.currency AND e.ExchangeDate = DATEADD(dd,-1,@date)
	
--4 update the day before yesterday actualrate from bettrans    
DELETE FROM @tmpTable
INSERT INTO @tmpTable(currency,actualrate)
select distinct currency, actualrate
		from bodb02.dbo.bettrans with (nolock) where winlostdate = DATEADD(dd,-2,@date) 

IF EXISTS(
	select currency FROM @tmpTable
	group by currency
	having count(currency) > 1
	)
BEGIN
	Select @ErrMsg = 'There are more than 1 actual rate for a currency in bettrans table on date: ' + CONVERT(VARCHAR(50),DATEADD(dd,-2,@date))
				 ,@ErrCode = 100
			return
	RETURN
END	

UPDATE e
SET e.actualrate = b.actualrate
	FROM ExchangeDailyOanda e WITH (ROWLOCK,UPDLOCK) INNER JOIN 
	@tmpTable b
	ON e.ExchangeId = b.currency AND e.ExchangeDate = DATEADD(dd,-2,@date)
*/
GO
GRANT EXECUTE ON [dbo].[Acc_ExchangeDaily_ActualRateUpd] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_ExchangeDaily_ActualRateUpd] TO [vnteam] AS [dbo]