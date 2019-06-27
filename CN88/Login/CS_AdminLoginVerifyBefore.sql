/*<info serverAlias="DBCUST-CUSTDB" executers="bodbDownlineNet, bodbDownlineNetView" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE [dbo].[CS_AdminLoginVerifyBefore]
	@UserName VARCHAR(50) = '' OUTPUT ,  
	@UserPwd VARCHAR(50),  
	@CustID INT OUTPUT, 	  	
	@LoginIP VARCHAR(20)='',  --- if output=NULL then account is the first login
	@SubAccID INT = 0 OUTPUT, --Sub-AccountID,
	@ServerID INT =0 OUTPUT,  
	@LoginTime DATETIME = null OUTPUT, --varchar(50) = null OUTPUT,	
	@LoginDomain NVARCHAR(253) = NULL ,
	@SiteGroup VARCHAR(10) = 'ALL',
	@Language VARCHAR(2) = 'E', 
	@BrowserName NVARCHAR(255) = NULL,
	@Platform NVARCHAR(255) = NULL,  
	@CountryCode VARCHAR(64) = NULL,
	@LastChangedPwdDate	DATETIME = NULL OUTPUT , 
	@ErrCode INT = 0 OUTPUT,  
	@ErrMsg NVARCHAR(4000) = '' OUTPUT,
	@IsNickname BIT = 0 OUTPUT,
	@NickName VARCHAR(50) = '' OUTPUT
AS
/*
	Created: 20190219@Johnson
	Task : Before Login for Tier0
	DB: DBCust/CUSTDB

	Revisions:
		- 20190219@Johnson: Clone sp from Age_LoginVerifyDownline for cn88 tier0 login [Redmine: #105660]
		- 20190422@Elodie: Offer unique nickname for CN88 [Redmine: 112287]

	Param's Explanation:
		• @IsNickname: is use Nickname or not
		• @SiteGroup: Check the site and corresponding domain
			+ ALL: All add domains 
			+ 789y: Allow customers of 789y ONLY
			+ IBCBET | Others: Allow all customers except 789y
		• @LastChangedPwdDate: If = NULL: Login current pass, <> NULL : Login old Pass 
		• @ErrCode:
			= 0: Transaction recorded successfully.
			> 0: Specific Error.		
				106: wrong username and password
				107: login failed
				108: account closed
				109: login exceed 5 times
				110: login failed because access from outsite throught test accounts
				111: not nickname
		• @ErrMsg: Error description.

*/
BEGIN
	SET NOCOUNT ON
	DECLARE @Begin DATETIME, @End DATETIME, @Duration INT, @inputLoginIP VARCHAR(15)

	SET @Begin = GETDATE()
	SELECT	@inputLoginIP = @LoginIP		

	DECLARE @isExisted BIT, @RoleID TINYINT, @role NVARCHAR(20), @closed BIT, 
		@LogData NVARCHAR(200), @LogSPData VARCHAR(1000),	
		@db_custid INT, @db_userpwd	NVARCHAR(50), @db_Username2 VARCHAR(50), @db_currency TINYINT, @OldUserPwd	VARCHAR(40), @failedcount INT, 		
		@db_loginip NVARCHAR(20), @db_enabled BIT,			
		-- For checking login domain
		@Site varchar(10), @IsMatched bit, @rowcount int, @isAllowed bit, @IsAccess BIT, @Status TINYINT
		
	SELECT @isAllowed = 0
	 
	----- begin 20110608: login using Nickname
	SET @ServerID = 0
	 
	SELECT @db_Username2 = NickName FROM dbo.f_CS_GetNickName(@UserName,1)

	IF EXISTS (SELECT 1 FROM customer AS c WITH (NOLOCK) WHERE c.username2 = @db_Username2)
	BEGIN
		----use nickname
		SELECT	@db_custid = custid, @db_userpwd = userpwd, @RoleID = roleid, @db_currency = currency, @failedcount = isnull(logincount,0),  
				@site = site , @db_loginip= isnull(iplogin, ''), @Nickname = @UserName, @UserName = Username, @IsNickname = 1
		FROM customer c WITH (NOLOCK)
		WHERE username2 = @db_Username2					
		
	END
	ELSE
	BEGIN
		--use username
		SELECT @db_custid = custid, @db_userpwd = userpwd, @RoleID = roleid, @db_currency = currency, @failedcount = isnull(logincount,0),  
				@site = site , @db_loginip= isnull(iplogin, ''),  @IsNickname = 0, @Nickname = f.NickName
		FROM customer WITH (NOLOCK)
			CROSS APPLY dbo.f_CS_GetNickName(UserName2,0) f			
		WHERE username = @UserName				
	END
	
	SET @rowcount = @@ROWCOUNT
	
	-- Check CN88 Site 
	IF(@rowcount <> 0)
	BEGIN
		IF @SiteGroup <>'ALL'  
		BEGIN
			EXEC dbo.Age_LoginCheckSiteGroup 
					@SiteGroup = @SiteGroup, 
					@Site = @Site,
					@isAllowed = @isAllowed OUTPUT

			IF @isAllowed = 0 
			BEGIN
				SELECT @LogData = 'Agent: ' + @UserName + ', login to wrong domain (' + @Site + '/' + @LoginDomain + ')'
				
				SET	@End = GETDATE() 
				SET @Duration = DATEDIFF(millisecond,@Begin,@End)			
			
				IF @IsNickname = 1
				BEGIN
					EXEC dbo.CS_WriteLog_UserLog_Login_Wrapper
						@UserID = @db_custid, 
						@RoleID = @RoleID, 
						@SubAccID = @SubAccID,
						@ServerID = @ServerID,
						@LoginIP = @inputLoginIP,
						@DomainName = @LoginDomain,	
						@ActionID = 1325,
						@Doing = @LogData,
						@BrowserName = @BrowserName,
						@Platform = @Platform,
						@CountryCode = @CountryCode,
						@Duration = @Duration,
						@Nickname = @db_Username2											
				END	
				ELSE 
				BEGIN
					EXEC dbo.CS_WriteLog_UserLog_Login_Wrapper
						@UserID = @db_custid, 
						@RoleID = @RoleID, 
						@SubAccID = @SubAccID,
						@ServerID = @ServerID,
						@LoginIP = @inputLoginIP,
						@DomainName = @LoginDomain,	
						@ActionID = 1325,
						@Doing = @LogData,
						@BrowserName = @BrowserName,
						@Platform = @Platform,
						@CountryCode = @CountryCode,
						@Duration = @Duration						
				END	
					SELECT @ErrMsg = CASE @Language WHEN 'E' THEN  'Wrong username/nickname or password.' 
							 ELSE [dbo].[f_Get_MsgNamebyMsgID](80001,@Language)
							 END ,@ErrCode=106  

				RETURN
			END 
		END	
	END	
	-- End Checking login domain

	-- user not found  
	IF (@rowcount = 0)
	BEGIN  
		SELECT @LogData =  'Agent:' + @UserName + ' Result:Failed (User_Not_Found)'
		
		SET	@End = GETDATE() 
		SET @Duration = DATEDIFF(millisecond,@Begin,@End)	
		
		IF @IsNickname = 1
		BEGIN
			EXEC dbo.CS_WriteLog_UserLog_Login_Wrapper
				@UserID = 0, 
				@RoleID = 0, 
				@SubAccID = @SubAccID,
				@ServerID = @ServerID,
				@LoginIP = @inputLoginIP,
				@DomainName = @LoginDomain,	
				@ActionID = 1324,
				@Doing = @LogData,
				@BrowserName = @BrowserName,
				@Platform = @Platform,
				@CountryCode = @CountryCode,
				@Duration = @Duration,
				@Nickname = @db_Username2				
		END				 
		ELSE
		BEGIN
			EXEC dbo.CS_WriteLog_UserLog_Login_Wrapper
				@UserID = 0, 
				@RoleID = 0, 
				@SubAccID = @SubAccID,
				@ServerID = @ServerID,
				@LoginIP = @inputLoginIP,
				@DomainName = @LoginDomain,	
				@ActionID = 1324,
				@Doing = @LogData,
				@BrowserName = @BrowserName,
				@Platform = @Platform,
				@CountryCode = @CountryCode,
				@Duration = @Duration				 
		END	 
			SELECT @ErrMsg = CASE @Language WHEN 'E' THEN  'Wrong username/nickname or password.' 
					 ELSE [dbo].[f_Get_MsgNamebyMsgID](80001,@Language)   
					 END ,@ErrCode=106        
		RETURN  
	END 
		
	--Check grant access to AgentSite from outside throught test accounts	
	SELECT @IsAccess = 1
	
	EXEC Age_LoginCheckGrantAccess
		@CustID = @db_custid,
		@LoginIP = @inputLoginIP,
		@CurrencyId = @db_currency,
		@IsAccess = @IsAccess OUTPUT

	IF @IsAccess = 0
	BEGIN
		SELECT @LogData = 'Account:' + @UserName + ' - ' + 'Login Result:Failed (No_Grant_Access)'  

		SET @End = GETDATE() 
		SET @Duration = DATEDIFF(millisecond,@Begin,@End)

		IF @IsNickname = 1
		BEGIN
			EXEC dbo.CS_WriteLog_UserLog_Login_Wrapper
				@UserID = @db_custid, 
				@RoleID = @RoleID, 
				@SubAccID = @SubAccID,
				@ServerID = @ServerID,
				@LoginIP = @inputLoginIP,
				@DomainName = @LoginDomain,
				@ActionID = 1324,
				@Doing = @LogData,
				@BrowserName = @BrowserName,
				@Platform = @Platform,
				@CountryCode = @CountryCode,
				@Duration = @Duration,
				@Nickname = @db_Username2				
		END	
		ELSE
		BEGIN
			EXEC dbo.CS_WriteLog_UserLog_Login_Wrapper
				@UserID = @db_custid, 
				@RoleID = @RoleID, 
				@SubAccID = @SubAccID,
				@ServerID = @ServerID,
				@LoginIP = @inputLoginIP,
				@DomainName = @LoginDomain,
				@ActionID = 1324,
				@Doing = @LogData,
				@BrowserName = @BrowserName,
				@Platform = @Platform,
				@CountryCode = @CountryCode,
				@Duration = @Duration				
		END	

		SELECT @ErrMsg = CASE @Language WHEN 'E' THEN N'Your account is not authorized to access at this location.'
										ELSE [dbo].[f_Get_MsgNamebyMsgID](80003,@Language) END ,@ErrCode=110     
		RETURN  
		 
	END
	
	IF @isNickname = 0 AND ISNULL(@NickName,'') <> ''
	BEGIN  
		SELECT @LogData =  'Account:' + @UserName + ' Result:Failed (Not_Nickname)'
		
		SET	@End = GETDATE() 
		SET @Duration = DATEDIFF(millisecond,@Begin,@End)
		
		IF @IsNickname = 1 
		BEGIN
			EXEC dbo.CS_WriteLog_UserLog_Login_Wrapper
				@UserID = @db_custid, 
				@RoleID = @RoleID, 
				@SubAccID = @SubAccID,
				@ServerID = @ServerID,
				@LoginIP = @inputLoginIP,
				@DomainName = @LoginDomain,		
				@ActionID = 1324,
				@Doing = @LogData,
				@BrowserName = @BrowserName,
				@Platform = @Platform,
				@CountryCode = @CountryCode,
				@Duration = @Duration,
				@Nickname = @db_Username2				
		END	
		ELSE
		BEGIN
			EXEC dbo.CS_WriteLog_UserLog_Login_Wrapper
				@UserID = @db_custid, 
				@RoleID = @RoleID, 
				@SubAccID = @SubAccID,
				@ServerID = @ServerID,
				@LoginIP = @inputLoginIP,
				@DomainName = @LoginDomain,		
				@ActionID = 1324,
				@Doing = @LogData,
				@BrowserName = @BrowserName,
				@Platform = @Platform,
				@CountryCode = @CountryCode,
				@Duration = @Duration					
		END	
			SELECT @ErrMsg = CASE @Language WHEN 'E' THEN  'Wrong username/nickname or password.' 
				 ELSE [dbo].[f_Get_MsgNamebyMsgID](80001,@Language)  
				 END ,@ErrCode= 106
			RETURN  
	END	
	
	--set serverID
	SELECT @CustID = @db_custid
	SELECT @ServerID = 	CASE WHEN @RoleID=2 THEN 90 WHEN @roleid=3 THEN 91 WHEN @roleid=4 THEN 92 ELSE 93 END -- login from web

	SELECT @role = CASE @RoleID WHEN 0 THEN 'Headline:' WHEN 1 THEN 'Customer:' WHEN 2 THEN 'Agent:' WHEN 3 THEN 'Master:' WHEN 4 THEN 'Super:' WHEN 0 THEN 'Agent' ELSE 'Unknown:' END  
	-- check condition  
	IF @RoleID NOT IN (0)
	BEGIN  
		SELECT @LogData =  @role + @UserName + ' Result:Failed (Not_Headline)'
		
		SET	@End = GETDATE() 
		SET @Duration = DATEDIFF(millisecond,@Begin,@End)
		
		IF @IsNickname = 1 
		BEGIN
			EXEC dbo.CS_WriteLog_UserLog_Login_Wrapper
				@UserID = @db_custid, 
				@RoleID = @RoleID, 
				@SubAccID = @SubAccID,
				@ServerID = @ServerID,
				@LoginIP = @inputLoginIP,
				@DomainName = @LoginDomain,		
				@ActionID = 1324,
				@Doing = @LogData,
				@BrowserName = @BrowserName,
				@Platform = @Platform,
				@CountryCode = @CountryCode,
				@Duration = @Duration,
				@Nickname = @db_Username2				
		END	
		ELSE
		BEGIN
			EXEC dbo.CS_WriteLog_UserLog_Login_Wrapper
				@UserID = @db_custid, 
				@RoleID = @RoleID, 
				@SubAccID = @SubAccID,
				@ServerID = @ServerID,
				@LoginIP = @inputLoginIP,
				@DomainName = @LoginDomain,		
				@ActionID = 1324,
				@Doing = @LogData,
				@BrowserName = @BrowserName,
				@Platform = @Platform,
				@CountryCode = @CountryCode,
				@Duration = @Duration					
		END	
		SELECT @ErrMsg = N'Login Failed.',@ErrCode=107  
		RETURN  
	END  

	SELECT @Status = CustStatus FROM dbo.f_CS_GetCustomerStatus (@CustID)

	IF @Status = 1
	BEGIN
		SELECT @ErrMsg = CASE @Language WHEN 'E' THEN 'Your account has been inactive. Please contact your upline for assistance.'  
				 ELSE [dbo].[f_Get_MsgNamebyMsgID](80009,@Language)
				END ,@ErrCode=700     
		SELECT @LogData ='Agent:' + @UserName + ' Result:Failed (User_Inactive)'
	    
		SET	@End = GETDATE() 
		SET @Duration = DATEDIFF(millisecond,@Begin,@End)

		IF @IsNickname = 1	
		BEGIN	
			EXEC dbo.CS_WriteLog_UserLog_Login_Wrapper
				@UserID = @CustID, 
				@RoleID = @RoleID, 
				@SubAccID = @SubAccID,
				@ServerID = @ServerID,
				@LoginIP = @inputLoginIP,
				@DomainName = @LoginDomain,	
				@ActionID = 1324,
				@Doing = @LogData,
				@BrowserName = @BrowserName,
				@Platform = @Platform,
				@CountryCode = @CountryCode,
				@Duration = @Duration,
				@Nickname = @db_Username2				
		END	
		ELSE
		BEGIN
			EXEC dbo.CS_WriteLog_UserLog_Login_Wrapper
				@UserID = @CustID, 
				@RoleID = @RoleID, 
				@SubAccID = @SubAccID,
				@ServerID = @ServerID,
				@LoginIP = @inputLoginIP,
				@DomainName = @LoginDomain,	
				@ActionID = 1324,
				@Doing = @LogData,
				@BrowserName = @BrowserName,
				@Platform = @Platform,
				@CountryCode = @CountryCode,
				@Duration = @Duration				
		END	
		RETURN
	END

	IF @Status = 2
	BEGIN
		SELECT @ErrMsg = CASE @Language WHEN 'E' THEN 'Your account has been suspended. Please contact your upline to activate your account!'  
				 ELSE [dbo].[f_Get_MsgNamebyMsgID](80010,@Language)
				END ,@ErrCode=701     
		SELECT @LogData ='Agent:' + @UserName + ' Result:Failed (User_Suspended)'
	    
		SET	@End = GETDATE() 
		SET @Duration = DATEDIFF(millisecond,@Begin,@End)

		IF @IsNickname = 1	
		BEGIN	
			EXEC dbo.CS_WriteLog_UserLog_Login_Wrapper
				@UserID = @CustID, 
				@RoleID = @RoleID, 
				@SubAccID = @SubAccID,
				@ServerID = @ServerID,
				@LoginIP = @inputLoginIP,
				@DomainName = @LoginDomain,	
				@ActionID = 1324,
				@Doing = @LogData,
				@BrowserName = @BrowserName,
				@Platform = @Platform,
				@CountryCode = @CountryCode,
				@Duration = @Duration,
				@Nickname = @db_Username2				
		END	
		ELSE
		BEGIN
			EXEC dbo.CS_WriteLog_UserLog_Login_Wrapper
				@UserID = @CustID, 
				@RoleID = @RoleID, 
				@SubAccID = @SubAccID,
				@ServerID = @ServerID,
				@LoginIP = @inputLoginIP,
				@DomainName = @LoginDomain,	
				@ActionID = 1324,
				@Doing = @LogData,
				@BrowserName = @BrowserName,
				@Platform = @Platform,
				@CountryCode = @CountryCode,
				@Duration = @Duration				
		END	
		RETURN
	END

	SELECT @closed = closed, @db_enabled = ISNULL(enabled,0)
	FROM custinfo WITH (NOLOCK) WHERE custid = @db_custid

	IF @db_enabled <> 1
	BEGIN
		 SELECT @ErrMsg = CASE @Language WHEN 'E' THEN 'This account was disabled!'  
				 ELSE [dbo].[f_Get_MsgNamebyMsgID](60020,@Language)
				END ,@ErrCode=600     
		SELECT @LogData ='Agent:' + @UserName + ' Result:Failed (User_Disabled)'
	    
		SET	@End = GETDATE() 
		SET @Duration = DATEDIFF(millisecond,@Begin,@End)

		IF @IsNickname = 1	
		BEGIN	
			EXEC dbo.CS_WriteLog_UserLog_Login_Wrapper
				@UserID = @CustID, 
				@RoleID = @RoleID, 
				@SubAccID = @SubAccID,
				@ServerID = @ServerID,
				@LoginIP = @inputLoginIP,
				@DomainName = @LoginDomain,	
				@ActionID = 1324,
				@Doing = @LogData,
				@BrowserName = @BrowserName,
				@Platform = @Platform,
				@CountryCode = @CountryCode,
				@Duration = @Duration,
				@Nickname = @db_Username2				
		END	
		ELSE
		BEGIN
			EXEC dbo.CS_WriteLog_UserLog_Login_Wrapper
				@UserID = @CustID, 
				@RoleID = @RoleID, 
				@SubAccID = @SubAccID,
				@ServerID = @ServerID,
				@LoginIP = @inputLoginIP,
				@DomainName = @LoginDomain,	
				@ActionID = 1324,
				@Doing = @LogData,
				@BrowserName = @BrowserName,
				@Platform = @Platform,
				@CountryCode = @CountryCode,
				@Duration = @Duration				
		END	
		RETURN
	END
	  
	IF ISNULL(@closed, 1) = 1
	BEGIN  
		SELECT @LogData =  @role + @UserName + ' Result:Failed(A/C_Closed)'
		
		SET	@End = GETDATE() 
		SET @Duration = DATEDIFF(millisecond,@Begin,@End)	

		IF @isNickname = 1
		BEGIN		
			EXEC dbo.CS_WriteLog_UserLog_Login_Wrapper
				@UserID = @db_custid, 
				@RoleID = @RoleID, 
				@SubAccID = @SubAccID,
				@ServerID = @ServerID,
				@LoginIP = @inputLoginIP,
				@DomainName = @LoginDomain,	
				@ActionID = 1324,
				@Doing = @LogData,
				@BrowserName = @BrowserName,
				@Platform = @Platform,
				@CountryCode = @CountryCode,
				@Duration = @Duration,
				@Nickname = @db_Username2				
		END	
		ELSE
		BEGIN
			EXEC dbo.CS_WriteLog_UserLog_Login_Wrapper
				@UserID = @db_custid, 
				@RoleID = @RoleID, 
				@SubAccID = @SubAccID,
				@ServerID = @ServerID,
				@LoginIP = @inputLoginIP,
				@DomainName = @LoginDomain,	
				@ActionID = 1324,
				@Doing = @LogData,
				@BrowserName = @BrowserName,
				@Platform = @Platform,
				@CountryCode = @CountryCode,
				@Duration = @Duration				
		END	

		SELECT @ErrMsg = CASE @Language WHEN 'E' THEN 'Your account has been locked due to multiple failed security check attempts. Please contact your upline to unlock.'  
						ELSE [dbo].[f_Get_MsgNamebyMsgID](80007,@Language)
				   END ,@ErrCode=108  
		RETURN  
	END  
	ELSE IF @db_userpwd <> @UserPWD
	BEGIN 
		SELECT	 @OldUserPwd			= ISNULL(OldUserPwd,'')
				,@LastChangedPwdDate	= LastChangedPwdDate
		FROM	CustLoginInfo WITH (NOLOCK)
		WHERE	CustID = @CustID
		
		IF	@UserPWD = @OldUserPwd	
			SELECT	@LastChangedPwdDate = @LastChangedPwdDate
		ELSE	SELECT	@LastChangedPwdDate = NULL 

		SELECT @LogData =  @role + @UserName + ' Result:Failed (Password problem)'  
		,@failedcount = @failedcount + 1    
	    
		SET	@End = GETDATE() 
		SET @Duration = DATEDIFF(millisecond,@Begin,@End)	
		
		IF @IsNickname =1
		BEGIN
			EXEC dbo.CS_WriteLog_UserLog_Login_Wrapper
				@UserID = @db_custid, 
				@RoleID = @RoleID, 
				@SubAccID = @SubAccID,
				@ServerID = @ServerID,
				@LoginIP = @inputLoginIP,
				@DomainName = @LoginDomain,	
				@ActionID = 1324,
				@Doing = @LogData,   
				@BrowserName = @BrowserName,
				@Platform = @Platform,
				@CountryCode = @CountryCode,
				@Duration = @Duration,
				@Nickname = @db_Username2				
		END	
		ELSE
		BEGIN
			EXEC dbo.CS_WriteLog_UserLog_Login_Wrapper
				@UserID = @db_custid, 
				@RoleID = @RoleID, 
				@SubAccID = @SubAccID,
				@ServerID = @ServerID,
				@LoginIP = @inputLoginIP,
				@DomainName = @LoginDomain,	
				@ActionID = 1324,
				@Doing = @LogData,   
				@BrowserName = @BrowserName,
				@Platform = @Platform,
				@CountryCode = @CountryCode,
				@Duration = @Duration				
		END	
		
		IF @failedcount > 5 	
		BEGIN
			UPDATE custinfo WITH (ROWLOCK, UPDLOCK) SET closed = 1 WHERE custid = @db_custid 
		    
			UPDATE Customer WITH (ROWLOCK,UPDLOCK) SET logincount = 0 WHERE custid = @db_custid 
			
	    	SELECT @LogSPData = '<CS_AdminLoginVerifyBefore IP="'+ @inputLoginIP + '" />'		    

			EXEC dbo.CS_WriteLog_UserLog_RunSP_Wrapper
				@UserID = @db_custid,
				@CustID = @CustID,
				@ActionID = 934,
				@TrackingValue = @LogSPData,
				@Duration = @Duration			
		END
		
		IF (@failedcount <= 5) 
		BEGIN
			UPDATE	customer WITH (ROWLOCK, UPDLOCK) 
			SET		logincount = @failedcount 
			WHERE	custid = @db_custid  
		END
	  	  		 
		SELECT @ErrMsg = CASE @Language WHEN 'E' THEN  'Wrong username/nickname or password.' 
				 ELSE [dbo].[f_Get_MsgNamebyMsgID](80001,@Language)  
				 END ,@ErrCode= case when @failedcount > 5 then 109 else 106 end
	  return  
	END  
	  
	-- Successful  
	UPDATE customer WITH (ROWLOCK, UPDLOCK)  
	SET logincount = 0,
		iplogin = @inputLoginIP, 		
		lastlogged = CURRENT_TIMESTAMP 
	WHERE custid = @db_custid  

	SELECT @LogData =  @role + @UserName + ' - ' + ' [Before Login] Result:Success'
	
	--return logintime
	SELECT @LoginTime = CURRENT_TIMESTAMP	


	SET	@End = GETDATE() 
	SET @Duration = DATEDIFF(millisecond,@Begin,@End)	
	IF @IsNickname =1
	BEGIN
		EXEC dbo.CS_WriteLog_UserLog_Login_Wrapper
			@UserID = @db_custid, 
			@RoleID = @RoleID, 
			@SubAccID = @SubAccID,
			@ServerID = @ServerID,
			@LoginIP = @inputLoginIP,
			@DomainName = @LoginDomain,	
			@ActionID = 1324,
			@Doing = @LogData,
			@BrowserName = @BrowserName,
			@Platform = @Platform,
			@CountryCode = @CountryCode,
			@Duration = @Duration,
			@Nickname = @db_Username2 			
	END	
	ELSE
	BEGIN
		EXEC dbo.CS_WriteLog_UserLog_Login_Wrapper
			@UserID = @db_custid, 
			@RoleID = @RoleID, 
			@SubAccID = @SubAccID,
			@ServerID = @ServerID,
			@LoginIP = @inputLoginIP,
			@DomainName = @LoginDomain,	
			@ActionID = 1324,
			@Doing = @LogData,
			@BrowserName = @BrowserName,
			@Platform = @Platform,
			@CountryCode = @CountryCode,
			@Duration = @Duration 			
	END	
END
GO
