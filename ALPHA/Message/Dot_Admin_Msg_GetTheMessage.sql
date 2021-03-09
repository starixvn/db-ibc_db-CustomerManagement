/*<info serverAlias="DBMSG-bodb_Message" executers="Dot_Admin" viewers="vnteam" isFunction="0" isNested="0"></info>*/
USE [bodb_Message]
GO
	
CREATE PROCEDURE [dbo].[Dot_Admin_Msg_GetTheMessage]
@MessageID int = 0
AS

/*
	2017/04/17@Mike(DB07):initial version copy from Dot_Msg_GetTheMessage
	2017/04/24@Mike(DB07):Add TopLevel
	2018/08/10@Mike(DB07):add select content_zhcn
	2019/12/20@JackChang(DB05):add select MsgContentsType
	2020/04/15@Jack Chang(DB05):Add select Remark
	- 20210309@Max: [Alpha] Duplicated message shown in Personal message [Redmine: #149622]
*/

BEGIN
	SELECT DISTINCT m.MessageId, m.Content_en, m.Content_cs, m.Content_ch,
		   m.Content_jp, m.Content_th, m.Content_it, m.Content_ko,
		   m.Content_es, m.Content_vn, m.Content_id, m.Content_el,
		   m.Content_mx, m.Content_zhcn,
		   m.PostTime, m.CreateTime, m.LastUpdateTime,
		   m.MsgType, m.IsSticky, m.IsTest, m.MatchId, m.IsBatch,
		   m.Creator, m.LastUpdator, 
		   m.CreatorName, m.LastUpdateName,
		   mt.TargetName as UserName, mt.BettransID, mt.TargetId, 
		   m.TopLevel, m.MsgContentsType, m.Remark
	FROM dbo.Msg m with (nolock)
	INNER JOIN dbo.MsgTarget mt with (nolock) ON m.MessageId = mt.MessageId
	WHERE m.MessageId = @MessageID
	AND  m.isDeleted=0 AND mt.isDeleted=0
END
GO
