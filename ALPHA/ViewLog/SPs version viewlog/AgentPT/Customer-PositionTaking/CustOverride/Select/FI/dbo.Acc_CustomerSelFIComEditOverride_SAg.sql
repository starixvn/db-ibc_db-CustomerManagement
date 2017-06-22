ALTER PROCEDURE [dbo].[Acc_CustomerSelFIComEditOverride_SAg]
	@CustID int --SuperID
AS

/*
Created by: Phuong Dao 
Task : Company Edits Super for Finance 
DB: DB05.bodb02
Orginal: Acc_CustomerSelComEditOverride_SAg

Revisions:
	- 20090917@Kiwi: Remove select data for l4.
	- 20091128@Kiwi: Move custsetting & custoverride to the separated tables (CustSetting3rd & CustOverride3rd).
	
Param's Explanation:
• @CustID: super ID
*/

SET NOCOUNT ON

SELECT 
	c.firstname, c.lastname, c.roleid, c.username, 
	isnull(c.phone,'') as phone, isnull(c.mobilephone,'') as mobilephone, isnull(c.fax,'') as fax,
	
	----- get s4 to check n4 <= s4 <= l4 ---------------
	MAX(case when cs.bettype = 3 then cs.spositiontaking else 0 END) as v201spositiontaking_3,
	MAX(case when cs.bettype = 2 then cs.spositiontaking else 0 END) as v201spositiontaking_2,

	------- get n4-----------------------------------------
	MAX(case when sco.bettype = 3 then sco.minpositiontaking else 0 END) as v201spositiontaking_3_min,
	MAX(case when sco.bettype = 2 then sco.minpositiontaking else 0 END) as v201spositiontaking_2_min

from 
	customer as c with (nolock)
	INNER JOIN custSetting3rd as cs with (NOLOCK) on c.custid = cs.custid
	INNER JOIN custOverride3rd as sco with (NOLOCK) on sco.custid = cs.custid and sco.sporttype=cs.sporttype and sco.bettype=cs.bettype	
where 
	c.roleid=4 and c.custid=@CustID AND sco.sporttype = 201 
group by 
	c.firstname, c.lastname, c.roleid, c.username, c.phone, c.mobilephone, c.fax
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelFIComEditOverride_SAg] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelFIComEditOverride_SAg] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelFIComEditOverride_SAg] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerSelFIComEditOverride_SAg] TO vnteam
