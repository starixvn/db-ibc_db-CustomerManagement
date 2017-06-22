 ALTER PROCEDURE [dbo].[Acc_CustomerInsAutoTransferAgent]
	@username		VARCHAR(MAX),
	@TransferType	TINYINT = 1,
	@UserID			INT,
	@IP				VARCHAR(50) = '',
	@ErrCode		INT = 0 OUTPUT,
	@ErrMsg			VARCHAR(4000)= 0 OUTPUT
 AS
	/*
		Created: Johnson
		Date: 2014-09-30
		Task: Add manually agents into automate	transfer list
		DB: DBTXN/CustDB
		
		Revisions:
			- 20150406@Johnson: fix log format [Redmine: #25321]
		Parameter's Explanation:
			- @TransferType = 1: Transfer all members
							= 2: Transfer all downlines
	*/
BEGIN
	SET NOCOUNT ON
	DECLARE @startRun	DATETIME,
			@endRun		DATETIME,
			@duration	INT
	SET	@startRun = GETDATE()
	
		--Check permission
	EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@userid,@funcname='[OtherTrans]',@ErrCode=@ErrCode OUTPUT,@ErrMsg=@ErrMsg OUTPUT
	IF @ErrCode <> 0
		RETURN
	
	DECLARE @tmpUser TABLE (custid INT,username VARCHAR(50))
	DECLARE @tmpCust TABLE (custid INT, islog BIT)
	DECLARE @ErrType VARCHAR(4000)
	
	INSERT INTO @tmpUser(username)
	SELECT DISTINCT val
	FROM strSplit (@username,',')
	
	UPDATE t
	SET t.custid = c.custid
	FROM @tmpUser t
		LEFT JOIN customer c WITH(NOLOCK) ON t.username = c.username AND roleid > 1
	
	IF EXISTS (SELECT 1 FROM @tmpUser WHERE custid IS NULL)
	BEGIN		
		SELECT @ErrType = ''
		SELECT @ErrType = @ErrType + username + ','
		FROM @tmpUser
		WHERE custid IS NULL
		
		SELECT @ErrMsg = 'Invalid Username: ' + @ErrType, @ErrCode = 100
		RETURN
	END
	
	IF EXISTS (SELECT TOP 1 1 FROM @tmpUser t 
					INNER JOIN [dbo].[Acc_ClearBalanceList] ac WITH(NOLOCK) ON t.custid = ac.custid
			)
	BEGIN
		SELECT @ErrType = ''
		SELECT @ErrType = @ErrType + username + ','
		FROM @tmpUser t
			INNER JOIN [dbo].[Acc_ClearBalanceList] ac WITH(NOLOCK) ON t.custid = ac.custid
				
		SELECT @ErrMsg = 'Existing Username: ' + @ErrType, @ErrCode = 101
		RETURN
	END
	
	INSERT INTO [dbo].[Acc_ClearBalanceList]
           ([custid] 
           ,[status]
           ,[LastTransfer]           
           ,[transferType])
    OUTPUT INSERTED.custid, 0 INTO @tmpCust    
	SELECT t.custid,'', GETDATE()-1, @TransferType
	FROM @tmpUser t
		LEFT JOIN Acc_ClearBalanceList ac WITH(NOLOCK) ON t.custid = ac.custid
	WHERE t.custid IS NOT NULL
		AND ac.custid IS NULL
	
	IF @@ERROR <> 0
	BEGIN
		SELECT @ErrMsg = 'Add agent unsuccessfully', @ErrCode = 102
		RETURN
	END	
	
	--write log
	DECLARE @LogData VARCHAR(4000),	
			@custid INT,			
			@log_username varchar(50)
			
	SET @endRun = GETDATE()
	SET @duration  = DATEDIFF(millisecond,@startRun,@endRun)	
	
	WHILE (1=1)
	BEGIN
		UPDATE TOP (1) t
		SET @log_username = username,
			@custid = t.custid,
			islog = 1
		FROM @tmpCust t 
			INNER JOIN @tmpUser u ON t.custid = u.custid
		WHERE islog = 0
		
		IF @@ROWCOUNT = 0 BREAK;
		
		SELECT @LogData = '<Acc_CustomerInsAutoTransferAgent username="' + COALESCE(@log_username,SPACE(1)) + '" ' 
								+ 'TransferType="' + COALESCE(CAST(@TransferType AS VARCHAR(10)),SPACE(1)) + '" '
								+ 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(50)),SPACE(1)) + '" '
								+ 'ErrMsg="' + COALESCE(@ErrMsg,SPACE(1))+'" '
								+ 'IP="' + COALESCE(@IP,SPACE(1)) + '" />'																		
		
		BEGIN TRY
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
				@Userid = @userid,
				@Custid = @CustID,
				@ActionID = 653,
				@TrackingValue = @LogData,				
				@Duration = @duration
		END TRY
		BEGIN CATCH
			SELECT @LogData = '<Acc_CustomerInsAutoTransferAgent username="' + COALESCE(@log_username,SPACE(1)) + '" ' 
									+ 'TransferType="' + COALESCE(CAST(@TransferType AS VARCHAR(10)),SPACE(1)) + '" '
									+ 'ErrCode="' + coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" '
									+ 'ErrMsg="' + coalesce(ERROR_MESSAGE(),space(1))+'" '
									+ 'IP="' + COALESCE(@IP,SPACE(1)) + '" />'																		
		
			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
				@Userid = @userid,
				@Custid = @CustID,
				@ActionID = 653,
				@TrackingValue = @LogData,
				@Duration = @duration								
		
		END CATCH
	END	
	
END
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerInsAutoTransferAgent] TO [bodbAdminNet]