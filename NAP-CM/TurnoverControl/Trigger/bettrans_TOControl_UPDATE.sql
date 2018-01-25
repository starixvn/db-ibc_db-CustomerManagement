ALTER TRIGGER [dbo].[bettrans_TOControl_UPDATE]
   ON  [dbo].[bettrans]
   AFTER UPDATE
AS 
/*
	Created: Helen
	Date: 2017-09-20
	Task: Insert new CustId to Gobal setting (multiple insert)
	DB: DB053.bodb02
	
	- Revisions:
		- 20170920@Helen: TO Control Phase 3 - [Redmine: 75557]
		- 20171110@Helen: Enhance performance for TO trigger - [Redmine: 86052]
		- 20171212@Helen: Support UUS - Implement some change request from OPS Team - [Redmine: 85638]
*/
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @n TINYINT

	SELECT TOP 2 @n = 1
	FROM inserted

	IF @@ROWCOUNT > 1
		IF (UPDATE(winlost) and UPDATE(statusid) and UPDATE(modds))
			IF ((SELECT TOP 1 statusid FROM deleted) IN (0, 111, 112, 113)) -- just need to get top 1 from the batch because all tickets' status in one batch is the same
				RETURN -- This is normal settment case, stake of ticket does not change ==> return

	
	-- Process for sportbook bettype for TO Control only
	IF EXISTS (SELECT 1 FROM inserted i 
				WHERE ((i.bettype < 31 and i.bettype NOT IN (9,29,10)) OR i.bettype between 121 and 999 OR i.bettype BETWEEN 1301 and 1334)
						AND i.betfrom <> 'p'
				)
	BEGIN			
	
		DECLARE @RowPerCommand SMALLINT = 1000
		, @batchID INT = 1
		, @MinID INT = 0, @MaxID INT = 0
		, @TableMaxID INT
		, @XMLString XML = NULL

		DECLARE @HasError BIT
		
		DECLARE @TmpTable AS TABLE (ID INT IDENTITY (1,1) PRIMARY KEY CLUSTERED, srecommend INT, mrecommend INT, recommend INT,player INT, matchid INT,winlostdate SMALLDATETIME
									, adj_TO MONEY, adj_TO_withABS MONEY, adj_HouseTO MONEY
									, adj_TO_RM MONEY, adj_TO_withABS_RM MONEY, adj_HouseTO_RM MONEY
									)
		--Build command string and push into SB Queue          
		--1000 rows per command string 	
		INSERT INTO @TmpTable (srecommend,  mrecommend, recommend,player, matchid,winlostdate
					, adj_TO,adj_TO_withABS, adj_HouseTO
					, adj_TO_RM,adj_TO_withABS_RM, adj_HouseTO_RM
					)
		SELECT i.srecommend, i.mrecommend, i.recommend,0 AS player, i.matchid,i.winlostdate, 
			
			SUM(CASE WHEN i.statusid IN (101,102,103) AND d.statusid IN (0,1,111,112,113) THEN -i.stake --delete ticket
					 WHEN i.statusid = 0 AND d.statusid = 102 THEN i.stake --recover ticket
					 WHEN d.statusid  = 103 AND i.statusid IN (0,111,112,113) THEN i.stake -- undo or calculate after refund
					 ELSE 0
				END) AS adj_TO,
			
			SUM(CASE WHEN i.statusid IN (101,102,103) AND d.statusid IN (0,1,111,112,113) THEN -ABS(i.stake) --delete ticket
					 WHEN i.statusid = 0 AND d.statusid = 102 THEN ABS(i.stake) --recover ticket
					 WHEN d.statusid  = 103 AND i.statusid IN (0,111,112,113) THEN ABS(i.stake) -- undo or calculate after refund
					 ELSE 0
				END) AS adj_TO_withABS,
					
			SUM(CASE WHEN i.statusid IN (101,102,103) AND d.statusid IN (0,1,111,112,113) THEN -(1-i.tpositiontaking)*abs(i.stake) --delete ticket
					 WHEN i.statusid = 0 AND d.statusid = 102 THEN (1-i.tpositiontaking)*abs(i.stake) --recover ticket
					 WHEN d.statusid  = 103 AND i.statusid IN (0,111,112,113) THEN (1-i.tpositiontaking)*abs(i.stake) -- undo or calculate after refund
					 ELSE 0
				END) AS adj_HouseTO,
			
			SUM(CASE WHEN i.statusid IN (101,102,103) AND d.statusid IN (0,1,111,112,113) THEN -i.stake * (CASE WHEN i.currency = 20 THEN 1 ELSE  i.actualrate END) --delete ticket
					 WHEN i.statusid = 0 AND d.statusid = 102 THEN i.stake * (CASE WHEN i.currency = 20 THEN 1 ELSE  i.actualrate END) --recover ticket
					 WHEN d.statusid  = 103 AND i.statusid IN (0,111,112,113) THEN i.stake * (CASE WHEN i.currency = 20 THEN 1 ELSE  i.actualrate END) -- undo or calculate after refund
					 ELSE 0
				END) AS adj_TO_RM,
			
			SUM(CASE WHEN i.statusid IN (101,102,103) AND d.statusid IN (0,1,111,112,113) THEN -ABS(i.stake * (CASE WHEN i.currency = 20 THEN 1 ELSE  i.actualrate END)) --delete ticket
					 WHEN i.statusid = 0 AND d.statusid = 102 THEN ABS(i.stake * (CASE WHEN i.currency = 20 THEN 1 ELSE  i.actualrate END)) --recover ticket
					 WHEN d.statusid  = 103 AND i.statusid IN (0,111,112,113) THEN ABS(i.stake * (CASE WHEN i.currency = 20 THEN 1 ELSE  i.actualrate END)) -- undo or calculate after refund
					 ELSE 0
				END) AS adj_TO_withABS_RM,
					
			SUM(CASE WHEN i.statusid IN (101,102,103) AND d.statusid IN (0,1,111,112,113) THEN -(1-i.tpositiontaking)*abs(i.stake * (CASE WHEN i.currency = 20 THEN 1 ELSE  i.actualrate END)) --delete ticket
					 WHEN i.statusid = 0 AND d.statusid = 102 THEN (1-i.tpositiontaking)*abs(i.stake * (CASE WHEN i.currency = 20 THEN 1 ELSE  i.actualrate END)) --recover ticket
					 WHEN d.statusid  = 103 AND i.statusid IN (0,111,112,113) THEN (1-i.tpositiontaking)*abs(i.stake * (CASE WHEN i.currency = 20 THEN 1 ELSE  i.actualrate END)) -- undo or calculate after refund
					 ELSE 0
				END) AS adj_HouseTO_RM
					
		FROM inserted i INNER JOIN deleted d ON i.transid = d.transid
		WHERE ((i.bettype < 31 and i.bettype NOT IN (9,29,10)) OR i.bettype between 121 and 999 OR i.bettype BETWEEN 1301 and 1334)
			AND i.betfrom <> 'p'		
		GROUP BY i.srecommend, i.mrecommend, i.recommend, i.matchid,i.winlostdate
		HAVING SUM(CASE WHEN i.statusid IN (101,102,103) AND d.statusid IN (0,1,111,112,113) THEN -i.stake --delete ticket
					 WHEN i.statusid = 0 AND d.statusid = 102 THEN i.stake --recover ticket
					 WHEN d.statusid  = 103 AND i.statusid IN (0,111,112,113) THEN i.stake -- undo or calculate after refund
					 ELSE 0
					END) <> 0 --Only get changed stake
		
		UNION ALL
		
		SELECT i.srecommend, i.mrecommend, i.recommend,I.custid AS player, i.matchid,i.winlostdate, 
			SUM(CASE WHEN i.statusid IN (101,102,103) AND d.statusid IN (0,1,111,112,113) THEN -i.stake --delete ticket
					 WHEN i.statusid = 0 AND d.statusid = 102 THEN i.stake --recover ticket
					 WHEN d.statusid  = 103 AND i.statusid IN (0,111,112,113) THEN i.stake -- undo or calculate after refund
					 ELSE 0
				END) AS adj_TO,
			
			SUM(CASE WHEN i.statusid IN (101,102,103) AND d.statusid IN (0,1,111,112,113) THEN -ABS(i.stake) --delete ticket
					 WHEN i.statusid = 0 AND d.statusid = 102 THEN ABS(i.stake) --recover ticket
					 WHEN d.statusid  = 103 AND i.statusid IN (0,111,112,113) THEN ABS(i.stake) -- undo or calculate after refund
					 ELSE 0
				END) AS adj_TO_withABS,
					
			SUM(CASE WHEN i.statusid IN (101,102,103) AND d.statusid IN (0,1,111,112,113) THEN -(1-i.tpositiontaking)*abs(i.stake) --delete ticket
					 WHEN i.statusid = 0 AND d.statusid = 102 THEN (1-i.tpositiontaking)*abs(i.stake) --recover ticket
					 WHEN d.statusid  = 103 AND i.statusid IN (0,111,112,113) THEN (1-i.tpositiontaking)*abs(i.stake) -- undo or calculate after refund
					 ELSE 0
				END) AS adj_HouseTO,
			
			SUM(CASE WHEN i.statusid IN (101,102,103) AND d.statusid IN (0,1,111,112,113) THEN -i.stake * (CASE WHEN i.currency = 20 THEN 1 ELSE  i.actualrate END)  --delete ticket
					 WHEN i.statusid = 0 AND d.statusid = 102 THEN i.stake * (CASE WHEN i.currency = 20 THEN 1 ELSE  i.actualrate END) --recover ticket
					 WHEN d.statusid  = 103 AND i.statusid IN (0,111,112,113) THEN i.stake * (CASE WHEN i.currency = 20 THEN 1 ELSE  i.actualrate END) -- undo or calculate after refund
					 ELSE 0
				END) AS adj_TO_RM,
			
			SUM(CASE WHEN i.statusid IN (101,102,103) AND d.statusid IN (0,1,111,112,113) THEN -ABS(i.stake * (CASE WHEN i.currency = 20 THEN 1 ELSE  i.actualrate END)) --delete ticket
					 WHEN i.statusid = 0 AND d.statusid = 102 THEN ABS(i.stake * (CASE WHEN i.currency = 20 THEN 1 ELSE  i.actualrate END)) --recover ticket
					 WHEN d.statusid  = 103 AND i.statusid IN (0,111,112,113) THEN ABS(i.stake * (CASE WHEN i.currency = 20 THEN 1 ELSE  i.actualrate END)) -- undo or calculate after refund
					 ELSE 0
				END) AS adj_TO_withABS_RM,
					
			SUM(CASE WHEN i.statusid IN (101,102,103) AND d.statusid IN (0,1,111,112,113) THEN -(1-i.tpositiontaking)*abs(i.stake * (CASE WHEN i.currency = 20 THEN 1 ELSE  i.actualrate END)) --delete ticket
					 WHEN i.statusid = 0 AND d.statusid = 102 THEN (1-i.tpositiontaking)*abs(i.stake * (CASE WHEN i.currency = 20 THEN 1 ELSE  i.actualrate END)) --recover ticket
					 WHEN d.statusid  = 103 AND i.statusid IN (0,111,112,113) THEN (1-i.tpositiontaking)*abs(i.stake * (CASE WHEN i.currency = 20 THEN 1 ELSE  i.actualrate END)) -- undo or calculate after refund
					 ELSE 0
				END) AS adj_HouseTO_RM
					
		FROM inserted i 
			INNER JOIN deleted d ON i.transid = d.transid
		WHERE ((i.bettype < 31 and i.bettype NOT IN (9,29,10)) OR i.bettype between 121 and 999 OR i.bettype BETWEEN 1301 and 1334)
			AND i.betfrom <> 'p'		
			AND EXISTS (SELECT 1 FROM bodb02.dbo.custAccount ca WITH (NOLOCK) WHERE ca.CustID = i.custid )
			
		GROUP BY i.srecommend, i.mrecommend, i.recommend,i.custid, i.matchid,i.winlostdate
		HAVING SUM(CASE WHEN i.statusid IN (101,102,103) AND d.statusid IN (0,1,111,112,113) THEN -i.stake --delete ticket
					 WHEN i.statusid = 0 AND d.statusid = 102 THEN i.stake --recover ticket
					 WHEN d.statusid  = 103 AND i.statusid IN (0,111,112,113) THEN i.stake -- undo or calculate after refund
					 ELSE 0
					END) <> 0 --Only get changed stake
					
		SELECT @TableMaxID = SCOPE_IDENTITY()

		IF @TableMaxID IS NULL OR @TableMaxID = 0
			RETURN

		IF @TableMaxID = 1 --use Contract_TOControl_Single to handle for only one row update
		BEGIN
			SELECT @XMLString = NULL

			SELECT @XMLString = (SELECT srecommend AS 'super',  mrecommend AS 'master', recommend AS 'agent', player 'player' , matchid AS 'mid',winlostdate AS 'wld'
										, adj_TO AS 'adjTO', adj_TO_withABS AS 'adjTOwithABS',adj_HouseTO AS 'adjHTONoExtraPT'
										, adj_TO_RM AS 'adjTO_RM', adj_TO_withABS_RM AS 'adjTOwithABS_RM',adj_HouseTO_RM AS 'adjHTONoExtraPT_RM'
										, 0 AS 'IsInsert'
								 FROM @TmpTable		
								 FOR XML PATH ('r'))

			IF @XMLString IS NOT NULL
				--Input to SB
			EXEC sb.TOControl_SendMessage @Xml = @XMLString, @ContractName = 'Contract_TOControl_Single', @SB_error = @HasError OUTPUT
		END
		ELSE
		BEGIN
			WHILE (1=1)
				BEGIN
					SET @MinID = @RowPerCommand * (@batchID - 1) + 1
					SET @MaxID = @MinID + (@RowPerCommand - 1)

					SELECT @XMLString = NULL

					SELECT @XMLString = (SELECT TOP (@RowPerCommand) srecommend AS 'super',  mrecommend AS 'master', recommend AS 'agent', player 'player', matchid AS 'mid', winlostdate AS 'wld'
													, adj_TO AS 'adjTO', adj_TO_withABS AS 'adjTOwithABS',adj_HouseTO AS 'adjHTONoExtraPT'
													, adj_TO_RM AS 'adjTO_RM', adj_TO_withABS_RM AS 'adjTOwithABS_RM',adj_HouseTO_RM AS 'adjHTONoExtraPT_RM'
													, 0 AS 'IsInsert'
										 FROM @TmpTable		
										 WHERE ID BETWEEN @MinID AND @MaxID
						 				 FOR XML PATH ('r'))

					IF @XMLString IS NOT NULL
						--Input to SB
						EXEC sb.TOControl_SendMessage @Xml = @XMLString, @ContractName = 'Contract_TOControl_Multiple', @SB_error = @HasError OUTPUT

					IF @MaxID >= @TableMaxID
						BREAK

					SET @batchID = @batchID + 1
				END
			END
		END	
END 

GO


