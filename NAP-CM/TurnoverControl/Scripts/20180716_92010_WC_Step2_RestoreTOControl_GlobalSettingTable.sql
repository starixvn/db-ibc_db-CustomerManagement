/*
	Created: 20180710@Kan
	Task: Rollback global setting after WC event [Redmine: #97774]
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
END
