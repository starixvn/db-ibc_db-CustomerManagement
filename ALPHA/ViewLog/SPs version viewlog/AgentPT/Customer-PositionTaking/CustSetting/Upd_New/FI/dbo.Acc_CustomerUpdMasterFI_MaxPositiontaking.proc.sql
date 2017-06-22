ALTER PROCEDURE [dbo].Acc_CustomerUpdMasterFI_MaxPositiontaking 
	@mrecommend int
AS

--@Source Control
/*
Created: 20090415@Phuc
Task : Update PT at member level when super update master(finance)
DB: DB02.bodb02
Original: [Acc_CustomerUpdMaxPositiontaking_Master]

Revisions:
	- 20090628@Phuc: auto master PT on member level.
	- 20090716@Phuc: Remove sco cause of l4=s4(correct data when s1+m1+a1>s4)
	- 20091201@Kiwi: Move custsetting & custoverride to the separated tables (CustSetting3rd & CustOverride3rd).
Param's Explanation:
• @ErrCode:
    = 0: Update successfully.
    > 0: Specific Error.
  
• @ErrMsg: Error description.
*/


declare @srecommend int

select @srecommend = srecommend 
from custinfo with (NOLOCK) 
where custid = @mrecommend

--Update all agent and member accounts
declare @mpos smallmoney, @apos smallmoney, @spos smallmoney, @mapos1 smallmoney, @mapos2 smallmoney, @mapos smallmoney, @maxmapos smallmoney

--Recal AUTO MPT m1=min(m3-a1,(im1?um1,um2))
-------------------------------------------------------------------------------------
Update cs 
	set mpositiontaking = 
		case when mcs.mpositiontaking-cs.apositiontaking > (case when cs.isautompositiontaking = 1 then cs.autompositiontaking else acs.autompositiontaking end)
			then (case when cs.isautompositiontaking = 1 then cs.autompositiontaking else acs.autompositiontaking end)
		else  mcs.mpositiontaking-cs.apositiontaking end
from
	CustSetting3rd as cs with (ROWLOCK, UPDLOCK)
	inner join custinfo as c with (NOLOCK) on cs.custid = c.custid
	inner join CustSetting3rd as mcs with (NOLOCK) on mcs.custid = c.mrecommend and mcs.sporttype=cs.sporttype and mcs.bettype=cs.bettype
	inner join CustSetting3rd as acs with (NOLOCK) on acs.custid = c.recommend and acs.sporttype=cs.sporttype and acs.bettype=cs.bettype
where
	c.mrecommend = @mrecommend
	and c.roleid = 1
	and (acs.isautompositiontaking = 1 or cs.isautompositiontaking = 1)
	and cs.sporttype = 201

-------------------------------------------------------------------------------------



----------------------------------------------------------------------------
--check master min/max
--m1=n3-a1
Update cs
set mpositiontaking = mco.minpositiontaking-cs.apositiontaking
from 
	CustSetting3rd as cs with (ROWLOCK, UPDLOCK)
	inner join custinfo as mb with (NOLOCK) on cs.custid = mb.custid and mb.mrecommend=@mrecommend and mb.roleid=1
	inner join CustOverride3rd as mco with (NOLOCK) on mco.custid = @mrecommend  and mco.sporttype=cs.sporttype and mco.bettype=cs.bettype
where cs.apositiontaking+cs.mpositiontaking<mco.minpositiontaking
	and cs.sporttype = 201

----------------------------------------------------------------------------


----------------------------------------------------------------------------
-- Update m1,a1 when m1+a1>l3
-- m1=min(m3,l3)-a1
Update cs 
set @maxmapos = case when mcs.mpositiontaking>mco.maxpositiontaking then mco.maxpositiontaking else mcs.mpositiontaking end,
	@mpos = case when @maxmapos-cs.apositiontaking<0 then 0 else @maxmapos-cs.apositiontaking end,
	mpositiontaking = @mpos,
	@apos = case when cs.apositiontaking + @mpos>@maxmapos then @maxmapos-@mpos else cs.apositiontaking end,
	apositiontaking = case when @apos<aco.minpositiontaking then aco.minpositiontaking else @apos end
from 
	CustSetting3rd as cs with (ROWLOCK, UPDLOCK)
	inner join custinfo as mb with (NOLOCK) on cs.custid = mb.custid and mb.mrecommend=@mrecommend and mb.roleid=1
	inner join CustSetting3rd as mcs with (NOLOCK) on mcs.custid = @mrecommend  and mcs.sporttype=cs.sporttype and mcs.bettype=cs.bettype
	inner join CustOverride3rd as mco with (NOLOCK) on mco.custid = @mrecommend  and mco.sporttype=cs.sporttype and mco.bettype=cs.bettype
	inner join CustOverride3rd as aco with (NOLOCK) on aco.custid = mb.recommend  and aco.sporttype=cs.sporttype and aco.bettype=cs.bettype
where cs.apositiontaking+cs.mpositiontaking>mco.maxpositiontaking
	and cs.sporttype = 201

----------------------------------------------------------------------------


----------------------------------------------------------------------------
--recal autopos
-- s1=min(s4-m1-a1,u)
Update cs 
	set spositiontaking = case when scs.spositiontaking-cs.mpositiontaking-cs.apositiontaking >
							(case when cs.isautopositiontaking=1 then cs.autopositiontaking else mcs.autopositiontaking end) then (case when cs.isautopositiontaking=1 then cs.autopositiontaking else mcs.autopositiontaking end) else scs.spositiontaking-cs.mpositiontaking-cs.apositiontaking end 
from
	CustSetting3rd as cs with (ROWLOCK, UPDLOCK)
	inner join custinfo as c with (NOLOCK) on cs.custid = c.custid
	inner join CustSetting3rd as mcs with (NOLOCK) on mcs.custid = c.mrecommend and mcs.sporttype=cs.sporttype and mcs.bettype=cs.bettype
	inner join CustSetting3rd as scs with (NOLOCK) on scs.custid = @srecommend and scs.sporttype=cs.sporttype and scs.bettype=cs.bettype
where
	c.mrecommend = @mrecommend
	and c.roleid = 1
	and (cs.isautopositiontaking=1 or mcs.isautopositiontaking=1)
	and cs.sporttype = 201

----------------------------------------------------------------------------



----------------------------------------------------------------------------
--check super min/max when a1+m1+s1<n4
-- s1=n4-m1-a1
Update cs 
set spositiontaking = sco.minpositiontaking-cs.mpositiontaking-cs.apositiontaking
from 
	CustSetting3rd as cs with (ROWLOCK, UPDLOCK)
	inner join custinfo as mb with (NOLOCK) on cs.custid = mb.custid and mb.mrecommend=@mrecommend and mb.roleid=1
	inner join CustOverride3rd as sco with (NOLOCK) on sco.custid = @srecommend  and sco.sporttype=cs.sporttype and sco.bettype=cs.bettype
where cs.apositiontaking+cs.mpositiontaking+cs.spositiontaking<sco.minpositiontaking
	and cs.sporttype = 201

----------------------------------------------------------------------------


----------------------------------------------------------------------------
-- Update s1,m1,a1 when s1+m1+a1>min(s4,l4)
-- s1=min(s4,l4)-m1-a1
-- m1=max(min(iif(s1+m1+a1>min(s4,l4),min(s4,l4)-m1-a1,m1+a1),l3),n3)-a1
-- a1=max(iif(a1+m1>max(min(iif(s1+m1+a1>min(s4,l4),min(s4,l4)-m1-a1,m1+a1),l3,n3),max(min(iif(s1+m1+a1>min(s4,l4),min(s4,l4)-m1-a1,m1+a1),l3,n3)-m1,a1),n2)
Update cs 
set @spos = case when scs.spositiontaking-cs.mpositiontaking-cs.apositiontaking<0 then 0 else scs.spositiontaking-cs.mpositiontaking-cs.apositiontaking end,
	spositiontaking = @spos,
	@mapos1 = case when @spos+cs.mpositiontaking+cs.apositiontaking>scs.spositiontaking then scs.spositiontaking-@spos else cs.mpositiontaking+cs.apositiontaking end,
	@maxmapos = case when mcs.mpositiontaking>mco.maxpositiontaking then mco.maxpositiontaking else mcs.mpositiontaking end,
	@mapos2 = case when @mapos1>@maxmapos then @maxmapos else @mapos1 end,
	@mapos = case when @mapos2<mco.minpositiontaking then mco.minpositiontaking else @mapos2 end,
	@mpos = case when @mapos-cs.apositiontaking<0 then 0 else @mapos-cs.apositiontaking end,
	mpositiontaking = @mpos,
	@apos = case when cs.apositiontaking + @mpos>@mapos then @mapos-@mpos else cs.apositiontaking end,
	apositiontaking = case when @apos<aco.minpositiontaking then aco.minpositiontaking else @apos end
from 
	CustSetting3rd as cs with (ROWLOCK, UPDLOCK)
	inner join custinfo as mb with (NOLOCK) on cs.custid = mb.custid and mb.mrecommend=@mrecommend and mb.roleid=1
	inner join CustSetting3rd as scs with (NOLOCK) on scs.custid = @srecommend  and scs.sporttype=cs.sporttype and scs.bettype=cs.bettype
	inner join CustSetting3rd as mcs with (NOLOCK) on mcs.custid = @mrecommend  and mcs.sporttype=cs.sporttype and mcs.bettype=cs.bettype
	inner join CustOverride3rd as mco with (NOLOCK) on mco.custid = @mrecommend  and mco.sporttype=cs.sporttype and mco.bettype=cs.bettype
	inner join CustOverride3rd as aco with (NOLOCK) on aco.custid = mb.recommend  and aco.sporttype=cs.sporttype and aco.bettype=cs.bettype
where cs.spositiontaking+cs.apositiontaking+cs.mpositiontaking>scs.spositiontaking
	and cs.sporttype = 201

GO
GRANT VIEW DEFINITION ON Acc_CustomerUpdMasterFI_MaxPositiontaking TO vnteam