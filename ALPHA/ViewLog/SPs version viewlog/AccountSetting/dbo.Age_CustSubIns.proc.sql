ALTER PROCEDURE [dbo].[Age_CustSubIns]
    @subaccid INT OUTPUT ,
    @custid INT , -- agentid or masterid or superid
    @username VARCHAR(30) ,
    @userpwd VARCHAR(40) ,
    @firstname NVARCHAR(50) = '-' ,
    @lastname NVARCHAR(50) = '-' ,
    @PageAccess VARCHAR(50) ,
    @success BIT = 1 OUTPUT ,
    @Language VARCHAR(2) = 'E' ,
    @LoginSubAccID INT = 0 , --Current Login Sub-AccountID
    @LoginIP VARCHAR(20) = '' ,
    @UserID INT = 0 ,
    @ErrCode INT = 0 OUTPUT ,
    @ErrMsg NVARCHAR(4000) = '' OUTPUT
AS /*
Created: 20080508
Task : Create new sub-account for agent
DB: DB02.bodb02
Original: Age_CustSubIns

Revisions:    
    - 20090318@Hanh: add Korean language
	- 20090917@Phuc: write log into DBLOG.
	- 20100108@Lewin: change splog data format
Param's Explanation:
• @ErrCode:
    = 0: Login successfully.
    > 0: Specific Error.
  
• @ErrMsg: Error description.
*/

    SET NOCOUNT ON
---------------------------
-- ***Check Sub-Account***
-- For Edit Sub-Account
/*
Declare @spPageAccess varchar(10)
set @spPageAccess = '[NO]' --No Permission for Sub-Account on this Sp
Declare @SubAllow bit
Exec Age_CustSubCheckPageAccess @LoginSubAccID, @spPageAccess, @Language, @SubAllow OUTPUT
if @SubAllow = 0
BEGIN
	select @ErrMsg = case @Language 
			when 'E' then 'Sorry, You don''t have Permission to create new Sub-Account.'
			when 'CS' then N'对不起，您不允许增加新的子账号.'							
			when 'CT' then N'對不起, 您不允許增加新的子帳號.'
			when 'J' then N'Sorry, You don''t have Permission to create new Sub-Account.'
			when 'TH' then N'ขออภัย คุณไม่ได้รับอนุญาติที่จะเปิดบัญชีใหม่สำหรับลูกค้าย่อย.'
			when 'KO' then N'죄송합니다. 새로운 보조 계정을 만드는것이 허가 되지 않았습니다.'
			else N'Sorry, You don''t have Permission to create new Sub-Account.'
		end	,@ErrCode=101		
	return	
END
*/

---------------------------
    DECLARE @ErrLog NVARCHAR(200) ,
        @NoOfSubAcc TINYINT ,
        @MaxOfSubAcc TINYINT

    SELECT  @success = 0 ,
            @username = REPLACE(@username, ' ', '')

--check duplicate username
    IF ( EXISTS ( SELECT    1
                  FROM      custsub WITH ( NOLOCK )
                  WHERE     username = @username ) )
        OR ( EXISTS ( SELECT    1
                      FROM      customer WITH ( NOLOCK )
                      WHERE     username = @username ) ) 
        BEGIN
            SELECT  @ErrMsg = CASE @Language
                                WHEN 'E'
                                THEN 'This username is not available.'
                                WHEN 'CS' THEN N'此账号无效.'
                                WHEN 'CT' THEN N'此帳號無效.'
                                WHEN 'J' THEN N'ID確認できません。'
                                WHEN 'TH'
                                THEN N'ชื่อที่ใช้ในการเข้าระบบนี้ ไม่สามารถใช้งานได้'
                                WHEN 'KO' THEN N'이 사용자 이름을 사용할 수 없습니다.'
                                ELSE N'This username is not available.'
                              END ,
                    @ErrCode = 102		
            RETURN	
        END

--check no of subacc (must <= @MaxOfSubAcc)
    SELECT  @NoOfSubAcc = COUNT(*)
    FROM    custsub WITH ( NOLOCK )
    WHERE   custid = @custid

    SELECT  @MaxOfSubAcc = CASE roleid
                             WHEN 4 THEN 15
                             ELSE 10
                           END
    FROM    customer WITH ( NOLOCK )
    WHERE   custid = @custid

    IF @NoOfSubAcc >= @MaxOfSubAcc 
        BEGIN
            SELECT  @ErrMsg = CASE @Language
                                WHEN 'E'
                                THEN 'You have exceeded your sub-accounts limit.'
                                WHEN 'CS' THEN N'您已超出子账号限定.'
                                WHEN 'CT' THEN N'您已超出子帳號限定.'
                                WHEN 'J'
                                THEN N'You have exceeded your sub-accounts limit.'
                                WHEN 'TH'
                                THEN N'คูณมียอดเกินวงจำกัดบัญชีย่อยของคุณ.'
                                WHEN 'KO' THEN N'보조계정의 관리 한도를 초과 하였습니다.'
                                ELSE N'You have exceeded your sub-accounts limit.'
                              END ,
                    @ErrCode = 103		
            RETURN	
        END

--Insert data to db
    INSERT  INTO custsub
            ( custid ,
              username ,
              userpwd ,
              firstname ,
              lastname ,
              PageAccess ,
              createdate			
			
            )
    VALUES  ( @custid ,
              @username ,
              @userpwd ,
              @firstname ,
              @lastname ,
              @PageAccess ,
              GETDATE()
            )
			
    SELECT  @subaccid = @@IDENTITY

    IF @@error <> 0 
        BEGIN
            SELECT  @ErrMsg = CASE @Language
                                WHEN 'E'
                                THEN 'Create sub-account failed. Please try again.'
                                WHEN 'CS' THEN N'新增会员不成功，请重新尝试.'
                                WHEN 'CT' THEN N'新增會員不成功,請重新嘗試.'
                                WHEN 'J'
                                THEN N'Create sub-account failed. Please try again.'
                                WHEN 'TH'
                                THEN N'การเพิ่มจำนวนบัญชีย่อย ไม่สำเร็จ กรุณาทำรายการอีกครั้ง.'
                                WHEN 'KO'
                                THEN N'보조계정 만들기에 실패했습니다. 다시 시도해 주시기 바랍니다.'
                                ELSE N'Create sub-account failed. Please try again.'
                              END ,
                    @ErrCode = 104		
            RETURN	
        END


    SELECT  @Success = 1
    DECLARE @LogSPData VARCHAR(5000)
---------------------------
-- ***Check Sub-Account***
-- For Edit Sub-Account
    SELECT  @LogSPData = 'subaccid="' + COALESCE(CAST(@SubAccID AS VARCHAR(30)), SPACE(1)) + '" ' + '
						custid="' + COALESCE(CAST(@custid AS VARCHAR(50)), SPACE(1)) + '" ' + '
						username="' + COALESCE(CAST(@username AS VARCHAR(30)), SPACE(1)) + '" ' + '
						fname="' + COALESCE(CAST(@firstname AS VARCHAR(100)), SPACE(1)) + '" ' + '
						lname="' + COALESCE(CAST(@lastname AS VARCHAR(100)), SPACE(1)) + '" ' + '
						PageAccess="' + COALESCE(CAST(@PageAccess AS VARCHAR(50)), SPACE(1)) + '" ' + '
						success="' + COALESCE(CAST(@success AS VARCHAR(50)), SPACE(1)) + '" ' + '
						Language="' + COALESCE(CAST(@Language AS VARCHAR(2)), SPACE(1)) + '" ' + '
						LoginSubAccID="' + COALESCE(CAST(@LoginSubAccID AS VARCHAR(50)), SPACE(1)) + '" ' + '
						LoginIP="' + COALESCE(CAST(@LoginIP AS VARCHAR(20)), SPACE(1)) + '" '+ '
						UserID="' + COALESCE(CAST(@UserID AS VARCHAR(50)), SPACE(1)) + '" ' + '
						ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(50)), SPACE(1)) + '" '+ '
						ErrMsg="' + COALESCE(CAST(@ErrMsg AS VARCHAR(8000)), SPACE(1)) + '" />'

/*612	Age_CustSubIns	Open new sub-account*/
    EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSPNew 
		@UserID = @UserID,
        @CustID = @CustID, 
		@ActionID = 612, 
		@TrackingValue = @LogSPData	
GO
GRANT  EXECUTE  ON [dbo].[Age_CustSubIns]  TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Age_CustSubIns] TO [VNTeam]