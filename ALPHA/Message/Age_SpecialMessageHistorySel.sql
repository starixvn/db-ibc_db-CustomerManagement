/*<info serverAlias="DBMSG-bodb_Message" executers="bodbDownlineNet,bodbDownlineNetView" viewers="vnteam" isFunction="0" isNested="0"></info>*/
USE [bodb_Message]
GO

ALTER PROCEDURE [dbo].[Age_SpecialMessageHistorySel] @TargetId INT
	,@TargetId2 VARCHAR(100)
	,@IsTest BIT = 0
	,@PageSize INT
	,@PageIndex INT
	,@TotalRows INT OUT
AS
/*
	Created: 20180621@Razor
	Task : Announcement Renovation
	DB: DBMSG.bodb_Message
	
	Revisions:
		- 20180621@Razor: Renovation Announcement [Redmind: #94705]
	Param's Explanation: 
		
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @Msg TABLE (
		[MessageId] [INT]
		,[Content_en] [NVARCHAR](4000)
		,[Content_cs] [NVARCHAR](4000)
		,[Content_ch] [NVARCHAR](4000)
		,[Content_jp] [NVARCHAR](4000)
		,[Content_th] [NVARCHAR](4000)
		,[Content_vn] [NVARCHAR](4000)
		,[PostTime] [DATETIME]
		,[MsgType] [TINYINT]
		,[IsSticky] [BIT]
		,[BetTransId] VARCHAR(4000)
		,[RowNum] [INT]
		)
	DECLARE @SiteIdList TABLE (val CHAR(7) PRIMARY KEY)
	DECLARE @RowStart INT
		,@RowEnd INT

	SELECT @PageIndex = @PageIndex - 1
		,@RowStart = @PageSize * @PageIndex + 1
		,@RowEnd = @RowStart + @PageSize - 1

	INSERT @SiteIdList (val)
	SELECT dbo.FixSiteID(val)
	FROM dbo.strSplit(@TargetId2, ',')

	INSERT @Msg
	SELECT DISTINCT m.MessageId
		,m.Content_en
		,m.Content_cs
		,m.Content_ch
		,m.Content_jp
		,m.Content_th
		,m.Content_vn
		,m.PostTime
		,m.MsgType
		,m.IsSticky
		,mt.BettransID
		,DENSE_RANK() OVER (
			ORDER BY m.PostTime DESC
			) AS rownum
	FROM dbo.Msg m WITH (NOLOCK)
		INNER JOIN MsgTarget mt WITH (NOLOCK) ON m.MessageId = mt.MessageId
	WHERE m.IsSticky = 1
		AND m.isDeleted = 0
		AND mt.isDeleted = 0
		AND (
			(
				m.MsgType = 1
				AND mt.TargetId = @targetid
				)
			OR (
				m.MsgType = 3
				AND dbo.FixSiteID(mt.TargetId) IN (
					SELECT val
					FROM @SiteIdList
					)
				)
			)
		AND m.PostTime <= GETDATE()
		AND CASE 
			WHEN (@IsTest = 1) THEN 1
			WHEN (m.IsTest = @IsTest) THEN 1
			ELSE 0
			END = 1
	ORDER BY rownum DESC

	SELECT @TotalRows = COUNT(1)
	FROM @Msg

	SELECT MessageId
		,Content_en
		,Content_cs
		,Content_ch
		,Content_jp
		,Content_th
		,Content_vn
		,PostTime
		,MsgType
		,IsSticky
		,BettransID
		,[RowNum]
	FROM @Msg p
	WHERE p.[RowNum] BETWEEN @RowStart
			AND @RowEnd
END
