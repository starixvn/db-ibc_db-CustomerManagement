USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Age_CustSubPwdUpd]    Script Date: 03/28/2013 21:51:28 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Age_CustSubPwdUpd]
	@custid int,
	@subaccid int,
	@UserPwd nvarchar(50),
	@Language varchar(2) = 'E',
	@LoginSubAccID int = 0, --Current Login Sub-AccountID	
	@LoginIP varchar(20)='',
	@ErrCode int = 0 OUTPUT,
	@UserID int=0,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS

/*
Created: 
Task : Agent changes password of sub-account
DB: DBTXN/bodb02
Original: CustSubPwdUpd

Revisions:
    - 20090311@Hanh: Log information into UserLog_RunSP table		
    - 20090318@Hanh: add Korean language			   
	- 20090917@Phuc: write log into DBLOG.
	- 20100107@Kiwi: Amend writing log.
	- 20101021@Henry: Record execution time
	- 20130218@Dan: Write more log on DBTXN server in case of DBLOG server failure
Param's Explanation:
• @ErrCode:
    = 0: Transaction recorded successfully.
    > 0: Specific Error.
  
• @ErrMsg: Error description.
*/
SET NOCOUNT ON

declare @startRun datetime
declare @endRun datetime
declare @duration int,
		@OldUserPwd VARCHAR(40)
set @startRun = getdate()

---------------------------
-- ***Check Sub-Account***
-- For Edit Sub-Account
/*
Declare @spPageAccess varchar(10)
set @spPageAccess = '[NO]' --No Permission for Sub-Account on this Sp
Declare @SubAllow bit
Exec Age_CustSubCheckPageAccess @LoginSubAccID, @spPageAccess, @Language, @SubAllow OUTPUT
if @SubAllow = 0
	BEGIN
	select @ErrMsg = case @Language 
				when 'E' then 'Sorry, You do not have Permission to update Sub-Account.'
				when 'CS' then N'对不起，您不允许修改子账号.'
				when 'CT' then N'對不起, 您不允許修改子帳號.'							
				when 'TH' then N'ขออภัย คุณไม่ได้รับอนุญาติที่จะปรับยอดเงินในบัญชีย่อย.'
				when 'J' then N'Sorry, You do not have Permission to update Sub-Account.'
				when 'KO' then N'죄송합니다. 보조 계정의 업데이트가 허가 되지 않았습니다.'
				else N'Sorry, You don''t have Permission to update Sub-Account.'
			end	,@ErrCode=101		
		return	
	END
*/
---------------------------
SELECT	@OldUserPwd = UserPwd
FROM	custSub WITH (NOLOCK)
WHERE	subaccid = @subaccid and custid = @custid

Update	custsub with (rowlock, updlock)
set		userpwd = @UserPwd
where	subaccid = @subaccid and custid = @custid

UPDATE CustLoginInfoSub WITH (UPDLOCK,ROWLOCK)
SET		OldUserPwd			= @OldUserPwd
		,PwdExpiry			= DATEADD(dd,30,GETDATE())
		,LastChangedPwdDate	= GETDATE()
WHERE	subaccid = @subaccid and custid = @custid

Declare @LogData varchar(5000)
Select @LogData = '<Age_CustSubPwdUpd SubAccount="' + convert(varchar(30),dbo.f_GetSubUsername(@SubAccID))
					 + '" IP="' + @LoginIP + '"/>'

set @endRun = getdate()
set @duration  = datediff (millisecond,@startRun,@endRun)

BEGIN TRY
	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		@UserID = @UserID,
		@CustID = @custid,
		@ActionID = 903,
		@TrackingValue = @LogData,
		@duration = @duration
END TRY
BEGIN CATCH
	Select @LogData = '<Age_CustSubPwdUpd SubAccount="' + convert(varchar(30),dbo.f_GetSubUsername(@SubAccID))
					+ '" ErrCode="' + coalesce(cast(ERROR_NUMBER() as varchar(50)),space(1)) +
					+ '" ErrMsg="' +  coalesce(ERROR_MESSAGE(),space(1)) + 
					+ '" IP="' + @LoginIP + '"/>'
					 
	EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		@UserID = @UserID,
		@CustID = @custid,
		@ActionID = 903,
		@TrackingValue = @LogData,
		@duration = @duration		
END CATCH

GO
GRANT EXECUTE ON [dbo].[Age_CustSubPwdUpd] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Age_CustSubPwdUpd] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Age_CustSubPwdUpd] TO [vnteam] AS [dbo]