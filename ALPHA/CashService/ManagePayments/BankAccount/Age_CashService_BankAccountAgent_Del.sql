/*<info serverAlias="DBCUST-AgencyCashService" executers="wsv_CashService"  viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE Age_CashService_BankAccountAgent_Del
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

	DECLARE @Old_IsActiveStatus BIT	= NULL
	
	SELECT @Old_IsActiveStatus = ( SELECT TOP 1 IsActive
							FROM CashAgentBankAccount WITH (NOLOCK) 
							WHERE AgentID = @custid AND AgentBankAccountID = @AgentBankAccountID AND IsActive = 1 )

	IF @Old_IsActiveStatus IS NULL
	BEGIN
		SELECT  @ErrMsg = N'Invalid parameters', @ErrCode = 100;
		RETURN
	END

	IF @Old_IsActiveStatus IS NOT NULL
	BEGIN
		-- UPDATE VALUES
		UPDATE ca
		SET 
				ca.IsActive = 0,
				ca.RepUpdateTime = dbo.f_GetDateTime2()
		FROM CashAgentBankAccount ca WITH (ROWLOCK , UPDLOCK)
		WHERE ca.AgentBankAccountID = @AgentBankAccountID		
	END	

	IF (@@error = 0)
	BEGIN
		SELECT  
			@ErrMsg = N'Update Successful!',
			@ErrCode = 0 ;
	END

	--START LOG
	--DECLARE @LogInfo_Tbl TABLE(UserID INT, CustID INT, ActionID INT, TrackingValue VARCHAR(MAX), TrackingValue2 VARCHAR(MAX) , Duration INT )
	DECLARE @TrackingValue VARCHAR(MAX), @TrackingValue2 VARCHAR(MAX)
	DECLARE @xml XML , @UserName NVARCHAR(50) , @ActionID INT = 300005
		SET @endRun = GETDATE ()
		SET @DurationTime = datediff (millisecond,@startRun,@endRun)

	-- LOG NEW VALUES
	SELECT @TrackingValue = '<Age_CashService_BankAccountAgent_Del 
							CustID="' + convert(varchar(20), @CustID) 
							+'" SubAccName="' + CustDB.dbo.f_GetSubUsername(@SubAccID) 
							+'" IP="' + convert(varchar(50), @IP)   
							+'" IsActive="' + convert(varchar(20), 0) +'" />'

	-- LOG OLD VALUES
	SELECT @TrackingValue2 = '<Age_CashService_BankAccountAgent_Del 
							CustID="' + convert(varchar(20), @CustID) 
							+'" SubAccName="' + CustDB.dbo.f_GetSubUsername(@SubAccID) 
							+'" IP="'  + convert(varchar(50), @IP)    
							+'" IsActive="' +  convert(varchar(20), @Old_IsActiveStatus)  +'" />'

	--INSERT INTO @LogInfo_Tbl (UserID, CustID, ActionID, TrackingValue, TrackingValue2, Duration)
	SELECT 
		@CustID AS UserID ,
		@CustID AS CustID ,
		@ActionID AS ActionID ,
		@TrackingValue AS TrackingValue ,
		@TrackingValue2 AS TrackingValue2 ,
		@TrackingValue AS TrackingValueMask ,
		@TrackingValue2 AS TrackingValueMask2  ,
		@DurationTime AS Duration
END