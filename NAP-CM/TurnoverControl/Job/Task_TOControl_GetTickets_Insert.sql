/*<info serverAlias="DBAGE-bodb02" executers="" viewers="vnteam" isFunction="0"></info>*/
GO
ALTER PROCEDURE [dbo].[Task_TOControl_GetTickets_Insert]
	@batchSize int = 1
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

	DECLARE @MaxRowId BIGINT, @LastRowId BIGINT, @TransID VARCHAR(20), @statusID VARCHAR(20), @bettype VARCHAR(20)
	
	SELECT @LastRowId = sValue
	FROM dbo.TOControl_Tickets_Setting WITH(NOLOCK)
	WHERE sKey = 'TOControl_Insert'
	
	SELECT @MaxRowId = MAX(RowId)
	FROM dbo.TOControl_Tickets WITH(NOLOCK)
	

	SELECT @LastRowId = ISNULL(@LastRowId, 0), @MaxRowId = ISNULL(@MaxRowId, 0)
	
	IF (@LastRowId = @MaxRowId) RETURN -- no row
	
	--wait for all trans can commit
	WAITFOR DELAY '00:00:00:280'

	DECLARE @RowIds TABLE (TransId BIGINT, statusID TINYINT, bettype SMALLINT)

	INSERT INTO @RowIds(TransId,statusID,bettype)
	SELECT t.TransId, td.statusID, td.bettype
	FROM dbo.TOControl_Tickets t WITH(NOLOCK)
		INNER JOIN TOControl_TicketDetails td WITH (NOLOCK) ON T.rowID = TD.rowID AND T.transid = TD.transid
	WHERE T.RowId > @LastRowId AND T.RowId <= @MaxRowId
	
	DECLARE @__TmpIds TABLE(TransId BIGINT, statusID TINYINT, bettype SMALLINT)
	DECLARE @MessageData NVARCHAR(MAX), @ErrorCode BIT = 0, @Retry INT = 0, @xml XML
	WHILE 1 = 1
	BEGIN
		DELETE @__TmpIds
		SELECT @TransID = NULL, @ErrorCode = 0, @Retry = 0, @xml = NULL

		DELETE TOP(@batchSize) @RowIds
		OUTPUT DELETED.TransId,DELETED.statusID,DELETED.bettype  INTO @__TmpIds

		IF @@ROWCOUNT = 0
			BREAK

		SELECT @TransID = TransID
				,@statusID = statusID
				,@bettype =  bettype
		FROM @__TmpIds

		SET @xml = N'<r><TransId>' + CAST(@TransID AS VARCHAR(20)) + '</TransId>' + '<statusID>' + CAST(@statusID AS VARCHAR(20)) + '</statusID>' + '<Bettype>' + CAST(@bettype AS VARCHAR(10)) + '</Bettype><IsInsert>1</IsInsert></r>'
		
		Retry:
		EXEC sb.TOControl_SendMessage @Xml = @xml, @ContractName = 'Contract_TOControl_Single', @SB_error = @ErrorCode OUTPUT
		
		IF @ErrorCode > 0
		BEGIN

			SET @Retry = @Retry + 1
			IF @Retry > 10
				BREAK

			WAITFOR DELAY '00:00:00:280'
			GOTO Retry
			
		END
		--wait for all trans can commit
		WAITFOR DELAY '00:00:00:010'
	END

	IF @ErrorCode = 0
	BEGIN
		UPDATE dbo.TOControl_Tickets_Setting WITH(ROWLOCK, UPDLOCK) 
		SET sValue = @MaxRowId
		WHERE sKey = 'TOControl_Insert'
	END
END