ALTER PROCEDURE [dbo].[Acc_CustomerUpdDangercust]
	@CustID int,
	@DangerType tinyint,
	@DangerLevel int,
	@UserID int,
	@Language varchar(2) = 'E',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@IP varchar(15) = ''
AS
SET NOCOUNT ON
/*
Created: 
Task : Update Danger, Danger2, Danger3 fields , and write log content
DB: DB02.bodb02
Original:Accounting site

Revisions:	
	- 20090717@pluto: update danger by dangertype.
	- 20090801@Shifu: check disabled user
	- 20090828@HuyNguyen: replace [Customer] --> [OtherCust]		
	- 20090917@Phuc: Write log to dblog
	- 20091008@Kiwi: Remove WriteLog_UserLog	
	- 20091231@pluto: Writelog old value	
	- 20100102@Lewin: Change @LogSPData, using WriteLog_UserLog_RunSPNew to write log
Param's Explanation:
	@CustID: Id of member will be updated,
	@DangerType: type of danger,
	@DangerLevel: new danger level value,
*/		

--Check permission for account site: @phuc20080213
EXEC db03.bodb02.dbo.Acc_Con_CheckPermission @custid=@userid,@funcname='[OtherCust]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
If @ErrCode <> 0
	RETURN
--end

--Check disable user
EXEC DB052.bodb02.dbo.Acc_CustomerSelCheckEnable @custid = @custid, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
if @ErrCode <>0 return
--end

if exists (select 1 from customer (NOLOCK) where custid = @CustID)
BEGIN
declare @dangerfield as varchar(10)
declare @oldvalue as varchar(10)
if (@DangerType=1)
	Begin 
		set @oldvalue=(Select Danger from custInfo (NOLOCK) where custid=@CustID)
		update custInfo with (UPDLOCK,ROWLOCK)set 
			Danger = @DangerLevel 
		where custid = @custid
		
		set @dangerfield='Danger'
	end
	if (@DangerType=2)
	Begin 
		set @oldvalue=(Select Danger2 from custInfo (NOLOCK) where custid=@CustID)
		update custInfo with (UPDLOCK,ROWLOCK)set 
			Danger2 = @DangerLevel 
		where custid = @custid
		
		set @dangerfield='Danger2'
	end
	if (@DangerType=3)
	Begin 
		set @oldvalue=(Select Danger3 from custInfo (NOLOCK) where custid=@CustID)
		update custInfo with (UPDLOCK,ROWLOCK)set 
			Danger3 = @DangerLevel 
		where custid = @custid
		set @dangerfield='Danger3'
	end
END
else
BEGIN	
	Select @ErrMsg = 'Invalid user!!',
		@ErrCode = 101	
	return	
END

declare @LogSPData varchar(2000)

Select @LogSPData = '<Acc_CustomerUpdDangercust CustID="'+ coalesce(cast(@CustID as varchar(50)),space(1)) + '"'
					+' OldValue="' + coalesce(cast(@oldvalue as varchar(50)),space(1)) + '"' 
					+' ' + @dangerfield + '="'  + coalesce(cast(@DangerLevel as varchar(50)),space(1)) + '"'
					+ ' UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '"'
					+ ' Language= "'+ coalesce(cast(@Language as varchar(2)),space(1))+'"'
					+ ' ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '"'
					+ ' ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(400)),space(1))+'"'
					+ ' IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+'" />'

/* 1114	Acc_CustomerUpdDangercust	Update Dangerous status for member*/	

EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew
	@UserID = @UserID,
	@CustID = @CustID,
	@ActionID = 1114,
	@TrackingValue = @LogSPData


GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdDangercust] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdDangercust] TO [vnteam]