USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Age_CustomerUpdAgentComm]    Script Date: 06/11/2015 11:24:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Age_CustomerUpdAgentComm    Script Date: 12/5/2013 4:35:18 PM ******/
ALTER PROCEDURE [dbo].[Age_CustomerUpdAgentComm]	
	@custid int, --customer to be updated
	@groupa decimal(9,8),
	@groupb decimal(9,8),
	@groupc decimal(9,8),
	@groupd decimal(9,8),
	@discount1x2 decimal(9,8),
	@discountcs decimal(9,8),
	@discountHRFixedOdds decimal(9,8) = 0,	
	@discountnumber decimal(9,8),
	@discountMyanmarOdds DECIMAL(9,8)=0, 
	@userid int, --updater Id	
	@subaccid int = 0, --Sub-AccountID
	@language varchar(2) = 'E',
	@IP varchar(15)='',	
	@errcode int = 0 OUTPUT,
	@errmsg nvarchar(200) = '' OUTPUT
AS
BEGIN
 /*
Created: 20090713@nqminh
Task : Update commission for Agent
DB: DBCUST/CUSTDB
Original:

Revisions:    
	- 20090729@Phuc: Write log subaccname instead of subaccid.
	- 20090818@Phuc: check page access and check upline closed first(call Age_CustSubCheckPageAccess)
	- 20091008@Kiwi: Remove WriteLog_UserLog
	- 20100918@Terry: Add Number Game
	- 20110907@Sophia: Change Linked Server from DB052 to DB053	
	- 20130311@Dan: Change linked server DB053 to DBAGE
	- 20131011@Elodie: Add HR Fixed Odds [Redmine:#6505]
	- 20150611@Kathy: Migrate custDB to new server DBCust (Move Acc_CustomerSelCheckEnable to DBCUST.CustDB) [Redmine:#36216]
	- 20150904@Helen: commission setting for MO [Redmine #41470]
	- 20160613@Helen: Security Prevention Step 1 - Cross level update -  [Redmine:55377]			            
	
Param's Explanation:
• @custid: custid that need to be viewed.   
• @groupa: groupa's discount value
• @groupb: groupb's discount value
• @groupc: groupc's discount value
• @discount1x2: group1x2's discount value
• @discountcs: other commission value

• @userid: updater id
• @subaccid: subaccId if any
• @language: updater's language
• @ip: updater's ip
• @errcode: error code
• @errmsg: error message if errcode > 0
*/

	SET NOCOUNT ON

	--Check disable user
	EXEC dbo.Acc_CustomerSelCheckEnable @custid = @custid, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
	if @ErrCode <>0 return
	--end

	DECLARE @roleid TINYINT
	
	SET @roleid = (SELECT roleid FROM Custinfo WITH (NOLOCK) WHERE custid = @custid)	
	
	-- Only direct upline have update permission
	IF NOT EXISTS (SELECT 1 FROM dbo.f_AGE_IsCrossLevelUpdate(@custid,@roleid,@userid))
	BEGIN
		SELECT @ErrMsg = 'You don''t have permission to perform this action.',
			   @ErrCode = 103
		RETURN
	END
	----------------------------------------------
	--Update Commission
	Declare @updatecomm_old bit
	Declare @groupa_old decimal(9,8),
		@groupb_old decimal(9,8),
		@groupc_old decimal(9,8),
		@groupd_old decimal(9,8),
		@discountcs_old decimal(9,8),
		@discount1x2_old decimal(9,8),
		@discountHRFixedOdds_old decimal(9,8),
		@discountnumber_old decimal(9,8),
		@discountMyanmarOdds_old decimal(9,8)

	-- Update Agent Commission --
	
	-- For Myanmar Odds
	DECLARE @IsMyanmarOdds BIT = 0
	
	SET @IsMyanmarOdds = dbo.fn_IsMyanmarOdds (@custid)
		
	IF @IsMyanmarOdds = 1
	BEGIN
		-- Get old value
		SET @discountMyanmarOdds_old = (SELECT CommRate FROM AgentCommRate WITH (NOLOCK) WHERE CustId = @custid AND Sporttype = 1 AND Bettype = 301)
		
	END
	
	select @groupa_old = groupa, @groupb_old = groupb, @groupc_old = groupc, @groupd_old = groupd
	from custsetting (nolock) where custid = @custid and sporttype = 1 and bettype = 1

	select @discountcs_old = discount
	from custsetting (nolock) where custid = @custid and sporttype = 1 and bettype = 4

	select @discount1x2_old = discount
	from custsetting (nolock) where custid = @custid and sporttype = 1 and bettype = 5

	select @discountHRFixedOdds_old = discount
	from custsetting (nolock) where custid = @custid and sporttype = 154 and bettype = 20

	select @discountnumber_old = discount
	from custsetting3rd (nolock) where custid = @custid and sporttype = 161 and bettype = 81

	if (@groupa_old <> @groupa) or (@groupb_old <> @groupb) or (@groupc_old <> @groupc) or (@groupd_old <> @groupd)
		or (@discountcs_old <> @discountcs) or (@discount1x2_old <> @discount1x2) or (@discountnumber_old <> @discountnumber) or (@discountHRFixedOdds_old <> @discountHRFixedOdds)
		OR (@IsMyanmarOdds = 1 AND @discountMyanmarOdds <> @discountMyanmarOdds_old)
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
			@discountcs = @discountcs, --other comm
			@discount1x2 = @discount1x2, --1x2
			@discountnumber = @discountnumber, 
			@discountHRFixedOdds = @discountHRFixedOdds, --1x2
			
			@discountMyanmarOdds = @discountMyanmarOdds,
			@discountMyanmarOdds_old = @discountMyanmarOdds_old,
			@IsMyanmarOdds = @IsMyanmarOdds,
			
			@updatecomm_old = @updatecomm_old,
			@SubAccID = @SubAccID,
			@UserID = @UserID,
			@Language = @Language,
			@IP = @IP,
			@ErrCode = @ErrCode OUTPUT,
			@ErrMsg = @ErrMsg OUTPUT
	end
END
GO
GRANT EXECUTE ON [dbo].[Age_CustomerUpdAgentComm] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Age_CustomerUpdAgentComm] TO [bodbExtAccNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Age_CustomerUpdAgentComm] TO [vnteam] AS [dbo]