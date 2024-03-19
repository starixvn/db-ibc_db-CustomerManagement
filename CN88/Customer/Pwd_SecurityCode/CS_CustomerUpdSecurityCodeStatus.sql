/*<info serverAlias="DBCUST-CustDB" executers="bodbDownlineNet,wsv_alp" viewers="" isFunction="0"></info>*/

 ALTER PROCEDURE [dbo].[CS_CustomerUpdSecurityCodeStatus]
	@custid			INT,
	@CheckedSecurityCode	BIT = 1,
	@FunctionName	VARCHAR(100) ='',	
	@Language		VARCHAR(2) = 'E',
	@IP				VARCHAR(20),
	@ErrCode		INT = 0 OUTPUT,
	@ErrMsg			NVARCHAR(500) = '' OUTPUT
 AS
/*
	Created: Elodie
	Date: 20190530
	Task: Update security code status of customer
	DB: DBCUST/CustDB
		
	Revisions:
		- 20190530@Elodie: Initial SP [Redmine: 113198]
		- 20190606@Elodie: Apply new structure for CN88's log [Redmine: #113198]

	Parameter's Explanation:
		- @CheckedSecurityCode: = 1: check security code success
							= 0: failed security code
		- @FunctionName: name of function which customer is required security code
		- @ErrCode = 100: failed count <= 5
					= 200: closed account
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @startRun DATETIME, @endRun DATETIME, @duration INT
	DECLARE @securityCodeCount INT
	
	SET @startRun = GETDATE()

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
			
			SELECT @LogSPData = '<R CheckedSecurityCode="' + COALESCE(CAST(@CheckedSecurityCode AS VARCHAR(10)), SPACE(1)) + '" '
								+ 'FunctionName="' + COALESCE(@FunctionName, SPACE(1)) + '" ' +
								+ 'Language="' + COALESCE(@Language, SPACE(1)) + '" ' +
								+ 'IP="' + COALESCE(@IP, SPACE(1)) + '" />'
			
			SET @endRun = GETDATE()
			SET @duration = DATEDIFF (MILLISECOND,@startRun,@endRun)

			EXEC dbo.CS_WriteLog_UserLog_RunSP_Wrapper
				@UserID = @CustID,
				@CustID = @CustID, 
				@ActionID = 943, 
				@TrackingValue = @LogSPData,
				@Duration = @duration					
		END
		ELSE 
		BEGIN
			UPDATE CustInfo WITH(UPDLOCK,ROWLOCK)
			SET closed = 1 
			WHERE custid = @custid
			
			UPDATE CustLoginInfo WITH(UPDLOCK,ROWLOCK)
			SET securityCodeCount = 0,ClosedReason=3
			WHERE custid = @custid
			
			SELECT @ErrMsg = CASE WHEN @Language = 'E' THEN 'Your account has been locked due to multiple failed security check attempts. Please contact your upline to unlock.'
									ELSE [dbo].[f_Get_MsgNamebyMsgID](40045,@Language) END,
				@ErrCode = 200		
				
			SELECT @LogSPData = '<R Language="' + COALESCE(@Language, SPACE(1)) + '" '
									+ 'IP="' + COALESCE(@IP, SPACE(1)) + '" />'
			
			SET @endRun = GETDATE()
			SET @duration = DATEDIFF (MILLISECOND,@startRun,@endRun)

			EXEC dbo.CS_WriteLog_UserLog_RunSP_Wrapper
				@UserID = @CustID,
				@CustID = @CustID, 
				@ActionID = 944, 
				@TrackingValue = @LogSPData,
				@Duration = @duration																			
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
END

