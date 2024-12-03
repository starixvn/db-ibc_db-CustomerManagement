/*<info serverAlias="DBCUST-CustDB" executers="wsv_alp" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CustomerIndirectLoginAccountIns]
	@custid 	INT,
	@SubAccID 	INT = 0,
	@roleid		TINYINT,
	@username 	VARCHAR(50),
	@userpwd  	VARCHAR(50),
	@IP 		VARCHAR(15)= '',
	@LoginDomain NVARCHAR(253) = NULL,
	@BrowserName NVARCHAR(255) = NULL,
	@Platform 	NVARCHAR(255) = NULL,  
	@CountryCode VARCHAR(64) = NULL,
	@Language	VARCHAR(3) = 'E',
	@ErrCode  	INT = 0 OUTPUT,
	@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS
/*
	Created: 20200522@Johnson
	Task : add indirect login account by upline
	DB: DBCUST/CustDB

	Revisions:
		- 20200521@Johnson: initial sp [redmine:#133846]
		- 20210408@Tina: Lock account & indirect close account [redmine: #148600]
		- 20241206@Johnson: Apply In-house replication for Credit Setting [RedmineID: #212684]
	Parameter's explaination:
		- @roleid: role of login account
*/		
BEGIN
	SET NOCOUNT ON
	
	DECLARE @Begin DATETIME, 
			@End DATETIME, 
			@Duration INT,			
			@CustIDIndirect INT,
			@SubAccIDIndirect INT = 0,
			@RoleidIndirect TINYINT,
			@db_userpwd VARCHAR(40),
			@DownlineUsername VARCHAR(30),
			@failedcount INT
			
	SET @Begin = GETDATE() 
		
	IF @roleid = 4
	BEGIN
		SELECT @CustIDIndirect = custid,
			@RoleidIndirect = roleid,
			@db_userpwd = userpwd,
			@DownlineUsername = UserName,
			@failedcount = ISNULL(logincount,0)
		FROM customer WITH(NOLOCK) 
		WHERE (username = @username OR username2 = @username)
			AND srecommend = @custid
		
		IF @CustIDIndirect IS NULL
		BEGIN
			SELECT @CustIDIndirect = s.custid,
				@SubAccIDIndirect = s.SubAccID,
				@RoleidIndirect = c.roleid,
				@db_userpwd = s.userpwd,
				@DownlineUsername = s.UserName,
				@failedcount = ISNULL(s.logincount,0)
			FROM custSub s WITH(NOLOCK) 
				INNER JOIN customer c WITH(NOLOCK) ON s.custid = c.custid
			WHERE (s.username = @username OR s.username2 = @username)
				AND c.srecommend = @custid
		END
	END	
	ELSE IF @roleid = 3
	BEGIN
		SELECT @CustIDIndirect = custid,
			@RoleidIndirect = roleid,
			@db_userpwd = userpwd,
			@DownlineUsername = UserName,
			@failedcount = ISNULL(logincount,0)
		FROM customer WITH(NOLOCK) 
		WHERE (username = @username OR username2 = @username)
			AND mrecommend = @custid
		
		IF @CustIDIndirect IS NULL
		BEGIN
			SELECT @CustIDIndirect = s.custid,
				@SubAccIDIndirect = s.SubAccID,
				@RoleidIndirect = c.roleid,
				@db_userpwd = s.userpwd,
				@DownlineUsername = s.UserName,
				@failedcount = ISNULL(s.logincount,0)
			FROM custSub s WITH(NOLOCK) 
				INNER JOIN customer c WITH(NOLOCK) ON s.custid = c.custid
			WHERE (s.username = @username OR s.username2 = @username)
				AND c.mrecommend = @custid
		END
	END	
	
	SET @SubAccIDIndirect = ISNULL(@SubAccIDIndirect,0)
	
	IF @RoleidIndirect NOT IN (2,3) OR @CustIDIndirect IS NULL
	BEGIN
		IF @RoleidIndirect = 1
		BEGIN
			SELECT @ErrMsg = CASE @Language 
					WHEN 'E' THEN 'You cannot indirectly log in to member account.'
					ELSE [dbo].[f_Get_MsgNamebyMsgID](40053,@Language)
				END	,@ErrCode=100	
		END
		ELSE 
		BEGIN
			SELECT @ErrMsg = CASE @Language 
					WHEN 'E' THEN 'Invalid account or it is not your downline.'
					ELSE [dbo].[f_Get_MsgNamebyMsgID](40052,@Language)
				END	,@ErrCode=101		
		END		
		RETURN	
	END
	
	IF (@SubAccIDIndirect = 0
		AND EXISTS (SELECT 1 
					FROM custinfo ci WITH(NOLOCK) 
						JOIN CustProductStatus cps WITH(NOLOCK) ON ci.custid = cps.CustID
					WHERE ci.custid = @custidIndirect 
						AND (cps.CloseInfo > 0 OR ci.[enabled] = 0))
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
	ELSE IF (@SubAccIDIndirect = 0
		AND EXISTS (SELECT 1 FROM CustProductStatus WITH(NOLOCK) WHERE custid = @custidIndirect AND ISNULL(Locked,0) > 0)) 
	BEGIN
		SELECT @ErrMsg = CASE @Language 
				WHEN 'E' THEN 'This account is locked, please unlock it and try again.'
				ELSE [dbo].[f_Get_MsgNamebyMsgID](40057,@Language)
			END	,@ErrCode=104		
		RETURN	
	END			
	
	DECLARE @ServerID INT,
			@UplineUsername VARCHAR(30),
			@LogData VARCHAR(4000),
			@LogSPData VARCHAR(4000)
				
	IF @SubAccID = 0
	BEGIN
		SELECT @UplineUsername = username
		FROM customer WITH(NOLOCK)
		WHERE custid = @custid
	END
	ELSE 
	BEGIN
		SELECT @UplineUsername = username
		FROM custSub WITH(NOLOCK)
		WHERE custid = @custid
			AND SubAccID = @SubAccID
	END
	
	--check pwd
	IF @userpwd <> @db_userpwd
	BEGIN		
		SELECT @failedcount = @failedcount + 1
		
		SET @End = GETDATE()
		SET @Duration = DATEDIFF(millisecond,@Begin,@End)
				
		IF @failedcount > 5
		BEGIN
			IF @SubAccIDIndirect = 0
			BEGIN
				UPDATE CustProductStatus WITH (ROWLOCK, UPDLOCK) 
				SET locked = 2,
					RepUpdateTime = dbo.f_GetDateTime2()
				WHERE custid = @custidIndirect 
				
				UPDATE Customer WITH (ROWLOCK,UPDLOCK) 
				SET logincount = 0,
					RepUpdateTime = dbo.f_GetDateTime2()
				WHERE custid = @custidIndirect 
				
				SELECT @LogSPData = '<R '
									+CASE WHEN @SubAccID > 0 THEN 'UplineSubAccount="'  + @UplineUserName +'" ' ELSE '' END 
									+'IP="'+ COALESCE(@IP,SPACE(1)) + '" />'		    
				
				EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
					@UserID = @custid,
					@CustID = @CustIDIndirect,
					@ActionID = 946,
					@TrackingValue = @LogSPData,
					@Duration = @Duration			
			END
			ELSE
			BEGIN
				UPDATE custSub WITH (ROWLOCK, UPDLOCK) 
				SET closed = 1, 
					logincount = 0,
					RepUpdateTime = dbo.f_GetDateTime2()
				WHERE subaccid = @SubAccIDIndirect
					    
				SELECT @LogSPData = '<R ' 
									+CASE WHEN @SubAccID > 0 THEN 'UplineSubAccount="'  + @UplineUserName +'" ' ELSE '' END 
									+'DownlineSubAccount="'  + COALESCE(@DownlineUsername,SPACE(1)) +'" ' 
									+'IP="'+ COALESCE(@IP,SPACE(1)) + '" />'											
				EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
					@UserID = @CustID,
					@CustID = @CustIDIndirect,
					@ActionID = 946,
					@TrackingValue = @LogSPData,
					@Duration = @Duration
			END
		END
		ELSE 
		BEGIN
			IF @SubAccIDIndirect = 0
			BEGIN
				UPDATE	customer WITH (ROWLOCK, UPDLOCK) 
				SET		logincount = @failedcount,
						RepUpdateTime = dbo.f_GetDateTime2()
				WHERE	custid = @custidIndirect
			END
			ELSE
			BEGIN
				UPDATE custSub WITH (ROWLOCK, UPDLOCK) 
				SET logincount = @failedcount,
					RepUpdateTime = dbo.f_GetDateTime2()
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
			@ActionID = 1335,
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
	
	IF EXISTS(SELECT 1 FROM CustInDirectLogin WITH(NOLOCK)
			WHERE custid = @custid
				AND SubAccID = @SubAccID
				AND custidIndirect = @custidIndirect
				AND SubAccIDIndirect = @SubAccIDIndirect
			)
	BEGIN
		SELECT @ErrMsg = CASE @Language 
				WHEN 'E' THEN 'The account has already been connected.'
				ELSE [dbo].[f_Get_MsgNamebyMsgID](40054,@Language)
			END	,@ErrCode=103	
		RETURN
	END
	
	INSERT INTO CustInDirectLogin(CustID, SubAccID,CustIDIndirect, SubAccIDIndirect,LastVerifyPwd)
	SELECT @custid, @SubAccID, @CustIDIndirect, @SubAccIDIndirect,GETDATE()
	
	IF @SubAccIDIndirect > 0
	BEGIN
		UPDATE custSub with (rowlock, updlock) 
		SET logincount = 0,
			RepUpdateTime = dbo.f_GetDateTime2()
		WHERE subaccid = @SubAccIDIndirect 
	END
	ELSE 
	BEGIN
		UPDATE customer with (rowlock, updlock)  
		SET logincount = 0,
			RepUpdateTime = dbo.f_GetDateTime2()
		WHERE custid = @CustIDIndirect
	END
	
	-- Write log
	SELECT @LogSPData = '<R '
							+CASE WHEN @SubAccID > 0 THEN 'UplineSubAccount="'  + COALESCE(@UplineUserName,SPACE(1)) +'" ' ELSE '' END 
							+'Account="'  + COALESCE(@DownlineUsername,SPACE(1)) +'" ' 
							+'IP="'+ COALESCE(@IP,SPACE(1)) + '" />'					

	SELECT @Duration = DATEDIFF (MILLISECOND, @Begin, GETDATE())
			
	EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
		@UserId				= @custid,
		@CustId				= @CustIDIndirect,
		@ActionId			= 95019,
		@TrackingValue		= @LogSPData,		
		@Duration			= @Duration
END	
GO
