/****** Object:  StoredProcedure [dbo].[Acc_CreditTermUpdSetGroupHeadline]    Script Date: 06/24/2008 19:07:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
ALTER PROCEDURE [dbo].[Acc_CreditTermUpdSetGroupHeadline]
	@CustID int,
	@groupID int,
	@UserID int,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT,
	@Language varchar(2)= 'E',
	@IP varchar(15) = ''
AS
--Original: ADMIN\account\creditterm_group_feed_add.asp
/*	Created by: [Creator]
	Revisions:
		- 20090828@HuyNguyen: replace [Customer] --> [OtherCust]
		- 20090919@Shifu: Log IP
		- 20100112@Kiwi: amend to write log in xml format.				
*/
SET NOCOUNT ON
--Check an account disabled or not
 EXEC DB052.bodb02.dbo.Acc_CustomerSelCheckEnable @custid = @CustID, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
 if @ErrCode <>0        return

--Check permission for account site: @phuc20080213
EXEC db03.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[OtherCust]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
If @ErrCode <> 0
	RETURN
--end

if NOT exists (select 1 from custaccount with (nolock) where custid = @custid and groupid = @groupID)
BEGIN
	SELECT @ErrMsg = 'This user does not belong to this group.',
		@ErrCode = 101
	Return
END
declare @oldchecker int 
select @oldchecker = checker from custaccount 
where groupid =@groupid and isgroupheadline = 1 

update custAccount set Isgroupheadline = 0 ,checker = 0 where groupid = @groupID

update custAccount set Isgroupheadline = 1, checker = @oldchecker where custid = @CustID


declare @LogData nvarchar(1000)
Select @LogData = '<Acc_CreditTermUpdSetGroupHeadline Custid="' + convert(varchar(20), @CustID) + '" ' +
'GroupID="' + convert(varchar(20), @groupID) + '" ' +
'IP="'+ coalesce(cast(@IP as varchar(15)),space(1)) + '" ' +
'ErrCode="'+ coalesce(cast(@ErrCode as varchar(10)),space(1)) + '" ' +
'ErrMsg="'+ @ErrMsg  + '" />'

EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew 
	@UserID = @UserID,
	@CustID = @CustID,
	@ActionID = 1003,
	@TrackingValue = @LogData

GO
GRANT EXECUTE ON [dbo].[Acc_CreditTermUpdSetGroupHeadline] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CreditTermUpdSetGroupHeadline] TO [vnteam]
