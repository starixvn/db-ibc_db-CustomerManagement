ALTER PROCEDURE Acc_CustomerUpdSuperFI_All
	@custid int,-- superid	
	@v201spositiontaking_2 smallmoney,
	@v201spositiontaking_3 smallmoney,
	@v201mpositiontaking_2 smallmoney = 0.5,
	@v201mpositiontaking_3 smallmoney = 0.5,
	@v201apositiontaking_2 smallmoney = 0.5,
	@v201apositiontaking_3 smallmoney = 0.5,
	@DisableFinancial bit,
	@DisableDownlineFI bit = 1,--Disable all downline

	@v201discount decimal(9,8),
	
	@minbetv201 money = 0,
	@maxbetv201 money = 0,
	@maxpermatchv201 money = 0,

	@UserID int = 0,	
	@Language varchar(2) = 'E',
	@IP varchar(15)='',
	@Username varchar(30) = '' OUTPUT,
	@ErrCode varchar(300) = '' OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT

AS
/*
Created: 20090415@Phuc
Task : update financial setting(super).
DB: DB02.bodb02

Revisions:
	- 20090703@Phuc: enrich error message.(-101: general info, -102: closed, -103: suspended, 
						-104: credit, -105: commission, -106: min/max bet, -107: positiontaking
						-108: disable FI, -109: disableHR)

Param's Explanation:
• @ErrCode:
    = 0: Transaction recorded successfully.
    > 0: Specific Error.
  
• @ErrMsg: Error description.
*/

SET NOCOUNT ON
Declare @ErrCode_Cur int, @ErrMsg_Cur nvarchar(4000), @roleid tinyint
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

EXEC dbo.Acc_CustomerUpdDisableFI 
	@CustID = @CustID,
	@DisableFinancial = @DisableFinancial,
	@DisableDownlineFI = @DisableDownlineFI,
	@UserID = @UserID,
	@Language = @Language,
	@ErrCode = @ErrCode_Cur OUTPUT,
	@ErrMsg = @ErrMsg_Cur OUTPUT,
	@IP = @IP
IF @ErrCode_Cur > 0
BEGIN
	select @ErrCode = @ErrCode + cast(@ErrCode_cur as varchar(300)) + char(7), 
			@ErrMsg = @ErrMsg + @ErrMsg_Cur + char(7)
	return
END
ELSE
BEGIN
	Select @ErrCode = @ErrCode + '-108'+char(7), @ErrMsg = @ErrMsg + char(7)
END

Select @ErrCode_Cur = 0, @ErrMsg_Cur = ''
EXEC dbo.Acc_CustomerUpdCommissionFI 
	@custid = @custid,
	@roleid = 4,
	@v201discount = @v201discount,
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
	Select @ErrCode = @ErrCode + '-105'+char(7), @ErrMsg = @ErrMsg + char(7)
END
	
	
Select @ErrCode_Cur = 0, @ErrMsg_Cur = ''
EXEC dbo.Acc_CustomerUpdMinMaxBetFI 
	@custid = @custid,
	@roleid = 4,
	@minbetv201 = @minbetv201,
	@maxbetv201 = @maxbetv201,
	@maxpermatchv201 = @maxpermatchv201,
	@SubAccID = 0,
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

Select @ErrCode_Cur = 0, @ErrMsg_Cur = ''
EXEC dbo.Acc_CustomerUpdSuperFI_Positiontaking 
	@custid = @custid,
	@v201spositiontaking_2 = @v201spositiontaking_2,
	@v201spositiontaking_3 = @v201spositiontaking_3,
	@v201mpositiontaking_2 = @v201mpositiontaking_2,
	@v201mpositiontaking_3 = @v201mpositiontaking_3,
	@v201apositiontaking_2 = @v201apositiontaking_2,
	@v201apositiontaking_3 = @v201apositiontaking_3,
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
	Select @ErrCode = @ErrCode + '-107'+char(7), @ErrMsg = @ErrMsg + char(7)
END

RETURN

GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdSuperFI_All] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdSuperFI_All] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdSuperFI_All] TO vnteam
