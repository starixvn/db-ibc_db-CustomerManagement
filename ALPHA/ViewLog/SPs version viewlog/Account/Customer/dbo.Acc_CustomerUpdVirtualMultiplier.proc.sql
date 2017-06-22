ALTER PROCEDURE [dbo].[Acc_CustomerUpdVirtualMultiplier] 
	@custid int,
	@virtualmultiplier smallmoney,
	@UserID int,
	@IP varchar(15) = '',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(100) = '' OUTPUT
AS
/*
Created: 
Task : Update virtualmultiplier.
DB: DB02.bodb02
Original:

Revisions:
	- 20090917@Phuc: Write log into dblog.
	- 20091008@Kiwi: Remove WriteLog_UserLog
	- 20100107@Lewin: Change LogSPData format, write log by new function
Param's Explanation:
• @ErrCode:
    = 0: update successfully.
    > 0: Specific Error.
  
• @ErrMsg: Error description.
*/

SET NOCOUNT ON

--Check permission for account site: @phuc20080213
EXEC db03.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[VirtualRate]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
If @ErrCode <> 0
	RETURN
--end
--Check disable user
EXEC DB052.bodb02.dbo.Acc_CustomerSelCheckEnable @custid = @custid, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
if @ErrCode <>0 return
--end

declare @roleid int

declare @OldValue smallmoney

select @OldValue = virtualmultiplier from custinfo with (nolock) where custid = @custid

if @virtualmultiplier > 1.6 or @virtualmultiplier < 0.2
BEGIN
	select @ErrMsg	= N'Invalid virtual rate.', @ErrCode = 101
	return
END
/*
IF @currency <> 20 AND @UserID not IN (
		1274,	--steven
		2433,	--WAN
		44919,	--WONG
		55421,	--MELVIN
		25520,	--joe
		360418	--dbaThien
)
BEGIN
	select @ErrMsg	= N'You are not authorized to edit this value.', @ErrCode = 102
	return
END
*/

select @roleid = roleid from customer with (NOLOCK) where custid = @custid

select @virtualmultiplier = round(@virtualmultiplier, 2)

if @roleid = 4
BEGIN
	update custinfo with (ROWLOCK, UPDLOCK) set virtualmultiplier = @virtualmultiplier
	where srecommend = @custid
END
else if @roleid = 3
BEGIN
	update custinfo with (ROWLOCK, UPDLOCK) set virtualmultiplier = @virtualmultiplier
	where mrecommend = @custid
END
else if @roleid = 2
BEGIN
	update custinfo with (ROWLOCK, UPDLOCK) set virtualmultiplier = @virtualmultiplier
	where recommend = @custid
END
else if @roleid = 1
BEGIN
	update custinfo with (ROWLOCK, UPDLOCK) set virtualmultiplier = @virtualmultiplier
	where custid = @custid
END

Declare @LogSPData varchar(2000)
Select @LogSPData = '<Acc_CustomerUpdVirtualMultiplier CustID="'+ cast(@custid as varchar(50))+ '" ' +
					'NewValue="'+ cast(@virtualmultiplier as varchar(50))+ '" ' +
					'OldValue="'+ cast(@OldValue as varchar(50))+ '" ' +
					'UserID="'+ cast(@UserID as varchar(50))+ '" ' +
					'ErrCode="'+ cast(@ErrCode as varchar(50)) + '" '+
					'ErrMsg="'+ cast(@ErrMsg as varchar(50)) + '" '+
					'IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+'" />'

/*801 Acc_CustomerUpdVirtualMultiplier Update Virtual Rate */
EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew
	@UserID = @UserID,
	@CustID = @CustID,
	@ActionID = 801,
	@TrackingValue = @LogSPData
	
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdVirtualMultiplier] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdVirtualMultiplier] TO [vnteam]