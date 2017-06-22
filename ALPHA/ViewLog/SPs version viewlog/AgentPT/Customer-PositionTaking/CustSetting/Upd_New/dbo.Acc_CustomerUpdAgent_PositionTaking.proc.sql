ALTER PROCEDURE [dbo].[Acc_CustomerUpdAgent_PositionTaking]
	@custid int, --agentID
	
	@apositiontaking_1 smallmoney,
	@apositiontaking_2 smallmoney,
	@apositiontaking_3 smallmoney,
	@apositiontaking_4 smallmoney,
	@apositiontaking_5 smallmoney,
	@apositiontaking_6 smallmoney,
	@apositiontaking_7 smallmoney,
	@apositiontaking_8 smallmoney,
	@apositiontaking_9 smallmoney,
	@apositiontaking_10 smallmoney,
	
	@mpositiontaking_1 smallmoney,
	@mpositiontaking_2 smallmoney,
	@mpositiontaking_3 smallmoney,
	@mpositiontaking_4 smallmoney,
	@mpositiontaking_5 smallmoney,
	@mpositiontaking_6 smallmoney,
	@mpositiontaking_7 smallmoney,
	@mpositiontaking_8 smallmoney,
	@mpositiontaking_9 smallmoney,
	@mpositiontaking_10 smallmoney,
	
	@alivepositiontaking_1 smallmoney,
	@alivepositiontaking_3 smallmoney,
	@alivepositiontaking_7 smallmoney,
	@alivepositiontaking_8 smallmoney,
	@mlivepositiontaking_1 smallmoney,
	@mlivepositiontaking_3 smallmoney,
	@mlivepositiontaking_7 smallmoney,
	@mlivepositiontaking_8 smallmoney,
	
	@v2apositiontaking_1 smallmoney,
	@v2apositiontaking_2 smallmoney,
	@v2apositiontaking_3 smallmoney,
	@v2apositiontaking_7 smallmoney,
	@v2apositiontaking_8 smallmoney,
	@v2apositiontaking_9 smallmoney,
	@v2apositiontaking_20 smallmoney,

	@v3apositiontaking_1 smallmoney,
	@v3apositiontaking_2 smallmoney,
	@v3apositiontaking_3 smallmoney,
	@v3apositiontaking_20 smallmoney,

	@v5apositiontaking_1 smallmoney,
	@v5apositiontaking_2 smallmoney,
	@v5apositiontaking_3 smallmoney,
	@v5apositiontaking_20 smallmoney,

	@v8apositiontaking_1 smallmoney,
	@v8apositiontaking_3 smallmoney,
	@v8apositiontaking_20 smallmoney,

	@v10apositiontaking_1 smallmoney,
	@v10apositiontaking_2 smallmoney,
	@v10apositiontaking_3 smallmoney,
	@v10apositiontaking_20 smallmoney,

	@v11apositiontaking_1 smallmoney,
	@v11apositiontaking_20 smallmoney,

	@v99apositiontaking_1 smallmoney,
	@v99apositiontaking_2 smallmoney,
	@v99apositiontaking_3 smallmoney,
	@v99apositiontaking_20 smallmoney,
	
	@v2mpositiontaking_1 smallmoney,
	@v2mpositiontaking_2 smallmoney,
	@v2mpositiontaking_3 smallmoney,
	@v2mpositiontaking_7 smallmoney,
	@v2mpositiontaking_8 smallmoney,
	@v2mpositiontaking_9 smallmoney,
	@v2mpositiontaking_20 smallmoney,

	@v3mpositiontaking_1 smallmoney,
	@v3mpositiontaking_2 smallmoney,
	@v3mpositiontaking_3 smallmoney,
	@v3mpositiontaking_20 smallmoney,

	@v5mpositiontaking_1 smallmoney,
	@v5mpositiontaking_2 smallmoney,
	@v5mpositiontaking_3 smallmoney,
	@v5mpositiontaking_20 smallmoney,

	@v8mpositiontaking_1 smallmoney,
	@v8mpositiontaking_3 smallmoney,
	@v8mpositiontaking_20 smallmoney,

	@v10mpositiontaking_1 smallmoney,
	@v10mpositiontaking_2 smallmoney,
	@v10mpositiontaking_3 smallmoney,
	@v10mpositiontaking_20 smallmoney,

	@v11mpositiontaking_1 smallmoney,
	@v11mpositiontaking_20 smallmoney,

	@v99mpositiontaking_1 smallmoney,
	@v99mpositiontaking_2 smallmoney,
	@v99mpositiontaking_3 smallmoney,
	@v99mpositiontaking_20 smallmoney,
	
	@auto_mpositiontaking_1 smallmoney = 0,
	@auto_mpositiontaking_2 smallmoney = 0,
	@auto_mpositiontaking_3 smallmoney = 0,
	@auto_mpositiontaking_4 smallmoney = 0,
	@auto_mpositiontaking_5 smallmoney= 0,
	@auto_mpositiontaking_6 smallmoney = 0,
	@auto_mpositiontaking_7 smallmoney = 0,
	@auto_mpositiontaking_8 smallmoney = 0,
	@auto_mpositiontaking_9 smallmoney = 0,
	@auto_mpositiontaking_10 smallmoney = 0,
	@auto_mlivepositiontaking_1 smallmoney = 0,
	@auto_mlivepositiontaking_3 smallmoney = 0,
	@auto_mlivepositiontaking_7 smallmoney = 0,
	@auto_mlivepositiontaking_8 smallmoney = 0,
	
	@auto_v2mpositiontaking_1 smallmoney = 0,
	@auto_v2mpositiontaking_2 smallmoney = 0,
	@auto_v2mpositiontaking_3 smallmoney = 0,
	@auto_v2mpositiontaking_7 smallmoney = 0,
	@auto_v2mpositiontaking_8 smallmoney = 0,
	@auto_v2mpositiontaking_9 smallmoney = 0,
	@auto_v2mpositiontaking_20 smallmoney = 0,
	
	@auto_v3mpositiontaking_1 smallmoney = 0,
	@auto_v3mpositiontaking_2 smallmoney = 0,
	@auto_v3mpositiontaking_3 smallmoney = 0,
	@auto_v3mpositiontaking_20 smallmoney = 0,
	
	@auto_v5mpositiontaking_1 smallmoney = 0,
	@auto_v5mpositiontaking_2 smallmoney = 0,
	@auto_v5mpositiontaking_3 smallmoney = 0,
	@auto_v5mpositiontaking_20 smallmoney = 0,
	
	@auto_v8mpositiontaking_1 smallmoney = 0,
	@auto_v8mpositiontaking_3 smallmoney = 0,
	@auto_v8mpositiontaking_20 smallmoney = 0,
	
	@auto_v10mpositiontaking_1 smallmoney = 0,
	@auto_v10mpositiontaking_2 smallmoney = 0,
	@auto_v10mpositiontaking_3 smallmoney = 0,
	@auto_v10mpositiontaking_20 smallmoney = 0,
	
	@auto_v11mpositiontaking_1 smallmoney = 0,
	@auto_v11mpositiontaking_20 smallmoney = 0,

	@auto_v99mpositiontaking_1 smallmoney = 0,
	@auto_v99mpositiontaking_2 smallmoney = 0,
	@auto_v99mpositiontaking_3 smallmoney = 0,
	@auto_v99mpositiontaking_20 smallmoney = 0,	
	
	@isauto_mpositiontaking_1 bit = 0,
	@isauto_mpositiontaking_2 bit = 0,
	@isauto_mpositiontaking_3 bit = 0,
	@isauto_mpositiontaking_4 bit = 0,
	@isauto_mpositiontaking_5 bit= 0,
	@isauto_mpositiontaking_6 bit = 0,
	@isauto_mpositiontaking_7 bit = 0,
	@isauto_mpositiontaking_8 bit = 0,
	@isauto_mpositiontaking_9 bit = 0,
	@isauto_mpositiontaking_10 bit = 0,
	@isauto_mlivepositiontaking_1 bit = 0,
	@isauto_mlivepositiontaking_3 bit = 0,
	@isauto_mlivepositiontaking_7 bit = 0,
	@isauto_mlivepositiontaking_8 bit = 0,
	
	@isauto_v2mpositiontaking_1 bit = 0,
	@isauto_v2mpositiontaking_2 bit = 0,
	@isauto_v2mpositiontaking_3 bit = 0,
	@isauto_v2mpositiontaking_7 bit = 0,
	@isauto_v2mpositiontaking_8 bit = 0,
	@isauto_v2mpositiontaking_9 bit = 0,
	@isauto_v2mpositiontaking_20 bit = 0,
	
	@isauto_v3mpositiontaking_1 bit = 0,
	@isauto_v3mpositiontaking_2 bit = 0,
	@isauto_v3mpositiontaking_3 bit = 0,
	@isauto_v3mpositiontaking_20 bit = 0,
	
	@isauto_v5mpositiontaking_1 bit = 0,
	@isauto_v5mpositiontaking_2 bit = 0,
	@isauto_v5mpositiontaking_3 bit = 0,
	@isauto_v5mpositiontaking_20 bit = 0,
	
	@isauto_v8mpositiontaking_1 bit = 0,
	@isauto_v8mpositiontaking_3 bit = 0,
	@isauto_v8mpositiontaking_20 bit = 0,
	
	@isauto_v10mpositiontaking_1 bit = 0,
	@isauto_v10mpositiontaking_2 bit = 0,
	@isauto_v10mpositiontaking_3 bit = 0,
	@isauto_v10mpositiontaking_20 bit = 0,
	
	@isauto_v11mpositiontaking_1 bit = 0,
	@isauto_v11mpositiontaking_20 bit = 0,

	@isauto_v99mpositiontaking_1 bit = 0,
	@isauto_v99mpositiontaking_2 bit = 0,
	@isauto_v99mpositiontaking_3 bit = 0,
	@isauto_v99mpositiontaking_20 bit = 0,	
	
	@updateallmembers bit = 0,
	@newmpositiontaking smallmoney = 0,--equals max(m+a) - chosen(a)

	@UpdateMultiple bit = 0,
	
	@UpdatePositiontaking bit = 1 OUTPUT,
	@UpdatePositiontakingv2 bit = 1 OUTPUT,
	@UpdatePositiontakingv3 bit = 1 OUTPUT,
	@UpdatePositiontakingv5 bit = 1 OUTPUT,
	@UpdatePositiontakingv8 bit = 1 OUTPUT,
	@UpdatePositiontakingv10 bit = 1 OUTPUT,
	@UpdatePositiontakingv11 bit = 1 OUTPUT,
	@UpdatePositiontakingv99 bit = 1 OUTPUT,
		
	@SubAccID int = 0, --Sub-AccountID	
	
	@UserID int = 0,	
	@Language varchar(2) = 'E',
	@IP varchar(15)='',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS
--@Source Control
/*
Created: 20080515@Thien
Task : Update Agent's Position Taking
DB: DB02.bodb02
Original: Acc_CustomerUpdEditCustomer_MAg

Revisions:
    - 20081003@Phuc: Auto Master PT 
		check n3<=m2+a2<=l3 if i2 = 0
			else a2<=l3 and u2+a2>=n3 if i2 = 1			
    - 20090314@HanhVu: add Korean language
    - 20090424@Phuc:Separate finance sporttype(201).
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

Declare @UserName varchar(20), @mrecommend int, @srecommend int
declare @ErrAcc varchar(4000), @ErrType varchar(4000)
Select @UserName = username, @mrecommend = mrecommend, @srecommend = srecommend from custinfo with (NOLOCK) where CustID = @CustID
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Check Param
if @UpdateMultiple = 0 or @UpdatePositiontaking = 1
BEGIN
	if 
		@apositiontaking_1  <0
		or @apositiontaking_2  <0
		or @apositiontaking_3  <0
		or @apositiontaking_4  <0
		or @apositiontaking_5  <0
		or @apositiontaking_6  <0
		or @apositiontaking_7  <0
		or @apositiontaking_8  <0
		or @apositiontaking_9  <0
		or @alivepositiontaking_1  <0
		or @alivepositiontaking_3  <0
		or @alivepositiontaking_7  <0
		or @alivepositiontaking_8  <0
		or @apositiontaking_10 <0
		or @apositiontaking_1+@mpositiontaking_1 >0.9
		or @apositiontaking_2+@mpositiontaking_2 >0.9
		or @apositiontaking_3+@mpositiontaking_3 >0.9
		or @apositiontaking_4+@mpositiontaking_4 >0.9
		or @apositiontaking_5+@mpositiontaking_5 >0.9
		or @apositiontaking_6+@mpositiontaking_6 >0.9
		or @apositiontaking_7+@mpositiontaking_7 >0.9
		or @apositiontaking_8+@mpositiontaking_8 >0.9
		or @apositiontaking_9+@mpositiontaking_9 >0.9
		or @apositiontaking_10+@mpositiontaking_10 >0.9
		or @alivepositiontaking_1+@mlivepositiontaking_1 >0.9
		or @alivepositiontaking_3+@mlivepositiontaking_3 >0.9
		or @alivepositiontaking_7+@mlivepositiontaking_7 >0.9
		or @alivepositiontaking_8+@mlivepositiontaking_8 >0.9
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
		or @mpositiontaking_1  >0.9
		or @mpositiontaking_2  >0.9
		or @mpositiontaking_3  >0.9
		or @mpositiontaking_4  >0.9
		or @mpositiontaking_5  >0.9
		or @mpositiontaking_6  >0.9
		or @mpositiontaking_7  >0.9
		or @mpositiontaking_8  >0.9
		or @mpositiontaking_9  >0.9
		or @mlivepositiontaking_1  >0.9
		or @mlivepositiontaking_3  >0.9
		or @mlivepositiontaking_7  >0.9
		or @mlivepositiontaking_8  >0.9
		or @mpositiontaking_10 >0.9
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

	--check n3<=m2+a2<=l3 if i2 = 0, 
	--a2<=l3 and u2+a2>=n3 if i2 = 1
	
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Min: '+ cast((co.minpositiontaking) as varchar(10))+ '-Max: '+ cast((co.maxpositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '--MinLive: '+ cast((co.minlivepositiontaking) as varchar(10))+ '-MaxLive: '+ cast((co.maxlivepositiontaking) as varchar(10)) else '' end + '<br>'
	from 
		custoverride as co with (NOLOCK) 
		inner join
		(
						select 1 as bettype, 1 as sporttype, @apositiontaking_1 as apositiontaking, @alivepositiontaking_1 as alivepositiontaking, @mpositiontaking_1 as mpositiontaking, @mlivepositiontaking_1 as mlivepositiontaking, @isauto_mpositiontaking_1 as isauto_mpositiontaking,  @isauto_mlivepositiontaking_1 as isauto_mlivepositiontaking, @auto_mpositiontaking_1 as auto_mpositiontaking,  @auto_mlivepositiontaking_1 as auto_mlivepositiontaking
			union all 	select 3 as bettype, 1 as sporttype, @apositiontaking_3 as apositiontaking, @alivepositiontaking_3 as alivepositiontaking, @mpositiontaking_3 as mpositiontaking, @mlivepositiontaking_3 as mlivepositiontaking, @isauto_mpositiontaking_3 as isauto_mpositiontaking,  @isauto_mlivepositiontaking_3 as isauto_mlivepositiontaking, @auto_mpositiontaking_3 as auto_mpositiontaking,  @auto_mlivepositiontaking_3 as auto_mlivepositiontaking
			union all 	select 7 as bettype, 1 as sporttype, @apositiontaking_7 as apositiontaking, @alivepositiontaking_7 as alivepositiontaking, @mpositiontaking_7 as mpositiontaking, @mlivepositiontaking_7 as mlivepositiontaking, @isauto_mpositiontaking_7 as isauto_mpositiontaking,  @isauto_mlivepositiontaking_7 as isauto_mlivepositiontaking, @auto_mpositiontaking_7 as auto_mpositiontaking,  @auto_mlivepositiontaking_7 as auto_mlivepositiontaking
			union all 	select 8 as bettype, 1 as sporttype, @apositiontaking_8 as apositiontaking, @alivepositiontaking_8 as alivepositiontaking, @mpositiontaking_8 as mpositiontaking, @mlivepositiontaking_8 as mlivepositiontaking, @isauto_mpositiontaking_8 as isauto_mpositiontaking,  @isauto_mlivepositiontaking_8 as isauto_mlivepositiontaking, @auto_mpositiontaking_8 as auto_mpositiontaking,  @auto_mlivepositiontaking_8 as auto_mlivepositiontaking
			union all 	select 2 as bettype, 1 as sporttype, @apositiontaking_2 as apositiontaking, 0 as alivepositiontaking, @mpositiontaking_2 as mpositiontaking, 0 as mlivepositiontaking, @isauto_mpositiontaking_2 as isauto_mpositiontaking, 0 as isauto_mlivepositiontaking, @auto_mpositiontaking_2 as auto_mpositiontaking,  0 as auto_mlivepositiontaking
			union all 	select 4 as bettype, 1 as sporttype, @apositiontaking_4 as apositiontaking, 0 as alivepositiontaking, @mpositiontaking_4 as mpositiontaking, 0 as mlivepositiontaking, @isauto_mpositiontaking_4 as isauto_mpositiontaking, 0 as isauto_mlivepositiontaking, @auto_mpositiontaking_4 as auto_mpositiontaking,  0 as auto_mlivepositiontaking
			union all 	select 5 as bettype, 1 as sporttype, @apositiontaking_5 as apositiontaking, 0 as alivepositiontaking, @mpositiontaking_5 as mpositiontaking, 0 as mlivepositiontaking, @isauto_mpositiontaking_5 as isauto_mpositiontaking, 0 as isauto_mlivepositiontaking, @auto_mpositiontaking_5 as auto_mpositiontaking,  0 as auto_mlivepositiontaking
			union all 	select 6 as bettype, 1 as sporttype, @apositiontaking_6 as apositiontaking, 0 as alivepositiontaking, @mpositiontaking_6 as mpositiontaking, 0 as mlivepositiontaking, @isauto_mpositiontaking_6 as isauto_mpositiontaking, 0 as isauto_mlivepositiontaking, @auto_mpositiontaking_6 as auto_mpositiontaking,  0 as auto_mlivepositiontaking
			union all 	select 9 as bettype, 1 as sporttype, @apositiontaking_9 as apositiontaking, 0 as alivepositiontaking, @mpositiontaking_9 as mpositiontaking, 0 as mlivepositiontaking, @isauto_mpositiontaking_9 as isauto_mpositiontaking, 0 as isauto_mlivepositiontaking, @auto_mpositiontaking_9 as auto_mpositiontaking,  0 as auto_mlivepositiontaking
			union all 	select 10 as bettype, 1 as sporttype, @apositiontaking_10 as apositiontaking, 0 as alivepositiontaking, @mpositiontaking_10 as mpositiontaking, 0 as mlivepositiontaking, @isauto_mpositiontaking_10 as isauto_mpositiontaking, 0 as isauto_mlivepositiontaking, @auto_mpositiontaking_10 as auto_mpositiontaking,  0 as auto_mlivepositiontaking
		) as b on co.sporttype=b.sporttype and co.bettype = b.bettype
		inner join sports with (nolock) on b.sporttype = sports.sporttype
		inner join bettype with (nolock) on b.bettype = bettype.typeid
	where co.custid = @mrecommend and (	
						((b.isauto_mpositiontaking=0) and (b.mpositiontaking+b.apositiontaking>co.maxpositiontaking or b.mpositiontaking+b.apositiontaking<co.minpositiontaking)) or 
						(b.isauto_mpositiontaking>0 and (b.apositiontaking>co.maxpositiontaking or b.apositiontaking + b.auto_mpositiontaking<co.minpositiontaking)) or 
						((b.sporttype = 1 and b.bettype in (1,3,7,8) and b.isauto_mlivepositiontaking=0) and (b.mlivepositiontaking+b.alivepositiontaking>co.maxlivepositiontaking or b.mlivepositiontaking+b.alivepositiontaking<co.minlivepositiontaking)) or
						((b.sporttype = 1 and b.bettype in (1,3,7,8) and b.isauto_mlivepositiontaking>0) and (b.alivepositiontaking>co.maxlivepositiontaking or b.alivepositiontaking + b.auto_mlivepositiontaking<co.minlivepositiontaking))
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
							when 'KO' then N'거래 조건이 잘못 되었습니다 (ibc가 설정한 최소값/최대값 ).<br>'+@ErrType
							else N'Wrong position taking (min/max set by company).<br>'+@ErrType
					end
		return
	END
	--check n2<=a2<=l2 
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Min: '+ cast((co.minpositiontaking) as varchar(10))+ '-Max: '+ cast((co.maxpositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '--MinLive: '+ cast((co.minlivepositiontaking) as varchar(10))+ '-MaxLive: '+ cast((co.maxlivepositiontaking) as varchar(10)) else '' end + '<br>'
	from 
		custoverride as co with (NOLOCK) 
		inner join
		(
						select 1 as bettype, 1 as sporttype, @apositiontaking_1 as apositiontaking, @alivepositiontaking_1 as alivepositiontaking, @mpositiontaking_1 as mpositiontaking, @mlivepositiontaking_1 as mlivepositiontaking
			union all 	select 3 as bettype, 1 as sporttype, @apositiontaking_3 as apositiontaking, @alivepositiontaking_3 as alivepositiontaking, @mpositiontaking_3 as mpositiontaking, @mlivepositiontaking_3 as mlivepositiontaking
			union all 	select 7 as bettype, 1 as sporttype, @apositiontaking_7 as apositiontaking, @alivepositiontaking_7 as alivepositiontaking, @mpositiontaking_7 as mpositiontaking, @mlivepositiontaking_7 as mlivepositiontaking
			union all 	select 8 as bettype, 1 as sporttype, @apositiontaking_8 as apositiontaking, @alivepositiontaking_8 as alivepositiontaking, @mpositiontaking_8 as mpositiontaking, @mlivepositiontaking_8 as mlivepositiontaking
			union all 	select 2 as bettype, 1 as sporttype, @apositiontaking_2 as apositiontaking, 0 as alivepositiontaking, @mpositiontaking_2 as mpositiontaking, 0 as mlivepositiontaking
			union all 	select 4 as bettype, 1 as sporttype, @apositiontaking_4 as apositiontaking, 0 as alivepositiontaking, @mpositiontaking_4 as mpositiontaking, 0 as mlivepositiontaking
			union all 	select 5 as bettype, 1 as sporttype, @apositiontaking_5 as apositiontaking, 0 as alivepositiontaking, @mpositiontaking_5 as mpositiontaking, 0 as mlivepositiontaking
			union all 	select 6 as bettype, 1 as sporttype, @apositiontaking_6 as apositiontaking, 0 as alivepositiontaking, @mpositiontaking_6 as mpositiontaking, 0 as mlivepositiontaking
			union all 	select 9 as bettype, 1 as sporttype, @apositiontaking_9 as apositiontaking, 0 as alivepositiontaking, @mpositiontaking_9 as mpositiontaking, 0 as mlivepositiontaking
			union all 	select 10 as bettype, 1 as sporttype, @apositiontaking_10 as apositiontaking, 0 as alivepositiontaking, @mpositiontaking_10 as mpositiontaking, 0 as mlivepositiontaking
		) as b on co.sporttype=b.sporttype and co.bettype = b.bettype
		inner join sports with (nolock) on b.sporttype = sports.sporttype
		inner join bettype with (nolock) on b.bettype = bettype.typeid
	where co.custid = @custid and (	
						(b.apositiontaking>co.maxpositiontaking or b.apositiontaking<co.minpositiontaking) or 
						(b.sporttype = 1 and b.bettype in (1,3,7,8) and (b.alivepositiontaking>co.maxlivepositiontaking or b.alivepositiontaking<co.minlivepositiontaking))
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
							when 'KO' then N'거래 조건이 잘못 되었습니다 (ibc가 설정한 최소값/최대값 ).<br>'+@ErrType
							else N'Wrong position taking (min/max set by company).<br>'+@ErrType
					end
		return
	END

	--check a2<=a4 - Vinh
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ cast((scs.apositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '-MaxLive: '+ cast((scs.alivepositiontaking) as varchar(10)) else '' end + '<br>'
	from customer as c with (NOLOCK) inner join custsetting as scs with (NOLOCK) on c.srecommend = scs.custid inner join 
		(
						select 1 as bettype, 1 as sporttype, @apositiontaking_1 as apositiontaking, @alivepositiontaking_1 as alivepositiontaking, @mpositiontaking_1 as mpositiontaking, @mlivepositiontaking_1 as mlivepositiontaking
			union all 	select 3 as bettype, 1 as sporttype, @apositiontaking_3 as apositiontaking, @alivepositiontaking_3 as alivepositiontaking, @mpositiontaking_3 as mpositiontaking, @mlivepositiontaking_3 as mlivepositiontaking
			union all 	select 7 as bettype, 1 as sporttype, @apositiontaking_7 as apositiontaking, @alivepositiontaking_7 as alivepositiontaking, @mpositiontaking_7 as mpositiontaking, @mlivepositiontaking_7 as mlivepositiontaking
			union all 	select 8 as bettype, 1 as sporttype, @apositiontaking_8 as apositiontaking, @alivepositiontaking_8 as alivepositiontaking, @mpositiontaking_8 as mpositiontaking, @mlivepositiontaking_8 as mlivepositiontaking
			union all 	select 2 as bettype, 1 as sporttype, @apositiontaking_2 as apositiontaking, 0 as alivepositiontaking, @mpositiontaking_2 as mpositiontaking, 0 as mlivepositiontaking
			union all 	select 4 as bettype, 1 as sporttype, @apositiontaking_4 as apositiontaking, 0 as alivepositiontaking, @mpositiontaking_4 as mpositiontaking, 0 as mlivepositiontaking
			union all 	select 5 as bettype, 1 as sporttype, @apositiontaking_5 as apositiontaking, 0 as alivepositiontaking, @mpositiontaking_5 as mpositiontaking, 0 as mlivepositiontaking
			union all 	select 6 as bettype, 1 as sporttype, @apositiontaking_6 as apositiontaking, 0 as alivepositiontaking, @mpositiontaking_6 as mpositiontaking, 0 as mlivepositiontaking
			union all 	select 9 as bettype, 1 as sporttype, @apositiontaking_9 as apositiontaking, 0 as alivepositiontaking, @mpositiontaking_9 as mpositiontaking, 0 as mlivepositiontaking
			union all 	select 10 as bettype, 1 as sporttype, @apositiontaking_10 as apositiontaking, 0 as alivepositiontaking, @mpositiontaking_10 as mpositiontaking, 0 as mlivepositiontaking
			) as b on scs.sporttype=b.sporttype and scs.bettype = b.bettype
		inner join sports with (nolock) on b.sporttype = sports.sporttype
		inner join bettype with (nolock) on b.bettype = bettype.typeid
	where c.custid = @mrecommend and 
		(b.apositiontaking>scs.apositiontaking or (b.sporttype = 1 and b.bettype in (1,3,7,8) and b.alivepositiontaking>scs.alivepositiontaking))

	if @ErrType <>''
	BEGIN
		select @ErrCode = 11
		Select @ErrMsg = 	@UserName + ': '+
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
END

--Basketball
if @UpdateMultiple = 0 or @UpdatePositiontakingv2 = 1
BEGIN
	if 
		@v2apositiontaking_1  <0
		or @v2apositiontaking_2  <0
		or @v2apositiontaking_3  <0
--		or @v2apositiontaking_7  <0
--		or @v2apositiontaking_8  <0
		or @v2apositiontaking_9  <0
		or @v2apositiontaking_20  <0
		
		or @v2apositiontaking_1+@v2mpositiontaking_1 >0.9
		or @v2apositiontaking_2+@v2mpositiontaking_2 >0.9
		or @v2apositiontaking_3+@v2mpositiontaking_3 >0.9
--		or @v2apositiontaking_7+@v2mpositiontaking_7 >0.9
--		or @v2apositiontaking_8+@v2mpositiontaking_8 >0.9
		or @v2apositiontaking_9+@v2mpositiontaking_9 >0.9
		or @v2apositiontaking_20+@v2mpositiontaking_20 >0.9
	
		or @v2mpositiontaking_1 <0
		or @v2mpositiontaking_2 <0
		or @v2mpositiontaking_3 <0
--		or @v2mpositiontaking_7 <0
--		or @v2mpositiontaking_8 <0
		or @v2mpositiontaking_9 <0
		or @v2mpositiontaking_20 <0
		
		or @v2mpositiontaking_1 >0.9
		or @v2mpositiontaking_2 >0.9
		or @v2mpositiontaking_3 >0.9
--		or @v2mpositiontaking_7 >0.9
--		or @v2mpositiontaking_8 >0.9
		or @v2mpositiontaking_9 >0.9
		or @v2mpositiontaking_20 >0.9
	BEGIN
		select @ErrCode = 8
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Wrong position taking (for Basketball).'
							when 'CS' then N'占成数不正确(于篮球).'
							when 'CT' then N'佔成數不正確(於籃球).'
							when 'TH' then N'การกำหนดจำนวนเงินไม่ถูกต้อง (สำหรับกีฬาบาสเก็ตบอล).'
							when 'J' then N'Wrong position taking (for Basketball).'
							when 'KO' then N'거래 조건이 잘못 되었습니다 (농구).'
							else N'Wrong position taking (for Basketball).'
					end
		return
	END
	
	--check n3<=m2+a2<=l3 if i2 = 0, 
	--a2<=l3 and u2+a2>=n3 if i2 = 1
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Min: '+ cast((co.minpositiontaking) as varchar(10))+ '-Max: '+ cast((co.maxpositiontaking) as varchar(10))+ '<br>'
	from custoverride as co with (NOLOCK) inner join
		(
				 		select 1 as bettype, 2 as sporttype, @v2apositiontaking_1 as apositiontaking, 0 as alivepositiontaking, @v2mpositiontaking_1 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v2mpositiontaking_1 as isauto_mpositiontaking,  0 as isauto_mlivepositiontaking, @auto_v2mpositiontaking_1 as auto_mpositiontaking
			union all 	select 2 as bettype, 2 as sporttype, @v2apositiontaking_2 as apositiontaking, 0 as alivepositiontaking, @v2mpositiontaking_2 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v2mpositiontaking_2 as isauto_mpositiontaking,  0 as isauto_mlivepositiontaking, @auto_v2mpositiontaking_2 as auto_mpositiontaking
			union all 	select 3 as bettype, 2 as sporttype, @v2apositiontaking_3 as apositiontaking, 0 as alivepositiontaking, @v2mpositiontaking_3 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v2mpositiontaking_3 as isauto_mpositiontaking,  0 as isauto_mlivepositiontaking, @auto_v2mpositiontaking_3 as auto_mpositiontaking
			union all 	select 9 as bettype, 2 as sporttype, @v2apositiontaking_9 as apositiontaking, 0 as alivepositiontaking, @v2mpositiontaking_9 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v2mpositiontaking_9 as isauto_mpositiontaking,  0 as isauto_mlivepositiontaking, @auto_v2mpositiontaking_9 as auto_mpositiontaking
			union all 	select 20 as bettype, 2 as sporttype, @v2apositiontaking_20 as apositiontaking, 0 as alivepositiontaking, @v2mpositiontaking_20 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v2mpositiontaking_20 as isauto_mpositiontaking,  0 as isauto_mlivepositiontaking, @auto_v2mpositiontaking_20 as auto_mpositiontaking
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
		Select @ErrMsg = 	case @Language 
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
	from custoverride as co with (NOLOCK) inner join
		(
				 	select 1 as bettype, 2 as sporttype, @v2apositiontaking_1 as apositiontaking, 0 as alivepositiontaking, @v2mpositiontaking_1 as mpositiontaking, 0 as mlivepositiontaking
			union all 	select 2 as bettype, 2 as sporttype, @v2apositiontaking_2 as apositiontaking, 0 as alivepositiontaking, @v2mpositiontaking_2 as mpositiontaking, 0 as mlivepositiontaking
			union all 	select 3 as bettype, 2 as sporttype, @v2apositiontaking_3 as apositiontaking, 0 as alivepositiontaking, @v2mpositiontaking_3 as mpositiontaking, 0 as mlivepositiontaking
			union all 	select 9 as bettype, 2 as sporttype, @v2apositiontaking_9 as apositiontaking, 0 as alivepositiontaking, @v2mpositiontaking_9 as mpositiontaking, 0 as mlivepositiontaking
			union all 	select 20 as bettype, 2 as sporttype, @v2apositiontaking_20 as apositiontaking, 0 as alivepositiontaking, @v2mpositiontaking_20 as mpositiontaking, 0 as mlivepositiontaking

		) as b on co.sporttype=b.sporttype and co.bettype = b.bettype
		inner join sports with (nolock) on b.sporttype = sports.sporttype
		inner join bettype with (nolock) on b.bettype = bettype.typeid
	where co.custid = @custid and (	
						(b.apositiontaking>co.maxpositiontaking or b.apositiontaking<co.minpositiontaking)
					)
	if @ErrType <>''
	BEGIN
		select @ErrCode = 10
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


	--check a2<=a4 - Vinh
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ cast((scs.apositiontaking) as varchar(10)) + '<br>'
	from customer as c with (NOLOCK) inner join custsetting as scs with (NOLOCK) on c.srecommend = scs.custid inner join 
		(
				 	select 1 as bettype, 2 as sporttype, @v2apositiontaking_1 as apositiontaking, 0 as alivepositiontaking, @v2mpositiontaking_1 as mpositiontaking, 0 as mlivepositiontaking
			union all 	select 2 as bettype, 2 as sporttype, @v2apositiontaking_2 as apositiontaking, 0 as alivepositiontaking, @v2mpositiontaking_2 as mpositiontaking, 0 as mlivepositiontaking
			union all 	select 3 as bettype, 2 as sporttype, @v2apositiontaking_3 as apositiontaking, 0 as alivepositiontaking, @v2mpositiontaking_3 as mpositiontaking, 0 as mlivepositiontaking
			union all 	select 9 as bettype, 2 as sporttype, @v2apositiontaking_9 as apositiontaking, 0 as alivepositiontaking, @v2mpositiontaking_9 as mpositiontaking, 0 as mlivepositiontaking
			union all 	select 20 as bettype, 2 as sporttype, @v2apositiontaking_20 as apositiontaking, 0 as alivepositiontaking, @v2mpositiontaking_20 as mpositiontaking, 0 as mlivepositiontaking
	
		) as b on scs.sporttype=b.sporttype and scs.bettype = b.bettype
		inner join sports with (nolock) on b.sporttype = sports.sporttype
		inner join bettype with (nolock) on b.bettype = bettype.typeid
	where c.custid = @mrecommend and (b.apositiontaking>scs.apositiontaking or (b.sporttype = 1 and b.bettype in (1,3,7,8) and b.alivepositiontaking>scs.alivepositiontaking))
	if @ErrType <>''
	BEGIN
		select @ErrCode = 12
		Select @ErrMsg = 	@UserName + ': '+
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
END

--Football
if @UpdateMultiple = 0 or @UpdatePositiontakingv3 = 1
BEGIN
	if 
		@v3apositiontaking_1  <0
		or @v3apositiontaking_2  <0
		or @v3apositiontaking_3  <0
		or @v3apositiontaking_20  <0
		
		or @v3apositiontaking_1+@v3mpositiontaking_1 >0.9
		or @v3apositiontaking_2+@v3mpositiontaking_2 >0.9
		or @v3apositiontaking_3+@v3mpositiontaking_3 >0.9
		or @v3apositiontaking_20+@v3mpositiontaking_20 >0.9
		
		or @v3mpositiontaking_1 <0
		or @v3mpositiontaking_2 <0
		or @v3mpositiontaking_3 <0
		or @v3mpositiontaking_20 <0
		
		or @v3mpositiontaking_1 >0.9
		or @v3mpositiontaking_2 >0.9
		or @v3mpositiontaking_3 >0.9
		or @v3mpositiontaking_20 >0.9
	BEGIN
		select @ErrCode = 8
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Wrong position taking (for Football).'
							when 'CS' then N'占成数不正确(于美式足球).'
							when 'CT' then N'佔成數不正確(於美式足球).'
							when 'TH' then N'การกำหนดจำนวนเงินไม่ถูกต้อง (สำหรับกีฬาอเมริกันฟุตบอล).'
							when 'J' then N'Wrong position taking (for Football).'
							when 'KO' then N'거래 조건이 잘못 되었습니다 (풋볼).'
							else N'Wrong position taking (for Football).'
					end
		return
	END
	
	--check n3<=m2+a2<=l3 if i2 = 0, 
	--a2<=l3 and u2+a2>=n3 if i2 = 1
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Min: '+ cast((co.minpositiontaking) as varchar(10))+ '-Max: '+ cast((co.maxpositiontaking) as varchar(10))+ '<br>'
	from custoverride as co with (NOLOCK) inner join
		(
				 		select 1 as bettype, 3 as sporttype, @v3apositiontaking_1 as apositiontaking, 0 as alivepositiontaking, @v3mpositiontaking_1 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v3mpositiontaking_1 as isauto_mpositiontaking,  0 as isauto_mlivepositiontaking, @auto_v3mpositiontaking_1 as auto_mpositiontaking
			union all 	select 2 as bettype, 3 as sporttype, @v3apositiontaking_2 as apositiontaking, 0 as alivepositiontaking, @v3mpositiontaking_2 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v3mpositiontaking_2 as isauto_mpositiontaking,  0 as isauto_mlivepositiontaking, @auto_v3mpositiontaking_2 as auto_mpositiontaking
			union all 	select 3 as bettype, 3 as sporttype, @v3apositiontaking_3 as apositiontaking, 0 as alivepositiontaking, @v3mpositiontaking_3 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v3mpositiontaking_3 as isauto_mpositiontaking,  0 as isauto_mlivepositiontaking, @auto_v3mpositiontaking_3 as auto_mpositiontaking
			union all 	select 20 as bettype, 3 as sporttype, @v3apositiontaking_20 as apositiontaking, 0 as alivepositiontaking, @v3mpositiontaking_20 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v3mpositiontaking_20 as isauto_mpositiontaking,  0 as isauto_mlivepositiontaking, @auto_v3mpositiontaking_20 as auto_mpositiontaking
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
		Select @ErrMsg = 	case @Language 
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
	from custoverride as co with (NOLOCK) inner join
		(
				 	select 1 as bettype, 3 as sporttype, @v3apositiontaking_1 as apositiontaking, 0 as alivepositiontaking, @v3mpositiontaking_1 as mpositiontaking, 0 as mlivepositiontaking
			union all 	select 2 as bettype, 3 as sporttype, @v3apositiontaking_2 as apositiontaking, 0 as alivepositiontaking, @v3mpositiontaking_2 as mpositiontaking, 0 as mlivepositiontaking
			union all 	select 3 as bettype, 3 as sporttype, @v3apositiontaking_3 as apositiontaking, 0 as alivepositiontaking, @v3mpositiontaking_3 as mpositiontaking, 0 as mlivepositiontaking
			union all 	select 20 as bettype, 3 as sporttype, @v3apositiontaking_20 as apositiontaking, 0 as alivepositiontaking, @v3mpositiontaking_20 as mpositiontaking, 0 as mlivepositiontaking
		) as b on co.sporttype=b.sporttype and co.bettype = b.bettype
		inner join sports with (nolock) on b.sporttype = sports.sporttype
		inner join bettype with (nolock) on b.bettype = bettype.typeid
	where co.custid = @custid and (	
						(b.apositiontaking>co.maxpositiontaking or b.apositiontaking<co.minpositiontaking)
--						or (b.sporttype = 1 and b.bettype in (1,3,7,8) and (b.alivepositiontaking>co.maxlivepositiontaking or b.alivepositiontaking<co.minlivepositiontaking))
					)
	if @ErrType <>''
	BEGIN
		select @ErrCode = 10
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
	from customer as c with (NOLOCK) inner join custsetting as scs with (NOLOCK) on c.srecommend = scs.custid inner join 
		(
				 	select 1 as bettype, 3 as sporttype, @v3apositiontaking_1 as apositiontaking, 0 as alivepositiontaking, @v3mpositiontaking_1 as mpositiontaking, 0 as mlivepositiontaking
			union all 	select 2 as bettype, 3 as sporttype, @v3apositiontaking_2 as apositiontaking, 0 as alivepositiontaking, @v3mpositiontaking_2 as mpositiontaking, 0 as mlivepositiontaking
			union all 	select 3 as bettype, 3 as sporttype, @v3apositiontaking_3 as apositiontaking, 0 as alivepositiontaking, @v3mpositiontaking_3 as mpositiontaking, 0 as mlivepositiontaking
			union all 	select 20 as bettype, 3 as sporttype, @v3apositiontaking_20 as apositiontaking, 0 as alivepositiontaking, @v3mpositiontaking_20 as mpositiontaking, 0 as mlivepositiontaking
		) as b on scs.sporttype=b.sporttype and scs.bettype = b.bettype
		inner join sports with (nolock) on b.sporttype = sports.sporttype
		inner join bettype with (nolock) on b.bettype = bettype.typeid
	where c.custid = @mrecommend and (b.apositiontaking>scs.apositiontaking or (b.sporttype = 1 and b.bettype in (1,3,7,8) and b.alivepositiontaking>scs.alivepositiontaking))
	if @ErrType <>''
	BEGIN
		select @ErrCode = 12
		Select @ErrMsg = 	@UserName + ': '+
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
END

--Tennis
if @UpdateMultiple = 0 or @UpdatePositiontakingv5 = 1
BEGIN
	if 
		@v5apositiontaking_1  <0
		or @v5apositiontaking_2  <0
		or @v5apositiontaking_3  <0
		or @v5apositiontaking_20  <0
		
		or @v5apositiontaking_1+@v5mpositiontaking_1 >0.9
		or @v5apositiontaking_2+@v5mpositiontaking_2 >0.9
		or @v5apositiontaking_3+@v5mpositiontaking_3 >0.9
		or @v5apositiontaking_20+@v5mpositiontaking_20 >0.9
		
		or @v5mpositiontaking_1 <0
		or @v5mpositiontaking_2 <0
		or @v5mpositiontaking_3 <0
		or @v5mpositiontaking_20 <0
		
		or @v5mpositiontaking_1 >0.9
		or @v5mpositiontaking_2 >0.9
		or @v5mpositiontaking_3 >0.9
		or @v5mpositiontaking_20 >0.9
	BEGIN
		select @ErrCode = 8
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Wrong position taking (for Tennis).'
							when 'CS' then N'占成数不正确(于网球).'
							when 'CT' then N'佔成數不正確(於網球).'
							when 'TH' then N'การกำหนดจำนวนเงินไม่ถูกต้อง (สำหรับกีฬาเทนนิส).'
							when 'J' then N'Wrong position taking (for Tennis).'
							when 'KO' then N'거래 조건이 잘못 되었습니다 (테니스).'
							else N'Wrong position taking (for Tennis).'
					end
		return
	END
	
	--check n3<=m2+a2<=l3 if i2 = 0, 
	--a2<=l3 and u2+a2>=n3 if i2 = 1
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Min: '+ cast((co.minpositiontaking) as varchar(10))+ '-Max: '+ cast((co.maxpositiontaking) as varchar(10))+ '<br>'
	from custoverride as co with (NOLOCK) inner join
		(
				 		select 1 as bettype, 5 as sporttype, @v5apositiontaking_1 as apositiontaking, 0 as alivepositiontaking, @v5mpositiontaking_1 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v5mpositiontaking_1 as isauto_mpositiontaking,  0 as isauto_mlivepositiontaking, @auto_v5mpositiontaking_1 as auto_mpositiontaking
			union all 	select 2 as bettype, 5 as sporttype, @v5apositiontaking_2 as apositiontaking, 0 as alivepositiontaking, @v5mpositiontaking_2 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v5mpositiontaking_2 as isauto_mpositiontaking,  0 as isauto_mlivepositiontaking, @auto_v5mpositiontaking_2 as auto_mpositiontaking
			union all 	select 3 as bettype, 5 as sporttype, @v5apositiontaking_3 as apositiontaking, 0 as alivepositiontaking, @v5mpositiontaking_3 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v5mpositiontaking_3 as isauto_mpositiontaking,  0 as isauto_mlivepositiontaking, @auto_v5mpositiontaking_3 as auto_mpositiontaking
			union all 	select 20 as bettype, 5 as sporttype, @v5apositiontaking_20 as apositiontaking, 0 as alivepositiontaking, @v5mpositiontaking_20 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v5mpositiontaking_20 as isauto_mpositiontaking,  0 as isauto_mlivepositiontaking, @auto_v5mpositiontaking_20 as auto_mpositiontaking
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
		Select @ErrMsg = 	case @Language 
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
	from custoverride as co with (NOLOCK) inner join
		(
				 		select 1 as bettype, 5 as sporttype, @v5apositiontaking_1 as apositiontaking, 0 as alivepositiontaking, @v5mpositiontaking_1 as mpositiontaking, 0 as mlivepositiontaking
			union all 	select 2 as bettype, 5 as sporttype, @v5apositiontaking_2 as apositiontaking, 0 as alivepositiontaking, @v5mpositiontaking_2 as mpositiontaking, 0 as mlivepositiontaking
			union all 	select 3 as bettype, 5 as sporttype, @v5apositiontaking_3 as apositiontaking, 0 as alivepositiontaking, @v5mpositiontaking_3 as mpositiontaking, 0 as mlivepositiontaking
			union all 	select 20 as bettype, 5 as sporttype, @v5apositiontaking_20 as apositiontaking, 0 as alivepositiontaking, @v5mpositiontaking_20 as mpositiontaking, 0 as mlivepositiontaking
		) as b on co.sporttype=b.sporttype and co.bettype = b.bettype
		inner join sports with (nolock) on b.sporttype = sports.sporttype
		inner join bettype with (nolock) on b.bettype = bettype.typeid
	where co.custid = @custid and (	
						(b.apositiontaking>co.maxpositiontaking or b.apositiontaking<co.minpositiontaking)
					)
	if @ErrType <>''
	BEGIN
		select @ErrCode = 10
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
	from custinfo as c with (NOLOCK) inner join custsetting as scs with (NOLOCK) on c.srecommend = scs.custid inner join 
		(
				 	select 1 as bettype, 5 as sporttype, @v5apositiontaking_1 as apositiontaking, 0 as alivepositiontaking, @v5mpositiontaking_1 as mpositiontaking, 0 as mlivepositiontaking
			union all 	select 2 as bettype, 5 as sporttype, @v5apositiontaking_2 as apositiontaking, 0 as alivepositiontaking, @v5mpositiontaking_2 as mpositiontaking, 0 as mlivepositiontaking
			union all 	select 3 as bettype, 5 as sporttype, @v5apositiontaking_3 as apositiontaking, 0 as alivepositiontaking, @v5mpositiontaking_3 as mpositiontaking, 0 as mlivepositiontaking
			union all 	select 20 as bettype, 5 as sporttype, @v5apositiontaking_20 as apositiontaking, 0 as alivepositiontaking, @v5mpositiontaking_20 as mpositiontaking, 0 as mlivepositiontaking
		) as b on scs.sporttype=b.sporttype and scs.bettype = b.bettype
		inner join sports with (nolock) on b.sporttype = sports.sporttype
		inner join bettype with (nolock) on b.bettype = bettype.typeid
	where c.custid = @mrecommend and (b.apositiontaking>scs.apositiontaking or (b.sporttype = 1 and b.bettype in (1,3,7,8) and b.alivepositiontaking>scs.alivepositiontaking))
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
END

--BaseBall
if @UpdateMultiple = 0 or @UpdatePositiontakingv8 = 1
BEGIN
	if 
		@v8apositiontaking_1  <0
		or @v8apositiontaking_3  <0
		or @v8apositiontaking_20  <0
		
		or @v8apositiontaking_1+@v8mpositiontaking_1 >0.9
		or @v8apositiontaking_3+@v8mpositiontaking_3 >0.9
		or @v8apositiontaking_20+@v8mpositiontaking_20 >0.9
		
		or @v8mpositiontaking_1 <0
		or @v8mpositiontaking_3 <0
		or @v8mpositiontaking_20 <0
		
		or @v8mpositiontaking_1 >0.9
		or @v8mpositiontaking_3 >0.9
		or @v8mpositiontaking_20 >0.9
	BEGIN
		select @ErrCode = 8
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


	--check n3<=m2+a2<=l3 if i2 = 0, 
	--a2<=l3 and u2+a2>=n3 if i2 = 1
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Min: '+ cast((co.minpositiontaking) as varchar(10))+ '-Max: '+ cast((co.maxpositiontaking) as varchar(10))+ '<br>'
	from custoverride as co with (NOLOCK) inner join
		(
				 		select 1 as bettype, 8 as sporttype, @v8apositiontaking_1 as apositiontaking, 0 as alivepositiontaking, @v8mpositiontaking_1 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v8mpositiontaking_1 as isauto_mpositiontaking,  0 as isauto_mlivepositiontaking, @auto_v8mpositiontaking_1 as auto_mpositiontaking
			union all 	select 3 as bettype, 8 as sporttype, @v8apositiontaking_3 as apositiontaking, 0 as alivepositiontaking, @v8mpositiontaking_3 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v8mpositiontaking_3 as isauto_mpositiontaking,  0 as isauto_mlivepositiontaking, @auto_v8mpositiontaking_3 as auto_mpositiontaking
			union all 	select 20 as bettype, 8 as sporttype, @v8apositiontaking_20 as apositiontaking, 0 as alivepositiontaking, @v8mpositiontaking_20 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v8mpositiontaking_20 as isauto_mpositiontaking,  0 as isauto_mlivepositiontaking, @auto_v8mpositiontaking_20 as auto_mpositiontaking
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
		Select @ErrMsg = 	case @Language 
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
	from custoverride as co with (NOLOCK) inner join
		(
				 	select 1 as bettype, 8 as sporttype, @v8apositiontaking_1 as apositiontaking, 0 as alivepositiontaking, @v8mpositiontaking_1 as mpositiontaking, 0 as mlivepositiontaking
			union all 	select 3 as bettype, 8 as sporttype, @v8apositiontaking_3 as apositiontaking, 0 as alivepositiontaking, @v8mpositiontaking_3 as mpositiontaking, 0 as mlivepositiontaking
			union all 	select 20 as bettype, 8 as sporttype, @v8apositiontaking_20 as apositiontaking, 0 as alivepositiontaking, @v8mpositiontaking_20 as mpositiontaking, 0 as mlivepositiontaking
		) as b on co.sporttype=b.sporttype and co.bettype = b.bettype
		inner join sports with (nolock) on b.sporttype = sports.sporttype
		inner join bettype with (nolock) on b.bettype = bettype.typeid
	where co.custid = @custid and (	
						(b.apositiontaking>co.maxpositiontaking or b.apositiontaking<co.minpositiontaking)
--						or (b.sporttype = 1 and b.bettype in (1,3,7,8) and (b.alivepositiontaking>co.maxlivepositiontaking or b.alivepositiontaking<co.minlivepositiontaking))
					)
	if @ErrType <>''
	BEGIN
		select @ErrCode = 10
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


	--check a2<=a4 - Vinh
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ cast((scs.apositiontaking) as varchar(10)) + '<br>'
	from customer as c with (NOLOCK) inner join custsetting as scs with (NOLOCK) on c.srecommend = scs.custid inner join 
		(
				 	select 1 as bettype, 8 as sporttype, @v8apositiontaking_1 as apositiontaking, 0 as alivepositiontaking, @v8mpositiontaking_1 as mpositiontaking, 0 as mlivepositiontaking
			union all 	select 3 as bettype, 8 as sporttype, @v8apositiontaking_3 as apositiontaking, 0 as alivepositiontaking, @v8mpositiontaking_3 as mpositiontaking, 0 as mlivepositiontaking
			union all 	select 20 as bettype, 8 as sporttype, @v8apositiontaking_20 as apositiontaking, 0 as alivepositiontaking, @v8mpositiontaking_20 as mpositiontaking, 0 as mlivepositiontaking
		) as b on scs.sporttype=b.sporttype and scs.bettype = b.bettype
		inner join sports with (nolock) on b.sporttype = sports.sporttype
		inner join bettype with (nolock) on b.bettype = bettype.typeid
	where c.custid = @mrecommend and (b.apositiontaking>scs.apositiontaking or (b.sporttype = 1 and b.bettype in (1,3,7,8) and b.alivepositiontaking>scs.alivepositiontaking))
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
END

--Golf
if @UpdateMultiple = 0 or @UpdatePositiontakingv10 = 1
BEGIN
	if 
		@v10apositiontaking_1  <0
		or @v10apositiontaking_2  <0
		or @v10apositiontaking_3  <0
		or @v10apositiontaking_20  <0
		
		or @v10apositiontaking_1+@v10mpositiontaking_1 >0.9
		or @v10apositiontaking_2+@v10mpositiontaking_2 >0.9
		or @v10apositiontaking_3+@v10mpositiontaking_3 >0.9
		or @v10apositiontaking_20+@v10mpositiontaking_20 >0.9
		
		or @v10mpositiontaking_1 <0
		or @v10mpositiontaking_2 <0
		or @v10mpositiontaking_3 <0
		or @v10mpositiontaking_20 <0
		
		or @v10mpositiontaking_1 >0.9
		or @v10mpositiontaking_2 >0.9
		or @v10mpositiontaking_3 >0.9
		or @v10mpositiontaking_20 >0.9
	BEGIN
		select @ErrCode = 8
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Wrong position taking (for Golf).'
							when 'CS' then N'占成数不正确(于高尔夫球).'
							when 'CT' then N'佔成數不正確(於高爾夫球).'
							when 'TH' then N'การกำหนดจำนวนเงินไม่ถูกต้อง (สำหรับกีฬากอฟล์).'
							when 'J' then N'Wrong position taking (for Golf).'
							when 'KO' then N'거래 조건이 잘못 되었습니다 (골프).'
							else N'Wrong position taking (for Golf).'
					end
		return
	END

	--check n3<=m2+a2<=l3 if i2 = 0, 
	--a2<=l3 and u2+a2>=n3 if i2 = 1
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Min: '+ cast((co.minpositiontaking) as varchar(10))+ '-Max: '+ cast((co.maxpositiontaking) as varchar(10))+ '<br>'
	from custoverride as co with (NOLOCK) inner join
		(
				 		select 1 as bettype, 10 as sporttype, @v10apositiontaking_1 as apositiontaking, 0 as alivepositiontaking, @v10mpositiontaking_1 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v10mpositiontaking_1 as isauto_mpositiontaking,  0 as isauto_mlivepositiontaking, @auto_v10mpositiontaking_1 as auto_mpositiontaking
			union all 	select 2 as bettype, 10 as sporttype, @v10apositiontaking_2 as apositiontaking, 0 as alivepositiontaking, @v10mpositiontaking_2 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v10mpositiontaking_2 as isauto_mpositiontaking,  0 as isauto_mlivepositiontaking, @auto_v10mpositiontaking_2 as auto_mpositiontaking
			union all 	select 3 as bettype, 10 as sporttype, @v10apositiontaking_3 as apositiontaking, 0 as alivepositiontaking, @v10mpositiontaking_3 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v10mpositiontaking_3 as isauto_mpositiontaking,  0 as isauto_mlivepositiontaking, @auto_v10mpositiontaking_3 as auto_mpositiontaking
			union all 	select 20 as bettype, 10 as sporttype, @v10apositiontaking_20 as apositiontaking, 0 as alivepositiontaking, @v10mpositiontaking_20 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v10mpositiontaking_20 as isauto_mpositiontaking,  0 as isauto_mlivepositiontaking, @auto_v10mpositiontaking_20 as auto_mpositiontaking
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
		Select @ErrMsg = 	case @Language 
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
	from custoverride as co with (NOLOCK) inner join
		(
				 	select 1 as bettype, 10 as sporttype, @v10apositiontaking_1 as apositiontaking, 0 as alivepositiontaking, @v10mpositiontaking_1 as mpositiontaking, 0 as mlivepositiontaking
			union all 	select 2 as bettype, 10 as sporttype, @v10apositiontaking_2 as apositiontaking, 0 as alivepositiontaking, @v10mpositiontaking_2 as mpositiontaking, 0 as mlivepositiontaking
			union all 	select 3 as bettype, 10 as sporttype, @v10apositiontaking_3 as apositiontaking, 0 as alivepositiontaking, @v10mpositiontaking_3 as mpositiontaking, 0 as mlivepositiontaking
			union all 	select 20 as bettype, 10 as sporttype, @v10apositiontaking_20 as apositiontaking, 0 as alivepositiontaking, @v10mpositiontaking_20 as mpositiontaking, 0 as mlivepositiontaking
		) as b on co.sporttype=b.sporttype and co.bettype = b.bettype
		inner join sports with (nolock) on b.sporttype = sports.sporttype
		inner join bettype with (nolock) on b.bettype = bettype.typeid
	where co.custid = @custid and (	
						(b.apositiontaking>co.maxpositiontaking or b.apositiontaking<co.minpositiontaking)
					)
	if @ErrType <>''
	BEGIN
		select @ErrCode = 10
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
	from custinfo as c with (NOLOCK) inner join custsetting as scs with (NOLOCK) on c.srecommend = scs.custid inner join 
		(
				 	select 1 as bettype, 10 as sporttype, @v10apositiontaking_1 as apositiontaking, 0 as alivepositiontaking, @v10mpositiontaking_1 as mpositiontaking, 0 as mlivepositiontaking
			union all 	select 2 as bettype, 10 as sporttype, @v10apositiontaking_2 as apositiontaking, 0 as alivepositiontaking, @v10mpositiontaking_2 as mpositiontaking, 0 as mlivepositiontaking
			union all 	select 3 as bettype, 10 as sporttype, @v10apositiontaking_3 as apositiontaking, 0 as alivepositiontaking, @v10mpositiontaking_3 as mpositiontaking, 0 as mlivepositiontaking
			union all 	select 20 as bettype, 10 as sporttype, @v10apositiontaking_20 as apositiontaking, 0 as alivepositiontaking, @v10mpositiontaking_20 as mpositiontaking, 0 as mlivepositiontaking
		) as b on scs.sporttype=b.sporttype and scs.bettype = b.bettype
		inner join sports with (nolock) on b.sporttype = sports.sporttype
		inner join bettype with (nolock) on b.bettype = bettype.typeid
	where c.custid = @mrecommend and (b.apositiontaking>scs.apositiontaking or (b.sporttype = 1 and b.bettype in (1,3,7,8) and b.alivepositiontaking>scs.alivepositiontaking))
	if @ErrType <>''
	BEGIN
		select @ErrCode = 12
		Select @ErrMsg = 	@UserName + ': '+
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
END

--Motorsports
if @UpdateMultiple = 0 or @UpdatePositiontakingv11 = 1
BEGIN
	if 
		@v11apositiontaking_1  <0
		or @v11apositiontaking_20  <0
		
		or @v11apositiontaking_1+@v11mpositiontaking_1 >0.9
		or @v11apositiontaking_20+@v11mpositiontaking_20 >0.9
		
		or @v11mpositiontaking_1 <0
		or @v11mpositiontaking_20 <0
		
		or @v11mpositiontaking_1 >0.9
		or @v11mpositiontaking_20 >0.9
	BEGIN
		select @ErrCode = 8
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Wrong position taking (for Motorsports).'
							when 'CS' then N'占成数不正确(于赛车).'
							when 'CT' then N'佔成數不正確(於賽車).'
							when 'TH' then N'การกำหนดจำนวนเงินไม่ถูกต้อง (สำหรับกีฬารถแข่ง).'
							when 'J' then N'Wrong position taking (for Motorsports).'
							when 'KO' then N'거래 조건이 잘못 되었습니다 (모토스포츠).'
							else N'Wrong position taking (for Motorsports).'
					end
		return
	END

	--check n3<=m2+a2<=l3 if i2 = 0, 
	--a2<=l3 and u2+a2>=n3 if i2 = 1
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Min: '+ cast((co.minpositiontaking) as varchar(10))+ '-Max: '+ cast((co.maxpositiontaking) as varchar(10))+ '<br>'
	from custoverride as co with (NOLOCK) inner join
		(
				 		select 1 as bettype, 11 as sporttype, @v11apositiontaking_1 as apositiontaking, 0 as alivepositiontaking, @v11mpositiontaking_1 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v11mpositiontaking_1 as isauto_mpositiontaking,  0 as isauto_mlivepositiontaking, @auto_v11mpositiontaking_1 as auto_mpositiontaking
			union all 	select 20 as bettype, 11 as sporttype, @v11apositiontaking_20 as apositiontaking, 0 as alivepositiontaking, @v11mpositiontaking_20 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v11mpositiontaking_20 as isauto_mpositiontaking,  0 as isauto_mlivepositiontaking, @auto_v11mpositiontaking_20 as auto_mpositiontaking
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
		Select @ErrMsg = 	case @Language 
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
	from custoverride as co with (NOLOCK) inner join
		(
						select 1 as bettype, 11 as sporttype, @v11apositiontaking_1 as apositiontaking, 0 as alivepositiontaking, @v11mpositiontaking_1 as mpositiontaking, 0 as mlivepositiontaking
			union all 	select 20 as bettype, 11 as sporttype, @v11apositiontaking_20 as apositiontaking, 0 as alivepositiontaking, @v11mpositiontaking_20 as mpositiontaking, 0 as mlivepositiontaking
		) as b on co.sporttype=b.sporttype and co.bettype = b.bettype
		inner join sports with (nolock) on b.sporttype = sports.sporttype
		inner join bettype with (nolock) on b.bettype = bettype.typeid
	where co.custid = @custid and (	
						(b.apositiontaking>co.maxpositiontaking or b.apositiontaking<co.minpositiontaking)
					)
	if @ErrType <>''
	BEGIN
		select @ErrCode = 10
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
	from custinfo as c with (NOLOCK) inner join custsetting as scs with (NOLOCK) on c.srecommend = scs.custid inner join 
		(
				 	select 1 as bettype, 11 as sporttype, @v11apositiontaking_1 as apositiontaking, 0 as alivepositiontaking, @v11mpositiontaking_1 as mpositiontaking, 0 as mlivepositiontaking
			union all 	select 20 as bettype, 11 as sporttype, @v11apositiontaking_20 as apositiontaking, 0 as alivepositiontaking, @v11mpositiontaking_20 as mpositiontaking, 0 as mlivepositiontaking
		) as b on scs.sporttype=b.sporttype and scs.bettype = b.bettype
		inner join sports with (nolock) on b.sporttype = sports.sporttype
		inner join bettype with (nolock) on b.bettype = bettype.typeid
	where c.custid = @mrecommend and (b.apositiontaking>scs.apositiontaking or (b.sporttype = 1 and b.bettype in (1,3,7,8) and b.alivepositiontaking>scs.alivepositiontaking))
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
END

--Other Sports
if @UpdateMultiple = 0 or @UpdatePositiontakingv99 = 1
BEGIN
	if 
		@v99apositiontaking_1  <0
		or @v99apositiontaking_2  <0
		or @v99apositiontaking_3  <0
		or @v99apositiontaking_20  <0
		
		or @v99apositiontaking_1+@v99mpositiontaking_1 >0.9
		or @v99apositiontaking_2+@v99mpositiontaking_2 >0.9
		or @v99apositiontaking_3+@v99mpositiontaking_3 >0.9
		or @v99apositiontaking_20+@v99mpositiontaking_20 >0.9
		
		or @v99mpositiontaking_1 <0
		or @v99mpositiontaking_2 <0
		or @v99mpositiontaking_3 <0
		or @v99mpositiontaking_20 <0
		
		or @v99mpositiontaking_1 >0.9
		or @v99mpositiontaking_2 >0.9
		or @v99mpositiontaking_3 >0.9
		or @v99mpositiontaking_20 >0.9
	BEGIN
		select @ErrCode = 8
		Select @ErrMsg = 	case @Language 
							when 'E' then 'Wrong position taking (for Other sports).'
							when 'CS' then N'占成数不正确(于其他).'
							when 'CT' then N'佔成數不正確(於其他).'
							when 'TH' then N'การกำหนดจำนวนเงินไม่ถูกต้อง (สำหรับกีฬาอื่นๆ).'
							when 'J' then N'Wrong position taking (for Other sports).'
							when 'KO' then N'거래 조건이 잘못 되었습니다 (기타 스포츠).'
							else N'Wrong position taking (for Other sports).'
					end
		return
	END

	--check n3<=m2+a2<=l3 if i2 = 0, 
	--a2<=l3 and u2+a2>=n3 if i2 = 1
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Min: '+ cast((co.minpositiontaking) as varchar(10))+ '-Max: '+ cast((co.maxpositiontaking) as varchar(10))+ '<br>'
	from custoverride as co with (NOLOCK) inner join
		(
				 		select 1 as bettype, 99 as sporttype, @v99apositiontaking_1 as apositiontaking, 0 as alivepositiontaking, @v99mpositiontaking_1 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v99mpositiontaking_1 as isauto_mpositiontaking,  0 as isauto_mlivepositiontaking, @auto_v99mpositiontaking_1 as auto_mpositiontaking
			union all 	select 2 as bettype, 99 as sporttype, @v99apositiontaking_2 as apositiontaking, 0 as alivepositiontaking, @v99mpositiontaking_2 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v99mpositiontaking_2 as isauto_mpositiontaking,  0 as isauto_mlivepositiontaking, @auto_v99mpositiontaking_2 as auto_mpositiontaking
			union all 	select 3 as bettype, 99 as sporttype, @v99apositiontaking_3 as apositiontaking, 0 as alivepositiontaking, @v99mpositiontaking_3 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v99mpositiontaking_3 as isauto_mpositiontaking,  0 as isauto_mlivepositiontaking, @auto_v99mpositiontaking_3 as auto_mpositiontaking
			union all 	select 20 as bettype, 99 as sporttype, @v99apositiontaking_20 as apositiontaking, 0 as alivepositiontaking, @v99mpositiontaking_20 as mpositiontaking, 0 as mlivepositiontaking, @isauto_v99mpositiontaking_20 as isauto_mpositiontaking,  0 as isauto_mlivepositiontaking, @auto_v99mpositiontaking_20 as auto_mpositiontaking
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
		Select @ErrMsg = 	case @Language 
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
	from custoverride as co with (NOLOCK) inner join
		(
				 	select 1 as bettype, 99 as sporttype, @v99apositiontaking_1 as apositiontaking, 0 as alivepositiontaking, @v99mpositiontaking_1 as mpositiontaking, 0 as mlivepositiontaking
			union all 	select 2 as bettype, 99 as sporttype, @v99apositiontaking_2 as apositiontaking, 0 as alivepositiontaking, @v99mpositiontaking_2 as mpositiontaking, 0 as mlivepositiontaking
			union all 	select 3 as bettype, 99 as sporttype, @v99apositiontaking_3 as apositiontaking, 0 as alivepositiontaking, @v99mpositiontaking_3 as mpositiontaking, 0 as mlivepositiontaking
			union all 	select 20 as bettype, 99 as sporttype, @v99apositiontaking_20 as apositiontaking, 0 as alivepositiontaking, @v99mpositiontaking_20 as mpositiontaking, 0 as mlivepositiontaking
		) as b on co.sporttype=b.sporttype and co.bettype = b.bettype
		inner join sports with (nolock) on b.sporttype = sports.sporttype
		inner join bettype with (nolock) on b.bettype = bettype.typeid
	where co.custid = @custid and (	
						(b.apositiontaking>co.maxpositiontaking or b.apositiontaking<co.minpositiontaking)
					)
	if @ErrType <>''
	BEGIN
		select @ErrCode = 10
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
	from custinfo as c with (NOLOCK) inner join custsetting as scs with (NOLOCK) on c.srecommend = scs.custid inner join 
		(
				 	select 1 as bettype, 99 as sporttype, @v99apositiontaking_1 as apositiontaking, 0 as alivepositiontaking, @v99mpositiontaking_1 as mpositiontaking, 0 as mlivepositiontaking
			union all 	select 2 as bettype, 99 as sporttype, @v99apositiontaking_2 as apositiontaking, 0 as alivepositiontaking, @v99mpositiontaking_2 as mpositiontaking, 0 as mlivepositiontaking
			union all 	select 3 as bettype, 99 as sporttype, @v99apositiontaking_3 as apositiontaking, 0 as alivepositiontaking, @v99mpositiontaking_3 as mpositiontaking, 0 as mlivepositiontaking
			union all 	select 20 as bettype, 99 as sporttype, @v99apositiontaking_20 as apositiontaking, 0 as alivepositiontaking, @v99mpositiontaking_20 as mpositiontaking, 0 as mlivepositiontaking
		) as b on scs.sporttype=b.sporttype and scs.bettype = b.bettype
		inner join sports with (nolock) on b.sporttype = sports.sporttype
		inner join bettype with (nolock) on b.bettype = bettype.typeid
	where c.custid = @mrecommend and (b.apositiontaking>scs.apositiontaking or (b.sporttype = 1 and b.bettype in (1,3,7,8) and b.alivepositiontaking>scs.alivepositiontaking))
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
END
--End check param
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
declare 
	@old_apositiontaking_1 smallmoney,
	@old_apositiontaking_2 smallmoney,
	@old_apositiontaking_3 smallmoney,
	@old_apositiontaking_4 smallmoney,
	@old_apositiontaking_5 smallmoney,
	@old_apositiontaking_6 smallmoney,
	@old_apositiontaking_7 smallmoney,
	@old_apositiontaking_8 smallmoney,
	@old_apositiontaking_9 smallmoney,
	@old_apositiontaking_10 smallmoney,
	@old_mpositiontaking_1 smallmoney,
	@old_mpositiontaking_2 smallmoney,
	@old_mpositiontaking_3 smallmoney,
	@old_mpositiontaking_4 smallmoney,
	@old_mpositiontaking_5 smallmoney,
	@old_mpositiontaking_6 smallmoney,
	@old_mpositiontaking_7 smallmoney,
	@old_mpositiontaking_8 smallmoney,
	@old_mpositiontaking_9 smallmoney,
	@old_mpositiontaking_10 smallmoney,
	@old_alivepositiontaking_1 smallmoney,
	@old_alivepositiontaking_3 smallmoney,
	@old_alivepositiontaking_7 smallmoney,
	@old_alivepositiontaking_8 smallmoney,
	@old_mlivepositiontaking_1 smallmoney,
	@old_mlivepositiontaking_3 smallmoney,
	@old_mlivepositiontaking_7 smallmoney,
	@old_mlivepositiontaking_8 smallmoney,
	
	@old_v2apositiontaking_1 smallmoney,
	@old_v2apositiontaking_2 smallmoney,
	@old_v2apositiontaking_3 smallmoney,
	@old_v2apositiontaking_7 smallmoney,
	@old_v2apositiontaking_8 smallmoney,
	@old_v2apositiontaking_9 smallmoney,
	@old_v2apositiontaking_20 smallmoney,

	@old_v3apositiontaking_1 smallmoney,
	@old_v3apositiontaking_2 smallmoney,
	@old_v3apositiontaking_3 smallmoney,
	@old_v3apositiontaking_20 smallmoney,

	@old_v5apositiontaking_1 smallmoney,
	@old_v5apositiontaking_2 smallmoney,
	@old_v5apositiontaking_3 smallmoney,
	@old_v5apositiontaking_20 smallmoney,

	@old_v8apositiontaking_1 smallmoney,
	@old_v8apositiontaking_3 smallmoney,
	@old_v8apositiontaking_20 smallmoney,

	@old_v10apositiontaking_1 smallmoney,
	@old_v10apositiontaking_2 smallmoney,
	@old_v10apositiontaking_3 smallmoney,
	@old_v10apositiontaking_20 smallmoney,

	@old_v11apositiontaking_1 smallmoney,
	@old_v11apositiontaking_20 smallmoney,

	@old_v99apositiontaking_1 smallmoney,
	@old_v99apositiontaking_2 smallmoney,
	@old_v99apositiontaking_3 smallmoney,
	@old_v99apositiontaking_20 smallmoney,
	
	@old_v2mpositiontaking_1 smallmoney,
	@old_v2mpositiontaking_2 smallmoney,
	@old_v2mpositiontaking_3 smallmoney,
	@old_v2mpositiontaking_7 smallmoney,
	@old_v2mpositiontaking_8 smallmoney,
	@old_v2mpositiontaking_9 smallmoney,
	@old_v2mpositiontaking_20 smallmoney,

	@old_v3mpositiontaking_1 smallmoney,
	@old_v3mpositiontaking_2 smallmoney,
	@old_v3mpositiontaking_3 smallmoney,
	@old_v3mpositiontaking_20 smallmoney,

	@old_v5mpositiontaking_1 smallmoney,
	@old_v5mpositiontaking_2 smallmoney,
	@old_v5mpositiontaking_3 smallmoney,
	@old_v5mpositiontaking_20 smallmoney,

	@old_v8mpositiontaking_1 smallmoney,
	@old_v8mpositiontaking_3 smallmoney,
	@old_v8mpositiontaking_20 smallmoney,

	@old_v10mpositiontaking_1 smallmoney,
	@old_v10mpositiontaking_2 smallmoney,
	@old_v10mpositiontaking_3 smallmoney,
	@old_v10mpositiontaking_20 smallmoney,

	@old_v11mpositiontaking_1 smallmoney,
	@old_v11mpositiontaking_20 smallmoney,

	@old_v99mpositiontaking_1 smallmoney,
	@old_v99mpositiontaking_2 smallmoney,
	@old_v99mpositiontaking_3 smallmoney,
	@old_v99mpositiontaking_20 smallmoney
	
select @old_mpositiontaking_1 = mpositiontaking, @old_mlivepositiontaking_1 = mlivepositiontaking, @old_apositiontaking_1 = apositiontaking, @old_alivepositiontaking_1 = alivepositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=1 and sporttype=1
select @old_mpositiontaking_3 = mpositiontaking, @old_mlivepositiontaking_3 = mlivepositiontaking, @old_apositiontaking_3 = apositiontaking, @old_alivepositiontaking_3 = alivepositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=3 and sporttype=1
select @old_mpositiontaking_7 = mpositiontaking, @old_mlivepositiontaking_7 = mlivepositiontaking, @old_apositiontaking_7 = apositiontaking, @old_alivepositiontaking_7 = alivepositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=7 and sporttype=1
select @old_mpositiontaking_8 = mpositiontaking, @old_mlivepositiontaking_8 = mlivepositiontaking, @old_apositiontaking_8 = apositiontaking, @old_alivepositiontaking_8 = alivepositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=8 and sporttype=1
select @old_mpositiontaking_2 = mpositiontaking, @old_apositiontaking_2 = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=2 and sporttype=1
select @old_mpositiontaking_4 = mpositiontaking, @old_apositiontaking_4 = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=4 and sporttype=1
select @old_mpositiontaking_5 = mpositiontaking, @old_apositiontaking_5 = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=5 and sporttype=1
select @old_mpositiontaking_6 = mpositiontaking, @old_apositiontaking_6 = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=6 and sporttype=1
select @old_mpositiontaking_9 = mpositiontaking, @old_apositiontaking_9 = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=9 and sporttype=1
select @old_mpositiontaking_10 = mpositiontaking, @old_apositiontaking_10 = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=9 and sporttype=1

select @old_v2mpositiontaking_1 = mpositiontaking, @old_v2apositiontaking_1 = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=1 and sporttype=2
select @old_v2mpositiontaking_2 = mpositiontaking, @old_v2apositiontaking_2 = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=2 and sporttype=2
select @old_v2mpositiontaking_3 = mpositiontaking, @old_v2apositiontaking_3 = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=3 and sporttype=2
select @old_v2mpositiontaking_7 = mpositiontaking, @old_v2apositiontaking_7 = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=7 and sporttype=2
select @old_v2mpositiontaking_8 = mpositiontaking, @old_v2apositiontaking_8 = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=8 and sporttype=2
select @old_v2mpositiontaking_9 = mpositiontaking, @old_v2apositiontaking_9 = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=9 and sporttype=2
select @old_v2mpositiontaking_20 = mpositiontaking, @old_v2apositiontaking_20 = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=20 and sporttype=2

select @old_v3mpositiontaking_1 = mpositiontaking, @old_v3apositiontaking_1 = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=1 and sporttype=3
select @old_v3mpositiontaking_2 = mpositiontaking, @old_v3apositiontaking_2 = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=2 and sporttype=3
select @old_v3mpositiontaking_3 = mpositiontaking, @old_v3apositiontaking_3 = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=3 and sporttype=3
select @old_v3mpositiontaking_20 = mpositiontaking, @old_v3apositiontaking_20 = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=20 and sporttype=3

select @old_v5mpositiontaking_1 = mpositiontaking, @old_v5apositiontaking_1 = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=1 and sporttype=5
select @old_v5mpositiontaking_2 = mpositiontaking, @old_v5apositiontaking_2 = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=2 and sporttype=5
select @old_v5mpositiontaking_3 = mpositiontaking, @old_v5apositiontaking_3 = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=3 and sporttype=5
select @old_v5mpositiontaking_20 = mpositiontaking, @old_v5apositiontaking_20 = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=20 and sporttype=5

select @old_v8mpositiontaking_1 = mpositiontaking, @old_v8apositiontaking_1 = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=1 and sporttype=8
select @old_v8mpositiontaking_3 = mpositiontaking, @old_v8apositiontaking_3 = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=3 and sporttype=8
select @old_v8mpositiontaking_20 = mpositiontaking, @old_v8apositiontaking_20 = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=20 and sporttype=8

select @old_v10mpositiontaking_1 = mpositiontaking, @old_v10apositiontaking_1 = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=1 and sporttype=10
select @old_v10mpositiontaking_2 = mpositiontaking, @old_v10apositiontaking_2 = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=2 and sporttype=10
select @old_v10mpositiontaking_3 = mpositiontaking, @old_v10apositiontaking_3 = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=3 and sporttype=10
select @old_v10mpositiontaking_20 = mpositiontaking, @old_v10apositiontaking_20 = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=20 and sporttype=10

select @old_v11mpositiontaking_1 = mpositiontaking, @old_v11apositiontaking_1 = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=1 and sporttype=11
select @old_v11mpositiontaking_20 = mpositiontaking, @old_v11apositiontaking_20 = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=20 and sporttype=11

select @old_v99mpositiontaking_1 = mpositiontaking, @old_v99apositiontaking_1 = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=1 and sporttype=99
select @old_v99mpositiontaking_2 = mpositiontaking, @old_v99apositiontaking_2 = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=2 and sporttype=99
select @old_v99mpositiontaking_3 = mpositiontaking, @old_v99apositiontaking_3 = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=3 and sporttype=99
select @old_v99mpositiontaking_20 = mpositiontaking, @old_v99apositiontaking_20 = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=20 and sporttype=99
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

declare
	@max_mapositiontaking_1 smallmoney,
	@max_mapositiontaking_2 smallmoney,
	@max_mapositiontaking_3 smallmoney,
	@max_mapositiontaking_4 smallmoney,
	@max_mapositiontaking_5 smallmoney,
	@max_mapositiontaking_6 smallmoney,
	@max_mapositiontaking_7 smallmoney,
	@max_mapositiontaking_8 smallmoney,
	@max_mapositiontaking_9 smallmoney,
	@max_mapositiontaking_10 smallmoney,
	@max_malivepositiontaking_1 smallmoney,
	
	@max_malivepositiontaking_3 smallmoney,
	@max_malivepositiontaking_7 smallmoney,
	@max_malivepositiontaking_8 smallmoney,
	
	@max_v2mapositiontaking_1 smallmoney,
	@max_v2mapositiontaking_2 smallmoney,
	@max_v2mapositiontaking_3 smallmoney,
	@max_v2mapositiontaking_7 smallmoney,
	@max_v2mapositiontaking_8 smallmoney,
	@max_v2mapositiontaking_9 smallmoney,
	@max_v2mapositiontaking_20 smallmoney,

	@max_v3mapositiontaking_1 smallmoney,
	@max_v3mapositiontaking_2 smallmoney,
	@max_v3mapositiontaking_3 smallmoney,
	@max_v3mapositiontaking_20 smallmoney,

	@max_v5mapositiontaking_1 smallmoney,
	@max_v5mapositiontaking_2 smallmoney,
	@max_v5mapositiontaking_3 smallmoney,
	@max_v5mapositiontaking_20 smallmoney,

	@max_v8mapositiontaking_1 smallmoney,
	@max_v8mapositiontaking_3 smallmoney,
	@max_v8mapositiontaking_20 smallmoney,

	@max_v10mapositiontaking_1 smallmoney,
	@max_v10mapositiontaking_2 smallmoney,
	@max_v10mapositiontaking_3 smallmoney,
	@max_v10mapositiontaking_20 smallmoney,

	@max_v11mapositiontaking_1 smallmoney,
	@max_v11mapositiontaking_20 smallmoney,

	@max_v99mapositiontaking_1 smallmoney,
	@max_v99mapositiontaking_2 smallmoney,
	@max_v99mapositiontaking_3 smallmoney,
	@max_v99mapositiontaking_20 smallmoney

select @max_mapositiontaking_1 =mpositiontaking, @max_malivepositiontaking_1 =mlivepositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=1 and sporttype=1
select @max_mapositiontaking_3 =mpositiontaking, @max_malivepositiontaking_3 =mlivepositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=3 and sporttype=1
select @max_mapositiontaking_7 =mpositiontaking, @max_malivepositiontaking_7 =mlivepositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=7 and sporttype=1
select @max_mapositiontaking_8 =mpositiontaking, @max_malivepositiontaking_8 =mlivepositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=8 and sporttype=1
select @max_mapositiontaking_2 =mpositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=2 and sporttype=1
select @max_mapositiontaking_4 =mpositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=4 and sporttype=1
select @max_mapositiontaking_5 =mpositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=5 and sporttype=1
select @max_mapositiontaking_6 =mpositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=6 and sporttype=1
select @max_mapositiontaking_9 =mpositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=9 and sporttype=1
select @max_mapositiontaking_10 =mpositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=10 and sporttype=1

select @max_v2mapositiontaking_1 =mpositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=1 and sporttype=2
select @max_v2mapositiontaking_2 =mpositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=2 and sporttype=2
select @max_v2mapositiontaking_3 =mpositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=3 and sporttype=2
select @max_v2mapositiontaking_7 =mpositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=7 and sporttype=2
select @max_v2mapositiontaking_8 =mpositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=8 and sporttype=2
select @max_v2mapositiontaking_9 =mpositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=9 and sporttype=2
select @max_v2mapositiontaking_20 =mpositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=20 and sporttype=2

select @max_v3mapositiontaking_1 =mpositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=1 and sporttype=3
select @max_v3mapositiontaking_2 =mpositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=2 and sporttype=3
select @max_v3mapositiontaking_3 =mpositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=3 and sporttype=3
select @max_v3mapositiontaking_20 =mpositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=20 and sporttype=3

select @max_v5mapositiontaking_1 =mpositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=1 and sporttype=5
select @max_v5mapositiontaking_2 =mpositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=2 and sporttype=5
select @max_v5mapositiontaking_3 =mpositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=3 and sporttype=5
select @max_v5mapositiontaking_20 =mpositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=20 and sporttype=5

select @max_v8mapositiontaking_1 =mpositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=1 and sporttype=8
select @max_v8mapositiontaking_3 =mpositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=3 and sporttype=8
select @max_v8mapositiontaking_20 =mpositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=20 and sporttype=8

select @max_v10mapositiontaking_1 =mpositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=1 and sporttype=10
select @max_v10mapositiontaking_2 =mpositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=2 and sporttype=10
select @max_v10mapositiontaking_3 =mpositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=3 and sporttype=10
select @max_v10mapositiontaking_20 =mpositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=20 and sporttype=10

select @max_v11mapositiontaking_1 =mpositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=1 and sporttype=11
select @max_v11mapositiontaking_20 =mpositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=20 and sporttype=11

select @max_v99mapositiontaking_1 =mpositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=1 and sporttype=99
select @max_v99mapositiontaking_2 =mpositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=2 and sporttype=99
select @max_v99mapositiontaking_3 =mpositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=3 and sporttype=99
select @max_v99mapositiontaking_20 =mpositiontaking from custsetting with (NOLOCK) where custid = @mrecommend and bettype=20 and sporttype=99


--check m2+a2<=m3 - Vinh
if @UpdateMultiple = 0 
	or @UpdatePositiontaking = 1
	or @UpdatePositiontakingv2 = 1
	or @UpdatePositiontakingv3 = 1
	or @UpdatePositiontakingv5 = 1
	or @UpdatePositiontakingv8 = 1
	or @UpdatePositiontakingv10 = 1
	or @UpdatePositiontakingv11 = 1
	or @UpdatePositiontakingv99 = 1
BEGIN
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ cast((b.max_mapositiontaking) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '-MaxLive: '+ cast((b.max_malivepositiontaking) as varchar(10)) else '' end + '<br>'
	from
	(
				  select 1 as bettype, 1 as sporttype, @apositiontaking_1 as apositiontaking, @mpositiontaking_1 as mpositiontaking, @max_mapositiontaking_1 as max_mapositiontaking, @alivepositiontaking_1 as alivepositiontaking, @mlivepositiontaking_1 as mlivepositiontaking, @max_malivepositiontaking_1 as max_malivepositiontaking
		union all select 3 as bettype, 1 as sporttype, @apositiontaking_3 as apositiontaking, @mpositiontaking_3 as mpositiontaking, @max_mapositiontaking_3 as max_mapositiontaking, @alivepositiontaking_3 as alivepositiontaking, @mlivepositiontaking_3 as mlivepositiontaking, @max_malivepositiontaking_3 as max_malivepositiontaking
		union all select 7 as bettype, 1 as sporttype, @apositiontaking_7 as apositiontaking, @mpositiontaking_7 as mpositiontaking, @max_mapositiontaking_7 as max_mapositiontaking, @alivepositiontaking_7 as alivepositiontaking, @mlivepositiontaking_7 as mlivepositiontaking, @max_malivepositiontaking_7 as max_malivepositiontaking
		union all select 8 as bettype, 1 as sporttype, @apositiontaking_8 as apositiontaking, @mpositiontaking_8 as mpositiontaking, @max_mapositiontaking_8 as max_mapositiontaking, @alivepositiontaking_8 as alivepositiontaking, @mlivepositiontaking_8 as mlivepositiontaking, @max_malivepositiontaking_8 as max_malivepositiontaking
		union all select 2 as bettype, 1 as sporttype, @apositiontaking_2 as apositiontaking, @mpositiontaking_2 as mpositiontaking, @max_mapositiontaking_2 as max_mapositiontaking, 0 as alivepositiontaking, 0 as mlivepositiontaking, 0 as max_malivepositiontaking		
		union all select 4 as bettype, 1 as sporttype, @apositiontaking_4 as apositiontaking, @mpositiontaking_4 as mpositiontaking, @max_mapositiontaking_4 as max_mapositiontaking, 0 as alivepositiontaking, 0 as mlivepositiontaking, 0 as max_malivepositiontaking
		union all select 5 as bettype, 1 as sporttype, @apositiontaking_5 as apositiontaking, @mpositiontaking_5 as mpositiontaking, @max_mapositiontaking_5 as max_mapositiontaking, 0 as alivepositiontaking, 0 as mlivepositiontaking, 0 as max_malivepositiontaking
		union all select 6 as bettype, 1 as sporttype, @apositiontaking_6 as apositiontaking, @mpositiontaking_6 as mpositiontaking, @max_mapositiontaking_6 as max_mapositiontaking, 0 as alivepositiontaking, 0 as mlivepositiontaking, 0 as max_malivepositiontaking
		union all select 9 as bettype, 1 as sporttype, @apositiontaking_9 as apositiontaking, @mpositiontaking_9 as mpositiontaking, @max_mapositiontaking_9 as max_mapositiontaking, 0 as alivepositiontaking, 0 as mlivepositiontaking, 0 as max_malivepositiontaking
		union all select 10 as bettype, 1 as sporttype, @apositiontaking_10 as apositiontaking, @mpositiontaking_10 as mpositiontaking, @max_mapositiontaking_10 as max_mapositiontaking, 0 as alivepositiontaking, 0 as mlivepositiontaking, 0 as max_malivepositiontaking
		
		--v2
		union all select 1 as bettype, 2 as sporttype, @v2apositiontaking_1 as apositiontaking, @v2mpositiontaking_1 as mpositiontaking, @max_v2mapositiontaking_1 as max_mapositiontaking, 0 as alivepositiontaking, 0 as mlivepositiontaking, 0 as max_malivepositiontaking
		union all select 2 as bettype, 2 as sporttype, @v2apositiontaking_2 as apositiontaking, @v2mpositiontaking_2 as mpositiontaking, @max_v2mapositiontaking_2 as max_mapositiontaking, 0 as alivepositiontaking, 0 as mlivepositiontaking, 0 as max_malivepositiontaking
		union all select 3 as bettype, 2 as sporttype, @v2apositiontaking_3 as apositiontaking, @v2mpositiontaking_3 as mpositiontaking, @max_v2mapositiontaking_3 as max_mapositiontaking, 0 as alivepositiontaking, 0 as mlivepositiontaking, 0 as max_malivepositiontaking
--		union all select 7 as bettype, 2 as sporttype, @v2apositiontaking_7 as apositiontaking, @v2mpositiontaking_7 as mpositiontaking, @max_v2mapositiontaking_7 as max_mapositiontaking, 0 as alivepositiontaking, 0 as mlivepositiontaking, 0 as max_malivepositiontaking
--		union all select 8 as bettype, 2 as sporttype, @v2apositiontaking_8 as apositiontaking, @v2mpositiontaking_8 as mpositiontaking, @max_v2mapositiontaking_8 as max_mapositiontaking, 0 as alivepositiontaking, 0 as mlivepositiontaking, 0 as max_malivepositiontaking
		union all select 9 as bettype, 2 as sporttype, @v2apositiontaking_9 as apositiontaking, @v2mpositiontaking_9 as mpositiontaking, @max_v2mapositiontaking_9 as max_mapositiontaking, 0 as alivepositiontaking, 0 as mlivepositiontaking, 0 as max_malivepositiontaking
		union all select 20 as bettype, 2 as sporttype, @v2apositiontaking_20 as apositiontaking, @v2mpositiontaking_20 as mpositiontaking, @max_v2mapositiontaking_20 as max_mapositiontaking, 0 as alivepositiontaking, 0 as mlivepositiontaking, 0 as max_malivepositiontaking
	
		--v3
		union all select 1 as bettype, 3 as sporttype, @v3apositiontaking_1 as apositiontaking, @v3mpositiontaking_1 as mpositiontaking, @max_v3mapositiontaking_1 as max_mapositiontaking, 0 as alivepositiontaking, 0 as mlivepositiontaking, 0 as max_malivepositiontaking
		union all select 2 as bettype, 3 as sporttype, @v3apositiontaking_2 as apositiontaking, @v3mpositiontaking_2 as mpositiontaking, @max_v3mapositiontaking_2 as max_mapositiontaking, 0 as alivepositiontaking, 0 as mlivepositiontaking, 0 as max_malivepositiontaking
		union all select 3 as bettype, 3 as sporttype, @v3apositiontaking_3 as apositiontaking, @v3mpositiontaking_3 as mpositiontaking, @max_v3mapositiontaking_3 as max_mapositiontaking, 0 as alivepositiontaking, 0 as mlivepositiontaking, 0 as max_malivepositiontaking
		union all select 20 as bettype, 3 as sporttype, @v3apositiontaking_20 as apositiontaking, @v3mpositiontaking_20 as mpositiontaking, @max_v3mapositiontaking_20 as max_mapositiontaking, 0 as alivepositiontaking, 0 as mlivepositiontaking, 0 as max_malivepositiontaking

		--v5
		union all select 1 as bettype, 5 as sporttype, @v5apositiontaking_1 as apositiontaking, @v5mpositiontaking_1 as mpositiontaking, @max_v5mapositiontaking_1 as max_mapositiontaking, 0 as alivepositiontaking, 0 as mlivepositiontaking, 0 as max_malivepositiontaking
		union all select 2 as bettype, 5 as sporttype, @v5apositiontaking_2 as apositiontaking, @v5mpositiontaking_2 as mpositiontaking, @max_v5mapositiontaking_2 as max_mapositiontaking, 0 as alivepositiontaking, 0 as mlivepositiontaking, 0 as max_malivepositiontaking
		union all select 3 as bettype, 5 as sporttype, @v5apositiontaking_3 as apositiontaking, @v5mpositiontaking_3 as mpositiontaking, @max_v5mapositiontaking_3 as max_mapositiontaking, 0 as alivepositiontaking, 0 as mlivepositiontaking, 0 as max_malivepositiontaking
		union all select 20 as bettype, 5 as sporttype, @v5apositiontaking_20 as apositiontaking, @v5mpositiontaking_20 as mpositiontaking, @max_v5mapositiontaking_20 as max_mapositiontaking, 0 as alivepositiontaking, 0 as mlivepositiontaking, 0 as max_malivepositiontaking

		--v8
		union all select 1 as bettype, 8 as sporttype, @v8apositiontaking_1 as apositiontaking, @v8mpositiontaking_1 as mpositiontaking, @max_v8mapositiontaking_1 as max_mapositiontaking, 0 as alivepositiontaking, 0 as mlivepositiontaking, 0 as max_malivepositiontaking
		union all select 3 as bettype, 8 as sporttype, @v8apositiontaking_3 as apositiontaking, @v8mpositiontaking_3 as mpositiontaking, @max_v8mapositiontaking_3 as max_mapositiontaking, 0 as alivepositiontaking, 0 as mlivepositiontaking, 0 as max_malivepositiontaking
		union all select 20 as bettype, 8 as sporttype, @v8apositiontaking_20 as apositiontaking, @v8mpositiontaking_20 as mpositiontaking, @max_v8mapositiontaking_20 as max_mapositiontaking, 0 as alivepositiontaking, 0 as mlivepositiontaking, 0 as max_malivepositiontaking

		--v10
		union all select 1 as bettype, 10 as sporttype, @v10apositiontaking_1 as apositiontaking, @v10mpositiontaking_1 as mpositiontaking, @max_v10mapositiontaking_1 as max_mapositiontaking, 0 as alivepositiontaking, 0 as mlivepositiontaking, 0 as max_malivepositiontaking
		union all select 2 as bettype, 10 as sporttype, @v10apositiontaking_2 as apositiontaking, @v10mpositiontaking_2 as mpositiontaking, @max_v10mapositiontaking_2 as max_mapositiontaking, 0 as alivepositiontaking, 0 as mlivepositiontaking, 0 as max_malivepositiontaking
		union all select 3 as bettype, 10 as sporttype, @v10apositiontaking_3 as apositiontaking, @v10mpositiontaking_3 as mpositiontaking, @max_v10mapositiontaking_3 as max_mapositiontaking, 0 as alivepositiontaking, 0 as mlivepositiontaking, 0 as max_malivepositiontaking
		union all select 20 as bettype, 10 as sporttype, @v10apositiontaking_20 as apositiontaking, @v10mpositiontaking_20 as mpositiontaking, @max_v10mapositiontaking_20 as max_mapositiontaking, 0 as alivepositiontaking, 0 as mlivepositiontaking, 0 as max_malivepositiontaking

		--v11
		union all select 1 as bettype, 11 as sporttype, @v11apositiontaking_1 as apositiontaking, @v11mpositiontaking_1 as mpositiontaking, @max_v11mapositiontaking_1 as max_mapositiontaking, 0 as alivepositiontaking, 0 as mlivepositiontaking, 0 as max_malivepositiontaking
		union all select 20 as bettype, 11 as sporttype, @v11apositiontaking_20 as apositiontaking, @v11mpositiontaking_20 as mpositiontaking, @max_v11mapositiontaking_20 as max_mapositiontaking, 0 as alivepositiontaking, 0 as mlivepositiontaking, 0 as max_malivepositiontaking

		--v99
		union all select 1 as bettype, 99 as sporttype, @v99apositiontaking_1 as apositiontaking, @v99mpositiontaking_1 as mpositiontaking, @max_v99mapositiontaking_1 as max_mapositiontaking, 0 as alivepositiontaking, 0 as mlivepositiontaking, 0 as max_malivepositiontaking
		union all select 2 as bettype, 99 as sporttype, @v99apositiontaking_2 as apositiontaking, @v99mpositiontaking_2 as mpositiontaking, @max_v99mapositiontaking_2 as max_mapositiontaking, 0 as alivepositiontaking, 0 as mlivepositiontaking, 0 as max_malivepositiontaking
		union all select 3 as bettype, 99 as sporttype, @v99apositiontaking_3 as apositiontaking, @v99mpositiontaking_3 as mpositiontaking, @max_v99mapositiontaking_3 as max_mapositiontaking, 0 as alivepositiontaking, 0 as mlivepositiontaking, 0 as max_malivepositiontaking
		union all select 20 as bettype, 99 as sporttype, @v99apositiontaking_20 as apositiontaking, @v99mpositiontaking_20 as mpositiontaking, @max_v99mapositiontaking_20 as max_mapositiontaking, 0 as alivepositiontaking, 0 as mlivepositiontaking, 0 as max_malivepositiontaking

	) as b
	inner join sports with (nolock) on b.sporttype = sports.sporttype
	inner join bettype with (nolock) on b.bettype = bettype.typeid
	where (b.apositiontaking+b.mpositiontaking>b.max_mapositiontaking) or 
		  (b.sporttype = 1 and b.bettype in (1,3,7,8) and (b.alivepositiontaking+b.mlivepositiontaking>b.max_malivepositiontaking))

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
END

--check u2<=min(m3,l3) - Phuc@20081209
if @UpdateMultiple = 0 
	or @UpdatePositiontaking = 1
	or @UpdatePositiontakingv2 = 1
	or @UpdatePositiontakingv3 = 1
	or @UpdatePositiontakingv5 = 1
	or @UpdatePositiontakingv8 = 1
	or @UpdatePositiontakingv10 = 1
	or @UpdatePositiontakingv11 = 1
	or @UpdatePositiontakingv99 = 1
BEGIN
	select @ErrType = ''
	select @ErrType = @ErrType + sportname + '-'+ typenamee + '-Max: '+ cast((case when max_mapositiontaking > co.maxpositiontaking then co.maxpositiontaking else max_mapositiontaking end) as varchar(10))
	+ case when b.sporttype=1 and b.bettype in (1,3,7,8) then '-MaxLive: '+ cast((case when max_malivepositiontaking > co.maxlivepositiontaking then co.maxlivepositiontaking else max_malivepositiontaking end) as varchar(10)) else '' end + '<br>'
	from custoverride co (nolock) inner join 
	(
					select 1 as bettype, 1 as sporttype, @auto_mpositiontaking_1 as autopositiontaking, @auto_mlivepositiontaking_1	as autolivepositiontaking, @isauto_mpositiontaking_1 as isautopositiontaking, @isauto_mlivepositiontaking_1	as isautolivepositiontaking, @max_mapositiontaking_1 as max_mapositiontaking,@max_malivepositiontaking_1 as max_malivepositiontaking
		union all 	select 2 as bettype, 1 as sporttype, @auto_mpositiontaking_2 as autopositiontaking, 0				as autolivepositiontaking, @isauto_mpositiontaking_2 as isautopositiontaking, 0				as isautolivepositiontaking, @max_mapositiontaking_2 as max_mapositiontaking,0 as max_malivepositiontaking	
		union all 	select 3 as bettype, 1 as sporttype, @auto_mpositiontaking_3 as autopositiontaking, @auto_mlivepositiontaking_3 	as autolivepositiontaking, @isauto_mpositiontaking_3 as isautopositiontaking, @isauto_mlivepositiontaking_3	as isautolivepositiontaking, @max_mapositiontaking_3 as max_mapositiontaking, @max_malivepositiontaking_3 as max_malivepositiontaking
		union all 	select 4 as bettype, 1 as sporttype, @auto_mpositiontaking_4 as autopositiontaking, 0				as autolivepositiontaking, @isauto_mpositiontaking_4 as isautopositiontaking, 0				as isautolivepositiontaking, @max_mapositiontaking_4 as max_mapositiontaking,0 as max_malivepositiontaking	
		union all 	select 5 as bettype, 1 as sporttype, @auto_mpositiontaking_5 as autopositiontaking, 0				as autolivepositiontaking, @isauto_mpositiontaking_5 as isautopositiontaking, 0				as isautolivepositiontaking, @max_mapositiontaking_5 as max_mapositiontaking,0 as max_malivepositiontaking	
		union all 	select 6 as bettype, 1 as sporttype, @auto_mpositiontaking_6 as autopositiontaking, 0				as autolivepositiontaking, @isauto_mpositiontaking_6 as isautopositiontaking, 0				as isautolivepositiontaking, @max_mapositiontaking_6 as max_mapositiontaking,0 as max_malivepositiontaking	
		union all 	select 7 as bettype, 1 as sporttype, @auto_mpositiontaking_7 as autopositiontaking, @auto_mlivepositiontaking_7 	as autolivepositiontaking, @isauto_mpositiontaking_7 as isautopositiontaking, @isauto_mlivepositiontaking_7	as isautolivepositiontaking, @max_mapositiontaking_7 as max_mapositiontaking, @max_malivepositiontaking_7 as max_malivepositiontaking
		union all 	select 8 as bettype, 1 as sporttype, @auto_mpositiontaking_8 as autopositiontaking, @auto_mlivepositiontaking_8 	as autolivepositiontaking, @isauto_mpositiontaking_8 as isautopositiontaking, @isauto_mlivepositiontaking_8	as isautolivepositiontaking, @max_mapositiontaking_8 as max_mapositiontaking, @max_malivepositiontaking_8 as max_malivepositiontaking
		union all 	select 9 as bettype, 1 as sporttype, @auto_mpositiontaking_9 as autopositiontaking, 0				as autolivepositiontaking, @isauto_mpositiontaking_9 as isautopositiontaking, 0				as isautolivepositiontaking, @max_mapositiontaking_9 as max_mapositiontaking,0 as max_malivepositiontaking	
		union all 	select 10 as bettype, 1 as sporttype, @auto_mpositiontaking_10 as autopositiontaking, 0				as autolivepositiontaking, @isauto_mpositiontaking_10 as isautopositiontaking, 0				as isautolivepositiontaking, @max_mapositiontaking_10 as max_mapositiontaking,0 as max_malivepositiontaking	
		
		--v2
		union all	select 1 as bettype, 2 as sporttype, @auto_v2mpositiontaking_1 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v2mpositiontaking_1 as isautopositiontaking, 0	as isautolivepositiontaking, @max_v2mapositiontaking_1 as max_mapositiontaking,0 as max_malivepositiontaking	
		union all 	select 2 as bettype, 2 as sporttype, @auto_v2mpositiontaking_2 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v2mpositiontaking_2 as isautopositiontaking, 0	as isautolivepositiontaking, @max_v2mapositiontaking_2 as max_mapositiontaking,0 as max_malivepositiontaking	
		union all 	select 3 as bettype, 2 as sporttype, @auto_v2mpositiontaking_3 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v2mpositiontaking_3 as isautopositiontaking, 0	as isautolivepositiontaking, @max_v2mapositiontaking_3 as max_mapositiontaking,0 as max_malivepositiontaking	
		union all 	select 9 as bettype, 2 as sporttype, @auto_v2mpositiontaking_9 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v2mpositiontaking_9 as isautopositiontaking, 0	as isautolivepositiontaking, @max_v2mapositiontaking_9 as max_mapositiontaking,0 as max_malivepositiontaking	
		union all 	select 20 as bettype, 2 as sporttype, @auto_v2mpositiontaking_20 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v2mpositiontaking_20 as isautopositiontaking, 0	as isautolivepositiontaking, @max_v2mapositiontaking_20 as max_mapositiontaking,0 as max_malivepositiontaking	
	
		--v3
		union all	select 1 as bettype, 3 as sporttype, @auto_v3mpositiontaking_1 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v3mpositiontaking_1 as isautopositiontaking, 0	as isautolivepositiontaking, @max_v3mapositiontaking_1 as max_mapositiontaking,0 as max_malivepositiontaking	
		union all 	select 2 as bettype, 3 as sporttype, @auto_v3mpositiontaking_2 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v3mpositiontaking_2 as isautopositiontaking, 0	as isautolivepositiontaking, @max_v3mapositiontaking_2 as max_mapositiontaking,0 as max_malivepositiontaking	
		union all 	select 3 as bettype, 3 as sporttype, @auto_v3mpositiontaking_3 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v3mpositiontaking_3 as isautopositiontaking, 0	as isautolivepositiontaking, @max_v3mapositiontaking_3 as max_mapositiontaking,0 as max_malivepositiontaking	
		union all 	select 20 as bettype, 3 as sporttype, @auto_v3mpositiontaking_20 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v3mpositiontaking_20 as isautopositiontaking, 0	as isautolivepositiontaking, @max_v3mapositiontaking_20 as max_mapositiontaking,0 as max_malivepositiontaking	

		--v5
		union all	select 1 as bettype, 5 as sporttype, @auto_v5mpositiontaking_1 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v5mpositiontaking_1 as isautopositiontaking, 0	as isautolivepositiontaking, @max_v5mapositiontaking_1 as max_mapositiontaking,0 as max_malivepositiontaking	
		union all 	select 2 as bettype, 5 as sporttype, @auto_v5mpositiontaking_2 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v5mpositiontaking_2 as isautopositiontaking, 0	as isautolivepositiontaking, @max_v5mapositiontaking_2 as max_mapositiontaking,0 as max_malivepositiontaking	
		union all 	select 3 as bettype, 5 as sporttype, @auto_v5mpositiontaking_3 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v5mpositiontaking_3 as isautopositiontaking, 0	as isautolivepositiontaking, @max_v5mapositiontaking_3 as max_mapositiontaking,0 as max_malivepositiontaking	
		union all 	select 20 as bettype, 5 as sporttype, @auto_v5mpositiontaking_20 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v5mpositiontaking_20 as isautopositiontaking, 0	as isautolivepositiontaking, @max_v5mapositiontaking_20 as max_mapositiontaking,0 as max_malivepositiontaking	

		--v8
		union all   select 1 as bettype, 8 as sporttype, @auto_v8mpositiontaking_1 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v8mpositiontaking_1 as isautopositiontaking, 0	as isautolivepositiontaking, @max_v8mapositiontaking_1 as max_mapositiontaking,0 as max_malivepositiontaking	
		union all 	select 3 as bettype, 8 as sporttype, @auto_v8mpositiontaking_3 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v8mpositiontaking_3 as isautopositiontaking, 0	as isautolivepositiontaking, @max_v8mapositiontaking_3 as max_mapositiontaking,0 as max_malivepositiontaking	
		union all 	select 20 as bettype, 8 as sporttype, @auto_v8mpositiontaking_20 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v8mpositiontaking_20 as isautopositiontaking, 0	as isautolivepositiontaking, @max_v8mapositiontaking_20 as max_mapositiontaking,0 as max_malivepositiontaking	

		--v10
		union all	select 1 as bettype, 10 as sporttype, @auto_v10mpositiontaking_1 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v10mpositiontaking_1 as isautopositiontaking, 0	as isautolivepositiontaking, @max_v10mapositiontaking_1 as max_mapositiontaking,0 as max_malivepositiontaking	
		union all 	select 2 as bettype, 10 as sporttype, @auto_v10mpositiontaking_2 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v10mpositiontaking_2 as isautopositiontaking, 0	as isautolivepositiontaking, @max_v10mapositiontaking_2 as max_mapositiontaking,0 as max_malivepositiontaking	
		union all 	select 3 as bettype, 10 as sporttype, @auto_v10mpositiontaking_3 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v10mpositiontaking_3 as isautopositiontaking, 0	as isautolivepositiontaking, @max_v10mapositiontaking_3 as max_mapositiontaking,0 as max_malivepositiontaking	
		union all 	select 20 as bettype, 10 as sporttype, @auto_v10mpositiontaking_20 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v10mpositiontaking_20 as isautopositiontaking, 0	as isautolivepositiontaking, @max_v10mapositiontaking_20 as max_mapositiontaking,0 as max_malivepositiontaking	

		--v11
		union all	select 1 as bettype, 11 as sporttype, @auto_v11mpositiontaking_1 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v11mpositiontaking_1 as isautopositiontaking, 0	as isautolivepositiontaking, @max_v11mapositiontaking_1 as max_mapositiontaking,0 as max_malivepositiontaking	
		union all 	select 20 as bettype, 11 as sporttype, @auto_v11mpositiontaking_20 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v11mpositiontaking_20 as isautopositiontaking, 0	as isautolivepositiontaking, @max_v11mapositiontaking_20 as max_mapositiontaking,0 as max_malivepositiontaking	

		--v99
		union all	select 1 as bettype, 99 as sporttype, @auto_v99mpositiontaking_1 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v99mpositiontaking_1 as isautopositiontaking, 0	as isautolivepositiontaking, @max_v99mapositiontaking_1 as max_mapositiontaking,0 as max_malivepositiontaking	
		union all 	select 2 as bettype, 99 as sporttype, @auto_v99mpositiontaking_2 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v99mpositiontaking_2 as isautopositiontaking, 0	as isautolivepositiontaking, @max_v99mapositiontaking_2 as max_mapositiontaking,0 as max_malivepositiontaking	
		union all 	select 3 as bettype, 99 as sporttype, @auto_v99mpositiontaking_3 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v99mpositiontaking_3 as isautopositiontaking, 0	as isautolivepositiontaking, @max_v99mapositiontaking_3 as max_mapositiontaking,0 as max_malivepositiontaking	
		union all 	select 20 as bettype, 99 as sporttype, @auto_v99mpositiontaking_20 as autopositiontaking, 0	as autolivepositiontaking, @isauto_v99mpositiontaking_20 as isautopositiontaking, 0	as isautolivepositiontaking, @max_v99mapositiontaking_20 as max_mapositiontaking, 0 as max_malivepositiontaking	
	) as b on b.sporttype = co.sporttype and b.bettype = co.bettype
	inner join sports with (nolock) on b.sporttype = sports.sporttype
	inner join bettype with (nolock) on b.bettype = bettype.typeid
	where co.custid = @mrecommend and
	(
		  (	b.isautopositiontaking = 1 
			and b.autopositiontaking > case when max_mapositiontaking > co.maxpositiontaking then co.maxpositiontaking else max_mapositiontaking end
		  ) 
			or 
		  (	b.isautolivepositiontaking = 1 and b.sporttype = 1 and b.bettype in (1,3,7,8) 
			and (b.autolivepositiontaking > case when max_malivepositiontaking > co.maxlivepositiontaking then co.maxlivepositiontaking else max_malivepositiontaking end)
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
END

----------------------------------------------------------------------------------------------------------

update custsetting with (ROWLOCK, UPDLOCK)
set
	apositiontaking = case when (@UpdateMultiple = 1 and ((sporttype=1 and @UpdatePositiontaking = 0) or (sporttype=2 and @UpdatePositiontakingv2 = 0) or (sporttype=3 and @UpdatePositiontakingv3 = 0) or (sporttype=5 and @UpdatePositiontakingv5 = 0) or (sporttype=8 and @UpdatePositiontakingv8 = 0) or (sporttype=10 and @UpdatePositiontakingv10 = 0) or (sporttype=11 and @UpdatePositiontakingv11 = 0) or (sporttype=99 and @UpdatePositiontakingv99 = 0))) then apositiontaking else case sporttype 	when 1 then case bettype when 1 then @apositiontaking_1 when 2 then @apositiontaking_2 when 3 then @apositiontaking_3 when 4 then @apositiontaking_4 when 5 then @apositiontaking_5 when 6 then @apositiontaking_6 when 7 then @apositiontaking_7 when 8 then @apositiontaking_8 when 9 then @apositiontaking_9 when 10 then @apositiontaking_10 else 0 end
					when 2 then case bettype when 1 then @v2apositiontaking_1 when 2 then @v2apositiontaking_2 when 3 then @v2apositiontaking_3 when 7 then @v2apositiontaking_7 when 8 then @v2apositiontaking_8  when 9 then @v2apositiontaking_9 when 20 then @v2apositiontaking_20 else 0 end
					when 3 then case bettype when 1 then @v3apositiontaking_1 when 2 then @v3apositiontaking_2 when 3 then @v3apositiontaking_3 when 20 then @v3apositiontaking_20 else 0 end
					when 5 then case bettype when 1 then @v5apositiontaking_1 when 2 then @v5apositiontaking_2 when 3 then @v5apositiontaking_3 when 20 then @v5apositiontaking_20 else 0 end
					when 8 then case bettype when 1 then @v8apositiontaking_1 when 3 then @v8apositiontaking_3 when 20 then @v8apositiontaking_20 else 0 end
					when 10 then case bettype when 1 then @v10apositiontaking_1 when 2 then @v10apositiontaking_2 when 3 then @v10apositiontaking_3 when 20 then @v10apositiontaking_20 else 0 end
					when 11 then case bettype when 1 then @v11apositiontaking_1 when 20 then @v11apositiontaking_20 else 0 end
					when 99 then case bettype when 1 then @v99apositiontaking_1 when 2 then @v99apositiontaking_2 when 3 then @v99apositiontaking_3 when 20 then @v99apositiontaking_20 else 0 end
				else apositiontaking end end,
	mpositiontaking = case when (@UpdateMultiple = 1 and ((sporttype=1 and @UpdatePositiontaking = 0) or (sporttype=2 and @UpdatePositiontakingv2 = 0) or (sporttype=3 and @UpdatePositiontakingv3 = 0) or (sporttype=5 and @UpdatePositiontakingv5 = 0) or (sporttype=8 and @UpdatePositiontakingv8 = 0) or (sporttype=10 and @UpdatePositiontakingv10 = 0) or (sporttype=11 and @UpdatePositiontakingv11 = 0)  or (sporttype=99 and @UpdatePositiontakingv99 = 0))) then mpositiontaking else case sporttype 	when 1 then case bettype when 1 then @mpositiontaking_1 when 2 then @mpositiontaking_2 when 3 then @mpositiontaking_3 when 4 then @mpositiontaking_4 when 5 then @mpositiontaking_5 when 6 then @mpositiontaking_6 when 7 then @mpositiontaking_7 when 8 then @mpositiontaking_8 when 9 then @mpositiontaking_9  when 10 then @mpositiontaking_10 else 0 end
					when 2 then case bettype when 1 then @v2mpositiontaking_1 when 2 then @v2mpositiontaking_2 when 3 then @v2mpositiontaking_3 when 7 then @v2mpositiontaking_7 when 8 then @v2mpositiontaking_8 when 9 then @v2mpositiontaking_9 when 20 then @v2mpositiontaking_20 else 0 end
					when 3 then case bettype when 1 then @v3mpositiontaking_1 when 2 then @v3mpositiontaking_2 when 3 then @v3mpositiontaking_3 when 20 then @v3mpositiontaking_20 else 0 end
					when 5 then case bettype when 1 then @v5mpositiontaking_1 when 2 then @v5mpositiontaking_2 when 3 then @v5mpositiontaking_3 when 20 then @v5mpositiontaking_20 else 0 end
					when 8 then case bettype when 1 then @v8mpositiontaking_1 when 3 then @v8mpositiontaking_3 when 20 then @v8mpositiontaking_20 else 0 end
					when 10 then case bettype when 1 then @v10mpositiontaking_1 when 2 then @v10mpositiontaking_2 when 3 then @v10mpositiontaking_3 when 20 then @v10mpositiontaking_20 else 0 end
					when 11 then case bettype when 1 then @v11mpositiontaking_1 when 20 then @v11mpositiontaking_20 else 0 end
					when 99 then case bettype when 1 then @v99mpositiontaking_1 when 2 then @v99mpositiontaking_2 when 3 then @v99mpositiontaking_3 when 20 then @v99mpositiontaking_20 else 0 end
				else mpositiontaking end end,
	alivepositiontaking = case when (@UpdateMultiple = 1 and ((sporttype=1 and @UpdatePositiontaking = 0) or (sporttype=2 and @UpdatePositiontakingv2 = 0) or (sporttype=3 and @UpdatePositiontakingv3 = 0) or (sporttype=5 and @UpdatePositiontakingv5 = 0) or (sporttype=8 and @UpdatePositiontakingv8 = 0) or (sporttype=10 and @UpdatePositiontakingv10 = 0) or (sporttype=11 and @UpdatePositiontakingv11 = 0) or (sporttype=99 and @UpdatePositiontakingv99 = 0))) then alivepositiontaking else case sporttype 	when 1 then case bettype when 1 then @alivepositiontaking_1 when 3 then @alivepositiontaking_3 when 7 then @alivepositiontaking_7 when 8 then @alivepositiontaking_8 else alivepositiontaking end else alivepositiontaking end end,
	mlivepositiontaking = case when (@UpdateMultiple = 1 and ((sporttype=1 and @UpdatePositiontaking = 0) or (sporttype=2 and @UpdatePositiontakingv2 = 0) or (sporttype=3 and @UpdatePositiontakingv3 = 0) or (sporttype=5 and @UpdatePositiontakingv5 = 0) or (sporttype=8 and @UpdatePositiontakingv8 = 0) or (sporttype=10 and @UpdatePositiontakingv10 = 0) or (sporttype=11 and @UpdatePositiontakingv11 = 0) or (sporttype=99 and @UpdatePositiontakingv99 = 0))) then mlivepositiontaking else case sporttype 	when 1 then case bettype when 1 then @mlivepositiontaking_1 when 3 then @mlivepositiontaking_3 when 7 then @mlivepositiontaking_7 when 8 then @mlivepositiontaking_8 else mlivepositiontaking end else mlivepositiontaking end end
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
					end, @ErrCode = 115
	return
end

--Cal Auto Positiontaking for Master
EXEC dbo.Acc_CustomerUpdAgent_AutoPositiontaking 
	@recommend = @custid,
	@mrecommend = @mrecommend,
	@auto_mpositiontaking_1 = @auto_mpositiontaking_1,
	@auto_mpositiontaking_2 = @auto_mpositiontaking_2,
	@auto_mpositiontaking_3 = @auto_mpositiontaking_3,
	@auto_mpositiontaking_4 = @auto_mpositiontaking_4,
	@auto_mpositiontaking_5 = @auto_mpositiontaking_5,
	@auto_mpositiontaking_6 = @auto_mpositiontaking_6,
	@auto_mpositiontaking_7 = @auto_mpositiontaking_7,
	@auto_mpositiontaking_8 = @auto_mpositiontaking_8,
	@auto_mpositiontaking_9 = @auto_mpositiontaking_9,
	@auto_mpositiontaking_10 = @auto_mpositiontaking_10,
	@auto_mlivepositiontaking_1 = @auto_mlivepositiontaking_1,
	@auto_mlivepositiontaking_3 = @auto_mlivepositiontaking_3,
	@auto_mlivepositiontaking_7 = @auto_mlivepositiontaking_7,
	@auto_mlivepositiontaking_8 = @auto_mlivepositiontaking_8,
	@auto_v2mpositiontaking_1 = @auto_v2mpositiontaking_1,
	@auto_v2mpositiontaking_2 = @auto_v2mpositiontaking_2,
	@auto_v2mpositiontaking_3 = @auto_v2mpositiontaking_3,
	@auto_v2mpositiontaking_7 = @auto_v2mpositiontaking_7,
	@auto_v2mpositiontaking_8 = @auto_v2mpositiontaking_8,
	@auto_v2mpositiontaking_9 = @auto_v2mpositiontaking_9,
	@auto_v2mpositiontaking_20 = @auto_v2mpositiontaking_20,
	@auto_v3mpositiontaking_1 = @auto_v3mpositiontaking_1,
	@auto_v3mpositiontaking_2 = @auto_v3mpositiontaking_2,
	@auto_v3mpositiontaking_3 = @auto_v3mpositiontaking_3,
	@auto_v3mpositiontaking_20 = @auto_v3mpositiontaking_20,
	@auto_v5mpositiontaking_1 = @auto_v5mpositiontaking_1,
	@auto_v5mpositiontaking_2 = @auto_v5mpositiontaking_2,
	@auto_v5mpositiontaking_3 = @auto_v5mpositiontaking_3,
	@auto_v5mpositiontaking_20 = @auto_v5mpositiontaking_20,
	@auto_v8mpositiontaking_1 = @auto_v8mpositiontaking_1,
	@auto_v8mpositiontaking_3 = @auto_v8mpositiontaking_3,
	@auto_v8mpositiontaking_20 = @auto_v8mpositiontaking_20,
	@auto_v10mpositiontaking_1 = @auto_v10mpositiontaking_1,
	@auto_v10mpositiontaking_2 = @auto_v10mpositiontaking_2,
	@auto_v10mpositiontaking_3 = @auto_v10mpositiontaking_3,
	@auto_v10mpositiontaking_20 = @auto_v10mpositiontaking_20,
	@auto_v11mpositiontaking_1 = @auto_v11mpositiontaking_1,
	@auto_v11mpositiontaking_20 = @auto_v11mpositiontaking_20,

	@auto_v99mpositiontaking_1 = @auto_v99mpositiontaking_1,
	@auto_v99mpositiontaking_2 = @auto_v99mpositiontaking_2,
	@auto_v99mpositiontaking_3 = @auto_v99mpositiontaking_3,
	@auto_v99mpositiontaking_20 = @auto_v99mpositiontaking_20,
	@updatemultiple = @updatemultiple,
	@updatepositiontaking = @updatepositiontaking,
	@updatepositiontakingv2 = @updatepositiontakingv2,
	@updatepositiontakingv3 = @updatepositiontakingv3,
	@updatepositiontakingv5 = @updatepositiontakingv5,
	@updatepositiontakingv8 = @updatepositiontakingv8,
	@updatepositiontakingv10 = @updatepositiontakingv10,
	@updatepositiontakingv11 = @updatepositiontakingv11,

	@updatepositiontakingv99 = @updatepositiontakingv99,
	
	@language = @language,
	@updateallmembers = @updateallmembers,
	@newmpositiontaking = @newmpositiontaking,
	@userid = @userid,
	@isauto_mpositiontaking_1 = @isauto_mpositiontaking_1,
	@isauto_mpositiontaking_2 = @isauto_mpositiontaking_2,
	@isauto_mpositiontaking_3 = @isauto_mpositiontaking_3,
	@isauto_mpositiontaking_4 = @isauto_mpositiontaking_4,
	@isauto_mpositiontaking_5 = @isauto_mpositiontaking_5,
	@isauto_mpositiontaking_6 = @isauto_mpositiontaking_6,
	@isauto_mpositiontaking_7 = @isauto_mpositiontaking_7,
	@isauto_mpositiontaking_8 = @isauto_mpositiontaking_8,
	@isauto_mpositiontaking_9 = @isauto_mpositiontaking_9,
	@isauto_mpositiontaking_10 = @isauto_mpositiontaking_10,
	@isauto_mlivepositiontaking_1 = @isauto_mlivepositiontaking_1,
	@isauto_mlivepositiontaking_3 = @isauto_mlivepositiontaking_3,
	@isauto_mlivepositiontaking_7 = @isauto_mlivepositiontaking_7,
	@isauto_mlivepositiontaking_8 = @isauto_mlivepositiontaking_8,
	@isauto_v2mpositiontaking_1 = @isauto_v2mpositiontaking_1,
	@isauto_v2mpositiontaking_2 = @isauto_v2mpositiontaking_2,
	@isauto_v2mpositiontaking_3 = @isauto_v2mpositiontaking_3,
	@isauto_v2mpositiontaking_7 = @isauto_v2mpositiontaking_7,
	@isauto_v2mpositiontaking_8 = @isauto_v2mpositiontaking_8,
	@isauto_v2mpositiontaking_9 = @isauto_v2mpositiontaking_9,
	@isauto_v2mpositiontaking_20 = @isauto_v2mpositiontaking_20,
	@isauto_v3mpositiontaking_1 = @isauto_v3mpositiontaking_1,
	@isauto_v3mpositiontaking_2 = @isauto_v3mpositiontaking_2,
	@isauto_v3mpositiontaking_3 = @isauto_v3mpositiontaking_3,
	@isauto_v3mpositiontaking_20 = @isauto_v3mpositiontaking_20,
	@isauto_v5mpositiontaking_1 = @isauto_v5mpositiontaking_1,
	@isauto_v5mpositiontaking_2 = @isauto_v5mpositiontaking_2,
	@isauto_v5mpositiontaking_3 = @isauto_v5mpositiontaking_3,
	@isauto_v5mpositiontaking_20 = @isauto_v5mpositiontaking_20,
	@isauto_v8mpositiontaking_1 = @isauto_v8mpositiontaking_1,
	@isauto_v8mpositiontaking_3 = @isauto_v8mpositiontaking_3,
	@isauto_v8mpositiontaking_20 = @isauto_v8mpositiontaking_20,
	@isauto_v10mpositiontaking_1 = @isauto_v10mpositiontaking_1,
	@isauto_v10mpositiontaking_2 = @isauto_v10mpositiontaking_2,
	@isauto_v10mpositiontaking_3 = @isauto_v10mpositiontaking_3,
	@isauto_v10mpositiontaking_20 = @isauto_v10mpositiontaking_20,
	@isauto_v11mpositiontaking_1 = @isauto_v11mpositiontaking_1,
	@isauto_v11mpositiontaking_20 = @isauto_v11mpositiontaking_20,

	@isauto_v99mpositiontaking_1 = @isauto_v99mpositiontaking_1,
	@isauto_v99mpositiontaking_2 = @isauto_v99mpositiontaking_2,
	@isauto_v99mpositiontaking_3 = @isauto_v99mpositiontaking_3,
	@isauto_v99mpositiontaking_20 = @isauto_v99mpositiontaking_20,
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


EXEC dbo.Acc_CustomerUpdAgent_MaxPositiontaking @recommend = @custid
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

Select @LogSPData ='<Acc_CustomerUpdAgent_PositionTaking><info UpdMultiple="'+ coalesce(cast(@UpdateMultiple as varchar(50)),space(1)) + '" ' +
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

'<ag apt_1="'+ coalesce(cast(@apositiontaking_1 as varchar(50)),space(1)) + '" ' +
'apt_2="'+ coalesce(cast(@apositiontaking_2 as varchar(50)),space(1)) + '" ' +
'apt_3="'+ coalesce(cast(@apositiontaking_3 as varchar(50)),space(1)) + '" ' +
'apt_4="'+ coalesce(cast(@apositiontaking_4 as varchar(50)),space(1)) + '" ' +
'apt_5="'+ coalesce(cast(@apositiontaking_5 as varchar(50)),space(1)) + '" ' +
'apt_6="'+ coalesce(cast(@apositiontaking_6 as varchar(50)),space(1)) + '" ' +
'apt_7="'+ coalesce(cast(@apositiontaking_7 as varchar(50)),space(1)) + '" ' +
'apt_8="'+ coalesce(cast(@apositiontaking_8 as varchar(50)),space(1)) + '" ' +
'apt_9="'+ coalesce(cast(@apositiontaking_9 as varchar(50)),space(1)) + '" ' +
'apt_10="'+ coalesce(cast(@apositiontaking_10 as varchar(50)),space(1)) + '" ' +
'alivept_1="'+ coalesce(cast(@alivepositiontaking_1 as varchar(50)),space(1)) + '" ' +
'alivept_3="'+ coalesce(cast(@alivepositiontaking_3 as varchar(50)),space(1)) + '" ' +
'alivept_7="'+ coalesce(cast(@alivepositiontaking_7 as varchar(50)),space(1)) + '" ' +
'alivept_8="'+ coalesce(cast(@alivepositiontaking_8 as varchar(50)),space(1)) + '" ' +

'v2apt_1="'+ coalesce(cast(@v2apositiontaking_1 as varchar(50)),space(1)) + '" ' +
'v2apt_2="'+ coalesce(cast(@v2apositiontaking_2 as varchar(50)),space(1)) + '" ' +
'v2apt_3="'+ coalesce(cast(@v2apositiontaking_3 as varchar(50)),space(1)) + '" ' +
'v2apt_7="'+ coalesce(cast(@v2apositiontaking_7 as varchar(50)),space(1)) + '" ' +
'v2apt_8="'+ coalesce(cast(@v2apositiontaking_8 as varchar(50)),space(1)) + '" ' +
'v2apt_9="'+ coalesce(cast(@v2apositiontaking_9 as varchar(50)),space(1)) + '" ' +
'v2apt_20="'+ coalesce(cast(@v2apositiontaking_20 as varchar(50)),space(1)) + '" ' +

'v3apt_1="'+ coalesce(cast(@v3apositiontaking_1 as varchar(50)),space(1)) + '" ' +
'v3apt_2="'+ coalesce(cast(@v3apositiontaking_2 as varchar(50)),space(1)) + '" ' +
'v3apt_3="'+ coalesce(cast(@v3apositiontaking_3 as varchar(50)),space(1)) + '" ' +
'v3apt_20="'+ coalesce(cast(@v3apositiontaking_20 as varchar(50)),space(1)) + '" ' +

'v5apt_1="'+ coalesce(cast(@v5apositiontaking_1 as varchar(50)),space(1)) + '" ' +
'v5apt_2="'+ coalesce(cast(@v5apositiontaking_2 as varchar(50)),space(1)) + '" ' +
'v5apt_3="'+ coalesce(cast(@v5apositiontaking_3 as varchar(50)),space(1)) + '" ' +
'v5apt_20="'+ coalesce(cast(@v5apositiontaking_20 as varchar(50)),space(1)) + '" ' +

'v8apt_1="'+ coalesce(cast(@v8apositiontaking_1 as varchar(50)),space(1)) + '" ' +
'v8apt_3="'+ coalesce(cast(@v8apositiontaking_3 as varchar(50)),space(1)) + '" ' +
'v8apt_20="'+ coalesce(cast(@v8apositiontaking_20 as varchar(50)),space(1)) + '" ' +

'v10apt_1="'+ coalesce(cast(@v10apositiontaking_1 as varchar(50)),space(1)) + '" ' +
'v10apt_2="'+ coalesce(cast(@v10apositiontaking_2 as varchar(50)),space(1)) + '" ' +
'v10apt_3="'+ coalesce(cast(@v10apositiontaking_3 as varchar(50)),space(1)) + '" ' +
'v10apt_20="'+ coalesce(cast(@v10apositiontaking_20 as varchar(50)),space(1)) + '" ' +

'v11apt_1="'+ coalesce(cast(@v11apositiontaking_1 as varchar(50)),space(1)) + '" ' +
'v11apt_20="'+ coalesce(cast(@v11apositiontaking_20 as varchar(50)),space(1)) + '" ' +

'v99apt_1="'+ coalesce(cast(@v99apositiontaking_1 as varchar(50)),space(1)) + '" ' +
'v99apt_2="'+ coalesce(cast(@v99apositiontaking_2 as varchar(50)),space(1)) + '" ' +
'v99apt_3="'+ coalesce(cast(@v99apositiontaking_3 as varchar(50)),space(1)) + '" ' +
'v99apt_20="'+ coalesce(cast(@v99apositiontaking_20 as varchar(50)),space(1)) + '" />' +

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
'v99mpt_20="'+ coalesce(cast(@v99mpositiontaking_20 as varchar(50)),space(1)) + '" />' +

--auto v1
'<aum a_mpt_1="'+ coalesce(cast(@auto_mpositiontaking_1 as varchar(50)),space(1)) + '" ' +
'a_mpt_2="'+ coalesce(cast(@auto_mpositiontaking_2 as varchar(50)),space(1)) + '" ' +
'a_mpt_3="'+ coalesce(cast(@auto_mpositiontaking_3 as varchar(50)),space(1)) + '" ' +
'a_mpt_4="'+ coalesce(cast(@auto_mpositiontaking_4 as varchar(50)),space(1)) + '" ' +
'a_mpt_5="'+ coalesce(cast(@auto_mpositiontaking_5 as varchar(50)),space(1)) + '" ' +
'a_mpt_6="'+ coalesce(cast(@auto_mpositiontaking_6 as varchar(50)),space(1)) + '" ' +
'a_mpt_7="'+ coalesce(cast(@auto_mpositiontaking_7 as varchar(50)),space(1)) + '" ' +
'a_mpt_8="'+ coalesce(cast(@auto_mpositiontaking_8 as varchar(50)),space(1)) + '" ' +
'a_mpt_9="'+ coalesce(cast(@auto_mpositiontaking_9 as varchar(50)),space(1)) + '" ' +
'a_mpt_10="'+ coalesce(cast(@auto_mpositiontaking_10 as varchar(50)),space(1)) + '" ' +
'a_mlivept_1="'+ coalesce(cast(@auto_mlivepositiontaking_1 as varchar(50)),space(1)) + '" ' +
'a_mlivept_3="'+ coalesce(cast(@auto_mlivepositiontaking_3 as varchar(50)),space(1)) + '" ' +
'a_mlivept_7="'+ coalesce(cast(@auto_mlivepositiontaking_7 as varchar(50)),space(1)) + '" ' +
'a_mlivept_8="'+ coalesce(cast(@auto_mlivepositiontaking_8 as varchar(50)),space(1)) + '" ' +

--auto v2
'a_v2mpt_1="'+ coalesce(cast(@auto_v2mpositiontaking_1 as varchar(50)),space(1)) + '" ' +
'a_v2mpt_2="'+ coalesce(cast(@auto_v2mpositiontaking_2 as varchar(50)),space(1)) + '" ' +
'a_v2mpt_3="'+ coalesce(cast(@auto_v2mpositiontaking_3 as varchar(50)),space(1)) + '" ' +
'a_v2mpt_7="'+ coalesce(cast(@auto_v2mpositiontaking_7 as varchar(50)),space(1)) + '" ' +
'a_v2mpt_8="'+ coalesce(cast(@auto_v2mpositiontaking_8 as varchar(50)),space(1)) + '" ' +
'a_v2mpt_9="'+ coalesce(cast(@auto_v2mpositiontaking_9 as varchar(50)),space(1)) + '" ' +
'a_v2mpt_20="'+ coalesce(cast(@auto_v2mpositiontaking_20 as varchar(50)),space(1)) + '" ' +

--auto v3
'a_v3mpt_1="'+ coalesce(cast(@auto_v3mpositiontaking_1 as varchar(50)),space(1)) + '" ' +
'a_v3mpt_2="'+ coalesce(cast(@auto_v3mpositiontaking_2 as varchar(50)),space(1)) + '" ' +
'a_v3mpt_3="'+ coalesce(cast(@auto_v3mpositiontaking_3 as varchar(50)),space(1)) + '" ' +
'a_v3mpt_20="'+ coalesce(cast(@auto_v3mpositiontaking_20 as varchar(50)),space(1)) + '" ' +

--auto v5
'a_v5mpt_1="'+ coalesce(cast(@auto_v5mpositiontaking_1 as varchar(50)),space(1)) + '" ' +
'a_v5mpt_2="'+ coalesce(cast(@auto_v5mpositiontaking_2 as varchar(50)),space(1)) + '" ' +
'a_v5mpt_3="'+ coalesce(cast(@auto_v5mpositiontaking_3 as varchar(50)),space(1)) + '" ' +
'a_v5mpt_20="'+ coalesce(cast(@auto_v5mpositiontaking_20 as varchar(50)),space(1)) + '" ' +

--auto v8
'a_v8mpt_1="'+ coalesce(cast(@auto_v8mpositiontaking_1 as varchar(50)),space(1)) + '" ' +
'a_v8mpt_3="'+ coalesce(cast(@auto_v8mpositiontaking_3 as varchar(50)),space(1)) + '" ' +
'a_v8mpt_20="'+ coalesce(cast(@auto_v8mpositiontaking_20 as varchar(50)),space(1)) + '" ' +

--auto v10
'a_v10mpt_1="'+ coalesce(cast(@auto_v10mpositiontaking_1 as varchar(50)),space(1)) + '" ' +
'a_v10mpt_2="'+ coalesce(cast(@auto_v10mpositiontaking_2 as varchar(50)),space(1)) + '" ' +
'a_v10mpt_3="'+ coalesce(cast(@auto_v10mpositiontaking_3 as varchar(50)),space(1)) + '" ' +
'a_v10mpt_20="'+ coalesce(cast(@auto_v10mpositiontaking_20 as varchar(50)),space(1)) + '" ' +

--auto v11
'a_v11mpt_1="'+ coalesce(cast(@auto_v11mpositiontaking_1 as varchar(50)),space(1)) + '" ' +
'a_v11mpt_20="'+ coalesce(cast(@auto_v11mpositiontaking_20 as varchar(50)),space(1)) + '" ' +

--auto v99
'a_v99mpt_1="'+ coalesce(cast(@auto_v99mpositiontaking_1 as varchar(50)),space(1)) + '" ' +
'a_v99mpt_2="'+ coalesce(cast(@auto_v99mpositiontaking_2 as varchar(50)),space(1)) + '" ' +
'a_v99mpt_3="'+ coalesce(cast(@auto_v99mpositiontaking_3 as varchar(50)),space(1)) + '" ' +
'a_v99mpt_20="'+ coalesce(cast(@auto_v99mpositiontaking_20 as varchar(50)),space(1)) + '" />' +

--isauto v1
'<iam isa_mpt_1="'+ coalesce(cast(@isauto_mpositiontaking_1 as varchar(50)),space(1)) + '" ' +
'isa_mpt_2="'+ coalesce(cast(@isauto_mpositiontaking_2 as varchar(50)),space(1)) + '" ' +
'isa_mpt_3="'+ coalesce(cast(@isauto_mpositiontaking_3 as varchar(50)),space(1)) + '" ' +
'isa_mpt_4="'+ coalesce(cast(@isauto_mpositiontaking_4 as varchar(50)),space(1)) + '" ' +
'isa_mpt_5="'+ coalesce(cast(@isauto_mpositiontaking_5 as varchar(50)),space(1)) + '" ' +
'isa_mpt_6="'+ coalesce(cast(@isauto_mpositiontaking_6 as varchar(50)),space(1)) + '" ' +
'isa_mpt_7="'+ coalesce(cast(@isauto_mpositiontaking_7 as varchar(50)),space(1)) + '" ' +
'isa_mpt_8="'+ coalesce(cast(@isauto_mpositiontaking_8 as varchar(50)),space(1)) + '" ' +
'isa_mpt_9="'+ coalesce(cast(@isauto_mpositiontaking_9 as varchar(50)),space(1)) + '" ' +
'isa_mpt_10="'+ coalesce(cast(@isauto_mpositiontaking_10 as varchar(50)),space(1)) + '" ' +
'isa_mlivept_1="'+ coalesce(cast(@isauto_mlivepositiontaking_1 as varchar(50)),space(1)) + '" ' +
'isa_mlivept_3="'+ coalesce(cast(@isauto_mlivepositiontaking_3 as varchar(50)),space(1)) + '" ' +
'isa_mlivept_7="'+ coalesce(cast(@isauto_mlivepositiontaking_7 as varchar(50)),space(1)) + '" ' +
'isa_mlivept_8="'+ coalesce(cast(@isauto_mlivepositiontaking_8 as varchar(50)),space(1)) + '" ' +

--isauto v2
'isa_v2mpt_1="'+ coalesce(cast(@isauto_v2mpositiontaking_1 as varchar(50)),space(1)) + '" ' +
'isa_v2mpt_2="'+ coalesce(cast(@isauto_v2mpositiontaking_2 as varchar(50)),space(1)) + '" ' +
'isa_v2mpt_3="'+ coalesce(cast(@isauto_v2mpositiontaking_3 as varchar(50)),space(1)) + '" ' +
'isa_v2mpt_7="'+ coalesce(cast(@isauto_v2mpositiontaking_7 as varchar(50)),space(1)) + '" ' +
'isa_v2mpt_8="'+ coalesce(cast(@isauto_v2mpositiontaking_8 as varchar(50)),space(1)) + '" ' +
'isa_v2mpt_9="'+ coalesce(cast(@isauto_v2mpositiontaking_9 as varchar(50)),space(1)) + '" ' +
'isa_v2mpt_20="'+ coalesce(cast(@isauto_v2mpositiontaking_20 as varchar(50)),space(1)) + '" ' +

--isauto v3
'isa_v3mpt_1="'+ coalesce(cast(@isauto_v3mpositiontaking_1 as varchar(50)),space(1)) + '" ' +
'isa_v3mpt_2="'+ coalesce(cast(@isauto_v3mpositiontaking_2 as varchar(50)),space(1)) + '" ' +
'isa_v3mpt_3="'+ coalesce(cast(@isauto_v3mpositiontaking_3 as varchar(50)),space(1)) + '" ' +
'isa_v3mpt_20="'+ coalesce(cast(@isauto_v3mpositiontaking_20 as varchar(50)),space(1)) + '" ' +

--isauto v5
'isa_v5mpt_1="'+ coalesce(cast(@isauto_v5mpositiontaking_1 as varchar(50)),space(1)) + '" ' +
'isa_v5mpt_2="'+ coalesce(cast(@isauto_v5mpositiontaking_2 as varchar(50)),space(1)) + '" ' +
'isa_v5mpt_3="'+ coalesce(cast(@isauto_v5mpositiontaking_3 as varchar(50)),space(1)) + '" ' +
'isa_v5mpt_20="'+ coalesce(cast(@isauto_v5mpositiontaking_20 as varchar(50)),space(1)) + '" ' +

--isauto v8
'isa_v8mpt_1="'+ coalesce(cast(@isauto_v8mpositiontaking_1 as varchar(50)),space(1)) + '" ' +
'isa_v8mpt_3="'+ coalesce(cast(@isauto_v8mpositiontaking_3 as varchar(50)),space(1)) + '" ' +
'isa_v8mpt_20="'+ coalesce(cast(@isauto_v8mpositiontaking_20 as varchar(50)),space(1)) + '" ' +

--isauto v10
'isa_v10mpt_1="'+ coalesce(cast(@isauto_v10mpositiontaking_1 as varchar(50)),space(1)) + '" ' +
'isa_v10mpt_2="'+ coalesce(cast(@isauto_v10mpositiontaking_2 as varchar(50)),space(1)) + '" ' +
'isa_v10mpt_3="'+ coalesce(cast(@isauto_v10mpositiontaking_3 as varchar(50)),space(1)) + '" ' +
'isa_v10mpt_20="'+ coalesce(cast(@isauto_v10mpositiontaking_20 as varchar(50)),space(1)) + '" ' +

--isauto v11
'isa_v11mpt_1="'+ coalesce(cast(@isauto_v11mpositiontaking_1 as varchar(50)),space(1)) + '" ' +
'isa_v11mpt_20="'+ coalesce(cast(@isauto_v11mpositiontaking_20 as varchar(50)),space(1)) + '" ' +
--isauto v99
'isa_v99mpt_1="'+ coalesce(cast(@isauto_v99mpositiontaking_1 as varchar(50)),space(1)) + '" ' +
'isa_v99mpt_2="'+ coalesce(cast(@isauto_v99mpositiontaking_2 as varchar(50)),space(1)) + '" ' +
'isa_v99mpt_3="'+ coalesce(cast(@isauto_v99mpositiontaking_3 as varchar(50)),space(1)) + '" ' +
'isa_v99mpt_20="'+ coalesce(cast(@isauto_v99mpositiontaking_20 as varchar(50)),space(1)) + '" /></Acc_CustomerUpdAgent_PositionTaking>'

--Log positiontaking
EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew
	@UserID = @UserID,
	@CustID = @CustID,
	@ActionID = 412,
	@TrackingValue = @LogSPData
GO

GRANT EXECUTE ON [dbo].[Acc_CustomerUpdAgent_PositionTaking] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdAgent_PositionTaking] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdAgent_PositionTaking] TO vnteam
