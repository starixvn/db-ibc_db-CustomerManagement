/*<info serverAlias="DBAGE-bodb02" executers="" viewers="vnteam" isFunction="0"></info>*/
GO
ALTER PROCEDURE [dbo].[Task_TOControl_GetTickets_Insert]
	@batchSize int = 100
AS
/*
	Created:20180626@Helen
	Task: Tuning trigger - [Redmine:97442]
	DB: DBAGE/bodb02; DB054.bodb02
		
	Revision:
		- 20180626@Helen: Tuning trigger - [Redmine:97442]
	
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @MaxRowId BIGINT, @LastRowId BIGINT
	DECLARE @RowIds TABLE (RowId BIGINT, TransId BIGINT, statusID TINYINT, bettype SMALLINT)
	
	DECLARE @ErrorCode BIT = 0, @xml XML
	
	SELECT @LastRowId = sValue
	FROM dbo.TOControl_Tickets_Setting WITH(NOLOCK)
	WHERE sKey = 'TOControl_Insert'
	
	INSERT INTO @RowIds(RowId, TransId,statusID,bettype)
	SELECT TOP (@batchSize) t.rowid, t.TransId, t.statusID, t.bettype 
	FROM dbo.TOControl_TicketDetails_Insert t WITH(NOLOCK)
	WHERE rowid > @LastRowId
	ORDER BY rowid
	
	IF @@ROWCOUNT = 0 RETURN
	
	--wait for all trans can commit
	WAITFOR DELAY '00:00:00:280'
	
	SELECT @MaxRowId = MAX(rowid)
	FROM @RowIds
	
	SET @xml = (  SELECT transid AS TransId,statusID AS statusID, bettype AS Bettype, 1 AS IsInsert
				  FROM @RowIds 
				  FOR XML PATH ('r')
				)
	
	EXEC sb.TOControl_SendMessage @Xml = @xml, @ContractName = 'Contract_TOControl_Single', @SB_error = @ErrorCode OUTPUT
	
	IF @ErrorCode = 0
	BEGIN
		UPDATE dbo.TOControl_Tickets_Setting WITH(ROWLOCK, UPDLOCK) 
		SET sValue = @MaxRowId
		WHERE sKey = 'TOControl_Insert'
	END
	
END