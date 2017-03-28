/*<info serverAlias="DBAGE-bodb02" executers="" viewers="vnteam" isFunction="0" isNested="1"></info>*/

CREATE PROCEDURE [Sb].[ConversationPick]
( 
		@FunctionName VARCHAR(100)
	,	@ContractName VARCHAR(200)
	,	@Handle UNIQUEIDENTIFIER OUT
)
AS
/*
	Create By: Don
	Created Date: 2017-03-22
	Task: Apply Service Broker for Turnover Control function
	DB: DBAGE.bodb02 
	
	Revision

	Para's explaination
*/
BEGIN 
	
	SET NOCOUNT ON 
	DECLARE @ConversationNo INT
			, @Cnt INT
			  
	SELECT @Cnt = Cnt
	FROM sb.ConversationCount WITH (NOLOCK)
	WHERE FunctionName = @functionName AND contractName = @ContractName
	
	SET @Cnt = ISNULL(@Cnt, 0)
	
	IF @Cnt = 0
	BEGIN
		SET @handle = NULL
		RETURN
	END
	
	SET @ConversationNo = @@SPID % @Cnt + 1
	
	SELECT @handle = ConversationHandle
	FROM sb.ConversationManagement WITH (NOLOCK)
	WHERE FunctionName = @functionName
			AND contractName = @ContractName
			AND ConversationNo = @ConversationNo 
			AND IsValid = 1  

END
GO