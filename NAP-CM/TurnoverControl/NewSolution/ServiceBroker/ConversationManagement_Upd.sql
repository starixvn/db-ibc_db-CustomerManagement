/*<info serverAlias="DBAGE-bodb02" executers="" viewers="vnteam" isFunction="0" isNested="0"></info>*/

CREATE PROCEDURE [Sb].[ConversationManagement_Upd]
( 
		@FunctionName VARCHAR(100) 
	,	@ContractName VARCHAR(100) = NULL  
	,	@FromService VARCHAR(100)
	,	@ToService VARCHAR(100)
	,	@NewCnt INT   
)
AS
/*
	Create By: Don
	Created Date: 2017-03-22
	Task: Apply Service Broker for Turnover Control function
	DB: DBAGE.bodb02
	
	Para's explaination
*/
BEGIN 
	SET NOCOUNT ON 
	
	DECLARE @Cnt INT
		  , @i BIGINT		  
		  , @MinConversation INT
		  , @MaxConversation INT
		  , @Count BIGINT
		  , @IsError BIT
		  
	DECLARE @ErrorMessage NVARCHAR(4000) 
		  , @ErrorSeverity INT = 10 -- Information No
		  , @ErrorState INT = 1
	DECLARE @t TABLE(ID BIGINT IDENTITY(1, 1), ContractName VARCHAR(100))
	
	IF @contractName IS NOT NULL
		INSERT INTO @t(ContractName) VALUES(@contractName)
	ELSE -- FOR ALL CONTRACTS PROCESS
	BEGIN
		INSERT INTO @t(ContractName) 
		SELECT ContractName
		FROM sb.ConfigurationReferenceDetail WITH (NOLOCK)
		WHERE FunctionName = @functionName
	END			
			
	SET @Count = @@ROWCOUNT		
	
	SET @IsError = 0
	SET @i = 1	
	WHILE @i <= @Count
	BEGIN	
		SELECT @contractName = ContractName
		FROM @t
		WHERE ID = @i
	  
		SELECT @MinConversation = MinConversation
			 , @MaxConversation = MaxConversation
		FROM sb.ConfigurationReferenceDetail WITH (NOLOCK)
		WHERE FunctionName = @functionName
		  AND ContractName = @contractName
		  
		IF @newCnt NOT BETWEEN @MinConversation AND @MaxConversation
		BEGIN
			SET @ErrorMessage = 'Contract name ' + @contractName + ' : @newCnt must be between ' + CAST(@MinConversation AS VARCHAR(100)) + ' and ' + CAST(@MaxConversation AS VARCHAR(100))
			RAISERROR (@ErrorMessage, -- Message text.  
					   @ErrorSeverity, -- Severity.  
					   @ErrorState -- State.  
					  );
			SET @IsError = 1				  
		END
		
		SET @i = @i + 1
	END	
	
	IF @IsError = 1
		RETURN					
	
	SET @i = 1	
	WHILE @i <= @Count
	BEGIN	
		SELECT @contractName = ContractName
		FROM @t
		WHERE ID = @i
		
		SET @Cnt = NULL
		SET @Cnt = (SELECT Cnt
					FROM sb.ConversationCount WITH (NOLOCK)
					WHERE FunctionName = @functionName
					  AND ContractName = @contractName)
		SET @Cnt = ISNULL(@Cnt, 0)							  
		
		IF @Cnt <> @newCnt
		BEGIN			  
			IF @Cnt < @newCnt -- Open new conversations for specific contract
				EXEC [sb].[ConversationManagement_Ins]
						@functionName = @functionName
					  , @contractName = @contractName  
					  , @fromService = @fromService
					  , @toService = @toService
					  , @newCnt = @newCnt
			ELSE -- Close existing conversations for specific contract
				EXEC [sb].[ConversationManagement_Del]
						@functionName = @functionName
					  , @contractName = @contractName    
					  , @newCnt = @newCnt	 		
		END
		
		SET @i = @i + 1
	END		
		  
	-- warning all contracts without conversation if any for DBA to have more info
	SELECT cfd.ContractName AS ContractWithoutConversation
	FROM sb.ConfigurationReferenceDetail cfd WITH (NOLOCK)
		 LEFT JOIN sb.ConversationCount cc WITH (NOLOCK)
				ON cfd.FunctionName = cc.FunctionName
				   AND cfd.ContractName = cc.ContractName
	WHERE cfd.FunctionName = @functionName 
	  AND ISNULL(cc.Cnt, 0) = 0
	
END
GO