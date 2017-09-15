/*
	Create By: Don
	Created Date: 2017-03-22
	Task: Apply Service Broker for Turnover Control function
	DB: DBAGE.bodb02 		
*/

USE bodb02
GO

-- Create configuration table

IF EXISTS(SELECT * FROM sys.tables WHERE type = 'U' AND name = 'ConfigurationReference')
	DROP TABLE [sb].[ConfigurationReference]
GO
CREATE TABLE [sb].[ConfigurationReference](
	[FunctionName] VARCHAR(50) NOT NULL,
	[MaxReceiveMsg] INT,
	[MaxReceiveTimeOut] INT,
	[IsExistingTarget] BIT
	
) ON [ServiceBroker]
GO
ALTER TABLE [sb].[ConfigurationReference] 
	ADD CONSTRAINT PK_ConfigurationReference_FunctionName PRIMARY KEY CLUSTERED ([FunctionName])
GO
ALTER TABLE [sb].[ConfigurationReference] ADD  CONSTRAINT [DF_ConfigurationReference_MaxReceiveMsg]  DEFAULT (1) FOR [MaxReceiveMsg]
GO
ALTER TABLE [sb].[ConfigurationReference] ADD  CONSTRAINT [DF_ConfigurationReference_MaxReceiveTimeOut]  DEFAULT (1) FOR [MaxReceiveTimeOut]
GO

IF EXISTS(SELECT * FROM sys.tables WHERE type = 'U' AND name = 'ConfigurationReferenceDetail')
	DROP TABLE [sb].[ConfigurationReferenceDetail]
GO
CREATE TABLE [sb].[ConfigurationReferenceDetail](
	[FunctionName] VARCHAR(50) NOT NULL,
	[ContractName] VARCHAR(200) NOT NULL,
	[MessageType] VARCHAR(200),
	[MinConversation] INT,
	[MaxConversation] INT
	
) ON [ServiceBroker]
GO
ALTER TABLE [sb].[ConfigurationReferenceDetail] 
	ADD CONSTRAINT PK_ConfigurationReferenceDetail_FunctionName_ContractName 
		PRIMARY KEY CLUSTERED ([FunctionName], [ContractName])
GO
ALTER TABLE [sb].[ConfigurationReferenceDetail] ADD CONSTRAINT [DF_ConfigurationReferenceDetail_MinConversation]  DEFAULT (5) FOR [MinConversation]
GO
ALTER TABLE [sb].[ConfigurationReferenceDetail] ADD CONSTRAINT [DF_ConfigurationReferenceDetail_MaxConversation]  DEFAULT (20) FOR [MaxConversation]
GO
ALTER TABLE [sb].[ConfigurationReferenceDetail] ADD CONSTRAINT [UN_ContractName_MessageType] UNIQUE ([ContractName], [MessageType])
GO

-- Create tables to manage service broker conversation

IF EXISTS(SELECT * FROM sys.tables WHERE type = 'U' AND name = 'ConversationCount')
	DROP TABLE [sb].[ConversationCount]
GO
CREATE TABLE [sb].[ConversationCount]
(
	[FunctionName] VARCHAR(100) NOT NULL,
	[ContractName] VARCHAR(200) NOT NULL,
	[Cnt] INT

)  ON [ServiceBroker]
GO
ALTER TABLE [sb].[ConversationCount] 
	ADD CONSTRAINT PK_ConversationCount_FunctionName_ContractName 
		PRIMARY KEY CLUSTERED ([FunctionName], [ContractName])
GO

IF EXISTS(SELECT * FROM sys.tables WHERE type = 'U' AND name = 'ConversationManagement')
	DROP TABLE [sb].[ConversationManagement]
GO
CREATE TABLE [Sb].[ConversationManagement](
	[FunctionName] VARCHAR(50) NOT NULL, 
	[ContractName] VARCHAR(100) NOT NULL,
	[ConversationNo] INT NOT NULL,
	[ConversationHandle] UNIQUEIDENTIFIER NULL,
	[CreatedDate] DATETIME NULL,
	[IsValid] BIT NULL

) ON [ServiceBroker]
GO
ALTER TABLE [Sb].[ConversationManagement] 
	ADD CONSTRAINT PK_ConversationManagement_FunctionName_ContractName_ConversationNo
		PRIMARY KEY CLUSTERED ([FunctionName], [ContractName], [ConversationNo])
GO
