ALTER PROCEDURE [Acc_CustomerUpdAgentFI_All]
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

	@DisableFinancial bit,
	@DisableDownlineFI bit = 1,--Disable all downline
	@v201discount decimal(9,8),
	
	@minbetv201 money = 0,
	@maxbetv201 money = 0,
	@maxpermatchv201 money = 0,
	
	@SubAccID int = 0, --Sub-AccountID	
	
	@UserID int = 0,	
	@Language varchar(2) = 'E',
	@IP varchar(15)='',
	@Username varchar(30) = '' OUTPUT,
	@ErrCode varchar(300) = '' OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS
/*
Created: 20090415@Phuc
Task : update financial setting(agent).
DB: DB02.bodb02

Revisions:
	- 20090703@Phuc: enrich error message.(-101: general info, -102: closed, -103: suspended, 
						-104: credit, -105: commission, -106: min/max bet, -107: positiontaking
						-108: disable FI, -109: disableHR)
	- 20090801@Shifu: check disabled user
Param's Explanation:
• @ErrCode:
    = 0: Transaction recorded successfully.
    > 0: Specific Error.
  
• @ErrMsg: Error description.
*/

SET NOCOUNT ON

Declare @ErrCode_Cur int, @ErrMsg_Cur nvarchar(4000), @roleid tinyint
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

EXEC dbo.Acc_CustomerUpdDisableFI 
	@CustID = @CustID,
	@DisableFinancial = @DisableFinancial,
	@DisableDownlineFI = @DisableDownlineFI,
	@UserID = @UserID,
	@SubAccID = @SubAccID,
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
	@roleid = 2,
	@v201discount = @v201discount,
	@UserID = @UserID,
	@SubAccID = @SubAccID,
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
	@roleid = 2,
	@minbetv201 = @minbetv201,
	@maxbetv201 = @maxbetv201,
	@maxpermatchv201 = @maxpermatchv201,
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


Select @ErrCode_Cur = 0, @ErrMsg_Cur = ''
EXEC dbo.Acc_CustomerUpdAgentFI_PositionTaking 
	@custid = @custid,
	@v201apositiontaking_2 = @v201apositiontaking_2,
	@v201apositiontaking_3 = @v201apositiontaking_3,
	@v201mpositiontaking_2 = @v201mpositiontaking_2,
	@v201mpositiontaking_3 = @v201mpositiontaking_3,
	@auto_v201mpositiontaking_2 = @auto_v201mpositiontaking_2,
	@auto_v201mpositiontaking_3 = @auto_v201mpositiontaking_3,
	@isauto_v201mpositiontaking_2 = @isauto_v201mpositiontaking_2,
	@isauto_v201mpositiontaking_3 = @isauto_v201mpositiontaking_3,
	@updateallmembers = @updateallmembers,
	@newmpositiontaking = @newmpositiontaking,
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
	Select @ErrCode = @ErrCode + '-107'+char(7), @ErrMsg = @ErrMsg + char(7)
END


GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdAgentFI_All] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdAgentFI_All] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdAgentFI_All] TO vnteam



