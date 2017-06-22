
ALTER PROCEDURE [dbo].[Age_LoginDownline]  
	@UserName varchar(50),  
	@UserPwd varchar(50),  
	@LoginIP varchar(20)='' OUTPUT,  --- if output=NULL then account is the first login
	@ServerID int =0 OUTPUT,  
	@RoleID int OUTPUT,  
	@CustID int OUTPUT,  
	@Currency varchar(10) = '' OUTPUT,  
	@CurrencyId int = 0 OUTPUT,
	@Language varchar(2) = 'E',  
	@MasterUsername varchar(50) = '' OUTPUT,  
	@SubAccID int = 0, --Sub-AccountID,  
	@site varchar(20) = '' OUTPUT,  
	@isWapLogin bit = false,
	@isCasinoDisabled bit = false OUTPUT,
	@IsCasinoSync bit = false OUTPUT,
	@ErrCode int = 0 OUTPUT,  
	@ErrMsg nvarchar(4000) = '' OUTPUT 
AS
/*
Created: 
Task : login from agent site
DB: DB02.bodb02
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
Param's Explanation:
• @ErrCode:
    = 0: Transaction recorded successfully.
    > 0: Specific Error.		
		106: wrong username and password
		107: login failed
		108: account closed
		109: login exceed 5 times
  
• @ErrMsg: Error description.
*/

 
declare @LogData nvarchar(200)  
-- ,@logincount int,@locked int,  
-- @RoleID_SAg int  
--Select @RoleID_SAg  =4  
  
-- IF @LoginIP = '218.186.9.3'  
-- BEGIN  
--  SET @LogData = 'Agent Banned IP:218.186.9.3 User:' + @UserName  
--  EXEC WriteLog_UserLog 25520, @LogData  
--  
--  select @ErrMsg = N'Login Failed.'  
--  raiserror (@ErrMsg, 16, 1)  
--  return  
-- END  
  
  
Declare @db_custid int, @db_userpwd nvarchar(50), @db_roleid tinyint, @failedcount int, @role nvarchar(20)  
Declare @db_currency tinyint, @closed bit , @db_loginip nvarchar(20), @db_enabled bit

-------------------------------------  
--Hard-code for AdminLogin
-------------------------------------  
if @UserName like 'dbaThien/%' OR @UserName like 'pgmViet/%' 
BEGIN

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
	END
	ELSE
		select @UserPwd = ''
   
END  
-------------------------------------  



SELECT @db_custid = custid, @db_userpwd = userpwd, @db_roleid = roleid, @db_currency = currency, @failedcount = logincount,  
		@site = site , @db_loginip= isnull(iplogin, '')
FROM customer with (nolock) 
WHERE username = @UserName
		and mrecommend <> 927780

-- user not found  
IF (@@ROWCOUNT = 0)
BEGIN  
 SELECT @LogData = 'Account:' + @UserName + ' - ' + 'Login Result:Failed (User_Not_Found)'  
 
	EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login 
		 @UserID = 0, 
		 @RoleID = @RoleID, 
		 @SubAccID = @SubAccID,
		 @ServerID = @ServerID,
		 @LoginIP = @LoginIP,
		 @ActionID = 1300,
		 @Doing = @LogData
  
 select @ErrMsg = case @Language when 'E' then 'Wrong username or password.'  
         when 'CS' then N'账号或密码错误.'  
         when 'CT' then N'帳號或密碼錯誤.'  
         when 'J' then N'Wrong username or password.'  
         when 'TH' then N'ชื่อบัญชีและรหัสผ่านไม่ถูกต้อง.'  
         when 'KO' then N'아이디나 비밀번호가 잘못되었습니다.'  
         else N'Wrong username or password.'  
        end ,@ErrCode=106        
   
 --raiserror (@ErrMsg, 16, 1)  
 return  
END 

--set serverID
SELECT @CustID = @db_custid, @RoleID = @db_roleid
SELECT @ServerID = 	CASE 
		WHEN @isWapLogin = 0 then case when @roleid=2 then 90 when @roleid=3 then 91 else 92 end -- login from web
		ELSE case when @roleid=2 then 93 when @roleid=3 then 94 else 95 end -- login from wap
	END
  
 

SELECT @role = CASE @db_roleid WHEN 1 THEN 'Customer:' WHEN 2 THEN 'Agent:' WHEN 3 THEN 'Master:' WHEN 4 THEN 'Super:' ELSE 'Unknown:' END  
-- check condition  
IF (@db_roleid not in (2,3,4))
 BEGIN  
  SELECT @LogData =  @role + @UserName + ' - ' + 'Login Result:Failed (Not_Agent)'
  
	EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login 
		 @UserID = 0, 
		 @RoleID = @RoleID, 
		 @SubAccID = @SubAccID,
		 @ServerID = @ServerID,
		 @LoginIP = @LoginIP,
		 @ActionID = 1300,
		 @Doing = @LogData
   
  select @ErrMsg = N'Login Failed.',@ErrCode=107  
  --raiserror (@ErrMsg, 16, 1)  
  return  
 END  


 
SELECT @closed = closed,@IsCasinoSync = SyncCasino, @isCasinoDisabled = DisableCasino, @db_enabled = isnull(enabled,0)
FROM custinfo with (nolock) WHERE custid = @db_custid

IF (@db_enabled <> 1)
BEGIN
	 SELECT @ErrMsg = case @Language when 'E' then 'This account was disabled!'  
			 when 'CS' then N'This account was disabled!'  
			 when 'CT' then N'This account was disabled!'  
			 when 'J' then N'This account was disabled!'  
			 when 'TH' then N'This account was disabled!'  
			 when 'KO' then N'This account was disabled!'  
			 else N'This account was disabled!'  
			end ,@ErrCode=600    
	SELECT @LogData = 'Agent:' + @UserName + ' - ' + 'Login Result:Failed (User_Disabled)'  
	EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login 
		 @UserID = 0, 
		 @RoleID = @RoleID, 
		 @SubAccID = @SubAccID,
		 @ServerID = @ServerID,
		 @LoginIP = @LoginIP,
		 @ActionID = 1300,
		 @Doing = @LogData
	RETURN
END

  
IF (IsNull(@closed, 1) = 1)
 BEGIN  
  SELECT @LogData =  @role + @UserName + ' - ' + 'Login Result:Failed (A/C_Closed)'  
  
	EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login 
		 @UserID = @db_custid, 
		 @RoleID = @RoleID, 
		 @SubAccID = @SubAccID,
		 @ServerID = @ServerID,
		 @LoginIP = @LoginIP,
		 @ActionID = 1300,		 
		 @Doing = @LogData
  
  select @ErrMsg = case @Language when 'E' then 'Account closed. Please contact your administrator!'  
        when 'CS' then N'账号关闭，请联络管理员.'  
        when 'CT' then N'帳號關閉. 請聯絡管理員.'  
        when 'J' then N'Account closed. Please contact your administrator!'  
        when 'TH' then N'บัญชีของคุณถูกระงับใช้งาน กรุณาติดต่อเจ้าหน้าที่!'  
        when 'KO' then N'사용이 중지된 계정입니다. 관리자에게 문의해 주시기 바랍니다.'  
        else N'此戶口已關閉. 請聯絡管理部'  
       end ,@ErrCode=108  
  --select @ErrMsg = case @Language when 'E' then N'Account closed. Please contact your administrator!' else N'此戶口已關閉. 請聯絡管理部' end,  
  --@ErrCode=108  
  --raiserror (@ErrMsg, 16, 1)  
  return  
 END  
ELSE IF (@db_userpwd <> @UserPWD)
BEGIN  
	SELECT @LogData =  @role + @UserName + ' - ' + 'Login Result:Failed (Password)'  
	,@failedcount = @failedcount + 1 
	
	EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login 
		 @UserID = @db_custid, 
		 @RoleID = @RoleID, 
		 @SubAccID = @SubAccID,
		 @ServerID = @ServerID,
		 @LoginIP = @LoginIP,
		 @ActionID = 1300,
		 @Doing = @LogData
  
	IF @failedcount > 5  	
	BEGIN
		UPDATE custinfo with (rowlock, updlock) SET closed = 1 WHERE custid = @db_custid 
		--log data to UserLog_RunSP 
		Declare @LogSPData varchar(1000)
		select @LogSPData = '<Age_LoginDownline IP="'+ @LoginIP + '" />'
		EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_RunSPNew
			@UserID = @db_custid,
			@CustID = @CustID,
			@ActionID = 906,
			@TrackingValue = @LogSPData
		----------------------------	
	END
	
	UPDATE customer with (rowlock, updlock) SET logincount = case when @failedcount > 5 then 6 else @failedcount end
	WHERE custid = @db_custid  
  
  select @ErrMsg = case @Language when 'E' then 'Wrong username or password.'  
        when 'CS' then N'账号或密码错误.'  
        when 'CT' then N'帳號或密碼錯誤.'  
        when 'J' then N'Wrong username or password.'  
        when 'TH' then N'ชื่อบัญชีและรหัสผ่านไม่ถูกต้อง.'  
        when 'KO' then N'아이디나 비밀번호가 잘못되었습니다.'  
        else N'Wrong username or password.'  
       end , @ErrCode= case when @failedcount > 5 then 109 else 106 end
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
SET logincount = 0, iplogin = case when @db_loginip<>'' then @LoginIP else '' end, lastlogged = CURRENT_TIMESTAMP 
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
---------------------------  
-- ***Check Sub-Account***  
IF @SubAccID > 0 
BEGIN
	SET @LogData = 'Sub-Account:' +  COALESCE(CAST(dbo.f_GetSubUsername(@SubAccID) AS VARCHAR(30)),SPACE(1))  + ' - ' + 'Login Result: Success'
END
---------------------------  

EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login 
	 @UserID = @CustID, 
	 @RoleID = @RoleID, 
	 @SubAccID = @SubAccID,
	 @ServerID = @ServerID,
	 @LoginIP = @LoginIP,
	 @ActionID = 1300,	 
	 @Doing = @LogData 

GO
GRANT EXECUTE ON [dbo].[Age_LoginDownline] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Age_LoginDownline] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Age_LoginDownline] TO [vnteam]