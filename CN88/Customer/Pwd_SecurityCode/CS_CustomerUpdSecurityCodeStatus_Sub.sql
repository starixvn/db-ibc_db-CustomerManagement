  /*<info serverAlias="DBCUST-CustDB" executers="bodbDownlineNet,wsv_alp" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE CS_CustomerUpdSecurityCodeStatus_Sub
	@custid		INT,
	@subAccID	INT,
	@CheckedSecurityCode BIT = 1,
	@FunctionName VARCHAR(100) ='',
	@Language	VARCHAR(2) = 'E',
	@IP			VARCHAR(20),
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		NVARCHAR(500) = '' OUTPUT
AS
/*	Created: Elodie
	Date: 20190530
	Task: Update security code status of sub account
	DB: DBCUST/CustDB
		
	Revisions:
		- 20190530@Elodie: Initial SP [Redmine: 113198]

	Parameter's Explanation:
		- @CheckedSecurityCode = 1: checked security code success
							= 0: wrong security code
		- @FunctionName: name of function which customer is required security code
		- @ErrCode = 100: failed providing SC
					= 200: Closed account
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @startRun DATETIME, @endRun DATETIME, @duration INT
	DECLARE @SecurityCodeCount INT
	
	SET @startRun = GETDATE()

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
			WHERE subAccID = @subAccID AND custid = @custid 
			
			SELECT @ErrMsg = CASE WHEN @Language = 'E' THEN 'Your provided Security Code is not correct. Please try again'
												ELSE [dbo].[f_Get_MsgNamebyMsgID](40026,@Language) END,
				@ErrCode = 100	
			
			SELECT @LogSPData = '<R SubAccount="' + COALESCE(CAST(dbo.f_GetSubUsername(@SubAccID) AS VARCHAR(30)), SPACE(1)) + '" ' 
								+ 'CheckedSecurityCode="' + COALESCE(CAST(@CheckedSecurityCode AS VARCHAR(10)), SPACE(1)) + '" '
								+ 'FunctionName="' + COALESCE(@FunctionName, SPACE(1)) + '" ' +
								+ 'Language="' + COALESCE(@Language, SPACE(1)) + '" ' +
								+ 'IP="' + COALESCE(@IP, SPACE(1)) + '" />'
			
			SET @endRun = GETDATE()
			SET @duration = DATEDIFF (MILLISECOND,@startRun,@endRun)

			EXEC dbo.CS_WriteLog_UserLog_RunSP_Wrapper
				@UserID = @CustID,
				@CustID = @CustID, 
				@ActionID = 941, 
				@TrackingValue = @LogSPData,
				@Duration = @duration			
		END
		ELSE
		BEGIN
			UPDATE CustSub WITH(UPDLOCK,ROWLOCK)
			SET closed = 1 
			WHERE subAccID = @SubAccID AND custid = @custid
						
			UPDATE CustLoginInfoSub WITH(UPDLOCK,ROWLOCK)
			SET SecurityCodeCount = 0
			WHERE subAccID = @subAccID AND custid = @custid 
			
			SELECT @ErrMsg = CASE WHEN @Language = 'E' THEN 'Your sub account has been locked due to multiple failed security check attempts. Please contact the main account user to unlock.'
									ELSE [dbo].[f_Get_MsgNamebyMsgID](40044,@Language) END,
				@ErrCode = 200		
				
			SELECT @LogSPData = '<R SubAccount="' + COALESCE(CAST(dbo.f_GetSubUsername(@SubAccID) AS VARCHAR(30)), SPACE(1)) + '" ' 																												
								+ 'Language="' + COALESCE(@Language, SPACE(1)) + '" ' +
								+ 'IP="' + COALESCE(@IP, SPACE(1)) + '" />'
			
			SET @endRun = GETDATE()
			SET @duration = DATEDIFF (MILLISECOND,@startRun,@endRun)

			EXEC dbo.CS_WriteLog_UserLog_RunSP_Wrapper
				@UserID = @CustID,
				@CustID = @CustID, 
				@ActionID = 942, 
				@TrackingValue = @LogSPData,
				@Duration = @duration																			
		END
	END
	ELSE
	BEGIN 
		IF @SecurityCodeCount > 0
		BEGIN
			UPDATE CustLoginInfoSub WITH(UPDLOCK,ROWLOCK)
			SET SecurityCodeCount = 0
			WHERE SubAccID = @SubAccID AND custid = @custid
		END 
	END
END
