/*<info serverAlias="DBCUST-CustDB" executers="bodbDownlineNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CustomerIndirectLoginAccountPwdCheck]
	@custid 	INT,
	@SubAccID 	INT = 0,	
	@CustIDIndirect INT,
	@SubAccIDIndirect INT = 0,
	@UserPWD 		VARCHAR(40),
	@UplineUsername VARCHAR(30),
	@DownlineUsername VARCHAR(30),
	@RoleidIndirect TINYINT,	
	@LoginDomain 	NVARCHAR(253) = NULL,
	@BrowserName 	NVARCHAR(255) = NULL,
	@Platform 		NVARCHAR(255) = NULL,  
	@CountryCode 	VARCHAR(64) = NULL,
	@IP 		VARCHAR(15)= '',	
	@Language	VARCHAR(3) = 'E',
	@ErrCode  	INT = 0 OUTPUT,
	@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS
/*
	Created: 20200526@Johnson
	Task : Check pwd for indirect login account by upline
	DB: DBCUST/CustDB

	Revisions:
		- 20200526@Johnson: initial sp [redmine:#133846]
	
	Parameter's explaination:		
*/		
BEGIN
	SET NOCOUNT ON
	
	DECLARE @Begin DATETIME, 			
			@Duration INT,
			@db_userpwd VARCHAR(40),
			@failedcount INT,
			@LogSPData VARCHAR(4000)
	
	SET @Begin = GETDATE() 

	IF NOT EXISTS (SELECT 1 FROM CustDirectLogin WITH(NOLOCK)
					WHERE custid = @custid
						AND SubAccID = @subAccID
						AND CustIDIndirect = @CustIDIndirect
						AND SubAccIDIndirect = @SubAccIDIndirect
				)
	BEGIN
		SELECT @ErrMsg = CASE @Language 
				WHEN 'E' THEN 'Invalid account or it is not your downline.'
				ELSE [dbo].[f_Get_MsgNamebyMsgID](40052,@Language)
			END	,@ErrCode=101		
		RETURN	
	END
	
	IF (@SubAccIDIndirect = 0
		AND EXISTS (SELECT 1 FROM custinfo WITH(NOLOCK) 
					WHERE custid = @custidIndirect 
						AND (closed = 1 OR enabled = 0))
		) 
		OR (@SubAccIDIndirect > 0
			AND EXISTS (SELECT 1 FROM custsub WITH(NOLOCK) 
						WHERE custid = @CustIDIndirect 
							AND SubAccID = @SubAccIDIndirect 
							AND closed = 1
						)
			)
	BEGIN
		SELECT @ErrMsg = CASE @Language 
				WHEN 'E' THEN 'This account is closed or disabled, please open it and try again.'
				ELSE [dbo].[f_Get_MsgNamebyMsgID](60036,@Language)
			END	,@ErrCode=102		
		RETURN	
	END	
	
	IF @SubAccIDIndirect = 0
	BEGIN
		SELECT @db_userpwd = userpwd,
			@failedcount = ISNULL(logincount,0)
		FROM customer WITH(NOLOCK)
		WHERE custid = @custidIndirect
	END
	ELSE 
	BEGIN
		SELECT @db_userpwd = userpwd,
			@failedcount = ISNULL(logincount,0)			
		FROM custSub WITH(NOLOCK)
		WHERE SubAccID = @SubAccIDIndirect
	END
	
	--check pwd
	IF @userpwd <> @db_userpwd
	BEGIN
		DECLARE @ServerID INT,				
				@LogData VARCHAR(4000)				
		
		SELECT @failedcount = @failedcount + 1
		
		SET @Duration = DATEDIFF(millisecond,@Begin,GETDATE())
				
		IF @failedcount > 5
		BEGIN
			IF @SubAccIDIndirect = 0
			BEGIN
				UPDATE custinfo WITH (ROWLOCK, UPDLOCK) SET closed = 1 WHERE custid = @custidIndirect 
				
				UPDATE Customer WITH (ROWLOCK,UPDLOCK) SET logincount = 0 WHERE custid = @custidIndirect 
				
				SELECT @LogSPData = '<Age_CustomerIndirectLoginAccountIns IP="'+ @IP + '" />'		    
				
				EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
					@UserID = @custid,
					@CustID = @CustIDIndirect,
					@ActionID = 947,
					@TrackingValue = @LogSPData,
					@Duration = @Duration			
			END
			ELSE
			BEGIN
				UPDATE custSub WITH (ROWLOCK, UPDLOCK) SET closed = 1, logincount = 0 WHERE subaccid = @SubAccIDIndirect
					    
				SELECT @LogSPData = '<R ' 
										+CASE WHEN @SubAccID > 0 THEN 'UplineSubAccount="'  + @UplineUserName +'" ' ELSE '' END 
										+'DownlineSubAccount="'  + @UplineUserName +'" ' 
										+'IP="'+ @IP + '" />'										
				EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
					@UserID = @CustID,
					@CustID = @CustIDIndirect,
					@ActionID = 947,
					@TrackingValue = @LogSPData,
					@Duration = @Duration
			END
		END
		ELSE 
		BEGIN
			IF @SubAccIDIndirect = 0
			BEGIN
				UPDATE	customer WITH (ROWLOCK, UPDLOCK) 
				SET		logincount = @failedcount 
				WHERE	custid = @custidIndirect
			END
			ELSE
			BEGIN
				UPDATE custSub WITH (ROWLOCK, UPDLOCK) 
				SET logincount = @failedcount
				WHERE subaccid = @SubAccIDIndirect
			END
		END	
		
		SELECT @ServerID = CASE WHEN @RoleidIndirect= 2 THEN 90 WHEN @RoleidIndirect=3 THEN 91 ELSE 0 END -- login from web
		SELECT @LogData = 'From account: '+ @UplineUsername + ' - To account: '+ @DownlineUsername + ' Login Result: Failed (Password Problem)' 
				
		EXEC dbo.Acc_WriteLog_UserLog_Login_Wrapper
			@UserID = @CustIDIndirect, 
			@RoleID = @RoleidIndirect, 
			@SubAccID = @SubAccIDIndirect,
			@ServerID = @ServerID,
			@LoginIP = @IP,
			@DomainName = @LoginDomain,	
			@ActionID = 1336,
			@Doing = @LogData,
			@BrowserName = @BrowserName,
			@Platform = @Platform,
			@CountryCode = @CountryCode,
			@Duration = @Duration
		
		SELECT @ErrMsg = CASE @Language 
				WHEN 'E' THEN 'Wrong password.'
				ELSE [dbo].[f_Get_MsgNamebyMsgID](80011,@Language)
			END	,@ErrCode=103		
		RETURN	
	END
	
	UPDATE CustDirectLogin WITH(UPDLOCK,ROWLOCK)
	SET LastVerifyPwd = GETDATE()
	WHERE custid = @custid
		AND SubAccID = @subAccID
		AND CustIDIndirect = @CustIDIndirect
		AND SubAccIDIndirect = @SubAccIDIndirect
		
	-- Write log
	SELECT @LogSPData = '<R '
							+CASE WHEN @SubAccID > 0 THEN 'UplineSubAccount="'  + @UplineUserName +'" ' ELSE '' END 
							+'Account="'  + @DownlineUsername +'" ' 
							+'IP="'+ @IP + '" />'					

	SELECT @Duration = DATEDIFF (MILLISECOND, @Begin, GETDATE())
			
	EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
		@UserId				= @custid,
		@CustId				= @CustIDIndirect,
		@ActionId			= 95021,
		@TrackingValue		= @LogSPData,		
		@Duration			= @Duration	
END			