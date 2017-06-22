ALTER PROCEDURE [dbo].[Acc_CustomerSelFIComEditOverride_Ag]
	@CustID int, --AgentID
	@MRecommend int = 0 --to check PT change date, in case "Master Edits Agent" only
AS

/*
Created by: Phuong Dao
Date: 2009-04-16 
Task :	Company Edits Agent for Finance 
		Master Edits Agent for Finance 
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
	--v201
	max(case when cs.bettype = 3 then case when cs.apositiontaking<mco.maxpositiontaking then cs.apositiontaking else mco.maxpositiontaking end else 0 end) as v201apositiontaking_3,
	max(case when cs.bettype = 2 then case when cs.apositiontaking<mco.maxpositiontaking then cs.apositiontaking else mco.maxpositiontaking end else 0 end) as v201apositiontaking_2,
	---------------------------------------------------------------------
	-- get n2
	--v201
	max(case when aco.bettype = 3 then aco.minpositiontaking else 0 end) as v201apositiontaking_3_min,
	max(case when aco.bettype = 2 then aco.minpositiontaking else 0 end) as v201apositiontaking_2_min,
	---------------------------------------------------------------------
	-- get l2
	--v201
	max(case when aco.bettype = 3 then aco.maxpositiontaking else 0 end) as v201apositiontaking_3_max,	
	max(case when aco.bettype = 2 then aco.maxpositiontaking else 0 end) as v201apositiontaking_2_max
	---------------------------------------------------------------------
from 
	customer as c with (nolock)
	INNER JOIN custsetting3rd as cs with (NOLOCK) on c.custid = cs.custid
	INNER JOIN custoverride3rd as aco with (NOLOCK) on aco.custid = cs.custid and aco.sporttype=cs.sporttype and aco.bettype=cs.bettype
	INNER JOIN custoverride3rd as mco with (NOLOCK) on mco.custid = c.mrecommend and mco.sporttype=cs.sporttype and mco.bettype=cs.bettype	
where 
	c.roleid=2 and c.custid=@CustID AND aco.sporttype=201
group by 
	c.firstname, c.lastname, c.roleid, c.username, c.phone, c.mobilephone, c.fax
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelFIComEditOverride_Ag] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelFIComEditOverride_Ag] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelFIComEditOverride_Ag] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerSelFIComEditOverride_Ag] TO vnteam


