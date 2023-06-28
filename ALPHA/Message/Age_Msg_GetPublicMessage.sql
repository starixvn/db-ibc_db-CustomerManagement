/*<info serverAlias="DBMSG-bodb_Message" executers="bodbDownlineNet,bodbDownlineNetView" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Age_Msg_GetPublicMessage]
	@targetid	int = 0,
	@targetid2	varchar(100) = '0',
	@special	int = 2,
	@sdate		datetime = NULL,
	@edate		datetime = NULL,
	@IsTest		bit = 0,
	@MatchId	int = 0,
	@Site		varchar(50)='',
	@PageSize	int = 100,
	@PageIndex	int	= 0,
	@TotalRows 	int	= 0 output

AS
/*
    Created: 20221121@Tacy
    Task: Alpha - Seperate SP get annoucement & void log spam
    DB: DBMSG-bodb_Message
    Original: Dot_Msg_GetPublicMessage

    Revisions:
		- 20221121@Tacy: Create SP [RedmineID: #180704]
		- 20221123@Tacy: TW enhance performance's sp [Dot_Msg_GetPublicMessage]
		- 20230517@Tacy: Add @Site [RedmineID: #188246]
		- 20230612@Tacy: Alpha - Enhance annoucement to make it clear to users [RedmineID: #188109]

    Param's Explanation:
		* @PageSize = 0 ~ all

 */
BEGIN
	SET NOCOUNT ON

	DECLARE @rowstart	INT,
			@rowend		INT

	SELECT	@rowstart = @PageSize * @PageIndex + 1, 
			@rowend = @RowStart + @PageSize - 1

	CREATE TABLE #TopMsg (RowID INT IDENTITY(1,1), MessageId INT, TopLevel TINYINT)

    IF @targetid=0 AND @PageSize=50 AND @targetid2='4000000,4100000,4100200' AND @special=0 AND @sdate IS NOT NULL AND @edate IS NOT NULL AND @IsTest=0
	BEGIN
		CREATE TABLE #MsgA (MessageId INT, TopLevel TINYINT);

		INSERT INTO #MsgA (MessageId, TopLevel)
		SELECT  m.MessageId, 
			m.TopLevel
		FROM dbo.Msg m WITH (NOLOCK)
		WHERE m.MsgType = 3
			AND m.TopLevel<>21
			AND m.isDeleted=0 
			AND m.IsSticky =0
			AND m.IsTest = 0
			AND m.MessageId >=497229;

		--Union all 
		INSERT INTO #MsgA (MessageId, TopLevel)
		SELECT  m.MessageId, 
				m.TopLevel
		FROM dbo.Msg m WITH (NOLOCK)
		WHERE m.MsgType = 3
			AND m.TopLevel=21
			AND m.isDeleted=0 
			AND m.IsSticky =0
			AND m.PostTime BETWEEN @sdate AND @edate
			AND m.IsTest = 0
			AND m.MessageId >=497229; --343146

		INSERT INTO #TopMsg (MessageId, TopLevel)
		SELECT DISTINCT a.MessageId, a.TopLevel
		FROM #MsgA AS a
		INNER JOIN MsgTarget AS b WITH (NOLOCK) ON a.MessageId = b.MessageId
		WHERE b.TargetId IN ('4000000','4100000','4100200','4000','4100','4120')
			AND b.isDeleted = 0
		ORDER BY a.TopLevel, a.MessageId DESC

		SELECT @TotalRows=COUNT(1)
		FROM #TopMsg

		SELECT  m.MessageId, m.Content_en, m.Content_cs, m.Content_ch,
				m.Content_jp, m.Content_th, m.Content_it, m.Content_ko,
				m.Content_es, m.Content_vn, m.Content_id, m.Content_el,
				m.Content_mx, m.Content_zhcn,
				m.PostTime, m.CreateTime, m.LastUpdateTime,
				m.MsgType, m.IsSticky, m.IsTest, m.MatchId,
				m.Creator, m.LastUpdator, m.CreatorName, m.LastUpdateName, m.IsBatch, 
				'' AS BettransID, 0 AS TargetId, '' AS UserName,
				m.TopLevel
		FROM Msg m WITH (NOLOCK) 
		INNER JOIN #TopMsg t ON m.MessageId = t.MessageId
		WHERE RowID BETWEEN @rowstart AND @rowend
		ORDER BY RowID

		DROP TABLE #MsgA	
	END
	ELSE
	BEGIN
		DECLARE @SiteIdList TABLE
		(
		  val CHAR(7) PRIMARY KEY
		)

		CREATE TABLE #Msg (MessageId INT, TopLevel TINYINT);

		INSERT INTO #Msg (MessageId, TopLevel)
        SELECT  m.MessageId, 
				m.TopLevel
		FROM dbo.Msg m with (nolock )
		WHERE m.MsgType = 3
			AND m.TopLevel<>21
			AND m.isDeleted=0 
			AND CASE
					WHEN ((@special IN (0,1) AND m.IsSticky = @special)) THEN 1
					WHEN (@special = 2) THEN 1
				ELSE 0 END = 1
			AND CASE
					WHEN (@IsTest = 1) THEN 1
					WHEN (m.IsTest = @IsTest) THEN 1
				ELSE 0 END = 1
			AND CASE
					WHEN (@MatchID = 0) THEN 1
					WHEN (m.MatchID = @MatchID) THEN 1
				ELSE 0 END = 1;

		INSERT INTO #Msg (MessageId, TopLevel)
		SELECT  m.MessageId, 
				m.TopLevel
		FROM dbo.Msg m with (nolock )
		WHERE m.MsgType = 3
			AND m.TopLevel=21
			AND m.isDeleted=0 
			AND CASE
					WHEN ((@special IN (0,1) AND m.IsSticky = @special)) THEN 1
					WHEN (@special = 2) THEN 1
				ELSE 0 END = 1
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

		IF @targetid2 <> '0'
		BEGIN
			INSERT @SiteIdList(val)	
			SELECT dbo.FixSiteID(val) FROM dbo.strSplit(@targetid2,',')

			INSERT INTO @SiteIdList 
			SELECT SUBSTRING( val , 1,2  ) + SUBSTRING( val , 5,2  )  
			FROM @SiteIdList
			WHERE LEN(val) > 4 AND SUBSTRING( val , 3,2  ) = '00' AND SUBSTRING( val , 7,1  )  = '0'
				
			INSERT INTO #TopMsg (MessageId, TopLevel)
			SELECT DISTINCT a.MessageId, a.TopLevel
			FROM #Msg AS a
			INNER JOIN MsgTarget AS b WITH (NOLOCK) ON a.MessageId = b.MessageId
			WHERE b.TargetId IN (SELECT val FROM @SiteIdList)
				AND b.isDeleted = 0
			ORDER BY a.TopLevel, a.MessageId DESC
			
			SELECT @TotalRows=COUNT(1)
			FROM #TopMsg

			IF @PageSize > 0
			BEGIN
				SELECT	m.MessageId, m.Content_en, m.Content_cs, m.Content_ch,
						m.Content_jp, m.Content_th, m.Content_it, m.Content_ko,
						m.Content_es, m.Content_vn, m.Content_id, m.Content_el,
						m.Content_mx, m.Content_zhcn,
						m.PostTime, m.CreateTime, m.LastUpdateTime,
						m.MsgType, m.IsSticky, m.IsTest, m.MatchId,
						m.Creator, m.LastUpdator, m.CreatorName, m.LastUpdateName, m.IsBatch, 
						'' AS BettransID, 0 AS TargetId, '' AS UserName,
						m.TopLevel
				FROM Msg m WITH (NOLOCK) 
				INNER JOIN #TopMsg t ON m.MessageId = t.MessageId
				WHERE RowID BETWEEN @rowstart AND @rowend
				ORDER BY RowID
			END
			ELSE IF @PageSize = 0
			BEGIN
				SELECT	m.MessageId, m.Content_en, m.Content_cs, m.Content_ch,
						m.Content_jp, m.Content_th, m.Content_it, m.Content_ko,
						m.Content_es, m.Content_vn, m.Content_id, m.Content_el,
						m.Content_mx, m.Content_zhcn,
						m.PostTime, m.CreateTime, m.LastUpdateTime,
						m.MsgType, m.IsSticky, m.IsTest, m.MatchId,
						m.Creator, m.LastUpdator, m.CreatorName, m.LastUpdateName, m.IsBatch, 
						'' AS BettransID, 0 AS TargetId, '' AS UserName,
						m.TopLevel
				FROM Msg m WITH (NOLOCK) 
				INNER JOIN #TopMsg t ON m.MessageId = t.MessageId
				ORDER BY RowID
			END
		END
		ELSE
		BEGIN
			INSERT INTO #TopMsg (MessageId, TopLevel)
			SELECT DISTINCT TOP (@PageSize) a.MessageId, a.TopLevel
			FROM #Msg AS a
			INNER JOIN MsgTarget AS b WITH (NOLOCK) ON a.MessageId = b.MessageId
			WHERE b.isDeleted = 0
			ORDER BY a.TopLevel, a.MessageId DESC

			SELECT @TotalRows=COUNT(1)
			FROM #TopMsg

			IF @PageSize > 0
			BEGIN
				SELECT	m.MessageId, m.Content_en, m.Content_cs, m.Content_ch,
						m.Content_jp, m.Content_th, m.Content_it, m.Content_ko,
						m.Content_es, m.Content_vn, m.Content_id, m.Content_el,
						m.Content_mx, m.Content_zhcn,
						m.PostTime, m.CreateTime, m.LastUpdateTime,
						m.MsgType, m.IsSticky, m.IsTest, m.MatchId,
						m.Creator, m.LastUpdator, m.CreatorName, m.LastUpdateName, m.IsBatch, 
						'' AS BettransID, 0 AS TargetId, '' AS UserName,
						m.TopLevel
				FROM Msg m WITH (NOLOCK) 
				INNER JOIN #TopMsg t ON m.MessageId = t.MessageId
				WHERE RowID BETWEEN @rowstart AND @rowend
				ORDER BY RowID
			END
			ELSE IF @PageSize = 0
			BEGIN
				SELECT	m.MessageId, m.Content_en, m.Content_cs, m.Content_ch,
						m.Content_jp, m.Content_th, m.Content_it, m.Content_ko,
						m.Content_es, m.Content_vn, m.Content_id, m.Content_el,
						m.Content_mx, m.Content_zhcn,
						m.PostTime, m.CreateTime, m.LastUpdateTime,
						m.MsgType, m.IsSticky, m.IsTest, m.MatchId,
						m.Creator, m.LastUpdator, m.CreatorName, m.LastUpdateName, m.IsBatch, 
						'' AS BettransID, 0 AS TargetId, '' AS UserName,
						m.TopLevel
				FROM Msg m WITH (NOLOCK) 
				INNER JOIN #TopMsg t ON m.MessageId = t.MessageId
				ORDER BY RowID
			END
		END

		DROP TABLE #Msg
	END

	DROP TABLE #TopMsg
END
GO