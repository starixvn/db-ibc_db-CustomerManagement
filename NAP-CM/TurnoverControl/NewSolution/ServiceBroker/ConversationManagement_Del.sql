/*<info serverAlias="DBAGE-bodb02" executers="" viewers="vnteam" isFunction="0" isNested="0"></info>*/

CREATE PROCEDURE [sb].[ConversationManagement_Del]
		@FunctionName VARCHAR(100)
	,	@ContractName VARCHAR(100)    
	,	@NewCnt INT 
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
			 		  
	DECLARE @ErrorMessage NVARCHAR(4000) 
		  , @ErrorSeverity INT
		  , @ErrorState INT
	
	SELECT @ErrorSeverity = 10, @ErrorState = 1					
	
	SET @ErrorMessage = '=============================================== Begin decrease process ==============================================='
	RAISERROR (@ErrorMessage, -- Message text.  
			   @ErrorSeverity, -- Severity.  
			   @ErrorState -- State.  
			  );
			  				
	UPDATE sb.ConversationCount WITH (ROWLOCK)
		SET Cnt = @NewCnt
	WHERE FunctionName = @FunctionName
	  AND ContractName = @ContractName	
	
	SET @ErrorMessage = '=============================================== End decrease process ==============================================='
	RAISERROR (@ErrorMessage, -- Message text.  
			   @ErrorSeverity, -- Severity.  
			   @ErrorState -- State.  
			  )
	
END
GO