ALTER PROC [dbo].[Agw_CustomerSelMinMaxBetHR]
 @CustID int  
AS  

/*

Created: 20090326@QuiNV
Task: Select minbet, maxbet, max per match for Horseracing 
DB: DBCUST.CustDB
Original:
Revisions:
	- 20091204@Kiwi: Retrieve data from CustSetting3rd.
	- 20100513@Terry: Get Minbet, MaxBet, MaxPerMatch Opentote	
	- 20110303@Lukas: get Minbet, MaxBet, MaxPerMatch AU Horse racing, Greyhound racing, Harness racing
	- 20150612@Kathy: Move sp from DBAGE.bodb02 to DBCUST.CustDB [Redmine:#36216]
	
Note:
	- 31 : Sa Tote
	- 41 : UK Tote
	- 51 : AU Tote
*/
  
SET NOCOUNT ON  
  
Declare   
 @uplineID int,  
 @roleid int,  
 -- Sa Tote  
 @v151minbet_31 money,  
 @v151maxbet_31 money,  
 @v151MaxPerMatch_31 money,  
  
 @v151MinBet_31_Min money,  
 @v151MaxBet_31_Max money,  
 @v151MaxPerMatch_31_Max money,  
 @v151MaxPerMatch_31_Min money,

 -- UK Tote
 @v151minbet_41 money,  
 @v151maxbet_41 money,  
 @v151MaxPerMatch_41 money,  
  
 @v151MinBet_41_Min money,  
 @v151MaxBet_41_Max money,  
 @v151MaxPerMatch_41_Max money,  
 @v151MaxPerMatch_41_Min money,

-- AU Horse 
 @v151minbet_51 money,  
 @v151maxbet_51 money,  
 @v151MaxPerMatch_51 money,  
  
 @v151MinBet_51_Min money,  
 @v151MaxBet_51_Max money,  
 @v151MaxPerMatch_51_Max money,  
 @v151MaxPerMatch_51_Min money,

-- UK Greyhound
 @v152minbet_41 money,  
 @v152maxbet_41 money,  
 @v152MaxPerMatch_41 money,  
  
 @v152MinBet_41_Min money,  
 @v152MaxBet_41_Max money,  
 @v152MaxPerMatch_41_Max money,  
 @v152MaxPerMatch_41_Min money,

-- AU Greyhound
 @v152minbet_51 money,  
 @v152maxbet_51 money,  
 @v152MaxPerMatch_51 money,  
  
 @v152MinBet_51_Min money,  
 @v152MaxBet_51_Max money,  
 @v152MaxPerMatch_51_Max money,  
 @v152MaxPerMatch_51_Min money,

-- AU Horse 
 @v153minbet_51 money,  
 @v153maxbet_51 money,  
 @v153MaxPerMatch_51 money,  
  
 @v153MinBet_51_Min money,  
 @v153MaxBet_51_Max money,  
 @v153MaxPerMatch_51_Max money,  
 @v153MaxPerMatch_51_Min money
   
select @roleid = roleid  
from custinfo with (nolock)  
where custid = @custid  
select @roleid = isnull(@roleid, 0)  

select @uplineID = case @roleid when 1 then recommend when 2 then mrecommend when 3 then srecommend else 0 end  
from custinfo with (nolock) where custid = @custid  
  
 
if @roleid in (1,2,3)  
BEGIN  
  
 -- SA Tote 
 Select    
  @v151MinBet_31_Min = Max(case when sporttype = 151 and bettype = 31 then (case when MinBet = 0 then NULL else MinBet end) else NULL end),     
  @v151MaxBet_31_Max = Min(case when sporttype = 151 and bettype = 31 then (case when MaxBet = 0 then NULL else MaxBet end) else NULL end),  
  @v151MinBet_41_Min = Max(case when sporttype = 151 and bettype = 41 then (case when MinBet = 0 then NULL else MinBet end) else NULL end),  
  @v151MaxBet_41_Max = Min(case when sporttype = 151 and bettype = 41 then (case when MaxBet = 0 then NULL else MaxBet end) else NULL end),  
  @v151MinBet_51_Min = Max(case when sporttype = 151 and bettype = 51 then (case when MinBet = 0 then NULL else MinBet end) else NULL end),  
  @v151MaxBet_51_Max = Min(case when sporttype = 151 and bettype = 51 then (case when MaxBet = 0 then NULL else MaxBet end) else NULL end),  
  @v152MinBet_41_Min = Max(case when sporttype = 152 and bettype = 41 then (case when MinBet = 0 then NULL else MinBet end) else NULL end),  
  @v152MaxBet_41_Max = Min(case when sporttype = 152 and bettype = 41 then (case when MaxBet = 0 then NULL else MaxBet end) else NULL end),  
  @v152MinBet_51_Min = Max(case when sporttype = 152 and bettype = 51 then (case when MinBet = 0 then NULL else MinBet end) else NULL end),  
  @v152MaxBet_51_Max = Min(case when sporttype = 152 and bettype = 51 then (case when MaxBet = 0 then NULL else MaxBet end) else NULL end),  
  @v153MinBet_51_Min = Max(case when sporttype = 153 and bettype = 51 then (case when MinBet = 0 then NULL else MinBet end) else NULL end),  
  @v153MaxBet_51_Max = Min(case when sporttype = 153 and bettype = 51 then (case when MaxBet = 0 then NULL else MaxBet end) else NULL end)
 from     
  custsetting3rd as cs WITH (NOLOCK)    
  INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.Recommend or cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend)    
  and cs.bettype in (31,41,51) and cs.sporttype between 151 and 153
 where ci.custid = @UplineID
     
     
 Select @v151MaxPerMatch_31_Min = 0,  
		@v151MaxPerMatch_41_Min = 0,
		@v151MaxPerMatch_51_Min = 0,
		@v152MaxPerMatch_41_Min = 0,
		@v152MaxPerMatch_51_Min = 0,
		@v153MaxPerMatch_51_Min = 0

 select
		@v151MaxperMatch_31_Max = Min(case when cs.MaxPerMatch151    = 0 then NULL else cs.MaxPerMatch151 end),
		@v151MaxperMatch_41_Max = Min(case when cs.MaxPerMatch151_OT = 0 then NULL else cs.MaxPerMatch151_OT end),
		@v151MaxperMatch_51_Max = Min(case when cs.MaxPerMatch151_AU = 0 then NULL else cs.MaxPerMatch151_AU end),
		@v152MaxperMatch_41_Max = Min(case when cs.MaxPerMatch152_UK = 0 then NULL else cs.MaxPerMatch152_UK end),
		@v152MaxperMatch_51_Max = Min(case when cs.MaxPerMatch152_AU = 0 then NULL else cs.MaxPerMatch152_AU end),
		@v153MaxperMatch_51_Max = Min(case when cs.MaxPerMatch153_AU = 0 then NULL else cs.MaxPerMatch153_AU end)
 from     
  custinfo as cs WITH (NOLOCK)     
  INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.Recommend or cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend)    
      
 where ci.custid = @UplineID    
--//------

--//---
  
END  
  
if @roleid = 4  
BEGIN  
 -- SA Tote
 Select   
  @v151MinBet_31_Min = 0,  
  @v151MaxBet_31_Max = 0,  
  @v151MaxPerMatch_31_Min = 0,  
  @v151MaxperMatch_31_Max = 0,    
  -- UK Tote
  @v151MinBet_41_Min = 0,  
  @v151MaxBet_41_Max = 0,  
  @v151MaxPerMatch_41_Min = 0,  
  @v151MaxperMatch_41_Max = 0,
-- AU Tote
  @v151MinBet_51_Min = 0,  
  @v151MaxBet_51_Max = 0,  
  @v151MaxPerMatch_51_Min = 0,  
  @v151MaxperMatch_51_Max = 0,
-- UK Greyhound

  @v152MinBet_41_Min = 0,  
  @v152MaxBet_41_Max = 0,  
  @v152MaxPerMatch_41_Min = 0,  
  @v152MaxperMatch_41_Max = 0,
-- AU Greyhound

  @v152MinBet_51_Min = 0,  
  @v152MaxBet_51_Max = 0,  
  @v152MaxPerMatch_51_Min = 0,  
  @v152MaxperMatch_51_Max = 0,    
-- AU Harness 
  @v153MinBet_51_Min = 0,  
  @v153MaxBet_51_Max = 0,  
  @v153MaxPerMatch_51_Min = 0,  
  @v153MaxperMatch_51_Max = 0  
  --//-- 
END  
  
  
SELECT  
 @v151minbet_31		 = max(case when sporttype = 151 and bettype = 31 then cs.minbet else null end),   
 @v151maxbet_31		 = min(case when sporttype = 151 and bettype = 31 then cs.maxbet else null end),      
 @v151maxpermatch_31 = max(case when sporttype = 151 and bettype = 31 then ci.maxpermatch151 else null end),      
 @v151minbet_41		 = max(case when sporttype = 151 and bettype = 41 then cs.minbet else null end), 
 @v151maxbet_41		 = min(case when sporttype = 151 and bettype = 41 then cs.maxbet else null end),   
 @v151maxpermatch_41 = max(case when sporttype = 151 and bettype = 41 then ci.maxpermatch151_OT else null end),
 @v151minbet_51		 = max(case when sporttype = 151 and bettype = 51 then cs.minbet else null end), 
 @v151maxbet_51		 = min(case when sporttype = 151 and bettype = 51 then cs.maxbet else null end),   
 @v151maxpermatch_51 = max(case when sporttype = 151 and bettype = 51 then ci.maxpermatch151_AU else null end),
 @v152minbet_41		 = max(case when sporttype = 152 and bettype = 41 then cs.minbet else null end), 
 @v152maxbet_41		 = min(case when sporttype = 152 and bettype = 41 then cs.maxbet else null end),   
 @v152maxpermatch_41 = max(case when sporttype = 152 and bettype = 41 then ci.maxpermatch152_UK else null end),
 @v152minbet_51		 = max(case when sporttype = 152 and bettype = 51 then cs.minbet else null end), 
 @v152maxbet_51		 = min(case when sporttype = 152 and bettype = 51 then cs.maxbet else null end),   
 @v152maxpermatch_51 = max(case when sporttype = 152 and bettype = 51 then ci.maxpermatch152_AU else null end),
 @v153minbet_51		 = max(case when sporttype = 153 and bettype = 51 then cs.minbet else null end), 
 @v153maxbet_51		 = min(case when sporttype = 153 and bettype = 51 then cs.maxbet else null end),   
 @v153maxpermatch_51 = max(case when sporttype = 153 and bettype = 51 then ci.maxpermatch153_AU else null end)
FROM   
 custinfo as ci with (NOLOCK)  
 INNER JOIN custsetting3rd as cs with (NOLOCK) on ci.custid  = cs.custid  
WHERE   
 ci.custid = @custId AND cs.bettype in (31,41,51) AND cs.sporttype between 151 and 153
--//---

-- SA Tote   
SELECT  
 isnull(@v151minbet_31, 0)			AS v151minbet_31,   
 isnull(@v151maxbet_31, 0)			AS v151maxbet_31,   
 isnull(@v151maxpermatch_31, 0)		AS v151maxpermatch_31,  
 isnull(@v151MinBet_31_Min, 0)		AS v151MinBet_31_Max,  
 isnull(@v151MaxBet_31_Max, 0)		AS v151MaxBet_31_Min,
 isnull(@v151MaxPerMatch_31_Min, 0) AS v151MaxPerMatch_31_Min,  
 isnull(@v151MaxperMatch_31_Max, 0) AS v151MaxperMatch_31_Max,  
--//---   
-- UK Tote   
 isnull(@v151minbet_41, 0)			AS v151minbet_41,   
 isnull(@v151maxbet_41, 0)			AS v151maxbet_41,   
 isnull(@v151maxpermatch_41, 0)		AS v151maxpermatch_41,
 isnull(@v151MinBet_41_Min, 0)		AS v151MinBet_41_Max,  
 isnull(@v151MaxBet_41_Max, 0)		AS v151MaxBet_41_Min,
 isnull(@v151MaxPerMatch_41_Min, 0) AS v151MaxPerMatch_41_Min,  
 isnull(@v151MaxperMatch_41_Max, 0) AS v151MaxperMatch_41_Max, 
-- AU Tote
 isnull(@v151minbet_51, 0)			AS v151minbet_51,   
 isnull(@v151maxbet_51, 0)			AS v151maxbet_51,   
 isnull(@v151maxpermatch_51, 0)		AS v151maxpermatch_51,  
 isnull(@v151MinBet_51_Min, 0)		AS v151MinBet_51_Max,  
 isnull(@v151MaxBet_51_Max, 0)		AS v151MaxBet_51_Min,
 isnull(@v151MaxPerMatch_51_Min, 0) AS v151MaxPerMatch_51_Min,  
 isnull(@v151MaxperMatch_51_Max, 0) AS v151MaxperMatch_51_Max, 
-- UK Greyhound
 isnull(@v152minbet_41, 0)			AS v152minbet_41,   
 isnull(@v152maxbet_41, 0)			AS v152maxbet_41,   
 isnull(@v152maxpermatch_41, 0)		AS v152maxpermatch_41,
 isnull(@v152MinBet_41_Min, 0)		AS v152MinBet_41_Max,  
 isnull(@v152MaxBet_41_Max, 0)		AS v152MaxBet_41_Min,
 isnull(@v152MaxPerMatch_41_Min, 0) AS v152MaxPerMatch_41_Min,  
 isnull(@v152MaxperMatch_41_Max, 0) AS v152MaxperMatch_41_Max, 
-- AU Greyhound
 isnull(@v152minbet_51, 0)			AS v152minbet_51,   
 isnull(@v152maxbet_51, 0)			AS v152maxbet_51,   
 isnull(@v152maxpermatch_51, 0)		AS v152maxpermatch_51,  
 isnull(@v152MinBet_51_Min, 0)		AS v152MinBet_51_Max,  
 isnull(@v152MaxBet_51_Max, 0)		AS v152MaxBet_51_Min,
 isnull(@v152MaxPerMatch_51_Min, 0) AS v152MaxPerMatch_51_Min,  
 isnull(@v152MaxperMatch_51_Max, 0) AS v152MaxperMatch_51_Max, 
-- AU Harness
 isnull(@v153minbet_51, 0)			AS v153minbet_51,   
 isnull(@v153maxbet_51, 0)			AS v153maxbet_51,   
 isnull(@v153maxpermatch_51, 0)		AS v153maxpermatch_51,  
 isnull(@v153MinBet_51_Min, 0)		AS v153MinBet_51_Max,  
 isnull(@v153MaxBet_51_Max, 0)		AS v153MaxBet_51_Min,
 isnull(@v153MaxPerMatch_51_Min, 0) AS v153MaxPerMatch_51_Min,  
 isnull(@v153MaxperMatch_51_Max, 0) AS v153MaxperMatch_51_Max

--//---

GO
GRANT EXECUTE ON [dbo].[Agw_CustomerSelMinMaxBetHR] TO [bodbAdminNet,wsv_nap] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Agw_CustomerSelMinMaxBetHR] TO [bodbDownlineNet,wsv_alp] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Agw_CustomerSelMinMaxBetHR] TO [vnteam] AS [dbo]