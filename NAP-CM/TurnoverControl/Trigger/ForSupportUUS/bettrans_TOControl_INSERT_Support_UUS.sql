ALTER TRIGGER [dbo].[bettrans_TOControl_INSERT]
   ON  [dbo].[bettrans]
   AFTER INSERT
AS 
/*
	Created: Helen
	Date: 2017-09-20
	Task: Insert new CustId to Gobal setting (multiple insert)
	DB: DB053.bodb02
	
	
	- Revisions:
		- 20170920@Helen: TO Control Phase 3 - [Redmine: 75557]
	
	
	XML mapping dictionary tag when buliding and parsing XML string
	Tag		Stand_For
	---		---------
	s		srecommend
	m		mrecommend
	a		arecommend
	mid		matchid
	aTO		adjusted_TurnOver
	aHTO	adjusted_HouseTurnOver
	
	Apply ExtraPT: SUM((1-tpositiontaking-extraPT) * stake))
*/
BEGIN
	DECLARE @XMLString XML = NULL, @HasError BIT = 0 
			
	SET NOCOUNT ON;
	
	DECLARE @GroupHeadlineList TABLE (CustID INT PRIMARY KEY)
	
	INSERT INTO @GroupHeadlineList (CustID)
	SELECT DISTINCT ca.custid
	FROM bodb02.dbo.custAccount ca WITH (NOLOCK) 
		INNER JOIN inserted  Ins ON ca.custid = Ins.custid
	
	
	SELECT @XMLString = (SELECT tmp.super,tmp.master, tmp.agent,tmp.player,tmp.mid, tmp.wld, tmp.adjTO,tmp.adjTOwithABS,tmp.adjHTONoExtraPT
								, tmp.adjTO_RM,tmp.adjTOwithABS_RM,tmp.adjHTONoExtraPT_RM
						FROM (SELECT srecommend AS 'super', mrecommend AS 'master', recommend AS 'agent',0 AS 'player', matchid AS 'mid', winlostdate AS 'wld'
							   
							   , SUM(stake) AS 'adjTO'
							   
							   , SUM(ABS(stake)) AS 'adjTOwithABS'
							   
							   , SUM((1-tpositiontaking)*ABS(stake)) AS 'adjHTONoExtraPT'
							   
							   , CONVERT(MONEY, SUM(stake* (CASE WHEN currency=20 THEN 1 ELSE  actualrate END ))) AS 'adjTO_RM'
							   
							   , CONVERT(MONEY, SUM(ABS(stake * (CASE WHEN currency=20 THEN 1 ELSE  actualrate END )))) AS 'adjTOwithABS_RM'
							   
							   , CONVERT(MONEY, SUM((1-tpositiontaking)*ABS(stake)*(CASE WHEN currency=20 THEN 1 ELSE  actualrate END ))) AS 'adjHTONoExtraPT_RM'
							   
							   
						 FROM inserted  
						 WHERE matchid > 0 AND statusID NOT BETWEEN 101 AND 103
						  	   AND ((bettype < 31 and bettype NOT IN (9,29,10)) OR bettype between 121 and 999 OR bettype BETWEEN 1301 and 1334)
							   
							   AND 1 = CASE WHEN srecommend IS NULL
												OR mrecommend IS NULL
												OR recommend IS NULL
												OR matchid IS NULL
												OR stake IS NULL
												OR tpositiontaking IS NULL
											THEN 0
										ELSE 1 END
								AND betfrom <> 'p'				
										
						 GROUP BY srecommend, mrecommend, recommend, matchid, winlostdate
						 UNION All
						 SELECT srecommend AS 'super', mrecommend AS 'master', recommend AS 'agent', Ins.custid AS 'player',matchid AS 'mid', winlostdate AS 'wld'
							   
							   , SUM(stake) AS 'adjTO'
							   
							   , SUM(ABS(stake)) AS 'adjTOWithABS'
							   
							   , SUM((1-tpositiontaking)*abs(stake)) AS 'aHTONoExtraPT'
							   
							   , CONVERT(MONEY,SUM(stake * (CASE WHEN ins.currency=20 THEN 1 ELSE  Ins.actualrate END ))) AS 'adjTO_RM'
							   
							   , CONVERT(MONEY,SUM(ABS(stake) * (CASE WHEN ins.currency=20 THEN 1 ELSE  Ins.actualrate END ))) AS 'adjTOWithABS_RM'
							   
							   , CONVERT(MONEY,SUM((1-tpositiontaking)*ABS(stake) * (CASE WHEN ins.currency=20 THEN 1 ELSE  Ins.actualrate END ))) AS 'aHTONoExtraPT_RM'
						 FROM inserted  Ins
							INNER JOIN @GroupHeadlineList GHL ON Ins.custid = GHL.CustID
						 WHERE matchid > 0 AND statusID NOT BETWEEN 101 AND 103
						  	   AND ((bettype < 31 and bettype NOT IN (9,29,10)) OR bettype between 121 and 999 OR bettype BETWEEN 1301 and 1334)
							   AND 1 = CASE WHEN srecommend IS NULL
												OR mrecommend IS NULL
												OR recommend IS NULL
												OR matchid IS NULL
												OR stake IS NULL
												OR tpositiontaking IS NULL
											THEN 0
										ELSE 1 END
								AND Ins.betfrom <> 'p'		
						 GROUP BY srecommend, mrecommend, recommend,Ins.custid, matchid, winlostdate) AS tmp
						 
						 FOR XML PATH ('r'))
						 

	IF @XMLString IS NOT NULL
	--put string into SB.Queue
	EXEC sb.TOControl_SendMessage @Xml = @XMLString, @ContractName = 'Contract_TOControl_Single', @SB_error = @HasError OUTPUT
	
END 
