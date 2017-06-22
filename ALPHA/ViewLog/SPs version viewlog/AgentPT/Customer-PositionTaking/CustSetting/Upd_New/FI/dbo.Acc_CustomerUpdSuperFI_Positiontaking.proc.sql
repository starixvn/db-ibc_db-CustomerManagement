ALTER PROCEDURE [dbo].[Acc_CustomerUpdSuperFI_Positiontaking]
	@custid int,-- superid	
	@v201spositiontaking_2 smallmoney,
	@v201spositiontaking_3 smallmoney,
	@v201mpositiontaking_2 smallmoney = 0.5,
	@v201mpositiontaking_3 smallmoney = 0.5,
	@v201apositiontaking_2 smallmoney = 0.5,
	@v201apositiontaking_3 smallmoney = 0.5,
	@UserID int = 0,	
	@Language varchar(2) = 'E',
	@IP varchar(15)='',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS
--@Source Control
/*
Created: 20090415@Phuc
Task : Update FI's Super PT 
DB: DB02.bodb02

Revisions:
	- 20090529@Phuc: Check m1+a1<=m4, a1<=a4
	- 20090917@Phuc: write log into DBLOG.
	- 20091201@Kiwi: Move custsetting & custoverride to the separated tables (CustSetting3rd & CustOverride3rd).
	- 20100112@Kiwi: Amend to write log in xml format.
Param's Explanation:
• @ErrCode:
    = 0: Transaction recorded successfully.
    > 0: Specific Error.
  
• @ErrMsg: Error description.
*/

SET NOCOUNT ON

Declare @username varchar(40)
select @username = username from custinfo with (NOLOCK) where custid = @custid
--------------------------------------------------------------------------------------------
--Check Param
Declare @ErrAcc nvarchar(4000)
declare @ErrType varchar(1000)

if @v201spositiontaking_2  <0
	or @v201spositiontaking_3  <0
	or @v201mpositiontaking_2  <0
	or @v201mpositiontaking_3  <0
	or @v201apositiontaking_2  <0
	or @v201apositiontaking_3  <0
	or @v201spositiontaking_2  >0.9
	or @v201spositiontaking_3  >0.9
	or @v201mpositiontaking_2  >0.9
	or @v201mpositiontaking_3  >0.9
	or @v201apositiontaking_2  >0.9
	or @v201apositiontaking_3  >0.9
	or @v201spositiontaking_2   <  @v201mpositiontaking_2
	or @v201spositiontaking_3   <  @v201mpositiontaking_3
	or @v201mpositiontaking_2   <  @v201apositiontaking_2
	or @v201mpositiontaking_3   <  @v201apositiontaking_3
BEGIN
	
	Select @ErrMsg = 	@UserName + ': '+
		case @Language 
						when 'E' then 'Wrong position taking.'
						when 'CS' then N'占成数不正确.'
						when 'CT' then N'佔成數不正確.'
						when 'TH' then N'การกำหนดจำนวนเงินไม่ถูกต้อง.'
						when 'J' then N'Wrong position taking.'
						else N'Wrong position taking.'
				end, @ErrCode = 101
	return
END

--check n4<=s4
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Min: '+ cast((co.minpositiontaking) as varchar(10)) + '<br>'
	from CustOverride3rd as co with (NOLOCK) 
	inner join
	(
					select 2 as bettype, 201 as sporttype, @v201spositiontaking_2 as spositiontaking
		union all 	select 3 as bettype, 201 as sporttype, @v201spositiontaking_3 as spositiontaking

	) as b on co.sporttype=b.sporttype and co.bettype = b.bettype
	inner join sports with (nolock) on b.sporttype = sports.sporttype
	inner join bettype with (nolock) on b.bettype = bettype.typeid
where co.custid = @custid and (b.spositiontaking<co.minpositiontaking) 

if @ErrType <>''
BEGIN
	Select @ErrMsg = 	@UserName + ': '+
		case @Language 
						when 'E' then 'Wrong position taking (min set by company).<br>'+@ErrType
						when 'CS' then N'占成数不正确(公司设给最低占成).<br>'+@ErrType
						when 'CT' then N'佔成數不正確(公司設給最低佔成).<br>'+@ErrType
						when 'TH' then N'การกำหนดจำนวนเงินไม่ถูกต้อง (ต่ำสุด อ้างอิงจากข้อมูลบริษัท).<br>'+@ErrType
						when 'J' then N'Wrong position taking (min set by company).<br>'+@ErrType
						else N'Wrong position taking (min set by company).<br>'+@ErrType
				end, @ErrCode = 102
	return
END

--check all s3+m3<=s4 if i3 = 0,
--m3<=s4 and u3<=s4 if i3=1
select @ErrAcc = ''
select top 100 @ErrAcc = @ErrAcc + username +', '
from 
	custinfo as c with (NOLOCK) 
	inner join CustSetting3rd as cs with (NOLOCK) on c.custid = cs.custid
	inner join (
					  select 	201 as sporttype, 2 as bettype, @v201spositiontaking_2 as maxpositiontaking
			union all select 	201 as sporttype, 3 as bettype, @v201spositiontaking_3 as maxpositiontaking
		) as b on cs.sporttype=b.sporttype and cs.bettype = b.bettype
where c.srecommend = @custid and c.roleid = 3 and (
						((cs.isautopositiontaking=0) and (cs.spositiontaking+cs.mpositiontaking>b.maxpositiontaking)) or 
						((cs.isautopositiontaking=1) and (cs.mpositiontaking>b.maxpositiontaking)) or 
						((cs.isautopositiontaking=1) and (cs.autopositiontaking>b.maxpositiontaking)) 
					)
group by username
if @ErrAcc<>''
BEGIN
	Select @ErrMsg = 	@UserName + ': '+
		case @Language 
						when 'E' then 'Existing masters exceeded new super position taking ('+@ErrAcc+').'
						when 'CS' then N'现有总代理超出新超级总代理占成数设定 ('+@ErrAcc+').'
						when 'CT' then N'現有總代理超出新超級總代理佔成數設定 ('+@ErrAcc+').'
						when 'TH' then N'ตัวแทนหลักที่มีอยู่ขณะนี้เกินกว่าจำนวนตัวแทนสูงสุดที่บริษัทกำหนดไว้('+@ErrAcc+').'
						when 'J' then N'Existing masters exceeded new super position taking ('+@ErrAcc+').'
						else N'Existing masters exceeded new super position taking ('+@ErrAcc+').'
				end, @ErrCode = 103
	return
END
--check all s1+m1+a1 <= s4
--check all u1<=s4 if i1=1
select @ErrAcc = ''
select top 100 @ErrAcc = @ErrAcc + username +', '
from 
	custinfo as c with (NOLOCK) 
	inner join CustSetting3rd as cs with (NOLOCK) on c.custid = cs.custid
	inner join (
				      select 	201 as sporttype, 2 as bettype, @v201spositiontaking_2 as maxpositiontaking
			union all select 	201 as sporttype, 3 as bettype, @v201spositiontaking_3 as maxpositiontaking
		) as b on cs.sporttype=b.sporttype and cs.bettype = b.bettype
where c.srecommend = @custid and c.roleid = 1 and (
			(cs.spositiontaking+cs.mpositiontaking+cs.apositiontaking>b.maxpositiontaking) or 
			(cs.isautopositiontaking=1 and cs.autopositiontaking>b.maxpositiontaking)  
			)
group by username
if @ErrAcc<>''
BEGIN
	Select @ErrMsg = 	@UserName + ': '+
		case @Language 
						when 'E' then 'Existing members exceeded new super position taking ('+@ErrAcc+').'
						when 'CS' then N'现有会员超出新超级总代理占成数设定('+@ErrAcc+').'
						when 'CT' then N'現有會員超出新超級總代理佔成數設定('+@ErrAcc+').'
						when 'TH' then N'สมาชิกที่มีอยู่ในขณะนี้เกินกว่า จำนวนตัวแทนสูงสุดรายใหม่กำหนดไว้('+@ErrAcc+').'
						when 'J' then N'Existing members exceeded new super position taking ('+@ErrAcc+').'
						else N'Existing members exceeded new super position taking ('+@ErrAcc+').'
				end, @ErrCode = 104
	return
END
--Check all m1+a1<=m4
select @ErrAcc = ''
select top 100 @ErrAcc = @ErrAcc + username +', '
from 
	custinfo as c with (NOLOCK) 
	inner join CustSetting3rd as cs with (NOLOCK) on c.custid = cs.custid
	inner join (
				      select 	201 as sporttype, 2 as bettype, @v201mpositiontaking_2 as maxpositiontaking
			union all select 	201 as sporttype, 3 as bettype, @v201mpositiontaking_3 as maxpositiontaking
		) as b on cs.sporttype=b.sporttype and cs.bettype = b.bettype
where c.srecommend = @custid and c.roleid = 1 and (
			(cs.mpositiontaking+cs.apositiontaking>b.maxpositiontaking)   
			)
group by username
if @ErrAcc<>''
BEGIN
	Select @ErrMsg = 	@UserName + ': '+
		case @Language 
						when 'E' then 'Existing members exceeded new master position taking ('+@ErrAcc+').'
						when 'CS' then N'现有会员超过新总代理的占成数 ('+@ErrAcc+').'
						when 'CT' then N'現有會員超過新總代理的佔成數 ('+@ErrAcc+').'
						when 'TH' then N'Existing members exceeded new master position taking ('+@ErrAcc+').'
						when 'J' then N'Existing members exceeded new master position taking ('+@ErrAcc+').'
						else N'Existing members exceeded new master position taking ('+@ErrAcc+').'
				end, @ErrCode = 108
	return
END
--Check all a1<=a4
select @ErrAcc = ''
select top 100 @ErrAcc = @ErrAcc + username +', '
from 
	custinfo as c with (NOLOCK) 
	inner join CustSetting3rd as cs with (NOLOCK) on c.custid = cs.custid
	inner join (
				      select 	201 as sporttype, 2 as bettype, @v201apositiontaking_2 as maxpositiontaking
			union all select 	201 as sporttype, 3 as bettype, @v201apositiontaking_3 as maxpositiontaking
		) as b on cs.sporttype=b.sporttype and cs.bettype = b.bettype
where c.srecommend = @custid and c.roleid = 1 and (
			(cs.apositiontaking>b.maxpositiontaking)   
			)
group by username
if @ErrAcc<>''
BEGIN
	Select @ErrMsg = 	@UserName + ': '+
		case @Language 
						when 'E' then 'Existing members exceeded new agent position taking ('+@ErrAcc+').'
						when 'CS' then N'现有会员超过新代理的占成数 ('+@ErrAcc+').'
						when 'CT' then N'現有會員超過新代理的佔成數 ('+@ErrAcc+').'
						when 'TH' then N'Existing members exceeded new agent position taking ('+@ErrAcc+').'
						when 'J' then N'Existing members exceeded new agent position taking ('+@ErrAcc+').'
						else N'Existing members exceeded new agent position taking ('+@ErrAcc+').'
				end, @ErrCode = 109
	return
END





--------------------------------------------------------------------------------------------
update CustSetting3rd with (ROWLOCK, UPDLOCK)
set
	spositiontaking = case bettype when 3 then @v201spositiontaking_3 when 2 then @v201spositiontaking_2 else spositiontaking end,
	mpositiontaking = case bettype when 3 then @v201mpositiontaking_3 when 2 then @v201mpositiontaking_2 else mpositiontaking end,
	apositiontaking = case bettype when 3 then @v201apositiontaking_3 when 2 then @v201apositiontaking_2 else apositiontaking end
where custid=@custid and sporttype = 201
if (@@error <> 0)
begin
	Select @ErrMsg = @UserName + ': '+
					case @Language 
						when 'E' then 'Update process is unsuccessful !'
						when 'CS' then N'更新程序不成功 !'
						when 'CT' then N'更新程序不成功 !'
						when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น.'
						when 'J' then N'アップデート出来ません。'
						else N'Update process is unsuccessful !'
					end	, @ErrCode = 105					 
	
	return
end

--exec dbo.Acc_CustomerUpdSuper_AutoPositiontaking @srecommend = @custid
Update cs
	set spositiontaking = case when scs.spositiontaking-cs.mpositiontaking-cs.apositiontaking >
							(case when cs.isautopositiontaking=1 then cs.autopositiontaking else mcs.autopositiontaking end) then (case when cs.isautopositiontaking=1 then cs.autopositiontaking else mcs.autopositiontaking end) else scs.spositiontaking-cs.mpositiontaking-cs.apositiontaking end 
from
	CustSetting3rd as cs with (ROWLOCK, UPDLOCK)
	inner join custinfo as c with (NOLOCK) on cs.custid = c.custid
	inner join CustSetting3rd as mcs with (NOLOCK) on mcs.custid = c.mrecommend and mcs.sporttype=cs.sporttype and mcs.bettype=cs.bettype
	inner join CustSetting3rd as scs with (NOLOCK) on scs.custid = @custid and scs.sporttype=cs.sporttype and scs.bettype=cs.bettype
where
	c.srecommend = @custid
	and c.roleid = 1 and cs.sporttype = 201
	and (cs.isautopositiontaking=1 or mcs.isautopositiontaking=1)

if (@@error <> 0)
begin
	Select @ErrMsg = @UserName + ': '+
					case @Language 
						when 'E' then 'Update process is unsuccessful !'
						when 'CS' then N'更新程序不成功 !'
						when 'CT' then N'更新程序不成功 !'
						when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น.'
						when 'J' then N'アップデート出来ません。'
						else N'Update process is unsuccessful !'
					end, @ErrCode = 107	
	return
end

--Update l4=s4
update CustOverride3rd with (ROWLOCK, UPDLOCK)
	set maxpositiontaking = case bettype when 2 then @v201spositiontaking_2 when 3 then @v201spositiontaking_3 else maxpositiontaking end
where custid = @custid and sporttype = 201

if (@@error <> 0)
begin
	Select @ErrMsg = @UserName + ': '+
					case @Language 
						when 'E' then 'Update process is unsuccessful !'
						when 'CS' then N'更新程序不成功 !'
						when 'CT' then N'更新程序不成功 !'
						when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น.'
						when 'J' then N'アップデート出来ません。'
						else N'Update process is unsuccessful !'
					end, @ErrCode = 106			 
	
	return
end

Declare @LogSPData varchar(5000)

Select @LogSPData ='<Acc_CustomerUpdSuperFI_Positiontaking><info custid="'+ coalesce(cast(@custid as varchar(50)),space(1)) + '" ' +
'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" ' +
'Language="'+ coalesce(cast(@Language as varchar(2)),space(1)) + '" ' +
'IP="'+ coalesce(cast(@IP as varchar(15)),space(1)) + '" ' +
'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" ' +
'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(5000)),space(1)) + '" />' +

'<s v201spt_2="'+ coalesce(cast(@v201spositiontaking_2 as varchar(50)),space(1)) + '" ' +
'v201spt_3="'+ coalesce(cast(@v201spositiontaking_3 as varchar(50)),space(1)) + '" />' +

'<m v201mpt_2="'+ coalesce(cast(@v201mpositiontaking_2 as varchar(50)),space(1)) + '" ' +
'v201mpt_3="'+ coalesce(cast(@v201mpositiontaking_3 as varchar(50)),space(1)) + '" />' +

'<ag v201apt_2="'+ coalesce(cast(@v201apositiontaking_2 as varchar(50)),space(1)) + '" ' +
'v201apt_3="'+ coalesce(cast(@v201apositiontaking_3 as varchar(50)),space(1)) + '" /></Acc_CustomerUpdSuperFI_Positiontaking>'

--Log positiontaking
EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew 
	@UserID = @UserID,
	@CustID = @CustID,
	@ActionID = 414,
	@TrackingValue = @LogSPData

GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdSuperFI_Positiontaking] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdSuperFI_Positiontaking] TO vnteam
