/*<info serverAlias="DBCUST-CUSTDB" executers="bodbDownlineNet,bodbExtAccNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CustomerSkipForceUpdPwd]
    @CustID INT ,
	@SubAccID INT = 0 , --Sub-AccountID
    @Language VARCHAR(2) = 'E' ,
    @LoginIP VARCHAR(20) = '' ,
    @ErrCode INT = 0 OUTPUT , --default no error
    @ErrMsg NVARCHAR(500) = '' OUTPUT
AS
/*
Created: 20200417@Eden
Task : Skip force Update Password
DB: DBCust/Custdb
Original:

Revisions:
    - 20200417@Eden: Alpha - Removing force change password [Redmine:#132012]					   
• @ErrCode:
    = 0: Transaction recorded successfully.
    > 0: Specific Error.
  
• @ErrMsg: Error description.

	DECLARE @ErrCode INT , @ErrMsg NVARCHAR(500)
	EXEC [Age_CustomerSkipForceUpdPwd]
		@CustID = 42614164,
		@SubAccID = 0 ,
		@Language = 'E' ,
		@LoginIP = '1.1.1.1' ,
		@ErrCode = @ErrCode OUTPUT ,
		@ErrMsg =  @ErrMsg OUTPUT
	SELECT @ErrCode,@ErrMsg

*/
BEGIN
    SET NOCOUNT ON
    
	DECLARE @startRun datetime
	DECLARE @endRun datetime
	DECLARE @duration int

	SET @startRun = getdate()
--Check disable user
    EXEC dbo.Acc_CustomerSelCheckEnable @custid = @custid,
        @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT
    IF @ErrCode <> 0 
        RETURN
	
    DECLARE  @PwdExpiry DATETIME
	
	IF EXISTS(	SELECT  TOP 1 1
				FROM	Customer WITH (NOLOCK) 
				WHERE	custid = @CustID AND pwdexpiry <> CONVERT(DATETIME,'01/01/1900')  AND roleID <> 1 AND lastlogged IS NOT NULL
			)
	BEGIN
		SELECT  @pwdexpiry = DATEADD(dd, 30, GETDATE())
	END
	ELSE
	BEGIN
		 SELECT  @ErrMsg = 'Skip Failed',
                 @ErrCode = 10001
         RETURN
	END
	
	UPDATE  customer WITH (ROWLOCK, UPDLOCK)
    SET     pwdexpiry = @PwdExpiry
    WHERE   custid = @CustID

	IF @SubAccID > 0
		UPDATE  CustLoginInfoSub WITH (UPDLOCK,ROWLOCK)
		SET		PwdExpiry			= @PwdExpiry
		WHERE	subaccid = @subaccid and custid = @custid
	
	SET @endRun = getdate()
	SET @duration  = datediff (millisecond,@startRun,@endRun)

	DECLARE @LogData NVARCHAR(4000)

	SELECT  @LogData = '<R IP="' + COALESCE(@LoginIP, SPACE(1)) + '" '

	IF @SubAccID > 0 
	BEGIN
		SET @LogData =  @LogData + 'SubAccount="' + dbo.f_GetSubUsername(@SubAccID) + '" '
	END

	SET @LogData = @LogData + ' />'

	EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
			@UserId				= @CustId,
			@CustId				= @CustId,
			@ActionId			= 945,
			@TrackingValue		= @LogData,
			@Duration			= @Duration

END
GO
