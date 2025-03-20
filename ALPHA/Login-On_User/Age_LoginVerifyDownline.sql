/*<info serverAlias="DBCUST-CustDB" executers="wsv_alp, wsv_alpv" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE Age_LoginVerifyDownline
	@UserName VARCHAR(50) = '' OUTPUT,  
	@UserPwd VARCHAR(50),  
	@CustID INT OUTPUT, 
	@SubAccID INT = 0 OUTPUT, --Sub-AccountID,  
	@LoginIP VARCHAR(20)= '',  --- if output=NULL then account is the first login
	@ServerID INT = 0 OUTPUT,  
	@LoginTime DATETIME = NULL OUTPUT, 
	@LoginDomain NVARCHAR(253) = NULL ,
	@SiteGroup VARCHAR(10) = 'ALL',
	@Language VARCHAR(2) = 'E', 
	@BrowserName NVARCHAR(255) = NULL,
	@Platform NVARCHAR(255) = NULL,  
	@CountryCode VARCHAR(64) = NULL,
	@LastChangedPwdDate	DATETIME = NULL OUTPUT, 
	@IsNickname BIT = 0 OUTPUT,
	@NickName VARCHAR(50) = '' OUTPUT,
	@SuperID INT = 0 OUTPUT,
	@Site 	VARCHAR(10) = '' OUTPUT,
	@SiteID INT = 0 OUTPUT,
	@RoleID TINYINT = 0 OUTPUT,
	@SubUserName VARCHAR(50) ='' OUTPUT,
	@IsKickOut BIT = 0 OUTPUT, 
	@IsDarkMode BIT = NULL,
	@ErrCode INT = 0 OUTPUT,  
	@ErrMsg NVARCHAR(4000) = '' OUTPUT	,
	@failedcount	INT		= 0 OUTPUT
AS
/*
	Created: 20090829@Don
	Task : check if one account or sub-account existed or not - [Before Login]
	DB: DBCUST/CustDB

	Revisions:
		- 20090917@Phuc: write log into DBLOG.
		- 20091210@Minh: add error code about login exceed 5 times.
		- 20100101@Kiwi: Modify Log.
		- 20100505@Lee: Add param LoginDomain
		- 20100820@Thien: change the error domain message to the vague one. Not let them know we have centralized site.
		- 20101006@Kaden; Add 4 parameter (DomainName, BrowserName, Platform, CountryCode). Save more detail user info 
		- 20101022@Johnson: Record execution time 
		- 20110103@Viet: Block all access from SMS office
		- 20110314@thien: put hard-code to stop abusing on logins with wrong password.
		- 20110324@Amy: output NVARCHAR for ErrMsg
		- 20110426@Amy: Change @db_Custid to @CustID
		- 20110608@Sophia: Login using Nickname, add parameter @IsNickname,  @Nickname
		- 20110621@Sophia: Do not update closed = 1 when login wrong more than 5 times, because it will be checked on web
		- 20110715@Sophia: add prefix 'Agency$' to username2
		- 20110722@Sophia: Do not Use Prefix 'Agency$' for username2
		- 20120223@Dan: check @failedcount < max size of tinyint before updating
		- 20120307@Elodie: Check grant access to AgentSite from outside throught test accounts
		- 20120611@Jamie: Harcode for real lines LC-RM% login to agency 
		- 20120622@Jamie: Check domain and corresponding Site (@SiteGroup)
		- 20121128@Elodie: Get an error message from f_Get_MsgNameByMsgID function by language
		- 20130123@Elodie: Write more log on DBTXN server in case of DBLOG server failure
		- 20130316@Thien: Prevent hacking from INDONESIA
		- 20130322@Ethan: Change write log format for @NicknameLoginOnly
		- 20130327@Jamie: Close account if login fail over 5 times.
		- 20130328@Jamie: Get LastChangedPwdDate in case login via OldUserPwd
		- 20130405@Thien: REMOVE "Prevent hacking from INDONESIA"
		- 20130420@Thien: Prevent hacking from Viettel IPs
		- 20130916@Elodie: Correct writting log on DBTXN server in case of actionID = 908
		- 20161102@Helen: Apply Service Broker for Writing Log - [Redmine: 65806] 
		- 20170724@Elodie: Don't reset login count of main account when sub account login successfull - [Redmine: #80409] 
		- 20190422@Elodie: Offer unique nickname for CN88 [Redmine: 112287]
		- 20200624@Johnson: add superid, siteid for BF login to prevent robot [redmine:#135142] 
		- 20210408@Tina: Lock account & indirect close account [redmine: #148600]
		- 20210824@Elodie: Implement Protection Code [Redmine: #160151]
		- 20211019@Winfred: Add log Alpha Support Dark Mode [Redmine: #151816]
		- 20230207@Tacy: Alpha/NAP - Split 789y site [RedmineID:#181596]
		- 20241206@Johnson: Apply In-house replication for Credit Setting [RedmineID: #212684]
		- 20241230@Aries: Scale Out DBCUST - Apply Inhouse replication for the remaning tables [Redmine: #215627]
		- 20250312@Helios: Alpha - Reset Password Notification [Redmine: #219803] 
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
				111: account locked
		• @ErrMsg: Error description.
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @Begin DATETIME, @End DATETIME, @Duration INT, @inputLoginIP VARCHAR(15)
	DECLARE @IsSubAccount BIT, @role NVARCHAR(20), @closed BIT, @LogData NVARCHAR(200), @LogSPData VARCHAR(1000), @ActionID INT,
		@db_custid INT, @db_userpwd NVARCHAR(50), @OldUserPwd VARCHAR(40), @db_loginip NVARCHAR(20), @db_enabled BIT, @db_currency tinyint,
		-- For checking login domain
		@IsMatched BIT, @rowcount INT, @isAllowed BIT, @IsAccess BIT,
		@Locked TINYINT, @db_ProtectionCode VARCHAR(30), @db_IsProtectedMode BIT

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
			@ActionID = 1304,
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
	DECLARE @SubNicknameLoginOnly BIT, @db_Username2 VARCHAR(50) = @UserName
	SET @SubNicknameLoginOnly = 0

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
					@Nickname = UserName2, @IsNickname = 1
			FROM custSub c WITH (NOLOCK)
			WHERE username2 = @db_Username2	

			SELECT @RoleID = roleid, @Site = c.site, @db_currency = currency, @SiteID=s.siteid
			FROM customer c WITH (NOLOCK)
			INNER JOIN Site s WITH (NOLOCK) ON s.site=c.site
			WHERE custid = @CustID

			SET @rowcount = @@ROWCOUNT	
		END
		ELSE
		BEGIN 			
			---check Nicknameloginonly
			SELECT @SubAccID = subaccid, @CustID = custid, @SubUserName = username, @IsNickname = 0, @Nickname = UserName2, @SubNicknameLoginOnly = ISNULL(NicknameLoginOnly,0),
					 @failedcount = isnull(logincount,0), @db_userpwd = userpwd, @closed = closed
			FROM custsub with (nolock) 				
			WHERE username = @UserName				

			SELECT @RoleID = roleid, @Site = c.site, @db_currency = currency, @SiteID=s.siteid
			FROM customer c WITH (NOLOCK)
			INNER JOIN Site s WITH (NOLOCK) ON s.site=c.site 
			WHERE custid = @CustID

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
					@ActionID = 1304,
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
					@ActionID = 1304,
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
						@ActionID = 1314,
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
				@ActionID = 1304,
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
					@ActionID = 1304,
					@Doing = @LogData,
					@BrowserName = @BrowserName,
					@Platform = @Platform,
					@CountryCode = @CountryCode,
					@Duration = @Duration,
					@Nickname = @Nickname									
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
					@ActionID = 1304,
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
						@ActionID = 1304,
						@Doing = @LogData,
						@BrowserName = @BrowserName,
						@Platform = @Platform,
						@CountryCode = @CountryCode,
						@Duration = @Duration,	
						@Nickname = @Nickname											
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
						@ActionID = 1304,
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
		
		SELECT @db_ProtectionCode = ISNULL(ProtectionCode, '') FROM CustLoginInfoSub cl WITH (NOLOCK) WHERE SubAccID = @SubAccID
		SELECT @db_IsProtectedMode = ISNULL(IsProtectedMode,0) FROM CustLoginInfo cl WITH (NOLOCK) WHERE custid = @CustID

		IF ISNULL(@Closed,1) = 1
		BEGIN    
			SELECT @LogData = 'Sub-account: ' + @SubUserName + ', login failed, Result:Failed (A/C_Closed)'   
			
			SET	@End = GETDATE() 
			SET @Duration = DATEDIFF(millisecond,@Begin,@End)		
			
			EXEC dbo.Acc_WriteLog_UserLog_Login_Wrapper
				@UserID = @CustID, 
				@RoleID = @RoleID, 
				@SubAccID = @SubAccID,
				@ServerID = @ServerID,
				@LoginIP = @inputLoginIP,
				@DomainName = @LoginDomain,	
				@ActionID = 1304,
				@Doing = @LogData,
				@BrowserName = @BrowserName,
				@Platform = @Platform,
				@CountryCode = @CountryCode,
				@Duration = @Duration				
			
			SELECT @ErrMsg = CASE @Language WHEN 'E' THEN 'Account closed. Please contact your administrator!'  
								ELSE [dbo].[f_Get_MsgNamebyMsgID](80002,@Language) 
							END ,@ErrCode=108    
			RETURN    
		END
		ELSE IF (@db_userpwd <> @UserPWD AND @db_ProtectionCode <> @UserPWD)
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
				@ActionID = 1304,
				@Doing = @LogData,
				@BrowserName = @BrowserName,
				@Platform = @Platform,
				@CountryCode = @CountryCode ,
				@Duration = @Duration 							

			/* START --Jamie@20130327 Close accounts after 5 logins failed */			
			IF @failedcount > 5
			BEGIN
				UPDATE custSub WITH (ROWLOCK, UPDLOCK) 
				SET closed = 1, 
					logincount = 0,
					RepUpdateTime = dbo.f_GetDateTime2()
				WHERE subaccid = @subaccid 
					    
				SELECT @LogSPData = '<Age_LoginVerifyDownline IP="'+ @inputLoginIP + '" '
										+'SubAccount="'  + @SubUserName +'" ' +
									' />'		
				EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
					@UserID = @CustID,
					@CustID = @CustID,
					@ActionID = 950,
					@TrackingValue = @LogSPData,
					@Duration = @Duration				
			END
			/* END -- Close accounts after 5 logins failed*/
			
			IF (@failedcount <=5)
			BEGIN
				UPDATE custSub WITH (ROWLOCK, UPDLOCK) 
				SET logincount = @failedcount,
					RepUpdateTime = dbo.f_GetDateTime2()
				WHERE subaccid = @subaccid 
			END		

			SELECT  @ErrMsg = CASE @Language WHEN 'E' THEN  'Wrong username/nickname or password.' 
											 ELSE [dbo].[f_Get_MsgNamebyMsgID](80001,@Language)
											 END 
				   ,@ErrCode= CASE WHEN @failedcount > 5 THEN 109 ELSE 106 END
			RETURN    
		END    

		IF @db_ProtectionCode = @UserPwd
		BEGIN
			IF @db_IsProtectedMode = 0
			BEGIN
				SET	@End = GETDATE() 
				SET @Duration = DATEDIFF(millisecond,@Begin,@End)	

				UPDATE cl
				SET IsProtectedMode = 1, @IsKickOut = 1
				   ,RepUpdateTime = dbo.f_GetDateTime2()
				FROM CustLoginInfo cl WITH (ROWLOCK)
				WHERE custid = @CustID 

				SELECT @LogSPData = '<Age_LoginVerifyDownline IP="'+ @inputLoginIP + '" '
												+'SubAccount="'  + @SubUserName +'" ' +
												+'Protected="1" />'  

				EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
					@UserID = @CustID,
					@CustID = @CustID,
					@ActionID = 1184,
					@TrackingValue = @LogSPData,
					@Duration = @Duration	
			END
			SET @ActionID = 1338	
		 END
		 ELSE
		 BEGIN
			SELECT @ActionID = 1304 
		 END

		UPDATE custSub WITH (ROWLOCK, UPDLOCK) 
		SET logincount = 0,
			RepUpdateTime = dbo.f_GetDateTime2()
		WHERE subaccid = @subaccid 
		
		--Get username, password from customer table to login in the context of agent    
		SELECT @db_custid = custid, @db_userpwd = userpwd, @RoleID = roleid, @Site = c.site, @UserName = username, @UserPwd = userpwd,
			@failedcount = ISNULL(logincount,0), @db_loginip= ISNULL(iplogin, ''), @SiteID=s.siteid
		FROM customer c WITH (NOLOCK) 
		INNER JOIN Site s WITH (NOLOCK) ON s.site=c.site
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

		IF EXISTS (SELECT 1 FROM customer AS c WITH (NOLOCK) WHERE c.username2 = @UserName)
		BEGIN
			----use nickname
			SELECT	@db_custid = custid, @db_userpwd = userpwd, @RoleID = roleid, @db_currency = currency, @failedcount = isnull(logincount,0),  
					@site = c.site , @db_loginip= isnull(iplogin, ''), @Nickname = UserName2, @UserName = Username, @IsNickname = 1, @SiteID=s.siteid
			FROM customer c WITH (NOLOCK) 
			INNER JOIN Site s WITH (NOLOCK) ON s.site=c.site
			WHERE username2 = @UserName
					and mrecommend <> 927780

			SET @rowcount = @@ROWCOUNT
		
		END
		ELSE
		BEGIN 
			---check Nicknameloginonly
			SELECT @db_custid = custid, @RoleID = roleid,  @IsNickname = 0 ,@Nickname = UserName2
			FROM customer with (nolock) 
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
				@ActionID = 1304,
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
					@site = c.site , @db_loginip= isnull(iplogin, ''),  @IsNickname = 0, @Nickname = UserName2, @SiteID=s.siteid
			FROM customer c WITH (NOLOCK) 
			INNER JOIN Site s WITH (NOLOCK) ON s.site=c.site
			WHERE username = @UserName
					and mrecommend <> 927780

			SET @rowcount = @@ROWCOUNT
		END
		-------end 20110608: login using Nickname

		SELECT @db_ProtectionCode = ISNULL(ProtectionCode, ''), @db_IsProtectedMode = ISNULL(IsProtectedMode,0) FROM CustLoginInfo cl WITH (NOLOCK) WHERE custid = @db_custid

	END 

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
					@ActionID = 1304,
					@Doing = @LogData,
					@BrowserName = @BrowserName,
					@Platform = @Platform,
					@CountryCode = @CountryCode,
					@Duration = @Duration,
					@Nickname = @Nickname									
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
					@ActionID = 1304,
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
						@ActionID = 1315,
						@Doing = @LogData,
						@BrowserName = @BrowserName,
						@Platform = @Platform,
						@CountryCode = @CountryCode,
						@Duration = @Duration,
						@Nickname = @Nickname											
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
						@ActionID = 1315,
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
				@ActionID = 1304,
				@Doing = @LogData,
				@BrowserName = @BrowserName,
				@Platform = @Platform,
				@CountryCode = @CountryCode,
				@Duration = @Duration,
				@Nickname = @Nickname							
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
				@ActionID = 1304,
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
					@ActionID = 1304,
					@Doing = @LogData,
					@BrowserName = @BrowserName,
					@Platform = @Platform,
					@CountryCode = @CountryCode,
					@Duration = @Duration,
					@Nickname = @Nickname									
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
					@ActionID = 1304,
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
				@ActionID = 1304,
				@Doing = @LogData,
				@BrowserName = @BrowserName,
				@Platform = @Platform,
				@CountryCode = @CountryCode,
				@Duration = @Duration,
				@Nickname = @Nickname							
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
				@ActionID = 1304,
				@Doing = @LogData,
				@BrowserName = @BrowserName,
				@Platform = @Platform,
				@CountryCode = @CountryCode,
				@Duration = @Duration								
		END	
		SELECT @ErrMsg = N'Login Failed.',@ErrCode=107  
	RETURN  
	END  

	SELECT @db_enabled = ISNULL(enabled,0), @superid = srecommend
	FROM custinfo WITH (NOLOCK) WHERE custid = @db_custid

	SELECT @Locked = CASE WHEN @IsSubAccount = 1 THEN 0 ELSE CPS.Locked END, 
		@closed = CASE WHEN CloseInfo > 0 THEN 1 ELSE 0 END
	FROM CustProductStatus CPS WITH (NOLOCK)
	WHERE CPS.CustID = @db_custid
	
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
				@ActionID = 1304,
				@Doing = @LogData,
				@BrowserName = @BrowserName,
				@Platform = @Platform,
				@CountryCode = @CountryCode,
				@Duration = @Duration,
				@Nickname = @Nickname							
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
				@ActionID = 1304,
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
			EXEC dbo.Acc_WriteLog_UserLog_Login_Wrapper
				@UserID = @db_custid, 
				@RoleID = @RoleID, 
				@SubAccID = @SubAccID,
				@ServerID = @ServerID,
				@LoginIP = @inputLoginIP,
				@DomainName = @LoginDomain,	
				@ActionID = 1304,
				@Doing = @LogData,
				@BrowserName = @BrowserName,
				@Platform = @Platform,
				@CountryCode = @CountryCode,
				@Duration = @Duration,
				@Nickname = @Nickname							
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
				@ActionID = 1304,
				@Doing = @LogData,
				@BrowserName = @BrowserName,
				@Platform = @Platform,
				@CountryCode = @CountryCode,
				@Duration = @Duration				
		END	

		SELECT @ErrMsg = CASE @Language WHEN 'E' THEN 'Account closed. Please contact your administrator!'  
						ELSE [dbo].[f_Get_MsgNamebyMsgID](80002,@Language)
				   END ,@ErrCode=108  
		RETURN  
	END
	ELSE IF ISNULL(@Locked, 0) > 0
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
				@ActionID = 1304,
				@Doing = @LogData,
				@BrowserName = @BrowserName,
				@Platform = @Platform,
				@CountryCode = @CountryCode,
				@Duration = @Duration,
				@Nickname = @Nickname							
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
				@ActionID = 1304,
				@Doing = @LogData,
				@BrowserName = @BrowserName,
				@Platform = @Platform,
				@CountryCode = @CountryCode,
				@Duration = @Duration				
		END	

		SELECT @ErrMsg = CASE @Language WHEN 'E' THEN 'Your account has been locked due to multiple failed security check. Please contact your upline to unlock.'  
						ELSE [dbo].[f_Get_MsgNamebyMsgID](80007,@Language)
				   END ,@ErrCode=111  
		RETURN  
	END  
	ELSE IF (@db_userpwd <> @UserPWD AND @db_ProtectionCode <> @UserPWD)
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
				@ActionID = 1304,
				@Doing = @LogData,   
				@BrowserName = @BrowserName,
				@Platform = @Platform,
				@CountryCode = @CountryCode,
				@Duration = @Duration,
				@Nickname = @Nickname							
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
				@ActionID = 1304,
				@Doing = @LogData,   
				@BrowserName = @BrowserName,
				@Platform = @Platform,
				@CountryCode = @CountryCode,
				@Duration = @Duration				
		END	
		
		IF @failedcount > 5 	
		BEGIN
			UPDATE CustProductStatus WITH (ROWLOCK, UPDLOCK) 
			SET Locked = 2,
				RepUpdateTime = dbo.f_GetDateTime2()
			WHERE custid = @db_custid 
		    
			UPDATE Customer WITH (ROWLOCK,UPDLOCK) 
			SET logincount = 0,
				RepUpdateTime = dbo.f_GetDateTime2()
			WHERE custid = @db_custid 
			
	    		SELECT @LogSPData = '<Age_LoginVerifyDownline IP="'+ @inputLoginIP + '" />'		    
			
			EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
				@UserID = @db_custid,
				@CustID = @CustID,
				@ActionID = 908,
				@TrackingValue = @LogSPData,
				@Duration = @Duration		
				
			-- Helios Add code
			SELECT @ErrMsg = CASE @Language WHEN 'E' THEN 'Your account has been locked due to multiple failed security check. Please contact your upline to unlock.'  
						ELSE [dbo].[f_Get_MsgNamebyMsgID](80007,@Language)
				   END ,@ErrCode=111  
		END
		
		IF (@failedcount <= 5) 
		BEGIN
			UPDATE	customer WITH (ROWLOCK, UPDLOCK) 
			SET		logincount = @failedcount,
					RepUpdateTime = dbo.f_GetDateTime2()
			WHERE	custid = @db_custid  
		
	  
		SELECT @ErrMsg = CASE @Language WHEN 'E' THEN  'Wrong username/nickname or password.' 
				 ELSE [dbo].[f_Get_MsgNamebyMsgID](80001,@Language)  
				 END ,@ErrCode= case when @failedcount > 5 then 109 else 106 end
		RETURN 

		END
	END
	
	IF @IsSubAccount = 0 
	BEGIN
		IF @db_ProtectionCode = @UserPwd
		BEGIN
			IF @db_IsProtectedMode = 0
			BEGIN
				SET	@End = GETDATE() 
				SET @Duration = DATEDIFF(millisecond,@Begin,@End)	

				UPDATE cl
				SET IsProtectedMode = 1, @IsKickOut = 1
				   ,RepUpdateTime = dbo.f_GetDateTime2()
				FROM CustLoginInfo cl WITH (ROWLOCK)
				WHERE custid = @CustID 

				SELECT @LogSPData = '<Age_LoginVerifyDownline IP="'+ @inputLoginIP + '" '
												+'SubAccount="'  + @SubUserName +'" ' +
												+'Protected="1" />'  

				EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
					@UserID = @db_custid,
					@CustID = @CustID,
					@ActionID = 1184,
					@TrackingValue = @LogSPData,
					@Duration = @Duration	
			END
			SET @ActionID = 1338	
		END
		ELSE
		BEGIN
		SELECT @ActionID = 1304 
		END
	END
	-- Successful  
	UPDATE customer WITH (ROWLOCK, UPDLOCK)  
	SET logincount = CASE WHEN @IsSubAccount = 0 THEN 0 ELSE logincount END,
		iplogin = @inputLoginIP, 		
		lastlogged = CURRENT_TIMESTAMP,
		RepUpdateTime = dbo.f_GetDateTime2()
	WHERE custid = @db_custid  
	
	IF ISNULL(CAST(@IsDarkMode AS INT),-1)  = 1 
	BEGIN
		EXEC dbo.Age_SwitchDarkMode
				@CustID = @CustID,
				@SubAccID = @SubAccID,
				@IsDarkMode = @IsDarkMode,
				@IP = @inputLoginIP,
				@Location = 'LoginPage'
	END
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
			@ActionID = @ActionID,
			@Doing = @LogData,
			@BrowserName = @BrowserName,
			@Platform = @Platform,
			@CountryCode = @CountryCode,
			@Duration = @Duration,
			@Nickname = @Nickname 			
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
			@ActionID = @ActionID,
			@Doing = @LogData,
			@BrowserName = @BrowserName,
			@Platform = @Platform,
			@CountryCode = @CountryCode,
			@Duration = @Duration 			
	END	
END