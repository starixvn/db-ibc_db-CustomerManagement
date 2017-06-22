ALTER PROCEDURE [dbo].[Acc_CreditTermUpdAddToGroup]
	@username varchar(30),
	@groupID int,
	@UserID int,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@Language varchar(2)= 'E',
	@IP varchar(15) = ''
AS
--Original: adm_acct_UpdateCustAccount
/*	Created by: [Creator]
	Revisions:
		- 20090828@HuyNguyen: replace [Customer] --> [OtherCust]	
		- 20090916@Shifu: Write log to DB06			
		- 20090917@Phuc: Write log to dblog
		- 20100112@Kiwi: amend to write log in xml format.		
*/
SET NOCOUNT ON

--Check permission for account site: @phuc20080213
EXEC db03.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[OtherCust]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
If @ErrCode <> 0
	RETURN
--end
Declare @Custid int

select @custid = custid from customer with (nolock) where username = @username
select @custid = isnull(@custid, 0)

if @custid = 0
BEGIN
	SELECT @ErrMsg = 'Username is not valid',
		@ErrCode = 102
	Return
END

--Check an account disabled or not
 EXEC DB052.bodb02.dbo.Acc_CustomerSelCheckEnable @username = @username, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
 if @ErrCode <>0        return
--end

if exists (select 1 from custaccount with (nolock) where custid = @custid and isgroupheadline = 1)
BEGIN
	SELECT @ErrMsg = 'Cannot add this user because this user is already headline in some group.',
		@ErrCode = 103
	Return
END

Declare @creditgrade nvarchar(1),
	@preagreeamount money,
	@installmentamount money,
	@installmentdate nvarchar(50),
	@accountremark nvarchar(200)

select @creditgrade = creditgrade, 
	@installmentdate = installmentdate,
	@installmentamount = installmentamount,
	@preagreeamount = preagreeamount,
	@accountremark = ' '
from custaccount with (nolock)
where isgroupheadline = 1 and groupid = @groupID


EXEC dbo.Acc_CreditTermUpdCustAccount 
	@custid = @custid,
	@creditgrade = @creditgrade,
	@preagreeamount = @preagreeamount,
	@installmentamount = @installmentamount,
	@installmentdate = @installmentdate,
	@accountremark = @accountremark,
	@groupID = @groupID,
	@isgroupheadline = 0

declare @LogSPData nvarchar(1000)

Select @LogSPData = '<Acc_CreditTermUpdAddToGroup Custid="' + convert(varchar(20), @CustID) + '" ' +
'GroupID="'+ convert(varchar(20), @groupID) + '" ' +
'IP="'+ coalesce(cast(@IP as varchar(15)),space(1)) + '" ' +
'ErrCode="'+ coalesce(cast(@ErrCode as varchar(10)),space(1)) + '" ' +
'ErrMsg="'+ @ErrMsg  + '" />'
EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew 
	@UserID = @UserID,
	@CustID = @Custid,
	@ActionID = 1000,
	@TrackingValue = @LogSPData
	
GO
GRANT EXECUTE ON [dbo].[Acc_CreditTermUpdAddToGroup] TO [bodbAdminNet]	
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CreditTermUpdAddToGroup] TO [vnteam]