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