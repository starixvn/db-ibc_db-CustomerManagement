/*<info serverAlias="DBCUST-CustDB" executers="bodbDownlineNet,wsv_alp,bodbDownlineNetView,wsv_alpv" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CustSubUpdPageAccess]
	@custid int,
	@subaccid int,
	@UpdPageAccess varchar(50), --[A] or [B]
	--@AddNew bit = 0,
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
DB: DBCUST/CustDB
Original: CustSubUpdPageAccess

Revisions:    	
    - 20090318@Hanh: add Korean language
    - 20090402@Phuc:WriteLog_UserLog_RunSP, remove check page access for subaccount.				   
	- 20090917@Phuc: write log into DBLOG.
	- 20100112@Kiwi: amend to write log in xml format.
	- 20101021@Henry: Record execution time
	- 20110606@Amy: Write log Old value
	- 20111228@Sophia: Change the type of @Old_UpdPageAccess up to 50 character
	- 20120315@Lukas: Change the way update pages access, replace all pages access by new ones
	- 20130218@Dan: Write more log on DBTXN server in case of DBLOG server failure
Param's Explanation:
• @ErrCode:
    = 0: Transaction recorded successfully.
    > 0: Specific Error.
• @UpdPageAccess:
[A] : Create Account
[B] : Update Account
[C] : Transfer
[D] : Total Bets
[E] : Reports
[F] : Forecast
[G] : View log
[H] : Member Info


  
• @ErrMsg: Error description.
*/
SET NOCOUNT ON
declare @startRun datetime
declare @endRun datetime
declare @duration int
set @startRun = getdate()

declare @Old_UpdPageAccess varchar(50)

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

SELECT @Old_UpdPageAccess = PageAccess FROM custsub WITH (NOLOCK) WHERE subaccid = @subaccid and custid = @custid

IF @Old_UpdPageAccess = @UpdPageAccess RETURN


--update custsub
--set PageAccess = Replace(PageAccess, @UpdPageAccess, '') + case @AddNew when 1 then @UpdPageAccess else '' end
--where
--	subaccid = @subaccid
--	and custid = @custid

UPDATE custsub WITH(ROWLOCK,UPDLOCK)
SET PageAccess = @UpdPageAccess
WHERE custid = @custid AND subaccid = @subaccid

Declare @LogSPData varchar(5000)
Declare @TrackingValue2 varchar(5000)
---------------------------
-- ***Check Sub-Account***
-- For Edit Sub-Account
Select @LogSPData ='<Age_CustSubUpdPageAccess custid="'+ coalesce(cast(@custid as varchar(50)),space(1)) + '" ' +
'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(30)),space(1)) + '" ' +
'UpdPageAccess="'+ coalesce(cast(@UpdPageAccess as varchar(50)),space(1)) + '" ' +
--'AddNew="'+ coalesce(cast(@AddNew as varchar(50)),space(1)) + '" ' +
'Language="'+ coalesce(cast(@Language as varchar(2)),space(1)) + '" ' +
'LoginSubAccID="'+ coalesce(cast(@LoginSubAccID as varchar(50)),space(1)) + '" ' +
'LoginIP="'+ coalesce(cast(@LoginIP as varchar(20)),space(1)) + '" ' +
'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" ' +
'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" ' +
'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(8000)),space(1)) + '" />'

Select @TrackingValue2 ='<Age_CustSubUpdPageAccess custid="'+ coalesce(cast(@custid as varchar(50)),space(1)) + '" ' +
'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(30)),space(1)) + '" ' +
'UpdPageAccess="'+ coalesce(cast(@Old_UpdPageAccess as varchar(50)),space(1)) + '" ' +
--'AddNew="'+ coalesce(cast(@AddNew as varchar(50)),space(1)) + '" ' +
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
		@ActionID = 611,
		@TrackingValue = @LogSPData,
		@TrackingValue2 = @TrackingValue2,
		@duration = @duration
END TRY
BEGIN CATCH
	Select @LogSPData ='<Age_CustSubUpdPageAccess custid="'+ coalesce(cast(@custid as varchar(50)),space(1)) + '" ' +
	'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(30)),space(1)) + '" ' +
	'UpdPageAccess="'+ coalesce(cast(@UpdPageAccess as varchar(50)),space(1)) + '" ' +
	--'AddNew="'+ coalesce(cast(@AddNew as varchar(50)),space(1)) + '" ' +
	'Language="'+ coalesce(cast(@Language as varchar(2)),space(1)) + '" ' +
	'LoginSubAccID="'+ coalesce(cast(@LoginSubAccID as varchar(50)),space(1)) + '" ' +
	'LoginIP="'+ coalesce(cast(@LoginIP as varchar(20)),space(1)) + '" ' +
	'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" ' +
	'ErrCode="'+ coalesce(cast(ERROR_NUMBER() as varchar(50)),space(1)) + '" ' +
	'ErrMsg="'+ coalesce(cast(ERROR_MESSAGE() as varchar(8000)),space(1)) + '" />'

	Select @TrackingValue2 ='<Age_CustSubUpdPageAccess custid="'+ coalesce(cast(@custid as varchar(50)),space(1)) + '" ' +
	'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(30)),space(1)) + '" ' +
	'UpdPageAccess="'+ coalesce(cast(@Old_UpdPageAccess as varchar(50)),space(1)) + '" ' +
	--'AddNew="'+ coalesce(cast(@AddNew as varchar(50)),space(1)) + '" ' +
	'Language="'+ coalesce(cast(@Language as varchar(2)),space(1)) + '" ' +
	'LoginSubAccID="'+ coalesce(cast(@LoginSubAccID as varchar(50)),space(1)) + '" ' +
	'LoginIP="'+ coalesce(cast(@LoginIP as varchar(20)),space(1)) + '" ' +
	'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" ' +
	'ErrCode="'+ coalesce(cast(ERROR_NUMBER() as varchar(50)),space(1)) + '" ' +
	'ErrMsg="'+ coalesce(cast(ERROR_MESSAGE() as varchar(8000)),space(1)) + '" />'
	
	EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
		@UserID = @UserID, 
		@CustID = @CustID,
		@ActionID = 611,
		@TrackingValue = @LogSPData,
		@TrackingValue2 = @TrackingValue2,
		@duration = @duration
END CATCH
