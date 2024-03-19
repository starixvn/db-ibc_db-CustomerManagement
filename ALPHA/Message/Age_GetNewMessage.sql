/*<info serverAlias="DBMSG-bodb_Message" executers="bodbDownlineNet,wsv_alp" viewers="vnteam" isFunction="0"></info>*/

USE [bodb_Message]
GO

ALTER PROCEDURE [dbo].[Age_GetNewMessage]
	@FromTime DATETIME,
	@ToTime DATETIME,
	@Type TINYINT,
	@IsTest BIT = 0
AS
/*
	Creator:	20180907@Eloide
	Task:		Get New Message to send via chat bot- [Redmine: #95940]
	Database:	DBMSG/bodb_Message
	
	Revisions:
		- 20180907@Elodie: Get New Message to send via chat bot- [Redmine: #95940]
		- 20181002@Elodie: Prevent get real messages in test environments- [Redmine: #95940]

	Parameter's Explaination:
		@Type:	0: Normal Msg
				1: Personal Msg
				2: Special Msg
				3: System Announcement

	Developer's Notes:
	Example: EXEC Age_GetNewMessage @FromTime = '2017-08-15 01:25:54.343', @ToTime = '2018-09-07 01:39:26.980', @Type = 0, @IsTest = 0
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @i BIGINT = 1000000, @RowCount INT

	CREATE TABLE #Msg (MessageId INT, MsgType TINYINT,
						Content_en NVARCHAR(4000) NULL,
						Content_ch NVARCHAR(4000) NULL,
						Content_cs NVARCHAR(4000) NULL,
						Content_jp NVARCHAR(4000) NULL,
						Content_th NVARCHAR(4000) NULL,
						Content_ko NVARCHAR(4000) NULL,
						Content_vn NVARCHAR(4000) NULL)

	IF @Type = 0 --Normal Msg
	BEGIN
		INSERT INTO #Msg (MessageId,MsgType,Content_en,Content_ch,Content_cs,Content_jp,Content_th,Content_ko,Content_vn)
		SELECT MessageId,MsgType,Content_en,Content_ch,Content_cs,Content_jp,Content_th,Content_ko,Content_vn
		FROM dbo.Msg WITH (NOLOCK) 
		WHERE PostTime BETWEEN @FromTime AND @ToTime
			AND MsgType = 3 AND IsSticky = 0
			AND isDeleted=0 
			AND IsTest =@IsTest

		SELECT @RowCount = @@ROWCOUNT
	END
	ELSE IF @Type = 1 --Personal Msg
	BEGIN
		INSERT INTO #Msg (MessageId,MsgType,Content_en,Content_ch,Content_cs,Content_jp,Content_th,Content_ko,Content_vn)
		SELECT MessageId,MsgType,Content_en,Content_ch,Content_cs,Content_jp,Content_th,Content_ko,Content_vn
		FROM dbo.Msg WITH (NOLOCK) 
		WHERE PostTime BETWEEN @FromTime AND @ToTime
			AND MsgType = 1
			AND isDeleted=0 
			AND IsTest =@IsTest

		SELECT @RowCount = @@ROWCOUNT
	END
	ELSE IF @Type = 2 --Special Msg
	BEGIN
		INSERT INTO #Msg (MessageId,MsgType,Content_en,Content_ch,Content_cs,Content_jp,Content_th,Content_ko,Content_vn)
		SELECT MessageId,MsgType,Content_en,Content_ch,Content_cs,Content_jp,Content_th,Content_ko,Content_vn
		FROM dbo.Msg WITH (NOLOCK) 
		WHERE PostTime BETWEEN @FromTime AND @ToTime
			--when a personal message is marked as Sticky Message. the message will be sent via letstalk under 2 type: Special Announcement and Personal Message.
			--it's not good for the UX. The message should be sent only once as a personal message.
			AND MsgType = 3 AND IsSticky = 1 
			AND isDeleted=0 
			AND IsTest =@IsTest

		SELECT @RowCount = @@ROWCOUNT
	END

	IF @RowCount = 0 RETURN

	SELECT m.MessageId,m.MsgType,Content_en,Content_ch,Content_cs,Content_jp,Content_th,Content_ko,Content_vn,mt.TargetId, mt.BetTransId
	FROM #Msg m
		CROSS APPLY (SELECT TOP (@i) * FROM dbo.MsgTarget WITH (NOLOCK) WHERE MessageId = m.MessageId AND isDeleted = 0) mt
	WHERE (TargetId IN (3000,3100,3200,3300,300000,310000,320000,330000,
						3110,3210,3310,3100100,3200100,3300100 --for i7 site
						) OR MsgType = 1)
	OPTION (OPTIMIZE FOR (@i = 1))
END
