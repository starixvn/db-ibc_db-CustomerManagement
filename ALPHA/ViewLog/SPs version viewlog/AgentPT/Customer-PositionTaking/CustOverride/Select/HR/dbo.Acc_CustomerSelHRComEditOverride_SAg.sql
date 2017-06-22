ALTER PROCEDURE [dbo].[Acc_CustomerSelHRComEditOverride_SAg]
	@CustID int --SuperID
AS

/*
Created by: Phuc
Task : Company Edits Super for HR 
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
	MAX(case when cs.bettype = 31 then sco.maxpositiontaking else 0 END) as v151spositiontaking_31,
	MAX(case when cs.bettype = 32 then sco.maxpositiontaking else 0 END) as v151spositiontaking_32,
	MAX(case when cs.bettype = 41 then sco.maxpositiontaking else 0 END) as v151spositiontaking_41,
	MAX(case when cs.bettype = 42 then sco.maxpositiontaking else 0 END) as v151spositiontaking_42,

	------- get n4-----------------------------------------
	MAX(case when sco.bettype = 31 then sco.minpositiontaking else 0 END) as v151spositiontaking_31_min,
	MAX(case when sco.bettype = 32 then sco.minpositiontaking else 0 END) as v151spositiontaking_32_min,
	MAX(case when sco.bettype = 41 then sco.minpositiontaking else 0 END) as v151spositiontaking_41_min,
	MAX(case when sco.bettype = 42 then sco.minpositiontaking else 0 END) as v151spositiontaking_42_min

from 
	customer as c with (nolock)
	INNER JOIN custSetting3rd as cs with (NOLOCK) on c.custid = cs.custid
	INNER JOIN custOverride3rd as sco with (NOLOCK) on sco.custid = cs.custid and sco.sporttype=cs.sporttype and sco.bettype=cs.bettype	
where 
	c.roleid=4 and c.custid=@CustID AND sco.sporttype = 151 
group by 
	c.firstname, c.lastname, c.roleid, c.username, c.phone, c.mobilephone, c.fax
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelHRComEditOverride_SAg] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelHRComEditOverride_SAg] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelHRComEditOverride_SAg] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerSelHRComEditOverride_SAg] TO vnteam
