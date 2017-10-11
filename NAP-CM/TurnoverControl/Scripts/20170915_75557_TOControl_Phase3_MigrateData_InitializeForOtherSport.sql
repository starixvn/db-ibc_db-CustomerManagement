/*
	Created: 20170915@Helen
	Task: SMA Turnover Control - Enhancement requests from phase 2 [RedmineID:75557]
	DB: DBCUST/CUSTDB
	
	Notes: TOControl_GlobalSetting: 6K rows
*/
-------- Soccer --------------------
UPDATE T
	SET Sporttype = 1,IsGroupHeadLine = 0
FROM TOControl_GlobalSetting T WITH (ROWLOCK,UPDLOCK)

------- Other sports -----------------
DELETE FROM TOControl_GlobalSetting WHERE Sporttype = 99

SELECT E.exchangeid, E.actualrate, 300000/actualrate AS MaxTurnOver
INTO #MaxTurnOver_tmp
FROM dbo.Exchange E WITH (NOLOCK)
WHERE EXISTS (SELECT 1 
			  FROM dbo.TOControl_GlobalSetting GS WITH (NOLOCK)
					INNER JOIN dbo.Custinfo CI WITH (NOLOCK) ON GS.CustID = CI.custid 
			  WHERE CI.currency = E.exchangeid		
			)	
	AND E.exchangeid <> 20		

INSERT INTO TOControl_GlobalSetting (CustID, MaxTurnOver, Sporttype, IsGroupHeadLine)
SELECT GS.CustID, CONVERT(MONEY,MT.MaxTurnOver) AS MaxTurnOver ,99,0
FROM dbo.TOControl_GlobalSetting GS WITH (NOLOCK)
	INNER JOIN dbo.Custinfo CI WITH (NOLOCK) ON GS.CustID = CI.custid 
	INNER JOIN dbo.Exchange E WITH (NOLOCK) ON E.exchangeid = CI.currency
	INNER JOIN #MaxTurnOver_tmp MT ON MT.ExchangeID = E.exchangeid
WHERE GS.Sporttype = 1 AND E.exchangeid <> 20
	
DROP TABLE #MaxTurnOver_tmp


GO
