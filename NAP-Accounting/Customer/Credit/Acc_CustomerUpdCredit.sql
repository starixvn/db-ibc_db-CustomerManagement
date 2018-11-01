USE [CustDB]
GO

ALTER PROCEDURE [dbo].[Acc_CustomerUpdCredit]
	@CustId		INT,
	@NewCredit	MONEY,
	@MaxCredit	MONEY			= NULL, -- max credit agent give member
	@SubAccID	INT				= 0, --Sub-AccountID
	@UserID		INT,
	@Language	VARCHAR(2)		= 'E',
	@IP			VARCHAR(15)	= '',
	@ErrCode	INT				= 0 OUTPUT,
	@ErrMsg		NVARCHAR(500)	= '' OUTPUT
AS

/*
	Created: 
	Task: Update given credit of customer
	DB: DBCUST.CustDB

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
		- 20171107@Percy: Prevent user from decreasing given credit due to data processing [RedmineID: #82834]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @roleid TINYINT, @srecommend INT, @mrecommend INT, @recommend INT, @username VARCHAR(50), @uplineId INT, @IsDepositMember BIT

	DECLARE @Credit_AllMaster MONEY, @Credit_AllMember MONEY, @Credit_SAg MONEY, @Credit_AllAgent MONEY,
			@Credit_AllOtherMaster MONEY, 
			@Credit_AllOtherAgent MONEY, @Credit_MAg MONEY,
			@OldCredit MONEY,
			@OldMaxCredit MONEY,
			@AgentCredit MONEY,
			@TotalAmt MONEY,
			@Credit_AllOtherMember MONEY,
			@matchlimit SMALLMONEY

	SELECT	@username = username,
			@roleid = roleid,
			@srecommend = srecommend,
			@mrecommend = mrecommend,
			@recommend = recommend,
			@MatchLimit = ISNULL(matchlimit, 1),
			@OldCredit = Credit
	FROM	dbo.custInfo WITH (NOLOCK)
	WHERE	custid = @custid

	SELECT	@OldMaxCredit = maxcredit
	FROM	dbo.CustAgent WITH (NOLOCK)
	WHERE	custid = @custid AND @roleid = 2 -- agent only

	IF ISNULL(@NewCredit, 0) = ISNULL(@OldCredit, 0) AND (@MaxCredit IS NULL OR ISNULL(@MaxCredit, 0) = ISNULL(@OldMaxCredit, 0))
		RETURN

	SELECT @roleid = ISNULL(@roleid, 0)

	IF @roleid NOT IN (1,2,3,4)
	BEGIN
		SELECT	@ErrCode = 100,
				@ErrMsg = CASE @Language WHEN 'E' THEN 'Invalid user!!' ELSE [dbo].[f_Get_MsgNamebyMsgID](40002, @Language) END			
		RETURN
	END

	IF EXISTS (SELECT 1 FROM dbo.Dep_CustSuper WITH (NOLOCK) WHERE custid = @srecommend)
		SELECT @IsDepositMember = 1
	ELSE
		SELECT @IsDepositMember = 0

	IF @roleid = 1
	BEGIN
		SELECT @uplineId = @recommend

		SELECT @Credit_AllOtherMember = ISNULL(SUM(ISNULL(Credit, 0)), 0)
		FROM dbo.custInfo WITH (NOLOCK) 
		WHERE recommend = @recommend AND roleid = 1 AND CustID <> @CustID

		DECLARE @AgentMaxCredit MONEY, @Agent_Credit_Bal MONEY, @Credit_Mem_Max MONEY

		SELECT	@AgentCredit = ISNULL(Credit, 0)
		FROM dbo.custInfo WITH (NOLOCK) 
		WHERE CustID = @recommend
	
		SELECT	@AgentMaxCredit = ISNULL(maxcredit, 0)
		FROM dbo.CustAgent WITH (NOLOCK)
		WHERE CustID = @recommend

		SELECT @Agent_Credit_Bal	= @AgentCredit - @Credit_AllOtherMember
		SELECT @Credit_Mem_Max		= CASE
										WHEN @AgentMaxCredit = 0 THEN @Agent_Credit_Bal
										WHEN @AgentMaxCredit > @Agent_Credit_Bal THEN @Agent_Credit_Bal
										ELSE @AgentMaxCredit END

		-- Prevent user from decreasing given credit due to processing data
		-- Must check before and after get total amount
		IF ISNULL(@OldCredit, 0) > ISNULL(@NewCredit, 0)
		BEGIN
			EXEC DBTXN.bodb02.dbo.Acc_Core_IsMainProcessRunning
				@CustId = @CustID,
				@UplineId = @uplineId,
				@IsDepositMember = @IsDepositMember,
				@ErrCode = @ErrCode OUTPUT,
				@ErrMsg = @ErrMsg OUTPUT

			IF @ErrCode <> 0
			BEGIN
				SELECT @ErrMsg = CASE @Language WHEN 'E' THEN 'Data processing is in progress, thus Given Credit cannot be reduced. Please try again in a few minutes.'
									ELSE [dbo].[f_Get_MsgNamebyMsgID](70022, @Language) END
				RETURN
			END
		END

		EXEC DBTXN.bodb02.dbo.Acc_CustomerTotalAmountSel @CustID = @custid, @TotalAmt = @TotalAmt OUTPUT

		-- Prevent user from decreasing given credit due to processing data
		IF ISNULL(@OldCredit, 0) > ISNULL(@NewCredit, 0)
		BEGIN
			EXEC DBTXN.bodb02.dbo.Acc_Core_IsMainProcessRunning
				@CustId = @CustID,
				@UplineId = @uplineId,
				@IsDepositMember = @IsDepositMember,
				@ErrCode = @ErrCode OUTPUT,
				@ErrMsg = @ErrMsg OUTPUT

			IF @ErrCode <> 0
			BEGIN
				SELECT @ErrMsg = CASE @Language WHEN 'E' THEN 'Data processing is in progress, thus Given Credit cannot be reduced. Please try again in a few minutes.'
									ELSE [dbo].[f_Get_MsgNamebyMsgID](70022, @Language) END
				RETURN
			END
		END

		IF @TotalAmt + @NewCredit < 0
		BEGIN
			SELECT	@ErrCode = 101,
					@ErrMsg = @UserName + ': ' + CASE @Language WHEN 'E' THEN 'Cannot reduce credit. Member outstanding exceeded.'
													ELSE [dbo].[f_Get_MsgNamebyMsgID](70006, @Language) END
			RETURN 
		END

		IF @NewCredit + @Credit_AllOtherMember > @AgentCredit 
		BEGIN
			SELECT	@ErrCode = 101,
					@ErrMsg =  @UserName + ': ' + CASE @Language WHEN 'E' THEN 'Sorry, increase credit unsuccessfully. You have exceeded your agent credit.'
													ELSE [dbo].[f_Get_MsgNamebyMsgID](70003, @Language) END
			RETURN
		END

		IF @NewCredit > @Credit_Mem_Max
		BEGIN
			SELECT	@ErrCode = 101,
					@ErrMsg =  @UserName + ': ' + CASE @Language WHEN 'E' THEN 'Sorry, credit increase is unsuccessful, You have exceeded member max credit given by your upline'
													ELSE [dbo].[f_Get_MsgNamebyMsgID](70013, @Language) END
												+' (' + CONVERT(VARCHAR(20), @Credit_Mem_Max) + ').'
			RETURN
		END
	END
	ELSE IF @roleid = 2
	BEGIN
		SELECT @uplineId = @mrecommend
			
		SELECT @Credit_AllMember = ISNULL(SUM(ISNULL(credit, 0)), 0)
		FROM dbo.custInfo WITH (NOLOCK)
		WHERE recommend = @CustID AND roleid = 1

		IF @MaxCredit IS NOT NULL
		BEGIN
			DECLARE @MaxCredit_Mem_Min MONEY

			SELECT @MaxCredit_Mem_Min = MAX(ISNULL(credit, 0)) 
			FROM dbo.custInfo WITH (NOLOCK)
			WHERE recommend = @CustId AND roleid = 1 

			IF @MaxCredit_Mem_Min > @maxcredit AND @MaxCredit > 0
			BEGIN
				SELECT	@ErrCode = 119,
						@ErrMsg = @UserName + ': ' + CASE @Language WHEN 'E' THEN 'Max credit update not successful, The new max credit is less than the credit of the current members!!!'
														ELSE [dbo].[f_Get_MsgNamebyMsgID](70015, @Language) END
													+ ' (' + CONVERT(VARCHAR(20), @Credit_AllMember) + ').'
				RETURN
			END 

			IF @maxcredit > @newcredit 
			BEGIN
				SELECT	@ErrCode = 120,
						@ErrMsg = @UserName + ': ' + CASE @Language WHEN 'E' THEN 'Max credit update not successful, The new max credit is greater than the credit of the agent'
														ELSE [dbo].[f_Get_MsgNamebyMsgID](70016, @Language) END
													+ ' (' + CONVERT(VARCHAR(20), @Credit_AllMember) + ').'
				RETURN
			END 	
		END

		SELECT @Credit_AllOtherAgent = ISNULL(SUM(ISNULL(credit, 0)), 0)
		FROM dbo.custInfo WITH (NOLOCK)
		WHERE mrecommend = @mrecommend AND roleid = 2 and CustID <> @CustID
	
		SELECT @Credit_MAg = ISNULL(credit, 0)
		FROM dbo.custInfo WITH (NOLOCK)
		WHERE custid = @mrecommend

		IF @Credit_AllOtherAgent + @NewCredit > @Credit_MAg
		BEGIN
			SELECT	@ErrCode = 201,
					@ErrMsg = @UserName + ': '+ CASE @Language WHEN 'E' THEN 'Sorry, credit update is not successful, You have exceeded your master credit.'
													ELSE [dbo].[f_Get_MsgNamebyMsgID](70011, @Language) END
			RETURN
		END
		
		IF @Credit_AllMember > @NewCredit
		BEGIN
			SELECT	@ErrCode = 202,
					@ErrMsg = @UserName + ': '+ CASE @Language WHEN 'E' THEN 'Credit update not successful, The new credit is not enough for all current members'
													ELSE [dbo].[f_Get_MsgNamebyMsgID](70017, @Language) END
												+ ' (' + CONVERT(VARCHAR(20), @Credit_AllMember) + ').'
			RETURN
		END
	END
	ELSE IF @roleid = 3
	BEGIN
		SELECT @uplineId = @srecommend

		SELECT @Credit_AllOtherMaster = ISNULL(SUM(ISNULL(credit, 0)), 0)
		FROM dbo.custInfo WITH (NOLOCK)
		WHERE srecommend = @srecommend AND RoleID = 3 AND CustID <> @CustID
	
		SELECT @Credit_AllMember = ISNULL(SUM(ISNULL(credit, 0)), 0)
		FROM dbo.custInfo WITH (NOLOCK)
		WHERE mrecommend = @CustID AND RoleID = 1
	
		SELECT @Credit_AllAgent = ISNULL(SUM(ISNULL(credit, 0)), 0)
		FROM dbo.custInfo WITH (NOLOCK)
		WHERE mrecommend = @CustID AND RoleID = 2
	
		SELECT @Credit_SAg = ISNULL(credit, 0)
		FROM dbo.custInfo WITH (NOLOCK)
		WHERE custid = @srecommend

		IF @srecommend > 100
		BEGIN
			IF @Credit_AllOtherMaster + @NewCredit > @Credit_SAg
			BEGIN
				SELECT	@ErrCode = 301,
						@ErrMsg = @UserName + ': ' + CASE @Language WHEN 'E' THEN 'Sorry, credit update is not successful, You have exceeded your super agent credit.'
														ELSE [dbo].[f_Get_MsgNamebyMsgID](70010, @Language) END
				RETURN
			END
			
			IF @Credit_AllMember > @NewCredit
			BEGIN
				SELECT	@ErrCode = 302,
						@ErrMsg = @UserName + ': ' + CASE @Language WHEN 'E' THEN 'Sorry, credit update is not successful, You have exceeded your master credit.'
														ELSE [dbo].[f_Get_MsgNamebyMsgID](70011, @Language) END
													+ ' (' + CONVERT(VARCHAR(20), @Credit_AllMember) + ').'
				RETURN
			END
			
			IF @Credit_AllAgent > @NewCredit
			BEGIN
				SELECT	@ErrCode = 303,
						@ErrMsg = @UserName + ': ' + CASE @Language WHEN 'E' THEN 'Credit update not successful, The new credit is not enough for all current agents'
														ELSE [dbo].[f_Get_MsgNamebyMsgID](70018, @Language) END
													+ ' (' + CONVERT(VARCHAR(20), @Credit_AllAgent) + ').'
				RETURN
			END
		END
	END
	ELSE IF @roleid = 4
	BEGIN
		SELECT @uplineId = @srecommend -- this super

		SELECT @Credit_AllMaster = ISNULL(SUM(ISNULL(credit, 0)), 0)
		FROM dbo.custInfo WITH (NOLOCK)
		WHERE srecommend = @CustID AND RoleID = 3
	
		SELECT @Credit_AllMember = ISNULL(SUM(ISNULL(credit, 0)), 0)
		FROM dbo.custInfo WITH (NOLOCK)
		WHERE srecommend = @CustID AND RoleID = 1

		SELECT @Credit_AllAgent = ISNULL(SUM(ISNULL(credit, 0)), 0)
		FROM dbo.custInfo WITH (NOLOCK)
		WHERE srecommend = @CustID AND RoleID = 2

		IF @Credit_AllMaster > @NewCredit
		BEGIN
			SELECT	@ErrCode = 401,
					@ErrMsg = @UserName + ': ' + CASE @Language WHEN 'E' THEN 'Credit update not successful, The new credit is not enough for all current masters'
													ELSE [dbo].[f_Get_MsgNamebyMsgID](70019, @Language) END
												+ ' (' + CONVERT(VARCHAR(20), @Credit_AllMaster) + ').'
			RETURN
		END

		IF @Credit_AllAgent > @NewCredit 
		BEGIN
			SELECT	@ErrCode = 402,
					@ErrMsg = @UserName + ': ' + CASE @Language WHEN 'E' THEN 'Credit update not successful, The new credit is not enough for all current agents'
													ELSE [dbo].[f_Get_MsgNamebyMsgID](70018, @Language) END
												+ ' (' + CONVERT(VARCHAR(20), @Credit_AllAgent) + ').'
			RETURN
		END

		IF @Credit_AllMember > @NewCredit 
		BEGIN
			SELECT	@ErrCode = 403,
					@ErrMsg = @UserName + ': ' + CASE @Language WHEN 'E' THEN 'Credit update not successful, The new credit is not enough for all current members'
													ELSE [dbo].[f_Get_MsgNamebyMsgID](70017, @Language) END
												+' (' + CONVERT(VARCHAR(20), @Credit_AllMember) + ').'
			RETURN
		END
	END

	UPDATE	dbo.custInfo WITH (ROWLOCK, UPDLOCK) 
	SET		credit = @NewCredit
	WHERE	custid = @custid

	IF ISNULL(@MaxCredit, 0) <> ISNULL(@OldMaxCredit, 0)
	BEGIN
		UPDATE	dbo.CustAgent WITH (ROWLOCK, UPDLOCK)
		SET		MaxCredit = ISNULL(@MaxCredit, MaxCredit)
		WHERE	custid = @custid AND @roleid = 2
	END

	-- Write Log
	DECLARE @LogData VARCHAR(500)
	SELECT  @LogData = 'Update Given Credit for Account '+ COALESCE(@username, SPACE(1))

	IF ((@maxcredit IS NOT NULL) AND ISNULL(@MaxCredit, 0) <> ISNULL(@OldMaxCredit, 0))
	BEGIN
		SELECT @LogData = @LogData + ' - ' + 'Member''s Max Credit '
							+ '(from ' + COALESCE(CAST(@OldMaxCredit AS VARCHAR(50)), SPACE(1))
							+ ' to ' + COALESCE(CAST(@maxcredit AS VARCHAR(50)), SPACE(1)) + ')'
	END

	IF @SubAccID > 0
	BEGIN
		SELECT @LogData = @LogData + ' by Sub-Account:' + COALESCE(dbo.f_GetSubUsername(@SubAccID), SPACE(1))
	END

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
		SELECT @LogData = @LogData + ' ErrMsg:' + ERROR_MESSAGE()

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
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdCredit] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdCredit] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdCredit] TO [bodbExtAccNet]
GO