/*<info serverAlias="DBCUST-CustDB" executers="bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE Age_CustomerUpdSecurityFunctionInfo
	@Custid		INT,
	@SubAccID	INT = 0,
	@Function	VARCHAR(30),
	@IsOn		BIT,
	@Userid		INT,
	@Language	VARCHAR(2) = 'E' ,
	@IP			VARCHAR(20) = '',
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		NVARCHAR(200) = '' OUTPUT
 AS
 /*
	Created: Elodie
	Date: 20210812
	Task: Update security function info 
	DB: DBACC/bodb02
		
	Revisions:
		- 20210812@Elodie: Initial sp [Redmine: #159628]

	Parameter's Explanation:
*/ 
BEGIN	
	SET NOCOUNT ON
	DECLARE @StartRun DATETIME, @EndRun DATETIME, @Duration INT, @ActionID INT, @LogSPData VARCHAR(MAX), @Old_LogSPData VARCHAR(MAX),
			@BitOrder TINYINT, @Old_IsOn BIT
				
	SET @startRun = GETDATE()
		
	--Check disable user
	EXEC dbo.Acc_CustomerSelCheckEnable @custid = @custid, @ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
	IF @ErrCode <> 0 RETURN
	
	IF (@SubAccID = 0 AND NOT EXISTS (SELECT 1 FROM dbo.CustLoginInfo WITH(NOLOCK) WHERE custid = @custid))
			OR (@SubAccID <> 0 AND NOT EXISTS (SELECT 1 FROM dbo.CustLoginInfoSub WITH(NOLOCK) WHERE custid = @custid AND SubAccId = @SubAccID))
	BEGIN
		SELECT @ErrMsg = CASE WHEN @Language = 'E' THEN 'Invalid user.'
										ELSE [dbo].[f_Get_MsgNamebyMsgID](40002,@Language) END,
				@ErrCode = 100
		RETURN
	END

	IF @Function = 'BetList'
	BEGIN
		SELECT @BitOrder = 1
	END
	ELSE IF @Function = 'Statement'
	BEGIN
		SELECT @BitOrder = 2
	END

	IF @SubAccID = 0
		SELECT @Old_IsOn = f.IsOn
		FROM CustLoginInfo cl WITH (NOLOCK) 
			CROSS APPLY (SELECT IsOn FROM f_GetSecurityFunctionInfo(@BitOrder,cl.FunctionInfo)) f
		WHERE custid = @custid
	ELSE
		SELECT @Old_IsOn = f.IsOn 
		FROM CustLoginInfoSub cl WITH (NOLOCK) 
			CROSS APPLY (SELECT IsOn FROM f_GetSecurityFunctionInfo(@BitOrder,cl.FunctionInfo)) f
		WHERE custid = @custid AND SubAccID = @SubAccID

	IF @Old_IsOn = @IsOn
		RETURN

	IF @SubAccID = 0
	BEGIN			
		UPDATE cl 
		SET cl.FunctionInfo = f.FunctionInfo
		FROM CustLoginInfo cl WITH(ROWLOCK)
			CROSS APPLY (SELECT FunctionInfo FROM f_GenerateSecurityFunctionInfo(@BitOrder, @IsOn, cl.FunctionInfo)) f
		WHERE custid = @custid
	END
	ELSE
	BEGIN			
		UPDATE cl 
		SET cl.FunctionInfo = f.FunctionInfo
		FROM CustLoginInfoSub cl WITH(ROWLOCK)
			CROSS APPLY (SELECT FunctionInfo FROM f_GenerateSecurityFunctionInfo(@BitOrder, @IsOn, cl.FunctionInfo)) f
		WHERE custid = @custid AND SubAccID = @SubAccID
	END				
			
	IF @@ERROR > 0
	BEGIN
		SELECT @ErrMsg = CASE WHEN @Language = 'E' THEN 'Update Security Code Option unsuccesful. Please try again.'
										ELSE [dbo].[f_Get_MsgNamebyMsgID](40058,@Language) END,
				@ErrCode = 101
		RETURN
	END
			
	SELECT @LogSPData = '<R '+ @Function + '="' + COALESCE(CAST(@IsOn AS VARCHAR(1)),SPACE(1)) + '" ' 		
							+ 'SubAcc="' + COALESCE(CAST(dbo.f_GetSubUsername(@SubAccID) AS VARCHAR(30)), SPACE(1)) + '" '						
							+ 'IP="' + COALESCE(@IP,SPACE(1)) + '" '
							+ 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1)) + '" ' 
							+ 'ErrMsg="' + COALESCE(@ErrMsg, SPACE(1)) + '" />'
	
	SELECT @Old_LogSPData = '<R '+ @Function + '="' + COALESCE(CAST(@Old_IsOn AS VARCHAR(1)),SPACE(1)) + '" ' 		
							+ 'SubAcc="' + COALESCE(CAST(dbo.f_GetSubUsername(@SubAccID) AS VARCHAR(30)), SPACE(1)) + '" '						
							+ 'IP="' + COALESCE(@IP,SPACE(1)) + '" '
							+ 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1)) + '" ' 
							+ 'ErrMsg="' + COALESCE(@ErrMsg, SPACE(1)) + '" />'
	SET @endRun = GETDATE()
	SET @duration  = DATEDIFF (MILLISECOND,@startRun,@endRun)
		
	EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
		@UserID = @CustID,
		@CustID = @CustID, 
		@ActionID = 951, 
		@TrackingValue = @LogSPData,
		@TrackingValue2 = @Old_LogSPData,
		@duration = @duration	
END
GO
