/*
	Created: 20180509@Kan
	Task: Apply temporary global setting for WC event [Redmine: #92010]
	DB: DBCUST/CUSTDB
*/

USE CustDB
GO

CREATE TABLE #ProvidedTOList
(
    UserName VARCHAR(64),
    MaxTurnOver MONEY
)

INSERT INTO #ProvidedTOList
    (UserName, MaxTurnOver)
VALUES
    ('S6H', 10000000),
    ('S312RMB', 10000000),
    ('S69BP', 1000000),
    ('S9EU', 1000000),
    ('M033H', 10000000),
    ('KY1', 1000000),
    ('S120S', 10000000),
    ('S312C', 10000000),
    ('S863R', 5000000),
    ('SKHK', 10000000),
    ('Pyy', 5000000),
    ('MHK9', 10000000),
    ('S6EU', 1000000),
    ('M6M', 10000000),
    ('POW', 5000000),
    ('S123R', 10000000),
    ('S56US', 500000),
    ('S124R', 10000000),
    ('WBRP', 10000000),
    ('K1K', 500000),
    ('WBRI', 10000000),
    ('MPH', 10000000),
    ('HPI', 5000000),
    ('S69R', 10000000),
    ('MC', 5000000),
    ('AA', 5000000),
    ('FNU', 500000),
    ('JGBP', 500000),
    ('S58RM', 2000000),
    ('POZ', 5000000),
    ('S312E', 10000000),
    ('HK09', 3000000),
    ('S7D', 5000000),
    ('POT', 5000000),
    ('R312R', 10000000),
    ('S69H', 10000000),
    ('FNH', 3000000),
    ('s6cn', 3000000),
    ('HK8', 5000000),
    ('VBR', 5000000),
    ('S80R', 5000000),
    ('POY', 5000000),
    ('JTRIHK', 5000000),
    ('M8H', 3000000),
    ('S125R', 10000000),
    ('S69NT', 5000000),
    ('M359ARMB', 3000000),
    ('266HK', 3000000),
    ('S6BP', 300000),
    ('FNG', 300000),
    ('SF8', 3000000),
    ('S56AE', 3000000),
    ('SB8R', 1000000),
    ('PPR', 5000000),
    ('HD', 5000000),
    ('SBV', 5000000),
    ('S33E', 300000),
    ('POR', 5000000),
    ('S312G', 10000000),
    ('M606HK', 3000000),
    ('S32DM', 1000000),
    ('WKR', 1000000),
    ('87R', 1000000),
    ('M62AH', 3000000),
    ('S69E', 500000),
    ('02R', 5000000),
    ('M6EU', 200000),
    ('S7RM', 1000000),
    ('FNM', 1000000),
    ('SGMM', 1000000),
    ('M863HK', 5000000),
    ('M69E', 200000),
    ('PYB', 5000000),
    ('XCN', 1000000),
    ('MR', 2000000),
    ('LHR', 1000000),
    ('S312RMC', 10000000),
    ('S69RM', 1000000),
    ('SBRR', 1000000),
    ('BBM', 1000000),
    ('TEK', 2000000),
    ('6666BP', 200000),
    ('S39R', 10000000),
    ('PYA', 5000000),
    ('S312D', 10000000),
    ('S47K', 1000000),
    ('THR', 3000000),
    ('S8AH', 3000000),
    ('MSE', 200000),
    ('SAE', 200000),
    ('SBTL', 500000)

UPDATE g
SET g.MaxTurnOver = t.MaxTurnOver
FROM dbo.TOControl_GlobalSetting g WITH (ROWLOCK, UPDLOCK)
    INNER JOIN dbo.Customer c WITH (NOLOCK) ON g.CustId = c.CustId
	INNER JOIN #ProvidedTOList t ON c.UserName = t.UserName
WHERE g.Sporttype = 1 AND g.IsGroupHeadLine = 0

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
SELECT s.CustId, s.MatchId, t.MaxTurnOver
FROM dbo.TOControl_Setting s WITH (NOLOCK)
    INNER JOIN dbo.Customer c WITH (NOLOCK) ON s.CustId = c.CustId
	INNER JOIN #ProvidedTOList t ON c.UserName = t.UserName
WHERE s.IsGroupHeadLine = 0 AND s.MatchId IN (
    SELECT MatchId
    FROM DBAGE.bodb02.dbo.Match WITH (NOLOCK)
    WHERE EventStatus = 'running' AND SportType = 1)

-- TOControl_Setting: batch update 1000
DECLARE @MaxId INT
SELECT @MaxId = MAX(Id) FROM #TOMatchList

DECLARE @Index INT = 1

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

DROP TABLE #ProvidedTOList
DROP TABLE #TOMatchList
