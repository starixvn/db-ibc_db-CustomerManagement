/*<info serverAlias="DBCUST-AgencyCashService" executers="wsv_CashService"  viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Age_CashService_BankAccountAgent_Upd
	@CustID			INT,			-- SMA_ID Input
	@AgentBankAccountID	INT,
	@BankAccountStatus	BIT,
	@AccountNickname		NVARCHAR(255)		= NULL,
	@TransTypeList		VARCHAR(10),
	@DepositMatchingMode	SMALLINT,
	@PromptPayEnabled		BIT,
	@PromptPayMobile		VARCHAR(50),
	@SubAccID			INT				= 0,
	@IP				VARCHAR(50)			= '',
	@Language			VARCHAR(2)			= 'E',
	@ErrCode			INT				= 0		OUTPUT,
	@ErrMsg			NVARCHAR(1000)		= ''		OUTPUT

AS 
/*  
	Created By: Helios
	Created Date: 2025-04-18
	Description: Agency Cash Service - Manage Payments - Tab Bank Account - BankAccount Update [Redmine #223896]  
	DB: DBCust.AgencyCashService
	
	Revisions:
		- 20250321@Helios: Agency Cash Service [Redmine: #223896]   
		- 20250623@Helios: Offer CashService - Enhance writelog with Masked: CashAgentBankAccount.PromptPayMobile [RedmineID: #231204] 
		- 20250724@Helios: Agency Cash Service -Customer Setting Sprint 8 [redmine: #235266]
		- 20250822@Helios: Agency Cash Service -Customer Setting Sprint 9 [redmine: #236430]

	Param:
		DECLARE @p1 INT , @p2 VARCHAR(1000)
		EXEC dbo.Age_CashService_BankAccountAgent_Upd
			    @CustID = 1,
			    @AgentBankAccountID = 1001,
			    @BankAccountStatus = 1,
			    @AccountNickname = 'Updated Account',
			    @TransTypeList = '1,3',
			    @DepositMatchingMode = 0,
			    @PromptPayEnabled = 0,
			    @PromptPayMobile = '0987654321',
			    @SubAccID	= 0,
			    @IP		= '1.1.1.1',
			    @Language	= 'E',
			    @ErrCode = @p1 OUTPUT,
			    @ErrMsg = @p2 OUTPUT;

		-- Check output values
		SELECT @p1 AS ErrorCode, @p2 AS ErrorMessage

*/  
BEGIN
	SET NOCOUNT ON;
	     
	DECLARE 
		@startRun		DATETIME ,
		@endRun		DATETIME ,
		@DurationTime	INT
	
	SET @startRun = GETDATE ()
	SELECT @ErrCode = 0 , @ErrMsg = '' 

	IF @CustID IS NULL OR @AgentBankAccountID IS NULL OR @BankAccountStatus IS NULL 
	OR @TransTypeList IS NULL OR @DepositMatchingMode IS NULL 
	BEGIN
		SELECT  @ErrMsg = N'Invalid parameters', @ErrCode = 100;
		RETURN
	END

	IF @PromptPayEnabled = 1 AND (@PromptPayMobile IS NULL  OR @PromptPayMobile = '')
	BEGIN
		SELECT  @ErrMsg = N'Invalid parameters', @ErrCode = 100;
		RETURN
	END

	DECLARE @CheckExists_BankAccountNumber BIT = NULL

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

	SELECT @CheckExists_BankAccountNumber = (SELECT TOP 1 1 
								FROM CashAgentBankAccount WITH (NOLOCK) 
								WHERE AgentID = @custid AND AgentBankAccountID = @AgentBankAccountID AND IsActive = 1)

	IF ISNULL(@CheckExists_BankAccountNumber , 0) = 0
	BEGIN
		SELECT  @ErrMsg = N'Bank account not found.', @ErrCode = 203
		RETURN
	END

	IF @CheckExists_BankAccountNumber = 1
	BEGIN TRY
		-- Stored for WriteLog
		INSERT INTO #Old_AgentBankAccount 
		(
			BankAccountStatus
		    , BankAccountNumber
		    , AccountHolderName
		    , AccountNickname
		    , PromptPayEnabled
		    , PromptPayMobile
		    , BankCode
		    , TransTypeList
		    , DepositMatching_Agent
		    , DepositMatching_Bank
		)
		SELECT 
			aba.BankAccountStatus,
			aba.BankAccountNumber,
			aba.AccountHolderName,
			aba.AccountNickname,
			aba.PromptPayEnabled,
			aba.PromptPayMobile,
			cbl.BankCode,
			aba.TransTypeList,
			aba.DepositMatching,
			cbl.DepositMode
		FROM CashAgentBankAccount aba WITH (NOLOCK)
		INNER JOIN CashBankList cbl WITH (NOLOCK) ON aba.BankID = cbl.BankID
		WHERE aba.AgentID = @CustID
		  AND aba.AgentBankAccountID = @AgentBankAccountID
		  AND aba.IsActive = 1;											-- Get Bank Account Is Active

		-- Update Values
		UPDATE aba
		SET 
			BankAccountStatus = @BankAccountStatus,
			AccountNickname = @AccountNickname,
			TransTypeList = @TransTypeList,
			DepositMatching = @DepositMatchingMode,
			PromptPayEnabled = @PromptPayEnabled,
			PromptPayMobile = CASE WHEN @PromptPayEnabled = 1 THEN @PromptPayMobile ELSE NULL END ,
			RepUpdateTime = dbo.f_GetDateTime2()
		FROM CashAgentBankAccount  aba WITH (ROWLOCK, UPDLOCK)
		WHERE aba.AgentID = @CustID
		AND aba.AgentBankAccountID = @AgentBankAccountID
		AND aba.IsActive = 1											-- Get Bank Account Is Active
	END TRY
	BEGIN CATCH
		SELECT @ErrMsg = ERROR_MESSAGE(), @ErrCode = ERROR_NUMBER();
		RETURN;
	END CATCH

	-- Parse and compare TransTypeList_Old vs TransTypeList_New to find removed values
	-- Check if both Manual Deposit (1) and Auto Deposit(2) are removed from TransTypeList_New while existed in TransTypeList_Old
	DECLARE @TransTypeList_Old VARCHAR(10), @TransTypeList_New VARCHAR(10), @IsCheck BIT = 0;
	SELECT TOP 1
		@TransTypeList_Old = oaba.TransTypeList,
		@TransTypeList_New = aba.TransTypeList
	FROM #Old_AgentBankAccount oaba
	INNER JOIN CashAgentBankAccount aba WITH (NOLOCK) ON oaba.BankAccountNumber = aba.BankAccountNumber
	WHERE aba.AgentID = @custid
	AND aba.AgentBankAccountID = @AgentBankAccountID
	AND aba.IsActive = 1;

	-- Readable logic: set IsCheck = 1 if (old has 1 or 2) and (new has neither 1 nor 2)
	IF (
		EXISTS (SELECT 1 FROM STRING_SPLIT(@TransTypeList_Old, ',') WHERE value IN ('1','2'))
		AND NOT EXISTS (SELECT 1 FROM STRING_SPLIT(@TransTypeList_New, ',') WHERE value IN ('1','2'))
	)
	BEGIN
		SET @IsCheck = 1;
	END

	-- If IsCheck = 1, count check data from CashMemberBankAccount before update for WriteLog
	DECLARE @Exist_MemberBankAccount_Affected INT = 0

	-- Collect old data before update
	SELECT @Exist_MemberBankAccount_Affected = (SELECT COUNT(1)
								  FROM CashMemberBankAccount c WITH (NOLOCK)
								  WHERE c.IsActive = 1 AND c.BankAccountAgentID = @AgentBankAccountID);

	IF @IsCheck = 1 AND @Exist_MemberBankAccount_Affected > 0
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
	DECLARE @TrackingValueMask	NVARCHAR(MAX), @TrackingValueMask2 NVARCHAR(MAX)
	DECLARE @TrackingValue		NVARCHAR(MAX), @TrackingValue2 NVARCHAR(MAX)
	DECLARE @xml XML , @UserName NVARCHAR(50) , @ActionID INT = 300004
		SET @endRun = GETDATE ()
		SET @DurationTime = datediff (millisecond,@startRun,@endRun)

	SELECT @UserName = (SELECT TOP 1 UserName FROM CustDB.dbo.vw_CashService_Customer vc WITH (NOLOCK) WHERE CustID = @CustID)

	DECLARE
		@BankAccountNumber	VARCHAR(255),
		@AccountHolderName	NVARCHAR(255),
		@BankCode			VARCHAR(255),
		@DepositMatching_Bank	VARCHAR(255),
		@DepositMatching_Agent	VARCHAR(255)

	SELECT	
		@BankAccountNumber	= oaba.BankAccountNumber,
		@AccountHolderName	= oaba.AccountHolderName,
		@BankCode			= oaba.BankCode,
		@DepositMatching_Bank	= oaba.DepositMatching_Bank,
		@DepositMatching_Agent	= oaba.DepositMatching_Agent
	FROM #Old_AgentBankAccount oaba

	-- Adjust Agent BankAccount
	-- LOG NEW VALUES
	SELECT @TrackingValueMask = '<Age_CashService_BankAccountAgent_Upd 
							CustID="' + CONVERT(VARCHAR(20), @CustID) 
							+'" SubAccName="' + CustDB.dbo.f_GetSubUsername(@SubAccID) 
							+'" IP="' + CONVERT(VARCHAR(50), @IP)   
							+'" BankAccountStatus="' + CONVERT(VARCHAR(10), @BankAccountStatus)   
							+'" AccountNickname="' + CONVERT(NVARCHAR(255), ISNULL(@AccountNickname, ''))   
							+'" TransTypeList="' + CONVERT(VARCHAR(10), ISNULL(@TransTypeList, ''))
							+'" DepositMatching="' + CONVERT(VARCHAR(10), ISNULL(@DepositMatchingMode, 0))
							+'" PromptPayEnabled="' + CONVERT(VARCHAR(20), @PromptPayEnabled)   
							+'" PromptPayMobile="' + CONVERT(VARCHAR(50), ISNULL(@PromptPayMobile, ''))   
							+'" BankAccountNumber="' + CONVERT(VARCHAR(100), ISNULL(@BankAccountNumber, ''))   
							+'" AccountHolderName="' + CONVERT(NVARCHAR(255), ISNULL(@AccountHolderName, ''))   
							+'" BankCode="' + CONVERT(VARCHAR(100), ISNULL(@BankCode, ''))   
							+'" DepositMatching_Bank="' + CONVERT(VARCHAR(60), ISNULL(@DepositMatching_Bank, ''))
							+'" DepositMatching_Agent="' + CONVERT(VARCHAR(10), ISNULL(@DepositMatching_Agent, 0)) +'" />'
	SET @TrackingValue = REPLACE(REPLACE(REPLACE(@TrackingValueMask, 
				ISNULL(@BankAccountNumber, ''), ''), 
				ISNULL(@AccountHolderName, ''), ''), 
				ISNULL(@PromptPayMobile, ''), '');

	-- LOG OLD VALUES
	SELECT @TrackingValueMask2 = '<Age_CashService_BankAccountAgent_Upd 
							CustID="' + CONVERT(VARCHAR(20), @CustID) 
							+'" SubAccName="' + CustDB.dbo.f_GetSubUsername(@SubAccID) 
							+'" IP="' + CONVERT(VARCHAR(50), @IP)   
							+'" BankAccountStatus="' + CONVERT(VARCHAR(10), a.BankAccountStatus)   
							+'" AccountNickname="' + CONVERT(NVARCHAR(255), ISNULL(a.AccountNickname, ''))   
							+'" TransTypeList="' + CONVERT(VARCHAR(10), ISNULL(a.TransTypeList, ''))
							+'" DepositMatching="' + CONVERT(VARCHAR(10), ISNULL(a.DepositMatching_Agent, 0))
							+'" PromptPayEnabled="' + CONVERT(VARCHAR(20), a.PromptPayEnabled)   
							+'" PromptPayMobile="' + CONVERT(VARCHAR(50), ISNULL(a.PromptPayMobile, ''))   
							+'" BankAccountNumber="' + CONVERT(VARCHAR(100), ISNULL(a.BankAccountNumber, ''))   
							+'" AccountHolderName="' + CONVERT(NVARCHAR(255), ISNULL(a.AccountHolderName, ''))   
							+'" BankCode="' + CONVERT(VARCHAR(100), ISNULL(a.BankCode, ''))   
							+'" DepositMatching_Bank="' + CONVERT(VARCHAR(60), ISNULL(a.DepositMatching_Bank, ''))
							+'" DepositMatching_Agent="' + CONVERT(VARCHAR(10), ISNULL(a.DepositMatching_Agent, 0)) +'" />'
	FROM #Old_AgentBankAccount a
	
	-- Masked version of OLD values for TrackingValue2 (sensitive data removed)
	SELECT @TrackingValue2 = '<Age_CashService_BankAccountAgent_Upd 
							CustID="' + CONVERT(VARCHAR(20), @CustID) 
							+'" SubAccName="' + CustDB.dbo.f_GetSubUsername(@SubAccID) 
							+'" IP="' + CONVERT(VARCHAR(50), @IP)   
							+'" BankAccountStatus="' + CONVERT(VARCHAR(10), a.BankAccountStatus)   
							+'" AccountNickname="' + CONVERT(NVARCHAR(255), ISNULL(a.AccountNickname, ''))   
							+'" TransTypeList="' + CONVERT(VARCHAR(10), ISNULL(a.TransTypeList, ''))
							+'" DepositMatching="' + CONVERT(VARCHAR(10), ISNULL(a.DepositMatching_Agent, 0))
							+'" PromptPayEnabled="' + CONVERT(VARCHAR(20), a.PromptPayEnabled)   
							+'" PromptPayMobile=""'   
							+'" BankAccountNumber=""'   
							+'" AccountHolderName=""'   
							+'" BankCode="' + CONVERT(VARCHAR(100), ISNULL(a.BankCode, ''))   
							+'" DepositMatching_Bank="' + CONVERT(VARCHAR(60), ISNULL(a.DepositMatching_Bank, ''))
							+'" DepositMatching_Agent="' + CONVERT(VARCHAR(10), ISNULL(a.DepositMatching_Agent, 0)) +'" />'
	FROM #Old_AgentBankAccount a

	INSERT INTO @LogInfo_Tbl (UserID, CustID, ActionID, TrackingValue, TrackingValue2, TrackingValueMask, TrackingValueMask2, Duration)
	SELECT @CustID ,  @CustID , @ActionID , @TrackingValue , @TrackingValue2 , @TrackingValueMask , @TrackingValueMask2 , @DurationTime


	-- Adjust Member BankAccount
	IF @IsCheck = 1 AND @Exist_MemberBankAccount_Affected > 0
	BEGIN
		SET @ActionID = 300010
		SET @TrackingValue = '' 
		SET @TrackingValue2 = '' 
		SET @TrackingValueMask = '' 
		SET @TrackingValueMask2 = '' 

		-- LOG NEW VALUES
		SELECT @TrackingValueMask = '<Age_CashService_BankAccountAgent_Upd
									CustID="' + CONVERT(VARCHAR(20), @CustID) 
									+'" SourceAccount="' + CONVERT(VARCHAR(50), @UserName)
									+'" SubAccName="' + CustDB.dbo.f_GetSubUsername(@SubAccID) 
									+'" IP="' + CONVERT(VARCHAR(50), @IP)
									+'" AgentBankAccountNumber="' + CONVERT(VARCHAR(100), N'NoMatchingBankAccount') + '" />'
		
		SELECT @TrackingValue = @TrackingValueMask;

		-- LOG OLD VALUES
		SELECT @TrackingValueMask2 = '<Age_CashService_BankAccountAgent_Upd
									CustID="' + CONVERT(VARCHAR(20), @CustID) 
									+'" SourceAccount="' + CONVERT(VARCHAR(50), @UserName)
									+'" SubAccName="' + CustDB.dbo.f_GetSubUsername(@SubAccID) 
									+'" IP="' + CONVERT(VARCHAR(50), @IP)
									+'" AgentBankAccountNumber="' + CONVERT(VARCHAR(100), ISNULL(@BankAccountNumber, '')) + '" />'

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
