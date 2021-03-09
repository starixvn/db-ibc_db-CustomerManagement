/*<info serverAlias="DBMSG-bodb_Message" executers="bodbDownlineNet,bodbDownlineNetView" viewers="vnteam" isFunction="0" isNested="0"></info>*/
USE [bodb_Message]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
BEGIN
    /*
    Created: @TWTeam
    Task: 
    DB: DB07
    Original:
    Revisions:
        Don@20090923: adapt for new design (Drop table BatchMsg)
		Scott@20120109: add condition for new flag column [isDeleted] to filter deleted data.
		Vivi@20131217: remark --and @IsTest=0, let isTest=1 into if loop, because else performance too bad.
		- 20210309@Max: [Alpha] Duplicated message shown in Personal message [Redmine: #149622]
    Param's Explanation:
    */
    SET NOCOUNT ON;

	IF @targetid>0 and @special=2 AND @sdate IS NOT NULL AND @edate IS NOT NULL AND @MatchID = 0 --and @IsTest=0 
	BEGIN
		declare @topm table (messageid int, targetId int)

		insert into @topm (messageid, targetId)
		SELECT DISTINCT top (@record) m.MessageId, mt.TargetId
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

		select  m.MessageId, m.Content_en, m.Content_cs, m.Content_ch,
							m.Content_jp, m.Content_th, m.Content_it, m.Content_ko,
							m.Content_es, m.Content_vn, m.Content_id, m.Content_el,
							m.Content_mx,
							m.PostTime, m.CreateTime, m.LastUpdateTime,
							m.MsgType, m.IsSticky, m.IsTest, m.MatchId, m.IsBatch,
							m.Creator, m.LastUpdator, 
							m.CreatorName, m.LastUpdateName,
							mt.TargetName as UserName, mt.BettransID, mt.TargetId, 
							0 as rownum
		FROM dbo.Msg m with (nolock)
				INNER JOIN @topm topm on m.MessageId = topm.MessageId
				INNER JOIN dbo.MsgTarget mt with (nolock) ON mt.MessageId = topm.MessageId and mt.TargetId = topm.TargetId
		ORDER BY m.PostTime DESC
	END
	ELSE
	BEGIN
		SELECT *
		FROM (
			SELECT DISTINCT m.MessageId, m.Content_en, m.Content_cs, m.Content_ch,
							m.Content_jp, m.Content_th, m.Content_it, m.Content_ko,
							m.Content_es, m.Content_vn, m.Content_id, m.Content_el,
							m.Content_mx,
							m.PostTime, m.CreateTime, m.LastUpdateTime,
							m.MsgType, m.IsSticky, m.IsTest, m.MatchId, m.IsBatch,
							m.Creator, m.LastUpdator, 
							m.CreatorName, m.LastUpdateName,
							mt.TargetName as UserName, mt.BettransID, mt.TargetId, 
							DENSE_RANK() OVER(ORDER BY m.PostTime desc) as rownum
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

END

GO
