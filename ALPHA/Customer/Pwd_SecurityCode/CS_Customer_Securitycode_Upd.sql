/*<info serverAlias="DBCUST-CUSTDB" executers="bodbDownlineNet, bodbDownlineNetView" viewers="" isFunction="0"></info>*/

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
		Task: update Security code of headline cn88
		
		Revisions:
			- 20190311@Johnson: initial sp [redmine:#105660]
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

		SELECT @roleid = roleid				
		FROM custinfo WITH(NOLOCK)
		WHERE custid = @custid
		
		IF (@@rowcount = 0 OR @roleid <> 0)
		BEGIN
			SELECT @ErrMsg = CASE WHEN @Language = 'E' THEN 'Invalid user.'
												ELSE [dbo].[f_Get_MsgNamebyMsgID](40002,@Language) END,
						@ErrCode = 100
				RETURN
		END
		
		-- Only direct upline have update permission
		IF NOT EXISTS (SELECT 1 FROM dbo.f_AGE_IsCrossLevelUpdate(@custid,@roleid,@userid))
		BEGIN
			SELECT @ErrMsg = 'You don''t have permission to perform this action.',
				   @ErrCode = 103
			RETURN
		END
			
		
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
		
		BEGIN TRY
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
				@UserID = @UserID,
				@CustID = @CustID, 
				@ActionID = @ActionID, 
				@TrackingValue = @LogSPData,
				@duration = @duration
		END TRY
		BEGIN CATCH
			SELECT @LogSPData = '<CS_Customer_SecurityCode_upd custid="' + COALESCE(CAST(@custid AS VARCHAR(10)),SPACE(1)) + '" ' 								
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
GO
