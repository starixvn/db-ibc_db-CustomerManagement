/*
	Created: 20180706@Kan
	Task: Backup TOControl_GlobalSetting after WC Event [Redmine: #97774]
	DB: DBCUST/CUSTDB
*/

USE CustDB
GO

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'TOControl_GlobalSetting_BK20180716')
BEGIN
	DROP TABLE dbo.TOControl_GlobalSetting_BK20180716
END

CREATE TABLE dbo.TOControl_GlobalSetting_BK20180716
(
	CustId INT NOT NULL,
	MaxTurnover MONEY NOT NULL,
	SportType SMALLINT NOT NULL,
	IsGroupHeadLine BIT NOT NULL,
	CONSTRAINT PK_TOControl_GlobalSetting_BK20180716 PRIMARY KEY (CustId, SportType, IsGroupHeadLine)
)

INSERT INTO dbo.TOControl_GlobalSetting_BK20180716
	(CustId, MaxTurnover, SportType, IsGroupHeadLine)
SELECT CustId, MaxTurnover, SportType, IsGroupHeadLine
FROM dbo.TOControl_GlobalSetting g WITH (NOLOCK)
