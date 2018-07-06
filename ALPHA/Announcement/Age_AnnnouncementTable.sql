USE [bodb_Message]
GO
/*
	Created: 20170707@David
	Task : Announcement Renovation
	DB: DBMSG/Announcement
	
	Revisions:
		- 20170707@David: Create Announcement Table  [Redmine:74338]
*/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Announcements](
	[Id] [INT] IDENTITY(1,1) NOT NULL,
	[Code] [NVARCHAR](20) NULL,
	[Title] [NVARCHAR](500) NULL,
	[IsActive] [BIT] NOT NULL,
	[AnnouncementType] [SMALLINT] NULL,
	[FromDate] [DATETIME] NOT NULL,
	[ToDate] [DATETIME] NOT NULL,
	[Environments] [NVARCHAR](50) NULL,
	[Systems] [NVARCHAR](20) NULL,
	[Ordinal] [SMALLINT] NULL,
	[Specifications] [NVARCHAR](MAX) NULL,
	[Contents] [NTEXT] NOT NULL,
	[CreatedDate] [DATETIME] NOT NULL,
	[CreatorId] [INT] NULL,
	[CreatorName] [NVARCHAR](50) NULL,
	[LastEditDate] [DATETIME] NULL,
	[LastEditorId] [INT] NULL,
	[LastEditorName] [NVARCHAR](50) NULL,

 CONSTRAINT [PK_Announcements] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO


