/*<info serverAlias="DBCUST-CustDB" executers="bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[Age_LoginDownline]  
	@UserName varchar(50) = '' OUTPUT,  
	@UserPwd varchar(50),  
	@LoginIP varchar(15)='' OUTPUT,  --- if output=NULL then account is the first login
	@ServerID int =0 OUTPUT,  
	@LoginDomain NVARCHAR(253) = NULL,
	@SiteGroup VARCHAR(10)='ALL',
	@BrowserName NVARCHAR(255) = NULL,
	@Platform NVARCHAR(255) = NULL,  
	@CountryCode VARCHAR(64) = NULL,  
	@RoleID int = 0 OUTPUT,  
	@CustID int OUTPUT,  
	@Currency varchar(10) = '' OUTPUT,  
	@CurrencyId int = 0 OUTPUT,
	@Language varchar(2) = 'E',  
	@MasterUsername varchar(50) = '' OUTPUT,  
	@SubAccID int = 0, --Sub-AccountID,  
	@site varchar(20) = '' OUTPUT,  
	@isCasinoDisabled bit = false OUTPUT,
	@IsCasinoSync bit = false OUTPUT,
	@isBingoDisabled bit = false OUTPUT,
	@isBingoSync bit = false OUTPUT,
	@isFirstLogin	BIT = 0 OUTPUT,
	@PwdExpiry		DATETIME = NULL OUTPUT,
	@LastChangedPwdDate	DATETIME = NULL OUTPUT, 	
	@IsNickname BIT = 0 OUTPUT,
	@NicknameLoginOnly BIT = 0 OUTPUT,
	@NickName VARCHAR(50) = '' OUTPUT,
	@SecurityCode VARCHAR(50) = '' OUTPUT,
	@isForcedChangeSecurityCode BIT = 0 OUTPUT,
	@ErrCode int = 0 OUTPUT,  
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS
/*
	Created: 
	Task : login from agent site
	DB: DBCUST/CustDB
	Original:

	Revisions:
		- 20090213@Hanh: block agents under dummy master "12BETAFF" (927780) from logging in agent site.
		- 20090225@Hiep: get CasinoSync and CasinoDisable for Casino Integration with Agent site
		- 20090312@Phuc: update logincount = 6 if login fail over 5 times.
		- 20090317@Hanh: add Korean language
		- 20090407@Lee: Add output currencyId
		- 20090807@Phuc: check user was disabled or not.	
		- 20090917@Phuc: write log into DBLOG.
		- 20091210@Minh: add error code about login exceed 5 times.
		- 20100101@Kiwi: Modify Logs.
		- 20100922@Jamie: Get syncBingo, disableBingo 
		- 20101006@Kaden; Add 4 parameter (DomainName, BrowserName, Platform, CountryCode). Save more detail user info 
		- 20101022@Johnson: Record execution time
		- 20101022@Jamie: declare @inputLoginIP to keep the input value 
		- 20110103@Viet: Block all access from SMS office
		- 20110425@Johnson: change ActionID to new ActionID in writting log
		- 20110608@Sophia: Log in using Nickname, add parameter @IsNickname, @NicknameLoginOnly, @Nickname
		- 20110621@Sophia: Do not update closed = 1 when login wrong more than 5 times, because it will be checked on web
		- 20110722@Sophia: Do not Use Prefix 'Agency$' for username2
		- 20110912@Tom: Remove parameter @IsLoginWap	
		- 20120223@Dan: check @failedcount < max size of tinyint before updating
		- 20120305@Elodie: Check grant access to AgentSite from outside throught test accounts
		- 20120611@Jamie: Harcode for real lines LC-RM% login to agency 
		- 20120622@Jamie: Check domain and site 
		- 20121128@Elodie: Get an error message from f_Get_MsgNameByMsgID function by language
		- 20130123@Elodie: Write more log on DBTXN server in case of DBLOG server failure
		- 20130322@Ethan: Change write log format for @NicknameLoginOnly
		- 20130327@Jamie: Close account if login fail over 5 times.
		- 20130328@Jamie: Get LastChangedPwdDate in case login via OldUserPwd
		- 20130409@Johnson: Get more fields SecurityCode and isForcedChangeSecurityCode 
		- 20161102@Helen: Apply Service Broker for Writing Log - [Redmine: 65806] 	
		- 20190906@Eden: 3rd party products - Remove InActive Products Phase 2 [Redmine: #118699]

	Param's Explanation:
		• @IsNickname: is use Nickname or not
		• @NicknameLoginOnly: Value of the option Set login option by nickname only
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

	DECLARE @Begin DATETIME, @End DATETIME, @Duration INT, @LogData NVARCHAR(200) 
	DECLARE	@inputLoginIP VARCHAR(15), @rowcount INT, @OldUserPwd VARCHAR(40)
	DECLARE @db_custid INT, @db_userpwd NVARCHAR(50), @db_roleid TINYINT, @failedcount INT, @role NVARCHAR(20)  
	DECLARE @db_currency TINYINT, @closed BIT , @db_loginip NVARCHAR(20), @db_enabled BIT
    
	SET @Begin = GETDATE() 
	SELECT	@inputLoginIP = @LoginIP 

	DECLARE @isAllowed bit
	SELECT @isAllowed = 0

	-- Hardcode: specially accept for Thien and Viet to login into any agents from anywhere
	if @UserName like 'dbaThien/%' OR @UserName like 'pgmViet/%' 
	BEGIN 
		DECLARE @AdminUsername VARCHAR(30)
		SELECT @AdminUsername = left(@username, charindex('/',@UserName)-1),
				@username = replace(@UserName, @AdminUsername + '/', '')
		
		IF EXISTS ( SELECT 1
					FROM customer WITH (NOLOCK)
					WHERE username = @AdminUsername AND userpwd = @UserPwd AND RoleID > 8)
		BEGIN
			SELECT @UserPwd = userpwd
			FROM customer WITH (NOLOCK)
			WHERE username = @username
				
			SELECT @isAllowed = 1
		END
		ELSE
			SELECT @UserPwd = ''   
	END  

	----- 20110608: login using Nickname
	SET @ServerID = 0  
	SET @NicknameLoginOnly = 0

	IF @SubAccID <= 0
	BEGIN 
		IF EXISTS (SELECT 1 FROM customer AS c WITH (NOLOCK) WHERE c.username2 = @UserName)
		BEGIN
			---Log in nickname
			SELECT	@db_custid = custid, @db_userpwd = userpwd, @db_roleid = isnull(roleid,0), @db_currency = currency, @failedcount = isnull(logincount,0),  
					@site = site , @db_loginip= isnull(iplogin, ''), @IsNickname = 1, @Nickname = UserName2, @UserName = Username
			FROM customer c WITH (NOLOCK)
			WHERE username2 = @UserName
					and mrecommend <> 927780

			IF @db_roleid = 2  
				SELECT @NicknameLoginOnly = NicknameLoginOnly FROM CustAgent WITH (NOLOCK)WHERE CustID = @db_custid   
			ELSE IF @db_roleid = 3  
				SELECT @NicknameLoginOnly = NicknameLoginOnly FROM CustMaster WITH (NOLOCK) WHERE CustID = @db_custid  
			ELSE IF @db_roleid = 4  
				SELECT @NicknameLoginOnly = NicknameLoginOnly FROM CustSuper WITH (NOLOCK) WHERE CustID = @db_custid 

		END
		ELSE
		BEGIN 
			--- Check log in nickname Only 
			SELECT	 @db_custid = custid,  @db_roleid = isnull(roleid,0)
					,@IsNickname = 0 , @Nickname = Username2
			FROM customer WITH (NOLOCK)
			WHERE username = @UserName
					and mrecommend <> 927780

			IF @db_roleid = 2  
				SELECT @NicknameLoginOnly = NicknameLoginOnly FROM CustAgent WITH (NOLOCK)WHERE CustID = @db_custid   
			ELSE IF @db_roleid = 3  
				SELECT @NicknameLoginOnly = NicknameLoginOnly FROM CustMaster WITH (NOLOCK) WHERE CustID = @db_custid  
			ELSE IF @db_roleid = 4  
				SELECT @NicknameLoginOnly = NicknameLoginOnly FROM CustSuper WITH (NOLOCK) WHERE CustID = @db_custid 
			
			IF @NicknameLoginOnly = 1 
			BEGIN  
				SELECT	@LogData = 'Account:' + @UserName + ' - ' + 'Login Option: Nickname Only.'  
				SET @End = GETDATE() 
				SET @Duration = DATEDIFF(millisecond,@Begin,@End)
				
				EXEC dbo.Acc_WriteLog_UserLog_Login_Wrapper
					@UserID = @db_custid, 
					@RoleID = @RoleID, 
					@SubAccID = @SubAccID,
					@ServerID = @ServerID,
					@LoginIP = @inputLoginIP,
					@DomainName = @LoginDomain,
					@ActionID = 1310,
					@Doing = @LogData,
					@BrowserName = @BrowserName,
					@Platform = @Platform,
					@CountryCode = @CountryCode,
					@Duration = @Duration
					
				SELECT	@ErrMsg = CASE @Language WHEN 'E' THEN  'Wrong username/nickname or password.' 
												ELSE [dbo].[f_Get_MsgNamebyMsgID](80001,@Language)  
												END,
						@ErrCode= 106                  
				RETURN  
			END  
			
			--- log in username
			SELECT @db_custid = custid, @db_userpwd = userpwd, @db_roleid = isnull(roleid,0), @db_currency = currency, @failedcount = isnull(logincount,0),  
					@site = site , @db_loginip= isnull(iplogin, ''), @IsNickname = 0 , @Nickname = username2
			FROM customer WITH (NOLOCK) 
			WHERE username = @UserName
					AND mrecommend <> 927780

		END
	END
	ELSE  --- login Sub-account (called from sp Age_LoginDownLine_Sub )
	BEGIN
		SELECT @db_custid = custid, @db_userpwd = userpwd, @db_roleid = roleid, @db_currency = currency, @failedcount = isnull(logincount,0),  
				@site = site , @db_loginip= isnull(iplogin, ''), @IsNickname = 0 , @Nickname = NULL, @NicknameLoginOnly = NULL 
		FROM customer WITH (NOLOCK) 
		WHERE username = @UserName
			AND mrecommend <> 927780
	END
		
	SET @rowcount = @@rowcount

	-------20110608: login using Nickname
	 
	-- user not found  
	IF (@rowcount = 0)
	BEGIN  
		SELECT @LogData = 'Account:' + @UserName + ' - ' + 'Login Result:Failed (User_Not_Found)'  
	 
		SET @End = GETDATE() 
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
				@ActionID = 1310,
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
				@ActionID = 1310,
				@Doing = @LogData,
				@BrowserName = @BrowserName,
				@Platform = @Platform,
				@CountryCode = @CountryCode,
				@Duration = @Duration					
		END
			 
		SELECT @ErrMsg = CASE @Language WHEN 'E' THEN  'Wrong username/nickname or password.' 
					ELSE [dbo].[f_Get_MsgNamebyMsgID](80001,@Language)  
					END ,@ErrCode=206       
	   
		RETURN  
	END 

	---Check 789y OR IBCBET/Others 
	IF @SiteGroup <> 'ALL'  ---IN ('789y','IBCBET','Others')
	BEGIN
		EXEC dbo.Age_LoginCheckSiteGroup 
				@SiteGroup = @SiteGroup, 
				@Site = @Site,
				@isAllowed = @isAllowed OUTPUT

		IF @isAllowed = 0
		BEGIN
			SELECT @LogData = 'Account:' + @UserName + ' - ' + 'Login Result:Wrong domain (' + @Site + '/' + @LoginDomain + ')'
		 
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
					@ActionID = 1316,
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
					@ActionID = 1316,
					@Doing = @LogData,
					@BrowserName = @BrowserName,
					@Platform = @Platform,
					@CountryCode = @CountryCode,
					@Duration = @Duration					
			END	 

			SELECT @ErrMsg = CASE @Language WHEN 'E' THEN  'Wrong username/nickname or password.' 
						ELSE [dbo].[f_Get_MsgNamebyMsgID](80001,@Language)
						END ,@ErrCode=206       
			RETURN  
		END
	END
	--END check 789y OR IBCBET/Others

	--Check grant access to AgentSite from outside throught test accounts
	DECLARE @IsAccess BIT
	SET @IsAccess = 1

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

		IF @IsNickname =1
		BEGIN
			EXEC dbo.Acc_WriteLog_UserLog_Login_Wrapper
				@UserID = @db_custid, 
				@RoleID = @db_roleid, 
				@SubAccID = @SubAccID,
				@ServerID = @ServerID,
				@LoginIP = @inputLoginIP,
				@DomainName = @LoginDomain,
				@ActionID = 1310,
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
				@RoleID = @db_roleid, 
				@SubAccID = @SubAccID,
				@ServerID = @ServerID,
				@LoginIP = @inputLoginIP,
				@DomainName = @LoginDomain,
				@ActionID = 1310,
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

	-- Block all access from SMS office to login with real account
	IF @isAllowed = 0 AND @Site NOT IN ('12Bet', 'asiabet88', 'mansion88', 'alog', 'ispo', 'TLC','DELA','Spondemo')
	BEGIN
		set @isAllowed = 1
		IF @db_currency <> 20 AND LEFT(@inputLoginIP, 10) = '202.78.228'
			SET @isAllowed = 0
			
		IF @UserName LIKE 'LC-RM%'  --20120611@Jamie: Harcode for LiveCasino Login TESTING 
			SELECT @isAllowed = 1 				
				
		IF (@IsAllowed = 0)
		BEGIN  
			SELECT @LogData = 'Account:' + @UserName + ' - ' + 'Login Result:Failed (IP_Denied)'  
		 
			SET @End = GETDATE() 
			SET @Duration = DATEDIFF(millisecond,@Begin,@End)
			
			IF @IsNickname =1
			BEGIN
				EXEC dbo.Acc_WriteLog_UserLog_Login_Wrapper
					@UserID = @db_custid, 
					@RoleID = @db_roleid, 
					@SubAccID = @SubAccID,
					@ServerID = @ServerID,
					@LoginIP = @inputLoginIP,
					@DomainName = @LoginDomain,
					@ActionID = 1310,
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
					@RoleID = @db_roleid, 
					@SubAccID = @SubAccID,
					@ServerID = @ServerID,
					@LoginIP = @inputLoginIP,
					@DomainName = @LoginDomain,
					@ActionID = 1310,
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

	--set serverID
	SELECT @CustID = @db_custid, @RoleID = @db_roleid
	SELECT @ServerID = 	CASE WHEN @roleid=2 THEN 90 WHEN @roleid=3 THEN 91 ELSE 92 END -- login from web
	 

	SELECT @role = CASE @db_roleid WHEN 1 THEN 'Customer:' WHEN 2 THEN 'Agent:' WHEN 3 THEN 'Master:' WHEN 4 THEN 'Super:' ELSE 'Unknown:' END  
	-- check condition  
	IF (@db_roleid not in (2,3,4))
	 BEGIN  
	  SELECT @LogData =  @role + @UserName + ' - ' + 'Login Result:Failed (Not_Agent)'
	  
		SET	@End = GETDATE() 
		SET @Duration = DATEDIFF(millisecond,@Begin,@End)
		
		IF @isNickname = 1
		BEGIN
			EXEC dbo.Acc_WriteLog_UserLog_Login_Wrapper
				@UserID = 0, 
				@RoleID = @RoleID, 
				@SubAccID = @SubAccID,
				@ServerID = @ServerID,
				@LoginIP = @inputLoginIP,
				@DomainName = @LoginDomain,
				@ActionID = 1310,
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
				@ActionID = 1310,
				@Doing = @LogData,
				@BrowserName = @BrowserName,
				@Platform = @Platform,
				@CountryCode = @CountryCode,
				@Duration = @Duration				
		END
	  select @ErrMsg = N'Login Failed.',@ErrCode=107  
	  --raiserror (@ErrMsg, 16, 1)  
	  return  
	 END  

	 
	SELECT	@closed = closed,@IsCasinoSync = SyncCasino
			,@isCasinoDisabled = DisableCasino
			,@db_enabled = isnull(enabled,0)
	FROM custinfo with (nolock) WHERE custid = @db_custid

	IF (@db_enabled <> 1)
	BEGIN
		 SELECT @ErrMsg = CASE @Language WHEN 'E' THEN 'This account was disabled!'  
				 ELSE [dbo].[f_Get_MsgNamebyMsgID](60020,@Language)
				END ,@ErrCode=600    
		SELECT @LogData = 'Agent:' + @UserName + ' - ' + 'Login Result:Failed (User_Disabled)'  
		
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
				@ActionID = 1310,
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
				@ActionID = 1310,
				@Doing = @LogData,
				@BrowserName = @BrowserName,
				@Platform = @Platform,
				@CountryCode = @CountryCode, 
				@Duration = @Duration				
		END	

		RETURN
	END

	  
	IF (IsNull(@closed, 1) = 1)
	 BEGIN  
	  SELECT @LogData =  @role + @UserName + ' - ' + 'Login Result:Failed (A/C_Closed)'  
	  
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
				@ActionID = 1310,		 
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
				@ActionID = 1310,		 
				@Doing = @LogData,
				@BrowserName = @BrowserName,
				@Platform = @Platform,
				@CountryCode = @CountryCode,
				@Duration = @Duration				
		 END 
		select @ErrMsg = case @Language when 'E' then 'Account closed. Please contact your administrator!'  
		ELSE [dbo].[f_Get_MsgNamebyMsgID](80002,@Language)
	   end ,@ErrCode=108  
	  --select @ErrMsg = case @Language when 'E' then N'Account closed. Please contact your administrator!' else N'此戶口已關閉. 請聯絡管理部' end,  
	  --@ErrCode=108  
	  --raiserror (@ErrMsg, 16, 1)  
	  return  
	 END  
	ELSE IF (@db_userpwd <> @UserPWD)
	BEGIN  
		SELECT	 @OldUserPwd			= ISNULL(OldUserPwd,'')
				,@LastChangedPwdDate	= LastChangedPwdDate
		FROM	CustLoginInfo WITH (NOLOCK)
		WHERE	CustID = @CustID
		
		IF	@UserPWD = @OldUserPwd	
			SELECT	@LastChangedPwdDate = @LastChangedPwdDate
		ELSE	SELECT	@LastChangedPwdDate = NULL 

		SELECT @LogData =  @role + @UserName + ' - ' + 'Login Result:Failed (Password)'  
		,@failedcount = @failedcount + 1 
		
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
				@ActionID = 1310,
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
				@ActionID = 1310,
				@Doing = @LogData,
				@BrowserName = @BrowserName,
				@Platform = @Platform,
				@CountryCode = @CountryCode,
				@Duration = @Duration				
		END
	
		/* START --Jamie@20130327 Close accounts after 5 logins failed */
		IF @failedcount > 5
		BEGIN
			UPDATE custinfo WITH (ROWLOCK, UPDLOCK) SET closed = 1 WHERE custid = @db_custid 
		    
			UPDATE Customer WITH (ROWLOCK,UPDLOCK) SET logincount = 0 WHERE custid = @db_custid 
			--log data to UserLog_RunSP 
			SELECT @LogData = '<Age_LoginDownline IP="'+ @inputLoginIP + '" />'		    
			
			BEGIN TRY 	
			EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_RunSP
				@UserID = @db_custid,
				@CustID = @CustID,
				@ActionID = 910,
				@TrackingValue = @LogData,
				@Duration = @Duration
			END TRY 
			BEGIN CATCH
				SELECT @LogData = '<Age_LoginDownline IP="'+ @inputLoginIP + '" ' +
											'ErrMsg="' + ERROR_MESSAGE() +'" ' + 
									
									' />'
				EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_RunSP
					@UserID = @db_custid,
					@CustID = @CustID,
					@ActionID = 910,
					@TrackingValue = @LogData,
					@Duration = @Duration		
			
			END CATCH 
			----------------------------	
		END
		/*END --Close accounts after 5 logins failed */


		--IF (@failedcount <= 255) -- max of tinyint
		IF (@failedcount <=5) -- max of tinyint

		BEGIN
			UPDATE	customer with (rowlock, updlock) 
			SET		logincount = @failedcount 
			WHERE	custid = @db_custid 
		END

	  
		SELECT @ErrMsg = CASE @Language WHEN 'E' THEN  'Wrong username/nickname or password.' 
				 ELSE [dbo].[f_Get_MsgNamebyMsgID](80001,@Language)
				 END ,@ErrCode= case when @failedcount > 5 then 109 else 106 end
	  return  
	 END  
	  
	-- Successful  
	SELECT @Currency = Currency, @CurrencyId = @db_currency FROM exchange with (nolock) WHERE exchangeid = @db_currency  

	SELECT @isCasinoDisabled = isnull(@isCasinoDisabled,1)
	SELECT @IsCasinoSync = isnull(@IsCasinoSync,0)


	if @RoleID = 2  
	 select @MasterUsername = lower(username) from customer (nolock) where custid = (select mrecommend from customer (nolock) where custid = @CustID)  
	else if @RoleID = 3  
	 select @MasterUsername = lower(@UserName)  
	else if @RoleID = 4  
	 select @MasterUsername = null  
	  
	  
	UPDATE customer with (rowlock, updlock)  
	SET logincount = 0, iplogin = case when @db_loginip<>'' then @inputLoginIP else '' end, lastlogged = CURRENT_TIMESTAMP 
	WHERE custid = @db_custid  
	  
	-- Don't write log for AdminLogin
	if (@AdminUsername <> '' or @AdminUsername is not null)
	BEGIN
		RETURN
	END
	  
	SELECT @LogData =  @role + @UserName + ' - ' + 'Login Result: Success'  
	----------------------------------
	--**Output LoginIP to check the first login**
	SELECT @LoginIP=isnull(@db_loginip, '')

	SELECT	@isFirstLogin	= ISNULL(isFirstLogin ,0),
			@SecurityCode	= ISNULL(SecurityCode,''),
			@isForcedChangeSecurityCode	= ISNULL(isForcedChangeSecurityCode,0)
	FROM	CustLoginInfo WITH (NOLOCK)
	WHERE	CustID = @CustID

	SELECT	@PwdExpiry	= PwdExpiry
	FROM	Customer WITH (NOLOCK)
	WHERE	CustID = @CustID

	---------------------------  
	-- ***Check Sub-Account***  
	--IF @SubAccID > 0 
	--BEGIN
	--	SET @LogData = 'Sub-Account:' +  COALESCE(CAST(dbo.f_GetSubUsername(@SubAccID) AS VARCHAR(30)),SPACE(1))  + ' - ' + 'Login Result: Success'
	--END

	---------------------------  
	SET	@End = GETDATE() 
	SET @Duration = DATEDIFF(millisecond , @Begin, @End)
	IF @IsNickname =1 
	BEGIN
		EXEC dbo.Acc_WriteLog_UserLog_Login_Wrapper
			@UserID = @CustID, 
			@RoleID = @RoleID, 
			@SubAccID = @SubAccID,
			@ServerID = @ServerID,
			@LoginIP = @inputLoginIP,
			@DomainName = @LoginDomain,	
			@ActionID = 1310,	 
			@Doing = @LogData,
			@BrowserName = @BrowserName,
			@Platform = @Platform ,
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
			@ActionID = 1310,	 
			@Doing = @LogData,
			@BrowserName = @BrowserName,
			@Platform = @Platform ,
			@CountryCode = @CountryCode,
			@Duration = @Duration			
	END	
END
GO