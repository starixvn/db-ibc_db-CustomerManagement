/*<info serverAlias="DBCUST-CUSTDB" executers="bodbDownlineNet,wsv_alp" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE [dbo].[CS_Customer_SecurityCode_upd]
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
		Created: 20190311@Johnson		
		DB: DBCUST/CustDB
		Task: update sc for customer of cn88
		
		Revisions:
			- 20190311@Johnson: clone sp from Age_CustomerUpdSecurityCode to support cn88 [Redmine:#105660]
			- 20190606@Elodie: Apply new structure for CN88's log [Redmine: #113198]
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
		IF NOT EXISTS (SELECT 1 FROM dbo.f_CS_AGE_IsCrossLevelUpdate(@custid,@userid))
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
				SELECT @isForcedChangeSecurityCode = 0, @actionID = 935			
			ELSE
				SELECT @isForcedChangeSecurityCode = 1, @actionID = 936 -- hard code to force customer change SC
				
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
			
			SELECT @LogSPData = '<CS_Customer_SecurityCode_upd custid="' + COALESCE(CAST(@custid AS VARCHAR(10)),SPACE(1)) + '" ' 								
									+ 'SubAccount="' + COALESCE(CAST(dbo.f_GetSubUsername(@SubAccID) AS VARCHAR(30)), SPACE(1)) + '" ' 
									+ 'isForcedChangeSecurityCode="' + COALESCE(CAST(@isForcedChangeSecurityCode AS VARCHAR(10)), SPACE(1)) + '" ' 
									+ 'IP="' + COALESCE(@IP,SPACE(1)) + '" '
									+ 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1)) + '" ' 
									+ 'ErrMsg="' + COALESCE(@ErrMsg, SPACE(1)) + '" />'
					
			SET @endRun = GETDATE()
			SET @duration  = DATEDIFF (MILLISECOND,@startRun,@endRun)
			
			EXEC CS_WriteLog_UserLog_RunSP_Wrapper
				@UserID = @UserID,
				@CustID = @CustID, 
				@ActionID = @ActionID, 
				@TrackingValue = @LogSPData,
				@duration = @duration 			
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
				UPDATE dbo.CustLoginInfo_Member WITH(UPDLOCK,ROWLOCK)
				SET SecurityCode = @SecurityCode
					,IP = @IP 
					,LastChangedID = @userid
					,LastChangedDate = GETDATE()
				WHERE custid = @custid
				
				IF @@Error > 0
				BEGIN
					SELECT @ErrMsg = CASE WHEN @Language = 'E' THEN 'Reset security code unsuccesful. Please try again.'
													ELSE [dbo].[f_Get_MsgNamebyMsgID](40023,@Language) END,
							@ErrCode = 101
					RETURN
				END
			END
			
			SELECT @LogSPData = '<CS_Customer_SecurityCode_upd custid="' + COALESCE(CAST(@custid AS VARCHAR(10)),SPACE(1)) + '" ' 								
									+ 'SubAccount="' + COALESCE(CAST(dbo.f_GetSubUsername(@SubAccID) AS VARCHAR(30)), SPACE(1)) + '" ' 
									+ 'IP="' + COALESCE(@IP,SPACE(1)) + '" '
									+ 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1)) + '" ' 
									+ 'ErrMsg="' + COALESCE(@ErrMsg, SPACE(1)) + '" />'
			
			
			SET @endRun = GETDATE()
			SET @duration  = DATEDIFF (MILLISECOND,@startRun,@endRun)
			
			EXEC CS_WriteLog_UserLog_RunSP_Wrapper
				@UserID = @UserID,
				@CustID = @CustID, 
				@ActionID = 936, 
				@TrackingValue = @LogSPData,
				@duration = @duration			
		END
		--for headline of cn88
		ELSE IF @roleid = 0
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM dbo.CustLoginInfo WITH(NOLOCK) WHERE custid = @custid)
			BEGIN
				SELECT @ErrMsg = CASE WHEN @Language = 'E' THEN 'Invalid user.'
												ELSE [dbo].[f_Get_MsgNamebyMsgID](40002,@Language) END,
						@ErrCode = 100
				RETURN
			END
			
			IF @custid = @userid -- reset isForcedChangeSecurityCode = 0 if customer reset his SC
				SELECT @isForcedChangeSecurityCode = 0, @actionID = 935			
			ELSE
				SELECT @isForcedChangeSecurityCode = 1, @actionID = 936 -- hard code to force customer change SC
						
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
			
			SELECT @LogSPData = '<CS_Customer_SecurityCode_upd custid="' + COALESCE(CAST(@custid AS VARCHAR(10)),SPACE(1)) + '" ' 								
									+ 'SubAccount="' + COALESCE(CAST(dbo.f_GetSubUsername(@SubAccID) AS VARCHAR(30)), SPACE(1)) + '" ' 
									+ 'isForcedChangeSecurityCode="' + COALESCE(CAST(@isForcedChangeSecurityCode AS VARCHAR(10)), SPACE(1)) + '" ' 
									+ 'IP="' + COALESCE(@IP,SPACE(1)) + '" '
									+ 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1)) + '" ' 
									+ 'ErrMsg="' + COALESCE(@ErrMsg, SPACE(1)) + '" />'
					
			SET @endRun = GETDATE()
			SET @duration  = DATEDIFF (MILLISECOND,@startRun,@endRun)
			
			EXEC CS_WriteLog_UserLog_RunSP_Wrapper
				@UserID = @UserID,
				@CustID = @CustID, 
				@ActionID = @ActionID, 
				@TrackingValue = @LogSPData,
				@duration = @duration			
		END
END
GO