/*
	Task: #72812 TurnOver Control
	Run on : DBCUST
*/

USE [master]
ALTER DATABASE CustDB ADD FILEGROUP [TOControl_Setting]
ALTER DATABASE CustDB ADD FILEGROUP [TOControl_SettingIndex]


ALTER DATABASE CustDB ADD FILE (NAME = N'TOControl_Setting'
								, FILENAME = N'H:\USER_DB\CustDB\TOControl_Setting_01.ndf' --Replace with each environment's appropriate path
								, SIZE = 2048KB , FILEGROWTH = 32768KB)
								,
								(NAME = N'TOControl_Setting'
								, FILENAME = N'H:\USER_DB\CustDB\TOControl_Setting_02.ndf' --Replace with each environment's appropriate path
								, SIZE = 2048KB , FILEGROWTH = 32768KB) TO FILEGROUP [TOControl_Setting]

ALTER DATABASE CustDB ADD FILE (NAME = N'TOControl_SettingIndex'
								, FILENAME = N'H:\USER_DB\CustDB\TOControl_SettingIndex_01.ndf' --Replace with each environment's appropriate path
								, SIZE = 2048KB , FILEGROWTH = 32768KB) TO FILEGROUP [TOControl_SettingIndex]

USE [CustDB]
GO
CREATE TABLE [dbo].[TOControl_GlobalSetting](
	[CustID] [int] NOT NULL,
	[MaxTurnOver] [money] NOT NULL,
 CONSTRAINT [PK_TO_ControlglobalSetting] PRIMARY KEY CLUSTERED 
(
	[CustID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [TOControl_Setting]
) ON [TOControl_Setting]
GO

USE [CustDB]
GO
CREATE TABLE [dbo].[TOControl_Setting](
	[CustID] [int] NOT NULL,
	[matchid] [int] NOT NULL,
	[MaxTurnOver] [money] NULL,
	[TotalTurnOver] [money] NULL,
	[IsNotified] [tinyint] NULL,
	[HouseTurnover] [money] NULL,
	[PercentLevel] [tinyint] NULL,
 CONSTRAINT [PK_TOControl_Setting] PRIMARY KEY CLUSTERED 
(
	[CustID] ASC,
	[matchid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [TOControl_Setting]
) ON [TOControl_Setting]

GO

CREATE NONCLUSTERED INDEX [IX_PercentLevel] ON [dbo].[TOControl_Setting]
(
	[PercentLevel] ASC
)
INCLUDE ([MaxTurnOver],
	[TotalTurnOver],
	[HouseTurnover],
	[IsNotified]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [TOControl_SettingIndex]
GO

ALTER TABLE [dbo].[TOControl_Setting] ADD  CONSTRAINT [DF_TOControl_Setting_isNotified]  DEFAULT ((0)) FOR [IsNotified]
GO
ALTER TABLE [dbo].[TOControl_Setting] ADD  CONSTRAINT [DF_TOControl_Setting_PercentLevel]  DEFAULT ((0)) FOR [PercentLevel]
GO