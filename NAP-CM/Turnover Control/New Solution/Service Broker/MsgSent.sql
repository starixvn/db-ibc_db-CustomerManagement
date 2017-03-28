/*<info serverAlias="DBAGE-bodb02" executers="" viewers="vnteam" isFunction="0" isNested="1"></info>*/

CREATE PROCEDURE [Sb].[MsgSent]
(
		@Xml XML
	,	@Handle UNIQUEIDENTIFIER
	,	@MessageType VARCHAR(200)
	,	@ErrorCode INT = 0 OUT
	,	@ErrorMessage VARCHAR(MAX) = '' OUT
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

	DECLARE @sql_string NVARCHAR(MAX) = ''
	SET @sql_string='SEND ON CONVERSATION @handle
					 MESSAGE TYPE ' + @MessageType + '(@xml)'
	BEGIN TRY
		EXEC SP_EXECUTESQL @sql_string,N'@handle uniqueidentifier, @xml xml', @Handle, @Xml
		--PRINT @sql_string
	END TRY
	
	BEGIN CATCH
		SET @ErrorCode = ERROR_NUMBER()
		SET @ErrorMessage = ERROR_MESSAGE()
	END CATCH
	
END
GO