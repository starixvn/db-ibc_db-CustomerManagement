/*<info serverAlias="DBMSG-bodb_Message" executers="bodbDownlineNet,bodbDownlineNetView" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Age_Msg_GetPublicMessage]
	@targetid int = 0,
	@targetid2 varchar(100) = '0',
	@special int = 2,
	@record int = 1,
	@sdate datetime = NULL,
	@edate datetime = NULL,
	@IsTest bit = 0,
	@MatchId int = 0
AS
/*
    Created: 20221121@Tacy
    Task: Alpha - Seperate SP get annoucement & void log spam
    DB: DBMSG-bodb_Message
    Original: Dot_Msg_GetPublicMessage

    Revisions:
			- 20221121@Tacy: Create SP

    Param's Explanation:
 */
BEGIN
	SET NOCOUNT ON
	
	DECLARE @MsgMessageID TABLE
		( val int PRIMARY KEY	)

    IF @targetid=0 AND @record=50 AND @targetid2='4000000,4100000,4100200' AND @special=0 AND @sdate IS NOT NULL AND @edate IS NOT NULL AND @IsTest=0
	BEGIN

		SELECT  m.MessageId, m.Content_en, m.Content_cs, m.Content_ch,
			m.Content_jp, m.Content_th, m.Content_it, m.Content_ko,
			m.Content_es, m.Content_vn, m.Content_id, m.Content_el,
			m.Content_mx, m.Content_zhcn,
			m.PostTime, m.CreateTime, m.LastUpdateTime,
			m.MsgType, m.IsSticky, m.IsTest, m.MatchId,
			m.Creator, m.LastUpdator, m.CreatorName, m.LastUpdateName, m.IsBatch, 
			'' as BettransID, 0 AS TargetId, '' as UserName,
			m.TopLevel
		INTO #MsgA
		FROM dbo.Msg m with (nolock )
		WHERE m.MsgType = 3
			AND m.TopLevel<>21
			AND m.isDeleted=0 
			AND m.IsSticky =0
			AND m.IsTest = 0
			AND m.MessageId >=497229 
		Union all 
		SELECT  m.MessageId, m.Content_en, m.Content_cs, m.Content_ch,
						m.Content_jp, m.Content_th, m.Content_it, m.Content_ko,
						m.Content_es, m.Content_vn, m.Content_id, m.Content_el,
						m.Content_mx, m.Content_zhcn,
						m.PostTime, m.CreateTime, m.LastUpdateTime,
						m.MsgType, m.IsSticky, m.IsTest, m.MatchId,
						m.Creator, m.LastUpdator, m.CreatorName, m.LastUpdateName, m.IsBatch, 
						'' as BettransID, 0 AS TargetId, '' as UserName,
						m.TopLevel
		FROM dbo.Msg m with (nolock )
		WHERE m.MsgType = 3
			AND m.TopLevel=21
			AND m.isDeleted=0 
			AND m.IsSticky =0
			AND m.PostTime BETWEEN @sdate AND @edate
			AND m.IsTest = 0
			AND m.MessageId >=497229 --343146

		SELECT top (@record) a.* 
		From #MsgA a inner join ( 			SELECT Distinct Messageid  FROM MsgTarget WITH(nolock) 
											WHERE TargetID IN ('4000000','4100000','4100200','4000','4100','4120')
												and isDeleted = 0 )  b
			 on a.messageid = b.messageid
		order by a.TopLevel, a.MessageId DESC

		DROP TABLE #MsgA	
		
	END
	ELSE
	BEGIN

		DECLARE @SiteIdList TABLE
		(
		  val CHAR(7) PRIMARY KEY
		)

        SELECT  m.MessageId, m.Content_en, m.Content_cs, m.Content_ch,
				m.Content_jp, m.Content_th, m.Content_it, m.Content_ko,
				m.Content_es, m.Content_vn, m.Content_id, m.Content_el,
				m.Content_mx, m.Content_zhcn,
				m.PostTime, m.CreateTime, m.LastUpdateTime,
				m.MsgType, m.IsSticky, m.IsTest, m.MatchId,
				m.Creator, m.LastUpdator, m.CreatorName, m.LastUpdateName, m.IsBatch, 
				'' as BettransID, 0 AS TargetId, '' as UserName,
				m.TopLevel
		INTO #Msg
			FROM dbo.Msg m with (nolock )
			WHERE m.MsgType = 3
			    AND m.TopLevel<>21
				AND m.isDeleted=0 
				AND CASE
					  WHEN ((@special IN (0,1) AND m.IsSticky = @special)) THEN 1
					  WHEN (@special = 2) THEN 1
					ELSE 0 END = 1
				AND CASE
					  WHEN (@IsTest = 1) THEN 1
					  WHEN (m.IsTest = @IsTest) THEN 1
					ELSE 0 END = 1
				AND CASE
					  WHEN (@MatchID = 0) THEN 1
					  WHEN (m.MatchID = @MatchID) THEN 1
					ELSE 0 END = 1
			Union all 
			SELECT  m.MessageId, m.Content_en, m.Content_cs, m.Content_ch,
							m.Content_jp, m.Content_th, m.Content_it, m.Content_ko,
							m.Content_es, m.Content_vn, m.Content_id, m.Content_el,
							m.Content_mx, m.Content_zhcn,
							m.PostTime, m.CreateTime, m.LastUpdateTime,
							m.MsgType, m.IsSticky, m.IsTest, m.MatchId,
							m.Creator, m.LastUpdator, m.CreatorName, m.LastUpdateName, m.IsBatch, 
							'' as BettransID, 0 AS TargetId, '' as UserName,
							m.TopLevel
			FROM dbo.Msg m with (nolock )
			WHERE m.MsgType = 3
			    AND m.TopLevel=21
				AND m.isDeleted=0 
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
		
			IF @targetid2 <> '0'
			BEGIN
				INSERT @SiteIdList(val)	SELECT dbo.FixSiteID(val) FROM dbo.strSplit(@targetid2,',')
				INSERT INTO @SiteIdList 
				SELECT SUBSTRING( val , 1,2  ) + SUBSTRING( val , 5,2  )  
				FROM @SiteIdList
				WHERE LEN(val) > 4 AND SUBSTRING( val , 3,2  ) = '00' AND SUBSTRING( val , 7,1  )  = '0'
				
				IF @record > 0
				BEGIN
					Select top (@record) a.* 
					From #MSG a inner join ( 	SELECT Distinct Messageid  FROM MsgTarget WITH(nolock) 
												WHERE TargetID IN (SELECT val FROM @SiteIdList)
													and isDeleted = 0 ) b
								on a.messageid = b.messageid
					ORDER BY a.TopLevel, a.MessageId DESC	
				END
				ELSE IF @record = 0
				BEGIN
					Select  a.* 
					From #MSG a inner join ( 	SELECT Distinct Messageid  FROM MsgTarget WITH(nolock) 
												WHERE TargetID IN (SELECT val FROM @SiteIdList)
													and isDeleted = 0 ) b
								on a.messageid = b.messageid
					ORDER BY a.TopLevel, a.MessageId DESC	
				END
			END
			ELSE
			BEGIN
				IF @record > 0
				BEGIN
					Select top (@record) a.* 
					From #MSG a inner join ( 	SELECT Distinct Messageid  FROM MsgTarget WITH(nolock) 
												WHERE isDeleted = 0 ) b
								on a.messageid = b.messageid
					ORDER BY a.TopLevel, a.MessageId DESC	
				END
				ELSE IF @record = 0
				BEGIN
					Select a.* 
					From #MSG a inner join ( 	SELECT Distinct Messageid  FROM MsgTarget WITH(nolock) 
												WHERE isDeleted = 0 ) b
								on a.messageid = b.messageid
					ORDER BY a.TopLevel, a.MessageId DESC	
				END
			END
	END

END
 