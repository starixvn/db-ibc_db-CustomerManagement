/*<info serverAlias="DBCUST-CustDB" executers="wsv_nap, wsv_alp, bodbExtAccNet,wsv_xnap " viewers="" isFunction="0" isNested="0"></info>*/

CREATE PROCEDURE Age_CustomerUpdProtectedMode
	@Custid				INT,
	@IsProtectionMode	BIT,
	@UserId				INT,
	@SubAccID			INT = 0,
	@Language			VARCHAR(2) = 'E' ,
	@IP					VARCHAR(20) = '',
	@ErrCode			INT = 0 OUTPUT,
	@ErrMsg				NVARCHAR(200) = '' OUTPUT
 AS
 /*
	Created: Elodie
	Date: 20210824
	Task: Update ProtectedMode
	DB: DBCUST/CustDB
		
	Revisions:
		- 20210824@Elodie: Initial sp [Redmine: #160151]

	Parameter's Explanation:
	Example: EXEC Age_CustomerUpdProtectedMode @Custid = 838203, @IsProtectionMode = 1, @SubAccId = 29183

*/ 
BEGIN	
	SET NOCOUNT ON
	DECLARE @StartRun DATETIME, @EndRun DATETIME, @Duration INT, @LogSPData VARCHAR(MAX)
	DECLARE @roleid TINYINT, @LogSPData_Old VARCHAR(MAX), @IsProtectionMode_Old BIT
				
	SET @startRun = GETDATE()
		
	--Check disable user
	EXEC dbo.Acc_CustomerSelCheckEnable @custid = @custid, @ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
	IF @ErrCode <> 0 RETURN

	IF (NOT EXISTS (SELECT 1 FROM dbo.CustLoginInfo WITH(NOLOCK) WHERE custid = @custid))
	BEGIN
		SELECT @ErrMsg = CASE WHEN @Language = 'E' THEN 'Invalid user.'
										ELSE [dbo].[f_Get_MsgNamebyMsgID](40002,@Language) END,
				@ErrCode = 100
		RETURN
	END
	
	SELECT @roleid = roleid
	FROM custinfo WITH(NOLOCK)
	WHERE custid = @custid

	-- Only direct upline have update permission
	IF NOT EXISTS (SELECT 1 FROM dbo.f_AGE_IsCrossLevelUpdate(@custid,@roleid,@userid))
	BEGIN
		SELECT @ErrMsg = 'You don''t have permission to perform this action.',
				@ErrCode = 101
		RETURN
	END

	SELECT @IsProtectionMode_Old = IsProtectedMode
	FROM CustLoginInfo c WITH (NOLOCK)
	WHERE c.custid = @Custid

	IF @IsProtectionMode_Old = @IsProtectionMode
		RETURN

	UPDATE cl 
	SET cl.IsProtectedMode = @IsProtectionMode
	FROM CustLoginInfo cl WITH(ROWLOCK)
	WHERE custid = @custid
		
	SELECT @LogSPData = '<R SubAcc="' + COALESCE(CAST(dbo.f_GetSubUsername(@SubAccID) AS VARCHAR(30)), SPACE(1)) + '" '						
							+ 'Protected="' + COALESCE(CAST(@IsProtectionMode AS VARCHAR(1)), SPACE(1)) + '" '		
							+ 'IP="' + COALESCE(@IP,SPACE(1)) + '" '
							+ 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1)) + '" ' 
							+ 'ErrMsg="' + COALESCE(@ErrMsg, SPACE(1)) + '" />'
	
	SELECT @LogSPData_Old = '<R SubAcc="' + COALESCE(CAST(dbo.f_GetSubUsername(@SubAccID) AS VARCHAR(30)), SPACE(1)) + '" '						
							+ 'Protected="' + COALESCE(CAST(@IsProtectionMode_Old AS VARCHAR(1)), SPACE(1)) + '" '		
							+ 'IP="' + COALESCE(@IP,SPACE(1)) + '" '
							+ 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1)) + '" ' 
							+ 'ErrMsg="' + COALESCE(@ErrMsg, SPACE(1)) + '" />'
	SET @endRun = GETDATE()
	SET @duration  = DATEDIFF (MILLISECOND,@startRun,@endRun)
		
	EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
		@UserID = @UserID,
		@CustID = @CustID, 
		@ActionID = 1183, 
		@TrackingValue = @LogSPData,
		@TrackingValue2 = @LogSPData_Old,
		@duration = @duration	
END
GO
