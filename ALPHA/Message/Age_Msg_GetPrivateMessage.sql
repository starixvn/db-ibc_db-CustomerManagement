/*<info serverAlias="DBMSG-bodb_Message" executers="bodbDownlineNet,bodbDownlineNetView" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Age_Msg_GetPrivateMessage]
	@targetid int = 0,
	@targetid2 varchar(100) = '0',
	@special int = 2,
	@record	int = 1,
	@sdate datetime = NULL,
	@edate datetime = NULL,
	@IsTest bit = 0,
	@MatchId int = 0,
	@Site varchar(50)=''
AS
/*
	Created: 20221121@Tacy
    Task: Alpha - Seperate SP get annoucement & void log spam
    DB: DBMSG-bodb_Message
    Original: Dot_Msg_GetPrivateMessage

    Revisions:
		- 20221121@Tacy: Create SP
		- 20230517@Tacy: Add @Site [RedmineID: #188246]
    Param's Explanation:
*/
BEGIN
    SET NOCOUNT ON;
	
	CREATE TABLE #MsgTmp (
		MessageId INT
		, Content_en NVARCHAR(4000)
		, Content_cs NVARCHAR(4000)
		, Content_ch NVARCHAR(4000)
		, Content_jp NVARCHAR(4000)
		, Content_th NVARCHAR(4000)
		, Content_it NVARCHAR(4000)
		, Content_ko NVARCHAR(4000)
		, Content_es NVARCHAR(4000)
		, Content_vn NVARCHAR(4000)
		, Content_id NVARCHAR(4000)
		, Content_el NVARCHAR(4000)
		, Content_mx NVARCHAR(4000)
		, Content_zhcn NVARCHAR(4000)
		, PostTime DATETIME
		, CreateTime DATETIME
		, LastUpdateTime DATETIME
		, MsgType TINYINT
		, IsSticky BIT
		, IsTest BIT
		, MatchId INT
		, IsBatch BIT
		, Creator INT
		, LastUpdator INT
		, CreatorName VARCHAR(50)
		, LastUpdateName VARCHAR(50)
		, TargetId INT
		, TargetName NVARCHAR(100)		
	)
	CREATE TABLE #MsgTarget_dup (
		MessageId INT		
		, TargetId INT
	)

	IF @targetid > 0 AND @special = 2 AND @sdate IS NOT NULL AND @edate IS NOT NULL AND @MatchID = 0 --and @IsTest=0 
	BEGIN

		INSERT INTO #MsgTmp (MessageId
			, Content_en 
			, Content_cs 
			, Content_ch 
			, Content_jp
			, Content_th 
			, Content_it 
			, Content_ko 
			, Content_es 
			, Content_vn 
			, Content_id 
			, Content_el 
			, Content_mx 
			, Content_zhcn 
			, PostTime 
			, CreateTime 
			, LastUpdateTime 
			, MsgType 
			, IsSticky 
			, IsTest 
			, MatchId 
			, IsBatch 
			, Creator 
			, LastUpdator 
			, CreatorName 
			, LastUpdateName 
			, TargetId 
			, TargetName
		)
		SELECT TOP (@record) m.MessageId
			, m.Content_en 
			, m.Content_cs 
			, m.Content_ch 
			, m.Content_jp
			, m.Content_th 
			, m.Content_it 
			, m.Content_ko 
			, m.Content_es 
			, m.Content_vn 
			, m.Content_id 
			, m.Content_el 
			, m.Content_mx 
			, m.Content_zhcn 
			, m.PostTime 
			, m.CreateTime 
			, m.LastUpdateTime 
			, m.MsgType 
			, m.IsSticky 
			, m.IsTest 
			, m.MatchId 
			, m.IsBatch 
			, m.Creator 
			, m.LastUpdator 
			, m.CreatorName 
			, m.LastUpdateName 
			, mt.TargetId
			, mt.TargetName
		FROM dbo.Msg m with (nolock)
		  INNER JOIN dbo.MsgTarget mt with (nolock) ON m.MessageId = mt.MessageId
		WHERE 
					m.PostTime between @sdate and @edate
					AND m.MsgType = 1
					AND m.isDeleted=0 AND mt.isDeleted=0
					--AND m.IsTest = @IsTest
					AND (@IsTest=1 OR m.IsTest = @IsTest)
					AND mt.TargetID = @targetid
		ORDER BY m.PostTime DESC
	END
	ELSE
	BEGIN
		INSERT INTO #MsgTmp (MessageId
			, Content_en 
			, Content_cs 
			, Content_ch 
			, Content_jp
			, Content_th 
			, Content_it 
			, Content_ko 
			, Content_es 
			, Content_vn 
			, Content_id 
			, Content_el 
			, Content_mx 
			, Content_zhcn 
			, PostTime 
			, CreateTime 
			, LastUpdateTime 
			, MsgType 
			, IsSticky 
			, IsTest 
			, MatchId 
			, IsBatch 
			, Creator 
			, LastUpdator 
			, CreatorName 
			, LastUpdateName 
			, TargetId 
			, TargetName
		)
		SELECT new_table.MessageId
			, new_table.Content_en 
			, new_table.Content_cs 
			, new_table.Content_ch 
			, new_table.Content_jp
			, new_table.Content_th 
			, new_table.Content_it 
			, new_table.Content_ko 
			, new_table.Content_es 
			, new_table.Content_vn 
			, new_table.Content_id 
			, new_table.Content_el 
			, new_table.Content_mx 
			, new_table.Content_zhcn 
			, new_table.PostTime 
			, new_table.CreateTime 
			, new_table.LastUpdateTime 
			, new_table.MsgType 
			, new_table.IsSticky 
			, new_table.IsTest 
			, new_table.MatchId 
			, new_table.IsBatch 
			, new_table.Creator 
			, new_table.LastUpdator 
			, new_table.CreatorName 
			, new_table.LastUpdateName 
			, new_table.TargetId
			, new_table.TargetName
		FROM (
				SELECT m.MessageId
					, m.Content_en 
					, m.Content_cs 
					, m.Content_ch 
					, m.Content_jp
					, m.Content_th 
					, m.Content_it 
					, m.Content_ko 
					, m.Content_es 
					, m.Content_vn 
					, m.Content_id 
					, m.Content_el 
					, m.Content_mx 
					, m.Content_zhcn 
					, m.PostTime 
					, m.CreateTime 
					, m.LastUpdateTime 
					, m.MsgType 
					, m.IsSticky 
					, m.IsTest 
					, m.MatchId 
					, m.IsBatch 
					, m.Creator 
					, m.LastUpdator 
					, m.CreatorName 
					, m.LastUpdateName 
					, mt.TargetId
					, mt.TargetName
					, DENSE_RANK() OVER(ORDER BY m.PostTime desc) as rownum
			FROM dbo.Msg m with (NOLOCK)
				INNER JOIN dbo.MsgTarget mt with (nolock) ON m.MessageId = mt.MessageId
			WHERE m.MsgType = 1
				AND m.isDeleted=0 AND mt.isDeleted=0
				AND CASE
					  WHEN ((@special IN (0,1)) AND m.IsSticky = @special) THEN 1
					  WHEN (@special = 2) THEN 1
					ELSE 0 END = 1
				AND CASE
					  WHEN (@targetid = 0) THEN 1
					  WHEN (@targetid <>0 AND mt.TargetID = @targetid) THEN 1
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
		) new_table
		WHERE CASE
				WHEN (@record <> 0 AND new_table.rownum <= @record) THEN 1
				WHEN (@record = 0) THEN 1
			ELSE 0 END = 1
		ORDER BY PostTime DESC

	END

	--Return Data
	INSERT INTO #MsgTarget_dup (MessageId, TargetId)
	SELECT m.MessageId, m.TargetId
	FROM #MsgTmp m
	GROUP BY m.MessageId, m.TargetId
	HAVING COUNT(1) > 1
	
	IF EXISTS (SELECT TOP 1 1 FROM #MsgTarget_dup)
	BEGIN
		SELECT  m.MessageId, m.Content_en, m.Content_cs, m.Content_ch,
							m.Content_jp, m.Content_th, m.Content_it, m.Content_ko,
							m.Content_es, m.Content_vn, m.Content_id, m.Content_el,
							m.Content_mx, m.Content_zhcn,
							m.PostTime, m.CreateTime, m.LastUpdateTime,
							m.MsgType, m.IsSticky, m.IsTest, m.MatchId, m.IsBatch,
							m.Creator, m.LastUpdator, 
							m.CreatorName, m.LastUpdateName,
							m.TargetName as UserName
							,STUFF(tmp.BettransID,1,1,'') as BettransID
							, m.TargetId, 
							0 as rownum
		FROM #MsgTarget_dup  mt
				CROSS APPLY (SELECT TOP 1  m.MessageId, m.Content_en, m.Content_cs, m.Content_ch,
									m.Content_jp, m.Content_th, m.Content_it, m.Content_ko,
									m.Content_es, m.Content_vn, m.Content_id, m.Content_el,
									m.Content_mx, m.Content_zhcn,
									m.PostTime, m.CreateTime, m.LastUpdateTime,
									m.MsgType, m.IsSticky, m.IsTest, m.MatchId, m.IsBatch,
									m.Creator, m.LastUpdator, 
									m.CreatorName, m.LastUpdateName,
									m.TargetName, m.TargetId
							FROM #MsgTmp m 
							WHERE MessageId = mt.MessageId AND TargetId = mt.TargetId
						)m
				CROSS APPLY (SELECT  ',' + ISNULL(BetTransId ,'')
							FROM dbo.MsgTarget WITH (NOLOCK) 
							WHERE TargetId = m.TargetId AND MessageId = m.MessageId
							FOR XML PATH('')
							) AS tmp(BettransID)
		
		UNION ALL
		SELECT m.MessageId, m.Content_en, m.Content_cs, m.Content_ch,
							m.Content_jp, m.Content_th, m.Content_it, m.Content_ko,
							m.Content_es, m.Content_vn, m.Content_id, m.Content_el,
							m.Content_mx, m.Content_zhcn,
							m.PostTime, m.CreateTime, m.LastUpdateTime,
							m.MsgType, m.IsSticky, m.IsTest, m.MatchId, m.IsBatch,
							m.Creator, m.LastUpdator, 
							m.CreatorName, m.LastUpdateName,
							m.TargetName as UserName
							, mt.BettransID
							, m.TargetId, 
							0 as rownum
		FROM #MsgTmp m
				INNER JOIN dbo.MsgTarget mt WITH (NOLOCK) ON mt.MessageId = m.MessageId AND mt.TargetId = m.TargetId
				LEFT JOIN #MsgTarget_dup d ON m.TargetId = d.TargetId and d.messageid = m.MessageId
		WHERE d.messageid IS NULL
		ORDER BY m.PostTime DESC
	END
	ELSE
	BEGIN
		SELECT m.MessageId, m.Content_en, m.Content_cs, m.Content_ch,
							m.Content_jp, m.Content_th, m.Content_it, m.Content_ko,
							m.Content_es, m.Content_vn, m.Content_id, m.Content_el,
							m.Content_mx, m.Content_zhcn,
							m.PostTime, m.CreateTime, m.LastUpdateTime,
							m.MsgType, m.IsSticky, m.IsTest, m.MatchId, m.IsBatch,
							m.Creator, m.LastUpdator, 
							m.CreatorName, m.LastUpdateName,
							m.TargetName as UserName
							, mt.BettransID
							, m.TargetId, 
							0 as rownum
		FROM #MsgTmp m
			INNER JOIN dbo.MsgTarget mt WITH (NOLOCK) ON mt.MessageId = m.MessageId AND mt.TargetId = m.TargetId
		ORDER BY m.PostTime DESC
	END

	DROP TABLE #MsgTarget_dup
	DROP TABLE #MsgTmp
END
GO