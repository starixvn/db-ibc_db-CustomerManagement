/*
	Create By: Don
	Created Date: 2017-03-22
	Task: Apply Service Broker for Turnover Control function
	DB: DBAGE.bodb02 		
*/

USE bodb02
GO
DELETE FROM [sb].[ConfigurationReference] WHERE [FunctionName] = 'TOControl'
GO
DELETE FROM [sb].[ConfigurationReferenceDetail] WHERE [FunctionName] = 'TOControl'
GO
DELETE FROM [sb].[ConversationCount] WHERE [FunctionName] = 'TOControl'
GO
DELETE FROM [sb].[ConversationManagement] WHERE [FunctionName] = 'TOControl'
GO
INSERT INTO [sb].[ConfigurationReference]([FunctionName],[MaxReceiveMsg],[MaxReceiveTimeOut],[IsExistingTarget])
VALUES('TOControl',100,200,1)
GO
INSERT INTO [sb].[ConfigurationReferenceDetail]([FunctionName],[ContractName],[MessageType],[MinConversation],[MaxConversation])
VALUES ('TOControl','Contract_TOControl_Single','MessageType_TOControl_Single',5,20)
	  ,('TOControl','Contract_TOControl_Multiple','MessageType_TOControl_Multiple',5,20)
GO

/*
	Create By: Don
	Created Date: 2017-03-22
	Task: Apply Service Broker for Turnover Control function
	DB: DBAGE.bodb02		
*/

USE bodb02
GO
EXEC [Sb].[ConversationManagement_Upd] 
		@functionName = 'TOControl'
	  , @contractName = 'Contract_TOControl_Single'		  
	  , @fromService = 'Service_TOControl_Initiator_DBAGE'
	  , @toService = 'Service_TOControl_Target_DBAGE'
	  , @newCnt = 10
	  
GO
EXEC [Sb].[ConversationManagement_Upd] 
		@functionName = 'TOControl'
	  , @contractName = 'Contract_TOControl_Multiple'		  
	  , @fromService = 'Service_TOControl_Initiator_DBAGE'
	  , @toService = 'Service_TOControl_Target_DBAGE'
	  , @newCnt = 5	  
GO	  
