ALTER PROCEDURE [dbo].[Acc_CustomerUpdTransferOption]
	@CustId int,
	@TransferOption varchar(8),
	@UserID int = 0,
	@IP varchar(15) = '',
	@SubAccID int = 0, --Sub-AccountID
	@Language varchar(2) = 'E',
	@ReturnErrCode bit = 0,	
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
/*
Created: 
Task : Update transfer option.
DB: DB02.bodb02
Original: 

Revisions:
	- 20090818@Phuc: check page access and check upline closed first(call Age_CustSubCheckPageAccess)
	- 20090828@HuyNguyen: replace [Customer] --> [OtherCust]		
    - 20090402@Phuc: write log into DBLog.
    - 20091008@Kiwi: Remove WriteLog_UserLog
    - 20100107@Lewin: Modify @LogSPData, call new writelog function
Param's Explanation:
*/

--------------------------
-- ***Check Downline Belonging***
declare @roleid tinyint
EXEC DB052.bodb02.dbo.Age_CustomerSelCheckBelonging 
@SessionCustID = @UserID, 
@Custid = @CustId,
@roleid = @roleid OUTPUT
if (@roleid = 0) return
---------------------------

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

declare @TransferOption_dec tinyint

select @roleid = roleid from customer with (NOLOCK) where custid = @custid
select @TransferOption_dec = dbo.F_Binary_Decimal(@TransferOption)

--update himself:
if (@roleid = 4 AND @Custid >= 100)--normal super
	OR
	(@roleid = 3)--master
	OR
	(
		--(@roleid = 2 AND exists(select 1 from customer with (nolock) where custid = @custid and srecommend < 100))--agent of direct master
		--OR
		(exists(select 1 from customer with (nolock) where transferoption = 0 and custid = (select mrecommend from customer with (nolock) where custid = @custid))) --master of the agent is allowed to transfer all day 
	)
		update customer set transferoption = @TransferOption_dec where custid = @CustId
	

--update downline: 
if (@roleid = 4) and (@Custid >= 100)--normal super
	update customer with (ROWLOCK, UPDLOCK) set transferoption = @TransferOption_dec
	where roleid IN(2, 3) and srecommend = @custid		
else if (@roleid = 3) --master
	update customer with (ROWLOCK, UPDLOCK) set transferoption = @TransferOption_dec
	where roleid = 2 and mrecommend = @custid


DECLARE @LogSPData varchar(3000)
Select @LogSPData = '<Acc_CustomerUpdTransferOption CustId="'+ coalesce(cast(@CustId as varchar(50)),space(1)) + '" '+
					'TransferOption="'+ coalesce(cast(@TransferOption as varchar(8)),space(1))+'" '+
					'UserID="'+ coalesce(cast(@UserID as varchar(50)),space(1)) + '" '+
					'IP="'+ coalesce(cast(@IP as varchar(15)),space(1)) + '" '+
					'SubAccName="'+ coalesce(cast(dbo.f_GetSubUsername(@SubAccID) as varchar(30)),space(1)) + '" '+
					'Language="'+ coalesce(cast(@Language as varchar(2)),space(1))+'" '+
					'ReturnErrCode="'+ coalesce(cast(@ReturnErrCode as varchar(50)),space(1)) + '" '+
					'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" '+
					'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(400)),space(1))+'" />'

/*700 Acc_CustomerUpdTransferOption Update Transfer Condition */
EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew
	@UserID = @UserID,
	@CustID = @CustID,
	@ActionID = 700,
	@TrackingValue = @LogSPData


GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdTransferOption] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdTransferOption] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdTransferOption] TO [vnteam]