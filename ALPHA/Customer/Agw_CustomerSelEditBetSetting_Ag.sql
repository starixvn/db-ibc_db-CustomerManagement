ALTER PROCEDURE [dbo].[Agw_CustomerSelEditBetSetting_Ag]
 @CustID int    
AS    
    
/*
Created: 20090203@QuiNV
Task : Select member bet setting information
DB: DBCUST.CustDB
Original:
Revisions:
	- 20091204@Kiwi: Retrieve data from CustSetting3rd for Financials.
	- 20100105@Jamie: Remove exchange table out 
	- 20101001@Johnson: get setting for number game and mixed sports
	- 20110316@Lukas: get maxperball info
	- 20120817@Sophia: Get setting for Virtual Sports (180)
	- 20121204@Tom: Add  virtual tennis setting (sporttype : 186 , bettype : 1220)
	- 20130305@Johnson: Add virtual horse racing setting (sporttype: 181)
	- 20140402@Dom: Add Virtual Speedway/ Cycling setting (sporttype: 183,185)
	- 20150612@Kathy: Move sp from DBAGE.bodb02 to DBCUST.CustDB [Redmine:#36216]
*/

    
SET NOCOUNT ON
Declare @MinBet_Max money, 
		@MaxBet_Min money, 
		@MaxPerMatch_Min money, 
		@MaxPerMatch_Max money,    
		@MinBetv2_Max money, 
		@MaxBetv2_Min money, 
		@MaxPerMatchv2_Min money, 
		@MaxPerMatchv2_Max money,    
		@MinBetv3_Max money, 
		@MaxBetv3_Min money, 
		@MaxPerMatchv3_Min money, 
		@MaxPerMatchv3_Max money,    
		@MinBetv5_Max money, 
		@MaxBetv5_Min money, 
		@MaxPerMatchv5_Min money, 
		@MaxPerMatchv5_Max money,    
		@MinBetv8_Max money, 
		@MaxBetv8_Min money, 
		@MaxPerMatchv8_Min money, 
		@MaxPerMatchv8_Max money,    
		@MinBetv10_Max money, 
		@MaxBetv10_Min money, 
		@MaxPerMatchv10_Min money, 
		@MaxPerMatchv10_Max money,    
		@MinBetv11_Max money, 
		@MaxBetv11_Min money, 
		@MaxPerMatchv11_Min money, 
		@MaxPerMatchv11_Max money,    
		@MinBetv201_Max money, 
		@MaxBetv201_Min money, 
		@MaxPerMatchv201_Min money, 
		@MaxPerMatchv201_Max money,     
		@MinBetv99_Max money, 
		@MaxBetv99_Min money, 
		@MaxPerMatchv99_Min money, 
		@MaxPerMatchv99_Max money,
		@MinBetv99MP_Max money, 
		@MaxBetv99MP_Min money, 
		@MaxPerMatchv99MP_Min money, 
		@MaxPerMatchv99MP_Max money,
		@MinBetv161_Max money, 
		@MaxBetv161_Min money, 
		@MaxPerMatchv161_Min money, 
		@MaxPerMatchv161_Max money,		
		@MinBet201 money, 
		@MaxBet201 money,
		@MinBet161 money, 
		@MaxBet161 money, 
		@MaxPerBallv161_Max money,
		@MinBetv180_Max money, 
		@MaxBetv180_Min money, 
		@MaxPerMatchv180_Min money, 
		@MaxPerMatchv180_Max money,
		@MinBet180 money, 
		@MaxBet180 money,
		@MinBetv181_Max money, 
		@MaxBetv181_Min money, 
		@MaxPerMatchv181_Min money, 
		@MaxPerMatchv181_Max money,
		@MinBet181 money, 
		@MaxBet181 money,
		---Dom----
		@MinBet183 money, 
		@MaxBet183 money,
		@MinBet185 money, 
		@MaxBet185 money,
		@MinBetv186_Max money, 
		@MaxBetv186_Min money, 
		@MaxPerMatchv186_Min money, 
		@MaxPerMatchv186_Max money,
		@MinBet186 money, 
		@MaxBet186 money,
		----Dom--------------
		@MinBetv183_Max money, 
		@MaxBetv183_Min money, 
		@MaxPerMatchv183_Min money, 
		@MaxPerMatchv183_Max money,
		@MinBetv185_Max money, 
		@MaxBetv185_Min money, 
		@MaxPerMatchv185_Min money, 
		@MaxPerMatchv185_Max money
      
------------------------------------------------------------------------------------------------------------------------------------------
  
             
Select    
 @MinBet_Max = Max(case when MinBet = 0 then NULL else MinBet end),     
 @MaxBet_Min = Min(case when MaxBet = 0 then NULL else MaxBet end)    
from     
 custsetting as cs WITH (NOLOCK)    
 INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.Recommend or cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend)    
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

SELECT 
 @MinBetv99MP_Max = Max(case when MinBet = 0 then NULL else MinBet end),
 @MaxBetv99MP_Min = Min(case when MaxBet = 0 then NULL else MaxBet end)
FROM
 custsetting as cs WITH(NOLOCK)
 INNER JOIN custinfo as ci WITH(NOLOCK) on (cs.custid = ci.recommend or cs.custid = ci.mrecommend or cs.custid = ci.srecommend)
 and cs.bettype = 9 and cs.sporttype = 99
WHERE ci.custid = @custid
    
Select     
 @MinBetv201_Max = Max(case when MinBet = 0 then NULL else MinBet end),     
 @MaxBetv201_Min = Min(case when MaxBet = 0 then NULL else MaxBet end)    
from     
 custsetting3rd as cs WITH (NOLOCK)    
 INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.Recommend or cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend)    
 and cs.bettype = 3 and cs.sporttype=201    
where ci.custid = @CustID    

SELECT 
 @MinBetv161_Max = Max(case when MinBet = 0 then NULL else MinBet end),
 @MaxBetv161_Min = Min(case when MaxBet = 0 then NULL else MaxBet end)
FROM
 custsetting3rd as cs WITH(NOLOCK)
 INNER JOIN custinfo as ci WITH(NOLOCK) on (cs.custid = ci.recommend or cs.custid = ci.mrecommend or cs.custid = ci.srecommend)
 and cs.sporttype = 161
WHERE ci.custid = @custid 
    
Select     
 @MinBetv99_Max = Max(case when MinBet = 0 then NULL else MinBet end),     
 @MaxBetv99_Min = Min(case when MaxBet = 0 then NULL else MaxBet end)    
from     
 custsetting as cs WITH (NOLOCK)    
 INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.Recommend or cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend)    
 and cs.bettype = 1 and cs.sporttype=99    
where ci.custid = @CustID    

Select    
 @MinBetv180_Max = Max(case when MinBet = 0 then NULL else MinBet end),     
 @MaxBetv180_Min = Min(case when MaxBet = 0 then NULL else MaxBet end)    
from     
 custsetting as cs WITH (NOLOCK)    
 INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.Recommend or cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend)    
 and cs.bettype = 1201 and cs.sporttype=180    
where ci.custid = @CustID 

Select    
 @MinBetv181_Max = Max(case when MinBet = 0 then NULL else MinBet end),     
 @MaxBetv181_Min = Min(case when MaxBet = 0 then NULL else MaxBet end)    
from     
 custsetting as cs WITH (NOLOCK)    
 INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.Recommend or cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend)    
 and cs.bettype = 1231 and cs.sporttype=181    
where ci.custid = @CustID 

Select    
 @MinBetv183_Max = Max(case when MinBet = 0 then NULL else MinBet end),     
 @MaxBetv183_Min = Min(case when MaxBet = 0 then NULL else MaxBet end)    
from     
 custsetting as cs WITH (NOLOCK)    
 INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.Recommend or cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend)    
 and cs.bettype = 1231 and cs.sporttype=183    
where ci.custid = @CustID

Select    
 @MinBetv185_Max = Max(case when MinBet = 0 then NULL else MinBet end),     
 @MaxBetv185_Min = Min(case when MaxBet = 0 then NULL else MaxBet end)    
from     
 custsetting as cs WITH (NOLOCK)    
 INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.Recommend or cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend)    
 and cs.bettype = 1231 and cs.sporttype=185    
where ci.custid = @CustID
    
Select    
 @MinBetv186_Max = Max(case when MinBet = 0 then NULL else MinBet end),     
 @MaxBetv186_Min = Min(case when MaxBet = 0 then NULL else MaxBet end)    
from     
 custsetting as cs WITH (NOLOCK)    
 INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.Recommend or cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend)    
 and cs.bettype = 1220 and cs.sporttype=186    
where ci.custid = @CustID 
    
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
 @MaxPerMatchv201_Min = 0,    
 @MaxPerMatchv201_Max = Min(case when cs.MaxPerMatch201 = 0 then NULL else cs.MaxPerMatch201 end),  
 @MaxPerMatchv99_Min = 0,    
 @MaxPerMatchv99_Max = Min(case when cs.MaxPerMatch99 = 0 then NULL else cs.MaxPerMatch99 end),
 @MaxPerMatchv99MP_Min = 0,
 @MaxPerMatchv99MP_Max = Min(case when cs.MaxPerMatch99MP = 0 then NULL else cs.MaxPerMatch99MP end),
 @MaxPerMatchv161_Min = 0,
 @MaxPerMatchv161_Max = Min(case when cs.MaxPerMatch161 = 0 then NULL else cs.MaxPerMatch161 end),
 @MaxPerBallv161_Max = Min(case when cs.MaxPerBall161 = 0 then NULL else cs.MaxPerBall161 end),
 @MaxPerMatchv180_Min = 0,     
 @MaxperMatchv180_Max = Min(case when cs.maxpermatch180 = 0 then NULL else cs.maxpermatch180 end),
 @MaxPerMatchv181_Min = 0,     
 @MaxperMatchv181_Max = Min(case when cs.maxpermatch181 = 0 then NULL else cs.maxpermatch181 end), 
 @MaxPerMatchv183_Min = 0,     
 @MaxperMatchv183_Max = Min(case when cs.maxpermatch183 = 0 then NULL else cs.maxpermatch183 end), 
 @MaxPerMatchv185_Min = 0,     
 @MaxperMatchv185_Max = Min(case when cs.maxpermatch185 = 0 then NULL else cs.maxpermatch185 end), 
 @MaxPerMatchv186_Min = 0,     
 @MaxperMatchv186_Max = Min(case when cs.maxpermatch186 = 0 then NULL else cs.maxpermatch186 end) 
from     
 custinfo as cs WITH (NOLOCK)     
 INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.Recommend or cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend)    
where ci.custid = @CustID    
  
--Retrieve @MinBet201 and @MaxBet201 for Financials
select	@MinBet201 = isnull(max(case when bettype = 3 and sporttype=201 then minbet else 0 end), 0),    
		@MaxBet201 = isnull(max(case when bettype = 3 and sporttype=201 then maxbet else 0 end), 0),
		@MinBet161 = isnull(max(case when sporttype = 161 then minbet else 0 end),0),
		@MaxBet161 = isnull(max(case when sporttype = 161 then maxbet else 0 end),0),
		@MinBet180 = isnull(max(case when sporttype = 180 then minbet else 0 end),0),
		@MaxBet180 = isnull(max(case when sporttype = 180 then maxbet else 0 end),0),
		@MinBet181 = isnull(max(case when sporttype = 181 then minbet else 0 end),0),
		@MaxBet181 = isnull(max(case when sporttype = 181 then maxbet else 0 end),0),
		@MinBet183 = isnull(max(case when sporttype = 183 then minbet else 0 end),0),--Dom
		@MaxBet183 = isnull(max(case when sporttype = 183 then maxbet else 0 end),0),--Dom
		@MinBet185 = isnull(max(case when sporttype = 185 then minbet else 0 end),0),--Dom
		@MaxBet185 = isnull(max(case when sporttype = 185 then maxbet else 0 end),0),--Dom		
		@MinBet186 = isnull(max(case when sporttype = 186 then minbet else 0 end),0),
		@MaxBet186 = isnull(max(case when sporttype = 186 then maxbet else 0 end),0)
from custsetting3rd with (nolock)
where custid=@CustID
    
select     
 ci.username,     
 isnull(ci.maxpermatch, 0) as maxpermatch,    
    
 isnull(ci.maxpermatch2, 0) as maxpermatchv2,    
 isnull(ci.maxpermatch3, 0) as maxpermatchv3,    
 isnull(ci.maxpermatch5, 0) as maxpermatchv5,    
 isnull(ci.maxpermatch8, 0) as maxpermatchv8,    
 isnull(ci.maxpermatch10, 0) as maxpermatchv10,    
 isnull(ci.maxpermatch11, 0) as maxpermatchv11,    
 isnull(ci.maxpermatch201, 0) as maxpermatchv201,    
 isnull(ci.maxpermatch99, 0) as maxpermatchv99, 
 isnull(ci.maxpermatch99MP,0) as maxpermatchv99MP,
 isnull(ci.maxpermatch161,0) as maxpermatchv161,   
 isnull(ci.maxperball161,0) as maxperballv161,
 isnull(ci.maxpermatch180, 0) as maxpermatch180, 
 isnull(ci.maxpermatch181, 0) as maxpermatch181,  
 isnull(ci.maxpermatch183, 0) as maxpermatch183,  
 isnull(ci.maxpermatch185, 0) as maxpermatch185,  
 isnull(ci.maxpermatch186, 0) as maxpermatch186,  
          
 isnull(max(case when cs.bettype = 1 and cs.sporttype=1 then cs.minbet else 0 end), 0) as minbet,    
 isnull(max(case when cs.bettype = 1 and cs.sporttype=1 then cs.maxbet else 0 end), 0) as maxbet,    
     
 isnull(max(case when cs.bettype = 1 and cs.sporttype=2 then cs.minbet else 0 end), 0) as MinBetv2,    
 isnull(max(case when cs.bettype = 1 and cs.sporttype=2 then cs.maxbet else 0 end), 0) as MaxBetv2,    
     
 isnull(max(case when cs.bettype = 1 and cs.sporttype=3 then cs.minbet else 0 end), 0) as MinBetv3,    
 isnull(max(case when cs.bettype = 1 and cs.sporttype=3 then cs.maxbet else 0 end), 0) as MaxBetv3,    
    
 isnull(max(case when cs.bettype = 1 and cs.sporttype=5 then cs.minbet else 0 end), 0) as MinBetv5,    
 isnull(max(case when cs.bettype = 1 and cs.sporttype=5 then cs.maxbet else 0 end), 0) as MaxBetv5,    
    
 isnull(max(case when cs.bettype = 1 and cs.sporttype=8 then cs.minbet else 0 end), 0) as MinBetv8,    
 isnull(max(case when cs.bettype = 1 and cs.sporttype=8 then cs.maxbet else 0 end), 0) as MaxBetv8,    
    
 isnull(max(case when cs.bettype = 1 and cs.sporttype=10 then cs.minbet else 0 end), 0) as MinBetv10,    
 isnull(max(case when cs.bettype = 1 and cs.sporttype=10 then cs.maxbet else 0 end), 0) as MaxBetv10,    
    
 isnull(max(case when cs.bettype = 1 and cs.sporttype=11 then cs.minbet else 0 end), 0) as MinBetv11,    
 isnull(max(case when cs.bettype = 1 and cs.sporttype=11 then cs.maxbet else 0 end), 0) as MaxBetv11,    
    
 isnull (@MinBet201, 0) as MinBetv201,
 isnull (@MaxBet201, 0) as MaxBetv201,

 isnull(@MinBet161,0) as MinBetv161,
 isnull(@MaxBet161,0) as MaxBetv161,
 
 isnull(@MinBet180,0) as MinBetv180,
 isnull(@MaxBet180,0) as MaxBetv180,
 
 isnull(@MinBet181,0) as MinBetv181,
 isnull(@MaxBet181,0) as MaxBetv181,

 isnull(@MinBet183,0) as MinBetv183,
 isnull(@MaxBet183,0) as MaxBetv183,

 isnull(@MinBet185,0) as MinBetv185,
 isnull(@MaxBet185,0) as MaxBetv185,
 
 isnull(@MinBet186,0) as MinBetv186,
 isnull(@MaxBet186,0) as MaxBetv186,
    
 isnull(max(case when cs.bettype = 1 and cs.sporttype=99 then cs.minbet else 0 end), 0) as MinBetv99,    
 isnull(max(case when cs.bettype = 1 and cs.sporttype=99 then cs.maxbet else 0 end), 0) as MaxBetv99,    
 
 isnull(max(case when cs.bettype = 9 and cs.sporttype = 99 then cs.minbet else 0 end),0) as MinBetv99MP,
 isnull(max(case when cs.bettype = 9 and cs.sporttype = 99 then cs.maxbet else 0 end),0) as MaxBetv99MP,
   
 IsNull(@MinBet_Max, 0) as MinBet_Max,    
 IsNull(@MaxBet_Min, 0) as MaxBet_Min,    
 IsNull(@MaxPerMatch_Min, 0) as MaxPerMatch_Min,    
 IsNull(@MaxPerMatch_Max, 0) as MaxPerMatch_Max,    
     
 IsNull(@MinBetv2_Max, 0) as MinBetv2_Max,     
 IsNull(@MaxBetv2_Min, 0) as MaxBetv2_Min,     
 IsNull(@MaxPerMatchv2_Min, 0) as MaxPerMatchv2_Min,     
 IsNull(@MaxPerMatchv2_Max, 0) as MaxPerMatchv2_Max,     
     
 IsNull(@MinBetv3_Max, 0) as MinBetv3_Max,     
 IsNull(@MaxBetv3_Min, 0) as MaxBetv3_Min,     
 IsNull(@MaxPerMatchv3_Min, 0) as MaxPerMatchv3_Min,     
 IsNull(@MaxPerMatchv3_Max, 0) as MaxPerMatchv3_Max,    
    
 IsNull(@MinBetv5_Max, 0) as MinBetv5_Max,     
 IsNull(@MaxBetv5_Min, 0) as MaxBetv5_Min,     
 IsNull(@MaxPerMatchv5_Min, 0) as MaxPerMatchv5_Min,     
 IsNull(@MaxPerMatchv5_Max, 0) as MaxPerMatchv5_Max,    
    
 IsNull(@MinBetv8_Max, 0) as MinBetv8_Max,     
 IsNull(@MaxBetv8_Min, 0) as MaxBetv8_Min,     
 IsNull(@MaxPerMatchv8_Min, 0) as MaxPerMatchv8_Min,     
 IsNull(@MaxPerMatchv8_Max, 0) as MaxPerMatchv8_Max,    
    
 IsNull(@MinBetv10_Max, 0) as MinBetv10_Max,     
 IsNull(@MaxBetv10_Min, 0) as MaxBetv10_Min,     
 IsNull(@MaxPerMatchv10_Min, 0) as MaxPerMatchv10_Min,     
 IsNull(@MaxPerMatchv10_Max, 0) as MaxPerMatchv10_Max,    
    
 IsNull(@MinBetv11_Max, 0) as MinBetv11_Max,     
 IsNull(@MaxBetv11_Min, 0) as MaxBetv11_Min,     
 IsNull(@MaxPerMatchv11_Min, 0) as MaxPerMatchv11_Min,     
 IsNull(@MaxPerMatchv11_Max, 0) as MaxPerMatchv11_Max,    
    
 IsNull(@MinBetv201_Max, 0) as MinBetv201_Max,     
 IsNull(@MaxBetv201_Min, 0) as MaxBetv201_Min,     
 IsNull(@MaxPerMatchv201_Min, 0) as MaxPerMatchv201_Min,     
 IsNull(@MaxPerMatchv201_Max, 0) as MaxPerMatchv201_Max,    
    
 IsNull(@MinBetv99_Max, 0) as MinBetv99_Max,     
 IsNull(@MaxBetv99_Min, 0) as MaxBetv99_Min,     
 IsNull(@MaxPerMatchv99_Min, 0) as MaxPerMatchv99_Min,     
 IsNull(@MaxPerMatchv99_Max, 0) as MaxPerMatchv99_Max ,  

 IsNull(@MinBetv99MP_Max,0) as MinBetv99MP_Max,
 IsNull(@MaxBetv99MP_Min,0) as MaxBetv99MP_Min,
 IsNull(@MaxPerMatchv99MP_Min,0) as MaxPerMatchv99MP_Min,
 IsNull(@MaxPerMatchv99MP_Max,0) as MaxPerMatchv99MP_Max,

 IsNULL(@MinBetv161_Max,0) as MinBetv161_Max,
 IsNull(@MaxBetv161_Min,0) as MaxBetv161_Min,
 IsNull(@MaxPerMatchv161_Min,0) as MaxPerMatchv161_Min,
 IsNull(@MaxPerMatchv161_Max,0) as MaxPerMatchv161_Max,
 Isnull(@MaxPerBallv161_Max,0) as MaxPerBallv161_Max,

 IsNull(@MinBetv180_Max, 0) as MinBet180_Max,    
 IsNull(@MaxBetv180_Min, 0) as MaxBet180_Min,    
 IsNull(@MaxPerMatchv180_Min, 0) as MaxPerMatch180_Min,    
 IsNull(@MaxPerMatchv180_Max, 0) as MaxPerMatch180_Max,

 IsNull(@MinBetv181_Max, 0) as MinBet181_Max,    
 IsNull(@MaxBetv181_Min, 0) as MaxBet181_Min,    
 IsNull(@MaxPerMatchv181_Min, 0) as MaxPerMatch181_Min,    
 IsNull(@MaxPerMatchv181_Max, 0) as MaxPerMatch181_Max,

 IsNull(@MinBetv183_Max, 0) as MinBet183_Max,    
 IsNull(@MaxBetv183_Min, 0) as MaxBet183_Min,    
 IsNull(@MaxPerMatchv183_Min, 0) as MaxPerMatch183_Min,    
 IsNull(@MaxPerMatchv183_Max, 0) as MaxPerMatch183_Max,

 IsNull(@MinBetv185_Max, 0) as MinBet185_Max,    
 IsNull(@MaxBetv185_Min, 0) as MaxBet185_Min,    
 IsNull(@MaxPerMatchv185_Min, 0) as MaxPerMatch185_Min,    
 IsNull(@MaxPerMatchv185_Max, 0) as MaxPerMatch185_Max,
 	
 IsNull(@MinBetv186_Max, 0) as MinBet186_Max,
 IsNull(@MaxBetv186_Min, 0) as MaxBet186_Min,
 IsNull(@MaxPerMatchv186_Min, 0) as MaxPerMatch186_Min,
 IsNull(@MaxPerMatchv186_Max, 0) as MaxPerMatch186_Max,
 
 ci.currency
from CustInfo as ci with (NOLOCK)    
	 INNER JOIN CustSetting as cs with (NOLOCK) on ci.custid = cs.custid    
where ci.custid=@CustID    
group by     
 ci.username,     
 Ci.maxpermatch,    
 ci.maxpermatch2,    
 ci.maxpermatch3,    
 ci.maxpermatch5,    
 ci.maxpermatch8,    
 ci.maxpermatch10,    
 ci.maxpermatch11,    
 ci.maxpermatch201,    
 ci.maxpermatch99,   
 ci.maxpermatch99MP,
 ci.maxpermatch161,
 ci.maxperball161,
 ci.maxpermatch180,
 ci.maxpermatch181,
 ci.maxpermatch183,
 ci.maxpermatch185,
 ci.maxpermatch186,
 ci.currency

GO
GRANT EXECUTE ON [dbo].[Agw_CustomerSelEditBetSetting_Ag] TO [bodbDownlineNet,wsv_alp] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Agw_CustomerSelEditBetSetting_Ag] TO [vnteam] AS [dbo]