ALTER PROCEDURE [dbo].[Acc_CustomerSelHRComEditOverride_MAg]
	@CustID int --MasterID
AS
/*
Created by: Phuc
Task :	Company Edits Master for HR 
		Super Edit Master
DB: DB05.bodb02
Orginal: Acc_CustomerSelComEditOverride_MAg
Revisions:
	- 20091128@Kiwi: Move custsetting & custoverride to the separated tables (CustSetting3rd & CustOverride3rd).	
Param's Explanation:
• @CustID: master ID
*/
SET NOCOUNT ON

select 
	c.firstname, c.lastname, c.roleid, c.username, 
	isnull(c.phone,'') as phone, isnull(c.mobilephone,'') as mobilephone, isnull(c.fax,'') as fax,
	
	---------------------------------------------------------------------
	-- get m3 to check n3 <= m3	
	--v151
	max(case when cs.bettype = 31 then cs.mpositiontaking else 0 end) as v151mpositiontaking_31,
	max(case when cs.bettype = 32 then cs.mpositiontaking else 0 end) as v151mpositiontaking_32,
	max(case when cs.bettype = 41 then cs.mpositiontaking else 0 end) as v151mpositiontaking_41,
	max(case when cs.bettype = 42 then cs.mpositiontaking else 0 end) as v151mpositiontaking_42,
	---------------------------------------------------------------------
	-- get n3
	--v151
	max(case when mco.bettype = 31 then mco.minpositiontaking else 0 end) as v151mpositiontaking_31_min,
	max(case when mco.bettype = 32 then mco.minpositiontaking else 0 end) as v151mpositiontaking_32_min,
	max(case when mco.bettype = 41 then mco.minpositiontaking else 0 end) as v151mpositiontaking_41_min,
	max(case when mco.bettype = 42 then mco.minpositiontaking else 0 end) as v151mpositiontaking_42_min,
	---------------------------------------------------------------------
	-- get l3
	--v151
	max(case when mco.bettype = 31 then mco.maxpositiontaking else 0 end) as v151mpositiontaking_31_max,	
	max(case when mco.bettype = 32 then mco.maxpositiontaking else 0 end) as v151mpositiontaking_32_max,
	max(case when mco.bettype = 41 then mco.maxpositiontaking else 0 end) as v151mpositiontaking_41_max,	
	max(case when mco.bettype = 42 then mco.maxpositiontaking else 0 end) as v151mpositiontaking_42_max

	---------------------------------------------------------------------
from 
	customer as c with (nolock)
	INNER JOIN custSetting3rd as cs with (NOLOCK) on c.custid = cs.custid
	INNER JOIN custOverride3rd as mco with (NOLOCK) on mco.custid = cs.custid and mco.sporttype=cs.sporttype and mco.bettype=cs.bettype	
where 
	c.roleid=3 and c.custid=@CustID AND mco.sporttype = 151 
group by 
	c.firstname, c.lastname, c.roleid, c.username, c.phone, c.mobilephone, c.fax
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelHRComEditOverride_MAg] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelHRComEditOverride_MAg] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelHRComEditOverride_MAg] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerSelHRComEditOverride_MAg] TO vnteam