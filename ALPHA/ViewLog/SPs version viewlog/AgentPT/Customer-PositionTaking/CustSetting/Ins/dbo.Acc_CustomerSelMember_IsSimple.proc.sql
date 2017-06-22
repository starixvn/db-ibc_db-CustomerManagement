ALTER PROCEDURE [dbo].[Acc_CustomerSelMember_IsSimple_1]
	@CustID int , -- AgID
	@pt1378 smallmoney,
	@pt456920 smallmoney,
	@pt10 smallmoney,
	@ptlive17 smallmoney,
	@ptlive38 smallmoney,
	@MinBet money,
	@MaxBet money,
	@MaxPerMatch money, 
	@IsSimple bit = 0 output
as
Set nocount on
declare 	
	@minpt1378 smallmoney,
	@minpt456920 smallmoney,
	@minpt10 smallmoney,
	@minptlive17 smallmoney,
	@minptlive38 smallmoney,
	@MinBet_Max money,
	@MaxBet_Min money,
	@MaxPerMatch_Min money,
	@MaxPermatch_Max money,
	@MaxperMatchv1_Max money,
	@MaxPerMatchv2_Max money,
	@MaxPerMatchv3_Max money,
	@MaxPerMatchv5_Max money,
	@MaxPerMatchv8_Max money,
	@MaxPerMatchv10_Max money,
	@MaxPerMatchv11_Max money,
	@MaxPerMatchv201_Max money,
	@MaxPerMatchv151_Max money,

	@MaxPerMatchv99_Max money
-- Minbet maxbet	
Select 
	@MinBet_Max = isnull(Max(case when MinBet = 0 then NULL else MinBet end),0), 
	@MaxBet_Min = isnull(Min(case when MaxBet = 0 then NULL else MaxBet end),0)
from 
	custsetting as cs WITH (NOLOCK)
	INNER JOIN (Select custid,mrecommend,srecommend from custinfo with(nolock) where custid = @CustID) ci 
		on (cs.CustID = ci.CustID or cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend) 
		and ( (cs.bettype = 1 and cs.sporttype in (1,2,3,5,8,10,11,99)) or (cs.bettype = 3 and cs.sporttype = 201) or (cs.bettype = 31 and cs.sporttype = 151))
where ci.custid = @CustID
-- MaxPerMatch
Select	
	@MaxPerMatch_Min = 0,
	@MaxperMatchv1_Max = isnull(Min(case when cs.MaxPerMatch = 0 then NULL else cs.MaxPerMatch end),0), 
	@MaxPerMatchv2_Max = isnull(Min(case when cs.MaxPerMatch2 = 0 then NULL else cs.MaxPerMatch2 end),0),
	@MaxPerMatchv3_Max = isnull(Min(case when cs.MaxPerMatch3 = 0 then NULL else cs.MaxPerMatch3 end),0),
	@MaxPerMatchv5_Max = isnull(Min(case when cs.MaxPerMatch5 = 0 then NULL else cs.MaxPerMatch5 end),0),
	@MaxPerMatchv8_Max = isnull(Min(case when cs.MaxPerMatch8 = 0 then NULL else cs.MaxPerMatch8 end),0),
	@MaxPerMatchv10_Max = isnull(Min(case when cs.MaxPerMatch10 = 0 then NULL else cs.MaxPerMatch10 end),0),
	@MaxPerMatchv11_Max = isnull(Min(case when cs.MaxPerMatch11 = 0 then NULL else cs.MaxPerMatch11 end),0),
	@MaxPerMatchv201_Max = isnull(Min(case when cs.MaxPerMatch201 = 0 then NULL else cs.MaxPerMatch201 end),0),
	@MaxPerMatchv151_Max = isnull(Min(case when cs.MaxPerMatch151 = 0 then NULL else cs.MaxPerMatch151 end),0),
	@MaxPerMatchv99_Max = isnull(Min(case when cs.MaxPerMatch99 = 0 then NULL else cs.MaxPerMatch99 end),0)
from 
	custinfo as cs WITH (NOLOCK) 
	INNER JOIN custinfo as ci WITH (NOLOCK) on (cs.CustID = ci.CustID or cs.CustID = ci.MRecommend or cs.CustID = ci.SRecommend)
where ci.custid = @CustID
select @maxpermatch_max = min(a.maxpermatch_max) from
(
	select @MaxperMatchv1_Max as maxpermatch_max
	union all
	select @MaxPerMatchv2_Max as maxpermatch_max
	union all
	select @MaxPerMatchv3_Max as maxpermatch_max
	union all
	select @MaxPerMatchv5_Max as maxpermatch_max
	union all
	select @MaxPerMatchv8_Max as maxpermatch_max
	union all
	select @MaxPerMatchv10_Max as maxpermatch_max
	union all
	select @MaxPerMatchv201_Max as maxpermatch_max
	union all
	select @MaxPerMatchv151_Max as maxpermatch_max
	union all
	select @MaxPerMatchv99_Max as maxpermatch_max
) a
-- Positiontaking
Select
	@minpt1378 = min(case when cs.bettype in(1,2,3,7,8) and cs.sporttype in (1,2,3,5,8,10,11,99,201) then case when cs.apositiontaking<co.maxpositiontaking then cs.apositiontaking else co.maxpositiontaking end else 1 end) ,
	@minpt456920 = min(case when cs.bettype in(4,5,6,9,20) then case when cs.apositiontaking<co.maxpositiontaking then cs.apositiontaking else co.maxpositiontaking end else 1 end),
	@minpt10 = min(case when cs.bettype in(10) then case when cs.apositiontaking<co.maxpositiontaking then cs.apositiontaking else co.maxpositiontaking end else 1 end),
	@minptlive17 = min(case when cs.bettype in(1,7) and cs.sporttype = 1 then case when cs.alivepositiontaking<co.maxpositiontaking then cs.alivepositiontaking else co.maxpositiontaking end else 1 end),
	@minptlive38 = min(case when cs.bettype in(3,8) and cs.sporttype = 1 then case when cs.alivepositiontaking<co.maxpositiontaking then cs.alivepositiontaking else co.maxpositiontaking end else 1 end)
From CustSetting as cs with (NOLOCK) 
	LEFT JOIN custoverride as co with (NOLOCK) on co.custid = cs.custid and co.sporttype=cs.sporttype and co.bettype= cs.bettype
Where cs.CustID = @CustID

IF @Pt1378 <= @minpt1378 and @pt456920 <= @minpt456920 and @pt10 <= @minpt10 and @ptlive17 <= @minptlive17 and @ptlive38 <= @minptlive38	
	and @MinBet >= @MinBet_Max and @MaxBet <= @MaxBet_Min and @MaxPerMatch >= @MaxPerMatch_Min and @MaxPerMatch <= @MaxPerMatch_Max 
		set @IsSimple = 1 
else
	set @IsSimple = 0

GO

GRANT EXECUTE ON [dbo].[Acc_CustomerSelMember_IsSimple_1] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelMember_IsSimple_1] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelMember_IsSimple_1] TO [bodbDownlineNetView]

