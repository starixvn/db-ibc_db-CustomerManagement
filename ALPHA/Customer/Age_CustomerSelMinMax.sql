 ALTER PROCEDURE [dbo].[Age_CustomerSelMinMax]
	@custid int,	
	@MinBet money output, @MaxBet money output, @MaxPerMatch money output,
	@MinBetv2 money output, @MaxBetv2 money output, @MaxPerMatchv2 money output,
	@MinBetv3 money output, @MaxBetv3 money output, @MaxPerMatchv3 money output,
	@MinBetv5 money output, @MaxBetv5 money output, @MaxPerMatchv5 money output,
	@MinBetv8 money output, @MaxBetv8 money output, @MaxPerMatchv8 money output,
	@MinBetv10 money output, @MaxBetv10 money output, @MaxPerMatchv10 money output,
	@MinBetv11 money output, @MaxBetv11 money output, @MaxPerMatchv11 money output,
	@MinBetv99 money output, @MaxBetv99 money output, @MaxPerMatchv99 money output,
	@MinBetv99MP money output, @MaxBetv99MP money output, @MaxPerMatchv99MP money output,
	@MinBetv161 money output, @MaxBetv161 money output, @MaxPerMatchv161 money output, @MaxPerBallv161 money output
AS
/*
Created: 20110427@Simon
Task : Select customer minbet, maxbet, maxpermatch. 
DB: DB05.bodb02
Original:

Revisions:
    
Param's Explanation:
• @custid: custid that need to be viewed.   
*/

SET NOCOUNT ON

Select
	@MinBet = Max(case when MinBet is NULL then 0 else MinBet end), 
	@MaxBet = Min(case when MaxBet = 0 then NULL else MaxBet end)
from custsetting WITH (NOLOCK)
where custid = @CustID and bettype = 1 and sporttype=1

Select 
	@MinBetv2 = Max(case when MinBet is NULL then 0 else MinBet end), 
	@MaxBetv2 = Min(case when MaxBet = 0 then NULL else MaxBet end)
from custsetting WITH (NOLOCK)		
where custid = @CustID and bettype = 1 and sporttype=2

Select 
	@MinBetv3 = Max(case when MinBet is NULL then 0 else MinBet end), 
	@MaxBetv3 = Min(case when MaxBet = 0 then NULL else MaxBet end)
from custsetting WITH (NOLOCK)
where custid = @CustID and bettype = 1 and sporttype=3

Select 
	@MinBetv5 = Max(case when MinBet is NULL then 0 else MinBet end), 
	@MaxBetv5 = Min(case when MaxBet = 0 then NULL else MaxBet end)
from custsetting WITH (NOLOCK)
where custid = @CustID and bettype = 1 and sporttype=5

Select 
	@MinBetv8 = Max(case when MinBet is NULL then 0 else MinBet end), 
	@MaxBetv8 = Min(case when MaxBet = 0 then NULL else MaxBet end)
from custsetting WITH (NOLOCK)
where custid = @CustID and bettype = 1 and sporttype=8

Select 
	@MinBetv10 = Max(case when MinBet is NULL then 0 else MinBet end), 
	@MaxBetv10 = Min(case when MaxBet = 0 then NULL else MaxBet end)
from custsetting WITH (NOLOCK)
where custid = @CustID and bettype = 1 and sporttype=10

Select 
	@MinBetv11 = Max(case when MinBet is NULL then 0 else MinBet end), 
	@MaxBetv11 = Min(case when MaxBet = 0 then NULL else MaxBet end)
from custsetting WITH (NOLOCK)
where custid = @CustID and bettype = 1 and sporttype=11


Select 
	@MinBetv99 = Max(case when MinBet is NULL then 0 else MinBet end), 
	@MaxBetv99 = Min(case when MaxBet = 0 then NULL else MaxBet end)
from custsetting WITH (NOLOCK)
where custid = @CustID and bettype = 1 and sporttype=99

Select 
	@MinBetv99MP = Max(case when MinBet is NULL then 0 else MinBet end), 
	@MaxBetv99MP = Min(case when MaxBet = 0 then NULL else MaxBet end)
from custsetting WITH (NOLOCK)
where custid = @CustID and bettype = 9 and sporttype=99

Select 
	@MinBetv161 = Max(case when MinBet is NULL then 0 else MinBet end), 
	@MaxBetv161 = Min(case when MaxBet = 0 then NULL else MaxBet end)
from custsetting3rd WITH (NOLOCK)
where custid = @CustID and bettype = 81 and sporttype=161


--MAX PER MATCH
Select 
	@MaxperMatch = Min(case when MaxPerMatch is NULL then 0 else MaxPerMatch end), 
	@MaxPerMatchv2 = Min(case when MaxPerMatch2 is NULL then 0 else MaxPerMatch2 end), 
	@MaxPerMatchv3 = Min(case when MaxPerMatch3 is NULL then 0 else MaxPerMatch3 end), 
	@MaxPerMatchv5 = Min(case when MaxPerMatch5 is NULL then 0 else MaxPerMatch5 end), 
	@MaxPerMatchv8 = Min(case when MaxPerMatch8 is NULL then 0 else MaxPerMatch8 end), 
	@MaxPerMatchv10 = Min(case when MaxPerMatch10 is NULL then 0 else MaxPerMatch10 end), 
	@MaxPerMatchv11 = Min(case when MaxPerMatch11 is NULL then 0 else MaxPerMatch11 end), 
	@MaxPerMatchv99 = Min(case when MaxPerMatch99 is NULL then 0 else MaxPerMatch99 end),
	@MaxPerMatchv99MP = Min(case when MaxPerMatch99MP is NULL then 0 else MaxPerMatch99MP end),
	@MaxPerMatchv161 = Min(case when MaxPerMatch161 is NULL then 0 else MaxPerMatch161 end),
	@MaxPerBallv161 = MIN(CASE WHEN MaxPerBall161 is NULL then 0 else MaxPerBall161 END)
from custinfo WITH (NOLOCK) 
where custid = @CustID


GO
GRANT EXECUTE ON [dbo].[Age_CustomerSelMinMax] TO [wsv_alp]
GO
GRANT EXECUTE ON [dbo].[Age_CustomerSelMinMax] TO [bodbDownlineNetView,wsv_alpv]
GO
GRANT EXECUTE ON [dbo].[Age_CustomerSelMinMax] TO [wsv_nap]
GO
GRANT VIEW DEFINITION ON [dbo].[Age_CustomerSelMinMax] TO vnteam 