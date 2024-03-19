/*<info serverAlias="DBCUST-CustDB" executers="bodbDownlineNet,wsv_alp" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CustomerUpdNicknameLoginOnly]
	@custid				INT,
	@NicknameLoginOnly	BIT = 0,
	@IP					VARCHAR(30) ='',
	@language			VARCHAR(2) = 'E' ,
	@ErrCode			INT = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS

/*
Created: 20110608@Sophia
Task : Set Nickname Log in only
DB: DBCUST/CustDB
Original:

Revisions:
    - 20121128@Elodie: Get an error message from f_Get_MsgNameByMsgID function by language
    - 20130311@Dan: Write more log on DBTXN server in case of DBLOG server failure
    - 20141117@Johnson: write log IP
Param's Explanation:
• @custid: custid that need to be update.   

*/

SET NOCOUNT ON

----****************** Update NicknameLoginOnly

DECLARE @RoleID int
 
 
SELECT @RoleID = RoleID FROM Customer  WITH (NOLOCK) WHERE custid = @custid

SET @ErrCode = 0
SET @ErrMsg = ''

IF @RoleID = 2
UPDATE CustAgent WITH (ROWLOCK, UPDLOCK) SET NicknameLoginOnly = @NicknameLoginOnly  WHERE custid = @custid    
ELSE IF @RoleID = 3  
UPDATE CustMaster WITH (ROWLOCK, UPDLOCK) SET NicknameLoginOnly = @NicknameLoginOnly  WHERE custid = @custid  
ELSE IF @RoleID = 4  
UPDATE CustSuper WITH (ROWLOCK, UPDLOCK) SET NicknameLoginOnly = @NicknameLoginOnly  WHERE custid = @custid  



------Error return
    IF ( @@error <> 0 ) 
        BEGIN
            SELECT  @ErrMsg = CASE @language
                                  WHEN 'E' THEN 'Update process is unsuccessful.'
								  ELSE [dbo].[f_Get_MsgNamebyMsgID](90001,@Language)
                                END ,
                    @ErrCode = 106 
            RETURN
        END
 
 

DECLARE @LogSPData NVARCHAR(4000)
--Write log NicknameLoginOnly
    SELECT  @LogSPData = '<Age_CustomerUpdNicknameLogOnly CustID="' + COALESCE(CAST(@CustID AS VARCHAR(50)), SPACE(1)) + '" '
						+ 'NicknameOnly="'+ dbo.f_EncodeXMLValue(COALESCE(CAST(@NicknameLoginOnly AS  VARCHAR(50)), SPACE(1))) + '" '
						+ 'IP="' + COALESCE(CAST(@IP AS VARCHAR(50)), SPACE(1)) + '" ' 
						+ 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(50)), SPACE(1)) + '" ' 
						+ 'ErrMsg="' + COALESCE(CAST(@ErrMsg AS VARCHAR(400)), SPACE(1)) + '" />'
 
 
BEGIN TRY
	/*622	bodb_CustomerLog	Update downline's info*/
	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
		@UserID = @CustID,
		@CustID = @CustID, 
		@ActionID = 622, 
		@TrackingValue = @LogSPData 
END TRY
BEGIN CATCH
	--Write log NicknameLoginOnly
    SELECT  @LogSPData = '<Age_CustomerUpdNicknameLogOnly CustID="' + COALESCE(CAST(@CustID AS VARCHAR(50)), SPACE(1)) + '" '
						+ 'NicknameOnly="'+ dbo.f_EncodeXMLValue(COALESCE(CAST(@NicknameLoginOnly AS  VARCHAR(50)), SPACE(1))) + '" '
						+ 'IP="' + COALESCE(CAST(@IP AS VARCHAR(50)), SPACE(1)) + '" ' 
						+ 'ErrCode="' + COALESCE(CAST(ERROR_NUMBER() AS VARCHAR(50)), SPACE(1)) + '" ' 
						+ 'ErrMsg="' + COALESCE(CAST(ERROR_MESSAGE() AS VARCHAR(2000)), SPACE(1)) + '" />'	
	/*622	bodb_CustomerLog	Update downline's info*/
	EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
		@UserID = @CustID,
		@CustID = @CustID, 
		@ActionID = 622, 
		@TrackingValue = @LogSPData 		
 END CATCH
--END 



