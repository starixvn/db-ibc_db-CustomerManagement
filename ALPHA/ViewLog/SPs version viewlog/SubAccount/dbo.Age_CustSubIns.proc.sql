ALTER PROCEDURE [dbo].[Age_CustSubIns]
	@subaccid int OUTPUT,
	@custid int, -- agentid or masterid or superid
	@username varchar(30),
	@userpwd varchar(40),
	@firstname nvarchar(50) = '-',
	@lastname nvarchar(50) = '-',
	@PageAccess varchar(50),
	@success bit = 1 OUTPUT,
	@Language varchar(2) = 'E',
	@LoginSubAccID int = 0, --Current Login Sub-AccountID
	@LoginIP varchar(20)='',
	@UserID int=0,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS
/*
Created: 20080508
Task : Create new sub-account for agent
DB: DB02.bodb02
Original: Age_CustSubIns

Revisions:    
    - 20090318@Hanh: add Korean language
	- 20090917@Phuc: write log into DBLOG.
	- 20100112@Kiwi: Amend to write log in xml format.
Param's Explanation:
• @ErrCode:
    = 0: Login successfully.
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
			when 'E' then 'Sorry, You don''t have Permission to create new Sub-Account.'
			when 'CS' then N'对不起，您不允许增加新的子账号.'							
			when 'CT' then N'對不起, 您不允許增加新的子帳號.'
			when 'J' then N'Sorry, You don''t have Permission to create new Sub-Account.'
			when 'TH' then N'ขออภัย คุณไม่ได้รับอนุญาติที่จะเปิดบัญชีใหม่สำหรับลูกค้าย่อย.'
			when 'KO' then N'죄송합니다. 새로운 보조 계정을 만드는것이 허가 되지 않았습니다.'
			else N'Sorry, You don''t have Permission to create new Sub-Account.'
		end	,@ErrCode=101		
	return	
END
*/

---------------------------
Declare @ErrLog nvarchar(200),
		@NoOfSubAcc tinyint,
		@MaxOfSubAcc tinyint

select @success = 0, @username = replace(@username, ' ', '')

--check duplicate username
if (exists (select 1 from custsub with (nolock) where username = @username))
	or (exists (select 1 from customer with (nolock) where username = @username))
BEGIN
	select @ErrMsg = case @Language 
			when 'E' then 'This username is not available.'
			when 'CS' then N'此账号无效.'
			when 'CT' then N'此帳號無效.'
			when 'J' then N'ID確認できません。'
			when 'TH' then N'ชื่อที่ใช้ในการเข้าระบบนี้ ไม่สามารถใช้งานได้'
			when 'KO' then N'이 사용자 이름을 사용할 수 없습니다.'
			else N'This username is not available.'
		end	,@ErrCode=102		
	return	
END

--check no of subacc (must <= @MaxOfSubAcc)
select @NoOfSubAcc = count(*) from custsub with (nolock) where custid = @custid

select @MaxOfSubAcc = case roleid when 4 then 15 else 10 end
from customer with (nolock)
where custid = @custid

if @NoOfSubAcc >= @MaxOfSubAcc
BEGIN
	select @ErrMsg = case @Language 
			when 'E' then 'You have exceeded your sub-accounts limit.'
			when 'CS' then N'您已超出子账号限定.'
			when 'CT' then N'您已超出子帳號限定.'
			when 'J' then N'You have exceeded your sub-accounts limit.'
			when 'TH' then N'คูณมียอดเกินวงจำกัดบัญชีย่อยของคุณ.'
			when 'KO' then N'보조계정의 관리 한도를 초과 하였습니다.'
			else N'You have exceeded your sub-accounts limit.'
		end	,@ErrCode=103		
	return	
END

--Insert data to db
Insert into custsub
			(
			custid,
			username,
			userpwd,
			firstname,
			lastname,
			PageAccess,
			createdate			
			)
			VALUES
			(
			@custid,
			@username,			
			@userpwd,
			@firstname,
			@lastname,
			@PageAccess,
			getdate()
			)
			
Select @subaccid = @@IDENTITY

if @@error <> 0
BEGIN
	select @ErrMsg = case @Language 
			when 'E' then 'Create sub-account failed. Please try again.'
			when 'CS' then N'新增会员不成功，请重新尝试.'
			when 'CT' then N'新增會員不成功,請重新嘗試.'
			when 'J' then N'Create sub-account failed. Please try again.'
			when 'TH' then N'การเพิ่มจำนวนบัญชีย่อย ไม่สำเร็จ กรุณาทำรายการอีกครั้ง.'
			when 'KO' then N'보조계정 만들기에 실패했습니다. 다시 시도해 주시기 바랍니다.'
			else N'Create sub-account failed. Please try again.'
		end	,@ErrCode=104		
	return	
END


Select @Success = 1
Declare @LogSPData varchar(5000)
---------------------------
-- ***Check Sub-Account***
-- For Edit Sub-Account
Select @LogSPData ='<Age_CustSubIns subaccid="'+ coalesce(cast(@SubAccID as varchar(30)),space(1)) + '" ' +
'custid="'+ coalesce(cast(@custid as varchar(50)),space(1)) + '" ' +
'username="'+ coalesce(cast(@username as varchar(30)),space(1)) + '" ' +
'fname="'+ coalesce(cast(@firstname as varchar(100)),space(1)) + '" ' +
'lname="'+ coalesce(cast(@lastname as varchar(100)),space(1)) + '" ' +
'PageAccess="'+ coalesce(cast(@PageAccess as varchar(50)),space(1)) + '" ' +
'success="'+ coalesce(cast(@success as varchar(50)),space(1)) + '" ' +
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
	@ActionID = 612,
	@TrackingValue = @LogSPData

GO
GRANT  EXECUTE  ON [dbo].[Age_CustSubIns]  TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Age_CustSubIns] TO [vnteam]