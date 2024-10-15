/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="wsv_nap,wsv_alp,wsv_alpv" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[WriteLog_UserLog_RunSP_RewardPayment]
		@PaymentLog NVARCHAR(MAX)
/* 
	Created: 20240918@Lewis  
    Task: Rebate and Retention for Credit Players - Write log for payment reward
    DB: DBLOG-bodb_CustomerLog

	Revisions:
		- 20240918@Lewis: Initialize SP [RedmineId: #208503]
*/
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON   

	DECLARE @__PaymentLog XML 
	SELECT @__PaymentLog = CONVERT(XML, @PaymentLog)

	DECLARE @tmpLog TABLE (
			UserID INT
			, CustID INT
			, SPName VARCHAR(50)
			, ActionID INT
			, TrackingValue NVARCHAR(MAX)
			, TrackingValue2 NVARCHAR(MAX)
			, Duration INT
	)
	INSERT INTO @tmpLog (
			UserID 
			, CustID 
			, SPName 
			, ActionID 
			, TrackingValue 
			, TrackingValue2 
			, Duration 
	)
	SELECT 
			t.PaymentLog.value('./@UserID','INT')
			, t.PaymentLog.value('./@CustID','INT')
			, t.PaymentLog.value('./@SPName','VARCHAR(50)')
			, t.PaymentLog.value('./@ActionID','INT')
			, t.PaymentLog.value('./@TrackingValue','NVARCHAR(MAX)')
			, t.PaymentLog.value('./@TrackingValue2','NVARCHAR(MAX)')
			, t.PaymentLog.value('./@Duration','INT')
	FROM @__PaymentLog.nodes('/row') AS t(PaymentLog)

	-- =========================
	-- Write Log
	-- =========================
	DECLARE
			@UserID INT
			, @CustID INT = 0
			, @SPName VARCHAR(50)= NULL
			, @ActionID INT = NULL
			, @TrackingValue NVARCHAR(MAX)= NULL
			, @TrackingValue2 NVARCHAR(MAX) = NULL
			, @Duration INT = NULL
	
	SELECT 
			@UserID = UserID
			, @CustID = CustID
			, @SPName = SPName
			, @ActionID = ActionID
			, @TrackingValue = TrackingValue
			, @TrackingValue2 = TrackingValue2
			, @Duration = Duration
	FROM @tmpLog

	EXEC WriteLog_UserLog_RunSP
			@UserID = @UserID
			, @CustID = @CustID
			, @SPName = @SPName
			, @ActionID = @ActionID
			, @TrackingValue = @TrackingValue
			, @TrackingValue2 = @TrackingValue2
			, @Duration = @Duration

END
GO