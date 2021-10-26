/*<info serverAlias="DBCUST-CustDB" executers="bodbDownlineNet" viewers="" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE Age_CustomerUpdProtectionCode
	@Custid			INT,
	@SubAccID		INT = 0,
	@ProtectionCode	VARCHAR(50),
	@Language		VARCHAR(2) = 'E' ,
	@IP				VARCHAR(20) = '',
	@ErrCode		INT = 0 OUTPUT,
	@ErrMsg			NVARCHAR(200) = '' OUTPUT
 AS
 /*
	Created: Elodie
	Date: 20210824
	Task: Update ProtectionCode
	DB: DBCUST/CustDB
		
	Revisions:
		- 20210824@Elodie: Initial sp [Redmine: #160151]

	Parameter's Explanation:
	Example: EXEC Age_CustomerUpdProtectionCode @Custid = 838203, @ProtectionCode = '123456', @SubAccId = 29183

*/ 
BEGIN	
	SET NOCOUNT ON
	DECLARE @StartRun DATETIME, @EndRun DATETIME, @Duration INT, @LogSPData VARCHAR(MAX), @Password VARCHAR(40)
				
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
	
	IF @SubAccID = 0
	BEGIN
		SELECT @Password = userpwd
		FROM Customer c WITH (NOLOCK)
		WHERE c.custid = @Custid
	END
	ELSE
	BEGIN
		SELECT @Password = userpwd
		FROM CustSub c WITH (NOLOCK)
		WHERE c.custid = @Custid AND subaccid = @SubAccID
	END

	IF @ProtectionCode = @Password
	BEGIN
		SELECT @ErrMsg = CASE WHEN @Language = 'E' THEN 'Protection Code cannot be the same as the password.'
										ELSE [dbo].[f_Get_MsgNamebyMsgID](40059,@Language) END,
				@ErrCode = 101
		RETURN
	END

	IF @SubAccID = 0
	BEGIN			
		UPDATE cl 
		SET cl.ProtectionCode = @ProtectionCode
		FROM CustLoginInfo cl WITH(ROWLOCK)
		WHERE custid = @custid
	END
	ELSE
	BEGIN			
		UPDATE cl 
		SET cl.ProtectionCode = @ProtectionCode
		FROM CustLoginInfoSub cl WITH(ROWLOCK)
		WHERE custid = @custid AND SubAccID = @SubAccID
	END				
			
	IF @@ERROR > 0
	BEGIN
		SELECT @ErrMsg = CASE WHEN @Language = 'E' THEN 'Failed to update Protection Code. Please try again.'
										ELSE [dbo].[f_Get_MsgNamebyMsgID](40060, @Language) END,
				@ErrCode = 102
		RETURN
	END
			
	SELECT @LogSPData = '<R SubAcc="' + COALESCE(CAST(dbo.f_GetSubUsername(@SubAccID) AS VARCHAR(30)), SPACE(1)) + '" '						
							+ 'IP="' + COALESCE(@IP,SPACE(1)) + '" '
							+ 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1)) + '" ' 
							+ 'ErrMsg="' + COALESCE(@ErrMsg, SPACE(1)) + '" />'
	
	SET @endRun = GETDATE()
	SET @duration  = DATEDIFF (MILLISECOND,@startRun,@endRun)
		
	EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
		@UserID = @CustID,
		@CustID = @CustID, 
		@ActionID = 953, 
		@TrackingValue = @LogSPData,
		@duration = @duration	
END
GO
