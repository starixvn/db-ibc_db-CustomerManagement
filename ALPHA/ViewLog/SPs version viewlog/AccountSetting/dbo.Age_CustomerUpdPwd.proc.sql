ALTER PROCEDURE [dbo].[Age_CustomerUpdPwd]
    @CustID INT ,
    @UserPwd NVARCHAR(50) ,
    @UserID INT ,
    @DisCasino BIT = 0 ,
    @Language VARCHAR(2) = 'E' ,
    @SubAccID INT = 0 , --Sub-AccountID
    @LoginIP VARCHAR(20) = '' ,
    @ErrCode INT = 0 OUTPUT , --default no error
    @ErrMsg NVARCHAR(100) = '' OUTPUT
AS /*
Created: 
Task : Reset password for his downlines
DB: DB02.bodb02
Original: CustomerPwdUpd2

Revisions:
    - 20090311@HanhVu: Log information into UserLog_RunSP table					   
	- 20090729@Phuc: Write log subaccname instead of subaccid.
	- 20090818@Phuc: check page access and check upline closed first(call Age_CustSubCheckPageAccess)
	- 20090917@Phuc: write log into DBLOG.
	- 20091209@Terry: Checked Disable casino
	- 20100108@Lewin: Change SPLogDataFormat
Param's Explanation:
• @ErrCode:
    = 0: Transaction recorded successfully.
    > 0: Specific Error.
  
• @ErrMsg: Error description.
*/

    SET NOCOUNT ON

--Check disable user
    EXEC DB052.bodb02.dbo.Acc_CustomerSelCheckEnable @custid = @custid,
        @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT
    IF @ErrCode <> 0 
        RETURN
--end

    DECLARE @ErrLog NVARCHAR(50)
    DECLARE @PwdExpiry DATETIME
    SELECT  @pwdexpiry = DATEADD(dd, 30, GETDATE())

    IF ( @DisCasino = 1
         AND EXISTS ( SELECT    1
                      FROM      CustInfo WITH ( NOLOCK )
                      WHERE     SyncCasino = 1
                                AND Custid = @CustID )
       ) 
        BEGIN
            SELECT  @ErrMsg = CASE @Language
                                WHEN 'E'
                                THEN 'This CHANGED PASSWORD function is temporarily unavailable, please update later.'
                                WHEN 'CS'
                                THEN N'This CHANGED PASSWORD function is temporarily unavailable, please update later.'
                                WHEN 'CT'
                                THEN N'This CHANGED PASSWORD function is temporarily unavailable, please update later.'
                                WHEN 'TH'
                                THEN N'This CHANGED PASSWORD function is temporarily unavailable, please update later.'
                                WHEN 'J'
                                THEN N'This CHANGED PASSWORD function is temporarily unavailable, please update later.'
                                WHEN 'KO'
                                THEN N'This CHANGED PASSWORD function is temporarily unavailable, please update later.'
                                ELSE N'This CHANGED PASSWORD function is temporarily unavailable, please update later.'
                              END ,
                    @ErrCode = 100
            RETURN
        END



    UPDATE  customer WITH ( ROWLOCK, UPDLOCK )
    SET     userpwd = @UserPwd ,
            pwdexpiry = @PwdExpiry
    WHERE   custid = @CustID

    DECLARE @LogData NVARCHAR(200)

    SELECT  @LogData = '<Age_CustomerUpdPwd  UserID="' + CONVERT(VARCHAR(20), @CustID)
            + '" IP="' + @LoginIP +'" '
---------------------------
-- ***Check Sub-Account***
    IF @SubAccID > 0 
        BEGIN
            SET @LogData =  @LogData + 'SubAccount="' + dbo.f_GetSubUsername(@SubAccID) + '"'
                
        END
---------------------------
	SET @LogData = @LogData + ' />'
	/*901	Age_CustomerUpdPwd	Reset Password*/
	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew
	@UserID = @UserID,
	@CustID = @CustID,
	@ActionID = 901,
	@TrackingValue = @LogData	

GO
GRANT EXECUTE ON [dbo].[Age_CustomerUpdPwd] TO [bodbDownlineNet]
GO 
GRANT VIEW DEFINITION ON [dbo].[Age_CustomerUpdPwd] TO [VNTeam]
GO
