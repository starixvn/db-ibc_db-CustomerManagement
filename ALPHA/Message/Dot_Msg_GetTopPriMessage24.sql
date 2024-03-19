USE [bodb_Message]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Eddie Chen
-- Create date: <Create Date,,>
-- Description:	To temporary solve ref private message high loading to web server
-- =============================================
ALTER PROCEDURE [dbo].[Dot_Msg_GetTopPriMessage24]
	@UserID int,
	@IsTest bit = 0,
	@LatestMsgID int = 0 -- Check new msg count that newer than this messageid
AS
BEGIN
    /*
    Created: @TWTeam
    Task: 
    DB: DB07
    Original:
    Revisions:
        Don@20090923 : adapt for new design (Drop table BatchMsg)
		20120109@Scott(DB07): add condition for new flag column [isDeleted] to filter deleted data.
    Param's Explanation:
    */
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
					 m.Content_mx,
					 m.PostTime, m.CreateTime, m.LastUpdateTime,
					 m.MsgType, m.IsSticky, m.IsTest, m.MatchId, m.IsBatch,
					 m.Creator, m.LastUpdator, 
					 m.CreatorName, m.LastUpdateName,
					 mt.TargetName as UserName, mt.BettransID, mt.TargetId
			FROM dbo.Msg m with (nolock)
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
						 m.Content_mx,
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
					 m.Content_mx,
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
GRANT EXECUTE ON [dbo].[Dot_Msg_GetTopPriMessage24] TO [bodbDownlineNet,wsv_alp]
GO
GRANT EXECUTE ON [dbo].[Dot_Msg_GetTopPriMessage24] TO [bodbDownlineNetView,wsv_alpv]
GO
GRANT VIEW DEFINITION ON [dbo].[Dot_Msg_GetTopPriMessage24] TO vnteam