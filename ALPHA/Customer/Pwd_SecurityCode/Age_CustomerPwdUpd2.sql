/*<info serverAlias="DBCUST-CustDB" executers="bodbDownlineNet,wsv_alp,VNTeam" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CustomerPwdUpd2]
    @CustID INT ,
    @UserPwd NVARCHAR(50) ,
    @OldPwd NVARCHAR(50) ,
    @LoginIP VARCHAR(20) = '' ,
    @UserID INT ,
    @Language VARCHAR(2) = 'E' ,--CS, CT
    @ErrCode INT = 0 OUTPUT ,
    @ErrMsg NVARCHAR(500) = '' OUTPUT
AS /*
Created: 
Task : Agent changes his own password 
DB: DBCUST/CustDB
Original: CustomerPwdUpd2

Revisions:
    - 20090311@HanhVu: Log information into UserLog_RunSP table
					   Remove check sub-acc because this SP is only used by main agent
	- 20090402@Phuc: write log into dblog.
	- 20091209@Terry: Checked Disable casino
	- 20100107@Lewin: Change LogSPData format
	- 20101021@Henry: Record execution time
	- 20121128@Elodie: Get an error message from f_Get_MsgNameByMsgID function by language
	- 20130328@Jamie: Update Old pwd and Last Changed Pwd 
	- 20160104@Helen: Disallow SMA changes password or updates account status of members - [Redmine:#49967]
	- 20210408@Tina: Lock account & indirect close account [redmine: #148600]
	- 20210824@Elodie: Implement Protection Code [Redmine: #160151]
	- 20220110@Eden: Saba Casino use DCS Setting [RedmineID: #164280]
Param's Explanation:
- @ErrCode:
    = 0: Transaction recorded successfully.
    > 0: Specific Error.
  
- @ErrMsg: Error description.
*/
BEGIN
    SET NOCOUNT ON
	DECLARE @startRun DATETIME, @endRun DATETIME, @duration INT, @LogSPData VARCHAR(MAX)
	DECLARE @failedcount INT, @ProtectionCode VARCHAR(30)

	SET @startRun = getdate()

	SELECT @failedcount = ISNULL(C.logincount,0)
	FROM Customer C WITH (NOLOCK)
	WHERE C.custid = @CustID

    DECLARE @PwdExpiry DATETIME

	IF @UserID <> @CustID AND CURRENT_USER <> 'wsv_nap' AND EXISTS (SELECT 1 FROM custInfo WITH (NOLOCK) WHERE custid = @CustID AND LockUpd = 1 AND roleid = 1)
	BEGIN
		 SELECT  @ErrMsg = CASE @Language
                                WHEN 'E' THEN 'You are currently not authorized to perform this action. Please contact the Customer Service Department for further assistance.'
                                ELSE [dbo].[f_Get_MsgNamebyMsgID](40033,@Language)
                              END ,
                 @ErrCode = 103
         RETURN
	END	
		
	IF EXISTS (SELECT 1 FROM CustLoginInfo WITH (NOLOCK) WHERE custid = @CustID AND ISNULL(ProtectionCode,'') = @UserPwd)
	BEGIN
		 SELECT  @ErrMsg = CASE @Language
                                WHEN 'E' THEN 'Your password does not meet the minimum security requirement.'
                                ELSE [dbo].[f_Get_MsgNamebyMsgID](40061,@Language)
                              END ,
                 @ErrCode = 105
         RETURN
	END	

	IF NOT EXISTS (SELECT  1 FROM customer WITH (NOLOCK) WHERE   CustID = @CustID AND UserPwd = @OldPwd)
    BEGIN
        SELECT @failedcount = @failedcount + 1

		IF @failedcount > 5 --Lock accounts after 5 logins failed */
		BEGIN
			UPDATE CustProductStatus WITH (ROWLOCK,UPDLOCK) SET Locked = 2 WHERE custid = @CustID 
		    
			UPDATE Customer WITH (ROWLOCK,UPDLOCK) SET logincount = 0 WHERE custid = @CustID 

			SET	@endRun = GETDATE() 
			SET @Duration = DATEDIFF(millisecond,@startRun,@endRun)
			SELECT @ErrMsg = case @Language when 'E' then 'Your account has been locked due to multiple failed security check. Please contact your upline to unlock.'  
			ELSE [dbo].[f_Get_MsgNamebyMsgID](40045,@Language)
		    END,@ErrCode = 104

			--log data to UserLog_RunSP 
			SELECT @LogSPData = '<Age_CustomerPwdUpd2 UserID="'
						+ CONVERT(VARCHAR(20), @CustID) + '" IP="'+ @LoginIP + '" />'		    
			
			BEGIN TRY 	
			EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_RunSP
				@UserID = @UserID,
				@CustID = @CustID,
				@ActionID = 948,
				@TrackingValue = @LogSPData,
				@Duration = @Duration
			END TRY 
			BEGIN CATCH
				SELECT @LogSPData = '<Age_CustomerPwdUpd2 UserID="'
						+ CONVERT(VARCHAR(20), @CustID) + '" IP="'+ @LoginIP + '" ' +
											'ErrMsg="' + ERROR_MESSAGE() +'" ' + 
									
									' />'
				EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_RunSP
					@UserID = @UserID,
					@CustID = @CustID,
					@ActionID = 948,
					@TrackingValue = @LogSPData,
					@Duration = @Duration		
			
			END CATCH 
		END
		ELSE IF @failedcount <=5
		BEGIN 			
			UPDATE Customer WITH(UPDLOCK,ROWLOCK)
			SET logincount = @failedcount
			WHERE custid = @custid
			
			SET	@endRun = GETDATE() 
			SET @Duration = DATEDIFF(millisecond,@startRun,@endRun)

			SELECT @ErrMsg = CASE WHEN @Language = 'E' THEN 'Old password is incorrect.'
												ELSE [dbo].[f_Get_MsgNamebyMsgID](40021,@Language) END,
				@ErrCode = 101		
		END

		RETURN
    END
	

	-- Successful
    SELECT  @pwdexpiry = DATEADD(dd, 30, GETDATE())
    UPDATE  customer WITH ( ROWLOCK, UPDLOCK )
    SET     userpwd = @UserPwd ,
            pwdexpiry = @PwdExpiry ,
            iplogin = @LoginIP
    WHERE   custid = @CustID
    
    UPDATE	CustLoginInfo WITH (UPDLOCK,ROWLOCK)
    SET		OldUserPwd				= @OldPwd
			,LastChangedPwdDate		= GETDATE()
			,isFirstLogin			= 0
	WHERE	CustID = @CustID

    SELECT  @LogSPData =  '<Age_CustomerPwdUpd2 UserID="'
						+ CONVERT(VARCHAR(20), @CustID) + '" IP="' + @LoginIP + '" />'

	set @endRun = getdate()
	set @duration  = datediff (millisecond,@startRun,@endRun)

	/*902	Age_CustomerPwdUpd2	Reset own password */
    EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
		@UserID = @UserID, 
		@CustID = @CustID,
        @ActionID = 902, 
		@TrackingValue = @LogSPData,
		@duration = @duration
		
END
