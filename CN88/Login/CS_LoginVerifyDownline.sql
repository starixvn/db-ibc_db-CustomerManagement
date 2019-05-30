/*<info serverAlias="DBCUST-CustDB" executers="bodbDownlineNet, bodbDownlineNetView" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE CS_LoginVerifyDownline
	@UserName VARCHAR(50) = '' OUTPUT,  
	@UserPwd VARCHAR(50),  
	@CustID INT OUTPUT, 
	@SubAccID INT = 0 OUTPUT, --Sub-AccountID,  
	@LoginIP VARCHAR(20)= '',  --- if output=NULL then account is the first login
	@ServerID INT = 0 OUTPUT,  
	@LoginTime DATETIME = NULL OUTPUT, 
	@LoginDomain NVARCHAR(253) = NULL,	
	@SiteGroup VARCHAR(10) = 'CN88',
	@Language VARCHAR(2) = 'E', 
	@BrowserName NVARCHAR(255) = NULL,
	@Platform NVARCHAR(255) = NULL,  
	@CountryCode VARCHAR(64) = NULL,
	@LastChangedPwdDate	DATETIME = NULL OUTPUT, 
	@IsNickname BIT = 0 OUTPUT,
	@NickName VARCHAR(50) = '' OUTPUT,
	@ErrCode INT = 0 OUTPUT,  
	@ErrMsg NVARCHAR(4000) = '' OUTPUT	
AS
/*
	Created: 20190518@Elodie
	Task : check if one account or sub-account existed or not - [Before Login]
	DB: DBCUST/CustDB

	Revisions:		
		- 20190422@Elodie: Offer unique nickname for CN88 [Redmine: 112287]

	Param's Explanation:
		• @IsNickname: is use Nickname or not
		• @SiteGroup: Check the site and corresponding domain
				+ ALL: All add domains 
				+ 789y: Allow customers of 789y ONLY
				+ IBCBET | Others: Allow all customers except 789y
				+ CN88: Allow customers of CN88 ONLY
		• @LastChangedPwdDate: If = NULL: Login current pass, <> NULL : Login old Pass 
		• @ErrCode:
			= 0: Transaction recorded successfully.
			> 0: Specific Error.		
				106: wrong username and password
				107: login failed
				108: account closed
				109: login exceed 5 times
				110: login failed because access from outsite throught test accounts
		• @ErrMsg: Error description.
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @Begin DATETIME, @End DATETIME, @Duration INT, @inputLoginIP VARCHAR(15)
	DECLARE @IsSubAccount BIT, @RoleID TINYINT, @SubUserName VARCHAR(50), @role NVARCHAR(20), @closed BIT, @LogData NVARCHAR(200), @LogSPData VARCHAR(1000), 
		@db_custid INT, @db_userpwd NVARCHAR(50), @OldUserPwd VARCHAR(40), @failedcount INT, @db_loginip NVARCHAR(20), @db_enabled BIT, @db_currency tinyint,
		-- For checking login domain
		@Site VARCHAR(10), @IsMatched BIT, @rowcount INT, @isAllowed BIT, @IsAccess BIT

	SET @Begin = GETDATE()
	SELECT @inputLoginIP = @LoginIP		
	SELECT @isAllowed = 0
		
	------- START: Thien@20130420: Prevent hacking from Viettel IPs ---
	IF @LoginIP IN ('210.211.126.116', '115.84.183.21', '115.78.129.42', '117.7.123.40', '210.211.126.71', '210.211.125.25', '101.99.3.227', '210.211.126.81',
					'117.7.97.115', '115.84.182.37', '115.78.129.42', '210.211.126.117', '115.84.183.11', '115.84.182.241', '210.211.126.199', '210.211.105.232',
					'210.211.120.18', '210.211.120.22', '210.211.120.23', '210.211.125.45', '117.7.109.98', '117.7.113.19', '117.7.119.52', '115.84.182.36',
					'117.7.112.247', '117.7.99.153', '117.2.217.87', '210.211.122.27', '117.3.169.84', '210.211.126.242', '210.211.125.215', '115.77.201.21',
					'171.237.114.124', '42.119.12.181', '210.211.122.6', '210.211.125.212', '117.3.169.84', '27.73.28.214')
		OR (@LoginIP like '210.211%'
		--or @LoginIP like '117.7%' or @LoginIP like '115.84%' or @LoginIP like '115.77%'
		)
		OR (@LoginDomain like '%ibc88.com%')
	BEGIN
		SELECT @LogData = 'Unauthorized login (' + @UserName +' - ' + @UserPwd + ')'
		
		SET	@End = GETDATE() 
		SET @Duration = DATEDIFF(millisecond,@Begin,@End)	
				
		EXEC dbo.Acc_WriteLog_UserLog_Login_Wrapper
			@UserID = 0, 
			@RoleID = 0, 
			@SubAccID = @SubAccID,
			@ServerID = @ServerID,
			@LoginIP = @LoginIP,
			@DomainName = @LoginDomain,
			@ActionID = 1326,
			@Doing = @LogData,
			@BrowserName = @BrowserName,
			@Platform = @Platform, 
			@CountryCode = @CountryCode,
			@Duration = @Duration
		
		SELECT @ErrMsg = 'System error!!', @ErrCode=106 
		RETURN
	END
	------- END: Thien@20130420: Prevent hacking from Viettel IPs ---	

	-----Begin login using Sub account
	DECLARE @SubNicknameLoginOnly BIT, @db_Username2 VARCHAR(50)
	SET @SubNicknameLoginOnly = 0

	SELECT @db_Username2 = NickName FROM dbo.f_CS_GetNickName(@UserName,1)

	IF EXISTS (SELECT 1 FROM custsub WITH (NOLOCK) WHERE username = @UserName OR UserName2 = @db_Username2)
		SET @IsSubAccount = 1
	ELSE
		SET @IsSubAccount = 0

	IF (@IsSubAccount = 1)
	BEGIN
		
		IF EXISTS (SELECT 1 FROM custsub AS c WITH (NOLOCK) WHERE UserName2 = @db_Username2)
		BEGIN
			----use nickname
			SELECT	@SubAccID = subaccid, @SubUserName = username, @CustID = custid, @db_userpwd = userpwd, @failedcount = isnull(logincount,0), @closed = closed,
					@Nickname = @UserName, @IsNickname = 1
			FROM custSub c WITH (NOLOCK)
			WHERE username2 = @db_Username2	

			SELECT @RoleID = roleid, @Site = site, @db_currency = currency FROM customer WITH (NOLOCK) WHERE custid = @CustID
			SET @rowcount = @@ROWCOUNT	
		END
		ELSE
		BEGIN 		
			---check Nicknameloginonly
			SELECT @SubAccID = subaccid, @SubUserName = UserName, @CustID = custid, @IsNickname = 0, @Nickname = f.NickName, @db_Username2 = UserName2, @SubNicknameLoginOnly = ISNULL(NicknameLoginOnly,0),
					 @failedcount = isnull(logincount,0), @db_userpwd = userpwd, @closed = closed
			FROM custsub with (nolock) 	
				CROSS APPLY dbo.f_CS_GetNickName(UserName2,0) f			
			WHERE username = @UserName				

			SELECT @RoleID = roleid, @Site = site, @db_currency = currency FROM customer WITH (NOLOCK) WHERE custid = @CustID
			SET @rowcount = @@ROWCOUNT

			IF @SubNicknameLoginOnly = 1 
			BEGIN  
				SELECT @LogData = 'Account:' + @UserName + ' - ' + 'Login Result:Failed! - Login Option: Nickname Only.'  
				SELECT	@failedcount = @failedcount + 1
				SET @End = GETDATE() 
				SET @Duration = DATEDIFF(millisecond,@Begin,@End)				
				
				EXEC dbo.Acc_WriteLog_UserLog_Login_Wrapper
					@UserID = @CustID, 
					@RoleID = @RoleID, 
					@SubAccID = @SubAccID,
					@ServerID = @ServerID,
					@LoginIP = @inputLoginIP,
					@DomainName = @LoginDomain,
					@ActionID = 1326,
					@Doing = @LogData,
					@BrowserName = @BrowserName,
					@Platform = @Platform,
					@CountryCode = @CountryCode,
					@Duration = @Duration 					  
				
				SELECT @ErrMsg = CASE @Language WHEN 'E' THEN  'Wrong username/nickname or password.' 
												ELSE [dbo].[f_Get_MsgNamebyMsgID](80001,@Language)    
												END ,
					   @ErrCode=106  

				RETURN  
			END  
		END
	-------end 20110608: login using Nickname
		-- check sub-account --
		
		-- Checking login domain and site
		IF(@rowcount <> 0)
		BEGIN
			EXECUTE @IsMatched = [dbo].[f_CheckAgentLoginDomain] @Site, @LoginDomain
			IF(@IsMatched = 0)
			BEGIN
				SELECT @LogData = 'Sub-account: ' + @SubUserName + ', login to wrong domain (' + @Site + '/' + @LoginDomain + ')'
				
				SET	@End = GETDATE() 
				SET @Duration = DATEDIFF(millisecond,@Begin,@End)	
				
				EXEC dbo.Acc_WriteLog_UserLog_Login_Wrapper
					@UserID = 0, 
					@RoleID = 0, 
					@SubAccID = @SubAccID,
					@ServerID = @ServerID,
					@LoginIP = @inputLoginIP,
					@DomainName = @LoginDomain,
					@ActionID = 1326,
					@Doing = @LogData,
					@BrowserName = @BrowserName,
					@Platform = @Platform, 
					@CountryCode = @CountryCode,
					@Duration = @Duration					
	 
				SELECT @ErrMsg = CASE @Language WHEN 'E' THEN  'Wrong username/nickname or password.' 
							ELSE [dbo].[f_Get_MsgNamebyMsgID](80001,@Language)   
							END ,@ErrCode=106  

				RETURN
			END
			
			-- Check 789y or IBCBET Site 
			IF @SiteGroup <> 'ALL' 
			BEGIN
				EXEC dbo.Age_LoginCheckSiteGroup 
					@SiteGroup = @SiteGroup, 
					@Site = @Site,
					@isAllowed = @isAllowed OUTPUT
			
				IF @isAllowed = 0
				BEGIN
					SELECT @LogData = 'Sub-account: ' + @SubUserName + ', login to wrong domain (' + @Site + '/' + @LoginDomain + ')'
					
					SET	@End = GETDATE() 
					SET @Duration = DATEDIFF(millisecond,@Begin,@End)						
					
					EXEC dbo.Acc_WriteLog_UserLog_Login_Wrapper
						@UserID = @CustID, 
						@RoleID = @RoleID, 
						@SubAccID = @SubAccID,
						@ServerID = @ServerID,
						@LoginIP = @inputLoginIP,
						@DomainName = @LoginDomain,
						@ActionID = 1327,
						@Doing = @LogData,
						@BrowserName = @BrowserName,
						@Platform = @Platform, 
						@CountryCode = @CountryCode,
						@Duration = @Duration						
							
					SELECT @ErrMsg = CASE @Language WHEN 'E' THEN  'Wrong username/nickname or password.' 
							 ELSE [dbo].[f_Get_MsgNamebyMsgID](80001,@Language)   
							 END ,@ErrCode=106  

					RETURN
				
				END
			END
		END
		-- End Checking login domain
	    
		IF (@rowcount = 0)
		BEGIN
			SELECT @LogData = 'Sub-account: ' + @SubUserName + ', login failed (User_Not_Found)'    
			
			SET	@End = GETDATE() 
			SET @Duration = DATEDIFF(millisecond,@Begin,@End)
						
			EXEC dbo.Acc_WriteLog_UserLog_Login_Wrapper
				@UserID = 0, 
				@RoleID = 0, 
				@SubAccID = @SubAccID,
				@ServerID = @ServerID,
				@LoginIP = @inputLoginIP,
				@DomainName = @LoginDomain,	
				@ActionID = 1326,
				@Doing = @LogData,
				@BrowserName = @BrowserName,
				@Platform = @Platform,
				@CountryCode = @CountryCode,
				@Duration = @Duration				
			
			SELECT @ErrMsg = CASE @Language WHEN 'E' THEN  'Wrong username/nickname or password.' 
					 ELSE [dbo].[f_Get_MsgNamebyMsgID](80001,@Language)
					 END ,@ErrCode=106    
			RETURN    
		END
	          
		--Check grant access to AgentSite from outside throught test accounts	
		SELECT @IsAccess = 1
		EXEC Age_LoginCheckGrantAccess
			@CustID = @CustID,
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
				EXEC dbo.Acc_WriteLog_UserLog_Login_Wrapper								
					@UserID = @CustID, 
					@RoleID = @RoleID, 
					@SubAccID = @SubAccID,
					@ServerID = @ServerID,
					@LoginIP = @inputLoginIP,
					@DomainName = @LoginDomain,
					@ActionID = 1326,
					@Doing = @LogData,
					@BrowserName = @BrowserName,
					@Platform = @Platform,
					@CountryCode = @CountryCode,
					@Duration = @Duration,
					@Nickname = @db_Username2									
			END	
			ELSE
			BEGIN				
				EXEC dbo.Acc_WriteLog_UserLog_Login_Wrapper
					@UserID = @CustID, 
					@RoleID = @RoleID, 
					@SubAccID = @SubAccID,
					@ServerID = @ServerID,
					@LoginIP = @inputLoginIP,
					@DomainName = @LoginDomain,
					@ActionID = 1326,
					@Doing = @LogData,
					@BrowserName = @BrowserName,
					@Platform = @Platform,
					@CountryCode = @CountryCode,
					@Duration = @Duration									
			END	
			 
			 SELECT @ErrMsg = CASE @Language WHEN 'E' THEN N'Your account is not authorized to access at this location.'
											ELSE [dbo].[f_Get_MsgNamebyMsgID](80003,@Language) END,
					@ErrCode=110     
			RETURN  
			 
		END

		-- Block all access from SMS office to login with real account
		IF @isAllowed = 0 AND @Site NOT IN ('12Bet', 'asiabet88', 'mansion88', 'alog', 'ispo', 'TLC','DELA','Spondemo')
		BEGIN
			SET @isAllowed = 1
			IF @db_currency <> 20 AND LEFT(@inputLoginIP, 10) = '202.78.228'
				SET @isAllowed = 0							
					
			IF (@IsAllowed = 0)
			BEGIN  
				SELECT @LogData = 'Account:' + @UserName + ' - ' + 'Login Result:Failed (IP_Denied)'  
			 
				SET @End = GETDATE() 
				SET @Duration = DATEDIFF(millisecond,@Begin,@End)
				
				IF @IsNickname = 1
				BEGIN					
					EXEC dbo.Acc_WriteLog_UserLog_Login_Wrapper
						@UserID = @CustID, 
						@RoleID = @RoleID, 
						@SubAccID = @SubAccID,
						@ServerID = @ServerID,
						@LoginIP = @inputLoginIP,
						@DomainName = @LoginDomain,
						@ActionID = 1326,
						@Doing = @LogData,
						@BrowserName = @BrowserName,
						@Platform = @Platform,
						@CountryCode = @CountryCode,
						@Duration = @Duration,	
						@Nickname = @db_Username2											
				END	
				ELSE 
				BEGIN					
					EXEC dbo.Acc_WriteLog_UserLog_Login_Wrapper
						@UserID = @CustID, 
						@RoleID = @RoleID, 
						@SubAccID = @SubAccID,
						@ServerID = @ServerID,
						@LoginIP = @inputLoginIP,
						@DomainName = @LoginDomain,
						@ActionID = 1326,
						@Doing = @LogData,
						@BrowserName = @BrowserName,
						@Platform = @Platform,
						@CountryCode = @CountryCode,
						@Duration = @Duration											
				 END 
				 SELECT @ErrMsg = CASE @Language WHEN 'E' THEN N'You login from unallowed location. [IP:' + @inputLoginIP + '].'  
					 ELSE [dbo].[f_Get_MsgNamebyMsgID](80004,@Language) + ' [IP:' + @inputLoginIP + '].'
					END ,@ErrCode=105        
				 RETURN  
			END 
		END
		------------------------
		
		IF ISNULL(@Closed,1) = 1
		BEGIN    
			SELECT @LogData = 'Sub-account: ' + @SubUserName + ', login failed, Result:Failed (A/C_Locked)'   
			
			SET	@End = GETDATE() 
			SET @Duration = DATEDIFF(millisecond,@Begin,@End)		
			
			EXEC dbo.Acc_WriteLog_UserLog_Login_Wrapper
				@UserID = @CustID, 
				@RoleID = @RoleID, 
				@SubAccID = @SubAccID,
				@ServerID = @ServerID,
				@LoginIP = @inputLoginIP,
				@DomainName = @LoginDomain,	
				@ActionID = 1326,
				@Doing = @LogData,
				@BrowserName = @BrowserName,
				@Platform = @Platform,
				@CountryCode = @CountryCode,
				@Duration = @Duration				
			
			SELECT @ErrMsg = CASE @Language WHEN 'E' THEN 'Your sub account has been locked due to multiple failed security check attempts. Please contact the main account user to unlock.'  
								ELSE [dbo].[f_Get_MsgNamebyMsgID](80008,@Language) 
							END ,@ErrCode=108    
			RETURN    
		END
		ELSE IF @db_userpwd <> @UserPWD
		BEGIN
			SELECT	 @OldUserPwd			= ISNULL(OldUserPwd,'')
					,@LastChangedPwdDate	= LastChangedPwdDate
			FROM	CustLoginInfoSub WITH (NOLOCK)
			WHERE	SubAccID = @SubAccID AND CustID = @CustID
			
			IF	@UserPWD = @OldUserPwd	
				SELECT	@LastChangedPwdDate = @LastChangedPwdDate
			ELSE	
				SELECT	@LastChangedPwdDate = NULL 
	    
			SELECT @LogData = 'Sub-account: ' + @SubUserName + ', login failed, password problem',
					@failedcount = @failedcount + 1    
		    
			SET	@End = GETDATE() 		
			SET @Duration = DATEDIFF(millisecond,@Begin,@End)	
			
			EXEC dbo.Acc_WriteLog_UserLog_Login_Wrapper	
				@UserID = @CustID, 
				@RoleID = @RoleID, 
				@SubAccID = @SubAccID,
				@ServerID = @ServerID,
				@LoginIP = @inputLoginIP,
				@DomainName = @LoginDomain,	
				@ActionID = 1326,
				@Doing = @LogData,
				@BrowserName = @BrowserName,
				@Platform = @Platform,
				@CountryCode = @CountryCode ,
				@Duration = @Duration 							

			/* START --Jamie@20130327 Close accounts after 5 logins failed */			
			IF @failedcount > 5
			BEGIN
				UPDATE custSub WITH (ROWLOCK, UPDLOCK) SET closed = 1, logincount = 0 WHERE subaccid = @subaccid 
				
				SELECT @LogSPData = '<CS_LoginVerifyDownline IP="'+ @inputLoginIP + '" '
										+'SubAccount="'  + @SubUserName +'" ' +
									' />'		

				EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
						@UserID = @CustID,
						@CustID = @CustID,
						@ActionID = 939,
						@TrackingValue = @LogSPData,
						@Duration = @Duration				
			END
			/* END -- Close accounts after 5 logins failed*/
			
			IF (@failedcount <=5)
			BEGIN
				UPDATE custSub WITH (ROWLOCK, UPDLOCK) SET logincount = @failedcount WHERE subaccid = @subaccid 
			END		

			SELECT  @ErrMsg = CASE @Language WHEN 'E' THEN  'Wrong username/nickname or password.' 
											 ELSE [dbo].[f_Get_MsgNamebyMsgID](80001,@Language)
											 END 
				   ,@ErrCode= CASE WHEN @failedcount > 5 THEN 109 ELSE 106 END
			RETURN    
		END    

		UPDATE custSub WITH (ROWLOCK, UPDLOCK) SET logincount = 0 WHERE subaccid = @subaccid 
		
		--Get username, password from customer table to login in the context of agent    
		SELECT @db_custid = custid, @db_userpwd = userpwd, @RoleID = roleid, @Site = site, @UserName = username, @UserPwd = userpwd,
			@failedcount = ISNULL(logincount,0), @db_loginip= ISNULL(iplogin, '')
		FROM customer WITH (NOLOCK) 
		WHERE custid = @CustID    
			AND mrecommend <> 927780

	END
	----- end of login using Sub account

	ELSE

	BEGIN 
		----- begin 20110608: login using Nickname
		SET  @ServerID = 0

		DECLARE @NicknameLoginOnly BIT 
		SET  @NicknameLoginOnly = 0
	 
		IF EXISTS (SELECT 1 FROM customer AS c WITH (NOLOCK) WHERE c.username2 = @db_Username2)
		BEGIN
			----use nickname
			SELECT	@db_custid = custid, @db_userpwd = userpwd, @RoleID = roleid, @db_currency = currency, @failedcount = isnull(logincount,0),  
					@site = site , @db_loginip= isnull(iplogin, ''), @Nickname = @UserName, @UserName = Username, @IsNickname = 1
			FROM customer c WITH (NOLOCK)
			WHERE username2 = @db_Username2
					and mrecommend <> 927780
		
		END
		ELSE
		BEGIN 
			---check Nicknameloginonly
			SELECT @db_custid = custid, @RoleID = roleid,  @IsNickname = 0 ,@Nickname = NickName, @db_Username2 = username2
			FROM customer with (nolock) 
				CROSS APPLY dbo.f_CS_GetNickName(UserName2,0)
			WHERE username = @UserName and mrecommend <> 927780
		
			IF @RoleID = 2  
				SELECT @NicknameLoginOnly = NicknameLoginOnly FROM CustAgent WITH (NOLOCK) WHERE CustID = @db_custid   
			ELSE IF @RoleID = 3  
				SELECT @NicknameLoginOnly = NicknameLoginOnly FROM CustMaster WITH (NOLOCK) WHERE CustID = @db_custid  
			ELSE IF @RoleID = 4  
				SELECT @NicknameLoginOnly = NicknameLoginOnly FROM CustSuper WITH (NOLOCK) WHERE CustID = @db_custid 

			IF @NicknameLoginOnly = 1 
																												BEGIN  
			SELECT @LogData = 'Account:' + @UserName + ' - ' + 'Login Result:Failed! - Login Option: Nickname Only.'  
			SELECT	@failedcount = @failedcount + 1
			SET @End = GETDATE() 
			SET @Duration = DATEDIFF(millisecond,@Begin,@End)
			
			EXEC dbo.Acc_WriteLog_UserLog_Login_Wrapper
				@UserID = @db_custid, 
				@RoleID = @RoleID, 
				@SubAccID = @SubAccID,
				@ServerID = @ServerID,
				@LoginIP = @inputLoginIP,
				@DomainName = @LoginDomain,
				@ActionID = 1326,
				@Doing = @LogData,
				@BrowserName = @BrowserName,
				@Platform = @Platform,
				@CountryCode = @CountryCode,
				@Duration = @Duration 				 
							
			SELECT @ErrMsg = CASE @Language WHEN 'E' THEN  'Wrong username/nickname or password.' 
											ELSE [dbo].[f_Get_MsgNamebyMsgID](80001,@Language)    
											END ,
				   @ErrCode=106  

			RETURN  
		END  
		----use username
			SELECT @db_custid = custid, @db_userpwd = userpwd, @RoleID = roleid, @db_currency = currency, @failedcount = isnull(logincount,0),  
					@site = site , @db_loginip= isnull(iplogin, ''),  @IsNickname = 0, @Nickname = NickName
			FROM customer WITH (NOLOCK)
				CROSS APPLY dbo.f_CS_GetNickName(UserName2,0)
			WHERE username = @UserName
				and mrecommend <> 927780

		END
		-------end 20110608: login using Nickname
	END 

	SET @rowcount = @@ROWCOUNT

	-- Checking login domain and site
	IF(@rowcount <> 0)
	BEGIN
		EXEC @IsMatched = [dbo].[f_CheckAgentLoginDomain] @Site, @LoginDomain
		IF(@IsMatched = 0)
		BEGIN

			SELECT @LogData = 'Agent: ' + @UserName + ', login to wrong domain (' + @Site + '/' + @LoginDomain + ')'
			
			SET	@End = GETDATE() 
			SET @Duration = DATEDIFF(millisecond,@Begin,@End)			
		
			IF @IsNickname = 1
			BEGIN				
				EXEC dbo.Acc_WriteLog_UserLog_Login_Wrapper
					@UserID = 0, 
					@RoleID = 0, 
					@SubAccID = @SubAccID,
					@ServerID = @ServerID,
					@LoginIP = @inputLoginIP,
					@DomainName = @LoginDomain,	
					@ActionID = 1326,
					@Doing = @LogData,
					@BrowserName = @BrowserName,
					@Platform = @Platform,
					@CountryCode = @CountryCode,
					@Duration = @Duration,
					@Nickname = @db_Username2									
			END	
			ELSE
			BEGIN 				
				EXEC dbo.Acc_WriteLog_UserLog_Login_Wrapper
					@UserID = 0, 
					@RoleID = 0, 
					@SubAccID = @SubAccID,
					@ServerID = @ServerID,
					@LoginIP = @inputLoginIP,
					@DomainName = @LoginDomain,	
					@ActionID = 1326,
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

		-- Check 789y or IBCBET Site 
		IF @SiteGroup <>'ALL'   ---IN ('789y','IBCBET','Others')
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
					EXEC dbo.Acc_WriteLog_UserLog_Login_Wrapper
						@UserID = @db_custid, 
						@RoleID = @RoleID, 
						@SubAccID = @SubAccID,
						@ServerID = @ServerID,
						@LoginIP = @inputLoginIP,
						@DomainName = @LoginDomain,	
						@ActionID = 1328,
						@Doing = @LogData,
						@BrowserName = @BrowserName,
						@Platform = @Platform,
						@CountryCode = @CountryCode,
						@Duration = @Duration,
						@Nickname = @db_Username2											
				END	
				ELSE 
				BEGIN					
					EXEC dbo.Acc_WriteLog_UserLog_Login_Wrapper
						@UserID = @db_custid, 
						@RoleID = @RoleID, 
						@SubAccID = @SubAccID,
						@ServerID = @ServerID,
						@LoginIP = @inputLoginIP,
						@DomainName = @LoginDomain,	
						@ActionID = 1328,
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
			EXEC dbo.Acc_WriteLog_UserLog_Login_Wrapper
				@UserID = 0, 
				@RoleID = 0, 
				@SubAccID = @SubAccID,
				@ServerID = @ServerID,
				@LoginIP = @inputLoginIP,
				@DomainName = @LoginDomain,	
				@ActionID = 1326,
				@Doing = @LogData,
				@BrowserName = @BrowserName,
				@Platform = @Platform,
				@CountryCode = @CountryCode,
				@Duration = @Duration,
				@Nickname = @db_Username2							
		END				 
		ELSE
		BEGIN			
			EXEC dbo.Acc_WriteLog_UserLog_Login_Wrapper
				@UserID = 0, 
				@RoleID = 0, 
				@SubAccID = @SubAccID,
				@ServerID = @ServerID,
				@LoginIP = @inputLoginIP,
				@DomainName = @LoginDomain,	
				@ActionID = 1326,
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
				EXEC dbo.Acc_WriteLog_UserLog_Login_Wrapper
					@UserID = @db_custid, 
					@RoleID = @RoleID, 
					@SubAccID = @SubAccID,
					@ServerID = @ServerID,
					@LoginIP = @inputLoginIP,
					@DomainName = @LoginDomain,
					@ActionID = 1326,
					@Doing = @LogData,
					@BrowserName = @BrowserName,
					@Platform = @Platform,
					@CountryCode = @CountryCode,
					@Duration = @Duration,
					@Nickname = @db_Username2									
			END	
			ELSE
			BEGIN				
				EXEC dbo.Acc_WriteLog_UserLog_Login_Wrapper
					@UserID = @db_custid, 
					@RoleID = @RoleID, 
					@SubAccID = @SubAccID,
					@ServerID = @ServerID,
					@LoginIP = @inputLoginIP,
					@DomainName = @LoginDomain,
					@ActionID = 1326,
					@Doing = @LogData,
					@BrowserName = @BrowserName,
					@Platform = @Platform,
					@CountryCode = @CountryCode,
					@Duration = @Duration									
			END	
			 SELECT @ErrMsg = CASE @Language WHEN 'E' THEN N'Your account is not authorized to access at this location.'
			 ELSE [dbo].[f_Get_MsgNamebyMsgID](80003,@Language)
			END ,@ErrCode=110     
			RETURN  
			 
		END

	--set serverID
	SELECT @CustID = @db_custid
	SELECT @ServerID = 	CASE WHEN @RoleID=2 THEN 90 WHEN @roleid=3 THEN 91 ELSE 92 END -- login from web

	SELECT @role = CASE @RoleID WHEN 1 THEN 'Customer:' WHEN 2 THEN 'Agent:' WHEN 3 THEN 'Master:' WHEN 4 THEN 'Super:' ELSE 'Unknown:' END  
	-- check condition  
	IF @RoleID NOT IN (2,3,4)
	BEGIN  
		SELECT @LogData =  @role + @UserName + ' Result:Failed (Not_Agent)'
		
		SET	@End = GETDATE() 
		SET @Duration = DATEDIFF(millisecond,@Begin,@End)
		
		IF @IsNickname = 1 
		BEGIN				
			EXEC dbo.Acc_WriteLog_UserLog_Login_Wrapper
				@UserID = 0, 
				@RoleID = @RoleID, 
				@SubAccID = @SubAccID,
				@ServerID = @ServerID,
				@LoginIP = @inputLoginIP,
				@DomainName = @LoginDomain,		
				@ActionID = 1326,
				@Doing = @LogData,
				@BrowserName = @BrowserName,
				@Platform = @Platform,
				@CountryCode = @CountryCode,
				@Duration = @Duration,
				@Nickname = @db_Username2							
		END	
		ELSE
		BEGIN				
			EXEC dbo.Acc_WriteLog_UserLog_Login_Wrapper
				@UserID = 0, 
				@RoleID = @RoleID, 
				@SubAccID = @SubAccID,
				@ServerID = @ServerID,
				@LoginIP = @inputLoginIP,
				@DomainName = @LoginDomain,		
				@ActionID = 1326,
				@Doing = @LogData,
				@BrowserName = @BrowserName,
				@Platform = @Platform,
				@CountryCode = @CountryCode,
				@Duration = @Duration								
		END	
		SELECT @ErrMsg = N'Login Failed.',@ErrCode=107  
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
			EXEC dbo.Acc_WriteLog_UserLog_Login_Wrapper
				@UserID = @CustID, 
				@RoleID = @RoleID, 
				@SubAccID = @SubAccID,
				@ServerID = @ServerID,
				@LoginIP = @inputLoginIP,
				@DomainName = @LoginDomain,	
				@ActionID = 1326,
				@Doing = @LogData,
				@BrowserName = @BrowserName,
				@Platform = @Platform,
				@CountryCode = @CountryCode,
				@Duration = @Duration,
				@Nickname = @db_Username2							
		END	
		ELSE
		BEGIN			
			EXEC dbo.Acc_WriteLog_UserLog_Login_Wrapper
				@UserID = @CustID, 
				@RoleID = @RoleID, 
				@SubAccID = @SubAccID,
				@ServerID = @ServerID,
				@LoginIP = @inputLoginIP,
				@DomainName = @LoginDomain,	
				@ActionID = 1326,
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
		SELECT @LogData =  @role + @UserName + ' Result:Failed(A/C_Locked)'
		
		SET	@End = GETDATE() 
		SET @Duration = DATEDIFF(millisecond,@Begin,@End)	

		IF @isNickname = 1
		BEGIN							
			EXEC dbo.Acc_WriteLog_UserLog_Login_Wrapper
				@UserID = @db_custid, 
				@RoleID = @RoleID, 
				@SubAccID = @SubAccID,
				@ServerID = @ServerID,
				@LoginIP = @inputLoginIP,
				@DomainName = @LoginDomain,	
				@ActionID = 1326,
				@Doing = @LogData,
				@BrowserName = @BrowserName,
				@Platform = @Platform,
				@CountryCode = @CountryCode,
				@Duration = @Duration,
				@Nickname = @db_Username2							
		END	
		ELSE
		BEGIN				
			EXEC dbo.Acc_WriteLog_UserLog_Login_Wrapper
				@UserID = @db_custid, 
				@RoleID = @RoleID, 
				@SubAccID = @SubAccID,
				@ServerID = @ServerID,
				@LoginIP = @inputLoginIP,
				@DomainName = @LoginDomain,	
				@ActionID = 1326,
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
			EXEC dbo.Acc_WriteLog_UserLog_Login_Wrapper
				@UserID = @db_custid, 
				@RoleID = @RoleID, 
				@SubAccID = @SubAccID,
				@ServerID = @ServerID,
				@LoginIP = @inputLoginIP,
				@DomainName = @LoginDomain,	
				@ActionID = 1326,
				@Doing = @LogData,   
				@BrowserName = @BrowserName,
				@Platform = @Platform,
				@CountryCode = @CountryCode,
				@Duration = @Duration,
				@Nickname = @db_Username2							
		END	
		ELSE
		BEGIN
			EXEC dbo.Acc_WriteLog_UserLog_Login_Wrapper
				@UserID = @db_custid, 
				@RoleID = @RoleID, 
				@SubAccID = @SubAccID,
				@ServerID = @ServerID,
				@LoginIP = @inputLoginIP,
				@DomainName = @LoginDomain,	
				@ActionID = 1326,
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
			
	    	SELECT @LogSPData = '<CS_LoginVerifyDownline IP="'+ @inputLoginIP + '" />'		    
			
			EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
				@UserID = @db_custid,
				@CustID = @CustID,
				@ActionID = 940,
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
	SET logincount = CASE WHEN @IsSubAccount = 0 THEN 0 ELSE logincount END,
		iplogin = CASE WHEN @db_loginip<>'' THEN @inputLoginIP ELSE '' END, 		
		lastlogged = CURRENT_TIMESTAMP 
	WHERE custid = @db_custid  

	SELECT @LogData =  @role + @UserName + ' - ' + ' [Before Login] Result:Success'
	----------------------------------
	--**Output LoginIP to check the first login**
	SELECT @LoginIP=isnull(@db_loginip, ''),
		@LoginTime = CURRENT_TIMESTAMP	

	----------------------------------
	---------------------------  
	-- ***Check Sub-Account***  
	IF @SubAccID > 0  
		SET @LogData = 'Sub-account:' +  convert(varchar(30), @SubUserName) + ' - ' + ' [Before Login] Result:Success' 
	---------------------------  

	SET	@End = GETDATE() 
	SET @Duration = DATEDIFF(millisecond,@Begin,@End)	
	IF @IsNickname =1 
	BEGIN
		EXEC dbo.Acc_WriteLog_UserLog_Login_Wrapper
			@UserID = @db_custid, 
			@RoleID = @RoleID, 
			@SubAccID = @SubAccID,
			@ServerID = @ServerID,
			@LoginIP = @inputLoginIP,
			@DomainName = @LoginDomain,	
			@ActionID = 1326,
			@Doing = @LogData,
			@BrowserName = @BrowserName,
			@Platform = @Platform,
			@CountryCode = @CountryCode,
			@Duration = @Duration,
			@Nickname = @db_Username2 			
	END	
	ELSE
	BEGIN
		EXEC dbo.Acc_WriteLog_UserLog_Login_Wrapper
			@UserID = @db_custid, 
			@RoleID = @RoleID, 
			@SubAccID = @SubAccID,
			@ServerID = @ServerID,
			@LoginIP = @inputLoginIP,
			@DomainName = @LoginDomain,	
			@ActionID = 1326,
			@Doing = @LogData,
			@BrowserName = @BrowserName,
			@Platform = @Platform,
			@CountryCode = @CountryCode,
			@Duration = @Duration 			
	END	
END