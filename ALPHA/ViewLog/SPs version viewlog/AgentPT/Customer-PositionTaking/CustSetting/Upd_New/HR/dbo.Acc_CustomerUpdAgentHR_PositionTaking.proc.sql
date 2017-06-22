ALTER PROCEDURE [dbo].[Acc_CustomerUpdAgentHR_PositionTaking]
	@custid int, --agentID
	--a2
	@v151apositiontaking_31 smallmoney,
	@v151apositiontaking_32 smallmoney,
	@v151apositiontaking_41 smallmoney,
	@v151apositiontaking_42 smallmoney,
	--m2
	@v151mpositiontaking_31 smallmoney,
	@v151mpositiontaking_32 smallmoney,
	@v151mpositiontaking_41 smallmoney,
	@v151mpositiontaking_42 smallmoney,
	--um2
	@auto_v151mpositiontaking_31 smallmoney = 0,
	@auto_v151mpositiontaking_32 smallmoney = 0,
	@auto_v151mpositiontaking_41 smallmoney = 0,
	@auto_v151mpositiontaking_42 smallmoney = 0,
	--im2
	@isauto_v151mpositiontaking_31 bit = 0,
	@isauto_v151mpositiontaking_32 bit = 0,
	@isauto_v151mpositiontaking_41 bit = 0,
	@isauto_v151mpositiontaking_42 bit = 0,

	@IsCopyPreset_31 bit = 0,--Use for copy preset to member
	@IsCopyPreset_41 bit = 0,--Use for copy preset to member
	@updateallmembers bit = 0,--Use for auto PT
	@newmpositiontaking smallmoney = 0,--equals max(m+a) - chosen(a)

	@SubAccID int = 0, --Sub-AccountID	
	
	@UserID int = 0,	
	@Language varchar(2) = 'E',
	@IP varchar(15)='',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS
--@Source Control
/*
Created: 20090517@Phuc
Task : Update HR's Agent Position Taking
DB: DB02.bodb02
Original: Acc_CustomerUpdEditCustomer_MAg

Revisions:
	- 20090610@Phuc: copy master preset to member(m2->m1).
	- 20090630@Phuc: auto master PT on member level.
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

Declare @UserName nvarchar(20), @mrecommend int, @srecommend int, @maxpos smallmoney
declare @ErrAcc varchar(4000), @ErrType varchar(4000)
Set @maxpos = 0.5 --max pt for HR

Select @UserName = username, @mrecommend = mrecommend, @srecommend = srecommend 
from custinfo with (NOLOCK) 
where CustID = @CustID

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Check Param
if @v151apositiontaking_31  <0
	or @v151apositiontaking_31 + @v151mpositiontaking_31 > @maxpos
	or @v151mpositiontaking_31 <0
	or @v151mpositiontaking_31 > @maxpos
	
	or @v151apositiontaking_32  <0
	or @v151apositiontaking_32 + @v151mpositiontaking_32 > @maxpos
	or @v151mpositiontaking_32 <0
	or @v151mpositiontaking_32 > @maxpos	
	
	or @v151apositiontaking_41  <0
	or @v151apositiontaking_41 + @v151mpositiontaking_41 > @maxpos
	or @v151mpositiontaking_41 <0
	or @v151mpositiontaking_41 > @maxpos
	
	or @v151apositiontaking_42  <0
	or @v151apositiontaking_42 + @v151mpositiontaking_42 > @maxpos
	or @v151mpositiontaking_42 <0
	or @v151mpositiontaking_42 > @maxpos
BEGIN
	select @ErrCode = 8
	Select @ErrMsg = 	@UserName + ': '+
		case @Language 
						when 'E' then 'Wrong position taking.'
						when 'CS' then N'占成数不正确.'
						when 'CT' then N'佔成數不正確.'
						when 'TH' then N'การกำหนดจำนวนเงินไม่ถูกต้อง.'
						when 'J' then N'Wrong position taking.'
						when 'KO' then N'거래 조건이 잘못 되었습니다.'
						else N'Wrong position taking.'
				end
	return
END

--check n3<=m2+a2<=l3 if im2 = 0, 
--a2<=l3 and um2+a2>=n3 if im2 = 1
select @ErrType = ''
select @ErrType = @ErrType + '-'+ typenamee + '-Min: '+ cast((co.minpositiontaking) as varchar(10))+ '-Max: '+ cast((co.maxpositiontaking) as varchar(10))+ '<br>'
from CustOverride3rd as co with (NOLOCK) inner join
	(
 					select 31 as bettype, 151 as sporttype, @v151apositiontaking_31 as apositiontaking, @v151mpositiontaking_31 as mpositiontaking, @isauto_v151mpositiontaking_31 as isauto_mpositiontaking, @auto_v151mpositiontaking_31 as auto_mpositiontaking		
 		union all	select 32 as bettype, 151 as sporttype, @v151apositiontaking_32 as apositiontaking, @v151mpositiontaking_32 as mpositiontaking, @isauto_v151mpositiontaking_32 as isauto_mpositiontaking, @auto_v151mpositiontaking_32 as auto_mpositiontaking
 		union all	select 41 as bettype, 151 as sporttype, @v151apositiontaking_41 as apositiontaking, @v151mpositiontaking_41 as mpositiontaking, @isauto_v151mpositiontaking_41 as isauto_mpositiontaking, @auto_v151mpositiontaking_41 as auto_mpositiontaking
 		union all	select 42 as bettype, 151 as sporttype, @v151apositiontaking_42 as apositiontaking, @v151mpositiontaking_42 as mpositiontaking, @isauto_v151mpositiontaking_42 as isauto_mpositiontaking, @auto_v151mpositiontaking_42 as auto_mpositiontaking
	) as b on co.sporttype=b.sporttype and co.bettype = b.bettype
	inner join bettype with (nolock) on b.bettype = bettype.typeid
where co.custid = @mrecommend and (	
					((b.isauto_mpositiontaking=0) and (b.mpositiontaking+b.apositiontaking>co.maxpositiontaking or b.mpositiontaking+b.apositiontaking<co.minpositiontaking)) or 
					(b.isauto_mpositiontaking>0 and (b.apositiontaking>co.maxpositiontaking or b.apositiontaking + b.auto_mpositiontaking<co.minpositiontaking))
				)
if @ErrType <>''
BEGIN
	select @ErrCode = 9
	Select @ErrMsg = @UserName + ': '+
			case @Language 
						when 'E' then 'Wrong position taking (min/max set by company).<br>'+@ErrType
						when 'CS' then N'占成数不正确(公司设给最低/高占成).<br>'+@ErrType
						when 'CT' then N'佔成數不正確(公司設給最低/高佔成).<br>'+@ErrType
						when 'TH' then N'การกำหนดจำนวนเงินไม่ถูกต้อง (สูงสุด หรือ ต่ำสุด อ้างอิงจากข้อมูลบริษัท).<br>'+@ErrType
						when 'J' then N'Wrong position taking (min/max set by company).<br>'+@ErrType
						when 'KO' then N'거래 조건이 잘못 되었습니다 (ibc가 설정한 최소값/최대값 ).<br>'+@ErrType
						else N'Wrong position taking (min/max set by company).<br>'+@ErrType
				end
	return
END

--n2<=a2<=l2
select @ErrType = ''
select @ErrType = @ErrType + '-'+ typenamee + '-Min: '+ cast((co.minpositiontaking) as varchar(10))+ '-Max: '+ cast((co.maxpositiontaking) as varchar(10))+ '<br>'
from CustOverride3rd as co with (NOLOCK) inner join
	(
			 		select 31 as bettype, 151 as sporttype, @v151apositiontaking_31 as apositiontaking, @v151mpositiontaking_31 as mpositiontaking
		union all	select 32 as bettype, 151 as sporttype, @v151apositiontaking_32 as apositiontaking, @v151mpositiontaking_32 as mpositiontaking
		union all	select 41 as bettype, 151 as sporttype, @v151apositiontaking_41 as apositiontaking, @v151mpositiontaking_41 as mpositiontaking
		union all	select 42 as bettype, 151 as sporttype, @v151apositiontaking_42 as apositiontaking, @v151mpositiontaking_42 as mpositiontaking
	) as b on co.sporttype=b.sporttype and co.bettype = b.bettype
	inner join bettype with (nolock) on b.bettype = bettype.typeid
where co.custid = @custid and (	
					(b.apositiontaking>co.maxpositiontaking or b.apositiontaking<co.minpositiontaking)
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
						when 'KO' then N'거래 조건이 잘못 되었습니다 (ibc가 설정한 최소값/최대값 ).<br>'+@ErrType
						else N'Wrong position taking (min/max set by company).<br>'+@ErrType
				end
	return
END

--check a2<=a4 - Vinh
select @ErrType = ''
select @ErrType = @ErrType + '-'+ typenamee + '-Max: '+ cast((scs.apositiontaking) as varchar(10)) + '<br>'
from custinfo as c with (NOLOCK) inner join CustSetting3rd as scs with (NOLOCK) on c.srecommend = scs.custid inner join 
	(
					select 31 as bettype, 151 as sporttype, @v151apositiontaking_31 as apositiontaking, @v151mpositiontaking_31 as mpositiontaking
		union all	select 32 as bettype, 151 as sporttype, @v151apositiontaking_32 as apositiontaking, @v151mpositiontaking_32 as mpositiontaking
		union all	select 41 as bettype, 151 as sporttype, @v151apositiontaking_41 as apositiontaking, @v151mpositiontaking_41 as mpositiontaking
		union all	select 42 as bettype, 151 as sporttype, @v151apositiontaking_42 as apositiontaking, @v151mpositiontaking_42 as mpositiontaking
	) as b on scs.sporttype=b.sporttype and scs.bettype = b.bettype
	inner join bettype with (nolock) on b.bettype = bettype.typeid
where c.custid = @mrecommend and (b.apositiontaking>scs.apositiontaking)
if @ErrType <>''
BEGIN
	select @ErrCode = 12
	Select @ErrMsg = @UserName + ': '+	
				case @Language 
						when 'E' then 'Wrong position taking (max set by company).<br>'+@ErrType
						when 'CS' then N'占成数不正确(公司设给最高占成).<br>'+@ErrType
						when 'CT' then N'佔成數不正確(公司設給最高佔成).<br>'+@ErrType
						when 'TH' then N'การกำหนดจำนวนเงินไม่ถูกต้อง (สูงสุด  อ้างอิงจากข้อมูลบริษัท).<br>'+@ErrType
						when 'J' then N'Wrong position taking (max set by company).<br>'+@ErrType
						when 'KO' then N'거래 조건이 잘못 되었습니다 (ibc가 설정한 최대 값).<br>'+@ErrType
						else N'Wrong position taking (max set by company).<br>'+@ErrType
				end
	return
END
--End check param
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
declare 
	@old_v151apositiontaking_31 smallmoney,
	@old_v151apositiontaking_32 smallmoney,
	@old_v151apositiontaking_41 smallmoney,
	@old_v151apositiontaking_42 smallmoney,
	
	@old_v151mpositiontaking_31 smallmoney,
	@old_v151mpositiontaking_32 smallmoney,
	@old_v151mpositiontaking_41 smallmoney,
	@old_v151mpositiontaking_42 smallmoney
	
select @old_v151mpositiontaking_31 = mpositiontaking, @old_v151apositiontaking_31 = apositiontaking 
from CustSetting3rd with (NOLOCK) 
where custid = @custid and bettype=31 and sporttype=151

select @old_v151mpositiontaking_32 = mpositiontaking, @old_v151apositiontaking_32 = apositiontaking 
from CustSetting3rd with (NOLOCK) 
where custid = @custid and bettype=32 and sporttype=151

select @old_v151mpositiontaking_41 = mpositiontaking, @old_v151apositiontaking_41 = apositiontaking 
from CustSetting3rd with (NOLOCK) 
where custid = @custid and bettype=41 and sporttype=151

select @old_v151mpositiontaking_42 = mpositiontaking, @old_v151apositiontaking_42 = apositiontaking 
from CustSetting3rd with (NOLOCK) 
where custid = @custid and bettype=42 and sporttype=151

declare
	@max_v151mapositiontaking_31 smallmoney,
	@max_v151mapositiontaking_32 smallmoney,
	@max_v151mapositiontaking_41 smallmoney,
	@max_v151mapositiontaking_42 smallmoney
	
select @max_v151mapositiontaking_31 =mpositiontaking 
from CustSetting3rd with (NOLOCK) 
where custid = @mrecommend and bettype=31 and sporttype=151

select @max_v151mapositiontaking_32 =mpositiontaking 
from CustSetting3rd with (NOLOCK) 
where custid = @mrecommend and bettype=32 and sporttype=151

select @max_v151mapositiontaking_41 =mpositiontaking 
from CustSetting3rd with (NOLOCK) 
where custid = @mrecommend and bettype=41 and sporttype=151

select @max_v151mapositiontaking_42 =mpositiontaking 
from CustSetting3rd with (NOLOCK) 
where custid = @mrecommend and bettype=42 and sporttype=151

--check m2+a2<=m3 - Vinh
select @ErrType = ''
select @ErrType = @ErrType + '-'+ typenamee + '-Max: '+ cast((b.max_mapositiontaking) as varchar(10)) + '<br>'
from
(
				select 31 as bettype, 151 as sporttype, @v151apositiontaking_31 as apositiontaking, @v151mpositiontaking_31 as mpositiontaking, @max_v151mapositiontaking_31 as max_mapositiontaking
	union all	select 32 as bettype, 151 as sporttype, @v151apositiontaking_32 as apositiontaking, @v151mpositiontaking_32 as mpositiontaking, @max_v151mapositiontaking_32 as max_mapositiontaking
	union all	select 41 as bettype, 151 as sporttype, @v151apositiontaking_41 as apositiontaking, @v151mpositiontaking_41 as mpositiontaking, @max_v151mapositiontaking_41 as max_mapositiontaking	
	union all	select 42 as bettype, 151 as sporttype, @v151apositiontaking_42 as apositiontaking, @v151mpositiontaking_42 as mpositiontaking, @max_v151mapositiontaking_42 as max_mapositiontaking
) as b
inner join bettype with (nolock) on b.bettype = bettype.typeid
where (b.apositiontaking+b.mpositiontaking>b.max_mapositiontaking) 

if @ErrType <>''
BEGIN
	select @ErrCode = 101
	Select @ErrMsg = 	@UserName + ': '+
						case @Language 
						when 'E' then 'Wrong position taking.<br>'+@ErrType
						when 'CS' then N'占成数不正确.<br>'+@ErrType
						when 'CT' then N'佔成數不正確.<br>'+@ErrType
						when 'TH' then N'การกำหนดจำนวนเงินไม่ถูกต้อง .<br>'+@ErrType
						when 'J' then N'Wrong position taking.<br>'+@ErrType
						when 'KO' then N'거래 조건이 잘못 되었습니다.<br>'+@ErrType
						else N'Wrong position taking.<br>'+@ErrType
				end		
	return
END

--check um2<=min(m3,l3) - Phuc@20081209
select @ErrType = ''
select @ErrType = @ErrType + '-'+ typenamee + '-Max: '+ cast((case when max_mapositiontaking > co.maxpositiontaking then co.maxpositiontaking else max_mapositiontaking end) as varchar(10)) + '<br>'
from CustOverride3rd co (nolock) inner join 
(
				select 31 as bettype, 151 as sporttype, @auto_v151mpositiontaking_31 as autopositiontaking, @isauto_v151mpositiontaking_31 as isautopositiontaking, @max_v151mapositiontaking_31 as max_mapositiontaking	
	union all   select 32 as bettype, 151 as sporttype, @auto_v151mpositiontaking_32 as autopositiontaking, @isauto_v151mpositiontaking_32 as isautopositiontaking, @max_v151mapositiontaking_32 as max_mapositiontaking	
	union all   select 41 as bettype, 151 as sporttype, @auto_v151mpositiontaking_41 as autopositiontaking, @isauto_v151mpositiontaking_41 as isautopositiontaking, @max_v151mapositiontaking_41 as max_mapositiontaking	
	union all   select 42 as bettype, 151 as sporttype, @auto_v151mpositiontaking_42 as autopositiontaking, @isauto_v151mpositiontaking_42 as isautopositiontaking, @max_v151mapositiontaking_42 as max_mapositiontaking	
) as b on b.sporttype = co.sporttype and b.bettype = co.bettype
inner join bettype with (nolock) on b.bettype = bettype.typeid
where co.custid = @mrecommend and
(
	  (	b.isautopositiontaking = 1 
		and b.autopositiontaking > case when max_mapositiontaking > co.maxpositiontaking then co.maxpositiontaking else max_mapositiontaking end
	  ) 
)

if @ErrType <>''
BEGIN
	select @ErrCode = 101
	Select @ErrMsg = 	@UserName + ': '+
						case @Language 
						when 'E' then 'Wrong position taking.<br>'+@ErrType
						when 'CS' then N'占成数不正确.<br>'+@ErrType
						when 'CT' then N'佔成數不正確.<br>'+@ErrType
						when 'TH' then N'การกำหนดจำนวนเงินไม่ถูกต้อง .<br>'+@ErrType
						when 'J' then N'Wrong position taking.<br>'+@ErrType
						when 'KO' then N'거래 조건이 잘못 되었습니다.<br>'+@ErrType
						else N'Wrong position taking.<br>'+@ErrType
				end		
	return
END

----------------------------------------------------------------------------------------------------------

update CustSetting3rd with (ROWLOCK, UPDLOCK)
set
	apositiontaking = case bettype when 31 then @v151apositiontaking_31 when 32 then @v151apositiontaking_32 when 41 then @v151apositiontaking_41 when 42 then @v151apositiontaking_42 else apositiontaking end,
	mpositiontaking = case bettype when 31 then @v151mpositiontaking_31 when 32 then @v151mpositiontaking_32 when 41 then @v151mpositiontaking_41 when 42 then @v151mpositiontaking_42 else mpositiontaking end
where custid=@custid and sporttype = 151
if (@@error <> 0)
begin
	
	Select @ErrMsg = @UserName + ':' + 
					case @Language 
						when 'E' then 'Update process is unsuccessful !'
						when 'CS' then N'更新程序不成功 !'
						when 'CT' then N'更新程序不成功 !'
						when 'TH' then N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น.'
						when 'J' then N'アップデート出来ません。'
						when 'KO' then N'업데이트에 실패했습니다.'
						else N'Update process is unsuccessful !'
					end, @ErrCode = 115
	return
end

--Cal Auto Positiontaking for Master
Declare 
	@old_auto_v151mpositiontaking_31 smallmoney,
	@old_auto_v151mpositiontaking_32 smallmoney,
	@old_auto_v151mpositiontaking_41 smallmoney,
	@old_auto_v151mpositiontaking_42 smallmoney,
	
	@old_isauto_v151mpositiontaking_31 bit,
	@old_isauto_v151mpositiontaking_32 bit,
	@old_isauto_v151mpositiontaking_41 bit,
	@old_isauto_v151mpositiontaking_42 bit

--------------------------------------------------------
--Get old Auto PT from Agent
select 	@old_auto_v151mpositiontaking_31 = autompositiontaking, @old_isauto_v151mpositiontaking_31 = isautompositiontaking	
from CustSetting3rd with (nolock) 
where custid = @custid and sporttype=151 and bettype= 31

select 	@old_auto_v151mpositiontaking_32 = autompositiontaking, @old_isauto_v151mpositiontaking_32 = isautompositiontaking	
from CustSetting3rd with (nolock) 
where custid = @custid and sporttype=151 and bettype= 32

select 	@old_auto_v151mpositiontaking_41 = autompositiontaking, @old_isauto_v151mpositiontaking_41 = isautompositiontaking	
from CustSetting3rd with (nolock) 
where custid = @custid and sporttype=151 and bettype= 41

select 	@old_auto_v151mpositiontaking_42 = autompositiontaking, @old_isauto_v151mpositiontaking_42 = isautompositiontaking	
from CustSetting3rd with (nolock) 
where custid = @custid and sporttype=151 and bettype= 42

--Update Master Agent account
update CustSetting3rd with (ROWLOCK, UPDLOCK) set autompositiontaking = b.autopositiontaking, isautompositiontaking = b.isautopositiontaking
from CustSetting3rd as cs inner join 
		(
						select 31 as bettype, @auto_v151mpositiontaking_31 as autopositiontaking, @isauto_v151mpositiontaking_31 as isautopositiontaking
			union all	select 32 as bettype, @auto_v151mpositiontaking_32 as autopositiontaking, @isauto_v151mpositiontaking_32 as isautopositiontaking
			union all	select 41 as bettype, @auto_v151mpositiontaking_41 as autopositiontaking, @isauto_v151mpositiontaking_41 as isautopositiontaking
			union all	select 42 as bettype, @auto_v151mpositiontaking_42 as autopositiontaking, @isauto_v151mpositiontaking_42 as isautopositiontaking
		) as b on b.bettype = cs.bettype
where cs.custid = @custid and cs.sporttype=151
if @@Error <> 0
BEGIN
	
	SELECT @ErrMsg = @UserName + ': '+ 
		case @Language 
			when 'E' then 'Error updating auto positiontaking'
			when 'CS' then N'更新占成数不成功'
			when 'CT' then N'更新佔成數不成功'
			when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ '
			when 'J' then N'Error updating auto positiontaking'
			when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다.'
			else N'Error updating auto positiontaking'
		end	
		,  @ErrCode=205
	return
END

---------------------------------
if (@auto_v151mpositiontaking_31 <> @old_auto_v151mpositiontaking_31 or @isauto_v151mpositiontaking_31 <> @old_isauto_v151mpositiontaking_31 ) 
BEGIN
	if @isauto_v151mpositiontaking_31 >0 --Use AUTO MPT
	BEGIN
		--m1=min(m3-a1,u2)
		select @maxpos = mpositiontaking from CustSetting3rd with (NOLOCK) where custid = @mrecommend and sporttype=151 and bettype = 31
		update cs 
			set mpositiontaking = case when @maxpos - apositiontaking>@auto_v151mpositiontaking_31 then @auto_v151mpositiontaking_31 else @maxpos -apositiontaking end
		from CustSetting3rd as cs with (ROWLOCK, UPDLOCK) 
		inner join custinfo as c with (NOLOCK) on cs.custid = c.custid
		where c.recommend = @custid and c.roleid = 1 and cs.bettype = 31 and cs.sporttype=151
		if @@Error <> 0
		BEGIN
			
			SELECT @ErrMsg =  @UserName + ': '+
					case @Language 
						when 'E' then 'Error updating auto positiontaking'
						when 'CS' then N'更新占成数不成功'
						when 'CT' then N'更新佔成數不成功'
						when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์'
						when 'J' then N'Error updating auto positiontaking'
						when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다.'
						else N'Error updating auto positiontaking'
					end	
					,  @ErrCode=219
			return
		END
	END
	else if @isauto_v151mpositiontaking_31 <> @old_isauto_v151mpositiontaking_31 --Not use AUTO MPT
	BEGIN
		if @updateallmembers = 1 --all member
		BEGIN
			--m1=min(m2,@newmpositiontaking)
			update cs 
				set mpositiontaking = case when acs.mpositiontaking<@newmpositiontaking then acs.mpositiontaking else @newmpositiontaking end
			from CustSetting3rd as cs with (ROWLOCK, UPDLOCK) 
			inner join custinfo as c with (NOLOCK) on cs.custid = c.custid
			inner join CustSetting3rd as acs with (NOLOCK) on acs.custid = @custid and cs.sporttype=acs.sporttype and cs.bettype=acs.bettype
			where c.recommend = @custid and c.roleid = 1 and cs.bettype = 31 and cs.sporttype=151
			if @@Error <> 0
			BEGIN
				
				SELECT @ErrMsg =  @UserName + ': '+
					case @Language 
						when 'E' then 'Error updating auto positiontaking'
						when 'CS' then N'更新占成数不成功'
						when 'CT' then N'更新佔成數不成功'
						when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ '
						when 'J' then N'Error updating auto positiontaking'
						when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다.'
						else N'Error updating auto positiontaking'
					end	
					,  @ErrCode=220
				return
			END
		END
	END
END	

---------------------------------
if (@auto_v151mpositiontaking_32 <> @old_auto_v151mpositiontaking_32 or @isauto_v151mpositiontaking_32 <> @old_isauto_v151mpositiontaking_32 ) 
BEGIN
	if @isauto_v151mpositiontaking_32 >0 --Use AUTO MPT
	BEGIN
		--m1=min(m3-a1,um2)
		select @maxpos = mpositiontaking from CustSetting3rd with (NOLOCK) where custid = @mrecommend and sporttype=151 and bettype = 32
		update cs 
			set mpositiontaking = case when @maxpos - apositiontaking>@auto_v151mpositiontaking_32 then @auto_v151mpositiontaking_32 else @maxpos -apositiontaking end
		from CustSetting3rd as cs with (ROWLOCK, UPDLOCK) 
		inner join custinfo as c with (NOLOCK) on cs.custid = c.custid
		where c.recommend = @custid and c.roleid = 1 and cs.bettype = 32 and cs.sporttype=151
		if @@Error <> 0
		BEGIN
			
			SELECT @ErrMsg =  @UserName + ': '+
					case @Language 
						when 'E' then 'Error updating auto positiontaking'
						when 'CS' then N'更新占成数不成功'
						when 'CT' then N'更新佔成數不成功'
						when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์'
						when 'J' then N'Error updating auto positiontaking'
						when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다.'
						else N'Error updating auto positiontaking'
					end	
					,  @ErrCode=219
			return
		END
	END
	else if @isauto_v151mpositiontaking_32 <> @old_isauto_v151mpositiontaking_32 --Not use AUTO MPT
	BEGIN
		if @updateallmembers = 1 --all member
		BEGIN
			--m1=min(m2,@newmpositiontaking)
			update cs 
				set mpositiontaking = case when acs.mpositiontaking<@newmpositiontaking then acs.mpositiontaking else @newmpositiontaking end
			from CustSetting3rd as cs with (ROWLOCK, UPDLOCK) 
			inner join custinfo as c with (NOLOCK) on cs.custid = c.custid
			inner join CustSetting3rd as acs with (NOLOCK) on acs.custid = @custid and cs.sporttype=acs.sporttype and cs.bettype=acs.bettype
			where c.recommend = @custid and c.roleid = 1 and cs.bettype = 32 and cs.sporttype=151
			if @@Error <> 0
			BEGIN
				
				SELECT @ErrMsg =  @UserName + ': '+
					case @Language 
						when 'E' then 'Error updating auto positiontaking'
						when 'CS' then N'更新占成数不成功'
						when 'CT' then N'更新佔成數不成功'
						when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์'
						when 'J' then N'Error updating auto positiontaking'
						when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다.'
						else N'Error updating auto positiontaking'
					end	
					,  @ErrCode=220
				return
			END
		END
	END
END

---------------------------------
if (@auto_v151mpositiontaking_41 <> @old_auto_v151mpositiontaking_41 or @isauto_v151mpositiontaking_41 <> @old_isauto_v151mpositiontaking_41 ) 
BEGIN
	if @isauto_v151mpositiontaking_41 >0 --Use AUTO MPT
	BEGIN
		--m1=min(m3-a1,um2)
		select @maxpos = mpositiontaking from CustSetting3rd with (NOLOCK) where custid = @mrecommend and sporttype=151 and bettype = 41
		update cs 
			set mpositiontaking = case when @maxpos - apositiontaking>@auto_v151mpositiontaking_41 then @auto_v151mpositiontaking_41 else @maxpos -apositiontaking end
		from CustSetting3rd as cs with (ROWLOCK, UPDLOCK) 
		inner join custinfo as c with (NOLOCK) on cs.custid = c.custid
		where c.recommend = @custid and c.roleid = 1 and cs.bettype = 41 and cs.sporttype=151
		if @@Error <> 0
		BEGIN
			
			SELECT @ErrMsg =  @UserName + ': '+
					case @Language 
						when 'E' then 'Error updating auto positiontaking'
						when 'CS' then N'更新占成数不成功'
						when 'CT' then N'更新佔成數不成功'
						when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์'
						when 'J' then N'Error updating auto positiontaking'
						when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다.'
						else N'Error updating auto positiontaking'
					end	
					,  @ErrCode=219
			return
		END
	END
	else if @isauto_v151mpositiontaking_41 <> @old_isauto_v151mpositiontaking_41 --Not use AUTO MPT
	BEGIN
		if @updateallmembers = 1 --all member
		BEGIN
			--m1=min(m2,@newmpositiontaking)
			update cs  
			set mpositiontaking = case when acs.mpositiontaking<@newmpositiontaking then acs.mpositiontaking else @newmpositiontaking end
			from CustSetting3rd as cs with (ROWLOCK, UPDLOCK)
			inner join custinfo as c with (NOLOCK) on cs.custid = c.custid
			inner join CustSetting3rd as acs with (NOLOCK) on acs.custid = @custid and cs.sporttype=acs.sporttype and cs.bettype=acs.bettype
			where c.recommend = @custid and c.roleid = 1 and cs.bettype = 41 and cs.sporttype=151
			if @@Error <> 0
			BEGIN
				
				SELECT @ErrMsg =  @UserName + ': '+
					case @Language 
						when 'E' then 'Error updating auto positiontaking'
						when 'CS' then N'更新占成数不成功'
						when 'CT' then N'更新佔成數不成功'
						when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์'
						when 'J' then N'Error updating auto positiontaking'
						when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다.'
						else N'Error updating auto positiontaking'
					end	
					,  @ErrCode=220
				return
			END
		END
	END
END

---------------------------------
if (@auto_v151mpositiontaking_42 <> @old_auto_v151mpositiontaking_42 or @isauto_v151mpositiontaking_42 <> @old_isauto_v151mpositiontaking_42 ) 
BEGIN
	if @isauto_v151mpositiontaking_42 >0 --Use AUTO MPT
	BEGIN
		--m1=min(m3-a1,um2)
		select @maxpos = mpositiontaking from CustSetting3rd with (NOLOCK) where custid = @mrecommend and sporttype=151 and bettype = 42
		update cs 
			set mpositiontaking = case when @maxpos - apositiontaking>@auto_v151mpositiontaking_42 then @auto_v151mpositiontaking_42 else @maxpos -apositiontaking end
		from CustSetting3rd as cs with (ROWLOCK, UPDLOCK)
		inner join custinfo as c with (NOLOCK) on cs.custid = c.custid
		where c.recommend = @custid and c.roleid = 1 and cs.bettype = 42 and cs.sporttype=151
		if @@Error <> 0
		BEGIN
			
			SELECT @ErrMsg =  @UserName + ': '+
					case @Language 
						when 'E' then 'Error updating auto positiontaking'
						when 'CS' then N'更新占成数不成功'
						when 'CT' then N'更新佔成數不成功'
						when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ '
						when 'J' then N'Error updating auto positiontaking'
						when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다.'
						else N'Error updating auto positiontaking'
					end	
					,  @ErrCode=219
			return
		END
	END
	else if @isauto_v151mpositiontaking_42 <> @old_isauto_v151mpositiontaking_42 --Not use AUTO MPT
	BEGIN
		if @updateallmembers = 1 --all member
		BEGIN
			--m1=min(m2,@newmpositiontaking)
			update cs
				set mpositiontaking = case when acs.mpositiontaking<@newmpositiontaking then acs.mpositiontaking else @newmpositiontaking end
			from CustSetting3rd as cs with (ROWLOCK, UPDLOCK)
			inner join custinfo as c with (NOLOCK) on cs.custid = c.custid
			inner join CustSetting3rd as acs with (NOLOCK) on acs.custid = @custid and cs.sporttype=acs.sporttype and cs.bettype=acs.bettype
			where c.recommend = @custid and c.roleid = 1 and cs.bettype = 42 and cs.sporttype=151
			if @@Error <> 0
			BEGIN
				
				SELECT @ErrMsg =  @UserName + ': '+
					case @Language 
						when 'E' then 'Error updating auto positiontaking'
						when 'CS' then N'更新占成数不成功'
						when 'CT' then N'更新佔成數不成功'
						when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ '
						when 'J' then N'Error updating auto positiontaking'
						when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다.'
						else N'Error updating auto positiontaking'
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
	set mpositiontaking = b.mpositiontaking
	from CustSetting3rd as cs with (ROWLOCK, UPDLOCK)
		inner join custinfo ci(nolock) on cs.custid = ci.custid and ci.recommend = @custid and ci.roleid = 1
		inner join 
			(
							select 151 as sporttype, 31 as bettype, @isauto_v151mpositiontaking_31 as isautopositiontaking, @old_isauto_v151mpositiontaking_31 as oldisautopositiontaking, @v151mpositiontaking_31 as mpositiontaking
				union all	select 151 as sporttype, 32 as bettype, @isauto_v151mpositiontaking_32 as isautopositiontaking, @old_isauto_v151mpositiontaking_32 as oldisautopositiontaking, @v151mpositiontaking_32 as mpositiontaking
			) as b on b.bettype = cs.bettype and b.sporttype = cs.sporttype
	where b.isautopositiontaking = 0 and b.oldisautopositiontaking = 0  
END
IF @IsCopyPreset_41 = 1 
BEGIN
	update cs 
	set mpositiontaking = b.mpositiontaking
	from CustSetting3rd as cs with (ROWLOCK, UPDLOCK)
		inner join custinfo ci(nolock) on cs.custid = ci.custid and ci.recommend = @custid and ci.roleid = 1
		inner join 
			(
							select 151 as sporttype, 41 as bettype, @isauto_v151mpositiontaking_41 as isautopositiontaking, @old_isauto_v151mpositiontaking_41 as oldisautopositiontaking, @v151mpositiontaking_41 as mpositiontaking
				union all	select 151 as sporttype, 42 as bettype, @isauto_v151mpositiontaking_42 as isautopositiontaking, @old_isauto_v151mpositiontaking_42 as oldisautopositiontaking, @v151mpositiontaking_42 as mpositiontaking
			) as b on b.bettype = cs.bettype and b.sporttype = cs.sporttype
	where b.isautopositiontaking = 0 and b.oldisautopositiontaking = 0  
END

EXEC dbo.Acc_CustomerUpdAgentHR_MaxPositiontaking @recommend = @custid
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

Select @LogSPData ='<Acc_CustomerUpdAgentHR_PositionTaking><info SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(30)),space(1)) + '" ' +
'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" ' +
'Language="'+ coalesce(cast(@Language as varchar(2)),space(1)) + '" ' +
'IsCopyPreset_31="'+ coalesce(cast(@IsCopyPreset_31 as varchar(50)),space(1)) + '" ' +
'IsCopyPreset_41="'+ coalesce(cast(@IsCopyPreset_41 as varchar(50)),space(1)) + '" ' +
'Updallmembers="'+ coalesce(cast(@updateallmembers as varchar(50)),space(1)) + '" ' +
'newmpt="'+ coalesce(cast(@newmpositiontaking as varchar(50)),space(1)) + '" ' +
'IP="'+ coalesce(cast(@IP as varchar(15)),space(1)) + '" ' +
'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" ' +
'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(5000)),space(1)) + '" />' +

'<ag v151apt_31="'+ coalesce(cast(@v151apositiontaking_31 as varchar(50)),space(1)) + '" ' +
'v151apt_32="'+ coalesce(cast(@v151apositiontaking_32 as varchar(50)),space(1)) + '" ' +
'v151apt_41="'+ coalesce(cast(@v151apositiontaking_41 as varchar(50)),space(1)) + '" ' +
'v151apt_42="'+ coalesce(cast(@v151apositiontaking_42 as varchar(50)),space(1)) + '" />' +

'<m v151mpt_31="'+ coalesce(cast(@v151mpositiontaking_31 as varchar(50)),space(1)) + '" ' +
'v151mpt_32="'+ coalesce(cast(@v151mpositiontaking_32 as varchar(50)),space(1)) + '" ' +
'v151mpt_41="'+ coalesce(cast(@v151mpositiontaking_41 as varchar(50)),space(1)) + '" ' +
'v151mpt_42="'+ coalesce(cast(@v151mpositiontaking_42 as varchar(50)),space(1)) + '" />' +

'<aum a_v151mpt_31="'+ coalesce(cast(@auto_v151mpositiontaking_31 as varchar(50)),space(1)) + '" ' +
'a_v151mpt_32="'+ coalesce(cast(@auto_v151mpositiontaking_32 as varchar(50)),space(1)) + '" ' +
'a_v151mpt_41="'+ coalesce(cast(@auto_v151mpositiontaking_41 as varchar(50)),space(1)) + '" ' +
'a_v151mpt_42="'+ coalesce(cast(@auto_v151mpositiontaking_42 as varchar(50)),space(1)) + '" />' +

'<iam isa_v151mpt_31="'+ coalesce(cast(@isauto_v151mpositiontaking_31 as varchar(50)),space(1)) + '" ' +
'isa_v151mpt_32="'+ coalesce(cast(@isauto_v151mpositiontaking_32 as varchar(50)),space(1)) + '" ' +
'isa_v151mpt_41="'+ coalesce(cast(@isauto_v151mpositiontaking_41 as varchar(50)),space(1)) + '" ' +
'isa_v151mpt_42="'+ coalesce(cast(@isauto_v151mpositiontaking_42 as varchar(50)),space(1)) + '" /></Acc_CustomerUpdAgentHR_PositionTaking>'

--Log positiontaking
EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew 
	@UserID = @UserID,
	@CustID = @CustID,
	@ActionID = 420,
	@TrackingValue = @LogSPData
GO

GRANT EXECUTE ON [dbo].[Acc_CustomerUpdAgentHR_PositionTaking] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdAgentHR_PositionTaking] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdAgentHR_PositionTaking] TO vnteam
