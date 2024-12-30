/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_alp,wsv_xnap" viewers="" isFunction="0" isNested="0"></info>*/
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
	- 20200424@Eden: HotFix - Sub acc click skip then kicked out [#133141]					   
	- 20241206@Johnson: Apply In-house replication for Credit Setting [RedmineID: #212684]
	- 20241230@Aries: Scale Out DBCUST - Apply Inhouse replication for the remaning tables [Redmine: #215627]
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
	
	IF ISNULL(@SubAccID,0) = 0
	BEGIN
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
		SET     pwdexpiry = @PwdExpiry,
				RepUpdateTime = dbo.f_GetDateTime2()
		WHERE   custid = @CustID
	END

	IF @SubAccID > 0
	BEGIN
		IF EXISTS ( SELECT  TOP 1 1
					FROM CustLoginInfoSub s WITH (NOLOCK) 
						INNER JOIN custinfo c WITH (NOLOCK) ON c.custid = s.CustID
					WHERE s.custid = @CustID  AND s.SubAccID = @SubAccID AND s.pwdexpiry <> CONVERT(DATETIME,'01/01/1900')  AND c.roleID <> 1
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

		UPDATE  CustLoginInfoSub WITH (UPDLOCK,ROWLOCK)
		SET		PwdExpiry			= @PwdExpiry
			   ,RepUpdateTime		= dbo.f_GetDateTime2()
		WHERE	subaccid = @subaccid and custid = @custid
	END
	
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
