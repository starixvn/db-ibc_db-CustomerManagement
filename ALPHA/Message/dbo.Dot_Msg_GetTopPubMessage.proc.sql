USE [bodb_Message]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Dot_Msg_GetTopPubMessage]
@messageType int,
@site1 nvarchar(10),
@site2 nvarchar(10) = '',
@site3 nvarchar(10) = '',
@LatestMsgID int = 0,  -- Check new msg count that newer than this messageid
@isTest bit
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
	SET NOCOUNT ON;
	-- Select Public Message
	--IF @LatestMsgID=0 SET @LatestMsgID=52000
	IF @LatestMsgID=0 SET @LatestMsgID=1

	IF @isTest = 0
	BEGIN
		-- Select Public Message(not include test message)
		SELECT TOP 1  m.MessageId, m.Content_en, m.Content_cs, m.Content_ch,
					  m.Content_jp, m.Content_th, m.Content_it, m.Content_ko,
					  m.Content_es, m.PostTime, m.CreateTime, m.LastUpdateTime, m.MsgType, m.IsSticky,
					  m.MsgType, m.IsSticky, m.IsTest, m.MatchId,
					  m.Creator, m.LastUpdator, mt.TargetId,
					  m.CreatorName, m.LastUpdateName, mt.TargetName as UserName
		FROM dbo.Msg m with (nolock)
		INNER JOIN dbo.MsgTarget mt with (nolock) ON m.MessageId = mt.MessageId
		WHERE m.MsgType = @messageType
			AND mt.TargetID IN (@site1,@site2,@site3)
			AND m.MessageId > @LatestMsgID
			AND m.IsTest = 0
		ORDER BY m.PostTime Desc
	END
	ELSE
	BEGIN
		-- Select Public Message(include test message)
		SELECT TOP 1  m.MessageId, m.Content_en, m.Content_cs, m.Content_ch,
					  m.Content_jp, m.Content_th, m.Content_it, m.Content_ko,
					  m.Content_es, m.PostTime, m.CreateTime, m.LastUpdateTime, m.MsgType, m.IsSticky,
					  m.MsgType, m.IsSticky, m.IsTest, m.MatchId,
					  m.Creator, m.LastUpdator, mt.TargetId,
					  m.CreatorName, m.LastUpdateName, mt.TargetName as UserName
		FROM dbo.Msg m with (nolock)
		INNER JOIN dbo.MsgTarget mt with (nolock) ON m.MessageId = mt.MessageId
		WHERE m.MsgType = @messageType
			AND mt.TargetID IN (@site1,@site2,@site3)
			AND m.MessageId > @LatestMsgID
		ORDER BY m.PostTime Desc
	END
END

GO
GRANT EXECUTE ON [dbo].[Dot_Msg_GetTopPubMessage] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Dot_Msg_GetTopPubMessage] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Dot_Msg_GetTopPubMessage] TO vnteam