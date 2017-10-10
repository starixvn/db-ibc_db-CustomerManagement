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

CREATE TABLE #TOControl_GlobalSetting(
	ID INT IDENTITY(1,1),
	[CustID] [int] NOT NULL,
	[MaxTurnOver] MONEY NOT NULL,
	[Sporttype] [smallint] NOT NULL,
	[IsGroupHeadLine] [bit] NOT NULL,
)

CREATE TABLE #MaxTurnOver_tmp (ExchangeID INT, actualrate FLOAT, MaxTurnOver MONEY)

INSERT INTO #MaxTurnOver_tmp (ExchangeID,actualrate,MaxTurnOver)
SELECT E.exchangeid, E.actualrate, CONVERT(MONEY, 300000/actualrate) AS MaxTurnOver
FROM dbo.Exchange E WITH (NOLOCK)
WHERE EXISTS (SELECT 1 
			  FROM dbo.TOControl_GlobalSetting GS WITH (NOLOCK)
					INNER JOIN dbo.Custinfo CI WITH (NOLOCK) ON GS.CustID = CI.custid 
			  WHERE CI.currency = E.exchangeid		
			)	

INSERT INTO TOControl_GlobalSetting (CustID, MaxTurnOver, Sporttype, IsGroupHeadLine)
SELECT GS.CustID, MT.MaxTurnOver,99,0
FROM dbo.TOControl_GlobalSetting GS WITH (NOLOCK)
	INNER JOIN dbo.Custinfo CI WITH (NOLOCK) ON GS.CustID = CI.custid 
	INNER JOIN dbo.Exchange E WITH (NOLOCK) ON E.exchangeid = CI.currency
	INNER JOIN #MaxTurnOver_tmp MT ON MT.ExchangeID = E.exchangeid
WHERE GS.Sporttype = 1
	
DROP TABLE #MaxTurnOver_tmp
DROP TABLE #TOControl_GlobalSetting

GO
