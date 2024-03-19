/*<info serverAlias="DBMSG-bodb_Message" executers="bodbDownlineNet,wsv_alp,bodbDownlineNetView,wsv_alpv" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Age_Msg_GetTopPriMessage24]
	@UserID int,
	@IsTest bit = 0,
	@LatestMsgID int = 0 -- Check new msg count that newer than this messageid
AS
/*
	Created: 20221121@Tacy
    Task: Alpha - Seperate SP get annoucement & void log spam
    DB: DBMSG-bodb_Message
    Original: Dot_Msg_GetTopPriMessage24

    Revisions:
			- 20221121@Tacy: Create SP

    Param's Explanation:
*/
BEGIN
	SET NOCOUNT ON;
	
	-- SELECT min(m.MessageId) FROM msg m (nolock) WHERE m.posttime > dateadd(d,-1,getdate()) and m.MsgType=1 AND m.IsSticky = 0
	IF @LatestMsgID=0 SET @LatestMsgID=261210
	
	IF @IsTest=0	
	BEGIN
		IF EXISTS (SELECT 1 FROM MsgTarget with (nolock) where targetid=@UserID)
		BEGIN
			SELECT TOP 1 m.MessageId, m.Content_en, m.Content_cs, m.Content_ch,
					 m.Content_jp, m.Content_th, m.Content_it, m.Content_ko,
					 m.Content_es, m.Content_vn, m.Content_id, m.Content_el,
					 m.Content_mx, m.Content_zhcn,
					 m.PostTime, m.CreateTime, m.LastUpdateTime,
					 m.MsgType, m.IsSticky, m.IsTest, m.MatchId, m.IsBatch,
					 m.Creator, m.LastUpdator, 
					 m.CreatorName, m.LastUpdateName,
					 mt.TargetName as UserName, mt.BettransID, mt.TargetId
			FROM dbo.Msg m with (nolock, index = [PK_Msg])
				INNER JOIN  dbo.MsgTarget  mt with (Nolock) ON m.MessageId = mt.MessageId 
			WHERE m.posttime > dateadd(d,-1,getdate()) and m.MsgType=1 and mt.TargetId=@UserID
			AND m.MessageId > @LatestMsgID
			AND m.IsSticky = 0
			AND m.IsTest=0
			AND m.isDeleted=0 AND mt.isDeleted=0
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
						 mt.TargetName as UserName, mt.BettransID, mt.TargetId
			FROM dbo.Msg m with (nolock)
				INNER JOIN  dbo.MsgTarget  mt with (Nolock) ON m.MessageId = mt.MessageId 
			WHERE m.MessageId = 0
		END
	END
	ELSE
	BEGIN
		SELECT TOP 1 m.MessageId, m.Content_en, m.Content_cs, m.Content_ch,
					 m.Content_jp, m.Content_th, m.Content_it, m.Content_ko,
					 m.Content_es, m.Content_vn, m.Content_id, m.Content_el,
					 m.Content_mx, m.Content_zhcn,
					 m.PostTime, m.CreateTime, m.LastUpdateTime,
					 m.MsgType, m.IsSticky, m.IsTest, m.MatchId, m.IsBatch,
					 m.Creator, m.LastUpdator, 
					 m.CreatorName, m.LastUpdateName,
					 mt.TargetName as UserName, mt.BettransID, mt.TargetId

		FROM dbo.Msg m with (nolock)
			INNER JOIN dbo.MsgTarget mt with (nolock) ON m.MessageId = mt.MessageId 
		WHERE m.posttime > dateadd(d,-1,getdate()) and m.MsgType=1 and mt.TargetId=@UserID
		AND m.MessageId > @LatestMsgID
		AND m.IsSticky = 0
		AND m.isDeleted=0 AND mt.isDeleted=0
		ORDER BY m.PostTime DESC
	END
END
GO