/*
	Created: 20180509@Kan
	Task: Apply temporary global setting for WC event [Redmine: #92010]
	DB: DBCUST/CUSTDB
*/

USE CustDB
GO

CREATE TABLE #TOGlobalList
(
	Id INT IDENTITY(1, 1),
	CustId INT PRIMARY KEY,
    MaxTurnOver MONEY
)

-- Insert data of Site: 789y
INSERT INTO #TOGlobalList
    (CustId, MaxTurnOver)
SELECT g.CustId, 200000
FROM dbo.TOControl_GlobalSetting_BK20180611 g WITH (NOLOCK)
    INNER JOIN dbo.Customer c WITH (NOLOCK) ON g.CustId = c.CustId
    INNER JOIN dbo.Exchange e WITH (NOLOCK) ON c.Currency = e.ExchangeId
WHERE c.Site = '789y'

-- Insert data of Site: Others
INSERT INTO #TOGlobalList
    (CustId, MaxTurnOver)
SELECT g.CustId,
    CASE
        WHEN e.Currency IN ('UUS', 'H', 'C') THEN 500000
        ELSE 500000 / e.ActualRate
    END
FROM dbo.TOControl_GlobalSetting_BK20180611 g WITH (NOLOCK)
    INNER JOIN dbo.Customer c WITH (NOLOCK) ON g.CustId = c.CustId
    INNER JOIN dbo.Exchange e WITH (NOLOCK) ON c.Currency = e.ExchangeId
WHERE c.Site <> '789y'

-- TOControl_GlobalSetting: batch update 1000
DECLARE @MaxId INT
SELECT @MaxId = MAX(Id) FROM #TOGlobalList

DECLARE @Index INT = 1

WHILE @Index <= @MaxId
BEGIN
    UPDATE g
	SET g.MaxTurnOver = t.MaxTurnOver
	FROM dbo.TOControl_GlobalSetting g WITH (ROWLOCK, UPDLOCK)
		INNER JOIN #TOGlobalList t WITH (NOLOCK) ON g.CustId = t.CustId
	WHERE t.Id BETWEEN @Index AND @Index + 999 AND g.Sporttype = 1 AND g.IsGroupHeadLine = 0

	SET @Index += 1000
END

-- Process TOControl_Setting
CREATE TABLE #TOMatchList
(
	Id INT IDENTITY(1, 1),
	CustId INT,
    MatchId INT,
    MaxTurnOver MONEY,
    CONSTRAINT [PK_TOMatchList] PRIMARY KEY CLUSTERED 
    (
        [CustId] ASC,
        [MatchId] ASC
    )
)

INSERT INTO #TOMatchList
    (CustId, MatchId, MaxTurnOver)
SELECT t.CustId, m.MatchId, t.MaxTurnOver
FROM dbo.TOControl_Setting m WITH (NOLOCK)
    INNER JOIN #TOGlobalList t WITH (NOLOCK) ON m.CustId = t.CustId
WHERE m.IsGroupHeadLine = 0 AND m.MatchId IN (
    SELECT MatchId
    FROM DBAGE.bodb02.dbo.Match WITH (NOLOCK)
    WHERE EventStatus = 'running' AND SportType = 1)

-- TOControl_Setting: batch update 1000
SELECT @MaxId = MAX(Id) FROM #TOMatchList
SET @Index = 1

WHILE @Index <= @MaxId
BEGIN
    UPDATE s
	SET s.MaxTurnOver = t.MaxTurnOver,
        s.IsNotified = ISNULL((SELECT MAX(PercentValue) FROM dbo.TOControl_LevelSetting WITH(NOLOCK) WHERE (HouseTurnOver * 100 / t.MaxTurnOver) >= PercentValue AND IsNotified = 1), 0),
        s.PercentLevel = ISNULL((SELECT MAX(PercentLevel) FROM dbo.TOControl_LevelSetting WITH (NOLOCK) WHERE (HouseTurnOver * 100 / t.MaxTurnOver) >= PercentValue), 0) 
	FROM dbo.TOControl_Setting s WITH (ROWLOCK, UPDLOCK)
		INNER JOIN #TOMatchList t WITH (NOLOCK) ON s.CustId = t.CustId AND s.MatchId = t.MatchId
	WHERE t.Id BETWEEN @Index AND @Index + 999
        AND s.IsGroupHeadLine = 0

	SET @Index += 1000
END

DROP TABLE #TOGlobalList
DROP TABLE #TOMatchList
