/*<info serverAlias="DBCUST-CustDB" executers="wsv_alp" viewers="vnteam" isFunction="0"></info>*/
 ALTER PROCEDURE [dbo].[Age_CustomerUpdSecurityCodeStatus]
	@custid			INT,
	@CheckedSecurityCode	BIT = 1,
	@FunctionName	VARCHAR(100) ='',	
	@Language		VARCHAR(2) = 'E',
	@IP				VARCHAR(20),
	@ErrCode		INT = 0 OUTPUT,
	@ErrMsg			NVARCHAR(500) = '' OUTPUT
 AS
	/*
		Created: Johnson
		Date: 2013-04-17
		Task: Update security code status of customer
		DB: DBTXN/bodb02
		
		Revisions:
		-- 20170619@Winnie: Apply color for closed Accounts RedmineID: #74494
		- 20210408@Tina: Lock account & indirect close account [redmine: #148600]

		Parameter's Explanation:
			- @CheckedSecurityCode: = 1: check security code success
								= 0: failed security code
			- @FunctionName: name of function which customer is required security code
			- @ErrCode = 100: failed count <= 5
						= 200: closed account
	*/
SET NOCOUNT ON
	DECLARE @securityCodeCount INT
	
	SELECT @securityCodeCount = ISNULL(securityCodeCount,0)
	FROM CustLoginInfo WITH(NOLOCK)
	WHERE custid = @custid
	
	IF @CheckedSecurityCode = 0
	BEGIN 
		DECLARE @LogSPData VARCHAR(MAX)
		
		SELECT @securityCodeCount = @securityCodeCount + 1
		
		IF @securityCodeCount <=5
		BEGIN 			
			UPDATE CustLoginInfo WITH(UPDLOCK,ROWLOCK)
			SET securityCodeCount = @securityCodeCount
			WHERE custid = @custid
			
			SELECT @ErrMsg = CASE WHEN @Language = 'E' THEN 'Your provided Security Code is not correct. Please try again'
												ELSE [dbo].[f_Get_MsgNamebyMsgID](40026,@Language) END,
				@ErrCode = 100		
			
			SELECT @LogSPData = '<Age_CustomerUpdSecurityCodeStatus custid="' + COALESCE(CAST(@custid AS VARCHAR(10)), SPACE(1)) + '" '	
														+ 'CheckedSecurityCode="' + COALESCE(CAST(@CheckedSecurityCode AS VARCHAR(10)), SPACE(1)) + '" '
														--+ 'FunctionName="' + COALESCE(@FunctionName, SPACE(1)) + '" ' +
														+ 'Language="' + COALESCE(@Language, SPACE(1)) + '" ' +
														+ 'IP="' + COALESCE(@IP, SPACE(1)) + '" />'
			
			BEGIN TRY
				EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
					@UserID = @CustID,
					@CustID = @CustID, 
					@ActionID = 917, 
					@TrackingValue = @LogSPData
			END TRY
			BEGIN CATCH
				SELECT @LogSPData = '<Age_CustomerUpdSecurityCodeStatus custid="' + COALESCE(CAST(@custid AS VARCHAR(10)), SPACE(1)) + '" '		
														+ 'CheckedSecurityCode="' + COALESCE(CAST(@CheckedSecurityCode AS VARCHAR(10)), SPACE(1)) + '" '																										
														--+ 'FunctionName="' + COALESCE(@FunctionName, SPACE(1)) + '" ' +
														+ 'Language="' + COALESCE(@Language, SPACE(1)) + '" ' +
														+ 'IP="' + COALESCE(@IP, SPACE(1)) + '" '
														+ 'ErrMsg="'+ COALESCE(ERROR_MESSAGE(), SPACE(1)) + '" />'
				
				EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
					@UserID = @CustID,
					@CustID = @CustID, 
					@ActionID = 917, 
					@TrackingValue = @LogSPData
			END CATCH	
		END
		ELSE 
		BEGIN
			UPDATE CustProductStatus WITH(UPDLOCK,ROWLOCK)
			SET Locked = 1 
			WHERE custid = @custid
			
			UPDATE CustLoginInfo WITH(UPDLOCK,ROWLOCK)
			SET securityCodeCount = 0
			WHERE custid = @custid
			
			SELECT @ErrMsg = CASE WHEN @Language = 'E' THEN 'Your account has been locked due to multiple failed security check. Please contact your upline to unlock.'
									ELSE [dbo].[f_Get_MsgNamebyMsgID](40045,@Language) END,
				@ErrCode = 200		
				
			SELECT @LogSPData = '<Age_CustomerUpdSecurityCodeStatus custid="' + COALESCE(CAST(@custid AS VARCHAR(10)), SPACE(1)) + '" '																											
														+ 'Language="' + COALESCE(@Language, SPACE(1)) + '" ' +
														+ 'IP="' + COALESCE(@IP, SPACE(1)) + '" />'
			
			BEGIN TRY
				EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
					@UserID = @CustID,
					@CustID = @CustID, 
					@ActionID = 918, 
					@TrackingValue = @LogSPData
			END TRY
			BEGIN CATCH
				SELECT @LogSPData = '<Age_CustomerUpdSecurityCodeStatus custid="' + COALESCE(CAST(@custid AS VARCHAR(10)), SPACE(1)) + '" '																												
														+ 'IP="' + COALESCE(@IP, SPACE(1)) + '" '
														+ 'ErrMsg="'+ COALESCE(ERROR_MESSAGE(), SPACE(1)) + '" />'
				
				EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
					@UserID = @CustID,
					@CustID = @CustID, 
					@ActionID = 918, 
					@TrackingValue = @LogSPData
			END CATCH														
		END
	END
	ELSE
	BEGIN 
		IF @securityCodeCount > 0
		BEGIN
			UPDATE CustLoginInfo WITH(UPDLOCK,ROWLOCK)
			SET securityCodeCount = 0
			WHERE custid = @custid
		END 
	END


GO
