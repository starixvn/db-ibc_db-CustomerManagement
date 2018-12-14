/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,bodbDownlineNet,bodbExtAccNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerUpdCredit]
	@custid int,
	@NewCredit money,
	@maxcredit money = null, -- max credit agent give member 	
	@SubAccID int = 0, --Sub-AccountID	
	@UserID int,
	@Language varchar(2) = 'E',
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@ErrCode int = 0 OUTPUT,
	@IP varchar(15)=''
AS

/*
Created: 
Task : Update given credit of customer
DB: DBCUST/CustDB
Original:

Revisions:
    - 20090314@HanhVu: add Korean language
    - 20090517@Phuc: update maxcredit on table CustAgent.
    - 20090521@PhuongDao: Not to update maxcredit on custinfo 
    - 20090723@Phuc: Write log subaccname instead of subaccid.
    - 20090903@Simon: Write Credit Log into Userlog_Credit table.
	- 20090917@Phuc: write log into DBLOG.
	- 20090926@Jamie: Check the conditions before updating credit and writing log 
	- 20091012@Kiwi: remove custBetCredit
	- 20100102@Kiwi: Modify Log.
	- 20100804@Henry: Grant execute permission to [bodbExtAccNet]
	- 20110513@Amy: Add check MaxExposure for Number Game (Remove Finance)
	- 20121128@Elodie: Get an error message from f_Get_MsgNameByMsgID function by language
	- 20130218@Dan: Write more log on DBTXN server in case of DBLOG server failure
	- 20131108@Elodie: Splitting bodb02 into CustDB (call Acc_CustomerSelMaxExposure_Ag by link database)
	- 20140224@Lukas: remove maxExposure
	- 20140306@Dom: add outstanding from translog
	- 20150612@Elodie: Separate CustDB to DBCUST server (use Acc_CustomerTotalAmountSel to get total amount)
	- 20160217@Percy: Check net position of Cricket [Redmine: #50028]
	- 20181101@Johnson: Apply service broker for logging [Redmine: #103547]
Param's Explanation:
• @ErrCode:
    = 0: Update successfully.
    > 0: Specific Error.
  
• @ErrMsg: Error description.		
*/

SET NOCOUNT ON
---------------------------
/*--20090820@Thien: not check this function so that upline can get back the used credit
EXEC DB053.bodb02.dbo.Acc_CustomerSelCheckEnable @custid = @custid, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
if @ErrCode <>0 return
*/

Declare @roleid tinyint, @srecommend int, @mrecommend int, @recommend int
Declare @Credit_AllMaster money, @Credit_AllMember money, @Credit_SAg money, @Credit_AllAgent money,
		@Credit_AllOtherMaster money, 
		@Credit_AllOtherAgent money, @Credit_MAg money,
		@OldCredit MONEY,
		@OldMaxCredit MONEY,
		@AgentCredit MONEY,
		@TotalUse MONEY,
		@Credit_AllOtherMember MONEY,
		@MaxExposure money,
		@MaxExposurev2 money,
		@MaxExposurev3 money,
		@MaxExposurev5 money,
		@MaxExposurev8 money,
		@MaxExposurev10 money,
		@MaxExposurev11 money,
		@MaxExposurev12 money,
		@MaxExposurev151 money,
		@MaxExposurev161 money,
		@MaxExposurev99 money,		
		@matchlimit smallmoney,
		
		@username varchar(40)
	

select	@username = username,
		@roleid = roleid,
		@srecommend = srecommend,
		@mrecommend = mrecommend,
		@recommend = recommend,
		@MatchLimit = isnull(ci.matchlimit, 1),
		@OldCredit = Credit
from	custinfo ci WITH(NOLOCK)
where	custid = @custid

SELECT	@OldMaxCredit = maxcredit 
FROM	CustAgent WITH(NOLOCK)
WHERE	custid = @custid and @roleid = 2

IF @NewCredit = @OldCredit AND (@maxcredit IS NULL OR ISNULL(@maxcredit,0) = ISNULL(@OldMaxCredit,0))
	RETURN

select @roleid = isnull(@roleid, 0)

if @roleid not in (1,2,3,4)
BEGIN
	Select @ErrMsg = case @Language 
						when 'E' then 'Invalid user!!'
						ELSE [dbo].[f_Get_MsgNamebyMsgID](40002,@Language)			
					end	,
		@ErrCode = 100	
	return
END

if @roleid = 1
BEGIN

	
	DECLARE	@netPosition MONEY
		SELECT @netPosition = ISNULL(SUM(Credit - Debit), 0)
		FROM DBTXN.bodb02.dbo.BalNetPosition WITH (NOLOCK) WHERE custid = @custid

	SELECT @Credit_AllOtherMember = ISNULL(SUM(Credit), 0)	 
	FROM custinfo WITH(NOLOCK) 
	WHERE Recommend = @Recommend AND RoleID = 1 AND CustID <> @CustID

	--Vinh@20081201: Add check max credit of agent when update credit on member-------------------------------------------------

	declare @AgentMaxCredit money, @Agent_Credit_Bal MONEY, @Credit_Mem_Max MONEY

	SELECT	@AgentCredit = ISNULL(Credit, 0) FROM custinfo WITH(NOLOCK) WHERE CustID = @Recommend
	
	SELECT	@AgentMaxCredit =ISNULL(maxcredit,0) FROM CustAgent WITH(NOLOCK) WHERE CustID = @Recommend

	Set @Agent_Credit_Bal = @AgentCredit - @Credit_AllOtherMember
	SELECT @Credit_Mem_Max = CASE WHEN  @AgentMaxCredit = 0 THEN @Agent_Credit_Bal
							      WHEN  @AgentMaxCredit > @Agent_Credit_Bal THEN @Agent_Credit_Bal
							      ELSE @AgentMaxCredit END 

	-----------------------------------------------------------------------------------------------------------------	
	EXEC DBTXN.bodb02.dbo.Acc_CustomerTotalAmountSel @CustID = @custid, @TotalAmt = @TotalUse OUTPUT

	--SELECT  @TotalUse = ISNULL(SUM(winlost-actual_stake+playercomm), 0) FROM bodb02.dbo.bettrans WITH(NOLOCK) WHERE custid=@custid
	--SELECT  @TotalUse = @TotalUse + ISNULL(SUM(-actual_stake), 0) FROM bodb02.dbo.translog WITH(NOLOCK) WHERE custid=@custid AND statusID=0
	/*
	EXEC bodb02.dbo.Acc_CustomerSelMaxExposure_Ag @custid = @custid, @sporttype=1, @MaxExposure = @MaxExposure OUTPUT
	EXEC bodb02.dbo.Acc_CustomerSelMaxExposure_Ag @custid = @custid, @sporttype=2, @MaxExposure = @MaxExposurev2 OUTPUT
	EXEC bodb02.dbo.Acc_CustomerSelMaxExposure_Ag @custid = @custid, @sporttype=3, @MaxExposure = @MaxExposurev3 OUTPUT
	EXEC bodb02.dbo.Acc_CustomerSelMaxExposure_Ag @custid = @custid, @sporttype=5, @MaxExposure = @MaxExposurev5 OUTPUT
	EXEC bodb02.dbo.Acc_CustomerSelMaxExposure_Ag @custid = @custid, @sporttype=8, @MaxExposure = @MaxExposurev8 OUTPUT
	EXEC bodb02.dbo.Acc_CustomerSelMaxExposure_Ag @custid = @custid, @sporttype=10, @MaxExposure = @MaxExposurev10 OUTPUT
	EXEC bodb02.dbo.Acc_CustomerSelMaxExposure_Ag @custid = @custid, @sporttype=11, @MaxExposure = @MaxExposurev11 OUTPUT
	EXEC bodb02.dbo.Acc_CustomerSelMaxExposure_Ag @custid = @custid, @sporttype=12, @MaxExposure = @MaxExposurev12 OUTPUT
	EXEC bodb02.dbo.Acc_CustomerSelMaxExposure_Ag @custid = @custid, @sporttype=151, @MaxExposure = @MaxExposurev151 OUTPUT
	EXEC bodb02.dbo.Acc_CustomerSelMaxExposure_Ag @custid = @custid, @sporttype=161, @MaxExposure = @MaxExposurev161 OUTPUT
	EXEC bodb02.dbo.Acc_CustomerSelMaxExposure_Ag @custid = @custid, @sporttype=99, @MaxExposure = @MaxExposurev99 OUTPUT
	*/
	IF @TotalUse+@NewCredit+@netPosition<0
	BEGIN
		SELECT @ErrMsg =  @UserName + ': ' +
						CASE @Language 
							WHEN 'E' THEN 'Cannot reduce credit. Member outstanding exceeded.'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](70006,@Language)
						END	, @ErrCode = 101		
		RETURN 
	END

	IF @NewCredit + @Credit_AllOtherMember>@AgentCredit 
	BEGIN
		SELECT @ErrMsg =  @UserName + ': ' +
						CASE @Language 
							WHEN 'E' THEN 'Sorry, increase credit unsuccessfully. You have exceeded your agent credit.'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](70003,@Language)
						END	, @ErrCode = 101		
		RETURN
	END

	IF @NewCredit > @Credit_Mem_Max--Vinh@20081201: Add check max credit of agent when update credit on member
	BEGIN
		SELECT @ErrMsg =  @UserName + ': ' +
						CASE @Language 
							WHEN 'E' THEN 'Sorry, credit increase is unsuccessful, You have exceeded member max credit given by your upline (' + convert(varchar(20), @Credit_Mem_Max) + ').'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](70013,@Language) + ' (' + convert(varchar(20), @Credit_Mem_Max) + ').'
						END	, @ErrCode = 102
		return
	END

	/*
	if NOT exists (select 1 from customer with(nolock) where custid = @Recommend and site = '12Bet')
	BEGIN
		IF @MaxExposure
		+@MaxExposurev2
		+@MaxExposurev3
		+@MaxExposurev5
		+@MaxExposurev8
		+@MaxExposurev10
		+@MaxExposurev11
		+@MaxExposurev12
		+@MaxExposurev151
		+@MaxExposurev161
		+@MaxExposurev99>@NewCredit*@MatchLimit
		BEGIN
			SELECT @ErrMsg =  @UserName + ': ' +
							CASE @Language 
								WHEN 'E' THEN 'Cannot reduce credit. Member outstanding exceeded.'
								ELSE [dbo].[f_Get_MsgNamebyMsgID](70006,@Language)
							END, @ErrCode = 102
		return
		END
	END
	*/
	
	
	
END
else if @roleid = 2
BEGIN	

	Select @Credit_AllMember = isnull(sum(credit), 0)
	from custinfo WITH(NOLOCK)
	where recommend = @CustID and RoleID=1

	--Vinh@20081201: Add check and update max credit on agent-------------------------------------------------
	if @maxcredit is not null
	BEGIN
		declare @MaxCredit_Mem_Min money

		select @MaxCredit_Mem_Min = max(isnull(credit,0)) 
		from custinfo WITH(NOLOCK)
		where recommend = @CustId and roleid =1 

		if @MaxCredit_Mem_Min > @maxcredit and (isnull(@maxcredit,0) > 0)
		BEGIN
			SELECT @ErrMsg =	@UserName + ': '+
							case @Language 
								when 'E' then 'Max credit update not successful, The new max credit is less than the credit of the current members!!!'
								ELSE [dbo].[f_Get_MsgNamebyMsgID](70015,@Language)
							end
							+' (' + convert(varchar(20), @Credit_AllMember) + ').', @ErrCode = 119					 
			return
		END 

		if @maxcredit > @newcredit 
		BEGIN
			SELECT @ErrMsg =	@UserName + ': '+
							case @Language 
								when 'E' then 'Max credit update not successful, The new max credit is greater than the credit of the agent'
								ELSE [dbo].[f_Get_MsgNamebyMsgID](70016,@Language)
							end
							+' (' + convert(varchar(20), @Credit_AllMember) + ').', @ErrCode = 120					 
			return
		END 	
	END
	------------------------------------------------------------------------------------------------------------

	Select @Credit_AllOtherAgent = isnull(sum(credit), 0)
	from custinfo WITH(NOLOCK)
	where mrecommend = @mrecommend and RoleID=2 and CustID <> @CustID
	
	Select @Credit_MAg = isnull(credit, 0)
	from custinfo WITH(NOLOCK)
	where custid = @mrecommend

	if @Credit_AllOtherAgent + @NewCredit >@Credit_MAg
	BEGIN
		SELECT @ErrMsg =  @UserName + ': '+
						case @Language 
							when 'E' then 'Sorry, credit update is not successful, You have exceeded your master credit.'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](70011,@Language)
						end, @ErrCode = 201
		return
	END
	if @Credit_AllMember>@NewCredit 
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'Credit update not successful, The new credit is not enough for all current members'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](70017,@Language)
						end
						+' (' + convert(varchar(20), @Credit_AllMember) + ').', @ErrCode = 202
		return
	END
END
else if @roleid = 3
BEGIN
	Select @Credit_AllOtherMaster = isnull(sum(credit), 0)		
	from custinfo WITH(NOLOCK)
	where srecommend = @srecommend and RoleID=3 and CustID <> @CustID
	
	Select @Credit_AllMember = isnull(sum(credit), 0)
	from custinfo WITH(NOLOCK)
	where mrecommend = @CustID and RoleID=1
	
	Select @Credit_AllAgent = isnull(sum(credit), 0)		
	from custinfo WITH(NOLOCK)
	where mrecommend = @CustID and RoleID=2
	
	Select @Credit_SAg = isnull(credit, 0)
	from custinfo WITH(NOLOCK)
	where custid = @srecommend

	if @Credit_AllOtherMaster + @NewCredit >@Credit_SAg and @srecommend>100
	BEGIN
		SELECT @ErrMsg =  @UserName + ': '+
						case @Language 
							when 'E' then 'Sorry, credit update is not successful, You have exceeded your super agent credit.'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](70010,@Language) 
						end	, @ErrCode = 301		
		return
	END
	if @Credit_AllMember>@NewCredit and @srecommend>100
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'Sorry, credit update is not successful, You have exceeded your master credit.'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](70011,@Language)
						end						
						+' (' + convert(varchar(20), @Credit_AllMember) + ').', @ErrCode = 302
		return
	END
	if @Credit_AllAgent>@NewCredit and @srecommend>100
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'Credit update not successful, The new credit is not enough for all current agents'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](70018,@Language)
						end						
						+' (' + convert(varchar(20), @Credit_AllAgent) + ').', @ErrCode = 303
		return
	END
END
else if @roleid = 4
BEGIN
	Select @Credit_AllMaster = isnull(sum(credit), 0)	
	from custinfo WITH(NOLOCK)
	where srecommend = @custid and RoleID=3
	
	Select @Credit_AllMember = isnull(sum(credit), 0)	
	from custinfo WITH(NOLOCK)
	where srecommend = @CustID and RoleID=1

	Select @Credit_AllAgent = isnull(sum(credit), 0)	
	from custinfo WITH(NOLOCK)
	where srecommend = @CustID and RoleID=2

	if @Credit_AllMaster>@NewCredit 
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'Credit update not successful, The new credit is not enough for all current masters'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](70019,@Language)
						end						
						+' (' + convert(varchar(20), @Credit_AllMaster) + ').', @ErrCode = 401
		return
	END

	if @Credit_AllAgent>@NewCredit 
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'Credit update not successful, The new credit is not enough for all current agents'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](70018,@Language)
						end						
						+' (' + convert(varchar(20), @Credit_AllAgent) + ').', @ErrCode = 402
		return
	END

	if @Credit_AllMember>@NewCredit 
	BEGIN
		SELECT @ErrMsg =	@UserName + ': '+
						case @Language 
							when 'E' then 'Credit update not successful, The new credit is not enough for all current members'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](70017,@Language)
						end						
						+' (' + convert(varchar(20), @Credit_AllMember) + ').', @ErrCode = 403
		return
	END
END

IF @NewCredit != @OldCredit
BEGIN
	update	custinfo WITH (ROWLOCK, updlock) 
	set		credit = @NewCredit
	where	custid = @custid
END

IF ISNULL(@maxcredit,0) != ISNULL(@OldMaxCredit,0)
BEGIN
	UPDATE	CustAgent WITH(ROWLOCK,UPDLOCK)
	SET		maxcredit = isnull(@maxcredit, maxcredit)
	WHERE	custid = @custid and @roleid = 2
END

--Write Log Credit
Declare @LogData varchar(500)
Select @LogData = 'Update Given Credit for Account '+ coalesce(cast(@username as varchar(30)),space(1)) 

IF ((@maxcredit IS NOT NULL) AND ISNULL(@maxcredit,0) != ISNULL(@OldMaxCredit,0))
BEGIN
	Select @LogData = @LogData + ' - ' + 'Member''s Max Credit (from ' + coalesce(cast(@OldMaxCredit as varchar(50)),space(1)) + ' to ' + coalesce(cast(@maxcredit as varchar(50)),space(1)) + ')'
END

-- ***Check Sub-Account***  
IF @SubAccID > 0 
BEGIN
	SET @LogData = @LogData + ' by Sub-Account:' +  COALESCE(CAST(dbo.f_GetSubUsername(@SubAccID) AS VARCHAR(30)),SPACE(1))
END
---------------------------  
DECLARE @log xml, @SB_Error BIT = 0
 
SELECT @log = (SELECT @UserID as '@UserID',
					@custid as '@CustID',
					@LogData as '@Doing',
					@OldCredit as '@OldValue',
					@NewCredit as '@NewValue',
					@IP as '@IP',
					1200 as '@ActionID',
					getdate() as '@LogDate'
				FOR XML PATH('Row')	
			)

EXEC bodb_CustomerLog.sb.CustomerLog_SendMessage @xml = @log, 
												@MessageType='MessageType_CustomerLog_UserLog_Credit', 
												@functionName = 'UserLog_Others',
												@SB_Error = @SB_Error out

--if ssb error
IF @SB_Error = 1 
BEGIN			
	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Credit
			@UserID = @UserID,
			@CustID = @CustID,
			@Doing = @LogData,
			@OldValue = @OldCredit,
			@NewValue = @NewCredit,
			@IP = @IP,
			@ActionID = 1200
	END TRY
	BEGIN CATCH
		SET @LogData = @LogData + ' ErrMsg:' + ERROR_MESSAGE() 
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Credit
			@UserID = @UserID,
			@CustID = @CustID,
			@Doing = @LogData,
			@OldValue = @OldCredit,
			@NewValue = @NewCredit,
			@IP = @IP,
			@ActionID = 1200		
	END CATCH
END

GO
