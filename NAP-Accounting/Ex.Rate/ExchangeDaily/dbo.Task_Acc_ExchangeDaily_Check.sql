ALTER PROCEDURE [dbo].[Task_Acc_ExchangeDaily_Check]
@InputDate datetime
AS
/*
Created: Henry
Task : Check the table ExchangeDaily for yesterday + the day before yesterday insertion
DB: DB052.bodb02
Revisions:
	- 20110322@Henry: add one more base currency: CNY
	- 20120427@Henry: check data from new table ExchangeDailyOanda instead of ExchangeDaily
	- 20140530@Don: 
		+ Exclude currencies 27 & 28 when compare number of currencies between Exchange & ExchangeDailyOanda
		+ Add a check on [3 In case, @InputDate equals today check if data for next day are ok (job runs at 11:35 PM daily)] 
	- 20140602@Don: Include currency 20 when calculate @ExchangeCount
*/		
SET NOCOUNT ON

declare @error varchar(1000)


if exists(
select 1 
from exchange e (nolock)
where 
	isnull(Code,'') <> '' and 
	not exists (
		select * from dbo.ExchangeDailyOanda o (nolock)
		where exchangedate = @InputDate and e.exchangeid = o.ExchangeId			
	) and
	exchangeid not in (27, 28)
)
--raise error if not exist
begin
	set @error = 'One or some of the ExchangeId of table Exchange could not get inserted to table ExchangeDailyOanda for job on date: ' + Cast(@InputDate  as varchar(50)) 
	RAISERROR(@error,16,1)
end
-- 2 Check value
if exists(
select 1 from ExchangeDailyOanda (nolock)
	where 
		exchangedate = @InputDate and 
		(isnull(Code,'') = ''
		OR isnull(MYR,0) = 0
		OR isnull(USD,0) = 0
		OR isnull(EUR,0) = 0
		OR isnull(CNY,0) = 0
		)	
)
begin
	set @error = 'One or some values of table ExchangeDailyOanda could not get inserted properly for job on date: ' + Cast(@InputDate  as varchar(50))
	RAISERROR(@error,16,1)
end
-- 3 In case, @InputDate equals today check if data for next day are ok (job runs at 11:35 PM daily)
declare @tmpDay smalldatetime
declare @tmpTomorrow smalldatetime
declare @ExchangeCount int, @OandaCount int
set @tmpDay = convert(varchar(10), @InputDate, 120)
set @tmpTomorrow = convert(varchar(10), dateadd(day, 1, getdate()), 120)
if (@tmpTomorrow = dateadd(day, 1, @tmpDay))
begin
	select @ExchangeCount = count(*) 
	from dbo.Exchange (nolock) 
	where exchangeid not in (27, 28)
		and (isnull(Code, '') <> '' or exchangeid = 20)

	select @OandaCount = count(*) 
	from dbo.ExchangeDailyOanda (nolock) 
	where ExchangeDate = @tmpTomorrow

	if (@ExchangeCount <> @OandaCount)
	begin
		set @error = 'ExchangeDailyOanda does not have data for job on date: ' + Cast(@tmpTomorrow  as varchar(50))
		RAISERROR(@error,16,1)
	end
end
	


GO
GRANT VIEW DEFINITION ON [dbo].[Task_Acc_ExchangeDaily_Check] TO [vnteam]