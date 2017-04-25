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

	  
