/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerUpdImportant]
	@CustID int,
	@Important bit,
	@UserID int,
	@Language varchar(2) = 'E',
	@IP varchar(15) = '',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT	
AS

/*	Created by: [Creator]
	DB: DBCUST-CUSTDB
	Revisions:
		- 20090828@HuyNguyen: replace [Customer] --> [OtherCust]				
		- 20090917@Phuc: Write log to dblog	
		- 20091008@Kiwi: Remove WriteLog_UserLog
		- 20101021@Henry: Record execution time
		- 20110603@Amy: Check Old/New value
		- 20110907@Sophia: Change Linked Server from DB052 to DB053
		- 20110908@Lukas: Check is existed customer to update important
		- 20130306@Lukas: change linked-server alias
		- 20150606@Elodie: Separate CustDB to DBCUST server (Move Acc_CustomerSelCheckEnable to DBCUST.CustDB)
		- 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]
		- 20240805@Tacy: Remove linked-server/cross-db on NAP_UserControl [redmineID: #208402]
		- 20241209@Johnson: Apply In-house replication for Credit Setting [RedmineID: #212684]
*/
BEGIN
	SET NOCOUNT ON
	declare @startRun datetime
	declare @endRun datetime
	declare @duration int
	set @startRun = getdate()

	DECLARE @Old_Important bit

	--Check disable user
	EXEC Acc_CustomerSelCheckEnable @custid = @custid, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
	if @ErrCode <>0 return
	--end


	if exists (SELECT 1 FROM customer WITH(NOLOCK) WHERE custid = @CustID)
	BEGIN
		select @Old_Important=Important from customer (NOLOCK) where custid = @CustID

		IF @Old_Important = @Important 
			RETURN

		update customer with (ROWLOCK) 
		set Important = @Important,
			RepUpdateTime = dbo.f_GetDateTime2()
		where custid = @custid	
	END
	else
	BEGIN	
		Select @ErrMsg = 'Invalid user!!',
			@ErrCode = 101	
		return	
	END

	declare @LogSPData varchar(2000)

	SELECT @LogSPData = '<Acc_CustomerUpdImportant CustID="'+ coalesce(cast(@CustID as varchar(50)),space(1)) + '" '
						+ 'Important="'+ coalesce(cast(@Important as varchar(50)),space(1)) + '" '
						+ 'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" '
						+ 'Language="'+ coalesce(cast(@Language as varchar(2)),space(1))+'" '
						+ 'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" ' 
						+ 'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(400)),space(1))+'" '
						+ 'IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+'" />'

	set @endRun = getdate()
	set @duration  = datediff (millisecond,@startRun,@endRun)

	/*1106	Acc_CustomerUpdImportant	Update Special status*/
	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
			@UserID = @UserId,
			@CustID = @CustID,
			@ActionID =	1106,
			@TrackingValue = @LogSPData,
			@duration = @duration
	END TRY
	BEGIN CATCH
		SELECT @LogSPData = '<Acc_CustomerUpdImportant CustID="'+ coalesce(cast(@CustID as varchar(50)),space(1)) + '" '
						+ 'Important="'+ coalesce(cast(@Important as varchar(50)),space(1)) + '" '
						+ 'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" '
						+ 'Language="'+ coalesce(cast(@Language as varchar(2)),space(1))+'" '
						+ 'ErrCode="'+ coalesce(cast(ERROR_MESSAGE() as varchar(50)),space(1)) + '" ' 
						+ 'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(400)),space(1))+'" '
						+ 'IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+'" />'
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
			@UserID = @UserId,
			@CustID = @CustID,
			@ActionID =	1106,
			@TrackingValue = @LogSPData,
			@duration = @duration
	END CATCH

END
GO