ALTER PROCEDURE [dbo].Acc_CustomerUpdSuper_AutoPositiontaking 
	@srecommend int
AS
--@Source Control
/*
Created: 2008@Thien
Task : Recalculate s1 when update s4
DB: DB02.bodb02
Original: Acc_CustomerUpdAutoPositiontaking_Com

Param's Explanation:
• @ErrCode:
    = 0: Update successfully.
    > 0: Specific Error.
  
• @ErrMsg: Error description.
*/

SET NOCOUNT ON

--u = (i3 or i1)?(u3 or u1)
--s1 = min(s4-m1-a1, u)
Update custsetting
	set spositiontaking = case when scs.spositiontaking-custsetting.mpositiontaking-custsetting.apositiontaking >
							(case when custsetting.isautopositiontaking=1 then custsetting.autopositiontaking else mcs.autopositiontaking end) then (case when custsetting.isautopositiontaking=1 then custsetting.autopositiontaking else mcs.autopositiontaking end) else scs.spositiontaking-custsetting.mpositiontaking-custsetting.apositiontaking end 
from
	custsetting
	inner join custinfo as c with (NOLOCK) on custsetting.custid = c.custid
	inner join custsetting as mcs with (NOLOCK) on mcs.custid = c.mrecommend and mcs.sporttype=custsetting.sporttype and mcs.bettype=custsetting.bettype
	inner join custsetting as scs with (NOLOCK) on scs.custid = @srecommend and scs.sporttype=custsetting.sporttype and scs.bettype=custsetting.bettype
where
	c.srecommend = @srecommend
	and c.roleid = 1
	and (custsetting.isautopositiontaking=1 or mcs.isautopositiontaking=1)

Update custsetting
	set slivepositiontaking = case when scs.slivepositiontaking-custsetting.mlivepositiontaking-custsetting.alivepositiontaking >
							(case when custsetting.isautolivepositiontaking=1 then custsetting.autolivepositiontaking else mcs.autolivepositiontaking end) then (case when custsetting.isautolivepositiontaking=1 then custsetting.autolivepositiontaking else mcs.autolivepositiontaking end) else scs.slivepositiontaking-custsetting.mlivepositiontaking-custsetting.alivepositiontaking end 
from
	custsetting
	inner join custinfo as c with (NOLOCK) on custsetting.custid = c.custid
	inner join custsetting as mcs with (NOLOCK) on mcs.custid = c.mrecommend and mcs.sporttype=custsetting.sporttype and mcs.bettype=custsetting.bettype
	inner join custsetting as scs with (NOLOCK) on scs.custid = @srecommend and scs.sporttype=custsetting.sporttype and scs.bettype=custsetting.bettype
where
	c.srecommend = @srecommend
	and c.roleid = 1
	and (custsetting.isautolivepositiontaking=1 or mcs.isautolivepositiontaking=1)

--Thien20081119: No need to run this SP
--exec Acc_CustomerUpdSuper_MinMaxPositiontaking @srecommend


GO
GRANT EXECUTE ON [dbo].Acc_CustomerUpdSuper_AutoPositiontaking TO [bodbAdminNet]
GO
