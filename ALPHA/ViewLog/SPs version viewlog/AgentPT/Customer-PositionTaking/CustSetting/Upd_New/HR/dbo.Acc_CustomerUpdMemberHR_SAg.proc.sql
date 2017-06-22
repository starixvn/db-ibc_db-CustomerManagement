ALTER PROCEDURE [dbo].[Acc_CustomerUpdMemberHR_SAg] 
	@CustID int,--memberid
	@UserID int,

	@v151spositiontaking_31 smallmoney OUTPUT,
	@v151spositiontaking_32 smallmoney OUTPUT,
	@v151spositiontaking_41 smallmoney OUTPUT,
	@v151spositiontaking_42 smallmoney OUTPUT,

	@auto_v151spositiontaking_31 smallmoney = 0,
	@auto_v151spositiontaking_32 smallmoney = 0,
	@auto_v151spositiontaking_41 smallmoney = 0,
	@auto_v151spositiontaking_42 smallmoney = 0,

	@isauto_v151spositiontaking_31 bit = 0,
	@isauto_v151spositiontaking_32 bit = 0,
	@isauto_v151spositiontaking_41 bit = 0,
	@isauto_v151spositiontaking_42 bit = 0,

	@isauto_v151smpositiontaking_31 bit = 0,--i3
	@isauto_v151smpositiontaking_32 bit = 0,
	@isauto_v151smpositiontaking_41 bit = 0,
	@isauto_v151smpositiontaking_42 bit = 0,

	@language varchar(2) = 'E',
	@SubAccID int = 0, --Sub-AccountID
	@IP varchar(15)='',
	@Username varchar(30) = '' OUTPUT,
	@ErrCode varchar(300) = '' OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS
--@Source Control
/*
Created: 20090520@Phuc
Task : Super edits Member(HR)
DB: DB02.bodb02
Original: Acc_CustomerUpdSuper_Member

Revisions:
	- 20090717@Phuc: enrich error message.(-101: general info, -102: closed, -103: suspended, 
						-104: credit, -105: commission, -106: min/max bet, -107: positiontaking
						-108: disable FI, -109: disableHR)
	- 20090723@Phuc: Write log subaccname instead of subaccid.
	- 20090801@Shifu: check disabled user
	- 20090818@Phuc: check page access and check upline closed first(call Age_CustSubCheckPageAccess)
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
Declare @ErrCode_cur int, @ErrMsg_cur nvarchar(4000), @roleid tinyint
Select @ErrCode_cur = 0, @ErrMsg_cur = '', @ErrCode = '', @ErrMsg = ''

EXEC DB052.bodb02.dbo.Age_CustomerSelCheckBelonging 
	@SessionCustID = @Userid, 
	@Custid = @custid,
	@Username = @Username OUTPUT,
	@roleid = @roleid OUTPUT
	if (@roleid = 0) return

--Check disable user
EXEC DB052.bodb02.dbo.Acc_CustomerSelCheckEnable @custid = @custid, @ErrCode=@ErrCode_Cur output,@ErrMsg=@ErrMsg_Cur output
IF @ErrCode_Cur > 0
BEGIN
	select @ErrCode = @ErrCode + cast(@ErrCode_cur as varchar(300)) + char(7), 
			@ErrMsg = @ErrMsg + @ErrMsg_Cur + char(7)
	return
END
--end 
declare 
	@v151mpositiontaking_31 smallmoney,
	@v151mpositiontaking_32 smallmoney,
	@v151mpositiontaking_41 smallmoney,
	@v151mpositiontaking_42 smallmoney,

	@old_v151spositiontaking_31 smallmoney,
	@old_v151spositiontaking_32 smallmoney,
	@old_v151spositiontaking_41 smallmoney,
	@old_v151spositiontaking_42 smallmoney,

	@mrecommend int,
	@recommend int,
	@srecommend int,

	@v151apositiontaking_31 smallmoney,
	@v151apositiontaking_32 smallmoney,
	@v151apositiontaking_41 smallmoney,
	@v151apositiontaking_42 smallmoney,

	@v151spositiontaking_31_max smallmoney,
	@v151spositiontaking_32_max smallmoney,
	@v151spositiontaking_41_max smallmoney,
	@v151spositiontaking_42_max smallmoney,

	@old_auto_v151spositiontaking_31 smallmoney ,
	@old_auto_v151spositiontaking_32 smallmoney ,
	@old_auto_v151spositiontaking_41 smallmoney ,
	@old_auto_v151spositiontaking_42 smallmoney ,

	@old_isauto_v151spositiontaking_31 bit ,
	@old_isauto_v151spositiontaking_32 bit ,	
	@old_isauto_v151spositiontaking_41 bit ,
	@old_isauto_v151spositiontaking_42 bit 	

declare @ErrType varchar(1000), @maxpos smallmoney


select @srecommend = srecommend, @mrecommend = mrecommend, @recommend = recommend, @username = username from customer with (NOLOCK) where custid = @custid

set @maxpos = 0.5 
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Check param
declare @IsValid bit
Select @isvalid = 1
if 
	@v151spositiontaking_31 <0
	or @v151spositiontaking_32 <0
	or @v151spositiontaking_41 <0
	or @v151spositiontaking_42 <0
	
	or @v151spositiontaking_31 > @maxpos
	or @v151spositiontaking_32 > @maxpos
	or @v151spositiontaking_41 > @maxpos
	or @v151spositiontaking_42 > @maxpos
BEGIN
	select @isvalid = 0, @ErrCode_cur = 1
	Select @ErrMsg_cur = 	@UserName + ': '+
		case @Language 
						when 'E' then 'Wrong position taking.'
						when 'CS' then N'占成数不正确.'
						when 'CT' then N'佔成數不正確.'
						when 'TH' then N'การกำหนดไม่ถูกต้อง.'
						when 'J' then N'Wrong position taking.'
						when 'KO' then N'거래 조건이 잘못 되었습니다.'
						else N'Wrong position taking.'
				end
	SELECT  @ErrCode = @ErrCode + cast(@ErrCode_cur as varchar(300)) + char(7), 
			@ErrMsg = @ErrMsg + @ErrMsg_Cur + char(7)		
	return
END



--Check Old_PT <> New_PT
select @v151apositiontaking_31 = apositiontaking, @v151mpositiontaking_31 = mpositiontaking, @old_v151spositiontaking_31 = spositiontaking, @old_auto_v151spositiontaking_31 = autopositiontaking, @old_isauto_v151spositiontaking_31 = isautopositiontaking from CustSetting3rd with (NOLOCK) where custid = @custid and bettype=31 and sporttype=151
select @v151apositiontaking_32 = apositiontaking, @v151mpositiontaking_32 = mpositiontaking, @old_v151spositiontaking_32 = spositiontaking, @old_auto_v151spositiontaking_32 = autopositiontaking, @old_isauto_v151spositiontaking_32 = isautopositiontaking from CustSetting3rd with (NOLOCK) where custid = @custid and bettype=32 and sporttype=151
select @v151apositiontaking_41 = apositiontaking, @v151mpositiontaking_41 = mpositiontaking, @old_v151spositiontaking_41 = spositiontaking, @old_auto_v151spositiontaking_41 = autopositiontaking, @old_isauto_v151spositiontaking_41 = isautopositiontaking from CustSetting3rd with (NOLOCK) where custid = @custid and bettype=41 and sporttype=151
select @v151apositiontaking_42 = apositiontaking, @v151mpositiontaking_42 = mpositiontaking, @old_v151spositiontaking_42 = spositiontaking, @old_auto_v151spositiontaking_42 = autopositiontaking, @old_isauto_v151spositiontaking_42 = isautopositiontaking from CustSetting3rd with (NOLOCK) where custid = @custid and bettype=42 and sporttype=151

IF @v151spositiontaking_31 = @old_v151spositiontaking_31 AND
	@v151spositiontaking_32 = @old_v151spositiontaking_32 AND
	@v151spositiontaking_41 = @old_v151spositiontaking_41 AND
	@v151spositiontaking_42 = @old_v151spositiontaking_42 AND
	
	@auto_v151spositiontaking_31 = @old_auto_v151spositiontaking_31 AND
	@auto_v151spositiontaking_32 = @old_auto_v151spositiontaking_32 AND
	@auto_v151spositiontaking_41 = @old_auto_v151spositiontaking_41 AND
	@auto_v151spositiontaking_42 = @old_auto_v151spositiontaking_42 AND
	
	@isauto_v151spositiontaking_31 = @old_isauto_v151spositiontaking_31 AND
	@isauto_v151spositiontaking_32 = @old_isauto_v151spositiontaking_32 AND
	@isauto_v151spositiontaking_41 = @old_isauto_v151spositiontaking_41 AND
	@isauto_v151spositiontaking_42 = @old_isauto_v151spositiontaking_42 
BEGIN
	Select @ErrCode = @ErrCode + '-107'+char(7), @ErrMsg = @ErrMsg + char(7)
	return
END 


	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + ', '
	from CustOverride3rd as co with (NOLOCK) inner join
(
					select 151 as sporttype, 31 as bettype, @auto_v151spositiontaking_31 as autopositiontaking, @isauto_v151spositiontaking_31 as isautopositiontaking
	union all		select 151 as sporttype, 32 as bettype, @auto_v151spositiontaking_32 as autopositiontaking, @isauto_v151spositiontaking_32 as isautopositiontaking	
	union all		select 151 as sporttype, 41 as bettype, @auto_v151spositiontaking_41 as autopositiontaking, @isauto_v151spositiontaking_41 as isautopositiontaking
	union all		select 151 as sporttype, 42 as bettype, @auto_v151spositiontaking_42 as autopositiontaking, @isauto_v151spositiontaking_42 as isautopositiontaking	
) as b on co.sporttype=b.sporttype and co.bettype=b.bettype
	inner join sports with (nolock) on b.sporttype = sports.sporttype
	inner join bettype with (nolock) on b.bettype = bettype.typeid

where co.custid = @srecommend and ((b.isautopositiontaking>0 and b.autopositiontaking>co.maxpositiontaking))


if @ErrType <>''
BEGIN
	select @isvalid = 0, @ErrCode_cur = 2
	Select @ErrMsg_cur = 	@UserName + ': '+
		case @Language 
						when 'E' then 'Wrong position taking (min/max set by company) ('+@ErrType+').'
						when 'CS' then N'占成数不正确(公司设给最低/高占成) ('+@ErrType+').'
						when 'CT' then N'佔成數不正確(公司設給最低/高佔成) ('+@ErrType+').'
						when 'TH' then N'การกำหนดไม่ถูกต้อง (สูงสุด หรือ ต่ำสุด อ้างอิงจากข้อมูลบริษัท) ('+@ErrType+').'
						when 'J' then N'Wrong position taking (min/max set by company) ('+@ErrType+').'
						when 'KO' then N'거래 조건이 잘못 되었습니다 (ibc가 설정한 최소값/최대값) ('+@ErrType+').'
						else N'Wrong position taking (min/max set by company) ('+@ErrType+').'
				end
	Select  @ErrCode = @ErrCode + cast(@ErrCode_cur as varchar(300)) + char(7), 
			@ErrMsg = @ErrMsg + @ErrMsg_Cur + char(7)
	return
END
-- End check parameter
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ cast((cs.spositiontaking) as varchar(10)) + '<br>'
	from CustSetting3rd as cs with (NOLOCK) inner join
		(
						select 31 as bettype, 151 as sporttype, @auto_v151spositiontaking_31 as autopositiontaking
			union all 	select 32 as bettype, 151 as sporttype, @auto_v151spositiontaking_32 as autopositiontaking
			union all	select 41 as bettype, 151 as sporttype, @auto_v151spositiontaking_41 as autopositiontaking
			union all 	select 42 as bettype, 151 as sporttype, @auto_v151spositiontaking_42 as autopositiontaking
		) as b on cs.sporttype=b.sporttype and cs.bettype=b.bettype
	inner join sports with (nolock) on b.sporttype = sports.sporttype
	inner join bettype with (nolock) on b.bettype = bettype.typeid
	where cs.custid = @srecommend
		and 
		((cs.spositiontaking<b.autopositiontaking))
		
	if @ErrType <>''
	BEGIN
		Select @ErrMsg_cur =	@UserName + ': '+
							case @Language 
								when 'E' then 'Wrong auto position taking.<br>'+@ErrType
								when 'CS' then N'自动占成数不正确.<br>'+@ErrType
								when 'CT' then N'自動佔成數不正確.<br>'+@ErrType
								when 'TH' then N'การปรับยอดเงินที่ผิดพลาดอันเนื่องมาจากระบบ.<br>'+@ErrType
								when 'J' then N'Wrong auto position taking.<br>'+@ErrType
								when 'KO' then N'자동 거래조건이 잘못 되었습니다.<br>'+@ErrType
								else N'Wrong auto position taking.<br>'+@ErrType
							end	, @ErrCode_cur = 223						
		Select  @ErrCode = @ErrCode + cast(@ErrCode_cur as varchar(300)) + char(7), 
				@ErrMsg = @ErrMsg + @ErrMsg_Cur + char(7)
		return
	END
	
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ cast((cs.spositiontaking) as varchar(10)) + '<br>'
	from CustSetting3rd as cs with (NOLOCK) inner join
		(
						select 31 as bettype, 151 as sporttype, @v151spositiontaking_31 as positiontaking
			union all 	select 32 as bettype, 151 as sporttype, @v151spositiontaking_32 as positiontaking
			union all	select 41 as bettype, 151 as sporttype, @v151spositiontaking_41 as positiontaking
			union all 	select 42 as bettype, 151 as sporttype, @v151spositiontaking_42 as positiontaking
		) as b on cs.sporttype=b.sporttype and cs.bettype=b.bettype
		inner join sports with (nolock) on b.sporttype = sports.sporttype
		inner join bettype with (nolock) on b.bettype = bettype.typeid
	where cs.custid = @srecommend
		and 
		((cs.spositiontaking<b.positiontaking))
		
	if @ErrType <>''
	BEGIN
		Select @ErrMsg_cur =	@UserName + ': '+
							case @Language 
								when 'E' then 'Wrong  position taking.<br>'+@ErrType
								when 'CS' then N'占成数不正确.<br>'+@ErrType
								when 'CT' then N'佔成數不正確.<br>'+@ErrType
								when 'TH' then N'การกำหนดไม่ถูกต้อง.<br>'+@ErrType
								when 'J' then N'Wrong  position taking.<br>'+@ErrType
								when 'KO' then N'거래 조건이 잘못 되었습니다.<br>'+@ErrType
								else N'Wrong  position taking.<br>'+@ErrType
							end, @ErrCode_cur = 5
		Select @ErrCode = @ErrCode + cast(@ErrCode_cur as varchar(300)) + char(7), 
				@ErrMsg = @ErrMsg + @ErrMsg_Cur + char(7)
		return
	END


select @v151spositiontaking_31_max = spositiontaking from CustSetting3rd with (NOLOCK) where custid = @srecommend and bettype=31 and sporttype=151
select @v151spositiontaking_32_max = spositiontaking from CustSetting3rd with (NOLOCK) where custid = @srecommend and bettype=32 and sporttype=151
select @v151spositiontaking_41_max = spositiontaking from CustSetting3rd with (NOLOCK) where custid = @srecommend and bettype=41 and sporttype=151
select @v151spositiontaking_42_max = spositiontaking from CustSetting3rd with (NOLOCK) where custid = @srecommend and bettype=42 and sporttype=151

select 
	@v151spositiontaking_31 = case when @v151mpositiontaking_31+@v151spositiontaking_31+@v151apositiontaking_31>@v151spositiontaking_31_max then @v151spositiontaking_31_max-@v151mpositiontaking_31-@v151apositiontaking_31 else @v151spositiontaking_31 end,
	@v151spositiontaking_32 = case when @v151mpositiontaking_32+@v151spositiontaking_32+@v151apositiontaking_32>@v151spositiontaking_32_max then @v151spositiontaking_32_max-@v151mpositiontaking_32-@v151apositiontaking_32 else @v151spositiontaking_32 end,
	@v151spositiontaking_41 = case when @v151mpositiontaking_41+@v151spositiontaking_41+@v151apositiontaking_41>@v151spositiontaking_41_max then @v151spositiontaking_41_max-@v151mpositiontaking_41-@v151apositiontaking_41 else @v151spositiontaking_41 end,
	@v151spositiontaking_42 = case when @v151mpositiontaking_42+@v151spositiontaking_42+@v151apositiontaking_42>@v151spositiontaking_42_max then @v151spositiontaking_42_max-@v151mpositiontaking_42-@v151apositiontaking_42 else @v151spositiontaking_42 end

select 
	@v151spositiontaking_31 = case when @v151spositiontaking_31<0 then 0 else @v151spositiontaking_31 end,
	@v151spositiontaking_32 = case when @v151spositiontaking_32<0 then 0 else @v151spositiontaking_32 end,
	@v151spositiontaking_41 = case when @v151spositiontaking_41<0 then 0 else @v151spositiontaking_41 end,
	@v151spositiontaking_42 = case when @v151spositiontaking_42<0 then 0 else @v151spositiontaking_42 end


--don't update s1 for member under master was set i3=1(normal)
update cs with (ROWLOCK, UPDLOCK)
set
	cs.spositiontaking = case cs.bettype when 31 then @v151spositiontaking_31 when 32 then @v151spositiontaking_32 when 41 then @v151spositiontaking_41 when 42 then @v151spositiontaking_42 else cs.spositiontaking end
from CustSetting3rd cs inner join customer c (nolock) on cs.custid = c.custid
	inner join CustSetting3rd scs (nolock) on scs.custid = c.mrecommend and cs.sporttype = scs.sporttype and cs.bettype = scs.bettype
where cs.custid=@custid and cs.sporttype = 151 and c.roleid = 1 and scs.isautopositiontaking = 0

--Update auto PT
update CustSetting3rd with (ROWLOCK, UPDLOCK) 
	set autopositiontaking = b.autopositiontaking, isautopositiontaking = b.isautopositiontaking
from CustSetting3rd as cs inner join 
		(
						select 31 as bettype, 151 as sporttype, @auto_v151spositiontaking_31 as autopositiontaking, @isauto_v151spositiontaking_31 as isautopositiontaking
			union all 	select 32 as bettype, 151 as sporttype, @auto_v151spositiontaking_32 as autopositiontaking, @isauto_v151spositiontaking_32 as isautopositiontaking	
			union all	select 41 as bettype, 151 as sporttype, @auto_v151spositiontaking_41 as autopositiontaking, @isauto_v151spositiontaking_41 as isautopositiontaking
			union all 	select 42 as bettype, 151 as sporttype, @auto_v151spositiontaking_42 as autopositiontaking, @isauto_v151spositiontaking_42 as isautopositiontaking	
		) as b on b.bettype = cs.bettype and b.sporttype = cs.sporttype
where cs.custid = @custid
if @@Error <> 0
BEGIN
	SELECT @ErrMsg_cur =  @UserName + ': '+
	case @Language 
		when 'E' then 'Error updating auto positiontaking'
		when 'CS' then N'更新占成数不成功'
		when 'CT' then N'更新佔成數不成功'
		when 'TH' then N'การปรับยอดจำนวนเงินในการเล่นไม่สมบูรณ์'
		when 'J' then N'Error updating auto positiontaking'
		when 'KO' then N'자동 거래 조건 업데이트에 에러가 발생 했습니다.'
		else N'Error updating auto positiontaking'
	end, @ErrCode_cur = 11
	SELECT  @ErrCode = @ErrCode + cast(@ErrCode_cur as varchar(300)) + char(7), 
			@ErrMsg = @ErrMsg + @ErrMsg_Cur + char(7)
	return
END

EXEC dbo.Acc_CustomerUpdMemberHR_MinMaxPositiontaking @custid = @custid, @recommend = @recommend, @mrecommend = @mrecommend, @srecommend = @srecommend

Declare @LogSPData varchar(5000)

Select @LogSPData = '<Acc_CustomerUpdMemberHR_SAg><info custid="'+ COALESCE(CAST(@CustID AS VARCHAR(50)),SPACE(1)) + '" ' +
'UserID="'+ COALESCE(CAST(@UserID AS VARCHAR(50)),SPACE(1)) + '" ' +
'Language="'+ COALESCE(CAST(@Language AS VARCHAR(2)),SPACE(1)) + '" ' +
'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(30)),space(1)) + '" ' +
'IP="'+ COALESCE(CAST(@IP AS VARCHAR(15)),SPACE(1)) + '" ' +
'ErrCode="'+ COALESCE(CAST(@ErrCode AS VARCHAR(50)),SPACE(1)) + '" ' +
'ErrMsg="'+ COALESCE(CAST(@ErrMsg AS VARCHAR(5000)),SPACE(1)) + '" />' +

'<s v151spt_31="'+ coalesce(cast(@v151spositiontaking_31 as varchar(50)),space(1)) + '" ' +
'v151spt_32="'+ coalesce(cast(@v151spositiontaking_32 as varchar(50)),space(1)) + '" ' +
'v151spt_41="'+ coalesce(cast(@v151spositiontaking_41 as varchar(50)),space(1)) + '" ' +
'v151spt_42="'+ coalesce(cast(@v151spositiontaking_42 as varchar(50)),space(1)) + '" />' +

'<a a_v151spt_31="'+ coalesce(cast(@auto_v151spositiontaking_31 as varchar(50)),space(1)) + '" ' +
'a_v151spt_32="'+ coalesce(cast(@auto_v151spositiontaking_32 as varchar(50)),space(1)) + '" ' +
'a_v151spt_41="'+ coalesce(cast(@auto_v151spositiontaking_41 as varchar(50)),space(1)) + '" ' +
'a_v151spt_42="'+ coalesce(cast(@auto_v151spositiontaking_42 as varchar(50)),space(1)) + '" />' +

'<ia isa_v151spt_31="'+ coalesce(cast(@isauto_v151spositiontaking_31 as varchar(50)),space(1)) + '" ' +
'isa_v151spt_32="'+ coalesce(cast(@isauto_v151spositiontaking_32 as varchar(50)),space(1)) + '" ' +
'isa_v151spt_41="'+ coalesce(cast(@isauto_v151spositiontaking_41 as varchar(50)),space(1)) + '" ' +
'isa_v151spt_42="'+ coalesce(cast(@isauto_v151spositiontaking_42 as varchar(50)),space(1)) + '" />' +

'<isau isa_v151smpt_31="'+ coalesce(cast(@isauto_v151smpositiontaking_31 as varchar(50)),space(1)) + '" ' +
'isa_v151smpt_32="'+ coalesce(cast(@isauto_v151smpositiontaking_32 as varchar(50)),space(1)) + '" ' +
'isa_v151smpt_41="'+ coalesce(cast(@isauto_v151smpositiontaking_41 as varchar(50)),space(1)) + '" ' +
'isa_v151smpt_42="'+ coalesce(cast(@isauto_v151smpositiontaking_42 as varchar(50)),space(1)) + '" /></Acc_CustomerUpdMemberHR_SAg>'

Select @ErrCode = @ErrCode + '-107'+char(7), @ErrMsg = @ErrMsg + char(7)
	
--Log positiontaking
EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew 
	@UserID = @UserID,
	@CustID = @CustID,
	@ActionID = 406,
	@TrackingValue = @LogSPData
	
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdMemberHR_SAg] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdMemberHR_SAg] TO [bodbExtAccNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdMemberHR_SAg] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdMemberHR_SAg] TO [vnteam]
