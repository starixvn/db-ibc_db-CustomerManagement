ALTER PROCEDURE [dbo].[Age_CustomerUpdUserInfo]
    @custid INT , --customer to be updated
    @firstname NVARCHAR(50) ,
    @lastname NVARCHAR(50) ,
    @phone NVARCHAR(50) ,
    @mobilephone NVARCHAR(50) ,
    @email NVARCHAR(50) ,
    @fax NVARCHAR(50) ,
    @discasino BIT = 0 ,
    @IP AS VARCHAR(15) = '' ,
    @userid INT , --updater Id	
    @subaccid INT = 0 , --Sub-AccountID
    @language VARCHAR(2) = 'E' ,
    @errorcode INT = 0 OUTPUT ,
    @errormsg NVARCHAR(200) = '' OUTPUT
AS /*
Created: 20090211@nqminh
Task : Select customer information
DB: DB02.bodb02
Original:

Revisions:
    - 20090318@Hanh: add Korean language
	- 20090729@Phuc: Write log subaccname instead of subaccid.
	- 20090818@Phuc: check page access and check upline closed first(call Age_CustSubCheckPageAccess)
	- 20090917@Phuc: write log into DBLOG.
	- 20091008@Kiwi: Remove WriteLog_UserLog
	- 20091125@Terry: Check disable casino
	- 20100108@Lewin: Change SP format
Param's Explanation:
• @custid: custid that need to be viewed.   
*/

    SET NOCOUNT ON

--Check disable user
    EXEC DB052.bodb02.dbo.Acc_CustomerSelCheckEnable @custid = @custid,
        @ErrCode = @errorcode OUTPUT, @ErrMsg = @errormsg OUTPUT
    IF @errorcode <> 0 
        RETURN
--end

    IF @disCasino = 1 
        BEGIN	
            SELECT  @errormsg = CASE @Language
                                  WHEN 'E'
                                  THEN 'This USER INFO function is temporarily unavailable, please update later.'
                                  WHEN 'CS'
                                  THEN N'This USER INFO function is temporarily unavailable, please update later.'
                                  WHEN 'CT'
                                  THEN N'This USER INFO function is temporarily unavailable, please update later.'
                                  WHEN 'TH'
                                  THEN N'This USER INFO function is temporarily unavailable, please update later.'
                                  WHEN 'J'
                                  THEN N'This USER INFO function is temporarily unavailable, please update later.'
                                  WHEN 'KO'
                                  THEN N'This USER INFO function is temporarily unavailable, please update later.'
                                  ELSE N'This USER INFO function is temporarily unavailable, please update later.'
                                END ,
                    @errorcode = 100
            RETURN
        END


--Do update
    UPDATE  Customer WITH ( ROWLOCK )
    SET     firstname = @firstname ,
            lastname = @lastname ,
            phone = @phone ,
            mobilephone = @mobilephone ,
            email = @email ,
            fax = @fax
    WHERE   custid = @custid

--Error return
    IF ( @@error <> 0 ) 
        BEGIN
            SELECT  @ErrorMsg = CASE @language
                                  WHEN 'E'
                                  THEN 'Update process is unsuccessful.'
                                  WHEN 'CS' THEN N'更新程序不成功。'
                                  WHEN 'CT' THEN N'更新程序不成功。'
                                  WHEN 'TH'
                                  THEN N'ขั้นตอนหรือกระบวนการในการปรับยอดไม่เสร็จสิ้น'
                                  WHEN 'J' THEN N'アップデート出来ません。'
                                  WHEN 'KO' THEN N'업데이트에 실패했습니다.'
                                  ELSE N'Update process is unsuccessful.'
                                END ,
                    @ErrorCode = 102
            RETURN
        END


------------------------
--Write log file
    DECLARE @LogSPData VARCHAR(4000)

    SELECT  @LogSPData = '<Age_CustomerUpdUserInfo CustID="' + COALESCE(CAST(@CustID AS VARCHAR(50)), SPACE(1)) + '" '
						+ 'FirstName="' + COALESCE(CAST(@firstname AS NVARCHAR(50)),SPACE(1)) + '" ' 
						+ 'LastName="'+ COALESCE(CAST(@lastname AS NVARCHAR(50)), SPACE(1)) + '" '
						+ 'Phone="' + COALESCE(CAST(@phone AS NVARCHAR(50)), SPACE(1)) + '" ' 
						+ 'MobilePhone="' + COALESCE(CAST(@mobilephone AS NVARCHAR(50)), SPACE(1)) + '" '
						+ 'Email="' + COALESCE(CAST(@email AS NVARCHAR(50)), SPACE(1)) + '" '
						+ 'Fax="' + COALESCE(CAST(@fax AS NVARCHAR(50)), SPACE(1)) + '" '
						+ 'IP="' + COALESCE(CAST(@IP AS VARCHAR(15)), SPACE(1)) + '" ' 
						+ 'SubAccName="' + COALESCE(CAST(dbo.f_GetSubUsername(@SubAccID) AS VARCHAR(30)), SPACE(1)) + '" ' 
						+ 'UserID="' + COALESCE(CAST(@UserID AS VARCHAR(50)), SPACE(1)) + '" '
						+ 'Language="' + COALESCE(CAST(@Language AS VARCHAR(2)), SPACE(1)) + '" '
						+ 'ErrCode="' + COALESCE(CAST(@ErrorCode AS VARCHAR(50)), SPACE(1)) + '" ' 
						+ 'ErrMsg="' + COALESCE(CAST(@ErrorMsg AS VARCHAR(400)), SPACE(1)) + '" />'

/*609	Age_CustomerUpdUserInfo	Update downline's info*/
EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew 
	@UserID = @UserID,
    @CustID = @CustID, 
	@ActionID = 609, 
	@TrackingValue = @LogSPData	

GO
GRANT EXECUTE ON [dbo].[Age_CustomerUpdUserInfo] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Age_CustomerUpdUserInfo] TO [vnteam]