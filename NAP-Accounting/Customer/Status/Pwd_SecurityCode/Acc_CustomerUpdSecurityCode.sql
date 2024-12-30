/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap,wsv_xnap" viewers="" isFunction="0" isNested="0"></info>*/
 ALTER PROCEDURE [dbo].[Acc_CustomerUpdSecurityCode]
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
		DB: DBCUST/CUSTDB
		Task: upline/admin update Security code of customer
		
		Revisions:
			- 20150609@Kathy: Migrate custDB to new server DBCust (Move Acc_CustomerSelCheckEnable to DBCUST.CustDB) [Redmine:#36216]
			- 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]
			- 20190529@Johnson: update SC for headline from NAP [redmine: #112225]
			- 20190606@Elodie: Apply new structure for CN88's log [Redmine: #113198]
			- 20240805@Tacy: Remove linked-server/cross-db on NAP_UserControl [redmineID: #208402]
			- 20241230@Aries: Scale Out DBCUST - Apply Inhouse replication for the remaning tables [Redmine: #215627]

		Parameter's Explanation:
	*/
SET NOCOUNT ON
	DECLARE @startRun DATETIME
			,@endRun DATETIME
			,@duration INT
			,@roleid INT
			,@LogSPData VARCHAR(MAX)
			
	SET @startRun = GETDATE()
	
	--Check disable user
	EXEC dbo.Acc_CustomerSelCheckEnable @custid = @custid, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
	if @ErrCode <>0 return
	
	SELECT @roleid = roleid 
	FROM custinfo WITH(NOLOCK)
	WHERE custid = @custid
	
	IF @roleid BETWEEN 2 AND 4 OR @roleid = 0--headline cn88
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
			,RepUpdateTime = dbo.f_GetDateTime2()
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
	
		EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
			@UserID = @UserID,
			@CustID = @CustID, 
			@ActionID = 914, 
			@TrackingValue = @LogSPData,
			@duration = @duration		
	END
	ELSE IF @roleid = 1
	BEGIN	
		IF NOT EXISTS (SELECT 1 FROM dbo.CustLoginInfo_Member WITH(NOLOCK) WHERE custid = @custid)
		BEGIN
			INSERT INTO [CustLoginInfo_Member]([CustID],[SecurityCode],[IP],[LastChangedID],[LastChangedDate],[RepUpdateTime])
			VALUES(@custid,@SecurityCode,@IP,@userid,GETDATE(),dbo.f_GetDateTime2())
		END
		ELSE
		BEGIN
			UPDATE CustLoginInfo_Member WITH(UPDLOCK,ROWLOCK)
			SET SecurityCode = @SecurityCode
				,IP = @IP
				,LastChangedID = @userID
				,LastChangedDate = GETDATE()
				,RepUpdateTime = dbo.f_GetDateTime2()
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
	
		EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
			@UserID = @UserID,
			@CustID = @CustID, 
			@ActionID = 915, 
			@TrackingValue = @LogSPData,
			@duration = @duration		
	END

GO