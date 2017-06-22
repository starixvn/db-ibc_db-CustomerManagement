ALTER PROCEDURE [dbo].[Acc_CustomerUpdPwdReset]
	@CustID int,
	@UserPwd nvarchar(50),
	@UserID int,
	@Language varchar(2) = 'E',
	@LoginIP VARCHAR(15) ='',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS

/*	Creator:[Creator]
	Date: 2008
	Task: Update user's password 
	DB: DB02.bodb02
	
	History:
		- 20080213@PhucPham: Check permission for Account site
		- 20090311@PhuongDao: Write log for updating user's password and add a param - @LoginIP 
		- 20090321@PhuongDao: Not checking permission if the admin changes his own password. 
		- 20090828@HuyNguyen: replace [Customer] --> [Password]
		- 20090917@Phuc: Write log to dblog	
		- 20100101@Lewin: Remove string 'Reset password ' from param @LogSPData
*/

SET NOCOUNT ON

IF @UserID <> @CustID
BEGIN
	--Check permission for account site: @phuc20080213
	EXEC db03.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[Password]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
	If @ErrCode <> 0
		RETURN
END

--Check disable user
EXEC DB052.bodb02.dbo.Acc_CustomerSelCheckEnable @custid = @custid, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
if @ErrCode <>0 return
--end

declare @PwdExpiry datetime

select @pwdexpiry = dateadd(dd, 30, getdate())

UPDATE customer  with (ROWLOCK, UPDLOCK)
SET userpwd=@UserPwd, pwdexpiry=@PwdExpiry 
where custid=@CustID

DECLARE @LogSPData nvarchar(max)
SELECT @LogSPData = '<Acc_CustomerUpdPwdReset CustID="' + convert(varchar(20), @CustID) +'" IP="' + @LoginIP +'" />'

/*900 Acc_CustomerUpdPwdReset Reset downline's password */
EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew
	@UserID = @UserID,
	@CustID = @CustID,
	@ActionID = 900,
	@TrackingValue = @LogSPData
	
GO
GRANT  EXECUTE  ON [dbo].[Acc_CustomerUpdPwdReset]  TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdPwdReset] TO [vnteam]