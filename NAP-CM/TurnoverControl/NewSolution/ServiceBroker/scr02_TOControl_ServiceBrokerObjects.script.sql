/* **************** Delete service broker objects **************** */

IF EXISTS (SELECT * FROM sys.objects
           WHERE name =
           N'TOControl_ProcessData')
     DROP PROCEDURE sb.TOControl_ProcessData
GO

-- Drop the queue and service if they already exist.
IF EXISTS (SELECT * FROM sys.services
           WHERE name =
           N'Service_TOControl_Target_DBAGE')
     DROP SERVICE
     [Service_TOControl_Target_DBAGE]
GO

IF EXISTS (SELECT * FROM sys.services
           WHERE name =
           N'Service_TOControl_Initiator_DBAGE')
     DROP SERVICE
     [Service_TOControl_Initiator_DBAGE]
GO

IF EXISTS (SELECT * FROM sys.service_queues
           WHERE name = N'Queue_TOControl_DBAGE')
     DROP QUEUE Queue_TOControl_DBAGE
GO

-- Drop contract and message type if they already exist.
IF EXISTS (SELECT * FROM sys.service_contracts
           WHERE name =
           N'Contract_TOControl_Single')
     DROP CONTRACT
     [Contract_TOControl_Single]
GO

IF EXISTS (SELECT * FROM sys.service_message_types
           WHERE name =
           N'MessageType_TOControl_Single')
     DROP MESSAGE TYPE
     [MessageType_TOControl_Single]
GO

IF EXISTS (SELECT * FROM sys.service_contracts
           WHERE name =
           N'Contract_TOControl_Multiple')
     DROP CONTRACT
     [Contract_TOControl_Multiple]
GO

IF EXISTS (SELECT * FROM sys.service_message_types
           WHERE name =
           N'MessageType_TOControl_Multiple')
     DROP MESSAGE TYPE
     [MessageType_TOControl_Multiple]
GO

/* **************** Create service broker objects **************** */

CREATE MESSAGE TYPE MessageType_TOControl_Single
GO
CREATE MESSAGE TYPE MessageType_TOControl_Multiple
GO

CREATE CONTRACT Contract_TOControl_Single(MessageType_TOControl_Single SENT BY ANY)
GO
CREATE CONTRACT Contract_TOControl_Multiple(MessageType_TOControl_Multiple SENT BY ANY)
GO

CREATE QUEUE Queue_TOControl_DBAGE WITH RETENTION = OFF ON ServiceBroker
GO

CREATE SERVICE Service_TOControl_Initiator_DBAGE 
	ON QUEUE Queue_TOControl_DBAGE(Contract_TOControl_Single, Contract_TOControl_Multiple)
GO

CREATE SERVICE Service_TOControl_Target_DBAGE 
	ON QUEUE Queue_TOControl_DBAGE(Contract_TOControl_Single, Contract_TOControl_Multiple)
GO

----ALTER QUEUE Queue_TOControl_DBAGE
----WITH
----	STATUS = ON,
----	ACTIVATION(
----				STATUS = OFF,
----				PROCEDURE_NAME = [sb].[TOControl_ProcessData],
----				MAX_QUEUE_READERS = 1, -- Maximum Number of queue reader can be started at the same time
----				EXECUTE AS 'dbo'
----			)
----GO