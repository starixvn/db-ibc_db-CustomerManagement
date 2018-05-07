/*
	Created: 20180509@Kan
	Task: Backup TOControl_GlobalSetting before WC Event [Redmine: #92010]
		- Supers, direct Masters, direct Agents
		- SportType = 1 (Soccer)
		- IsGroupHeadLine = 0
	DB: DBCUST/CUSTDB
*/

USE CustDB
GO

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'TOControl_GlobalSetting_BK20180611')
BEGIN
	DROP TABLE dbo.TOControl_GlobalSetting_BK20180611
END

CREATE TABLE dbo.TOControl_GlobalSetting_BK20180611
(
	Id INT IDENTITY(1, 1),
	CustId INT PRIMARY KEY,
	MaxTurnover MONEY,
	MaxCustId INT
)

DECLARE @MaxCustId INT
SELECT @MaxCustId = MAX(CustId) FROM dbo.TOControl_GlobalSetting WITH (NOLOCK)

;WITH CTE AS
(
	-- Supers
	SELECT CustId
	FROM Customer WITH (NOLOCK)
	WHERE RoleId = 4
	UNION ALL
	-- Direct Masters
	SELECT CustId
	FROM Customer WITH (NOLOCK)
	WHERE CustId NOT IN (SELECT CustId FROM Acc_CustDirect WITH (NOLOCK))
		AND SRecommend IN (SELECT CustId from Acc_CustDirect WITH (NOLOCK))
		AND RoleId = 3
	UNION ALL
	-- Direct Agents
	SELECT CustId
	FROM Customer WITH (NOLOCK)
	WHERE CustId NOT IN (SELECT CustId FROM Acc_CustDirect WITH (NOLOCK))
		AND MRecommend IN (SELECT CustId from Acc_CustDirect WITH (NOLOCK))
		AND RoleId = 2
)
INSERT INTO dbo.TOControl_GlobalSetting_BK20180611
	(CustId, MaxTurnover, MaxCustId)
SELECT g.CustId, g.MaxTurnover, @MaxCustId
FROM CTE
	INNER JOIN dbo.TOControl_GlobalSetting g WITH (NOLOCK) ON CTE.CustId = g.CustId
WHERE g.Sporttype = 1
	AND g.IsGroupHeadLine = 0
