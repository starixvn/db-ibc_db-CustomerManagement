ALTER PROCEDURE [dbo].[Acc_CustomerUpdAbnormal]
	@CustID int,
	@UpdateDownline bit = 0,
	@AbnormalLevel int=0,
	@UserID int,
	@Language varchar(2) = 'E',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@IP varchar(15) = ''
AS
/*
	Created: 20120822@Elodie
	Task: Update Abnormal level and write log
	DB: DBTXN/bodb02

	Revisions:	
		- 20130306@Lukas: change linked-server alias & add more write log section
		- 20150606@Elodie: Separate CustDB to DBCUST server (Move Acc_CustomerSelCheckEnable to DBCUST.CustDB)
		
	Param's Explanation:
		@CustID: Id of member will be updated
		@@AbnormalLevel: new abnormal level value
*/
Begin
	SET NOCOUNT ON
	declare @startRun datetime
	declare @endRun datetime
	declare @duration int, @roleid int
	set @startRun = getdate()

	--Check permission for account site:
	EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@userid,@funcname='[OtherCust]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
	If @ErrCode <> 0
		RETURN
	--end

	--Check disable user
	EXEC Acc_CustomerSelCheckEnable @custid = @custid, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
	if @ErrCode <> 0 
		return
	--end

	if exists (select 1 from customer (NOLOCK) where custid = @CustID)
	BEGIN
		select @roleid = roleid from custinfo (nolock) where custid = @custid

		declare @OldAbnormal as varchar(10)
		set @OldAbnormal = (Select Abnormal from custInfo (NOLOCK) where custid = @CustID)
		
		if @roleid = 2 and @updateDownline = 1 
		BEGIN
			update custinfo with(UPDLOCK,ROWLOCK)
			set Abnormal = @AbnormalLevel
			where recommend= @custid
		END
		else
		BEGIN
			update custInfo with (UPDLOCK,ROWLOCK)
			set Abnormal = @AbnormalLevel
			where custid = @custid
		END					
	END
	else
	BEGIN	
		Select @ErrMsg = 'Invalid user!!',
			   @ErrCode = 101	
		return	
	END

	declare @LogSPData varchar(2000)

	Select @LogSPData = '<Acc_CustomerUpdAbnormal CustID="' + coalesce(cast(@CustID as varchar(50)),space(1)) + '"'
						+ ' OldAbnormal="' + coalesce(cast(@OldAbnormal as varchar(50)),space(1)) + '"' 
						+ ' NewAbnormal="' + coalesce(cast(@AbnormalLevel as varchar(50)),space(1)) + '"'
						+ ' UpdateDownline="' + coalesce(convert(varchar(1),@UpdateDownline),space(1)) + '"'
						+ ' UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '"'
						+ ' Language= "'+ coalesce(cast(@Language as varchar(2)),space(1))+'"'
						+ ' ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '"'
						+ ' ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(400)),space(1))+'"'
						+ ' IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+'" />'

	set @endRun = getdate()
	set @duration  = datediff (millisecond,@startRun,@endRun)

	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
			@UserID = @UserID,
			@CustID = @CustID,
			@ActionID = 1137,
			@TrackingValue = @LogSPData,
			@duration = @duration
	END TRY
	BEGIN CATCH
		Select @LogSPData = '<Acc_CustomerUpdAbnormal CustID="' + coalesce(cast(@CustID as varchar(50)),space(1)) + '"'
						+ ' OldAbnormal="' + coalesce(cast(@OldAbnormal as varchar(50)),space(1)) + '"' 
						+ ' NewAbnormal="' + coalesce(cast(@AbnormalLevel as varchar(50)),space(1)) + '"'
						+ ' UpdateDownline="' + coalesce(convert(varchar(1),@UpdateDownline),space(1)) + '"'
						+ ' UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '"'
						+ ' Language= "'+ coalesce(cast(@Language as varchar(2)),space(1))+'"'
						+ ' ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '"'
						+ ' ErrMsg="'+ coalesce(cast(ERROR_MESSAGE() as varchar(400)),space(1))+'"'
						+ ' IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+'" />'
						
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
			@UserID = @UserID,
			@CustID = @CustID,
			@ActionID = 1137,
			@TrackingValue = @LogSPData,
			@duration = @duration
	END CATCH
End

GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdAbnormal] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdAbnormal] TO [vnteam]