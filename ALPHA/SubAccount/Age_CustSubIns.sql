/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_alp,wsv_alpv" viewers="vnteam" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CustSubIns]
(
	@subaccid int,
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
)
AS
/*
Created: 20080508
Task : Create new sub-account for agent
DB: DBCust/CustDB
Original: Age_CustSubIns

Revisions:    
    - 20090318@Hanh: add Korean language
	- 20090917@Phuc: write log into DBLOG.
	- 20100112@Kiwi: Amend to write log in xml format.
	- 20101021@Henry: Record execution time
	- 20110613@Sophia: Check duplicate with nickname (Username2)
	- 20110722@Sophia: Don't use prefix for Username2
	- 20120320@Sophia: Modify the message username to user name
	- 20121128@Elodie: Get an error message from f_Get_MsgNameByMsgID function by language
	- 20130218@Dan: Write more log on DBTXN server in case of DBLOG server failure
	- 20130328@Jamie: Add CustLoginInfoSub 
	- 20130424@Jamie: Set isForcedChangeSecurityCode = 1 WHEN Upline's SecurityCode NOT NULL
	- 20140709@Logan: Force using Security Code for SMA from all sites (except 789y) [Redmine:#18121]
	- 20180621@Razor: Add Message Customer Read Status [Redmind: #94705]
	- 20181002@Dominic: Check existing username/username2 in archived DB  [Redmine:99882]
	- 20190422@Elodie: Offer unique nickname for CN88 [Redmine:112287]
	- 20200602@Johnson: set max sub-acc = 30 for IBCIndo site [redmine:#135198]
	- 20221122@Johnson: move sp Age_MsgCustReadStatus_Ins to web [RedmineID: #180730]
	- 20240704@Helen: Revise code for scaleout dbcust - [Redmine:#206823]
	- 20241213@Johnson: Apply In-house replication for Credit Setting [RedmineID: #212684]
	- 20241230@Aries: Scale Out DBCUST - Apply Inhouse replication for the remaning tables [Redmine: #215627]

Param's Explanation:
• @ErrCode:
    = 0: Login successfully.
    > 0: Specific Error.
  
• @ErrMsg: Error description.
*/

SET NOCOUNT ON
declare @startRun datetime
declare @endRun datetime
declare @duration int
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
		@MaxOfSubAcc tinyint,
		@PwdExpiry	DATETIME
		
SELECT @PwdExpiry = DATEADD(DD, 30, GETDATE())

select @success = 0, @username = LTRIM(RTRIM(@username))

--check no of subacc (must <= @MaxOfSubAcc)
select @NoOfSubAcc = count(*) from custsub with (nolock) where custid = @custid

select @MaxOfSubAcc = CASE WHEN site = 'IBCIndo' THEN 30 
							ELSE CASE roleid when 4 then 15 else 10 end
							END
from customer with (nolock)
where custid = @custid

if @NoOfSubAcc >= @MaxOfSubAcc
BEGIN
	select @ErrMsg = case @Language 
			when 'E' then 'You have exceeded your sub-accounts limit.'
			ELSE [dbo].[f_Get_MsgNamebyMsgID](40008,@Language)
		end	,@ErrCode=103		
	return	
END

--Insert data to db
BEGIN TRY
	EXEC dbo.Age_CustSubIns_Detail
		 @subaccid	= @subaccid	
		,@custid	= @custid	
		,@username	= @username	
		,@userpwd	= @userpwd	
		,@firstname = @firstname 
		,@lastname	= @lastname	
		,@PageAccess= @PageAccess
		,@Language	= 'E'	
	
		,@ErrCode	= @ErrCode OUTPUT
		,@ErrMsg	= @ErrMsg OUTPUT
	
	IF ISNULL(@ErrCode,0) > 0 
	BEGIN
		SELECT @ErrMsg = CASE @Language 
						   WHEN 'E' then 'Create sub-account failed. Please try again.'
						   ELSE [dbo].[f_Get_MsgNamebyMsgID](40009,@Language)
						 END
			 , @ErrCode = 104
		RETURN	
	END


	DECLARE	@UplineSecurityCode			VARCHAR(50)
		  , @isForcedChangeSecurityCode	BIT

	SELECT @UplineSecurityCode		   = NULL,
		   @isForcedChangeSecurityCode = 0

	SELECT @UplineSecurityCode = SecurityCode
		 , @isForcedChangeSecurityCode = isForcedChangeSecurityCode
	  FROM dbo.CustLoginInfo WITH(NOLOCK)
	 WHERE CustID = @CustID

	IF @UplineSecurityCode IS NOT NULL OR @isForcedChangeSecurityCode = 1
		SELECT @isForcedChangeSecurityCode = 1

	INSERT INTO dbo.CustLoginInfoSub
	(
		SubAccID, CustID, OldUserPwd, PwdExpiry, LastChangedPwdDate, isFirstLogin,
		SecurityCodeCount, SecurityCode, isForcedChangeSecurityCode, LastChangedSecurityCodeDate,
		RepUpdateTime
	)
	VALUES
	(   
		@subaccid, @CustID, NULL, @PwdExpiry, GETDATE(), 1,
		0, NULL, @isForcedChangeSecurityCode, NULL,
		dbo.f_GetDateTime2()
	)
	
END TRY
BEGIN CATCH
	DELETE FROM custsub WITH(ROWLOCK)
	OUTPUT DELETED.subaccid, dbo.f_GetDateTime2()
	INTO custsub_Del_Inhouse(subaccid,RepUpdateTime)
	WHERE subaccid = @subaccid
	
	SELECT @ErrMsg = CASE @Language 
						WHEN 'E' THEN 'Create sub-account failed. Please try again.'
						ELSE [dbo].[f_Get_MsgNamebyMsgID](40009, @Language)
						END
			, @ErrCode = 105

	RETURN
END CATCH

SELECT @Success = 1
DECLARE @LogSPData varchar(5000)
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

set @endRun = getdate()
set @duration  = datediff (millisecond,@startRun,@endRun)

---------------------------
BEGIN TRY
	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
		@UserID = @UserID, 
		@CustID = @CustID,
		@ActionID = 612,
		@TrackingValue = @LogSPData,
		@duration = @duration
END TRY
BEGIN CATCH
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
			'ErrCode="'+ coalesce(cast(ERROR_NUMBER() as varchar(50)),space(1)) + '" ' +
			'ErrMsg="'+ coalesce(ERROR_MESSAGE(),space(1)) + '" />'
	
	EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
		@UserID = @UserID, 
		@CustID = @CustID,
		@ActionID = 612,
		@TrackingValue = @LogSPData,
		@duration = @duration
END CATCH
	

GO
