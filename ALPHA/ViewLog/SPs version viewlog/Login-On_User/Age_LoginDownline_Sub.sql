alter PROCEDURE [dbo].[Age_LoginDownline_Sub]    
	@SubUserName varchar(50),    
	@UserPwd varchar(50),    
	@LoginIP varchar(20),    
	@ServerID int =0 OUTPUT,    
	@RoleID int OUTPUT,    
	@CustID int OUTPUT,    
	@On_UserID int OUTPUT,    
	@Currency varchar(10) = '' OUTPUT,    
	@CurrencyId int = 0 OUTPUT,
	@Language varchar(2) = 'E',    
	@MasterUsername varchar(50) = '' OUTPUT,    
	@SubAccID int = 0 OUTPUT,    
	@UserName nvarchar(50) OUTPUT,    
	@site varchar(20) = '' OUTPUT,    
	@SubPageAccess varchar(50) = '' OUTPUT,    
	@IsWapLogin bit = false,
	@isCasinoDisabled bit = false OUTPUT,
	@IsCasinoSync bit = false OUTPUT,
	@ErrCode int = 0 OUTPUT,    
	@ErrMsg nvarchar(4000) = '' OUTPUT
			
AS    

/*
Created: 
Task : login sub-acc from agent site
DB: DB02.bodb02
Original:LoginDownline_Sub  

Revisions:
    - 20090220@Phuc: Close sub-acc when login with wrong password more than 5 times 
    - 20090225@Hiep: get CasinoSync and CasinoDisable for Casino Integration with Agent site
    - 20090318@Hanh: add Korean language
    - 20090407@Lee: Add output currencyId
	- 20090917@Phuc: write log into DBLOG.
	- 20091210@Minh: add error code about login exceed 5 times.  
	- 20100101@Kiwi: Modify Log.  
	
Param's Explanation:
• @ErrCode:
    = 0: Login successfully.
    > 0: Specific Error.
  
• @ErrMsg: Error description.
*/

  
SET NOCOUNT ON    
declare @LogData nvarchar(200)    
   
Declare @db_userpwd varchar(40), @failedcount tinyint, @closed bit
SELECT @SubAccID = subaccid, @CustID = custid, @SubPageAccess = PageAccess,
		@db_userpwd = userpwd, @failedcount = isnull(logincount,0), @closed = closed 
FROM custSub (nolock) where username = @SubUserName

IF @@ROWCOUNT = 0  
BEGIN
	Select @LogData = 'Sub-account: ' + @SubUserName + ', login failed, password problem'    
	
	EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login 
		 @UserID = 0, 
		 @RoleID = @RoleID, 
		 @SubAccID = @SubAccID,
		 @ServerID = @ServerID,
		 @LoginIP = @LoginIP,
		 @ActionID = 1302,
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
 
IF IsNull(@Closed,1) = 1 
BEGIN    
	Select @LogData = 'Sub-account: ' + @SubUserName + ', login failed, Result:Failed(A/C_Closed)'    
	EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login 
		 @UserID = @CustID, 
		 @RoleID = @RoleID, 
		 @SubAccID = @SubAccID,
		 @ServerID = @ServerID,
		 @LoginIP = @LoginIP,
		 @ActionID = 1302,
		 @Doing = @LogData  
	select @ErrMsg = case @Language when 'E' then 'Account closed. Please contact your administrator!'  
        when 'CS' then N'账号关闭，请联络管理员.'  
        when 'CT' then N'帳號關閉. 請聯絡管理員.'  
        when 'J' then N'Account closed. Please contact your administrator!'  
        when 'TH' then N'บัญชีของคุณถูกระงับใช้งาน กรุณาติดต่อเจ้าหน้าที่!'  
        when 'KO' then N'사용이 중지된 계정입니다. 관리자에게 문의해 주시기 바랍니다.'  
        else N'此戶口已關閉. 請聯絡管理部'  
       end ,@ErrCode=108    
	--raiserror (@ErrMsg, 16, 1)    
	return    
END
ELSE IF @db_userpwd <> @UserPWD
BEGIN
	Select @LogData = 'Sub-account: ' + @SubUserName + ', login failed, password problem',
			@failedcount = @failedcount + 1 
	EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login 
		 @UserID = @CustID, 
		 @RoleID = @RoleID, 
		 @SubAccID = @SubAccID,
		 @ServerID = @ServerID,
		 @LoginIP = @LoginIP,
		 @ActionID = 1302,
		 @Doing = @LogData   
	IF @failedcount > 5
	BEGIN
		UPDATE custSub with (rowlock, updlock) SET closed = 1, logincount = 0 WHERE subaccid = @subaccid 
		--log data to UserLog_RunSP 
		Declare @LogSPData varchar(1000)
		select @LogSPData = '<Age_LoginDownline_Sub IP="'+ @LoginIP + '" />'	
			   
		EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_RunSPNew
			@UserID = @CustID,
			@CustID = @SubAccID,
			@ActionID = 907,
			@TrackingValue = @LogSPData
	END
	ELSE
		UPDATE custSub with (rowlock, updlock) SET logincount = @failedcount WHERE subaccid = @subaccid 
	
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

UPDATE custSub with (rowlock, updlock) SET logincount = 0 WHERE subaccid = @subaccid 
  
--Get username, password from customer table to login in the context of agent    
Select @UserName = username, @UserPwd = userpwd from customer with (nolock) where custid = @CustID    
    
--Login in the name of agent    
EXEC dbo.Age_LoginDownline     
 @UserName = @UserName,    
 @UserPwd = @UserPwd,    
 @LoginIP = @LoginIP,    
 @ServerID = @ServerID OUTPUT,    
 @RoleID = @RoleID OUTPUT,    
 @CustID = @CustID OUTPUT,    
 --@On_UserID = @On_UserID OUTPUT,    
 @Currency = @Currency OUTPUT,  
 @CurrencyId = @CurrencyId OUTPUT,  
 @Language = @Language,    
 @MasterUsername = @MasterUsername OUTPUT,    
 @SubAccID = @SubAccID,    
 @site = @site OUTPUT,  
 @IsWapLogin = @IsWapLogin,  
 @isCasinoDisabled = @isCasinoDisabled OUTPUT,
 @IsCasinoSync = @IsCasinoSync OUTPUT,
 @ErrCode =@ErrCode OUTPUT,    
 @ErrMsg =@ErrMsg OUTPUT
 
GO
GRANT EXECUTE ON [dbo].[Age_LoginDownline_Sub] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Age_LoginDownline_Sub] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Age_LoginDownline_Sub] TO [vnteam]
