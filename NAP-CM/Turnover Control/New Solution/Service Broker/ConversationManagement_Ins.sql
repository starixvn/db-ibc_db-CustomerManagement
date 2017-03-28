/*<info serverAlias="DBAGE-bodb02" executers="" viewers="vnteam" isFunction="0" isNested="0"></info>*/

CREATE PROCEDURE [sb].[ConversationManagement_Ins]
		@FunctionName VARCHAR(100)
	,	@ContractName VARCHAR(100)  
	,	@FromService VARCHAR(100)
	,	@ToService VARCHAR(100)
	,	@NewCnt INT  
AS
/*
	Create By: Don
	Created Date: 2017-03-22
	Task: Apply Service Broker for Turnover Control function
	DB: DBAGE.bodb02
	
	Para's explaination
	
		- @NewCnt: expected conversation for this contract
*/
BEGIN 
	SET NOCOUNT ON 
	
	DECLARE @Cnt INT
		  , @i INT
		  , @handle UNIQUEIDENTIFIER
		  , @ConversationNo INT
		  , @SendSequence BIGINT
		  , @CurrentSendSequence BIGINT		  
		  , @CurrentDate DATETIME		  
		  , @MaxID INT			  
	DECLARE @ErrorMessage NVARCHAR(4000) 
		  , @ErrorSeverity INT
		  , @ErrorState INT		  
	DECLARE @t TABLE(ID BIGINT IDENTITY(1, 1), Handle UNIQUEIDENTIFIER, ConversationNo INT, SendSequence BIGINT)
	
	SELECT @ErrorSeverity = 10, @ErrorState = 1							 
			  
	SET @Cnt = (SELECT Cnt
				FROM sb.ConversationCount WITH (NOLOCK)
				WHERE FunctionName = @functionName
						AND ContractName = @contractName)
	
	IF @Cnt IS NULL 
	BEGIN
		INSERT INTO sb.ConversationCount (functionName,ContractName,Cnt) 
		VALUES (@functionName,@contractName,0)
	END		
	
	SET @Cnt = ISNULL(@Cnt,0)
	SET @CurrentDate =  GETDATE()		
		
	SET @ErrorMessage = '=============================================== Begin increase process ==============================================='
	RAISERROR (@ErrorMessage, -- Message text.  
			   @ErrorSeverity, -- Severity.  
			   @ErrorState -- State.  
			  )
			  
	SET @i = @Cnt + 1
			
	WHILE @i <= @newCnt
	BEGIN
		BEGIN DIALOG CONVERSATION @handle
		FROM SERVICE  @fromService 
		TO SERVICE  @toService 
		on contract @contractName 
		WITH ENCRYPTION = OFF								
		
		INSERT INTO sb.ConversationManagement(FunctionName, ContractName, ConversationNo, ConversationHandle,CreatedDate,IsValid)
		VALUES(@functionName, @contractName, @i, @handle,@CurrentDate,1)
		
		SET @ErrorMessage = 'Begin conversation ' + CAST(@handle AS VARCHAR(200)) + ' successfully'
		RAISERROR (@ErrorMessage, -- Message text.  
				   @ErrorSeverity, -- Severity.  
				   @ErrorState -- State.  
				  )
		
		SET @i = @i + 1					
	END
	
	UPDATE sb.ConversationCount WITH (ROWLOCK)
		SET Cnt = @newCnt
	WHERE FunctionName = @functionName
	  AND ContractName = @contractName
	
	SET @ErrorMessage = '=============================================== End increase process ==============================================='
	RAISERROR (@ErrorMessage, -- Message text.  
			   @ErrorSeverity, -- Severity.  
			   @ErrorState -- State.  
			  )
	
END
GO