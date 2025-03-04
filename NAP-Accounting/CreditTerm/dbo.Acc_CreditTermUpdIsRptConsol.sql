/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CreditTermUpdIsRptConsol]
	@CustId INT,
	@IsRptConsol BIT,
	@UserID INT,
	@ErrCode INT=0 OUTPUT,
	@ErrMsg NVARCHAR(200)='' OUTPUT
AS 
BEGIN
		
	SET NOCOUNT ON
	/*	Created by: Elodie
		Date: 20130611
		Task: Update IsRptConsol field for credit term headline
		DB: DBTXN/BODB02
		Original: 
		
		Revisions:
			- 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]
			- 20240805@Tacy: Remove linked-server/cross-db on NAP_UserControl [redmineID: #208402]
			- 20241231@Hughie: Scale Out DBCUST - Apply Inhouse replication for the remaning tables [Redmine: #215627]
			
		Example:	DECLARE @ErrCode INT, @ErrMsg NVARCHAR(200)
					EXEC Acc_CreditTermUpdIsRptConsol @custId = 334521, @IsRptConsol = 1, @UserID = 8, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT
					SELECT @ErrCode, @ErrMsg
			
							   
	*/
	DECLARE @startRun DATETIME
	DECLARE @endRun DATETIME
	DECLARE @duration INT
	SET @startRun = getdate()
	DECLARE @old_IsRptConsol BIT

	if not exists(select 1 from custAccount with (nolock) where custid = @CustId AND IsGroupHeadLine = 1)
	BEGIN
		Select 
			@ErrMsg = 'This group headline doesn''t exist',
			@ErrCode = 102
		RETURN 
	END

	SELECT @old_IsRptConsol = IsRptConsol FROM custAccount WITH (NOLOCK) WHERE custid = @CustId and IsGroupHeadLine = 1

	UPDATE CustAccount WITH (ROWLOCK, UPDLOCK)
	SET IsRptConsol = @IsRptConsol 
		,RepUpdateTime = dbo.f_GetDateTime2()
	WHERE custid = @CustId and IsGroupHeadLine = 1
	IF (@@ERROR <>0)
	BEGIN
		Select 
			@ErrMsg = 'Update unsuccessful.',
			@ErrCode = 103
		RETURN 
	END

	DECLARE @LogSPData NVARCHAR(400)
	DECLARE @TrackingValue2 NVARCHAR(400)

	Select @LogSPData = '<Acc_CreditTermUpdIsRptConsol IsRptConsol="' + convert(varchar(2), @IsRptConsol) + 
						'" ErrMsg="" />'
	Select @TrackingValue2 = '<Acc_CreditTermUpdIsRptConsol IsRptConsol="' + convert(varchar(2), @old_IsRptConsol) + 
							 '" ErrMsg="" />'

	set @endRun = getdate()
	set @duration  = datediff (millisecond,@startRun,@endRun)

	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
			@UserID = @UserID,
			@CustID = @CustId,
			@ActionID = 1006,
			@TrackingValue = @LogSPData,
			@TrackingValue2 = @TrackingValue2,
			@duration = @duration
	END TRY
	BEGIN CATCH		
		Select @LogSPData = '<Acc_CreditTermUpdIsRptConsol IsRptConsol="' + convert(varchar(20), @IsRptConsol) + 
							'" ErrMsg="'+ error_message() + '" />'
		Select @TrackingValue2 = '<Acc_CreditTermUpdIsRptConsol IsRptConsol="' + convert(varchar(20), @old_IsRptConsol) + 
								 '" ErrMsg="'+ error_message() + '" />'
							
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
			@UserID = @UserID,
			@CustID = @CustId,
			@ActionID = 1006,
			@TrackingValue = @LogSPData,
			@TrackingValue2 = @TrackingValue2,
			@duration = @duration
	END CATCH    
END
GO