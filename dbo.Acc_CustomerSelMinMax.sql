/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,bodbDownlineNet,bodbExtAccNet,bodbDownlineNetView" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerSelMinMax]
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
	@MinBetv1MP money output, @MaxBetv1MP money output, @MaxPerMatchv1MP money output,	
	@MinBetv161 money output, @MaxBetv161 money output, @MaxPerMatchv161 money output, @MaxPerBallv161 money output,
	@MinBetv164 money output, @MaxBetv164 money output, @MaxPerMatchv164 money output
AS
/*
Created: 20110427@Simon
Task : Select customer minbet, maxbet, maxpermatch. 
DB: DBCUST/CUSTDB
Original:

Revisions:
    - 20131011@Elodie: Add HR Fixed Odds [Redmine:#6505]
    - 20161109@Helen: Separate Bet Setting for Soccer - Parlay - [Redmine:66265]
    - 20180125@Winnie: Hide inactive products [RedmineID: #86086]
	- 20181106@Johnson: add Happy 5 [Redmine: #104006]
Param's Explanation:
• @custid: custid that need to be viewed.   
*/
BEGIN
	SET NOCOUNT ON

	Select
		@MinBet = isnull(MinBet,0), 
		@MaxBet = isnull(MaxBet,0)
	from custsetting WITH (NOLOCK)
	where custid = @CustID and bettype = 1 and sporttype=1

	Select 
		@MinBetv2 = isnull(MinBet,0), 
		@MaxBetv2 = isnull(MaxBet,0)
	from custsetting WITH (NOLOCK)		
	where custid = @CustID and bettype = 1 and sporttype=2

	Select 
		@MinBetv3 = isnull(MinBet,0), 
		@MaxBetv3 = isnull(MaxBet,0)
	from custsetting WITH (NOLOCK)
	where custid = @CustID and bettype = 1 and sporttype=3

	Select 
		@MinBetv5 = isnull(MinBet,0), 
		@MaxBetv5 = isnull(MaxBet,0)
	from custsetting WITH (NOLOCK)
	where custid = @CustID and bettype = 1 and sporttype=5

	Select 
		@MinBetv8 = isnull(MinBet,0), 
		@MaxBetv8 = isnull(MaxBet,0)
	from custsetting WITH (NOLOCK)
	where custid = @CustID and bettype = 1 and sporttype=8

	Select 
		@MinBetv10 = isnull(MinBet,0), 
		@MaxBetv10 = isnull(MaxBet,0)
	from custsetting WITH (NOLOCK)
	where custid = @CustID and bettype = 1 and sporttype=10

	Select 
		@MinBetv11 = isnull(MinBet,0), 
		@MaxBetv11 = isnull(MaxBet,0)
	from custsetting WITH (NOLOCK)
	where custid = @CustID and bettype = 1 and sporttype=11

	Select 
		@MinBetv99 = isnull(MinBet,0), 
		@MaxBetv99 = isnull(MaxBet,0)
	from custsetting WITH (NOLOCK)
	where custid = @CustID and bettype = 1 and sporttype=99

	Select 
		@MinBetv99MP = isnull(MinBet,0), 
		@MaxBetv99MP = isnull(MaxBet,0)
	from custsetting WITH (NOLOCK)
	where custid = @CustID and bettype = 9 and sporttype=99

	Select 
		@MinBetv1MP = isnull(MinBet,0), 
		@MaxBetv1MP = isnull(MaxBet,0)
	from custsetting WITH (NOLOCK)
	where custid = @CustID and bettype = 9 and sporttype=1


	Select 
		@MinBetv161 = isnull(MinBet,0), 
		@MaxBetv161 = isnull(MaxBet,0)
	from custsetting3rd WITH (NOLOCK)
	where custid = @CustID and bettype = 81 and sporttype=161
	
	Select 
		@MinBetv164 = isnull(MinBet,0), 
		@MaxBetv164 = isnull(MaxBet,0)
	from custsetting3rd WITH (NOLOCK)
	where custid = @CustID and bettype = 8101 and sporttype=164

	--MAX PER MATCH
	Select 
		@MaxperMatch = MaxPerMatch, 
		@MaxPerMatchv2 = MaxPerMatch2, 
		@MaxPerMatchv3 = MaxPerMatch3, 
		@MaxPerMatchv5 = MaxPerMatch5, 
		@MaxPerMatchv8 = MaxPerMatch8, 
		@MaxPerMatchv10 = MaxPerMatch10, 
		@MaxPerMatchv11 = MaxPerMatch11, 
		@MaxPerMatchv99 = MaxPerMatch99,
		@MaxPerMatchv99MP = MaxPerMatch99MP,
		@MaxPerMatchv1MP = MaxPerMatch1MP,		
		@MaxPerMatchv161 = MaxPerMatch161,
		@MaxPerBallv161 = MaxPerBall161,
		@MaxPerMatchv164 = MaxPerMatch164
	from custinfo WITH (NOLOCK) 
	where custid = @CustID

END
GO
