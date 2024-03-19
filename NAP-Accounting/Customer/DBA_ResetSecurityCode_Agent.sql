/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,wsv_nap" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[DBA_ResetSecurityCode_Agent]
	@custid		INT,
	@userid		INT,
	@isForcedChangeSecurityCode BIT = 1,
	@Securitycode	VARCHAR(50) = '',
	@language	VARCHAR(2) = 'E' ,
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		VARCHAR(200) = '' OUTPUT,
	@IP			VARCHAR(20) = ''
 AS
	/*
		Created: Johnson
		Date: 2013-04-09
		DB: DBCUST/custDB
		Task: upline/admin update Security code of customer
		
		Revisions:
			- Daniel@20150622: Separated custDB to server DBCUST
			- 20180808@Helen: DB05.DBPOLICY migration - [Redmine:99462]
			
		Parameter's Explanation:
	*/
BEGIN	
	SET NOCOUNT ON
	DECLARE @startRun DATETIME
			,@endRun DATETIME
			,@duration INT
			,@roleid INT
			,@LogSPData VARCHAR(MAX)
			
	SET @startRun = GETDATE()
	
	EXEC NAP_UserControl.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[SecurityCode]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
	If @ErrCode <> 0
		RETURN
	
	--Check disable user
	EXEC dbo.Acc_CustomerSelCheckEnable @custid = @custid, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
	if @ErrCode <>0 return
	
	SELECT @roleid = roleid 
	FROM custinfo WITH(NOLOCK)
	WHERE custid = @custid
	
	IF @roleid BETWEEN 2 AND 4
	BEGIN	
		IF NOT EXISTS (SELECT 1 FROM dbo.CustLoginInfo WITH(NOLOCK) WHERE custid = @custid)
		BEGIN
			SELECT @ErrMsg = CASE WHEN @Language = 'E' THEN 'Invalid user.'
											ELSE [dbo].[f_Get_MsgNamebyMsgID](40002,@Language) END,
					@ErrCode = 100
			RETURN
		END
		
		UPDATE CustLoginInfo WITH(UPDLOCK,ROWLOCK)
		SET SecurityCode = @SecurityCode
			,isForcedChangeSecurityCode = @isForcedChangeSecurityCode
			,LastChangedSecurityCodeDate = GETDATE()		
		WHERE custid = @custid
	
		IF @@Error > 0
		BEGIN
			SELECT @ErrMsg = CASE WHEN @Language = 'E' THEN 'Reset security code unsuccesful. Please try again.'
											ELSE [dbo].[f_Get_MsgNamebyMsgID](40023,@Language) END,
					@ErrCode = 101
			RETURN
		END
		
		SELECT @LogSPData = '<DBA_ResetSecurityCode_Agent custid="' + COALESCE(CAST(@custid AS VARCHAR(10)),SPACE(1)) + '" ' 
							+ 'isForcedChangeSecurityCode="' + COALESCE(CAST(@isForcedChangeSecurityCode AS VARCHAR(10)), SPACE(1)) + '" ' 
							+ 'IP="' + COALESCE(@IP,SPACE(1)) + '" '
							+ 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1)) + '" ' 
							+ 'ErrMsg="' + COALESCE(@ErrMsg, SPACE(1)) + '" />'
		
		SET @endRun = GETDATE()
		SET @duration  = DATEDIFF (MILLISECOND,@startRun,@endRun)
	
		BEGIN TRY
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
				@UserID = @UserID,
				@CustID = @CustID, 
				@ActionID = 914, 
				@TrackingValue = @LogSPData,
				@duration = @duration
		END TRY
		BEGIN CATCH
			SELECT @LogSPData = '<DBA_ResetSecurityCode_Agent custid="' + COALESCE(CAST(@custid AS VARCHAR(10)),SPACE(1)) + '" ' 
								+ 'isForcedChangeSecurityCode="' + COALESCE(CAST(@isForcedChangeSecurityCode AS VARCHAR(10)), SPACE(1)) + '" ' 
								+ 'IP="' + COALESCE(@IP,SPACE(1)) + '" '
								+ 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1)) + '" ' 
								+ 'ErrMsg="' + ERROR_MESSAGE() + '" />'
								
			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
				@UserID = @UserID,
				@CustID = @CustID, 
				@ActionID = 914, 
				@TrackingValue = @LogSPData,
				@duration = @duration 
		END CATCH
	END
	ELSE IF @roleid = 1
	BEGIN	
		IF NOT EXISTS (SELECT 1 FROM dbo.CustLoginInfo_Member WITH(NOLOCK) WHERE custid = @custid)
		BEGIN
			INSERT INTO [CustLoginInfo_Member]([CustID],[SecurityCode],[IP],[LastChangedID],[LastChangedDate])
			VALUES(@custid,@SecurityCode,@IP,@userid,GETDATE())
		END
		ELSE
		BEGIN
			UPDATE CustLoginInfo_Member WITH(UPDLOCK,ROWLOCK)
			SET SecurityCode = @SecurityCode
				,IP = @IP
				,LastChangedID = @userID
				,LastChangedDate = GETDATE()
			WHERE custid = @custid

			IF @@Error > 0
			BEGIN
				SELECT @ErrMsg = CASE WHEN @Language = 'E' THEN 'Reset security code unsuccesful. Please try again.'
												ELSE [dbo].[f_Get_MsgNamebyMsgID](40023,@Language) END,
						@ErrCode = 201
				RETURN
			END
		END
		
		SELECT @LogSPData = '<DBA_ResetSecurityCode_Agent custid="' + COALESCE(CAST(@custid AS VARCHAR(10)),SPACE(1)) + '" ' 							
							+ 'IP="' + COALESCE(@IP,SPACE(1)) + '" '
							+ 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1)) + '" ' 
							+ 'ErrMsg="' + COALESCE(@ErrMsg, SPACE(1)) + '" />'
		
		SET @endRun = GETDATE()
		SET @duration  = DATEDIFF (MILLISECOND,@startRun,@endRun)
	
		BEGIN TRY
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
				@UserID = @UserID,
				@CustID = @CustID, 
				@ActionID = 915, 
				@TrackingValue = @LogSPData,
				@duration = @duration
		END TRY
		BEGIN CATCH
			SELECT @LogSPData = '<DBA_ResetSecurityCode_Agent custid="' + COALESCE(CAST(@custid AS VARCHAR(10)),SPACE(1)) + '" ' 								
								+ 'IP="' + COALESCE(@IP,SPACE(1)) + '" '
								+ 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1)) + '" ' 
								+ 'ErrMsg="' + ERROR_MESSAGE() + '" />'
								
			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
				@UserID = @UserID,
				@CustID = @CustID, 
				@ActionID = 915, 
				@TrackingValue = @LogSPData,
				@duration = @duration 
		END CATCH
	END
END	
GO