/*<info serverAlias="DBCUST-AgencyCashService" executers="wsv_CashService"  viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Age_CashService_AgentBankAccountLimit_Upd
	@CustID			INT				,		-- SMA_ID Input
	@ModeAction			BIT				= 0, 
	@DrawLimit			INT				,
	@MinPerDeposit		MONEY				= 0,
	@MaxPerDeposit		MONEY				= 0,
	@MinPerWithdrawal		MONEY				= 0,
	@MaxPerWithdrawal		MONEY				= 0,
	@SubAccID			INT				= 0,
	@IP				VARCHAR(50)			= '',
	@Language			VARCHAR(2)			= 'E',
	@ErrCode			INT				= 0		OUTPUT,
	@ErrMsg			NVARCHAR(1000)		= ''		OUTPUT
AS 
/*  
	Created By: Helios
	Created Date: 2025-04-18
	Description: Agency Cash Service - Update daily withdrawal count [Redmine #223896]   
	DB: DBCust.AgencyCashService
	
	Revisions:
		- 20250321@Helios: Agency Cash Service [Redmine: #223896]   

	Param:

	Update Daily Withdrawal Count
		exec Age_CashService_AgentBankAccountLimit_Upd @CustID =  1176086 , @ModeAction = 0 , @DrawLimit = 24 , @SubAccID = 0 , @IP = '1.1.1.1'

	Update Min-Max Per Trans:
		exec Age_CashService_AgentBankAccountLimit_Upd @CustID =  1176086 , @ModeAction = 1 , @DrawLimit = 24 ,  @MinPerDeposit = 1 , @MaxPerDeposit = 100 , @MinPerWithdrawal = 1 , @MaxPerWithdrawal = 300 , @SubAccID = 0 , @IP = '1.1.1.1'

		DECLARE @p1 INT , @p2 NVARCHAR(1000)
		exec Age_CashService_AgentBankAccountLimit_Upd @CustID =  1176086 , @ModeAction = 1 , @DrawLimit = NULL ,  @MinPerDeposit = 1 , @MaxPerDeposit = 100 , @MinPerWithdrawal = 1 , @MaxPerWithdrawal = 300 , @SubAccID = 0 , @IP = '1.1.1.1' , @ErrCode = @p1 OUTPUT , @ErrMsg = @p2 OUTPUT
		SELECT @p1 , @p2

	@ModeAction : 
		0 = Update by Tab PaymentGateway
		1 = Only Update by Tab BankAccount
*/  
BEGIN
	SET NOCOUNT ON;

	DECLARE @startRun DATETIME ,  @endRun DATETIME , @DurationTime INT
		
	SET @startRun = GETDATE ()
	SELECT @ErrCode = 0 , @ErrMsg = '' 

	-- Create Table For WriteLog Old Data:
	DECLARE @Old_CashAgentLimit TABLE (
		AgentID			INT,
		MinPerDeposit		MONEY,
		MaxPerDeposit		MONEY, 
		MinPerWithdrawal		MONEY,
		MaxPerWithdrawal		MONEY
	)

	DECLARE @Old_DailyWithdrawalCount SMALLINT = NULL

	SELECT @Old_DailyWithdrawalCount = DailyWithdrawalCount FROM CashAgentManagement WITH (NOLOCK) WHERE AgentID = @CustID

	IF @Old_DailyWithdrawalCount IS NULL
	BEGIN
		SELECT  @ErrMsg = N'Invalid parameters', @ErrCode = 100;
		RETURN
	END

	IF ISNULL(@DrawLimit , 0) = 0
	BEGIN
		SELECT  @ErrMsg = N'Invalid parameters'	, @ErrCode = 100 ;	
		RETURN
	END

	IF @DrawLimit IS NOT NULL AND @DrawLimit > 32767
	BEGIN
		SELECT  @ErrMsg = N'Invalid parameters' , @ErrCode = 100 ;	
		RETURN
	END

	DECLARE @v_limit SMALLINT = NULL
			SET @v_limit = @DrawLimit

	-- Update by Tab PaymentGateway & Tab BankAccount
	IF @v_limit IS NOT NULL AND @v_limit != @Old_DailyWithdrawalCount
	BEGIN
		-- Update Values
		UPDATE ctl
			SET DailyWithdrawalCount = @v_limit
			,   RepUpdateTime = dbo.f_GetDateTime2()
		FROM CashAgentManagement ctl WITH (ROWLOCK , UPDLOCK)
		WHERE ctl.AgentID = @CustID

		IF (@@error = 0)
		BEGIN
			SELECT  
				@ErrMsg = N'Action completed successfully.',
				@ErrCode = 0 ;
		END
	END

	

	--START LOG
	DECLARE @LogInfo_Tbl TABLE(UserID INT, CustID INT, ActionID INT, TrackingValue VARCHAR(MAX), TrackingValue2 VARCHAR(MAX) , Duration INT )
	DECLARE @TrackingValue VARCHAR(MAX), @TrackingValue2 VARCHAR(MAX)
	DECLARE @xml XML , @UserName NVARCHAR(50) , @ActionID INT = 0
		SET @endRun = GETDATE ()
		SET @DurationTime = datediff (millisecond,@startRun,@endRun)
	
	-- LOG FOR Update by Tab PaymentGateway & Tab BankAccount
	IF @v_limit IS NOT NULL AND @v_limit != @Old_DailyWithdrawalCount
	BEGIN
		SET @ActionID = 300001
		
		-- LOG NEW VALUES
		SELECT @TrackingValue = '<Age_CashService_AgentBankAccountLimit_Upd 
								CustID="' + convert(varchar(20), @CustID) 
								+'" SubAccName="' + CustDB.dbo.f_GetSubUsername(@SubAccID) 
								+'" IP="' + convert(varchar(50), @IP)   
								+'" DailyWithdrawalCount="' + convert(varchar(20), @v_limit) +'" />'

		-- LOG OLD VALUES
		SELECT @TrackingValue2 = '<Age_CashService_AgentBankAccountLimit_Upd 
								 CustID="' + convert(varchar(20), @CustID) 
								+'" SubAccName="' + CustDB.dbo.f_GetSubUsername(@SubAccID) 
								+'" IP="'  + convert(varchar(50), @IP)    
								+'" DailyWithdrawalCount="' +  convert(varchar(20), @Old_DailyWithdrawalCount)  +'" />'

		INSERT INTO @LogInfo_Tbl (UserID, CustID, ActionID, TrackingValue, TrackingValue2, Duration)
		SELECT @CustID ,  @CustID , @ActionID , @TrackingValue , @TrackingValue2 , @DurationTime
	END



	-- Only Update by Tab BankAccount
	IF @ModeAction = 1 
	BEGIN
		-- Validate Min-Max Per Trans:
		IF (
			--Check for zero values
			ISNULL(@MinPerDeposit,0) = 0 OR ISNULL(@MaxPerDeposit,0) = 0 OR ISNULL(@MinPerWithdrawal,0) = 0 OR ISNULL(@MaxPerWithdrawal,0) = 0
			-- Ensure Max values are greater than Min values
			OR @MaxPerDeposit < @MinPerDeposit
			OR @MaxPerWithdrawal < @MinPerWithdrawal
			-- Prevent negative values
			OR @MinPerDeposit < 0 OR @MaxPerDeposit < 0 OR @MinPerWithdrawal < 0 OR @MaxPerWithdrawal < 0
		)
		BEGIN
		SELECT  @ErrMsg = N'Invalid parameters', @ErrCode = 101;
			RETURN
		END

		-- Validate Min-Max Per Trans with current values:
		IF EXISTS (
			SELECT TOP 1 1
			FROM CashAgentBankAccountLimit a WITH (NOLOCK)
			WHERE AgentID = @CustID
			AND a.MinPerDeposit = @MinPerDeposit
			AND a.MaxPerDeposit = @MaxPerDeposit
			AND a.MinPerWithdrawal = @MinPerWithdrawal
			AND a.MaxPerWithdrawal = @MaxPerWithdrawal
		)
		BEGIN
			--SELECT  @ErrMsg = N'UnChanged' , @ErrCode = 101 ;	
			RETURN
		END


		DECLARE @Exist_LimitAccount BIT = NULL

		SELECT @Exist_LimitAccount = (SELECT TOP 1 1 FROM CashAgentBankAccountLimit WITH (NOLOCK) WHERE AgentID = @CustID)

		IF ISNULL(@Exist_LimitAccount , 0) = 0
		BEGIN
		SELECT  @ErrMsg = N'Invalid parameters', @ErrCode = 102;
			RETURN
		END

		IF @Exist_LimitAccount IS NOT NULL
		BEGIN
			-- Stored for WriteLog
			INSERT INTO @Old_CashAgentLimit 
			(
				AgentID
			    , MinPerDeposit
			    , MaxPerDeposit
			    , MinPerWithdrawal
			    , MaxPerWithdrawal
			)
			SELECT 
			      AgentID
			    , MinPerDeposit
			    , MaxPerDeposit
			    , MinPerWithdrawal
			    , MaxPerWithdrawal
			FROM CashAgentBankAccountLimit WITH (NOLOCK)
			WHERE AgentID = @CustID

			-- Update Values
			UPDATE ctl
			SET 
				ctl.MinPerDeposit = @MinPerDeposit,
				ctl.MaxPerDeposit = @MaxPerDeposit,
				ctl.MinPerWithdrawal = @MinPerWithdrawal,
				ctl.MaxPerWithdrawal = @MaxPerWithdrawal,
				RepUpdateTime = dbo.f_GetDateTime2()
			FROM CashAgentBankAccountLimit ctl WITH (ROWLOCK , UPDLOCK)
			WHERE ctl.AgentID = @CustID


			IF (@@error = 0)
			BEGIN
				SELECT  
					@ErrMsg = N'Action completed successfully.',
					@ErrCode = 0 ;
			END
		END
	END

	-- LOG FOR Only Update by Tab BankAccount
	IF @ModeAction = 1
	BEGIN
		SET @ActionID = 300002

		-- LOG NEW VALUES
		SET @xml = (
		SELECT	@CustID                         AS '@CustID',
				CustDB.dbo.f_GetSubUsername(@SubAccID) AS '@SubAccName',
				@IP                             AS '@IP',
				(
					SELECT	CONVERT(DECIMAL(20,2), @MinPerDeposit)     AS '@MinPerDeposit',
							CONVERT(DECIMAL(20,2), @MaxPerDeposit)     AS '@MaxPerDeposit',
							CONVERT(DECIMAL(20,2), @MinPerWithdrawal)  AS '@MinPerWithdrawal',
							CONVERT(DECIMAL(20,2), @MaxPerWithdrawal)  AS '@MaxPerWithdrawal'
					FOR XML PATH('PerTrans'), 
					TYPE
				)FOR XML PATH('ROOT'),TYPE
		);

		SET @TrackingValue = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')


		-- LOG OLD VALUES
		SET @xml = (
		SELECT	@CustID                         AS '@CustID',
				CustDB.dbo.f_GetSubUsername(@SubAccID) AS '@SubAccName',
				@IP                             AS '@IP',
				(
					SELECT	CONVERT(DECIMAL(20,2), a.MinPerDeposit)     AS '@MinPerDeposit',
							CONVERT(DECIMAL(20,2), a.MaxPerDeposit)     AS '@MaxPerDeposit',
							CONVERT(DECIMAL(20,2), a.MinPerWithdrawal)  AS '@MinPerWithdrawal',
							CONVERT(DECIMAL(20,2), a.MaxPerWithdrawal)  AS '@MaxPerWithdrawal'
					FROM @Old_CashAgentLimit a
					FOR XML PATH('PerTrans'), 
					TYPE
				)FOR XML PATH('ROOT'),TYPE
		);

		SET @TrackingValue2 = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')		

		INSERT INTO @LogInfo_Tbl (UserID, CustID, ActionID, TrackingValue, TrackingValue2, Duration)
		SELECT @CustID ,  @CustID , @ActionID , @TrackingValue , @TrackingValue2 , @DurationTime

	END


	-- Return Data Object
	SELECT UserID, CustID, ActionID, TrackingValue, TrackingValue2 , TrackingValue AS TrackingValueMask, TrackingValue2 AS  TrackingValueMask2 , Duration FROM @LogInfo_Tbl
END
