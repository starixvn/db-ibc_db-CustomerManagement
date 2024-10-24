/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_alp" viewers="vnteam" isFunction="0"></info>*/
ALTER  PROCEDURE [dbo].[Age_CustomerInsNickName] 
	@custid			INT,
	@Nickname		VARCHAR(50) = NULL,
	@IP				VARCHAR(30) = '',
	@language		VARCHAR(2) = 'E' ,
	@ErrCode		INT = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS

/*
Created: 20110608@Sophia
Task :  Create customer's nickname
DB: DBTXN/bodb02
Original:

Revisions:
	- 20110722@Sophia: don't use prefix for username2 anymore
	- 20121128@Elodie: Get an error message from f_Get_MsgNameByMsgID function by language
    - 20130311@Dan: Write more log on DBTXN server in case of DBLOG server failure
    - 20141117@Johnson: write log IP
	- 20181002@Dominic: Check existing username/username2 in archived DB  [Redmine:99882]
	- 20190422@Elodie: Offer unique nickname for CN88 [Redmine:112287]
	- 20240704@Louisa: Scaleout DBCUST [Redmine:#199915]

Param's Explanation:
• @custid: custid that need to be update.   
*/

BEGIN
SET NOCOUNT ON

------ Create Nickname
	BEGIN TRY
		UPDATE  Customer WITH (ROWLOCK)
		SET     Username2 = @Nickname, RepUpdateTime = SYSDATETIME()
		WHERE   custid = @custid and ISNULL(Username2,'') = ''
 
	END TRY
	BEGIN CATCH
            SELECT  @ErrMsg = CASE @language
                                  WHEN 'E' THEN 'Failed to create username. Please try again.'
                                  ELSE [dbo].[f_Get_MsgNamebyMsgID](40007,@Language)
                                END ,
                    @ErrCode = 105 
            RETURN
     END CATCH

	---------- 
	--Write log Nickname
    DECLARE @LogSPData NVARCHAR(4000)

    SELECT  @LogSPData = '<Age_CustomerInsNickname CustID="' + COALESCE(CAST(@CustID AS VARCHAR(50)), SPACE(1)) + '" '
						+ 'Username2="'+ dbo.f_EncodeXMLValue(COALESCE(CAST(@Nickname AS  VARCHAR(50)), SPACE(1))) + '" '
						+ 'IP="' + COALESCE(CAST(@IP AS VARCHAR(50)), SPACE(1)) + '" ' 
						+ 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(50)), SPACE(1)) + '" ' 
						+ 'ErrMsg="' + COALESCE(CAST(@ErrMsg AS VARCHAR(400)), SPACE(1)) + '" />' 

	BEGIN TRY
		/*621	Age_CustomerUpdNickname	Update downline's info*/
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
			@UserID = @CustID,
			@CustID = @CustID, 
			@ActionID = 621, 
			@TrackingValue = @LogSPData 
	END TRY
	BEGIN CATCH
		SELECT  @LogSPData = '<Age_CustomerInsNickname CustID="' + COALESCE(CAST(@CustID AS VARCHAR(50)), SPACE(1)) + '" '
						+ 'Username2="'+ dbo.f_EncodeXMLValue(COALESCE(CAST(@Nickname AS  VARCHAR(50)), SPACE(1))) + '" '
						+ 'IP="' + COALESCE(CAST(@IP AS VARCHAR(50)), SPACE(1)) + '" ' 
						+ 'ErrCode="' + COALESCE(CAST(ERROR_NUMBER() AS VARCHAR(50)), SPACE(1)) + '" ' 
						+ 'ErrMsg="' + COALESCE(CAST(ERROR_MESSAGE() AS VARCHAR(2000)), SPACE(1)) + '" />'
						
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
			@UserID = @CustID,
			@CustID = @CustID, 
			@ActionID = 621, 
			@TrackingValue = @LogSPData 
	END CATCH
END 
GO
