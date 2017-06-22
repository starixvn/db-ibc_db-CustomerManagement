ALTER PROCEDURE [dbo].[Acc_CustomerUpdSuper_All]
	@custid int,-- superid
	@firstname nvarchar(50),
	@lastname nvarchar(50),
	@phone nvarchar(50),
	@mobilephone nvarchar(50),
	@email nvarchar(50)='',
	@fax nvarchar(50),
	@disCasino bit = 0,
	@closed bit,
	@Suspended bit,

	@SubAccID int = 0,
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

	@MinBetv99 money = 0,
	@MaxBetv99 money = 0,
	@MaxPerMatchv99 money,
	
	@credit money,
	@Language varchar(2),
	
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
	@v11mpositiontaking_2 smallmoney = 0.7,
	@v11mpositiontaking_20 smallmoney = 0.7,

	@v99mpositiontaking_1 smallmoney = 0.7,
	@v99mpositiontaking_2 smallmoney = 0.7,
	@v99mpositiontaking_3 smallmoney = 0.7,
	@v99mpositiontaking_20 smallmoney = 0.7,
	
	@apositiontaking_1 smallmoney = 0.7,
	@apositiontaking_2 smallmoney = 0.7,
	@apositiontaking_3 smallmoney = 0.7,
	@apositiontaking_4 smallmoney = 0.7,
	@apositiontaking_5 smallmoney = 0.7,
	@apositiontaking_6 smallmoney = 0.7,
	@apositiontaking_7 smallmoney = 0.7,
	@apositiontaking_8 smallmoney = 0.7,
	@apositiontaking_9 smallmoney = 0.7,
	@apositiontaking_10 smallmoney = 0.7,
	
	@alivepositiontaking_1 smallmoney = 0.7,
	@alivepositiontaking_3 smallmoney = 0.7,
	@alivepositiontaking_7 smallmoney = 0.7,
	@alivepositiontaking_8 smallmoney = 0.7,
	
	@v2apositiontaking_1 smallmoney = 0.7,
	@v2apositiontaking_2 smallmoney = 0.7,
	@v2apositiontaking_3 smallmoney = 0.7,
	@v2apositiontaking_7 smallmoney = 0.7,
	@v2apositiontaking_8 smallmoney = 0.7,
	@v2apositiontaking_9 smallmoney = 0.7,
	@v2apositiontaking_20 smallmoney = 0.7,

	@v3apositiontaking_1 smallmoney = 0.7,
	@v3apositiontaking_2 smallmoney = 0.7,
	@v3apositiontaking_3 smallmoney = 0.7,
	@v3apositiontaking_20 smallmoney = 0.7,

	@v5apositiontaking_1 smallmoney = 0.7,
	@v5apositiontaking_2 smallmoney = 0.7,
	@v5apositiontaking_3 smallmoney = 0.7,
	@v5apositiontaking_20 smallmoney = 0.7,

	@v8apositiontaking_1 smallmoney = 0.7,
	@v8apositiontaking_3 smallmoney = 0.7,
	@v8apositiontaking_20 smallmoney = 0.7,

	@v10apositiontaking_1 smallmoney = 0.7,
	@v10apositiontaking_2 smallmoney = 0.7,
	@v10apositiontaking_3 smallmoney = 0.7,
	@v10apositiontaking_20 smallmoney = 0.7,

	@v11apositiontaking_1 smallmoney = 0.7,
	@v11apositiontaking_20 smallmoney = 0.7,

	@v99apositiontaking_1 smallmoney = 0.7,
	@v99apositiontaking_2 smallmoney = 0.7,
	@v99apositiontaking_3 smallmoney = 0.7,
	@v99apositiontaking_20 smallmoney = 0.7,
	
	@groupa decimal(9,8),
	@groupb decimal(9,8),
	@groupc decimal(9,8),
	@groupd decimal(9,8),
	@discountcs decimal(9,8),
	@discount1x2 decimal(9,8)=0,

	@IP varchar(15)='',
	@UserID int = 0,	
	@Username varchar(30) = '' OUTPUT,
	@ErrCode varchar(300) = '' OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS
--@Source Control
/*
Created: 20080514@Thien
Task : Update Super
DB: DB02.bodb02
Original:Acc_CustomerUpdEditCustomer_Com

Revisions:
    - 20081023@Phuc: Add new sporttype 201, bettype 3, hard code copy min/max/maxperbet/PT for 201 from 2 sporttype 
    - 20090122@PhuongBich: add new sporttype 201, bettype 2.
	- 20090317@Phuc: disable Financial
	- 20090320@PhuongDao: Change the param @IsUpdDownlineFI to @DisableDownlineFI
    - 20090424@Phuc:Separate finance sporttype(201).
    - 20090514@PhuongDao: Add 1x2 Commission
	- 20090703@Phuc: enrich error message.(-101: general info, -102: closed, -103: suspended, -104: credit, -105: commission, -106: min/max bet, -107: positiontaking
	- 20090801@Shifu: check disabled user
	- 20091203@Shifu: check disabled casino
Param's Explanation:
• @ErrCode:
    = 0: Update successfully.
    > 0: Specific Error.
  
• @ErrMsg: Error description.
*/

SET NOCOUNT ON
declare @roleid tinyint, @ErrCode_Cur int, @ErrMsg_Cur nvarchar(4000)
Select @ErrCode_Cur = 0, @ErrMsg_Cur = '', @ErrCode = '', @ErrMsg = ''

---------------------------
-- ***Check Downline Belonging***
EXEC DB052.bodb02.dbo.Age_CustomerSelCheckBelonging 
	@SessionCustID = @Userid, 
	@Custid = @custid,
	@Username = @Username OUTPUT,
	@roleid = @roleid OUTPUT
	if (@roleid = 0) return
---------------------------

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
Select @ErrCode_Cur = 0, @ErrMsg_Cur = ''
EXEC dbo.Acc_CustomerUpdUserInfo 
	@CustID = @CustID,
	@firstname = @firstname,
	@lastname = @lastname,
	@phone = @phone,
	@mobilephone = @mobilephone,
	@fax = @fax,
	@email = @email,
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

----------------------------------------------
--Update Closed	
Select @ErrCode_Cur = 0, @ErrMsg_Cur = ''
EXEC dbo.Acc_CustomerUpdClosed 
	@CustID = @CustID,
	@Closed = @Closed,
	@UserID = @UserID,
	@disCasino = @disCasino,
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

---------------------------------------------
---update suspended 
Select @ErrCode_Cur = 0, @ErrMsg_Cur = ''
EXEC Acc_CustomerUpdSuspended
	@CustID =@CustID,
	@Suspended =@Suspended,	
	@SubAccID =@SubAccID , 
	@UserID =@UserID,
	@disCasino = @disCasino,
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
----------------------------------------------
--Update credit
Select @ErrCode_Cur = 0, @ErrMsg_Cur = ''
EXEC dbo.Acc_CustomerUpdCredit 
	@custid = @custid,
	@NewCredit = @Credit,
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

----------------------------------------------
--Update Commission
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

select @discountcs_old = sdiscount
from custsetting (nolock) where custid = @custid and sporttype = 1 and bettype = 4

--1x2
select @discount1x2_old = sdiscount
from custsetting (nolock) where custid = @custid and sporttype = 1 and bettype = 5

if (@groupa_old <> @groupa) or (@groupb_old <> @groupb) or (@groupc_old <> @groupc) or (@groupd_old <> @groupd)
    or (@discountcs_old <> @discountcs) or (@discount1x2_old <> @discount1x2)
    set @updatecomm_old = 1
else 
	set @updatecomm_old = 0
if @updatecomm_old <> 0
begin
	
	EXEC dbo.Acc_CustomerUpdSuper_Commission 
		@custid = @custid,
		@groupa = @groupa,
		@groupb = @groupb,
		@groupc = @groupc,
		@groupd = @groupd,
		@discountcs = @discountcs,
		@discount1x2 = @discount1x2,
		@updatecomm_old = @updatecomm_old,
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

----------------------------------------------
--Update Min Max Bet

Select @ErrCode_Cur = 0, @ErrMsg_Cur = ''
EXEC dbo.Acc_CustomerUpdSuper_MinMaxBet 
	@custid = @custid,
	@MinBet = @MinBet,
	@MaxBet = @MaxBet,
	@MaxPerMatch = @MaxPerMatch,
	@MinBetv2 = @MinBetv2,
	@MaxBetv2 = @MaxBetv2,
	@MaxPerMatchv2 = @MaxPerMatchv2,
	@MinBetv3 = @MinBetv3,
	@MaxBetv3 = @MaxBetv3,
	@MaxPerMatchv3 = @MaxPerMatchv3,
	@MinBetv5 = @MinBetv5,
	@MaxBetv5 = @MaxBetv5,
	@MaxPerMatchv5 = @MaxPerMatchv5,
	@MinBetv8 = @MinBetv8,
	@MaxBetv8 = @MaxBetv8,
	@MaxPerMatchv8 = @MaxPerMatchv8,
	@MinBetv10 = @MinBetv10,
	@MaxBetv10 = @MaxBetv10,
	@MaxPerMatchv10 = @MaxPerMatchv10,
	@MinBetv11 = @MinBetv11,
	@MaxBetv11 = @MaxBetv11,
	@MaxPerMatchv11 = @MaxPerMatchv11,
	@MinBetv99 = @MinBetv99,
	@MaxBetv99 = @MaxBetv99,
	@MaxPerMatchv99 = @MaxPerMatchv99,
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


----------------------------------------------
--Update Position Taking
--If old_PT <> new_PT => update 
Declare 
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
	@mlivepositiontaking_1_old smallmoney,
	@mlivepositiontaking_3_old smallmoney,
	@mlivepositiontaking_7_old smallmoney,
	@mlivepositiontaking_8_old smallmoney,
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
	@v11mpositiontaking_2_old smallmoney,
	@v11mpositiontaking_20_old smallmoney,

	@v99mpositiontaking_1_old smallmoney,
	@v99mpositiontaking_2_old smallmoney,
	@v99mpositiontaking_3_old smallmoney,
	@v99mpositiontaking_20_old smallmoney,
	@apositiontaking_1_old smallmoney,
	@apositiontaking_2_old smallmoney,
	@apositiontaking_3_old smallmoney,
	@apositiontaking_4_old smallmoney,
	@apositiontaking_5_old smallmoney,
	@apositiontaking_6_old smallmoney,
	@apositiontaking_7_old smallmoney,
	@apositiontaking_8_old smallmoney,
	@apositiontaking_9_old smallmoney,
	@apositiontaking_10_old smallmoney,
	@alivepositiontaking_1_old smallmoney,
	@alivepositiontaking_3_old smallmoney,
	@alivepositiontaking_7_old smallmoney,
	@alivepositiontaking_8_old smallmoney,
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
	@v99apositiontaking_20_old smallmoney
--Get old PT
select @spositiontaking_1_old = spositiontaking, @slivepositiontaking_1_old = slivepositiontaking, @mpositiontaking_1_old = mpositiontaking, @mlivepositiontaking_1_old = mlivepositiontaking, @apositiontaking_1_old = apositiontaking, @alivepositiontaking_1_old = alivepositiontaking  from custsetting with (NOLOCK) where custid = @custid and bettype=1 and sporttype=1
select @spositiontaking_3_old = spositiontaking, @slivepositiontaking_3_old = slivepositiontaking, @mpositiontaking_3_old = mpositiontaking, @mlivepositiontaking_3_old = mlivepositiontaking, @apositiontaking_3_old = apositiontaking, @alivepositiontaking_3_old = alivepositiontaking  from custsetting with (NOLOCK) where custid = @custid and bettype=3 and sporttype=1
select @spositiontaking_7_old = spositiontaking, @slivepositiontaking_7_old = slivepositiontaking, @mpositiontaking_7_old = mpositiontaking, @mlivepositiontaking_7_old = mlivepositiontaking, @apositiontaking_7_old = apositiontaking, @alivepositiontaking_7_old = alivepositiontaking  from custsetting with (NOLOCK) where custid = @custid and bettype=7 and sporttype=1
select @spositiontaking_8_old = spositiontaking, @slivepositiontaking_8_old = slivepositiontaking, @mpositiontaking_8_old = mpositiontaking, @mlivepositiontaking_8_old = mlivepositiontaking, @apositiontaking_8_old = apositiontaking, @alivepositiontaking_8_old = alivepositiontaking  from custsetting with (NOLOCK) where custid = @custid and bettype=8 and sporttype=1
select @spositiontaking_2_old = spositiontaking, @mpositiontaking_2_old = mpositiontaking, @apositiontaking_2_old = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=2 and sporttype=1
select @spositiontaking_4_old = spositiontaking, @mpositiontaking_4_old = mpositiontaking, @apositiontaking_4_old = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=4 and sporttype=1

select @spositiontaking_5_old = spositiontaking, @mpositiontaking_5_old = mpositiontaking, @apositiontaking_5_old = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=5 and sporttype=1
select @spositiontaking_6_old = spositiontaking, @mpositiontaking_6_old = mpositiontaking, @apositiontaking_6_old = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=6 and sporttype=1
select @spositiontaking_9_old = spositiontaking, @mpositiontaking_9_old = mpositiontaking, @apositiontaking_9_old = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=9 and sporttype=1
select @spositiontaking_10_old = spositiontaking, @mpositiontaking_10_old = mpositiontaking, @apositiontaking_10_old = apositiontaking  from custsetting with (NOLOCK) where custid = @custid and bettype=10 and sporttype=1

select @v2spositiontaking_1_old = spositiontaking, @v2mpositiontaking_1_old = mpositiontaking, @v2apositiontaking_1_old = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=1 and sporttype=2
select @v2spositiontaking_2_old = spositiontaking, @v2mpositiontaking_2_old = mpositiontaking, @v2apositiontaking_2_old = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=2 and sporttype=2
select @v2spositiontaking_3_old = spositiontaking, @v2mpositiontaking_3_old = mpositiontaking, @v2apositiontaking_3_old = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=3 and sporttype=2
select @v2spositiontaking_7_old = spositiontaking, @v2mpositiontaking_7_old = mpositiontaking, @v2apositiontaking_7_old = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=7 and sporttype=2
select @v2spositiontaking_8_old = spositiontaking, @v2mpositiontaking_8_old = mpositiontaking, @v2apositiontaking_8_old = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=8 and sporttype=2
select @v2spositiontaking_9_old = spositiontaking, @v2mpositiontaking_9_old = mpositiontaking, @v2apositiontaking_9_old = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=9 and sporttype=2
select @v2spositiontaking_20_old = spositiontaking, @v2mpositiontaking_20_old = mpositiontaking, @v2apositiontaking_20_old = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=20 and sporttype=2

select @v3spositiontaking_1_old = spositiontaking, @v3mpositiontaking_1_old = mpositiontaking, @v3apositiontaking_1_old = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=1 and sporttype=3
select @v3spositiontaking_2_old = spositiontaking, @v3mpositiontaking_2_old = mpositiontaking, @v3apositiontaking_2_old = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=2 and sporttype=3
select @v3spositiontaking_3_old = spositiontaking, @v3mpositiontaking_3_old = mpositiontaking, @v3apositiontaking_3_old = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=3 and sporttype=3
select @v3spositiontaking_20_old = spositiontaking, @v3mpositiontaking_20_old = mpositiontaking, @v3apositiontaking_20_old = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=20 and sporttype=3

select @v5spositiontaking_1_old = spositiontaking, @v5mpositiontaking_1_old = mpositiontaking, @v5apositiontaking_1_old = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=1 and sporttype=5
select @v5spositiontaking_2_old = spositiontaking, @v5mpositiontaking_2_old = mpositiontaking, @v5apositiontaking_2_old = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=2 and sporttype=5
select @v5spositiontaking_3_old = spositiontaking, @v5mpositiontaking_3_old = mpositiontaking, @v5apositiontaking_3_old = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=3 and sporttype=5
select @v5spositiontaking_20_old = spositiontaking, @v5mpositiontaking_20_old = mpositiontaking, @v5apositiontaking_20_old = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=20 and sporttype=5

select @v8spositiontaking_1_old = spositiontaking, @v8mpositiontaking_1_old = mpositiontaking, @v8apositiontaking_1_old = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=1 and sporttype=8
select @v8spositiontaking_3_old = spositiontaking, @v8mpositiontaking_3_old = mpositiontaking, @v8apositiontaking_3_old = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=3 and sporttype=8
select @v8spositiontaking_20_old = spositiontaking, @v8mpositiontaking_20_old = mpositiontaking, @v8apositiontaking_20_old = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=20 and sporttype=8

select @v10spositiontaking_1_old = spositiontaking, @v10mpositiontaking_1_old = mpositiontaking, @v10apositiontaking_1_old = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=1 and sporttype=10
select @v10spositiontaking_2_old = spositiontaking, @v10mpositiontaking_2_old = mpositiontaking, @v10apositiontaking_2_old = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=2 and sporttype=10
select @v10spositiontaking_3_old = spositiontaking, @v10mpositiontaking_3_old = mpositiontaking, @v10apositiontaking_3_old = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=3 and sporttype=10
select @v10spositiontaking_20_old = spositiontaking, @v10mpositiontaking_20_old = mpositiontaking, @v10apositiontaking_20_old = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=20 and sporttype=10

select @v11spositiontaking_1_old = spositiontaking, @v11mpositiontaking_1_old = mpositiontaking, @v11apositiontaking_1_old = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=1 and sporttype=11
select @v11spositiontaking_20_old = spositiontaking, @v11mpositiontaking_20_old = mpositiontaking, @v11apositiontaking_20_old = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=20 and sporttype=11

select @v99spositiontaking_1_old = spositiontaking, @v99mpositiontaking_1_old = mpositiontaking, @v99apositiontaking_1_old = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=1 and sporttype=99
select @v99spositiontaking_2_old = spositiontaking, @v99mpositiontaking_2_old = mpositiontaking, @v99apositiontaking_2_old = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=2 and sporttype=99
select @v99spositiontaking_3_old = spositiontaking, @v99mpositiontaking_3_old = mpositiontaking, @v99apositiontaking_3_old = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=3 and sporttype=99
select @v99spositiontaking_20_old = spositiontaking, @v99mpositiontaking_20_old = mpositiontaking, @v99apositiontaking_20_old = apositiontaking from custsetting with (NOLOCK) where custid = @custid and bettype=20 and sporttype=99

--Check if Old_PT = New_PT
IF 	@spositiontaking_1 <> @spositiontaking_1_old or
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
	@v11mpositiontaking_2 <> @v11mpositiontaking_2_old or
	@v11mpositiontaking_20 <> @v11mpositiontaking_20_old or

	@v99mpositiontaking_1 <> @v99mpositiontaking_1_old or
	@v99mpositiontaking_2 <> @v99mpositiontaking_2_old or
	@v99mpositiontaking_3 <> @v99mpositiontaking_3_old or
	@v99mpositiontaking_20 <> @v99mpositiontaking_20_old or
	@apositiontaking_1 <> @apositiontaking_1_old or
	@apositiontaking_2 <> @apositiontaking_2_old or
	@apositiontaking_3 <> @apositiontaking_3_old or
	@apositiontaking_4 <> @apositiontaking_4_old or
	@apositiontaking_5 <> @apositiontaking_5_old or
	@apositiontaking_6 <> @apositiontaking_6_old or
	@apositiontaking_7 <> @apositiontaking_7_old or
	@apositiontaking_8 <> @apositiontaking_8_old or
	@apositiontaking_9 <> @apositiontaking_9_old or
	@apositiontaking_10 <> @apositiontaking_10_old or
	@alivepositiontaking_1 <> @alivepositiontaking_1_old or
	@alivepositiontaking_3 <> @alivepositiontaking_3_old or
	@alivepositiontaking_7 <> @alivepositiontaking_7_old or
	@alivepositiontaking_8 <> @alivepositiontaking_8_old or
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
	@v99apositiontaking_20 <> @v99apositiontaking_20_old 
BEGIN
	Select @ErrCode_Cur = 0, @ErrMsg_Cur = ''
	EXEC dbo.Acc_CustomerUpdSuper_PositionTaking 
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
		@v11mpositiontaking_2 = @v11mpositiontaking_2,
		@v11mpositiontaking_20 = @v11mpositiontaking_20,

		@v99mpositiontaking_1 = @v99mpositiontaking_1,
		@v99mpositiontaking_2 = @v99mpositiontaking_2,
		@v99mpositiontaking_3 = @v99mpositiontaking_3,
		@v99mpositiontaking_20 = @v99mpositiontaking_20,
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
		@alivepositiontaking_1 = @alivepositiontaking_1,
		@alivepositiontaking_3 = @alivepositiontaking_3,
		@alivepositiontaking_7 = @alivepositiontaking_7,
		@alivepositiontaking_8 = @alivepositiontaking_8,
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


GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdSuper_All] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdSuper_All] TO vnteam
