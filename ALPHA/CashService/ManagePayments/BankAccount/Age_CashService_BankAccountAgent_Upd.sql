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

	-- Create Table For WriteLog Old Data:
	DECLARE @Old_CashAgentBankAccount TABLE (
		    --AgentBankAccountID    INT,
		    --BankID                INT,
		    AgentID               INT,
		    BankAccountStatus     BIT,
		    AccountNickname       NVARCHAR(255),
		    TransTypeList         VARCHAR(10),
		    DepositMatching       SMALLINT,
		    PromptPayEnabled      BIT,
		    PromptPayMobile       VARCHAR(50)
	)

	SELECT @CheckExists_BankAccountNumber = (SELECT TOP 1 1 
								FROM CashAgentBankAccount WITH (NOLOCK) 
								WHERE AgentID = @custid AND AgentBankAccountID = @AgentBankAccountID AND IsActive = 1)

	IF ISNULL(@CheckExists_BankAccountNumber , 0) = 0
	BEGIN
		SELECT  @ErrMsg = N'This bank account already exist, please enter a different bank account number.', @ErrCode = 102
		RETURN
	END

	IF @CheckExists_BankAccountNumber = 1
	BEGIN
		-- Stored for WriteLog
		INSERT INTO @Old_CashAgentBankAccount 
		(
			AgentID
			, BankAccountStatus
			, AccountNickname
			, TransTypeList
			, DepositMatching
			, PromptPayEnabled
			, PromptPayMobile
		)
		SELECT 
			aba.AgentID, 
			aba.BankAccountStatus, 
			aba.AccountNickname, 
			aba.TransTypeList, 
			aba.DepositMatching, 
			aba.PromptPayEnabled, 
			aba.PromptPayMobile
		FROM CashAgentBankAccount  aba WITH (NOLOCK)
		WHERE aba.AgentID = @CustID
		AND aba.AgentBankAccountID = @AgentBankAccountID
		AND aba.IsActive = 1											-- Get Bank Account Is Active

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
	END	
	
	IF (@@error = 0)
	BEGIN
		SELECT @ErrMsg = N'Action completed successfully.', @ErrCode = 0 ;
	END

	--START LOG
	DECLARE @LogInfo_Tbl TABLE(UserID INT, CustID INT, ActionID INT, TrackingValue NVARCHAR(MAX), TrackingValue2 NVARCHAR(MAX) , Duration INT )
	DECLARE @TrackingValueMask	NVARCHAR(MAX), @TrackingValueMask2 NVARCHAR(MAX)
	DECLARE @TrackingValue		NVARCHAR(MAX), @TrackingValue2 NVARCHAR(MAX)
	DECLARE @xml XML , @UserName NVARCHAR(50) , @ActionID INT = 300004
		SET @endRun = GETDATE ()
		SET @DurationTime = datediff (millisecond,@startRun,@endRun)

	-- LOG NEW VALUES
	SET @xml = (
		SELECT	
				@CustID								AS '@CustID',
				CustDB.dbo.f_GetSubUsername(@SubAccID)	AS '@SubAccName',
				@IP								AS '@IP',
				CONVERT(INT, @BankAccountStatus)	AS '@BankAccountStatus',
				CONVERT(NVARCHAR(255), @AccountNickname) AS '@AccountNickname',
				@TransTypeList					AS '@TransTypeList',
				@DepositMatchingMode			AS '@DepositMatching',
				CONVERT(INT, @PromptPayEnabled)	AS '@PromptPayEnabled',
				@PromptPayMobile				AS '@PromptPayMobile'
		FOR XML PATH('Age_CashService_BankAccountAgent_Upd'), 
		TYPE
	);
	SET @TrackingValueMask = REPLACE(CONVERT(NVARCHAR(MAX), @xml), '" />', '"/"')
	SELECT @TrackingValue = REPLACE(@TrackingValueMask, ISNULL(@PromptPayMobile, ''), '');

	-- LOG OLD VALUES
	SET @xml = (
		SELECT	
				@CustID								AS '@CustID',
				CustDB.dbo.f_GetSubUsername(@SubAccID)	AS '@SubAccName',
				@IP								AS '@IP',
				CONVERT(INT, a.BankAccountStatus)	AS '@BankAccountStatus',
				CONVERT(NVARCHAR(255), a.AccountNickname) AS '@AccountNickname',
				a.TransTypeList					AS '@TransTypeList',
				a.DepositMatching				AS '@DepositMatching',
				CONVERT(INT, a.PromptPayEnabled)	AS '@PromptPayEnabled',
				a.PromptPayMobile				AS '@PromptPayMobile'
		FROM @Old_CashAgentBankAccount a
		FOR XML PATH('Age_CashService_BankAccountAgent_Upd'), 
		TYPE
	);
	SET @TrackingValueMask2 = REPLACE(CONVERT(NVARCHAR(MAX), @xml), '" />', '"/"')
	
	SET @xml = (
		SELECT	
				@CustID								AS '@CustID',
				CustDB.dbo.f_GetSubUsername(@SubAccID)	AS '@SubAccName',
				@IP								AS '@IP',
				CONVERT(INT, a.BankAccountStatus)	AS '@BankAccountStatus',
				CONVERT(NVARCHAR(255), a.AccountNickname) AS '@AccountNickname',
				a.TransTypeList					AS '@TransTypeList',
				a.DepositMatching				AS '@DepositMatching',
				CONVERT(INT, a.PromptPayEnabled)	AS '@PromptPayEnabled',
				''								AS '@PromptPayMobile'
		FROM @Old_CashAgentBankAccount a
		FOR XML PATH('Age_CashService_BankAccountAgent_Upd'), 
		TYPE
	);
	SELECT @TrackingValue2 = REPLACE(CONVERT(NVARCHAR(MAX), @xml), '" />', '"/"')

	INSERT INTO @LogInfo_Tbl (UserID, CustID, ActionID, TrackingValue, TrackingValue2, Duration)
	SELECT @CustID ,  @CustID , @ActionID , @TrackingValue , @TrackingValue2 , @DurationTime


	-- Return Data Object
	SELECT
		@custid		  AS UserID
	    , @custid		  AS CustID
	    , @ActionID		  AS ActionID
	    , @TrackingValue	  AS TrackingValue
	    , @TrackingValue2	  AS TrackingValue2
	    , @TrackingValueMask  AS TrackingValueMask
	    , @TrackingValueMask2 AS TrackingValueMask2
	    , @DurationTime	  AS Duration
END
