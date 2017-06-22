ALTER PROCEDURE [dbo].[Acc_CustomerUpdAutoTransferAgent]
	@custid			INT,
	@TransferType	TINYINT = 1,
	@userID			INT,
	@IP				VARCHAR(30) = '',
	@ErrCode		INT = 0 OUTPUT,
	@ErrMsg			VARCHAR(500) = '' OUTPUT
AS
	/*
		Created: Johnson
		Date: 2014-09-25
		Task: Update transfer type for agent
		DB: DBTXN/CustDB
		
		Revisions:
		
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
	
	IF NOT EXISTS(SELECT 1 FROM Acc_ClearBalanceList WITH(NOLOCK) WHERE custid = @custid)
	BEGIN
		SELECT @ErrMsg = 'This agent doesn''t exist in the automate transfer list.', @ErrCode = 100
		RETURN
	END
	
	DECLARE @Old_transferType TINYINT
	SELECT @Old_transferType = TransferType FROM Acc_ClearBalanceList WITH(NOLOCK) WHERE custid = @custid
	
	IF @Old_TransferTYpe = @TransferType RETURN
	
	UPDATE Acc_ClearBalanceList WITH(UPDLOCK,ROWLOCK)
	SET TransferType = @TransferType
	WHERE custid = @custid
	
	IF @@ERROR <> 0
	BEGIN
		SELECT @ErrMsg = 'Update agent unsuccessfully.', @ErrCode = 101
		RETURN
	END
	
	--write log
	DECLARE @LogData VARCHAR(4000),
			@LogData_Old VARCHAR(4000)
			
	SET @endRun = GETDATE()
	SET @duration  = DATEDIFF(millisecond,@startRun,@endRun)
		
	SELECT @LogData = '<Acc_CustomerUpdAutoTransferAgent CustID="' + COALESCE(CAST(@CustID AS VARCHAR(10)),SPACE(1)) + '"'
								+ 'TransferType="' + COALESCE(CAST(@TransferType AS VARCHAR(10)),SPACE(1)) + '" '
								+ 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(50)),SPACE(1)) + '" '
								+ 'ErrMsg="' + COALESCE(@ErrMsg,SPACE(1))+'" '
								+ 'IP="' + COALESCE(@IP,SPACE(1)) + '" />'																		
	
	SELECT @LogData_Old = '<Acc_CustomerUpdAutoTransferAgent CustID="' + COALESCE(CAST(@CustID AS VARCHAR(10)),SPACE(1)) + '"'
								+ 'TransferType="' + COALESCE(CAST(@Old_TransferType AS VARCHAR(10)),SPACE(1)) + '" '
								+ 'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(50)),SPACE(1)) + '" '
								+ 'ErrMsg="' + COALESCE(@ErrMsg,SPACE(1))+'" '
								+ 'IP="' + COALESCE(@IP,SPACE(1)) + '" />'																		
		
	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
			@Userid = @userid,
			@Custid = @CustID,
			@ActionID = 654,
			@TrackingValue = @LogData,				
			@TrackingValue2 = @LogData_Old,
			@Duration = @duration
	END TRY
	BEGIN CATCH
		SELECT @LogData = '<Acc_CustomerUpdAutoTransferAgent CustID="' + COALESCE(CAST(@CustID AS VARCHAR(10)),SPACE(1)) + '"'
								+ 'TransferType="' + COALESCE(CAST(@TransferType AS VARCHAR(10)),SPACE(1)) + '" '
								+ 'ErrCode="' + coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" '
								+ 'ErrMsg="' + coalesce(ERROR_MESSAGE(),space(1))+'" '
								+ 'IP="' + COALESCE(@IP,SPACE(1)) + '" />'																		
	
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
			@Userid = @userid,
			@Custid = @CustID,
			@ActionID = 654,
			@TrackingValue = @LogData,
			@Duration = @duration								
	
	END CATCH
END
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdAutoTransferAgent] TO [bodbAdminNet]