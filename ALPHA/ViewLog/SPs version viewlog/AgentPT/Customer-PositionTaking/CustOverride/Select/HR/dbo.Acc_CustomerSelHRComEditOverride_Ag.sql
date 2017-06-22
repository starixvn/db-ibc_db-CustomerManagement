ALTER PROCEDURE [dbo].[Acc_CustomerSelHRComEditOverride_Ag]
	@CustID int, --AgentID
	@MRecommend int = 0 --to check PT change date, in case "Master Edits Agent" only
AS

/*
Created by: Phuc
Date: 2009-05-21 
Task :	Company Edits Agent for HR 
		Master Edits Agent for HR
DB: DB05.bodb02
Orginal: Acc_CustomerSelComEditOverride_Ag
Revisions:
	- 20091128@Kiwi: Move custsetting & custoverride to the separated tables (CustSetting3rd & CustOverride3rd).	
Param's Explanation:
• @CustID: agent ID
*/

SET NOCOUNT ON


select 
	c.firstname, c.lastname, c.roleid, c.username, isnull(c.phone,'') as phone, isnull(c.mobilephone,'') as mobilephone, isnull(c.fax,'') as fax,
	
	---------------------------------------------------------------------
	-- get min(a2,l3) to check n2 <= min(a2,l3)	
	--v151
	max(case when cs.bettype = 31 then case when cs.apositiontaking<mco.maxpositiontaking then cs.apositiontaking else mco.maxpositiontaking end else 0 end) as v151apositiontaking_31,
	max(case when cs.bettype = 32 then case when cs.apositiontaking<mco.maxpositiontaking then cs.apositiontaking else mco.maxpositiontaking end else 0 end) as v151apositiontaking_32,
	max(case when cs.bettype = 41 then case when cs.apositiontaking<mco.maxpositiontaking then cs.apositiontaking else mco.maxpositiontaking end else 0 end) as v151apositiontaking_41,
	max(case when cs.bettype = 42 then case when cs.apositiontaking<mco.maxpositiontaking then cs.apositiontaking else mco.maxpositiontaking end else 0 end) as v151apositiontaking_42,
	---------------------------------------------------------------------
	-- get n2
	--v151
	max(case when aco.bettype = 31 then aco.minpositiontaking else 0 end) as v151apositiontaking_31_min,
	max(case when aco.bettype = 32 then aco.minpositiontaking else 0 end) as v151apositiontaking_32_min,
	max(case when aco.bettype = 41 then aco.minpositiontaking else 0 end) as v151apositiontaking_41_min,
	max(case when aco.bettype = 42 then aco.minpositiontaking else 0 end) as v151apositiontaking_42_min,
	---------------------------------------------------------------------
	-- get l2
	--v151
	max(case when aco.bettype = 31 then aco.maxpositiontaking else 0 end) as v151apositiontaking_31_max,	
	max(case when aco.bettype = 32 then aco.maxpositiontaking else 0 end) as v151apositiontaking_32_max,
	max(case when aco.bettype = 41 then aco.maxpositiontaking else 0 end) as v151apositiontaking_41_max,	
	max(case when aco.bettype = 42 then aco.maxpositiontaking else 0 end) as v151apositiontaking_42_max
	---------------------------------------------------------------------
from 
	customer as c with (nolock)
	INNER JOIN custSetting3rd as cs with (NOLOCK) on c.custid = cs.custid
	INNER JOIN custOverride3rd as aco with (NOLOCK) on aco.custid = cs.custid and aco.sporttype=cs.sporttype and aco.bettype=cs.bettype
	INNER JOIN custOverride3rd as mco with (NOLOCK) on mco.custid = c.mrecommend and mco.sporttype=cs.sporttype and mco.bettype=cs.bettype	
where 
	c.roleid=2 and c.custid=@CustID AND aco.sporttype=151
group by 
	c.firstname, c.lastname, c.roleid, c.username, c.phone, c.mobilephone, c.fax
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelHRComEditOverride_Ag] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelHRComEditOverride_Ag] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelHRComEditOverride_Ag] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerSelHRComEditOverride_Ag] TO vnteam


