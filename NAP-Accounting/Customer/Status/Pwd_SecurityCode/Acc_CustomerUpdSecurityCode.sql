USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Acc_CustomerUpdSecurityCode]    Script Date: 06/10/2015 14:57:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Acc_CustomerUpdSecurityCode    Script Date: 12/5/2013 4:34:23 PM ******/
/****** Object:  Stored Procedure dbo.Acc_CustomerUpdSecurityCode    Script Date: 4/23/2013 10:50:32 AM ******/
 ALTER PROCEDURE [dbo].[Acc_CustomerUpdSecurityCode]
	@custid		INT,
	@userid		INT,
	@isForcedChangeSecurityCode BIT = 1,
	@Securitycode	VARCHAR(50) = '',
	@language	VARCHAR(2) = 'E' ,
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		VARCHAR(200) = '' OUTPUT,
	@IP			VARCHAR(20) = '',
	@system VARCHAR(50) = ''
 AS
	/*
		Created: Johnson
		Date: 2013-04-09
		DB: DBTXN/bodb02
		Task: upline/admin update Security code of customer
		
		Revisions:
			- 20150609@Kathy: Migrate custDB to new server DBCust (Move Acc_CustomerSelCheckEnable to DBCUST.CustDB) [Redmine:#36216]
		
		Parameter's Explanation:
	*/
SET NOCOUNT ON
	DECLARE @startRun DATETIME
			,@endRun DATETIME
			,@duration INT
			,@roleid INT
			,@LogSPData VARCHAR(MAX)
			
	SET @startRun = GETDATE()
	IF @system = 'EXTERNAL'
	BEGIN
		--- no check permssion in case of calling from external accounting
		SET @ErrMsg = ''
	END
	ELSE
	BEGIN
		EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[SecurityCode]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
		If @ErrCode <> 0
			RETURN
	END
	
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
		
		SELECT @LogSPData = '<Acc_CustomerUpdSecurityCode custid="' + COALESCE(CAST(@custid AS VARCHAR(10)),SPACE(1)) + '" ' 
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
			SELECT @LogSPData = '<Acc_CustomerUpdSecurityCode custid="' + COALESCE(CAST(@custid AS VARCHAR(10)),SPACE(1)) + '" ' 
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
		
		SELECT @LogSPData = '<Acc_CustomerUpdSecurityCode custid="' + COALESCE(CAST(@custid AS VARCHAR(10)),SPACE(1)) + '" ' 							
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
			SELECT @LogSPData = '<Acc_CustomerUpdSecurityCode custid="' + COALESCE(CAST(@custid AS VARCHAR(10)),SPACE(1)) + '" ' 								
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

GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdSecurityCode] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdSecurityCode] TO [bodbExtAccNet] AS [dbo]