USE [CustDB]
GO
/*
  Creator: David
	Date: 2018-05-10
	DB: DBCUST.CustDB
	Task: Update secret key 

	Revisions:

	Param's Explanation:
*/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[EAS_OTP_CustomerOTPSecretKeyUpd] @CustID int,
@SecretKey nvarchar(50),
@Enabled bit = 1,
@ErrCode int = 0 OUTPUT,
@ErrMsg nvarchar(200) = '' OUTPUT
AS
BEGIN
  SET NOCOUNT ON
  DECLARE @startRun datetime,
          @endRun datetime,
          @duration int,
          @LogSPData varchar(max),
          @ActionID int
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
GRANT EXECUTE ON [dbo].[EAS_OTP_CustomerOTPSecretKeyUpd] TO [bodbExtAccNet]
GO