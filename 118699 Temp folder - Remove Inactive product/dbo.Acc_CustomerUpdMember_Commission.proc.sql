/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,bodbDownlineNet,bodbExtAccNet,bodbDownlineNetView" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerUpdMember_Commission]
	@custid INT,-- MemberId
	@playerdiscount DECIMAL(9,8),
	@playerdiscountcs DECIMAL(9,8),	
	@playerdiscount1x2 DECIMAL(9,8)=0,
	
	@updatecomm_old BIT = 1,
	@SubAccID INT = 0, --Sub-AccountID
	@UserID INT = 0,	
	@Language VARCHAR(2) = 'E',
	@IP VARCHAR(15)='',
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(4000) = '' OUTPUT
AS
BEGIN
--@Source Control
/*
Created: 20080514@Thien
Task : Update Member's Commission
DB: DBTXN/bodb02
Original:

Revisions:
    - 20090314@HanhVu: add Korean language
    - 20090424@Phuc:Separate finance sporttype(201).
					Write log subaccname instead of subaccid.
    - 20090514@PhuongDao: Add 1x2 Commission
	- 20090917@Phuc: write log into DBLOG.
	- 20100112@Phuc: hardcode not to update commission for member under agent 8RM.
	- 20100112@Kiwi: amend to write log in xml format.
	- 20100830@Henry: Amend to update commission for Number Game
	- 20101019@Henry: Record execution time
	- 20110603@Amy: Write log Old values
	- 20110930@Johnson: Add more group under Won currency
	- 20120412@Hurri: hardcode not to update commission for member under agent BARM.
	- 20120522@Sophia: Remove hardcode not to update commission for member under agent BARM.
	- 20121128@Elodie: Get an error message from f_Get_MsgNameByMsgID function by language
	- 20130218@Dan: Write more log on DBTXN server in case of DBLOG server failure
	- 20131011@Elodie: Add HR Fixed Odds [Redmine:#6505]
	- 20131029@Kathy: Apply exec rep to update commission [Redmine:#3244]
	- 20150904@Helen: commission setting for MO [Redmine #41470]
	- 20180125@Winnie: Hide inactive products [RedmineID: #86086]		
Param's Explanation:
• @ErrCode:
    = 0: Update successfully.
    > 0: Specific Error.
  
• @ErrMsg: Error description.
*/

	SET NOCOUNT ON

	declare @startRun datetime
	declare @endRun datetime
	declare @duration int
	set @startRun = getdate()

	DECLARE @Old_playerdiscount DECIMAL(9,8),
			@Old_playerdiscountcs DECIMAL(9,8),	
			@Old_playerdiscount1x2 DECIMAL(9,8)

	--Check Param
	IF	@playerdiscount<0 OR @playerdiscount>0.2
		OR @playerdiscountcs<0 OR @playerdiscountcs>0.2
		OR @playerdiscount1x2<0 OR @playerdiscount1x2>0.2
	BEGIN	
		SELECT @ErrMsg = CASE @Language 
							WHEN 'E' THEN 'Invalid commission rate.'
							ELSE [dbo].[f_Get_MsgNamebyMsgID](1,@Language)
						END, @ErrCode = 101
								
		RETURN
	END
	
	---------------------------------------
	DECLARE @username VARCHAR(40), @recommend INT,
			@discount DECIMAL(9,8), @discountcs DECIMAL(9,8), @discount1x2 DECIMAL(9,8),@ugroup VARCHAR(10)
	declare @err1 int, @err2 int
			
	SELECT @UserName  = username,
			@recommend = recommend,
			@ugroup = c.ugroup
	FROM customer c WITH (NOLOCK) WHERE CustID = @CustID
	
	IF @updatecomm_old = 1
	BEGIN
		SELECT @Old_playerdiscount=playerdiscount FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND sporttype=1 AND bettype=1
		SELECT @Old_playerdiscountcs=playerdiscount FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND sporttype = 1 AND bettype = 4
		SELECT @Old_playerdiscount1x2=playerdiscount FROM custsetting WITH (NOLOCK) WHERE custid = @custid AND sporttype = 1 AND bettype = 5

		--Get g2
		SELECT 
			@discount = CASE WHEN @ugroup IN ('a','hka','dea') THEN groupa 
							 WHEN @ugroup IN ('b','hkb','deb') THEN groupb 
							 WHEN @ugroup IN ('c','hkc','dec') THEN groupc 
							 WHEN @ugroup IN ('d','hkd','ded') THEN groupd ELSE groupa END
		FROM custsetting WITH (NOLOCK)
		WHERE custid = @recommend AND bettype=1 AND sporttype=1
		--Get a2
		SELECT @discountcs = discount
		FROM custsetting WITH (NOLOCK)
		WHERE custid = @recommend AND sporttype = 1 AND bettype = 4
		
		--1x2
		SELECT @discount1x2 = discount
		FROM custsetting WITH (NOLOCK)
		WHERE custid = @recommend AND sporttype = 1 AND bettype = 5
		

		--@playerdiscount>g2?g2:@playerdiscount 
		--@playerdiscountcs>a2?a2:@playerdiscountcs
		SELECT 
			@playerdiscount = CASE WHEN @playerdiscount>@discount THEN @discount ELSE @playerdiscount END,
			@playerdiscountcs = CASE WHEN @playerdiscountcs>@discountcs THEN @discountcs ELSE @playerdiscountcs END,
			@playerdiscount1x2 = CASE WHEN @playerdiscount1x2>@discount1x2 THEN @discount1x2 ELSE @playerdiscount1x2 END
		---------------------------------------
		Declare @RoleId int
		Select
			@RoleId = roleid
		from custInfo with(NOLOCK)
		where custid = @custid

			
		-- Apply exec rep
		
		exec Acc_CustSetting_06
			@CustId = @custid,
			@RoleId = @RoleId,
			@groupa = @playerdiscount ,
			@discountcs = @playerdiscountcs,			
			@discount1x2 = @playerdiscount1x2


	END


	Declare @LogSPData varchar(8000)
	Declare @TrackingValue2 varchar(8000)

	Select @LogSPData = '<Acc_CustomerUpdMember_Commission custid="'+ coalesce(cast(@custid as varchar(50)),space(1)) + '" ' +
	'playerdiscount="'+ coalesce(cast(@playerdiscount as varchar(50)),space(1)) + '" ' +
	'playerdiscountcs="'+ coalesce(cast(@playerdiscountcs as varchar(50)),space(1)) + '" ' +
	'playerdiscount1x2="'+ coalesce(cast(@playerdiscount1x2 as varchar(50)),space(1)) + '" ' 
	
	SET @LogSPData = @LogSPData +
	'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(30)),space(1)) + '" ' +
	'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" ' +
	'Language="'+ coalesce(cast(@Language as varchar(2)),space(1)) + '" ' +
	'IP="'+ coalesce(cast(@IP as varchar(15)),space(1)) + '" ' +
	'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" ' +
	'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(5000)),space(1))+ '" />'

	Select @TrackingValue2 = '<Acc_CustomerUpdMember_Commission custid="'+ coalesce(cast(@custid as varchar(50)),space(1)) + '" ' +
	'playerdiscount="'+ coalesce(cast(@Old_playerdiscount as varchar(50)),space(1)) + '" ' +
	'playerdiscountcs="'+ coalesce(cast(@Old_playerdiscountcs as varchar(50)),space(1)) + '" ' +
	'playerdiscount1x2="'+ coalesce(cast(@Old_playerdiscount1x2 as varchar(50)),space(1)) + '" ' 
	
	
	SET @TrackingValue2 = @TrackingValue2 + 
	'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(30)),space(1)) + '" ' +
	'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" ' +
	'Language="'+ coalesce(cast(@Language as varchar(2)),space(1)) + '" ' +
	'IP="'+ coalesce(cast(@IP as varchar(15)),space(1)) + '" ' +
	'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" ' +
	'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(5000)),space(1))+ '" />'


	set @endRun = getdate()
	set @duration  = datediff (millisecond,@startRun,@endRun)

	BEGIN TRY
		--Log customer info 
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
			@UserID = @UserID,
			@CustID = @CustID,
			@ActionID = 207,
			@TrackingValue = @LogSPData,
			@TrackingValue2 = @TrackingValue2,
			@duration = @duration
	END TRY
	BEGIN CATCH
		Select @LogSPData = '<Acc_CustomerUpdMember_Commission custid="'+ coalesce(cast(@custid as varchar(50)),space(1)) + '" ' +
		'playerdiscount="'+ coalesce(cast(@playerdiscount as varchar(50)),space(1)) + '" ' +
		'playerdiscountcs="'+ coalesce(cast(@playerdiscountcs as varchar(50)),space(1)) + '" ' +
		'playerdiscount1x2="'+ coalesce(cast(@playerdiscount1x2 as varchar(50)),space(1)) + '" ' 
		
			
		SET @LogSPData = @LogSPData +
		'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(30)),space(1)) + '" ' +
		'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" ' +
		'Language="'+ coalesce(cast(@Language as varchar(2)),space(1)) + '" ' +
		'IP="'+ coalesce(cast(@IP as varchar(15)),space(1)) + '" ' +
		'ErrCode="'+ coalesce(cast(ERROR_NUMBER() as varchar(50)),space(1)) + '" ' +
		'ErrMsg="'+ coalesce(cast(ERROR_MESSAGE() as varchar(5000)),space(1))+ '" />'

		Select @TrackingValue2 = '<Acc_CustomerUpdMember_Commission custid="'+ coalesce(cast(@custid as varchar(50)),space(1)) + '" ' +
		'playerdiscount="'+ coalesce(cast(@Old_playerdiscount as varchar(50)),space(1)) + '" ' +
		'playerdiscountcs="'+ coalesce(cast(@Old_playerdiscountcs as varchar(50)),space(1)) + '" ' +
		'playerdiscount1x2="'+ coalesce(cast(@Old_playerdiscount1x2 as varchar(50)),space(1)) + '" ' 
		
			
		SET @TrackingValue2 = @TrackingValue2 +
		'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(30)),space(1)) + '" ' +
		'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" ' +
		'Language="'+ coalesce(cast(@Language as varchar(2)),space(1)) + '" ' +
		'IP="'+ coalesce(cast(@IP as varchar(15)),space(1)) + '" ' +
		'ErrCode="'+ coalesce(cast(ERROR_NUMBER() as varchar(50)),space(1)) + '" ' +
		'ErrMsg="'+ coalesce(cast(ERROR_MESSAGE() as varchar(5000)),space(1))+ '" />'

		--Log customer info 
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
			@UserID = @UserID,
			@CustID = @CustID,
			@ActionID = 207,
			@TrackingValue = @LogSPData,
			@TrackingValue2 = @TrackingValue2,
			@duration = @duration
	END CATCH
END

GO
