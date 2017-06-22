ALTER PROCEDURE [dbo].[Age_LoginVerifyDownline]
	@UserName VARCHAR(50),  
	@UserPwd VARCHAR(50),  
	@CustID INT OUTPUT,  
	@SubAccID INT = 0 OUTPUT, --Sub-AccountID,  
	@LoginIP VARCHAR(20)='',  
	@ServerID INT =0 OUTPUT,  
	@LoginTime DATETIME = null OUTPUT, --varchar(50) = null OUTPUT,	
	@Language VARCHAR(2) = 'E',  
	@ErrCode INT = 0 OUTPUT,  
	@ErrMsg NVARCHAR(4000) = '' OUTPUT 
AS
/*
Created: 20090829@Don
Task : check if one account or sub-account existed or not
DB: DB02.bodb02

Revisions:
	- 20090917@Phuc: write log into DBLOG.
	- 20091210@Minh: add error code about login exceed 5 times.
	- 20100101@Kiwi: Modify Log.
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

SET NOCOUNT ON

DECLARE @isExisted BIT,
	@RoleID TINYINT,
	@LogData NVARCHAR(200),  
    @db_custid INT, 
    @db_userpwd NVARCHAR(50), 
    @failedcount INT, 
    @role NVARCHAR(20), 
	@closed BIT , 
	@db_loginip NVARCHAR(20), 
	@db_enabled BIT,
	@LogSPData VARCHAR(1000),
	@SubUserName VARCHAR(50)

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


IF EXISTS (SELECT 1 FROM custsub WITH (NOLOCK) WHERE username = @UserName)
	SET @isExisted = 1
ELSE
	SET @isExisted = 0

IF (@isExisted = 1)
BEGIN
    -- check sub-account --
   SET @SubUserName = @UserName
   
   SELECT @SubAccID = subaccid, @CustID = custid, 
		@db_userpwd = userpwd, @failedcount = ISNULL(logincount,0), @closed = closed
    FROM custSub (NOLOCK) WHERE username = @SubUserName

	Select @RoleID = roleid from custinfo WITH (NOLOCK) where custid = @CustID
    
    IF (@@ROWCOUNT = 0)
    BEGIN
		SELECT @LogData = 'Sub-account: ' + @SubUserName + ', login failed (User_Not_Found)'    
		
		EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login 
			 @UserID = 0, 
			 @RoleID = 0, 
			 @SubAccID = @SubAccID,
			 @ServerID = @ServerID,
			 @LoginIP = @LoginIP,
			 @ActionID = 1304,
			 @Doing = @LogData
		SELECT @ErrMsg = CASE @Language WHEN 'E' THEN 'Wrong username or password.'  
							WHEN 'CS' THEN N'账号或密码错误.'  
							WHEN 'CT' THEN N'帳號或密碼錯誤.'  
							WHEN 'J' THEN N'Wrong username or password.'  
							WHEN 'TH' THEN N'ชื่อบัญชีและรหัสผ่านไม่ถูกต้อง.'  
							WHEN 'KO' THEN N'아이디나 비밀번호가 잘못되었습니다.'  
							ELSE N'Wrong username or password.'  
						END ,@ErrCode=106    
		RETURN    
	END
     
    IF ISNULL(@Closed,1) = 1
    BEGIN    
		SELECT @LogData = 'Sub-account: ' + @SubUserName + ', login failed, Result:Failed (A/C_Closed)'   
		EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login 
			 @UserID = @CustID, 
			 @RoleID = @RoleID, 
			 @SubAccID = @SubAccID,
			 @ServerID = @ServerID,
			 @LoginIP = @LoginIP,
			 @ActionID = 1304,
			 @Doing = @LogData   
		SELECT @ErrMsg = CASE @Language WHEN 'E' THEN 'Account closed. Please contact your administrator!'  
							WHEN 'CS' THEN N'账号关闭，请联络管理员.'  
							WHEN 'CT' THEN N'帳號關閉. 請聯絡管理員.'  
							WHEN 'J' THEN N'Account closed. Please contact your administrator!'  
							WHEN 'TH' THEN N'บัญชีของคุณถูกระงับใช้งาน กรุณาติดต่อเจ้าหน้าที่!'  
							WHEN 'KO' THEN N'사용이 중지된 계정입니다. 관리자에게 문의해 주시기 바랍니다.'  
							ELSE N'此戶口已關閉. 請聯絡管理部'  
						END ,@ErrCode=108    
		RETURN    
    END
    ELSE IF @db_userpwd <> @UserPWD
    BEGIN
	    SELECT @LogData = 'Sub-account: ' + @SubUserName + ', login failed, password problem',
			    @failedcount = @failedcount + 1    
	    
	    EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login 
			 @UserID = @CustID, 
			 @RoleID = @RoleID, 
			 @SubAccID = @SubAccID,
			 @ServerID = @ServerID,
			 @LoginIP = @LoginIP,
			 @ActionID = 1304,
			 @Doing = @LogData  
	    IF @failedcount > 5
	    BEGIN
		    UPDATE custSub WITH (ROWLOCK, UPDLOCK) SET closed = 1, logincount = 0 WHERE subaccid = @subaccid 
		    --log data to UserLog_RunSP 
		    
		    SELECT @LogSPData = '<Age_LoginVerifyDownline IP="'+ @LoginIP + '" />'			
			EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_RunSPNew
				@UserID = @db_custid,
				@CustID = @CustID,
				@ActionID = 908,
				@TrackingValue = @LogSPData
	    END
	    ELSE
		    UPDATE custSub WITH (ROWLOCK, UPDLOCK) SET logincount = @failedcount WHERE subaccid = @subaccid 
    	
	    SELECT @ErrMsg = CASE @Language WHEN 'E' THEN 'Wrong username or password.'  
            WHEN 'CS' THEN N'账号或密码错误.'  
            WHEN 'CT' THEN N'帳號或密碼錯誤.'  
            WHEN 'J' THEN N'Wrong username or password.'  
            WHEN 'TH' THEN N'ชื่อบัญชีและรหัสผ่านไม่ถูกต้อง.'  
            WHEN 'KO' THEN N'아이디나 비밀번호가 잘못되었습니다.'    
            ELSE N'Wrong username or password.'  
           END ,@ErrCode=106    
	    RETURN    
    END    

    UPDATE custSub WITH (ROWLOCK, UPDLOCK) SET logincount = 0 WHERE subaccid = @subaccid 
	
	--Get username, password from customer table to login in the context of agent    
	Select @UserName = username, @UserPwd = userpwd from customer WITH (NOLOCK) where custid = @CustID    
END

-- check account --
SELECT @db_custid = custid, @db_userpwd = userpwd, @RoleID = roleid, 
	@failedcount = logincount, @db_loginip= ISNULL(iplogin, '')
FROM customer WITH (NOLOCK) 
WHERE username = @UserName
	    AND mrecommend <> 927780

-- user not found  
IF (@@ROWCOUNT = 0)
BEGIN  
	SELECT @LogData =  'Agent:' + @UserName + ' Result:Failed (User_Not_Found)'
	EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login 
		 @UserID = 0, 
		 @RoleID = 0, 
		 @SubAccID = @SubAccID,
		 @ServerID = @ServerID,
		 @LoginIP = @LoginIP,
		 @ActionID = 1304,
		 @Doing = @LogData

	SELECT @ErrMsg = CASE @Language WHEN 'E' THEN 'Wrong username or password.'  
						WHEN 'CS' THEN N'账号或密码错误.'  
						WHEN 'CT' THEN N'帳號或密碼錯誤.'  
						WHEN 'J' THEN N'Wrong username or password.'  
						WHEN 'TH' THEN N'ชื่อบัญชีและรหัสผ่านไม่ถูกต้อง.'  
						WHEN 'KO' THEN N'아이디나 비밀번호가 잘못되었습니다.'  
						ELSE N'Wrong username or password.'  
					END ,@ErrCode=106        
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
	
	EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login 
		 @UserID = 0, 
		 @RoleID = @RoleID, 
		 @SubAccID = @SubAccID,
		 @ServerID = @ServerID,
		 @LoginIP = @LoginIP,
		 @ActionID = 1304,
		 @Doing = @LogData

	SELECT @ErrMsg = N'Login Failed.',@ErrCode=107  
RETURN  
END  

SELECT @closed = closed, @db_enabled = ISNULL(enabled,0)
FROM custinfo WITH (NOLOCK) WHERE custid = @db_custid

IF @db_enabled <> 1
BEGIN
     SELECT @ErrMsg = CASE @Language WHEN 'E' THEN 'This account was disabled!'  
						 WHEN 'CS' THEN N'This account was disabled!'  
						 WHEN 'CT' THEN N'This account was disabled!'  
						 WHEN 'J' THEN N'This account was disabled!'  
						 WHEN 'TH' THEN N'This account was disabled!'  
						 WHEN 'KO' THEN N'This account was disabled!'  
						 ELSE N'This account was disabled!'  
						END ,@ErrCode=600    
    SELECT @LogData ='Agent:' + @UserName + ' Result:Failed (User_Disabled)'
    
	EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login 
		 @UserID = @CustID, 
		 @RoleID = @RoleID, 
		 @SubAccID = @SubAccID,
		 @ServerID = @ServerID,
		 @LoginIP = @LoginIP,
		 @ActionID = 1304,
		 @Doing = @LogData
    RETURN
END

  
IF ISNULL(@closed, 1) = 1
BEGIN  
	SELECT @LogData =  @role + @UserName + ' Result:Failed(A/C_Closed)'
	
	EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login 
		 @UserID = @db_custid, 
		 @RoleID = @RoleID, 
		 @SubAccID = @SubAccID,
		 @ServerID = @ServerID,
		 @LoginIP = @LoginIP,
		 @ActionID = 1304,
		 @Doing = @LogData 
	SELECT @ErrMsg = CASE @Language WHEN 'E' THEN 'Account closed. Please contact your administrator!'  
					WHEN 'CS' THEN N'账号关闭，请联络管理员.'  
					WHEN 'CT' THEN N'帳號關閉. 請聯絡管理員.'  
					WHEN 'J' THEN N'Account closed. Please contact your administrator!'  
					WHEN 'TH' THEN N'บัญชีของคุณถูกระงับใช้งาน กรุณาติดต่อเจ้าหน้าที่!'  
					WHEN 'KO' THEN N'사용이 중지된 계정입니다. 관리자에게 문의해 주시기 바랍니다.'  
					ELSE N'此戶口已關閉. 請聯絡管理部'  
			   END ,@ErrCode=108  
	RETURN  
END  
ELSE IF @db_userpwd <> @UserPWD
BEGIN  
    SELECT @LogData =  @role + @UserName + ' Result:Failed (Password problem)'  
    ,@failedcount = @failedcount + 1  
    EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login 
		 @UserID = @db_custid, 
		 @RoleID = @RoleID, 
		 @SubAccID = @SubAccID,
		 @ServerID = @ServerID,
		 @LoginIP = @LoginIP,
		 @ActionID = 1304,
		 @Doing = @LogData   
  
    IF @failedcount > 5  	
    BEGIN
	    UPDATE custinfo WITH (ROWLOCK, UPDLOCK) SET closed = 1 WHERE custid = @db_custid 
	    --log data to UserLog_RunSP 
	    SELECT @LogSPData = '<Age_LoginVerifyDownline IP="'+ @LoginIP + '" />'			
	    EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_RunSPNew
		    @UserID = @db_custid,
		    @CustID = @CustID,
		    @ActionID = 908,
		    @TrackingValue = @LogSPData
	    ----------------------------	
    END
	
    UPDATE customer WITH (ROWLOCK, UPDLOCK) SET logincount = CASE WHEN @failedcount > 5 THEN 6 ELSE @failedcount END
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
UPDATE customer WITH (ROWLOCK, UPDLOCK)  
SET logincount = 0, iplogin = CASE WHEN @db_loginip<>'' THEN @LoginIP ELSE '' END, lastlogged = CURRENT_TIMESTAMP 
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

EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login 
		 @UserID = @db_custid, 
		 @RoleID = @RoleID, 
		 @SubAccID = @SubAccID,
		 @ServerID = @ServerID,
		 @LoginIP = @LoginIP,
		 @ActionID = 1304,
		 @Doing = @LogData 

GO
GRANT EXECUTE ON [dbo].[Age_LoginVerifyDownline] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Age_LoginVerifyDownline] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Age_LoginVerifyDownline] TO [vnteam]