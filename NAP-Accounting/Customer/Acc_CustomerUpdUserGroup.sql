/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerUpdUserGroup]
	@username varchar(50), 
	@ugroup varchar(3),
	@userid int,
	@IP varchar(15) = '',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
 /*
Created:
Task : Update User group
DB: DBTXN/bodb02
Original:

Revisions:    
	- 20090827@Phuc: exclude 1x2 commission from other commission.
	- 20090828@HuyNguyen: replace [Customer] --> [OtherCust]
	- 20090917@Phuc: Write log into dblog.	
	- 20091008@Kiwi: Remove WriteLog_UserLog
	- 20091112@Simon: Write Log IP
	- 20091210@Kiwi: Don't need to exclude 201 because we separate to another table custsetting3rd
	- 20100107@Lewin: Modify @LogSPData, call new writelog function
	- 20101019@Henry: Record execution time
	- 20110907@Lukas: Change linked-server from DB052 -> DB053
	- 20110929@Johnson: Check member group under Won currency
	- 20130310@Lukas: change linked-server alias & add more write log section
	- 20150610@Kathy: Migrate custDB to new server DBCust (Move Acc_CustomerSelCheckEnable to DBCUST.CustDB) [Redmine:#36216]
	- 20150904@Helen: commission setting for MO [Redmine #41470]
	- 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]
	- 20190905@Eden: 3rd party products - Remove InActive Products Phase 2 [Redmine: #118699]
	- 20200918@Winfred: Reinsert MyanmarOdds [Redmine: #141926]	
	- 20230310@Helios: Customer Setting - Migrate Sportsbook to DCS [RedmineID: #193083] 
    - 20240805@Tacy: Remove linked-server/cross-db on NAP_UserControl [redmineID: #208402]
	- 20241209@Johnson: Apply In-house replication for Credit Setting [RedmineID: #212684]
Param's Explanation:
*/
BEGIN
	SET NOCOUNT ON

	declare @startRun datetime
	declare @endRun datetime
	declare @duration int
	set @startRun = getdate()

	declare @custid int, @currency INT, @old_ugroup varchar(3), @srecommend int, @mrecommend int, @recommend int
	declare @IsMyanmarOdds BIT = 0 -- MyanmarOdds
	Declare
		@SuperDiscount decimal(9,8),
		@MasterDiscount decimal(9,8),
		@AgentDiscount decimal(9,8),
		@PlayerDiscount decimal(9,8)

	select
		@custid = custid,
		@currency = currency,
		@IsMyanmarOdds	= CASE WHEN site = '76666B' THEN 1 ELSE 0 END,
		@old_ugroup = ugroup,
		@recommend = recommend, 
		@mrecommend = mrecommend, 
		@srecommend = srecommend
	from customer with(nolock)
	where
		username = @username
		and roleid = 1

	IF @IsMyanmarOdds = 1 AND @ugroup <> 'a'
	BEGIN
		Select @ErrMsg = 'Unable to assign this group to the customer.',
			@ErrCode = 105					 	
		return	
	END

	IF @currency = 45 AND @ugroup NOT IN ('dea','deb','dec','ded')
	BEGIN
		Select @ErrMsg = 'Unable to assign this group to the customer.',
			@ErrCode = 100					 	
		return	
	END

	if @currency <> 45 AND @ugroup not in ('a', 'b', 'c', 'd', 'hka', 'hkb', 'hkc', 'hkd')
	BEGIN
		Select @ErrMsg = 'Unable to assign this group to the customer.',
			@ErrCode = 101					 	
		return	
	END

	if isnull(@custid, 0) = 0
	BEGIN
		Select @ErrMsg = 'Invalid user. Member '+@username+' is not found.',
			@ErrCode = 102					 	
		return	
	END

	--Check disable user
	EXEC dbo.Acc_CustomerSelCheckEnable @custid = @custid, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
	if @ErrCode <>0 return
	--end


	if @ugroup = @old_ugroup
	BEGIN
		Select @ErrMsg = 'The user group of '+ @username + ' is already "' + @ugroup + '".',
			@ErrCode = 103					 	
		return	
	END

	if @ugroup like 'hk_'
	BEGIN
		if exists (select 1 from customer with (nolock) where custid = @recommend and site = 'INDO')
		BEGIN
			Select @ErrMsg = 'This user belongs to INDO site, so you cannot change to HK group.',
			@ErrCode = 104					 		
			return	
		END	
	END


	-- Collect Commission Upline
	SELECT 
		@SuperDiscount = MAX(CASE WHEN cda.CustID  =  @srecommend THEN cda.Discount END),
		@MasterDiscount = MAX(CASE WHEN cda.CustID =  @mrecommend THEN cda.Discount END),
		@AgentDiscount = MAX(CASE WHEN cda.CustID  =  @recommend THEN cda.Discount END)
	FROM CustDiscount3rd_Agent cda WITH (NOLOCK)
	WHERE cda.custid IN (@srecommend , @mrecommend , @recommend)
	AND cda.SportType = 1
	AND cda.bettype = (CASE
					WHEN @ugroup IN ('a' , 'hka' , 'dea') THEN 1
					WHEN @ugroup IN ('b' , 'hkb' , 'deb') THEN 3
					WHEN @ugroup IN ('c' , 'hkc' , 'dec') THEN 7
					ELSE 8
				 END)	
	
	-- Changed Commission of member Follow uGroup
	UPDATE cdm
		SET cdm.SuperDiscount	= @SuperDiscount
		, cdm.MasterDiscount	= @MasterDiscount
		, cdm.AgentDiscount	= @AgentDiscount
		, cdm.PlayerDiscount	=  CASE WHEN cdm.PlayerDiscount > @AgentDiscount THEN @AgentDiscount ELSE cdm.PlayerDiscount END
		, RepUpdateTime = dbo.f_GetDateTime2()
	FROM CustDiscount3rd_Member cdm WITH (ROWLOCK , UPDLOCK)
	WHERE cdm.custid = @CustID AND cdm.SportType = 1 AND cdm.bettype NOT IN (4 , 5)

	-- Changed uGroup Customer
	UPDATE Customer WITH (ROWLOCK , UPDLOCK)
	SET ugroup = @ugroup,
		RepUpdateTime = dbo.f_GetDateTime2()
	WHERE custid=@custid

	declare @LogSPData varchar(5000)

	Select @LogSPData = '<Acc_CustomerUpdUserGroup CustName="'+ @username + '" From="' + @old_ugroup 
						+ '" To="' + @ugroup +'" '+
						'Userid="'+ coalesce(cast(@userid as varchar(50)),space(1)) + '" '+
						'IP="'+ coalesce(cast(@IP as varchar(15)),space(1)) + '" '+
						'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" '+
						'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(400)),space(1))+'" />'

	set @endRun = getdate()
	set @duration  = datediff (millisecond,@startRun,@endRun)

	/*608 Acc_CustomerUpdUserGroup Change user group */
	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
			@UserID = @UserID,
			@CustID = @CustID,
			@ActionID = 608,
			@TrackingValue = @LogSPData,
			@duration = @duration
	END TRY
	BEGIN CATCH
		Select @LogSPData = '<Acc_CustomerUpdUserGroup CustName="'+ @username + '" From="' + @old_ugroup 
						+ '" To="' + @ugroup +'" '+
						'Userid="'+ coalesce(cast(@userid as varchar(50)),space(1)) + '" '+
						'IP="'+ coalesce(cast(@IP as varchar(15)),space(1)) + '" '+
						'ErrCode="'+ coalesce(cast(ERROR_MESSAGE() as varchar(50)),space(1)) + '" '+
						'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(400)),space(1))+'" />'
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
			@UserID = @UserID,
			@CustID = @CustID,
			@ActionID = 608,
			@TrackingValue = @LogSPData,
			@duration = @duration
	END CATCH
END
GO