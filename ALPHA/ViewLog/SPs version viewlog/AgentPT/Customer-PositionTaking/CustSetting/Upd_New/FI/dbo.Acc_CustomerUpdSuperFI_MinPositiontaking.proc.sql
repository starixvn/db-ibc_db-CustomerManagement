
ALTER PROCEDURE [dbo].Acc_CustomerUpdSuperFI_MinPositiontaking
	@srecommend int
AS
--@Source Control
/*
Created: 20090415@Phuc
Task : Update PT at member level when edit n4(finance)
DB: DB02.bodb02
Original: Acc_CustomerUpdMinMaxPositiontaking_SAg

Revisions:
	- 20090626@Phuc: auto master PT on member level.
    - 20090716@Phuc: remove update s1 = min(u,s1) cause of recal autos already do it.
					Remove sco cause of l4=s4(correct data when s1+m1+a1>s4)
	- 20091201@Kiwi: Move custsetting & custoverride to the separated tables (CustSetting3rd & CustOverride3rd).

Param's Explanation:
• @ErrCode:
    = 0: Update successfully.
    > 0: Specific Error.
  
• @ErrMsg: Error description.
*/


declare @mpos smallmoney, @apos smallmoney, @spos smallmoney, @mapos1 smallmoney, @mapos2 smallmoney, @mapos smallmoney, @maxmapos smallmoney

----------------------------------------------------------------------------
--fix super positiontaking if >max
--s1=u if u<s1 (s1=min(u,s1))

--update custsetting with (ROWLOCK, UPDLOCK) set custsetting.spositiontaking = case when custsetting.isautopositiontaking=1 then custsetting.autopositiontaking else mcs.autopositiontaking end
--from 
	--custsetting inner join customer as mb with (NOLOCK) on custsetting.custid = mb.custid and mb.srecommend = @srecommend and mb.roleid=1
	--inner join custsetting as mcs with (NOLOCK) on mcs.custid = mb.mrecommend and mcs.sporttype=custsetting.sporttype and mcs.bettype=custsetting.bettype
--where (custsetting.isautopositiontaking=1 or mcs.isautopositiontaking=1) and (case when custsetting.isautopositiontaking=1 then custsetting.autopositiontaking else mcs.autopositiontaking end)< custsetting.spositiontaking

/*
update custsetting with (ROWLOCK, UPDLOCK) set custsetting.spositiontaking = case when custsetting.isautopositiontaking=1 then custsetting.autopositiontaking else mcs.autopositiontaking end
from 
	custsetting inner join custinfo as mb with (NOLOCK) on custsetting.custid = mb.custid and mb.srecommend = @srecommend and mb.roleid=1
	inner join (
		select cs.custid, sporttype, bettype, isautopositiontaking, autopositiontaking
		from dbo.custsetting cs with (nolock)
		where custid in (select custid from dbo.custinfo m with (nolock) where srecommend = @srecommend and roleid = 3)
	) as mcs  on mcs.custid = mb.mrecommend and mcs.sporttype=custsetting.sporttype and mcs.bettype=custsetting.bettype
where (custsetting.isautopositiontaking=1 or mcs.isautopositiontaking=1) 
	and (case when custsetting.isautopositiontaking=1 then custsetting.autopositiontaking else mcs.autopositiontaking end)<custsetting.spositiontaking
	and custsetting.sporttype = 201
*/

----------------------------------------------------------------------------
--s1=min(s1,s4-m3) if i=0
update cs
	set cs.spositiontaking = scs.spositiontaking - mcs.mpositiontaking
from 
	CustSetting3rd as cs with (ROWLOCK, UPDLOCK)
	inner join custinfo as mb with (NOLOCK) on cs.custid = mb.custid and mb.srecommend = @srecommend and mb.roleid=1
	inner join CustSetting3rd as mcs with (NOLOCK) on mcs.custid = mb.mrecommend and mcs.sporttype=cs.sporttype and mcs.bettype=cs.bettype
	inner join CustSetting3rd as scs with (NOLOCK) on scs.custid = @srecommend and scs.sporttype=cs.sporttype and scs.bettype=cs.bettype
where cs.isautopositiontaking=0 and mcs.isautopositiontaking=0 
	and scs.spositiontaking - mcs.mpositiontaking<cs.spositiontaking
	and cs.sporttype = 201


----------------------------------------------------------------------------
--check agent min
--a1=max(a1,n2)
Update cs 
	set apositiontaking = aco.minpositiontaking,
		cs.mpositiontaking = case when cs.mpositiontaking + aco.minpositiontaking > mcs.mpositiontaking then mcs.mpositiontaking-aco.minpositiontaking else cs.mpositiontaking end
from 
	CustSetting3rd as cs with (ROWLOCK, UPDLOCK) 
	inner join custinfo as mb with (NOLOCK) on cs.custid = mb.custid and mb.srecommend=@srecommend and mb.roleid=1
	inner join CustSetting3rd as mcs with (NOLOCK) on mcs.custid = mb.mrecommend  and mcs.sporttype=cs.sporttype and mcs.bettype=cs.bettype
	inner join CustOverride3rd as aco with (NOLOCK) on aco.custid = mb.recommend  and aco.sporttype=cs.sporttype and aco.bettype=cs.bettype
where cs.apositiontaking<aco.minpositiontaking
	and cs.sporttype = 201

----------------------------------------------------------------------------
--check agent max
--a1=min(a1,l2)
Update cs
	set apositiontaking = aco.maxpositiontaking
from 
	CustSetting3rd as cs with (ROWLOCK, UPDLOCK) 
	inner join custinfo as mb with (NOLOCK) on cs.custid = mb.custid and mb.srecommend=@srecommend and roleid=1
	inner join CustOverride3rd as aco with (NOLOCK) on aco.custid = mb.recommend  and aco.sporttype=cs.sporttype and aco.bettype=cs.bettype
where cs.apositiontaking>aco.maxpositiontaking
	and cs.sporttype = 201

----------------------------------------------------------------------------


--Recal AUTO MPT m1=min(m3-a1,um2)
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
	c.srecommend = @srecommend
	and c.roleid = 1
	and (acs.isautompositiontaking = 1 or cs.isautompositiontaking = 1)
	and cs.sporttype = 201

	
-------------------------------------------------------------------------------------


--check master min
--m1=max(m1,n3-a1)
Update cs
	set mpositiontaking = mco.minpositiontaking-cs.apositiontaking
from 
	CustSetting3rd as cs with (ROWLOCK, UPDLOCK) 
	inner join custinfo as mb with (NOLOCK) on cs.custid = mb.custid and mb.srecommend=@srecommend and mb.roleid=1
	inner join CustOverride3rd as mco with (NOLOCK) on mco.custid = mb.mrecommend  and mco.sporttype=cs.sporttype and mco.bettype=cs.bettype
where cs.apositiontaking+cs.mpositiontaking<mco.minpositiontaking
	and cs.sporttype = 201

----------------------------------------------------------------------------
--check master max
Update cs 
	set @maxmapos = case when mcs.mpositiontaking>mco.maxpositiontaking then mco.maxpositiontaking else mcs.mpositiontaking end,
		@mpos = case when @maxmapos-cs.apositiontaking<0 then 0 else @maxmapos-cs.apositiontaking end,
		mpositiontaking = @mpos,
		@apos = case when cs.apositiontaking + @mpos>@maxmapos then @maxmapos-@mpos else cs.apositiontaking end,
		apositiontaking = case when @apos<aco.minpositiontaking then aco.minpositiontaking else @apos end
from 
	CustSetting3rd as cs with (ROWLOCK, UPDLOCK)
	inner join custinfo as mb with (NOLOCK) on cs.custid = mb.custid and mb.srecommend=@srecommend and mb.roleid=1
	inner join CustSetting3rd as mcs with (NOLOCK) on mcs.custid = mb.mrecommend  and mcs.sporttype=cs.sporttype and mcs.bettype=cs.bettype
	inner join CustOverride3rd as mco with (NOLOCK) on mco.custid = mb.mrecommend  and mco.sporttype=cs.sporttype and mco.bettype=cs.bettype
	inner join CustOverride3rd as aco with (NOLOCK) on aco.custid = mb.recommend  and aco.sporttype=cs.sporttype and aco.bettype=cs.bettype
where cs.apositiontaking+cs.mpositiontaking>mco.maxpositiontaking
	and cs.sporttype = 201

----------------------------------------------------------------------------------------------------------------------------------------------------------------------
--recal autopos
Update cs
	set spositiontaking = case when scs.spositiontaking-cs.mpositiontaking-cs.apositiontaking >
							(case when cs.isautopositiontaking=1 then cs.autopositiontaking else mcs.autopositiontaking end) then (case when cs.isautopositiontaking=1 then cs.autopositiontaking else mcs.autopositiontaking end) else scs.spositiontaking-cs.mpositiontaking-cs.apositiontaking end 
from
	CustSetting3rd as cs with (ROWLOCK, UPDLOCK) 
	inner join custinfo as c with (NOLOCK) on cs.custid = c.custid
	inner join CustSetting3rd as mcs with (NOLOCK) on mcs.custid = c.mrecommend and mcs.sporttype=cs.sporttype and mcs.bettype=cs.bettype
	inner join CustSetting3rd as scs with (NOLOCK) on scs.custid = @srecommend and scs.sporttype=cs.sporttype and scs.bettype=cs.bettype
where
	c.srecommend = @srecommend
	and c.roleid = 1
	and (cs.isautopositiontaking=1 or mcs.isautopositiontaking=1)
	and cs.sporttype = 201

----------------------------------------------------------------------------

--check super min
--s1=max(n4-m1-a1,s1)
Update cs
	set spositiontaking = sco.minpositiontaking-cs.mpositiontaking-cs.apositiontaking
from 
	CustSetting3rd as cs with (ROWLOCK, UPDLOCK) 
	inner join custinfo as mb with (NOLOCK) on cs.custid = mb.custid and mb.srecommend=@srecommend and mb.roleid=1
	inner join CustOverride3rd as sco with (NOLOCK) on sco.custid = @srecommend  and sco.sporttype=cs.sporttype and sco.bettype=cs.bettype
where cs.apositiontaking+cs.mpositiontaking+cs.spositiontaking<sco.minpositiontaking
	and cs.sporttype = 201

----------------------------------------------------------------------------

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
	inner join custinfo as mb with (NOLOCK) on cs.custid = mb.custid and mb.srecommend=@srecommend and mb.roleid=1
	inner join CustSetting3rd as scs with (NOLOCK) on scs.custid = @srecommend  and scs.sporttype=cs.sporttype and scs.bettype=cs.bettype
	inner join CustSetting3rd as mcs with (NOLOCK) on mcs.custid = mb.mrecommend  and mcs.sporttype=cs.sporttype and mcs.bettype=cs.bettype
	inner join CustOverride3rd as mco with (NOLOCK) on mco.custid = mb.mrecommend  and mco.sporttype=cs.sporttype and mco.bettype=cs.bettype
	inner join CustOverride3rd as aco with (NOLOCK) on aco.custid = mb.recommend  and aco.sporttype=cs.sporttype and aco.bettype=cs.bettype
where cs.spositiontaking+cs.apositiontaking+cs.mpositiontaking>scs.spositiontaking
	and cs.sporttype = 201


GO
GRANT EXECUTE ON [dbo].Acc_CustomerUpdSuperFI_MinPositiontaking TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].Acc_CustomerUpdSuperFI_MinPositiontaking TO vnteam
GO
