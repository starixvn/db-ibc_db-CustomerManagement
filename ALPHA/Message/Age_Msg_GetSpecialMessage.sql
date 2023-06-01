/*<info serverAlias="DBMSG-bodb_Message" executers="bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[Age_Msg_GetSpecialMessage]
	@targetid int = 0,
	@targetid2 varchar(100) = '0',
	@special int = 2,
	@record	int = 1,
	@sdate datetime = NULL,
	@edate datetime = NULL,
	@IsTest bit = 0,
	@MatchId int = 0,
	@Site varchar(50)
AS
/*
    Created: Elodie
    Task: 
    DB: DBMSG/bodb_Message
    Original: Dot_Msg_GetSpecialMessage
    Revisions:
		- 20220323@Elodie: Initial SP [RedmineID #170363]
		- 20230517@Tacy: Alpha - Special Announcement - Exclude a message sending to 755555 & 76666B [RedmineID: #188246]
    Param's Explanation:
    
*/
BEGIN
    SET NOCOUNT ON

	DECLARE @SiteIdList TABLE
	(
	  val CHAR(7) PRIMARY KEY
	)
	IF @targetid2 <> '0'
		INSERT @SiteIdList(val)	SELECT dbo.FixSiteID(val) FROM dbo.strSplit(@targetid2,',')

	SELECT *
	FROM (
		SELECT DISTINCT m.MessageId, m.Content_en, m.Content_cs, m.Content_ch,
						m.Content_jp, m.Content_th, m.Content_it, m.Content_ko,
						m.Content_es, m.Content_vn, m.Content_id, m.Content_el,
						m.Content_mx, m.Content_zhcn,
						m.PostTime, m.CreateTime, m.LastUpdateTime,
						m.MsgType, m.IsSticky, m.IsTest, m.MatchId, m.IsBatch,
						m.Creator, m.LastUpdator, 
						m.CreatorName, m.LastUpdateName,
						mt.BettransID, 
						m.TopLevel,
					    DENSE_RANK() OVER(ORDER BY m.PostTime desc) as rownum
		FROM dbo.Msg m with (nolock)
		    INNER JOIN MsgTarget mt with (nolock) ON m.MessageId = mt.MessageId
		WHERE m.IsSticky = 1
			AND m.isDeleted=0 AND mt.isDeleted=0
			AND ((m.MsgType = 1 AND mt.TargetId = @targetid) OR 
                 (m.MsgType = 3 AND dbo.FixSiteID(mt.TargetId) IN (SELECT val FROM @SiteIdList)))
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
	AND CASE WHEN @Site IN ('755555', '76666B') AND new_table.MessageId<>1732314 THEN 1 
			 WHEN @Site NOT IN ('755555', '76666B') THEN 1
		ELSE 0 END = 1
	ORDER BY TopLevel, PostTime DESC
END

