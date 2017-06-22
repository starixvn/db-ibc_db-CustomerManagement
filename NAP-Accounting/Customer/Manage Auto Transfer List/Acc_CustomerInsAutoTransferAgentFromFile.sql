 ALTER PROCEDURE [dbo].[Acc_CustomerInsAutoTransferAgentFromFile]	
	@username		VARCHAR(MAX),
	@TransferType	TINYINT = 1,
	@UserID			INT,
	@IP				VARCHAR(50) = '',
	@ErrCode		INT = 0 OUTPUT,
	@ErrMsg			VARCHAR(4000)= 0 OUTPUT
 AS
	/*
		Created: Johnson
		Date: 2014-09-23
		Task: Manage auto transfer list agents adding from file
		DB: DBTXN/CustDB
		
		Revisions:
			- 20141023@Johnson: Set default transfer to 'Transfer all downlines' from upload file
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
	DECLARE @tmpResult TABLE (username VARCHAR(50), remark VARCHAR(100), isSuccess bit)
	
	INSERT INTO @tmpUser(username)
	SELECT val
	FROM strSplit (@username,',')
	
	--Hardcode transfer type from file is 'Transfer all downlines'
	SET @TransferType = 2
	
	UPDATE t
	SET t.custid = c.custid
	FROM @tmpUser t
		LEFT JOIN customer c WITH(NOLOCK) ON t.username = c.username AND roleid > 1
	
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
		SELECT @ErrMsg = 'Add agent unsuccessfully', @ErrCode = 100
		RETURN
	END	
		 
	INSERT INTO @tmpResult(username,remark,isSuccess)
	SELECT username, 'Added successfully.',1
	FROM @tmpUser
	WHERE custid IN (SELECT custid FROM @tmpCust)
	
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
		
		SELECT @LogData = '<Acc_CustomerInsAutoTransferAgentFromFile username="' + COALESCE(@log_username,SPACE(1)) + '" ' 
								+ 'TransferType="' + COALESCE(CAST(@TransferType AS VARCHAR(10)),SPACE(1)) + '" '
								+ 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(50)),SPACE(1)) + '" '
								+ 'ErrMsg="' + COALESCE(@ErrMsg,SPACE(1))+'" '
								+ 'IP="' + COALESCE(@IP,SPACE(1)) + '" />'																		
		
		BEGIN TRY
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
				@Userid = @userid,
				@Custid = @CustID,
				@ActionID = 652,
				@TrackingValue = @LogData,				
				@Duration = @duration
		END TRY
		BEGIN CATCH
			SELECT @LogData = '<Acc_CustomerInsAutoTransferAgentFromFile username="' + COALESCE(@log_username,SPACE(1)) + '" ' 
									+ 'TransferType="' + COALESCE(CAST(@TransferType AS VARCHAR(10)),SPACE(1)) + '" '
									+ 'ErrCode="' + coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" '
									+ 'ErrMsg="' + coalesce(ERROR_MESSAGE(),space(1))+'" '
									+ 'IP="' + COALESCE(@IP,SPACE(1)) + '" />'																		
		
			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
				@Userid = @userid,
				@Custid = @CustID,
				@ActionID = 652,
				@TrackingValue = @LogData,
				@Duration = @duration								
		
		END CATCH
	END	
	
	SELECT * from @tmpResult
	
END
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerInsAutoTransferAgentFromFile] TO [bodbAdminNet]
