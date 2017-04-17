USE [bodb_Message]
GO
/****** Object:  StoredProcedure [dbo].[Acc_Msg_GetTopPubMessage]    Script Date: 11/30/2016 03:08:05 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Acc_Msg_GetTopPubMessage    Script Date: 1/13/2012 11:46:38 AM ******/

ALTER PROCEDURE [dbo].[Acc_Msg_GetTopPubMessage]
	@messageType int,
	@site1 varchar(10),
	@site2 varchar(10) = '',
	@site3 varchar(10) = '',
	@site4 varchar(10) = '',
	@site5 varchar(10) = '',
	@LatestMsgID int = 0,  -- Check new msg count that newer than this messageid
	@isTest bit
AS

/*
    Created: Jamie
	Date: 20120112
    Task: Get public message
    DB: DB07
    Original:[Dot_Msg_GetTopPubMessage]

    Revisions:
		- 20120112@Lukas: exclude messages with isDeleted = 1
    Param's Explanation:
 */
		
BEGIN
    
	SET NOCOUNT ON;
	DECLARE @site6 CHAR(4)
	DECLARE @site7 CHAR(4)
	DECLARE @site8 CHAR(4)
	SET @site6=''
	SET @site7=''
	SET @site8=''

	-- select min(messageid) from msg (nolock) where posttime > '2013/7/15' --363887
	-- exec Acc_Msg_GetTopPubMessage @messageType=3,@site1='3000',@site2='',@site3='',@site4=default,@site5=default,@LatestMsgID=0,@isTest=0
	-- [Dot_Msg_GetTopPubMessage]/[Acc_Msg_GetTopPubMessage]
	IF @LatestMsgID=0 SET @LatestMsgID=522518 --361330
	
	IF @site1<>'' SET @site1=dbo.FixSiteID(@site1)
	IF @site2<>'' SET @site2=dbo.FixSiteID(@site2)
	IF @site3<>'' SET @site3=dbo.FixSiteID(@site3)
	IF @site4<>'' SET @site4=dbo.FixSiteID(@site4)
	IF @site5<>'' SET @site5=dbo.FixSiteID(@site5)

	IF @site1<>'' SET @site6=dbo.FixSiteID2(@site1)
	IF @site2<>'' SET @site7=dbo.FixSiteID2(@site2)
	IF @site3<>'' SET @site8=dbo.FixSiteID2(@site3)
	
	Declare @site1i int, @site2i int, @site3i int, @site4i int, @site5i int
	Declare @site6i int, @site7i int, @site8i int
	
	SELECT
		@site1i = @site1,
		@site2i = @site2,
		@site3i = @site3,
		@site4i = @site4,
		@site5i = @site5,
		@site6i = @site6,
		@site7i = @site7,
		@site8i = @site8
		

	IF @isTest = 0
	BEGIN
		-- Select Public Message(not include test message)
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
		WHERE m.MsgType = @messageType
			AND mt.TargetID IN (@site1i,@site2i,@site3i,@site4i,@site5i,@site6i,@site7i,@site8i)
			AND m.MessageId >= @LatestMsgID
			AND m.IsTest = 0
			AND m.isDeleted = 0
			AND mt.isDeleted = 0
		ORDER BY m.PostTime Desc
	END
	ELSE
	BEGIN
		-- Select Public Message(include test message)
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
		WHERE m.MsgType = @messageType
			AND mt.TargetID IN (@site1i,@site2i,@site3i,@site4i,@site5i,@site6i,@site7i,@site8i)
			AND m.MessageId >= @LatestMsgID
			AND m.isDeleted = 0
			AND mt.isDeleted = 0
		ORDER BY m.PostTime Desc
	END
END









GO
GRANT EXECUTE ON [dbo].[Acc_Msg_GetTopPubMessage] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Acc_Msg_GetTopPubMessage] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Acc_Msg_GetTopPubMessage] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Msg_GetTopPubMessage] TO [vnteam] AS [dbo]