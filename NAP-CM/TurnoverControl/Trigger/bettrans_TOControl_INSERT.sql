ALTER TRIGGER [dbo].[bettrans_TOControl_INSERT]
   ON  [dbo].[bettrans]
   AFTER INSERT
AS 
/*
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
		INNER JOIN bodb02.dbo.custInfo ci WITH (NOLOCK) ON ci.custid = ca.custid
	WHERE ci.roleid = 1	
			
	SELECT @XMLString = (SELECT tmp.s,tmp.m, tmp.a,tmp.p,tmp.mid, tmp.wld, tmp.aTO,tmp.aHTOWithoutExtraPT
						FROM (SELECT srecommend AS 's', mrecommend AS 'm', recommend AS 'a',0 AS 'p', matchid AS 'mid', winlostdate AS 'wld',
							   SUM(stake) AS 'aTO',
							   SUM((1-tpositiontaking)*abs(stake)) AS 'aHTOWithoutExtraPT'
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
						 SELECT srecommend AS 's', mrecommend AS 'm', recommend AS 'a', Ins.custid AS 'p',matchid AS 'mid', winlostdate AS 'wld',
							   SUM(stake) AS 'aTO',
							   SUM((1-tpositiontaking)*abs(stake)) AS 'aHTOWithoutExtraPT'
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
