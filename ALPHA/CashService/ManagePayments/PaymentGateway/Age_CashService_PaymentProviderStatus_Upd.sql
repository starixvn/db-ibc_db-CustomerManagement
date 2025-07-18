/*<info serverAlias="DBCUST-AgencyCashService" executers="wsv_CashService"  viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Age_CashService_PaymentProviderStatus_Upd
	@CustID			INT,			-- SMA_ID Input
	@ProviderID			INT,			
	@ProviderStatus		BIT,
	@SubAccID			INT				= 0,
	@IP				VARCHAR(50)			= '',
	@Language			VARCHAR(2)			= 'E',
	@ErrCode			INT				= 0		OUTPUT,
	@ErrMsg			NVARCHAR(1000)		= ''		OUTPUT
AS 
/*  
	Created By: Helios
	Created Date: 2025-04-18
	Description: Agency Cash Service - Update Provider Status [Redmine #223896]
	DB: DBCust.AgencyCashService
	
	Revisions:
		- 20250321@Helios: Agency Cash Service [Redmine: #223896]

	Param:
		DECLARE @p1 INT = 0 , @p2 NVARCHAR(1000) = ''

		exec Age_CashService_PaymentProviderStatus_Upd	@CustID		= 1176086 , 
										@ProviderID		= 1,
										@ProviderStatus	= 0 ,
										@ErrCode		= @p1 OUTPUT,
										@ErrMsg		= @p2 OUTPUT

		SELECT @p1 , @p2


	@ProviderStatus:		0 = Enabled 
					1 = Disabled
*/  
BEGIN
	SET NOCOUNT ON;

	DECLARE 
		@startRun		DATETIME ,
		@endRun		DATETIME ,
		@DurationTime	INT
	
	SET @startRun = GETDATE ()
	SELECT @ErrCode = 0 , @ErrMsg = '' 

	DECLARE @Old_ProviderStatus BIT	= NULL		-- use write log

	IF dbo.f_IsValidProvider(@ProviderID) = 0
	BEGIN
		SELECT  @ErrMsg = N'Invalid parameters', @ErrCode = 100;
		RETURN;
	END
	
	SELECT @Old_ProviderStatus = (SELECT TOP 1 ProviderStatus FROM CashAgentProviderConfig WITH (NOLOCK) WHERE AgentID = @CustID AND ProviderID = @ProviderID)

	IF @Old_ProviderStatus IS NULL OR @ProviderID IS NULL OR @ProviderStatus IS NULL
	BEGIN
		SELECT  @ErrMsg = N'Invalid parameters', @ErrCode = 100;
		RETURN
	END

	IF @Old_ProviderStatus IS NOT NULL AND @Old_ProviderStatus = @ProviderStatus
	BEGIN
		SELECT  @ErrMsg = N'NoChange', @ErrCode = 0 ;
		RETURN
	END

	IF @Old_ProviderStatus IS NOT NULL AND @Old_ProviderStatus != @ProviderStatus
	BEGIN
		-- UPDATE VALUES
		UPDATE cp 
			SET ProviderStatus = @ProviderStatus 
			  , RepUpdateTime = dbo.f_GetDateTime2()
		FROM CashAgentProviderConfig cp WITH (ROWLOCK , UPDLOCK)
		WHERE cp.AgentID = @CustID
		AND cp.ProviderID = @ProviderID	
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
	DECLARE @xml XML , @UserName NVARCHAR(50) , @ActionID INT = 305003
		SET @endRun = GETDATE ()
		SET @DurationTime = datediff (millisecond,@startRun,@endRun)

	-- LOG NEW VALUES
	SELECT @TrackingValue = '<Age_CashService_PaymentProviderStatus_Upd 
							CustID="' + convert(varchar(20), @CustID) 
							+'" SubAccName="' + CustDB.dbo.f_GetSubUsername(@SubAccID) 
							+'" IP="' + convert(varchar(50), @IP)   
							+'" ProviderID="' + convert(varchar(20), @ProviderID)   
							+'" ProviderStatus="' + convert(varchar(20), @ProviderStatus) +'" />'

	-- LOG OLD VALUES
	SELECT @TrackingValue2 = '<Age_CashService_PaymentProviderStatus_Upd 
							CustID="' + convert(varchar(20), @CustID) 
							+'" SubAccName="' + CustDB.dbo.f_GetSubUsername(@SubAccID) 
							+'" IP="'  + convert(varchar(50), @IP)    
							+'" ProviderID="' + convert(varchar(20), @ProviderID)   
							+'" ProviderStatus="' +  convert(varchar(20), @Old_ProviderStatus)  +'" />'

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
