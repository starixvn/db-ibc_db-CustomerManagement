/****** Object:  StoredProcedure [dbo].[Acc_CustomerUpdMaxPositiontaking_Master]    Script Date: 11/05/2007 11:38:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].Acc_CustomerUpdMaster_MaxPositiontaking 
	@mrecommend int
AS

--@Source Control
/*
Created: 20080515@Thien
Task : Update PT at member level when super update master.
DB: DB02.bodb02
Original: [Acc_CustomerUpdMaxPositiontaking_Master]

Revisions:
	- 20080923@Phuc: Recal auto master postiontaking 
    - 20081125@Phuc: Remove update m2,a2 when m2+a2>m3; update m1,a1 when m1+a1>m3  
    - 20090628@Phuc: auto master PT on member level.
    - 20090716@Phuc: Remove connection to custoveride table cause of l4=s4(correct data when s1+m1+a1>s4)

Param's Explanation:
• @ErrCode:
    = 0: Update successfully.
    > 0: Specific Error.
  
• @ErrMsg: Error description.
*/


declare @srecommend int
select @srecommend = srecommend from customer with (NOLOCK) where custid = @mrecommend
--Update all agent and member accounts

declare @mpos smallmoney, @apos smallmoney, @spos smallmoney, @mapos1 smallmoney, @mapos2 smallmoney, @mapos smallmoney, @maxmapos smallmoney

--Phuc remove @20081125 
/*
-- Update m2,a2 when m2+a2>m3(normal)
-- m2=m3-a2,a2=max(iif(m3<m2+a2,m3-m2,a2),n2)

Update custsetting with (ROWLOCK, UPDLOCK) set 
	@mpos = case when mcs.mpositiontaking-custsetting.apositiontaking<0 then 0 else mcs.mpositiontaking-custsetting.apositiontaking end,
	mpositiontaking = @mpos,
	@apos = case when mcs.mpositiontaking-@mpos-custsetting.apositiontaking<0 then mcs.mpositiontaking-@mpos else custsetting.apositiontaking end,
	apositiontaking = case when aco.minpositiontaking > @apos then aco.minpositiontaking else @apos end 
from 
	custsetting inner join customer as a with (NOLOCK) on custsetting.custid = a.custid and a.mrecommend = @mrecommend and a.roleid = 2
	inner join custsetting as mcs with (NOLOCK) on mcs.custid = @mrecommend and mcs.sporttype=custsetting.sporttype and mcs.bettype=custsetting.bettype
	inner join custoverride as aco with (NOLOCK) on aco.custid = custsetting.custid  and aco.sporttype=custsetting.sporttype and aco.bettype=custsetting.bettype
where 
	custsetting.mpositiontaking+custsetting.apositiontaking > mcs.mpositiontaking

-- Update m2,a2 when m2+a2>m3(live)
-- m2=m3-a2,a2=max(iif(m3<m2+a2,m3-m2,a2),n2)
Update custsetting with (ROWLOCK, UPDLOCK) set 
	@mpos = case when mcs.mlivepositiontaking-custsetting.alivepositiontaking<0 then 0 else mcs.mlivepositiontaking-custsetting.alivepositiontaking end,
	mlivepositiontaking = @mpos,
	@apos = case when mcs.mlivepositiontaking-@mpos-custsetting.alivepositiontaking<0 then mcs.mlivepositiontaking-@mpos else custsetting.alivepositiontaking end,
	alivepositiontaking = case when aco.minlivepositiontaking > @apos then aco.minlivepositiontaking else @apos end 
from 
	custsetting inner join customer as a with (NOLOCK) on custsetting.custid = a.custid and a.mrecommend = @mrecommend and a.roleid = 2
	inner join custsetting as mcs with (NOLOCK) on mcs.custid = @mrecommend and mcs.sporttype=custsetting.sporttype and mcs.bettype=custsetting.bettype
	inner join custoverride as aco with (NOLOCK) on aco.custid = custsetting.custid  and aco.sporttype=custsetting.sporttype and aco.bettype=custsetting.bettype
where 
	custsetting.sporttype=1 and custsetting.bettype in (1,3,7,8) 
	and custsetting.mlivepositiontaking+custsetting.alivepositiontaking > mcs.mlivepositiontaking
*/

--Recal AUTO MPT m1=min(m3-a1,u2)
-------------------------------------------------------------------------------------
Update custsetting with (ROWLOCK, UPDLOCK) 
	set mpositiontaking = 
		case when mcs.mpositiontaking-custsetting.apositiontaking > case when custsetting.isautompositiontaking = 1 then custsetting.autompositiontaking else acs.autompositiontaking end
			then case when custsetting.isautompositiontaking = 1 then custsetting.autompositiontaking else acs.autompositiontaking end
		else  mcs.mpositiontaking-custsetting.apositiontaking end
from
	custsetting
	inner join custinfo as c with (NOLOCK) on custsetting.custid = c.custid
	inner join custsetting as mcs with (NOLOCK) on mcs.custid = c.mrecommend and mcs.sporttype=custsetting.sporttype and mcs.bettype=custsetting.bettype
	inner join custsetting as acs with (NOLOCK) on acs.custid = c.recommend and acs.sporttype=custsetting.sporttype and acs.bettype=custsetting.bettype
where
	c.mrecommend = @mrecommend
	and c.roleid = 1
	and (acs.isautompositiontaking = 1 or custsetting.isautompositiontaking = 1)
		
Update custsetting with (ROWLOCK, UPDLOCK) 
	set mlivepositiontaking =
		case when mcs.mlivepositiontaking-custsetting.alivepositiontaking > case when custsetting.isautolivempositiontaking = 1 then custsetting.autolivempositiontaking else acs.autolivempositiontaking end
			then case when custsetting.isautolivempositiontaking = 1 then custsetting.autolivempositiontaking else acs.autolivempositiontaking end
		else  mcs.mlivepositiontaking-custsetting.alivepositiontaking end
from
	custsetting
	inner join custinfo as c with (NOLOCK) on custsetting.custid = c.custid
	inner join custsetting as mcs with (NOLOCK) on mcs.custid = c.mrecommend and mcs.sporttype=custsetting.sporttype and mcs.bettype=custsetting.bettype
	inner join custsetting as acs with (NOLOCK) on acs.custid = c.recommend and acs.sporttype=custsetting.sporttype and acs.bettype=custsetting.bettype
where
	c.mrecommend = @mrecommend
	and c.roleid = 1
	and (acs.isautolivempositiontaking = 1 or custsetting.isautolivempositiontaking = 1)

-------------------------------------------------------------------------------------



----------------------------------------------------------------------------
--check master min/max
--m1=n3-a1
Update custsetting with (ROWLOCK, UPDLOCK) set 
	mpositiontaking = mco.minpositiontaking-custsetting.apositiontaking
from 
	custsetting inner join custinfo as mb with (NOLOCK) on custsetting.custid = mb.custid and mb.mrecommend=@mrecommend and mb.roleid=1
	inner join custoverride as mco with (NOLOCK) on mco.custid = @mrecommend  and mco.sporttype=custsetting.sporttype and mco.bettype=custsetting.bettype
where custsetting.apositiontaking+custsetting.mpositiontaking<mco.minpositiontaking

Update custsetting with (ROWLOCK, UPDLOCK) set 
	mlivepositiontaking = mco.minlivepositiontaking-custsetting.alivepositiontaking
from 
	custsetting inner join custinfo as mb with (NOLOCK) on custsetting.custid = mb.custid and mb.mrecommend=@mrecommend and mb.roleid=1
	inner join custoverride as mco with (NOLOCK) on mco.custid = @mrecommend  and mco.sporttype=custsetting.sporttype and mco.bettype=custsetting.bettype
where custsetting.sporttype=1 and custsetting.bettype in (1,3,7,8) and custsetting.alivepositiontaking+custsetting.mlivepositiontaking<mco.minlivepositiontaking
----------------------------------------------------------------------------


----------------------------------------------------------------------------
-- Update m1,a1 when m1+a1>l3
-- m1=min(m3,l3)-a1
Update custsetting with (ROWLOCK, UPDLOCK) set 
	@maxmapos = case when mcs.mpositiontaking>mco.maxpositiontaking then mco.maxpositiontaking else mcs.mpositiontaking end,
	@mpos = case when @maxmapos-custsetting.apositiontaking<0 then 0 else @maxmapos-custsetting.apositiontaking end,
	mpositiontaking = @mpos,
	@apos = case when custsetting.apositiontaking + @mpos>@maxmapos then @maxmapos-@mpos else custsetting.apositiontaking end,
	apositiontaking = case when @apos<aco.minpositiontaking then aco.minpositiontaking else @apos end
from 
	custsetting inner join custinfo as mb with (NOLOCK) on custsetting.custid = mb.custid and mb.mrecommend=@mrecommend and mb.roleid=1
	inner join custsetting as mcs with (NOLOCK) on mcs.custid = @mrecommend  and mcs.sporttype=custsetting.sporttype and mcs.bettype=custsetting.bettype
	inner join custoverride as mco with (NOLOCK) on mco.custid = @mrecommend  and mco.sporttype=custsetting.sporttype and mco.bettype=custsetting.bettype
	inner join custoverride as aco with (NOLOCK) on aco.custid = mb.recommend  and aco.sporttype=custsetting.sporttype and aco.bettype=custsetting.bettype
where custsetting.apositiontaking+custsetting.mpositiontaking>mco.maxpositiontaking

Update custsetting with (ROWLOCK, UPDLOCK) set 
	@maxmapos = case when mcs.mlivepositiontaking>mco.maxlivepositiontaking then mco.maxlivepositiontaking else mcs.mlivepositiontaking end,
	@mpos = case when @maxmapos-custsetting.alivepositiontaking<0 then 0 else @maxmapos-custsetting.alivepositiontaking end,
	mlivepositiontaking = @mpos,
	@apos = case when custsetting.alivepositiontaking + @mpos>@maxmapos then @maxmapos-@mpos else custsetting.alivepositiontaking end,
	alivepositiontaking = case when @apos<aco.minlivepositiontaking then aco.minlivepositiontaking else @apos end
from 
	custsetting inner join custinfo as mb with (NOLOCK) on custsetting.custid = mb.custid and mb.mrecommend=@mrecommend and mb.roleid=1
	inner join custsetting as mcs with (NOLOCK) on mcs.custid = @mrecommend  and mcs.sporttype=custsetting.sporttype and mcs.bettype=custsetting.bettype
	inner join custoverride as mco with (NOLOCK) on mco.custid = @mrecommend  and mco.sporttype=custsetting.sporttype and mco.bettype=custsetting.bettype
	inner join custoverride as aco with (NOLOCK) on aco.custid = mb.recommend  and aco.sporttype=custsetting.sporttype and aco.bettype=custsetting.bettype
where custsetting.sporttype=1 and custsetting.bettype in (1,3,7,8) and custsetting.alivepositiontaking+custsetting.mlivepositiontaking>mco.maxlivepositiontaking
----------------------------------------------------------------------------


----------------------------------------------------------------------------
--recal autopos
-- s1=min(s4-m1-a1,u)
Update custsetting with (ROWLOCK, UPDLOCK) 
	set spositiontaking = case when scs.spositiontaking-custsetting.mpositiontaking-custsetting.apositiontaking >
							(case when custsetting.isautopositiontaking=1 then custsetting.autopositiontaking else mcs.autopositiontaking end) then (case when custsetting.isautopositiontaking=1 then custsetting.autopositiontaking else mcs.autopositiontaking end) else scs.spositiontaking-custsetting.mpositiontaking-custsetting.apositiontaking end 
from
	custsetting
	inner join custinfo as c with (NOLOCK) on custsetting.custid = c.custid
	inner join custsetting as mcs with (NOLOCK) on mcs.custid = c.mrecommend and mcs.sporttype=custsetting.sporttype and mcs.bettype=custsetting.bettype
	inner join custsetting as scs with (NOLOCK) on scs.custid = @srecommend and scs.sporttype=custsetting.sporttype and scs.bettype=custsetting.bettype
where
	c.mrecommend = @mrecommend
	and c.roleid = 1
	and (custsetting.isautopositiontaking=1 or mcs.isautopositiontaking=1)

Update custsetting with (ROWLOCK, UPDLOCK) 
	set slivepositiontaking = case when scs.slivepositiontaking-custsetting.mlivepositiontaking-custsetting.alivepositiontaking >
							(case when custsetting.isautolivepositiontaking=1 then custsetting.autolivepositiontaking else mcs.autolivepositiontaking end) then (case when custsetting.isautolivepositiontaking=1 then custsetting.autolivepositiontaking else mcs.autolivepositiontaking end) else scs.slivepositiontaking-custsetting.mlivepositiontaking-custsetting.alivepositiontaking end 
from
	custsetting
	inner join custinfo as c with (NOLOCK) on custsetting.custid = c.custid
	inner join custsetting as mcs with (NOLOCK) on mcs.custid = c.mrecommend and mcs.sporttype=custsetting.sporttype and mcs.bettype=custsetting.bettype
	inner join custsetting as scs with (NOLOCK) on scs.custid = @srecommend and scs.sporttype=custsetting.sporttype and scs.bettype=custsetting.bettype
where
	c.mrecommend = @mrecommend
	and c.roleid = 1
	and (custsetting.isautolivepositiontaking=1 or mcs.isautolivepositiontaking=1)
----------------------------------------------------------------------------



----------------------------------------------------------------------------
--check super min/max when a1+m1+s1<n4
-- s1=n4-m1-a1
Update custsetting with (ROWLOCK, UPDLOCK) set 
	spositiontaking = sco.minpositiontaking-custsetting.mpositiontaking-custsetting.apositiontaking
from 
	custsetting inner join custinfo as mb with (NOLOCK) on custsetting.custid = mb.custid and mb.mrecommend=@mrecommend and mb.roleid=1
	inner join custoverride as sco with (NOLOCK) on sco.custid = @srecommend  and sco.sporttype=custsetting.sporttype and sco.bettype=custsetting.bettype
where custsetting.apositiontaking+custsetting.mpositiontaking+custsetting.spositiontaking<sco.minpositiontaking

Update custsetting with (ROWLOCK, UPDLOCK) set 
	slivepositiontaking = sco.minlivepositiontaking-custsetting.mlivepositiontaking-custsetting.alivepositiontaking
from 
	custsetting inner join custinfo as mb with (NOLOCK) on custsetting.custid = mb.custid and mb.mrecommend=@mrecommend and mb.roleid=1
	inner join custoverride as sco with (NOLOCK) on sco.custid = @srecommend  and sco.sporttype=custsetting.sporttype and sco.bettype=custsetting.bettype
where custsetting.sporttype=1 and custsetting.bettype in (1,3,7,8) and custsetting.alivepositiontaking+custsetting.mlivepositiontaking+custsetting.slivepositiontaking<sco.minlivepositiontaking
----------------------------------------------------------------------------


--update s1,m1,a1 in case s1+m1+a1>s4
--s1=max(0,s4-m1-a1)
--@mapos1=iif(s1_new+m1+a1>s4,s4-s1_new,m1+a1)
--@maxmapos=min(m3,l3)
--@mapos2=min(@mapos1,@maxmapos)
--@mapos=max(@mapos2,n3)
--m1=max(0,@mapos-a1)
--a1=iif(m1_new+a1>@mapos,@mapos-m1_new,a1)
Update custsetting with (ROWLOCK, UPDLOCK) set 
	@spos = case when scs.spositiontaking-custsetting.mpositiontaking-custsetting.apositiontaking<0 then 0 else scs.spositiontaking-custsetting.mpositiontaking-custsetting.apositiontaking end,
	spositiontaking = @spos,
	@mapos1 = case when @spos+custsetting.mpositiontaking+custsetting.apositiontaking>scs.spositiontaking then scs.spositiontaking-@spos else custsetting.mpositiontaking+custsetting.apositiontaking end,
	@maxmapos = case when mcs.mpositiontaking>mco.maxpositiontaking then mco.maxpositiontaking else mcs.mpositiontaking end,
	@mapos2 = case when @mapos1>@maxmapos then @maxmapos else @mapos1 end,
	@mapos = case when @mapos2<mco.minpositiontaking then mco.minpositiontaking else @mapos2 end,
	@mpos = case when @mapos-custsetting.apositiontaking<0 then 0 else @mapos-custsetting.apositiontaking end,
	mpositiontaking = @mpos,
	@apos = case when custsetting.apositiontaking + @mpos>@mapos then @mapos-@mpos else custsetting.apositiontaking end,
	apositiontaking = case when @apos<aco.minpositiontaking then aco.minpositiontaking else @apos end
from 
	custsetting inner join custinfo as mb with (NOLOCK) on custsetting.custid = mb.custid and mb.mrecommend=@mrecommend and mb.roleid=1
	inner join custsetting as scs with (NOLOCK) on scs.custid = @srecommend  and scs.sporttype=custsetting.sporttype and scs.bettype=custsetting.bettype
	inner join custsetting as mcs with (NOLOCK) on mcs.custid = @mrecommend  and mcs.sporttype=custsetting.sporttype and mcs.bettype=custsetting.bettype
	inner join custoverride as mco with (NOLOCK) on mco.custid = @mrecommend  and mco.sporttype=custsetting.sporttype and mco.bettype=custsetting.bettype
	inner join custoverride as aco with (NOLOCK) on aco.custid = mb.recommend  and aco.sporttype=custsetting.sporttype and aco.bettype=custsetting.bettype
where custsetting.spositiontaking+custsetting.apositiontaking+custsetting.mpositiontaking>scs.spositiontaking

Update custsetting with (ROWLOCK, UPDLOCK) set 
	@spos = case when scs.slivepositiontaking-custsetting.mlivepositiontaking-custsetting.alivepositiontaking<0 then 0 else scs.slivepositiontaking-custsetting.mlivepositiontaking-custsetting.alivepositiontaking end,
	slivepositiontaking = @spos,
	@mapos1 = case when @spos+custsetting.mlivepositiontaking+custsetting.alivepositiontaking>scs.slivepositiontaking then scs.slivepositiontaking-@spos else custsetting.mlivepositiontaking+custsetting.alivepositiontaking end,
	@maxmapos = case when mcs.mlivepositiontaking>mco.maxlivepositiontaking then mco.maxlivepositiontaking else mcs.mlivepositiontaking end,
	@mapos2 = case when @mapos1>@maxmapos then @maxmapos else @mapos1 end,
	@mapos = case when @mapos2<mco.minlivepositiontaking then mco.minlivepositiontaking else @mapos2 end,
	@mpos = case when @mapos-custsetting.alivepositiontaking<0 then 0 else @mapos-custsetting.alivepositiontaking end,
	mlivepositiontaking = @mpos,
	@apos = case when custsetting.alivepositiontaking + @mpos>@mapos then @mapos-@mpos else custsetting.alivepositiontaking end,
	alivepositiontaking = case when @apos<aco.minlivepositiontaking then aco.minlivepositiontaking else @apos end
from 
	custsetting inner join custinfo as mb with (NOLOCK) on custsetting.custid = mb.custid and mb.mrecommend=@mrecommend and mb.roleid=1
	inner join custsetting as scs with (NOLOCK) on scs.custid = @srecommend  and scs.sporttype=custsetting.sporttype and scs.bettype=custsetting.bettype
	inner join custsetting as mcs with (NOLOCK) on mcs.custid = @mrecommend  and mcs.sporttype=custsetting.sporttype and mcs.bettype=custsetting.bettype
	inner join custoverride as sco with (NOLOCK) on sco.custid = @srecommend  and sco.sporttype=custsetting.sporttype and sco.bettype=custsetting.bettype
	inner join custoverride as mco with (NOLOCK) on mco.custid = @mrecommend  and mco.sporttype=custsetting.sporttype and mco.bettype=custsetting.bettype
	inner join custoverride as aco with (NOLOCK) on aco.custid = mb.recommend  and aco.sporttype=custsetting.sporttype and aco.bettype=custsetting.bettype
where custsetting.sporttype=1 and custsetting.bettype in (1,3,7,8) and custsetting.slivepositiontaking+custsetting.alivepositiontaking+custsetting.mlivepositiontaking>scs.slivepositiontaking
----------------------------------------------------------------------------



GO
