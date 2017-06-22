ALTER PROCEDURE [dbo].[Acc_CustomerUpdMatchLimit]
	@custid int,
	@matchlimit smallmoney,
	@UserID int,
	@ReturnErrCode bit = 0,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS

SET NOCOUNT ON
/*	Created by: [Creator]
	Revisions:
		- 20090828@HuyNguyen: replace [Customer] --> [OtherCust]	
		- 20091008@Kiwi: Remove WriteLog_UserLog	
		- 20100106@Lewin: Replace @LogSPData	
*/
--Check permission for account site: @phuc20080213
EXEC db03.bodb02.dbo.Acc_Con_CheckPermission @custid=@userid,@funcname='[OtherCust]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output

If @ErrCode <> 0
BEGIN
	IF @ReturnErrCode = 0
		RAISERROR (@ErrMsg, 16, 1)
	RETURN
END
--end
--Check disable user
	EXEC DB052.bodb02.dbo.Acc_CustomerSelCheckEnable @custid = @custid, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
	if @ErrCode <>0 return
--end
declare @roleid int
if @matchlimit >1 or @matchlimit<0
BEGIN
	select @ErrMsg = 'Invalid credit per match value', @ErrCode = 101
	if @ReturnErrCode = 0
		RaisError (@ErrMsg, 16, 1)
	return
END

select @roleid = roleid from customer with (NOLOCK) where custid = @custid
select @matchlimit = round(@matchlimit, 2)
if @roleid = 4
BEGIN
	update custinfo with (ROWLOCK, UPDLOCK) set matchlimit = @matchlimit
	where srecommend = @custid
END
else if @roleid = 3
BEGIN
	update custinfo with (ROWLOCK, UPDLOCK) set matchlimit = @matchlimit
	where mrecommend = @custid
END
else if @roleid = 2
BEGIN
	update custinfo with (ROWLOCK, UPDLOCK) set matchlimit = @matchlimit
	where recommend = @custid
END

DECLARE @LogSPData VARCHAR(300)
SELECT @LogSPData = '<Acc_CustomerUpdMatchLimit CustID="' + convert(varchar(20), @CustID) 
					+ '" MatchLimit ="' + convert(varchar(20), @matchlimit) 
					+ '" UserId="' + convert(varchar(20), @UserID) + '" />'

/*800 Acc_CustomerUpdMatchLimit Update Max Exposure (%) */
EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew
	@UserID = @UserID,
	@CustID = @CustID,
	@ActionID = 800,
	@TrackingValue = @LogSPData	

GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdMatchLimit] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdMatchLimit] TO [vnteam]
