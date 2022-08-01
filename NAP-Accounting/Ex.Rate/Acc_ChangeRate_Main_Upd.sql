/*<info serverAlias="DBTXN-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Acc_ChangeRate_Main_Upd] 
	@TableName VARCHAR(200),
	@IsSiteDB BIT = 0 
AS
/*
	Created: 20211229@Malcolm
	DB: DBTXN-bodb02
	Task: Update rates for all existed tickets once financial change rates

	Revisions:
		- 20211229@Malcolm: Initialize SP [RedmineID: #163417]
		- 20220801@Sophia: Scale out, call at SiteDB [RedmineID: #175253]

	Param's Explanation:
	
	@TableName :
		1-bettransRnG
		2-bettransLC
		3-translog
		4-bettrans
		5-Transfer_Coll
		6-bettransG
 */
BEGIN
	SET NOCOUNT ON 
		  
	IF @TableName IS NULL OR @TableName = ''
	BEGIN
		RAISERROR('pls check @TableName!!!', 16, 1)
		RETURN
	END
	 
	DECLARE @Winlostdate SMALLDATETIME
	SELECT @winlostdate = CONVERT(VARCHAR(10), GETDATE(), 23)
	
	IF @IsSiteDB = 0 
	BEGIN 
		EXEC dbo.ExecRep_00 @Winlostdate = @winlostdate
				, @Target = 'DBTRANS' -- DBTRANS/REPLICATED
				, @TableName = @TableName

		EXEC dbo.ExecRep_00 @Winlostdate = @winlostdate
				, @Target = 'REPLICATED' -- DBTRANS/REPLICATED
				, @TableName = @TableName
	END
	ELSE  --- Call at SiteDB, clone code from ExecRep_00
	BEGIN 
		IF @TableName = 'bettrans' --bettrans@dbtrans
		BEGIN
			-- update for SB's tickets (using virtualrate)
			INSERT INTO #bettrans(transid, actualrate, virtualrate, old_actualrate)
			SELECT transid, e.actualrate, e.actualrate*(b.virtualrate/b.actualrate) AS virtualrate, b.actualrate
			FROM dbo.bettrans b WITH(NOLOCK) 
				INNER JOIN CustDB.dbo.exchange e WITH (NOLOCK) ON b.currency = e.exchangeid
			WHERE b.actualrate <> e.actualrate AND b.winlostdate >= @Winlostdate 
				AND (b.bettype <= 30 OR b.bettype BETWEEN 50 AND 19998) AND b.actualrate <> b.virtualrate
			 
			-- update for SB's tickets (without virtualrate)
			INSERT INTO #bettrans(transid, actualrate, virtualrate, old_actualrate)
			SELECT transid, e.actualrate, e.actualrate, b.actualrate 
			FROM dbo.bettrans b WITH(NOLOCK) 
				,CustDB.dbo.exchange e WITH (NOLOCK)
			WHERE b.currency = e.exchangeid AND b.actualrate <> e.actualrate 
				AND b.winlostdate >= @Winlostdate AND (b.bettype <= 30 OR b.bettype BETWEEN 50 AND 19998) 
				AND b.actualrate = b.virtualrate

			INSERT INTO #bettrans(transid, actualrate, virtualrate, old_actualrate)
			SELECT transid, e.actualrate, e.actualrate, b.actualrate 
			FROM dbo.bettrans b WITH(NOLOCK) 
				,CustDB.dbo.exchange e WITH (NOLOCK)
			WHERE b.currency = e.exchangeid AND b.actualrate <> e.actualrate 
				AND b.winlostdate >= @Winlostdate AND b.bettype BETWEEN 31 AND 49 
				AND b.actualrate = b.virtualrate AND b.currency2 IS NULL

			--==	
			INSERT INTO #bettrans(transid, actualrate, virtualrate, old_actualrate)
			SELECT transid, e.actualrate, b.virtualrate, b.actualrate
			FROM dbo.bettrans b WITH(NOLOCK) 
				,CustDB.dbo.exchange e WITH (NOLOCK)
			WHERE b.currency = e.exchangeid AND b.actualrate <> e.actualrate 
				AND b.winlostdate >= @Winlostdate AND b.bettype BETWEEN 31 AND 49 AND b.currency2 IS NOT NULL

			IF OBJECT_ID ('CashOutSelling', N'U') IS NOT NULL
			BEGIN
				INSERT INTO #CashOutSelling (transid, virtualrate)
				SELECT b.transid, b.actualrate * (co.VirtualRate/b.old_actualrate)
				FROM dbo.CashOutSelling co WITH(NOLOCK)
					INNER JOIN #bettrans b ON b.transid = co.TransID
			END
		END
		
		IF @TableName = 'translog'  --translog@dbtrans
		BEGIN
			-- update for TransLog table (using virtualrate)
			INSERT INTO #translog(transid, actualrate, virtualrate)
			SELECT translogid, e.actualrate, e.actualrate*(b.virtualrate/b.actualrate) as virtualrate
			FROM dbo.TransLog b WITH(NOLOCK) 				
				INNER JOIN CustDB.dbo.exchange e WITH (NOLOCK) ON b.currency = e.exchangeid 
			WHERE b.winlostdate >= @Winlostdate
				AND b.actualrate <> e.actualrate 				
			 
		END

		IF @TableName = 'bettransRnG' --bettransRnG@dbtrans
		BEGIN
			-- update for BettransRNG table (using virtualrate)
			INSERT INTO #bettransRnG(transid, actualrate, virtualrate)
			SELECT transid, e.actualrate, e.actualrate*(b.virtualrate/b.actualrate) as virtualrate
			FROM dbo.BettransRNG b WITH(NOLOCK) 				
				INNER JOIN CustDB.dbo.exchange e WITH (NOLOCK) ON b.currency = e.exchangeid 
			WHERE b.winlostdate >= @Winlostdate
				AND b.actualrate <> e.actualrate 				
				 
		END
		
		IF @TableName = 'bettransLC' --bettransLC@dbtrans
		BEGIN
			-- update for BettransLC table (using virtualrate)
			INSERT INTO #bettransLC(transid, actualrate, virtualrate)
			select transid, e.actualrate, e.actualrate*(b.virtualrate/b.actualrate) as virtualrate
			FROM dbo.BettransLC b WITH(NOLOCK) 				
				INNER JOIN CustDB.dbo.exchange e WITH (NOLOCK) ON b.currency = e.exchangeid 
			WHERE b.winlostdate >= @Winlostdate
				AND b.actualrate <> e.actualrate 
		END
		 
		IF @TableName = 'Transfer_Coll' --transfer_coll@dbtrans
		BEGIN
			-- Transfer_Coll tickets
			INSERT INTO #Transfer_Coll(transid, actualrate)
			SELECT b.transid, e.actualrate
			FROM dbo.Transfer_Coll b WITH(NOLOCK) 
				,CustDB.dbo.exchange e WITH (NOLOCK)
			WHERE b.currency = e.exchangeid AND b.actualrate <> e.actualrate 
				AND b.winlostdate >= @Winlostdate AND b.bettype >= 19001
		END
		
		IF @TableName = 'bettransG' --bettransG@dbtrans
		BEGIN
			-- update for bettransG table 
			INSERT INTO #bettransG(transid, actualrate, virtualrate)
			SELECT b.transid, e.actualrate, e.actualrate * (b.virtualrate / b.actualrate) AS virtualrate
			FROM dbo.bettransG b WITH(NOLOCK)
				INNER JOIN CustDB.dbo.CustInfo c WITH (NOLOCK) ON c.custid = b.custid
				INNER JOIN CustDB.dbo.exchange e WITH (NOLOCK)  ON e.exchangeid = c.currency	
			WHERE b.winlostdate >= @Winlostdate AND b.actualrate <> e.actualrate
		END

		IF @TableName = 'Transfer' --Transfer@dbtrans
		BEGIN
			-- update for transfer table 
			INSERT INTO #transfer(transid, actualrate)
			SELECT transid, e.actualrate
			FROM dbo.Transfer b WITH(NOLOCK) 
				,CustDB.dbo.exchange e WITH (NOLOCK)
			WHERE b.currency = e.exchangeid AND b.actualrate <> e.actualrate 
				AND b.winlostdate >= @Winlostdate 
		END
		
		
		---- Update data	
		
		DECLARE @__table TABLE (transid BIGINT, actualrate FLOAT, virtualrate FLOAT)
		DECLARE @rowcount INT = 1
		
		IF @TableName = 'bettransRnG' --update bettransRnG
		BEGIN
			SET @rowcount = 1
			WHILE @rowcount <> 0
			BEGIN
				DELETE FROM @__table
			
				DELETE TOP(2000) FROM #bettransRnG
				OUTPUT deleted.transid, deleted.actualrate, deleted.virtualrate INTO @__table
				SET @rowcount = @@ROWCOUNT
			
				UPDATE b WITH(ROWLOCK, UPDLOCK)
				SET b.actualrate = t.actualrate,
					b.virtualrate = t.virtualrate
				FROM @__table t 
					INNER JOIN dbo.bettransRnG b ON t.transid = b.transid
			END
		END
		
		IF @TableName = 'bettransLC' --update bettransLC
		BEGIN
			SET @rowcount = 1 
			WHILE @rowcount <> 0
			BEGIN
				DELETE FROM @__table
			
				DELETE TOP(2000) FROM #bettransLC
				OUTPUT deleted.transid, deleted.actualrate, deleted.virtualrate into @__table
				SET @rowcount = @@ROWCOUNT
			
				UPDATE b WITH(ROWLOCK, UPDLOCK)
				SET b.actualrate = t.actualrate,
					b.virtualrate = t.virtualrate
				FROM @__table t 
					INNER JOIN dbo.bettransLC b ON t.transid = b.transid 
			END
		END
		
		IF @TableName = 'translog' --update translog
		BEGIN
			SET @rowcount = 1 
			WHILE @rowcount <> 0
			BEGIN
				DELETE FROM @__table
			
				DELETE TOP(2000) FROM #translog
				OUTPUT deleted.transid, deleted.actualrate, deleted.virtualrate INTO @__table
				SET @rowcount = @@ROWCOUNT
			
				UPDATE b WITH(ROWLOCK, UPDLOCK)
				SET b.actualrate = t.actualrate,
					b.virtualrate = t.virtualrate
				FROM @__table t 
					INNER JOIN dbo.translog b on t.transid = b.translogid 
			END
		END
		
		IF @TableName = 'bettrans' --update bettrans
		BEGIN
			SET @rowcount = 1 
			WHILE @rowcount <> 0
			BEGIN
				DELETE FROM @__table
			
				DELETE TOP(2000) FROM #bettrans 
				OUTPUT deleted.transid, deleted.actualrate, deleted.virtualrate into @__table
				SET @rowcount = @@ROWCOUNT
			
				UPDATE b WITH(ROWLOCK, UPDLOCK)
				SET b.actualrate = t.actualrate,
					b.virtualrate = t.virtualrate
				FROM @__table t 
					INNER JOIN dbo.bettrans b ON t.transid = b.transid 
			END

			IF OBJECT_ID ('CashOutSelling', N'U') IS NOT NULL
			BEGIN
				SET @rowcount = 1
				WHILE @rowcount <> 0
				BEGIN
					DELETE FROM @__table

					DELETE TOP(2000) FROM #CashOutSelling
					OUTPUT deleted.transid, deleted.virtualrate INTO @__table (transid, virtualrate)
					SET @rowcount = @@ROWCOUNT

					UPDATE co WITH(ROWLOCK, UPDLOCK)
					SET co.VirtualRate = t.virtualrate
					FROM @__table t
						INNER JOIN dbo.CashOutSelling co ON co.TransID = t.transid
				END
			END
		END
		
		IF @TableName = 'Transfer_Coll' --update transfer_coll
		BEGIN 
			SET @rowcount = 1 
			WHILE @rowcount <> 0
			BEGIN
				DELETE FROM @__table
				
				DELETE TOP(2000) FROM #Transfer_Coll 
				OUTPUT deleted.transid, deleted.actualrate, 0 INTO @__table
				SET @rowcount = @@ROWCOUNT
				
				UPDATE b WITH(ROWLOCK, UPDLOCK)
				SET b.actualrate = t.actualrate			
				FROM @__table t 
					INNER JOIN dbo.Transfer_Coll b ON t.transid = b.transid 
			END
		END 
		
		IF @TableName = 'bettransG' --update bettransG
		BEGIN
			SET @rowcount = 1
			-- update for bettransG 
			WHILE @rowcount <> 0
			BEGIN
				DELETE FROM @__table
			
				DELETE TOP(2000) FROM #bettransG
				OUTPUT deleted.transid, deleted.actualrate, deleted.virtualrate INTO @__table
				SET @rowcount = @@ROWCOUNT
		
				UPDATE b WITH (ROWLOCK, UPDLOCK)
				SET b.actualrate = t.actualrate, b.virtualrate = t.virtualrate
				FROM @__table t 
					INNER JOIN dbo.bettransG b ON t.transid = b.transid 	
			END
		END

		IF @TableName = 'Transfer' --update Transfer
		BEGIN
			SET @rowcount = 1
			-- update for Transfer 
			WHILE @rowcount <> 0
			BEGIN
				DELETE FROM @__table
			
				DELETE TOP(2000) FROM #transfer
				OUTPUT deleted.transid, deleted.actualrate INTO @__table (transid, actualrate)
				SET @rowcount = @@ROWCOUNT
		
				UPDATE b WITH (ROWLOCK, UPDLOCK)
				SET b.actualrate = t.actualrate
				FROM @__table t 
					INNER JOIN dbo.Transfer b ON t.transid = b.transid 	
			END
		END
	
	END

END