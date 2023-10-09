/*<info serverAlias="DBMSG-bodb_Message" executers="bodbDownlineNet,bodbDownlineNetView" viewers="vnteam" isFunction="0" isNested="0"></info>*/
USE [bodb_Message]
GO

ALTER PROCEDURE [dbo].[Age_MsgCustReadStatus_SelUnread] 
	 @CustId INT
	,@SubAccId INT = 0
	,@IsTest BIT = 0
	,@targetid2 VARCHAR(100) = '0'
	,@Site varchar(50)
AS
/*
	Created: 20180621@Razor
	Task : Announcement Renovation
	DB: DBMSG.bodb_Message
	
	Revisions:
		- 20180621@Razor: Renovation Announcement [Redmind: #94705]
		- 20180817@Viet: revise SP
		- 20210309@Max: [Alpha] Duplicated message shown in Personal message [Redmine: #149622]
		- 20230517@Tacy: Alpha - Special Announcement - Exclude a message sending to 755555 & 76666B [RedmineID: #188246]
		- 20230929@Tacy: Alpha - Special Announcement - ONLY Upload for 755555 and 766666b [RedmineID: #194638]

	Param's Explanation: 
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @mInfo as TABLE (MsgType tinyint, targetID int)	

	IF @targetid2 <> '0'
	BEGIN
		INSERT INTO @mInfo (MsgType, targetID)
		SELECT 3, val
		FROM dbo.strSplit(@targetid2, ',')

		INSERT INTO @mInfo (MsgType, targetID)
		SELECT MsgType, CONVERT(INT, LEFT(RTRIM(targetID),2)+'00'+RIGHT(RTRIM(targetID),2)+'0')
		FROM @mInfo
		WHERE targetID BETWEEN 1000 AND 9999 --len(targetID) = 4
	END

	INSERT INTO @mInfo (MsgType, targetID) VALUES (1, @CustId)

	DECLARE @lastSeenNormalMsg DATETIME
			,@lastSeenSpecialMsg DATETIME
			,@lastSeenPersonalMsg DATETIME

	SELECT @lastSeenNormalMsg = LastSeenNormalMsg
		,@lastSeenSpecialMsg = LastSeenSpecialMsg
		,@lastSeenPersonalMsg = LastSeenPersonalMsg
	FROM MsgCustReadStatus WITH(NOLOCK)
	WHERE CustId = @CustId
		AND SubAccID = @SubAccId
	
	DECLARE @minLastSeen DATETIME
	SET @minLastSeen = @lastSeenNormalMsg
	IF @minLastSeen > @LastSeenSpecialMsg SET @minLastSeen = @LastSeenSpecialMsg
	IF @minLastSeen > @lastSeenPersonalMsg SET @minLastSeen = @lastSeenPersonalMsg
	
	;WITH cteMsg
	AS(
	SELECT DISTINCT m.MessageId, m.MsgType, m.PostTime, m.IsSticky, s.targetID
	FROM dbo.Msg m WITH (NOLOCK, INDEX=IX_PostTime)
		INNER JOIN @mInfo s ON s.MsgType = m.MsgType
		INNER JOIN dbo.MsgTarget mt WITH (NOLOCK) ON mt.MessageId =  m.MessageId AND mt.TargetId = s.targetID AND mt.isDeleted = 0
	WHERE  m.PostTime > @minLastSeen 
		AND m.isDeleted = 0 
		AND m.IsTest = @IsTest
		AND CASE WHEN @Site IN ('755555', '76666B') AND m.MessageId<>1799334	 THEN 1
				 WHEN @Site NOT IN ('755555', '76666B') AND m.MessageId<>1799336 THEN 1
			ELSE 0 END = 1
	)
	SELECT SUM(CASE WHEN m.MsgType = 3 AND m.IsSticky = 0 AND m.PostTime > @lastSeenNormalMsg THEN 1 ELSE 0 END) as Normal
		,SUM(CASE WHEN m.IsSticky = 1 AND m.PostTime > @lastSeenSpecialMsg THEN 1 ELSE 0 END) as Special		
		,SUM(CASE WHEN m.MsgType = 1 AND m.PostTime > @lastSeenPersonalMsg THEN 1 ELSE 0 END) as Personal
	FROM cteMsg m
END
GO