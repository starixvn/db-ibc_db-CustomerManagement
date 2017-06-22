ALTER PROCEDURE dbo.Acc_CustomerUpdImportant
	@CustID int,
	@Important bit,
	@UserID int,
	@Language varchar(2) = 'E',
	@IP varchar(15) = '',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT	
AS
SET NOCOUNT ON
/*	Created by: [Creator]
	Revisions:
		- 20090828@HuyNguyen: replace [Customer] --> [OtherCust]				
		- 20090917@Phuc: Write log to dblog	
		- 20091008@Kiwi: Remove WriteLog_UserLog
*/


--Check permission for account site: @phuc20080213
EXEC db03.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[OtherCust]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
If @ErrCode <> 0
	RETURN
--end
--Check disable user
EXEC DB052.bodb02.dbo.Acc_CustomerSelCheckEnable @custid = @custid, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
if @ErrCode <>0 return
--end

if exists (select 1 from customer (NOLOCK) where custid = @CustID)
BEGIN
	update customer with (ROWLOCK) set Important = @Important
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


/*1106	Acc_CustomerUpdImportant	Update Special status*/
EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew
	@UserID = @UserId,
	@CustID = @CustID,
	@ActionID =	1106,
	@TrackingValue = @LogSPData

GO
GRANT  EXECUTE  ON [dbo].[Acc_CustomerUpdImportant]  TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdImportant] TO [vnteam]