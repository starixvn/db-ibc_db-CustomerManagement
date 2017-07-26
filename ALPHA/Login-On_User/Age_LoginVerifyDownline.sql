/*<info serverAlias="DBCUST-CUSTDB" executers="bodbDownlineNet, bodbDownlineNetView" viewers="vnteam" isFunction="0"></info>*/
USE CustDB
GO

ALTER PROCEDURE [dbo].[Age_LoginVerifyDownline]
	@UserName VARCHAR(50) = '' OUTPUT ,  
	@UserPwd VARCHAR(50),  
	@CustID INT OUTPUT, 
	@SubAccID INT = 0 OUTPUT, --Sub-AccountID,  
	@LoginIP VARCHAR(20)='',  --- if output=NULL then account is the first login
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
Created: 20090829@Don
Task : check if one account or sub-account existed or not - [Before Login]
DB: DBTXN/BODB02

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
• @ErrMsg: Error description.

*/
BEGIN
	SET NOCOUNT ON

	DECLARE @Begin		DATETIME
	DECLARE @End		DATETIME
	DECLARE @Duration	INT

	SET @Begin = GETDATE()

	DECLARE	@inputLoginIP VARCHAR(15)

	SELECT	@inputLoginIP = @LoginIP		

	DECLARE @isExisted BIT,
		@RoleID TINYINT,
		@LogData NVARCHAR(200),  
		@db_custid INT, 
		@db_userpwd			NVARCHAR(50),
		@OldUserPwd		VARCHAR(40), 
		@failedcount INT, 
		@role NVARCHAR(20), 
		@closed BIT , 
		@db_loginip NVARCHAR(20), 
		@db_enabled BIT,
		@LogSPData VARCHAR(1000),
		@SubUserName VARCHAR(50),
		-- For checking login domain
		@Site varchar(10),
		@IsMatched bit,
		@rowcount int,
		@db_currency tinyint,
		@isAllowed bit,

		@IsAccess BIT
		
	SELECT @isAllowed = 0

	-- SB Parameters -----
	DECLARE @SB_xml XML, @SB_currentDate DATETIME, @SB_Error BIT = 0
	SET @SB_currentDate = GETDATE()
	-- SB Parameters ----------
	
	-------------------------------------------------------------------
	------- START: Thien@20130420: Prevent hacking from Viettel IPs ---
	-------------------------------------------------------------------
	IF @LoginIP IN ('210.211.126.116', '115.84.183.21', '115.78.129.42', '117.7.123.40', '210.211.126.71', '210.211.125.25', '101.99.3.227', '210.211.126.81',
					'117.7.97.115', '115.84.182.37', '115.78.129.42', '210.211.126.117', '115.84.183.11', '115.84.182.241', '210.211.126.199', '210.211.105.232',
					'210.211.120.18', '210.211.120.22', '210.211.120.23', '210.211.125.45', '117.7.109.98', '117.7.113.19', '117.7.119.52', '115.84.182.36',
					'117.7.112.247', '117.7.99.153', '117.2.217.87', '210.211.122.27', '117.3.169.84', '210.211.126.242', '210.211.125.215', '115.77.201.21',
					'171.237.114.124', '42.119.12.181', '210.211.122.6', '210.211.125.212', '117.3.169.84', '27.73.28.214')
		OR (@LoginIP like '210.211%'
		--or @LoginIP like '117.7%'
		--or @LoginIP like '115.84%'
		--or @LoginIP like '115.77%'
		)
		OR (@LoginDomain like '%ibc88.com%')
	BEGIN
		SELECT @LogData = 'Unauthorized login (' + @UserName +' - ' + @UserPwd + ')'
		
		SET	@End = GETDATE() 
		SET @Duration = DATEDIFF(millisecond,@Begin,@End)	
		
		-- Starting: Service Broke code --
		SET @SB_xml = (SELECT	
							0	AS '@UserID'
							, 0 AS '@RoleID'
							, @SubAccID	AS '@SubAccID'
							, @ServerID	AS '@ServerID'
							, @LoginIP AS '@IP'
							, @LoginDomain AS '@DomainName'
							, @SB_currentDate AS '@LogDate'
							, 1304	AS '@ActionID'
							, @LogData AS	'@Doing'
							, @BrowserName AS '@BrowserName'
							, @Platform	AS '@Platform'
							, @CountryCode AS '@CountryCode'
							, @Duration	AS '@Duration'
							, NULL AS '@Username2'
				
						FOR XML PATH ('row')
						)
			
		--SELECT @SB_xml
		EXEC bodb_CustomerLog.sb.CustomerLog_SendMessage @xml = @SB_xml, @MessageType='MessageType_CustomerLog_UserLog_Login', @SB_Error = @SB_Error out
		--SELECT @SB_Error AS SB_Error
		IF @SB_Error = 1 
		BEGIN
			EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login
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
		END
		
		SELECT @ErrMsg =   'System error!!' , @ErrCode=106 

		RETURN
	END
	------------------------------------------------------------------
	------- END: Thien@20130420: Prevent hacking from Viettel IPs ---
	------------------------------------------------------------------
	IF @UserName like 'dbaThien/%' OR @UserName like 'pgmViet/%' 
	BEGIN -- Hardcode: specially accept for Thien and Viet to login into any agents from anywhere
		DECLARE @AdminUsername varchar(30)
		SELECT @AdminUsername = left(@username, charindex('/',@UserName)-1),
				@username = replace(@UserName, @AdminUsername + '/', '')
		
		IF exists (SELECT 1
					FROM customer WITH (nolock)
					WHERE username = @AdminUsername and userpwd = @UserPwd and RoleID > 8)
		BEGIN
			SELECT @UserPwd = userpwd
			FROM customer WITH (nolock)
			WHERE username = @username
				
			SELECT @isAllowed = 1
		END
		ELSE
			SELECT @UserPwd = ''   
	END  

	-----Begin login using Sub account
	IF EXISTS (SELECT 1 FROM custsub WITH (NOLOCK) WHERE username = @UserName)
		SET @isExisted = 1
	ELSE
		SET @isExisted = 0


	IF (@isExisted = 1)
	BEGIN
		-- check sub-account --
		SET @SubUserName = @UserName
	   
		SELECT	@SubAccID = subaccid, @CustID = custid, 
				@db_userpwd = userpwd, @failedcount = ISNULL(logincount,0), @closed = closed
		FROM custSub (NOLOCK) WHERE username = @SubUserName

		SELECT @RoleID = roleid, @Site = site, @db_currency = currency FROM customer WITH (NOLOCK) WHERE custid = @CustID

		SET @rowcount = 	@@ROWCOUNT

		
		-- Checking login domain and site
		IF(@rowcount <> 0)
		BEGIN
			EXECUTE @IsMatched = [dbo].[f_CheckAgentLoginDomain] @Site, @LoginDomain
			IF(@IsMatched = 0)
			BEGIN
				SELECT @LogData = 'Sub-account: ' + @SubUserName + ', login to wrong domain (' + @Site + '/' + @LoginDomain + ')'
				
				SET	@End = GETDATE() 
				SET @Duration = DATEDIFF(millisecond,@Begin,@End)	
				-- Starting: Service Broke code --
				SET @SB_xml = (SELECT	
									0	AS '@UserID'
									, 0 AS '@RoleID'
									, @SubAccID	AS '@SubAccID'
									, @ServerID	AS '@ServerID'
									, @inputLoginIP AS '@IP'
									, @LoginDomain AS '@DomainName'
									, @SB_currentDate AS '@LogDate'
									, 1304	AS '@ActionID'
									, @LogData AS	'@Doing'
									, @BrowserName AS '@BrowserName'
									, @Platform	AS '@Platform'
									, @CountryCode AS '@CountryCode'
									, @Duration	AS '@Duration'
									, NULL AS '@Username2'
						
								FOR XML PATH ('row')
								)
					
				--SELECT @SB_xml
				EXEC bodb_CustomerLog.sb.CustomerLog_SendMessage @xml = @SB_xml, @MessageType='MessageType_CustomerLog_UserLog_Login', @SB_Error = @SB_Error out
				--SELECT @SB_Error AS SB_Error
				IF @SB_Error = 1 
				BEGIN
		
					BEGIN TRY		
						EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login
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
					END TRY
					BEGIN CATCH
						SELECT @LogData = @LogData + ' ErrMsg=' + left(error_message(), 400)
						EXEC bodb_customerlog.dbo.WriteLog_UserLog_Login
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
					END CATCH
				END	
				/* Thien@20100820: change the error message to the vague one. Not let them know we have centralized site.
				SELECT @ErrMsg = CASE @Language WHEN 'E' THEN 'You are not allowed to login on this site! Please contact the administrator for the assistance.'  
									WHEN 'CS' THEN N'You are not allowed to login on this site! Please contact the administrator for the assistance..'  
									WHEN 'CT' THEN N'You are not allowed to login on this site! Please contact the administrator for the assistance..'  
									WHEN 'J' THEN N'You are not allowed to login on this site! Please contact the administrator for the assistance..'  
									WHEN 'TH' THEN N'You are not allowed to login on this site! Please contact the administrator for the assistance..'  
									WHEN 'KO' THEN N'You are not allowed to login on this site! Please contact the administrator for the assistance..'  
									ELSE N'You are not allowed to login on this site! Please contact the administrator for the assistance.'  
								END ,@ErrCode=110
				*/
	 
					SELECT @ErrMsg = CASE @Language WHEN 'E' THEN  'Wrong username/nickname or password.' 
							 ELSE [dbo].[f_Get_MsgNamebyMsgID](80001,@Language)   
							 END ,@ErrCode=106  

				RETURN
			END
			
			-- Check 789y or IBCBET Site 
			IF @SiteGroup <> 'ALL'  --IN ('789y','IBCBET','Others')
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
					-- Starting: Service Broke code --
					SET @SB_xml = (SELECT	
										@CustID	AS '@UserID'
										, @RoleID AS '@RoleID'
										, @SubAccID	AS '@SubAccID'
										, @ServerID	AS '@ServerID'
										, @inputLoginIP AS '@IP'
										, @LoginDomain AS '@DomainName'
										, @SB_currentDate AS '@LogDate'
										, 1314	AS '@ActionID'
										, @LogData AS	'@Doing'
										, @BrowserName AS '@BrowserName'
										, @Platform	AS '@Platform'
										, @CountryCode AS '@CountryCode'
										, @Duration	AS '@Duration'
										, NULL AS '@Username2'
							
									FOR XML PATH ('row')
									)
						
					--SELECT @SB_xml
					EXEC bodb_CustomerLog.sb.CustomerLog_SendMessage @xml = @SB_xml, @MessageType='MessageType_CustomerLog_UserLog_Login', @SB_Error = @SB_Error out
					--SELECT @SB_Error AS SB_Error
					IF @SB_Error = 1 
					BEGIN
				
						BEGIN TRY		
							EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login
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
						END TRY
						BEGIN CATCH
							SELECT @LogData = @LogData + ' ErrMsg=' + left(error_message(), 400)
							EXEC bodb_customerlog.dbo.WriteLog_UserLog_Login
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
						END CATCH
					END				
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
			
			-- Starting: Service Broke code --
			SET @SB_xml = (SELECT	
								0	AS '@UserID'
								, 0 AS '@RoleID'
								, @SubAccID	AS '@SubAccID'
								, @ServerID	AS '@ServerID'
								, @inputLoginIP AS '@IP'
								, @LoginDomain AS '@DomainName'
								, @SB_currentDate AS '@LogDate'
								, 1304	AS '@ActionID'
								, @LogData AS	'@Doing'
								, @BrowserName AS '@BrowserName'
								, @Platform	AS '@Platform'
								, @CountryCode AS '@CountryCode'
								, @Duration	AS '@Duration'
								, NULL AS '@Username2'
					
							FOR XML PATH ('row')
							)
				
			--SELECT @SB_xml
			EXEC bodb_CustomerLog.sb.CustomerLog_SendMessage @xml = @SB_xml, @MessageType='MessageType_CustomerLog_UserLog_Login', @SB_Error = @SB_Error out
			--SELECT @SB_Error AS SB_Error
			IF @SB_Error = 1 
			BEGIN
							
				BEGIN TRY		
					EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login
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
				END TRY
				BEGIN CATCH
					SELECT @LogData = @LogData + ' ErrMsg=' + left(error_message(), 400)
					EXEC bodb_customerlog.dbo.WriteLog_UserLog_Login
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
				END CATCH
			END	
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
			
			IF @IsNickname =1
			BEGIN
				-- Starting: Service Broke code --
				SET @SB_xml = (SELECT	
									@CustID	AS '@UserID'
									, @RoleID AS '@RoleID'
									, @SubAccID	AS '@SubAccID'
									, @ServerID	AS '@ServerID'
									, @inputLoginIP AS '@IP'
									, @LoginDomain AS '@DomainName'
									, @SB_currentDate AS '@LogDate'
									, 1304	AS '@ActionID'
									, @LogData AS	'@Doing'
									, @BrowserName AS '@BrowserName'
									, @Platform	AS '@Platform'
									, @CountryCode AS '@CountryCode'
									, @Duration	AS '@Duration'
									, @Nickname AS '@Username2'
						
								FOR XML PATH ('row')
								)
					
				--SELECT @SB_xml
				EXEC bodb_CustomerLog.sb.CustomerLog_SendMessage @xml = @SB_xml, @MessageType='MessageType_CustomerLog_UserLog_Login', @SB_Error = @SB_Error out
				--SELECT @SB_Error AS SB_Error
				IF @SB_Error = 1 
				BEGIN
					BEGIN TRY
						EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login
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
					END TRY
					BEGIN CATCH
						SELECT @LogData = @LogData + ' ErrMsg=' + left(error_message(), 400)
						EXEC bodb_customerlog.dbo.WriteLog_UserLog_Login
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
					END CATCH
				END	
			END	
			ELSE
			BEGIN
				-- Starting: Service Broke code --
				SET @SB_xml = (SELECT	
									@CustID	AS '@UserID'
									, @RoleID AS '@RoleID'
									, @SubAccID	AS '@SubAccID'
									, @ServerID	AS '@ServerID'
									, @inputLoginIP AS '@IP'
									, @LoginDomain AS '@DomainName'
									, @SB_currentDate AS '@LogDate'
									, 1304	AS '@ActionID'
									, @LogData AS	'@Doing'
									, @BrowserName AS '@BrowserName'
									, @Platform	AS '@Platform'
									, @CountryCode AS '@CountryCode'
									, @Duration	AS '@Duration'
									, NULL AS '@Username2'
						
								FOR XML PATH ('row')
								)
					
				--SELECT @SB_xml
				EXEC bodb_CustomerLog.sb.CustomerLog_SendMessage @xml = @SB_xml, @MessageType='MessageType_CustomerLog_UserLog_Login', @SB_Error = @SB_Error out
				--SELECT @SB_Error AS SB_Error
				IF @SB_Error = 1 
				BEGIN
				
					BEGIN TRY
						EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login
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
					END TRY
					BEGIN CATCH
						SELECT @LogData = @LogData + ' ErrMsg=' + left(error_message(), 400)
						EXEC bodb_customerlog.dbo.WriteLog_UserLog_Login
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
					END CATCH
				END	
			END	
			 SELECT @ErrMsg = CASE @Language WHEN 'E' THEN N'Your account is not authorized to access at this location.'
			 ELSE [dbo].[f_Get_MsgNamebyMsgID](80003,@Language)  
			END ,@ErrCode=110     
			RETURN  
			 
		END


		-- Block all access from SMS office to login with real account
		IF @isAllowed = 0 AND @Site NOT IN ('12Bet', 'asiabet88', 'mansion88', 'alog', 'ispo', 'TLC','DELA','Spondemo')
		BEGIN
			set @isAllowed = 1
			IF @db_currency <> 20 AND LEFT(@inputLoginIP, 10) = '202.78.228'
				set @isAllowed = 0
				
			IF @UserName LIKE 'LC-RM%'  --20120611@Jamie: Harcode for LiveCasino Login TESTING 
				SELECT @isAllowed = 1 	
					
			IF (@IsAllowed = 0)
			BEGIN  
				SELECT @LogData = 'Account:' + @UserName + ' - ' + 'Login Result:Failed (IP_Denied)'  
			 
				SET @End = GETDATE() 
				SET @Duration = DATEDIFF(millisecond,@Begin,@End)
				
				IF @IsNickname = 1
				BEGIN
					-- Starting: Service Broke code --
					SET @SB_xml = (SELECT	
										@CustID	AS '@UserID'
										, @RoleID AS '@RoleID'
										, @SubAccID	AS '@SubAccID'
										, @ServerID	AS '@ServerID'
										, @inputLoginIP AS '@IP'
										, @LoginDomain AS '@DomainName'
										, @SB_currentDate AS '@LogDate'
										, 1304	AS '@ActionID'
										, @LogData AS	'@Doing'
										, @BrowserName AS '@BrowserName'
										, @Platform	AS '@Platform'
										, @CountryCode AS '@CountryCode'
										, @Duration	AS '@Duration'
										, @Nickname AS '@Username2'
							
									FOR XML PATH ('row')
									)
						
					--SELECT @SB_xml
					EXEC bodb_CustomerLog.sb.CustomerLog_SendMessage @xml = @SB_xml, @MessageType='MessageType_CustomerLog_UserLog_Login', @SB_Error = @SB_Error out
					--SELECT @SB_Error AS SB_Error
					IF @SB_Error = 1 
					BEGIN
						BEGIN TRY
							EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login
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
						END TRY
						BEGIN CATCH
							SELECT @LogData = @LogData + ' ErrMsg=' + left(error_message(), 400)
							EXEC bodb_customerlog.dbo.WriteLog_UserLog_Login
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
						END CATCH
					END	
				END	
				ELSE 
				BEGIN
					-- Starting: Service Broke code --
					SET @SB_xml = (SELECT	
										@CustID	AS '@UserID'
										, @RoleID AS '@RoleID'
										, @SubAccID	AS '@SubAccID'
										, @ServerID	AS '@ServerID'
										, @inputLoginIP AS '@IP'
										, @LoginDomain AS '@DomainName'
										, @SB_currentDate AS '@LogDate'
										, 1304	AS '@ActionID'
										, @LogData AS	'@Doing'
										, @BrowserName AS '@BrowserName'
										, @Platform	AS '@Platform'
										, @CountryCode AS '@CountryCode'
										, @Duration	AS '@Duration'
										, NULL AS '@Username2'
							
									FOR XML PATH ('row')
									)
						
					--SELECT @SB_xml
					EXEC bodb_CustomerLog.sb.CustomerLog_SendMessage @xml = @SB_xml, @MessageType='MessageType_CustomerLog_UserLog_Login', @SB_Error = @SB_Error out
					--SELECT @SB_Error AS SB_Error
					IF @SB_Error = 1 
					BEGIN
				 
						BEGIN TRY
							EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login
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
						END TRY
						BEGIN CATCH
							SELECT @LogData = @LogData + ' ErrMsg=' + left(error_message(), 400)
							EXEC bodb_customerlog.dbo.WriteLog_UserLog_Login
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
						END CATCH
					END	
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
			SELECT @LogData = 'Sub-account: ' + @SubUserName + ', login failed, Result:Failed (A/C_Closed)'   
			
			SET	@End = GETDATE() 
			SET @Duration = DATEDIFF(millisecond,@Begin,@End)		
			-- Starting: Service Broke code --
			SET @SB_xml = (SELECT	
								@CustID	AS '@UserID'
								, @RoleID AS '@RoleID'
								, @SubAccID	AS '@SubAccID'
								, @ServerID	AS '@ServerID'
								, @inputLoginIP AS '@IP'
								, @LoginDomain AS '@DomainName'
								, @SB_currentDate AS '@LogDate'
								, 1304	AS '@ActionID'
								, @LogData AS	'@Doing'
								, @BrowserName AS '@BrowserName'
								, @Platform	AS '@Platform'
								, @CountryCode AS '@CountryCode'
								, @Duration	AS '@Duration'
								, NULL AS '@Username2'
					
							FOR XML PATH ('row')
							)
				
			--SELECT @SB_xml
			EXEC bodb_CustomerLog.sb.CustomerLog_SendMessage @xml = @SB_xml, @MessageType='MessageType_CustomerLog_UserLog_Login', @SB_Error = @SB_Error out
			--SELECT @SB_Error AS SB_Error
			IF @SB_Error = 1 
			BEGIN
				 
				BEGIN TRY	
					EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login
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
				END TRY
				BEGIN CATCH
					SELECT @LogData = @LogData + ' ErrMsg=' + left(error_message(), 400)
					EXEC bodb_customerlog.dbo.WriteLog_UserLog_Login
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
				END CATCH
			END	
			SELECT @ErrMsg = CASE @Language WHEN 'E' THEN 'Account closed. Please contact your administrator!'  
								ELSE [dbo].[f_Get_MsgNamebyMsgID](80002,@Language) 
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
			ELSE	SELECT	@LastChangedPwdDate = NULL 
	    
			SELECT @LogData = 'Sub-account: ' + @SubUserName + ', login failed, password problem',
					@failedcount = @failedcount + 1    
		    
			SET	@End = GETDATE() 		
			SET @Duration = DATEDIFF(millisecond,@Begin,@End)	
			-- Starting: Service Broke code --
			SET @SB_xml = (SELECT	
								@CustID	AS '@UserID'
								, @RoleID AS '@RoleID'
								, @SubAccID	AS '@SubAccID'
								, @ServerID	AS '@ServerID'
								, @inputLoginIP AS '@IP'
								, @LoginDomain AS '@DomainName'
								, @SB_currentDate AS '@LogDate'
								, 1304	AS '@ActionID'
								, @LogData AS	'@Doing'
								, @BrowserName AS '@BrowserName'
								, @Platform	AS '@Platform'
								, @CountryCode AS '@CountryCode'
								, @Duration	AS '@Duration'
								, NULL AS '@Username2'
					
							FOR XML PATH ('row')
							)
				
			--SELECT @SB_xml
			EXEC bodb_CustomerLog.sb.CustomerLog_SendMessage @xml = @SB_xml, @MessageType='MessageType_CustomerLog_UserLog_Login', @SB_Error = @SB_Error out
			--SELECT @SB_Error AS SB_Error
			IF @SB_Error = 1 
			BEGIN
			
				BEGIN TRY		
					EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login
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
				END TRY
				BEGIN CATCH
					SELECT @LogData = @LogData + ' ErrMsg=' + left(error_message(), 400)
					EXEC bodb_customerlog.dbo.WriteLog_UserLog_Login
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
				END CATCH
			END	
	--	    IF @failedcount > 5
	--	    BEGIN
	--		    UPDATE custSub WITH (ROWLOCK, UPDLOCK) SET closed = 1, logincount = 0 WHERE subaccid = @subaccid 
	--		    --log data to UserLog_RunSP 
	--		    
	--		    SELECT @LogSPData = '<Age_LoginVerifyDownline IP="'+ @inputLoginIP + '" />'			
	--						EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_RunSP
	--				@UserID = @CustID,
	--				@CustID = @CustID,
	--				@ActionID = 908,
	--				@TrackingValue = @LogSPData
	--	    END
	--	    ELSE

			/* START --Jamie@20130327 Close accounts after 5 logins failed */			
			IF @failedcount > 5
			BEGIN
				UPDATE custSub WITH (ROWLOCK, UPDLOCK) SET closed = 1, logincount = 0 WHERE subaccid = @subaccid 
				--log data to UserLog_RunSP 	    
				SELECT @LogSPData = '<Age_LoginVerifyDownline IP="'+ @inputLoginIP + '" '
										+'SubAccount="'  + @SubUserName +'" ' +
									' />'		
				BEGIN TRY	
					EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_RunSP
						@UserID = @CustID,
						@CustID = @CustID,
						@ActionID = 908,
						@TrackingValue = @LogSPData,
						@Duration = @Duration
				END TRY 
				BEGIN CATCH
					SELECT @LogData = '<Age_LoginVerifyDownline IP="'+ @inputLoginIP + '" '
										+'SubAccount="'  + @SubUserName +'" ' +
										+'ErrMsg='+error_message() +'" ' + 
										' />'	
					EXEC bodb_customerlog.dbo.WriteLog_UserLog_RunSP
						@UserID = @CustID,
						@CustID = @CustID,
						@ActionID = 908,
						@TrackingValue = @LogSPData,
						@Duration = @Duration			
				END CATCH 
			END

			/* END -- Close accounts after 5 logins failed*/
			
		 --   IF (@failedcount <= 255) -- max of tinyint
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
		Select @UserName = username, @UserPwd = userpwd from customer WITH (NOLOCK) where custid = @CustID    


	-- check account --
	SELECT @db_custid = custid, @db_userpwd = userpwd, @RoleID = roleid, @Site = site,
		@failedcount = ISNULL(logincount,0), @db_loginip= ISNULL(iplogin, ''), @IsNickname = 0, @Nickname = NULL
	FROM customer WITH (NOLOCK) 
	WHERE username = @UserName
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
					@site = site , @db_loginip= isnull(iplogin, ''), @Nickname = UserName2, @UserName = Username, @IsNickname = 1
			FROM customer c WITH (NOLOCK)
			WHERE username2 = @UserName
					and mrecommend <> 927780
		
	END
	ELSE
	BEGIN 
		---check Nicknameloginonly
		SELECT @db_custid = custid,  @RoleID = roleid,  @IsNickname = 0 ,@Nickname = UserName2
		FROM customer with (nolock) 
		WHERE username = @UserName
				and mrecommend <> 927780
		
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
			-- Starting: Service Broke code --
			SET @SB_xml = (SELECT	
								@db_custid	AS '@UserID'
								, @RoleID AS '@RoleID'
								, @SubAccID	AS '@SubAccID'
								, @ServerID	AS '@ServerID'
								, @inputLoginIP AS '@IP'
								, @LoginDomain AS '@DomainName'
								, @SB_currentDate AS '@LogDate'
								, 1304	AS '@ActionID'
								, @LogData AS	'@Doing'
								, @BrowserName AS '@BrowserName'
								, @Platform	AS '@Platform'
								, @CountryCode AS '@CountryCode'
								, @Duration	AS '@Duration'
								, NULL AS '@Username2'
					
							FOR XML PATH ('row')
							)
				
			--SELECT @SB_xml
			EXEC bodb_CustomerLog.sb.CustomerLog_SendMessage @xml = @SB_xml, @MessageType='MessageType_CustomerLog_UserLog_Login', @SB_Error = @SB_Error out
			--SELECT @SB_Error AS SB_Error
			IF @SB_Error = 1 
			BEGIN
			
				BEGIN TRY
					EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login
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
				  END TRY
				  BEGIN CATCH
						SELECT @LogData = @LogData + ' ErrMsg=' + left(error_message(), 400)
	  					EXEC bodb_customerlog.dbo.WriteLog_UserLog_Login
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
				  END CATCH
			END
			SELECT @ErrMsg = CASE @Language WHEN 'E' THEN  'Wrong username/nickname or password.' 
											ELSE [dbo].[f_Get_MsgNamebyMsgID](80001,@Language)    
											END ,
				   @ErrCode=106  

			RETURN  
		END  
	----use username
		SELECT @db_custid = custid, @db_userpwd = userpwd, @RoleID = roleid, @db_currency = currency, @failedcount = isnull(logincount,0),  
				@site = site , @db_loginip= isnull(iplogin, ''),  @IsNickname = 0, @Nickname = UserName2
		FROM customer WITH (NOLOCK)
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
				-- Starting: Service Broke code --
				SET @SB_xml = (SELECT	
									0	AS '@UserID'
									, 0 AS '@RoleID'
									, @SubAccID	AS '@SubAccID'
									, @ServerID	AS '@ServerID'
									, @inputLoginIP AS '@IP'
									, @LoginDomain AS '@DomainName'
									, @SB_currentDate AS '@LogDate'
									, 1304	AS '@ActionID'
									, @LogData AS	'@Doing'
									, @BrowserName AS '@BrowserName'
									, @Platform	AS '@Platform'
									, @CountryCode AS '@CountryCode'
									, @Duration	AS '@Duration'
									, @Nickname AS '@Username2'
						
								FOR XML PATH ('row')
								)
					
				--SELECT @SB_xml
				EXEC bodb_CustomerLog.sb.CustomerLog_SendMessage @xml = @SB_xml, @MessageType='MessageType_CustomerLog_UserLog_Login', @SB_Error = @SB_Error out
				--SELECT @SB_Error AS SB_Error
				IF @SB_Error = 1 
				BEGIN
				
					BEGIN TRY
						EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login
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
					END TRY
					BEGIN CATCH
						SELECT @LogData = @LogData + ' ErrMsg=' + left(error_message(), 400)
						EXEC bodb_customerlog.dbo.WriteLog_UserLog_Login
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
					END CATCH
				END	
			END	
			ELSE
			BEGIN 
				-- Starting: Service Broke code --
				SET @SB_xml = (SELECT	
									0	AS '@UserID'
									, 0 AS '@RoleID'
									, @SubAccID	AS '@SubAccID'
									, @ServerID	AS '@ServerID'
									, @inputLoginIP AS '@IP'
									, @LoginDomain AS '@DomainName'
									, @SB_currentDate AS '@LogDate'
									, 1304	AS '@ActionID'
									, @LogData AS	'@Doing'
									, @BrowserName AS '@BrowserName'
									, @Platform	AS '@Platform'
									, @CountryCode AS '@CountryCode'
									, @Duration	AS '@Duration'
									, NULL AS '@Username2'
						
								FOR XML PATH ('row')
								)
					
				--SELECT @SB_xml
				EXEC bodb_CustomerLog.sb.CustomerLog_SendMessage @xml = @SB_xml, @MessageType='MessageType_CustomerLog_UserLog_Login', @SB_Error = @SB_Error out
				--SELECT @SB_Error AS SB_Error
				IF @SB_Error = 1 
				BEGIN
					BEGIN TRY
						EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login
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
					END TRY
					BEGIN CATCH
						SELECT @LogData = @LogData + ' ErrMsg=' + left(error_message(), 400)
						EXEC bodb_customerlog.dbo.WriteLog_UserLog_Login
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
					END CATCH
				END	
			END	
			/* Thien@20100820: change the error message to the vague one. Not let them know we have centralized site.
				SELECT @ErrMsg = CASE @Language WHEN 'E' THEN 'You are not allowed to login on this site! Please contact the administrator for the assistance.'  
									WHEN 'CS' THEN N'You are not allowed to login on this site! Please contact the administrator for the assistance..'  
									WHEN 'CT' THEN N'You are not allowed to login on this site! Please contact the administrator for the assistance..'  
									WHEN 'J' THEN N'You are not allowed to login on this site! Please contact the administrator for the assistance..'  
									WHEN 'TH' THEN N'You are not allowed to login on this site! Please contact the administrator for the assistance..'  
									WHEN 'KO' THEN N'You are not allowed to login on this site! Please contact the administrator for the assistance..'  
									ELSE N'You are not allowed to login on this site! Please contact the administrator for the assistance.'  
								END ,@ErrCode=110
				*/
		 
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
					-- Starting: Service Broke code --
					SET @SB_xml = (SELECT	
										@db_custid	AS '@UserID'
										, @RoleID AS '@RoleID'
										, @SubAccID	AS '@SubAccID'
										, @ServerID	AS '@ServerID'
										, @inputLoginIP AS '@IP'
										, @LoginDomain AS '@DomainName'
										, @SB_currentDate AS '@LogDate'
										, 1315	AS '@ActionID'
										, @LogData AS	'@Doing'
										, @BrowserName AS '@BrowserName'
										, @Platform	AS '@Platform'
										, @CountryCode AS '@CountryCode'
										, @Duration	AS '@Duration'
										, @Nickname AS '@Username2'
							
									FOR XML PATH ('row')
									)
						
					--SELECT @SB_xml
					EXEC bodb_CustomerLog.sb.CustomerLog_SendMessage @xml = @SB_xml, @MessageType='MessageType_CustomerLog_UserLog_Login', @SB_Error = @SB_Error out
					--SELECT @SB_Error AS SB_Error
					IF @SB_Error = 1 
					BEGIN
					
						BEGIN TRY
							EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login
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
						END TRY
						BEGIN CATCH
							SELECT @LogData = @LogData + ' ErrMsg=' + left(error_message(), 400)
							EXEC bodb_customerlog.dbo.WriteLog_UserLog_Login
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
						END CATCH
					END	
				END	
				ELSE 
				BEGIN
					-- Starting: Service Broke code --
					SET @SB_xml = (SELECT	
										@db_custid	AS '@UserID'
										, @RoleID AS '@RoleID'
										, @SubAccID	AS '@SubAccID'
										, @ServerID	AS '@ServerID'
										, @inputLoginIP AS '@IP'
										, @LoginDomain AS '@DomainName'
										, @SB_currentDate AS '@LogDate'
										, 1315	AS '@ActionID'
										, @LogData AS	'@Doing'
										, @BrowserName AS '@BrowserName'
										, @Platform	AS '@Platform'
										, @CountryCode AS '@CountryCode'
										, @Duration	AS '@Duration'
										, NULL AS '@Username2'
							
									FOR XML PATH ('row')
									)
						
					--SELECT @SB_xml
					EXEC bodb_CustomerLog.sb.CustomerLog_SendMessage @xml = @SB_xml, @MessageType='MessageType_CustomerLog_UserLog_Login', @SB_Error = @SB_Error out
					--SELECT @SB_Error AS SB_Error
					IF @SB_Error = 1 
					BEGIN
						BEGIN TRY
							EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login
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
						END TRY
						BEGIN CATCH
							SELECT @LogData = @LogData + ' ErrMsg=' + left(error_message(), 400)
							EXEC bodb_customerlog.dbo.WriteLog_UserLog_Login
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
						END CATCH
					END	
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
			-- Starting: Service Broke code --
			SET @SB_xml = (SELECT	
								0	AS '@UserID'
								, 0 AS '@RoleID'
								, @SubAccID	AS '@SubAccID'
								, @ServerID	AS '@ServerID'
								, @inputLoginIP AS '@IP'
								, @LoginDomain AS '@DomainName'
								, @SB_currentDate AS '@LogDate'
								, 1304	AS '@ActionID'
								, @LogData AS	'@Doing'
								, @BrowserName AS '@BrowserName'
								, @Platform	AS '@Platform'
								, @CountryCode AS '@CountryCode'
								, @Duration	AS '@Duration'
								, @Nickname AS '@Username2'
					
							FOR XML PATH ('row')
							)
				
			--SELECT @SB_xml
			EXEC bodb_CustomerLog.sb.CustomerLog_SendMessage @xml = @SB_xml, @MessageType='MessageType_CustomerLog_UserLog_Login', @SB_Error = @SB_Error out
			--SELECT @SB_Error AS SB_Error
			IF @SB_Error = 1 
			BEGIN
							
				BEGIN TRY
					EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login
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
				END TRY
				BEGIN CATCH
					SELECT @LogData = @LogData + ' ErrMsg=' + left(error_message(), 400)
					EXEC bodb_customerlog.dbo.WriteLog_UserLog_Login
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
				END CATCH
			END	
		END				 
		ELSE
		BEGIN
			-- Starting: Service Broke code --
			SET @SB_xml = (SELECT	
								0	AS '@UserID'
								, 0 AS '@RoleID'
								, @SubAccID	AS '@SubAccID'
								, @ServerID	AS '@ServerID'
								, @inputLoginIP AS '@IP'
								, @LoginDomain AS '@DomainName'
								, @SB_currentDate AS '@LogDate'
								, 1304	AS '@ActionID'
								, @LogData AS	'@Doing'
								, @BrowserName AS '@BrowserName'
								, @Platform	AS '@Platform'
								, @CountryCode AS '@CountryCode'
								, @Duration	AS '@Duration'
								, NULL AS '@Username2'
					
							FOR XML PATH ('row')
							)
				
			--SELECT @SB_xml
			EXEC bodb_CustomerLog.sb.CustomerLog_SendMessage @xml = @SB_xml, @MessageType='MessageType_CustomerLog_UserLog_Login', @SB_Error = @SB_Error out
			--SELECT @SB_Error AS SB_Error
			IF @SB_Error = 1 
			BEGIN
			 
				BEGIN TRY
					EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login
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
				 END TRY
				 BEGIN CATCH
					SELECT @LogData = @LogData + ' ErrMsg=' + left(error_message(), 400)
	 				EXEC bodb_customerlog.dbo.WriteLog_UserLog_Login
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
				 END CATCH
			END	 
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
				-- Starting: Service Broke code --
				SET @SB_xml = (SELECT	
									@db_custid	AS '@UserID'
									, @RoleID AS '@RoleID'
									, @SubAccID	AS '@SubAccID'
									, @ServerID	AS '@ServerID'
									, @inputLoginIP AS '@IP'
									, @LoginDomain AS '@DomainName'
									, @SB_currentDate AS '@LogDate'
									, 1304	AS '@ActionID'
									, @LogData AS	'@Doing'
									, @BrowserName AS '@BrowserName'
									, @Platform	AS '@Platform'
									, @CountryCode AS '@CountryCode'
									, @Duration	AS '@Duration'
									, @Nickname AS '@Username2'
						
								FOR XML PATH ('row')
								)
					
				--SELECT @SB_xml
				EXEC bodb_CustomerLog.sb.CustomerLog_SendMessage @xml = @SB_xml, @MessageType='MessageType_CustomerLog_UserLog_Login', @SB_Error = @SB_Error out
				--SELECT @SB_Error AS SB_Error
				IF @SB_Error = 1 
				BEGIN
			
					BEGIN TRY
						EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login
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
					END TRY
					BEGIN CATCH
						SELECT @LogData = @LogData + ' ErrMsg=' + left(error_message(), 400)
						EXEC bodb_customerlog.dbo.WriteLog_UserLog_Login
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
					END CATCH
				END
			END	
			ELSE
			BEGIN
				-- Starting: Service Broke code --
				SET @SB_xml = (SELECT	
									@db_custid	AS '@UserID'
									, @RoleID AS '@RoleID'
									, @SubAccID	AS '@SubAccID'
									, @ServerID	AS '@ServerID'
									, @inputLoginIP AS '@IP'
									, @LoginDomain AS '@DomainName'
									, @SB_currentDate AS '@LogDate'
									, 1304	AS '@ActionID'
									, @LogData AS	'@Doing'
									, @BrowserName AS '@BrowserName'
									, @Platform	AS '@Platform'
									, @CountryCode AS '@CountryCode'
									, @Duration	AS '@Duration'
									, NULL AS '@Username2'
						
								FOR XML PATH ('row')
								)
					
				--SELECT @SB_xml
				EXEC bodb_CustomerLog.sb.CustomerLog_SendMessage @xml = @SB_xml, @MessageType='MessageType_CustomerLog_UserLog_Login', @SB_Error = @SB_Error out
				--SELECT @SB_Error AS SB_Error
				IF @SB_Error = 1 
				BEGIN
					BEGIN TRY
						EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login
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
					END TRY
					BEGIN CATCH
						SELECT @LogData = @LogData + ' ErrMsg=' + left(error_message(), 400)
						EXEC bodb_customerlog.dbo.WriteLog_UserLog_Login
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
					END CATCH
				END	
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
			-- Starting: Service Broke code --
			SET @SB_xml = (SELECT	
								0	AS '@UserID'
								, @RoleID AS '@RoleID'
								, @SubAccID	AS '@SubAccID'
								, @ServerID	AS '@ServerID'
								, @inputLoginIP AS '@IP'
								, @LoginDomain AS '@DomainName'
								, @SB_currentDate AS '@LogDate'
								, 1304	AS '@ActionID'
								, @LogData AS	'@Doing'
								, @BrowserName AS '@BrowserName'
								, @Platform	AS '@Platform'
								, @CountryCode AS '@CountryCode'
								, @Duration	AS '@Duration'
								, @Nickname AS '@Username2'
					
							FOR XML PATH ('row')
							)
				
			--SELECT @SB_xml
			EXEC bodb_CustomerLog.sb.CustomerLog_SendMessage @xml = @SB_xml, @MessageType='MessageType_CustomerLog_UserLog_Login', @SB_Error = @SB_Error out
			--SELECT @SB_Error AS SB_Error
			IF @SB_Error = 1 
			BEGIN			
				BEGIN TRY
					EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login
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
				END TRY
				BEGIN CATCH
					SELECT @LogData = @LogData + ' ErrMsg=' + left(error_message(), 400)
					EXEC bodb_customerlog.dbo.WriteLog_UserLog_Login
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
				END CATCH
			END	
		END	
		ELSE
		BEGIN
			-- Starting: Service Broke code --
			SET @SB_xml = (SELECT	
								0	AS '@UserID'
								, @RoleID AS '@RoleID'
								, @SubAccID	AS '@SubAccID'
								, @ServerID	AS '@ServerID'
								, @inputLoginIP AS '@IP'
								, @LoginDomain AS '@DomainName'
								, @SB_currentDate AS '@LogDate'
								, 1304	AS '@ActionID'
								, @LogData AS	'@Doing'
								, @BrowserName AS '@BrowserName'
								, @Platform	AS '@Platform'
								, @CountryCode AS '@CountryCode'
								, @Duration	AS '@Duration'
								, NULL AS '@Username2'
					
							FOR XML PATH ('row')
							)
				
			--SELECT @SB_xml
			EXEC bodb_CustomerLog.sb.CustomerLog_SendMessage @xml = @SB_xml, @MessageType='MessageType_CustomerLog_UserLog_Login', @SB_Error = @SB_Error out
			--SELECT @SB_Error AS SB_Error
			IF @SB_Error = 1 
			BEGIN			
			
				BEGIN TRY
					EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login
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
				END TRY
				BEGIN CATCH
					SELECT @LogData = @LogData + ' ErrMsg=' + left(error_message(), 400)
					EXEC bodb_customerlog.dbo.WriteLog_UserLog_Login
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
				END CATCH
			END	
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
			-- Starting: Service Broke code --
			SET @SB_xml = (SELECT	
								@CustID	AS '@UserID'
								, @RoleID AS '@RoleID'
								, @SubAccID	AS '@SubAccID'
								, @ServerID	AS '@ServerID'
								, @inputLoginIP AS '@IP'
								, @LoginDomain AS '@DomainName'
								, @SB_currentDate AS '@LogDate'
								, 1304	AS '@ActionID'
								, @LogData AS	'@Doing'
								, @BrowserName AS '@BrowserName'
								, @Platform	AS '@Platform'
								, @CountryCode AS '@CountryCode'
								, @Duration	AS '@Duration'
								, @Nickname AS '@Username2'
					
							FOR XML PATH ('row')
							)
				
			--SELECT @SB_xml
			EXEC bodb_CustomerLog.sb.CustomerLog_SendMessage @xml = @SB_xml, @MessageType='MessageType_CustomerLog_UserLog_Login', @SB_Error = @SB_Error out
			--SELECT @SB_Error AS SB_Error
			IF @SB_Error = 1 
			BEGIN			
			
				BEGIN TRY
					EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login
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
				END TRY
				BEGIN CATCH
					SELECT @LogData = @LogData + ' ErrMsg=' + left(error_message(), 400)
					EXEC bodb_customerlog.dbo.WriteLog_UserLog_Login
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
				END CATCH
			END	
		END	
		ELSE
		BEGIN
			-- Starting: Service Broke code --
			SET @SB_xml = (SELECT	
								@CustID	AS '@UserID'
								, @RoleID AS '@RoleID'
								, @SubAccID	AS '@SubAccID'
								, @ServerID	AS '@ServerID'
								, @inputLoginIP AS '@IP'
								, @LoginDomain AS '@DomainName'
								, @SB_currentDate AS '@LogDate'
								, 1304	AS '@ActionID'
								, @LogData AS	'@Doing'
								, @BrowserName AS '@BrowserName'
								, @Platform	AS '@Platform'
								, @CountryCode AS '@CountryCode'
								, @Duration	AS '@Duration'
								, NULL AS '@Username2'
					
							FOR XML PATH ('row')
							)
				
			--SELECT @SB_xml
			EXEC bodb_CustomerLog.sb.CustomerLog_SendMessage @xml = @SB_xml, @MessageType='MessageType_CustomerLog_UserLog_Login', @SB_Error = @SB_Error out
			--SELECT @SB_Error AS SB_Error
			IF @SB_Error = 1 
			BEGIN			
				BEGIN TRY
					EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login
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
				END TRY
				BEGIN CATCH
					SELECT @LogData = @LogData + ' ErrMsg=' + left(error_message(), 400)
					EXEC bodb_customerlog.dbo.WriteLog_UserLog_Login
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
				END CATCH
			END	
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
			-- Starting: Service Broke code --
			SET @SB_xml = (SELECT	
								@db_custid	AS '@UserID'
								, @RoleID AS '@RoleID'
								, @SubAccID	AS '@SubAccID'
								, @ServerID	AS '@ServerID'
								, @inputLoginIP AS '@IP'
								, @LoginDomain AS '@DomainName'
								, @SB_currentDate AS '@LogDate'
								, 1304	AS '@ActionID'
								, @LogData AS	'@Doing'
								, @BrowserName AS '@BrowserName'
								, @Platform	AS '@Platform'
								, @CountryCode AS '@CountryCode'
								, @Duration	AS '@Duration'
								, @Nickname AS '@Username2'
					
							FOR XML PATH ('row')
							)
				
			--SELECT @SB_xml
			EXEC bodb_CustomerLog.sb.CustomerLog_SendMessage @xml = @SB_xml, @MessageType='MessageType_CustomerLog_UserLog_Login', @SB_Error = @SB_Error out
			--SELECT @SB_Error AS SB_Error
			IF @SB_Error = 1 
			BEGIN			
			
				BEGIN TRY
					EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login
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
				END TRY
				BEGIN CATCH
					SELECT @LogData = @LogData + ' ErrMsg=' + left(error_message(), 400)
					EXEC bodb_customerlog.dbo.WriteLog_UserLog_Login
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
				END CATCH
			END	
		END	
		ELSE
		BEGIN
			-- Starting: Service Broke code --
			SET @SB_xml = (SELECT	
								@db_custid	AS '@UserID'
								, @RoleID AS '@RoleID'
								, @SubAccID	AS '@SubAccID'
								, @ServerID	AS '@ServerID'
								, @inputLoginIP AS '@IP'
								, @LoginDomain AS '@DomainName'
								, @SB_currentDate AS '@LogDate'
								, 1304	AS '@ActionID'
								, @LogData AS	'@Doing'
								, @BrowserName AS '@BrowserName'
								, @Platform	AS '@Platform'
								, @CountryCode AS '@CountryCode'
								, @Duration	AS '@Duration'
								, NULL AS '@Username2'
					
							FOR XML PATH ('row')
							)
				
			--SELECT @SB_xml
			EXEC bodb_CustomerLog.sb.CustomerLog_SendMessage @xml = @SB_xml, @MessageType='MessageType_CustomerLog_UserLog_Login', @SB_Error = @SB_Error out
			--SELECT @SB_Error AS SB_Error
			IF @SB_Error = 1 
			BEGIN			
				BEGIN TRY
					EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login
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
				END TRY
				BEGIN CATCH
					SELECT @LogData = @LogData + ' ErrMsg=' + left(error_message(), 400)
					EXEC bodb_customerlog.dbo.WriteLog_UserLog_Login
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
				END CATCH
			END	
		END	
		SELECT @ErrMsg = CASE @Language WHEN 'E' THEN 'Account closed. Please contact your administrator!'  
						ELSE [dbo].[f_Get_MsgNamebyMsgID](80002,@Language)
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
			-- Starting: Service Broke code --
			SET @SB_xml = (SELECT	
								@db_custid	AS '@UserID'
								, @RoleID AS '@RoleID'
								, @SubAccID	AS '@SubAccID'
								, @ServerID	AS '@ServerID'
								, @inputLoginIP AS '@IP'
								, @LoginDomain AS '@DomainName'
								, @SB_currentDate AS '@LogDate'
								, 1304	AS '@ActionID'
								, @LogData AS	'@Doing'
								, @BrowserName AS '@BrowserName'
								, @Platform	AS '@Platform'
								, @CountryCode AS '@CountryCode'
								, @Duration	AS '@Duration'
								, @Nickname AS '@Username2'
					
							FOR XML PATH ('row')
							)
				
			--SELECT @SB_xml
			EXEC bodb_CustomerLog.sb.CustomerLog_SendMessage @xml = @SB_xml, @MessageType='MessageType_CustomerLog_UserLog_Login', @SB_Error = @SB_Error out
			--SELECT @SB_Error AS SB_Error
			IF @SB_Error = 1 
			BEGIN			
			 		
				BEGIN TRY
					EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login
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
				END TRY
				BEGIN CATCH
					SELECT @LogData = @LogData + ' ErrMsg=' + left(error_message(), 400)
					EXEC bodb_customerlog.dbo.WriteLog_UserLog_Login
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
				END CATCH
			END	
		END	
		ELSE
		BEGIN
			-- Starting: Service Broke code --
			SET @SB_xml = (SELECT	
								@db_custid	AS '@UserID'
								, @RoleID AS '@RoleID'
								, @SubAccID	AS '@SubAccID'
								, @ServerID	AS '@ServerID'
								, @inputLoginIP AS '@IP'
								, @LoginDomain AS '@DomainName'
								, @SB_currentDate AS '@LogDate'
								, 1304	AS '@ActionID'
								, @LogData AS	'@Doing'
								, @BrowserName AS '@BrowserName'
								, @Platform	AS '@Platform'
								, @CountryCode AS '@CountryCode'
								, @Duration	AS '@Duration'
								, NULL AS '@Username2'
					
							FOR XML PATH ('row')
							)
				
			--SELECT @SB_xml
			EXEC bodb_CustomerLog.sb.CustomerLog_SendMessage @xml = @SB_xml, @MessageType='MessageType_CustomerLog_UserLog_Login', @SB_Error = @SB_Error out
			--SELECT @SB_Error AS SB_Error
			IF @SB_Error = 1 
			BEGIN			
			
				BEGIN TRY
					EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login
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
				END TRY
				BEGIN CATCH
					SELECT @LogData = @LogData + ' ErrMsg=' + left(error_message(), 400)
					EXEC bodb_customerlog.dbo.WriteLog_UserLog_Login
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
				END CATCH
			END	
		END	
	--	
	--    IF @failedcount > 5 AND @IsNickname = 0 	
	--    BEGIN
	--	    UPDATE custinfo WITH (ROWLOCK, UPDLOCK) SET closed = 1 WHERE custid = @db_custid 
	--	    --log data to UserLog_RunSP 
	--	    SELECT @LogSPData = '<Age_LoginVerifyDownline IP="'+ @inputLoginIP + '" />'			
	--	    	    EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_RunSP
	--		    @UserID = @db_custid,
	--		    @CustID = @CustID,
	--		    @ActionID = 908,
	--		    @TrackingValue = @LogSPData
	--	    ----------------------------	
	--    END

		
		IF @failedcount > 5 	
		BEGIN
			UPDATE custinfo WITH (ROWLOCK, UPDLOCK) SET closed = 1 WHERE custid = @db_custid 
		    
			UPDATE Customer WITH (ROWLOCK,UPDLOCK) SET logincount = 0 WHERE custid = @db_custid 
			--log data to UserLog_RunSP 
	    		SELECT @LogSPData = '<Age_LoginVerifyDownline IP="'+ @inputLoginIP + '" />'		    
			BEGIN TRY 	
			EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_RunSP
				@UserID = @db_custid,
				@CustID = @CustID,
				@ActionID = 908,
				@TrackingValue = @LogSPData,
				@Duration = @Duration
			END TRY 
			BEGIN CATCH
				SELECT @LogSPData = '<Age_LoginVerifyDownline IP="'+ @inputLoginIP + '" ' +
											'ErrMsg="' + ERROR_MESSAGE() +'" ' + 
									
									' />'
				EXEC bodb_customerlog.dbo.WriteLog_UserLog_RunSP
					@UserID = @db_custid,
					@CustID = @CustID,
					@ActionID = 908,
					@TrackingValue = @LogSPData,
					@Duration = @Duration		
			
			END CATCH 
			----------------------------	
		END

		--IF (@failedcount <= 255) -- max of tinyint
		--BEGIN
		--	UPDATE customer WITH (ROWLOCK, UPDLOCK) SET logincount = CASE WHEN @failedcount > 5  AND @IsNickname = 0 THEN 6 ELSE @failedcount END
		--	WHERE custid = @db_custid  
		--END
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
	SET logincount = CASE WHEN @isExisted = 0 THEN 0 ELSE logincount END,
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
	IF @IsNickname =1 AND @SubAccID <= 0
	BEGIN
		-- Starting: Service Broke code --
		SET @SB_xml = (SELECT	
							@db_custid	AS '@UserID'
							, @RoleID AS '@RoleID'
							, @SubAccID	AS '@SubAccID'
							, @ServerID	AS '@ServerID'
							, @inputLoginIP AS '@IP'
							, @LoginDomain AS '@DomainName'
							, @SB_currentDate AS '@LogDate'
							, 1304	AS '@ActionID'
							, @LogData AS	'@Doing'
							, @BrowserName AS '@BrowserName'
							, @Platform	AS '@Platform'
							, @CountryCode AS '@CountryCode'
							, @Duration	AS '@Duration'
							, @Nickname AS '@Username2'
				
						FOR XML PATH ('row')
						)
			
		--SELECT @SB_xml
		EXEC bodb_CustomerLog.sb.CustomerLog_SendMessage @xml = @SB_xml, @MessageType='MessageType_CustomerLog_UserLog_Login', @SB_Error = @SB_Error out
		--SELECT @SB_Error AS SB_Error
		IF @SB_Error = 1 
		BEGIN			
			BEGIN TRY		
				EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login
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
			END TRY
			BEGIN CATCH
				SELECT @LogData = @LogData + ' ErrMsg=' + left(error_message(), 400)
				EXEC bodb_customerlog.dbo.WriteLog_UserLog_Login
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
			END CATCH
		END	
	END	
	ELSE
	BEGIN
		-- Starting: Service Broke code --
		SET @SB_xml = (SELECT	
							@db_custid	AS '@UserID'
							, @RoleID AS '@RoleID'
							, @SubAccID	AS '@SubAccID'
							, @ServerID	AS '@ServerID'
							, @inputLoginIP AS '@IP'
							, @LoginDomain AS '@DomainName'
							, @SB_currentDate AS '@LogDate'
							, 1304	AS '@ActionID'
							, @LogData AS	'@Doing'
							, @BrowserName AS '@BrowserName'
							, @Platform	AS '@Platform'
							, @CountryCode AS '@CountryCode'
							, @Duration	AS '@Duration'
							, NULL AS '@Username2'
				
						FOR XML PATH ('row')
						)
			
		--SELECT @SB_xml
		EXEC bodb_CustomerLog.sb.CustomerLog_SendMessage @xml = @SB_xml, @MessageType='MessageType_CustomerLog_UserLog_Login', @SB_Error = @SB_Error out
		--SELECT @SB_Error AS SB_Error
		IF @SB_Error = 1 
		BEGIN			
			BEGIN TRY
				EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login
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
			END TRY
			BEGIN CATCH
				SELECT @LogData = @LogData + ' ErrMsg=' + left(error_message(), 400)
				EXEC bodb_customerlog.dbo.WriteLog_UserLog_Login
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
			END CATCH
		END	
	END	
END
GO
