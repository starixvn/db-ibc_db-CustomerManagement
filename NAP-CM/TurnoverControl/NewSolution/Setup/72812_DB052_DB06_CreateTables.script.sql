/*
	Task: #72812 TurnOver Control
	Run on : DB052; DB06; DBTP
*/

USE [master]
GO
ALTER DATABASE bodb02 ADD FILEGROUP [TOControl_Setting]

ALTER DATABASE bodb02 ADD FILE (NAME = N'TOControl_Setting_01'
								, FILENAME = N'H:\IBC_DB\bodb02\TOControl_Setting_01.ndf' --Replace with each environment's appropriate path
								, SIZE = 2048KB , FILEGROWTH = 32768KB) TO FILEGROUP [TOControl_Setting]

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