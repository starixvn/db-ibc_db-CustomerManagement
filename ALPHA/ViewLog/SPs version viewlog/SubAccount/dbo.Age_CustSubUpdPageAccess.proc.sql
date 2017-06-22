ALTER PROCEDURE [dbo].[Age_CustSubUpdPageAccess]
	@custid int,
	@subaccid int,
	@UpdPageAccess varchar(10), --[A] or [B]
	@AddNew bit = 0,
	@Language varchar(2) = 'E',
	@LoginSubAccID int = 0, --Current Login Sub-AccountID
	@LoginIP varchar(20)='',
	@UserID int=0,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS
/*
Created: 
Task : Edit permission of Sub-Account
DB: DB02.bodb02
Original: CustSubUpdPageAccess

Revisions:    	
    - 20090318@Hanh: add Korean language
    - 20090402@Phuc:WriteLog_UserLog_RunSP, remove check page access for subaccount.				   
	- 20090917@Phuc: write log into DBLOG.
	- 20100112@Kiwi: amend to write log in xml format.
Param's Explanation:
• @ErrCode:
    = 0: Transaction recorded successfully.
    > 0: Specific Error.
  
• @ErrMsg: Error description.
*/
SET NOCOUNT ON
/*
Declare @spPageAccess varchar(10)
set @spPageAccess = '[NO]' --No Permission for Sub-Account on this Sp
Declare @SubAllow bit
Exec Age_CustSubCheckPageAccess @LoginSubAccID, @spPageAccess, @Language, @SubAllow OUTPUT
if @SubAllow = 0
	BEGIN
	select @ErrMsg = case @Language 
				when 'E' then 'Sorry, You don''t have Permission to update Sub-Account.'
				when 'CS' then N'对不起，您不允许修改子账号.'							
				when 'CT' then N'對不起, 您不允許修改子帳號.'
				when 'TH' then N'ขออภัย คุณไม่ได้รับอนุญาติที่จะปรับยอดเงินในบัญชีย่อย.'
				when 'J' then N'Sorry, You don''t have Permission to update Sub-Account.'
				when 'KO' then N'죄송합니다. 보조 계정의 업데이트가 허가 되지 않았습니다.'
				else N'Sorry, You don''t have Permission to update Sub-Account.'
			end	,@ErrCode=101		
		return	
	END
---------------------------
*/

update custsub
set PageAccess = Replace(PageAccess, @UpdPageAccess, '') + case @AddNew when 1 then @UpdPageAccess else '' end
where
	subaccid = @subaccid
	and custid = @custid

Declare @LogSPData varchar(5000)
---------------------------
-- ***Check Sub-Account***
-- For Edit Sub-Account
Select @LogSPData ='<Age_CustSubUpdPageAccess custid="'+ coalesce(cast(@custid as varchar(50)),space(1)) + '" ' +
'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(30)),space(1)) + '" ' +
'UpdPageAccess="'+ coalesce(cast(@UpdPageAccess as varchar(10)),space(1)) + '" ' +
'AddNew="'+ coalesce(cast(@AddNew as varchar(50)),space(1)) + '" ' +
'Language="'+ coalesce(cast(@Language as varchar(2)),space(1)) + '" ' +
'LoginSubAccID="'+ coalesce(cast(@LoginSubAccID as varchar(50)),space(1)) + '" ' +
'LoginIP="'+ coalesce(cast(@LoginIP as varchar(20)),space(1)) + '" ' +
'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" ' +
'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" ' +
'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(8000)),space(1)) + '" />'

---------------------------
EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew 
	@UserID = @UserID, 
	@CustID = @CustID,
	@ActionID = 611,
	@TrackingValue = @LogSPData
GO
GRANT  EXECUTE  ON [dbo].[Age_CustSubUpdPageAccess]  TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Age_CustSubUpdPageAccess] TO [vnteam]