ALTER PROCEDURE [dbo].[Acc_CustomerUpdMasterHR_Positiontaking]
	@custid int,-- masterid	
	@v151spositiontaking_31 smallmoney,
	@v151spositiontaking_32 smallmoney,
	@v151spositiontaking_41 smallmoney,
	@v151spositiontaking_42 smallmoney,

	@auto_v151spositiontaking_31 smallmoney = 0,
	@auto_v151spositiontaking_32 smallmoney = 0,
	@auto_v151spositiontaking_41 smallmoney = 0,
	@auto_v151spositiontaking_42 smallmoney = 0,
	
	@isauto_v151spositiontaking_31 bit = 0,
	@isauto_v151spositiontaking_32 bit = 0,
	@isauto_v151spositiontaking_41 bit = 0,
	@isauto_v151spositiontaking_42 bit = 0,
	
	@v151mpositiontaking_31 smallmoney = 0.5,
	@v151mpositiontaking_32 smallmoney = 0.5,
	@v151mpositiontaking_41 smallmoney = 0.5,
	@v151mpositiontaking_42 smallmoney = 0.5,
	
	@IsCopyPreset_31 bit = 0,--Use for copy preset to member
	@IsCopyPreset_41 bit = 0,--Use for copy preset to member
	@updateallmembers bit = 0,--Use for auto PT
	@newspositiontaking smallmoney = 0,--equals max(s+m) - chosen(m)
	@SubAccID int = 0, --Sub-AccountID	
	@UserID int = 0,	
	@Language varchar(2) = 'E',
	@IP varchar(15)='',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
as

--@Source Control
/*
Created: 20090514@Phuc
Task : Update HR's Master Position Taking
DB: DB02.bodb02
Original: Acc_CustomerUpdEditCustomer_SAg

Revisions:
	- 20090610@Phuc: copy super preset to member(s3->s1).
	- 20090628@Phuc: auto master PT on member level.
					Write log subaccname instead of subaccid.
	- 20090917@Phuc: write log into DBLOG.
	- 20091201@Kiwi: Move custsetting & custoverride to the separated tables (CustSetting3rd & CustOverride3rd).
	- 20100112@Kiwi: Amend to write log in xml format.
Param's Explanation:
• @ErrCode:
    = 0: Update successfully.
    > 0: Specific Error.
  
• @ErrMsg: Error description.
*/


SET NOCOUNT ON

declare @ErrAcc varchar(4000), @ErrType varchar(4000)
declare @UserName nvarchar(20), @srecommend int,
		@maxpos smallmoney,	@maxdownlinepos smallmoney
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Select @UserName  = username, @srecommend = srecommend 
from custinfo with (NOLOCK) 
where CustID = @CustID

Select @maxpos = 0.5, @maxdownlinepos = 0 --Max pos for HR = 0.5
-- th: @maxpos and @maxdownlinepos are no longer used
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--v201
if 
	@v151spositiontaking_31 <0
	or @v151spositiontaking_32 <0
	or @v151spositiontaking_41 <0
	or @v151spositiontaking_42 <0
	
	or @v151mpositiontaking_31 <0
	or @v151mpositiontaking_32 <0
	or @v151mpositiontaking_41 <0
	or @v151mpositiontaking_42 <0
	
	or @auto_v151spositiontaking_31  >@maxpos
	or @auto_v151spositiontaking_32  >@maxpos
	or @auto_v151spositiontaking_41  >@maxpos
	or @auto_v151spositiontaking_42  >@maxpos

	or @v151spositiontaking_31+@v151mpositiontaking_31 >@maxpos
	or @v151spositiontaking_32+@v151mpositiontaking_32 >@maxpos
	or @v151spositiontaking_41+@v151mpositiontaking_41 >@maxpos
	or @v151spositiontaking_42+@v151mpositiontaking_42 >@maxpos
BEGIN
	select @ErrCode = 11
	Select @ErrMsg = @UserName + ': ' + 
				case @Language 
						when 'E' then 'Wrong position taking.'
						when 'CS' then N'占成数不正确.'
						when 'CT' then N'佔成數不正確.'
						when 'TH' then N'การกำหนดไม่ถูกต้อง.'
						when 'J' then N'Wrong position taking.'
						when 'KO' then N'거래 조건이 잘못 되었습니다.'
						else N'Wrong position taking.'
				end
	return
END

--check n4<=s3+m3<=l4 if i3 = 0, 
--m3<=l4 and u3+m3>=n4 if i3 = 1
select @ErrType = ''
select @ErrType = @ErrType + '-'+ typenamee + '-Min: '+ cast((co.minpositiontaking) as varchar(10))+ '-Max: '+ cast((co.maxpositiontaking) as varchar(10))+ '<br>'
from custoverride as co with (NOLOCK) inner join
	(
			 		select 31 as bettype, 151 as sporttype, @v151spositiontaking_31 as spositiontaking, @v151mpositiontaking_31 as mpositiontaking, @isauto_v151spositiontaking_31 as isauto_spositiontaking, @auto_v151spositiontaking_31 as auto_spositiontaking
		union all	select 32 as bettype, 151 as sporttype, @v151spositiontaking_32 as spositiontaking, @v151mpositiontaking_32 as mpositiontaking, @isauto_v151spositiontaking_32 as isauto_spositiontaking, @auto_v151spositiontaking_32 as auto_spositiontaking
		union all	select 41 as bettype, 151 as sporttype, @v151spositiontaking_41 as spositiontaking, @v151mpositiontaking_41 as mpositiontaking, @isauto_v151spositiontaking_41 as isauto_spositiontaking, @auto_v151spositiontaking_41 as auto_spositiontaking
		union all	select 42 as bettype, 151 as sporttype, @v151spositiontaking_42 as spositiontaking, @v151mpositiontaking_42 as mpositiontaking, @isauto_v151spositiontaking_42 as isauto_spositiontaking, @auto_v151spositiontaking_42 as auto_spositiontaking

	) as b on co.sporttype=b.sporttype and co.bettype = b.bettype
	inner join bettype with (nolock) on b.bettype = bettype.typeid
where co.custid = @srecommend and (	
					((b.isauto_spositiontaking=0) and (b.spositiontaking+b.mpositiontaking>co.maxpositiontaking or b.spositiontaking+b.mpositiontaking<co.minpositiontaking)) or 
					(b.isauto_spositiontaking>0 and (b.mpositiontaking>co.maxpositiontaking or b.mpositiontaking + b.auto_spositiontaking<co.minpositiontaking))
				)
if @ErrType <>''
BEGIN
	select @ErrCode = 12
	Select @ErrMsg = @UserName + ': ' +
				case @Language 
						when 'E' then 'Wrong position taking (min/max set by company).<br>'+@ErrType
						when 'CS' then N'占成数不正确(公司设给最低/高占成).<br>'+@ErrType
						when 'CT' then N'佔成數不正確(公司設給最低/高佔成).<br>'+@ErrType
						when 'TH' then N'การกำหนดจำนวนเงินไม่ถูกต้อง (สูงสุด หรือ ต่ำสุด อ้างอิงจากข้อมูลบริษัท).<br>'+@ErrType
						when 'J' then N'Wrong position taking (min/max set by company).<br>'+@ErrType
						when 'KO' then N'거래 조건이 잘못 되었습니다 (ibc가 설정한 최소값/최대값).<br>'+@ErrType
						else N'Wrong position taking (min/max set by company).<br>'+@ErrType
				end
	return
END
--n3<=m3<=l3
select @ErrType = ''
select @ErrType = @ErrType + '-'+ typenamee + '-Min: '+ cast((co.minpositiontaking) as varchar(10))+ '-Max: '+ cast((co.maxpositiontaking) as varchar(10)) + '<br>'
from custoverride as co with (NOLOCK) inner join
	(
			 		select 31 as bettype, 151 as sporttype, @v151spositiontaking_31 as spositiontaking, @v151mpositiontaking_31 as mpositiontaking, @isauto_v151spositiontaking_31 as isauto_spositiontaking
		union all	select 32 as bettype, 151 as sporttype, @v151spositiontaking_32 as spositiontaking, @v151mpositiontaking_32 as mpositiontaking, @isauto_v151spositiontaking_32 as isauto_spositiontaking
		union all	select 41 as bettype, 151 as sporttype, @v151spositiontaking_41 as spositiontaking, @v151mpositiontaking_41 as mpositiontaking, @isauto_v151spositiontaking_41 as isauto_spositiontaking
		union all	select 42 as bettype, 151 as sporttype, @v151spositiontaking_42 as spositiontaking, @v151mpositiontaking_42 as mpositiontaking, @isauto_v151spositiontaking_42 as isauto_spositiontaking
	) as b on co.sporttype=b.sporttype and co.bettype = b.bettype
	inner join bettype with (nolock) on b.bettype = bettype.typeid
where co.custid = @custid and (	
					(b.mpositiontaking>co.maxpositiontaking or b.mpositiontaking<co.minpositiontaking) 
--						or (b.sporttype = 2 and b.bettype in (1,3,7,8) and (b.mlivepositiontaking>co.maxlivepositiontaking or b.mlivepositiontaking<co.minlivepositiontaking))
				)
if @ErrType <>''
BEGIN
	select @ErrCode = 13
	Select @ErrMsg = @UserName + ': '+
				case @Language 
						when 'E' then 'Wrong position taking (min/max set by company).<br>'+@ErrType
						when 'CS' then N'占成数不正确(公司设给最低/高占成).<br>'+@ErrType
						when 'CT' then N'佔成數不正確(公司設給最低/高佔成).<br>'+@ErrType
						when 'TH' then N'การกำหนดจำนวนเงินไม่ถูกต้อง (สูงสุด หรือ ต่ำสุด อ้างอิงจากข้อมูลบริษัท).<br>'+@ErrType
						when 'J' then N'Wrong position taking (min/max set by company).<br>'+@ErrType
						when 'KO' then N'거래 조건이 잘못 되었습니다 (ibc가 설정한 최소값/최대값).<br>'+@ErrType
						else N'Wrong position taking (min/max set by company).<br>'+@ErrType
				end
	return
END

--m2+a2<=m3
select @ErrAcc = ''
select top 100 @ErrAcc = @ErrAcc + username +', '
from 
	custinfo as c with (NOLOCK) 
	inner join CustSetting3rd as cs with (NOLOCK) on c.custid = cs.custid
	inner join (
						select 	151 as sporttype, 31 as bettype, @v151mpositiontaking_31 as maxpositiontaking	
			union all	select 	151 as sporttype, 32 as bettype, @v151mpositiontaking_32 as maxpositiontaking
			union all	select 	151 as sporttype, 41 as bettype, @v151mpositiontaking_41 as maxpositiontaking
			union all	select 	151 as sporttype, 42 as bettype, @v151mpositiontaking_42 as maxpositiontaking
		) as b on cs.sporttype=b.sporttype and cs.bettype = b.bettype
where c.mrecommend = @custid and c.roleid = 2 and (cs.apositiontaking+cs.mpositiontaking>b.maxpositiontaking)
group by username
if @ErrAcc<>''
BEGIN
	select @ErrCode = 14
	Select @ErrMsg = @UserName + ': ' + 
				case @Language 
						when 'E' then 'Existing agents exceeded new master positiontaking ('+@ErrAcc+').'
						when 'CS' then N'现有代理超出新总代理占成数设定 ('+@ErrAcc+ N') .'
						when 'CT' then N'現有代理超出新總代理佔成數設定 ('+@ErrAcc+ N') .'
						when 'TH' then N' ตัวแทนที่มีอยู่ขณะนี้เกินกว่าจำนวนตัวแทนหลักรายใหม่ ('+@ErrAcc+ N').'
						when 'J' then N'Existing agents exceeded new master positiontaking ('+@ErrAcc+ N') .'
						when 'KO' then N'에이전트의 거래조건 설정 법위를 넘어섰습니다 ('+@ErrAcc+ N') .'
						else N'Existing agents exceeded new master positiontaking ('+@ErrAcc+ N') .'
				end
	return
END

--m1+a1<=m3
select @ErrAcc = ''
select top 100 @ErrAcc = @ErrAcc + username +', '
from 
	custinfo as c with (NOLOCK) 
	inner join CustSetting3rd as cs with (NOLOCK) on c.custid = cs.custid
	inner join (
						select 	151 as sporttype, 31 as bettype, @v151mpositiontaking_31 as maxpositiontaking
			union all	select 	151 as sporttype, 32 as bettype, @v151mpositiontaking_32 as maxpositiontaking
			union all	select 	151 as sporttype, 41 as bettype, @v151mpositiontaking_41 as maxpositiontaking
			union all	select 	151 as sporttype, 42 as bettype, @v151mpositiontaking_42 as maxpositiontaking
		) as b on cs.sporttype=b.sporttype and cs.bettype = b.bettype
where c.mrecommend = @custid and c.roleid = 1 and (cs.apositiontaking+cs.mpositiontaking>b.maxpositiontaking )
group by username
if @ErrAcc<>''
BEGIN
	select @ErrCode = 15
	Select @ErrMsg = @UserName + ': ' + 
				case @Language 
						when 'E' then 'Existing members exceeded new master positiontaking ('+@ErrAcc+') .'
						when 'CS' then N'现有会员超出新总代理占成数设定 ('+@ErrAcc+ N') .'
						when 'CT' then N'現有會員超出新總代理佔成數設定 ('+@ErrAcc+ N') .'
						when 'TH' then N'สมาชิกที่มีอยู่ในขณะนี้เกินกว่า จำนวนตัวแทนหลักรายใหม่ กำหนดไว้ ('+@ErrAcc+ N').'
						when 'J' then N'Existing members exceeded new master positiontaking ('+@ErrAcc+ N') .'
						when 'KO' then N'회원의 거래조건 설정 범위를 넘어섰습니다 ('+@ErrAcc+ N') .'
						else N'Existing members exceeded new master positiontaking ('+@ErrAcc+ N') .'
				end
	return
END

--check m3<=m4
select @ErrType = ''
select @ErrType = @ErrType + '-'+ typenamee + '-Max: '+ cast((scs.mpositiontaking) as varchar(10)) + '<br>'
from CustSetting3rd as scs with (NOLOCK) inner join
	(
			 			select 31 as bettype, 151 as sporttype, @v151spositiontaking_31 as spositiontaking, @v151mpositiontaking_31 as mpositiontaking, @auto_v151spositiontaking_31 as auto_spositiontaking  
		union all	 	select 32 as bettype, 151 as sporttype, @v151spositiontaking_32 as spositiontaking, @v151mpositiontaking_32 as mpositiontaking, @auto_v151spositiontaking_32 as auto_spositiontaking
		union all	 	select 41 as bettype, 151 as sporttype, @v151spositiontaking_41 as spositiontaking, @v151mpositiontaking_41 as mpositiontaking, @auto_v151spositiontaking_41 as auto_spositiontaking
		union all	 	select 42 as bettype, 151 as sporttype, @v151spositiontaking_42 as spositiontaking, @v151mpositiontaking_42 as mpositiontaking, @auto_v151spositiontaking_42 as auto_spositiontaking
	) as b on scs.sporttype=b.sporttype and scs.bettype = b.bettype
	inner join bettype with (nolock) on b.bettype = bettype.typeid
where scs.custid = @srecommend and (
					scs.mpositiontaking<b.mpositiontaking 
					)
if @ErrType <>''
BEGIN
	select @ErrCode = 16
	Select @ErrMsg = @UserName + ': '+
				case @Language 
						when 'E' then 'Wrong position taking (max for master set by company).<br>'+@ErrType
						when 'CS' then N'占成数不正确(公司设给总代理最高占成).<br>'+@ErrType
						when 'CT' then N'佔成數不正確(公司設給總代理最高佔成).<br>'+@ErrType
						when 'TH' then N'การกำหนดไม่ถูกต้อง (สูงสุดไม่เกิน สำหรับรายการหลัก อ้างอิงจากข้อมูลบริษัท).<br>'+@ErrType
						when 'J' then N'Wrong position taking (max for master set by company).<br>'+@ErrType
						when 'KO' then N'거래 조건이 잘못 되었습니다 (ibc가 설정한 마스터의 최대값).<br>'+@ErrType
						else N'Wrong position taking (max for master set by company).<br>'+@ErrType
				end
	return
END

--m3>=u2
select @ErrAcc = ''
select top 100 @ErrAcc = @ErrAcc + username +', '
from 
	custinfo as c with (NOLOCK) 
	inner join CustSetting3rd as cs with (NOLOCK) on c.custid = cs.custid
	inner join (
						select 	151 as sporttype, 31 as bettype, @v151mpositiontaking_31 as maxpositiontaking
			union all	select 	151 as sporttype, 32 as bettype, @v151mpositiontaking_32 as maxpositiontaking
			union all	select 	151 as sporttype, 41 as bettype, @v151mpositiontaking_41 as maxpositiontaking
			union all	select 	151 as sporttype, 42 as bettype, @v151mpositiontaking_42 as maxpositiontaking
		) as b on cs.sporttype=b.sporttype and cs.bettype = b.bettype
where c.mrecommend = @custid and c.roleid = 2 
	and (	cs.autompositiontaking > b.maxpositiontaking and cs.isautompositiontaking = 1
		)
group by username
if @ErrAcc<>''
BEGIN
	select @ErrCode = 17
	Select @ErrMsg = @UserName + ': ' +
				case @Language 
						when 'E' then 'Existing agents exceeded new master positiontaking ('+@ErrAcc+').'
						when 'CS' then N'现有代理超出新总代理占成数设定 ('+@ErrAcc+ N') .'
						when 'CT' then N'現有代理超出新總代理佔成數設定 ('+@ErrAcc+ N') .'
						when 'TH' then N' ตัวแทนที่มีอยู่ขณะนี้เกินกว่าจำนวนตัวแทนหลักรายใหม่ ('+@ErrAcc+ N').'
						when 'J' then N'Existing agents exceeded new master positiontaking ('+@ErrAcc+ N') .'
						when 'KO' then N'에이전트의 거래조건 설정 법위를 넘어섰습니다 ('+@ErrAcc+ N') .'
						else N'Existing agents exceeded new master positiontaking ('+@ErrAcc+ N') .'
				end
	return
END

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--v201
--u3<=s4
select @ErrType = ''
select @ErrType = @ErrType + '-'+ typenamee + '-Max: '+ cast((cs.spositiontaking) as varchar(10)) + '<br>'
from CustSetting3rd as cs with (NOLOCK) inner join
	(
						select 31 as bettype, 151 as sporttype, @auto_v151spositiontaking_31 as autopositiontaking
		union all		select 32 as bettype, 151 as sporttype, @auto_v151spositiontaking_32 as autopositiontaking
		union all		select 41 as bettype, 151 as sporttype, @auto_v151spositiontaking_41 as autopositiontaking
		union all		select 42 as bettype, 151 as sporttype, @auto_v151spositiontaking_42 as autopositiontaking
	) as b on cs.sporttype=b.sporttype and cs.bettype=b.bettype
	inner join bettype with (nolock) on b.bettype = bettype.typeid
where cs.custid = @srecommend
	and 
	((cs.spositiontaking+@maxdownlinepos<b.autopositiontaking))
if @ErrType <>''
BEGIN
	Select @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'Wrong auto position taking.<br>'+@ErrType
							when 'CS' then N'自动占成数不正确.<br>'+@ErrType
							when 'CT' then N'自動佔成數不正確.<br>'+@ErrType
							when 'TH' then N'การปรับยอดเงินที่ผิดพลาดอันเนื่องมาจากระบบ.<br>'+@ErrType
							when 'J' then N'Wrong auto position taking.<br>'+@ErrType
							when 'KO' then N'자동 거래조건이 잘못 되었습니다.<br>'+@ErrType
							else N'Wrong auto position taking.<br>'+@ErrType
						end, @ErrCode = 223
	return
END
--s3<=s4,s3+m3<=s4
select @ErrType = ''
select @ErrType = @ErrType + '-'+ typenamee + '-Max: '+ cast((cs.spositiontaking) as varchar(10))+ '<br>'
from CustSetting3rd as cs with (NOLOCK) inner join
	(
						select 31 as bettype, 151 as sporttype, @v151spositiontaking_31 as spositiontaking, @v151mpositiontaking_31 as mpositiontaking
		union all		select 32 as bettype, 151 as sporttype, @v151spositiontaking_32 as spositiontaking, @v151mpositiontaking_32 as mpositiontaking
		union all		select 41 as bettype, 151 as sporttype, @v151spositiontaking_41 as spositiontaking, @v151mpositiontaking_41 as mpositiontaking
		union all		select 42 as bettype, 151 as sporttype, @v151spositiontaking_42 as spositiontaking, @v151mpositiontaking_42 as mpositiontaking
	) as b on cs.sporttype=b.sporttype and cs.bettype=b.bettype
	inner join bettype with (nolock) on b.bettype = bettype.typeid
where cs.custid = @srecommend
	and 
	((cs.spositiontaking<b.spositiontaking) or (cs.spositiontaking+@maxdownlinepos<b.spositiontaking+b.mpositiontaking)
--		or (b.bettype in (1,3,7,8) and b.sporttype=1 and cs.slivepositiontaking<b.slivepositiontaking)
	)
if @ErrType <>''
BEGIN
	Select @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'Wrong  position taking.<br>'+@ErrType
							when 'CS' then N'占成数不正确.<br>'+@ErrType
							when 'CT' then N'佔成數不正確.<br>'+@ErrType
							when 'TH' then N'การกำหนดไม่ถูกต้อง.<br>'+@ErrType
							when 'J' then N'Wrong  position taking.<br>'+@ErrType
							when 'KO' then N'거래 조건이 잘못 되었습니다.<br>'+@ErrType
							else N'Wrong  position taking.<br>'+@ErrType
						end, @ErrCode = 224
	return
END

------------

------------

update CustSetting3rd with (ROWLOCK, UPDLOCK)
set
	spositiontaking = case bettype when 31 then @v151spositiontaking_31 when 32 then @v151spositiontaking_32 when 41 then @v151spositiontaking_41 when 42 then @v151spositiontaking_42 else spositiontaking end,	
	mpositiontaking = case bettype when 31 then @v151mpositiontaking_31 when 32 then @v151mpositiontaking_32 when 41 then @v151mpositiontaking_41 when 42 then @v151mpositiontaking_42 else mpositiontaking end	
where custid=@custid and sporttype = 151
if (@@error <> 0)
begin
	
	Select @ErrMsg = @UserName + ': '+
					case @Language 
						when 'E' then 'Update process is unsuccessful !'
						when 'CS' then N'更新程序不成功 !'
						when 'CT' then N'更新程序不成功 !'
						when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น.'
						when 'J' then N'アップデート出来ません。'
						when 'KO' then N'업데이트에 실패했습니다.'
						else N'Update process is unsuccessful !'
					end	, @ErrCode = 122					 
	
	return
end

--Auto PT Acc_CustomerUpdMaster_AutoPositiontaking
Declare 
	@old_auto_v151spositiontaking_31 smallmoney,
	@old_auto_v151spositiontaking_32 smallmoney,
	@old_auto_v151spositiontaking_41 smallmoney,
	@old_auto_v151spositiontaking_42 smallmoney,
	
	@old_isauto_v151spositiontaking_31 bit,
	@old_isauto_v151spositiontaking_32 bit,
	@old_isauto_v151spositiontaking_41 bit,
	@old_isauto_v151spositiontaking_42 bit
	
select 	@old_auto_v151spositiontaking_31	=	autopositiontaking		,	@old_isauto_v151spositiontaking_31	=	isautopositiontaking		from CustSetting3rd with (nolock) where custid = @custid and sporttype=151	and bettype=31
select 	@old_auto_v151spositiontaking_32	=	autopositiontaking		,	@old_isauto_v151spositiontaking_32	=	isautopositiontaking		from CustSetting3rd with (nolock) where custid = @custid and sporttype=151	and bettype=32
select 	@old_auto_v151spositiontaking_41	=	autopositiontaking		,	@old_isauto_v151spositiontaking_41	=	isautopositiontaking		from CustSetting3rd with (nolock) where custid = @custid and sporttype=151	and bettype=41
select 	@old_auto_v151spositiontaking_42	=	autopositiontaking		,	@old_isauto_v151spositiontaking_42	=	isautopositiontaking		from CustSetting3rd with (nolock) where custid = @custid and sporttype=151	and bettype=42

--Update Master Agent account
--For HR
update CustSetting3rd with (ROWLOCK, UPDLOCK) set autopositiontaking = b.autopositiontaking, isautopositiontaking = b.isautopositiontaking
from CustSetting3rd as cs inner join 
		(
						select 31 as bettype, @auto_v151spositiontaking_31 as autopositiontaking, @isauto_v151spositiontaking_31 as isautopositiontaking
			union all	select 32 as bettype, @auto_v151spositiontaking_32 as autopositiontaking, @isauto_v151spositiontaking_32 as isautopositiontaking
			union all	select 41 as bettype, @auto_v151spositiontaking_41 as autopositiontaking, @isauto_v151spositiontaking_41 as isautopositiontaking
			union all	select 42 as bettype, @auto_v151spositiontaking_42 as autopositiontaking, @isauto_v151spositiontaking_42 as isautopositiontaking
		) as b on b.bettype = cs.bettype
where cs.custid = @custid and cs.sporttype=151
if @@Error <> 0
BEGIN
	
	SELECT @ErrMsg = @UserName + ': ' + 
		case @Language 
			when 'E' then 'Error updating auto positiontaking '
			when 'CS' then N'更新占成数不成功'
			when 'CT' then N'更新佔成數不成功'
			when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ '
			when 'J' then N'Error updating auto positiontaking '
			when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 '
			else N'Error updating auto positiontaking '
		end	
		,  @ErrCode=205
	return
END

if (@auto_v151spositiontaking_31 <> @old_auto_v151spositiontaking_31 or @isauto_v151spositiontaking_31 <> @old_isauto_v151spositiontaking_31 ) 
BEGIN
	if @isauto_v151spositiontaking_31 >0
	BEGIN
		select @maxpos = spositiontaking from CustSetting3rd with (NOLOCK) where custid = @srecommend and sporttype=151 and bettype = 31
		update cs
			set spositiontaking = case when @maxpos - mpositiontaking-apositiontaking>@auto_v151spositiontaking_31 then @auto_v151spositiontaking_31 else @maxpos - mpositiontaking-apositiontaking end
		from CustSetting3rd as cs with (ROWLOCK, UPDLOCK)
		inner join custinfo as c with (NOLOCK) on cs.custid = c.custid
		where c.mrecommend = @custid and c.roleid = 1 and cs.bettype = 31 and cs.sporttype=151 and cs.isautopositiontaking=0
		if @@Error <> 0
		BEGIN
			
			SELECT @ErrMsg = @UserName + ': ' +  
					case @Language 
						when 'E' then 'Error updating auto positiontaking '
						when 'CS' then N'更新占成数不成功'
						when 'CT' then N'更新佔成數不成功'
						when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ '
						when 'J' then N'Error updating auto positiontaking '
						when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다'
						else N'Error updating auto positiontaking '
					end	
					,  @ErrCode=219
			return
		END
	END
	else if @isauto_v151spositiontaking_31 <> @old_isauto_v151spositiontaking_31
	BEGIN
		if @updateallmembers = 1
		BEGIN
			update cs
				set spositiontaking = case when mcs.spositiontaking<@newspositiontaking then mcs.spositiontaking else @newspositiontaking end
			from CustSetting3rd as cs with (ROWLOCK, UPDLOCK)
			inner join custinfo as c with (NOLOCK) on cs.custid = c.custid
			inner join CustSetting3rd as mcs with (NOLOCK) on mcs.custid = @custid and cs.sporttype=mcs.sporttype and cs.bettype=mcs.bettype
			where c.mrecommend = @custid and c.roleid = 1 and cs.bettype = 31 and cs.sporttype=151 and cs.isautopositiontaking=0
			if @@Error <> 0
			BEGIN
				
				SELECT @ErrMsg = @UserName + ': ' +  
					case @Language 
						when 'E' then 'Error updating auto positiontaking '
						when 'CS' then N'更新占成数不成功'
						when 'CT' then N'更新佔成數不成功'
						when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ '
						when 'J' then N'Error updating auto positiontaking '
						when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다'
						else N'Error updating auto positiontaking '
					end	
					,  @ErrCode=220
				return
			END
		END
	END
END	

if (@auto_v151spositiontaking_32 <> @old_auto_v151spositiontaking_32 or @isauto_v151spositiontaking_32 <> @old_isauto_v151spositiontaking_32) 
BEGIN
	if @isauto_v151spositiontaking_32 >0
	BEGIN
		select @maxpos = spositiontaking from CustSetting3rd with (NOLOCK) where custid = @srecommend and sporttype=151 and bettype = 32
		update cs
			set spositiontaking = case when @maxpos - mpositiontaking-apositiontaking>@auto_v151spositiontaking_32 then @auto_v151spositiontaking_32 else @maxpos - mpositiontaking-apositiontaking end
		from CustSetting3rd as cs with (ROWLOCK, UPDLOCK)
		inner join custinfo as c with (NOLOCK) on cs.custid = c.custid
		where c.mrecommend = @custid and c.roleid = 1 and cs.bettype = 32 and cs.sporttype=151 and cs.isautopositiontaking=0
		if @@Error <> 0
		BEGIN
			
			SELECT @ErrMsg = @UserName + ': ' + 
					case @Language 
						when 'E' then 'Error updating auto positiontaking'
						when 'CS' then N'更新占成数不成功'
						when 'CT' then N'更新佔成數不成功'
						when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ '
						when 'J' then N'Error updating auto positiontaking '
						when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 '
						else N'Error updating auto positiontaking '
					end	
					,  @ErrCode=219
			return
		END
	END
	else if @isauto_v151spositiontaking_32 <> @old_isauto_v151spositiontaking_32
	BEGIN
		if @updateallmembers = 1
		BEGIN
			update cs
				set spositiontaking = case when mcs.spositiontaking<@newspositiontaking then mcs.spositiontaking else @newspositiontaking end
			from CustSetting3rd as cs with (ROWLOCK, UPDLOCK)
			inner join custinfo as c with (NOLOCK) on cs.custid = c.custid
			inner join CustSetting3rd as mcs with (NOLOCK) on mcs.custid = @custid and cs.sporttype=mcs.sporttype and cs.bettype=mcs.bettype
			where c.mrecommend = @custid and c.roleid = 1 and cs.bettype = 32 and cs.sporttype=151 and cs.isautopositiontaking=0
			if @@Error <> 0
			BEGIN
				
				SELECT @ErrMsg = @UserName + ': ' + 
					case @Language 
						when 'E' then 'Error updating auto positiontaking'
						when 'CS' then N'更新占成数不成功'
						when 'CT' then N'更新佔成數不成功'
						when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ '
						when 'J' then N'Error updating auto positiontaking'
						when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 '
						else N'Error updating auto positiontaking'
					end	
					,  @ErrCode=220
				return
			END
		END
	END
END	

if (@auto_v151spositiontaking_41 <> @old_auto_v151spositiontaking_41 or @isauto_v151spositiontaking_41 <> @old_isauto_v151spositiontaking_41) 
BEGIN
	if @isauto_v151spositiontaking_41 >0
	BEGIN
		select @maxpos = spositiontaking from CustSetting3rd with (NOLOCK) where custid = @srecommend and sporttype=151 and bettype = 41
		update cs
			set spositiontaking = case when @maxpos - mpositiontaking-apositiontaking>@auto_v151spositiontaking_41 then @auto_v151spositiontaking_41 else @maxpos - mpositiontaking-apositiontaking end
		from CustSetting3rd as cs with (ROWLOCK, UPDLOCK)
		inner join custinfo as c with (NOLOCK) on cs.custid = c.custid
		where c.mrecommend = @custid and c.roleid = 1 and cs.bettype = 41 and cs.sporttype=151 and cs.isautopositiontaking=0
		if @@Error <> 0
		BEGIN
			
			SELECT @ErrMsg = @UserName + ': ' +  
					case @Language 
						when 'E' then 'Error updating auto positiontaking '
						when 'CS' then N'更新占成数不成功'
						when 'CT' then N'更新佔成數不成功'
						when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ '
						when 'J' then N'Error updating auto positiontaking '
						when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다'
						else N'Error updating auto positiontaking '
					end	
					,  @ErrCode=219
			return
		END
	END
	else if @isauto_v151spositiontaking_41 <> @old_isauto_v151spositiontaking_41
	BEGIN
		if @updateallmembers = 1
		BEGIN
			update cs
				set spositiontaking = case when mcs.spositiontaking<@newspositiontaking then mcs.spositiontaking else @newspositiontaking end
			from CustSetting3rd as cs with (ROWLOCK, UPDLOCK)
			inner join custinfo as c with (NOLOCK) on cs.custid = c.custid
			inner join CustSetting3rd as mcs with (NOLOCK) on mcs.custid = @custid and cs.sporttype=mcs.sporttype and cs.bettype=mcs.bettype
			where c.mrecommend = @custid and c.roleid = 1 and cs.bettype = 41 and cs.sporttype=151 and cs.isautopositiontaking=0
			if @@Error <> 0
			BEGIN
				
				SELECT @ErrMsg = @UserName + ': ' +  
					case @Language 
						when 'E' then 'Error updating auto positiontaking '
						when 'CS' then N'更新占成数不成功'
						when 'CT' then N'更新佔成數不成功'
						when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ '
						when 'J' then N'Error updating auto positiontaking '
						when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 '
						else N'Error updating auto positiontaking '
					end	
					,  @ErrCode=220
				return
			END
		END
	END
END	

if (@auto_v151spositiontaking_42 <> @old_auto_v151spositiontaking_42 or @isauto_v151spositiontaking_42 <> @old_isauto_v151spositiontaking_42) 
BEGIN
	if @isauto_v151spositiontaking_42 >0
	BEGIN
		select @maxpos = spositiontaking from CustSetting3rd with (NOLOCK) where custid = @srecommend and sporttype=151 and bettype = 42
		update cs 
			set spositiontaking = case when @maxpos - mpositiontaking-apositiontaking>@auto_v151spositiontaking_42 then @auto_v151spositiontaking_42 else @maxpos - mpositiontaking-apositiontaking end
		from CustSetting3rd as cs with (ROWLOCK, UPDLOCK)
		inner join custinfo as c with (NOLOCK) on cs.custid = c.custid
		where c.mrecommend = @custid and c.roleid = 1 and cs.bettype = 42 and cs.sporttype=151 and cs.isautopositiontaking=0
		if @@Error <> 0
		BEGIN
			
			SELECT @ErrMsg = @UserName + ': ' + 
					case @Language 
						when 'E' then 'Error updating auto positiontaking '
						when 'CS' then N'更新占成数不成功'
						when 'CT' then N'更新佔成數不成功'
						when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ '
						when 'J' then N'Error updating auto positiontaking '
						when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 '
						else N'Error updating auto positiontaking '
					end	
					,  @ErrCode=219
			return
		END
	END
	else if @isauto_v151spositiontaking_42 <> @old_isauto_v151spositiontaking_42
	BEGIN
		if @updateallmembers = 1
		BEGIN
			update cs
				set spositiontaking = case when mcs.spositiontaking<@newspositiontaking then mcs.spositiontaking else @newspositiontaking end
			from CustSetting3rd as cs with (ROWLOCK, UPDLOCK)
			inner join custinfo as c with (NOLOCK) on cs.custid = c.custid
			inner join CustSetting3rd as mcs with (NOLOCK) on mcs.custid = @custid and cs.sporttype=mcs.sporttype and cs.bettype=mcs.bettype
			where c.mrecommend = @custid and c.roleid = 1 and cs.bettype = 42 and cs.sporttype=151 and cs.isautopositiontaking=0
			if @@Error <> 0
			BEGIN
				
				SELECT @ErrMsg = @UserName + ': ' +
					case @Language 
						when 'E' then 'Error updating auto positiontaking '
						when 'CS' then N'更新占成数不成功'
						when 'CT' then N'更新佔成數不成功'
						when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์'
						when 'J' then N'Error updating auto positiontaking '
						when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 '
						else N'Error updating auto positiontaking '
					end	
					,  @ErrCode=220
				return
			END
		END
	END
END	

--Copy preset to member
IF @IsCopyPreset_31 = 1 
BEGIN
	update cs 
		set spositiontaking = b.spositiontaking
	from CustSetting3rd as cs with (ROWLOCK, UPDLOCK)
		inner join custinfo ci (nolock) on ci.custid = cs.custid and ci.mrecommend = @custid and ci.roleid = 1
		inner join 
			(
							select 151 as sporttype, 31 as bettype, @isauto_v151spositiontaking_31 as isautopositiontaking, @old_isauto_v151spositiontaking_31 as oldisautopositiontaking, @v151spositiontaking_31 as spositiontaking
				union all	select 151 as sporttype, 32 as bettype, @isauto_v151spositiontaking_32 as isautopositiontaking, @old_isauto_v151spositiontaking_32 as oldisautopositiontaking, @v151spositiontaking_32 as spositiontaking
			) as b on b.bettype = cs.bettype and b.sporttype = cs.sporttype
	where b.isautopositiontaking = 0 and b.oldisautopositiontaking = 0  
END
IF @IsCopyPreset_41 = 1 
BEGIN
	update cs 
	set spositiontaking = b.spositiontaking
	from CustSetting3rd as cs with (ROWLOCK, UPDLOCK)
		inner join custinfo ci (nolock) on ci.custid = cs.custid and ci.mrecommend = @custid and ci.roleid = 1
		inner join 
			(
							select 151 as sporttype, 41 as bettype, @isauto_v151spositiontaking_41 as isautopositiontaking, @old_isauto_v151spositiontaking_41 as oldisautopositiontaking, @v151spositiontaking_41 as spositiontaking
				union all	select 151 as sporttype, 42 as bettype, @isauto_v151spositiontaking_42 as isautopositiontaking, @old_isauto_v151spositiontaking_42 as oldisautopositiontaking, @v151spositiontaking_42 as spositiontaking
			) as b on b.bettype = cs.bettype and b.sporttype = cs.sporttype
	where b.isautopositiontaking = 0 and b.oldisautopositiontaking = 0  
END


EXEC dbo.Acc_CustomerUpdMasterHR_MaxPositiontaking @mrecommend = @custid
if (@@error <> 0)
begin
	
	Select @ErrMsg = @UserName + ': '+
					case @Language 
						when 'E' then 'Update process is unsuccessful !'
						when 'CS' then N'更新程序不成功 !'
						when 'CT' then N'更新程序不成功 !'
						when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น.'
						when 'J' then N'アップデート出来ません。'
						when 'KO' then N'업데이트에 실패했습니다.'
						else N'Update process is unsuccessful !'
					end, @ErrCode = 124					 
	
	return
end

Declare @LogSPData varchar(5000)
	
Select @LogSPData = '<Acc_CustomerUpdMasterHR_Positiontaking><info Updallmembers="'+ coalesce(cast(@updateallmembers as varchar(50)),space(1)) + '" ' +
'newspt="'+ coalesce(cast(@newspositiontaking as varchar(50)),space(1)) + '" ' +
'IsCopyPreset_31="'+ coalesce(cast(@IsCopyPreset_31 as varchar(50)),space(1)) + '" ' +
'IsCopyPreset_41="'+ coalesce(cast(@IsCopyPreset_41 as varchar(50)),space(1)) + '" ' +
'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(30)),space(1)) + '" ' +
'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" ' +
'Language="'+ coalesce(cast(@Language as varchar(2)),space(1)) + '" ' +
'IP="'+ coalesce(cast(@IP as varchar(15)),space(1)) + '" ' +
'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" ' +
'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(5000)),space(1)) + '" />' +

'<s v151spt_31="'+ coalesce(cast(@v151spositiontaking_31 as varchar(50)),space(1)) + '" ' +
'v151spt_32="'+ coalesce(cast(@v151spositiontaking_32 as varchar(50)),space(1)) + '" ' +
'v151spt_41="'+ coalesce(cast(@v151spositiontaking_41 as varchar(50)),space(1)) + '" ' +
'v151spt_42="'+ coalesce(cast(@v151spositiontaking_42 as varchar(50)),space(1)) + '" />' +

'<au a_v151spt_31="'+ coalesce(cast(@auto_v151spositiontaking_31 as varchar(50)),space(1)) + '" ' +
'a_v151spt_32="'+ coalesce(cast(@auto_v151spositiontaking_32 as varchar(50)),space(1)) + '" ' +
'a_v151spt_41="'+ coalesce(cast(@auto_v151spositiontaking_41 as varchar(50)),space(1)) + '" ' +
'a_v151spt_42="'+ coalesce(cast(@auto_v151spositiontaking_42 as varchar(50)),space(1)) + '" />' +

'<ia isa_v151spt_31="'+ coalesce(cast(@isauto_v151spositiontaking_31 as varchar(50)),space(1)) + '" ' +
'isa_v151spt_32="'+ coalesce(cast(@isauto_v151spositiontaking_32 as varchar(50)),space(1)) + '" ' +
'isa_v151spt_41="'+ coalesce(cast(@isauto_v151spositiontaking_41 as varchar(50)),space(1)) + '" ' +
'isa_v151spt_42="'+ coalesce(cast(@isauto_v151spositiontaking_42 as varchar(50)),space(1)) + '" />' +

'<m v151mpt_31="'+ coalesce(cast(@v151mpositiontaking_31 as varchar(50)),space(1)) + '" ' +
'v151mpt_32="'+ coalesce(cast(@v151mpositiontaking_32 as varchar(50)),space(1)) + '" ' +
'v151mpt_41="'+ coalesce(cast(@v151mpositiontaking_41 as varchar(50)),space(1)) + '" ' +
'v151mpt_42="'+ coalesce(cast(@v151mpositiontaking_42 as varchar(50)),space(1)) + '" /></Acc_CustomerUpdMasterHR_Positiontaking>'

--Log positiontaking
EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew 
	@UserID = @UserID,
	@CustID = @CustID,
	@ActionID = 419,
	@TrackingValue = @LogSPData

GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdMasterHR_Positiontaking] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdMasterHR_Positiontaking] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdMasterHR_Positiontaking] TO vnteam
