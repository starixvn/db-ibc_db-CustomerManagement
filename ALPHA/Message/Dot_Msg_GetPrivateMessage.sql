/*<info serverAlias="DBMSG-bodb_Message" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView,Dot_Admin,Dot_Member" viewers="vnteam" isFunction="0" isNested="0"></info>*/
USE [bodb_Message]
GO
			
ALTER PROCEDURE [dbo].[Dot_Msg_GetPrivateMessage]
	@targetid int = 0,
	@targetid2 varchar(100) = '0',
	@special int = 2,
	@record	int = 1,
	@sdate datetime = NULL,
	@edate datetime = NULL,
	@IsTest bit = 0,
	@MatchId int = 0
AS
/*
    Created: @TWTeam
    Task: 
    DB: DB07
    Original:
    Revisions:
        Don@20090923: adapt for new design (Drop table BatchMsg)
		Scott@20120109: add condition for new flag column [isDeleted] to filter deleted data.
		Vivi@20131217: remark --and @IsTest=0, let isTest=1 into if loop, because else performance too bad.
		Scott@20180828 : Added Content_zhcn
		- 20210309@Max: [Alpha] Duplicated message shown in Personal message [Redmine: #149622]
    Param's Explanation:
*/
BEGIN
    
    SET NOCOUNT ON;

	CREATE TABLE #MsgTmp(MessageId INT, TargetId INT, TargetName NVARCHAR(100), PostTime DATETIME)
	CREATE TABLE #MsgTarget_dup (MessageId INT, TargetId INT, TargetName NVARCHAR(100))

	IF @targetid > 0 AND @special = 2 AND @sdate IS NOT NULL AND @edate IS NOT NULL AND @MatchID = 0 --and @IsTest=0 
	BEGIN
		INSERT INTO #MsgTmp (messageid, targetId, TargetName)
		SELECT TOP (@record) m.MessageId, mt.TargetId, TargetName
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
		INSERT INTO #MsgTmp (MessageId, TargetId, TargetName, PostTime)
		SELECT new_table.MessageId, new_table.TargetId, new_table.TargetName, new_table.PostTime
		FROM (
			SELECT m.MessageId
							,mt.TargetName
							, mt.TargetId
							, m.PostTime
							, DENSE_RANK() OVER(ORDER BY m.PostTime desc) as rownum
			FROM dbo.Msg m with (nolock)
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
					WHEN (@sdate IS NULL AND @edate IS NULL) THEN 1
					  WHEN (@sdate IS NOT NULL AND @edate IS NOT NULL 
						AND m.PostTime BETWEEN @sdate AND @edate) THEN 1			 
				  
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
	INSERT INTO #MsgTarget_dup (TargetId, TargetName, MessageId)
	SELECT TargetId, TargetName, MessageId
	FROM #MsgTmp
	GROUP BY TargetId,TargetName, MessageId
	HAVING COUNT(1) > 1
	
	IF EXISTS (SELECT TOP 1 1 FROM #MsgTarget_dup)
	BEGIN
		SELECT m.MessageId, m.Content_en, m.Content_cs, m.Content_ch,
							m.Content_jp, m.Content_th, m.Content_it, m.Content_ko,
							m.Content_es, m.Content_vn, m.Content_id, m.Content_el,
							m.Content_mx, m.Content_zhcn,
							m.PostTime, m.CreateTime, m.LastUpdateTime,
							m.MsgType, m.IsSticky, m.IsTest, m.MatchId, m.IsBatch,
							m.Creator, m.LastUpdator, 
							m.CreatorName, m.LastUpdateName,
							topm.TargetName as UserName
							--, mt.BettransID
							,STUFF(tmp.BettransID,1,1,'') as BettransID
							, topm.TargetId, 
							0 as rownum
		FROM dbo.Msg m with (nolock)
				INNER JOIN #MsgTarget_dup topm on m.MessageId = topm.MessageId
				CROSS APPLY (SELECT  ',' + ISNULL(BetTransId ,'')
							FROM dbo.MsgTarget 
							WHERE TargetId = topm.TargetId AND MessageId = m.MessageId
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
							topm.TargetName as UserName
							, mt.BettransID
							, topm.TargetId, 
							0 as rownum
		FROM dbo.Msg m WITH (NOLOCK)
				INNER JOIN #MsgTmp topm ON m.MessageId = topm.MessageId
				INNER JOIN dbo.MsgTarget mt WITH (NOLOCK) ON mt.MessageId = topm.MessageId and mt.TargetId = topm.TargetId
				LEFT JOIN #MsgTarget_dup d ON mt.TargetId = d.TargetId and d.messageid = m.MessageId
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
							topm.TargetName as UserName
							, mt.BettransID
							, topm.TargetId, 
							0 as rownum
		FROM dbo.Msg m WITH (NOLOCK)
				INNER JOIN #MsgTmp topm ON m.MessageId = topm.MessageId
				INNER JOIN dbo.MsgTarget mt WITH (NOLOCK) ON mt.MessageId = topm.MessageId and mt.TargetId = topm.TargetId
		ORDER BY m.PostTime DESC
	END

	DROP TABLE #MsgTarget_dup
	DROP TABLE #MsgTmp
END
