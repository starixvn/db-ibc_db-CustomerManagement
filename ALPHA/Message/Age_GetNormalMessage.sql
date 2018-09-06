/*<info serverAlias="DBMSG-bodb_Message" executers="bodbDownlineNet" viewers="vnteam" isFunction="0"></info>*/

USE [bodb_Message];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

ALTER PROCEDURE [dbo].[Age_GetNormalMessage]
	@targetid INT = 0,
	@targetid2 VARCHAR(100) = '0',
	@special INT = 2,
	@record INT = 1,
	@sdate DATETIME = NULL,
	@edate DATETIME = NULL,
	@IsTest BIT = 0,
	@MatchId INT = 0
AS
/*
	Creator:	20180822@Alvin
	Task:		Get Normal Message - [Redmine: #95940]
	Database:	DBMSG.bodb_Message
	
	Revisions:
		
	Parameter's Explaination:
		
	Developer's Notes:
	Example:
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @SiteIdList TABLE
	(
	  val CHAR(7) PRIMARY KEY
	);
	IF @targetid2 <> '0'
		INSERT @SiteIdList(val)	SELECT dbo.FixSiteID(val) FROM dbo.strSplit(@targetid2,',');
	
	SELECT *
	FROM (
		SELECT DISTINCT  m.MessageId, m.Content_en, m.Content_cs, m.Content_ch,
						m.Content_jp, m.Content_th, m.Content_it, m.Content_ko,
						m.Content_es, m.Content_vn, m.Content_id, m.Content_el,
						m.Content_mx,
						m.PostTime, m.CreateTime, m.LastUpdateTime,
						m.MsgType, m.IsSticky, m.IsTest, m.MatchId,
						m.Creator, m.LastUpdator, m.CreatorName, m.LastUpdateName, m.IsBatch, 
						mt.BettransID, 0 AS TargetId, '' AS UserName,
						m.TopLevel,
						DENSE_RANK() OVER(ORDER BY m.TopLevel, m.PostTime DESC) AS rownum
		FROM dbo.Msg m WITH (NOLOCK)
			INNER JOIN MsgTarget mt WITH (NOLOCK) ON m.MessageId = mt.MessageId
		WHERE m.MsgType = 3
			AND m.isDeleted=0 AND mt.isDeleted=0
			AND CASE
					WHEN ((@special IN (0,1) AND m.IsSticky = @special)) THEN 1
					WHEN (@special = 2) THEN 1
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
			AND CASE 
					WHEN (@targetid2 = '0') THEN 1
					WHEN (@targetid2 <> '0' AND dbo.FixSiteID(mt.TargetID) IN (SELECT val FROM @SiteIdList)) THEN 1
				ELSE 0 END = 1
	) new_table
	WHERE CASE
			WHEN (@record <> 0 AND new_table.rownum <= @record) THEN 1
			WHEN (@record = 0) THEN 1
		ELSE 0 END = 1
	ORDER BY PostTime DESC;
END;