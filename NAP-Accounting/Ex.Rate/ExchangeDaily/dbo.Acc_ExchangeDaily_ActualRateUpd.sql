/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,wsv_nap" viewers="" isFunction="0" isNested="1"></info>*/
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
	- 20140625@Jim: fix bug Conversion failed when converting character string to smalldatetime data type. (hot fix #18216)
	- 20220915@Evan: Support crypto  [Redmine: #177481]  

*/		
SET NOCOUNT ON
DECLARE @exchange TABLE(id int identity(1,1), exchangeid int,MultipliedBy int)
DECLARE @date smalldatetime
DECLARE @tmpTable TABLE(currency INT, actualrate FLOAT)
set @date = CONVERT(VARCHAR(10), CURRENT_TIMESTAMP, 120)


-- update ExchangeDaily actualrate from table exchange for today
UPDATE e
SET e.actualrate = ex.actualrate
FROM
    ExchangeDailyOanda e WITH (ROWLOCK,UPDLOCK)
    INNER JOIN exchange ex (NOLOCK) ON e.ExchangeId = ex.exchangeid AND e.ExchangeDate = @date
WHERE ex.CurrencyType <> 1

-- update ExchangeDaily actualrate from table exchange for tomorrow
UPDATE e
SET e.actualrate = ex.actualrate
FROM
    ExchangeDailyOanda e WITH (ROWLOCK,UPDLOCK)
    INNER JOIN exchange ex (NOLOCK) ON e.ExchangeId = ex.exchangeid AND e.ExchangeDate =DATEADD(dd,1,@date)
WHERE ex.CurrencyType <> 1
GO
