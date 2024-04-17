ALTER PROCEDURE [dbo].[Agm_LoginDownline_Sub]    
	@SubUserName varchar(50),    
	@UserPwd varchar(50),    
	@LoginIP varchar(20),    
	@ServerID int =0 OUTPUT,    
	@LoginDomain NVARCHAR(253) = NULL,
	@SiteGroup VARCHAR(10)='ALL',
	@BrowserName NVARCHAR(255) = NULL,
	@Platform NVARCHAR(255) = NULL,  
	@CountryCode VARCHAR(64) = NULL,
	@RoleID int OUTPUT,    
	@CustID int OUTPUT,    
	@On_UserID int OUTPUT,    
	@Currency varchar(10) = '' OUTPUT,    
	@CurrencyId int = 0 OUTPUT,
	@Language varchar(2) = 'E',    
	@MasterUsername varchar(50) = '' OUTPUT,    
	@SubAccID int = 0 OUTPUT,    
	@UserName varchar(50) OUTPUT,    
	@site varchar(20) = '' OUTPUT,    
	@SubPageAccess varchar(50) = '' OUTPUT,    
	@isCasinoDisabled bit = false OUTPUT,
	@IsCasinoSync bit = false OUTPUT,
	@isBingoDisabled bit = false OUTPUT,
	@IsBingoSync bit = false OUTPUT,
	@isFirstLogin	BIT =0 OUTPUT,
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
Created: 20110620@Sophia
Task : login sub-acc from agent's smartphone site
DB: DBTXN/BODB02
Original: Refer Age_LoginDownline

Revision:
	- 20110916@Jamie: Optimize code 
	- 20120223@Dan: check @failedcount < max size of tinyint before updating
	- 20120307@Elodie: Check grant access to AgentSite from outside throught test accounts
					   Correct ActionID = 1311 -> ActionID = 1313
	- 20121128@Elodie: Get an error message from f_Get_MsgNameByMsgID function by language
	- 20130123@Elodie: Write more log on DBTXN server in case of DBLOG server failure
	- 20130124@Jamie: Check domain and site 
	- 20130327@Jamie: Close account if login fail over 5 times.
	- 20130328@Jamie: Get LastChangedPwdDate in case login via OldUserPwd
	- 20130409@Johnson: Get more fields SecurityCode and isForcedChangeSecurityCode
Param's Explanation:
• @SiteGroup: Check the site and corresponding domain
	+ ALL: All add domains 
	+ 789y: Allow customers of 789y ONLY
	+ IBCBET | Others: Allow all customers except 789y
• @LastChangedPwdDate: If = NULL: Login current pass, <> NULL : Login old Pass 
• @ErrCode:
    = 0: Login successfully.
    > 0: Specific Error.
  
• @ErrMsg: Error description.
*/

  
SET NOCOUNT ON    

DECLARE	@Begin		DATETIME 
DECLARE @End		DATETIME
DECLARE @Duration	INT
Declare @AdminUsername varchar(30)
Declare @LogSPData varchar(1000)

SET @Begin = GETDATE()

declare @LogData nvarchar(200),
		@OldUserPwd	VARCHAR(40)   
-------------------------------------  
--Hard-code for AdminLogin
-------------------------------------  
if @UserName like 'dbaThien/%' OR @UserName like 'pgmViet/%' 
BEGIN

	select  @AdminUsername = left(@username, charindex('/',@UserName)-1),
			@SubUserName = replace(@UserName, @AdminUsername + '/', '')
	
	if exists (select 1
				from customer with (nolock)
				WHERE username = @AdminUsername and userpwd = @UserPwd and RoleID > 8)
	BEGIN
		select @UserPwd = userpwd FROM custSub (nolock) where username = @SubUserName

	END
	ELSE
		select @UserPwd = ''
   
END  
-------------------------------------   
   
Declare @db_userpwd varchar(40), @failedcount tinyint, @closed bit

SELECT @SubAccID = subaccid, @CustID = custid, @SubPageAccess = PageAccess,
		@db_userpwd = userpwd, @failedcount = isnull(logincount,0), @closed = closed 
FROM custSub (nolock) where username = @SubUserName

IF @@ROWCOUNT = 0  
BEGIN
	Select @LogData = 'Sub-account: ' + @SubUserName + ', login failed, password problem'    
	
	SET	@End = GETDATE() 
	SET @Duration = DATEDIFF(millisecond,@Begin,@End)
	BEGIN TRY
		EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login
			 @UserID = 0, 
			 @RoleID = @RoleID, 
			 @SubAccID = @SubAccID,
			 @ServerID = @ServerID,
			 @LoginIP = @LoginIP,
			 @DomainName = @LoginDomain,
			 @ActionID = 1313,
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
			 @LoginIP = @LoginIP,
			 @DomainName = @LoginDomain,
			 @ActionID = 1313,
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
 
IF IsNull(@Closed,1) = 1 
BEGIN    
	Select @LogData = 'Sub-account: ' + @SubUserName + ', login failed, Result:Failed(A/C_Closed)'    
	
	SET	@End = GETDATE() 
	SET @Duration = DATEDIFF(millisecond,@Begin,@End)	
	BEGIN TRY
		EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login
		 @UserID = @CustID, 
		 @RoleID = @RoleID, 
		 @SubAccID = @SubAccID,
		 @ServerID = @ServerID,
		 @LoginIP = @LoginIP,
		 @DomainName = @LoginDomain,
		 @ActionID = 1313,
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
		 @LoginIP = @LoginIP,
		 @DomainName = @LoginDomain,
		 @ActionID = 1313,
		 @Doing = @LogData,
		 @BrowserName = @BrowserName,
		 @Platform = @Platform,
		 @CountryCode = @CountryCode,
		 @Duration = @Duration  
	END CATCH
	select @ErrMsg = case @Language when 'E' then 'Account closed. Please contact your administrator!'  
        ELSE [dbo].[f_Get_MsgNamebyMsgID](80002,@Language)
       end ,@ErrCode=108    
	--raiserror (@ErrMsg, 16, 1)    
	return    
END
ELSE IF @db_userpwd <> @UserPWD
BEGIN
	SELECT	 @OldUserPwd			= ISNULL(OldUserPwd,'')
			,@LastChangedPwdDate	= LastChangedPwdDate
			,@PwdExpiry				= PwdExpiry
	FROM	CustLoginInfoSub WITH (NOLOCK)
	WHERE	SubAccID = @SubAccID AND CustID = @CustID
	
	IF	@UserPWD = @OldUserPwd	
		SELECT	@LastChangedPwdDate = @LastChangedPwdDate
	ELSE	SELECT	@LastChangedPwdDate = NULL 

	Select @LogData = 'Sub-account: ' + @SubUserName + ', login failed, password problem',
			@failedcount = @failedcount + 1 
	SET	@End = GETDATE() 	
	SET @Duration = DATEDIFF(millisecond,@Begin,@End)				
	BEGIN TRY
		EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login
		 @UserID = @CustID, 
		 @RoleID = @RoleID, 
		 @SubAccID = @SubAccID,
		 @ServerID = @ServerID,
		 @LoginIP = @LoginIP,
		 @DomainName = @LoginDomain,	
		 @ActionID = 1313,
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
		 @LoginIP = @LoginIP,
		 @DomainName = @LoginDomain,	
		 @ActionID = 1313,
		 @Doing = @LogData,
		 @BrowserName = @BrowserName,
		 @Platform = @Platform,
		 @CountryCode = @CountryCode,
		 @Duration = @Duration  
	END CATCH
	/* START --Jamie@20130327 Close accounts after 5 logins failed */
	IF @failedcount > 5
	BEGIN
		UPDATE custSub WITH (ROWLOCK, UPDLOCK) SET closed = 1, logincount = 0 WHERE subaccid = @subaccid 		
		SELECT	@LogData = '<Agm_LoginDownline_Sub IP="' + @LoginIP + '" ' + 
								'SubAccount="' + @SubUserName +'" ' +
							' />'
		BEGIN TRY 	
			EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_RunSP
				@UserID = @CustID,
				@CustID = @CustID,
				@ActionID = 912,
				@TrackingValue = @LogData,
				@Duration = @Duration
		END TRY 
		BEGIN CATCH
			SELECT @LogData = '<Agm_LoginDownline_Sub IP="'+ @LoginIP + '" ' +
									'SubAccount="' + @SubUserName +'" ' +
									'ErrMsg="' + ERROR_MESSAGE() +'" ' + 							
								' />'
			EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_RunSP
				@UserID = @CustID,
				@CustID = @CustID,
				@ActionID = 912,
				@TrackingValue = @LogData,
				@Duration = @Duration		
		
		END CATCH 		
	END 
	/* END -- Close accounts after 5 logins failed*/
 
	--IF (@failedcount <= 255) -- max of tinyint
	IF (@failedcount <= 5) 
	BEGIN
		UPDATE custSub with (rowlock, updlock) SET logincount = @failedcount WHERE subaccid = @subaccid 
	END
	
	SELECT @ErrMsg = CASE @Language WHEN 'E' THEN  'Wrong username/nickname or password.' 
			 ELSE [dbo].[f_Get_MsgNamebyMsgID](80001,@Language)   
			 END , @ErrCode= case when @failedcount > 5 then 109 else 106 end	
	RETURN 	

	--IF (@failedcount <= 255) -- max of tinyint
	--BEGIN
	--	UPDATE custSub with (rowlock, updlock) SET logincount = @failedcount WHERE subaccid = @subaccid 
	--END
	
	--SELECT @ErrMsg = CASE @Language WHEN 'E' THEN  'Wrong username/nickname or password.' 
	--	 ELSE [dbo].[f_Get_MsgNamebyMsgID](80001,@Language)
	--	 END , @ErrCode= case when @failedcount > 5 then 109 else 106 end	
	--return    
END    

UPDATE custSub with (rowlock, updlock) SET logincount = 0 WHERE subaccid = @subaccid 
 
/**
	Add the log under Agency 

**/ 

Declare @db_custid int,   @db_roleid tinyint,  @role nvarchar(20)  
Declare @db_currency tinyint , @db_loginip nvarchar(20), @db_enabled bit

declare @isAllowed bit
select @isAllowed = 0


SELECT	@db_custid = custid, @db_userpwd = userpwd, @db_roleid = roleid, 
		@username= username,
		@db_currency = currency, @failedcount = isnull(logincount,0),  
		@site = site , @db_loginip= isnull(iplogin, ''), @IsNickname = 0 , @Nickname = NULL, @NicknameLoginOnly = NULL
FROM	customer with (nolock) 
WHERE	custid = @custID 


---Check 789y OR IBCBET/Others 

IF @SiteGroup <>'ALL'  --IN ('789y','IBCBET','Others')
BEGIN
	EXEC dbo.Age_LoginCheckSiteGroup 
			@SiteGroup = @SiteGroup, 
			@Site = @Site,
			@isAllowed = @isAllowed OUTPUT

	IF @isAllowed = 0
	BEGIN
		SELECT  @LogData = 'Sub-account: ' + @SubUserName +' - ' + 'Login Result:Wrong domain (' + @Site + '/' + @LoginDomain + ')'
		SET	@End = GETDATE() 
		SET @Duration = DATEDIFF(millisecond,@Begin,@End)	
		BEGIN TRY
			EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login
				 @UserID = @db_custid, 
				 @RoleID = @db_roleid, 
				 @SubAccID = @SubAccID,
				 @ServerID = @ServerID,
				 @LoginIP = @LoginIP,
				 @DomainName = @LoginDomain,	
				 @ActionID = 1321,
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
				 @LoginIP = @LoginIP,
				 @DomainName = @LoginDomain,	
				 @ActionID = 1321,
				 @Doing = @LogData,
				 @BrowserName = @BrowserName,
				 @Platform = @Platform,
				 @CountryCode = @CountryCode,
				 @Duration = @Duration  
		END CATCH
			SELECT @ErrMsg = CASE @Language WHEN 'E' THEN  'Wrong username/nickname or password.' 
					 ELSE [dbo].[f_Get_MsgNamebyMsgID](80001,@Language)
					 END 
				  ,@ErrCode= 206 	
		RETURN  		
	END
END
--END check 789y OR IBCBET/Others

--Check grant access to AgentSite from outside throught test accounts
DECLARE @IsAccess BIT
SET @IsAccess = 1

EXEC Age_LoginCheckGrantAccess
	@CustID = @db_custid,
	@LoginIP = @LoginIP,
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
		 @LoginIP = @LoginIP,
		 @DomainName = @LoginDomain,
		 @ActionID = 1313,
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
		 @LoginIP = @LoginIP,
		 @DomainName = @LoginDomain,
		 @ActionID = 1313,
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
		 @LoginIP = @LoginIP,
		 @DomainName = @LoginDomain,
		 @ActionID = 1313,
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
		 @LoginIP = @LoginIP,
		 @DomainName = @LoginDomain,
		 @ActionID = 1313,
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
	IF @db_currency <> 20 AND LEFT(@LoginIP, 10) = '202.78.228'
		set @isAllowed = 0
						
	IF (@IsAllowed = 0)
	BEGIN  
		SELECT @LogData = 'Account:' + @UserName + ' - ' + 'Login Result:Failed (IP_Denied)'  
	 
		SET @End = GETDATE() 
		SET @Duration = DATEDIFF(millisecond,@Begin,@End)
		BEGIN TRY
			EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login
			 @UserID = @db_custid, 
			 @RoleID = @db_roleid, 
			 @SubAccID = @SubAccID,
			 @ServerID = @ServerID,
			 @LoginIP = @LoginIP,
			 @DomainName = @LoginDomain,
			 @ActionID = 1313,
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
			 @LoginIP = @LoginIP,
			 @DomainName = @LoginDomain,
			 @ActionID = 1313,
			 @Doing = @LogData,
			 @BrowserName = @BrowserName,
			 @Platform = @Platform,
			 @CountryCode = @CountryCode,
			 @Duration = @Duration
	  END CATCH
		 select @ErrMsg = case @Language when 'E' then N'You login from unallowed location. [IP:' + @LoginIP + '].'  
				 ELSE [dbo].[f_Get_MsgNamebyMsgID](80004,@Language) + ' [IP:' + @LoginIP + '].'  
				end ,@ErrCode=105       
		 RETURN  
	END 
END
------------------------

--set serverID
SELECT @CustID = @db_custid, @RoleID = @db_roleid
SELECT @ServerID = 	CASE WHEN @roleid=2 THEN 96 WHEN @roleid=3 THEN 97 ELSE 98 END -- login from smartphone
 

SELECT @role = CASE @db_roleid WHEN 1 THEN 'Customer:' WHEN 2 THEN 'Agent:' WHEN 3 THEN 'Master:' WHEN 4 THEN 'Super:' ELSE 'Unknown:' END  
 
SELECT	@closed = closed,@IsCasinoSync = SyncCasino
		,@isCasinoDisabled = DisableCasino
		,@isBingoDisabled = DisableBingo
		,@isBingoSync = SyncBingo
		,@db_enabled = isnull(enabled,0)
FROM custinfo with (nolock) WHERE custid = @db_custid

IF (@db_enabled <> 1)
BEGIN
	 SELECT @ErrMsg = case @Language when 'E' then 'This account was disabled!'  
			 ELSE [dbo].[f_Get_MsgNamebyMsgID](60020,@Language) 
			end ,@ErrCode=600    
	SELECT @LogData = 'Agent:' + @UserName + ' - ' + 'Login Result:Failed (User_Disabled)'  
	
	SET	@End = GETDATE() 
	SET @Duration = DATEDIFF(millisecond,@Begin,@End)	
	BEGIN TRY
		EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login
		 @UserID = 0, 
		 @RoleID = @RoleID, 
		 @SubAccID = @SubAccID,
		 @ServerID = @ServerID,
		 @LoginIP = @LoginIP,
		 @DomainName = @LoginDomain,	
		 @ActionID = 1313,
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
		 @LoginIP = @LoginIP,
		 @DomainName = @LoginDomain,	
		 @ActionID = 1313,
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
	BEGIN TRY
		EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login
		 @UserID = @db_custid, 
		 @RoleID = @RoleID, 
		 @SubAccID = @SubAccID,
		 @ServerID = @ServerID,
		 @LoginIP = @LoginIP,
		 @DomainName = @LoginDomain,	
		 @ActionID = 1313,		 
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
		 @LoginIP = @LoginIP,
		 @DomainName = @LoginDomain,	
		 @ActionID = 1313,		 
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

-- Successful  
SELECT @Currency = Currency, @CurrencyId = @db_currency FROM exchange with (nolock) WHERE exchangeid = @db_currency  

SELECT @isCasinoDisabled = isnull(@isCasinoDisabled,1)
SELECT @IsCasinoSync = isnull(@IsCasinoSync,0)

--if @RoleID = 2  
-- select @MasterUsername = lower(username) from customer (nolock) where custid = (select mrecommend from customer (nolock) where custid = @CustID)  
--else if @RoleID = 3  
-- select @MasterUsername = lower(@UserName)  
--else if @RoleID = 4  
-- select @MasterUsername = null  
  
SELECT @MasterUsername = NULL -- 20110916@Jamie: Temporarily hard-code, remove param later  

UPDATE customer with (rowlock, updlock)  
SET logincount = 0, iplogin = case when @db_loginip<>'' then @LoginIP else '' end, lastlogged = CURRENT_TIMESTAMP 
WHERE custid = @db_custid  
  
-- Don't write log for AdminLogin
if (@AdminUsername <> '' or @AdminUsername is not null)
BEGIN
	RETURN
END
 

----------------------------------
--**Output LoginIP to check the first login**
SELECT @LoginIP=isnull(@db_loginip, '')

SELECT	 @isFirstLogin	= ISNULL(isFirstLogin,0)
		,@PwdExpiry		= PwdExpiry
		,@SecurityCode	= ISNULL(SecurityCode,'')
		,@isForcedChangeSecurityCode	= ISNULL(isForcedChangeSecurityCode,0)
FROM	CustLoginInfoSub WITH (NOLOCK)
WHERE	SubAccID = @SubAccID AND CustID = @CustID

SET	@End = GETDATE() 
SET @Duration = DATEDIFF(millisecond , @Begin, @End)

SET @LogData = 'Sub-Account:' +  @SubUserName  + ' - ' + 'Login Result: Success'
BEGIN TRY
	EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login
	 @UserID = @CustID, 
	 @RoleID = @RoleID, 
	 @SubAccID = @SubAccID,
	 @ServerID = @ServerID,
	 @LoginIP = @LoginIP,
	 @DomainName = @LoginDomain,	
	 @ActionID = 1313,  
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
	 @LoginIP = @LoginIP,
	 @DomainName = @LoginDomain,	
	 @ActionID = 1313,  
	 @Doing = @LogData,
	 @BrowserName = @BrowserName,
	 @Platform = @Platform ,
	 @CountryCode = @CountryCode,
	 @Duration = @Duration
END CATCH


GO
GRANT EXECUTE ON [dbo].[Agm_LoginDownline_Sub] TO [wsv_alp]
GO
GRANT EXECUTE ON [dbo].[Agm_LoginDownline_Sub] TO [wsv_alpv]
GO
GRANT VIEW DEFINITION ON [dbo].[Agm_LoginDownline_Sub] TO [vnteam]