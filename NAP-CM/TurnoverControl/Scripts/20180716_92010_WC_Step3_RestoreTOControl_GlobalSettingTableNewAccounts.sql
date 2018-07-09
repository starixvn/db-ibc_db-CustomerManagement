/*
	Created: 20180710@Kan
	Task: Rollback global setting after WC event [Redmine: #97774]
	DB: DBCUST/CUSTDB
*/

USE CustDB
GO

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'TOControl_GlobalSetting_BK20180611')
BEGIN
	-- Restore new data updated during WC Event
	-- Update data of Site: 789y
	DECLARE @MaxCustId INT
	
	SELECT TOP 1 @MaxCustId = MaxCustId
	FROM dbo.TOControl_GlobalSetting_BK20180611 WITH (NOLOCK)

	UPDATE g
	SET g.MaxTurnOver = 200000
	FROM dbo.TOControl_GlobalSetting g WITH (ROWLOCK, UPDLOCK)
		INNER JOIN dbo.Customer c WITH (NOLOCK) ON g.CustId = c.CustId
		INNER JOIN dbo.Exchange e WITH (NOLOCK) ON c.Currency = e.ExchangeId
	WHERE g.CustId > @MaxCustId
		AND g.Sporttype = 1
		AND g.IsGroupHeadLine = 0
		AND c.Site = '789y'

	-- Update data of Site: Others
	UPDATE g
	SET g.MaxTurnOver = CASE
		WHEN e.Currency IN ('UUS', 'H', 'C') THEN 300000
		ELSE 300000 / e.ActualRate END
	FROM dbo.TOControl_GlobalSetting g WITH (ROWLOCK, UPDLOCK)
		INNER JOIN dbo.Customer c WITH (NOLOCK) ON g.CustId = c.CustId
		INNER JOIN dbo.Exchange e WITH (NOLOCK) ON c.Currency = e.ExchangeId
	WHERE g.CustId > @MaxCustId
		AND g.Sporttype = 1
		AND g.IsGroupHeadLine = 0
		AND c.Site <> '789y'
END
