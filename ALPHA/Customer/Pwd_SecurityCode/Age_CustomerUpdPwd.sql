/*<info serverAlias="DBCUST-CUSTDB" executers="bodbDownlineNet,wsv_alp,bodbExtAccNet,wsv_xnap" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CustomerUpdPwd]
    @CustID INT ,
    @UserPwd NVARCHAR(50) ,
    @UserID INT ,
    @Language VARCHAR(2) = 'E' ,
    @SubAccID INT = 0 , --Sub-AccountID
    @LoginIP VARCHAR(20) = '' ,
    @ErrCode INT = 0 OUTPUT , --default no error
    @ErrMsg NVARCHAR(500) = '' OUTPUT
AS /*
Created: 
Task : Reset password for his downlines
DB: DBCust/Custdb
Original: CustomerPwdUpd2

Revisions: 
    - 20090311@HanhVu: Log information into UserLog_RunSP table					   
	- 20090729@Phuc: Write log subaccname instead of subaccid.
	- 20090818@Phuc: check page access and check upline closed first(call Age_CustSubCheckPageAccess)
	- 20090917@Phuc: write log into DBLOG.
	- 20091209@Terry: Checked Disable casino
	- 20100108@Lewin: Change SPLogDataFormat
	- 20101021@Henry: Record execution time
	- 20110907@Sophia: Change Linked Server from DB052 to DB053	
	- 20121128@Elodie: Get an error message from f_Get_MsgNameByMsgID function by language
	- 20130311@Dan: Change linked server DB053 to DBAGE; Write more log on DBTXN server in case of DBLOG server failure
	- 20150508@Johnson: Check sub-account not allow to update main account password [Redmine: #35551]
	- 20150611@Kathy: Migrate custDB to new server DBCust (Move Acc_CustomerSelCheckEnable to DBCUST.CustDB) [Redmine:#36216]
	- 20160104@Helen: Disallow SMA changes password or updates account status of members - [Redmine:#49967]
	- 20190611@Johnson: force change pwd if upline reset pwd [redmine: #114566]
	- 20200417@Eden: Alpha - Removing force change password [Redmine:#132012]
	- 20210824@Elodie: Implement Protection Code [Redmine: #160151]
	- 20220110@Eden: Saba Casino use DCS Setting [RedmineID: #164280]
Param's Explanation:
• @ErrCode:
    = 0: Transaction recorded successfully.
    > 0: Specific Error.
  
• @ErrMsg: Error description.
*/
BEGIN
    SET NOCOUNT ON
    
	declare @startRun datetime
	declare @endRun datetime
	declare @duration int
	set @startRun = getdate()
--Check disable user
    EXEC dbo.Acc_CustomerSelCheckEnable @custid = @custid,
        @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT
    IF @ErrCode <> 0 
        RETURN
--end

    DECLARE  @ErrLog NVARCHAR(50)
			,@PwdExpiry DATETIME
			,@OldPwd	VARCHAR(40)
			,@roleid TINYINT
    
    IF EXISTS (SELECT 1 FROM custSub WITH(NOLOCK) WHERE custid = @custid AND subaccID = @SubAccID)
	 BEGIN
            SELECT  @ErrMsg ='You dont have permission to do this action.',
                    @ErrCode = 101
            RETURN
        END	
	
	IF @UserID <> @CustID AND CURRENT_USER <> 'bodbAdminNet,wsv_nap' AND EXISTS (SELECT 1 FROM custInfo WITH (NOLOCK) WHERE custid = @CustID AND LockUpd = 1 AND roleid = 1)
	BEGIN
		 SELECT  @ErrMsg = CASE @Language
                                WHEN 'E' THEN 'You are currently not authorized to perform this action. Please contact the Customer Service Department for further assistance.'
                                ELSE [dbo].[f_Get_MsgNamebyMsgID](40033,@Language)
                              END ,
                 @ErrCode = 102
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

	SELECT	@OldPwd	= userpwd, @roleid = roleid
	FROM	Customer WITH (NOLOCK) 
	WHERE	custid = @CustID
	
	--force change pwd if upline reset pwd
	IF @custid <> @userid
	BEGIN
		
		SELECT  @pwdexpiry = CASE WHEN @roleid = 1 THEN DATEADD(dd, -1, GETDATE()) ELSE '01/01/1900' END
	END
	ELSE 
		SELECT  @pwdexpiry = DATEADD(dd, 30, GETDATE())

    UPDATE  customer WITH (ROWLOCK, UPDLOCK)
    SET     userpwd = @UserPwd ,
            pwdexpiry = @PwdExpiry
    WHERE   custid = @CustID
    
	IF @roleid <> 1
	BEGIN
		UPDATE	CustLoginInfo WITH (ROWLOCK, UPDLOCK)
		SET		OldUserPwd			= @OldPwd
				,LastChangedPwdDate = GETDATE()				
		WHERE	custid = @CustID
	END
	ELSE
	BEGIN
		UPDATE	CustLoginInfo_Member WITH (ROWLOCK, UPDLOCK)
		SET	gesture = NULL
		WHERE	custid = @CustID
	END
	
    DECLARE @LogData NVARCHAR(4000)

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
	
	set @endRun = getdate()
	set @duration  = datediff (millisecond,@startRun,@endRun)
	
	BEGIN TRY	
		/*901	Age_CustomerUpdPwd	Reset Password*/
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
			@UserID = @UserID,
			@CustID = @CustID,
			@ActionID = 901,
			@TrackingValue = @LogData	,
			@duration = @duration
	END TRY
	BEGIN CATCH		
		SELECT  @LogData = '<Age_CustomerUpdPwd  UserID="' + CONVERT(VARCHAR(20), @CustID)
            + '" IP="' + @LoginIP +'" '
		---------------------------
		-- ***Check Sub-Account***
		IF @SubAccID > 0 
			BEGIN
				SET @LogData =  @LogData + 'SubAccount="' + dbo.f_GetSubUsername(@SubAccID) + '" '
	                
			END
		---------------------------
		SET @LogData = @LogData + 'ErrCode="' + coalesce(cast(ERROR_NUMBER() as varchar(50)),space(1)) + '" ' 
								+ 'ErrMsg="' + coalesce(cast(ERROR_MESSAGE() as varchar(2000)),space(1)) + '" ' 	
						+ '/>'
	
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
			@UserID = @UserID,
			@CustID = @CustID,
			@ActionID = 901,
			@TrackingValue = @LogData	,
			@duration = @duration	
	END CATCH
END
GO
