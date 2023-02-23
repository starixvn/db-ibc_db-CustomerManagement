/*<info serverAlias="DBCUST-CUSTDB" executers="bodbDownlineNet, bodbDownlineNetView" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_LoginClaimDownline]  
    @CustID INT = 0,
    @UserPwd VARCHAR(50),
	@LoginIP VARCHAR(20)='' OUTPUT,  --- if output=NULL then account is the first login
	@ServerID INT = 0 OUTPUT,
	@LoginDomain NVARCHAR(253) = NULL,
	@BrowserName NVARCHAR(255) = NULL,
	@Platform NVARCHAR(255) = NULL,  
	@CountryCode VARCHAR(64) = NULL,
	@RoleID INT OUTPUT,  
	@Currency VARCHAR(10) = '' OUTPUT,  
	@CurrencyId INT = 0 OUTPUT,
	@MasterUsername VARCHAR(30) = '' OUTPUT,  
	@UserName VARCHAR(30) = '' OUTPUT,    
	@SubAccID INT = 0, --Sub-AccountID,  
	@SubPageAccess VARCHAR(50) = '' OUTPUT,   
	@SubUserName VARCHAR(30) = '' OUTPUT,   
	@site VARCHAR(20) = '' OUTPUT,  
	
	@LoginTime DATETIME = null, --VARCHAR(50) = NULL,
	@Language VARCHAR(2) = 'E',  
	@isFirstLogin	BIT = 0 OUTPUT,
	@PwdExpiry		DATETIME = NULL OUTPUT,
	@ErrCode INT = 0 OUTPUT,  
	@ErrMsg NVARCHAR(4000) = '' OUTPUT,
	@IsNickname BIT = 0 OUTPUT,
	@NicknameLoginOnly BIT = 0 OUTPUT,
	@Nickname VARCHAR(50) = '' OUTPUT,
	@SecurityCode VARCHAR(50) = '' OUTPUT,
	@isForcedChangeSecurityCode BIT = 0 OUTPUT,
	@IsProtectedMode BIT = 0 OUTPUT

	@LanguageUsage  VARCHAR(2) = '' OUTPUT
AS
/*
	Created: 20090903@Don
	Task : check if customer's ID existed or not
	DB: DBCUST/CustDB

	Revisions:
		- 20100101@Kiwi: Modify Log.
		- 20100510@Lee: Add verifying @UserPwd
		- 20100529@Lee: Fix bug @@ROWCOUNT
		- 20101006@Kaden; Add 4 parameter (DomainName, BrowserName, Platform, CountryCode). Save more detail user info 
		- 20101015@Jamie: Get DisableBingo, and SyncBingo 
		- 20101022@Johnson: Record execution time
		- 20110608@Sophia: Log in using Nickname, add parameter @IsNickname, @NicknameLoginOnly, @Nickname
		- 20110715@Sophia: add prefix 'Agency$' to username2
		- 20110722@Sophia: Do not Use Prefix 'Agency$' for username2
		- 20111007@Jamie: Duration between first login and sencond login is less than 5 seconds that considered Failed Login 
		- 20120427@Jamie: Increase the session life time to 10s instead of 5s  
		- 20121128@Elodie: Get an error message from f_Get_MsgNameByMsgID function by language
		- 20130123@Elodie: Change link server DB03 to DBONUSER
						   Write more log on DBTXN server in case of DBLOG server failure
		- 20130409@Johnson: Get more fields isForcedChangeSecurityCode and SecurityCode
		- 20161102@Helen: Apply Service Broker for Writing Log - [Redmine: 65806] 
		- 20190221@Johnson: Add role = 0 for tier0 for cn88 [redmine: #105660]
		- 20190422@Elodie: Offer unique nickname for CN88 [Redmine: 112287]
		- 20190906@Eden: 3rd party products - Remove InActive Products Phase 2 [Redmine: #118699]
		- 20210510@Eden: Enhancement for not relying on DB On_User [redmine: #154507]
		- 20210824@Elodie: Implement Protection Code [Redmine: #160151]
		- 20220110@Eden: Saba Casino use DCS Setting [RedmineID: #164280]
		- 20220110@Eden: HotFix - Alpha login_After login success log of sub account is not shown if sub's password <> main's password [RedmineID: #181370]
		- 20230214@Helios: Enhance language part [RedmineID: #183700]

	Param's Explanation:
		• @IsNickname: is use Nickname or not, parameter Input also Output
		• @Nickname: parameter Input also Output
*/
BEGIN

	SET NOCOUNT ON

	DECLARE @Begin DATETIME, @End DATETIME, @Duration INT, @inputLoginIP VARCHAR(15)
	DECLARE @LogData NVARCHAR(200), @role NVARCHAR(20), @db_currency TINYINT, @db_loginip NVARCHAR(20), @rowcount INT, 
		@db_userpwd NVARCHAR(50), @db_ProtectionCode VARCHAR(30), @ActionID INT
    
	SET @Begin = GETDATE() 
	SELECT @inputLoginIP = @LoginIP 	
	
	----- begin 20110608: login using Nickname
	SET @ServerID = 0 

	SELECT @RoleID = RoleID, @db_userpwd = UserPwd
	FROM customer c WITH (NOLOCK) 
	WHERE CustID = @CustID

	IF @SubAccID <=0
	BEGIN
		IF @RoleID = 2  
			SELECT @NicknameLoginOnly = NicknameLoginOnly FROM CustAgent WITH (NOLOCK) WHERE CustID = @CustID   
		ELSE IF @RoleID = 3  
			SELECT @NicknameLoginOnly = NicknameLoginOnly FROM CustMaster WITH (NOLOCK) WHERE CustID = @CustID  
		ELSE IF @RoleID = 4  
			SELECT @NicknameLoginOnly = NicknameLoginOnly FROM CustSuper WITH (NOLOCK) WHERE CustID = @CustID 

		SELECT @db_ProtectionCode = cl.ProtectionCode FROM CustLoginInfo cl WITH (NOLOCK) WHERE custid = @CustID
	END
	ELSE
	BEGIN
		SELECT @NicknameLoginOnly = NicknameLoginOnly FROM dbo.custSub WITH (NOLOCK) WHERE subaccid = @SubAccID  
		SELECT @db_ProtectionCode = cl.ProtectionCode FROM CustLoginInfoSub cl WITH (NOLOCK) WHERE subaccid = @SubAccID  
	END

	IF @NicknameLoginOnly = 1 AND @IsNickname = 0
	BEGIN  
		SELECT @LogData = '[After Login] Login Result:Failed!'  
				 
		SET @End = GETDATE() 
		SET @Duration = DATEDIFF(millisecond,@Begin,@End)
					
		EXEC dbo.Acc_WriteLog_UserLog_Login_Wrapper
			@UserID = @CustID, 
			@RoleID = @RoleID, 
			@SubAccID = @SubAccID,
			@ServerID = @ServerID,
			@LoginIP = @inputLoginIP,
			@DomainName = @LoginDomain,
			@ActionID = 1303,
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
	-------end 20110608: login using Nickname	 

	IF ISDATE(@LoginTime) = 0 OR DATEDIFF(SECOND, @LoginTime, CURRENT_TIMESTAMP) > 10
	BEGIN
		SELECT @LogData = '[After Login] Result:Failed(Session_Expired)'
		-- ***Check Sub-Account***  
		IF @SubAccID > 0 
		BEGIN
			SET @LogData = 'SubAccount:' +  COALESCE(CAST(dbo.f_GetSubUsername(@SubAccID) AS VARCHAR(30)),SPACE(1)) + ' - ' + @LogData
		END

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
				@ActionID = 1303,
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
				@ActionID = 1303,
				@Doing = @LogData,
				@BrowserName = @BrowserName,
				@Platform = @Platform,
				@CountryCode = @CountryCode,
				@Duration = @Duration
			
		END	

		SELECT @ErrMsg = CASE @Language WHEN 'E' THEN 'Login error! Session expired.'  
				ELSE [dbo].[f_Get_MsgNamebyMsgID](80005,@Language) END , @ErrCode=105    

		RETURN    
	END
		
	IF @SubAccID > 0
	BEGIN
		SELECT 
			@SubUserName = username, 
			@CustID = cs.custid,			 
			@SubPageAccess = PageAccess,
			@db_userpwd = cs.userpwd
		FROM custSub cs WITH (NOLOCK)
			INNER JOIN CustLoginInfoSub cl WITH (NOLOCK) ON cs.custid = cl.CustID AND cs.subaccid = cl.SubAccID
		WHERE cs.subaccid = @SubAccID AND (userpwd = @UserPwd OR cl.ProtectionCode = @UserPwd)

		IF @@ROWCOUNT = 0  
		BEGIN
			SELECT @LogData = 'Sub-account Login' + ',[After Login] Result:Failed(User_Not_Found)'      
			EXEC dbo.Acc_WriteLog_UserLog_Login_Wrapper
				@UserID = 0, 
				@RoleID = @RoleID, 
				@SubAccID = @SubAccID,
				@ServerID = @ServerID,
				@LoginIP = @inputLoginIP,
				@DomainName = @LoginDomain,
				@ActionID = 1303,
				@Doing = @LogData,
				@BrowserName = @BrowserName,
				@Platform = @Platform,
				@CountryCode = @CountryCode
								
			SELECT @ErrMsg = CASE @Language WHEN 'E' THEN  'Wrong username/nickname or password.' 
						ELSE [dbo].[f_Get_MsgNamebyMsgID](80001,@Language)   
						END ,@ErrCode=106   
			RETURN    
		END
	END
		
	SELECT 
		@RoleID = roleid, 
		@db_currency = currency, 
		@site = site , 
		@db_loginip= ISNULL(iplogin, ''), 
		@UserName = username
	FROM 
		customer c WITH (NOLOCK)
			INNER JOIN CustLoginInfo cl WITH (NOLOCK) ON c.custid = cl.custid 
	WHERE 
		c.custid = @CustID AND ((@SubAccID = 0 AND (userpwd = @UserPwd OR cl.ProtectionCode = @UserPwd)) OR @SubAccID <> 0)

	SET @rowcount = @@ROWCOUNT

	SELECT @ServerID = CASE WHEN @roleid=2 THEN 90 WHEN @roleid=3 THEN 91 WHEN @roleid = 4 THEN 92 ELSE 93 END -- login from web

	-- user not found  
	IF @rowcount = 0  
	BEGIN  
		SELECT @LogData = '[After Login]Result:Failed(User_Not_Found)' 
		
		IF @IsNickname = 1 
		BEGIN
			EXEC dbo.Acc_WriteLog_UserLog_Login_Wrapper
				@UserID = @CustID, 
				@RoleID = @RoleID, 
				@SubAccID = @SubAccID,
				@ServerID = @ServerID,
				@LoginIP = @inputLoginIP,
				@DomainName = @LoginDomain,
				@ActionID = 1303,
				@Doing = @LogData,
				@BrowserName = @BrowserName,
				@Platform = @Platform,
				@CountryCode = @CountryCode,
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
				@ActionID = 1303,
				@Doing = @LogData,
				@BrowserName = @BrowserName,
				@Platform = @Platform,
				@CountryCode = @CountryCode				
		END	
		SELECT @ErrMsg = CASE @Language WHEN 'E' THEN  'Wrong username/nickname or password.' 
					ELSE [dbo].[f_Get_MsgNamebyMsgID](80001,@Language)  
					END ,@ErrCode=106  
		RETURN  
	END 

	SELECT @role = CASE @RoleID WHEN 0 THEN 'Headline:'
						WHEN 1 THEN 'Customer:' 
						WHEN 2 THEN 'Agent:' 
						WHEN 3 THEN 'Master:' 
						WHEN 4 THEN 'Super:' 
					ELSE 'Unknown:' END  
	  
	-- Successful  
	SELECT 
		@Currency = Currency, 
		@CurrencyId = @db_currency 
	FROM 
		exchange WITH (NOLOCK) 
	WHERE exchangeid = @db_currency  

	IF @RoleID = 2  
		SELECT @MasterUsername = LOWER(username) FROM customer (NOLOCK) WHERE custid = (SELECT mrecommend FROM customer (NOLOCK) WHERE custid = @CustID)  
	ELSE IF @RoleID = 3  
		SELECT @MasterUsername = LOWER(@UserName)  
	ELSE IF @RoleID = 4  
		SELECT @MasterUsername = NULL  

/*
	GET ON_USER_AGENT INFO - CHECK (SECOND LOGIN) - (FIRST LOGIN) < 5 RETURN 
*/
	DECLARE	@1stLoginTime DATETIME

	EXEC Age_OnUser_Agent_LoginTime_Sel_Wrapper @CustID = @CustID, @SubAccID = @SubAccID, @LoginTime = @1stLoginTime OUTPUT
		
	IF DATEDIFF(SECOND, @1stLoginTime, CURRENT_TIMESTAMP)< 5
	BEGIN 		
		SELECT @LogData =  @role + @UserName + '[After Login] Result:Failed(Unknown_Login)'	
			
		EXEC dbo.Acc_WriteLog_UserLog_Login_Wrapper
			@UserID = @CustID, 
			@RoleID = @RoleID, 
			@SubAccID = @SubAccID,
			@ServerID = @ServerID,
			@LoginIP = @inputLoginIP,
			@DomainName = @LoginDomain,	
			@ActionID = 1303,
			@Doing = @LogData,
			@BrowserName = @BrowserName,
			@Platform = @Platform,
			@CountryCode = @CountryCode,
			@Duration = @Duration
			
		SELECT @ErrMsg = CASE @Language WHEN 'E' THEN 'Login error! Session expired.'  
				ELSE [dbo].[f_Get_MsgNamebyMsgID](80005,@Language)
			END , @ErrCode=107    
		RETURN
	END 
		
	SELECT @LogData =  @role + @UserName + ' [After Login] Result:Success'  

	----------------------------------
	--**Output LoginIP to check the first login**
	SELECT @LoginIP=ISNULL(@db_loginip, '')

	IF @SubAccID > 0 
	BEGIN
		SELECT	 @isFirstLogin	= ISNULL(isFirstLogin,0)
				,@PwdExpiry		= PwdExpiry
				,@securitycode	= ISNULL(SecurityCode,'')
				,@isForcedChangeSecurityCode = ISNULL(isForcedChangeSecurityCode,0)
				,@LanguageUsage = CASE WHEN ISNULL(LanguageUsage , '') = '' THEN '' ELSE LanguageUsage END -- LanguageUsage in CustLoginInfoSub Is Exists or Not 
		FROM	CustLoginInfoSub WITH (NOLOCK)
		WHERE	SubAccID = @SubAccID AND CustID = @CustID

		SELECT	@IsProtectedMode = ISNULL(IsProtectedMode, 0)
		FROM	CustLoginInfo WITH (NOLOCK)
		WHERE	CustID = @CustID
	END
	ELSE 
	BEGIN
		SELECT	@isFirstLogin	= ISNULL(isFirstLogin,0),
				@securityCode	= ISNULL(SecurityCode,''),
				@isForcedChangeSecurityCode = ISNULL(isForcedChangeSecurityCode,0),
				@IsProtectedMode = ISNULL(IsProtectedMode, 0),
				@LanguageUsage = CASE WHEN ISNULL(LanguageUsage , '') = '' THEN '' ELSE LanguageUsage END -- LanguageUsage in CustLoginInfo Is Exists or Not
		FROM	CustLoginInfo WITH (NOLOCK)
		WHERE	CustID = @CustID
		
		SELECT	@PwdExpiry	= PwdExpiry
		FROM	Customer WITH (NOLOCK)
		WHERE	CustID = @CustID
	END

	-- ***Check Sub-Account***  
	IF @SubAccID > 0 
	BEGIN
		SET @LogData = 'Sub-account:' +  COALESCE(CAST(dbo.f_GetSubUsername(@SubAccID) AS VARCHAR(30)),SPACE(1)) + ' - ' + ' [After Login] Result:Success' 
	END

	SET @End = GETDATE()
	SET @Duration = DATEDIFF(millisecond,@Begin,@End)
	IF @db_ProtectionCode = @UserPwd 
		SELECT @ActionID = 1341
	ELSE IF @db_userpwd = @UserPwd
		SELECT @ActionID = 1303
	--------------------------- 
	IF @IsNickname =1
	BEGIN
		EXEC dbo.Acc_WriteLog_UserLog_Login_Wrapper
			@UserID = @CustID, 
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
			@UserID = @CustID, 
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
GO