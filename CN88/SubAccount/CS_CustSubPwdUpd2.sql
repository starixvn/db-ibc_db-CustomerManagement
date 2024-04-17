/*<info serverAlias="DBCUST-CustDB" executers="wsv_alp" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[CS_CustSubPwdUpd2]
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
Created: 20190708@Johnson
Task : Sub-account change his own password
DB: DBCUST/CUSTDB
Original: Age_CustSubPwdUpd2

Revisions:
    - 20190708@Johnson: initial sp [redmine:#116088]
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

Update custsub with (rowlock, updlock)
set userpwd = @UserPwd,
	@SubAccname = username
where subaccid = @SubAccID and custid = @CustID

UPDATE	CustLoginInfoSub WITH (UPDLOCK,ROWLOCK)
SET		OldUserPwd			= @OldPwd
		,PwdExpiry			= NULL--dont need to force reset pwd
		,LastChangedPwdDate	= GETDATE()
		,isFirstLogin		= 0 
WHERE	SubAccID = @SubAccID and CustID = @CustID

Declare @LogData nvarchar(200)
--904	Age_CustSubPwdUpd2	Sub-account changed his own password

Select @LogData = '<R SubAccount="' + convert(varchar(30),@SubAccname)
					 + '" IP="' + @LoginIP + '"/>'

set @endRun = getdate()
set @duration  = datediff (millisecond,@startRun,@endRun)

EXEC dbo.CS_WriteLog_UserLog_RunSP_Wrapper
			@UserID = @CustID, 
			@CustID = @CustID,
			@ActionID = 160011,
			@TrackingValue = @LogData,			
			@duration = @duration
			
GO