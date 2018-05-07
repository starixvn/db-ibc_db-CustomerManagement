ALTER TRIGGER [dbo].[translog_TOControl_INSERT]
   ON  [dbo].[translog]
   AFTER INSERT
AS 
/*
	Created: Helen
	Date: 2018-03-15
	Task: Integrate Super Live product
	DB: DB053.bodb02
	
	- Revisions:
		- 20180315@Helen: Integrate Super Live product - [Redmine:89986]
		
	
*/
BEGIN
	
	DECLARE @XMLString XML = NULL, @HasError BIT = 0 
			
	SET NOCOUNT ON;
	
	-- SUPER LIVE, tickets insert into translog
	IF (EXISTS (SELECT 1 FROM inserted WHERE eventID > 0 AND gameID BETWEEN 801 AND 899)) 
	BEGIN
		SELECT @XMLString = (SELECT tmp.super,tmp.master, tmp.agent,tmp.player,tmp.mid, tmp.wld, tmp.adjTO,tmp.adjTOwithABS,tmp.adjHTONoExtraPT
									, tmp.adjTO_RM,tmp.adjTOwithABS_RM,tmp.adjHTONoExtraPT_RM, tmp.IsInsert 
							FROM (SELECT srecommend AS 'super', mrecommend AS 'master', recommend AS 'agent',custid AS 'player', eventID AS 'mid', winlostdate AS 'wld'
								   
								   , SUM(stake) AS 'adjTO'
								   
								   , SUM(ABS(stake)) AS 'adjTOwithABS'
								   
								   , SUM((1-tpositiontaking)*ABS(stake)) AS 'adjHTONoExtraPT'
								   
								   , CONVERT(MONEY, SUM(stake*(CASE WHEN currency = 20 THEN 1 ELSE  actualrate END ))) AS 'adjTO_RM'
								   
								   , CONVERT(MONEY, SUM(ABS(stake * (CASE WHEN currency = 20 THEN 1 ELSE  actualrate END )))) AS 'adjTOwithABS_RM'
								   
								   , CONVERT(MONEY, SUM((1-tpositiontaking)*ABS(stake)*(CASE WHEN currency = 20 THEN 1 ELSE  actualrate END ))) AS 'adjHTONoExtraPT_RM'
								   , 1 AS 'IsInsert'
								 FROM inserted  
								 WHERE eventID > 0 AND statusID NOT BETWEEN 101 AND 103
			  						   AND gameID BETWEEN 801 AND 899
									   AND 1 = CASE WHEN srecommend IS NULL
														OR mrecommend IS NULL
														OR recommend IS NULL
														OR eventID IS NULL
														OR stake IS NULL
														OR tpositiontaking IS NULL
													THEN 0
												ELSE 1 END
										AND betfrom <> 'p'
								 GROUP BY srecommend, mrecommend, recommend,custid, eventID, winlostdate
							 
							 ) AS tmp
							 
							 FOR XML PATH ('r'))
		
		IF @XMLString IS NOT NULL
		BEGIN
			--put string into SB.Queue
			EXEC sb.TOControl_SendMessage @Xml = @XMLString, @ContractName = 'Contract_TOControl_Single', @SB_error = @HasError OUTPUT
		END
	END
	ELSE
	BEGIN
		RETURN
	END
END 


