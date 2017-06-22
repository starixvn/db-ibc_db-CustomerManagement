ALTER PROCEDURE [dbo].[Age_CustSubPwdUpd2]
	@CustID int,
	@SubAccID int,	
	@UserPwd nvarchar(50),
	@OldPwd nvarchar(50),
	@LoginIP varchar(20)='',
	@Language varchar(2) = 'E',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(100) = '' output	
AS
/*
Created: 
Task : Sub-account change his own password
DB: DB02.bodb02
Original: CustSubPwdUpd2

Revisions:
    - 20090311@HanhVu: Log information into UserLog_RunSP table					   
	- 20090402@Phuc: write log into dblog.
	- 20091209@Terry: Remove Rais Error
	- 20100107@Kiwi: Amend writing log format.
*/
SET NOCOUNT ON
Declare @SubAccname varchar(30)

if not exists (select 1 from custsub with (nolock) where subaccid = @SubAccID and userpwd = @OldPwd)
BEGIN
	Select @ErrMsg =  case @Language 
						when 'E' then 'Old password is incorrect.'
						when 'CS' then N'旧密码不正确.'
						when 'CT' then N'舊密碼不正確.'
						when 'J' then N'パスワードが正しくありません。'
						when 'TH' then N'รหัสผ่านเดิมไม่ถูกต้อง.'
						when 'ES' then N'La contraseña antigua es incorrecta.'
						when 'KO' then N'이전의 비밀번호가 잘못된 것입니다.'
						else N'Old password is incorrect.'
					end ,	
	@ErrCode = 100
	return
END

Update custsub with (rowlock, updlock)
set userpwd = @UserPwd,
	@SubAccname = username
where subaccid = @SubAccID and custid = @CustID

Declare @LogData nvarchar(200)
--904	Age_CustSubPwdUpd2	Sub-account changed his own password

Select @LogData = '<Age_CustomerPwdUpd2 SubAccount="' + convert(varchar(30),@SubAccname)
					 + '" IP="' + @LoginIP + '"/>'

EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew
	@UserID = @CustID,
	@CustID = @CustID,
	@ActionID = 904,
	@TrackingValue = @LogData	


GO
GRANT EXECUTE ON [dbo].[Age_CustSubPwdUpd2] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Age_CustSubPwdUpd2] TO [VNTeam]