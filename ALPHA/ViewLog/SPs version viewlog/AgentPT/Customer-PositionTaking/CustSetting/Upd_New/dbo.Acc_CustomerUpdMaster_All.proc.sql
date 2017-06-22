ALTER PROCEDURE [dbo].[Acc_CustomerUpdMaster_All]
	@custid int,-- masterid	
	@disCasino bit = 0,	
	@firstname nvarchar(50),
	@lastname nvarchar(50),
	@phone nvarchar(50),	
	@mobilephone nvarchar(50),
	@email nvarchar(50) = '',
	@fax nvarchar(50),
	@closed bit,
	@Suspended bit,
	@srecommend int,--superid
	 
	@minbet money,
	@maxbet money,
	@maxpermatch money,
	
	@minbetv2 money,
	@maxbetv2 money,
	@maxpermatchv2 money,
	
	@minbetv3 money,
	@maxbetv3 money,
	@maxpermatchv3 money,
	
	@minbetv5 money,
	@maxbetv5 money,
	@maxpermatchv5 money,
	
	@minbetv8 money,
	@maxbetv8 money,
	@maxpermatchv8 money,
	
	@minbetv10 money,
	@maxbetv10 money,
	@maxpermatchv10 money,
	
	@minbetv11 money,
	@maxbetv11 money,
	@maxpermatchv11 money,

	@minbetv99 money,
	@maxbetv99 money,
	@maxpermatchv99 money,
	
	@credit money,
	@Language varchar(2),
	@UpdateMultiple bit = 0,
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
	
	@groupa decimal(9,8),
	@groupb decimal(9,8),
	@groupc decimal(9,8),
	@groupd decimal(9,8),
	@discountcs decimal(9,8),
	@discount1x2 decimal(9,8)=0, --1x2	
	@UpdateCommission bit = 1,
	
	@UpdateMinMaxBet bit = 1,
	@UpdateMinMaxBetv2 bit = 1,
	@UpdateMinMaxBetv3 bit = 1,
	@UpdateMinMaxBetv5 bit = 1,
	@UpdateMinMaxBetv8 bit = 1,
	@UpdateMinMaxBetv10 bit = 1,
	@UpdateMinMaxBetv11 bit = 1,
	@UpdateMinMaxBetv99 bit = 1,
	
	@UpdatePositiontaking bit = 1,
	@UpdatePositiontakingv2 bit = 1,
	@UpdatePositiontakingv3 bit = 1,
	@UpdatePositiontakingv5 bit = 1,
	@UpdatePositiontakingv8 bit = 1,
	@UpdatePositiontakingv10 bit = 1,
	@UpdatePositiontakingv11 bit = 1,
	@UpdatePositiontakingv99 bit = 1,
	
	@UpdateClosed bit = 1,
	@UpdateSuspended BIT = 1,

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
	
	@updateallmembers bit = 0,
	@newspositiontaking smallmoney = 0,--equals max(s+m) - chosen(m)
	
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
	
	@SubAccID int = 0, --Sub-AccountID
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
	
	@IP varchar(15) = '',
	@UserID int,
	@Username varchar(30) = '' OUTPUT,
	@ErrCode varchar(300) = '' OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
as
--@Source Control
/*
Created: 20080514@Thien
Task : Update master
DB: DB02.bodb02
Original: Acc_CustomerUpdEditCustomer_SAg

Revisions:
    - 20081023@Phuc: Add new sporttype 201, bettype 3, hard code copy min/max/maxperbet/PT for 201 from 2 sporttype 
    - 20090122@PhuongBich: add new sporttype 201, bettype 2.
    - 20090317@Phuc: update Financial.
	- 20090320@PhuongDao: Change the param @IsUpdDownlineFI to @DisableDownlineFI
    - 20090424@Phuc:Separate finance sporttype(201).
    - 20090430@Kiwi: Add checking IF @UpdateSuspended = 1 for updating multiple customer
    - 20090514@PhuongDao: Add 1x2 Commission
    - 20090801@Shifu: check disabled user
    - 20091125@Terry: Check disable casino
Param's Explanation:
• @ErrCode:
    = 0: Update successfully.
    > 0: Specific Error.
  
• @ErrMsg: Error description.
*/

SET NOCOUNT ON
---------------------------
-- ***Check Downline Belonging***
declare @roleid tinyint, @ErrCode_Cur int, @ErrMsg_Cur nvarchar(4000)
Select @ErrCode_Cur = 0, @ErrMsg_Cur = '', @ErrCode = '', @ErrMsg = ''

EXEC  DB052.bodb02.dbo.Age_CustomerSelCheckBelonging 
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
----------------------------------------------

----------------------------------------------
--Update Info
IF @UpdateMultiple = 0
BEGIN
	Select @ErrCode_Cur = 0, @ErrMsg_Cur = ''
	EXEC dbo.Acc_CustomerUpdUserInfo 
				@CustID = @CustID,
				@firstname = @firstname,
				@lastname = @lastname,
				@phone = @phone,
				@mobilephone = @mobilephone,
				@fax = @fax,
				@email = @email,
				@SubAccID = @SubAccID,
				@disCasino = @disCasino,
				@UserID = @UserID,
				@ErrMsg = @ErrMsg_Cur OUTPUT,
				@ErrCode = @ErrCode_Cur OUTPUT,
				@IP = @IP			
	
	IF @ErrCode_Cur > 0
	BEGIN
		select @ErrCode = @ErrCode + cast(@ErrCode_cur as varchar(300)) + char(7), 
				@ErrMsg = @ErrMsg + @ErrMsg_Cur + char(7)
		
	END
	ELSE
	BEGIN
		Select @ErrCode = @ErrCode + '-101'+char(7), @ErrMsg = @ErrMsg + char(7)
	END
END

----------------------------------------------
--Update Closed
if @UpdateClosed = 1
BEGIN
	Select @ErrCode_Cur = 0, @ErrMsg_Cur = ''
	EXEC dbo.Acc_CustomerUpdClosed
				@CustID = @CustID,
				@Closed = @Closed,
				@disCasino = @disCasino,
				@SubAccID = @SubAccID,
				@UserID = @UserID,
				@Language = @Language,
				@ErrCode = @ErrCode_Cur OUTPUT,
				@ErrMsg = @ErrMsg_Cur OUTPUT,
				@IP = @IP
				
	IF @ErrCode_Cur > 0
	BEGIN
		select @ErrCode = @ErrCode + cast(@ErrCode_cur as varchar(300)) + char(7), 
				@ErrMsg = @ErrMsg + @ErrMsg_Cur + char(7)
		
	END
	ELSE
	BEGIN
		Select @ErrCode = @ErrCode + '-102'+char(7), @ErrMsg = @ErrMsg + char(7)
	END
END


---------------------------------------------
---update suspended
IF @UpdateSuspended = 1
BEGIN
	Select @ErrCode_Cur = 0, @ErrMsg_Cur = ''
	EXEC Acc_CustomerUpdSuspended
				@CustID =@CustID,
				@Suspended =@Suspended,	
				@disCasino = @disCasino,
				@SubAccID =@SubAccID , 
				@UserID =@UserID,
				@Language =@Language,
				@ErrCode =@ErrCode_Cur OUTPUT,
				@ErrMsg =@ErrMsg_Cur OUTPUT,
				@IP =@IP
				
	IF @ErrCode_Cur > 0
	BEGIN
		select @ErrCode = @ErrCode + cast(@ErrCode_cur as varchar(300)) + char(7), 
				@ErrMsg = @ErrMsg + @ErrMsg_Cur + char(7)
		
	END
	ELSE
	BEGIN
		Select @ErrCode = @ErrCode + '-103'+char(7), @ErrMsg = @ErrMsg + char(7)
	END
END
----------------------------------------------
--Update credit
IF @UpdateMultiple = 0
BEGIN
	Select @ErrCode_Cur = 0, @ErrMsg_Cur = ''
	EXEC dbo.Acc_CustomerUpdCredit 
		@custid = @custid,
		@NewCredit = @Credit,
		@SubAccID = @SubAccID,
		@UserID = @UserID,
		@Language = @Language,
		@ErrMsg = @ErrMsg_Cur OUTPUT,
		@ErrCode = @ErrCode_Cur OUTPUT,
		@IP = @IP
	IF @ErrCode_Cur > 0
	BEGIN
		select @ErrCode = @ErrCode + cast(@ErrCode_cur as varchar(300)) + char(7), 
				@ErrMsg = @ErrMsg + @ErrMsg_Cur + char(7)
		return
	END
	ELSE
	BEGIN
		Select @ErrCode = @ErrCode + '-104'+char(7), @ErrMsg = @ErrMsg + char(7)
	END
END

----------------------------------------------
--Update Commission
if @UpdateCommission=1 
BEGIN
	Select @ErrCode_Cur = 0, @ErrMsg_Cur = ''
	Declare @updatecomm_old bit
	Declare @groupa_old decimal(9,8),
		@groupb_old decimal(9,8),
		@groupc_old decimal(9,8),
		@groupd_old decimal(9,8),
		@discountcs_old decimal(9,8),
		@discount1x2_old decimal(9,8)

	select @groupa_old = groupa, @groupb_old = groupb, @groupc_old = groupc, @groupd_old = groupd
	from custsetting (nolock) where custid = @custid and sporttype = 1 and bettype = 1

	select @discountcs_old = adiscount
	from custsetting (nolock) where custid = @custid and sporttype = 1 and bettype = 4

	select @discount1x2_old = adiscount
	from custsetting (nolock) where custid = @custid and sporttype = 1 and bettype = 5

	if (@groupa_old <> @groupa) or (@groupb_old <> @groupb) or (@groupc_old <> @groupc) or (@groupd_old <> @groupd)
		or (@discountcs_old <> @discountcs) or (@discount1x2_old <> @discount1x2)
		set @updatecomm_old = 1
	else 
		set @updatecomm_old = 0
	if @updatecomm_old <> 0
	begin
		
		EXEC dbo.Acc_CustomerUpdMaster_Commission 
			@custid = @custid,
			@groupa = @groupa,
			@groupb = @groupb,
			@groupc = @groupc,
			@groupd = @groupd,
			@discountcs = @discountcs,
			@discount1x2 = @discount1x2,
			@updatecomm_old = @updatecomm_old,
			@SubAccID = @SubAccID,
			@UserID = @UserID,
			@Language = @Language,
			@IP = @IP,
			@ErrCode = @ErrCode_Cur OUTPUT,
			@ErrMsg = @ErrMsg_Cur OUTPUT
	end
	IF @ErrCode_Cur > 0
	BEGIN
		select @ErrCode = @ErrCode + cast(@ErrCode_cur as varchar(300)) + char(7), 
				@ErrMsg = @ErrMsg + @ErrMsg_Cur + char(7)
		return
	END
	ELSE
	BEGIN
		Select @ErrCode = @ErrCode + '-105'+char(7), @ErrMsg = @ErrMsg + char(7)
	END
END

----------------------------------------------
--Update MinBet, MaxBet, MaxPerMatch
if 	@UpdateMinMaxBet  = 1 or
	@UpdateMinMaxBetv2  = 1 or
	@UpdateMinMaxBetv3  = 1 or
	@UpdateMinMaxBetv5  = 1 or
	@UpdateMinMaxBetv8  = 1 or
	@UpdateMinMaxBetv10  = 1 or
	@UpdateMinMaxBetv11  = 1 or
	@UpdateMinMaxBetv99  = 1
BEGIN
	Select @ErrCode_Cur = 0, @ErrMsg_Cur = ''
	EXEC dbo.Acc_CustomerUpdMaster_MinMaxBet 
		@custid = @custid,
		@minbet = @minbet,
		@maxbet = @maxbet,
		@maxpermatch = @maxpermatch,
		@minbetv2 = @minbetv2,
		@maxbetv2 = @maxbetv2,
		@maxpermatchv2 = @maxpermatchv2,
		@minbetv3 = @minbetv3,
		@maxbetv3 = @maxbetv3,
		@maxpermatchv3 = @maxpermatchv3,
		@minbetv5 = @minbetv5,
		@maxbetv5 = @maxbetv5,
		@maxpermatchv5 = @maxpermatchv5,
		@minbetv8 = @minbetv8,
		@maxbetv8 = @maxbetv8,
		@maxpermatchv8 = @maxpermatchv8,
		@minbetv10 = @minbetv10,
		@maxbetv10 = @maxbetv10,
		@maxpermatchv10 = @maxpermatchv10,
		@minbetv11 = @minbetv11,
		@maxbetv11 = @maxbetv11,
		@maxpermatchv11 = @maxpermatchv11,
		@minbetv99 = @minbetv99,
		@maxbetv99 = @maxbetv99,
		@maxpermatchv99 = @maxpermatchv99,
		@UpdateMultiple = @UpdateMultiple,
		@UpdateMinMaxBet = @UpdateMinMaxBet,
		@UpdateMinMaxBetv2 = @UpdateMinMaxBetv2,
		@UpdateMinMaxBetv3 = @UpdateMinMaxBetv3,
		@UpdateMinMaxBetv5 = @UpdateMinMaxBetv5,
		@UpdateMinMaxBetv8 = @UpdateMinMaxBetv8,
		@UpdateMinMaxBetv10 = @UpdateMinMaxBetv10,
		@UpdateMinMaxBetv11 = @UpdateMinMaxBetv11,
		@UpdateMinMaxBetv99 = @UpdateMinMaxBetv99,
		@SubAccID = @SubAccID,
		@UserID = @UserID,
		@Language = @Language,
		@IP = @IP,
		@ErrCode = @ErrCode_cur OUTPUT,
		@ErrMsg = @ErrMsg_Cur OUTPUT
	IF @ErrCode_Cur > 0
	BEGIN
		select @ErrCode = @ErrCode + cast(@ErrCode_cur as varchar(300)) + char(7), 
				@ErrMsg = @ErrMsg + @ErrMsg_Cur + char(7)
		return
	END
	ELSE
	BEGIN
		Select @ErrCode = @ErrCode + '-106'+char(7), @ErrMsg = @ErrMsg + char(7)
	END
END

----------------------------------------------
--Update Position Taking
if	@UpdatePositiontaking   = 1  or
	@UpdatePositiontakingv2   = 1  or
	@UpdatePositiontakingv3   = 1  or
	@UpdatePositiontakingv5   = 1  or
	@UpdatePositiontakingv8   = 1  or
	@UpdatePositiontakingv10   = 1  or
	@UpdatePositiontakingv11   = 1  or
	@UpdatePositiontakingv99   = 1  
BEGIN
	Select @ErrCode_Cur = 0, @ErrMsg_Cur = ''
	--Check Old_PT <> New_PT
	Declare 
		--s3
		@spositiontaking_1_old smallmoney,
		@spositiontaking_2_old smallmoney,
		@spositiontaking_3_old smallmoney,
		@spositiontaking_4_old smallmoney,
		@spositiontaking_5_old smallmoney,
		@spositiontaking_6_old smallmoney,
		@spositiontaking_7_old smallmoney,
		@spositiontaking_8_old smallmoney,
		@spositiontaking_9_old smallmoney,
		@spositiontaking_10_old smallmoney,
		@slivepositiontaking_1_old smallmoney,
		@slivepositiontaking_3_old smallmoney,
		@slivepositiontaking_7_old smallmoney,
		@slivepositiontaking_8_old smallmoney,
		
		@v2spositiontaking_1_old smallmoney,
		@v2spositiontaking_2_old smallmoney,
		@v2spositiontaking_3_old smallmoney,
		@v2spositiontaking_7_old smallmoney,
		@v2spositiontaking_8_old smallmoney,
		@v2spositiontaking_9_old smallmoney,
		@v2spositiontaking_20_old smallmoney,
		
		@v3spositiontaking_1_old smallmoney,
		@v3spositiontaking_2_old smallmoney,
		@v3spositiontaking_3_old smallmoney,	
		@v3spositiontaking_20_old smallmoney,
		
		@v5spositiontaking_1_old smallmoney,
		@v5spositiontaking_2_old smallmoney,
		@v5spositiontaking_3_old smallmoney,	
		@v5spositiontaking_20_old smallmoney,
		
		@v8spositiontaking_1_old smallmoney,
		@v8spositiontaking_3_old smallmoney,	
		@v8spositiontaking_20_old smallmoney,
		
		@v10spositiontaking_1_old smallmoney,
		@v10spositiontaking_2_old smallmoney,
		@v10spositiontaking_3_old smallmoney,	
		@v10spositiontaking_20_old smallmoney,
		@v11spositiontaking_1_old smallmoney,
		@v11spositiontaking_20_old smallmoney,
		
		@v99spositiontaking_1_old smallmoney,
		@v99spositiontaking_2_old smallmoney,
		@v99spositiontaking_3_old smallmoney,	
		@v99spositiontaking_20_old smallmoney,
		--u3
		@auto_spositiontaking_1_old smallmoney ,
		@auto_spositiontaking_2_old smallmoney ,
		@auto_spositiontaking_3_old smallmoney ,
		@auto_spositiontaking_4_old smallmoney ,
		@auto_spositiontaking_5_old smallmoney,
		@auto_spositiontaking_6_old smallmoney ,
		@auto_spositiontaking_7_old smallmoney ,
		@auto_spositiontaking_8_old smallmoney ,
		@auto_spositiontaking_9_old smallmoney ,
		@auto_spositiontaking_10_old smallmoney ,
		@auto_slivepositiontaking_1_old smallmoney ,
		@auto_slivepositiontaking_3_old smallmoney ,
		@auto_slivepositiontaking_7_old smallmoney ,
		@auto_slivepositiontaking_8_old smallmoney ,
		
		@auto_v2spositiontaking_1_old smallmoney ,
		@auto_v2spositiontaking_2_old smallmoney ,
		@auto_v2spositiontaking_3_old smallmoney ,
		@auto_v2spositiontaking_7_old smallmoney ,
		@auto_v2spositiontaking_8_old smallmoney ,
		@auto_v2spositiontaking_9_old smallmoney ,
		@auto_v2spositiontaking_20_old smallmoney ,
		
		@auto_v3spositiontaking_1_old smallmoney ,
		@auto_v3spositiontaking_2_old smallmoney ,
		@auto_v3spositiontaking_3_old smallmoney ,
		@auto_v3spositiontaking_20_old smallmoney ,
		
		@auto_v5spositiontaking_1_old smallmoney ,
		@auto_v5spositiontaking_2_old smallmoney ,
		@auto_v5spositiontaking_3_old smallmoney ,
		@auto_v5spositiontaking_20_old smallmoney ,
		
		@auto_v8spositiontaking_1_old smallmoney ,
		@auto_v8spositiontaking_3_old smallmoney ,
		@auto_v8spositiontaking_20_old smallmoney ,
		
		@auto_v10spositiontaking_1_old smallmoney ,
		@auto_v10spositiontaking_2_old smallmoney ,
		@auto_v10spositiontaking_3_old smallmoney ,
		@auto_v10spositiontaking_20_old smallmoney ,
		
		@auto_v11spositiontaking_1_old smallmoney ,
		@auto_v11spositiontaking_20_old smallmoney ,

		@auto_v99spositiontaking_1_old smallmoney ,
		@auto_v99spositiontaking_2_old smallmoney ,
		@auto_v99spositiontaking_3_old smallmoney ,
		@auto_v99spositiontaking_20_old smallmoney ,
		--i3
		@isauto_spositiontaking_1_old bit ,
		@isauto_spositiontaking_2_old bit ,
		@isauto_spositiontaking_3_old bit ,
		@isauto_spositiontaking_4_old bit ,
		@isauto_spositiontaking_5_old bit,
		@isauto_spositiontaking_6_old bit ,
		@isauto_spositiontaking_7_old bit ,
		@isauto_spositiontaking_8_old bit ,
		@isauto_spositiontaking_9_old bit ,
		@isauto_spositiontaking_10_old bit ,
		@isauto_slivepositiontaking_1_old bit ,
		@isauto_slivepositiontaking_3_old bit ,
		@isauto_slivepositiontaking_7_old bit ,
		@isauto_slivepositiontaking_8_old bit ,
		
		@isauto_v2spositiontaking_1_old bit ,
		@isauto_v2spositiontaking_2_old bit ,
		@isauto_v2spositiontaking_3_old bit ,
		@isauto_v2spositiontaking_7_old bit ,
		@isauto_v2spositiontaking_8_old bit ,
		@isauto_v2spositiontaking_9_old bit ,
		@isauto_v2spositiontaking_20_old bit ,
		
		@isauto_v3spositiontaking_1_old bit ,
		@isauto_v3spositiontaking_2_old bit ,
		@isauto_v3spositiontaking_3_old bit ,
		@isauto_v3spositiontaking_20_old bit ,
		
		@isauto_v5spositiontaking_1_old bit ,
		@isauto_v5spositiontaking_2_old bit ,
		@isauto_v5spositiontaking_3_old bit ,
		@isauto_v5spositiontaking_20_old bit ,
		
		@isauto_v8spositiontaking_1_old bit ,
		@isauto_v8spositiontaking_3_old bit ,
		@isauto_v8spositiontaking_20_old bit ,
		
		@isauto_v10spositiontaking_1_old bit ,
		@isauto_v10spositiontaking_2_old bit ,
		@isauto_v10spositiontaking_3_old bit ,
		@isauto_v10spositiontaking_20_old bit ,
		
		@isauto_v11spositiontaking_1_old bit ,
		@isauto_v11spositiontaking_20_old bit ,
		
		@isauto_v99spositiontaking_1_old bit ,
		@isauto_v99spositiontaking_2_old bit ,
		@isauto_v99spositiontaking_3_old bit ,
		@isauto_v99spositiontaking_20_old bit ,
		--m3		
		@mpositiontaking_1_old smallmoney ,
		@mpositiontaking_2_old smallmoney ,
		@mpositiontaking_3_old smallmoney ,
		@mpositiontaking_4_old smallmoney ,
		@mpositiontaking_5_old smallmoney ,
		@mpositiontaking_6_old smallmoney ,
		@mpositiontaking_7_old smallmoney ,
		@mpositiontaking_8_old smallmoney ,
		@mpositiontaking_9_old smallmoney ,
		@mpositiontaking_10_old smallmoney ,
		@mlivepositiontaking_1_old smallmoney ,
		@mlivepositiontaking_3_old smallmoney ,
		@mlivepositiontaking_7_old smallmoney ,
		@mlivepositiontaking_8_old smallmoney ,
		
		@v2mpositiontaking_1_old smallmoney ,
		@v2mpositiontaking_2_old smallmoney ,
		@v2mpositiontaking_3_old smallmoney ,
		@v2mpositiontaking_7_old smallmoney ,
		@v2mpositiontaking_8_old smallmoney ,
		@v2mpositiontaking_9_old smallmoney ,
		@v2mpositiontaking_20_old smallmoney ,
		
		@v3mpositiontaking_1_old smallmoney ,
		@v3mpositiontaking_2_old smallmoney ,
		@v3mpositiontaking_3_old smallmoney ,
		@v3mpositiontaking_20_old smallmoney ,
		
		@v5mpositiontaking_1_old smallmoney ,
		@v5mpositiontaking_2_old smallmoney ,
		@v5mpositiontaking_3_old smallmoney ,
		@v5mpositiontaking_20_old smallmoney ,
		
		@v8mpositiontaking_1_old smallmoney ,
		@v8mpositiontaking_3_old smallmoney ,
		@v8mpositiontaking_20_old smallmoney ,
		
		@v10mpositiontaking_1_old smallmoney ,
		@v10mpositiontaking_2_old smallmoney ,
		@v10mpositiontaking_3_old smallmoney ,
		@v10mpositiontaking_20_old smallmoney ,
		
		@v11mpositiontaking_1_old smallmoney ,
		@v11mpositiontaking_20_old smallmoney ,
		
		@v99mpositiontaking_1_old smallmoney ,
		@v99mpositiontaking_2_old smallmoney ,
		@v99mpositiontaking_3_old smallmoney ,
		@v99mpositiontaking_20_old smallmoney
		
	--Get old PT s3,m3,u3,i3
	select @spositiontaking_1_old = spositiontaking, @slivepositiontaking_1_old = slivepositiontaking, @mpositiontaking_1_old = mpositiontaking, @mlivepositiontaking_1_old = mlivepositiontaking, @auto_spositiontaking_1_old = autopositiontaking, @auto_slivepositiontaking_1_old = autolivepositiontaking, @isauto_spositiontaking_1_old = isautopositiontaking, @isauto_slivepositiontaking_1_old = isautolivepositiontaking  from custsetting with (NOLOCK) where custid = @custid and bettype=1 and sporttype=1
	select @spositiontaking_3_old = spositiontaking, @slivepositiontaking_3_old = slivepositiontaking, @mpositiontaking_3_old = mpositiontaking, @mlivepositiontaking_3_old = mlivepositiontaking, @auto_spositiontaking_3_old = autopositiontaking, @auto_slivepositiontaking_3_old = autolivepositiontaking, @isauto_spositiontaking_3_old = isautopositiontaking, @isauto_slivepositiontaking_3_old = isautolivepositiontaking  from custsetting with (NOLOCK) where custid = @custid and bettype=3 and sporttype=1
	select @spositiontaking_7_old = spositiontaking, @slivepositiontaking_7_old = slivepositiontaking, @mpositiontaking_7_old = mpositiontaking, @mlivepositiontaking_7_old = mlivepositiontaking, @auto_spositiontaking_7_old = autopositiontaking, @auto_slivepositiontaking_7_old = autolivepositiontaking, @isauto_spositiontaking_7_old = isautopositiontaking, @isauto_slivepositiontaking_7_old = isautolivepositiontaking  from custsetting with (NOLOCK) where custid = @custid and bettype=7 and sporttype=1
	select @spositiontaking_8_old = spositiontaking, @slivepositiontaking_8_old = slivepositiontaking, @mpositiontaking_8_old = mpositiontaking, @mlivepositiontaking_8_old = mlivepositiontaking, @auto_spositiontaking_8_old = autopositiontaking, @auto_slivepositiontaking_8_old = autolivepositiontaking, @isauto_spositiontaking_8_old = isautopositiontaking, @isauto_slivepositiontaking_8_old = isautolivepositiontaking  from custsetting with (NOLOCK) where custid = @custid and bettype=8 and sporttype=1
	select @spositiontaking_2_old = spositiontaking, @mpositiontaking_2_old = mpositiontaking, @auto_spositiontaking_2_old = autopositiontaking, @isauto_spositiontaking_2_old = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=2 and sporttype=1
	select @spositiontaking_4_old = spositiontaking, @mpositiontaking_4_old = mpositiontaking, @auto_spositiontaking_4_old = autopositiontaking, @isauto_spositiontaking_4_old = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=4 and sporttype=1

	select @spositiontaking_5_old = spositiontaking, @mpositiontaking_5_old = mpositiontaking, @auto_spositiontaking_5_old = autopositiontaking, @isauto_spositiontaking_5_old = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=5 and sporttype=1
	select @spositiontaking_6_old = spositiontaking, @mpositiontaking_6_old = mpositiontaking, @auto_spositiontaking_6_old = autopositiontaking, @isauto_spositiontaking_6_old = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=6 and sporttype=1
	select @spositiontaking_9_old = spositiontaking, @mpositiontaking_9_old = mpositiontaking, @auto_spositiontaking_9_old = autopositiontaking, @isauto_spositiontaking_9_old = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=9 and sporttype=1
	select @spositiontaking_10_old = spositiontaking, @mpositiontaking_10_old = mpositiontaking, @auto_spositiontaking_10_old = autopositiontaking, @isauto_spositiontaking_10_old = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=10 and sporttype=1

	select @v2spositiontaking_1_old = spositiontaking, @v2mpositiontaking_1_old = mpositiontaking, @auto_v2spositiontaking_1_old = autopositiontaking, @isauto_v2spositiontaking_1_old = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=1 and sporttype=2
	select @v2spositiontaking_2_old = spositiontaking, @v2mpositiontaking_2_old = mpositiontaking, @auto_v2spositiontaking_2_old = autopositiontaking, @isauto_v2spositiontaking_2_old = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=2 and sporttype=2
	select @v2spositiontaking_3_old = spositiontaking, @v2mpositiontaking_3_old = mpositiontaking, @auto_v2spositiontaking_3_old = autopositiontaking, @isauto_v2spositiontaking_3_old = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=3 and sporttype=2
	select @v2spositiontaking_7_old = spositiontaking, @v2mpositiontaking_7_old = mpositiontaking, @auto_v2spositiontaking_7_old = autopositiontaking, @isauto_v2spositiontaking_7_old = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=7 and sporttype=2
	select @v2spositiontaking_8_old = spositiontaking, @v2mpositiontaking_8_old = mpositiontaking, @auto_v2spositiontaking_8_old = autopositiontaking, @isauto_v2spositiontaking_8_old = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=8 and sporttype=2
	select @v2spositiontaking_9_old = spositiontaking, @v2mpositiontaking_9_old = mpositiontaking, @auto_v2spositiontaking_9_old = autopositiontaking, @isauto_v2spositiontaking_9_old = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=9 and sporttype=2
	select @v2spositiontaking_20_old = spositiontaking, @v2mpositiontaking_20_old = mpositiontaking, @auto_v2spositiontaking_20_old = autopositiontaking, @isauto_v2spositiontaking_20_old = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=20 and sporttype=2

	select @v3spositiontaking_1_old = spositiontaking, @v3mpositiontaking_1_old = mpositiontaking, @auto_v3spositiontaking_1_old = autopositiontaking, @isauto_v3spositiontaking_1_old = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=1 and sporttype=3
	select @v3spositiontaking_2_old = spositiontaking, @v3mpositiontaking_2_old = mpositiontaking, @auto_v3spositiontaking_2_old = autopositiontaking, @isauto_v3spositiontaking_2_old = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=2 and sporttype=3
	select @v3spositiontaking_3_old = spositiontaking, @v3mpositiontaking_3_old = mpositiontaking, @auto_v3spositiontaking_3_old = autopositiontaking, @isauto_v3spositiontaking_3_old = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=3 and sporttype=3
	select @v3spositiontaking_20_old = spositiontaking, @v3mpositiontaking_20_old = mpositiontaking, @auto_v3spositiontaking_20_old = autopositiontaking, @isauto_v3spositiontaking_20_old = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=20 and sporttype=3

	select @v5spositiontaking_1_old = spositiontaking, @v5mpositiontaking_1_old = mpositiontaking, @auto_v5spositiontaking_1_old = autopositiontaking, @isauto_v5spositiontaking_1_old = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=1 and sporttype=5
	select @v5spositiontaking_2_old = spositiontaking, @v5mpositiontaking_2_old = mpositiontaking, @auto_v5spositiontaking_2_old = autopositiontaking, @isauto_v5spositiontaking_2_old = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=2 and sporttype=5
	select @v5spositiontaking_3_old = spositiontaking, @v5mpositiontaking_3_old = mpositiontaking, @auto_v5spositiontaking_3_old = autopositiontaking, @isauto_v5spositiontaking_3_old = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=3 and sporttype=5
	select @v5spositiontaking_20_old = spositiontaking, @v5mpositiontaking_20_old = mpositiontaking, @auto_v5spositiontaking_20_old = autopositiontaking, @isauto_v5spositiontaking_20_old = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=20 and sporttype=5

	select @v8spositiontaking_1_old = spositiontaking, @v8mpositiontaking_1_old = mpositiontaking, @auto_v8spositiontaking_1_old = autopositiontaking, @isauto_v8spositiontaking_1_old = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=1 and sporttype=8
	select @v8spositiontaking_3_old = spositiontaking, @v8mpositiontaking_3_old = mpositiontaking, @auto_v8spositiontaking_3_old = autopositiontaking, @isauto_v8spositiontaking_3_old = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=3 and sporttype=8
	select @v8spositiontaking_20_old = spositiontaking, @v8mpositiontaking_20_old = mpositiontaking, @auto_v8spositiontaking_20_old = autopositiontaking, @isauto_v8spositiontaking_20_old = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=20 and sporttype=8

	select @v10spositiontaking_1_old = spositiontaking, @v10mpositiontaking_1_old = mpositiontaking, @auto_v10spositiontaking_1_old = autopositiontaking, @isauto_v10spositiontaking_1_old = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=1 and sporttype=10
	select @v10spositiontaking_2_old = spositiontaking, @v10mpositiontaking_2_old = mpositiontaking, @auto_v10spositiontaking_2_old = autopositiontaking, @isauto_v10spositiontaking_2_old = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=2 and sporttype=10
	select @v10spositiontaking_3_old = spositiontaking, @v10mpositiontaking_3_old = mpositiontaking, @auto_v10spositiontaking_3_old = autopositiontaking, @isauto_v10spositiontaking_3_old = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=3 and sporttype=10
	select @v10spositiontaking_20_old = spositiontaking, @v10mpositiontaking_20_old = mpositiontaking, @auto_v10spositiontaking_20_old = autopositiontaking, @isauto_v10spositiontaking_20_old = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=20 and sporttype=10

	select @v11spositiontaking_1_old = spositiontaking, @v11mpositiontaking_1_old = mpositiontaking, @auto_v11spositiontaking_1_old = autopositiontaking, @isauto_v11spositiontaking_1_old = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=1 and sporttype=11
	select @v11spositiontaking_20_old = spositiontaking, @v11mpositiontaking_20_old = mpositiontaking, @auto_v11spositiontaking_20_old = autopositiontaking, @isauto_v11spositiontaking_20_old = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=20 and sporttype=11

	select @v99spositiontaking_1_old = spositiontaking, @v99mpositiontaking_1_old = mpositiontaking, @auto_v99spositiontaking_1_old = autopositiontaking, @isauto_v99spositiontaking_1_old = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=1 and sporttype=99
	select @v99spositiontaking_2_old = spositiontaking, @v99mpositiontaking_2_old = mpositiontaking, @auto_v99spositiontaking_2_old = autopositiontaking, @isauto_v99spositiontaking_2_old = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=2 and sporttype=99
	select @v99spositiontaking_3_old = spositiontaking, @v99mpositiontaking_3_old = mpositiontaking, @auto_v99spositiontaking_3_old = autopositiontaking, @isauto_v99spositiontaking_3_old = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=3 and sporttype=99
	select @v99spositiontaking_20_old = spositiontaking, @v99mpositiontaking_20_old = mpositiontaking, @auto_v99spositiontaking_20_old = autopositiontaking, @isauto_v99spositiontaking_20_old = isautopositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=20 and sporttype=99
	--Check Old_PT <> New_PT
	IF	@spositiontaking_1 <> @spositiontaking_1_old or
		@spositiontaking_2 <> @spositiontaking_2_old or
		@spositiontaking_3 <> @spositiontaking_3_old or
		@spositiontaking_4 <> @spositiontaking_4_old or
		@spositiontaking_5 <> @spositiontaking_5_old or
		@spositiontaking_6 <> @spositiontaking_6_old or
		@spositiontaking_7 <> @spositiontaking_7_old or
		@spositiontaking_8 <> @spositiontaking_8_old or
		@spositiontaking_9 <> @spositiontaking_9_old or
		@spositiontaking_10 <> @spositiontaking_10_old or
		@slivepositiontaking_1 <> @slivepositiontaking_1_old or
		@slivepositiontaking_3 <> @slivepositiontaking_3_old or
		@slivepositiontaking_7 <> @slivepositiontaking_7_old or
		@slivepositiontaking_8 <> @slivepositiontaking_8_old or
		
		@v2spositiontaking_1 <> @v2spositiontaking_1_old or
		@v2spositiontaking_2 <> @v2spositiontaking_2_old or
		@v2spositiontaking_3 <> @v2spositiontaking_3_old or
		@v2spositiontaking_7 <> @v2spositiontaking_7_old or
		@v2spositiontaking_8 <> @v2spositiontaking_8_old or
		@v2spositiontaking_9 <> @v2spositiontaking_9_old or
		@v2spositiontaking_20 <> @v2spositiontaking_20_old or
		
		@v3spositiontaking_1 <> @v3spositiontaking_1_old or
		@v3spositiontaking_2 <> @v3spositiontaking_2_old or
		@v3spositiontaking_3 <> @v3spositiontaking_3_old or
		@v3spositiontaking_20 <> @v3spositiontaking_20_old or
		
		@v5spositiontaking_1 <> @v5spositiontaking_1_old or
		@v5spositiontaking_2 <> @v5spositiontaking_2_old or
		@v5spositiontaking_3 <> @v5spositiontaking_3_old or
		@v5spositiontaking_20 <> @v5spositiontaking_20_old or
		
		@v8spositiontaking_1 <> @v8spositiontaking_1_old or
		@v8spositiontaking_3 <> @v8spositiontaking_3_old or
		@v8spositiontaking_20 <> @v8spositiontaking_20_old or
		
		@v10spositiontaking_1 <> @v10spositiontaking_1_old or
		@v10spositiontaking_2 <> @v10spositiontaking_2_old or
		@v10spositiontaking_3 <> @v10spositiontaking_3_old or
		@v10spositiontaking_20 <> @v10spositiontaking_20_old or
		
		@v11spositiontaking_1 <> @v11spositiontaking_1_old or
		@v11spositiontaking_20 <> @v11spositiontaking_20_old or

		@v99spositiontaking_1 <> @v99spositiontaking_1_old or
		@v99spositiontaking_2 <> @v99spositiontaking_2_old or
		@v99spositiontaking_3 <> @v99spositiontaking_3_old or
		@v99spositiontaking_20 <> @v99spositiontaking_20_old or
		
		@auto_spositiontaking_1 <> @auto_spositiontaking_1_old or
		@auto_spositiontaking_2 <> @auto_spositiontaking_2_old or
		@auto_spositiontaking_3 <> @auto_spositiontaking_3_old or
		@auto_spositiontaking_4 <> @auto_spositiontaking_4_old or
		@auto_spositiontaking_5 <> @auto_spositiontaking_5_old or
		@auto_spositiontaking_6 <> @auto_spositiontaking_6_old or
		@auto_spositiontaking_7 <> @auto_spositiontaking_7_old or
		@auto_spositiontaking_8 <> @auto_spositiontaking_8_old or
		@auto_spositiontaking_9 <> @auto_spositiontaking_9_old or
		@auto_spositiontaking_10 <> @auto_spositiontaking_10_old or
		@auto_slivepositiontaking_1 <> @auto_slivepositiontaking_1_old or
		@auto_slivepositiontaking_3 <> @auto_slivepositiontaking_3_old or
		@auto_slivepositiontaking_7 <> @auto_slivepositiontaking_7_old or
		@auto_slivepositiontaking_8 <> @auto_slivepositiontaking_8_old or
		
		@auto_v2spositiontaking_1 <> @auto_v2spositiontaking_1_old or
		@auto_v2spositiontaking_2 <> @auto_v2spositiontaking_2_old or
		@auto_v2spositiontaking_3 <> @auto_v2spositiontaking_3_old or
		@auto_v2spositiontaking_7 <> @auto_v2spositiontaking_7_old or
		@auto_v2spositiontaking_8 <> @auto_v2spositiontaking_8_old or
		@auto_v2spositiontaking_9 <> @auto_v2spositiontaking_9_old or
		@auto_v2spositiontaking_20 <> @auto_v2spositiontaking_20_old or
		
		@auto_v3spositiontaking_1 <> @auto_v3spositiontaking_1_old or
		@auto_v3spositiontaking_2 <> @auto_v3spositiontaking_2_old or
		@auto_v3spositiontaking_3 <> @auto_v3spositiontaking_3_old or
		@auto_v3spositiontaking_20 <> @auto_v3spositiontaking_20_old or
		
		@auto_v5spositiontaking_1 <> @auto_v5spositiontaking_1_old or
		@auto_v5spositiontaking_2 <> @auto_v5spositiontaking_2_old or
		@auto_v5spositiontaking_3 <> @auto_v5spositiontaking_3_old or
		@auto_v5spositiontaking_20 <> @auto_v5spositiontaking_20_old or
		
		@auto_v8spositiontaking_1 <> @auto_v8spositiontaking_1_old or
		@auto_v8spositiontaking_3 <> @auto_v8spositiontaking_3_old or
		@auto_v8spositiontaking_20 <> @auto_v8spositiontaking_20_old or
		
		@auto_v10spositiontaking_1 <> @auto_v10spositiontaking_1_old or
		@auto_v10spositiontaking_2 <> @auto_v10spositiontaking_2_old or
		@auto_v10spositiontaking_3 <> @auto_v10spositiontaking_3_old or
		@auto_v10spositiontaking_20 <> @auto_v10spositiontaking_20_old or
		
		@auto_v11spositiontaking_1 <> @auto_v11spositiontaking_1_old or
		@auto_v11spositiontaking_20 <> @auto_v11spositiontaking_20_old or

		@auto_v99spositiontaking_1 <> @auto_v99spositiontaking_1_old or
		@auto_v99spositiontaking_2 <> @auto_v99spositiontaking_2_old or
		@auto_v99spositiontaking_3 <> @auto_v99spositiontaking_3_old or
		@auto_v99spositiontaking_20 <> @auto_v99spositiontaking_20_old or

		@isauto_spositiontaking_1 <> @isauto_spositiontaking_1_old or
		@isauto_spositiontaking_2 <> @isauto_spositiontaking_2_old or
		@isauto_spositiontaking_3 <> @isauto_spositiontaking_3_old or
		@isauto_spositiontaking_4 <> @isauto_spositiontaking_4_old or
		@isauto_spositiontaking_5 <> @isauto_spositiontaking_5_old or
		@isauto_spositiontaking_6 <> @isauto_spositiontaking_6_old or
		@isauto_spositiontaking_7 <> @isauto_spositiontaking_7_old or
		@isauto_spositiontaking_8 <> @isauto_spositiontaking_8_old or
		@isauto_spositiontaking_9 <> @isauto_spositiontaking_9_old or
		@isauto_spositiontaking_10 <> @isauto_spositiontaking_10_old or
		@isauto_slivepositiontaking_1 <> @isauto_slivepositiontaking_1_old or
		@isauto_slivepositiontaking_3 <> @isauto_slivepositiontaking_3_old or
		@isauto_slivepositiontaking_7 <> @isauto_slivepositiontaking_7_old or
		@isauto_slivepositiontaking_8 <> @isauto_slivepositiontaking_8_old or

		@isauto_v2spositiontaking_1 <> @isauto_v2spositiontaking_1_old or
		@isauto_v2spositiontaking_2 <> @isauto_v2spositiontaking_2_old or
		@isauto_v2spositiontaking_3 <> @isauto_v2spositiontaking_3_old or
		@isauto_v2spositiontaking_7 <> @isauto_v2spositiontaking_7_old or
		@isauto_v2spositiontaking_8 <> @isauto_v2spositiontaking_8_old or
		@isauto_v2spositiontaking_9 <> @isauto_v2spositiontaking_9_old or
		@isauto_v2spositiontaking_20 <> @isauto_v2spositiontaking_20_old or

		@isauto_v3spositiontaking_1 <> @isauto_v3spositiontaking_1_old or
		@isauto_v3spositiontaking_2 <> @isauto_v3spositiontaking_2_old or
		@isauto_v3spositiontaking_3 <> @isauto_v3spositiontaking_3_old or
		@isauto_v3spositiontaking_20 <> @isauto_v3spositiontaking_20_old or

		@isauto_v5spositiontaking_1 <> @isauto_v5spositiontaking_1_old or
		@isauto_v5spositiontaking_2 <> @isauto_v5spositiontaking_2_old or
		@isauto_v5spositiontaking_3 <> @isauto_v5spositiontaking_3_old or
		@isauto_v5spositiontaking_20 <> @isauto_v5spositiontaking_20_old or

		@isauto_v8spositiontaking_1 <> @isauto_v8spositiontaking_1_old or
		@isauto_v8spositiontaking_3 <> @isauto_v8spositiontaking_3_old or
		@isauto_v8spositiontaking_20 <> @isauto_v8spositiontaking_20_old or

		@isauto_v10spositiontaking_1 <> @isauto_v10spositiontaking_1_old or
		@isauto_v10spositiontaking_2 <> @isauto_v10spositiontaking_2_old or
		@isauto_v10spositiontaking_3 <> @isauto_v10spositiontaking_3_old or
		@isauto_v10spositiontaking_20 <> @isauto_v10spositiontaking_20_old or

		@isauto_v11spositiontaking_1 <> @isauto_v11spositiontaking_1_old or
		@isauto_v11spositiontaking_20 <> @isauto_v11spositiontaking_20_old or

		@isauto_v99spositiontaking_1 <> @isauto_v99spositiontaking_1_old or
		@isauto_v99spositiontaking_2 <> @isauto_v99spositiontaking_2_old or
		@isauto_v99spositiontaking_3 <> @isauto_v99spositiontaking_3_old or
		@isauto_v99spositiontaking_20 <> @isauto_v99spositiontaking_20_old or

		@mpositiontaking_1 <> @mpositiontaking_1_old or
		@mpositiontaking_2 <> @mpositiontaking_2_old or
		@mpositiontaking_3 <> @mpositiontaking_3_old or
		@mpositiontaking_4 <> @mpositiontaking_4_old or
		@mpositiontaking_5 <> @mpositiontaking_5_old or
		@mpositiontaking_6 <> @mpositiontaking_6_old or
		@mpositiontaking_7 <> @mpositiontaking_7_old or
		@mpositiontaking_8 <> @mpositiontaking_8_old or
		@mpositiontaking_9 <> @mpositiontaking_9_old or
		@mpositiontaking_10 <> @mpositiontaking_10_old or
		@mlivepositiontaking_1 <> @mlivepositiontaking_1_old or
		@mlivepositiontaking_3 <> @mlivepositiontaking_3_old or
		@mlivepositiontaking_7 <> @mlivepositiontaking_7_old or
		@mlivepositiontaking_8 <> @mlivepositiontaking_8_old or

		@v2mpositiontaking_1 <> @v2mpositiontaking_1_old or
		@v2mpositiontaking_2 <> @v2mpositiontaking_2_old or
		@v2mpositiontaking_3 <> @v2mpositiontaking_3_old or
		@v2mpositiontaking_7 <> @v2mpositiontaking_7_old or
		@v2mpositiontaking_8 <> @v2mpositiontaking_8_old or
		@v2mpositiontaking_9 <> @v2mpositiontaking_9_old or
		@v2mpositiontaking_20 <> @v2mpositiontaking_20_old or

		@v3mpositiontaking_1 <> @v3mpositiontaking_1_old or
		@v3mpositiontaking_2 <> @v3mpositiontaking_2_old or
		@v3mpositiontaking_3 <> @v3mpositiontaking_3_old or
		@v3mpositiontaking_20 <> @v3mpositiontaking_20_old or

		@v5mpositiontaking_1 <> @v5mpositiontaking_1_old or
		@v5mpositiontaking_2 <> @v5mpositiontaking_2_old or
		@v5mpositiontaking_3 <> @v5mpositiontaking_3_old or
		@v5mpositiontaking_20 <> @v5mpositiontaking_20_old or

		@v8mpositiontaking_1 <> @v8mpositiontaking_1_old or
		@v8mpositiontaking_3 <> @v8mpositiontaking_3_old or
		@v8mpositiontaking_20 <> @v8mpositiontaking_20_old or

		@v10mpositiontaking_1 <> @v10mpositiontaking_1_old or
		@v10mpositiontaking_2 <> @v10mpositiontaking_2_old or
		@v10mpositiontaking_3 <> @v10mpositiontaking_3_old or
		@v10mpositiontaking_20 <> @v10mpositiontaking_20_old or

		@v11mpositiontaking_1 <> @v11mpositiontaking_1_old or
		@v11mpositiontaking_20 <> @v11mpositiontaking_20_old or

		@v99mpositiontaking_1 <> @v99mpositiontaking_1_old or
		@v99mpositiontaking_2 <> @v99mpositiontaking_2_old or
		@v99mpositiontaking_3 <> @v99mpositiontaking_3_old or
		@v99mpositiontaking_20 <> @v99mpositiontaking_20_old
	BEGIN
		EXEC dbo.Acc_CustomerUpdMaster_PositionTaking 
			@custid = @custid,
			@spositiontaking_1 = @spositiontaking_1,
			@spositiontaking_2 = @spositiontaking_2,
			@spositiontaking_3 = @spositiontaking_3,
			@spositiontaking_4 = @spositiontaking_4,
			@spositiontaking_5 = @spositiontaking_5,
			@spositiontaking_6 = @spositiontaking_6,
			@spositiontaking_7 = @spositiontaking_7,
			@spositiontaking_8 = @spositiontaking_8,
			@spositiontaking_9 = @spositiontaking_9,
			@spositiontaking_10 = @spositiontaking_10,
			@slivepositiontaking_1 = @slivepositiontaking_1,
			@slivepositiontaking_3 = @slivepositiontaking_3,
			@slivepositiontaking_7 = @slivepositiontaking_7,
			@slivepositiontaking_8 = @slivepositiontaking_8,
			@v2spositiontaking_1 = @v2spositiontaking_1,
			@v2spositiontaking_2 = @v2spositiontaking_2,
			@v2spositiontaking_3 = @v2spositiontaking_3,
			@v2spositiontaking_7 = @v2spositiontaking_7,
			@v2spositiontaking_8 = @v2spositiontaking_8,
			@v2spositiontaking_9 = @v2spositiontaking_9,
			@v2spositiontaking_20 = @v2spositiontaking_20,
			@v3spositiontaking_1 = @v3spositiontaking_1,
			@v3spositiontaking_2 = @v3spositiontaking_2,
			@v3spositiontaking_3 = @v3spositiontaking_3,
			@v3spositiontaking_20 = @v3spositiontaking_20,
			@v5spositiontaking_1 = @v5spositiontaking_1,
			@v5spositiontaking_2 = @v5spositiontaking_2,
			@v5spositiontaking_3 = @v5spositiontaking_3,
			@v5spositiontaking_20 = @v5spositiontaking_20,
			@v8spositiontaking_1 = @v8spositiontaking_1,
			@v8spositiontaking_3 = @v8spositiontaking_3,
			@v8spositiontaking_20 = @v8spositiontaking_20,
			@v10spositiontaking_1 = @v10spositiontaking_1,
			@v10spositiontaking_2 = @v10spositiontaking_2,
			@v10spositiontaking_3 = @v10spositiontaking_3,
			@v10spositiontaking_20 = @v10spositiontaking_20,
			@v11spositiontaking_1 = @v11spositiontaking_1,
			@v11spositiontaking_20 = @v11spositiontaking_20,

			@v99spositiontaking_1 = @v99spositiontaking_1,
			@v99spositiontaking_2 = @v99spositiontaking_2,
			@v99spositiontaking_3 = @v99spositiontaking_3,
			@v99spositiontaking_20 = @v99spositiontaking_20,
			@UpdateMultiple = @UpdateMultiple,
			@UpdatePositiontaking = @UpdatePositiontaking,
			@UpdatePositiontakingv2 = @UpdatePositiontakingv2,
			@UpdatePositiontakingv3 = @UpdatePositiontakingv3,
			@UpdatePositiontakingv5 = @UpdatePositiontakingv5,
			@UpdatePositiontakingv8 = @UpdatePositiontakingv8,
			@UpdatePositiontakingv10 = @UpdatePositiontakingv10,
			@UpdatePositiontakingv11 = @UpdatePositiontakingv11,
			
			@UpdatePositiontakingv99 = @UpdatePositiontakingv99,
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
			@updateallmembers = @updateallmembers,
			@newspositiontaking = @newspositiontaking,
			@isauto_spositiontaking_1 = @isauto_spositiontaking_1,
			@isauto_spositiontaking_2 = @isauto_spositiontaking_2,
			@isauto_spositiontaking_3 = @isauto_spositiontaking_3,
			@isauto_spositiontaking_4 = @isauto_spositiontaking_4,
			@isauto_spositiontaking_5 = @isauto_spositiontaking_5,
			@isauto_spositiontaking_6 = @isauto_spositiontaking_6,
			@isauto_spositiontaking_7 = @isauto_spositiontaking_7,
			@isauto_spositiontaking_8 = @isauto_spositiontaking_8,
			@isauto_spositiontaking_9 = @isauto_spositiontaking_9,
			@isauto_spositiontaking_10 = @isauto_spositiontaking_10,
			@isauto_slivepositiontaking_1 = @isauto_slivepositiontaking_1,
			@isauto_slivepositiontaking_3 = @isauto_slivepositiontaking_3,
			@isauto_slivepositiontaking_7 = @isauto_slivepositiontaking_7,
			@isauto_slivepositiontaking_8 = @isauto_slivepositiontaking_8,
			@isauto_v2spositiontaking_1 = @isauto_v2spositiontaking_1,
			@isauto_v2spositiontaking_2 = @isauto_v2spositiontaking_2,
			@isauto_v2spositiontaking_3 = @isauto_v2spositiontaking_3,
			@isauto_v2spositiontaking_7 = @isauto_v2spositiontaking_7,
			@isauto_v2spositiontaking_8 = @isauto_v2spositiontaking_8,
			@isauto_v2spositiontaking_9 = @isauto_v2spositiontaking_9,
			@isauto_v2spositiontaking_20 = @isauto_v2spositiontaking_20,
			@isauto_v3spositiontaking_1 = @isauto_v3spositiontaking_1,
			@isauto_v3spositiontaking_2 = @isauto_v3spositiontaking_2,
			@isauto_v3spositiontaking_3 = @isauto_v3spositiontaking_3,
			@isauto_v3spositiontaking_20 = @isauto_v3spositiontaking_20,
			@isauto_v5spositiontaking_1 = @isauto_v5spositiontaking_1,
			@isauto_v5spositiontaking_2 = @isauto_v5spositiontaking_2,
			@isauto_v5spositiontaking_3 = @isauto_v5spositiontaking_3,
			@isauto_v5spositiontaking_20 = @isauto_v5spositiontaking_20,
			@isauto_v8spositiontaking_1 = @isauto_v8spositiontaking_1,
			@isauto_v8spositiontaking_3 = @isauto_v8spositiontaking_3,
			@isauto_v8spositiontaking_20 = @isauto_v8spositiontaking_20,
			@isauto_v10spositiontaking_1 = @isauto_v10spositiontaking_1,
			@isauto_v10spositiontaking_2 = @isauto_v10spositiontaking_2,
			@isauto_v10spositiontaking_3 = @isauto_v10spositiontaking_3,
			@isauto_v10spositiontaking_20 = @isauto_v10spositiontaking_20,
			@isauto_v11spositiontaking_1 = @isauto_v11spositiontaking_1,
			@isauto_v11spositiontaking_20 = @isauto_v11spositiontaking_20,

			@isauto_v99spositiontaking_1 = @isauto_v99spositiontaking_1,
			@isauto_v99spositiontaking_2 = @isauto_v99spositiontaking_2,
			@isauto_v99spositiontaking_3 = @isauto_v99spositiontaking_3,
			@isauto_v99spositiontaking_20 = @isauto_v99spositiontaking_20,
			@mpositiontaking_1 = @mpositiontaking_1,
			@mpositiontaking_2 = @mpositiontaking_2,
			@mpositiontaking_3 = @mpositiontaking_3,
			@mpositiontaking_4 = @mpositiontaking_4,
			@mpositiontaking_5 = @mpositiontaking_5,
			@mpositiontaking_6 = @mpositiontaking_6,
			@mpositiontaking_7 = @mpositiontaking_7,
			@mpositiontaking_8 = @mpositiontaking_8,
			@mpositiontaking_9 = @mpositiontaking_9,
			@mpositiontaking_10 = @mpositiontaking_10,
			@mlivepositiontaking_1 = @mlivepositiontaking_1,
			@mlivepositiontaking_3 = @mlivepositiontaking_3,
			@mlivepositiontaking_7 = @mlivepositiontaking_7,
			@mlivepositiontaking_8 = @mlivepositiontaking_8,
			@v2mpositiontaking_1 = @v2mpositiontaking_1,
			@v2mpositiontaking_2 = @v2mpositiontaking_2,
			@v2mpositiontaking_3 = @v2mpositiontaking_3,
			@v2mpositiontaking_7 = @v2mpositiontaking_7,
			@v2mpositiontaking_8 = @v2mpositiontaking_8,
			@v2mpositiontaking_9 = @v2mpositiontaking_9,
			@v2mpositiontaking_20 = @v2mpositiontaking_20,
			@v3mpositiontaking_1 = @v3mpositiontaking_1,
			@v3mpositiontaking_2 = @v3mpositiontaking_2,
			@v3mpositiontaking_3 = @v3mpositiontaking_3,
			@v3mpositiontaking_20 = @v3mpositiontaking_20,
			@v5mpositiontaking_1 = @v5mpositiontaking_1,
			@v5mpositiontaking_2 = @v5mpositiontaking_2,
			@v5mpositiontaking_3 = @v5mpositiontaking_3,
			@v5mpositiontaking_20 = @v5mpositiontaking_20,
			@v8mpositiontaking_1 = @v8mpositiontaking_1,
			@v8mpositiontaking_3 = @v8mpositiontaking_3,
			@v8mpositiontaking_20 = @v8mpositiontaking_20,
			@v10mpositiontaking_1 = @v10mpositiontaking_1,
			@v10mpositiontaking_2 = @v10mpositiontaking_2,
			@v10mpositiontaking_3 = @v10mpositiontaking_3,
			@v10mpositiontaking_20 = @v10mpositiontaking_20,
			@v11mpositiontaking_1 = @v11mpositiontaking_1,
			@v11mpositiontaking_20 = @v11mpositiontaking_20,

			@v99mpositiontaking_1 = @v99mpositiontaking_1,
			@v99mpositiontaking_2 = @v99mpositiontaking_2,
			@v99mpositiontaking_3 = @v99mpositiontaking_3,
			@v99mpositiontaking_20 = @v99mpositiontaking_20,
			@SubAccID = @SubAccID,
			@UserID = @UserID,
			@Language = @Language,
			@IP = @IP,
			@ErrCode = @ErrCode_cur OUTPUT,
			@ErrMsg = @ErrMsg_Cur OUTPUT
	END
	IF @ErrCode_Cur > 0
	BEGIN
		select @ErrCode = @ErrCode + cast(@ErrCode_cur as varchar(300)) + char(7), 
				@ErrMsg = @ErrMsg + @ErrMsg_Cur + char(7)
		return
	END
	ELSE
	BEGIN
		Select @ErrCode = @ErrCode + '-107'+char(7), @ErrMsg = @ErrMsg + char(7)
	END
END

GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdMaster_All] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdMaster_All] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdMaster_All] TO vnteam