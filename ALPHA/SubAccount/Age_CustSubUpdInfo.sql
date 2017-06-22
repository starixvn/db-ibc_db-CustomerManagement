ALTER PROCEDURE [dbo].[Age_CustSubUpdInfo]
	@custid int,
	@subaccid int,
	@firstname nvarchar(50),
	@lastname nvarchar(50),
	@closed bit,
	@Language varchar(2) = 'E',
	@LoginSubAccID int = 0, --Current Login Sub-AccountID	
	@LoginIP varchar(20)='',
	@UserID int=0,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS
/*
Created: 
Task : Edit info of Sub-Account
DB: DBTXN/bodb02
Original: 

Revisions:    	
    - 20090318@Hanh: add Korean language			   
    - 20090402@Phuc: WriteLog_UserLog_RunSP, remove check page access for subaccount.			   
	- 20090917@Phuc: write log into DBLOG.
	- 20100112@Kiwi: amend to write log in xml format.
	- 20100917@Kiwi: Correct "convert wrong datatype when writing log"
	- 20101021@Henry: Record execution time
	- 20110606@Amy: Write log Old values
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
declare @duration int
set @startRun = getdate()
	
declare @old_firstname nvarchar(50),
	@old_lastname nvarchar(50),
	@old_closed bit
---------------------------
-- ***Check Sub-Account***
-- For Edit Sub-Account
--original SP: CustSubUpdInfo
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
*/
---------------------------

SELECT @old_firstname = firstname ,	@old_lastname = lastname ,@old_closed= closed
FROM custsub with (nolock)
	WHERE subaccid = @subaccid and custid = @custid
	
IF @old_firstname = @firstname AND 
	@old_lastname = @lastname AND 	
	@old_closed= @closed
RETURN

Update custsub with (rowlock, updlock)
set firstname = @firstname,
	lastname = @lastname,
	closed = @closed
where subaccid = @subaccid and custid = @custid

Declare @LogSPData varchar(max)
Declare @TrackingValue2 varchar(max)
---------------------------
-- ***Check Sub-Account***
-- For Edit Sub-Account
Select @LogSPData ='<Age_CustSubUpdInfo custid="'+ coalesce(cast(@custid as varchar(50)),space(1)) + '" ' +
	'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(30)),space(1)) + '" ' +
	'fname="'+ dbo.f_EncodeXMLValue(coalesce(cast(@firstname as nvarchar(50)),space(1))) + '" ' +
	'lname="'+ dbo.f_EncodeXMLValue(coalesce(cast(@lastname as nvarchar(50)),space(1))) + '" ' +
	'closed="'+ coalesce(cast(@closed as varchar(50)),space(1)) + '" ' +
	'Language="'+ coalesce(cast(@Language as varchar(2)),space(1)) + '" ' +
	'LoginSubAccID="'+ coalesce(cast(@LoginSubAccID as varchar(50)),space(1)) + '" ' +
	'LoginIP="'+ coalesce(cast(@LoginIP as varchar(20)),space(1)) + '" ' +
	'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" ' +
	'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" ' +
	'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(8000)),space(1)) + '" />'
	
Select @TrackingValue2 ='<Age_CustSubUpdInfo custid="'+ coalesce(cast(@custid as varchar(50)),space(1)) + '" ' +
	'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(30)),space(1)) + '" ' +
	'fname="'+ dbo.f_EncodeXMLValue(coalesce(cast(@old_firstname as nvarchar(50)),space(1))) + '" ' +
	'lname="'+ dbo.f_EncodeXMLValue(coalesce(cast(@old_lastname as nvarchar(50)),space(1))) + '" ' +
	'closed="'+ coalesce(cast(@old_closed as varchar(50)),space(1)) + '" ' +
	'Language="'+ coalesce(cast(@Language as varchar(2)),space(1)) + '" ' +
	'LoginSubAccID="'+ coalesce(cast(@LoginSubAccID as varchar(50)),space(1)) + '" ' +
	'LoginIP="'+ coalesce(cast(@LoginIP as varchar(20)),space(1)) + '" ' +
	'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" ' +
	'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" ' +
	'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(8000)),space(1)) + '" />'
	
set @endRun = getdate()
set @duration  = datediff (millisecond,@startRun,@endRun)	
---------------------------
BEGIN TRY	
	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		@UserID = @UserID, 
		@CustID = @CustID,
		@ActionID = 610,
		@TrackingValue = @LogSPData,
		@TrackingValue2 = @TrackingValue2,
		@duration = @duration
END TRY
BEGIN CATCH
	Select @LogSPData ='<Age_CustSubUpdInfo custid="'+ coalesce(cast(@custid as varchar(50)),space(1)) + '" ' +
		'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(30)),space(1)) + '" ' +
		'fname="'+ dbo.f_EncodeXMLValue(coalesce(cast(@firstname as nvarchar(50)),space(1))) + '" ' +
		'lname="'+ dbo.f_EncodeXMLValue(coalesce(cast(@lastname as nvarchar(50)),space(1))) + '" ' +
		'closed="'+ coalesce(cast(@closed as varchar(50)),space(1)) + '" ' +
		'Language="'+ coalesce(cast(@Language as varchar(2)),space(1)) + '" ' +
		'LoginSubAccID="'+ coalesce(cast(@LoginSubAccID as varchar(50)),space(1)) + '" ' +
		'LoginIP="'+ coalesce(cast(@LoginIP as varchar(20)),space(1)) + '" ' +
		'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" ' +
		'ErrCode="'+ coalesce(cast(ERROR_NUMBER() as varchar(50)),space(1)) + '" ' +
		'ErrMsg="'+ coalesce(cast(ERROR_MESSAGE() as varchar(8000)),space(1)) + '" />'
		
	Select @TrackingValue2 ='<Age_CustSubUpdInfo custid="'+ coalesce(cast(@custid as varchar(50)),space(1)) + '" ' +
		'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(30)),space(1)) + '" ' +
		'fname="'+ dbo.f_EncodeXMLValue(coalesce(cast(@old_firstname as nvarchar(50)),space(1))) + '" ' +
		'lname="'+ dbo.f_EncodeXMLValue(coalesce(cast(@old_lastname as nvarchar(50)),space(1))) + '" ' +
		'closed="'+ coalesce(cast(@old_closed as varchar(50)),space(1)) + '" ' +
		'Language="'+ coalesce(cast(@Language as varchar(2)),space(1)) + '" ' +
		'LoginSubAccID="'+ coalesce(cast(@LoginSubAccID as varchar(50)),space(1)) + '" ' +
		'LoginIP="'+ coalesce(cast(@LoginIP as varchar(20)),space(1)) + '" ' +
		'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" ' +
		'ErrCode="'+ coalesce(cast(ERROR_NUMBER() as varchar(50)),space(1)) + '" ' +
		'ErrMsg="'+ coalesce(cast(ERROR_MESSAGE() as varchar(8000)),space(1)) + '" />'
	
	EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		@UserID = @UserID, 
		@CustID = @CustID,
		@ActionID = 610,
		@TrackingValue = @LogSPData,
		@TrackingValue2 = @TrackingValue2,
		@duration = @duration		
END CATCH

GO
GRANT  EXECUTE  ON [dbo].[Age_CustSubUpdInfo]  TO [bodbDownlineNet]
GO
GRANT  EXECUTE  ON [dbo].[Age_CustSubUpdInfo]  TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Age_CustSubUpdInfo] TO [vnteam]
