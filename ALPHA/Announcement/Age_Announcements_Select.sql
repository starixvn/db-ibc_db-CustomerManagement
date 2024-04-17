/*<info serverAlias="DBMSG-bodb_Message" executers="wsv_alp,bodbDownlineNetView,wsv_alpv,wsv_nap" viewers="vnteam" isFunction="0" isNested="0"></info>*/
USE [bodb_Message]
GO

ALTER PROCEDURE [dbo].[Age_Announcements_Select] @Environment NVARCHAR(50) = ''
	,@FilterBy SMALLINT
	,@System NVARCHAR(20) = ''
	,@FromDate DATETIME
	,@ToDate DATETIME
	,@IsActive BIT = NULL
AS
/*
	Created: 20170707@David
	Task : Announcement Renovation
	DB: DBMSG.bodb_Message/Announcement
	
	Revisions:
		- 20170707@David: Insert Announcement  [Redmine:74338]
		- 20180621@Razor: Renovation Announcement [Redmind: #94705]
		- 20180830@Razor: Add emergency popup [Redmind: #100154]
		- 20190121@Alvin: Update System filter condition
		- Note: consider later. Not write log now because of nowhere uses it and create new table for useless
	Param's Explanation:
		@FilterBy:  1 - Created Date
					2 - Released Date
					3 - Expired Date
*/
BEGIN
	SET NOCOUNT ON

	SELECT [Id]
		,[Code]
		,[Title]
		,[IsActive]
		,[AnnouncementType]
		,[FromDate]
		,[ToDate]
		,[Environments]
		,[Systems]
		,[Ordinal]
		,[Specifications]
		,[Contents]
		,[CreatedDate]
		,[CreatorId]
		,[CreatorName]
		,[LastEditDate]
		,[LastEditorId]
		,[LastEditorName]
	FROM dbo.Announcements WITH (NOLOCK)
	WHERE Environments LIKE '%' + @Environment + '%'
		AND (
			@System = ''
			OR @System IN (
				SELECT ltrim(val)
				FROM dbo.strSplit(Systems, ',')
				)
			)
		AND IsActive = COALESCE(@IsActive, IsActive)
		AND CASE 
			WHEN (
					@FilterBy = 1
					AND CreatedDate BETWEEN @FromDate
						AND @ToDate
					)
				THEN 1
			WHEN (
					@FilterBy = 2
					AND FromDate BETWEEN @FromDate
						AND @ToDate
					)
				THEN 1
			WHEN (
					@FilterBy = 3
					AND ToDate BETWEEN @FromDate
						AND @ToDate
					)
				THEN 1
			ELSE 0
			END = 1
END
GO


