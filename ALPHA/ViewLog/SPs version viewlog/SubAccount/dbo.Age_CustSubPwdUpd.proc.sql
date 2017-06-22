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
DB: DB02.bodb02
Original: CustSubPwdUpd

Revisions:
    - 20090311@Hanh: Log information into UserLog_RunSP table		
    - 20090318@Hanh: add Korean language			   
	- 20090917@Phuc: write log into DBLOG.
	- 20100107@Kiwi: Amend writing log.
Param's Explanation:
• @ErrCode:
    = 0: Transaction recorded successfully.
    > 0: Specific Error.
  
• @ErrMsg: Error description.
*/
SET NOCOUNT ON
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
Update custsub with (rowlock, updlock)
set userpwd = @UserPwd
where subaccid = @subaccid and custid = @custid

Declare @LogData varchar(300)
Select @LogData = '<Age_CustSubPwdUpd SubAccount="' + convert(varchar(30),dbo.f_GetSubUsername(@SubAccID))
					 + '" IP="' + @LoginIP + '"/>'

EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew
	@UserID = @UserID,
	@CustID = @subaccid,
	@ActionID = 903,
	@TrackingValue = @LogData

GO
GRANT  EXECUTE  ON [dbo].[Age_CustSubPwdUpd]  TO [bodbDownlineNet]
GO
GRANT  EXECUTE  ON [dbo].[Age_CustSubPwdUpd]  TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Age_CustSubPwdUpd] TO [VNTeam]
