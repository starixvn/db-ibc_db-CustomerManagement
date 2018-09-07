/*<info serverAlias="DBMSG-bodb_Message" executers="bodbDownlineNet" viewers="vnteam" isFunction="0"></info>*/

USE [bodb_Message]
GO

ALTER PROCEDURE [dbo].[Age_GetNewMessage]
	@LastQueryTime DATETIME,
	@Type TINYINT,
	@IsTest BIT = 0
AS
/*
	Creator:	20180907@Eloide
	Task:		Get New Message to send via chat bot- [Redmine: #95940]
	Database:	DBMSG/bodb_Message
	
	Revisions:
		
	Parameter's Explaination:
		@Type:	0: Normal Msg
				1: Personal Msg
				2: Special Msg
				3: System Announcement

	Developer's Notes:
	Example: EXEC Age_GetNewMessage @LastQueryTime = '2017-08-15 01:25:54.343', @Type = 0, @IsTest = 0
*/
BEGIN
	SET NOCOUNT ON

	CREATE TABLE #Msg (MessageId INT,
						Content_en NVARCHAR(4000) NULL,
						Content_ch NVARCHAR(4000) NULL,
						Content_cs NVARCHAR(4000) NULL,
						Content_jp NVARCHAR(4000) NULL,
						Content_it NVARCHAR(4000) NULL,
						Content_th NVARCHAR(4000) NULL,
						Content_ko NVARCHAR(4000) NULL,
						Content_es NVARCHAR(4000) NULL,
						Content_vn NVARCHAR(4000) NULL,
						Content_id NVARCHAR(4000) NULL,
						Content_el NVARCHAR(4000) NULL,
						Content_mx NVARCHAR(4000) NULL)

	IF @Type = 0 --Normal Msg
	BEGIN
		INSERT INTO #Msg (MessageId,Content_en,Content_ch,Content_cs,Content_jp,Content_it,Content_th,Content_ko,Content_es,Content_vn,Content_id,Content_el,Content_mx)
		SELECT MessageId,Content_en,Content_ch,Content_cs,Content_jp,Content_it,Content_th,Content_ko,Content_es,Content_vn,Content_id,Content_el,Content_mx
		FROM dbo.Msg WITH (NOLOCK) 
		WHERE PostTime > @LastQueryTime
			AND MsgType = 3 AND IsSticky = 0
			AND isDeleted=0 
			AND IsTest <=@IsTest
	END
	ELSE IF @Type = 1 --Personal Msg
	BEGIN
		INSERT INTO #Msg (MessageId,Content_en,Content_ch,Content_cs,Content_jp,Content_it,Content_th,Content_ko,Content_es,Content_vn,Content_id,Content_el,Content_mx)
		SELECT MessageId,Content_en,Content_ch,Content_cs,Content_jp,Content_it,Content_th,Content_ko,Content_es,Content_vn,Content_id,Content_el,Content_mx
		FROM dbo.Msg WITH (NOLOCK) 
		WHERE PostTime > @LastQueryTime
			AND MsgType = 1
			AND isDeleted=0 
			AND IsTest <=@IsTest
	END
	ELSE IF @Type = 2 --Special Msg
	BEGIN
		INSERT INTO #Msg (MessageId,Content_en,Content_ch,Content_cs,Content_jp,Content_it,Content_th,Content_ko,Content_es,Content_vn,Content_id,Content_el,Content_mx)
		SELECT MessageId,Content_en,Content_ch,Content_cs,Content_jp,Content_it,Content_th,Content_ko,Content_es,Content_vn,Content_id,Content_el,Content_mx
		FROM dbo.Msg WITH (NOLOCK) 
		WHERE PostTime > @LastQueryTime
			AND IsSticky = 1
			AND isDeleted=0 
			AND IsTest <=@IsTest
	END

	SELECT m.MessageId,Content_en,Content_ch,Content_cs,Content_jp,Content_it,Content_th,Content_ko,Content_es,Content_vn,Content_id,Content_el,Content_mx, mt.TargetId
	FROM #Msg m
		INNER JOIN dbo.MsgTarget mt WITH (NOLOCK) ON mt.MessageId = m.MessageId
	WHERE mt.isDeleted = 0
		AND mt.TargetId IN (3000,3100,3200,3300,300000,310000,320000,330000)
END
