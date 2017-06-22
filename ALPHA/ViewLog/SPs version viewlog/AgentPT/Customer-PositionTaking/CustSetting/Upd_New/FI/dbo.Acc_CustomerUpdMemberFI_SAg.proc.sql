ALTER PROCEDURE [dbo].[Acc_CustomerUpdMemberFI_SAg] 
	@CustID int,--memberid
	@DisabledFI bit = 0,
	--v201
	@v201spositiontaking_2 smallmoney OUTPUT,
	@v201spositiontaking_3 smallmoney OUTPUT,

	@UserID int,
	
	--v201
	@auto_v201spositiontaking_2 smallmoney = 0,
	@auto_v201spositiontaking_3 smallmoney = 0,

	--v201
	@isauto_v201spositiontaking_2 bit = 0,
	@isauto_v201spositiontaking_3 bit = 0,

	--v201
	@isauto_v201smpositiontaking_2 bit = 0,
	@isauto_v201smpositiontaking_3 bit = 0,

	@language varchar(2) = 'E',
	@SubAccID int = 0, --Sub-AccountID
	@IP varchar(15)='',
	@Username varchar(30) = '' OUTPUT,
	@ErrCode varchar(300) = '' OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS
--@Source Control
/*
Created: 20090415@Phuc
Task : Super edits Member(FI)
DB: DB02.bodb02
Original: Acc_CustomerUpdSuper_Member

Revisions:
	- 20090717@Phuc: Enrich error message.(-101: general info, -102: closed, -103: suspended, 
						-104: credit, -105: commission, -106: min/max bet, -107: positiontaking
						-108: disable FI, -109: disableHR)
	- 20090723@Phuc: Write log subaccname instead of subaccid.
	- 20090801@Shifu: check disabled user
	- 20090818@Phuc: check page access and check upline closed first(call Age_CustSubCheckPageAccess)
	- 20090917@Phuc: write log into DBLOG.
	- 20091201@Kiwi: Move custsetting & custoverride to the separated tables (CustSetting3rd & CustOverride3rd).
	- 20100112@Kiwi: amend to write log in xml format.
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
	@Username = @Username OUTPUT,
	@Custid = @custid,
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
	--v201
	@v201mpositiontaking_2 smallmoney,
	@v201mpositiontaking_3 smallmoney,

	--v201
	@old_v201spositiontaking_2 smallmoney,
	@old_v201spositiontaking_3 smallmoney,

	@mrecommend int,
	@recommend int,
	@srecommend int,

	--v201
	@v201apositiontaking_2 smallmoney,
	@v201apositiontaking_3 smallmoney,

	--v201
	@v201spositiontaking_2_max smallmoney,
	@v201spositiontaking_3_max smallmoney,

	--v201
	@old_auto_v201spositiontaking_2 smallmoney ,
	@old_auto_v201spositiontaking_3 smallmoney ,

	--v201
	@old_isauto_v201spositiontaking_2 bit ,
	@old_isauto_v201spositiontaking_3 bit 	
declare @ErrType varchar(1000), @maxpos smallmoney


select @DisabledFI = isnull(@DisabledFI,0) 
select @srecommend = srecommend, @mrecommend = mrecommend, @recommend = recommend, @username = username from custinfo with (NOLOCK) where custid = @custid

set @maxpos = 0.5 
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Check param
declare @IsValid bit
Select @isvalid = 1
if 
	--v201
	@v201spositiontaking_2 <0
	or @v201spositiontaking_3 <0
	--v201
	or @v201spositiontaking_2 > @maxpos
	or @v201spositiontaking_3 > @maxpos
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
--v201
select @v201apositiontaking_2 = apositiontaking, @v201mpositiontaking_2 = mpositiontaking, @old_v201spositiontaking_2 = spositiontaking, @old_auto_v201spositiontaking_2 = autopositiontaking, @old_isauto_v201spositiontaking_2 = isautopositiontaking from CustSetting3rd with (NOLOCK) where custid = @custid and bettype=2 and sporttype=201
select @v201apositiontaking_3 = apositiontaking, @v201mpositiontaking_3 = mpositiontaking, @old_v201spositiontaking_3 = spositiontaking, @old_auto_v201spositiontaking_3 = autopositiontaking, @old_isauto_v201spositiontaking_3 = isautopositiontaking from CustSetting3rd with (NOLOCK) where custid = @custid and bettype=3 and sporttype=201

IF @v201spositiontaking_2 = @old_v201spositiontaking_2 AND
	@v201spositiontaking_3 = @old_v201spositiontaking_3 AND
	--v201
	@auto_v201spositiontaking_2 = @old_auto_v201spositiontaking_2 AND
	@auto_v201spositiontaking_3 = @old_auto_v201spositiontaking_3 AND
	--v201
	@isauto_v201spositiontaking_2 = @old_isauto_v201spositiontaking_2 AND
	@isauto_v201spositiontaking_3 = @old_isauto_v201spositiontaking_3 
BEGIN
	Select @ErrCode = @ErrCode + '-107'+char(7), @ErrMsg = @ErrMsg + char(7)
	return
END 


	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + ', '
	from CustOverride3rd as co with (NOLOCK) inner join
(
	--v201
					select 201 as sporttype, 2 as bettype, @auto_v201spositiontaking_2 as autopositiontaking, @isauto_v201spositiontaking_2 as isautopositiontaking
	union all		select 201 as sporttype, 3 as bettype, @auto_v201spositiontaking_3 as autopositiontaking, @isauto_v201spositiontaking_3 as isautopositiontaking
) as b on co.sporttype=b.sporttype and co.bettype=b.bettype
	inner join sports with (nolock) on b.sporttype = sports.sporttype
	inner join bettype with (nolock) on b.bettype = bettype.typeid

where co.custid = @srecommend and (b.isautopositiontaking>0 and b.autopositiontaking>co.maxpositiontaking)


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
	SELECT  @ErrCode = @ErrCode + cast(@ErrCode_cur as varchar(300)) + char(7), 
			@ErrMsg = @ErrMsg + @ErrMsg_Cur + char(7)
	return
END
-- End check parameter
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ cast((cs.spositiontaking) as varchar(10)) + '<br>'
	from CustSetting3rd as cs with (NOLOCK) inner join
		(
						select 2 as bettype, 201 as sporttype, @auto_v201spositiontaking_2 as autopositiontaking
			union all 	select 3 as bettype, 201 as sporttype, @auto_v201spositiontaking_3 as autopositiontaking
		) as b on cs.sporttype=b.sporttype and cs.bettype=b.bettype
	inner join sports with (nolock) on b.sporttype = sports.sporttype
	inner join bettype with (nolock) on b.bettype = bettype.typeid
	where cs.custid = @srecommend
		and (cs.spositiontaking<b.autopositiontaking)
		
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
		select @ErrCode = @ErrCode + cast(@ErrCode_cur as varchar(300)) + char(7), 
				@ErrMsg = @ErrMsg + @ErrMsg_Cur + char(7)
		return
	END
	
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ cast((cs.spositiontaking) as varchar(10)) + '<br>'
	from CustSetting3rd as cs with (NOLOCK) inner join
		(
			--v201
						select 2 as bettype, 201 as sporttype, @v201spositiontaking_2 as positiontaking
			union all 	select 3 as bettype, 201 as sporttype, @v201spositiontaking_3 as positiontaking
		) as b on cs.sporttype=b.sporttype and cs.bettype=b.bettype
		inner join sports with (nolock) on b.sporttype = sports.sporttype
		inner join bettype with (nolock) on b.bettype = bettype.typeid
	where cs.custid = @srecommend
		and (cs.spositiontaking<b.positiontaking)
		
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
		Select  @ErrCode = @ErrCode + cast(@ErrCode_cur as varchar(300)) + char(7), 
				@ErrMsg = @ErrMsg + @ErrMsg_Cur + char(7)
		return
	END


--v201
select @v201spositiontaking_2_max = spositiontaking from CustSetting3rd with (NOLOCK) where custid = @srecommend and bettype=2 and sporttype=201
select @v201spositiontaking_3_max = spositiontaking from CustSetting3rd with (NOLOCK) where custid = @srecommend and bettype=3 and sporttype=201

select 
	--v201
	@v201spositiontaking_2 = case when @v201mpositiontaking_2+@v201spositiontaking_2+@v201apositiontaking_2>@v201spositiontaking_2_max then @v201spositiontaking_2_max-@v201mpositiontaking_2-@v201apositiontaking_2 else @v201spositiontaking_2 end,
	@v201spositiontaking_3 = case when @v201mpositiontaking_3+@v201spositiontaking_3+@v201apositiontaking_3>@v201spositiontaking_3_max then @v201spositiontaking_3_max-@v201mpositiontaking_3-@v201apositiontaking_3 else @v201spositiontaking_3 end

select 
	--v201
	@v201spositiontaking_2 = case when @v201spositiontaking_2<0 then 0 else @v201spositiontaking_2 end,
	@v201spositiontaking_3 = case when @v201spositiontaking_3<0 then 0 else @v201spositiontaking_3 end


--don't update s1 for member under master was set i3=1(normal)
update cs with (ROWLOCK, UPDLOCK)
set
	cs.spositiontaking = case cs.bettype when 2 then @v201spositiontaking_2 when 3 then @v201spositiontaking_3 else cs.spositiontaking end
from CustSetting3rd cs inner join custinfo c (nolock) on cs.custid = c.custid
	inner join CustSetting3rd scs (nolock) on scs.custid = c.mrecommend and cs.sporttype = scs.sporttype and cs.bettype = scs.bettype
where cs.custid=@custid and cs.sporttype = 201 and c.roleid = 1 and scs.isautopositiontaking = 0

--Update auto PT
update CustSetting3rd with (ROWLOCK, UPDLOCK) set autopositiontaking = b.autopositiontaking, isautopositiontaking = b.isautopositiontaking
from CustSetting3rd as cs inner join 
		(
			--v201
						select 2 as bettype, 201 as sporttype, @auto_v201spositiontaking_2 as autopositiontaking, @isauto_v201spositiontaking_2 as isautopositiontaking
			union all 	select 3 as bettype, 201 as sporttype, @auto_v201spositiontaking_3 as autopositiontaking, @isauto_v201spositiontaking_3 as isautopositiontaking
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

EXEC dbo.Acc_CustomerUpdMemberFI_MinMaxPositiontaking @custid = @custid, @recommend = @recommend, @mrecommend = @mrecommend, @srecommend = @srecommend

Declare @LogSPData varchar(5000)

Select @LogSPData = '<Acc_CustomerUpdMemberFI_SAg><info custid="'+ COALESCE(CAST(@CustID AS VARCHAR(50)),SPACE(1)) + '" ' +
'UserID="'+ COALESCE(CAST(@UserID AS VARCHAR(50)),SPACE(1)) + '" ' +
'Language="'+ COALESCE(CAST(@Language AS VARCHAR(2)),SPACE(1)) + '" ' +
'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(30)),space(1)) + '" ' +
'IP="'+ COALESCE(CAST(@IP AS VARCHAR(15)),SPACE(1)) + '" ' +
'ErrCode="'+ COALESCE(CAST(@ErrCode AS VARCHAR(50)),SPACE(1)) + '" ' +
'ErrMsg="'+ COALESCE(CAST(@ErrMsg AS VARCHAR(5000)),SPACE(1)) + '" />' +

'<s v201spt_2="'+ coalesce(cast(@v201spositiontaking_2 as varchar(50)),space(1)) + '" ' +
'v201spt_3="'+ coalesce(cast(@v201spositiontaking_3 as varchar(50)),space(1)) + '" />' +

'<au a_v201spt_2="'+ coalesce(cast(@auto_v201spositiontaking_2 as varchar(50)),space(1)) + '" ' +
'a_v201spt_3="'+ coalesce(cast(@auto_v201spositiontaking_3 as varchar(50)),space(1)) + '" />' +

--i1
'<ia isa_v201spt_2="'+ coalesce(cast(@isauto_v201spositiontaking_2 as varchar(50)),space(1)) + '" ' +
'isa_v201spt_3="'+ coalesce(cast(@isauto_v201spositiontaking_3 as varchar(50)),space(1)) + '" />' +

--i3
'<isau isa_v201smpt_2="'+ coalesce(cast(@isauto_v201smpositiontaking_2 as varchar(50)),space(1)) + '" ' +
'isa_v201smpt_3="'+ coalesce(cast(@isauto_v201smpositiontaking_3 as varchar(50)),space(1)) + '" /></Acc_CustomerUpdMemberFI_SAg>'


Select @ErrCode = @ErrCode + '-107'+char(7), @ErrMsg = @ErrMsg + char(7)

--Log positiontaking
EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew 
	@UserID = @UserID,
	@CustID = @CustID,
	@ActionID = 405,
	@TrackingValue = @LogSPData
	
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdMemberFI_SAg] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdMemberFI_SAg] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdMemberFI_SAg] TO [bodbExtAccNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdMemberFI_SAg] TO [vnteam]
