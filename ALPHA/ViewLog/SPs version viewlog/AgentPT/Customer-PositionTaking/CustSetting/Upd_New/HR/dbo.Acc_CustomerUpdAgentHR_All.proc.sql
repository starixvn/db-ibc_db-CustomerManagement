ALTER PROCEDURE Acc_CustomerUpdAgentHR_All
	@custid int, --agentID
	@UserID int = 0,

	@v151apositiontaking_31 smallmoney,--a2
	@v151apositiontaking_32 smallmoney,
	@v151apositiontaking_41 smallmoney,
	@v151apositiontaking_42 smallmoney,
	
	@v151mpositiontaking_31 smallmoney,--m2
	@v151mpositiontaking_32 smallmoney,
	@v151mpositiontaking_41 smallmoney,
	@v151mpositiontaking_42 smallmoney,

	@auto_v151mpositiontaking_31 smallmoney = 0,--u2
	@auto_v151mpositiontaking_32 smallmoney = 0,
	@auto_v151mpositiontaking_41 smallmoney = 0,
	@auto_v151mpositiontaking_42 smallmoney = 0,
	
	@isauto_v151mpositiontaking_31 bit = 0,
	@isauto_v151mpositiontaking_32 bit = 0,
	@isauto_v151mpositiontaking_41 bit = 0,
	@isauto_v151mpositiontaking_42 bit = 0,

	@UpdateDisableHR bit = 1,
	@UpdateCommission bit = 1,
	@UpdatePositiontaking bit = 1,
	@UpdateMinMaxBet bit = 1,
	
	@IsCopyPreset_31 bit = 0,--Use for copy preset to member
	@IsCopyPreset_41 bit = 0,--Use for copy preset to member
	@updateallmembers bit = 0,
	@newmpositiontaking smallmoney = 0,--equals max(m+a) - chosen(a)

	@DisableHorseracing bit,
	@DisableDownline bit = true,
	@minbet money,
	@maxbet money,
	@maxpermatch money,
	
	@v151discount_31 decimal(9,8),	
	@v151discount_41 decimal(9,8),
	@SubAccID int = 0, --Sub-AccountID	
	@Language varchar(2) = 'E',
	@Username varchar(30) = '' OUTPUT,
	@ErrCode varchar(300) = '' OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT,
	@IP varchar(15)=''
AS
/*
Created: 20090514@Phuc
Task : update HR setting(agent).
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

BEGIN
	--Update Horseracing status (allow/disallow)	
	IF @UpdateDisableHR = 1 
	BEGIN	
		Select @ErrCode_Cur = 0, @ErrMsg_Cur = ''		
		EXEC dbo.Acc_CustomerUpdDisableHR	
			@custid=@custid, 
			@DisableHorseracing=@DisableHorseracing, 
			@DisableDownline=@DisableDownline,
			@UserID=@UserID, 
			@SubAccID=@SubAccID,
			@Language=@Language, 
			@ErrCode=@ErrCode_Cur output, 
			@ErrMsg=@ErrMsg_Cur output, 
			@IP=@IP
		IF @ErrCode_Cur > 0
		BEGIN
			select @ErrCode = @ErrCode + cast(@ErrCode_cur as varchar(300)) + char(7), 
					@ErrMsg = @ErrMsg + @ErrMsg_Cur + char(7)
			return
		END
		ELSE
		BEGIN
			Select @ErrCode = @ErrCode + '-109'+char(7), @ErrMsg = @ErrMsg + char(7)
		END
	END
	--end--	
	
	--Update Horseracing commission	
	IF @UpdateCommission = 1 
	BEGIN
		Select @ErrCode_Cur = 0, @ErrMsg_Cur = ''
		EXEC dbo.Acc_CustomerUpdAgent_CommissionHR	
			@custid=@custid, 
			@v151discount_31=@v151discount_31, 
			@v151discount_41=@v151discount_41, 
			@UserID=@UserID, 
			@SubAccID=@SubAccID,
			@Language=@Language, 
			@IP=@IP,  
			@ErrCode=@ErrCode_Cur output, 
			@ErrMsg=@ErrMsg_Cur output
			
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
	--end--

	--Update bet setting
	IF @UpdateMinMaxBet = 1
	BEGIN
		Select @ErrCode_Cur = 0, @ErrMsg_Cur = ''
		EXEC dbo.Acc_CustomerUpdAgent_MinMaxBetHR	
			@custid=@custid, 
			@minbet=@minbet, 
			@maxbet=@maxbet, 
			@maxpermatch=@maxpermatch, 
			@UserID=@UserID, 
			@SubAccID=@SubAccID,
			@Language=@Language, 
			@IP=@IP, 
			@ErrCode=@ErrCode_Cur output, 
			@ErrMsg=@ErrMsg_Cur output
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
	--end--

	--Update PT for HR
	IF @UpdatePositiontaking = 1
	BEGIN
		Select @ErrCode_Cur = 0, @ErrMsg_Cur = ''
		EXEC dbo.Acc_CustomerUpdAgentHR_PositionTaking 
			@custid = @custid,
			@v151apositiontaking_31 = @v151apositiontaking_31,
			@v151apositiontaking_32 = @v151apositiontaking_32,
			@v151apositiontaking_41 = @v151apositiontaking_41,
			@v151apositiontaking_42 = @v151apositiontaking_42,
			@v151mpositiontaking_31 = @v151mpositiontaking_31,
			@v151mpositiontaking_32 = @v151mpositiontaking_32,
			@v151mpositiontaking_41 = @v151mpositiontaking_41,
			@v151mpositiontaking_42 = @v151mpositiontaking_42,
			@auto_v151mpositiontaking_31 = @auto_v151mpositiontaking_31,
			@auto_v151mpositiontaking_32 = @auto_v151mpositiontaking_32,
			@auto_v151mpositiontaking_41 = @auto_v151mpositiontaking_41,
			@auto_v151mpositiontaking_42 = @auto_v151mpositiontaking_42,
			@isauto_v151mpositiontaking_31 = @isauto_v151mpositiontaking_31,
			@isauto_v151mpositiontaking_32 = @isauto_v151mpositiontaking_32,
			@isauto_v151mpositiontaking_41 = @isauto_v151mpositiontaking_41,
			@isauto_v151mpositiontaking_42 = @isauto_v151mpositiontaking_42,
		
			@IsCopyPreset_31 = @IsCopyPreset_31,--Use for copy preset to member
			@IsCopyPreset_41 = @IsCopyPreset_41,--Use for copy preset to member
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

	END
	RETURN 
				
END

GO
GRANT EXECUTE ON [dbo].Acc_CustomerUpdAgentHR_All TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].Acc_CustomerUpdAgentHR_All TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].Acc_CustomerUpdAgentHR_All TO vnteam
