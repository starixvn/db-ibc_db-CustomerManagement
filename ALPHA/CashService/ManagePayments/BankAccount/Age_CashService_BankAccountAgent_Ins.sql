/*<info serverAlias="DBCUST-AgencyCashService" executers="wsv_CashService"  viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Age_CashService_BankAccountAgent_Ins
	@CustID				INT,			-- SMA_ID Input
	@Username				VARCHAR(50),
	@BankID				INT,
	@BankAccountStatus		BIT,
	@AccountHolderName		NVARCHAR(255),
	@BankAccountNumber		VARCHAR(100),
	@AccountNickname			NVARCHAR(255),
	@TransTypeList			VARCHAR(10),
	@DepositMatchingMode		SMALLINT,
	@PromptPayEnabled			BIT,
	@PromptPayMobile			VARCHAR(50),
	@SubAccID				INT				= 0,
	@IP					VARCHAR(50)			= '',
	@Language				VARCHAR(2)			= 'E',
	@ErrCode				INT				= 0		OUTPUT,
	@ErrMsg				NVARCHAR(1000)		= ''		OUTPUT

AS 
/*  
	Created By: Helios
	Created Date: 2025-04-18
	Description: Agency Cash Service - Manage Payments - Tab Bank Account - BankAccount List [Redmine #223896]
	DB: DBCust.AgencyCashService
	
	Revisions:
		- 20250321@Helios: Agency Cash Service [Redmine: #223896]    

	Param:
		DECLARE @p1 INT , @p2 VARCHAR(1000)

		EXEC dbo.Age_CashService_BankAccountAgent_Ins
			@CustID = 123333333,
			@BankID = 101,
			@BankAccountStatus = 1,
			@AccountHolderName = N'John Doe',
			@BankAccountNumber = '12345678901112312',
			@AccountNickname = 'Primary Account',
			@TransTypeList = '1,3',
			@DepositMatchingMode = 0,
			@PromptPayEnabled = 1,
			@Username = 'Test',
			@PromptPayMobile = '0987654321',
			@SubAccID = 0,
			@IP	= '1.1.1.1',
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

	DECLARE @CheckExistsBankAccountNumber BIT
	
	IF @CustID IS NULL OR @BankID IS NULL OR @BankAccountStatus IS NULL 
	OR @AccountHolderName IS NULL OR @AccountHolderName = '' 
	OR @BankAccountNumber IS NULL OR @BankAccountNumber = ''
	OR @TransTypeList IS NULL OR @TransTypeList = ''
	OR @DepositMatchingMode IS NULL
	BEGIN
		SELECT  @ErrMsg = N'Invalid Values Input'	, @ErrCode = 100 ;	
		RETURN
	END

	IF dbo.f_IsValidBank(@BankID) = 0
	BEGIN
	    SET @ErrCode = 100;
	    SET @ErrMsg = N'Invalid Bank Input';
	    RETURN;
	END

	IF @PromptPayEnabled = 1 AND (@PromptPayMobile IS NULL  OR @PromptPayMobile = '')
	BEGIN
		SELECT  @ErrMsg = N'Invalid Values Input'	, @ErrCode = 101 ;	
		RETURN
	END


	SELECT @CheckExistsBankAccountNumber = (SELECT TOP 1 1 
								FROM CashAgentBankAccount WITH (NOLOCK) 
								WHERE AgentID = @custid AND BankID = @BankID AND BankAccountNumber = @BankAccountNumber AND IsActive = 1)
	IF @CheckExistsBankAccountNumber = 1
	BEGIN
		SELECT  @ErrMsg = 'This bank account already exist, please enter a different bank account number.',
							--					CASE @Language
							--                              WHEN 'E' THEN 'This bank account already exist, please enter a different bank account number.'
							--                              ELSE [dbo].[f_Get_MsgNamebyMsgID](9900,@Language)	-- Need Define MsgID
							--                            END ,
                 @ErrCode = 102
		RETURN	
	END
	ELSE 
	BEGIN
		INSERT INTO CashAgentBankAccount 
		(
			BankID
		    , AgentID
		    , BankAccountStatus
		    , AccountHolderName
		    , BankAccountNumber
		    , AccountNickname
		    , TransTypeList
		    , DepositMatching
		    , PromptPayEnabled
		    , PromptPayMobile
		    , IsActive
		    , CreateDate
		    , CreateBy
		    , RepUpdateTime
		)
		SELECT 
			@BankID , 
			@CustID , 
			@BankAccountStatus , 
			@AccountHolderName , 
			@BankAccountNumber , 
			@AccountNickname , 
			@TransTypeList,
			@DepositMatchingMode , 
			@PromptPayEnabled , 
			@PromptPayMobile ,
			1 ,		-- isActive
			GETDATE (), 
			@CustID , 		
			dbo.f_GetDateTime2()
	END

	IF (@@error = 0)
	BEGIN
		SELECT  
			@ErrMsg = N'Update Successful!',
			@ErrCode = 0 ;
	END

	--START LOG
	DECLARE @LogInfo_Tbl TABLE(UserID INT, CustID INT, ActionID INT, TrackingValue NVARCHAR(MAX), TrackingValue2 NVARCHAR(MAX) , Duration INT )
	DECLARE @TrackingValue NVARCHAR(MAX), @TrackingValue2 NVARCHAR(MAX)
	DECLARE @xml XML , @ActionID INT = 300003
		SET @endRun = GETDATE ()
		SET @DurationTime = datediff (millisecond,@startRun,@endRun)

	-- LOG NEW VALUES
	SET @xml = (
	SELECT	@CustID                         AS '@CustID',
			CustDB.dbo.f_GetSubUsername(@SubAccID) AS '@SubAccName',
			@IP                             AS '@IP',
			(
				SELECT	@CustID					 AS '@CustID',
						@BankID					 AS '@BankID',
						CONVERT(INT, @BankAccountStatus)     AS '@BankAccountStatus',
						CONVERT(NVARCHAR(255), @AccountHolderName)			 AS '@AccountHolderName',
						@BankAccountNumber			 AS '@BankAccountNumber',
						CONVERT(NVARCHAR(255), @AccountNickname)				 AS '@AccountNickname',
						@TransTypeList				 AS '@TransTypeList',
						@DepositMatchingMode			 AS '@DepositMatchingMode',
						CONVERT(INT, @PromptPayEnabled)      AS '@PromptPayEnabled',
						@PromptPayMobile				 AS '@PromptPayMobile'
				FOR XML PATH('AgentBankAccount'), 
				TYPE
			)
	FOR XML PATH('ROOT'), TYPE
	);
	SET @TrackingValue = REPLACE(CONVERT(NVARCHAR(MAX), @xml), '" />', '"/"')

	
	INSERT INTO @LogInfo_Tbl (UserID, CustID, ActionID, TrackingValue, TrackingValue2, Duration)
	SELECT @CustID ,  @CustID , @ActionID , @TrackingValue , NULL , @DurationTime

	-- Return Data Object
	SELECT UserID, CustID, ActionID, TrackingValue, TrackingValue2 , TrackingValue AS TrackingValueMask, TrackingValue2 AS  TrackingValueMask2 , Duration FROM @LogInfo_Tbl
END
