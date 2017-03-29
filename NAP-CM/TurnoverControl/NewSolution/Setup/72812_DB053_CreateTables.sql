/*
	Task: #72812 TurnOver Control
	Run on : DB053; DB054
*/

USE [master]
ALTER DATABASE bodb02 ADD FILEGROUP [TOControl_Transition]
ALTER DATABASE bodb02 ADD FILEGROUP [TOControl_Setting]

ALTER DATABASE bodb02 ADD FILE (NAME = N'TOControl_Transition'
								, FILENAME = N'H:\IBC_DB\bodb02\TOControl_Transition_01.ndf' --Replace with each environment's appropriate path
								, SIZE = 2048KB , FILEGROWTH = 32768KB)
								,
								(NAME = N'TOControl_Transition'
								, FILENAME = N'H:\IBC_DB\bodb02\TOControl_Transition_02.ndf' --Replace with each environment's appropriate path
								, SIZE = 2048KB , FILEGROWTH = 32768KB) TO FILEGROUP [TOControl_Transition]

ALTER DATABASE bodb02 ADD FILE (NAME = N'TOControl_Setting'
								, FILENAME = N'H:\IBC_DB\bodb02\TOControl_Setting_01.ndf' --Replace with each environment's appropriate path
								, SIZE = 2048KB , FILEGROWTH = 32768KB)

USE [bodb02]
GO
CREATE TABLE [dbo].[TOControl_Transition](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[CustID] [int] NOT NULL,
	[matchid] [int] NOT NULL,
	[adjusted_TurnOver] [money] NULL,
	[adjusted_HouseTurnOver] [money] NULL,
	CONSTRAINT [PK_TOControl_Transition] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [TOControl_Transition]
) ON [TOControl_Transition]
GO
USE [bodb02]
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

USE [bodb02]
GO
CREATE TABLE [dbo].[TOControl_GlobalVariables](
	[VName] [varchar](20) NULL,
	[VValue] [varchar](200) NULL,
) ON [TOControl_Setting]
GO
INSERT INTO [dbo].[TOConTrol_GlobalVariables] (VName, VValue)
	SELECT 'MaxID', CONVERT(VARCHAR(200),0)