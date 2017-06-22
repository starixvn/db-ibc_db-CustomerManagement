ALTER PROCEDURE [dbo].[Acc_CreditTermUpdChecker]
	@CustId int,
	@CheckerID int,
	@UserID int,
	@ErrCode int=0 OUTPUT,
	@ErrMsg nvarchar(200)='' OUTPUT, 
	@Language varchar(2)= 'E'
AS 
BEGIN
	
SET NOCOUNT ON
--Check permission for account site: @phuc20080213
/*	Created by: [Creator]
	Date:  
	Task :
	DB: DBTXN\BODB02
	Original: 
	Revisions:
		- 20090828@HuyNguyen: replace [Customer] --> [OtherCust]	
		- 20130131@Elodie: Change link server DB03 to DBPOLICY
						   Amend to write log in xml format and write more log on DBTXN server in case of DBLOG server failure
						   
*/
DECLARE @startRun DATETIME
DECLARE @endRun DATETIME
DECLARE @duration INT
SET @startRun = getdate()
DECLARE @old_CheckerID INT

EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[OtherCust]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
If @ErrCode <> 0
	RETURN

if not exists(select 1 from DBPOLICY.bodb02.dbo.AccCustomer_1 with (nolock) where custid = @CheckerID and groupID = 111)
BEGIN
	Select 
		@ErrMsg = 'Invalid checker!',
		@ErrCode = 102
	RETURN 
END

SELECT @old_CheckerID = checker FROM custAccount WITH (NOLOCK) WHERE custid = @CustId
UPDATE CustAccount SET checker = @CheckerID 
WHERE custid = @CustId
IF (@@ERROR <>0)
BEGIN
	Select 
		@ErrMsg = 'Cannot update!!!',
		@ErrCode = 103
	RETURN 
END
DECLARE @LogSPData NVARCHAR(400)
DECLARE @TrackingValue2 NVARCHAR(400)

Select @LogSPData = '<Acc_CreditTermUpdChecker Checker="' + convert(varchar(20), @CheckerID) + 
					'" ErrMsg="" />'
Select @TrackingValue2 = '<Acc_CreditTermUpdChecker Checker="' + convert(varchar(20), @old_CheckerID) + 
						 '" ErrMsg="" />'

set @endRun = getdate()
set @duration  = datediff (millisecond,@startRun,@endRun)

BEGIN TRY
	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
		@UserID = @UserID,
		@CustID = @CustId,
		@ActionID = 1005,
		@TrackingValue = @LogSPData,
		@TrackingValue2 = @TrackingValue2,
		@duration = @duration
END TRY
BEGIN CATCH		
	Select @LogSPData = '<Acc_CreditTermUpdChecker Checker="' + convert(varchar(20), @CheckerID) + 
						'" ErrMsg="'+ error_message() + '" />'
	Select @TrackingValue2 = '<Acc_CreditTermUpdChecker Checker="' + convert(varchar(20), @old_CheckerID) + 
							 '" ErrMsg="'+ error_message() + '" />'
						
	EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
		@UserID = @UserID,
		@CustID = @CustId,
		@ActionID = 1005,
		@TrackingValue = @LogSPData,
		@TrackingValue2 = @TrackingValue2,
		@duration = @duration
END CATCH    
END

GO
GRANT EXECUTE ON [dbo].Acc_CreditTermUpdChecker TO [bodbAdminNet]