/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_alp,wsv_xnap" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CustomerUpdSecurityCode]
	@custid		INT,
	@userid		INT,
	@subaccID	INT = 0,
	@isForcedChangeSecurityCode BIT = 0,
	@Securitycode	VARCHAR(50) = '',
	@language	VARCHAR(2) = 'E' ,
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		NVARCHAR(200) = '' OUTPUT,
	@IP			VARCHAR(20) = ''
 AS
 
	/*
		Created: Johnson
		Date: 2013-04-09
		DB: DBCUST/CustDB
		Task: upline/admin update Security code of customer
		
		Revisions:
			- 20140514@viet: also check sub-account's security code
			- 20141008@Johnson: write log in case of updating own security code
			- 20150611@Kathy: Migrate custDB to new server DBCust (Move Acc_CustomerSelCheckEnable to DBCUST.CustDB) [Redmine:#36216]
			- 20160613@Helen: Security Prevention Step 1 - Cross level update -  [Redmine:55377]
			- 20241230@Aries: Scale Out DBCUST - Apply Inhouse replication for the remaning tables [Redmine: #215627]
		Parameter's Explanation:
	*/
BEGIN	
	SET NOCOUNT ON
		DECLARE @startRun DATETIME
				,@endRun DATETIME
				,@duration INT
				,@uplineID INT
				,@uplineSecurityCode VARCHAR(50)
				,@roleid INT
				,@uplineSecurityCode_sub VARCHAR(50)
				,@actionID INT
				,@LogSPData VARCHAR(MAX)
				
		SET @startRun = GETDATE()
		
		--Check disable user
		EXEC dbo.Acc_CustomerSelCheckEnable @custid = @custid, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
		if @ErrCode <>0 return

		SELECT @roleid = roleid,
				@uplineID = CASE roleid WHEN 1 THEN recommend
										WHEN 2 THEN mrecommend
										WHEN 3 THEN srecommend END
		FROM custinfo WITH(NOLOCK)
		WHERE custid = @custid
		
		-- Only direct upline have update permission
		IF NOT EXISTS (SELECT 1 FROM dbo.f_AGE_IsCrossLevelUpdate(@custid,@roleid,@userid))
		BEGIN
			SELECT @ErrMsg = 'You don''t have permission to perform this action.',
				   @ErrCode = 103
			RETURN
		END
	
		IF @roleid between 2 and 4
		BEGIN			
			IF NOT EXISTS (SELECT 1 FROM dbo.CustLoginInfo WITH(NOLOCK) WHERE custid = @custid)
			BEGIN
				SELECT @ErrMsg = CASE WHEN @Language = 'E' THEN 'Invalid user.'
												ELSE [dbo].[f_Get_MsgNamebyMsgID](40002,@Language) END,
						@ErrCode = 100
				RETURN
			END
		
			IF @roleid <> 4
			BEGIN 
				IF @subaccID <> 0
				BEGIN
					SELECT @uplineSecurityCode_sub = SecurityCode
					FROM dbo.CustLoginInfoSub WITH(NOLOCK) 
					WHERE SubAccID = @subaccID
					
					IF @uplineSecurityCode_sub IS NULL --AND @custid <> @userid
					BEGIN
						SELECT @ErrMsg = CASE WHEN @Language = 'E' THEN 'The upline is not enabled this function.'
														ELSE [dbo].[f_Get_MsgNamebyMsgID](40027,@Language) END,
								@ErrCode = 100
						RETURN
					END
				END
				ELSE
				BEGIN										
					SELECT @uplineSecurityCode = SecurityCode
					FROM dbo.CustLoginInfo WITH(NOLOCK) 
					WHERE custid = @uplineID
					
					IF @uplineSecurityCode IS NULL AND @custid <> @userid
					BEGIN
						SELECT @ErrMsg = CASE WHEN @Language = 'E' THEN 'The upline is not enabled this function.'
														ELSE [dbo].[f_Get_MsgNamebyMsgID](40027,@Language) END,
								@ErrCode = 100
						RETURN
					END			
				END			
			END
			
			IF @custid = @userid -- reset isForcedChangeSecurityCode = 0 if customer reset his SC
				SELECT @isForcedChangeSecurityCode = 0, @actionID = 924			
			ELSE
				SELECT @isForcedChangeSecurityCode = 1, @actionID = 916 -- hard code to force customer change SC
				
			UPDATE CustLoginInfo WITH(UPDLOCK,ROWLOCK)
			SET SecurityCode = @SecurityCode
				,isForcedChangeSecurityCode = @isForcedChangeSecurityCode
				,LastChangedSecurityCodeDate = GETDATE()	
				,RepUpdateTime = dbo.f_GetDateTime2()
			WHERE custid = @custid
			
			IF @@Error > 0
			BEGIN
				SELECT @ErrMsg = CASE WHEN @Language = 'E' THEN 'Reset security code unsuccesful. Please try again.'
												ELSE [dbo].[f_Get_MsgNamebyMsgID](40023,@Language) END,
						@ErrCode = 101
				RETURN
			END
			
			SELECT @LogSPData = '<Age_CustomerUpdSecurityCode custid="' + COALESCE(CAST(@custid AS VARCHAR(10)),SPACE(1)) + '" ' 								
									+ 'SubAccount="' + COALESCE(CAST(dbo.f_GetSubUsername(@SubAccID) AS VARCHAR(30)), SPACE(1)) + '" ' 
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
					@ActionID = @ActionID, 
					@TrackingValue = @LogSPData,
					@duration = @duration
			END TRY
			BEGIN CATCH
				SELECT @LogSPData = '<Age_CustomerUpdSecurityCode custid="' + COALESCE(CAST(@custid AS VARCHAR(10)),SPACE(1)) + '" ' 								
									+ 'SubAccount="' + COALESCE(CAST(dbo.f_GetSubUsername(@SubAccID) AS VARCHAR(30)), SPACE(1)) + '" ' 
									+ 'isForcedChangeSecurityCode="' + COALESCE(CAST(@isForcedChangeSecurityCode AS VARCHAR(10)), SPACE(1)) + '" ' 
									+ 'IP="' + COALESCE(@IP,SPACE(1)) + '" '
									+ 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1)) + '" ' 
									+ 'ErrMsg="' + ERROR_MESSAGE() + '" />'
									
				EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
					@UserID = @UserID,
					@CustID = @CustID, 
					@ActionID = @ActionID, 
					@TrackingValue = @LogSPData,
					@duration = @duration 
			END CATCH
			
		END
		ELSE IF @roleid = 1
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM dbo.CustLoginInfo_Member WITH(NOLOCK) WHERE custid = @custid)
			BEGIN 
				INSERT INTO [CustLoginInfo_Member]([CustID],[SecurityCode],[IP],[LastChangedID],[LastChangedDate],[RepUpdateTime])
				VALUES(@custid,@SecurityCode,@IP,@userid,GETDATE(), dbo.f_GetDateTime2())
			END
			ELSE
			BEGIN 
				UPDATE dbo.CustLoginInfo_Member WITH(UPDLOCK,ROWLOCK)
				SET SecurityCode = @SecurityCode
					,IP = @IP 
					,LastChangedID = @userid
					,LastChangedDate = GETDATE()
					,RepUpdateTime = dbo.f_GetDateTime2()
				WHERE custid = @custid
				
				IF @@Error > 0
				BEGIN
					SELECT @ErrMsg = CASE WHEN @Language = 'E' THEN 'Reset security code unsuccesful. Please try again.'
													ELSE [dbo].[f_Get_MsgNamebyMsgID](40023,@Language) END,
							@ErrCode = 101
					RETURN
				END
			END
			
			SELECT @LogSPData = '<Age_CustomerUpdSecurityCode custid="' + COALESCE(CAST(@custid AS VARCHAR(10)),SPACE(1)) + '" ' 								
									+ 'SubAccount="' + COALESCE(CAST(dbo.f_GetSubUsername(@SubAccID) AS VARCHAR(30)), SPACE(1)) + '" ' 
									+ 'IP="' + COALESCE(@IP,SPACE(1)) + '" '
									+ 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1)) + '" ' 
									+ 'ErrMsg="' + COALESCE(@ErrMsg, SPACE(1)) + '" />'
			
			
			SET @endRun = GETDATE()
			SET @duration  = DATEDIFF (MILLISECOND,@startRun,@endRun)
			
			BEGIN TRY
				EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
					@UserID = @UserID,
					@CustID = @CustID, 
					@ActionID = 916, 
					@TrackingValue = @LogSPData,
					@duration = @duration
			END TRY
			BEGIN CATCH
				SELECT @LogSPData = '<Age_CustomerUpdSecurityCode custid="' + COALESCE(CAST(@custid AS VARCHAR(10)),SPACE(1)) + '" ' 								
									+ 'SubAccount="' + COALESCE(CAST(dbo.f_GetSubUsername(@SubAccID) AS VARCHAR(30)), SPACE(1)) + '" ' 
									+ 'IP="' + COALESCE(@IP,SPACE(1)) + '" '
									+ 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1)) + '" ' 
									+ 'ErrMsg="' + ERROR_MESSAGE() + '" />'
									
				EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
					@UserID = @UserID,
					@CustID = @CustID, 
					@ActionID = 916, 
					@TrackingValue = @LogSPData,
					@duration = @duration 
			END CATCH
		END
END
GO
GRANT EXECUTE ON [dbo].[Age_CustomerUpdSecurityCode] TO [wsv_alp] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Age_CustomerUpdSecurityCode] TO [wsv_alpv] AS [dbo]