/*<info serverAlias="DBMSG-bodb_Message" executers="bodbDownlineNet,bodbDownlineNetView" viewers="vnteam" isFunction="0" isNested="0"></info>*/
USE [bodb_Message]
GO

ALTER PROCEDURE [dbo].[Age_PublicMessageHistorySel] @TargetId2 VARCHAR(100)
	,@sDate DATETIME
	,@eDate DATETIME
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
		,[Content_en] [nvarchar](4000)
		,[Content_cs] [nvarchar](4000)
		,[Content_ch] [nvarchar](4000)
		,[Content_jp] [nvarchar](4000)
		,[Content_th] [nvarchar](4000)
		,[Content_vn] [nvarchar](4000)
		,[PostTime] [DATETIME]
		,[MsgType] [TINYINT]
		,[IsSticky] [BIT]
		,[TopLevel] [TINYINT]
		)
	DECLARE @PagingData TABLE (
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
		,[TopLevel] [TINYINT]
		,[RowNum] [INT]
		)
	DECLARE @SiteIdList TABLE (val CHAR(7) PRIMARY KEY)
	DECLARE @RowStart INT
		,@RowEnd INT

	SELECT @PageIndex = @PageIndex - 1
		,@RowStart = @PageSize * @PageIndex + 1
		,@RowEnd = @RowStart + @PageSize - 1

	IF @TargetId2 <> '0'
		INSERT @SiteIdList (val)
		SELECT dbo.FixSiteID(val)
		FROM dbo.strSplit(@TargetId2, ',')

	INSERT INTO @Msg
	SELECT m.MessageId
		,m.Content_en
		,m.Content_cs
		,m.Content_ch
		,m.Content_jp
		,m.Content_th
		,m.Content_vn
		,m.PostTime
		,m.MsgType
		,m.IsSticky
		,m.TopLevel
	FROM dbo.Msg m WITH (NOLOCK)
	WHERE m.MsgType = 3
		AND m.TopLevel <> 21
		AND m.isDeleted = 0
		AND m.IsSticky = 0
		AND CASE 
			WHEN (@IsTest = 1) THEN 1
			WHEN (m.IsTest = @IsTest) THEN 1
			ELSE 0
			END = 1
	
	UNION ALL
	SELECT m.MessageId
		,m.Content_en
		,m.Content_cs
		,m.Content_ch
		,m.Content_jp
		,m.Content_th
		,m.Content_vn
		,m.PostTime
		,m.MsgType
		,m.IsSticky
		,m.TopLevel
	FROM dbo.Msg m WITH (NOLOCK)
	WHERE m.MsgType = 3
		AND m.TopLevel = 21
		AND m.isDeleted = 0
		AND m.IsSticky = 0
		AND m.PostTime BETWEEN @sdate
			AND @edate
		AND CASE 
			WHEN (@IsTest = 1) THEN 1
			WHEN (m.IsTest = @IsTest) THEN 1
			ELSE 0
			END = 1

	INSERT INTO @PagingData
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
		,m.TopLevel
		,DENSE_RANK() OVER (
			ORDER BY m.TopLevel
				,m.PostTime DESC
			) AS rownum
	FROM @Msg m
		INNER JOIN dbo.MsgTarget mt WITH (NOLOCK) ON m.MessageId = mt.MessageId
		INNER JOIN @SiteIdList s ON s.val = dbo.FixSiteID(mt.TargetID)
	WHERE mt.isDeleted = 0
	ORDER BY m.TopLevel
		,m.PostTime DESC

	SELECT @TotalRows = COUNT(1)
	FROM @PagingData

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
	FROM @PagingData p
	WHERE p.[RowNum] BETWEEN @RowStart
			AND @RowEnd
END
