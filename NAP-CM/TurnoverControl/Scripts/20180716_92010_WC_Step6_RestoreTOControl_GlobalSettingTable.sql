/*
	Created: 20180509@Kan
	Task: Apply temporary global setting for WC event [Redmine: #92010]
	DB: DBCUST/CUSTDB
*/

USE CustDB
GO

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'TOControl_GlobalSetting_BK20180611')
BEGIN
	DECLARE @MaxId INT,
		@Index INT = 1

	SELECT @MaxId = MAX(Id)
	FROM dbo.TOControl_GlobalSetting_BK20180611 WITH (NOLOCK)
	
	-- Restore backed-up data: batch update 1000
	WHILE @Index <= @MaxId
	BEGIN
		UPDATE g
		SET g.MaxTurnOver = bk.MaxTurnOver
		FROM dbo.TOControl_GlobalSetting g WITH (ROWLOCK, UPDLOCK)
			INNER JOIN dbo.TOControl_GlobalSetting_BK20180611 bk WITH (NOLOCK) ON g.CustId = bk.CustId
		WHERE bk.Id BETWEEN @Index AND @Index + 999
			AND g.Sporttype = 1
			AND g.IsGroupHeadLine = 0

		SET @Index += 1000
	END

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

	-- Defer to drop backup table in case of Error (DBA should drop it manually)
    -- DROP TABLE dbo.TOControl_GlobalSetting_BK20180611
END
