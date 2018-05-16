/*<info serverAlias="DBCUST-CustDB" executers="bodbExtAccNet" viewers="vnteam" isFunction="0"></info>*/
USE [CustDB]
GO

ALTER PROCEDURE [dbo].[EAS_OTP_CustomerOTPSecretKeyUpd] 
	@CustID INT,
	@SecretKey VARCHAR(50),
	@Enabled BIT = 1,
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(200) = '' OUTPUT
AS
/*
    Creator: David
	Date: 2018-05-10
	Task: Implement External OTP
	DB: DBCUST/CustDB

	Revisions:
		- 20180516@David: Update OTP Secret key [Redmine:#94192]

	Param's Explanation:
*/
BEGIN
  SET NOCOUNT ON
  DECLARE @startRun DATETIME,
          @endRun DATETIME,
          @duration INT,
          @LogSPData VARCHAR(max),
          @ActionID INT
  SELECT
    @startRun = GETDATE(),
    @ActionID = 933


  BEGIN TRY
    UPDATE [dbo].[EASCustOTP] WITH (ROWLOCK, UPDLOCK)
    SET [SecretKey] = @SecretKey,
        [Enabled] = @Enabled,
        [ModifiedDate] = GETDATE()
    WHERE dbo.EASCustOTP.CustID = @CustID
  END TRY
  BEGIN CATCH
    IF @@Error <> 0
    BEGIN
      SELECT
        @ErrMsg = 'Error! Error when reset OTP.',
        @ErrCode = 101
      RETURN
    END
  END CATCH

  -- write log
  SELECT
    @LogSPData = '<EAS_OTP_CustomerOTPSecretKeyUpd="' + COALESCE(CAST(@CustID AS varchar(10)), SPACE(1)) + '" '
    + 'ErrCode="' + COALESCE(CAST(@ErrCode AS varchar(10)), SPACE(1)) + '" '
    + 'ErrMsg="' + COALESCE(@ErrMsg, SPACE(1)) + '" />'
  SET @endRun = GETDATE()
  SET @duration = DATEDIFF(MILLISECOND, @startRun, @endRun)

  BEGIN TRY
    -- try to insert into DBLOG
    EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP @UserID = @CustID,
                                                           @CustID = @CustID,
                                                           @ActionID = @ActionID,
                                                           @TrackingValue = @LogSPData,
                                                           @duration = @duration
  END TRY
  BEGIN CATCH
    SELECT
      @LogSPData = '<EAS_OTP_CustomerOTPSecretKeyUpd custid="' + COALESCE(CAST(@CustID AS varchar(10)), SPACE(1)) + '" '
      + 'ErrCode="' + COALESCE(CAST(@ErrCode AS varchar(10)), SPACE(1)) + '" '
      + 'ErrMsg="' + ERROR_MESSAGE() + '" />'


    EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP @UserID = @CustID,
                                                     @CustID = @CustID,
                                                     @ActionID = @ActionID,
                                                     @TrackingValue = @LogSPData,
                                                     @duration = @duration
  END CATCH
END
GO
