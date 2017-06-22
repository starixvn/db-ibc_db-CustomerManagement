ALTER PROCEDURE [dbo].[Age_CustomerSelMinMaxLimit]
	@custid int,
	@userid int,
	@MinBet_Max money output, @MaxBet_Min money output, @MaxPerMatch_Min money = 0 output, @MaxPerMatch_Max money output,
	@MinBetv2_Max money output, @MaxBetv2_Min money output, @MaxPerMatchv2_Min money = 0  output, @MaxPerMatchv2_Max money output,
	@MinBetv3_Max money output, @MaxBetv3_Min money output, @MaxPerMatchv3_Min money = 0  output, @MaxPerMatchv3_Max money output,
	@MinBetv5_Max money output, @MaxBetv5_Min money output, @MaxPerMatchv5_Min money = 0  output, @MaxPerMatchv5_Max money output,
	@MinBetv8_Max money output, @MaxBetv8_Min money output, @MaxPerMatchv8_Min money = 0  output, @MaxPerMatchv8_Max money output,
	@MinBetv10_Max money output, @MaxBetv10_Min money output, @MaxPerMatchv10_Min money = 0  output, @MaxPerMatchv10_Max money output,
	@MinBetv11_Max money output, @MaxBetv11_Min money output, @MaxPerMatchv11_Min money = 0  output, @MaxPerMatchv11_Max money output,
	@MinBetv99_Max money output, @MaxBetv99_Min money output, @MaxPerMatchv99_Min money = 0  output, @MaxPerMatchv99_Max money output,	
	@MinBetv99MP_Max money output, @MaxBetv99MP_Min money output, @MaxPerMatchv99MP_Min money = 0  output, @MaxPerMatchv99MP_Max money output,
	@MinBetv1MP_Max money output, @MaxBetv1MP_Min money output, @MaxPerMatchv1MP_Min money = 0  output, @MaxPerMatchv1MP_Max money output,
	@MinBetv154_Max money  = 0  output, @MaxBetv154_Min money   = 0 output, @MaxPerMatchv154_Min money  = 0  output, @MaxPerMatchv154_Max money = 0 output,	
	@MinBetv161_Max money output, @MaxBetv161_Min money output, @MaxPerMatchv161_Min money = 0  output, @MaxPerMatchv161_Max money = 0 output, @MaxPerBallv161_Min money = 0 output, @MaxPerBallv161_Max money = 0 output
AS
/*
Created: 20090714@nqminh
Task : Select customer minbet_max, maxbet_min, maxpermatch_min, maxpermatch_max 
DB: DBCUST.CustDB
Original:

Revisions:
	- 20090122@[Reviewer]: [Description of revision]
	- 20100919@Terry: Add Number Game and Mixed Sport
	- 20101029@Johnson: Include max per ball for number game
	- 20131011@Elodie: Add HR Fixed Odds [Redmine:#6505]
	- 20161109@Helen: Separate Bet Setting for Soccer - Parlay - [Redmine:66265]
Param's Explanation:
• @custid: custid that need to be viewed.   
*/

SET NOCOUNT ON

Declare @RoleId int
Select @RoleId = RoleId 
From CustInfo (nolock)
Where CustId = @CustID

If (@RoleId = 1)
Begin
	Select
		@MinBet_Max = Max(case when MinBet = 0 then NULL else MinBet end), 
		@MaxBet_Min = Min(case when MaxBet = 0 then NULL else MaxBet end)
	from 
		custsetting as cs WITH (NOLOCK)
		INNER JOIN custinfo as ci WITH (NOLOCK) on 
			(cs.CustID = ci.Recommend or cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend)
		and cs.bettype = 1 and cs.sporttype=1
	where ci.custid = @CustID

	Select 
		@MinBetv2_Max = Max(case when MinBet = 0 then NULL else MinBet end), 
		@MaxBetv2_Min = Min(case when MaxBet = 0 then NULL else MaxBet end)
	from 
		custsetting as cs WITH (NOLOCK)
		INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.Recommend or cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend)
		and cs.bettype = 1 and cs.sporttype=2
	where ci.custid = @CustID

	Select 
		@MinBetv3_Max = Max(case when MinBet = 0 then NULL else MinBet end), 
		@MaxBetv3_Min = Min(case when MaxBet = 0 then NULL else MaxBet end)
	from 
		custsetting as cs WITH (NOLOCK)
		INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.Recommend or cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend)
		and cs.bettype = 1 and cs.sporttype=3
	where ci.custid = @CustID

	Select 
		@MinBetv5_Max = Max(case when MinBet = 0 then NULL else MinBet end), 
		@MaxBetv5_Min = Min(case when MaxBet = 0 then NULL else MaxBet end)
	from 
		custsetting as cs WITH (NOLOCK)
		INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.Recommend or cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend)
		and cs.bettype = 1 and cs.sporttype=5
	where ci.custid = @CustID

	Select 
		@MinBetv8_Max = Max(case when MinBet = 0 then NULL else MinBet end), 
		@MaxBetv8_Min = Min(case when MaxBet = 0 then NULL else MaxBet end)
	from 
		custsetting as cs WITH (NOLOCK)
		INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.Recommend or cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend)
		and cs.bettype = 1 and cs.sporttype=8
	where ci.custid = @CustID

	Select 
		@MinBetv10_Max = Max(case when MinBet = 0 then NULL else MinBet end), 
		@MaxBetv10_Min = Min(case when MaxBet = 0 then NULL else MaxBet end)
	from 
		custsetting as cs WITH (NOLOCK)
		INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.Recommend or cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend)
		and cs.bettype = 1 and cs.sporttype=10
	where ci.custid = @CustID

	Select 
		@MinBetv11_Max = Max(case when MinBet = 0 then NULL else MinBet end), 
		@MaxBetv11_Min = Min(case when MaxBet = 0 then NULL else MaxBet end)
	from 
		custsetting as cs WITH (NOLOCK)
		INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.Recommend or cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend)
		and cs.bettype = 1 and cs.sporttype=11
	where ci.custid = @CustID


	Select 
		@MinBetv99_Max = Max(case when MinBet = 0 then NULL else MinBet end), 
		@MaxBetv99_Min = Min(case when MaxBet = 0 then NULL else MaxBet end)
	from 
		custsetting as cs WITH (NOLOCK)
		INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.Recommend or cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend)
		and cs.bettype = 1 and cs.sporttype=99
	where ci.custid = @CustID
	
	Select 
		@MinBetv99MP_Max = Max(case when MinBet = 0 then NULL else MinBet end), 
		@MaxBetv99MP_Min = Min(case when MaxBet = 0 then NULL else MaxBet end)
	from 
		custsetting as cs WITH (NOLOCK)
		INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.Recommend or cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend)
		and cs.bettype = 9 and cs.sporttype=99
	where ci.custid = @CustID	
	
	Select 
		@MinBetv1MP_Max = Max(case when MinBet = 0 then NULL else MinBet end), 
		@MaxBetv1MP_Min = Min(case when MaxBet = 0 then NULL else MaxBet end)
	from 
		custsetting as cs WITH (NOLOCK)
		INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.Recommend or cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend)
		and cs.bettype = 9 and cs.sporttype=1
	where ci.custid = @CustID	
	
	Select 
		@MinBetv154_Max = Max(case when MinBet = 0 then NULL else MinBet end), 
		@MaxBetv154_Min = Min(case when MaxBet = 0 then NULL else MaxBet end)
	from 
		custsetting as cs WITH (NOLOCK)
		INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.Recommend or cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend)
		and cs.bettype = 20 and cs.sporttype=154
	where ci.custid = @CustID
	
	Select 
		@MinBetv161_Max = Max(case when MinBet = 0 then NULL else MinBet end), 
		@MaxBetv161_Min = Min(case when MaxBet = 0 then NULL else MaxBet end)
	from 
		custsetting3rd as cs3 WITH (NOLOCK)
		INNER JOIN custinfo as ci WITH (NOLOCK) on (cs3.CustID = ci.Recommend or cs3.CustID = ci.MRecommend or cs3.CustID = ci.SRecommend)
		and cs3.bettype = 81 and cs3.sporttype=161
	where ci.custid = @CustID


	--MAX PER MATCH
	Select 
		@MaxPerMatch_Min = 0, 	
		@MaxperMatch_Max = Min(case when cs.MaxPerMatch = 0 then NULL else cs.MaxPerMatch end), 
		
		@MaxPerMatchv2_Min = 0,	
		@MaxPerMatchv2_Max = Min(case when cs.MaxPerMatch2 = 0 then NULL else cs.MaxPerMatch2 end), 

		@MaxPerMatchv3_Min = 0,	
		@MaxPerMatchv3_Max = Min(case when cs.MaxPerMatch3 = 0 then NULL else cs.MaxPerMatch3 end), 

		@MaxPerMatchv5_Min = 0,	
		@MaxPerMatchv5_Max = Min(case when cs.MaxPerMatch5 = 0 then NULL else cs.MaxPerMatch5 end), 
		
		@MaxPerMatchv8_Min = 0,	
		@MaxPerMatchv8_Max = Min(case when cs.MaxPerMatch8 = 0 then NULL else cs.MaxPerMatch8 end), 

		@MaxPerMatchv10_Min = 0,	
		@MaxPerMatchv10_Max = Min(case when cs.MaxPerMatch10 = 0 then NULL else cs.MaxPerMatch10 end), 
		
		@MaxPerMatchv11_Min = 0,	
		@MaxPerMatchv11_Max = Min(case when cs.MaxPerMatch11 = 0 then NULL else cs.MaxPerMatch11 end), 

		@MaxPerMatchv99_Min = 0,	
		@MaxPerMatchv99_Max = Min(case when cs.MaxPerMatch99 = 0 then NULL else cs.MaxPerMatch99 end),
		
		@MaxPerMatchv154_Min = 0,	
		@MaxPerMatchv154_Max = Min(case when cs.MaxPerMatch154 = 0 then NULL else cs.MaxPerMatch154 end), 
		
		@MaxPerMatchv161_Min = 0,	
		@MaxPerMatchv161_Max = Min(case when cs.MaxPerMatch161 = 0 then NULL else cs.MaxPerMatch161 end),
		
		@MaxPerBallv161_Min = 0,
		@MaxPerBallv161_Max = MIN(CASE WHEN cs.MaxPerBall161 = 0 THEN NULL ELSE cs.MaxPerBall161 END),
		
		@MaxPerMatchv99MP_Min = 0,	
		@MaxPerMatchv99MP_Max = Min(case when cs.MaxPerMatch99MP = 0 then NULL else cs.MaxPerMatch99MP end),
		
		@MaxPerMatchv1MP_Min = 0,	
		@MaxPerMatchv1MP_Max = Min(case when cs.MaxPerMatch1MP = 0 then NULL else cs.MaxPerMatch1MP end)
		
	from 
		custinfo as cs WITH (NOLOCK) 
		INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.Recommend or cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend)
	where ci.custid = @CustID
End
Else
If (@RoleId = 2)
Begin
	Select
		@MinBet_Max = Max(case when MinBet = 0 then NULL else MinBet end), 
		@MaxBet_Min = Min(case when MaxBet = 0 then NULL else MaxBet end)
	from 
		custsetting as cs WITH (NOLOCK)
		INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend)
		and cs.bettype = 1 and cs.sporttype=1
	where ci.custid = @CustID

	Select 
		@MinBetv2_Max = Max(case when MinBet = 0 then NULL else MinBet end), 
		@MaxBetv2_Min = Min(case when MaxBet = 0 then NULL else MaxBet end)
	from 
		custsetting as cs WITH (NOLOCK)
		INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend)
		and cs.bettype = 1 and cs.sporttype=2
	where ci.custid = @CustID

	Select 
		@MinBetv3_Max = Max(case when MinBet = 0 then NULL else MinBet end), 
		@MaxBetv3_Min = Min(case when MaxBet = 0 then NULL else MaxBet end)
	from 
		custsetting as cs WITH (NOLOCK)
		INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend)
		and cs.bettype = 1 and cs.sporttype=3
	where ci.custid = @CustID

	Select 
		@MinBetv5_Max = Max(case when MinBet = 0 then NULL else MinBet end), 
		@MaxBetv5_Min = Min(case when MaxBet = 0 then NULL else MaxBet end)
	from 
		custsetting as cs WITH (NOLOCK)
		INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend)
		and cs.bettype = 1 and cs.sporttype=5
	where ci.custid = @CustID

	Select 
		@MinBetv8_Max = Max(case when MinBet = 0 then NULL else MinBet end), 
		@MaxBetv8_Min = Min(case when MaxBet = 0 then NULL else MaxBet end)
	from 
		custsetting as cs WITH (NOLOCK)
		INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend)
		and cs.bettype = 1 and cs.sporttype=8
	where ci.custid = @CustID

	Select 
		@MinBetv10_Max = Max(case when MinBet = 0 then NULL else MinBet end), 
		@MaxBetv10_Min = Min(case when MaxBet = 0 then NULL else MaxBet end)
	from 
		custsetting as cs WITH (NOLOCK)
		INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend)
		and cs.bettype = 1 and cs.sporttype=10
	where ci.custid = @CustID

	Select 
		@MinBetv11_Max = Max(case when MinBet = 0 then NULL else MinBet end), 
		@MaxBetv11_Min = Min(case when MaxBet = 0 then NULL else MaxBet end)
	from 
		custsetting as cs WITH (NOLOCK)
		INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend)
		and cs.bettype = 1 and cs.sporttype=11
	where ci.custid = @CustID


	Select 
		@MinBetv99_Max = Max(case when MinBet = 0 then NULL else MinBet end), 
		@MaxBetv99_Min = Min(case when MaxBet = 0 then NULL else MaxBet end)
	from 
		custsetting as cs WITH (NOLOCK)
		INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend)
		and cs.bettype = 1 and cs.sporttype=99
	where ci.custid = @CustID

	Select 
		@MinBetv99MP_Max = Max(case when MinBet = 0 then NULL else MinBet end), 
		@MaxBetv99MP_Min = Min(case when MaxBet = 0 then NULL else MaxBet end)
	from 
		custsetting as cs WITH (NOLOCK)
		INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend)
		and cs.bettype = 9 and cs.sporttype=99
	where ci.custid = @CustID
	
	Select 
		@MinBetv1MP_Max = Max(case when MinBet = 0 then NULL else MinBet end), 
		@MaxBetv1MP_Min = Min(case when MaxBet = 0 then NULL else MaxBet end)
	from 
		custsetting as cs WITH (NOLOCK)
		INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend)
		and cs.bettype = 9 and cs.sporttype=1
	where ci.custid = @CustID
	
	Select 
		@MinBetv154_Max = Max(case when MinBet = 0 then NULL else MinBet end), 
		@MaxBetv154_Min = Min(case when MaxBet = 0 then NULL else MaxBet end)
	from 
		custsetting as cs WITH (NOLOCK)
		INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend)
		and cs.bettype = 20 and cs.sporttype=154
	where ci.custid = @CustID
		
	Select 
		@MinBetv161_Max = Max(case when MinBet = 0 then NULL else MinBet end), 
		@MaxBetv161_Min = Min(case when MaxBet = 0 then NULL else MaxBet end)
	from 
		custsetting3rd as cs3 WITH (NOLOCK)
		INNER JOIN custinfo as ci WITH (NOLOCK) on (cs3.CustID = ci.MRecommend or cs3.CustID = ci.SRecommend)
		and cs3.bettype = 81 and cs3.sporttype=161
	where ci.custid = @CustID



	--MAX PER MATCH
	Select 
		@MaxPerMatch_Min = 0, 	
		@MaxperMatch_Max = Min(case when cs.MaxPerMatch = 0 then NULL else cs.MaxPerMatch end), 
		
		@MaxPerMatchv2_Min = 0,	
		@MaxPerMatchv2_Max = Min(case when cs.MaxPerMatch2 = 0 then NULL else cs.MaxPerMatch2 end), 

		@MaxPerMatchv3_Min = 0,	
		@MaxPerMatchv3_Max = Min(case when cs.MaxPerMatch3 = 0 then NULL else cs.MaxPerMatch3 end), 

		@MaxPerMatchv5_Min = 0,	
		@MaxPerMatchv5_Max = Min(case when cs.MaxPerMatch5 = 0 then NULL else cs.MaxPerMatch5 end), 
		
		@MaxPerMatchv8_Min = 0,	
		@MaxPerMatchv8_Max = Min(case when cs.MaxPerMatch8 = 0 then NULL else cs.MaxPerMatch8 end), 

		@MaxPerMatchv10_Min = 0,	
		@MaxPerMatchv10_Max = Min(case when cs.MaxPerMatch10 = 0 then NULL else cs.MaxPerMatch10 end), 
		
		@MaxPerMatchv11_Min = 0,	
		@MaxPerMatchv11_Max = Min(case when cs.MaxPerMatch11 = 0 then NULL else cs.MaxPerMatch11 end), 

		@MaxPerMatchv99_Min = 0,	
		@MaxPerMatchv99_Max = Min(case when cs.MaxPerMatch99 = 0 then NULL else cs.MaxPerMatch99 end),
		
		@MaxPerMatchv99MP_Min = 0,	
		@MaxPerMatchv99MP_Max = Min(case when cs.MaxPerMatch99MP = 0 then NULL else cs.MaxPerMatch99MP end),
		
		@MaxPerMatchv1MP_Min = 0,	
		@MaxPerMatchv1MP_Max = Min(case when cs.MaxPerMatch1MP = 0 then NULL else cs.MaxPerMatch1MP end),
		
		@MaxPerMatchv154_Min = 0,	
		@MaxPerMatchv154_Max = Min(case when cs.MaxPerMatch154 = 0 then NULL else cs.MaxPerMatch154 end), 
		
		@MaxPerBallv161_Min = 0,
		@MaxPerBallv161_Max = MIN(CASE WHEN cs.MaxPerBall161 = 0 THEN NULL ELSE cs.MaxPerBall161 END),
		
		@MaxPerMatchv161_Min = 0,	
		@MaxPerMatchv161_Max = Min(case when cs.MaxPerMatch161 = 0 then NULL else cs.MaxPerMatch161 end)
		
	from 
		custinfo as cs WITH (NOLOCK) 
		INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend)
	where ci.custid = @CustID
End
Else
If (@RoleId = 3)
Begin
	/*@userid is SRecommendID now*/
	Select 
		@MinBet_Max = MinBet,
		@MaxBet_Min = MaxBet
	from 
		custsetting as cs WITH (NOLOCK)
	where cs.custid = @userid and cs.bettype =  1 and cs.sporttype=1		  
		  
	Select 
		@MinBetv2_Max = MinBet,
		@MaxBetv2_Min = MaxBet
	from 
		custsetting as cs WITH (NOLOCK)
	where cs.custid = @userid and cs.bettype =  1 and cs.sporttype=2

	Select 
		@MinBetv3_Max = MinBet,
		@MaxBetv3_Min = MaxBet
	from 
		custsetting as cs WITH (NOLOCK)
	where cs.custid = @userid and cs.bettype =  1 and cs.sporttype=3

	Select 
		@MinBetv5_Max = MinBet,
		@MaxBetv5_Min = MaxBet
	from 
		custsetting as cs WITH (NOLOCK)
	where cs.custid = @userid and cs.bettype =  1 and cs.sporttype=5

	Select 
		@MinBetv8_Max = MinBet,
		@MaxBetv8_Min = MaxBet
	from 
		custsetting as cs WITH (NOLOCK)
	where cs.custid = @userid and cs.bettype =  1 and cs.sporttype=8

	Select 
		@MinBetv10_Max = MinBet,
		@MaxBetv10_Min = MaxBet
	from 
		custsetting as cs WITH (NOLOCK)
	where cs.custid = @userid and cs.bettype =  1 and cs.sporttype=10

	Select 
		@MinBetv11_Max = MinBet,
		@MaxBetv11_Min = MaxBet
	from 
		custsetting as cs WITH (NOLOCK)
	where cs.custid = @userid and cs.bettype =  1 and cs.sporttype=11

	Select 
		@MinBetv99_Max = MinBet,
		@MaxBetv99_Min = MaxBet
	from 
		custsetting as cs WITH (NOLOCK)
	where cs.custid = @userid and cs.bettype =  1 and cs.sporttype=99
	
	Select 
		@MinBetv99MP_Max = MinBet,
		@MaxBetv99MP_Min = MaxBet
	from 
		custsetting as cs WITH (NOLOCK)
	where cs.custid = @userid and cs.bettype =  9 and cs.sporttype=99
				
	Select 
		@MinBetv1MP_Max = MinBet,
		@MaxBetv1MP_Min = MaxBet
	from 
		custsetting as cs WITH (NOLOCK)
	where cs.custid = @userid and cs.bettype =  9 and cs.sporttype=1
	
	Select 
		@MinBetv154_Max = MinBet,
		@MaxBetv154_Min = MaxBet
	from 
		custsetting as cs WITH (NOLOCK)
	where cs.custid = @userid and cs.bettype =  20 and cs.sporttype=154
			
	Select 
		@MinBetv161_Max = MinBet,
		@MaxBetv161_Min = MaxBet
	from 
		custsetting3rd as cs3 WITH (NOLOCK)
	where cs3.custid = @userid and cs3.bettype =  81 and cs3.sporttype=161
	
	--MAX PER MATCH
	Select 
		@MaxPerMatch_Min = 0,
		@MaxperMatch_Max = MaxPerMatch,
		
		@MaxPerMatchv2_Min = 0,
		@MaxPerMatchv2_Max = MaxPerMatch2,
		
		@MaxPerMatchv3_Min = 0,
		@MaxPerMatchv3_Max = MaxPerMatch3,
		
		@MaxPerMatchv5_Min = 0,
		@MaxPerMatchv5_Max = MaxPerMatch5,
		
		@MaxPerMatchv8_Min = 0,
		@MaxPerMatchv8_Max = MaxPerMatch8,
		
		@MaxPerMatchv10_Min = 0,
		@MaxPerMatchv10_Max = MaxPerMatch10,
		
		@MaxPerMatchv11_Min = 0,
		@MaxPerMatchv11_Max = MaxPerMatch11,		

		@MaxPerMatchv99_Min = 0,
		@MaxPerMatchv99_Max = MaxPerMatch99,
		
		@MaxPerMatchv99MP_Min = 0,
		@MaxPerMatchv99MP_Max = MaxPerMatch99MP,
		
		@MaxPerMatchv1MP_Min = 0,
		@MaxPerMatchv1MP_Max = MaxPerMatch1MP,
		
		@MaxPerMatchv154_Min = 0,
		@MaxPerMatchv154_Max = MaxPerMatch154,
		
		@MaxPerBallv161_Min = 0,
		@MaxPerBallv161_Max = MaxPerBall161,
		
		@MaxPerMatchv161_Min = 0,
		@MaxPerMatchv161_Max = MaxPerMatch161	
					
	from 
		custinfo as ci WITH (NOLOCK) 
	where ci.custid = @userid

End


GO
GRANT EXECUTE ON [dbo].[Age_CustomerSelMinMaxLimit] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Age_CustomerSelMinMaxLimit] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Age_CustomerSelMinMaxLimit] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Age_CustomerSelMinMaxLimit] TO [vnteam] AS [dbo]