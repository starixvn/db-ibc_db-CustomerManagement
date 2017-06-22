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
DB: DBTRANS.bodb02
Original: CustSubPwdUpd2

Revisions:
    - 20090311@HanhVu: Log information into UserLog_RunSP table					   
	- 20090402@Phuc: write log into dblog.
	- 20091209@Terry: Remove Rais Error
	- 20100107@Kiwi: Amend writing log format.
	- 20101021@Henry: Record execution time
	- 20121128@Elodie: Get an error message from f_Get_MsgNameByMsgID function by language
	- 20130328@Jamie: Update Old pwd and Last Changed Pwd 
*/
SET NOCOUNT ON

declare @startRun datetime
declare @endRun datetime
declare @duration int
set @startRun = getdate()

Declare @SubAccname varchar(30)
DECLARE @PwdExpiry DATETIME

if not exists (select 1 from custsub with (nolock) where subaccid = @SubAccID and userpwd = @OldPwd)
BEGIN
	Select @ErrMsg =  case @Language 
						when 'E' then 'Old password is incorrect.'
						ELSE [dbo].[f_Get_MsgNamebyMsgID](40021,@Language)
					  end ,	
	@ErrCode = 100
	return
END

SELECT	@PwdExpiry = DATEADD(dd, 30, GETDATE())

Update custsub with (rowlock, updlock)
set userpwd = @UserPwd,
	@SubAccname = username
where subaccid = @SubAccID and custid = @CustID

UPDATE	CustLoginInfoSub WITH (UPDLOCK,ROWLOCK)
SET		OldUserPwd			= @OldPwd
		,PwdExpiry			= @PwdExpiry
		,LastChangedPwdDate	= GETDATE()
		,isFirstLogin		= 0 
WHERE	SubAccID = @SubAccID and CustID = @CustID

Declare @LogData nvarchar(200)
--904	Age_CustSubPwdUpd2	Sub-account changed his own password

Select @LogData = '<Age_CustomerPwdUpd2 SubAccount="' + convert(varchar(30),@SubAccname)
					 + '" IP="' + @LoginIP + '"/>'

set @endRun = getdate()
set @duration  = datediff (millisecond,@startRun,@endRun)

EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
	@UserID = @CustID,
	@CustID = @CustID,
	@ActionID = 904,
	@TrackingValue = @LogData	,
	@duration = @duration


GO
GRANT EXECUTE ON [dbo].[Age_CustSubPwdUpd2] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Age_CustSubPwdUpd2] TO [VNTeam]