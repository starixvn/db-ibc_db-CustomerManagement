ALTER PROCEDURE Acc_CreditTermUpdRemark
	@accountremark nvarchar(200),
	@CustId int,
	@UserID int,
	@ErrCode int=0 OUTPUT,
	@ErrMsg nvarchar(200)='' OUTPUT, 
	@Language varchar(2)= 'E',
	@accountremarkdate datetime = '' OUTPUT
AS 
BEGIN
	
SET NOCOUNT ON
/*	Created by: [Creator]
	Task: Update remarks on Credit term report
	Revisions:
		- 20090828@HuyNguyen: replace [Customer] --> [OtherCust]
		- 20100126@Kiwi: Amend to write log in xml format.			
*/
--Check permission for account site: @phuc20080213
EXEC db03.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[OtherCust]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
If @ErrCode <> 0
	RETURN

SELECT @accountremarkdate = CURRENT_TIMESTAMP

UPDATE CustAccount 
SET 
	accountremark = @accountremark, 
	accountremarkdate = @accountremarkdate
WHERE custid = @CustId
IF (@@ERROR <>0)
BEGIN
	Select @ErrMsg = 'Cannot update!!!',
		@ErrCode = 102
	RETURN 
END

declare @LogSPData nvarchar(400)

Select @LogSPData = '<Acc_CreditTermUpdRemark Custid="' + convert(varchar(20), @CustID) + '" ' +
'AccountRemark="'+ dbo.f_EncodeXMLValue(coalesce(cast(@accountremark as varchar(200)), space(1))) + '" '+
'AccountRemarkDate="'+ cast(@accountremarkdate as nvarchar(200))+ '" />'

EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew 
	@UserID = @UserID,
	@CustID = @Custid,
	@ActionID = 1004,
	@TrackingValue = @LogSPData

    
END
GO

GRANT EXECUTE ON [dbo].Acc_CreditTermUpdRemark TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].Acc_CreditTermUpdRemark TO [vnteam]
