USE [bodb_Message]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Dot_Msg_GetMessage]
@targetid int = 0, 
@targetid2 varchar(100) = '0', 
@special int = 2, 
@record int = 1, 
@sdate datetime=NULL, 
@edate datetime=NULL,
@IsTest bit = 0,
@MatchId int = 0
AS
BEGIN
    /*
    Created: @TWTeam
    Task: 
    DB: DB07
    Original:
    Revisions:
        
    Param's Explanation:
    */
	SELECT *
	FROM (
		SELECT DISTINCT m.MessageId, m.Content_en, m.Content_cs, m.Content_ch,
					    m.Content_jp, m.Content_th, m.Content_it, m.Content_ko,
					    m.Content_es, m.PostTime, m.CreateTime, m.LastUpdateTime,
						m.MsgType, m.IsSticky, m.IsTest, m.MatchId,
					    m.Creator, m.LastUpdator, mt.TargetId,
						m.CreatorName, m.LastUpdateName, mt.TargetName as UserName,
						bm.Batchid,bm.BContent_en,bm.BContent_cs,bm.BContent_ch,
						bm.BContent_jp,bm.BContent_th,bm.BContent_it,bm.BContent_ko,
						bm.BContent_es, m.BettransID,
					    DENSE_RANK() OVER(ORDER BY m.PostTime desc) as rownum
		FROM dbo.Msg m with (nolock)
		INNER JOIN dbo.MsgTarget mt with (nolock) ON m.MessageId = mt.MessageId
		LEFT JOIN BatchMsg bm with (nolock) on m.batchid=bm.batchid
		WHERE ((CASE
				  WHEN (@targetid = 0) THEN 1
				  WHEN (@targetid <> 0 AND m.MsgType = 1 AND mt.TargetId = @targetid) THEN 1
				ELSE 0 END = 1) OR
				(CASE
				  WHEN (@targetid2 = '0') THEN 1
				  WHEN (@targetid2 <> '0' AND m.MsgType = 3 AND mt.TargetId IN (SELECT val FROM dbo.strSplit(@targetid2,','))) THEN 1
				ELSE 0 END = 1))
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
END


GO
GRANT EXECUTE ON [dbo].[Dot_Msg_GetMessage] TO [wsv_alp]
GO
GRANT EXECUTE ON [dbo].[Dot_Msg_GetMessage] TO [wsv_alpv]
GO
GRANT VIEW DEFINITION ON [dbo].[Dot_Msg_GetMessage] TO vnteam