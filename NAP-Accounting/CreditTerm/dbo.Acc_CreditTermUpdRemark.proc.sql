/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CreditTermUpdRemark]
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
		DB: DBTXN\BODB02
		Revisions:
			- 20090828@HuyNguyen: replace [Customer] --> [OtherCust]
			- 20100126@Kiwi: Amend to write log in xml format.	
			- 20100917@Kiwi: Correct "convert wrong datatype when writing log"		
			- 20101021@Henry: Record execution time 
			- 20110607@Amy: Write log Old values
			- 20130131@Elodie: Change link server DB03 to DBPOLICY
							   Write more log on DBTXN server in case of DBLOG server failure
			- 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]
			- 20240805@Tacy: Remove linked-server/cross-db on NAP_UserControl [redmineID: #208402]
			- 20250102@Hughie: Scale Out DBCUST - Apply Inhouse replication for the remaning tables [Redmine: #215627]
										   
	*/


	declare @startRun datetime
	declare @endRun datetime
	declare @duration int
	set @startRun = getdate()
	declare @old_accountremark nvarchar(200)

	SELECT @accountremarkdate = CURRENT_TIMESTAMP

	SELECT @old_accountremark = accountremark FROM CustAccount WITH(NOLOCK) WHERE custid=@CustId

	IF @old_accountremark = @accountremark RETURN

	UPDATE CustAccount 
	SET 
		accountremark = @accountremark, 
		accountremarkdate = @accountremarkdate,
		RepUpdateTime = dbo.f_GetDateTime2()
	WHERE custid = @CustId
	IF (@@ERROR <>0)
	BEGIN
		Select @ErrMsg = 'Cannot update!!!',
			@ErrCode = 102
		RETURN 
	END

	declare @LogSPData nvarchar(400)
	declare @TrackingValue2 nvarchar(400)

	Select @LogSPData = '<Acc_CreditTermUpdRemark Custid="' + convert(varchar(20), @CustID) + '" ' +
	'AccountRemark="'+ dbo.f_EncodeXMLValue(coalesce(cast(@accountremark as nvarchar(200)), space(1))) + '" '+
	'AccountRemarkDate="'+ cast(@accountremarkdate as nvarchar(200))+ '" />'

	Select @TrackingValue2 = '<Acc_CreditTermUpdRemark Custid="' + convert(varchar(20), @CustID) + '" ' +
	'AccountRemark="'+ dbo.f_EncodeXMLValue(coalesce(cast(@old_accountremark as nvarchar(200)), space(1))) + '" '+
	'AccountRemarkDate="'+ cast(@accountremarkdate as nvarchar(200))+ '" />'


	set @endRun = getdate()
	set @duration  = datediff (millisecond,@startRun,@endRun)

	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
			@UserID = @UserID,
			@CustID = @Custid,
			@ActionID = 1004,
			@TrackingValue = @LogSPData,
			@TrackingValue2 = @TrackingValue2,
			@duration = @duration
	END TRY
	BEGIN CATCH
		Select @LogSPData = '<Acc_CreditTermUpdRemark Custid="' + convert(varchar(20), @CustID) + '" ' +
							'AccountRemark="'+ dbo.f_EncodeXMLValue(coalesce(cast(@accountremark as nvarchar(200)), space(1))) + '" '+
							'AccountRemarkDate="'+ cast(@accountremarkdate as nvarchar(200))+ '" ' +
							'ErrMsg="'+ error_message() + '" />'
							
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
			@UserID = @UserID,
			@CustID = @Custid,
			@ActionID = 1004,
			@TrackingValue = @LogSPData,
			@TrackingValue2 = @TrackingValue2,
			@duration = @duration
	END CATCH
    
END
GO