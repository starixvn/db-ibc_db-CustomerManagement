/*
	Created: 20170915@Helen
	Task: SMA Turnover Control - Enhancement requests from phase 2 [RedmineID:75557]
	DB: DBCUST/CUSTDB; DBAGE/bodb02
*/

GO
TRUNCATE TABLE TOControl_LevelSetting
GO
INSERT INTO dbo.TOControl_LevelSetting (PercentValue, PercentLevel,isNotified)
VALUES (0,0,0)
	, (10,1,0)
	, (20, 2,0)
	, (30, 3,0)
	, (40, 4,0)
	, (50, 5,0)
	, (60, 6,1)
	, (70, 7,0)
	, (80, 8,1)
	, (90, 9,0)
	, (100, 10,1)

