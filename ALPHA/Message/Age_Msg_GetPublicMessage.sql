/*<info serverAlias="DBMSG-bodb_Message" executers="bodbDownlineNet,bodbDownlineNetView" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Age_Msg_GetPublicMessage]
	@targetid int = 0,
	@targetid2 varchar(100) = '0',
	@special int = 2,
	@record int = 1,
	@sdate datetime = NULL,
	@edate datetime = NULL,
	@IsTest bit = 0,
	@MatchId int = 0,
	@Site varchar(50)=''
AS
/*
    Created: 20221121@Tacy
    Task: Alpha - Seperate SP get annoucement & void log spam
    DB: DBMSG-bodb_Message
    Original: Dot_Msg_GetPublicMessage

    Revisions:
		- 20221121@Tacy: Create SP
		- 20221123@Tacy: TW enhance performance's sp [Dot_Msg_GetPublicMessage]
		- 20230517@Tacy: Add @Site [RedmineID: #188246]

    Param's Explanation:
 */
BEGIN
	SET NOCOUNT ON
	
	DECLARE @MsgMessageID TABLE
		( val int PRIMARY KEY	)

    IF @targetid=0 AND @record=50 AND @targetid2='4000000,4100000,4100200' AND @special=0 AND @sdate IS NOT NULL AND @edate IS NOT NULL AND @IsTest=0
	BEGIN
		
		create table #MsgA (MessageId int, TopLevel tinyint);

		insert into #MsgA (MessageId, TopLevel)
		SELECT  m.MessageId, 
			m.TopLevel
		FROM dbo.Msg m with (nolock )
		WHERE m.MsgType = 3
			AND m.TopLevel<>21
			AND m.isDeleted=0 
			AND m.IsSticky =0
			AND m.IsTest = 0
			AND m.MessageId >=497229;

		--Union all 
		insert into #MsgA (MessageId, TopLevel)
		SELECT  m.MessageId, 
				m.TopLevel
		FROM dbo.Msg m with (nolock )
		WHERE m.MsgType = 3
			AND m.TopLevel=21
			AND m.isDeleted=0 
			AND m.IsSticky =0
			AND m.PostTime BETWEEN @sdate AND @edate
			AND m.IsTest = 0
			AND m.MessageId >=497229; --343146

		;with TopMsg as
		(
			select distinct top (@record) a.MessageId, a.TopLevel
			from #MsgA as a
			inner join MsgTarget as b with (nolock) on a.MessageId = b.MessageId
			where b.TargetId in ('4000000','4100000','4100200','4000','4100','4120')
			and b.isDeleted = 0
			order by a.TopLevel, a.MessageId desc
		)
		select  m.MessageId, m.Content_en, m.Content_cs, m.Content_ch,
				m.Content_jp, m.Content_th, m.Content_it, m.Content_ko,
				m.Content_es, m.Content_vn, m.Content_id, m.Content_el,
				m.Content_mx, m.Content_zhcn,
				m.PostTime, m.CreateTime, m.LastUpdateTime,
				m.MsgType, m.IsSticky, m.IsTest, m.MatchId,
				m.Creator, m.LastUpdator, m.CreatorName, m.LastUpdateName, m.IsBatch, 
				'' as BettransID, 0 AS TargetId, '' as UserName,
				m.TopLevel
		from Msg m with (nolock) inner join TopMsg 
		on m.MessageId = TopMsg.MessageId;

		DROP TABLE #MsgA	
		
	END
	ELSE
	BEGIN

		DECLARE @SiteIdList TABLE
		(
		  val CHAR(7) PRIMARY KEY
		)

		create table #Msg (MessageId int, TopLevel tinyint);

		insert into #Msg (MessageId, TopLevel)
        SELECT  m.MessageId, 
				m.TopLevel
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
				ELSE 0 END = 1;

			insert into #Msg (MessageId, TopLevel)
			SELECT  m.MessageId, 
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
					;with TopMsg as
					(
						select distinct top (@record) a.MessageId, a.TopLevel
						from #Msg as a
						inner join MsgTarget as b with (nolock) on a.MessageId = b.MessageId
						where b.TargetId in (select val from @SiteIdList)
						and b.isDeleted = 0
						order by a.TopLevel, a.MessageId desc
					)
					select	m.MessageId, m.Content_en, m.Content_cs, m.Content_ch,
							m.Content_jp, m.Content_th, m.Content_it, m.Content_ko,
							m.Content_es, m.Content_vn, m.Content_id, m.Content_el,
							m.Content_mx, m.Content_zhcn,
							m.PostTime, m.CreateTime, m.LastUpdateTime,
							m.MsgType, m.IsSticky, m.IsTest, m.MatchId,
							m.Creator, m.LastUpdator, m.CreatorName, m.LastUpdateName, m.IsBatch, 
							'' as BettransID, 0 AS TargetId, '' as UserName,
							m.TopLevel
					from Msg m with (nolock) inner join TopMsg 
					on m.MessageId = TopMsg.MessageId;
				END
				ELSE IF @record = 0
				BEGIN
					;with TopMsg as
					(
						select distinct a.MessageId, a.TopLevel
						from #Msg as a
						inner join MsgTarget as b with (nolock) on a.MessageId = b.MessageId
						where b.TargetId in (select val from @SiteIdList)
						and b.isDeleted = 0
					)
					select	m.MessageId, m.Content_en, m.Content_cs, m.Content_ch,
							m.Content_jp, m.Content_th, m.Content_it, m.Content_ko,
							m.Content_es, m.Content_vn, m.Content_id, m.Content_el,
							m.Content_mx, m.Content_zhcn,
							m.PostTime, m.CreateTime, m.LastUpdateTime,
							m.MsgType, m.IsSticky, m.IsTest, m.MatchId,
							m.Creator, m.LastUpdator, m.CreatorName, m.LastUpdateName, m.IsBatch, 
							'' as BettransID, 0 AS TargetId, '' as UserName,
							m.TopLevel
					from Msg m with (nolock) inner join TopMsg 
					on m.MessageId = TopMsg.MessageId
					ORDER BY TopMsg.TopLevel, TopMsg.MessageId DESC
				END
			END
			ELSE
			BEGIN

				IF @record > 0
				BEGIN
					;with TopMsg as
					(
						select distinct top (@record) a.MessageId, a.TopLevel
						from #Msg as a
						inner join MsgTarget as b with (nolock) on a.MessageId = b.MessageId
						where b.isDeleted = 0
						order by a.TopLevel, a.MessageId desc
					)
					select	m.MessageId, m.Content_en, m.Content_cs, m.Content_ch,
							m.Content_jp, m.Content_th, m.Content_it, m.Content_ko,
							m.Content_es, m.Content_vn, m.Content_id, m.Content_el,
							m.Content_mx, m.Content_zhcn,
							m.PostTime, m.CreateTime, m.LastUpdateTime,
							m.MsgType, m.IsSticky, m.IsTest, m.MatchId,
							m.Creator, m.LastUpdator, m.CreatorName, m.LastUpdateName, m.IsBatch, 
							'' as BettransID, 0 AS TargetId, '' as UserName,
							m.TopLevel
					from Msg m with (nolock) inner join TopMsg 
					on m.MessageId = TopMsg.MessageId;
				END
				ELSE IF @record = 0
				BEGIN
					;with TopMsg as
					(
						select distinct a.MessageId, a.TopLevel
						from #Msg as a
						inner join MsgTarget as b with (nolock) on a.MessageId = b.MessageId
						where b.isDeleted = 0
					)
					select	m.MessageId, m.Content_en, m.Content_cs, m.Content_ch,
							m.Content_jp, m.Content_th, m.Content_it, m.Content_ko,
							m.Content_es, m.Content_vn, m.Content_id, m.Content_el,
							m.Content_mx, m.Content_zhcn,
							m.PostTime, m.CreateTime, m.LastUpdateTime,
							m.MsgType, m.IsSticky, m.IsTest, m.MatchId,
							m.Creator, m.LastUpdator, m.CreatorName, m.LastUpdateName, m.IsBatch, 
							'' as BettransID, 0 AS TargetId, '' as UserName,
							m.TopLevel
					from Msg m with (nolock) inner join TopMsg 
					on m.MessageId = TopMsg.MessageId
					ORDER BY TopMsg.TopLevel, TopMsg.MessageId DESC
				END
			END
	END
END
GO