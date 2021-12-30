/*<info serverAlias="DBTXN-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Acc_ExchangeBaseRateOnServer]
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(200) = '' OUTPUT,
	@IP VARCHAR(15) = ''
AS
/*
	Created: 20211230@Malcolm
	DB: DBTXN-bodb02
	Task: Update exchange rate

	Revisions:
		- 20211230@Malcolm: Initialize SP [RedmineID: #163417]

	Param's Explanation:

*/
BEGIN
	SET NOCOUNT ON

	DECLARE @Winlostdate DATETIME, @RowCount INT, @Ids VARCHAR(MAX) = ''

	SELECT @Winlostdate = CONVERT(VARCHAR, GETDATE(), 23)

	IF DATEDIFF(DD, @Winlostdate, GETDATE()) > 1
	BEGIN
		RAISERROR('pls check winlostdate!!!', 16, 1)
		RETURN
	END

	-- Outright movement
	EXEC dbo.Task_OutrightMovement

	-- Parlay movement
	EXEC dbo.Task_ParlayMovement @Winlostdate = @Winlostdate

	-- Update exchange rate oanda
	EXEC DBCust.CustDB.dbo.DBA_ExchangeDailyOandaUpd_Actualrate @ExchangeDate = @Winlostdate
	-- Wait for a while to release repication cmds
	WAITFOR DELAY '00:00:10'

	CREATE TABLE #tmp (transid BIGINT, actualrate FLOAT, virtualrate FLOAT)
	CREATE TABLE #translog (translogid BIGINT, actualrate FLOAT, virtualrate FLOAT)
	CREATE TABLE #bettransRnG (transid BIGINT, actualrate FLOAT, virtualrate FLOAT)
	CREATE TABLE #bettransLC (transid BIGINT, actualrate FLOAT, virtualrate FLOAT)
	CREATE TABLE #Transfer_Coll (transid BIGINT, actualrate FLOAT)
	CREATE TABLE #bettransG (transid BIGINT, actualrate FLOAT, virtialrate FLOAT)

	--Get data
	BEGIN
		-- Update for SB's tickets (using virtualrate)
		PRINT '1.--------SB''s tickets (using virtualrate)--------'
			
		INSERT INTO #tmp(transid, actualrate, virtualrate)
		SELECT transid, e.actualrate, e.actualrate*(b.virtualrate/b.actualrate) AS virtualrate
		FROM dbo.bettrans b WITH(NOLOCK) 
			INNER JOIN CustDB.dbo.exchange e WITH (NOLOCK) ON b.currency = e.exchangeid
		WHERE b.actualrate <> e.actualrate AND b.winlostdate >= @Winlostdate 
			AND (b.bettype <= 30 OR b.bettype BETWEEN 50 AND 19998) AND b.actualrate <> b.virtualrate
	 
		PRINT '2.--------SB''s tickets (without virtualrate)--------'
		-- Update for SB's tickets (without virtualrate)
		 
		INSERT INTO #tmp(transid, actualrate, virtualrate)
		SELECT transid, e.actualrate, e.actualrate 
		FROM dbo.bettrans b WITH(NOLOCK) 
			,CustDB.dbo.exchange e WITH (NOLOCK)
		WHERE b.currency = e.exchangeid AND b.actualrate <> e.actualrate AND b.winlostdate >= @Winlostdate AND (b.bettype <= 30 OR b.bettype BETWEEN 50 AND 19998) AND b.actualrate = b.virtualrate
 

		PRINT '3.----------------'			
		INSERT INTO #tmp(transid, actualrate, virtualrate)
		SELECT transid, e.actualrate, e.actualrate 
		FROM dbo.bettrans b WITH(NOLOCK) 
			,CustDB.dbo.exchange e WITH (NOLOCK)
		WHERE b.currency = e.exchangeid AND b.actualrate <> e.actualrate AND b.winlostdate >= @Winlostdate AND b.bettype BETWEEN 31 AND 49 AND b.actualrate = b.virtualrate AND b.currency2 IS NULL
 

		PRINT '4.-------OPENTOTE tickets---------'
		-- OPENTOTE tickets
			
		INSERT INTO #tmp(transid, actualrate, virtualrate)
		SELECT transid, e.actualrate, b.virtualrate
		FROM dbo.bettrans b WITH(NOLOCK) 
			,CustDB.dbo.exchange e WITH (NOLOCK)
		WHERE b.currency = e.exchangeid AND b.actualrate <> e.actualrate AND b.winlostdate >= @Winlostdate AND b.bettype BETWEEN 31 AND 49 AND b.currency2 IS NOT NULL


		PRINT '5.-------transfer tickets---------'
		-- transfer tickets		 
			
		INSERT INTO #tmp(transid, actualrate, virtualrate)
		SELECT transid, e.actualrate, b.virtualrate
		FROM dbo.bettrans b WITH(NOLOCK) 
			,CustDB.dbo.exchange e WITH (NOLOCK)
		WHERE b.currency = e.exchangeid AND b.actualrate <> e.actualrate AND b.winlostdate >= @Winlostdate AND b.bettype >= 19001
 
		-- update for TransLog table (using virtualrate)
		PRINT '6.--------TransLog table--------' 
							
		INSERT INTO #translog(translogid, actualrate, virtualrate)
		SELECT translogid, e.actualrate, e.actualrate*(b.virtualrate/b.actualrate) AS virtualrate
		FROM dbo.TransLog b WITH(NOLOCK) 				
			INNER JOIN CustDB.dbo.exchange e WITH (NOLOCK)
				ON b.currency = e.exchangeid 
		WHERE 
			b.winlostdate >= @Winlostdate
			AND b.actualrate <> e.actualrate 				
			 
		-- update for BettransRNG table (using virtualrate)
		PRINT '8.--------BettransRNG table--------'
	 
		INSERT INTO #bettransRnG(transid, actualrate, virtualrate)
		SELECT transid, e.actualrate, e.actualrate*(b.virtualrate/b.actualrate) AS virtualrate
		FROM dbo.BettransRNG b WITH(NOLOCK) 				
			INNER JOIN CustDB.dbo.exchange e WITH (NOLOCK)
				ON b.currency = e.exchangeid 
		WHERE 
			b.winlostdate >= @Winlostdate
			AND b.actualrate <> e.actualrate 				
				
		-- update for BettransLC table (using virtualrate)
		PRINT '10.--------BettransLC table--------' 
			 
		INSERT INTO #bettransLC(transid, actualrate, virtualrate)
		SELECT transid, e.actualrate, e.actualrate*(b.virtualrate/b.actualrate) AS virtualrate
		FROM dbo.BettransLC b WITH(NOLOCK) 				
			INNER JOIN CustDB.dbo.exchange e WITH (NOLOCK)
				ON b.currency = e.exchangeid 
		WHERE 
			b.winlostdate >= @Winlostdate
			AND b.actualrate <> e.actualrate 
					
		-- Transfer_Coll tickets
		PRINT '11.-------Transfer_Coll table ---------'
				 
		IF EXISTS (SELECT 1 FROM sys.objects WHERE Object_Name(Object_ID) = 'Transfer_Coll')
		BEGIN
			INSERT INTO #Transfer_Coll(transid, actualrate)
			SELECT b.transid, e.actualrate
			FROM dbo.Transfer_Coll b WITH(NOLOCK) 
				,CustDB.dbo.exchange e WITH (NOLOCK)
			WHERE b.currency = e.exchangeid AND b.actualrate <> e.actualrate AND b.winlostdate >= @Winlostdate AND b.bettype >= 19001
		END
		
		-- update for bettransG table 
		PRINT '12.------------------------------------'

		INSERT INTO #bettransG(transid, actualrate, virtialrate)
		SELECT b.transid, e.actualrate, e.actualrate * (b.virtualrate / b.actualrate) AS virtualrate
		FROM  dbo.bettransG b WITH(NOLOCK)
		    INNER JOIN CustDB.dbo.CustInfo c WITH (NOLOCK) ON c.custid = b.custid
			INNER JOIN CustDB.dbo.exchange e WITH (NOLOCK)  ON e.exchangeid = c.currency	
		WHERE b.winlostdate >= @Winlostdate AND b.actualrate <> e.actualrate
	
		PRINT 'END: Reminder of UPDATE Exchange Rate Oanda: EXEC CustDB.dbo.DBA_ExchangeDailyOandaUpd_Actualrate @ExchangeDate=''xxx'''
	END

	DECLARE @table TABLE (transid BIGINT, actualrate FLOAT, virtualrate FLOAT)

	--Update for bettransRnG
	WHILE 1 = 1
	BEGIN
		DELETE FROM @table
		
		DELETE TOP(2000) 		
		FROM #bettransRnG
		OUTPUT deleted.transid, deleted.actualrate, deleted.virtualrate INTO @table
		
		IF @@ROWCOUNT = 0
			BREAK
		
		SELECT @Ids = CONVERT(VARCHAR(MAX), 
					  (
						SELECT 
							  transid AS '@transid'
							   ,actualrate AS '@actualrate'
							   ,virtualrate AS '@virtualrate'
						FROM @table FOR XML PATH('r'), ROOT('root')
					   ))


		EXEC [dbo].[ExecRep_1411915] @TableName = 'bettransRnG', @Target = 'DBTRANS', @ids = @Ids

		EXEC [dbo].[ExecRep_1411915] @TableName = 'bettransRnG', @Target = 'REPLICATED', @ids = @Ids

	END
	--Update for translog 
	WHILE 1 = 1
	BEGIN
		DELETE FROM @table
		
		DELETE TOP(2000) 		
		FROM #translog
		OUTPUT deleted.translogid, deleted.actualrate, deleted.virtualrate INTO @table
		
		IF @@ROWCOUNT = 0
			BREAK
		
		SELECT @Ids = CONVERT(VARCHAR(MAX), 
					  (
						SELECT 
							  transid AS '@transid'
							   ,actualrate AS '@actualrate'
							   ,virtualrate AS '@virtualrate'
						FROM @table FOR XML PATH('r'), ROOT('root')
					   ))

		EXEC [dbo].[ExecRep_1411915] @TableName = 'translog', @Target = 'DBTRANS', @ids = @Ids

		EXEC [dbo].[ExecRep_1411915] @TableName = 'translog', @Target = 'REPLICATED', @ids = @Ids
	END

	--Update for bettrans 
	WHILE 1 = 1
	BEGIN
		DELETE FROM @table
		
		DELETE TOP(2000) 		
		FROM #tmp 
		OUTPUT deleted.transid, deleted.actualrate, deleted.virtualrate INTO @table
		
		IF @@ROWCOUNT = 0
			BREAK
		
		SELECT @Ids = CONVERT(VARCHAR(MAX), 
					  (
						SELECT 
							  transid AS '@transid'
							   ,actualrate AS '@actualrate'
							   ,virtualrate AS '@virtualrate'
						FROM @table FOR XML PATH('r'), ROOT('root')
					   ))

		EXEC [dbo].[ExecRep_1411915] @TableName = 'bettrans', @Target = 'DBTRANS', @ids = @Ids

		EXEC [dbo].[ExecRep_1411915] @TableName = 'bettrans', @Target = 'REPLICATED', @ids = @Ids
	END

	--Update for Transfer_Coll
	WHILE 1 = 1
	BEGIN
		DELETE FROM @table
		
		DELETE TOP(2000) 		
		FROM #Transfer_Coll 
		OUTPUT deleted.transid, deleted.actualrate, 0 INTO @table

		IF @@ROWCOUNT = 0
			BREAK
		
		SELECT @Ids = CONVERT(VARCHAR(MAX), 
				  (
					SELECT 
						  transid AS '@transid'
						   ,actualrate AS '@actualrate'
						   ,virtualrate AS '@virtualrate'
					FROM @table FOR XML PATH('r'), ROOT('root')
				   )) 

		EXEC [dbo].[ExecRep_1411915] @TableName = 'Transfer_Coll', @Target = 'DBTRANS', @ids = @Ids

		EXEC [dbo].[ExecRep_1411915] @TableName = 'Transfer_Coll', @Target = 'REPLICATED', @ids = @Ids
	END

	--Update for bettransG 
	WHILE 1 = 1
	BEGIN
		DELETE FROM @table
		
		DELETE TOP(2000) 
		FROM #bettransG
		OUTPUT deleted.transid, deleted.actualrate, deleted.virtialrate INTO @table

		IF @@ROWCOUNT = 0
			BREAK

		SELECT @Ids = CONVERT(VARCHAR(MAX), 
					  (
						SELECT 
							  transid AS '@transid'
							   ,actualrate AS '@actualrate'
							   ,virtualrate AS '@virtualrate'
						FROM @table FOR XML PATH('r'), ROOT('root')
					   )) 

		EXEC [dbo].[ExecRep_1411915] @TableName = 'bettransG', @Target = 'DBTRANS', @ids = @Ids

		EXEC [dbo].[ExecRep_1411915] @TableName = 'bettransG', @Target = 'REPLICATED', @ids = @Ids
	END

	DROP TABLE #bettransG
	DROP TABLE #bettransLC
	DROP TABLE #bettransRnG
	DROP TABLE #tmp
	DROP TABLE #Transfer_Coll
	DROP TABLE #translog
END
GO
