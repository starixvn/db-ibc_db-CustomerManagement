
ALTER PROCEDURE [dbo].[Acc_CustomerUpdMasterFI_Positiontaking]
	@custid int,-- masterid	
	@v201spositiontaking_2 smallmoney,
	@v201spositiontaking_3 smallmoney,
	@auto_v201spositiontaking_2 smallmoney = 0,
	@auto_v201spositiontaking_3 smallmoney = 0,
	@isauto_v201spositiontaking_2 bit = 0,
	@isauto_v201spositiontaking_3 bit = 0,
	@v201mpositiontaking_2 smallmoney = 0.7,
	@v201mpositiontaking_3 smallmoney = 0.7,
	@updateallmembers bit = 0,
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
Created: 20090415@Phuc
Task : Update FI's Master Position Taking
DB: DB02.bodb02
Original: Acc_CustomerUpdEditCustomer_SAg

Revisions:
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

Select @maxpos = 0.5, @maxdownlinepos = 0 --Max pos for FI = 0.5
-- th: @maxpos and @maxdownlinepos are no longer used
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--v201
if 
	@v201spositiontaking_2 <0
	or @v201spositiontaking_2+@v201mpositiontaking_2 >@maxpos
	or @auto_v201spositiontaking_2  >@maxpos
	or @v201mpositiontaking_2 <0	
	
	or @v201spositiontaking_3 <0
	or @v201spositiontaking_3+@v201mpositiontaking_3 >@maxpos
	or @auto_v201spositiontaking_3  > @maxpos
	or @v201mpositiontaking_3 <0	
BEGIN
	select @ErrCode = 11
	Select @ErrMsg = 	@UserName + ': '+
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
select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Min: '+ cast((co.minpositiontaking) as varchar(10))+ '-Max: '+ cast((co.maxpositiontaking) as varchar(10))+ '<br>'
from CustOverride3rd as co with (NOLOCK) inner join
	(
			 		select 2 as bettype, 201 as sporttype, @v201spositiontaking_2 as spositiontaking, 0 as slivepositiontaking, @v201mpositiontaking_2 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v201spositiontaking_2 as isauto_spositiontaking,  0 as isauto_slivepositiontaking, @auto_v201spositiontaking_2 as auto_spositiontaking
		union all	select 3 as bettype, 201 as sporttype, @v201spositiontaking_3 as spositiontaking, 0 as slivepositiontaking, @v201mpositiontaking_3 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v201spositiontaking_3 as isauto_spositiontaking,  0 as isauto_slivepositiontaking, @auto_v201spositiontaking_3 as auto_spositiontaking

	) as b on co.sporttype=b.sporttype and co.bettype = b.bettype
	inner join sports with (nolock) on b.sporttype = sports.sporttype
	inner join bettype with (nolock) on b.bettype = bettype.typeid
where co.custid = @srecommend and (	
					((b.isauto_spositiontaking=0) and (b.spositiontaking+b.mpositiontaking>co.maxpositiontaking or b.spositiontaking+b.mpositiontaking<co.minpositiontaking)) or 
					(b.isauto_spositiontaking>0 and (b.mpositiontaking>co.maxpositiontaking or b.mpositiontaking + b.auto_spositiontaking<co.minpositiontaking))
				)
if @ErrType <>''
BEGIN
	select @ErrCode = 12
	Select @ErrMsg = 	@UserName + ': '+
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
select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Min: '+ cast((co.minpositiontaking) as varchar(10))+ '-Max: '+ cast((co.maxpositiontaking) as varchar(10)) + '<br>'
from CustOverride3rd as co with (NOLOCK) inner join
	(
			 			select 2 as bettype, 201 as sporttype, @v201spositiontaking_2 as spositiontaking, 0 as slivepositiontaking, @v201mpositiontaking_2 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v201spositiontaking_2 as isauto_spositiontaking,  0 as isauto_slivepositiontaking
		union all	 	select 3 as bettype, 201 as sporttype, @v201spositiontaking_3 as spositiontaking, 0 as slivepositiontaking, @v201mpositiontaking_3 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v201spositiontaking_3 as isauto_spositiontaking,  0 as isauto_slivepositiontaking
	) as b on co.sporttype=b.sporttype and co.bettype = b.bettype
	inner join sports with (nolock) on b.sporttype = sports.sporttype
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
						select 	201 as sporttype, 2 as bettype, @v201mpositiontaking_2 as maxpositiontaking		
			union all	select 	201 as sporttype, 3 as bettype, @v201mpositiontaking_3 as maxpositiontaking
		) as b on cs.sporttype=b.sporttype and cs.bettype = b.bettype
where c.mrecommend = @custid and c.roleid = 2 and cs.apositiontaking+cs.mpositiontaking>b.maxpositiontaking
group by username
if @ErrAcc<>''
BEGIN
	select @ErrCode = 14
	Select @ErrMsg = 	@UserName + ': '+
		case @Language 
						when 'E' then 'Existing agents exceeded new master positiontaking ('+@ErrAcc+') (for Finance).'
						when 'CS' then N'现有代理超出新总代理占成数设定 ('+@ErrAcc+ N') (于金融) .'
						when 'CT' then N'現有代理超出新總代理佔成數設定 ('+@ErrAcc+ N') (於金融).'
						when 'TH' then N' ตัวแทนที่มีอยู่ขณะนี้เกินกว่าจำนวนตัวแทนหลักรายใหม่ ('+@ErrAcc+ N')(สำหรับการเงิน).'
						when 'J' then N'Existing agents exceeded new master positiontaking ('+@ErrAcc+ N') (for Finance).'
						when 'KO' then N'에이전트의 거래조건 설정 법위를 넘어섰습니다 ('+@ErrAcc+ N') (금융).'
						else N'Existing agents exceeded new master positiontaking ('+@ErrAcc+ N') (for Finance).'
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
						select 	201 as sporttype, 2 as bettype, @v201mpositiontaking_2 as maxpositiontaking
			union all	select 	201 as sporttype, 3 as bettype, @v201mpositiontaking_3 as maxpositiontaking
		) as b on cs.sporttype=b.sporttype and cs.bettype = b.bettype
where c.mrecommend = @custid and c.roleid = 1 and (cs.apositiontaking+cs.mpositiontaking>b.maxpositiontaking)
group by username
if @ErrAcc<>''
BEGIN
	select @ErrCode = 15
	Select @ErrMsg = 	@UserName + ': '+
		case @Language 
						when 'E' then 'Existing members exceeded new master positiontaking ('+@ErrAcc+') (for Finance).'
						when 'CS' then N'现有会员超出新总代理占成数设定 ('+@ErrAcc+ N') (于金融).'
						when 'CT' then N'現有會員超出新總代理佔成數設定 ('+@ErrAcc+ N') (於金融).'
						when 'TH' then N'สมาชิกที่มีอยู่ในขณะนี้เกินกว่า จำนวนตัวแทนหลักรายใหม่ กำหนดไว้ ('+@ErrAcc+ N')(สำหรับการเงิน).'
						when 'J' then N'Existing members exceeded new master positiontaking ('+@ErrAcc+ N') (for Finance).'
						when 'KO' then N'회원의 거래조건 설정 범위를 넘어섰습니다 ('+@ErrAcc+ N') (금융).'
						else N'Existing members exceeded new master positiontaking ('+@ErrAcc+ N') (for Finance).'
				end
	return
END

--check m3<=m4
select @ErrType = ''
select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ cast((scs.mpositiontaking) as varchar(10)) + '<br>'
from CustSetting3rd as scs with (NOLOCK) inner join
	(
			 			select 2 as bettype, 201 as sporttype, @v201spositiontaking_2 as spositiontaking, 0 as slivepositiontaking, @v201mpositiontaking_2 as mpositiontaking, 0 as mlivepositiontaking, @auto_v201spositiontaking_2 as auto_spositiontaking,  0 as auto_slivepositiontaking
		union all	 	select 3 as bettype, 201 as sporttype, @v201spositiontaking_3 as spositiontaking, 0 as slivepositiontaking, @v201mpositiontaking_3 as mpositiontaking, 0 as mlivepositiontaking, @auto_v201spositiontaking_3 as auto_spositiontaking,  0 as auto_slivepositiontaking
	) as b on scs.sporttype=b.sporttype and scs.bettype = b.bettype
	inner join sports with (nolock) on b.sporttype = sports.sporttype
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

--m3>=um2
select @ErrAcc = ''
select top 100 @ErrAcc = @ErrAcc + username +', '
from 
	custinfo as c with (NOLOCK) 
	inner join CustSetting3rd as cs with (NOLOCK) on c.custid = cs.custid
	inner join (
						select 	201 as sporttype, 2 as bettype, @v201mpositiontaking_2 as maxpositiontaking,  0 as maxlivepositiontaking
			union all	select 	201 as sporttype, 3 as bettype, @v201mpositiontaking_3 as maxpositiontaking,  0 as maxlivepositiontaking
		) as b on cs.sporttype=b.sporttype and cs.bettype = b.bettype
where c.mrecommend = @custid and c.roleid = 2 
	and (	cs.autompositiontaking > b.maxpositiontaking and cs.isautompositiontaking = 1
		)
group by username
if @ErrAcc<>''
BEGIN
	select @ErrCode = 17
	Select @ErrMsg = 	@UserName + ': '+
		case @Language 
						when 'E' then 'Existing agents exceeded new master positiontaking ('+@ErrAcc+') (for Finance).'
						when 'CS' then N'现有代理超出新总代理占成数设定 ('+@ErrAcc+ N') (于金融) .'
						when 'CT' then N'現有代理超出新總代理佔成數設定 ('+@ErrAcc+ N') (於金融).'
						when 'TH' then N' ตัวแทนที่มีอยู่ขณะนี้เกินกว่าจำนวนตัวแทนหลักรายใหม่ ('+@ErrAcc+ N')(สำหรับการเงิน).'
						when 'J' then N'Existing agents exceeded new master positiontaking ('+@ErrAcc+ N') (for Finance).'
						when 'KO' then N'에이전트의 거래조건 설정 법위를 넘어섰습니다 ('+@ErrAcc+ N') (금융).'
						else N'Existing agents exceeded new master positiontaking ('+@ErrAcc+ N') (for Finance).'
				end
	return
END

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--v201
--u3<=s4
select @ErrType = ''
select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ cast((cs.spositiontaking) as varchar(10)) + '<br>'
from CustSetting3rd as cs with (NOLOCK) inner join
	(
						select 2 as bettype, 201 as sporttype, @auto_v201spositiontaking_2 as autopositiontaking
		union all		select 3 as bettype, 201 as sporttype, @auto_v201spositiontaking_3 as autopositiontaking
	) as b on cs.sporttype=b.sporttype and cs.bettype=b.bettype
	inner join sports with (nolock) on b.sporttype = sports.sporttype
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
select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ cast((cs.spositiontaking) as varchar(10))+ '<br>'
from CustSetting3rd as cs with (NOLOCK) inner join
	(
						select 2 as bettype, 201 as sporttype, @v201spositiontaking_2 as spositiontaking, @v201mpositiontaking_2 as mpositiontaking

		union all		select 3 as bettype, 201 as sporttype, @v201spositiontaking_3 as spositiontaking, @v201mpositiontaking_3 as mpositiontaking
	) as b on cs.sporttype=b.sporttype and cs.bettype=b.bettype
	inner join sports with (nolock) on b.sporttype = sports.sporttype
	inner join bettype with (nolock) on b.bettype = bettype.typeid
where cs.custid = @srecommend
	and 
	((cs.spositiontaking<b.spositiontaking) or (cs.spositiontaking+@maxdownlinepos<b.spositiontaking+b.mpositiontaking)
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
	spositiontaking = case bettype when 3 then @v201spositiontaking_3 when 2 then @v201spositiontaking_2 else spositiontaking end,	
	mpositiontaking = case bettype when 3 then @v201mpositiontaking_3 when 2 then @v201mpositiontaking_2 else mpositiontaking end	
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
						when 'KO' then N'업데이트에 실패했습니다.'
						else N'Update process is unsuccessful !'
					end	, @ErrCode = 122					 
	
	return
end

--Auto PT Acc_CustomerUpdMaster_AutoPositiontaking
Declare 
	@old_auto_v201spositiontaking_2 smallmoney,
	@old_auto_v201spositiontaking_3 smallmoney,
	--v201
	@old_isauto_v201spositiontaking_2 bit,
	@old_isauto_v201spositiontaking_3 bit
	
select 	@old_auto_v201spositiontaking_2	=	autopositiontaking		,	@old_isauto_v201spositiontaking_2	=	isautopositiontaking		from CustSetting3rd with (nolock) where custid = @custid and sporttype=201	and bettype=	2
select 	@old_auto_v201spositiontaking_3	=	autopositiontaking		,	@old_isauto_v201spositiontaking_3	=	isautopositiontaking		from CustSetting3rd with (nolock) where custid = @custid and sporttype=201	and bettype=	3

--Update Master Agent account
--For Financial
update cs  
set autopositiontaking = b.autopositiontaking, isautopositiontaking = b.isautopositiontaking
from CustSetting3rd as cs with (ROWLOCK, UPDLOCK)
inner join 
			(
							select 2 as bettype, @auto_v201spositiontaking_2 as autopositiontaking, @isauto_v201spositiontaking_2 as isautopositiontaking
				union all	select 3 as bettype, @auto_v201spositiontaking_3 as autopositiontaking, @isauto_v201spositiontaking_3 as isautopositiontaking
			) as b on b.bettype = cs.bettype
where cs.custid = @custid and cs.sporttype=201
if @@Error <> 0
BEGIN
	
	SELECT @ErrMsg =  @UserName + ': '+
		case @Language 
			when 'E' then 'Error updating auto positiontaking (for Finance)'
			when 'CS' then N'更新占成数不成功(于金融)'
			when 'CT' then N'更新佔成數不成功(於金融)'
			when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ (สำหรับการเงิน)'
			when 'J' then N'Error updating auto positiontaking (for Finance)'
			when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 (금융)'
			else N'Error updating auto positiontaking (for Finance)'
		end	
		,  @ErrCode=205
	return
END

if (@auto_v201spositiontaking_2 <> @old_auto_v201spositiontaking_2 or @isauto_v201spositiontaking_2 <> @old_isauto_v201spositiontaking_2 ) 
BEGIN
	if @isauto_v201spositiontaking_2 >0
	BEGIN
		select @maxpos = spositiontaking from CustSetting3rd with (NOLOCK) where custid = @srecommend and sporttype=201 and bettype = 2
		update cs
			set spositiontaking = case when @maxpos - mpositiontaking-apositiontaking>@auto_v201spositiontaking_2 then @auto_v201spositiontaking_2 else @maxpos - mpositiontaking-apositiontaking end
		from CustSetting3rd as cs with (ROWLOCK, UPDLOCK)
		inner join custinfo as c with (NOLOCK) on cs.custid = c.custid
		where c.mrecommend = @custid and c.roleid = 1 and cs.bettype = 2 and cs.sporttype=201 and cs.isautopositiontaking=0
		if @@Error <> 0
		BEGIN
			
			SELECT @ErrMsg =  @UserName + ': '+
					case @Language 
						when 'E' then 'Error updating auto positiontaking (for Finance)'
						when 'CS' then N'更新占成数不成功(于金融)'
						when 'CT' then N'更新佔成數不成功(於金融)'
						when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ (สำหรับการเงิน)'
						when 'J' then N'Error updating auto positiontaking (for Finance)'
						when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 (금융)'
						else N'Error updating auto positiontaking (for Finance)'
					end	
					,  @ErrCode=219
			return
		END
	END
	else if @isauto_v201spositiontaking_2 <> @old_isauto_v201spositiontaking_2
	BEGIN
		if @updateallmembers = 1
		BEGIN
			update cs
				set spositiontaking = case when mcs.spositiontaking<@newspositiontaking then mcs.spositiontaking else @newspositiontaking end
			from CustSetting3rd as cs with (ROWLOCK, UPDLOCK)
			inner join custinfo as c with (NOLOCK) on cs.custid = c.custid
			inner join CustSetting3rd as mcs with (NOLOCK) on mcs.custid = @custid and cs.sporttype=mcs.sporttype and cs.bettype=mcs.bettype
			where c.mrecommend = @custid and c.roleid = 1 and cs.bettype = 2 and cs.sporttype=201 and cs.isautopositiontaking=0
			if @@Error <> 0
			BEGIN
				
				SELECT @ErrMsg =  @UserName + ': '+
					case @Language 
						when 'E' then 'Error updating auto positiontaking (for Finance)'
						when 'CS' then N'更新占成数不成功(于金融)'
						when 'CT' then N'更新佔成數不成功(於金融)'
						when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ (สำหรับการเงิน)'
						when 'J' then N'Error updating auto positiontaking (for Finance)'
						when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 (금융)'
						else N'Error updating auto positiontaking (for Finance)'
					end	
					,  @ErrCode=220
				return
			END
		END
	END
END	

if (@auto_v201spositiontaking_3 <> @old_auto_v201spositiontaking_3 or @isauto_v201spositiontaking_3 <> @old_isauto_v201spositiontaking_3 ) 
BEGIN
	if @isauto_v201spositiontaking_3 >0
	BEGIN
		select @maxpos = spositiontaking from CustSetting3rd with (NOLOCK) where custid = @srecommend and sporttype=201 and bettype = 3
		update cs
			set spositiontaking = case when @maxpos - mpositiontaking-apositiontaking>@auto_v201spositiontaking_3 then @auto_v201spositiontaking_3 else @maxpos - mpositiontaking-apositiontaking end
		from CustSetting3rd as cs with (ROWLOCK, UPDLOCK)
		inner join custinfo as c with (NOLOCK) on cs.custid = c.custid
		where c.mrecommend = @custid and c.roleid = 1 and cs.bettype = 3 and cs.sporttype=201 and cs.isautopositiontaking=0
		if @@Error <> 0
		BEGIN
			
			SELECT @ErrMsg =  @UserName + ': '+
					case @Language 
						when 'E' then 'Error updating auto positiontaking (for Finance)'
						when 'CS' then N'更新占成数不成功(于金融)'
						when 'CT' then N'更新佔成數不成功(於金融)'
						when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ (สำหรับการเงิน)'
						when 'J' then N'Error updating auto positiontaking (for Finance)'
						when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 (금융)'
						else N'Error updating auto positiontaking (for Finance)'
					end	
					,  @ErrCode=219
			return
		END
	END
	else if @isauto_v201spositiontaking_3 <> @old_isauto_v201spositiontaking_3
	BEGIN
		if @updateallmembers = 1
		BEGIN
			update cs 
				set spositiontaking = case when mcs.spositiontaking<@newspositiontaking then mcs.spositiontaking else @newspositiontaking end
			from CustSetting3rd as cs with (ROWLOCK, UPDLOCK)
			inner join custinfo as c with (NOLOCK) on cs.custid = c.custid
			inner join CustSetting3rd as mcs with (NOLOCK) on mcs.custid = @custid and cs.sporttype=mcs.sporttype and cs.bettype=mcs.bettype
			where c.mrecommend = @custid and c.roleid = 1 and cs.bettype = 3 and cs.sporttype=201 and cs.isautopositiontaking=0
			if @@Error <> 0
			BEGIN
				
				SELECT @ErrMsg =  @UserName + ': '+
					case @Language 
						when 'E' then 'Error updating auto positiontaking (for Finance)'
						when 'CS' then N'更新占成数不成功(于金融)'
						when 'CT' then N'更新佔成數不成功(於金融)'
						when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ (สำหรับการเงิน)'
						when 'J' then N'Error updating auto positiontaking (for Finance)'
						when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 (금융)'
						else N'Error updating auto positiontaking (for Finance)'
					end	
					,  @ErrCode=220
				return
			END
		END
	END
END	

EXEC dbo.Acc_CustomerUpdMasterFI_MaxPositiontaking @mrecommend = @custid
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
	
Select @LogSPData = '<Acc_CustomerUpdMasterFI_Positiontaking><info Updallmembers="'+ coalesce(cast(@updateallmembers as varchar(50)),space(1)) + '" ' +
'newspt="'+ coalesce(cast(@newspositiontaking as varchar(50)),space(1)) + '" ' +
'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(30)),space(1)) + '" ' +
'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" ' +
'Language="'+ coalesce(cast(@Language as varchar(2)),space(1)) + '" ' +
'IP="'+ coalesce(cast(@IP as varchar(15)),space(1)) + '" ' +
'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" ' +
'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(5000)),space(1)) + '" />' +

'<s v201spt_2="'+ coalesce(cast(@v201spositiontaking_2 as varchar(50)),space(1)) + '" ' +
'v201spt_3="'+ coalesce(cast(@v201spositiontaking_3 as varchar(50)),space(1)) + '" />' +

'<au a_v201spt_2="'+ coalesce(cast(@auto_v201spositiontaking_2 as varchar(50)),space(1)) + '" ' +
'a_v201spt_3="'+ coalesce(cast(@auto_v201spositiontaking_3 as varchar(50)),space(1)) + '" />' +

'<ia isa_v201spt_2="'+ coalesce(cast(@isauto_v201spositiontaking_2 as varchar(50)),space(1)) + '" ' +
'isa_v201spt_3="'+ coalesce(cast(@isauto_v201spositiontaking_3 as varchar(50)),space(1)) + '" />' +

'<m v201mpt_2="'+ coalesce(cast(@v201mpositiontaking_2 as varchar(50)),space(1)) + '" ' +
'v201mpt_3="'+ coalesce(cast(@v201mpositiontaking_3 as varchar(50)),space(1)) + '" /></Acc_CustomerUpdMasterFI_Positiontaking>'

--Log positiontaking
EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew 
	@UserID = @UserID,
	@CustID = @CustID,
	@ActionID = 415,
	@TrackingValue = @LogSPData

GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdMasterFI_Positiontaking] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdMasterFI_Positiontaking] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdMasterFI_Positiontaking] TO vnteam
