
ALTER PROCEDURE [dbo].[Acc_CustomerUpdMaster_PositionTaking]
	@custid int,-- masterid	
	
	@spositiontaking_1 smallmoney,
	@spositiontaking_2 smallmoney,
	@spositiontaking_3 smallmoney,
	@spositiontaking_4 smallmoney,
	@spositiontaking_5 smallmoney,
	@spositiontaking_6 smallmoney,
	@spositiontaking_7 smallmoney,
	@spositiontaking_8 smallmoney,
	@spositiontaking_9 smallmoney,
	@spositiontaking_10 smallmoney,
	@slivepositiontaking_1 smallmoney,
	@slivepositiontaking_3 smallmoney,
	@slivepositiontaking_7 smallmoney,
	@slivepositiontaking_8 smallmoney,
	
	@v2spositiontaking_1 smallmoney,
	@v2spositiontaking_2 smallmoney,
	@v2spositiontaking_3 smallmoney,
	@v2spositiontaking_7 smallmoney,
	@v2spositiontaking_8 smallmoney,
	@v2spositiontaking_9 smallmoney,
	@v2spositiontaking_20 smallmoney,
	
	@v3spositiontaking_1 smallmoney,
	@v3spositiontaking_2 smallmoney,
	@v3spositiontaking_3 smallmoney,	
	@v3spositiontaking_20 smallmoney,
	
	@v5spositiontaking_1 smallmoney,
	@v5spositiontaking_2 smallmoney,
	@v5spositiontaking_3 smallmoney,	
	@v5spositiontaking_20 smallmoney,
	
	@v8spositiontaking_1 smallmoney,
	@v8spositiontaking_3 smallmoney,	
	@v8spositiontaking_20 smallmoney,
	
	@v10spositiontaking_1 smallmoney,
	@v10spositiontaking_2 smallmoney,
	@v10spositiontaking_3 smallmoney,	
	@v10spositiontaking_20 smallmoney,
	
	@v11spositiontaking_1 smallmoney,
	@v11spositiontaking_20 smallmoney,
	
	@v99spositiontaking_1 smallmoney,
	@v99spositiontaking_2 smallmoney,
	@v99spositiontaking_3 smallmoney,	
	@v99spositiontaking_20 smallmoney,	
	
	@auto_spositiontaking_1 smallmoney = 0,
	@auto_spositiontaking_2 smallmoney = 0,
	@auto_spositiontaking_3 smallmoney = 0,
	@auto_spositiontaking_4 smallmoney = 0,
	@auto_spositiontaking_5 smallmoney= 0,
	@auto_spositiontaking_6 smallmoney = 0,
	@auto_spositiontaking_7 smallmoney = 0,
	@auto_spositiontaking_8 smallmoney = 0,
	@auto_spositiontaking_9 smallmoney = 0,
	@auto_spositiontaking_10 smallmoney = 0,
	@auto_slivepositiontaking_1 smallmoney = 0,
	@auto_slivepositiontaking_3 smallmoney = 0,
	@auto_slivepositiontaking_7 smallmoney = 0,
	@auto_slivepositiontaking_8 smallmoney = 0,
	
	@auto_v2spositiontaking_1 smallmoney = 0,
	@auto_v2spositiontaking_2 smallmoney = 0,
	@auto_v2spositiontaking_3 smallmoney = 0,
	@auto_v2spositiontaking_7 smallmoney = 0,
	@auto_v2spositiontaking_8 smallmoney = 0,
	@auto_v2spositiontaking_9 smallmoney = 0,
	@auto_v2spositiontaking_20 smallmoney = 0,
	
	@auto_v3spositiontaking_1 smallmoney = 0,
	@auto_v3spositiontaking_2 smallmoney = 0,
	@auto_v3spositiontaking_3 smallmoney = 0,
	@auto_v3spositiontaking_20 smallmoney = 0,
	
	@auto_v5spositiontaking_1 smallmoney = 0,
	@auto_v5spositiontaking_2 smallmoney = 0,
	@auto_v5spositiontaking_3 smallmoney = 0,
	@auto_v5spositiontaking_20 smallmoney = 0,
	
	@auto_v8spositiontaking_1 smallmoney = 0,
	@auto_v8spositiontaking_3 smallmoney = 0,
	@auto_v8spositiontaking_20 smallmoney = 0,
	
	@auto_v10spositiontaking_1 smallmoney = 0,
	@auto_v10spositiontaking_2 smallmoney = 0,
	@auto_v10spositiontaking_3 smallmoney = 0,
	@auto_v10spositiontaking_20 smallmoney = 0,
	
	@auto_v11spositiontaking_1 smallmoney = 0,
	@auto_v11spositiontaking_20 smallmoney = 0,

	@auto_v99spositiontaking_1 smallmoney = 0,
	@auto_v99spositiontaking_2 smallmoney = 0,
	@auto_v99spositiontaking_3 smallmoney = 0,
	@auto_v99spositiontaking_20 smallmoney = 0,	
	
	@isauto_spositiontaking_1 bit = 0,
	@isauto_spositiontaking_2 bit = 0,
	@isauto_spositiontaking_3 bit = 0,
	@isauto_spositiontaking_4 bit = 0,
	@isauto_spositiontaking_5 bit= 0,
	@isauto_spositiontaking_6 bit = 0,
	@isauto_spositiontaking_7 bit = 0,
	@isauto_spositiontaking_8 bit = 0,
	@isauto_spositiontaking_9 bit = 0,
	@isauto_spositiontaking_10 bit = 0,
	@isauto_slivepositiontaking_1 bit = 0,
	@isauto_slivepositiontaking_3 bit = 0,
	@isauto_slivepositiontaking_7 bit = 0,
	@isauto_slivepositiontaking_8 bit = 0,
	
	@isauto_v2spositiontaking_1 bit = 0,
	@isauto_v2spositiontaking_2 bit = 0,
	@isauto_v2spositiontaking_3 bit = 0,
	@isauto_v2spositiontaking_7 bit = 0,
	@isauto_v2spositiontaking_8 bit = 0,
	@isauto_v2spositiontaking_9 bit = 0,
	@isauto_v2spositiontaking_20 bit = 0,
	
	@isauto_v3spositiontaking_1 bit = 0,
	@isauto_v3spositiontaking_2 bit = 0,
	@isauto_v3spositiontaking_3 bit = 0,
	@isauto_v3spositiontaking_20 bit = 0,
	
	@isauto_v5spositiontaking_1 bit = 0,
	@isauto_v5spositiontaking_2 bit = 0,
	@isauto_v5spositiontaking_3 bit = 0,
	@isauto_v5spositiontaking_20 bit = 0,
	
	@isauto_v8spositiontaking_1 bit = 0,
	@isauto_v8spositiontaking_3 bit = 0,
	@isauto_v8spositiontaking_20 bit = 0,
	
	@isauto_v10spositiontaking_1 bit = 0,
	@isauto_v10spositiontaking_2 bit = 0,
	@isauto_v10spositiontaking_3 bit = 0,
	@isauto_v10spositiontaking_20 bit = 0,
	
	@isauto_v11spositiontaking_1 bit = 0,
	@isauto_v11spositiontaking_20 bit = 0,
	
	@isauto_v99spositiontaking_1 bit = 0,
	@isauto_v99spositiontaking_2 bit = 0,
	@isauto_v99spositiontaking_3 bit = 0,
	@isauto_v99spositiontaking_20 bit = 0,	
	
	@mpositiontaking_1 smallmoney = 0.7,
	@mpositiontaking_2 smallmoney = 0.7,
	@mpositiontaking_3 smallmoney = 0.7,
	@mpositiontaking_4 smallmoney = 0.7,
	@mpositiontaking_5 smallmoney = 0.7,
	@mpositiontaking_6 smallmoney = 0.7,
	@mpositiontaking_7 smallmoney = 0.7,
	@mpositiontaking_8 smallmoney = 0.7,
	@mpositiontaking_9 smallmoney = 0.7,
	@mpositiontaking_10 smallmoney = 0.7,
	@mlivepositiontaking_1 smallmoney = 0.7,
	@mlivepositiontaking_3 smallmoney = 0.7,
	@mlivepositiontaking_7 smallmoney = 0.7,
	@mlivepositiontaking_8 smallmoney = 0.7,
	
	@v2mpositiontaking_1 smallmoney = 0.7,
	@v2mpositiontaking_2 smallmoney = 0.7,
	@v2mpositiontaking_3 smallmoney = 0.7,
	@v2mpositiontaking_7 smallmoney = 0.7,
	@v2mpositiontaking_8 smallmoney = 0.7,
	@v2mpositiontaking_9 smallmoney = 0.7,
	@v2mpositiontaking_20 smallmoney = 0.7,
	
	@v3mpositiontaking_1 smallmoney = 0.7,
	@v3mpositiontaking_2 smallmoney = 0.7,
	@v3mpositiontaking_3 smallmoney = 0.7,
	@v3mpositiontaking_20 smallmoney = 0.7,
	
	@v5mpositiontaking_1 smallmoney = 0.7,
	@v5mpositiontaking_2 smallmoney = 0.7,
	@v5mpositiontaking_3 smallmoney = 0.7,
	@v5mpositiontaking_20 smallmoney = 0.7,
	
	@v8mpositiontaking_1 smallmoney = 0.7,
	@v8mpositiontaking_3 smallmoney = 0.7,
	@v8mpositiontaking_20 smallmoney = 0.7,
	
	@v10mpositiontaking_1 smallmoney = 0.7,
	@v10mpositiontaking_2 smallmoney = 0.7,
	@v10mpositiontaking_3 smallmoney = 0.7,
	@v10mpositiontaking_20 smallmoney = 0.7,
	
	@v11mpositiontaking_1 smallmoney = 0.7,
	@v11mpositiontaking_20 smallmoney = 0.7,

	@v99mpositiontaking_1 smallmoney = 0.7,
	@v99mpositiontaking_2 smallmoney = 0.7,
	@v99mpositiontaking_3 smallmoney = 0.7,
	@v99mpositiontaking_20 smallmoney = 0.7,
	
	@updateallmembers bit = 0,
	@newspositiontaking smallmoney = 0,--equals max(s+m) - chosen(m)
	
	@UpdateMultiple bit = 0,	
	
	@UpdatePositiontaking bit = 1,
	@UpdatePositiontakingv2 bit = 1,
	@UpdatePositiontakingv3 bit = 1,
	@UpdatePositiontakingv5 bit = 1,
	@UpdatePositiontakingv8 bit = 1,
	@UpdatePositiontakingv10 bit = 1,
	@UpdatePositiontakingv11 bit = 1,
	@UpdatePositiontakingv99 bit = 1,	
	
	@SubAccID int = 0, --Sub-AccountID	
	
	@UserID int = 0,	
	@Language varchar(2) = 'E',
	@IP varchar(15)='',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
as

--@Source Control
/*
Created: 20080515@Thien
Task : Update Master's Position Taking
DB: DB02.bodb02
Original: Acc_CustomerUpdEditCustomer_SAg

Revisions:
    - 20081023@Phuc: Add new sporttype 201, bettype 3
    - 20090122@PhuongBich: add new sporttype 201, bettype 2.
    - 20090314@HanhVu: add Korean language
    - 20090424@Phuc:Separate finance sporttype(201).
    - 20090628@Phuc: auto master PT on member level.
					Write log subaccname instead of subaccid.
	- 20090917@Phuc: write log into DBLOG.
	- 20100112@Kiwi: amend to write log in xml format.
Param's Explanation:
• @ErrCode:
    = 0: Update successfully.
    > 0: Specific Error.
  
• @ErrMsg: Error description.
*/


SET NOCOUNT ON

declare @ErrAcc varchar(4000), @ErrType varchar(4000)
declare @UserName varchar(30), @srecommend int,
		@maxpos smallmoney,	@maxdownlinepos smallmoney
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Select @UserName  = username, @srecommend = srecommend from custinfo with (NOLOCK) where CustID = @CustID
Select @maxpos = 0.9, @maxdownlinepos = 0
-- th: @maxpos and @maxdownlinepos are no longer used
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

if @UpdateMultiple = 0 or @UpdatePositiontaking = 1
BEGIN
	if 
		@spositiontaking_1  <0
		or @spositiontaking_2  <0
		or @spositiontaking_3  <0
		or @spositiontaking_4  <0
		or @spositiontaking_5  <0
		or @spositiontaking_6  <0
		or @spositiontaking_7  <0
		or @spositiontaking_8  <0
		or @spositiontaking_9  <0
		or @slivepositiontaking_1  <0
		or @slivepositiontaking_3  <0
		or @slivepositiontaking_7  <0
		or @slivepositiontaking_8  <0
		or @spositiontaking_10 <0
		
		or @mpositiontaking_1  <0
		or @mpositiontaking_2  <0
		or @mpositiontaking_3  <0
		or @mpositiontaking_4  <0
		or @mpositiontaking_5  <0
		or @mpositiontaking_6  <0
		or @mpositiontaking_7  <0
		or @mpositiontaking_8  <0
		or @mpositiontaking_9  <0
		or @mlivepositiontaking_1  <0
		or @mlivepositiontaking_3  <0
		or @mlivepositiontaking_7  <0
		or @mlivepositiontaking_8  <0
		or @mpositiontaking_10 <0
		
		or @spositiontaking_1+@mpositiontaking_1 >0.9
		or @spositiontaking_2+@mpositiontaking_2 >0.9
		or @spositiontaking_3+@mpositiontaking_3 >0.9
		or @spositiontaking_4+@mpositiontaking_4 >0.9
		or @spositiontaking_5+@mpositiontaking_5 >0.9
		or @spositiontaking_6+@mpositiontaking_6 >0.9
		or @spositiontaking_7+@mpositiontaking_7 >0.9
		or @spositiontaking_8+@mpositiontaking_8 >0.9
		or @spositiontaking_9+@mpositiontaking_9 >0.9
		or @spositiontaking_10+@mpositiontaking_10 >0.9
		or @slivepositiontaking_1+@mlivepositiontaking_1 >0.9
		or @slivepositiontaking_3+@mlivepositiontaking_3 >0.9
		or @slivepositiontaking_7+@mlivepositiontaking_7 >0.9
		or @slivepositiontaking_8+@mlivepositiontaking_8 >0.9
		or @auto_spositiontaking_1  <0
		or @auto_spositiontaking_2  <0
		or @auto_spositiontaking_3  <0
		or @auto_spositiontaking_4  <0
		or @auto_spositiontaking_5  <0
		or @auto_spositiontaking_6  <0
		or @auto_spositiontaking_7  <0
		or @auto_spositiontaking_8  <0
		or @auto_spositiontaking_9  <0
		or @auto_spositiontaking_10 <0
		or @auto_slivepositiontaking_1  <0
		or @auto_slivepositiontaking_3  <0
		or @auto_slivepositiontaking_7  <0
		or @auto_slivepositiontaking_8  <0
		or @auto_spositiontaking_1  >0.9
		or @auto_spositiontaking_2  >0.9
		or @auto_spositiontaking_3  >0.9
		or @auto_spositiontaking_4  >0.9
		or @auto_spositiontaking_5  >0.9
		or @auto_spositiontaking_6  >0.9
		or @auto_spositiontaking_7  >0.9
		or @auto_spositiontaking_8  >0.9
		or @auto_spositiontaking_9  >0.9
		or @auto_spositiontaking_10 >0.9
		or @auto_slivepositiontaking_1  >0.9
		or @auto_slivepositiontaking_3  >0.9
		or @auto_slivepositiontaking_7  >0.9
		or @auto_slivepositiontaking_8  >0.9
				
	BEGIN
		select @ErrCode = 5
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Wrong position taking (for Soccer).'
							when 'CS' then N'占成数不正确(于足球).'
							when 'CT' then N'佔成數不正確(於足球).'
							when 'TH' then N'การกำหนดจำนวนเงินไม่ถูกต้อง (สำหรับกีฬาฟุตบอล).'
							when 'J' then N'Wrong position taking (for Soccer).'
							when 'KO' then N'거래 조건이 잘못 되었습니다 (축구).'
							else N'Wrong position taking (for Soccer).'
					end
		return
	END
	--check n4<=s3+m3<=l4 if i3 = 0, 
	--m3<=l4 and u3+m3>=n4 if i3 = 1
	
--	select @ErrType = ''
--	select @ErrType = @ErrType + sportname + '-'+ typenamee + 
--	case when b.isauto_spositiontaking=0 then 
--		'-Min: '+ cast((co.minpositiontaking) as varchar(10))+ '-Max: '+ cast((co.maxpositiontaking) as varchar(10))
--		+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '--MinLive: '+ cast((co.minlivepositiontaking) as varchar(10))+ '-MaxLive: '+ cast((co.maxlivepositiontaking) as varchar(10)) else '' end
--	else
--		'-Min: '+ cast((co.minpositiontaking) as varchar(10))+ '-Max: '+ cast((co.maxpositiontaking) as varchar(10))
--		+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '--MinLive: '+ cast((co.minlivepositiontaking) as varchar(10))+ '-MaxLive: '+ cast((co.maxlivepositiontaking) as varchar(10)) else '' end
--	end

	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Min: '+ cast((co.minpositiontaking) as varchar(10))+ '-Max: '+ cast((co.maxpositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '--MinLive: '+ cast((co.minlivepositiontaking) as varchar(10))+ '-MaxLive: '+ cast((co.maxlivepositiontaking) as varchar(10)) else '' end + '<br>'
	from 
		custoverride as co with (NOLOCK) 
		inner join
		(
					select 1 as bettype, 1 as sporttype, @spositiontaking_1 as spositiontaking, @slivepositiontaking_1 as slivepositiontaking, @mpositiontaking_1 as mpositiontaking, @mlivepositiontaking_1 as mlivepositiontaking, @isauto_spositiontaking_1 as isauto_spositiontaking,  @isauto_slivepositiontaking_1 as isauto_slivepositiontaking, @auto_spositiontaking_1 as auto_spositiontaking,  @auto_slivepositiontaking_1 as auto_slivepositiontaking
			union all 	select 3 as bettype, 1 as sporttype, @spositiontaking_3 as spositiontaking, @slivepositiontaking_3 as slivepositiontaking, @mpositiontaking_3 as mpositiontaking, @mlivepositiontaking_3 as mlivepositiontaking, @isauto_spositiontaking_3 as isauto_spositiontaking,  @isauto_slivepositiontaking_3 as isauto_slivepositiontaking, @auto_spositiontaking_3 as auto_spositiontaking,  @auto_slivepositiontaking_3 as auto_slivepositiontaking
			union all 	select 7 as bettype, 1 as sporttype, @spositiontaking_7 as spositiontaking, @slivepositiontaking_7 as slivepositiontaking, @mpositiontaking_7 as mpositiontaking, @mlivepositiontaking_7 as mlivepositiontaking, @isauto_spositiontaking_7 as isauto_spositiontaking,  @isauto_slivepositiontaking_7 as isauto_slivepositiontaking, @auto_spositiontaking_7 as auto_spositiontaking,  @auto_slivepositiontaking_7 as auto_slivepositiontaking
			union all 	select 8 as bettype, 1 as sporttype, @spositiontaking_8 as spositiontaking, @slivepositiontaking_8 as slivepositiontaking, @mpositiontaking_8 as mpositiontaking, @mlivepositiontaking_8 as mlivepositiontaking, @isauto_spositiontaking_8 as isauto_spositiontaking,  @isauto_slivepositiontaking_8 as isauto_slivepositiontaking, @auto_spositiontaking_8 as auto_spositiontaking,  @auto_slivepositiontaking_8 as auto_slivepositiontaking
			union all 	select 2 as bettype, 1 as sporttype, @spositiontaking_2 as spositiontaking, 0 as slivepositiontaking, @mpositiontaking_2 as mpositiontaking, 0 as mlivepositiontaking, @isauto_spositiontaking_2 as isauto_spositiontaking,  0 as isauto_slivepositiontaking, @auto_spositiontaking_2 as auto_spositiontaking,  0 as auto_slivepositiontaking
			union all 	select 4 as bettype, 1 as sporttype, @spositiontaking_4 as spositiontaking, 0 as slivepositiontaking, @mpositiontaking_4 as mpositiontaking, 0 as mlivepositiontaking, @isauto_spositiontaking_4 as isauto_spositiontaking,  0 as isauto_slivepositiontaking, @auto_spositiontaking_4 as auto_spositiontaking,  0 as auto_slivepositiontaking
			union all 	select 5 as bettype, 1 as sporttype, @spositiontaking_5 as spositiontaking, 0 as slivepositiontaking, @mpositiontaking_5 as mpositiontaking, 0 as mlivepositiontaking, @isauto_spositiontaking_5 as isauto_spositiontaking,  0 as isauto_slivepositiontaking, @auto_spositiontaking_5 as auto_spositiontaking,  0 as auto_slivepositiontaking
			union all 	select 6 as bettype, 1 as sporttype, @spositiontaking_6 as spositiontaking, 0 as slivepositiontaking, @mpositiontaking_6 as mpositiontaking, 0 as mlivepositiontaking, @isauto_spositiontaking_6 as isauto_spositiontaking,  0 as isauto_slivepositiontaking, @auto_spositiontaking_6 as auto_spositiontaking,  0 as auto_slivepositiontaking
			union all 	select 9 as bettype, 1 as sporttype, @spositiontaking_9 as spositiontaking, 0 as slivepositiontaking, @mpositiontaking_9 as mpositiontaking, 0 as mlivepositiontaking, @isauto_spositiontaking_9 as isauto_spositiontaking,  0 as isauto_slivepositiontaking, @auto_spositiontaking_9 as auto_spositiontaking,  0 as auto_slivepositiontaking
			union all 	select 10 as bettype, 1 as sporttype, @spositiontaking_10 as spositiontaking, 0 as slivepositiontaking, @mpositiontaking_10 as mpositiontaking, 0 as mlivepositiontaking, @isauto_spositiontaking_10 as isauto_spositiontaking,  0 as isauto_slivepositiontaking, @auto_spositiontaking_10 as auto_spositiontaking,  0 as auto_slivepositiontaking	
		) as b on co.sporttype=b.sporttype and co.bettype = b.bettype
		inner join sports with (nolock) on b.sporttype = sports.sporttype
		inner join bettype with (nolock) on b.bettype = bettype.typeid
	where co.custid = @srecommend and (	
						((b.isauto_spositiontaking=0) and (b.spositiontaking+b.mpositiontaking>co.maxpositiontaking or b.spositiontaking+b.mpositiontaking<co.minpositiontaking)) or 
						(b.isauto_spositiontaking>0 and (b.mpositiontaking>co.maxpositiontaking or b.mpositiontaking + b.auto_spositiontaking<co.minpositiontaking)) or 
						((b.sporttype = 1 and b.bettype in (1,3,7,8) and b.isauto_slivepositiontaking=0) and (b.slivepositiontaking+b.mlivepositiontaking>co.maxlivepositiontaking or b.slivepositiontaking+b.mlivepositiontaking<co.minlivepositiontaking)) or
						((b.sporttype = 1 and b.bettype in (1,3,7,8) and b.isauto_slivepositiontaking>0) and (b.mlivepositiontaking>co.maxlivepositiontaking or b.mlivepositiontaking + b.auto_slivepositiontaking<co.minlivepositiontaking))
					)
	if @ErrType <>''
	BEGIN
		select @ErrCode = 6
		Select @ErrMsg = 	case @Language 
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

	--check n3<=m3<=l3 
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Min: '+ cast((co.minpositiontaking) as varchar(10))+ '-Max: '+ cast((co.maxpositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '--MinLive: '+ cast((co.minlivepositiontaking) as varchar(10))+ '-MaxLive: '+ cast((co.maxlivepositiontaking) as varchar(10)) else '' end + '<br>'
	from 
		custoverride as co with (NOLOCK) 
		inner join
		(
					select 1 as bettype, 1 as sporttype, @spositiontaking_1 as spositiontaking, @slivepositiontaking_1 as slivepositiontaking, @mpositiontaking_1 as mpositiontaking, @mlivepositiontaking_1 as mlivepositiontaking, @isauto_spositiontaking_1 as isauto_spositiontaking,  @isauto_slivepositiontaking_1 as isauto_slivepositiontaking
			union all 	select 3 as bettype, 1 as sporttype, @spositiontaking_3 as spositiontaking, @slivepositiontaking_3 as slivepositiontaking, @mpositiontaking_3 as mpositiontaking, @mlivepositiontaking_3 as mlivepositiontaking, @isauto_spositiontaking_3 as isauto_spositiontaking,  @isauto_slivepositiontaking_3 as isauto_slivepositiontaking
			union all 	select 7 as bettype, 1 as sporttype, @spositiontaking_7 as spositiontaking, @slivepositiontaking_7 as slivepositiontaking, @mpositiontaking_7 as mpositiontaking, @mlivepositiontaking_7 as mlivepositiontaking, @isauto_spositiontaking_7 as isauto_spositiontaking,  @isauto_slivepositiontaking_7 as isauto_slivepositiontaking
			union all 	select 8 as bettype, 1 as sporttype, @spositiontaking_8 as spositiontaking, @slivepositiontaking_8 as slivepositiontaking, @mpositiontaking_8 as mpositiontaking, @mlivepositiontaking_8 as mlivepositiontaking, @isauto_spositiontaking_8 as isauto_spositiontaking,  @isauto_slivepositiontaking_8 as isauto_slivepositiontaking
			union all 	select 2 as bettype, 1 as sporttype, @spositiontaking_2 as spositiontaking, 0 as slivepositiontaking, @mpositiontaking_2 as mpositiontaking, 0 as mlivepositiontaking, @isauto_spositiontaking_2 as isauto_spositiontaking,  0 as isauto_slivepositiontaking
			union all 	select 4 as bettype, 1 as sporttype, @spositiontaking_4 as spositiontaking, 0 as slivepositiontaking, @mpositiontaking_4 as mpositiontaking, 0 as mlivepositiontaking, @isauto_spositiontaking_4 as isauto_spositiontaking,  0 as isauto_slivepositiontaking
			union all 	select 5 as bettype, 1 as sporttype, @spositiontaking_5 as spositiontaking, 0 as slivepositiontaking, @mpositiontaking_5 as mpositiontaking, 0 as mlivepositiontaking, @isauto_spositiontaking_5 as isauto_spositiontaking,  0 as isauto_slivepositiontaking
			union all 	select 6 as bettype, 1 as sporttype, @spositiontaking_6 as spositiontaking, 0 as slivepositiontaking, @mpositiontaking_6 as mpositiontaking, 0 as mlivepositiontaking, @isauto_spositiontaking_6 as isauto_spositiontaking,  0 as isauto_slivepositiontaking
			union all 	select 9 as bettype, 1 as sporttype, @spositiontaking_9 as spositiontaking, 0 as slivepositiontaking, @mpositiontaking_9 as mpositiontaking, 0 as mlivepositiontaking, @isauto_spositiontaking_9 as isauto_spositiontaking,  0 as isauto_slivepositiontaking
			union all 	select 10 as bettype, 1 as sporttype, @spositiontaking_10 as spositiontaking, 0 as slivepositiontaking, @mpositiontaking_10 as mpositiontaking, 0 as mlivepositiontaking, @isauto_spositiontaking_10 as isauto_spositiontaking,  0 as isauto_slivepositiontaking	
		) as b on co.sporttype=b.sporttype and co.bettype = b.bettype
		inner join sports with (nolock) on b.sporttype = sports.sporttype
		inner join bettype with (nolock) on b.bettype = bettype.typeid
	where co.custid = @custid and (	
						(b.mpositiontaking>co.maxpositiontaking or b.mpositiontaking<co.minpositiontaking) or 
						(b.sporttype = 1 and b.bettype in (1,3,7,8) and (b.mlivepositiontaking>co.maxlivepositiontaking or b.mlivepositiontaking<co.minlivepositiontaking))
					)
	if @ErrType <>''
	BEGIN
		select @ErrCode = 7
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

	--a2+m2<=m3
	select @ErrAcc = ''
	--select top 100 @ErrAcc = @ErrAcc + username + ' (' + sportname + '-' + typenamee + ') <br>'
	select top 100 @ErrAcc = @ErrAcc + username +', '
	from 
		custinfo as c with (NOLOCK) 
		inner join custsetting as cs with (NOLOCK) on c.custid = cs.custid
		inner join (
	
				select 		1 as sporttype, 1 as bettype, @mpositiontaking_1 as maxpositiontaking,  @mlivepositiontaking_1 as maxlivepositiontaking
				union all select 	1 as sporttype, 2 as bettype, @mpositiontaking_2 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	1 as sporttype, 3 as bettype, @mpositiontaking_3 as maxpositiontaking,  @mlivepositiontaking_3 as maxlivepositiontaking
				union all select 	1 as sporttype, 4 as bettype, @mpositiontaking_4 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	1 as sporttype, 5 as bettype, @mpositiontaking_5 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	1 as sporttype, 6 as bettype, @mpositiontaking_6 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	1 as sporttype, 7 as bettype, @mpositiontaking_7 as maxpositiontaking,  @mlivepositiontaking_7 as maxlivepositiontaking
				union all select 	1 as sporttype, 8 as bettype, @mpositiontaking_8 as maxpositiontaking,  @mlivepositiontaking_8 as maxlivepositiontaking
				union all select 	1 as sporttype, 9 as bettype, @mpositiontaking_9 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	1 as sporttype, 10 as bettype, @mpositiontaking_10 as maxpositiontaking,  0 as maxlivepositiontaking
			) as b on cs.sporttype=b.sporttype and cs.bettype = b.bettype
		--inner join sports with (nolock) on b.sporttype = sports.sporttype
		--inner join bettype with (nolock) on b.bettype = bettype.typeid
	where c.mrecommend = @custid and c.roleid = 2 and (cs.apositiontaking+cs.mpositiontaking>b.maxpositiontaking or (b.sporttype=1 and b.bettype in (1,3,7,8) and cs.alivepositiontaking+cs.mlivepositiontaking>b.maxlivepositiontaking))
	group by username--, sportname, typenamee
	if @ErrAcc<>''
	BEGIN
		select @ErrCode = 8
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Existing agents exceeded new master positiontaking ('+@ErrAcc+') (for Soccer).'
							--when 'E' then 'Existing agents exceeded new master positiontaking <br> ' +@ErrAcc
							when 'CS' then N'现有代理超出新总代理占成数设定 ('+@ErrAcc+ N') (于足球).'
							when 'CT' then N'現有代理超出新總代理佔成數設定 ('+@ErrAcc+ N') (於足球).'
							when 'TH' then N'ตัวแทนที่มีอยู่ขณะนี้เกินกว่าจำนวนตัวแทนหลักรายใหม่ ('+@ErrAcc+ N')(สำหรับกีฬาฟุตบอล).'
							when 'J' then N'Existing agents exceeded new master positiontaking ('+@ErrAcc+ N') (for Soccer).'
							when 'KO' then N'에이전트의 거래조건 설정 법위를 넘어섰습니다 ('+@ErrAcc+ N') (축구).'
							else N'Existing agents exceeded new master positiontaking ('+@ErrAcc+') (for Soccer).'
					end
		return
	END

	--a1+m1<=m3
	select @ErrAcc = ''
	select top 100 @ErrAcc = @ErrAcc + username +', '
	from 
		custinfo as c with (NOLOCK) 
		inner join custsetting as cs with (NOLOCK) on c.custid = cs.custid
		inner join (
	
				select 		1 as sporttype, 1 as bettype, @mpositiontaking_1 as maxpositiontaking,  @mlivepositiontaking_1 as maxlivepositiontaking
				union all select 	1 as sporttype, 2 as bettype, @mpositiontaking_2 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	1 as sporttype, 3 as bettype, @mpositiontaking_3 as maxpositiontaking,  @mlivepositiontaking_3 as maxlivepositiontaking
				union all select 	1 as sporttype, 4 as bettype, @mpositiontaking_4 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	1 as sporttype, 5 as bettype, @mpositiontaking_5 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	1 as sporttype, 6 as bettype, @mpositiontaking_6 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	1 as sporttype, 7 as bettype, @mpositiontaking_7 as maxpositiontaking,  @mlivepositiontaking_7 as maxlivepositiontaking
				union all select 	1 as sporttype, 8 as bettype, @mpositiontaking_8 as maxpositiontaking,  @mlivepositiontaking_8 as maxlivepositiontaking
				union all select 	1 as sporttype, 9 as bettype, @mpositiontaking_9 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	1 as sporttype, 10 as bettype, @mpositiontaking_10 as maxpositiontaking,  0 as maxlivepositiontaking
			) as b on cs.sporttype=b.sporttype and cs.bettype = b.bettype
	where c.mrecommend = @custid and c.roleid = 1 and (cs.apositiontaking+cs.mpositiontaking>b.maxpositiontaking or (b.sporttype=1 and b.bettype in (1,3,7,8) and cs.alivepositiontaking+cs.mlivepositiontaking>b.maxlivepositiontaking))
	group by username
	if @ErrAcc<>''
	BEGIN
		select @ErrCode = 9
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Existing members exceeded new master positiontaking ('+@ErrAcc+') (for Soccer).'
							when 'CS' then N'现有会员超出新总代理占成数设定 ('+@ErrAcc+ N') (于足球).'
							when 'CT' then N'現有會員超出新總代理佔成數設定 ('+@ErrAcc+ N') (於足球).'
							when 'TH' then N'สมาชิกที่มีอยู่ในขณะนี้เกินกว่า จำนวนตัวแทนหลักรายใหม่ กำหนดไว้('+@ErrAcc+ N')(สำหรับฟุตบอล ).'
							when 'J' then N'Existing members exceeded new master positiontaking ('+@ErrAcc+ N') (for Soccer).'
							when 'KO' then N'회원의 거래조건 설정 범위를 넘어섰습니다 ('+@ErrAcc+ N') (축구).'
							else N'Existing members exceeded new master positiontaking ('+@ErrAcc+ N') (for Soccer).'
					end
		return
	END

	--check m3<=m4
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ cast((scs.mpositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '-MaxLive: '+ cast((scs.mlivepositiontaking) as varchar(10)) else '' end + '<br>'
	from custsetting as scs with (NOLOCK) inner join
		(
					select 1 as bettype, 1 as sporttype, @spositiontaking_1 as spositiontaking, @slivepositiontaking_1 as slivepositiontaking, @mpositiontaking_1 as mpositiontaking, @mlivepositiontaking_1 as mlivepositiontaking, @auto_spositiontaking_1 as auto_spositiontaking,  @auto_slivepositiontaking_1 as auto_slivepositiontaking
			union all 	select 3 as bettype, 1 as sporttype, @spositiontaking_3 as spositiontaking, @slivepositiontaking_3 as slivepositiontaking, @mpositiontaking_3 as mpositiontaking, @mlivepositiontaking_3 as mlivepositiontaking, @auto_spositiontaking_3 as auto_spositiontaking,  @auto_slivepositiontaking_3 as auto_slivepositiontaking
			union all 	select 7 as bettype, 1 as sporttype, @spositiontaking_7 as spositiontaking, @slivepositiontaking_7 as slivepositiontaking, @mpositiontaking_7 as mpositiontaking, @mlivepositiontaking_7 as mlivepositiontaking, @auto_spositiontaking_7 as auto_spositiontaking,  @auto_slivepositiontaking_7 as auto_slivepositiontaking
			union all 	select 8 as bettype, 1 as sporttype, @spositiontaking_8 as spositiontaking, @slivepositiontaking_8 as slivepositiontaking, @mpositiontaking_8 as mpositiontaking, @mlivepositiontaking_8 as mlivepositiontaking, @auto_spositiontaking_8 as auto_spositiontaking,  @auto_slivepositiontaking_8 as auto_slivepositiontaking
			union all 	select 2 as bettype, 1 as sporttype, @spositiontaking_2 as spositiontaking, 0 as slivepositiontaking, @mpositiontaking_2 as mpositiontaking, 0 as mlivepositiontaking, @auto_spositiontaking_2 as auto_spositiontaking,  0 as auto_slivepositiontaking
			union all 	select 4 as bettype, 1 as sporttype, @spositiontaking_4 as spositiontaking, 0 as slivepositiontaking, @mpositiontaking_4 as mpositiontaking, 0 as mlivepositiontaking, @auto_spositiontaking_4 as auto_spositiontaking,  0 as auto_slivepositiontaking
			union all 	select 5 as bettype, 1 as sporttype, @spositiontaking_5 as spositiontaking, 0 as slivepositiontaking, @mpositiontaking_5 as mpositiontaking, 0 as mlivepositiontaking, @auto_spositiontaking_5 as auto_spositiontaking,  0 as auto_slivepositiontaking
			union all 	select 6 as bettype, 1 as sporttype, @spositiontaking_6 as spositiontaking, 0 as slivepositiontaking, @mpositiontaking_6 as mpositiontaking, 0 as mlivepositiontaking, @auto_spositiontaking_6 as auto_spositiontaking,  0 as auto_slivepositiontaking
			union all 	select 9 as bettype, 1 as sporttype, @spositiontaking_9 as spositiontaking, 0 as slivepositiontaking, @mpositiontaking_9 as mpositiontaking, 0 as mlivepositiontaking, @auto_spositiontaking_9 as auto_spositiontaking,  0 as auto_slivepositiontaking
			union all 	select 10 as bettype, 1 as sporttype, @spositiontaking_10 as spositiontaking, 0 as slivepositiontaking, @mpositiontaking_10 as mpositiontaking, 0 as mlivepositiontaking, @auto_spositiontaking_10 as auto_spositiontaking,  0 as auto_slivepositiontaking
		) as b on scs.sporttype=b.sporttype and scs.bettype = b.bettype
		inner join sports with (nolock) on b.sporttype = sports.sporttype
		inner join bettype with (nolock) on b.bettype = bettype.typeid
	where scs.custid = @srecommend and (
						scs.mpositiontaking<b.mpositiontaking or (b.sporttype=1 and b.bettype in (1,3,7,8) and scs.mlivepositiontaking<b.mlivepositiontaking)
						)
	if @ErrType <>''
	BEGIN
		select @ErrCode = 10
		Select @ErrMsg = 	@UserName + ': '+
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
		inner join custsetting as cs with (NOLOCK) on c.custid = cs.custid
		inner join (
	
				select 		1 as sporttype, 1 as bettype, @mpositiontaking_1 as maxpositiontaking,  @mlivepositiontaking_1 as maxlivepositiontaking
				union all select 	1 as sporttype, 2 as bettype, @mpositiontaking_2 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	1 as sporttype, 3 as bettype, @mpositiontaking_3 as maxpositiontaking,  @mlivepositiontaking_3 as maxlivepositiontaking
				union all select 	1 as sporttype, 4 as bettype, @mpositiontaking_4 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	1 as sporttype, 5 as bettype, @mpositiontaking_5 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	1 as sporttype, 6 as bettype, @mpositiontaking_6 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	1 as sporttype, 7 as bettype, @mpositiontaking_7 as maxpositiontaking,  @mlivepositiontaking_7 as maxlivepositiontaking
				union all select 	1 as sporttype, 8 as bettype, @mpositiontaking_8 as maxpositiontaking,  @mlivepositiontaking_8 as maxlivepositiontaking
				union all select 	1 as sporttype, 9 as bettype, @mpositiontaking_9 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	1 as sporttype, 10 as bettype, @mpositiontaking_10 as maxpositiontaking,  0 as maxlivepositiontaking
			) as b on cs.sporttype=b.sporttype and cs.bettype = b.bettype
	where c.mrecommend = @custid and c.roleid = 2 
		and (	(cs.autompositiontaking > b.maxpositiontaking and cs.isautompositiontaking = 1)
				or ((b.sporttype=1 and b.bettype in (1,3,7,8) and cs.autolivempositiontaking > b.maxlivepositiontaking) and cs.isautolivempositiontaking = 1)
			)
	group by username
	if @ErrAcc<>''
	BEGIN
		select @ErrCode = 17
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Existing agents exceeded new master positiontaking ('+@ErrAcc+') (for Soccer).'
							when 'CS' then N'现有代理超出新总代理占成数设定 ('+@ErrAcc+ N') (于足球).'
							when 'CT' then N'現有代理超出新總代理佔成數設定 ('+@ErrAcc+ N') (於足球).'
							when 'TH' then N'ตัวแทนที่มีอยู่ขณะนี้เกินกว่าจำนวนตัวแทนหลักรายใหม่ ('+@ErrAcc+ N')(สำหรับกีฬาฟุตบอล).'
							when 'J' then N'Existing agents exceeded new master positiontaking ('+@ErrAcc+ N') (for Soccer).'
							when 'KO' then N'에이전트의 거래조건 설정 법위를 넘어섰습니다 ('+@ErrAcc+ N') (축구).'
							else N'Existing agents exceeded new master positiontaking ('+@ErrAcc+') (for Soccer).'
					end
		return
	END
END


if @UpdateMultiple = 0 or @UpdatePositiontakingv2 = 1
BEGIN
	if 
		@v2spositiontaking_1  <0
		or @v2spositiontaking_2  <0
		or @v2spositiontaking_3  <0
		or @v2spositiontaking_7  <0
		or @v2spositiontaking_8  <0
		or @v2spositiontaking_9  <0
		or @v2spositiontaking_20  <0
		
		or @v2spositiontaking_1+@v2mpositiontaking_1 >0.9
		or @v2spositiontaking_2+@v2mpositiontaking_2 >0.9
		or @v2spositiontaking_3+@v2mpositiontaking_3 >0.9
		or @v2spositiontaking_7+@v2mpositiontaking_7 >0.9
		or @v2spositiontaking_8+@v2mpositiontaking_8 >0.9
		or @v2spositiontaking_9+@v2mpositiontaking_9 >0.9
		or @v2spositiontaking_20+@v2mpositiontaking_20 >0.9
		
		or @auto_v2spositiontaking_1  >0.9
		or @auto_v2spositiontaking_2  >0.9
		or @auto_v2spositiontaking_3  >0.9
		or @auto_v2spositiontaking_7  >0.9
		or @auto_v2spositiontaking_8  >0.9
		or @auto_v2spositiontaking_9  >0.9
		or @auto_v2spositiontaking_20  >0.9
		
		or @v2mpositiontaking_1 <0
		or @v2mpositiontaking_2 <0
		or @v2mpositiontaking_3 <0
		or @v2mpositiontaking_7 <0
		or @v2mpositiontaking_8 <0
		or @v2mpositiontaking_9 <0
		or @v2mpositiontaking_20 <0
				
	BEGIN
		select @ErrCode = 11
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Wrong position taking (for Basketball).'
							when 'CS' then N'占成数不正确(于篮球).'
							when 'CT' then N'佔成數不正確(於籃球).'
							when 'TH' then N'การกำหนดไม่ถูกต้อง (สำหรับกีฬาบาสเก็ตบอล).'
							when 'J' then N'Wrong position taking (for Basketball).'
							when 'KO' then N'거래 조건이 잘못 되었습니다 (농구).'
							else N'Wrong position taking (for Basketball).'
					end
		return
	END

	--check n4<=s3+m3<=l4 if i3 = 0, 
	--m3<=l4 and u3+m3>=n4 if i3 = 1
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Min: '+ cast((co.minpositiontaking) as varchar(10))+ '-Max: '+ cast((co.maxpositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '--MinLive: '+ cast((co.minlivepositiontaking) as varchar(10))+ '-MaxLive: '+ cast((co.maxlivepositiontaking) as varchar(10)) else '' end + '<br>'
	from custoverride as co with (NOLOCK) inner join
		(
				 	select 1 as bettype, 2 as sporttype, @v2spositiontaking_1 as spositiontaking, 0 as slivepositiontaking, @v2mpositiontaking_1 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v2spositiontaking_1 as isauto_spositiontaking,  0 as isauto_slivepositiontaking, @auto_v2spositiontaking_1 as auto_spositiontaking
			union all 	select 2 as bettype, 2 as sporttype, @v2spositiontaking_2 as spositiontaking, 0 as slivepositiontaking, @v2mpositiontaking_2 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v2spositiontaking_2 as isauto_spositiontaking,  0 as isauto_slivepositiontaking, @auto_v2spositiontaking_2 as auto_spositiontaking
			union all 	select 3 as bettype, 2 as sporttype, @v2spositiontaking_3 as spositiontaking, 0 as slivepositiontaking, @v2mpositiontaking_3 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v2spositiontaking_3 as isauto_spositiontaking,  0 as isauto_slivepositiontaking, @auto_v2spositiontaking_3 as auto_spositiontaking
--			union all 	select 7 as bettype, 2 as sporttype, @v2spositiontaking_7 as spositiontaking, 0 as slivepositiontaking, @v2mpositiontaking_7 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v2spositiontaking_7 as isauto_spositiontaking,  0 as isauto_slivepositiontaking, @auto_v2spositiontaking_7 as auto_spositiontaking
--			union all 	select 8 as bettype, 2 as sporttype, @v2spositiontaking_8 as spositiontaking, 0 as slivepositiontaking, @v2mpositiontaking_8 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v2spositiontaking_8 as isauto_spositiontaking,  0 as isauto_slivepositiontaking, @auto_v2spositiontaking_8 as auto_spositiontaking
			union all 	select 9 as bettype, 2 as sporttype, @v2spositiontaking_9 as spositiontaking, 0 as slivepositiontaking, @v2mpositiontaking_9 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v2spositiontaking_9 as isauto_spositiontaking,  0 as isauto_slivepositiontaking, @auto_v2spositiontaking_9 as auto_spositiontaking
			union all 	select 20 as bettype, 2 as sporttype, @v2spositiontaking_20 as spositiontaking, 0 as slivepositiontaking, @v2mpositiontaking_20 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v2spositiontaking_20 as isauto_spositiontaking,  0 as isauto_slivepositiontaking, @auto_v2spositiontaking_20 as auto_spositiontaking

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
		Select @ErrMsg = 	case @Language 
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
	
	--check n3<=m3<=l3 
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Min: '+ cast((co.minpositiontaking) as varchar(10))+ '-Max: '+ cast((co.maxpositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '--MinLive: '+ cast((co.minlivepositiontaking) as varchar(10))+ '-MaxLive: '+ cast((co.maxlivepositiontaking) as varchar(10)) else '' end + '<br>'
	from custoverride as co with (NOLOCK) inner join
		(
				 	select 1 as bettype, 2 as sporttype, @v2spositiontaking_1 as spositiontaking, 0 as slivepositiontaking, @v2mpositiontaking_1 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v2spositiontaking_1 as isauto_spositiontaking,  0 as isauto_slivepositiontaking
			union all 	select 2 as bettype, 2 as sporttype, @v2spositiontaking_2 as spositiontaking, 0 as slivepositiontaking, @v2mpositiontaking_2 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v2spositiontaking_2 as isauto_spositiontaking,  0 as isauto_slivepositiontaking
			union all 	select 3 as bettype, 2 as sporttype, @v2spositiontaking_3 as spositiontaking, 0 as slivepositiontaking, @v2mpositiontaking_3 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v2spositiontaking_3 as isauto_spositiontaking,  0 as isauto_slivepositiontaking
--			union all 	select 7 as bettype, 2 as sporttype, @v2spositiontaking_7 as spositiontaking, 0 as slivepositiontaking, @v2mpositiontaking_7 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v2spositiontaking_7 as isauto_spositiontaking,  0 as isauto_slivepositiontaking
--			union all 	select 8 as bettype, 2 as sporttype, @v2spositiontaking_8 as spositiontaking, 0 as slivepositiontaking, @v2mpositiontaking_8 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v2spositiontaking_8 as isauto_spositiontaking,  0 as isauto_slivepositiontaking
			union all 	select 9 as bettype, 2 as sporttype, @v2spositiontaking_9 as spositiontaking, 0 as slivepositiontaking, @v2mpositiontaking_9 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v2spositiontaking_9 as isauto_spositiontaking,  0 as isauto_slivepositiontaking
			union all 	select 20 as bettype, 2 as sporttype, @v2spositiontaking_20 as spositiontaking, 0 as slivepositiontaking, @v2mpositiontaking_20 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v2spositiontaking_20 as isauto_spositiontaking,  0 as isauto_slivepositiontaking
		) as b on co.sporttype=b.sporttype and co.bettype = b.bettype
		inner join sports with (nolock) on b.sporttype = sports.sporttype
		inner join bettype with (nolock) on b.bettype = bettype.typeid
	where co.custid = @custid and (	
						(b.mpositiontaking>co.maxpositiontaking or b.mpositiontaking<co.minpositiontaking) 
--						or (b.sporttype = 1 and b.bettype in (1,3,7,8) and (b.mlivepositiontaking>co.maxlivepositiontaking or b.mlivepositiontaking<co.minlivepositiontaking))
					)
	if @ErrType <>''
	BEGIN
		select @ErrCode = 13
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

	--a2+m2<=m3
	select @ErrAcc = ''
	select top 100 @ErrAcc = @ErrAcc + username +', '
	from 
		custinfo as c with (NOLOCK) 
		inner join custsetting as cs with (NOLOCK) on c.custid = cs.custid
		inner join (
	
					select 	2 as sporttype, 1 as bettype, @v2mpositiontaking_1 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	2 as sporttype, 2 as bettype, @v2mpositiontaking_2 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	2 as sporttype, 3 as bettype, @v2mpositiontaking_3 as maxpositiontaking,  0 as maxlivepositiontaking
--				union all select 	2 as sporttype, 7 as bettype, @v2mpositiontaking_7 as maxpositiontaking,  0 as maxlivepositiontaking
--				union all select 	2 as sporttype, 8 as bettype, @v2mpositiontaking_8 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	2 as sporttype, 9 as bettype, @v2mpositiontaking_9 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	2 as sporttype, 20 as bettype, @v2mpositiontaking_20 as maxpositiontaking,  0 as maxlivepositiontaking
			) as b on cs.sporttype=b.sporttype and cs.bettype = b.bettype
	where c.mrecommend = @custid and c.roleid = 2 and (cs.apositiontaking+cs.mpositiontaking>b.maxpositiontaking or (b.sporttype=1 and b.bettype in (1,3,7,8) and cs.alivepositiontaking+cs.mlivepositiontaking>b.maxlivepositiontaking))
	group by username
	if @ErrAcc<>''
	BEGIN
		select @ErrCode = 14
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Existing agents exceeded new master positiontaking ('+@ErrAcc+') (for Basketball).'
							when 'CS' then N'现有代理超出新总代理占成数设定 ('+@ErrAcc+ N') (于篮球).'
							when 'CT' then N'現有代理超出新總代理佔成數設定 ('+@ErrAcc+ N') (於籃球).'
							when 'TH' then N'ตัวแทนที่มีอยู่ขณะนี้เกินกว่าจำนวนตัวแทนหลักรายใหม่ ('+@ErrAcc+ N')(สำหรับกีฬาบาสเก็ตบอล)).'
							when 'J' then N'Existing agents exceeded new master positiontaking ('+@ErrAcc+ N') (for Basketball).'
							when 'KO' then N'에이전트의 거래조건 설정 법위를 넘어섰습니다 ('+@ErrAcc+ N') (농구).'
							else N'Existing agents exceeded new master positiontaking ('+@ErrAcc+ N') (for Basketball).'
					end
		return
	END
	--m1+a1<=m3
	select @ErrAcc = ''
	select top 100 @ErrAcc = @ErrAcc + username +', '
	from 
		custinfo as c with (NOLOCK) 
		inner join custsetting as cs with (NOLOCK) on c.custid = cs.custid
		inner join (
	
					select 	2 as sporttype, 1 as bettype, @v2mpositiontaking_1 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	2 as sporttype, 2 as bettype, @v2mpositiontaking_2 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	2 as sporttype, 3 as bettype, @v2mpositiontaking_3 as maxpositiontaking,  0 as maxlivepositiontaking
--				union all select 	2 as sporttype, 7 as bettype, @v2mpositiontaking_7 as maxpositiontaking,  0 as maxlivepositiontaking
--				union all select 	2 as sporttype, 8 as bettype, @v2mpositiontaking_8 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	2 as sporttype, 9 as bettype, @v2mpositiontaking_9 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	2 as sporttype, 20 as bettype, @v2mpositiontaking_20 as maxpositiontaking,  0 as maxlivepositiontaking
			) as b on cs.sporttype=b.sporttype and cs.bettype = b.bettype
	where c.mrecommend = @custid and c.roleid = 1 and (cs.apositiontaking+cs.mpositiontaking>b.maxpositiontaking or (b.sporttype=1 and b.bettype in (1,3,7,8) and cs.alivepositiontaking+cs.mlivepositiontaking>b.maxlivepositiontaking))
	group by username
	if @ErrAcc<>''
	BEGIN
		select @ErrCode = 15
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Existing members exceeded new master positiontaking ('+@ErrAcc+') (for Basketball).'
							when 'CS' then N'现有会员超出新总代理占成数设定 ('+@ErrAcc+ N') (于篮球).'
							when 'CT' then N'現有會員超出新總代理佔成數設定 ('+@ErrAcc+ N') (於籃球).'
							when 'TH' then N'สมาชิกที่มีอยู่ในขณะนี้เกินกว่า จำนวนตัวแทนหลักรายใหม่ กำหนดไว้('+@ErrAcc+ N')(สำหรับกีฬาบาสเก็ตบอล).'
							when 'J' then N'Existing members exceeded new master positiontaking ('+@ErrAcc+ N') (for Basketball).'
							when 'KO' then N'회원의 거래조건 설정 범위를 넘어섰습니다 ('+@ErrAcc+ N') (농구).'
							else N'Existing members exceeded new master positiontaking ('+@ErrAcc+') (for Basketball).'
					end
		return
	END
	
	--check m3<=m4
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ cast((scs.mpositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '-MaxLive: '+ cast((scs.mlivepositiontaking) as varchar(10)) else '' end + '<br>'
	from custsetting as scs with (NOLOCK) inner join
		(
				 	select 1 as bettype, 2 as sporttype, @v2spositiontaking_1 as spositiontaking, 0 as slivepositiontaking, @v2mpositiontaking_1 as mpositiontaking, 0 as mlivepositiontaking, @auto_v2spositiontaking_1 as auto_spositiontaking,  0 as auto_slivepositiontaking
			union all 	select 2 as bettype, 2 as sporttype, @v2spositiontaking_2 as spositiontaking, 0 as slivepositiontaking, @v2mpositiontaking_2 as mpositiontaking, 0 as mlivepositiontaking, @auto_v2spositiontaking_2 as auto_spositiontaking,  0 as auto_slivepositiontaking
			union all 	select 3 as bettype, 2 as sporttype, @v2spositiontaking_3 as spositiontaking, 0 as slivepositiontaking, @v2mpositiontaking_3 as mpositiontaking, 0 as mlivepositiontaking, @auto_v2spositiontaking_3 as auto_spositiontaking,  0 as auto_slivepositiontaking
--			union all 	select 7 as bettype, 2 as sporttype, @v2spositiontaking_7 as spositiontaking, 0 as slivepositiontaking, @v2mpositiontaking_7 as mpositiontaking, 0 as mlivepositiontaking, @auto_v2spositiontaking_7 as auto_spositiontaking,  0 as auto_slivepositiontaking
--			union all 	select 8 as bettype, 2 as sporttype, @v2spositiontaking_8 as spositiontaking, 0 as slivepositiontaking, @v2mpositiontaking_8 as mpositiontaking, 0 as mlivepositiontaking, @auto_v2spositiontaking_8 as auto_spositiontaking,  0 as auto_slivepositiontaking
			union all 	select 9 as bettype, 2 as sporttype, @v2spositiontaking_9 as spositiontaking, 0 as slivepositiontaking, @v2mpositiontaking_9 as mpositiontaking, 0 as mlivepositiontaking, @auto_v2spositiontaking_9 as auto_spositiontaking,  0 as auto_slivepositiontaking
			union all 	select 20 as bettype, 2 as sporttype, @v2spositiontaking_20 as spositiontaking, 0 as slivepositiontaking, @v2mpositiontaking_20 as mpositiontaking, 0 as mlivepositiontaking, @auto_v2spositiontaking_20 as auto_spositiontaking,  0 as auto_slivepositiontaking
		) as b on scs.sporttype=b.sporttype and scs.bettype = b.bettype
		inner join sports with (nolock) on b.sporttype = sports.sporttype
		inner join bettype with (nolock) on b.bettype = bettype.typeid
	where scs.custid = @srecommend and (
						scs.mpositiontaking<b.mpositiontaking or (b.sporttype=1 and b.bettype in (1,3,7,8) and scs.mlivepositiontaking<b.mlivepositiontaking)
						)
	if @ErrType <>''
	BEGIN
		select @ErrCode = 16
		Select @ErrMsg = 	@UserName + ': '+
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
		inner join custsetting as cs with (NOLOCK) on c.custid = cs.custid
		inner join (
					select 	2 as sporttype, 1 as bettype, @v2mpositiontaking_1 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	2 as sporttype, 2 as bettype, @v2mpositiontaking_2 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	2 as sporttype, 3 as bettype, @v2mpositiontaking_3 as maxpositiontaking,  0 as maxlivepositiontaking
--				union all select 	2 as sporttype, 7 as bettype, @v2mpositiontaking_7 as maxpositiontaking,  0 as maxlivepositiontaking
--				union all select 	2 as sporttype, 8 as bettype, @v2mpositiontaking_8 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	2 as sporttype, 9 as bettype, @v2mpositiontaking_9 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	2 as sporttype, 20 as bettype, @v2mpositiontaking_20 as maxpositiontaking,  0 as maxlivepositiontaking
			) as b on cs.sporttype=b.sporttype and cs.bettype = b.bettype
	where c.mrecommend = @custid and c.roleid = 2 
		and (	cs.autompositiontaking > b.maxpositiontaking and cs.isautompositiontaking = 1
			)
	group by username
	if @ErrAcc<>''
	BEGIN
		select @ErrCode = 17
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Existing agents exceeded new master positiontaking ('+@ErrAcc+') (for Basketball).'
							when 'CS' then N'现有代理超出新总代理占成数设定 ('+@ErrAcc+ N') (于篮球).'
							when 'CT' then N'現有代理超出新總代理佔成數設定 ('+@ErrAcc+ N') (於籃球).'
							when 'TH' then N'ตัวแทนที่มีอยู่ขณะนี้เกินกว่าจำนวนตัวแทนหลักรายใหม่ ('+@ErrAcc+ N')(สำหรับกีฬาบาสเก็ตบอล)).'
							when 'J' then N'Existing agents exceeded new master positiontaking ('+@ErrAcc+ N') (for Basketball).'
							when 'KO' then N'에이전트의 거래조건 설정 법위를 넘어섰습니다 ('+@ErrAcc+ N') (농구).'
							else N'Existing agents exceeded new master positiontaking ('+@ErrAcc+ N') (for Basketball).'
					end
		return
	END
END


if @UpdateMultiple = 0 or @UpdatePositiontakingv3 = 1
BEGIN
	if 
		@v3spositiontaking_1  <0
		or @v3spositiontaking_2  <0
		or @v3spositiontaking_3  <0
		or @v3spositiontaking_20  <0
		
		or @v3spositiontaking_1+@v3mpositiontaking_1 >0.9
		or @v3spositiontaking_2+@v3mpositiontaking_2 >0.9
		or @v3spositiontaking_3+@v3mpositiontaking_3 >0.9
		or @v3spositiontaking_20+@v3mpositiontaking_20 >0.9
		
		or @auto_v3spositiontaking_1  >0.9
		or @auto_v3spositiontaking_2  >0.9
		or @auto_v3spositiontaking_3  >0.9
		or @auto_v3spositiontaking_20  >0.9
		
		or @v3mpositiontaking_1 <0
		or @v3mpositiontaking_2 <0
		or @v3mpositiontaking_3 <0
		or @v3mpositiontaking_20 <0
				
	BEGIN
		select @ErrCode = 11
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Wrong position taking (for Football).'
							when 'CS' then N'占成数不正确(于美式足球).'
							when 'CT' then N'佔成數不正確(於美式足球).'
							when 'TH' then N'การกำหนดไม่ถูกต้อง (สำหรับกีฬาอเมริกันฟุตบอล).'
							when 'J' then N'Wrong position taking (for Football).'
							when 'KO' then N'거래 조건이 잘못 되었습니다 (풋볼).'
							else N'Wrong position taking (for Football).'
					end
		return
	END

	--check n4<=s3+m3<=l4 if i3 = 0, 
	--m3<=l4 and u3+m3>=n4 if i3 = 1
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Min: '+ cast((co.minpositiontaking) as varchar(10))+ '-Max: '+ cast((co.maxpositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '--MinLive: '+ cast((co.minlivepositiontaking) as varchar(10))+ '-MaxLive: '+ cast((co.maxlivepositiontaking) as varchar(10)) else '' end + '<br>'
	from custoverride as co with (NOLOCK) inner join
		(
				 	select 1 as bettype, 3 as sporttype, @v3spositiontaking_1 as spositiontaking, 0 as slivepositiontaking, @v3mpositiontaking_1 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v3spositiontaking_1 as isauto_spositiontaking,  0 as isauto_slivepositiontaking, @auto_v3spositiontaking_1 as auto_spositiontaking
			union all 	select 2 as bettype, 3 as sporttype, @v3spositiontaking_2 as spositiontaking, 0 as slivepositiontaking, @v3mpositiontaking_2 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v3spositiontaking_2 as isauto_spositiontaking,  0 as isauto_slivepositiontaking, @auto_v3spositiontaking_2 as auto_spositiontaking
			union all 	select 3 as bettype, 3 as sporttype, @v3spositiontaking_3 as spositiontaking, 0 as slivepositiontaking, @v3mpositiontaking_3 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v3spositiontaking_3 as isauto_spositiontaking,  0 as isauto_slivepositiontaking, @auto_v3spositiontaking_3 as auto_spositiontaking
			union all 	select 20 as bettype, 3 as sporttype, @v3spositiontaking_20 as spositiontaking, 0 as slivepositiontaking, @v3mpositiontaking_20 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v3spositiontaking_20 as isauto_spositiontaking,  0 as isauto_slivepositiontaking, @auto_v3spositiontaking_20 as auto_spositiontaking

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
		Select @ErrMsg = 	case @Language 
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
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Min: '+ cast((co.minpositiontaking) as varchar(10))+ '-Max: '+ cast((co.maxpositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '--MinLive: '+ cast((co.minlivepositiontaking) as varchar(10))+ '-MaxLive: '+ cast((co.maxlivepositiontaking) as varchar(10)) else '' end + '<br>'
	from custoverride as co with (NOLOCK) inner join
		(
				 	select 1 as bettype, 3 as sporttype, @v3spositiontaking_1 as spositiontaking, 0 as slivepositiontaking, @v3mpositiontaking_1 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v3spositiontaking_1 as isauto_spositiontaking,  0 as isauto_slivepositiontaking
			union all 	select 2 as bettype, 3 as sporttype, @v3spositiontaking_2 as spositiontaking, 0 as slivepositiontaking, @v3mpositiontaking_2 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v3spositiontaking_2 as isauto_spositiontaking,  0 as isauto_slivepositiontaking
			union all 	select 3 as bettype, 3 as sporttype, @v3spositiontaking_3 as spositiontaking, 0 as slivepositiontaking, @v3mpositiontaking_3 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v3spositiontaking_3 as isauto_spositiontaking,  0 as isauto_slivepositiontaking
			union all 	select 20 as bettype, 3 as sporttype, @v3spositiontaking_20 as spositiontaking, 0 as slivepositiontaking, @v3mpositiontaking_20 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v3spositiontaking_20 as isauto_spositiontaking,  0 as isauto_slivepositiontaking
		) as b on co.sporttype=b.sporttype and co.bettype = b.bettype
		inner join sports with (nolock) on b.sporttype = sports.sporttype
		inner join bettype with (nolock) on b.bettype = bettype.typeid
	where co.custid = @custid and (	
						(b.mpositiontaking>co.maxpositiontaking or b.mpositiontaking<co.minpositiontaking) 
--						or (b.sporttype = 1 and b.bettype in (1,3,7,8) and (b.mlivepositiontaking>co.maxlivepositiontaking or b.mlivepositiontaking<co.minlivepositiontaking))
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
		inner join custsetting as cs with (NOLOCK) on c.custid = cs.custid
		inner join (
	
					select 	3 as sporttype, 1 as bettype, @v3mpositiontaking_1 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	3 as sporttype, 2 as bettype, @v3mpositiontaking_2 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	3 as sporttype, 3 as bettype, @v3mpositiontaking_3 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	3 as sporttype, 20 as bettype, @v3mpositiontaking_20 as maxpositiontaking,  0 as maxlivepositiontaking
			) as b on cs.sporttype=b.sporttype and cs.bettype = b.bettype
	where c.mrecommend = @custid and c.roleid = 2 and (cs.apositiontaking+cs.mpositiontaking>b.maxpositiontaking or (b.sporttype=1 and b.bettype in (1,3,7,8) and cs.alivepositiontaking+cs.mlivepositiontaking>b.maxlivepositiontaking))
	group by username
	if @ErrAcc<>''
	BEGIN
		select @ErrCode = 14
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Existing agents exceeded new master positiontaking ('+@ErrAcc+') (for Football).'
							when 'CS' then N'现有代理超出新总代理占成数设定 ('+@ErrAcc+ N') (于美式足球) .'
							when 'CT' then N'現有代理超出新總代理佔成數設定 ('+@ErrAcc+ N') (於美式足球).'
							when 'TH' then N' ตัวแทนที่มีอยู่ขณะนี้เกินกว่าจำนวนตัวแทนหลักรายใหม่ ('+@ErrAcc+ N')(สำหรับกีฬาอเมริกันฟุตบอล)).'
							when 'J' then N'Existing agents exceeded new master positiontaking ('+@ErrAcc+ N')(for Football).'
							when 'KO' then N'에이전트의 거래조건 설정 법위를 넘어섰습니다 ('+@ErrAcc+ N')(풋볼).'
							else N'Existing agents exceeded new master positiontaking ('+@ErrAcc+') (for Football).'
					end
		return
	END
	
	--m1+a1<=m3
	select @ErrAcc = ''
	select top 100 @ErrAcc = @ErrAcc + username +', '
	from 
		custinfo as c with (NOLOCK) 
		inner join custsetting as cs with (NOLOCK) on c.custid = cs.custid
		inner join (
	
					select 	3 as sporttype, 1 as bettype, @v3mpositiontaking_1 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	3 as sporttype, 2 as bettype, @v3mpositiontaking_2 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	3 as sporttype, 3 as bettype, @v3mpositiontaking_3 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	3 as sporttype, 20 as bettype, @v3mpositiontaking_20 as maxpositiontaking,  0 as maxlivepositiontaking
			) as b on cs.sporttype=b.sporttype and cs.bettype = b.bettype
	where c.mrecommend = @custid and c.roleid = 1 and (cs.apositiontaking+cs.mpositiontaking>b.maxpositiontaking or (b.sporttype=1 and b.bettype in (1,3,7,8) and cs.alivepositiontaking+cs.mlivepositiontaking>b.maxlivepositiontaking))
	group by username
	if @ErrAcc<>''
	BEGIN
		select @ErrCode = 15
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Existing members exceeded new master positiontaking ('+@ErrAcc+') (for Football).'
							when 'CS' then N'现有会员超出新总代理占成数设定 ('+@ErrAcc+ N') (于美式足球).'
							when 'CT' then N'現有會員超出新總代理佔成數設定 ('+@ErrAcc+ N') (於美式足球).'
							when 'TH' then N'สมาชิกที่มีอยู่ในขณะนี้เกินกว่า จำนวนตัวแทนหลักรายใหม่ กำหนดไว้ ('+@ErrAcc+ N')(สำหรับกีฬาอเมริกันฟุตบอล).'
							when 'J' then N'Existing members exceeded new master positiontaking ('+@ErrAcc+ N') (for Football).'
							when 'KO' then N'회원의 거래조건 설정 범위를 넘어섰습니다 ('+@ErrAcc+ N') (풋볼).'
							else N'Existing members exceeded new master positiontaking ('+@ErrAcc+') (for Football).'
					end
		return
	END
	
	--check m3<=m4
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ cast((scs.mpositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '-MaxLive: '+ cast((scs.mlivepositiontaking) as varchar(10)) else '' end + '<br>'
	from custsetting as scs with (NOLOCK) inner join
		(
				select 1 as bettype, 3 as sporttype, @v3spositiontaking_1 as spositiontaking, 0 as slivepositiontaking, @v3mpositiontaking_1 as mpositiontaking, 0 as mlivepositiontaking, @auto_v3spositiontaking_1 as auto_spositiontaking,  0 as auto_slivepositiontaking
			union all 	select 2 as bettype, 3 as sporttype, @v3spositiontaking_2 as spositiontaking, 0 as slivepositiontaking, @v3mpositiontaking_2 as mpositiontaking, 0 as mlivepositiontaking, @auto_v3spositiontaking_2 as auto_spositiontaking,  0 as auto_slivepositiontaking
			union all 	select 3 as bettype, 3 as sporttype, @v3spositiontaking_3 as spositiontaking, 0 as slivepositiontaking, @v3mpositiontaking_3 as mpositiontaking, 0 as mlivepositiontaking, @auto_v3spositiontaking_3 as auto_spositiontaking,  0 as auto_slivepositiontaking
			union all 	select 20 as bettype, 3 as sporttype, @v3spositiontaking_20 as spositiontaking, 0 as slivepositiontaking, @v3mpositiontaking_20 as mpositiontaking, 0 as mlivepositiontaking, @auto_v3spositiontaking_20 as auto_spositiontaking,  0 as auto_slivepositiontaking
		) as b on scs.sporttype=b.sporttype and scs.bettype = b.bettype
		inner join sports with (nolock) on b.sporttype = sports.sporttype
		inner join bettype with (nolock) on b.bettype = bettype.typeid
	where scs.custid = @srecommend and (
						scs.mpositiontaking<b.mpositiontaking or (b.sporttype=1 and b.bettype in (1,3,7,8) and scs.mlivepositiontaking<b.mlivepositiontaking)
						)
	if @ErrType <>''
	BEGIN
		select @ErrCode = 16
		Select @ErrMsg = @UserName + ': '+
					case @Language 
							when 'E' then 'Wrong position taking (max for master set by company).<br>'+@ErrType
							when 'CS' then N'占成数不正确(公司设给总代理最高占成).<br>'+@ErrType
							when 'CT' then N'佔成數不正確(公司設給總代理最高佔成).<br>'+@ErrType
							when 'TH' then N'การกำหนดจำนวนเงินไม่ถูกต้อง (สูงสุดไม่เกิน สำหรับรายการหลัก อ้างอิงจากรายการถ่ายทอดสด).<br>'+@ErrType
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
		inner join custsetting as cs with (NOLOCK) on c.custid = cs.custid
		inner join (
	
					select 	3 as sporttype, 1 as bettype, @v3mpositiontaking_1 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	3 as sporttype, 2 as bettype, @v3mpositiontaking_2 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	3 as sporttype, 3 as bettype, @v3mpositiontaking_3 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	3 as sporttype, 20 as bettype, @v3mpositiontaking_20 as maxpositiontaking,  0 as maxlivepositiontaking
			) as b on cs.sporttype=b.sporttype and cs.bettype = b.bettype
	where c.mrecommend = @custid and c.roleid = 2 
		and (	cs.autompositiontaking > b.maxpositiontaking and cs.isautompositiontaking = 1
			)
	group by username
	if @ErrAcc<>''
	BEGIN
		select @ErrCode = 17
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Existing agents exceeded new master positiontaking ('+@ErrAcc+') (for Football).'
							when 'CS' then N'现有代理超出新总代理占成数设定 ('+@ErrAcc+ N') (于美式足球) .'
							when 'CT' then N'現有代理超出新總代理佔成數設定 ('+@ErrAcc+ N') (於美式足球).'
							when 'TH' then N' ตัวแทนที่มีอยู่ขณะนี้เกินกว่าจำนวนตัวแทนหลักรายใหม่ ('+@ErrAcc+ N')(สำหรับกีฬาอเมริกันฟุตบอล)).'
							when 'J' then N'Existing agents exceeded new master positiontaking ('+@ErrAcc+ N')(for Football).'
							when 'KO' then N'에이전트의 거래조건 설정 법위를 넘어섰습니다 ('+@ErrAcc+ N')(풋볼).'
							else N'Existing agents exceeded new master positiontaking ('+@ErrAcc+') (for Football).'
					end
		return
	END
END



if @UpdateMultiple = 0 or @UpdatePositiontakingv5 = 1
BEGIN
	if 
		@v5spositiontaking_1  <0
		or @v5spositiontaking_2  <0
		or @v5spositiontaking_3  <0
		or @v5spositiontaking_20  <0
		
		or @v5spositiontaking_1+@v5mpositiontaking_1 >0.9
		or @v5spositiontaking_2+@v5mpositiontaking_2 >0.9
		or @v5spositiontaking_3+@v5mpositiontaking_3 >0.9
		or @v5spositiontaking_20+@v5mpositiontaking_20 >0.9
		
		or @auto_v5spositiontaking_1  >0.9
		or @auto_v5spositiontaking_2  >0.9
		or @auto_v5spositiontaking_3  >0.9
		or @auto_v5spositiontaking_20  >0.9
		
		or @v5mpositiontaking_1 <0
		or @v5mpositiontaking_2 <0
		or @v5mpositiontaking_3 <0
		or @v5mpositiontaking_20 <0
				
	BEGIN
		select @ErrCode = 11
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Wrong position taking (for Tennis).'
							when 'CS' then N'占成数不正确(于网球).'
							when 'CT' then N'佔成數不正確(於網球).'
							when 'TH' then N'การกำหนดไม่ถูกต้อง (สำหรับกีฬาเทนนิส).'
							when 'J' then N'Wrong position taking (for Tennis).'
							when 'KO' then N'거래 조건이 잘못 되었습니다 (테니스).'
							else N'Wrong position taking (for Tennis).'
					end
		return
	END

	--check n4<=s3+m3<=l4 if i3 = 0, 
	--m3<=l4 and u3+m3>=n4 if i3 = 1
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Min: '+ cast((co.minpositiontaking) as varchar(10))+ '-Max: '+ cast((co.maxpositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '--MinLive: '+ cast((co.minlivepositiontaking) as varchar(10))+ '-MaxLive: '+ cast((co.maxlivepositiontaking) as varchar(10)) else '' end + '<br>'
	from custoverride as co with (NOLOCK) inner join
		(
				 	select 1 as bettype, 5 as sporttype, @v5spositiontaking_1 as spositiontaking, 0 as slivepositiontaking, @v5mpositiontaking_1 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v5spositiontaking_1 as isauto_spositiontaking,  0 as isauto_slivepositiontaking, @auto_v5spositiontaking_1 as auto_spositiontaking
			union all 	select 2 as bettype, 5 as sporttype, @v5spositiontaking_2 as spositiontaking, 0 as slivepositiontaking, @v5mpositiontaking_2 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v5spositiontaking_2 as isauto_spositiontaking,  0 as isauto_slivepositiontaking, @auto_v5spositiontaking_2 as auto_spositiontaking
			union all 	select 3 as bettype, 5 as sporttype, @v5spositiontaking_3 as spositiontaking, 0 as slivepositiontaking, @v5mpositiontaking_3 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v5spositiontaking_3 as isauto_spositiontaking,  0 as isauto_slivepositiontaking, @auto_v5spositiontaking_3 as auto_spositiontaking
			union all 	select 20 as bettype, 5 as sporttype, @v5spositiontaking_20 as spositiontaking, 0 as slivepositiontaking, @v5mpositiontaking_20 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v5spositiontaking_20 as isauto_spositiontaking,  0 as isauto_slivepositiontaking, @auto_v5spositiontaking_20 as auto_spositiontaking

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
		Select @ErrMsg = 	case @Language 
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
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Min: '+ cast((co.minpositiontaking) as varchar(10))+ '-Max: '+ cast((co.maxpositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '--MinLive: '+ cast((co.minlivepositiontaking) as varchar(10))+ '-MaxLive: '+ cast((co.maxlivepositiontaking) as varchar(10)) else '' end + '<br>'
	from custoverride as co with (NOLOCK) inner join
		(
				 	select 1 as bettype, 5 as sporttype, @v5spositiontaking_1 as spositiontaking, 0 as slivepositiontaking, @v5mpositiontaking_1 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v5spositiontaking_1 as isauto_spositiontaking,  0 as isauto_slivepositiontaking
			union all 	select 2 as bettype, 5 as sporttype, @v5spositiontaking_2 as spositiontaking, 0 as slivepositiontaking, @v5mpositiontaking_2 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v5spositiontaking_2 as isauto_spositiontaking,  0 as isauto_slivepositiontaking
			union all 	select 3 as bettype, 5 as sporttype, @v5spositiontaking_3 as spositiontaking, 0 as slivepositiontaking, @v5mpositiontaking_3 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v5spositiontaking_3 as isauto_spositiontaking,  0 as isauto_slivepositiontaking
			union all 	select 20 as bettype, 5 as sporttype, @v5spositiontaking_20 as spositiontaking, 0 as slivepositiontaking, @v5mpositiontaking_20 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v5spositiontaking_20 as isauto_spositiontaking,  0 as isauto_slivepositiontaking
		) as b on co.sporttype=b.sporttype and co.bettype = b.bettype
		inner join sports with (nolock) on b.sporttype = sports.sporttype
		inner join bettype with (nolock) on b.bettype = bettype.typeid
	where co.custid = @custid and (	
						(b.mpositiontaking>co.maxpositiontaking or b.mpositiontaking<co.minpositiontaking) 
--						or (b.sporttype = 1 and b.bettype in (1,3,7,8) and (b.mlivepositiontaking>co.maxlivepositiontaking or b.mlivepositiontaking<co.minlivepositiontaking))
					)
	if @ErrType <>''
	BEGIN
		select @ErrCode = 13
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

	--m2+a2<=m3
	select @ErrAcc = ''
	select top 100 @ErrAcc = @ErrAcc + username +', '
	from 
		custinfo as c with (NOLOCK) 
		inner join custsetting as cs with (NOLOCK) on c.custid = cs.custid
		inner join (
	
					select 	5 as sporttype, 1 as bettype, @v5mpositiontaking_1 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	5 as sporttype, 2 as bettype, @v5mpositiontaking_2 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	5 as sporttype, 3 as bettype, @v5mpositiontaking_3 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	5 as sporttype, 20 as bettype, @v5mpositiontaking_20 as maxpositiontaking,  0 as maxlivepositiontaking
			) as b on cs.sporttype=b.sporttype and cs.bettype = b.bettype
	where c.mrecommend = @custid and c.roleid = 2 and (cs.apositiontaking+cs.mpositiontaking>b.maxpositiontaking or (b.sporttype=1 and b.bettype in (1,3,7,8) and cs.alivepositiontaking+cs.mlivepositiontaking>b.maxlivepositiontaking))
	group by username
	if @ErrAcc<>''
	BEGIN
		select @ErrCode = 14
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Existing agents exceeded new master positiontaking ('+@ErrAcc+') (for Tennis).'
							when 'CS' then N'现有代理超出新总代理占成数设定 ('+@ErrAcc+ N') (于网球).'
							when 'CT' then N'現有代理超出新總代理佔成數設定 ('+@ErrAcc+ N') (於網球).'
							when 'TH' then N'ตัวแทนที่มีอยู่ขณะนี้เกินกว่าจำนวนตัวแทนหลักรายใหม่('+@ErrAcc+ N')( สำหรับเทนนิส ).'
							when 'J' then N'Existing agents exceeded new master positiontaking ('+@ErrAcc+ N') (for Tennis).'
							when 'KO' then N'에이전트의 거래조건 설정 법위를 넘어섰습니다 ('+@ErrAcc+ N') (테니스).'
							else N'Existing agents exceeded new master positiontaking ('+@ErrAcc+') (for Tennis).'
					end
		return
	END

	--m1+a1<=m3
	select @ErrAcc = ''
	select top 100 @ErrAcc = @ErrAcc + username +', '
	from 
		custinfo as c with (NOLOCK) 
		inner join custsetting as cs with (NOLOCK) on c.custid = cs.custid
		inner join (
	
					select 	5 as sporttype, 1 as bettype, @v5mpositiontaking_1 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	5 as sporttype, 2 as bettype, @v5mpositiontaking_2 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	5 as sporttype, 3 as bettype, @v5mpositiontaking_3 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	5 as sporttype, 20 as bettype, @v5mpositiontaking_20 as maxpositiontaking,  0 as maxlivepositiontaking
			) as b on cs.sporttype=b.sporttype and cs.bettype = b.bettype
	where c.mrecommend = @custid and c.roleid = 1 and (cs.apositiontaking+cs.mpositiontaking>b.maxpositiontaking or (b.sporttype=1 and b.bettype in (1,3,7,8) and cs.alivepositiontaking+cs.mlivepositiontaking>b.maxlivepositiontaking))
	group by username
	if @ErrAcc<>''
	BEGIN
		select @ErrCode = 15
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Existing members exceeded new master positiontaking ('+@ErrAcc+') (for Tennis).'
							when 'CS' then N'现有会员超出新总代理占成数设定 ('+@ErrAcc+ N') (于网球).'
							when 'CT' then N'現有會員超出新總代理佔成數設定 ('+@ErrAcc+ N') (於網球).'
							when 'TH' then N' สมาชิกที่มีอยู่ในขณะนี้เกินกว่า จำนวนตัวแทนหลักรายใหม่ กำหนดไว้('+@ErrAcc+ N')(สำหรับกีฬาเทนนิส).'
							when 'J' then N'Existing members exceeded new master positiontaking ('+@ErrAcc+ N') (for Tennis).'
							when 'KO' then N'회원의 거래조건 설정 범위를 넘어섰습니다 ('+@ErrAcc+ N') (테니스).'
							else N'Existing members exceeded new master positiontaking ('+@ErrAcc+') (for Tennis).'
					end
		return
	END
	
	--check m3<=m4
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ cast((scs.mpositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '-MaxLive: '+ cast((scs.mlivepositiontaking) as varchar(10)) else '' end + '<br>'
	from custsetting as scs with (NOLOCK) inner join
		(
				 	select 1 as bettype, 5 as sporttype, @v5spositiontaking_1 as spositiontaking, 0 as slivepositiontaking, @v5mpositiontaking_1 as mpositiontaking, 0 as mlivepositiontaking, @auto_v5spositiontaking_1 as auto_spositiontaking,  0 as auto_slivepositiontaking
			union all 	select 2 as bettype, 5 as sporttype, @v5spositiontaking_2 as spositiontaking, 0 as slivepositiontaking, @v5mpositiontaking_2 as mpositiontaking, 0 as mlivepositiontaking, @auto_v5spositiontaking_2 as auto_spositiontaking,  0 as auto_slivepositiontaking
			union all 	select 3 as bettype, 5 as sporttype, @v5spositiontaking_3 as spositiontaking, 0 as slivepositiontaking, @v5mpositiontaking_3 as mpositiontaking, 0 as mlivepositiontaking, @auto_v5spositiontaking_3 as auto_spositiontaking,  0 as auto_slivepositiontaking
			union all 	select 20 as bettype, 5 as sporttype, @v5spositiontaking_20 as spositiontaking, 0 as slivepositiontaking, @v5mpositiontaking_20 as mpositiontaking, 0 as mlivepositiontaking, @auto_v5spositiontaking_20 as auto_spositiontaking,  0 as auto_slivepositiontaking
		) as b on scs.sporttype=b.sporttype and scs.bettype = b.bettype
		inner join sports with (nolock) on b.sporttype = sports.sporttype
		inner join bettype with (nolock) on b.bettype = bettype.typeid
	where scs.custid = @srecommend and (
						scs.mpositiontaking<b.mpositiontaking or (b.sporttype=1 and b.bettype in (1,3,7,8) and scs.mlivepositiontaking<b.mlivepositiontaking)
						)
	if @ErrType <>''
	BEGIN
		select @ErrCode = 16
		Select @ErrMsg = @UserName + ': '+
					case @Language 
							when 'E' then 'Wrong position taking (max for master set by company).<br>'+@ErrType
							when 'CS' then N'占成数不正确(公司设给总代理最高占成).<br>'+@ErrType
							when 'CT' then N'佔成數不正確(公司設給總代理最高佔成).<br>'+@ErrType
							when 'TH' then N'การกำหนดจำนวนเงินไม่ถูกต้อง (สูงสุดไม่เกิน สำหรับรายการหลัก อ้างอิงจากรายการถ่ายทอดสด).<br>'+@ErrType
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
		inner join custsetting as cs with (NOLOCK) on c.custid = cs.custid
		inner join (
					select 	5 as sporttype, 1 as bettype, @v5mpositiontaking_1 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	5 as sporttype, 2 as bettype, @v5mpositiontaking_2 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	5 as sporttype, 3 as bettype, @v5mpositiontaking_3 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	5 as sporttype, 20 as bettype, @v5mpositiontaking_20 as maxpositiontaking,  0 as maxlivepositiontaking
			) as b on cs.sporttype=b.sporttype and cs.bettype = b.bettype
	where c.mrecommend = @custid and c.roleid = 2 
		and (	cs.autompositiontaking > b.maxpositiontaking and cs.isautompositiontaking = 1
			)
	group by username
	if @ErrAcc<>''
	BEGIN
		select @ErrCode = 17
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Existing agents exceeded new master positiontaking ('+@ErrAcc+') (for Tennis).'
							when 'CS' then N'现有代理超出新总代理占成数设定 ('+@ErrAcc+ N') (于网球).'
							when 'CT' then N'現有代理超出新總代理佔成數設定 ('+@ErrAcc+ N') (於網球).'
							when 'TH' then N'ตัวแทนที่มีอยู่ขณะนี้เกินกว่าจำนวนตัวแทนหลักรายใหม่('+@ErrAcc+ N')( สำหรับเทนนิส ).'
							when 'J' then N'Existing agents exceeded new master positiontaking ('+@ErrAcc+ N') (for Tennis).'
							when 'KO' then N'에이전트의 거래조건 설정 법위를 넘어섰습니다 ('+@ErrAcc+ N') (테니스).'
							else N'Existing agents exceeded new master positiontaking ('+@ErrAcc+') (for Tennis).'
					end
		return
	END
END



if @UpdateMultiple = 0 or @UpdatePositiontakingv8 = 1
BEGIN
	if 
		@v8spositiontaking_1  <0
		or @v8spositiontaking_3  <0
		or @v8spositiontaking_20  <0
		
		or @v8spositiontaking_1+@v8mpositiontaking_1 >0.9
		or @v8spositiontaking_3+@v8mpositiontaking_3 >0.9
		or @v8spositiontaking_20+@v8mpositiontaking_20 >0.9
		
		or @auto_v8spositiontaking_1  >0.9
		or @auto_v8spositiontaking_3  >0.9
		or @auto_v8spositiontaking_20  >0.9
		
		or @v8mpositiontaking_1 <0
		or @v8mpositiontaking_3 <0
		or @v8mpositiontaking_20 <0
				
	BEGIN
		select @ErrCode = 11
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Wrong position taking (for Baseball).'
							when 'CS' then N'占成数不正确(于棒球).'
							when 'CT' then N'佔成數不正確(於棒球).'
							when 'TH' then N'การกำหนดจำนวนเงินไม่ถูกต้อง (สำหรับกีฬาเบสบอล).'
							when 'J' then N'Wrong position taking (for Baseball).'
							when 'KO' then N'거래 조건이 잘못 되었습니다 (야구).'
							else N'Wrong position taking (for Baseball).'
					end
		return
	END

	--check n4<=s3+m3<=l4 if i3 = 0, 
	--m3<=l4 and u3+m3>=n4 if i3 = 1
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Min: '+ cast((co.minpositiontaking) as varchar(10))+ '-Max: '+ cast((co.maxpositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '--MinLive: '+ cast((co.minlivepositiontaking) as varchar(10))+ '-MaxLive: '+ cast((co.maxlivepositiontaking) as varchar(10)) else '' end + '<br>'
	from custoverride as co with (NOLOCK) inner join
		(
				 	select 1 as bettype, 8 as sporttype, @v8spositiontaking_1 as spositiontaking, 0 as slivepositiontaking, @v8mpositiontaking_1 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v8spositiontaking_1 as isauto_spositiontaking,  0 as isauto_slivepositiontaking, @auto_v8spositiontaking_1 as auto_spositiontaking
			union all 	select 3 as bettype, 8 as sporttype, @v8spositiontaking_3 as spositiontaking, 0 as slivepositiontaking, @v8mpositiontaking_3 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v8spositiontaking_3 as isauto_spositiontaking,  0 as isauto_slivepositiontaking, @auto_v8spositiontaking_3 as auto_spositiontaking
			union all 	select 20 as bettype, 8 as sporttype, @v8spositiontaking_20 as spositiontaking, 0 as slivepositiontaking, @v8mpositiontaking_20 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v8spositiontaking_20 as isauto_spositiontaking,  0 as isauto_slivepositiontaking, @auto_v8spositiontaking_20 as auto_spositiontaking

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
		Select @ErrMsg = 	case @Language
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
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Min: '+ cast((co.minpositiontaking) as varchar(10))+ '-Max: '+ cast((co.maxpositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '--MinLive: '+ cast((co.minlivepositiontaking) as varchar(10))+ '-MaxLive: '+ cast((co.maxlivepositiontaking) as varchar(10)) else '' end + '<br>'
	from custoverride as co with (NOLOCK) inner join
		(
				 	select 1 as bettype, 8 as sporttype, @v8spositiontaking_1 as spositiontaking, 0 as slivepositiontaking, @v8mpositiontaking_1 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v8spositiontaking_1 as isauto_spositiontaking,  0 as isauto_slivepositiontaking
			union all 	select 3 as bettype, 8 as sporttype, @v8spositiontaking_3 as spositiontaking, 0 as slivepositiontaking, @v8mpositiontaking_3 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v8spositiontaking_3 as isauto_spositiontaking,  0 as isauto_slivepositiontaking
			union all 	select 20 as bettype, 8 as sporttype, @v8spositiontaking_20 as spositiontaking, 0 as slivepositiontaking, @v8mpositiontaking_20 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v8spositiontaking_20 as isauto_spositiontaking,  0 as isauto_slivepositiontaking
		) as b on co.sporttype=b.sporttype and co.bettype = b.bettype
		inner join sports with (nolock) on b.sporttype = sports.sporttype
		inner join bettype with (nolock) on b.bettype = bettype.typeid
	where co.custid = @custid and (	
						(b.mpositiontaking>co.maxpositiontaking or b.mpositiontaking<co.minpositiontaking) 
--						or (b.sporttype = 1 and b.bettype in (1,3,7,8) and (b.mlivepositiontaking>co.maxlivepositiontaking or b.mlivepositiontaking<co.minlivepositiontaking))
					)
	if @ErrType <>''
	BEGIN
		select @ErrCode = 13
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
	--m2+a2<=m3
	select @ErrAcc = ''
	select top 100 @ErrAcc = @ErrAcc + username +', '
	from 
		custinfo as c with (NOLOCK) 
		inner join custsetting as cs with (NOLOCK) on c.custid = cs.custid
		inner join (
	
					select 	8 as sporttype, 1 as bettype, @v8mpositiontaking_1 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	8 as sporttype, 3 as bettype, @v8mpositiontaking_3 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	8 as sporttype, 20 as bettype, @v8mpositiontaking_20 as maxpositiontaking,  0 as maxlivepositiontaking
			) as b on cs.sporttype=b.sporttype and cs.bettype = b.bettype
	where c.mrecommend = @custid and c.roleid = 2 and (cs.apositiontaking+cs.mpositiontaking>b.maxpositiontaking or (b.sporttype=1 and b.bettype in (1,3,7,8) and cs.alivepositiontaking+cs.mlivepositiontaking>b.maxlivepositiontaking))
	group by username
	if @ErrAcc<>''
	BEGIN
		select @ErrCode = 14
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Existing agents exceeded new master positiontaking ('+@ErrAcc+') (for Baseball).'
							when 'CS' then N'现有代理超出新总代理占成数设定 ('+@ErrAcc+ N') (于棒球).'
							when 'CT' then N'現有代理超出新總代理佔成數設定 ('+@ErrAcc+ N') (於棒球).'
							when 'TH' then N'ตัวแทนที่มีอยู่ขณะนี้เกินกว่าจำนวนตัวแทนหลักรายใหม่ ('+@ErrAcc+ N')(สำหรับกีฬาเบสบอล).'
							when 'J' then N'Existing agents exceeded new master positiontaking ('+@ErrAcc+ N') (for Baseball).'
							when 'KO' then N'에이전트의 거래조건 설정 법위를 넘어섰습니다 ('+@ErrAcc+ N') (야구).'
							else N'Existing agents exceeded new master positiontaking ('+@ErrAcc+ N') (for Baseball).'
					end
		return
	END
	--m1+a1<=m3
	select @ErrAcc = ''
	select top 100 @ErrAcc = @ErrAcc + username +', '
	from 
		custinfo as c with (NOLOCK) 
		inner join custsetting as cs with (NOLOCK) on c.custid = cs.custid
		inner join (
	
					select 	8 as sporttype, 1 as bettype, @v8mpositiontaking_1 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	8 as sporttype, 3 as bettype, @v8mpositiontaking_3 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	8 as sporttype, 20 as bettype, @v8mpositiontaking_20 as maxpositiontaking,  0 as maxlivepositiontaking
			) as b on cs.sporttype=b.sporttype and cs.bettype = b.bettype
	where c.mrecommend = @custid and c.roleid = 1 and (cs.apositiontaking+cs.mpositiontaking>b.maxpositiontaking or (b.sporttype=1 and b.bettype in (1,3,7,8) and cs.alivepositiontaking+cs.mlivepositiontaking>b.maxlivepositiontaking))
	group by username
	if @ErrAcc<>''
	BEGIN
		select @ErrCode = 15
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Existing members exceeded new master positiontaking ('+@ErrAcc+') (for Baseball).'
							when 'CS' then N'现有会员超出新总代理占成数设定 ('+@ErrAcc+ N')(于棒球).'
							when 'CT' then N'現有會員超出新總代理佔成數設定 ('+@ErrAcc+ N') (於棒球).'
							when 'TH' then N'สมาชิกที่มีอยู่ในขณะนี้เกินกว่า จำนวนตัวแทนหลักรายใหม่ กำหนดไว้ ('+@ErrAcc+ N')(สำหรับกีฬาเบสบอล).'
							when 'J' then N'Existing members exceeded new master positiontaking ('+@ErrAcc+ N') (for Baseball).'
							when 'KO' then N'회원의 거래조건 설정 범위를 넘어섰습니다 ('+@ErrAcc+ N') (야구).'
							else N'Existing members exceeded new master positiontaking ('+@ErrAcc+ N') (for Baseball).'
					end
		return
	END
	
	--check m3<=m4
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ cast((scs.mpositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '-MaxLive: '+ cast((scs.mlivepositiontaking) as varchar(10)) else '' end + '<br>'
	from custsetting as scs with (NOLOCK) inner join
		(
				 	select 1 as bettype, 8 as sporttype, @v8spositiontaking_1 as spositiontaking, 0 as slivepositiontaking, @v8mpositiontaking_1 as mpositiontaking, 0 as mlivepositiontaking, @auto_v8spositiontaking_1 as auto_spositiontaking,  0 as auto_slivepositiontaking
			union all 	select 3 as bettype, 8 as sporttype, @v8spositiontaking_3 as spositiontaking, 0 as slivepositiontaking, @v8mpositiontaking_3 as mpositiontaking, 0 as mlivepositiontaking, @auto_v8spositiontaking_3 as auto_spositiontaking,  0 as auto_slivepositiontaking
			union all 	select 20 as bettype, 8 as sporttype, @v8spositiontaking_20 as spositiontaking, 0 as slivepositiontaking, @v8mpositiontaking_20 as mpositiontaking, 0 as mlivepositiontaking, @auto_v8spositiontaking_20 as auto_spositiontaking,  0 as auto_slivepositiontaking
		) as b on scs.sporttype=b.sporttype and scs.bettype = b.bettype
		inner join sports with (nolock) on b.sporttype = sports.sporttype
		inner join bettype with (nolock) on b.bettype = bettype.typeid
	where scs.custid = @srecommend and (
						scs.mpositiontaking<b.mpositiontaking or (b.sporttype=1 and b.bettype in (1,3,7,8) and scs.mlivepositiontaking<b.mlivepositiontaking)
						)
	if @ErrType <>''
	BEGIN
		select @ErrCode = 16
		Select @ErrMsg = 	@UserName + ': '+
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
		inner join custsetting as cs with (NOLOCK) on c.custid = cs.custid
		inner join (
					select 	8 as sporttype, 1 as bettype, @v8mpositiontaking_1 as maxpositiontaking,  0 as maxlivepositiontaking
					union all select 	8 as sporttype, 3 as bettype, @v8mpositiontaking_3 as maxpositiontaking,  0 as maxlivepositiontaking
					union all select 	8 as sporttype, 20 as bettype, @v8mpositiontaking_20 as maxpositiontaking,  0 as maxlivepositiontaking
			) as b on cs.sporttype=b.sporttype and cs.bettype = b.bettype
	where c.mrecommend = @custid and c.roleid = 2 
		and (	cs.autompositiontaking > b.maxpositiontaking and cs.isautompositiontaking = 1
			)
	group by username
	if @ErrAcc<>''
	BEGIN
		select @ErrCode = 17
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Existing agents exceeded new master positiontaking ('+@ErrAcc+') (for Baseball).'
							when 'CS' then N'现有代理超出新总代理占成数设定 ('+@ErrAcc+ N') (于棒球).'
							when 'CT' then N'現有代理超出新總代理佔成數設定 ('+@ErrAcc+ N') (於棒球).'
							when 'TH' then N'ตัวแทนที่มีอยู่ขณะนี้เกินกว่าจำนวนตัวแทนหลักรายใหม่ ('+@ErrAcc+ N')(สำหรับกีฬาเบสบอล).'
							when 'J' then N'Existing agents exceeded new master positiontaking ('+@ErrAcc+ N') (for Baseball).'
							when 'KO' then N'에이전트의 거래조건 설정 법위를 넘어섰습니다 ('+@ErrAcc+ N') (야구).'
							else N'Existing agents exceeded new master positiontaking ('+@ErrAcc+ N') (for Baseball).'
					end
		return
	END

END


if @UpdateMultiple = 0 or @UpdatePositiontakingv10 = 1
BEGIN
	if 
		@v10spositiontaking_1  <0
		or @v10spositiontaking_2  <0
		or @v10spositiontaking_3  <0
		or @v10spositiontaking_20  <0
		
		or @v10spositiontaking_1+@v10mpositiontaking_1 >0.9
		or @v10spositiontaking_2+@v10mpositiontaking_2 >0.9
		or @v10spositiontaking_3+@v10mpositiontaking_3 >0.9
		or @v10spositiontaking_20+@v10mpositiontaking_20 >0.9
		
		or @auto_v10spositiontaking_1  >0.9
		or @auto_v10spositiontaking_2  >0.9
		or @auto_v10spositiontaking_3  >0.9
		or @auto_v10spositiontaking_20  >0.9
		
		or @v10mpositiontaking_1 <0
		or @v10mpositiontaking_2 <0
		or @v10mpositiontaking_3 <0
		or @v10mpositiontaking_20 <0
				
	BEGIN
		select @ErrCode = 11
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Wrong position taking (for Golf).'
							when 'CS' then N'占成数不正确(于高尔夫球).'
							when 'CT' then N'佔成數不正確(於高爾夫球).'
							when 'TH' then N'การกำหนดไม่ถูกต้อง (สำหรับกีฬากอฟล์).'
							when 'J' then N'Wrong position taking (for Golf).'
							when 'KO' then N'거래 조건이 잘못 되었습니다 (골프).'
							else N'Wrong position taking (for Golf).'
					end
		return
	END

	--check n4<=s3+m3<=l4 if i3 = 0, 
	--m3<=l4 and u3+m3>=n4 if i3 = 1
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Min: '+ cast((co.minpositiontaking) as varchar(10))+ '-Max: '+ cast((co.maxpositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '--MinLive: '+ cast((co.minlivepositiontaking) as varchar(10))+ '-MaxLive: '+ cast((co.maxlivepositiontaking) as varchar(10)) else '' end + '<br>'
	from custoverride as co with (NOLOCK) inner join
		(
				 	select 1 as bettype, 10 as sporttype, @v10spositiontaking_1 as spositiontaking, 0 as slivepositiontaking, @v10mpositiontaking_1 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v10spositiontaking_1 as isauto_spositiontaking,  0 as isauto_slivepositiontaking, @auto_v10spositiontaking_1 as auto_spositiontaking
			union all 	select 2 as bettype, 10 as sporttype, @v10spositiontaking_2 as spositiontaking, 0 as slivepositiontaking, @v10mpositiontaking_2 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v10spositiontaking_2 as isauto_spositiontaking,  0 as isauto_slivepositiontaking, @auto_v10spositiontaking_2 as auto_spositiontaking
			union all 	select 3 as bettype, 10 as sporttype, @v10spositiontaking_3 as spositiontaking, 0 as slivepositiontaking, @v10mpositiontaking_3 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v10spositiontaking_3 as isauto_spositiontaking,  0 as isauto_slivepositiontaking, @auto_v10spositiontaking_3 as auto_spositiontaking
			union all 	select 20 as bettype, 10 as sporttype, @v10spositiontaking_20 as spositiontaking, 0 as slivepositiontaking, @v10mpositiontaking_20 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v10spositiontaking_20 as isauto_spositiontaking,  0 as isauto_slivepositiontaking, @auto_v10spositiontaking_20 as auto_spositiontaking

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
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Wrong position taking (min/max set by company).<br>'+@ErrType
							when 'CS' then N'占成数不正确(公司设给最低/高占成).<br>'+@ErrType
							when 'CT' then N'佔成數不正確(公司設給最低/高佔成).<br>'+@ErrType
							when 'TH' then N'การกำหนดจำนวนเงินไม่ถูกต้อง (สูงสุด  อ้างอิงจากข้อมูลบริษัท).<br>'+@ErrType
							when 'J' then N'Wrong position taking (min/max set by company).<br>'+@ErrType
							when 'KO' then N'거래 조건이 잘못 되었습니다 (ibc가 설정한 최소값/최대값).<br>'+@ErrType
							else N'Wrong position taking (min/max set by company).<br>'+@ErrType
					end
		return
	END
	--n3<=m3<=l3
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Min: '+ cast((co.minpositiontaking) as varchar(10))+ '-Max: '+ cast((co.maxpositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '--MinLive: '+ cast((co.minlivepositiontaking) as varchar(10))+ '-MaxLive: '+ cast((co.maxlivepositiontaking) as varchar(10)) else '' end + '<br>'
	from custoverride as co with (NOLOCK) inner join
		(
				 	select 1 as bettype, 10 as sporttype, @v10spositiontaking_1 as spositiontaking, 0 as slivepositiontaking, @v10mpositiontaking_1 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v10spositiontaking_1 as isauto_spositiontaking,  0 as isauto_slivepositiontaking
			union all 	select 2 as bettype, 10 as sporttype, @v10spositiontaking_2 as spositiontaking, 0 as slivepositiontaking, @v10mpositiontaking_2 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v10spositiontaking_2 as isauto_spositiontaking,  0 as isauto_slivepositiontaking
			union all 	select 3 as bettype, 10 as sporttype, @v10spositiontaking_3 as spositiontaking, 0 as slivepositiontaking, @v10mpositiontaking_3 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v10spositiontaking_3 as isauto_spositiontaking,  0 as isauto_slivepositiontaking
			union all 	select 20 as bettype, 10 as sporttype, @v10spositiontaking_20 as spositiontaking, 0 as slivepositiontaking, @v10mpositiontaking_20 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v10spositiontaking_20 as isauto_spositiontaking,  0 as isauto_slivepositiontaking
		) as b on co.sporttype=b.sporttype and co.bettype = b.bettype
		inner join sports with (nolock) on b.sporttype = sports.sporttype
		inner join bettype with (nolock) on b.bettype = bettype.typeid
	where co.custid = @custid and (	
						(b.mpositiontaking>co.maxpositiontaking or b.mpositiontaking<co.minpositiontaking) 
--						or (b.sporttype = 1 and b.bettype in (1,3,7,8) and (b.mlivepositiontaking>co.maxlivepositiontaking or b.mlivepositiontaking<co.minlivepositiontaking))
					)
	if @ErrType <>''
	BEGIN
		select @ErrCode = 13
		Select @ErrMsg = 	@UserName + ': '+
					case @Language 
							when 'E' then 'Wrong position taking (min/max set by company).<br>'+@ErrType
							when 'CS' then N'占成数不正确(公司设给最低/高占成).<br>'+@ErrType
							when 'CT' then N'佔成數不正確(公司設給最低/高佔成).<br>'+@ErrType
							when 'TH' then N'การกำหนดจำนวนเงินไม่ถูกต้อง (สูงสุด  อ้างอิงจากข้อมูลบริษัท).<br>'+@ErrType
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
		inner join custsetting as cs with (NOLOCK) on c.custid = cs.custid
		inner join (
	
					select 	10 as sporttype, 1 as bettype, @v10mpositiontaking_1 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	10 as sporttype, 2 as bettype, @v10mpositiontaking_2 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	10 as sporttype, 3 as bettype, @v10mpositiontaking_3 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	10 as sporttype, 20 as bettype, @v10mpositiontaking_20 as maxpositiontaking,  0 as maxlivepositiontaking
			) as b on cs.sporttype=b.sporttype and cs.bettype = b.bettype
	where c.mrecommend = @custid and c.roleid = 2 and (cs.apositiontaking+cs.mpositiontaking>b.maxpositiontaking or (b.sporttype=1 and b.bettype in (1,3,7,8) and cs.alivepositiontaking+cs.mlivepositiontaking>b.maxlivepositiontaking))
	group by username
	if @ErrAcc<>''
	BEGIN
		select @ErrCode = 14
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Existing agents exceeded new master positiontaking ('+@ErrAcc+') (for Golf).'
							when 'CS' then N'现有代理超出新总代理占成数设定 ('+@ErrAcc+ N') (于高尔夫球).'
							when 'CT' then N'現有代理超出新總代理佔成數設定 ('+@ErrAcc+ N') (於高爾夫球).'
							when 'TH' then N'ตัวแทนที่มีอยู่ขณะนี้เกินกว่าจำนวนตัวแทนหลักรายใหม่ ('+@ErrAcc+ N')(สำหรับกีฬารถแข่ง).'
							when 'J' then N'Existing agents exceeded new master positiontaking ('+@ErrAcc+ N')(for Golf) .'
							when 'KO' then N'에이전트의 거래조건 설정 법위를 넘어섰습니다 ('+@ErrAcc+ N')(골프) .'
							else N'Existing agents exceeded new master positiontaking ('+@ErrAcc+ N') (for Golf).'
					end
		return
	END
	--m1+a1<=m3
	select @ErrAcc = ''
	select top 100 @ErrAcc = @ErrAcc + username +', '
	from 
		customer as c with (NOLOCK) 
		inner join custsetting as cs with (NOLOCK) on c.custid = cs.custid
		inner join (
	
					select 	10 as sporttype, 1 as bettype, @v10mpositiontaking_1 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	10 as sporttype, 2 as bettype, @v10mpositiontaking_2 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	10 as sporttype, 3 as bettype, @v10mpositiontaking_3 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	10 as sporttype, 20 as bettype, @v10mpositiontaking_20 as maxpositiontaking,  0 as maxlivepositiontaking
			) as b on cs.sporttype=b.sporttype and cs.bettype = b.bettype
	where c.mrecommend = @custid and c.roleid = 1 and (cs.apositiontaking+cs.mpositiontaking>b.maxpositiontaking or (b.sporttype=1 and b.bettype in (1,3,7,8) and cs.alivepositiontaking+cs.mlivepositiontaking>b.maxlivepositiontaking))
	group by username
	if @ErrAcc<>''
	BEGIN
		select @ErrCode = 15
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Existing members exceeded new master positiontaking ('+@ErrAcc+') (for Golf).'
							when 'CS' then N'现有会员超出新总代理占成数设定 ('+@ErrAcc+ N') (于高尔夫球).'
							when 'CT' then N'現有會員超出新總代理佔成數設定 ('+@ErrAcc+ N') (於高爾夫球).'
							when 'TH' then N' สมาชิกที่มีอยู่ในขณะนี้เกินกว่า จำนวนตัวแทนหลักรายใหม่ กำหนดไว้ ('+@ErrAcc+ N')(สำหรับกีฬากอฟล์).'
							when 'J' then N'Existing members exceeded new master positiontaking ('+@ErrAcc+ N') (for Golf).'
							when 'KO' then N'회원의 거래조건 설정 범위를 넘어섰습니다 ('+@ErrAcc+ N') (골프).'
							else N'Existing members exceeded new master positiontaking ('+@ErrAcc+ N') (for Golf).'
					end
		return
	END
	
	--check m3<=m4
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ cast((scs.mpositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '-MaxLive: '+ cast((scs.mlivepositiontaking) as varchar(10)) else '' end + '<br>'
	from custsetting as scs with (NOLOCK) inner join
		(
				 	select 1 as bettype, 10 as sporttype, @v10spositiontaking_1 as spositiontaking, 0 as slivepositiontaking, @v10mpositiontaking_1 as mpositiontaking, 0 as mlivepositiontaking, @auto_v10spositiontaking_1 as auto_spositiontaking,  0 as auto_slivepositiontaking
			union all 	select 2 as bettype, 10 as sporttype, @v10spositiontaking_2 as spositiontaking, 0 as slivepositiontaking, @v10mpositiontaking_2 as mpositiontaking, 0 as mlivepositiontaking, @auto_v10spositiontaking_2 as auto_spositiontaking,  0 as auto_slivepositiontaking
			union all 	select 3 as bettype, 10 as sporttype, @v10spositiontaking_3 as spositiontaking, 0 as slivepositiontaking, @v10mpositiontaking_3 as mpositiontaking, 0 as mlivepositiontaking, @auto_v10spositiontaking_3 as auto_spositiontaking,  0 as auto_slivepositiontaking
			union all 	select 20 as bettype, 10 as sporttype, @v10spositiontaking_20 as spositiontaking, 0 as slivepositiontaking, @v10mpositiontaking_20 as mpositiontaking, 0 as mlivepositiontaking, @auto_v10spositiontaking_20 as auto_spositiontaking,  0 as auto_slivepositiontaking
		) as b on scs.sporttype=b.sporttype and scs.bettype = b.bettype
		inner join sports with (nolock) on b.sporttype = sports.sporttype
		inner join bettype with (nolock) on b.bettype = bettype.typeid
	where scs.custid = @srecommend and (
						scs.mpositiontaking<b.mpositiontaking or (b.sporttype=1 and b.bettype in (1,3,7,8) and scs.mlivepositiontaking<b.mlivepositiontaking)
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
		inner join custsetting as cs with (NOLOCK) on c.custid = cs.custid
		inner join (
					select 	10 as sporttype, 1 as bettype, @v10mpositiontaking_1 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	10 as sporttype, 2 as bettype, @v10mpositiontaking_2 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	10 as sporttype, 3 as bettype, @v10mpositiontaking_3 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	10 as sporttype, 20 as bettype, @v10mpositiontaking_20 as maxpositiontaking,  0 as maxlivepositiontaking
			) as b on cs.sporttype=b.sporttype and cs.bettype = b.bettype
	where c.mrecommend = @custid and c.roleid = 2 
		and (	cs.autompositiontaking > b.maxpositiontaking and cs.isautompositiontaking = 1
			)
	group by username
	if @ErrAcc<>''
	BEGIN
		select @ErrCode = 17
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Existing agents exceeded new master positiontaking ('+@ErrAcc+') (for Golf).'
							when 'CS' then N'现有代理超出新总代理占成数设定 ('+@ErrAcc+ N') (于高尔夫球).'
							when 'CT' then N'現有代理超出新總代理佔成數設定 ('+@ErrAcc+ N') (於高爾夫球).'
							when 'TH' then N'ตัวแทนที่มีอยู่ขณะนี้เกินกว่าจำนวนตัวแทนหลักรายใหม่ ('+@ErrAcc+ N')(สำหรับกีฬารถแข่ง).'
							when 'J' then N'Existing agents exceeded new master positiontaking ('+@ErrAcc+ N')(for Golf) .'
							when 'KO' then N'에이전트의 거래조건 설정 법위를 넘어섰습니다 ('+@ErrAcc+ N')(골프) .'
							else N'Existing agents exceeded new master positiontaking ('+@ErrAcc+ N') (for Golf).'
					end
		return
	END

END



if @UpdateMultiple = 0 or @UpdatePositiontakingv11 = 1
BEGIN
	if 
		@v11spositiontaking_1  <0
		or @v11spositiontaking_20  <0
		
		or @v11spositiontaking_1+@v11mpositiontaking_1 >0.9
		or @v11spositiontaking_20+@v11mpositiontaking_20 >0.9
		
		or @auto_v11spositiontaking_1  >0.9
		or @auto_v11spositiontaking_20  >0.9
		
		or @v11mpositiontaking_1 <0
		or @v11mpositiontaking_20 <0
				
	BEGIN
		select @ErrCode = 11
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Wrong position taking (for Motorsports).'
							when 'CS' then N'占成数不正确(于赛车).'
							when 'CT' then N'佔成數不正確(於賽車).'
							when 'TH' then N'การกำหนดไม่ถูกต้อง (สำหรับกีฬารถแข่ง).'
							when 'J' then N'Wrong position taking (for Motorsports).'
							when 'KO' then N'거래 조건이 잘못 되었습니다 (모토스포츠).'
							else N'Wrong position taking (for Motorsports).'
					end
		return
	END

	--check n4<=s3+m3<=l4 if i3 = 0, 
	--m3<=l4 and u3+m3>=n4 if i3 = 1
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Min: '+ cast((co.minpositiontaking) as varchar(10))+ '-Max: '+ cast((co.maxpositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '--MinLive: '+ cast((co.minlivepositiontaking) as varchar(10))+ '-MaxLive: '+ cast((co.maxlivepositiontaking) as varchar(10)) else '' end + '<br>'
	from custoverride as co with (NOLOCK) inner join
		(
				 	select 1 as bettype, 11 as sporttype, @v11spositiontaking_1 as spositiontaking, 0 as slivepositiontaking, @v11mpositiontaking_1 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v11spositiontaking_1 as isauto_spositiontaking,  0 as isauto_slivepositiontaking, @auto_v11spositiontaking_1 as auto_spositiontaking
			union all 	select 20 as bettype, 11 as sporttype, @v11spositiontaking_20 as spositiontaking, 0 as slivepositiontaking, @v11mpositiontaking_20 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v11spositiontaking_20 as isauto_spositiontaking,  0 as isauto_slivepositiontaking, @auto_v11spositiontaking_20 as auto_spositiontaking

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
		Select @ErrMsg = 	case @Language 
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
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Min: '+ cast((co.minpositiontaking) as varchar(10))+ '-Max: '+ cast((co.maxpositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '--MinLive: '+ cast((co.minlivepositiontaking) as varchar(10))+ '-MaxLive: '+ cast((co.maxlivepositiontaking) as varchar(10)) else '' end + '<br>'
	from custoverride as co with (NOLOCK) inner join
		(
				 	select 1 as bettype, 11 as sporttype, @v11spositiontaking_1 as spositiontaking, 0 as slivepositiontaking, @v11mpositiontaking_1 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v11spositiontaking_1 as isauto_spositiontaking,  0 as isauto_slivepositiontaking
			union all 	select 20 as bettype, 11 as sporttype, @v11spositiontaking_20 as spositiontaking, 0 as slivepositiontaking, @v11mpositiontaking_20 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v11spositiontaking_20 as isauto_spositiontaking,  0 as isauto_slivepositiontaking
		) as b on co.sporttype=b.sporttype and co.bettype = b.bettype
		inner join sports with (nolock) on b.sporttype = sports.sporttype
		inner join bettype with (nolock) on b.bettype = bettype.typeid
	where co.custid = @custid and (	
						(b.mpositiontaking>co.maxpositiontaking or b.mpositiontaking<co.minpositiontaking) 
--						or (b.sporttype = 1 and b.bettype in (1,3,7,8) and (b.mlivepositiontaking>co.maxlivepositiontaking or b.mlivepositiontaking<co.minlivepositiontaking))
					)
	if @ErrType <>''
	BEGIN
		select @ErrCode = 13
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
	--m2+a2<=m3
	select @ErrAcc = ''
	select top 100 @ErrAcc = @ErrAcc + username +', '
	from 
		custinfo as c with (NOLOCK) 
		inner join custsetting as cs with (NOLOCK) on c.custid = cs.custid
		inner join (
	
					select 	11 as sporttype, 1 as bettype, @v11mpositiontaking_1 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	11 as sporttype, 20 as bettype, @v11mpositiontaking_20 as maxpositiontaking,  0 as maxlivepositiontaking
			) as b on cs.sporttype=b.sporttype and cs.bettype = b.bettype
	where c.mrecommend = @custid and c.roleid = 2 and (cs.apositiontaking+cs.mpositiontaking>b.maxpositiontaking or (b.sporttype=1 and b.bettype in (1,3,7,8) and cs.alivepositiontaking+cs.mlivepositiontaking>b.maxlivepositiontaking))
	group by username
	if @ErrAcc<>''
	BEGIN
		select @ErrCode = 14
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Existing agents exceeded new master positiontaking ('+@ErrAcc+') (for Motorsports).'
							when 'CS' then N'现有代理超出新总代理占成数设定 ('+@ErrAcc+ N') (于赛车).'
							when 'CT' then N'現有代理超出新總代理佔成數設定 ('+@ErrAcc+ N') (於賽車).'
							when 'TH' then N'ตัวแทนที่มีอยู่ขณะนี้เกินกว่าจำนวนตัวแทนหลักรายใหม่ ('+@ErrAcc+ N')(สำหรับกีฬารถแข่ง).'
							when 'J' then N'Existing agents exceeded new master positiontaking ('+@ErrAcc+ N') (for Motorsports).'
							when 'KO' then N'에이전트의 거래조건 설정 법위를 넘어섰습니다 ('+@ErrAcc+ N') (모토스포츠).'
							else N'Existing agents exceeded new master positiontaking ('+@ErrAcc+ N') (for Motorsports).'
					end
		return
	END
	--m1+a1<=m3
	select @ErrAcc = ''
	select top 100 @ErrAcc = @ErrAcc + username +', '
	from 
		custinfo as c with (NOLOCK) 
		inner join custsetting as cs with (NOLOCK) on c.custid = cs.custid
		inner join (
	
					select 	11 as sporttype, 1 as bettype, @v11mpositiontaking_1 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	11 as sporttype, 20 as bettype, @v11mpositiontaking_20 as maxpositiontaking,  0 as maxlivepositiontaking
			) as b on cs.sporttype=b.sporttype and cs.bettype = b.bettype
	where c.mrecommend = @custid and c.roleid = 1 and (cs.apositiontaking+cs.mpositiontaking>b.maxpositiontaking or (b.sporttype=1 and b.bettype in (1,3,7,8) and cs.alivepositiontaking+cs.mlivepositiontaking>b.maxlivepositiontaking))
	group by username
	if @ErrAcc<>''
	BEGIN
		select @ErrCode = 15
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Existing members exceeded new master positiontaking ('+@ErrAcc+') (for Motorsports).'
							when 'CS' then N'现有会员超出新总代理占成数设定 ('+@ErrAcc+ N') (于赛车) .'
							when 'CT' then N'現有會員超出新總代理佔成數設定 ('+@ErrAcc+ N') (於賽車).'
							when 'TH' then N'สมาชิกที่มีอยู่ในขณะนี้เกินกว่า จำนวนตัวแทนหลักรายใหม่ กำหนดไว้ ('+@ErrAcc+ N')(สำหรับกีฬารถแข่ง).'
							when 'J' then N'Existing members exceeded new master positiontaking ('+@ErrAcc+ N') (for Motorsports).'
							when 'KO' then N'회원의 거래조건 설정 범위를 넘어섰습니다 ('+@ErrAcc+ N') (모토스포츠).'
							else N'Existing members exceeded new master positiontaking ('+@ErrAcc+ N') (for Motorsports).'
					end
		return
	END
	
	--check m3<=m4
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ cast((scs.mpositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '-MaxLive: '+ cast((scs.mlivepositiontaking) as varchar(10)) else '' end + '<br>'
	from custsetting as scs with (NOLOCK) inner join
		(
				 	select 1 as bettype, 11 as sporttype, @v11spositiontaking_1 as spositiontaking, 0 as slivepositiontaking, @v11mpositiontaking_1 as mpositiontaking, 0 as mlivepositiontaking, @auto_v11spositiontaking_1 as auto_spositiontaking,  0 as auto_slivepositiontaking
			union all 	select 20 as bettype, 11 as sporttype, @v11spositiontaking_20 as spositiontaking, 0 as slivepositiontaking, @v11mpositiontaking_20 as mpositiontaking, 0 as mlivepositiontaking, @auto_v11spositiontaking_20 as auto_spositiontaking,  0 as auto_slivepositiontaking
		) as b on scs.sporttype=b.sporttype and scs.bettype = b.bettype
		inner join sports with (nolock) on b.sporttype = sports.sporttype
		inner join bettype with (nolock) on b.bettype = bettype.typeid
	where scs.custid = @srecommend and (
						scs.mpositiontaking<b.mpositiontaking or (b.sporttype=1 and b.bettype in (1,3,7,8) and scs.mlivepositiontaking<b.mlivepositiontaking)
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
		inner join custsetting as cs with (NOLOCK) on c.custid = cs.custid
		inner join (
					select 	11 as sporttype, 1 as bettype, @v11mpositiontaking_1 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	11 as sporttype, 20 as bettype, @v11mpositiontaking_20 as maxpositiontaking,  0 as maxlivepositiontaking
			) as b on cs.sporttype=b.sporttype and cs.bettype = b.bettype
	where c.mrecommend = @custid and c.roleid = 2 
		and (	cs.autompositiontaking > b.maxpositiontaking and cs.isautompositiontaking = 1
			)
	group by username
	if @ErrAcc<>''
	BEGIN
		select @ErrCode = 17
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Existing agents exceeded new master positiontaking ('+@ErrAcc+') (for Motorsports).'
							when 'CS' then N'现有代理超出新总代理占成数设定 ('+@ErrAcc+ N') (于赛车).'
							when 'CT' then N'現有代理超出新總代理佔成數設定 ('+@ErrAcc+ N') (於賽車).'
							when 'TH' then N'ตัวแทนที่มีอยู่ขณะนี้เกินกว่าจำนวนตัวแทนหลักรายใหม่ ('+@ErrAcc+ N')(สำหรับกีฬารถแข่ง).'
							when 'J' then N'Existing agents exceeded new master positiontaking ('+@ErrAcc+ N') (for Motorsports).'
							when 'KO' then N'에이전트의 거래조건 설정 법위를 넘어섰습니다 ('+@ErrAcc+ N') (모토스포츠).'
							else N'Existing agents exceeded new master positiontaking ('+@ErrAcc+ N') (for Motorsports).'
					end
		return
	END
END


if @UpdateMultiple = 0 or @UpdatePositiontakingv99 = 1
BEGIN
	if 
		@v99spositiontaking_1  <0
		or @v99spositiontaking_2  <0
		or @v99spositiontaking_3  <0
		or @v99spositiontaking_20  <0
		
		or @v99spositiontaking_1+@v99mpositiontaking_1 >0.9
		or @v99spositiontaking_2+@v99mpositiontaking_2 >0.9
		or @v99spositiontaking_3+@v99mpositiontaking_3 >0.9
		or @v99spositiontaking_20+@v99mpositiontaking_20 >0.9
		
		or @auto_v99spositiontaking_1  >0.9
		or @auto_v99spositiontaking_2  >0.9
		or @auto_v99spositiontaking_3  >0.9
		or @auto_v99spositiontaking_20  >0.9
		
		or @v99mpositiontaking_1 <0
		or @v99mpositiontaking_2 <0
		or @v99mpositiontaking_3 <0
		or @v99mpositiontaking_20 <0
				
	BEGIN
		select @ErrCode = 11
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Wrong position taking (for Other sports).'
							when 'CS' then N'占成数不正确(于其他).'
							when 'CT' then N'佔成數不正確(於其他).'
							when 'TH' then N'การกำหนดไม่ถูกต้อง (สำหรับกีฬาอื่นๆ).'
							when 'J' then N'Wrong position taking (for Other sports).'
							when 'KO' then N'거래 조건이 잘못 되었습니다 (기타 스포츠).'
							else N'Wrong position taking (for Other sports).'
					end
		return
	END

	--check n4<=s3+m3<=l4 if i3 = 0, 
	--m3<=l4 and u3+m3>=n4 if i3 = 1
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Min: '+ cast((co.minpositiontaking) as varchar(10))+ '-Max: '+ cast((co.maxpositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '--MinLive: '+ cast((co.minlivepositiontaking) as varchar(10))+ '-MaxLive: '+ cast((co.maxlivepositiontaking) as varchar(10)) else '' end + '<br>'
	from custoverride as co with (NOLOCK) inner join
		(
				 	select 1 as bettype, 99 as sporttype, @v99spositiontaking_1 as spositiontaking, 0 as slivepositiontaking, @v99mpositiontaking_1 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v99spositiontaking_1 as isauto_spositiontaking,  0 as isauto_slivepositiontaking, @auto_v99spositiontaking_1 as auto_spositiontaking
			union all 	select 2 as bettype, 99 as sporttype, @v99spositiontaking_2 as spositiontaking, 0 as slivepositiontaking, @v99mpositiontaking_2 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v99spositiontaking_2 as isauto_spositiontaking,  0 as isauto_slivepositiontaking, @auto_v99spositiontaking_2 as auto_spositiontaking
			union all 	select 3 as bettype, 99 as sporttype, @v99spositiontaking_3 as spositiontaking, 0 as slivepositiontaking, @v99mpositiontaking_3 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v99spositiontaking_3 as isauto_spositiontaking,  0 as isauto_slivepositiontaking, @auto_v99spositiontaking_3 as auto_spositiontaking
			union all 	select 20 as bettype, 99 as sporttype, @v99spositiontaking_20 as spositiontaking, 0 as slivepositiontaking, @v99mpositiontaking_20 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v99spositiontaking_20 as isauto_spositiontaking,  0 as isauto_slivepositiontaking, @auto_v99spositiontaking_20 as auto_spositiontaking

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
		Select @ErrMsg = 	case @Language 
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
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Min: '+ cast((co.minpositiontaking) as varchar(10))+ '-Max: '+ cast((co.maxpositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '--MinLive: '+ cast((co.minlivepositiontaking) as varchar(10))+ '-MaxLive: '+ cast((co.maxlivepositiontaking) as varchar(10)) else '' end + '<br>'
	from custoverride as co with (NOLOCK) inner join
		(
				 	select 1 as bettype, 99 as sporttype, @v99spositiontaking_1 as spositiontaking, 0 as slivepositiontaking, @v99mpositiontaking_1 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v99spositiontaking_1 as isauto_spositiontaking,  0 as isauto_slivepositiontaking
			union all 	select 2 as bettype, 99 as sporttype, @v99spositiontaking_2 as spositiontaking, 0 as slivepositiontaking, @v99mpositiontaking_2 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v99spositiontaking_2 as isauto_spositiontaking,  0 as isauto_slivepositiontaking
			union all 	select 3 as bettype, 99 as sporttype, @v99spositiontaking_3 as spositiontaking, 0 as slivepositiontaking, @v99mpositiontaking_3 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v99spositiontaking_3 as isauto_spositiontaking,  0 as isauto_slivepositiontaking
			union all 	select 20 as bettype, 99 as sporttype, @v99spositiontaking_20 as spositiontaking, 0 as slivepositiontaking, @v99mpositiontaking_20 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v99spositiontaking_20 as isauto_spositiontaking,  0 as isauto_slivepositiontaking
		) as b on co.sporttype=b.sporttype and co.bettype = b.bettype
		inner join sports with (nolock) on b.sporttype = sports.sporttype
		inner join bettype with (nolock) on b.bettype = bettype.typeid
	where co.custid = @custid and (	
						(b.mpositiontaking>co.maxpositiontaking or b.mpositiontaking<co.minpositiontaking) 
--						or (b.sporttype = 1 and b.bettype in (1,3,7,8) and (b.mlivepositiontaking>co.maxlivepositiontaking or b.mlivepositiontaking<co.minlivepositiontaking))
					)
	if @ErrType <>''
	BEGIN
		select @ErrCode = 13
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
	
	--m2+a2<=m3
	select @ErrAcc = ''
	select top 100 @ErrAcc = @ErrAcc + username +', '
	from 
		custinfo as c with (NOLOCK) 
		inner join custsetting as cs with (NOLOCK) on c.custid = cs.custid
		inner join (
	
					select 	99 as sporttype, 1 as bettype, @v99mpositiontaking_1 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	99 as sporttype, 2 as bettype, @v99mpositiontaking_2 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	99 as sporttype, 3 as bettype, @v99mpositiontaking_3 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	99 as sporttype, 20 as bettype, @v99mpositiontaking_20 as maxpositiontaking,  0 as maxlivepositiontaking
			) as b on cs.sporttype=b.sporttype and cs.bettype = b.bettype
	where c.mrecommend = @custid and c.roleid = 2 and (cs.apositiontaking+cs.mpositiontaking>b.maxpositiontaking or (b.sporttype=1 and b.bettype in (1,3,7,8) and cs.alivepositiontaking+cs.mlivepositiontaking>b.maxlivepositiontaking))
	group by username
	if @ErrAcc<>''
	BEGIN
		select @ErrCode = 14
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Existing agents exceeded new master positiontaking ('+@ErrAcc+') (for Other sports).'
							when 'CS' then N'现有代理超出新总代理占成数设定 ('+@ErrAcc+ N')(于其他).'
							when 'CT' then N'現有代理超出新總代理佔成數設定 ('+@ErrAcc+ N')(於其他).'
							when 'TH' then N'ตัวแทนที่มีอยู่ขณะนี้เกินกว่าจำนวนตัวแทนหลักรายใหม่ ('+@ErrAcc+ N')(สำหรับกีฬาอื่นๆ).'
							when 'J' then N'Existing agents exceeded new master positiontaking ('+@ErrAcc+ N') (for Other sports).'
							when 'KO' then N'에이전트의 거래조건 설정 법위를 넘어섰습니다 ('+@ErrAcc+ N') (기타 스포츠).'
							else N'Existing agents exceeded new master positiontaking ('+@ErrAcc+ N') (for Other sports).'
					end
		return
	END

	--m1+a1<=m3
	select @ErrAcc = ''
	select top 100 @ErrAcc = @ErrAcc + username +', '
	from 
		custinfo as c with (NOLOCK) 
		inner join custsetting as cs with (NOLOCK) on c.custid = cs.custid
		inner join (
	
					select 	99 as sporttype, 1 as bettype, @v99mpositiontaking_1 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	99 as sporttype, 2 as bettype, @v99mpositiontaking_2 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	99 as sporttype, 3 as bettype, @v99mpositiontaking_3 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	99 as sporttype, 20 as bettype, @v99mpositiontaking_20 as maxpositiontaking,  0 as maxlivepositiontaking
			) as b on cs.sporttype=b.sporttype and cs.bettype = b.bettype
	where c.mrecommend = @custid and c.roleid = 1 and (cs.apositiontaking+cs.mpositiontaking>b.maxpositiontaking or (b.sporttype=1 and b.bettype in (1,3,7,8) and cs.alivepositiontaking+cs.mlivepositiontaking>b.maxlivepositiontaking))
	group by username
	if @ErrAcc<>''
	BEGIN
		select @ErrCode = 15
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Existing members exceeded new master positiontaking ('+@ErrAcc+') (for Other sports).'
							when 'CS' then N'现有会员超出新总代理占成数设定 ('+@ErrAcc+ N') (于其他).'
							when 'CT' then N'現有會員超出新總代理佔成數設定 ('+@ErrAcc+ N') (於其他).'
							when 'TH' then N'สมาชิกที่มีอยู่ในขณะนี้เกินกว่า จำนวนตัวแทนหลักรายใหม่ กำหนดไว้ ('+@ErrAcc+ N')(สำหรับกีฬาอื่นๆ).'
							when 'J' then N'Existing members exceeded new master positiontaking ('+@ErrAcc+ N') (for Other sports).'
							when 'KO' then N'회원의 거래조건 설정 범위를 넘어섰습니다 ('+@ErrAcc+ N') (기타 스포츠).'
							else N'Existing members exceeded new master positiontaking ('+@ErrAcc+ N') (for Other sports).'
					end
		return
	END
	
	--check m3<=m4
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ cast((scs.mpositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '-MaxLive: '+ cast((scs.mlivepositiontaking) as varchar(10)) else '' end + '<br>'
	from custsetting as scs with (NOLOCK) inner join
		(
				 	select 1 as bettype, 99 as sporttype, @v99spositiontaking_1 as spositiontaking, 0 as slivepositiontaking, @v99mpositiontaking_1 as mpositiontaking, 0 as mlivepositiontaking, @auto_v99spositiontaking_1 as auto_spositiontaking,  0 as auto_slivepositiontaking
			union all 	select 2 as bettype, 99 as sporttype, @v99spositiontaking_2 as spositiontaking, 0 as slivepositiontaking, @v99mpositiontaking_2 as mpositiontaking, 0 as mlivepositiontaking, @auto_v99spositiontaking_2 as auto_spositiontaking,  0 as auto_slivepositiontaking
			union all 	select 3 as bettype, 99 as sporttype, @v99spositiontaking_3 as spositiontaking, 0 as slivepositiontaking, @v99mpositiontaking_3 as mpositiontaking, 0 as mlivepositiontaking, @auto_v99spositiontaking_3 as auto_spositiontaking,  0 as auto_slivepositiontaking
			union all 	select 20 as bettype, 99 as sporttype, @v99spositiontaking_20 as spositiontaking, 0 as slivepositiontaking, @v99mpositiontaking_20 as mpositiontaking, 0 as mlivepositiontaking, @auto_v99spositiontaking_20 as auto_spositiontaking,  0 as auto_slivepositiontaking
		) as b on scs.sporttype=b.sporttype and scs.bettype = b.bettype
		inner join sports with (nolock) on b.sporttype = sports.sporttype
		inner join bettype with (nolock) on b.bettype = bettype.typeid
	where scs.custid = @srecommend and (
						scs.mpositiontaking<b.mpositiontaking or (b.sporttype=1 and b.bettype in (1,3,7,8) and scs.mlivepositiontaking<b.mlivepositiontaking)
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
		inner join custsetting as cs with (NOLOCK) on c.custid = cs.custid
		inner join (
					select 	99 as sporttype, 1 as bettype, @v99mpositiontaking_1 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	99 as sporttype, 2 as bettype, @v99mpositiontaking_2 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	99 as sporttype, 3 as bettype, @v99mpositiontaking_3 as maxpositiontaking,  0 as maxlivepositiontaking
				union all select 	99 as sporttype, 20 as bettype, @v99mpositiontaking_20 as maxpositiontaking,  0 as maxlivepositiontaking
			) as b on cs.sporttype=b.sporttype and cs.bettype = b.bettype
	where c.mrecommend = @custid and c.roleid = 2 
		and (	cs.autompositiontaking > b.maxpositiontaking and cs.isautompositiontaking = 1
			)
	group by username
	if @ErrAcc<>''
	BEGIN
		select @ErrCode = 17
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Existing agents exceeded new master positiontaking ('+@ErrAcc+') (for Other sports).'
							when 'CS' then N'现有代理超出新总代理占成数设定 ('+@ErrAcc+ N')(于其他).'
							when 'CT' then N'現有代理超出新總代理佔成數設定 ('+@ErrAcc+ N')(於其他).'
							when 'TH' then N'ตัวแทนที่มีอยู่ขณะนี้เกินกว่าจำนวนตัวแทนหลักรายใหม่ ('+@ErrAcc+ N')(สำหรับกีฬาอื่นๆ).'
							when 'J' then N'Existing agents exceeded new master positiontaking ('+@ErrAcc+ N') (for Other sports).'
							when 'KO' then N'에이전트의 거래조건 설정 법위를 넘어섰습니다 ('+@ErrAcc+ N') (기타 스포츠).'
							else N'Existing agents exceeded new master positiontaking ('+@ErrAcc+ N') (for Other sports).'
					end
		return
	END

END
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

if @UpdateMultiple = 0 or @UpdatePositiontaking=1 
BEGIN
	--check u3<=s4
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ cast((cs.spositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '-MaxLive: '+ cast((cs.slivepositiontaking) as varchar(10)) else '' end + '<br>'
	from custsetting as cs with (NOLOCK) inner join
		(
					select 1 as bettype, 1 as sporttype, @auto_spositiontaking_1 as autopositiontaking, @auto_slivepositiontaking_1 as autolivepositiontaking
			union all 	select 2 as bettype, 1 as sporttype, @auto_spositiontaking_2 as autopositiontaking, 0 as autolivepositiontaking
			union all 	select 3 as bettype, 1 as sporttype, @auto_spositiontaking_3 as autopositiontaking, @auto_slivepositiontaking_3 as autolivepositiontaking
			union all 	select 4 as bettype, 1 as sporttype, @auto_spositiontaking_4 as autopositiontaking, 0 as autolivepositiontaking
			union all 	select 5 as bettype, 1 as sporttype, @auto_spositiontaking_5 as autopositiontaking, 0 as autolivepositiontaking
			union all 	select 6 as bettype, 1 as sporttype, @auto_spositiontaking_6 as autopositiontaking, 0 as autolivepositiontaking
			union all 	select 7 as bettype, 1 as sporttype, @auto_spositiontaking_7 as autopositiontaking, @auto_slivepositiontaking_7 as autolivepositiontaking
			union all 	select 8 as bettype, 1 as sporttype, @auto_spositiontaking_8 as autopositiontaking, @auto_slivepositiontaking_8 as autolivepositiontaking
			union all 	select 9 as bettype, 1 as sporttype, @auto_spositiontaking_9 as autopositiontaking, 0 as autolivepositiontaking
			union all 	select 10 as bettype, 1 as sporttype, @auto_spositiontaking_10 as autopositiontaking, 0 as autolivepositiontaking
		) as b on cs.sporttype=b.sporttype and cs.bettype=b.bettype
		inner join sports with (nolock) on b.sporttype = sports.sporttype
		inner join bettype with (nolock) on b.bettype = bettype.typeid
	where cs.custid = @srecommend
		and 
		((cs.spositiontaking+@maxdownlinepos<b.autopositiontaking) or (b.bettype in (1,3,7,8) and b.sporttype=1 and cs.slivepositiontaking+@maxdownlinepos<b.autolivepositiontaking))


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
							end	, @ErrCode = 101
		return
	END
	
	--check s3<=s4
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ cast((cs.spositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '-MaxLive: '+ cast((cs.slivepositiontaking) as varchar(10)) else '' end + '<br>'
	from custsetting as cs with (NOLOCK) inner join
		(
					select 1 as bettype, 1 as sporttype, @spositiontaking_1 as spositiontaking, @slivepositiontaking_1 as slivepositiontaking, @mpositiontaking_1 as mpositiontaking, @mlivepositiontaking_1 as mlivepositiontaking
			union all 	select 2 as bettype, 1 as sporttype, @spositiontaking_2 as spositiontaking, 0 as slivepositiontaking, @mpositiontaking_2 as mpositiontaking, 0 as mlivepositiontaking
			union all 	select 3 as bettype, 1 as sporttype, @spositiontaking_3 as spositiontaking, @slivepositiontaking_3 as slivepositiontaking, @mpositiontaking_3 as mpositiontaking, @mlivepositiontaking_3 as mlivepositiontaking
			union all 	select 4 as bettype, 1 as sporttype, @spositiontaking_4 as spositiontaking, 0 as slivepositiontaking, @mpositiontaking_4 as mpositiontaking, 0 as mlivepositiontaking
			union all 	select 5 as bettype, 1 as sporttype, @spositiontaking_5 as spositiontaking, 0 as slivepositiontaking, @mpositiontaking_5 as mpositiontaking, 0 as mlivepositiontaking
			union all 	select 6 as bettype, 1 as sporttype, @spositiontaking_6 as spositiontaking, 0 as slivepositiontaking, @mpositiontaking_6 as mpositiontaking, 0 as mlivepositiontaking
			union all 	select 7 as bettype, 1 as sporttype, @spositiontaking_7 as spositiontaking, @slivepositiontaking_7 as slivepositiontaking, @mpositiontaking_7 as mpositiontaking, @mlivepositiontaking_7 as mlivepositiontaking
			union all 	select 8 as bettype, 1 as sporttype, @spositiontaking_8 as spositiontaking, @slivepositiontaking_8 as slivepositiontaking, @mpositiontaking_8 as mpositiontaking, @mlivepositiontaking_8 as mlivepositiontaking
			union all 	select 9 as bettype, 1 as sporttype, @spositiontaking_9 as spositiontaking, 0 as slivepositiontaking, @mpositiontaking_9 as mpositiontaking, 0 as mlivepositiontaking
			union all 	select 10 as bettype, 1 as sporttype, @spositiontaking_10 as spositiontaking, 0 as slivepositiontaking, @mpositiontaking_10 as mpositiontaking, 0 as mlivepositiontaking
		) as b on cs.sporttype=b.sporttype and cs.bettype=b.bettype
		inner join sports with (nolock) on b.sporttype = sports.sporttype
		inner join bettype with (nolock) on b.bettype = bettype.typeid
	where cs.custid = @srecommend
		and 
		((cs.spositiontaking<b.spositiontaking) or (cs.spositiontaking+@maxdownlinepos<b.spositiontaking+b.mpositiontaking) or (b.bettype in (1,3,7,8) and b.sporttype=1 and cs.slivepositiontaking<b.slivepositiontaking) or (b.bettype in (1,3,7,8) and b.sporttype=1 and cs.slivepositiontaking+@maxdownlinepos<b.slivepositiontaking+b.mlivepositiontaking))
	
	if @ErrType <>''
	BEGIN
		Select @ErrMsg =	@UserName + ': '+
							case @Language 
								when 'E' then 'Wrong position taking.<br>'+@ErrType
								when 'CS' then N'占成数不正确.<br>'+@ErrType
								when 'CT' then N'佔成數不正確.<br>'+@ErrType
								when 'TH' then N'การกำหนดไม่ถูกต้อง.<br>'+@ErrType
								when 'J' then N'Wrong position taking.<br>'+@ErrType
								when 'KO' then N'거래 조건이 잘못 되었습니다.<br>'+@ErrType
								else N'Wrong position taking.<br>'+@ErrType
							end	, @ErrCode = 102
		return
	END
END

if @UpdateMultiple = 0 or @UpdatePositiontakingv2=1 
BEGIN
	--u3<=s4
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ cast((cs.spositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '-MaxLive: '+ cast((cs.slivepositiontaking) as varchar(10)) else '' end + '<br>'
	from custsetting as cs with (NOLOCK) inner join
		(
			select 1 as bettype, 2 as sporttype, @auto_v2spositiontaking_1 as autopositiontaking, 0 as autolivepositiontaking
			union all 	select 2 as bettype, 2 as sporttype, @auto_v2spositiontaking_2 as autopositiontaking, 0 as autolivepositiontaking
			union all 	select 3 as bettype, 2 as sporttype, @auto_v2spositiontaking_3 as autopositiontaking, 0 as autolivepositiontaking
			union all 	select 7 as bettype, 2 as sporttype, @auto_v2spositiontaking_7 as autopositiontaking, 0 as autolivepositiontaking
			union all 	select 8 as bettype, 2 as sporttype, @auto_v2spositiontaking_8 as autopositiontaking, 0 as autolivepositiontaking
			union all 	select 9 as bettype, 2 as sporttype, @auto_v2spositiontaking_9 as autopositiontaking, 0 as autolivepositiontaking
			union all 	select 20 as bettype, 2 as sporttype, @auto_v2spositiontaking_20 as autopositiontaking, 0 as autolivepositiontaking
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
							end, @ErrCode = 103
		return
	END
	--s3<=s4,s3+m3<=s4
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ cast((cs.spositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '-MaxLive: '+ cast((cs.slivepositiontaking) as varchar(10)) else '' end + '<br>'
	from custsetting as cs with (NOLOCK) inner join
		(
					select 1 as bettype, 2 as sporttype, @v2spositiontaking_1 as spositiontaking, 0 as livepositiontaking, @v2mpositiontaking_1 as mpositiontaking
			union all 	select 2 as bettype, 2 as sporttype, @v2spositiontaking_2 as spositiontaking, 0 as livepositiontaking, @v2mpositiontaking_2 as mpositiontaking
			union all 	select 3 as bettype, 2 as sporttype, @v2spositiontaking_3 as spositiontaking, 0 as livepositiontaking, @v2mpositiontaking_3 as mpositiontaking
--			union all 	select 7 as bettype, 2 as sporttype, @v2spositiontaking_7 as spositiontaking, 0 as livepositiontaking, @v2mpositiontaking_7 as mpositiontaking
--			union all 	select 8 as bettype, 2 as sporttype, @v2spositiontaking_8 as spositiontaking, 0 as livepositiontaking, @v2mpositiontaking_8 as mpositiontaking
			union all 	select 9 as bettype, 2 as sporttype, @v2spositiontaking_9 as spositiontaking, 0 as livepositiontaking, @v2mpositiontaking_9 as mpositiontaking
			union all 	select 20 as bettype, 2 as sporttype, @v2spositiontaking_20 as spositiontaking, 0 as livepositiontaking, @v2mpositiontaking_20 as mpositiontaking
		) as b on cs.sporttype=b.sporttype and cs.bettype=b.bettype
		inner join sports with (nolock) on b.sporttype = sports.sporttype
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
							end, @ErrCode = 104
		return
	END
END

if @UpdateMultiple = 0 or @UpdatePositiontakingv3=1 
BEGIN
	--u3<=s4
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ cast((cs.spositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '-MaxLive: '+ cast((cs.slivepositiontaking) as varchar(10)) else '' end + '<br>'
	from custsetting as cs with (NOLOCK) inner join
		(
					select 1 as bettype, 3 as sporttype, @auto_v3spositiontaking_1 as autopositiontaking, 0 as autolivepositiontaking
			union all 	select 2 as bettype, 3 as sporttype, @auto_v3spositiontaking_2 as autopositiontaking, 0 as autolivepositiontaking
			union all 	select 3 as bettype, 3 as sporttype, @auto_v3spositiontaking_3 as autopositiontaking, 0 as autolivepositiontaking
			union all 	select 20 as bettype, 3 as sporttype, @auto_v3spositiontaking_20 as autopositiontaking, 0 as autolivepositiontaking
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
							end, @ErrCode = 103
		return
	END
	--s3<=s4,s3+m3<=s4
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ cast((cs.spositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '-MaxLive: '+ cast((cs.slivepositiontaking) as varchar(10)) else '' end + '<br>'
	from custsetting as cs with (NOLOCK) inner join
		(
					select 1 as bettype, 3 as sporttype, @v3spositiontaking_1 as spositiontaking, 0 as livepositiontaking, @v3mpositiontaking_1 as mpositiontaking
			union all 	select 2 as bettype, 3 as sporttype, @v3spositiontaking_2 as spositiontaking, 0 as livepositiontaking, @v3mpositiontaking_2 as mpositiontaking
			union all 	select 3 as bettype, 3 as sporttype, @v3spositiontaking_3 as spositiontaking, 0 as livepositiontaking, @v3mpositiontaking_3 as mpositiontaking
			union all 	select 20 as bettype, 3 as sporttype, @v3spositiontaking_20 as spositiontaking, 0 as livepositiontaking, @v3mpositiontaking_20 as mpositiontaking
		) as b on cs.sporttype=b.sporttype and cs.bettype=b.bettype
		inner join sports with (nolock) on b.sporttype = sports.sporttype
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
							end, @ErrCode = 104
		return
	END
END

if @UpdateMultiple = 0 or @UpdatePositiontakingv5=1 
BEGIN
	--u3<=s4
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ cast((cs.spositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '-MaxLive: '+ cast((cs.slivepositiontaking) as varchar(10)) else '' end + '<br>'
	from custsetting as cs with (NOLOCK) inner join
		(
					select 1 as bettype, 5 as sporttype, @auto_v5spositiontaking_1 as autopositiontaking, 0 as autolivepositiontaking
			union all 	select 2 as bettype, 5 as sporttype, @auto_v5spositiontaking_2 as autopositiontaking, 0 as autolivepositiontaking
			union all 	select 3 as bettype, 5 as sporttype, @auto_v5spositiontaking_3 as autopositiontaking, 0 as autolivepositiontaking
			union all 	select 20 as bettype, 5 as sporttype, @auto_v5spositiontaking_20 as autopositiontaking, 0 as autolivepositiontaking
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
							end, @ErrCode = 103
		return
	END
	--s3<=s4,s3+m3<=s4
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ cast((cs.spositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '-MaxLive: '+ cast((cs.slivepositiontaking) as varchar(10)) else '' end + '<br>'
	from custsetting as cs with (NOLOCK) inner join
		(
					select 1 as bettype, 5 as sporttype, @v5spositiontaking_1 as spositiontaking, 0 as livepositiontaking, @v5mpositiontaking_1 as mpositiontaking
			union all 	select 2 as bettype, 5 as sporttype, @v5spositiontaking_2 as spositiontaking, 0 as livepositiontaking, @v5mpositiontaking_2 as mpositiontaking
			union all 	select 3 as bettype, 5 as sporttype, @v5spositiontaking_3 as spositiontaking, 0 as livepositiontaking, @v5mpositiontaking_3 as mpositiontaking
			union all 	select 20 as bettype, 5 as sporttype, @v5spositiontaking_20 as spositiontaking, 0 as livepositiontaking, @v5mpositiontaking_20 as mpositiontaking
		) as b on cs.sporttype=b.sporttype and cs.bettype=b.bettype
		inner join sports with (nolock) on b.sporttype = sports.sporttype
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
							end, @ErrCode = 104
		return
	END
END

if @UpdateMultiple = 0 or @UpdatePositiontakingv8=1 
BEGIN
	--u3<=s4
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ cast((cs.spositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '-MaxLive: '+ cast((cs.slivepositiontaking) as varchar(10)) else '' end + '<br>'
	from custsetting as cs with (NOLOCK) inner join
		(
					select 1 as bettype, 8 as sporttype, @auto_v8spositiontaking_1 as autopositiontaking, 0 as autolivepositiontaking
			union all 	select 3 as bettype, 8 as sporttype, @auto_v8spositiontaking_3 as autopositiontaking, 0 as autolivepositiontaking
			union all 	select 20 as bettype, 8 as sporttype, @auto_v8spositiontaking_20 as autopositiontaking, 0 as autolivepositiontaking
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
							end, @ErrCode = 103
		return
	END
	--s3<=s4,s3+m3<=s4
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ cast((cs.spositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '-MaxLive: '+ cast((cs.slivepositiontaking) as varchar(10)) else '' end + '<br>'
	from custsetting as cs with (NOLOCK) inner join
		(
					select 1 as bettype, 8 as sporttype, @v8spositiontaking_1 as spositiontaking, 0 as livepositiontaking, @v8mpositiontaking_1 as mpositiontaking
			union all 	select 3 as bettype, 8 as sporttype, @v8spositiontaking_3 as spositiontaking, 0 as livepositiontaking, @v8mpositiontaking_3 as mpositiontaking
			union all 	select 20 as bettype, 8 as sporttype, @v8spositiontaking_20 as spositiontaking, 0 as livepositiontaking, @v8mpositiontaking_20 as mpositiontaking
		) as b on cs.sporttype=b.sporttype and cs.bettype=b.bettype
		inner join sports with (nolock) on b.sporttype = sports.sporttype
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
							end, @ErrCode = 104
		return
	END
END

if @UpdateMultiple = 0 or @UpdatePositiontakingv10=1 
BEGIN
	--u3<=s4
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ cast((cs.spositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '-MaxLive: '+ cast((cs.slivepositiontaking) as varchar(10)) else '' end + '<br>'
	from custsetting as cs with (NOLOCK) inner join
		(
					select 1 as bettype, 10 as sporttype, @auto_v10spositiontaking_1 as autopositiontaking, 0 as autolivepositiontaking
			union all 	select 2 as bettype, 10 as sporttype, @auto_v10spositiontaking_2 as autopositiontaking, 0 as autolivepositiontaking
			union all 	select 3 as bettype, 10 as sporttype, @auto_v10spositiontaking_3 as autopositiontaking, 0 as autolivepositiontaking
			union all 	select 20 as bettype, 10 as sporttype, @auto_v10spositiontaking_20 as autopositiontaking, 0 as autolivepositiontaking
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
							end, @ErrCode = 103
		return
	END
	--s3<=s4,s3+m3<=s4
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ cast((cs.spositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '-MaxLive: '+ cast((cs.slivepositiontaking) as varchar(10)) else '' end + '<br>'
	from custsetting as cs with (NOLOCK) inner join
		(
					select 1 as bettype, 10 as sporttype, @v10spositiontaking_1 as spositiontaking, 0 as livepositiontaking, @v10mpositiontaking_1 as mpositiontaking
			union all 	select 2 as bettype, 10 as sporttype, @v10spositiontaking_2 as spositiontaking, 0 as livepositiontaking, @v10mpositiontaking_2 as mpositiontaking
			union all 	select 3 as bettype, 10 as sporttype, @v10spositiontaking_3 as spositiontaking, 0 as livepositiontaking, @v10mpositiontaking_3 as mpositiontaking
			union all 	select 20 as bettype, 10 as sporttype, @v10spositiontaking_20 as spositiontaking, 0 as livepositiontaking, @v10mpositiontaking_20 as mpositiontaking
		) as b on cs.sporttype=b.sporttype and cs.bettype=b.bettype
		inner join sports with (nolock) on b.sporttype = sports.sporttype
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
							end, @ErrCode = 104
		return
	END
END

if @UpdateMultiple = 0 or @UpdatePositiontakingv11=1 
BEGIN
	--u3<=s4
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ cast((cs.spositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '-MaxLive: '+ cast((cs.slivepositiontaking) as varchar(10)) else '' end + '<br>'
	from custsetting as cs with (NOLOCK) inner join
		(
					select 1 as bettype, 11 as sporttype, @auto_v11spositiontaking_1 as autopositiontaking, 0 as autolivepositiontaking
			union all 	select 20 as bettype, 11 as sporttype, @auto_v11spositiontaking_20 as autopositiontaking, 0 as autolivepositiontaking
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
							end, @ErrCode = 103
		return
	END
	--s3<=s4,s3+m3<=s4
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ cast((cs.spositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '-MaxLive: '+ cast((cs.slivepositiontaking) as varchar(10)) else '' end + '<br>'
	from custsetting as cs with (NOLOCK) inner join
		(
					select 1 as bettype, 11 as sporttype, @v11spositiontaking_1 as spositiontaking, 0 as livepositiontaking, @v11mpositiontaking_1 as mpositiontaking
			union all 	select 20 as bettype, 11 as sporttype, @v11spositiontaking_20 as spositiontaking, 0 as livepositiontaking, @v11mpositiontaking_20 as mpositiontaking
		) as b on cs.sporttype=b.sporttype and cs.bettype=b.bettype
		inner join sports with (nolock) on b.sporttype = sports.sporttype
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
							end, @ErrCode = 104
		return
	END
END

if @UpdateMultiple = 0 or @UpdatePositiontakingv99=1 
BEGIN
	--u3<=s4
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ cast((cs.spositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '-MaxLive: '+ cast((cs.slivepositiontaking) as varchar(10)) else '' end + '<br>'
	from custsetting as cs with (NOLOCK) inner join
		(
					select 1 as bettype, 99 as sporttype, @auto_v99spositiontaking_1 as autopositiontaking, 0 as autolivepositiontaking
			union all 	select 2 as bettype, 99 as sporttype, @auto_v99spositiontaking_2 as autopositiontaking, 0 as autolivepositiontaking
			union all 	select 3 as bettype, 99 as sporttype, @auto_v99spositiontaking_3 as autopositiontaking, 0 as autolivepositiontaking
			union all 	select 20 as bettype, 99 as sporttype, @auto_v99spositiontaking_20 as autopositiontaking, 0 as autolivepositiontaking
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
							end, @ErrCode = 103
		return
	END
	--s3<=s4,s3+m3<=s4
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ cast((cs.spositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '-MaxLive: '+ cast((cs.slivepositiontaking) as varchar(10)) else '' end + '<br>'
	from custsetting as cs with (NOLOCK) inner join
		(
					select 1 as bettype, 99 as sporttype, @v99spositiontaking_1 as spositiontaking, 0 as livepositiontaking, @v99mpositiontaking_1 as mpositiontaking
			union all 	select 2 as bettype, 99 as sporttype, @v99spositiontaking_2 as spositiontaking, 0 as livepositiontaking, @v99mpositiontaking_2 as mpositiontaking
			union all 	select 3 as bettype, 99 as sporttype, @v99spositiontaking_3 as spositiontaking, 0 as livepositiontaking, @v99mpositiontaking_3 as mpositiontaking
			union all 	select 20 as bettype, 99 as sporttype, @v99spositiontaking_20 as spositiontaking, 0 as livepositiontaking, @v99mpositiontaking_20 as mpositiontaking
		) as b on cs.sporttype=b.sporttype and cs.bettype=b.bettype
		inner join sports with (nolock) on b.sporttype = sports.sporttype
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
							end, @ErrCode = 104
		return
	END
END



------------

------------

update custsetting with (ROWLOCK, UPDLOCK)
set
	spositiontaking = case
		when @UpdateMultiple = 1 and ((sporttype=1 and @UpdatePositiontaking = 0)
										or (sporttype=2 and @UpdatePositiontakingv2 = 0)
										or (sporttype=3 and @UpdatePositiontakingv3 = 0)
										or (sporttype=5 and @UpdatePositiontakingv5 = 0)
										or (sporttype=8 and @UpdatePositiontakingv8 = 0)
										or (sporttype=10 and @UpdatePositiontakingv10 = 0)
										or (sporttype=11 and @UpdatePositiontakingv11 = 0)
										or (sporttype=99 and @UpdatePositiontakingv99 = 0)
										) then spositiontaking
		else case sporttype when 1 then case bettype when 1 then @spositiontaking_1 when 2 then @spositiontaking_2 when 3 then @spositiontaking_3 when 4 then @spositiontaking_4 when 5 then @spositiontaking_5 when 6 then @spositiontaking_6 when 7 then @spositiontaking_7 when 8 then @spositiontaking_8 when 9 then @spositiontaking_9  when 10 then @spositiontaking_10 else 0 end
		
		when 2 then case bettype when 1 then @v2spositiontaking_1 when 2 then @v2spositiontaking_2 when 3 then @v2spositiontaking_3 when 7 then @v2spositiontaking_7 when 8 then @v2spositiontaking_8 when 9 then @v2spositiontaking_9 when 20 then @v2spositiontaking_20 else 0 end
		when 3 then case bettype when 1 then @v3spositiontaking_1 when 2 then @v3spositiontaking_2 when 3 then @v3spositiontaking_3 when 20 then @v3spositiontaking_20 else 0 end
		when 5 then case bettype when 1 then @v5spositiontaking_1 when 2 then @v5spositiontaking_2 when 3 then @v5spositiontaking_3 when 20 then @v5spositiontaking_20 else 0 end
		when 8 then case bettype when 1 then @v8spositiontaking_1 when 3 then @v8spositiontaking_3 when 20 then @v8spositiontaking_20 else 0 end
		when 10 then case bettype when 1 then @v10spositiontaking_1 when 2 then @v10spositiontaking_2 when 3 then @v10spositiontaking_3 when 20 then @v10spositiontaking_20 else 0 end
		when 11 then case bettype when 1 then @v11spositiontaking_1 when 20 then @v11spositiontaking_20 else 0 end
		when 99 then case bettype when 1 then @v99spositiontaking_1 when 2 then @v99spositiontaking_2 when 3 then @v99spositiontaking_3 when 20 then @v99spositiontaking_20 else 0 end
		else spositiontaking end	end,
	
	slivepositiontaking = case when @UpdateMultiple = 1 and ((sporttype=1 and @UpdatePositiontaking = 0) or (sporttype=2 and @UpdatePositiontakingv2 = 0) or (sporttype=3 and @UpdatePositiontakingv3 = 0) or (sporttype=5 and @UpdatePositiontakingv5 = 0) or (sporttype=8 and @UpdatePositiontakingv8 = 0) or (sporttype=10 and @UpdatePositiontakingv10 = 0) or (sporttype=11 and @UpdatePositiontakingv11 = 0) or (sporttype=99 and @UpdatePositiontakingv99 = 0)) then slivepositiontaking else case sporttype 	when 1 then case bettype when 1 then @slivepositiontaking_1 when 3 then @slivepositiontaking_3 when 7 then @slivepositiontaking_7 when 8 then @slivepositiontaking_8 else slivepositiontaking end else slivepositiontaking end end,
	
	mpositiontaking = case when @UpdateMultiple = 1 and ((sporttype=1 and @UpdatePositiontaking = 0) or (sporttype=2 and @UpdatePositiontakingv2 = 0) or (sporttype=3 and @UpdatePositiontakingv3 = 0) or (sporttype=5 and @UpdatePositiontakingv5 = 0) or (sporttype=8 and @UpdatePositiontakingv8 = 0) or (sporttype=10 and @UpdatePositiontakingv10 = 0) or (sporttype=11 and @UpdatePositiontakingv11 = 0) or (sporttype=99 and @UpdatePositiontakingv99 = 0)) then mpositiontaking else case sporttype 	when 1 then case bettype when 1 then @mpositiontaking_1 when 2 then @mpositiontaking_2 when 3 then @mpositiontaking_3 when 4 then @mpositiontaking_4 when 5 then @mpositiontaking_5 when 6 then @mpositiontaking_6 when 7 then @mpositiontaking_7 when 8 then @mpositiontaking_8 when 9 then @mpositiontaking_9  when 10 then @mpositiontaking_10 else 0 end
					
			when 2 then case bettype when 1 then @v2mpositiontaking_1 when 2 then @v2mpositiontaking_2 when 3 then @v2mpositiontaking_3 when 7 then @v2mpositiontaking_7 when 8 then @v2mpositiontaking_8 when 9 then @v2mpositiontaking_9  when 20 then @v2mpositiontaking_20 else 0 end
			when 3 then case bettype when 1 then @v3mpositiontaking_1 when 2 then @v3mpositiontaking_2 when 3 then @v3mpositiontaking_3 when 20 then @v3mpositiontaking_20 else 0 end
			when 5 then case bettype when 1 then @v5mpositiontaking_1 when 2 then @v5mpositiontaking_2 when 3 then @v5mpositiontaking_3 when 20 then @v5mpositiontaking_20 else 0 end
			when 8 then case bettype when 1 then @v8mpositiontaking_1 when 3 then @v8mpositiontaking_3 when 20 then @v8mpositiontaking_20 else 0 end
			when 10 then case bettype when 1 then @v10mpositiontaking_1 when 2 then @v10mpositiontaking_2 when 3 then @v10mpositiontaking_3 when 20 then @v10mpositiontaking_20 else 0 end
			when 11 then case bettype when 1 then @v11mpositiontaking_1 when 20 then @v11mpositiontaking_20 else 0 end
			when 99 then case bettype when 1 then @v99mpositiontaking_1 when 2 then @v99mpositiontaking_2 when 3 then @v99mpositiontaking_3 when 20 then @v99mpositiontaking_20 else 0 end
			else mpositiontaking end end,
	
	mlivepositiontaking = case when @UpdateMultiple = 1 and ((sporttype=1 and @UpdatePositiontaking = 0) or (sporttype=2 and @UpdatePositiontakingv2 = 0) or (sporttype=3 and @UpdatePositiontakingv3 = 0) or (sporttype=5 and @UpdatePositiontakingv5 = 0) or (sporttype=8 and @UpdatePositiontakingv8 = 0) or (sporttype=10 and @UpdatePositiontakingv10 = 0) or (sporttype=11 and @UpdatePositiontakingv11 = 0)  or (sporttype=99 and @UpdatePositiontakingv99 = 0)) then mlivepositiontaking else case sporttype 	when 1 then case bettype when 1 then @mlivepositiontaking_1 when 3 then @mlivepositiontaking_3 when 7 then @mlivepositiontaking_7 when 8 then @mlivepositiontaking_8 else mlivepositiontaking end else mlivepositiontaking end end
	
where custid=@custid
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

EXEC dbo.Acc_CustomerUpdMaster_AutoPositiontaking 
		@mrecommend=@custid, @srecommend = @srecommend,
		@auto_spositiontaking_1 = @auto_spositiontaking_1,
		@auto_spositiontaking_2 = @auto_spositiontaking_2, 
		@auto_spositiontaking_3 = @auto_spositiontaking_3,
		@auto_spositiontaking_4 = @auto_spositiontaking_4,
		@auto_spositiontaking_5 = @auto_spositiontaking_5, 
		@auto_spositiontaking_6 = @auto_spositiontaking_6,
		@auto_spositiontaking_7 = @auto_spositiontaking_7,
		@auto_spositiontaking_8 = @auto_spositiontaking_8, 
		@auto_spositiontaking_9 = @auto_spositiontaking_9,
		@auto_spositiontaking_10 = @auto_spositiontaking_10,
		
		@auto_slivepositiontaking_1 = @auto_slivepositiontaking_1, 
		@auto_slivepositiontaking_3 = @auto_slivepositiontaking_3,
		@auto_slivepositiontaking_7 = @auto_slivepositiontaking_7,
		@auto_slivepositiontaking_8 = @auto_slivepositiontaking_8,
		 
		@auto_v2spositiontaking_1 = @auto_v2spositiontaking_1,
		@auto_v2spositiontaking_2 = @auto_v2spositiontaking_2,
		@auto_v2spositiontaking_3 = @auto_v2spositiontaking_3, 
		@auto_v2spositiontaking_7 = @auto_v2spositiontaking_7,
		@auto_v2spositiontaking_8 = @auto_v2spositiontaking_8,
		@auto_v2spositiontaking_9 = @auto_v2spositiontaking_9,
		@auto_v2spositiontaking_20 = @auto_v2spositiontaking_20,
		
		@auto_v3spositiontaking_1 = @auto_v3spositiontaking_1,
		@auto_v3spositiontaking_2 = @auto_v3spositiontaking_2,
		@auto_v3spositiontaking_3 = @auto_v3spositiontaking_3, 
		@auto_v3spositiontaking_20 = @auto_v3spositiontaking_20,

		@auto_v5spositiontaking_1 = @auto_v5spositiontaking_1,
		@auto_v5spositiontaking_2 = @auto_v5spositiontaking_2,
		@auto_v5spositiontaking_3 = @auto_v5spositiontaking_3, 
		@auto_v5spositiontaking_20 = @auto_v5spositiontaking_20,

		@auto_v8spositiontaking_1 = @auto_v8spositiontaking_1,
		@auto_v8spositiontaking_3 = @auto_v8spositiontaking_3, 
		@auto_v8spositiontaking_20 = @auto_v8spositiontaking_20,

		@auto_v10spositiontaking_1 = @auto_v10spositiontaking_1,
		@auto_v10spositiontaking_2 = @auto_v10spositiontaking_2,
		@auto_v10spositiontaking_3 = @auto_v10spositiontaking_3, 
		@auto_v10spositiontaking_20 = @auto_v10spositiontaking_20,

		@auto_v11spositiontaking_1 = @auto_v11spositiontaking_1,
		@auto_v11spositiontaking_20 = @auto_v11spositiontaking_20,

		@auto_v99spositiontaking_1 = @auto_v99spositiontaking_1,
		@auto_v99spositiontaking_2 = @auto_v99spositiontaking_2,
		@auto_v99spositiontaking_3 = @auto_v99spositiontaking_3, 
		@auto_v99spositiontaking_20 = @auto_v99spositiontaking_20,
		
		@updatemultiple = @updatemultiple,
		@updatepositiontaking = @updatepositiontaking, 
		
		@UpdatePositiontakingv2 = @UpdatePositiontakingv2,
		@UpdatePositiontakingv3 = @UpdatePositiontakingv3,
		@UpdatePositiontakingv5 = @UpdatePositiontakingv5,
		@UpdatePositiontakingv8 = @UpdatePositiontakingv8,
		@UpdatePositiontakingv10 = @UpdatePositiontakingv10,
		@UpdatePositiontakingv11 = @UpdatePositiontakingv11,
		@UpdatePositiontakingv99 = @UpdatePositiontakingv99,
		
		@language = @language,
		@updateallmembers = @updateallmembers,
		@newspositiontaking = @newspositiontaking,
		@userid = @userid,

		@isauto_spositiontaking_1	=	 @isauto_spositiontaking_1,
		@isauto_spositiontaking_2	=	 @isauto_spositiontaking_2,
		@isauto_spositiontaking_3	=	 @isauto_spositiontaking_3,
		@isauto_spositiontaking_4	=	 @isauto_spositiontaking_4,
		@isauto_spositiontaking_5	=	 @isauto_spositiontaking_5,
		@isauto_spositiontaking_6	=	 @isauto_spositiontaking_6,
		@isauto_spositiontaking_7	=	 @isauto_spositiontaking_7,
		@isauto_spositiontaking_8	=	 @isauto_spositiontaking_8,
		@isauto_spositiontaking_9	=	 @isauto_spositiontaking_9,
		@isauto_spositiontaking_10	=	 @isauto_spositiontaking_10,
		
		@isauto_slivepositiontaking_1	=	 @isauto_slivepositiontaking_1,
		@isauto_slivepositiontaking_3	=	 @isauto_slivepositiontaking_3,
		@isauto_slivepositiontaking_7	=	 @isauto_slivepositiontaking_7,
		@isauto_slivepositiontaking_8	=	 @isauto_slivepositiontaking_8,
		
		@isauto_v2spositiontaking_1	=	 @isauto_v2spositiontaking_1,
		@isauto_v2spositiontaking_2	=	 @isauto_v2spositiontaking_2,
		@isauto_v2spositiontaking_3	=	 @isauto_v2spositiontaking_3,
		@isauto_v2spositiontaking_7	=	 @isauto_v2spositiontaking_7,
		@isauto_v2spositiontaking_8	=	 @isauto_v2spositiontaking_8,
		@isauto_v2spositiontaking_9	=	 @isauto_v2spositiontaking_9,
		@isauto_v2spositiontaking_20	=	 @isauto_v2spositiontaking_20,
		
		@isauto_v3spositiontaking_1	=	 @isauto_v3spositiontaking_1,
		@isauto_v3spositiontaking_2	=	 @isauto_v3spositiontaking_2,
		@isauto_v3spositiontaking_3	=	 @isauto_v3spositiontaking_3,
		@isauto_v3spositiontaking_20	=	 @isauto_v3spositiontaking_20,

		@isauto_v5spositiontaking_1	=	 @isauto_v5spositiontaking_1,
		@isauto_v5spositiontaking_2	=	 @isauto_v5spositiontaking_2,
		@isauto_v5spositiontaking_3	=	 @isauto_v5spositiontaking_3,
		@isauto_v5spositiontaking_20	=	 @isauto_v5spositiontaking_20,

		@isauto_v8spositiontaking_1	=	 @isauto_v8spositiontaking_1,
		@isauto_v8spositiontaking_3	=	 @isauto_v8spositiontaking_3,
		@isauto_v8spositiontaking_20	=	 @isauto_v8spositiontaking_20,

		@isauto_v10spositiontaking_1	=	 @isauto_v10spositiontaking_1,
		@isauto_v10spositiontaking_2	=	 @isauto_v10spositiontaking_2,
		@isauto_v10spositiontaking_3	=	 @isauto_v10spositiontaking_3,
		@isauto_v10spositiontaking_20	=	 @isauto_v10spositiontaking_20,

		@isauto_v11spositiontaking_1	=	 @isauto_v11spositiontaking_1,
		@isauto_v11spositiontaking_20	=	 @isauto_v11spositiontaking_20,

		@isauto_v99spositiontaking_1	=	 @isauto_v99spositiontaking_1,
		@isauto_v99spositiontaking_2	=	 @isauto_v99spositiontaking_2,
		@isauto_v99spositiontaking_3	=	 @isauto_v99spositiontaking_3,
		@isauto_v99spositiontaking_20	=	 @isauto_v99spositiontaking_20,
		@ErrCode = @ErrCode OUTPUT,
		@ErrMsg = @ErrMsg OUTPUT
		
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
					end, @ErrCode = 123					 
	
	return
end
EXEC dbo.Acc_CustomerUpdMaster_MaxPositiontaking @mrecommend = @custid
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
	
Select @LogSPData = '<Acc_CustomerUpdMaster_PositionTaking><info Updallmembers="'+ coalesce(cast(@updateallmembers as varchar(50)),space(1)) + '" ' +
'newspt="'+ coalesce(cast(@newspositiontaking as varchar(50)),space(1)) + '" ' +
'UpdMultiple="'+ coalesce(cast(@UpdateMultiple as varchar(50)),space(1)) + '" ' +
'Updpt="'+ coalesce(cast(@UpdatePositiontaking as varchar(50)),space(1)) + '" ' +
'Updptv2="'+ coalesce(cast(@UpdatePositiontakingv2 as varchar(50)),space(1)) + '" ' +
'Updptv3="'+ coalesce(cast(@UpdatePositiontakingv3 as varchar(50)),space(1)) + '" ' +
'Updptv5="'+ coalesce(cast(@UpdatePositiontakingv5 as varchar(50)),space(1)) + '" ' +
'Updptv8="'+ coalesce(cast(@UpdatePositiontakingv8 as varchar(50)),space(1)) + '" ' +
'Updptv10="'+ coalesce(cast(@UpdatePositiontakingv10 as varchar(50)),space(1)) + '" ' +
'Updptv11="'+ coalesce(cast(@UpdatePositiontakingv11 as varchar(50)),space(1)) + '" ' +
'Updptv99="'+ coalesce(cast(@UpdatePositiontakingv99 as varchar(50)),space(1)) + '" ' +
'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(30)),space(1)) + '" ' +
'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" ' +
'Language="'+ coalesce(cast(@Language as varchar(2)),space(1)) + '" ' +
'IP="'+ coalesce(cast(@IP as varchar(15)),space(1)) + '" ' +
'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" ' +
'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(5000)),space(1)) + '" />' +

'<s spt_1="'+ coalesce(cast(@spositiontaking_1 as varchar(50)),space(1)) + '" ' +
'spt_2="'+ coalesce(cast(@spositiontaking_2 as varchar(50)),space(1)) + '" ' +
'spt_3="'+ coalesce(cast(@spositiontaking_3 as varchar(50)),space(1)) + '" ' +
'spt_4="'+ coalesce(cast(@spositiontaking_4 as varchar(50)),space(1)) + '" ' +
'spt_5="'+ coalesce(cast(@spositiontaking_5 as varchar(50)),space(1)) + '" ' +
'spt_6="'+ coalesce(cast(@spositiontaking_6 as varchar(50)),space(1)) + '" ' +
'spt_7="'+ coalesce(cast(@spositiontaking_7 as varchar(50)),space(1)) + '" ' +
'spt_8="'+ coalesce(cast(@spositiontaking_8 as varchar(50)),space(1)) + '" ' +
'spt_9="'+ coalesce(cast(@spositiontaking_9 as varchar(50)),space(1)) + '" ' +
'spt_10="'+ coalesce(cast(@spositiontaking_10 as varchar(50)),space(1)) + '" ' +
'slivept_1="'+ coalesce(cast(@slivepositiontaking_1 as varchar(50)),space(1)) + '" ' +
'slivept_3="'+ coalesce(cast(@slivepositiontaking_3 as varchar(50)),space(1)) + '" ' +
'slivept_7="'+ coalesce(cast(@slivepositiontaking_7 as varchar(50)),space(1)) + '" ' +
'slivept_8="'+ coalesce(cast(@slivepositiontaking_8 as varchar(50)),space(1)) + '" ' +

--v2
'v2spt_1="'+ coalesce(cast(@v2spositiontaking_1 as varchar(50)),space(1)) + '" ' +
'v2spt_2="'+ coalesce(cast(@v2spositiontaking_2 as varchar(50)),space(1)) + '" ' +
'v2spt_3="'+ coalesce(cast(@v2spositiontaking_3 as varchar(50)),space(1)) + '" ' +
'v2spt_7="'+ coalesce(cast(@v2spositiontaking_7 as varchar(50)),space(1)) + '" ' +
'v2spt_8="'+ coalesce(cast(@v2spositiontaking_8 as varchar(50)),space(1)) + '" ' +
'v2spt_9="'+ coalesce(cast(@v2spositiontaking_9 as varchar(50)),space(1)) + '" ' +
'v2spt_20="'+ coalesce(cast(@v2spositiontaking_20 as varchar(50)),space(1)) + '" ' +

--v3
'v3spt_1="'+ coalesce(cast(@v3spositiontaking_1 as varchar(50)),space(1)) + '" ' +
'v3spt_2="'+ coalesce(cast(@v3spositiontaking_2 as varchar(50)),space(1)) + '" ' +
'v3spt_3="'+ coalesce(cast(@v3spositiontaking_3 as varchar(50)),space(1)) + '" ' +
'v3spt_20="'+ coalesce(cast(@v3spositiontaking_20 as varchar(50)),space(1)) + '" ' +

--v5
'v5spt_1="'+ coalesce(cast(@v5spositiontaking_1 as varchar(50)),space(1)) + '" ' +
'v5spt_2="'+ coalesce(cast(@v5spositiontaking_2 as varchar(50)),space(1)) + '" ' +
'v5spt_3="'+ coalesce(cast(@v5spositiontaking_3 as varchar(50)),space(1)) + '" ' +
'v5spt_20="'+ coalesce(cast(@v5spositiontaking_20 as varchar(50)),space(1)) + '" ' +

--v8
'v8spt_1="'+ coalesce(cast(@v8spositiontaking_1 as varchar(50)),space(1)) + '" ' +
'v8spt_3="'+ coalesce(cast(@v8spositiontaking_3 as varchar(50)),space(1)) + '" ' +
'v8spt_20="'+ coalesce(cast(@v8spositiontaking_20 as varchar(50)),space(1)) + '" ' +

--v10
'v10spt_1="'+ coalesce(cast(@v10spositiontaking_1 as varchar(50)),space(1)) + '" ' +
'v10spt_2="'+ coalesce(cast(@v10spositiontaking_2 as varchar(50)),space(1)) + '" ' +
'v10spt_3="'+ coalesce(cast(@v10spositiontaking_3 as varchar(50)),space(1)) + '" ' +
'v10spt_20="'+ coalesce(cast(@v10spositiontaking_20 as varchar(50)),space(1)) + '" ' +

--v11
'v11spt_1="'+ coalesce(cast(@v11spositiontaking_1 as varchar(50)),space(1)) + '" ' +
'v11spt_20="'+ coalesce(cast(@v11spositiontaking_20 as varchar(50)),space(1)) + '" ' +

--v99
'v99spt_1="'+ coalesce(cast(@v99spositiontaking_1 as varchar(50)),space(1)) + '" ' +
'v99spt_2="'+ coalesce(cast(@v99spositiontaking_2 as varchar(50)),space(1)) + '" ' +
'v99spt_3="'+ coalesce(cast(@v99spositiontaking_3 as varchar(50)),space(1)) + '" ' +
'v99spt_20="'+ coalesce(cast(@v99spositiontaking_20 as varchar(50)),space(1)) + '" />' +

'<au a_spt_1="'+ coalesce(cast(@auto_spositiontaking_1 as varchar(50)),space(1)) + '" ' +
'a_spt_2="'+ coalesce(cast(@auto_spositiontaking_2 as varchar(50)),space(1)) + '" ' +
'a_spt_3="'+ coalesce(cast(@auto_spositiontaking_3 as varchar(50)),space(1)) + '" ' +
'a_spt_4="'+ coalesce(cast(@auto_spositiontaking_4 as varchar(50)),space(1)) + '" ' +
'a_spt_5="'+ coalesce(cast(@auto_spositiontaking_5 as varchar(50)),space(1)) + '" ' +
'a_spt_6="'+ coalesce(cast(@auto_spositiontaking_6 as varchar(50)),space(1)) + '" ' +
'a_spt_7="'+ coalesce(cast(@auto_spositiontaking_7 as varchar(50)),space(1)) + '" ' +
'a_spt_8="'+ coalesce(cast(@auto_spositiontaking_8 as varchar(50)),space(1)) + '" ' +
'a_spt_9="'+ coalesce(cast(@auto_spositiontaking_9 as varchar(50)),space(1)) + '" ' +
'a_spt_10="'+ coalesce(cast(@auto_spositiontaking_10 as varchar(50)),space(1)) + '" ' +
'a_slivept_1="'+ coalesce(cast(@auto_slivepositiontaking_1 as varchar(50)),space(1)) + '" ' +
'a_slivept_3="'+ coalesce(cast(@auto_slivepositiontaking_3 as varchar(50)),space(1)) + '" ' +
'a_slivept_7="'+ coalesce(cast(@auto_slivepositiontaking_7 as varchar(50)),space(1)) + '" ' +
'a_slivept_8="'+ coalesce(cast(@auto_slivepositiontaking_8 as varchar(50)),space(1)) + '" ' +

'a_v2spt_1="'+ coalesce(cast(@auto_v2spositiontaking_1 as varchar(50)),space(1)) + '" ' +
'a_v2spt_2="'+ coalesce(cast(@auto_v2spositiontaking_2 as varchar(50)),space(1)) + '" ' +
'a_v2spt_3="'+ coalesce(cast(@auto_v2spositiontaking_3 as varchar(50)),space(1)) + '" ' +
'a_v2spt_7="'+ coalesce(cast(@auto_v2spositiontaking_7 as varchar(50)),space(1)) + '" ' +
'a_v2spt_8="'+ coalesce(cast(@auto_v2spositiontaking_8 as varchar(50)),space(1)) + '" ' +
'a_v2spt_9="'+ coalesce(cast(@auto_v2spositiontaking_9 as varchar(50)),space(1)) + '" ' +
'a_v2spt_20="'+ coalesce(cast(@auto_v2spositiontaking_20 as varchar(50)),space(1)) + '" ' +

'a_v3spt_1="'+ coalesce(cast(@auto_v3spositiontaking_1 as varchar(50)),space(1)) + '" ' +
'a_v3spt_2="'+ coalesce(cast(@auto_v3spositiontaking_2 as varchar(50)),space(1)) + '" ' +
'a_v3spt_3="'+ coalesce(cast(@auto_v3spositiontaking_3 as varchar(50)),space(1)) + '" ' +
'a_v3spt_20="'+ coalesce(cast(@auto_v3spositiontaking_20 as varchar(50)),space(1)) + '" ' +

'a_v5spt_1="'+ coalesce(cast(@auto_v5spositiontaking_1 as varchar(50)),space(1)) + '" ' +
'a_v5spt_2="'+ coalesce(cast(@auto_v5spositiontaking_2 as varchar(50)),space(1)) + '" ' +
'a_v5spt_3="'+ coalesce(cast(@auto_v5spositiontaking_3 as varchar(50)),space(1)) + '" ' +
'a_v5spt_20="'+ coalesce(cast(@auto_v5spositiontaking_20 as varchar(50)),space(1)) + '" ' +

'a_v8spt_1="'+ coalesce(cast(@auto_v8spositiontaking_1 as varchar(50)),space(1)) + '" ' +
'a_v8spt_3="'+ coalesce(cast(@auto_v8spositiontaking_3 as varchar(50)),space(1)) + '" ' +
'a_v8spt_20="'+ coalesce(cast(@auto_v8spositiontaking_20 as varchar(50)),space(1)) + '" ' +

'a_v10spt_1="'+ coalesce(cast(@auto_v10spositiontaking_1 as varchar(50)),space(1)) + '" ' +
'a_v10spt_2="'+ coalesce(cast(@auto_v10spositiontaking_2 as varchar(50)),space(1)) + '" ' +
'a_v10spt_3="'+ coalesce(cast(@auto_v10spositiontaking_3 as varchar(50)),space(1)) + '" ' +
'a_v10spt_20="'+ coalesce(cast(@auto_v10spositiontaking_20 as varchar(50)),space(1)) + '" ' +

'a_v11spt_1="'+ coalesce(cast(@auto_v11spositiontaking_1 as varchar(50)),space(1)) + '" ' +
'a_v11spt_20="'+ coalesce(cast(@auto_v11spositiontaking_20 as varchar(50)),space(1)) + '" ' +

'a_v99spt_1="'+ coalesce(cast(@auto_v99spositiontaking_1 as varchar(50)),space(1)) + '" ' +
'a_v99spt_2="'+ coalesce(cast(@auto_v99spositiontaking_2 as varchar(50)),space(1)) + '" ' +
'a_v99spt_3="'+ coalesce(cast(@auto_v99spositiontaking_3 as varchar(50)),space(1)) + '" ' +
'a_v99spt_20="'+ coalesce(cast(@auto_v99spositiontaking_20 as varchar(50)),space(1)) + '" />' +

'<ia isa_spt_1="'+ coalesce(cast(@isauto_spositiontaking_1 as varchar(50)),space(1)) + '" ' +
'isa_spt_2="'+ coalesce(cast(@isauto_spositiontaking_2 as varchar(50)),space(1)) + '" ' +
'isa_spt_3="'+ coalesce(cast(@isauto_spositiontaking_3 as varchar(50)),space(1)) + '" ' +
'isa_spt_4="'+ coalesce(cast(@isauto_spositiontaking_4 as varchar(50)),space(1)) + '" ' +
'isa_spt_5="'+ coalesce(cast(@isauto_spositiontaking_5 as varchar(50)),space(1)) + '" ' +
'isa_spt_6="'+ coalesce(cast(@isauto_spositiontaking_6 as varchar(50)),space(1)) + '" ' +
'isa_spt_7="'+ coalesce(cast(@isauto_spositiontaking_7 as varchar(50)),space(1)) + '" ' +
'isa_spt_8="'+ coalesce(cast(@isauto_spositiontaking_8 as varchar(50)),space(1)) + '" ' +
'isa_spt_9="'+ coalesce(cast(@isauto_spositiontaking_9 as varchar(50)),space(1)) + '" ' +
'isa_spt_10="'+ coalesce(cast(@isauto_spositiontaking_10 as varchar(50)),space(1)) + '" ' +
'isa_slivept_1="'+ coalesce(cast(@isauto_slivepositiontaking_1 as varchar(50)),space(1)) + '" ' +
'isa_slivept_3="'+ coalesce(cast(@isauto_slivepositiontaking_3 as varchar(50)),space(1)) + '" ' +
'isa_slivept_7="'+ coalesce(cast(@isauto_slivepositiontaking_7 as varchar(50)),space(1)) + '" ' +
'isa_slivept_8="'+ coalesce(cast(@isauto_slivepositiontaking_8 as varchar(50)),space(1)) + '" ' +

'isa_v2spt_1="'+ coalesce(cast(@isauto_v2spositiontaking_1 as varchar(50)),space(1)) + '" ' +
'isa_v2spt_2="'+ coalesce(cast(@isauto_v2spositiontaking_2 as varchar(50)),space(1)) + '" ' +
'isa_v2spt_3="'+ coalesce(cast(@isauto_v2spositiontaking_3 as varchar(50)),space(1)) + '" ' +
'isa_v2spt_7="'+ coalesce(cast(@isauto_v2spositiontaking_7 as varchar(50)),space(1)) + '" ' +
'isa_v2spt_8="'+ coalesce(cast(@isauto_v2spositiontaking_8 as varchar(50)),space(1)) + '" ' +
'isa_v2spt_9="'+ coalesce(cast(@isauto_v2spositiontaking_9 as varchar(50)),space(1)) + '" ' +
'isa_v2spt_20="'+ coalesce(cast(@isauto_v2spositiontaking_20 as varchar(50)),space(1)) + '" ' +

'isa_v3spt_1="'+ coalesce(cast(@isauto_v3spositiontaking_1 as varchar(50)),space(1)) + '" ' +
'isa_v3spt_2="'+ coalesce(cast(@isauto_v3spositiontaking_2 as varchar(50)),space(1)) + '" ' +
'isa_v3spt_3="'+ coalesce(cast(@isauto_v3spositiontaking_3 as varchar(50)),space(1)) + '" ' +
'isa_v3spt_20="'+ coalesce(cast(@isauto_v3spositiontaking_20 as varchar(50)),space(1)) + '" ' +

'isa_v5spt_1="'+ coalesce(cast(@isauto_v5spositiontaking_1 as varchar(50)),space(1)) + '" ' +
'isa_v5spt_2="'+ coalesce(cast(@isauto_v5spositiontaking_2 as varchar(50)),space(1)) + '" ' +
'isa_v5spt_3="'+ coalesce(cast(@isauto_v5spositiontaking_3 as varchar(50)),space(1)) + '" ' +
'isa_v5spt_20="'+ coalesce(cast(@isauto_v5spositiontaking_20 as varchar(50)),space(1)) + '" ' +

'isa_v8spt_1="'+ coalesce(cast(@isauto_v8spositiontaking_1 as varchar(50)),space(1)) + '" ' +
'isa_v8spt_3="'+ coalesce(cast(@isauto_v8spositiontaking_3 as varchar(50)),space(1)) + '" ' +
'isa_v8spt_20="'+ coalesce(cast(@isauto_v8spositiontaking_20 as varchar(50)),space(1)) + '" ' +

'isa_v10spt_1="'+ coalesce(cast(@isauto_v10spositiontaking_1 as varchar(50)),space(1)) + '" ' +
'isa_v10spt_2="'+ coalesce(cast(@isauto_v10spositiontaking_2 as varchar(50)),space(1)) + '" ' +
'isa_v10spt_3="'+ coalesce(cast(@isauto_v10spositiontaking_3 as varchar(50)),space(1)) + '" ' +
'isa_v10spt_20="'+ coalesce(cast(@isauto_v10spositiontaking_20 as varchar(50)),space(1)) + '" ' +

'isa_v11spt_1="'+ coalesce(cast(@isauto_v11spositiontaking_1 as varchar(50)),space(1)) + '" ' +
'isa_v11spt_20="'+ coalesce(cast(@isauto_v11spositiontaking_20 as varchar(50)),space(1)) + '" ' +

'isa_v99spt_1="'+ coalesce(cast(@isauto_v99spositiontaking_1 as varchar(50)),space(1)) + '" ' +
'isa_v99spt_2="'+ coalesce(cast(@isauto_v99spositiontaking_2 as varchar(50)),space(1)) + '" ' +
'isa_v99spt_3="'+ coalesce(cast(@isauto_v99spositiontaking_3 as varchar(50)),space(1)) + '" ' +
'isa_v99spt_20="'+ coalesce(cast(@isauto_v99spositiontaking_20 as varchar(50)),space(1)) + '" />' +

'<m mpt_1="'+ coalesce(cast(@mpositiontaking_1 as varchar(50)),space(1)) + '" ' +
'mpt_2="'+ coalesce(cast(@mpositiontaking_2 as varchar(50)),space(1)) + '" ' +
'mpt_3="'+ coalesce(cast(@mpositiontaking_3 as varchar(50)),space(1)) + '" ' +
'mpt_4="'+ coalesce(cast(@mpositiontaking_4 as varchar(50)),space(1)) + '" ' +
'mpt_5="'+ coalesce(cast(@mpositiontaking_5 as varchar(50)),space(1)) + '" ' +
'mpt_6="'+ coalesce(cast(@mpositiontaking_6 as varchar(50)),space(1)) + '" ' +
'mpt_7="'+ coalesce(cast(@mpositiontaking_7 as varchar(50)),space(1)) + '" ' +
'mpt_8="'+ coalesce(cast(@mpositiontaking_8 as varchar(50)),space(1)) + '" ' +
'mpt_9="'+ coalesce(cast(@mpositiontaking_9 as varchar(50)),space(1)) + '" ' +
'mpt_10="'+ coalesce(cast(@mpositiontaking_10 as varchar(50)),space(1)) + '" ' +
'mlivept_1="'+ coalesce(cast(@mlivepositiontaking_1 as varchar(50)),space(1)) + '" ' +
'mlivept_3="'+ coalesce(cast(@mlivepositiontaking_3 as varchar(50)),space(1)) + '" ' +
'mlivept_7="'+ coalesce(cast(@mlivepositiontaking_7 as varchar(50)),space(1)) + '" ' +
'mlivept_8="'+ coalesce(cast(@mlivepositiontaking_8 as varchar(50)),space(1)) + '" ' +

'v2mpt_1="'+ coalesce(cast(@v2mpositiontaking_1 as varchar(50)),space(1)) + '" ' +
'v2mpt_2="'+ coalesce(cast(@v2mpositiontaking_2 as varchar(50)),space(1)) + '" ' +
'v2mpt_3="'+ coalesce(cast(@v2mpositiontaking_3 as varchar(50)),space(1)) + '" ' +
'v2mpt_7="'+ coalesce(cast(@v2mpositiontaking_7 as varchar(50)),space(1)) + '" ' +
'v2mpt_8="'+ coalesce(cast(@v2mpositiontaking_8 as varchar(50)),space(1)) + '" ' +
'v2mpt_9="'+ coalesce(cast(@v2mpositiontaking_9 as varchar(50)),space(1)) + '" ' +
'v2mpt_20="'+ coalesce(cast(@v2mpositiontaking_20 as varchar(50)),space(1)) + '" ' +

'v3mpt_1="'+ coalesce(cast(@v3mpositiontaking_1 as varchar(50)),space(1)) + '" ' +
'v3mpt_2="'+ coalesce(cast(@v3mpositiontaking_2 as varchar(50)),space(1)) + '" ' +
'v3mpt_3="'+ coalesce(cast(@v3mpositiontaking_3 as varchar(50)),space(1)) + '" ' +
'v3mpt_20="'+ coalesce(cast(@v3mpositiontaking_20 as varchar(50)),space(1)) + '" ' +

'v5mpt_1="'+ coalesce(cast(@v5mpositiontaking_1 as varchar(50)),space(1)) + '" ' +
'v5mpt_2="'+ coalesce(cast(@v5mpositiontaking_2 as varchar(50)),space(1)) + '" ' +
'v5mpt_3="'+ coalesce(cast(@v5mpositiontaking_3 as varchar(50)),space(1)) + '" ' +
'v5mpt_20="'+ coalesce(cast(@v5mpositiontaking_20 as varchar(50)),space(1)) + '" ' +

'v8mpt_1="'+ coalesce(cast(@v8mpositiontaking_1 as varchar(50)),space(1)) + '" ' +
'v8mpt_3="'+ coalesce(cast(@v8mpositiontaking_3 as varchar(50)),space(1)) + '" ' +
'v8mpt_20="'+ coalesce(cast(@v8mpositiontaking_20 as varchar(50)),space(1)) + '" ' +

'v10mpt_1="'+ coalesce(cast(@v10mpositiontaking_1 as varchar(50)),space(1)) + '" ' +
'v10mpt_2="'+ coalesce(cast(@v10mpositiontaking_2 as varchar(50)),space(1)) + '" ' +
'v10mpt_3="'+ coalesce(cast(@v10mpositiontaking_3 as varchar(50)),space(1)) + '" ' +
'v10mpt_20="'+ coalesce(cast(@v10mpositiontaking_20 as varchar(50)),space(1)) + '" ' +

'v11mpt_1="'+ coalesce(cast(@v11mpositiontaking_1 as varchar(50)),space(1)) + '" ' +
'v11mpt_20="'+ coalesce(cast(@v11mpositiontaking_20 as varchar(50)),space(1)) + '" ' +

'v99mpt_1="'+ coalesce(cast(@v99mpositiontaking_1 as varchar(50)),space(1)) + '" ' +
'v99mpt_2="'+ coalesce(cast(@v99mpositiontaking_2 as varchar(50)),space(1)) + '" ' +
'v99mpt_3="'+ coalesce(cast(@v99mpositiontaking_3 as varchar(50)),space(1)) + '" ' +
'v99mpt_20="'+ coalesce(cast(@v99mpositiontaking_20 as varchar(50)),space(1)) + '" /></Acc_CustomerUpdMaster_PositionTaking>' 

--Log positiontaking
EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew 
	@UserID = @UserID,
	@CustID = @CustID,
	@ActionID = 411,
	@TrackingValue = @LogSPData

GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdMaster_PositionTaking] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdMaster_PositionTaking] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdMaster_PositionTaking] TO vnteam
