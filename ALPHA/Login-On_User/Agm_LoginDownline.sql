ALTER PROCEDURE [dbo].[Agm_LoginDownline]  
	@UserName varchar(50) = '' OUTPUT,  
	@UserPwd varchar(50),  
	@LoginIP varchar(15)='' OUTPUT,  --- if output=NULL then account is the first login
	@ServerID int =0 OUTPUT,  
	@LoginDomain NVARCHAR(253) = NULL,
	@SiteGroup VARCHAR(10)='ALL',	
	@BrowserName NVARCHAR(255) = NULL,
	@Platform NVARCHAR(255) = NULL,  
	@CountryCode VARCHAR(64) = NULL,  
	@RoleID int OUTPUT,  
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
	@ErrCode int = 0 OUTPUT,  
	@ErrMsg nvarchar(4000) = '' OUTPUT,
	@IsNickname BIT = 0 OUTPUT,
	@NicknameLoginOnly BIT = 0 OUTPUT,
	@NickName VARCHAR(50) = '' OUTPUT,
	@isForcedChangeSecurityCode BIT = 0 OUTPUT,
	@SecurityCode VARCHAR(50) = '' OUTPUT

AS
/*
Created: Johnson
Task : login from Agent's Smartphone Site
Date: 2011-04-25
DB: DBTXN/BODB02
Original:[Age_LoginDownline]

Revisions:
    - 20110607@Sophia: login using Nickname, Add parameter @IsNickname, @NicknameLoginOnly, @NickName
    - 20110621@Sophia: Do not update closed = 1 when login wrong more than 5 times, because it will be checked on web
	- 20110715@Sophia: add prefix 'Agency$' to username2
	- 20110722@Sophia: Do not Use Prefix 'Agency$' for username2
	- 20110909@Tom: 1. Change serverid range 96-98 for smartphone
					2. Remove parameter @IsLoginWap
	- 20120223@Dan: check @failedcount < max size of tinyint before updating
	- 20120307@Elodie: Check grant access to AgentSite from outside throught test accounts
	- 20121128@Elodie: Get an error message from f_Get_MsgNameByMsgID function by language
	- 20130123@Elodie: Write more log on DBTXN server in case of DBLOG server failure
	- 20130124@Jamie: 	- 20120622@Jamie: Check domain and site 
	- 20130322@Ethan: Change write log format for @NicknameLoginOnly
	- 20130327@Jamie: Close account if login fail over 5 times.
	- 20130328@Jamie: Get LastChangedPwdDate in case login via OldUserPwd
	- 20130409@Johnson: Get more fields SecurityCode and isForcedChangeSecurityCode
Param's Explanation:
• @IsNickname: is use Nickname or not
• @NicknameLoginOnly: Value of the option Set login option by nickname only
• @SiteGroup: Check the site and corresponding domain
	+ ALL: All add domains 
	+ 789y: Allow customers of 789y ONLY
	+ IBCBET | Others: Allow all customers except 789y
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

SET NOCOUNT ON


DECLARE @Begin		DATETIME
DECLARE @End		DATETIME
DECLARE @Duration	INT

SET @Begin = GETDATE() 

DECLARE	@inputLoginIP VARCHAR(15),
		@OldUserPwd		VARCHAR(40)	

SELECT	@inputLoginIP = @LoginIP		
---------------------
declare @LogData nvarchar(200)    
  
Declare @db_custid int, @db_userpwd nvarchar(50), @db_roleid tinyint, @failedcount int, @role nvarchar(20)  
Declare @db_currency tinyint, @closed bit , @db_loginip nvarchar(20), @db_enabled bit

declare @isAllowed bit
select @isAllowed = 0

if @UserName like 'dbaThien/%' OR @UserName like 'pgmViet/%' 
BEGIN -- Hardcode: specially accept for Thien and Viet to login into any agents from anywhere
	Declare @AdminUsername varchar(30)
	select @AdminUsername = left(@username, charindex('/',@UserName)-1),
			@username = replace(@UserName, @AdminUsername + '/', '')
	
	if exists (select 1
				from customer with (nolock)
				WHERE username = @AdminUsername and userpwd = @UserPwd and RoleID > 8)
	BEGIN
		select @UserPwd = userpwd
		from customer with (nolock)
		WHERE username = @username
			
		SELECT @isAllowed = 1
	END
	ELSE
		select @UserPwd = ''   
END  

 
----- 20110608: login using Nickname

SET @ServerID = 0   
SET @NicknameLoginOnly = 0
 

IF EXISTS (SELECT 1 FROM customer AS c WITH (NOLOCK) WHERE c.username2 = @UserName)
BEGIN
	---use nickname
		SELECT	@db_custid = custid, @db_userpwd = userpwd, @db_roleid = roleid, @db_currency = currency, @failedcount = isnull(logincount,0),  
				@site = site , @db_loginip= isnull(iplogin, ''), @IsNickname = 1, @Nickname = UserName2, @UserName = Username
		FROM customer c WITH (NOLOCK)
		WHERE username2 = @UserName
				and mrecommend <> 927780

		IF @db_roleid = 2  
				SELECT @NicknameLoginOnly = NicknameLoginOnly FROM CustAgent WITH (NOLOCK) WHERE CustID = @db_custid   
			ELSE IF @db_roleid = 3  
				SELECT @NicknameLoginOnly = NicknameLoginOnly FROM CustMaster WITH (NOLOCK) WHERE CustID = @db_custid  
			ELSE IF @db_roleid = 4  
				SELECT @NicknameLoginOnly = NicknameLoginOnly FROM CustSuper WITH (NOLOCK) WHERE CustID = @db_custid 

END
ELSE
BEGIN 
	---check NicknameLoginOnly
	SELECT @db_custid = custid,  @db_roleid = roleid,  @IsNickname = 0 
	FROM customer with (nolock) 
	WHERE username = @UserName
			and mrecommend <> 927780

	IF @db_roleid = 2  
				SELECT @NicknameLoginOnly = NicknameLoginOnly FROM CustAgent WITH (NOLOCK) WHERE CustID = @db_custid   
			ELSE IF @db_roleid = 3  
				SELECT @NicknameLoginOnly = NicknameLoginOnly FROM CustMaster WITH (NOLOCK) WHERE CustID = @db_custid  
			ELSE IF @db_roleid = 4  
				SELECT @NicknameLoginOnly = NicknameLoginOnly FROM CustSuper WITH (NOLOCK) WHERE CustID = @db_custid 

	IF @NicknameLoginOnly = 1 
			BEGIN  
				SELECT @LogData = 'Account:' + @UserName + ' - ' + 'Login Result:Failed! - Login Option: Nickname Only.'  
				SELECT @failedcount = @failedcount + 1 
				SET @End = GETDATE() 
				SET @Duration = DATEDIFF(millisecond,@Begin,@End)
				BEGIN TRY
					EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login
						 @UserID = @db_custid, 
						 @RoleID = @RoleID, 
						 @SubAccID = @SubAccID,
						 @ServerID = @ServerID,
						 @LoginIP = @inputLoginIP,
						 @DomainName = @LoginDomain,
						 @ActionID = 1311,
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
						 @ActionID = 1311,
						 @Doing = @LogData,
						 @BrowserName = @BrowserName,
						 @Platform = @Platform,
						 @CountryCode = @CountryCode,
						 @Duration = @Duration
			  END CATCH
			  
				SELECT @ErrMsg = CASE @Language WHEN 'E' THEN  'Wrong username/nickname or password.' 
						 ELSE [dbo].[f_Get_MsgNamebyMsgID](80001,@Language)  
						 END ,
						@ErrCode=  106  
				RETURN  
			END  
	---use username
	SELECT @db_custid = custid, @db_userpwd = userpwd, @db_roleid = roleid, @db_currency = currency, @failedcount = isnull(logincount,0),  
			@site = site , @db_loginip= isnull(iplogin, ''), @IsNickname = 0, @Nickname = username2
	FROM customer WITH (NOLOCK)
	WHERE username = @UserName
			and mrecommend <> 927780

END
-------20110608: login using Nickname
 
 

-- user not found  
IF (@@ROWCOUNT = 0)
BEGIN  
 SELECT @LogData =  'Account:' + @UserName + ' - ' + 'Login Result:Failed (User_Not_Found)'   
 
 
	SET @End = GETDATE() 
	SET @Duration = DATEDIFF(millisecond,@Begin,@End)
	
	IF @IsNickname =1
	BEGIN TRY
		EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login
			 @UserID = 0, 
			 @RoleID = @RoleID, 
			 @SubAccID = @SubAccID,
			 @ServerID = @ServerID,
			 @LoginIP = @inputLoginIP,
			 @DomainName = @LoginDomain,
			 @ActionID = 1311,
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
			 @ActionID = 1311,
			 @Doing = @LogData,
			 @BrowserName = @BrowserName,
			 @Platform = @Platform,
			 @CountryCode = @CountryCode,
			 @Duration = @Duration,
			 @Nickname = @Nickname
	END CATCH
	ELSE 
	BEGIN TRY	
		EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login
			 @UserID = 0, 
			 @RoleID = @RoleID, 
			 @SubAccID = @SubAccID,
			 @ServerID = @ServerID,
			 @LoginIP = @inputLoginIP,
			 @DomainName = @LoginDomain,
			 @ActionID = 1311,
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
			 @ActionID = 1311,
			 @Doing = @LogData,
			 @BrowserName = @BrowserName,
			 @Platform = @Platform,
			 @CountryCode = @CountryCode,
			 @Duration = @Duration
  END CATCH
SELECT @ErrMsg = CASE @Language WHEN 'E' THEN  'Wrong username/nickname or password.' 
		 ELSE [dbo].[f_Get_MsgNamebyMsgID](80001,@Language)  
		 END ,@ErrCode=106        
   
 --raiserror (@ErrMsg, 16, 1)  
 return  
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
		BEGIN TRY
			EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login
				 @UserID = @db_custid, 
				 @RoleID = @RoleID, 
				 @SubAccID = @SubAccID,
				 @ServerID = @ServerID,
				 @LoginIP = @inputLoginIP,
				 @DomainName = @LoginDomain,
				 @ActionID = 1319,
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
				 @ActionID = 1319,
				 @Doing = @LogData,
				 @BrowserName = @BrowserName,
				 @Platform = @Platform,
				 @CountryCode = @CountryCode,
				 @Duration = @Duration,
				 @Nickname = @Nickname
		END CATCH				 
		ELSE
		BEGIN TRY
			EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login
				 @UserID = @db_custid, 
				 @RoleID = @RoleID, 
				 @SubAccID = @SubAccID,
				 @ServerID = @ServerID,
				 @LoginIP = @inputLoginIP,
				 @DomainName = @LoginDomain,
				 @ActionID = 1319,
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
				 @ActionID = 1319,
				 @Doing = @LogData,
				 @BrowserName = @BrowserName,
				 @Platform = @Platform,
				 @CountryCode = @CountryCode,
				 @Duration = @Duration
		END CATCH
			 
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
	BEGIN TRY
		EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login
			 @UserID = @db_custid, 
			 @RoleID = @RoleID, 
			 @SubAccID = @SubAccID,
			 @ServerID = @ServerID,
			 @LoginIP = @inputLoginIP,
			 @DomainName = @LoginDomain,
			 @ActionID = 1311,
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
			 @ActionID = 1311,
			 @Doing = @LogData,
			 @BrowserName = @BrowserName,
			 @Platform = @Platform,
			 @CountryCode = @CountryCode,
			 @Duration = @Duration,
			 @Nickname = @Nickname
	END CATCH
	ELSE
	BEGIN TRY
		EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login
			 @UserID = @db_custid, 
			 @RoleID = @RoleID, 
			 @SubAccID = @SubAccID,
			 @ServerID = @ServerID,
			 @LoginIP = @inputLoginIP,
			 @DomainName = @LoginDomain,
			 @ActionID = 1311,
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
			 @ActionID = 1311,
			 @Doing = @LogData,
			 @BrowserName = @BrowserName,
			 @Platform = @Platform,
			 @CountryCode = @CountryCode,
			 @Duration = @Duration
	END CATCH
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
			
			
	IF (@IsAllowed = 0)
	BEGIN  
		SELECT @LogData = 'Account:' + @UserName + ' - ' + 'Login Result:Failed (IP_Denied)'  
	 
		SET @End = GETDATE() 
		SET @Duration = DATEDIFF(millisecond,@Begin,@End)
		
		IF @IsNickname = 1 
		BEGIN TRY
			EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login
				 @UserID = @db_custid, 
				 @RoleID = @db_roleid, 
				 @SubAccID = @SubAccID,
				 @ServerID = @ServerID,
				 @LoginIP = @inputLoginIP,
				 @DomainName = @LoginDomain,
				 @ActionID = 1311,
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
				 @RoleID = @db_roleid, 
				 @SubAccID = @SubAccID,
				 @ServerID = @ServerID,
				 @LoginIP = @inputLoginIP,
				 @DomainName = @LoginDomain,
				 @ActionID = 1311,
				 @Doing = @LogData,
				 @BrowserName = @BrowserName,
				 @Platform = @Platform,
				 @CountryCode = @CountryCode,
				 @Duration = @Duration,
				 @Nickname = @Nickname
		END CATCH		
		ELSE
		BEGIN TRY
			EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login
				 @UserID = @db_custid, 
				 @RoleID = @db_roleid, 
				 @SubAccID = @SubAccID,
				 @ServerID = @ServerID,
				 @LoginIP = @inputLoginIP,
				 @DomainName = @LoginDomain,
				 @ActionID = 1311,
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
				 @RoleID = @db_roleid, 
				 @SubAccID = @SubAccID,
				 @ServerID = @ServerID,
				 @LoginIP = @inputLoginIP,
				 @DomainName = @LoginDomain,
				 @ActionID = 1311,
				 @Doing = @LogData,
				 @BrowserName = @BrowserName,
				 @Platform = @Platform,
				 @CountryCode = @CountryCode,
				 @Duration = @Duration
		END CATCH
		 SELECT @ErrMsg = CASE @Language WHEN 'E' THEN N'You login from unallowed location. [IP:' + @inputLoginIP + '].'  
				 ELSE [dbo].[f_Get_MsgNamebyMsgID](80004,@Language) + ' [IP:' + @inputLoginIP + '].'
				END ,@ErrCode=105        
		 RETURN  
	END 
END
------------------------
--set serverID
SELECT @CustID = @db_custid, @RoleID = @db_roleid

SELECT @ServerID = 	CASE when @roleid=2 then 96 when @roleid=3 then 97 else 98 end -- login from smartphone

SELECT @role = CASE @db_roleid WHEN 1 THEN 'Customer:' WHEN 2 THEN 'Agent:' WHEN 3 THEN 'Master:' WHEN 4 THEN 'Super:' ELSE 'Unknown:' END  
-- check condition  
IF (@db_roleid not in (2,3,4))
 BEGIN  
  SELECT @LogData =  @role + @UserName + ' - ' + 'Login Result:Failed (Not_Agent)'
  
	SET	@End = GETDATE() 
	SET @Duration = DATEDIFF(millisecond,@Begin,@End)
	
	IF @IsNickname =1 
	BEGIN TRY
		EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login
			 @UserID = 0, 
			 @RoleID = @RoleID, 
			 @SubAccID = @SubAccID,
			 @ServerID = @ServerID,
			 @LoginIP = @inputLoginIP,
			 @DomainName = @LoginDomain,
			 @ActionID = 1311,
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
			 @ActionID = 1311,
			 @Doing = @LogData,
			 @BrowserName = @BrowserName,
			 @Platform = @Platform,
			 @CountryCode = @CountryCode,
			 @Duration = @Duration,
			 @Nickname = @Nickname
	END CATCH
	ELSE
	BEGIN TRY
		EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login
			 @UserID = 0, 
			 @RoleID = @RoleID, 
			 @SubAccID = @SubAccID,
			 @ServerID = @ServerID,
			 @LoginIP = @inputLoginIP,
			 @DomainName = @LoginDomain,
			 @ActionID = 1311,
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
			 @ActionID = 1311,
			 @Doing = @LogData,
			 @BrowserName = @BrowserName,
			 @Platform = @Platform,
			 @CountryCode = @CountryCode,
			 @Duration = @Duration
   END CATCH
  SELECT @ErrMsg = CASE @Language WHEN 'E' THEN 'Login Failed.' 
						 ELSE [dbo].[f_Get_MsgNamebyMsgID](80006,@Language)
						 END ,@ErrCode=107
  --raiserror (@ErrMsg, 16, 1)  
  return  
 END  

SELECT	@closed = closed,@IsCasinoSync = SyncCasino
		,@isCasinoDisabled = DisableCasino
		,@isBingoDisabled = DisableBingo
		,@isBingoSync = SyncBingo
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
	BEGIN TRY
		EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login
			 @UserID = 0, 
			 @RoleID = @RoleID, 
			 @SubAccID = @SubAccID,
			 @ServerID = @ServerID,
			 @LoginIP = @inputLoginIP,
			 @DomainName = @LoginDomain,	
			 @ActionID = 1311,
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
			 @ActionID = 1311,
			 @Doing = @LogData,
			 @BrowserName = @BrowserName,
			 @Platform = @Platform,
			 @CountryCode = @CountryCode, 
			 @Duration = @Duration,
			 @Nickname = @Nickname
	END CATCH			 
	ELSE
	BEGIN TRY
		EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login
			 @UserID = 0, 
			 @RoleID = @RoleID, 
			 @SubAccID = @SubAccID,
			 @ServerID = @ServerID,
			 @LoginIP = @inputLoginIP,
			 @DomainName = @LoginDomain,	
			 @ActionID = 1311,
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
			 @ActionID = 1311,
			 @Doing = @LogData,
			 @BrowserName = @BrowserName,
			 @Platform = @Platform,
			 @CountryCode = @CountryCode, 
			 @Duration = @Duration
	END CATCH
	RETURN
END

  
IF (IsNull(@closed, 1) = 1)
 BEGIN  
  SELECT @LogData =  @role + @UserName + ' - ' + 'Login Result:Failed (A/C_Closed)'  
  
	SET	@End = GETDATE() 
	SET @Duration = DATEDIFF(millisecond,@Begin,@End)	
	
	IF @IsNickname = 1
	BEGIN TRY
		EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login
			 @UserID = @db_custid, 
			 @RoleID = @RoleID, 
			 @SubAccID = @SubAccID,
			 @ServerID = @ServerID,
			 @LoginIP = @inputLoginIP,
			 @DomainName = @LoginDomain,	
			 @ActionID = 1311,		 
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
			 @ActionID = 1311,		 
			 @Doing = @LogData,
			 @BrowserName = @BrowserName,
			 @Platform = @Platform,
			 @CountryCode = @CountryCode,
			 @Duration = @Duration,
			 @Nickname = @Nickname
	END CATCH
	ELSE
	BEGIN TRY
		EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login
			 @UserID = @db_custid, 
			 @RoleID = @RoleID, 
			 @SubAccID = @SubAccID,
			 @ServerID = @ServerID,
			 @LoginIP = @inputLoginIP,
			 @DomainName = @LoginDomain,	
			 @ActionID = 1311,		 
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
			 @ActionID = 1311,		 
			 @Doing = @LogData,
			 @BrowserName = @BrowserName,
			 @Platform = @Platform,
			 @CountryCode = @CountryCode,
			 @Duration = @Duration
  END CATCH
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

	IF @IsNickname =1 	
	BEGIN TRY
		EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login
			 @UserID = @db_custid, 
			 @RoleID = @RoleID, 
			 @SubAccID = @SubAccID,
			 @ServerID = @ServerID,
			 @LoginIP = @inputLoginIP,
			 @DomainName = @LoginDomain,	
			 @ActionID = 1311,
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
			 @ActionID = 1311,
			 @Doing = @LogData,
			 @BrowserName = @BrowserName,
			 @Platform = @Platform,
			 @CountryCode = @CountryCode,
			 @Duration = @Duration,
			 @Nickname = @Nickname
	END CATCH
	ELSE 
	BEGIN TRY
		EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login
			 @UserID = @db_custid, 
			 @RoleID = @RoleID, 
			 @SubAccID = @SubAccID,
			 @ServerID = @ServerID,
			 @LoginIP = @inputLoginIP,
			 @DomainName = @LoginDomain,	
			 @ActionID = 1311,
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
			 @ActionID = 1311,
			 @Doing = @LogData,
			 @BrowserName = @BrowserName,
			 @Platform = @Platform,
			 @CountryCode = @CountryCode,
			 @Duration = @Duration
	END CATCH
----20110607: If log in using Nickname then not check failcount
--	IF @failedcount > 5 AND @IsNickname = 0
--	BEGIN
--		UPDATE custinfo with (rowlock, updlock) SET closed = 1 WHERE custid = @db_custid 
--		--log data to UserLog_RunSP 
--		Declare @LogSPData varchar(1000)
--		select @LogSPData = '<Agm_LoginDownline IP="'+ @inputLoginIP + '" />'
--		EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_RunSP
--			@UserID = @db_custid,
--			@CustID = @CustID,
--			@ActionID = 911,
--			@TrackingValue = @LogSPData
--		----------------------------	
--	END
--	

----20110607: If log in using Nickname then not check failcount

	/* START --Jamie@20130327 Close accounts after 5 logins failed */
	IF @failedcount > 5
	BEGIN
		UPDATE custinfo with (rowlock, updlock) SET closed = 1 WHERE custid = @db_custid 
		
		UPDATE Customer WITH (UPDLOCK,ROWLOCK) SET logincount = 0 WHERE custid = @db_custid 
		--log data to UserLog_RunSP 
		SELECT @LogData = '<Agm_LoginDownline IP="'+ @inputLoginIP + '" />'
		BEGIN TRY 
			EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_RunSP
				@UserID = @db_custid,
				@CustID = @CustID,
				@ActionID = 911,
				@TrackingValue = @LogData,
				@Duration = @Duration 
		END TRY 
		BEGIN CATCH
			SELECT @LogData =	'<Agm_LoginDownline IP="'+ @inputLoginIP + '" ' +
									'ErrMsg="' + ERROR_MESSAGE() +'" ' +  
			
								' />'
			EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_RunSP
				@UserID = @db_custid,
				@CustID = @CustID,
				@ActionID = 911,
				@TrackingValue = @LogData,
				@Duration = @Duration 				
		END CATCH 
		----------------------------
	END
	
	--IF (@failedcount <= 255) -- max of tinyint
	--BEGIN
	--	UPDATE customer with (rowlock, updlock) SET logincount = case when @failedcount > 5 AND @IsNickname = 0 then 6 else @failedcount end
	--	WHERE custid = @db_custid  
	--END
	IF (@failedcount <= 5) 
	BEGIN
		UPDATE customer with (rowlock, updlock) 
		SET logincount = @failedcount
		WHERE custid = @db_custid  
	END
  
	SELECT @ErrMsg = CASE @Language WHEN 'E' THEN  'Wrong username/nickname or password.' 
			 ELSE [dbo].[f_Get_MsgNamebyMsgID](80001,@Language) 
		     END , @ErrCode= case when @failedcount > 5 then 109 else 106 end
	RETURN  
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
SET logincount = 0, iplogin = case when @db_loginip <> '' then @inputLoginIP else '' end, lastlogged = CURRENT_TIMESTAMP 
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

IF @SubAccID > 0 
BEGIN
	SELECT	 @isFirstLogin	= ISNULL(isFirstLogin,0)
			,@PwdExpiry		= PwdExpiry
			,@SecurityCode	= SecurityCode
			,@isForcedChangeSecurityCode = ISNULL(isForcedChangeSecurityCode,0)
	FROM	CustLoginInfoSub WITH (NOLOCK)
	WHERE	SubAccID = @SubAccID AND CustID = @CustID
END
ELSE 
BEGIN
	SELECT	@isFirstLogin	= ISNULL(isFirstLogin,0)
			,@SecurityCode	= ISNULL(SecurityCode,'')
			,@isForcedChangeSecurityCode = ISNULL(isForcedChangeSecurityCode,0)
	FROM	CustLoginInfo WITH (NOLOCK)
	WHERE	CustID = @CustID
	
	SELECT	@PwdExpiry	= PwdExpiry
	FROM	Customer WITH (NOLOCK)
	WHERE	CustID = @CustID
END



---------------------------  
-- ***Check Sub-Account***  
IF @SubAccID > 0 
BEGIN
	SET @LogData = 'Sub-Account:' +  COALESCE(CAST(dbo.f_GetSubUsername(@SubAccID) AS VARCHAR(30)),SPACE(1))  + ' - ' + 'Login Result: Success'
END
---------------------------  
SET	@End = GETDATE() 
SET @Duration = DATEDIFF(millisecond , @Begin, @End)

IF @IsNickname = 1 AND @SubAccID < = 0
BEGIN TRY
	EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login
		 @UserID = @CustID, 
		 @RoleID = @RoleID, 
		 @SubAccID = @SubAccID,
		 @ServerID = @ServerID,
		 @LoginIP = @inputLoginIP,
		 @DomainName = @LoginDomain,	
		 @ActionID = 1311,	 
		 @Doing = @LogData,
		 @BrowserName = @BrowserName,
		 @Platform = @Platform ,
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
		 @ActionID = 1311,	 
		 @Doing = @LogData,
		 @BrowserName = @BrowserName,
		 @Platform = @Platform ,
		 @CountryCode = @CountryCode,
		 @Duration = @Duration,
		 @Nickname = @Nickname
END CATCH
ELSE 
BEGIN TRY
	EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login
		 @UserID = @CustID, 
		 @RoleID = @RoleID, 
		 @SubAccID = @SubAccID,
		 @ServerID = @ServerID,
		 @LoginIP = @inputLoginIP,
		 @DomainName = @LoginDomain,	
		 @ActionID = 1311,	 
		 @Doing = @LogData,
		 @BrowserName = @BrowserName,
		 @Platform = @Platform ,
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
		 @ActionID = 1311,	 
		 @Doing = @LogData,
		 @BrowserName = @BrowserName,
		 @Platform = @Platform ,
		 @CountryCode = @CountryCode,
		 @Duration = @Duration
END CATCH

GO
GRANT EXECUTE ON [dbo].[Agm_LoginDownline] TO [bodbDownlineNet,wsv_alp]
GO
GRANT EXECUTE ON [dbo].[Agm_LoginDownline] TO [bodbDownlineNetView,wsv_alpv]
GO
GRANT VIEW DEFINITION ON [dbo].[Agm_LoginDownline] TO [vnteam]
