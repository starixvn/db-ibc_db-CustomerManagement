/*<info serverAlias="DBMSG-bodb_Message" executers="bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Age_Msg_GetSpecialMessage]
	@targetid int = 0,
	@targetid2 varchar(100) = '0',
	@special int = 2,
	@sdate datetime = NULL,
	@edate datetime = NULL,
	@IsTest bit = 0,
	@MatchId int = 0,
	@Site varchar(50),
	@PageSize	int = 100,
	@PageIndex	int	= 0,
	@TotalRows 	int	= 0 output
AS
/*
    Created: Elodie
    Task: 
    DB: DBMSG/bodb_Message
    Original: Dot_Msg_GetSpecialMessage
    Revisions:
		- 20220323@Elodie: Initial SP [RedmineID #170363]
		- 20230517@Tacy: Alpha - Special Announcement - Exclude a message sending to 755555 & 76666B [RedmineID: #188246]
		- 20230612@Tacy: Alpha - Enhance annoucement to make it clear to users [RedmineID: #188109]
		- 20230929@Tacy: Alpha - Special Announcement - ONLY Upload for 755555 and 766666b [RedmineID: #194638]
		- 20231204@Tacy: Alpha - Special Announcement - show Announcement "three days" for site 7a5555 [RedmineID: #197951]
		- 20240130@Tacy: Alpha - Special Announcement - show Announcement "seven days" for site 7a5555 [RedmineID: #200446]

	Param's Explanation:
		* MsgID: 1799334 ~ ...【VOID SETTLED WINNING TICKET】 of the past seven days
				 1799336 ~ ...【VOID SETTLED WINNING TICKET】 of the past three days
		
		* @PageSize = 0 ~ all
    
*/
BEGIN
    SET NOCOUNT ON

	DECLARE @rowstart	INT,
			@rowend		INT

	SELECT	@rowstart = @PageSize * @PageIndex + 1, 
			@rowend = @RowStart + @PageSize - 1

	DECLARE @SiteIdList TABLE
	(
	  val CHAR(7) PRIMARY KEY
	)

	CREATE TABLE #Msg (
		[RowID] [int] NOT NULL IDENTITY(1,1),
		[MessageId] [int] NOT NULL,
		[Content_en] [nvarchar](4000) NULL,
		[Content_ch] [nvarchar](4000) NULL,
		[Content_cs] [nvarchar](4000) NULL,
		[Content_jp] [nvarchar](4000) NULL,
		[Content_it] [nvarchar](4000) NULL,
		[Content_th] [nvarchar](4000) NULL,
		[Content_ko] [nvarchar](4000) NULL,
		[Content_es] [nvarchar](4000) NULL,
		[Content_vn] [nvarchar](4000) NULL,
		[Content_id] [nvarchar](4000) NULL,
		[Content_el] [nvarchar](4000) NULL,
		[Content_mx] [nvarchar](4000) NULL,
		[Content_zhcn] [nvarchar](4000) NULL,
		[PostTime] [datetime] NULL,
		[CreateTime] [datetime] NULL,
		[LastUpdateTime] [datetime] NULL,
		[MsgType] [tinyint] NULL,
		[IsSticky] [bit] NULL,
		[IsTest] [bit] NOT NULL,
		[MatchId] [int] NULL,
		[IsBatch] [bit] NULL,
		[Creator] [int] NULL,
		[LastUpdator] [int] NULL,
		[CreatorName] [nvarchar](50) NULL,
		[LastUpdateName] [varchar](50) NULL,
		[BetTransId] [varchar](max) NULL,
		[TopLevel] [tinyint] NOT NULL
	)

	IF @targetid2 <> '0'
	BEGIN
		INSERT @SiteIdList(val)	
		SELECT dbo.FixSiteID(val) 
		FROM dbo.strSplit(@targetid2,',')
	END
	
	INSERT INTO #Msg (MessageId, Content_en, Content_cs, Content_ch,
					Content_jp, Content_th, Content_it, Content_ko,
					Content_es, Content_vn, Content_id, Content_el,
					Content_mx, Content_zhcn,
					PostTime, CreateTime, LastUpdateTime,
					MsgType, IsSticky, IsTest, MatchId, IsBatch,
					Creator, LastUpdator, 
					CreatorName, LastUpdateName,
					BettransID, TopLevel)
	SELECT DISTINCT m.MessageId, m.Content_en, m.Content_cs, m.Content_ch,
					m.Content_jp, m.Content_th, m.Content_it, m.Content_ko,
					m.Content_es, m.Content_vn, m.Content_id, m.Content_el,
					m.Content_mx, m.Content_zhcn,
					m.PostTime, m.CreateTime, m.LastUpdateTime,
					m.MsgType, m.IsSticky, m.IsTest, m.MatchId, m.IsBatch,
					m.Creator, m.LastUpdator, 
					m.CreatorName, m.LastUpdateName,
					mt.BettransID, 
					m.TopLevel
	FROM dbo.Msg m with (nolock)
		INNER JOIN MsgTarget mt with (nolock) ON m.MessageId = mt.MessageId
	WHERE m.IsSticky = 1
		AND m.isDeleted=0 AND mt.isDeleted=0
		AND ((m.MsgType = 1 AND mt.TargetId = @targetid) OR 
				(m.MsgType = 3 AND dbo.FixSiteID(mt.TargetId) IN (SELECT val FROM @SiteIdList)))
		AND CASE				 
				WHEN (@sdate IS NOT NULL AND @edate IS NOT NULL 
					AND m.PostTime BETWEEN @sdate AND @edate) THEN 1		 
				WHEN (@sdate IS NULL AND @edate IS NULL) THEN 1
				WHEN (@sdate IS NOT NULL AND @edate IS NULL AND m.PostTime >= @sdate) THEN 1
				WHEN (@sdate IS NULL AND @edate IS NOT NULL AND m.PostTime <= @edate) THEN 1
			ELSE 0 END = 1
		AND CASE
				WHEN (@IsTest = 1) THEN 1
				WHEN (m.IsTest = @IsTest) THEN 1
			ELSE 0 END = 1
		AND CASE
				WHEN (@MatchID = 0) THEN 1
				WHEN (m.MatchID = @MatchID) THEN 1
			ELSE 0 END = 1
	ORDER BY m.PostTime DESC

	SELECT @TotalRows=COUNT(1)
	FROM #Msg

	SELECT MessageId, Content_en, Content_cs, Content_ch,
		Content_jp, Content_th, Content_it, Content_ko,
		Content_es, Content_vn, Content_id, Content_el,
		Content_mx, Content_zhcn,
		PostTime, CreateTime, LastUpdateTime,
		MsgType, IsSticky, IsTest, MatchId, IsBatch,
		Creator, LastUpdator, 
		CreatorName, LastUpdateName,
		BettransID, TopLevel
	FROM #Msg m
	WHERE CASE
			WHEN (@PageSize <> 0 AND RowID BETWEEN @rowstart AND @rowend) THEN 1
			WHEN (@PageSize = 0) THEN 1
		ELSE 0 END = 1
	AND CASE WHEN @Site IN ('755555', '76666B') AND m.MessageId<>1799334	 THEN 1
			 WHEN @Site NOT IN ('755555', '76666B') AND m.MessageId<>1799336 THEN 1
		ELSE 0 END = 1
	ORDER BY TopLevel, PostTime DESC, RowID

	DROP TABLE #Msg
END