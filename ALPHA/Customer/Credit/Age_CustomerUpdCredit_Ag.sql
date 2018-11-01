/*<info serverAlias="DBCUST-CUSTDB" executers="bodbDownlineNet" viewers="vnteam" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CustomerUpdCredit_Ag]  
	@UserID			INT,
	@CustID			INT, -- memberID
	@SubAccID		INT				= 0, -- Sub-AccountID
	@CreditAmt		MONEY,
	@IP				VARCHAR(15)		= '',
	@Language		VARCHAR(2)		= 'E',
	@CreditProblem	BIT				= 0 OUTPUT,
	@ErrMsg			NVARCHAR(500)	= '' OUTPUT
AS

/*  
	Created: 20090211@xxx  
	Task: Update customer credit  
	DB: DBCUST.CustDB
	Original:  
  
	Revisions:      
		- 20090318@Hanh: add Korean language  
		- 20090521@PhuongDao: Get maxcredit from CustAgent   
		- 20090729@Phuc: Write log subaccname instead of subaccid.  
		- 20090818@Phuc: check page access and check upline closed first(call Age_CustSubCheckPageAccess)  
		- 20090903@Simon: Write Credit Log into Userlog_Credit table.  
		- 20090917@Phuc: write log into DBLOG.  
		- 20090929@Jamie: Check the old credit and the new credit before updating  
		- 20091012@Kiwi: Remove CustBetCreditUpdResync  
		- 20100101@Kiwi: Modify Log.   
		- 20121128@Elodie: Get an error message from f_Get_MsgNameByMsgID function by language  
		- 20130218@Dan: Write more log on DBTXN server in case of DBLOG server failure  
		- 20131108@Elodie: Splitting bodb02 into CustDB (Call bettrans from bodb02 by link database)  
		- 20140225@Lukas: edit error message to remove special charecter '/n' (msgID = 70007)  
		- 20140306@Kathy: modify formula of Outstanding amount to be calculated based on table Bettrans and TransLog [Redmine:#11550]  
		- 20150228@Kiwi: restrict to allow the agent update given credit for member only [Redmine:31476]  
		- 20150612@Elodie: Separate CustDB to DBCUST server (Move Acc_CustomerSelCheckAllowedDownlines to DBCUST.CustDB, use Acc_CustomerTotalAmountSel to get total amount)  
		- 20171107@Percy: Prevent user from decreasing given credit due to data processing [RedmineID: #82834]
		- 20181101@Johnson: Apply service broker for logging [Redmine: #103547]
	Param's Explanation:  
		• @custid: custid that need to be updated   
		• @CreditAmt: new credit   
*/

BEGIN
	SET NOCOUNT ON

	DECLARE
		@Credit_AllOtherMember MONEY,
		@Credit_Ag MONEY,
		@MaxCredit_Ag MONEY,
		@TotalAmt MONEY

	DECLARE @ErrCode INT = 0
  
	DECLARE @AgID INT, @username VARCHAR(50), @OldCredit MONEY, @RoleID TINYINT
	SELECT  @AgID = recommend, @username = username, @OldCredit = Credit, @RoleID = roleid
	FROM dbo.custInfo WITH (NOLOCK)
	WHERE custid = @CustID

	IF (ISNULL(@RoleID, 0) <> 1)
	BEGIN
		SELECT @ErrMsg = CASE @Language WHEN 'E' THEN 'Invalid user!!' ELSE [dbo].[f_Get_MsgNamebyMsgID](40002, @Language) END
		RETURN
	END
  
	IF ISNULL(@OldCredit, 0) = ISNULL(@CreditAmt, 0)
		RETURN

	SELECT @Credit_AllOtherMember = ISNULL(SUM(ISNULL(credit, 0)), 0)
	FROM dbo.custInfo WITH (NOLOCK)  
	WHERE recommend = @AgID AND roleid = 1 AND custid <> @CustID

	SELECT @Credit_Ag = ISNULL(credit, 0)
	FROM dbo.custInfo WITH (NOLOCK)  
	WHERE custid = @AgID  

	-- Get Max Credit from CustAgent   
	SELECT @MaxCredit_Ag = ISNULL(maxcredit, 0)
	FROM dbo.CustAgent WITH (NOLOCK)
	WHERE custid = @AgID
	
	-- 1st
	-- Prevent user from decreasing given credit due to processing data
	IF ISNULL(@OldCredit, 0) > ISNULL(@CreditAmt, 0)
	BEGIN
		EXEC DBTXN.bodb02.dbo.Acc_Core_IsMainProcessRunning
			@CustId = @CustID,
			@UplineId = @AgID,
			@IsDepositMember = 0,
			@ErrCode = @ErrCode OUTPUT,
			@ErrMsg = @ErrMsg OUTPUT

		IF @ErrCode <> 0
		BEGIN
			SELECT @ErrMsg = CASE @Language WHEN 'E' THEN 'Data processing is in progress, thus Given Credit cannot be reduced. Please try again in a few minutes.'
								ELSE [dbo].[f_Get_MsgNamebyMsgID](70022, @Language) END
			
			SELECT @CreditProblem = 1

			RETURN
		END
	END

	EXEC DBTXN.bodb02.dbo.Acc_CustomerTotalAmountSel @CustID = @custid, @TotalAmt = @TotalAmt OUTPUT  
	
	-- 2nd
	-- Prevent user from decreasing given credit due to processing data
	IF ISNULL(@OldCredit, 0) > ISNULL(@CreditAmt, 0)
	BEGIN
		EXEC DBTXN.bodb02.dbo.Acc_Core_IsMainProcessRunning
			@CustId = @CustID,
			@UplineId = @AgID,
			@IsDepositMember = 0,
			@ErrCode = @ErrCode OUTPUT,
			@ErrMsg = @ErrMsg OUTPUT

		IF @ErrCode <> 0
		BEGIN
			SELECT @ErrMsg = CASE @Language WHEN 'E' THEN 'Data processing is in progress, thus Given Credit cannot be reduced. Please try again in a few minutes.'
								ELSE [dbo].[f_Get_MsgNamebyMsgID](70022, @Language) END
			
			SELECT @CreditProblem = 1
			
			RETURN
		END
	END

	SELECT @TotalAmt = ISNULL(@TotalAmt, 0)

	IF @CreditAmt + @TotalAmt < 0
	BEGIN
		SELECT	@CreditProblem = 1,
				@ErrMsg = CASE @Language WHEN 'E' THEN 'Cannot reduce credit. Member outstanding exceeded.'  
							ELSE [dbo].[f_Get_MsgNamebyMsgID](70006, @Language) END
		RETURN
	END
	
	IF @Credit_AllOtherMember + @CreditAmt > @Credit_Ag
	BEGIN
		SELECT	@CreditProblem = 1,
				@ErrMsg = CASE @Language WHEN 'E' THEN 'Sorry, increase credit unsuccessfully. You have exceeded your agent credit.'  
							ELSE [dbo].[f_Get_MsgNamebyMsgID](70003, @Language) END
		RETURN 
	END

    DECLARE @Agent_Credit_Bal MONEY, @Credit_Mem_Max MONEY
  
    SELECT  @Agent_Credit_Bal	= @Credit_Ag - @Credit_AllOtherMember
    SELECT  @Credit_Mem_Max		= CASE
									WHEN @MaxCredit_Ag = 0 THEN @Agent_Credit_Bal
									WHEN @MaxCredit_Ag > @Agent_Credit_Bal THEN @Agent_Credit_Bal  
									ELSE @MaxCredit_Ag END
  
    IF @CreditAmt > @Credit_Mem_Max
    BEGIN  
        SELECT	@CreditProblem = 1,
				@ErrMsg = CASE @Language WHEN 'E' THEN 'Sorry, increase credit unsuccessfully. You have exceeded the agent''s member max credit'
                            ELSE [dbo].[f_Get_MsgNamebyMsgID](70007, @Language) END
						 + ' (' + convert(varchar(20), @Credit_Mem_Max) + ').'
        RETURN
    END
	
	UPDATE dbo.custInfo WITH (ROWLOCK)
	SET credit = @CreditAmt
	WHERE CustID = @CustID
      
	-- Write Log
	DECLARE @LogData VARCHAR(500)
	SELECT  @LogData = 'Update credit for member account ' + COALESCE(@username, SPACE(1))

	IF @SubAccID > 0
	BEGIN  
		SELECT @LogData = @LogData + ' by Sub-Account ' + COALESCE(dbo.f_GetSubUsername(@SubAccID), SPACE(1))
	END
	
	DECLARE @log xml, @SB_Error BIT = 0
 
	SELECT @log = (SELECT @UserID as '@UserID',
						@custid as '@CustID',
						@LogData as '@Doing',
						@OldCredit as '@OldValue',
						@CreditAmt as '@NewValue',
						@IP as '@IP',
						1203 as '@ActionID'
					FOR XML PATH('Row')	
				)

	EXEC bodb_CustomerLog.sb.CustomerLog_SendMessage @xml = @log, 
													@MessageType='MessageType_CustomerLog_UserLog_Credit', 
													@functionName = 'UserLog_Credit',
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
				@NewValue = @CreditAmt,  
				@IP = @IP,  
				@ActionID = 1203  
		END TRY  
		BEGIN CATCH  
			SELECT @LogData = @LogData + ' ErrMsg=' + ERROR_MESSAGE()
		  
			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Credit  
				@UserID = @UserID,  
				@CustID = @CustID,  
				@Doing = @LogData,  
				@OldValue = @OldCredit,  
				@NewValue = @CreditAmt,  
				@IP = @IP,  
				@ActionID = 1203          
		END CATCH
	END	
END
GO

