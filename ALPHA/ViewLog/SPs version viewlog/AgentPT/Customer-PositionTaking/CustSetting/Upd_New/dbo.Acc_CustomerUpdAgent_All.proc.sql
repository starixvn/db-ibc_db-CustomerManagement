ALTER PROCEDURE [dbo].[Acc_CustomerUpdAgent_All]
	@custid int,
	@firstname nvarchar(50),
	@lastname nvarchar(50),
	@phone nvarchar(50),
	@mobilephone nvarchar(50),
	@email nvarchar(50)='',
	@fax nvarchar(50),
	@groupa decimal(9,8),
	@groupb decimal(9,8),
	@groupc decimal(9,8),
	@groupd decimal(9,8),
	@discountcs decimal(9,8),
	@discount1x2 decimal(9,8)=0,	
	@closed bit,
	@Suspended bit,
	@disCasino bit = 0,	
	
	@mrecommend int,
	@MinBet money,
	@MaxBet money,
	@MaxPerMatch money,
	 
	@MinBetv2 money,
	@MaxBetv2 money,
	@MaxPerMatchv2 money,
	
	@MinBetv3 money,
	@MaxBetv3 money,
	@MaxPerMatchv3 money,

	@MinBetv5 money,
	@MaxBetv5 money,
	@MaxPerMatchv5 money,

	@MinBetv8 money,
	@MaxBetv8 money,
	@MaxPerMatchv8 money,

	@MinBetv10 money,
	@MaxBetv10 money,
	@MaxPerMatchv10 money,

	@MinBetv11 money,
	@MaxBetv11 money,
	@MaxPerMatchv11 money,

	@MinBetv99 money,
	@MaxBetv99 money,
	@MaxPerMatchv99 money,

	@credit money,
	@maxcredit money = null, -- max credit agent give member 
	@Language varchar(2) = 'E',
	@UpdateMultiple bit = 0,
	
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
	
	--Auto Master PT
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
	
	@UpdateCommission bit = 1,
	@UpdateMinMaxBet bit = 1,
	@UpdateMinMaxBetv2 bit = 1,
	@UpdateMinMaxBetv3 bit = 1,
	@UpdateMinMaxBetv5 bit = 1,
	@UpdateMinMaxBetv8 bit = 1,
	@UpdateMinMaxBetv10 bit = 1,
	@UpdateMinMaxBetv11 bit = 1,
	@UpdateMinMaxBetv99 bit = 1,
	
	@UpdatePositiontaking bit = 1 OUTPUT,
	@UpdatePositiontakingv2 bit = 1 OUTPUT,
	@UpdatePositiontakingv3 bit = 1 OUTPUT,
	@UpdatePositiontakingv5 bit = 1 OUTPUT,
	@UpdatePositiontakingv8 bit = 1 OUTPUT,
	@UpdatePositiontakingv10 bit = 1 OUTPUT,
	@UpdatePositiontakingv11 bit = 1 OUTPUT,
	@UpdatePositiontakingv99 bit = 1 OUTPUT,
	
	@updateallmembers bit = 0,
	@newmpositiontaking smallmoney = 0,--equals max(m+a) - chosen(a)
	
	@UpdateClosed bit = 1,	
	@UpdateSuspended BIT = 1,
	@SubAccID int = 0, --Sub-AccountID
	@UserID int,
	@IP varchar(15)='',
	
	@Username varchar(30) = '' OUTPUT,
	@ErrCode varchar(300) = '' OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
as
--@Source Control
/*
Created: 20080514@Thien
Task : Update Agent
DB: DB02.bodb02
Original: Acc_CustomerUpdEditCustomer_MAg

Revisions:
    - 20081023@Phuc: Add new sporttype 201, bettype 3, hard code copy min/max/maxperbet/PT for 201 from 2 sporttype 
    - 20090122@PhuongBich: add new sporttype 201, bettype 2.
	- 20090317@Phuc: update Financial
	- 20090320@PhuongDao: Change the param @IsUpdDownlineFI to @DisableDownlineFI
    - 20090424@Phuc:Separate finance sporttype(201).
    - 20090430@Kiwi: Add checking IF @UpdateSuspended = 1 for updating multiple customer.
	- 20090703@Phuc: enrich error message.(-101: general info, -102: closed, -103: suspended, 
						-104: credit, -105: commission, -106: min/max bet, -107: positiontaking
						-108: disable FI, -109: disableHR)
	- 20090801@Shifu: check disabled user
	- 20091125@Terry: check disabled Casino
Param's Explanation:
• @ErrCode:
    = 0: Update Agent successfully.
    > 0: Specific Error.
  
• @ErrMsg: Error description.
*/

SET NOCOUNT ON
--------------------------

---------------------------
-- ***Check Downline Belonging***
declare @roleid tinyint, @ErrCode_Cur int, @ErrMsg_Cur nvarchar(4000)
Select @ErrCode_Cur = 0, @ErrMsg_Cur = '', @ErrCode = '', @ErrMsg = ''

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
				@UserID = @UserID,
				@disCasino = @disCasino,
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
	EXEC dbo.Acc_CustomerUpdSuspended
				@CustID =@CustID,
				@Suspended =@Suspended,	
				@disCasino = @disCasino,
				@SubAccID =@SubAccID , 
				@UserID =@UserID,
				@Language =@Language,
				@ErrCode =@ErrCode_cur OUTPUT,
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

--Update credit
IF @UpdateMultiple = 0
BEGIN
	Select @ErrCode_Cur = 0, @ErrMsg_Cur = ''
	EXEC dbo.Acc_CustomerUpdCredit
		@custid = @custid,
		@NewCredit = @Credit,
		@maxcredit = @maxcredit,--Vinh@20081201: Add check and update max credit on member
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

	select @discountcs_old = discount
	from custsetting (nolock) where custid = @custid and sporttype = 1 and bettype = 4

	select @discount1x2_old = discount
	from custsetting (nolock) where custid = @custid and sporttype = 1 and bettype = 5


	if (@groupa_old <> @groupa) or (@groupb_old <> @groupb) or (@groupc_old <> @groupc) or (@groupd_old <> @groupd)
		or (@discountcs_old <> @discountcs) or (@discount1x2_old <> @discount1x2)
		set @updatecomm_old = 1
	else 
		set @updatecomm_old = 0
	if @updatecomm_old <> 0
	begin	
		
		EXEC dbo.Acc_CustomerUpdAgent_Commission 
			@custid = @custid,
			@groupa = @groupa,
			@groupb = @groupb,
			@groupc = @groupc,
			@groupd = @groupd,
			@discountcs = @discountcs,
			@discount1x2 = @discount1x2, --1x2 
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
		Select @ErrCode = @ErrCode + '-105' + char(7), @ErrMsg = @ErrMsg + char(7)
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
	EXEC dbo.Acc_CustomerUpdAgent_MinMaxBet
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
		@ErrCode = @ErrCode_Cur OUTPUT,
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
	Declare @apositiontaking_1_old smallmoney,
		@apositiontaking_2_old smallmoney,
		@apositiontaking_3_old smallmoney,
		@apositiontaking_4_old smallmoney,
		@apositiontaking_5_old smallmoney,
		@apositiontaking_6_old smallmoney,
		@apositiontaking_7_old smallmoney,
		@apositiontaking_8_old smallmoney,
		@apositiontaking_9_old smallmoney,
		@apositiontaking_10_old smallmoney,
		
		@mpositiontaking_1_old smallmoney,
		@mpositiontaking_2_old smallmoney,
		@mpositiontaking_3_old smallmoney,
		@mpositiontaking_4_old smallmoney,
		@mpositiontaking_5_old smallmoney,
		@mpositiontaking_6_old smallmoney,
		@mpositiontaking_7_old smallmoney,
		@mpositiontaking_8_old smallmoney,
		@mpositiontaking_9_old smallmoney,
		@mpositiontaking_10_old smallmoney,
		
		@alivepositiontaking_1_old smallmoney,
		@alivepositiontaking_3_old smallmoney,
		@alivepositiontaking_7_old smallmoney,
		@alivepositiontaking_8_old smallmoney,
		@mlivepositiontaking_1_old smallmoney,
		@mlivepositiontaking_3_old smallmoney,
		@mlivepositiontaking_7_old smallmoney,
		@mlivepositiontaking_8_old smallmoney,
		
		@v2apositiontaking_1_old smallmoney,
		@v2apositiontaking_2_old smallmoney,
		@v2apositiontaking_3_old smallmoney,
		@v2apositiontaking_7_old smallmoney,
		@v2apositiontaking_8_old smallmoney,
		@v2apositiontaking_9_old smallmoney,
		@v2apositiontaking_20_old smallmoney,

		@v3apositiontaking_1_old smallmoney,
		@v3apositiontaking_2_old smallmoney,
		@v3apositiontaking_3_old smallmoney,
		@v3apositiontaking_20_old smallmoney,

		@v5apositiontaking_1_old smallmoney,
		@v5apositiontaking_2_old smallmoney,
		@v5apositiontaking_3_old smallmoney,
		@v5apositiontaking_20_old smallmoney,

		@v8apositiontaking_1_old smallmoney,
		@v8apositiontaking_3_old smallmoney,
		@v8apositiontaking_20_old smallmoney,

		@v10apositiontaking_1_old smallmoney,
		@v10apositiontaking_2_old smallmoney,
		@v10apositiontaking_3_old smallmoney,
		@v10apositiontaking_20_old smallmoney,

		@v11apositiontaking_1_old smallmoney,
		@v11apositiontaking_20_old smallmoney,

		@v99apositiontaking_1_old smallmoney,
		@v99apositiontaking_2_old smallmoney,
		@v99apositiontaking_3_old smallmoney,
		@v99apositiontaking_20_old smallmoney,
		
		@v2mpositiontaking_1_old smallmoney,
		@v2mpositiontaking_2_old smallmoney,
		@v2mpositiontaking_3_old smallmoney,
		@v2mpositiontaking_7_old smallmoney,
		@v2mpositiontaking_8_old smallmoney,
		@v2mpositiontaking_9_old smallmoney,
		@v2mpositiontaking_20_old smallmoney,

		@v3mpositiontaking_1_old smallmoney,
		@v3mpositiontaking_2_old smallmoney,
		@v3mpositiontaking_3_old smallmoney,
		@v3mpositiontaking_20_old smallmoney,

		@v5mpositiontaking_1_old smallmoney,
		@v5mpositiontaking_2_old smallmoney,
		@v5mpositiontaking_3_old smallmoney,
		@v5mpositiontaking_20_old smallmoney,

		@v8mpositiontaking_1_old smallmoney,
		@v8mpositiontaking_3_old smallmoney,
		@v8mpositiontaking_20_old smallmoney,

		@v10mpositiontaking_1_old smallmoney,
		@v10mpositiontaking_2_old smallmoney,
		@v10mpositiontaking_3_old smallmoney,
		@v10mpositiontaking_20_old smallmoney,

		@v11mpositiontaking_1_old smallmoney,
		@v11mpositiontaking_20_old smallmoney,

		@v99mpositiontaking_1_old smallmoney,
		@v99mpositiontaking_2_old smallmoney,
		@v99mpositiontaking_3_old smallmoney,
		@v99mpositiontaking_20_old smallmoney,
		
		--Auto Master PT
		@auto_mpositiontaking_1_old smallmoney ,
		@auto_mpositiontaking_2_old smallmoney ,
		@auto_mpositiontaking_3_old smallmoney ,
		@auto_mpositiontaking_4_old smallmoney ,
		@auto_mpositiontaking_5_old smallmoney,
		@auto_mpositiontaking_6_old smallmoney ,
		@auto_mpositiontaking_7_old smallmoney ,
		@auto_mpositiontaking_8_old smallmoney ,
		@auto_mpositiontaking_9_old smallmoney ,
		@auto_mpositiontaking_10_old smallmoney ,
		@auto_mlivepositiontaking_1_old smallmoney ,
		@auto_mlivepositiontaking_3_old smallmoney ,
		@auto_mlivepositiontaking_7_old smallmoney ,
		@auto_mlivepositiontaking_8_old smallmoney ,
		
		@auto_v2mpositiontaking_1_old smallmoney ,
		@auto_v2mpositiontaking_2_old smallmoney ,
		@auto_v2mpositiontaking_3_old smallmoney ,
		@auto_v2mpositiontaking_7_old smallmoney ,
		@auto_v2mpositiontaking_8_old smallmoney ,
		@auto_v2mpositiontaking_9_old smallmoney ,
		@auto_v2mpositiontaking_20_old smallmoney ,
		
		@auto_v3mpositiontaking_1_old smallmoney ,
		@auto_v3mpositiontaking_2_old smallmoney ,
		@auto_v3mpositiontaking_3_old smallmoney ,
		@auto_v3mpositiontaking_20_old smallmoney ,
		
		@auto_v5mpositiontaking_1_old smallmoney ,
		@auto_v5mpositiontaking_2_old smallmoney ,
		@auto_v5mpositiontaking_3_old smallmoney ,
		@auto_v5mpositiontaking_20_old smallmoney ,
		
		@auto_v8mpositiontaking_1_old smallmoney ,
		@auto_v8mpositiontaking_3_old smallmoney ,
		@auto_v8mpositiontaking_20_old smallmoney ,
		
		@auto_v10mpositiontaking_1_old smallmoney ,
		@auto_v10mpositiontaking_2_old smallmoney ,
		@auto_v10mpositiontaking_3_old smallmoney ,
		@auto_v10mpositiontaking_20_old smallmoney ,
		
		@auto_v11mpositiontaking_1_old smallmoney ,
		@auto_v11mpositiontaking_20_old smallmoney ,

		@auto_v99mpositiontaking_1_old smallmoney ,
		@auto_v99mpositiontaking_2_old smallmoney ,
		@auto_v99mpositiontaking_3_old smallmoney ,
		@auto_v99mpositiontaking_20_old smallmoney ,	
		
		@isauto_mpositiontaking_1_old bit ,
		@isauto_mpositiontaking_2_old bit ,
		@isauto_mpositiontaking_3_old bit ,
		@isauto_mpositiontaking_4_old bit ,
		@isauto_mpositiontaking_5_old bit,
		@isauto_mpositiontaking_6_old bit ,
		@isauto_mpositiontaking_7_old bit ,
		@isauto_mpositiontaking_8_old bit ,
		@isauto_mpositiontaking_9_old bit ,
		@isauto_mpositiontaking_10_old bit ,
		@isauto_mlivepositiontaking_1_old bit ,
		@isauto_mlivepositiontaking_3_old bit ,
		@isauto_mlivepositiontaking_7_old bit ,
		@isauto_mlivepositiontaking_8_old bit ,
		
		@isauto_v2mpositiontaking_1_old bit ,
		@isauto_v2mpositiontaking_2_old bit ,
		@isauto_v2mpositiontaking_3_old bit ,
		@isauto_v2mpositiontaking_7_old bit ,
		@isauto_v2mpositiontaking_8_old bit ,
		@isauto_v2mpositiontaking_9_old bit ,
		@isauto_v2mpositiontaking_20_old bit ,
		
		@isauto_v3mpositiontaking_1_old bit ,
		@isauto_v3mpositiontaking_2_old bit ,
		@isauto_v3mpositiontaking_3_old bit ,
		@isauto_v3mpositiontaking_20_old bit ,
		
		@isauto_v5mpositiontaking_1_old bit ,
		@isauto_v5mpositiontaking_2_old bit ,
		@isauto_v5mpositiontaking_3_old bit ,
		@isauto_v5mpositiontaking_20_old bit ,
		
		@isauto_v8mpositiontaking_1_old bit ,
		@isauto_v8mpositiontaking_3_old bit ,
		@isauto_v8mpositiontaking_20_old bit ,
		
		@isauto_v10mpositiontaking_1_old bit ,
		@isauto_v10mpositiontaking_2_old bit ,
		@isauto_v10mpositiontaking_3_old bit ,
		@isauto_v10mpositiontaking_20_old bit ,
		
		@isauto_v11mpositiontaking_1_old bit ,
		@isauto_v11mpositiontaking_20_old bit ,
		
		@isauto_v99mpositiontaking_1_old bit ,
		@isauto_v99mpositiontaking_2_old bit ,
		@isauto_v99mpositiontaking_3_old bit ,
		@isauto_v99mpositiontaking_20_old bit
	--Get old PT m2,a2,u2,i2
	select @mpositiontaking_1_old = mpositiontaking, @mlivepositiontaking_1_old = mlivepositiontaking, @apositiontaking_1_old = apositiontaking, @alivepositiontaking_1_old = alivepositiontaking, @auto_mpositiontaking_1_old = autompositiontaking, @auto_mlivepositiontaking_1_old = autolivempositiontaking, @isauto_mpositiontaking_1_old = isautompositiontaking, @isauto_mlivepositiontaking_1_old = isautolivempositiontaking  from custsetting with (NOLOCK) where custid = @custid and bettype=1 and sporttype=1
	select @mpositiontaking_3_old = mpositiontaking, @mlivepositiontaking_3_old = mlivepositiontaking, @apositiontaking_3_old = apositiontaking, @alivepositiontaking_3_old = alivepositiontaking, @auto_mpositiontaking_3_old = autompositiontaking, @auto_mlivepositiontaking_3_old = autolivempositiontaking, @isauto_mpositiontaking_3_old = isautompositiontaking, @isauto_mlivepositiontaking_3_old = isautolivempositiontaking  from custsetting with (NOLOCK) where custid = @custid and bettype=3 and sporttype=1
	select @mpositiontaking_7_old = mpositiontaking, @mlivepositiontaking_7_old = mlivepositiontaking, @apositiontaking_7_old = apositiontaking, @alivepositiontaking_7_old = alivepositiontaking, @auto_mpositiontaking_7_old = autompositiontaking, @auto_mlivepositiontaking_7_old = autolivempositiontaking, @isauto_mpositiontaking_7_old = isautompositiontaking, @isauto_mlivepositiontaking_7_old = isautolivempositiontaking  from custsetting with (NOLOCK) where custid = @custid and bettype=7 and sporttype=1
	select @mpositiontaking_8_old = mpositiontaking, @mlivepositiontaking_8_old = mlivepositiontaking, @apositiontaking_8_old = apositiontaking, @alivepositiontaking_8_old = alivepositiontaking, @auto_mpositiontaking_8_old = autompositiontaking, @auto_mlivepositiontaking_8_old = autolivempositiontaking, @isauto_mpositiontaking_8_old = isautompositiontaking, @isauto_mlivepositiontaking_8_old = isautolivempositiontaking  from custsetting with (NOLOCK) where custid = @custid and bettype=8 and sporttype=1
	select @mpositiontaking_2_old = mpositiontaking, @apositiontaking_2_old = apositiontaking, @auto_mpositiontaking_2_old = autompositiontaking, @isauto_mpositiontaking_2_old = isautompositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=2 and sporttype=1
	select @mpositiontaking_4_old = mpositiontaking, @apositiontaking_4_old = apositiontaking, @auto_mpositiontaking_4_old = autompositiontaking, @isauto_mpositiontaking_4_old = isautompositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=4 and sporttype=1

	select @mpositiontaking_5_old = mpositiontaking, @apositiontaking_5_old = apositiontaking, @auto_mpositiontaking_5_old = autompositiontaking, @isauto_mpositiontaking_5_old = isautompositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=5 and sporttype=1
	select @mpositiontaking_6_old = mpositiontaking, @apositiontaking_6_old = apositiontaking, @auto_mpositiontaking_6_old = autompositiontaking, @isauto_mpositiontaking_6_old = isautompositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=6 and sporttype=1
	select @mpositiontaking_9_old = mpositiontaking, @apositiontaking_9_old = apositiontaking, @auto_mpositiontaking_9_old = autompositiontaking, @isauto_mpositiontaking_9_old = isautompositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=9 and sporttype=1
	select @mpositiontaking_10_old = mpositiontaking, @apositiontaking_10_old = apositiontaking, @auto_mpositiontaking_10_old = autompositiontaking, @isauto_mpositiontaking_10_old = isautompositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=10 and sporttype=1

	select @v2mpositiontaking_1_old = mpositiontaking, @v2apositiontaking_1_old = apositiontaking, @auto_v2mpositiontaking_1_old = autompositiontaking, @isauto_v2mpositiontaking_1_old = isautompositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=1 and sporttype=2
	select @v2mpositiontaking_2_old = mpositiontaking, @v2apositiontaking_2_old = apositiontaking, @auto_v2mpositiontaking_2_old = autompositiontaking, @isauto_v2mpositiontaking_2_old = isautompositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=2 and sporttype=2
	select @v2mpositiontaking_3_old = mpositiontaking, @v2apositiontaking_3_old = apositiontaking, @auto_v2mpositiontaking_3_old = autompositiontaking, @isauto_v2mpositiontaking_3_old = isautompositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=3 and sporttype=2
	select @v2mpositiontaking_7_old = mpositiontaking, @v2apositiontaking_7_old = apositiontaking, @auto_v2mpositiontaking_7_old = autompositiontaking, @isauto_v2mpositiontaking_7_old = isautompositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=7 and sporttype=2
	select @v2mpositiontaking_8_old = mpositiontaking, @v2apositiontaking_8_old = apositiontaking, @auto_v2mpositiontaking_8_old = autompositiontaking, @isauto_v2mpositiontaking_8_old = isautompositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=8 and sporttype=2
	select @v2mpositiontaking_9_old = mpositiontaking, @v2apositiontaking_9_old = apositiontaking, @auto_v2mpositiontaking_9_old = autompositiontaking, @isauto_v2mpositiontaking_9_old = isautompositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=9 and sporttype=2
	select @v2mpositiontaking_20_old = mpositiontaking, @v2apositiontaking_20_old = apositiontaking, @auto_v2mpositiontaking_20_old = autompositiontaking, @isauto_v2mpositiontaking_20_old = isautompositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=20 and sporttype=2

	select @v3mpositiontaking_1_old = mpositiontaking, @v3apositiontaking_1_old = apositiontaking, @auto_v3mpositiontaking_1_old = autompositiontaking, @isauto_v3mpositiontaking_1_old = isautompositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=1 and sporttype=3
	select @v3mpositiontaking_2_old = mpositiontaking, @v3apositiontaking_2_old = apositiontaking, @auto_v3mpositiontaking_2_old = autompositiontaking, @isauto_v3mpositiontaking_2_old = isautompositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=2 and sporttype=3
	select @v3mpositiontaking_3_old = mpositiontaking, @v3apositiontaking_3_old = apositiontaking, @auto_v3mpositiontaking_3_old = autompositiontaking, @isauto_v3mpositiontaking_3_old = isautompositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=3 and sporttype=3
	select @v3mpositiontaking_20_old = mpositiontaking, @v3apositiontaking_20_old = apositiontaking, @auto_v3mpositiontaking_20_old = autompositiontaking, @isauto_v3mpositiontaking_20_old = isautompositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=20 and sporttype=3

	select @v5mpositiontaking_1_old = mpositiontaking, @v5apositiontaking_1_old = apositiontaking, @auto_v5mpositiontaking_1_old = autompositiontaking, @isauto_v5mpositiontaking_1_old = isautompositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=1 and sporttype=5
	select @v5mpositiontaking_2_old = mpositiontaking, @v5apositiontaking_2_old = apositiontaking, @auto_v5mpositiontaking_2_old = autompositiontaking, @isauto_v5mpositiontaking_2_old = isautompositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=2 and sporttype=5
	select @v5mpositiontaking_3_old = mpositiontaking, @v5apositiontaking_3_old = apositiontaking, @auto_v5mpositiontaking_3_old = autompositiontaking, @isauto_v5mpositiontaking_3_old = isautompositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=3 and sporttype=5
	select @v5mpositiontaking_20_old = mpositiontaking, @v5apositiontaking_20_old = apositiontaking, @auto_v5mpositiontaking_20_old = autompositiontaking, @isauto_v5mpositiontaking_20_old = isautompositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=20 and sporttype=5

	select @v8mpositiontaking_1_old = mpositiontaking, @v8apositiontaking_1_old = apositiontaking, @auto_v8mpositiontaking_1_old = autompositiontaking, @isauto_v8mpositiontaking_1_old = isautompositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=1 and sporttype=8
	select @v8mpositiontaking_3_old = mpositiontaking, @v8apositiontaking_3_old = apositiontaking, @auto_v8mpositiontaking_3_old = autompositiontaking, @isauto_v8mpositiontaking_3_old = isautompositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=3 and sporttype=8
	select @v8mpositiontaking_20_old = mpositiontaking, @v8apositiontaking_20_old = apositiontaking, @auto_v8mpositiontaking_20_old = autompositiontaking, @isauto_v8mpositiontaking_20_old = isautompositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=20 and sporttype=8

	select @v10mpositiontaking_1_old = mpositiontaking, @v10apositiontaking_1_old = apositiontaking, @auto_v10mpositiontaking_1_old = autompositiontaking, @isauto_v10mpositiontaking_1_old = isautompositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=1 and sporttype=10
	select @v10mpositiontaking_2_old = mpositiontaking, @v10apositiontaking_2_old = apositiontaking, @auto_v10mpositiontaking_2_old = autompositiontaking, @isauto_v10mpositiontaking_2_old = isautompositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=2 and sporttype=10
	select @v10mpositiontaking_3_old = mpositiontaking, @v10apositiontaking_3_old = apositiontaking, @auto_v10mpositiontaking_3_old = autompositiontaking, @isauto_v10mpositiontaking_3_old = isautompositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=3 and sporttype=10
	select @v10mpositiontaking_20_old = mpositiontaking, @v10apositiontaking_20_old = apositiontaking, @auto_v10mpositiontaking_20_old = autompositiontaking, @isauto_v10mpositiontaking_20_old = isautompositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=20 and sporttype=10

	select @v11mpositiontaking_1_old = mpositiontaking, @v11apositiontaking_1_old = apositiontaking, @auto_v11mpositiontaking_1_old = autompositiontaking, @isauto_v11mpositiontaking_1_old = isautompositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=1 and sporttype=11
	select @v11mpositiontaking_20_old = mpositiontaking, @v11apositiontaking_20_old = apositiontaking, @auto_v11mpositiontaking_20_old = autompositiontaking, @isauto_v11mpositiontaking_20_old = isautompositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=20 and sporttype=11

	select @v99mpositiontaking_1_old = mpositiontaking, @v99apositiontaking_1_old = apositiontaking, @auto_v99mpositiontaking_1_old = autompositiontaking, @isauto_v99mpositiontaking_1_old = isautompositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=1 and sporttype=99
	select @v99mpositiontaking_2_old = mpositiontaking, @v99apositiontaking_2_old = apositiontaking, @auto_v99mpositiontaking_2_old = autompositiontaking, @isauto_v99mpositiontaking_2_old = isautompositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=2 and sporttype=99
	select @v99mpositiontaking_3_old = mpositiontaking, @v99apositiontaking_3_old = apositiontaking, @auto_v99mpositiontaking_3_old = autompositiontaking, @isauto_v99mpositiontaking_3_old = isautompositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=3 and sporttype=99
	select @v99mpositiontaking_20_old = mpositiontaking, @v99apositiontaking_20_old = apositiontaking, @auto_v99mpositiontaking_20_old = autompositiontaking, @isauto_v99mpositiontaking_20_old = isautompositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=20 and sporttype=99
	
	IF @apositiontaking_1 <> @apositiontaking_1_old or
			@apositiontaking_2 <> @apositiontaking_2_old or
			@apositiontaking_3 <> @apositiontaking_3_old or
			@apositiontaking_4 <> @apositiontaking_4_old or
			@apositiontaking_5 <> @apositiontaking_5_old or
			@apositiontaking_6 <> @apositiontaking_6_old or
			@apositiontaking_7 <> @apositiontaking_7_old or
			@apositiontaking_8 <> @apositiontaking_8_old or
			@apositiontaking_9 <> @apositiontaking_9_old or
			@apositiontaking_10 <> @apositiontaking_10_old or
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
			@alivepositiontaking_1 <> @alivepositiontaking_1_old or
			@alivepositiontaking_3 <> @alivepositiontaking_3_old or
			@alivepositiontaking_7 <> @alivepositiontaking_7_old or
			@alivepositiontaking_8 <> @alivepositiontaking_8_old or
			@mlivepositiontaking_1 <> @mlivepositiontaking_1_old or
			@mlivepositiontaking_3 <> @mlivepositiontaking_3_old or
			@mlivepositiontaking_7 <> @mlivepositiontaking_7_old or
			@mlivepositiontaking_8 <> @mlivepositiontaking_8_old or
			@v2apositiontaking_1 <> @v2apositiontaking_1_old or
			@v2apositiontaking_2 <> @v2apositiontaking_2_old or
			@v2apositiontaking_3 <> @v2apositiontaking_3_old or
			@v2apositiontaking_7 <> @v2apositiontaking_7_old or
			@v2apositiontaking_8 <> @v2apositiontaking_8_old or
			@v2apositiontaking_9 <> @v2apositiontaking_9_old or
			@v2apositiontaking_20 <> @v2apositiontaking_20_old or
			@v3apositiontaking_1 <> @v3apositiontaking_1_old or
			@v3apositiontaking_2 <> @v3apositiontaking_2_old or
			@v3apositiontaking_3 <> @v3apositiontaking_3_old or
			@v3apositiontaking_20 <> @v3apositiontaking_20_old or
			@v5apositiontaking_1 <> @v5apositiontaking_1_old or
			@v5apositiontaking_2 <> @v5apositiontaking_2_old or
			@v5apositiontaking_3 <> @v5apositiontaking_3_old or
			@v5apositiontaking_20 <> @v5apositiontaking_20_old or
			@v8apositiontaking_1 <> @v8apositiontaking_1_old or
			@v8apositiontaking_3 <> @v8apositiontaking_3_old or
			@v8apositiontaking_20 <> @v8apositiontaking_20_old or
			@v10apositiontaking_1 <> @v10apositiontaking_1_old or
			@v10apositiontaking_2 <> @v10apositiontaking_2_old or
			@v10apositiontaking_3 <> @v10apositiontaking_3_old or
			@v10apositiontaking_20 <> @v10apositiontaking_20_old or
			@v11apositiontaking_1 <> @v11apositiontaking_1_old or
			@v11apositiontaking_20 <> @v11apositiontaking_20_old or

			@v99apositiontaking_1 <> @v99apositiontaking_1_old or
			@v99apositiontaking_2 <> @v99apositiontaking_2_old or
			@v99apositiontaking_3 <> @v99apositiontaking_3_old or
			@v99apositiontaking_20 <> @v99apositiontaking_20_old or
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
			@v99mpositiontaking_20 <> @v99mpositiontaking_20_old or
			@auto_mpositiontaking_1 <> @auto_mpositiontaking_1_old or
			@auto_mpositiontaking_2 <> @auto_mpositiontaking_2_old or
			@auto_mpositiontaking_3 <> @auto_mpositiontaking_3_old or
			@auto_mpositiontaking_4 <> @auto_mpositiontaking_4_old or
			@auto_mpositiontaking_5 <> @auto_mpositiontaking_5_old or
			@auto_mpositiontaking_6 <> @auto_mpositiontaking_6_old or
			@auto_mpositiontaking_7 <> @auto_mpositiontaking_7_old or
			@auto_mpositiontaking_8 <> @auto_mpositiontaking_8_old or
			@auto_mpositiontaking_9 <> @auto_mpositiontaking_9_old or
			@auto_mpositiontaking_10 <> @auto_mpositiontaking_10_old or
			@auto_mlivepositiontaking_1 <> @auto_mlivepositiontaking_1_old or
			@auto_mlivepositiontaking_3 <> @auto_mlivepositiontaking_3_old or
			@auto_mlivepositiontaking_7 <> @auto_mlivepositiontaking_7_old or
			@auto_mlivepositiontaking_8 <> @auto_mlivepositiontaking_8_old or
			@auto_v2mpositiontaking_1 <> @auto_v2mpositiontaking_1_old or
			@auto_v2mpositiontaking_2 <> @auto_v2mpositiontaking_2_old or
			@auto_v2mpositiontaking_3 <> @auto_v2mpositiontaking_3_old or
			@auto_v2mpositiontaking_7 <> @auto_v2mpositiontaking_7_old or
			@auto_v2mpositiontaking_8 <> @auto_v2mpositiontaking_8_old or
			@auto_v2mpositiontaking_9 <> @auto_v2mpositiontaking_9_old or
			@auto_v2mpositiontaking_20 <> @auto_v2mpositiontaking_20_old or
			@auto_v3mpositiontaking_1 <> @auto_v3mpositiontaking_1_old or
			@auto_v3mpositiontaking_2 <> @auto_v3mpositiontaking_2_old or
			@auto_v3mpositiontaking_3 <> @auto_v3mpositiontaking_3_old or
			@auto_v3mpositiontaking_20 <> @auto_v3mpositiontaking_20_old or
			@auto_v5mpositiontaking_1 <> @auto_v5mpositiontaking_1_old or
			@auto_v5mpositiontaking_2 <> @auto_v5mpositiontaking_2_old or
			@auto_v5mpositiontaking_3 <> @auto_v5mpositiontaking_3_old or
			@auto_v5mpositiontaking_20 <> @auto_v5mpositiontaking_20_old or
			@auto_v8mpositiontaking_1 <> @auto_v8mpositiontaking_1_old or
			@auto_v8mpositiontaking_3 <> @auto_v8mpositiontaking_3_old or
			@auto_v8mpositiontaking_20 <> @auto_v8mpositiontaking_20_old or
			@auto_v10mpositiontaking_1 <> @auto_v10mpositiontaking_1_old or
			@auto_v10mpositiontaking_2 <> @auto_v10mpositiontaking_2_old or
			@auto_v10mpositiontaking_3 <> @auto_v10mpositiontaking_3_old or
			@auto_v10mpositiontaking_20 <> @auto_v10mpositiontaking_20_old or
			@auto_v11mpositiontaking_1 <> @auto_v11mpositiontaking_1_old or
			@auto_v11mpositiontaking_20 <> @auto_v11mpositiontaking_20_old or

			@auto_v99mpositiontaking_1 <> @auto_v99mpositiontaking_1_old or
			@auto_v99mpositiontaking_2 <> @auto_v99mpositiontaking_2_old or
			@auto_v99mpositiontaking_3 <> @auto_v99mpositiontaking_3_old or
			@auto_v99mpositiontaking_20 <> @auto_v99mpositiontaking_20_old or
			@isauto_mpositiontaking_1 <> @isauto_mpositiontaking_1_old or
			@isauto_mpositiontaking_2 <> @isauto_mpositiontaking_2_old or
			@isauto_mpositiontaking_3 <> @isauto_mpositiontaking_3_old or
			@isauto_mpositiontaking_4 <> @isauto_mpositiontaking_4_old or
			@isauto_mpositiontaking_5 <> @isauto_mpositiontaking_5_old or
			@isauto_mpositiontaking_6 <> @isauto_mpositiontaking_6_old or
			@isauto_mpositiontaking_7 <> @isauto_mpositiontaking_7_old or
			@isauto_mpositiontaking_8 <> @isauto_mpositiontaking_8_old or
			@isauto_mpositiontaking_9 <> @isauto_mpositiontaking_9_old or
			@isauto_mpositiontaking_10 <> @isauto_mpositiontaking_10_old or
			@isauto_mlivepositiontaking_1 <> @isauto_mlivepositiontaking_1_old or
			@isauto_mlivepositiontaking_3 <> @isauto_mlivepositiontaking_3_old or
			@isauto_mlivepositiontaking_7 <> @isauto_mlivepositiontaking_7_old or
			@isauto_mlivepositiontaking_8 <> @isauto_mlivepositiontaking_8_old or
			@isauto_v2mpositiontaking_1 <> @isauto_v2mpositiontaking_1_old or
			@isauto_v2mpositiontaking_2 <> @isauto_v2mpositiontaking_2_old or
			@isauto_v2mpositiontaking_3 <> @isauto_v2mpositiontaking_3_old or
			@isauto_v2mpositiontaking_7 <> @isauto_v2mpositiontaking_7_old or
			@isauto_v2mpositiontaking_8 <> @isauto_v2mpositiontaking_8_old or
			@isauto_v2mpositiontaking_9 <> @isauto_v2mpositiontaking_9_old or
			@isauto_v2mpositiontaking_20 <> @isauto_v2mpositiontaking_20_old or
			@isauto_v3mpositiontaking_1 <> @isauto_v3mpositiontaking_1_old or
			@isauto_v3mpositiontaking_2 <> @isauto_v3mpositiontaking_2_old or
			@isauto_v3mpositiontaking_3 <> @isauto_v3mpositiontaking_3_old or
			@isauto_v3mpositiontaking_20 <> @isauto_v3mpositiontaking_20_old or
			@isauto_v5mpositiontaking_1 <> @isauto_v5mpositiontaking_1_old or
			@isauto_v5mpositiontaking_2 <> @isauto_v5mpositiontaking_2_old or
			@isauto_v5mpositiontaking_3 <> @isauto_v5mpositiontaking_3_old or
			@isauto_v5mpositiontaking_20 <> @isauto_v5mpositiontaking_20_old or
			@isauto_v8mpositiontaking_1 <> @isauto_v8mpositiontaking_1_old or
			@isauto_v8mpositiontaking_3 <> @isauto_v8mpositiontaking_3_old or
			@isauto_v8mpositiontaking_20 <> @isauto_v8mpositiontaking_20_old or
			@isauto_v10mpositiontaking_1 <> @isauto_v10mpositiontaking_1_old or
			@isauto_v10mpositiontaking_2 <> @isauto_v10mpositiontaking_2_old or
			@isauto_v10mpositiontaking_3 <> @isauto_v10mpositiontaking_3_old or
			@isauto_v10mpositiontaking_20 <> @isauto_v10mpositiontaking_20_old or
			@isauto_v11mpositiontaking_1 <> @isauto_v11mpositiontaking_1_old or
			@isauto_v11mpositiontaking_20 <> @isauto_v11mpositiontaking_20_old or

			@isauto_v99mpositiontaking_1 <> @isauto_v99mpositiontaking_1_old or
			@isauto_v99mpositiontaking_2 <> @isauto_v99mpositiontaking_2_old or
			@isauto_v99mpositiontaking_3 <> @isauto_v99mpositiontaking_3_old or
			@isauto_v99mpositiontaking_20 <> @isauto_v99mpositiontaking_20_old
	BEGIN
		EXEC dbo.Acc_CustomerUpdAgent_PositionTaking 
			@custid = @custid,
			@apositiontaking_1 = @apositiontaking_1,
			@apositiontaking_2 = @apositiontaking_2,
			@apositiontaking_3 = @apositiontaking_3,
			@apositiontaking_4 = @apositiontaking_4,
			@apositiontaking_5 = @apositiontaking_5,
			@apositiontaking_6 = @apositiontaking_6,
			@apositiontaking_7 = @apositiontaking_7,
			@apositiontaking_8 = @apositiontaking_8,
			@apositiontaking_9 = @apositiontaking_9,
			@apositiontaking_10 = @apositiontaking_10,
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
			@alivepositiontaking_1 = @alivepositiontaking_1,
			@alivepositiontaking_3 = @alivepositiontaking_3,
			@alivepositiontaking_7 = @alivepositiontaking_7,
			@alivepositiontaking_8 = @alivepositiontaking_8,
			@mlivepositiontaking_1 = @mlivepositiontaking_1,
			@mlivepositiontaking_3 = @mlivepositiontaking_3,
			@mlivepositiontaking_7 = @mlivepositiontaking_7,
			@mlivepositiontaking_8 = @mlivepositiontaking_8,
			@v2apositiontaking_1 = @v2apositiontaking_1,
			@v2apositiontaking_2 = @v2apositiontaking_2,
			@v2apositiontaking_3 = @v2apositiontaking_3,
			@v2apositiontaking_7 = @v2apositiontaking_7,
			@v2apositiontaking_8 = @v2apositiontaking_8,
			@v2apositiontaking_9 = @v2apositiontaking_9,
			@v2apositiontaking_20 = @v2apositiontaking_20,
			@v3apositiontaking_1 = @v3apositiontaking_1,
			@v3apositiontaking_2 = @v3apositiontaking_2,
			@v3apositiontaking_3 = @v3apositiontaking_3,
			@v3apositiontaking_20 = @v3apositiontaking_20,
			@v5apositiontaking_1 = @v5apositiontaking_1,
			@v5apositiontaking_2 = @v5apositiontaking_2,
			@v5apositiontaking_3 = @v5apositiontaking_3,
			@v5apositiontaking_20 = @v5apositiontaking_20,
			@v8apositiontaking_1 = @v8apositiontaking_1,
			@v8apositiontaking_3 = @v8apositiontaking_3,
			@v8apositiontaking_20 = @v8apositiontaking_20,
			@v10apositiontaking_1 = @v10apositiontaking_1,
			@v10apositiontaking_2 = @v10apositiontaking_2,
			@v10apositiontaking_3 = @v10apositiontaking_3,
			@v10apositiontaking_20 = @v10apositiontaking_20,
			@v11apositiontaking_1 = @v11apositiontaking_1,
			@v11apositiontaking_20 = @v11apositiontaking_20,

			@v99apositiontaking_1 = @v99apositiontaking_1,
			@v99apositiontaking_2 = @v99apositiontaking_2,
			@v99apositiontaking_3 = @v99apositiontaking_3,
			@v99apositiontaking_20 = @v99apositiontaking_20,
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
			
			@updateallmembers = @updateallmembers,
			@newmpositiontaking = @newmpositiontaking,
			
			@UpdateMultiple = @UpdateMultiple,
			@UpdatePositiontaking = @UpdatePositiontaking OUTPUT,
			@UpdatePositiontakingv2 = @UpdatePositiontakingv2 OUTPUT,
			@UpdatePositiontakingv3 = @UpdatePositiontakingv3 OUTPUT,
			@UpdatePositiontakingv5 = @UpdatePositiontakingv5 OUTPUT,
			@UpdatePositiontakingv8 = @UpdatePositiontakingv8 OUTPUT,
			@UpdatePositiontakingv10 = @UpdatePositiontakingv10 OUTPUT,
			@UpdatePositiontakingv11 = @UpdatePositiontakingv11 OUTPUT,
			@UpdatePositiontakingv99 = @UpdatePositiontakingv99 OUTPUT,
			@SubAccID = @SubAccID,
			@UserID = @UserID,
			@Language = @Language,
			@IP = @IP,
			@ErrCode = @ErrCode_Cur OUTPUT,
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
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdAgent_All] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdAgent_All] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdAgent_All] TO vnteam