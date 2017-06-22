ALTER PROCEDURE [dbo].[Acc_CustomerSelFIComEditOverride_MAg]
	@CustID int --MasterID
	
AS
/*
Created by: Phuong Dao  
Task :	Company Edits Master for Finance 
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
	--v201
	max(case when cs.bettype = 3 then cs.mpositiontaking else 0 end) as v201mpositiontaking_3,
	max(case when cs.bettype = 2 then cs.mpositiontaking else 0 end) as v201mpositiontaking_2,
	---------------------------------------------------------------------
	-- get n3
	--v201
	max(case when mco.bettype = 3 then mco.minpositiontaking else 0 end) as v201mpositiontaking_3_min,
	max(case when mco.bettype = 2 then mco.minpositiontaking else 0 end) as v201mpositiontaking_2_min,
	---------------------------------------------------------------------
	-- get l3
	--v201
	max(case when mco.bettype = 3 then mco.maxpositiontaking else 0 end) as v201mpositiontaking_3_max,	
	max(case when mco.bettype = 2 then mco.maxpositiontaking else 0 end) as v201mpositiontaking_2_max

	---------------------------------------------------------------------
from 
	customer as c with (nolock)
	INNER JOIN custSetting3rd as cs with (NOLOCK) on c.custid = cs.custid
	INNER JOIN custOverride3rd as mco with (NOLOCK) on mco.custid = cs.custid and mco.sporttype=cs.sporttype and mco.bettype=cs.bettype	
where 
	c.roleid=3 and c.custid=@CustID AND mco.sporttype = 201 
group by 
	c.firstname, c.lastname, c.roleid, c.username, c.phone, c.mobilephone, c.fax
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelFIComEditOverride_MAg] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelFIComEditOverride_MAg] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelFIComEditOverride_MAg] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerSelFIComEditOverride_MAg] TO vnteam