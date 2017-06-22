ALTER PROCEDURE [dbo].Acc_CustomerUpdAgentHR_MinMaxPositiontaking
	@recommend int,
	@mrecommend int,
	@srecommend int
AS
--@Source Control
/*
Created: 20090520@Phuc
Task : update PT at member level when update n2,l2(HR)
DB: DB02.bodb02
Original:[Acc_CustomerUpdMinMaxPositiontaking_Ag]

Revisions:
    - 20090716@Phuc: Remove update s1 = min(u,s1) cause of recal autos already do it.
					 Remove connection to custoveride table cause of l4=s4(correct data when s1+m1+a1>s4)
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
/*
update custsetting with (ROWLOCK, UPDLOCK) set cs.spositiontaking = case when cs.isautopositiontaking=1 then cs.autopositiontaking else mcs.autopositiontaking end
from 
	custsetting inner join custinfo as mb with (NOLOCK) on cs.custid = mb.custid and mb.recommend = @recommend and mb.roleid=1
	inner join custsetting as mcs with (NOLOCK) on mcs.custid = mb.mrecommend and mcs.sporttype=cs.sporttype and mcs.bettype=cs.bettype
where (cs.isautopositiontaking=1 or mcs.isautopositiontaking=1) 
	and (case when cs.isautopositiontaking=1 then cs.autopositiontaking else mcs.autopositiontaking end)<cs.spositiontaking
	and cs.sporttype = 151
*/

-------------------------------------------------------------------------------------
--check agent min/max
-- Update a1 when a1<n2
-- a1=n2
Update cs
	set apositiontaking = aco.minpositiontaking,
		cs.mpositiontaking = case when cs.mpositiontaking + aco.minpositiontaking > mcs.mpositiontaking then mcs.mpositiontaking-aco.minpositiontaking else cs.mpositiontaking end
from 
	CustSetting3rd as cs with (ROWLOCK, UPDLOCK)
	inner join custinfo as mb with (NOLOCK) on cs.custid = mb.custid and mb.recommend=@recommend and mb.roleid=1
	inner join CustSetting3rd as mcs with (NOLOCK) on mcs.custid = @mrecommend  and mcs.sporttype=cs.sporttype and mcs.bettype=cs.bettype
	inner join CustOverride3rd as aco with (NOLOCK) on aco.custid = @recommend  and aco.sporttype=cs.sporttype and aco.bettype=cs.bettype
where cs.apositiontaking < aco.minpositiontaking
	and cs.sporttype = 151



-------------------------------------------------------------------------------------


-------------------------------------------------------------------------------------
-- Update a1 when a1>l2
-- a1=l2
Update cs
	set apositiontaking = aco.maxpositiontaking
from 
	CustSetting3rd as cs with (ROWLOCK, UPDLOCK)
	inner join custinfo as mb with (NOLOCK) on cs.custid = mb.custid and mb.recommend=@recommend and mb.roleid=1
	inner join CustOverride3rd as aco with (NOLOCK) on aco.custid = @recommend  and aco.sporttype=cs.sporttype and aco.bettype=cs.bettype
where cs.apositiontaking > aco.maxpositiontaking
	and cs.sporttype = 151

-------------------------------------------------------------------------------------



--Recal AUTO MPT 
--Update m1=min(m3-a1,u2)
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
	c.recommend = @recommend
	and c.roleid = 1
	and (acs.isautompositiontaking = 1 or cs.isautompositiontaking = 1)
	and cs.sporttype = 151

	
------------------------------------------------------------------------------------


-------------------------------------------------------------------------------------
--check master min/max
-- Update m1 when m1+a1<n3
-- m1=n3-a1
Update cs
	set mpositiontaking = mco.minpositiontaking-cs.apositiontaking
from 
	CustSetting3rd as cs with (ROWLOCK, UPDLOCK)
	inner join custinfo as mb with (NOLOCK) on cs.custid = mb.custid and mb.recommend=@recommend and mb.roleid=1
	inner join CustOverride3rd as mco with (NOLOCK) on mco.custid = @mrecommend  and mco.sporttype=cs.sporttype and mco.bettype=cs.bettype
where cs.apositiontaking+cs.mpositiontaking<mco.minpositiontaking
	and cs.sporttype = 151


-------------------------------------------------------------------------------------


-------------------------------------------------------------------------------------
-- Update m1,a1 when m1+a1>l3
-- m1=min(m3,l3)-a1
-- a1=max(iif(m1+a1>min(m3,l3),min(m3,l3)-m1,a1),n2)
Update cs 
	set @maxmapos = case when mcs.mpositiontaking>mco.maxpositiontaking then mco.maxpositiontaking else mcs.mpositiontaking end,
		@mpos = case when @maxmapos-cs.apositiontaking<0 then 0 else @maxmapos-cs.apositiontaking end,
		mpositiontaking = @mpos,
		@apos = case when cs.apositiontaking + @mpos>@maxmapos then @maxmapos-@mpos else cs.apositiontaking end,
		apositiontaking = case when @apos<aco.minpositiontaking then aco.minpositiontaking else @apos end
from 
	CustSetting3rd as cs with (ROWLOCK, UPDLOCK)
	inner join custinfo as mb with (NOLOCK) on cs.custid = mb.custid and mb.recommend=@recommend and mb.roleid=1
	inner join CustSetting3rd as mcs with (NOLOCK) on mcs.custid = @mrecommend  and mcs.sporttype=cs.sporttype and mcs.bettype=cs.bettype
	inner join CustOverride3rd as mco with (NOLOCK) on mco.custid = @mrecommend  and mco.sporttype=cs.sporttype and mco.bettype=cs.bettype
	inner join CustOverride3rd as aco with (NOLOCK) on aco.custid = @recommend  and aco.sporttype=cs.sporttype and aco.bettype=cs.bettype
where cs.apositiontaking+cs.mpositiontaking>mco.maxpositiontaking
	and cs.sporttype = 151

-------------------------------------------------------------------------------------


-------------------------------------------------------------------------------------
--s1=min(s4-m1-a1,u)
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
	c.recommend = @recommend
	and c.roleid = 1
	and (cs.isautopositiontaking=1 or mcs.isautopositiontaking=1)
	and cs.sporttype = 151


-------------------------------------------------------------------------------------


-------------------------------------------------------------------------------------
--check super min/max
--Update s1 when s1+m1+a1<n4
--s1=n4-m1-a1 
Update cs
	set spositiontaking = sco.minpositiontaking-cs.mpositiontaking-cs.apositiontaking
from 
	CustSetting3rd as cs with (ROWLOCK, UPDLOCK)
	inner join custinfo as mb with (NOLOCK) on cs.custid = mb.custid and mb.recommend=@recommend and mb.roleid=1
	inner join CustOverride3rd as sco with (NOLOCK) on sco.custid = @srecommend  and sco.sporttype=cs.sporttype and sco.bettype=cs.bettype
where cs.apositiontaking+cs.mpositiontaking+cs.spositiontaking<sco.minpositiontaking
	and cs.sporttype = 151

-------------------------------------------------------------------------------------



--update s1,m1,a1 in case s1+m1+a1>s4
--s1=max(0,s4-m1-a1)
--@mapos1=iif(s1_new+m1+a1>s4,s4-s1_new,m1+a1)
--@maxmapos=min(m3,l3)
--@mapos2=min(@mapos1,@maxmapos)
--@mapos=max(@mapos2,n3)
--m1=max(0,@mapos-a1)
--a1=iif(m1_new+a1>@mapos,@mapos-m1_new,a1)
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
	inner join custinfo as mb with (NOLOCK) on cs.custid = mb.custid and mb.recommend=@recommend and mb.roleid=1
	inner join CustSetting3rd as scs with (NOLOCK) on scs.custid = @srecommend  and scs.sporttype=cs.sporttype and scs.bettype=cs.bettype
	inner join CustSetting3rd as mcs with (NOLOCK) on mcs.custid = @mrecommend  and mcs.sporttype=cs.sporttype and mcs.bettype=cs.bettype
	inner join CustOverride3rd as mco with (NOLOCK) on mco.custid = @mrecommend  and mco.sporttype=cs.sporttype and mco.bettype=cs.bettype
	inner join CustOverride3rd as aco with (NOLOCK) on aco.custid = @recommend  and aco.sporttype=cs.sporttype and aco.bettype=cs.bettype
where cs.spositiontaking+cs.apositiontaking+cs.mpositiontaking>scs.spositiontaking
	and cs.sporttype = 151


GO
GRANT EXECUTE ON [dbo].Acc_CustomerUpdAgentHR_MinMaxPositiontaking TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].Acc_CustomerUpdAgentHR_MinMaxPositiontaking TO vnteam
GO
