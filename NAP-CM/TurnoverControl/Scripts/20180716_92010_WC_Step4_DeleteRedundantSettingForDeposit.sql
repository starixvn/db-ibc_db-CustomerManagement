/*
	Created: 20180706@Kan
	Task: Delete redundant settings for deposit [Redmine: #97774]
	DB: DBCUST/CUSTDB
*/

USE CustDB
GO

CREATE TABLE #DepositCustomers
(
    Id INT IDENTITY(1, 1),
    CustId INT PRIMARY KEY
)

-- Get Deposit Customers who has global setting
INSERT INTO #DepositCustomers
    (CustId)
SELECT DISTINCT ci.CustId
FROM dbo.CustInfo ci WITH (NOLOCK)
    INNER JOIN dbo.Dep_CustSuper dep WITH (NOLOCK) ON ci.SRecommend = dep.CustId
    INNER JOIN dbo.TOControl_GlobalSetting g WITH (NOLOCK) ON ci.CustId = g.CustId

-- Batch delete 1000 in TOControl_GlobalSetting & TOControl_Setting
DECLARE @MaxId INT
SELECT @MaxId = MAX(Id) FROM #DepositCustomers

DECLARE @Index INT = 1

WHILE @Index <= @MaxId
BEGIN
    DELETE
    FROM dbo.TOControl_GlobalSetting
    WHERE CustId IN (
        SELECT CustId
        FROM #DepositCustomers
        WHERE Id BETWEEN @Index AND @Index + 999)

    DELETE
    FROM dbo.TOControl_Setting
    WHERE CustId IN (
        SELECT CustId
        FROM #DepositCustomers
        WHERE Id BETWEEN @Index AND @Index + 999)

    SET @Index += 1000
END

DROP TABLE #DepositCustomers
