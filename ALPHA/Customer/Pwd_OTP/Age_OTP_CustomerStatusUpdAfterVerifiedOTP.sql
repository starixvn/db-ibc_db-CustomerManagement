/*<info serverAlias="DBCUST-CustDB" executers="bodbDownlineNet,bodbDownlineNetView" viewers="vnteam" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_OTP_CustomerStatusUpdAfterVerifiedOTP]
	@CustID INT,
	@SubAccID INT = 0,
	@CheckedOTP BIT = 1,
	@FunctionName VARCHAR(100) = '',

	@Language VARCHAR(2) = 'E',
	@IP NVARCHAR(200),
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(200) = N'' OUTPUT
AS
/*
	Creator: Percy
	Date: 2016-10-13
	DB: DBCUST.CustDB
	Task: Update status of account

	Revisions:
	-- 20170619@Winnie: Apply color for closed accounts RedmineID: #74494

	Param's Explanation:
		- @CheckedOTP:	= 1: check OTP success
						= 0: failed OTP code
		- @FunctionName: name of function which customer is required OTP
		- @ErrCode	= 100: failed providing OTP
					= 200: Closed account
*/
BEGIN
	SET NOCOUNT ON

	SELECT @ErrCode = 0, @ErrMsg = N''

	DECLARE @VerifyOTPCount INT, @LogSPData VARCHAR(MAX), @UserId INT

	IF @SubAccID <> 0 -- sub account
	BEGIN
		SELECT  @VerifyOTPCount = ISNULL(VerifyOTPCount, 0) FROM CustLoginInfoSub WITH(NOLOCK) WHERE CustID = @CustID AND SubAccID = @SubAccID

		IF @CheckedOTP = 0
		BEGIN 
			SELECT  @VerifyOTPCount = @VerifyOTPCount + 1
		
			IF @VerifyOTPCount <=5
			BEGIN 			
				UPDATE CustLoginInfoSub WITH(UPDLOCK, ROWLOCK)
				SET VerifyOTPCount = @VerifyOTPCount
				WHERE CustID = @CustID AND SubAccID = @SubAccID
			
				SELECT  @ErrCode = 100,
						@ErrMsg = CASE WHEN @Language = 'E' THEN 'Your OTP is invalid or expired.'
									ELSE [dbo].[f_Get_MsgNamebyMsgID](40035,@Language) END
			
				SELECT @LogSPData = '<Age_OTP_CustomerStatusUpdAfterVerifiedOTP custid="' + COALESCE(CAST(@custid AS VARCHAR(10)), SPACE(1)) + '" '	
															+ 'SubAccount="' + COALESCE(CAST(dbo.f_GetSubUsername(@SubAccID) AS VARCHAR(30)), SPACE(1)) + '" '
															+ 'CheckedOTP="' + COALESCE(CAST(@CheckedOTP AS VARCHAR(10)), SPACE(1)) + '" '
															+ 'FunctionName="' + COALESCE(@FunctionName, SPACE(1)) + '" ' +
															+ 'Language="' + COALESCE(@Language, SPACE(1)) + '" ' +
															+ 'IP="' + COALESCE(@IP, SPACE(1)) + '" />'
			
				BEGIN TRY
					EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
						@UserID = @CustID,
						@CustID = @CustID, 
						@ActionID = 930, 
						@TrackingValue = @LogSPData
				END TRY
				BEGIN CATCH
					SELECT @LogSPData = '<Age_OTP_CustomerStatusUpdAfterVerifiedOTP custid="' + COALESCE(CAST(@custid AS VARCHAR(10)), SPACE(1)) + '" '		
															+ 'SubAccount="' + COALESCE(CAST(dbo.f_GetSubUsername(@SubAccID) AS VARCHAR(30)), SPACE(1)) + '" '
															+ 'CheckedOTP="' + COALESCE(CAST(@CheckedOTP AS VARCHAR(10)), SPACE(1)) + '" '																										
															+ 'FunctionName="' + COALESCE(@FunctionName, SPACE(1)) + '" ' +
															+ 'Language="' + COALESCE(@Language, SPACE(1)) + '" ' +
															+ 'IP="' + COALESCE(@IP, SPACE(1)) + '" '
															+ 'ErrMsg="'+ COALESCE(ERROR_MESSAGE(), SPACE(1)) + '" />'
				
					EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
						@UserID = @CustID,
						@CustID = @CustID, 
						@ActionID = 930, 
						@TrackingValue = @LogSPData
				END CATCH	
			END
			ELSE 
			BEGIN
				UPDATE CustSub WITH(UPDLOCK, ROWLOCK)
				SET closed = 1 
				WHERE SubAccId = @SubAccID AND CustID = @CustID
			
				UPDATE CustLoginInfoSub WITH(UPDLOCK, ROWLOCK)
				SET VerifyOTPCount = 0
				WHERE CustID = @CustID
			
				SELECT	@ErrCode = 200,
						@ErrMsg = CASE WHEN @Language = 'E' THEN 'We''re sorry, your account is closed because you provided wrong OTP over 5 times. Please contact CSD or your upline to reopen.'
										ELSE [dbo].[f_Get_MsgNamebyMsgID](40034, @Language) END
					
				
				SELECT @LogSPData = '<Age_OTP_CustomerStatusUpdAfterVerifiedOTP custid="' + COALESCE(CAST(@CustID AS VARCHAR(10)), SPACE(1)) + '" '																											
															+ 'SubAccount="' + COALESCE(CAST(dbo.f_GetSubUsername(@SubAccID) AS VARCHAR(30)), SPACE(1)) + '" '
															+ 'Language="' + COALESCE(@Language, SPACE(1)) + '" ' +
															+ 'IP="' + COALESCE(@IP, SPACE(1)) + '" />'
			
				BEGIN TRY
					EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
						@UserID = @CustID,
						@CustID = @CustID, 
						@ActionID = 931, 
						@TrackingValue = @LogSPData
				END TRY
				BEGIN CATCH
					SELECT @LogSPData = '<Age_OTP_CustomerStatusUpdAfterVerifiedOTP custid="' + COALESCE(CAST(@CustID AS VARCHAR(10)), SPACE(1)) + '" '																												
															+ 'SubAccount="' + COALESCE(CAST(dbo.f_GetSubUsername(@SubAccID) AS VARCHAR(30)), SPACE(1)) + '" '
															+ 'IP="' + COALESCE(@IP, SPACE(1)) + '" '
															+ 'ErrMsg="'+ COALESCE(ERROR_MESSAGE(), SPACE(1)) + '" />'
				
					EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
						@UserID = @CustID,
						@CustID = @CustID, 
						@ActionID = 931, 
						@TrackingValue = @LogSPData
				END CATCH														
			END
		END
		ELSE
		BEGIN 
			IF @VerifyOTPCount > 0
			BEGIN
				UPDATE CustLoginInfoSub WITH(UPDLOCK,ROWLOCK)
				SET VerifyOTPCount = 0
				WHERE CustID = @CustID AND SubAccID = @SubAccID
			END 
		END
	END
	ELSE -- main account
	BEGIN
		SELECT  @VerifyOTPCount = ISNULL(VerifyOTPCount, 0) FROM CustLoginInfo WITH(NOLOCK) WHERE CustID = @CustID

		IF @CheckedOTP = 0
		BEGIN 
			SELECT  @VerifyOTPCount = @VerifyOTPCount + 1
		
			IF @VerifyOTPCount <=5
			BEGIN 			
				UPDATE CustLoginInfo WITH(UPDLOCK, ROWLOCK)
				SET VerifyOTPCount = @VerifyOTPCount
				WHERE CustID = @CustID
			
				SELECT  @ErrCode = 100,
						@ErrMsg = CASE WHEN @Language = 'E' THEN 'Your OTP is invalid or expired.'
									ELSE [dbo].[f_Get_MsgNamebyMsgID](40035,@Language) END
			
				SELECT @LogSPData = '<Age_OTP_CustomerStatusUpdAfterVerifiedOTP custid="' + COALESCE(CAST(@custid AS VARCHAR(10)), SPACE(1)) + '" '	
															+ 'CheckedOTP="' + COALESCE(CAST(@CheckedOTP AS VARCHAR(10)), SPACE(1)) + '" '
															+ 'FunctionName="' + COALESCE(@FunctionName, SPACE(1)) + '" ' +
															+ 'Language="' + COALESCE(@Language, SPACE(1)) + '" ' +
															+ 'IP="' + COALESCE(@IP, SPACE(1)) + '" />'
			
				BEGIN TRY
					EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
						@UserID = @CustID,
						@CustID = @CustID, 
						@ActionID = 930, 
						@TrackingValue = @LogSPData
				END TRY
				BEGIN CATCH
					SELECT @LogSPData = '<Age_OTP_CustomerStatusUpdAfterVerifiedOTP custid="' + COALESCE(CAST(@custid AS VARCHAR(10)), SPACE(1)) + '" '		
															+ 'CheckedOTP="' + COALESCE(CAST(@CheckedOTP AS VARCHAR(10)), SPACE(1)) + '" '																										
															+ 'FunctionName="' + COALESCE(@FunctionName, SPACE(1)) + '" ' +
															+ 'Language="' + COALESCE(@Language, SPACE(1)) + '" ' +
															+ 'IP="' + COALESCE(@IP, SPACE(1)) + '" '
															+ 'ErrMsg="'+ COALESCE(ERROR_MESSAGE(), SPACE(1)) + '" />'
				
					EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
						@UserID = @CustID,
						@CustID = @CustID, 
						@ActionID = 930, 
						@TrackingValue = @LogSPData
				END CATCH	
			END
			ELSE 
			BEGIN
				UPDATE CustInfo WITH(UPDLOCK, ROWLOCK)
				SET closed = 1 
				WHERE CustID = @CustID
			
				UPDATE CustLoginInfo WITH(UPDLOCK, ROWLOCK)
				SET VerifyOTPCount = 0,ClosedReason=3
				WHERE CustID = @CustID
			
				SELECT	@ErrCode = 200,
						@ErrMsg = CASE WHEN @Language = 'E' THEN 'We''re sorry, your account is closed because you provided wrong OTP over 5 times. Please contact CSD or your upline to reopen.'
										ELSE [dbo].[f_Get_MsgNamebyMsgID](40034, @Language) END
					
				
				SELECT @LogSPData = '<Age_OTP_CustomerStatusUpdAfterVerifiedOTP custid="' + COALESCE(CAST(@CustID AS VARCHAR(10)), SPACE(1)) + '" '																											
															+ 'Language="' + COALESCE(@Language, SPACE(1)) + '" ' +
															+ 'IP="' + COALESCE(@IP, SPACE(1)) + '" />'
			
				BEGIN TRY
					EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
						@UserID = @CustID,
						@CustID = @CustID, 
						@ActionID = 931, 
						@TrackingValue = @LogSPData
				END TRY
				BEGIN CATCH
					SELECT @LogSPData = '<Age_OTP_CustomerStatusUpdAfterVerifiedOTP custid="' + COALESCE(CAST(@CustID AS VARCHAR(10)), SPACE(1)) + '" '																												
															+ 'IP="' + COALESCE(@IP, SPACE(1)) + '" '
															+ 'ErrMsg="'+ COALESCE(ERROR_MESSAGE(), SPACE(1)) + '" />'
				
					EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
						@UserID = @CustID,
						@CustID = @CustID, 
						@ActionID = 931, 
						@TrackingValue = @LogSPData
				END CATCH														
			END
		END
		ELSE
		BEGIN 
			IF @VerifyOTPCount > 0
			BEGIN
				UPDATE CustLoginInfo WITH(UPDLOCK,ROWLOCK)
				SET VerifyOTPCount = 0
				WHERE CustID = @CustID
			END 
		END
	END

	IF @ErrCode IS NULL
		SELECT @ErrCode = 0
	IF @ErrMsg IS NULL
		SELECT @ErrMsg = N''
END
GO
GRANT EXECUTE ON [dbo].[Age_OTP_CustomerStatusUpdAfterVerifiedOTP] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Age_OTP_CustomerStatusUpdAfterVerifiedOTP] TO [bodbDownlineNetView] AS [dbo]
GO