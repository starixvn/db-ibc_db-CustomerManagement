ALTER PROCEDURE [dbo].[Acc_CustomerUpdAgentFI_PositionTaking]
	@custid int, --agentID
	@v201apositiontaking_2 smallmoney,
	@v201apositiontaking_3 smallmoney,
	@v201mpositiontaking_2 smallmoney,
	@v201mpositiontaking_3 smallmoney,
	@auto_v201mpositiontaking_2 smallmoney = 0,
	@auto_v201mpositiontaking_3 smallmoney = 0,
	@isauto_v201mpositiontaking_2 bit = 0,
	@isauto_v201mpositiontaking_3 bit = 0,

	@updateallmembers bit = 0,
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
Created: 20090415@Phuc
Task : Update FI's Agent Position Taking
DB: DB02.bodb02
Original: Acc_CustomerUpdEditCustomer_MAg

Revisions:
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
Set @maxpos = 0.5 --max pt for FI

Select @UserName = username, @mrecommend = mrecommend, @srecommend = srecommend 
from custinfo with (NOLOCK) 
where CustID = @CustID

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Check Param
--v201
if @v201apositiontaking_3  <0
	or @v201apositiontaking_3 + @v201mpositiontaking_3 > @maxpos
	or @v201mpositiontaking_3 <0
	or @v201mpositiontaking_3 > @maxpos
	
	or @v201apositiontaking_2  <0
	or @v201apositiontaking_2 + @v201mpositiontaking_2 > @maxpos
	or @v201mpositiontaking_2 <0
	or @v201mpositiontaking_2 > @maxpos
	
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

--check n3<=m2+a2<=l3 if i2 = 0, 
--a2<=l3 and um2+a2>=n3 if im2 = 1
select @ErrType = ''
select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Min: '+ cast((co.minpositiontaking) as varchar(10))+ '-Max: '+ cast((co.maxpositiontaking) as varchar(10))+ '<br>'
from CustOverride3rd as co with (NOLOCK) inner join
	(
 					select 2 as bettype, 201 as sporttype, @v201apositiontaking_2 as apositiontaking, 0 as alivepositiontaking, @v201mpositiontaking_2 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v201mpositiontaking_2 as isauto_mpositiontaking,  0 as isauto_mlivepositiontaking, @auto_v201mpositiontaking_2 as auto_mpositiontaking		
 		union all	select 3 as bettype, 201 as sporttype, @v201apositiontaking_3 as apositiontaking, 0 as alivepositiontaking, @v201mpositiontaking_3 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v201mpositiontaking_3 as isauto_mpositiontaking,  0 as isauto_mlivepositiontaking, @auto_v201mpositiontaking_3 as auto_mpositiontaking
	) as b on co.sporttype=b.sporttype and co.bettype = b.bettype
	inner join sports with (nolock) on b.sporttype = sports.sporttype
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
select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Min: '+ cast((co.minpositiontaking) as varchar(10))+ '-Max: '+ cast((co.maxpositiontaking) as varchar(10))+ '<br>'
from CustOverride3rd as co with (NOLOCK) inner join
	(
			 		select 2 as bettype, 201 as sporttype, @v201apositiontaking_2 as apositiontaking, 0 as alivepositiontaking, @v201mpositiontaking_2 as mpositiontaking, 0 as mlivepositiontaking
		union all	select 3 as bettype, 201 as sporttype, @v201apositiontaking_3 as apositiontaking, 0 as alivepositiontaking, @v201mpositiontaking_3 as mpositiontaking, 0 as mlivepositiontaking
	) as b on co.sporttype=b.sporttype and co.bettype = b.bettype
	inner join sports with (nolock) on b.sporttype = sports.sporttype
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
select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ cast((scs.apositiontaking) as varchar(10)) + '<br>'
from custinfo as c with (NOLOCK) inner join CustSetting3rd as scs with (NOLOCK) on c.srecommend = scs.custid inner join 
	(
					 	select 2 as bettype, 201 as sporttype, @v201apositiontaking_2 as apositiontaking, 0 as alivepositiontaking, @v201mpositiontaking_2 as mpositiontaking, 0 as mlivepositiontaking
		union all	 	select 3 as bettype, 201 as sporttype, @v201apositiontaking_3 as apositiontaking, 0 as alivepositiontaking, @v201mpositiontaking_3 as mpositiontaking, 0 as mlivepositiontaking
	) as b on scs.sporttype=b.sporttype and scs.bettype = b.bettype
	inner join sports with (nolock) on b.sporttype = sports.sporttype
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
	--v201
	@old_v201apositiontaking_2 smallmoney,
	@old_v201apositiontaking_3 smallmoney,
	
	--v201
	@old_v201mpositiontaking_2 smallmoney,
	@old_v201mpositiontaking_3 smallmoney
	
--v201
select @old_v201mpositiontaking_2 = mpositiontaking, @old_v201apositiontaking_2 = apositiontaking 
from CustSetting3rd with (NOLOCK) 
where custid = @custid and bettype=2 and sporttype=201

select @old_v201mpositiontaking_3 = mpositiontaking, @old_v201apositiontaking_3 = apositiontaking 
from CustSetting3rd with (NOLOCK) 
where custid = @custid and bettype=3 and sporttype=201

declare
	--v201
	@max_v201mapositiontaking_2 smallmoney,
	@max_v201mapositiontaking_3 smallmoney
	
--v201
select @max_v201mapositiontaking_2 =mpositiontaking 
from CustSetting3rd with (NOLOCK) 
where custid = @mrecommend and bettype=2 and sporttype=201

select @max_v201mapositiontaking_3 =mpositiontaking 
from CustSetting3rd with (NOLOCK) 
where custid = @mrecommend and bettype=3 and sporttype=201

--check m2+a2<=m3 - Vinh
select @ErrType = ''
select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ cast((b.max_mapositiontaking) as varchar(10)) + '<br>'
from
(
	--v201
			  select 2 as bettype, 201 as sporttype, @v201apositiontaking_2 as apositiontaking, @v201mpositiontaking_2 as mpositiontaking, @max_v201mapositiontaking_2 as max_mapositiontaking, 0 as alivepositiontaking, 0 as mlivepositiontaking, 0 as max_malivepositiontaking
	union all select 3 as bettype, 201 as sporttype, @v201apositiontaking_3 as apositiontaking, @v201mpositiontaking_3 as mpositiontaking, @max_v201mapositiontaking_3 as max_mapositiontaking, 0 as alivepositiontaking, 0 as mlivepositiontaking, 0 as max_malivepositiontaking

) as b
inner join sports with (nolock) on b.sporttype = sports.sporttype
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
select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ cast((case when max_mapositiontaking > co.maxpositiontaking then co.maxpositiontaking else max_mapositiontaking end) as varchar(10)) + '<br>'
from CustOverride3rd co (nolock) inner join 
(
	--v201
				select 2 as bettype, 201 as sporttype, @auto_v201mpositiontaking_2 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v201mpositiontaking_2 as isautopositiontaking, 0	as isautolivepositiontaking, @max_v201mapositiontaking_2 as max_mapositiontaking,0 as max_malivepositiontaking	
	union all   select 3 as bettype, 201 as sporttype, @auto_v201mpositiontaking_3 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v201mpositiontaking_3 as isautopositiontaking, 0	as isautolivepositiontaking, @max_v201mapositiontaking_3 as max_mapositiontaking,0 as max_malivepositiontaking	

) as b on b.sporttype = co.sporttype and b.bettype = co.bettype
inner join sports with (nolock) on b.sporttype = sports.sporttype
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
	apositiontaking = case bettype when 3 then @v201apositiontaking_3 when 2 then @v201apositiontaking_2 else apositiontaking end,
	mpositiontaking = case bettype when 3 then @v201mpositiontaking_3 when 2 then @v201mpositiontaking_2 else mpositiontaking end
where custid=@custid and sporttype = 201
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
	@old_auto_v201mpositiontaking_2 smallmoney,
	@old_auto_v201mpositiontaking_3 smallmoney,
	@old_isauto_v201mpositiontaking_2 bit,
	@old_isauto_v201mpositiontaking_3 bit
--------------------------------------------------------
--Get old Auto PT from Agent
select 	@old_auto_v201mpositiontaking_2	= autompositiontaking, @old_isauto_v201mpositiontaking_2	= isautompositiontaking	
from CustSetting3rd with (nolock) 
where custid = @custid and sporttype=201 and bettype= 2

select 	@old_auto_v201mpositiontaking_3	= autompositiontaking, @old_isauto_v201mpositiontaking_3	= isautompositiontaking
from CustSetting3rd with (nolock) 
where custid = @custid and sporttype=201	and bettype=	3

--v201
--Update Master Agent account
--For Financial
update CustSetting3rd with (ROWLOCK, UPDLOCK) set autompositiontaking = b.autopositiontaking, isautompositiontaking = b.isautopositiontaking
from CustSetting3rd as cs inner join 
		(
						select 2 as bettype, @auto_v201mpositiontaking_2 as autopositiontaking, @isauto_v201mpositiontaking_2 as isautopositiontaking
			union all	select 3 as bettype, @auto_v201mpositiontaking_3 as autopositiontaking, @isauto_v201mpositiontaking_3 as isautopositiontaking
		) as b on b.bettype = cs.bettype
where cs.custid = @custid and cs.sporttype=201
if @@Error <> 0
BEGIN
	
	SELECT @ErrMsg = @UserName + ': '+ 
		case @Language 
			when 'E' then 'Error updating auto positiontaking (for Finance)'
			when 'CS' then N'更新占成数不成功(于金融)'
			when 'CT' then N'更新佔成數不成功(於金融)'
			when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ (สำหรับการเงิน)'
			when 'J' then N'Error updating auto positiontaking (for Finance)'
			when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 (금융).'
			else N'Error updating auto positiontaking (for Finance)'
		end	
		,  @ErrCode=205
	return
END

---------------------------------
--Update Financial(201)
if (@auto_v201mpositiontaking_2 <> @old_auto_v201mpositiontaking_2 or @isauto_v201mpositiontaking_2 <> @old_isauto_v201mpositiontaking_2 ) 
BEGIN
	if @isauto_v201mpositiontaking_2 >0 --Use AUTO MPT
	BEGIN
		--m1=min(m3-a1,u2)
		select @maxpos = mpositiontaking from CustSetting3rd with (NOLOCK) where custid = @mrecommend and sporttype=201 and bettype = 2
		update cs
		set mpositiontaking = case when @maxpos - apositiontaking>@auto_v201mpositiontaking_2 then @auto_v201mpositiontaking_2 else @maxpos -apositiontaking end
		from CustSetting3rd as cs with (ROWLOCK, UPDLOCK)
		inner join custinfo as c with (NOLOCK) on cs.custid = c.custid
		where c.recommend = @custid and c.roleid = 1 and cs.bettype = 2 and cs.sporttype=201
		if @@Error <> 0
		BEGIN
			
			SELECT @ErrMsg =  @UserName + ': '+
					case @Language 
						when 'E' then 'Error updating auto positiontaking (for Finance)'
						when 'CS' then N'更新占成数不成功(于金融)'
						when 'CT' then N'更新佔成數不成功(於金融)'
						when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ (สำหรับการเงิน)'
						when 'J' then N'Error updating auto positiontaking (for Finance)'
						when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 (금융).'
						else N'Error updating auto positiontaking (for Finance)'
					end	
					,  @ErrCode=219
			return
		END
	END
	else if @isauto_v201mpositiontaking_2 <> @old_isauto_v201mpositiontaking_2 --Not use AUTO MPT
	BEGIN
		if @updateallmembers = 1 --all member
		BEGIN
			--m1=min(m2,@newmpositiontaking)
			update cs
			set mpositiontaking = case when acs.mpositiontaking<@newmpositiontaking then acs.mpositiontaking else @newmpositiontaking end
			from CustSetting3rd as cs with (ROWLOCK, UPDLOCK)
			inner join custinfo as c with (NOLOCK) on cs.custid = c.custid
			inner join CustSetting3rd as acs with (NOLOCK) on acs.custid = @custid and cs.sporttype=acs.sporttype and cs.bettype=acs.bettype
			where c.recommend = @custid and c.roleid = 1 and cs.bettype = 2 and cs.sporttype=201
			if @@Error <> 0
			BEGIN
				
				SELECT @ErrMsg =  @UserName + ': '+
					case @Language 
						when 'E' then 'Error updating auto positiontaking (for Finance)'
						when 'CS' then N'更新占成数不成功(于金融)'
						when 'CT' then N'更新佔成數不成功(於金融)'
						when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ (สำหรับการเงิน)'
						when 'J' then N'Error updating auto positiontaking (for Finance)'
						when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 (금융).'
						else N'Error updating auto positiontaking (for Finance)'
					end	
					,  @ErrCode=220
				return
			END
		END
	END
END	

if (@auto_v201mpositiontaking_3 <> @old_auto_v201mpositiontaking_3 or @isauto_v201mpositiontaking_3 <> @old_isauto_v201mpositiontaking_3 ) 
BEGIN
	if @isauto_v201mpositiontaking_3 >0 --Use AUTO MPT
	BEGIN
		--m1=min(m3-a1,u2)
		select @maxpos = mpositiontaking from CustSetting3rd with (NOLOCK) where custid = @mrecommend and sporttype=201 and bettype = 3
		update cs
		set mpositiontaking = case when @maxpos - apositiontaking>@auto_v201mpositiontaking_3 then @auto_v201mpositiontaking_3 else @maxpos -apositiontaking end
		from CustSetting3rd as cs with (ROWLOCK, UPDLOCK)
		inner join custinfo as c with (NOLOCK) on cs.custid = c.custid
		where c.recommend = @custid and c.roleid = 1 and cs.bettype = 3 and cs.sporttype=201
		if @@Error <> 0
		BEGIN
			
			SELECT @ErrMsg =  @UserName + ': '+
					case @Language 
						when 'E' then 'Error updating auto positiontaking (for Finance)'
						when 'CS' then N'更新占成数不成功(于金融)'
						when 'CT' then N'更新佔成數不成功(於金融)'
						when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ (สำหรับการเงิน)'
						when 'J' then N'Error updating auto positiontaking (for Finance)'
						when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 (금융).'
						else N'Error updating auto positiontaking (for Finance)'
					end	
					,  @ErrCode=219
			return
		END
	END
	else if @isauto_v201mpositiontaking_3 <> @old_isauto_v201mpositiontaking_3 --Not use AUTO MPT
	BEGIN
		if @updateallmembers = 1 --all member
		BEGIN
			--m1=min(m2,@newmpositiontaking)
			update cs
				set mpositiontaking = case when acs.mpositiontaking<@newmpositiontaking then acs.mpositiontaking else @newmpositiontaking end
			from CustSetting3rd as cs with (ROWLOCK, UPDLOCK)
			inner join custinfo as c with (NOLOCK) on cs.custid = c.custid
			inner join CustSetting3rd as acs with (NOLOCK) on acs.custid = @custid and cs.sporttype=acs.sporttype and cs.bettype=acs.bettype
			where c.recommend = @custid and c.roleid = 1 and cs.bettype = 3 and cs.sporttype=201
			if @@Error <> 0
			BEGIN
				
				SELECT @ErrMsg =  @UserName + ': '+
					case @Language 
						when 'E' then 'Error updating auto positiontaking (for Finance)'
						when 'CS' then N'更新占成数不成功(于金融)'
						when 'CT' then N'更新佔成數不成功(於金融)'
						when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์ (สำหรับการเงิน)'
						when 'J' then N'Error updating auto positiontaking (for Finance)'
						when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다 (금융).'
						else N'Error updating auto positiontaking (for Finance)'
					end	
					,  @ErrCode=220
				return
			END
		END
	END
END	

---------------------------------


EXEC dbo.Acc_CustomerUpdAgentFI_MaxPositiontaking @recommend = @custid
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

Select @LogSPData ='<Acc_CustomerUpdAgentFI_PositionTaking><info SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(30)),space(1)) + '" ' +
'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" ' +
'Language="'+ coalesce(cast(@Language as varchar(2)),space(1)) + '" ' +
'IP="'+ coalesce(cast(@IP as varchar(15)),space(1)) + '" ' +
'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" ' +
'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(5000)),space(1)) + '" />' +

'<ag v201apt_2="'+ coalesce(cast(@v201apositiontaking_2 as varchar(50)),space(1)) + '" ' +
'v201apt_3="'+ coalesce(cast(@v201apositiontaking_3 as varchar(50)),space(1)) + '" />' +

'<m v201mpt_2="'+ coalesce(cast(@v201mpositiontaking_2 as varchar(50)),space(1)) + '" ' +
'v201mpt_3="'+ coalesce(cast(@v201mpositiontaking_3 as varchar(50)),space(1)) + '" />' +

--auto v1
'<aum a_v201mpt_2="'+ coalesce(cast(@auto_v201mpositiontaking_2 as varchar(50)),space(1)) + '" ' +
'a_v201mpt_3="'+ coalesce(cast(@auto_v201mpositiontaking_3 as varchar(50)),space(1)) + '" />' +

--isauto v1
'<iam isa_v201mpt_2="'+ coalesce(cast(@isauto_v201mpositiontaking_2 as varchar(50)),space(1)) + '" ' +
'isa_v201mpt_3="'+ coalesce(cast(@isauto_v201mpositiontaking_3 as varchar(50)),space(1)) + '" /></Acc_CustomerUpdAgentFI_PositionTaking>'

--Log positiontaking
EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew 
	@UserID = @UserID,
	@CustID = @CustID,
	@ActionID = 416,
	@TrackingValue = @LogSPData
GO

GRANT EXECUTE ON [dbo].[Acc_CustomerUpdAgentFI_PositionTaking] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdAgentFI_PositionTaking] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdAgentFI_PositionTaking] TO vnteam
