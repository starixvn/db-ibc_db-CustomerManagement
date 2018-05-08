/*<info serverAlias="DBAGE-bodb02" executers="" viewers="vnteam" isFunction="0" isNested="0"></info>*/

CREATE PROCEDURE [sb].[TOControl_SendMessage]
(	
		@Xml XML = NULL
	,	@FunctionName VARCHAR(100) = 'TOControl'
	,	@ContractName VARCHAR(100) = ''
	,	@SB_error BIT = 0 OUTPUT
)
AS
/*
	Create By: Don
	Created Date: 2017-03-22
	Task: Apply Service Broker for Turnover Control function
	DB: DBAGE.bodb02 
		
	Revision
		- 20180508@Helen: Hardcode messagetype to have better performance [Redmine: N/A]
		
	Para's explaination
*/

BEGIN
	
	SET NOCOUNT ON
	DECLARE @Handle UNIQUEIDENTIFIER, @MessageType VARCHAR (200)
	DECLARE @ErrorCode INT = 0, @ErrorMessage VARCHAR(MAX) = ''
	
	IF @ContractName = 'Contract_TOControl_Single' 
		SET @MessageType = 'MessageType_TOControl_Single'
	ELSE 
		SET @MessageType = 'MessageType_TOControl_Multiple'
			
	--SET @MessageType = (SELECT TOP 1 MessageType FROM sb.ConfigurationReferenceDetail WITH (NOLOCK) WHERE FunctionName = @FunctionName AND ContractName = @ContractName)
	
	EXEC sb.ConversationPick @FunctionName = @FunctionName, @ContractName = @ContractName, @Handle = @Handle OUT
	
	IF @Handle IS NULL
	BEGIN
		SET @SB_error = 1
		RETURN
	END
	ELSE 
	BEGIN
		EXEC sb.MsgSent @Handle = @Handle, @Xml = @Xml, @MessageType = @MessageType , @ErrorCode = @ErrorCode OUT, @ErrorMessage =  @ErrorMessage OUT
		IF @ErrorCode <> 0
			SET @SB_error = 1
		ELSE 
			SET @SB_error = 0	
	END
	
END
GO