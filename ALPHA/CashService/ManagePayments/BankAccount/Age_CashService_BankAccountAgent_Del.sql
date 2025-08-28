/*<info serverAlias="DBCUST-AgencyCashService" executers="wsv_CashService"  viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE Age_CashService_BankAccountAgent_Del
	@AgentBankAccountID		INT,			
	@CustID				INT,
	@SubAccID				INT				= 0,
	@IP					VARCHAR(50)			= '',
	@Language				VARCHAR(2)			= 'E',
	@ErrCode				INT				= 0		OUTPUT,
	@ErrMsg				NVARCHAR(1000)		= ''		OUTPUT

AS 
/*  
	Created By: Helios
	Created Date: 2025-04-18
	Description: Agency Cash Service - Manage Payments - Tab Bank Account - Delete BankAccount [Redmine #223896]
	DB: DBCust.AgencyCashService
	
	Revisions:
		- 20250321@Helios: Agency Cash Service [Redmine: #223896]    
		- 20250724@Helios: Agency Cash Service -Customer Setting Sprint 8 [redmine: #235266]
		- 20250822@Helios: Agency Cash Service -Customer Setting Sprint 9 [redmine: #236430]

	Param:
		DECLARE @p1 INT , @p2 VARCHAR(1000)

		EXEC dbo.Age_CashService_BankAccountAgent_Del
			@AgentBankAccountID = 24,
			@CustID = 14373905,
			@SubAccID = 0,
			@IP = '1.1.1.1',
			@Language = 'E',
			@ErrCode = @p1 OUTPUT,
			@ErrMsg = @p2 OUTPUT;

		-- Check output values
		SELECT @p1 AS ErrorCode, @p2 AS ErrorMessage;

	

*/  
BEGIN
	SET NOCOUNT ON;

	DECLARE 
		@startRun		DATETIME ,
		@endRun		DATETIME ,
		@DurationTime	INT
	
	SET @startRun = GETDATE ()
	SELECT @ErrCode = 0 , @ErrMsg = '' 

	-- Use temp table to store only necessary columns
	CREATE TABLE #Old_AgentBankAccount (
		BankAccountStatus     BIT,
		BankAccountNumber     VARCHAR(100),
		AccountHolderName     NVARCHAR(255),
		AccountNickname       NVARCHAR(255),
		PromptPayEnabled      BIT,
		PromptPayMobile       VARCHAR(50),
		BankCode              VARCHAR(10),
		TransTypeList         VARCHAR(10),
		DepositMatching_Agent SMALLINT,
		DepositMatching_Bank  VARCHAR(60)
	);

	INSERT INTO #Old_AgentBankAccount
	(
		BankAccountStatus,
		BankAccountNumber,
		AccountHolderName,
		AccountNickname,
		PromptPayEnabled,
		PromptPayMobile,
		BankCode,
		TransTypeList,
		DepositMatching_Agent,
		DepositMatching_Bank
	)
	SELECT
		ca.BankAccountStatus,
		ca.BankAccountNumber,
		ca.AccountHolderName,
		ca.AccountNickname,
		ca.PromptPayEnabled,
		ca.PromptPayMobile,
		cbl.BankCode,
		ca.TransTypeList,
		ca.DepositMatching,
		cbl.DepositMode
	FROM CashAgentBankAccount ca WITH (NOLOCK)
	INNER JOIN CashBankList cbl WITH (NOLOCK) ON ca.BankID = cbl.BankID
	WHERE ca.AgentID = @CustID
	AND ca.AgentBankAccountID = @AgentBankAccountID
	AND ca.IsActive = 1;

	IF NOT EXISTS (SELECT TOP 1 1 FROM #Old_AgentBankAccount oaba)
	BEGIN
		SELECT  @ErrMsg = N'Invalid parameters', @ErrCode = 100;
		RETURN
	END

	IF EXISTS (SELECT TOP 1 1 FROM #Old_AgentBankAccount oaba)
	BEGIN TRY
		-- UPDATE VALUES
		UPDATE ca
		SET 
				ca.IsActive = 0,
				ca.RepUpdateTime = dbo.f_GetDateTime2()
		FROM CashAgentBankAccount ca WITH (ROWLOCK , UPDLOCK)
		WHERE ca.AgentBankAccountID = @AgentBankAccountID
	END	TRY
	BEGIN CATCH
		SELECT @ErrMsg = ERROR_MESSAGE(), @ErrCode = ERROR_NUMBER();
		RETURN;
	END CATCH

	-- If IsCheck = 1, count check data from CashMemberBankAccount before update for WriteLog
	DECLARE @Exist_MemberBankAccount_Affected INT = 0

	-- Collect old data before update
	SELECT @Exist_MemberBankAccount_Affected = (SELECT COUNT(1)
								  FROM CashMemberBankAccount c WITH (NOLOCK)
								  WHERE c.IsActive = 1 AND c.BankAccountAgentID = @AgentBankAccountID);

	IF @Exist_MemberBankAccount_Affected > 0
	BEGIN TRY
		-- Update BankAccountAgentID to NULL : 
		UPDATE CashMemberBankAccount WITH (ROWLOCK, UPDLOCK)
			SET BankAccountAgentID = NULL,
				RepUpdateTime = dbo.f_GetDateTime2()
		WHERE IsActive = 1
			AND BankAccountAgentID = @AgentBankAccountID;
	END TRY
	BEGIN CATCH
		SELECT @ErrMsg = ERROR_MESSAGE(), @ErrCode = ERROR_NUMBER();
		RETURN;
	END CATCH

	--START LOG
	DECLARE @LogInfo_Tbl TABLE(UserID INT, CustID INT, ActionID INT, TrackingValue NVARCHAR(MAX), TrackingValue2 NVARCHAR(MAX), TrackingValueMask NVARCHAR(MAX), TrackingValueMask2 NVARCHAR(MAX) , Duration INT )
	DECLARE @TrackingValue NVARCHAR(MAX), @TrackingValue2 NVARCHAR(MAX), @TrackingValueMask NVARCHAR(MAX), @TrackingValueMask2 NVARCHAR(MAX)
	DECLARE @UserName NVARCHAR(50) , @ActionID INT = 300005
	DECLARE @BankAccountNumber VARCHAR(100), @AccountHolderName NVARCHAR(255), @AccountNickname NVARCHAR(255), 
			@PromptPayEnabled BIT, @PromptPayMobile VARCHAR(50), @BankCode VARCHAR(10), @TransTypeList VARCHAR(10),
			@DepositMatching_Agent SMALLINT, @DepositMatching_Bank VARCHAR(60)
	
	SELECT @UserName = (SELECT TOP 1 UserName FROM CustDB.dbo.vw_CashService_Customer vc WITH (NOLOCK) WHERE CustID = @CustID)

	-- Extract data from temp table for logging
	SELECT  
		@BankAccountNumber = BankAccountNumber,
		@AccountHolderName = AccountHolderName,
		@AccountNickname = AccountNickname,
		@PromptPayEnabled = PromptPayEnabled,
		@PromptPayMobile = PromptPayMobile,
		@BankCode = BankCode,
		@TransTypeList = TransTypeList,
		@DepositMatching_Agent = DepositMatching_Agent,
		@DepositMatching_Bank = DepositMatching_Bank
	FROM #Old_AgentBankAccount;
	
	SET @endRun = GETDATE()
	SET @DurationTime = DATEDIFF(millisecond, @startRun, @endRun)

	-- LOG NEW VALUES
	SELECT @TrackingValueMask = '<Age_CashService_BankAccountAgent_Del
							CustID="' + CONVERT(VARCHAR(20), @CustID) 
							+'" SubAccName="' + CustDB.dbo.f_GetSubUsername(@SubAccID) 
							+'" IP="' + CONVERT(VARCHAR(50), @IP)   
							+'" BankCode="' + CONVERT(VARCHAR(100), @BankCode)   
							+'" BankAccountNumber="' + CONVERT(VARCHAR(100), @BankAccountNumber)   
							+'" AccountHolderName="' + CONVERT(NVARCHAR(255), @AccountHolderName)   
							+'" AccountNickname="' + CONVERT(NVARCHAR(255), ISNULL(@AccountNickname, ''))   
							+'" PromptPayEnabled="' + CONVERT(VARCHAR(20), @PromptPayEnabled)   
							+'" PromptPayMobile="' + CONVERT(VARCHAR(50), ISNULL(@PromptPayMobile, ''))   
							+'" TransTypeList="' + CONVERT(VARCHAR(10), ISNULL(@TransTypeList, ''))
							+'" DepositMatching_Agent="' + CONVERT(VARCHAR(10), ISNULL(@DepositMatching_Agent, 0)) 
							+'" DepositMatching_Bank="' + CONVERT(VARCHAR(60), ISNULL(@DepositMatching_Bank, ''))
							+'" IsActive="' + CONVERT(VARCHAR(20), 0) +'" />'
		
	SET @TrackingValue = REPLACE(REPLACE(REPLACE(@TrackingValueMask, 
				ISNULL(@BankAccountNumber, ''), ''), 
				ISNULL(@AccountHolderName, ''), ''), 
				ISNULL(@PromptPayMobile, ''), '');

	-- LOG OLD VALUES
	SELECT @TrackingValueMask2 = '<Age_CashService_BankAccountAgent_Del
							CustID="' + CONVERT(VARCHAR(20), @CustID) 
							+'" SubAccName="' + CustDB.dbo.f_GetSubUsername(@SubAccID) 
							+'" IP="' + CONVERT(VARCHAR(50), @IP)    
							+'" BankCode="' + CONVERT(VARCHAR(100), @BankCode)   
							+'" BankAccountNumber="' + CONVERT(VARCHAR(100), @BankAccountNumber)   
							+'" AccountHolderName="' + CONVERT(NVARCHAR(255), @AccountHolderName)   
							+'" AccountNickname="' + CONVERT(NVARCHAR(255), ISNULL(@AccountNickname, ''))   
							+'" PromptPayEnabled="' + CONVERT(VARCHAR(20), @PromptPayEnabled)   
							+'" PromptPayMobile="' + CONVERT(VARCHAR(50), ISNULL(@PromptPayMobile, ''))    
							+'" TransTypeList="' + CONVERT(VARCHAR(10), ISNULL(@TransTypeList, ''))   
							+'" DepositMatching_Agent="' + CONVERT(VARCHAR(10), ISNULL(@DepositMatching_Agent, 0)) 
							+'" DepositMatching_Bank="' + CONVERT(VARCHAR(60), ISNULL(@DepositMatching_Bank, ''))
							+'" IsActive="' + CONVERT(VARCHAR(20), 1) +'" />'
	
	SET @TrackingValue2 = REPLACE(REPLACE(REPLACE(@TrackingValueMask2, 
				ISNULL(@BankAccountNumber, ''), ''), 
				ISNULL(@AccountHolderName, ''), ''), 
				ISNULL(@PromptPayMobile, ''), '');
	
	INSERT INTO @LogInfo_Tbl (UserID, CustID, ActionID, TrackingValue, TrackingValue2, TrackingValueMask, TrackingValueMask2, Duration)
	SELECT @CustID ,  @CustID , @ActionID , @TrackingValue , @TrackingValue2 , @TrackingValueMask , @TrackingValueMask2 , @DurationTime

	IF @Exist_MemberBankAccount_Affected > 0
	BEGIN

		SET @ActionID = 300011
		SET @TrackingValue = '' 
		SET @TrackingValue2 = '' 
		SET @TrackingValueMask = '' 
		SET @TrackingValueMask2 = '' 

		-- LOG NEW VALUES
		SELECT @TrackingValueMask = '<Age_CashService_BankAccountAgent_Del
									CustID="' + CONVERT(VARCHAR(20), @CustID) 
									+'" SourceAccount="' + CONVERT(VARCHAR(50), @UserName)   
									+'" SubAccName="' + CustDB.dbo.f_GetSubUsername(@SubAccID) 
									+'" IP="' + CONVERT(VARCHAR(50), @IP)    
									+'" AgentBankAccountNumber="' + CONVERT(VARCHAR(100), N'NoMatchingBankAccount') + '" />'
		SELECT @TrackingValue = @TrackingValueMask;

		-- LOG OLD VALUES
		SELECT @TrackingValueMask2 = '<Age_CashService_BankAccountAgent_Del
									CustID="' + CONVERT(VARCHAR(20), @CustID) 
									+'" SourceAccount="' + CONVERT(VARCHAR(50), @UserName)   
									+'" SubAccName="' + CustDB.dbo.f_GetSubUsername(@SubAccID) 
									+'" IP="' + CONVERT(VARCHAR(50), @IP)    
									+'" AgentBankAccountNumber="' +  CONVERT(VARCHAR(100), ISNULL(@BankAccountNumber, ''))+ '" />'
		SELECT @TrackingValue2 = @TrackingValueMask2;

		IF @BankAccountNumber IS NOT NULL
		BEGIN
			SET @TrackingValue2 = REPLACE(
				@TrackingValue2,
				'AgentBankAccountNumber="' + CONVERT(VARCHAR(100), @BankAccountNumber) + '"',
				'AgentBankAccountNumber=""'
			);
		END;

		INSERT INTO @LogInfo_Tbl (UserID, CustID, ActionID, TrackingValue, TrackingValue2, TrackingValueMask, TrackingValueMask2, Duration)
		SELECT @CustID ,  @CustID , @ActionID , @TrackingValue , @TrackingValue2 , @TrackingValueMask , @TrackingValueMask2 , @DurationTime
	END

	-- Return Data Object
	SELECT
		UserID,
		CustID,
		ActionID,
		TrackingValue,
		TrackingValue2,
		TrackingValueMask,
		TrackingValueMask2,
		Duration
	FROM @LogInfo_Tbl
END