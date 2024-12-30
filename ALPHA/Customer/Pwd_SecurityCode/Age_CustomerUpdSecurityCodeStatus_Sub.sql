/*<info serverAlias="DBCUST-CustDB" executers="wsv_alp,wsv_alpv" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CustomerUpdSecurityCodeStatus_Sub]
	@custid		INT,
	@subAccID	INT,
	@CheckedSecurityCode BIT = 1,
	@FunctionName VARCHAR(100) ='',
	@Language	VARCHAR(2) = 'E',
	@IP			VARCHAR(20),
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		NVARCHAR(500) = '' OUTPUT
 AS
	/*Created: Johnson
		Date: 2013-04-17
		Task: Update security code status of sub account
		DB: DBTXN/bodb02
		
		Revisions:
			- 20250109@Johnson: Apply In-house replication for Credit Setting [RedmineID: #212684]		
			- 20241230@Aries: Scale Out DBCUST - Apply Inhouse replication for the remaning tables [Redmine: #215627]
		
		Parameter's Explanation:
			- @CheckedSecurityCode = 1: checked security code success
								= 0: wrong security code
			- @FunctionName: name of function which customer is required security code
			- @ErrCode = 100: failed providing SC
						= 200: Closed account
	*/
SET NOCOUNT ON
	DECLARE @SecurityCodeCount INT
	
	SELECT @SecurityCodeCount = ISNULL(SecurityCodeCount,0)
	FROM CustLoginInfoSub WITH(NOLOCK)
	WHERE SubAccID = @subAccID AND custid = @custid 
	
	IF @CheckedSecurityCode = 0
	BEGIN 
		DECLARE @LogSPData VARCHAR(MAX)
		
		SELECT @SecurityCodeCount = @SecurityCodeCount + 1
		
		IF @SecurityCodeCount <= 5
		BEGIN 			
			UPDATE CustLoginInfoSub WITH(UPDLOCK,ROWLOCK)
			SET SecurityCodeCount = @SecurityCodeCount
			   ,RepUpdateTime = dbo.f_GetDateTime2()
			WHERE subAccID = @subAccID AND custid = @custid 
			
			SELECT @ErrMsg = CASE WHEN @Language = 'E' THEN 'Your provided Security Code is not correct. Please try again'
												ELSE [dbo].[f_Get_MsgNamebyMsgID](40026,@Language) END,
				@ErrCode = 100	
			
			SELECT @LogSPData = '<Age_CustomerUpdSecurityCodeStatus_Sub SubAccount="' + COALESCE(CAST(dbo.f_GetSubUsername(@SubAccID) AS VARCHAR(30)), SPACE(1)) + '" ' 
														+ 'CheckedSecurityCode="' + COALESCE(CAST(@CheckedSecurityCode AS VARCHAR(10)), SPACE(1)) + '" '
														+ 'FunctionName="' + COALESCE(@FunctionName, SPACE(1)) + '" ' +
														+ 'Language="' + COALESCE(@Language, SPACE(1)) + '" ' +
														+ 'IP="' + COALESCE(@IP, SPACE(1)) + '" />'
			
			BEGIN TRY
				EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
					@UserID = @CustID,
					@CustID = @CustID, 
					@ActionID = 921, 
					@TrackingValue = @LogSPData
			END TRY
			BEGIN CATCH
				SELECT @LogSPData = '<Age_CustomerUpdSecurityCodeStatus_Sub SubAccount="' + COALESCE(CAST(dbo.f_GetSubUsername(@SubAccID) AS VARCHAR(30)), SPACE(1)) + '" ' 
														+ 'CheckedSecurityCode="' + COALESCE(CAST(@CheckedSecurityCode AS VARCHAR(10)), SPACE(1)) + '" '														
														+ 'FunctionName="' + COALESCE(@FunctionName, SPACE(1)) + '" ' +
														+ 'Language="' + COALESCE(@Language, SPACE(1)) + '" ' +
														+ 'IP="' + COALESCE(@IP, SPACE(1)) + '" '
														+ 'ErrMsg="'+ COALESCE(ERROR_MESSAGE(), SPACE(1)) + '" />'
				
				EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
					@UserID = @CustID,
					@CustID = @CustID, 
					@ActionID = 921, 
					@TrackingValue = @LogSPData
			END CATCH		
		END
		ELSE
		BEGIN
			UPDATE CustSub WITH(UPDLOCK,ROWLOCK)
			SET closed = 1,
				RepUpdateTime = dbo.f_GetDateTime2()
			WHERE subAccID = @SubAccID AND custid = @custid
						
			UPDATE CustLoginInfoSub WITH(UPDLOCK,ROWLOCK)
			SET SecurityCodeCount = 0
				,RepUpdateTime = dbo.f_GetDateTime2()
			WHERE subAccID = @subAccID AND custid = @custid 
			
			SELECT @ErrMsg = CASE WHEN @Language = 'E' THEN 'We''re sorry, your account is closed because you provided wrong SC over 5 times. Please contact CSD or your upline to reopen.'
									ELSE [dbo].[f_Get_MsgNamebyMsgID](40025,@Language) END,
				@ErrCode = 200		
				
			SELECT @LogSPData = '<Age_CustomerUpdSecurityCodeStatus_Sub SubAccount="' + COALESCE(CAST(dbo.f_GetSubUsername(@SubAccID) AS VARCHAR(30)), SPACE(1)) + '" ' 																												
														+ 'Language="' + COALESCE(@Language, SPACE(1)) + '" ' +
														+ 'IP="' + COALESCE(@IP, SPACE(1)) + '" />'
			
			BEGIN TRY
				EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
					@UserID = @CustID,
					@CustID = @CustID, 
					@ActionID = 922, 
					@TrackingValue = @LogSPData
			END TRY
			BEGIN CATCH
				SELECT @LogSPData = '<Age_CustomerUpdSecurityCodeStatus_Sub SubAccount="' + COALESCE(CAST(dbo.f_GetSubUsername(@SubAccID) AS VARCHAR(30)), SPACE(1)) + '" ' 
														+ 'Language="' + COALESCE(@Language, SPACE(1)) + '" ' +
														+ 'IP="' + COALESCE(@IP, SPACE(1)) + '" '
														+ 'ErrMsg="'+ COALESCE(ERROR_MESSAGE(), SPACE(1)) + '" />'
				
				EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
					@UserID = @CustID,
					@CustID = @CustID, 
					@ActionID = 922, 
					@TrackingValue = @LogSPData
			END CATCH														
		END
	END
	ELSE
	BEGIN 
		IF @SecurityCodeCount > 0
		BEGIN
			UPDATE CustLoginInfoSub WITH(UPDLOCK,ROWLOCK)
			SET  SecurityCodeCount = 0
				,RepUpdateTime = dbo.f_GetDateTime2()
			WHERE SubAccID = @SubAccID AND custid = @custid
		END 
	END


GO