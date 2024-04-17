USE [bodb_Message]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Dot_Msg_GetPublicMessage]
	@targetid int = 0,
	@targetid2 varchar(100) = '0',
	@special int = 2,
	@record int = 1,
	@sdate datetime = NULL,
	@edate datetime = NULL,
	@IsTest bit = 0,
	@MatchId int = 0
AS
BEGIN
	
	SET NOCOUNT ON
    /*
    Created: @TWTeam
    Task: 
    DB: DB07
    Original:
    Revisions:
        Scott@20110322 : if len(siteid) is 4 transfer to 7
		20120109@Scott(DB07): add condition for new flag column [isDeleted] to filter deleted data.
		20130702@Scott(DB07): Fix data duplication.
		20161130@Paul: sort by TopLevel column [RedmineID #66535]
		20170920@Joychen: rownum sort by TopLevel, m.PostTime desc 
    Param's Explanation:
    */
    -- vivi add
	Declare @Msg table (
			[MessageId] [int],[Content_en] [nvarchar](4000) ,	[Content_cs] [nvarchar](4000) ,	[Content_ch] [nvarchar](4000) ,
			[Content_jp] [nvarchar](4000) ,[Content_th] [nvarchar](4000) ,[Content_it] [nvarchar](4000) ,[Content_ko] [nvarchar](4000) ,
			[Content_es] [nvarchar](4000) ,[Content_vn] [nvarchar](4000) ,[Content_id] [nvarchar](4000) ,[Content_el] [nvarchar](4000) ,
			[Content_mx] [nvarchar](4000) ,
			[PostTime] [datetime] ,	[CreateTime] [datetime] ,[LastUpdateTime] [datetime] ,
			[MsgType] [tinyint] ,[IsSticky] [bit] ,	[IsTest] [bit] ,[MatchId] [int] ,
			[Creator] [int] ,[LastUpdator] [int],[CreatorName] [nvarchar](50),[LastUpdateName] [varchar](50) ,IsBatch [bit],
			[TopLevel] [tinyint])
	
    IF @targetid=0 AND @record=50 AND @targetid2='4000000,4100000,4100200' AND @special=0 AND @sdate IS NOT NULL AND @edate IS NOT NULL AND @IsTest=0
	BEGIN
		
		insert into @Msg	
        SELECT  m.MessageId, m.Content_en, m.Content_cs, m.Content_ch,
				m.Content_jp, m.Content_th, m.Content_it, m.Content_ko,
				m.Content_es, m.Content_vn, m.Content_id, m.Content_el,
				m.Content_mx,
				m.PostTime, m.CreateTime, m.LastUpdateTime,
				m.MsgType, m.IsSticky, m.IsTest, m.MatchId,
				m.Creator, m.LastUpdator, m.CreatorName, m.LastUpdateName, m.IsBatch, 
				m.TopLevel
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
							m.Content_mx,
							m.PostTime, m.CreateTime, m.LastUpdateTime,
							m.MsgType, m.IsSticky, m.IsTest, m.MatchId,
							m.Creator, m.LastUpdator, m.CreatorName, m.LastUpdateName, m.IsBatch, 
							m.TopLevel
			FROM dbo.Msg m with (nolock )
			WHERE m.MsgType = 3
			    AND m.TopLevel=21
				AND m.isDeleted=0 
				AND m.IsSticky =0
				AND m.PostTime BETWEEN @sdate AND @edate
				AND m.IsTest = 0
				AND m.MessageId >=497229 --343146


		;with cte as (
		   SELECT DISTINCT  m.MessageId, m.Content_en, m.Content_cs, m.Content_ch,
							m.Content_jp, m.Content_th, m.Content_it, m.Content_ko,
							m.Content_es, m.Content_vn, m.Content_id, m.Content_el,
							m.Content_mx,
							m.PostTime, m.CreateTime, m.LastUpdateTime,
							m.MsgType, m.IsSticky, m.IsTest, m.MatchId,
							m.Creator, m.LastUpdator, m.CreatorName, m.LastUpdateName, m.IsBatch, 
							mt.BettransID, 0 AS TargetId, '' as UserName, --mt.TargetId, mt.TargetName as UserName,
							m.TopLevel,
							DENSE_RANK() OVER(ORDER BY m.TopLevel, m.PostTime desc) as rownum
			FROM @Msg m 
			INNER JOIN dbo.MsgTarget mt with (nolock , index =IX_MessageId )  ON m.MessageId = mt.MessageId
			WHERE mt.isDeleted=0
				AND dbo.FixSiteID(mt.TargetID) IN ('4000000','4100000','4100200')
			)		
			Select  *
			from cte m with(nolock)
			WHERE m.rownum <= 50
		    order by TopLevel, posttime desc	
		
		
	END
	ELSE
	BEGIN

		DECLARE @SiteIdList TABLE
		(
		  val CHAR(7) PRIMARY KEY
		)
		IF @targetid2 <> '0'
			INSERT @SiteIdList(val)	SELECT dbo.FixSiteID(val) FROM dbo.strSplit(@targetid2,',')

		insert into @Msg	
        SELECT  m.MessageId, m.Content_en, m.Content_cs, m.Content_ch,
				m.Content_jp, m.Content_th, m.Content_it, m.Content_ko,
				m.Content_es, m.Content_vn, m.Content_id, m.Content_el,
				m.Content_mx,
				m.PostTime, m.CreateTime, m.LastUpdateTime,
				m.MsgType, m.IsSticky, m.IsTest, m.MatchId,
				m.Creator, m.LastUpdator, m.CreatorName, m.LastUpdateName, m.IsBatch, 
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
					ELSE 0 END = 1
			Union all 
			SELECT  m.MessageId, m.Content_en, m.Content_cs, m.Content_ch,
							m.Content_jp, m.Content_th, m.Content_it, m.Content_ko,
							m.Content_es, m.Content_vn, m.Content_id, m.Content_el,
							m.Content_mx,
							m.PostTime, m.CreateTime, m.LastUpdateTime,
							m.MsgType, m.IsSticky, m.IsTest, m.MatchId,
							m.Creator, m.LastUpdator, m.CreatorName, m.LastUpdateName, m.IsBatch, 
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
		
			
		;with cte as (
		   SELECT DISTINCT  m.MessageId, m.Content_en, m.Content_cs, m.Content_ch,
							m.Content_jp, m.Content_th, m.Content_it, m.Content_ko,
							m.Content_es, m.Content_vn, m.Content_id, m.Content_el,
							m.Content_mx,
							m.PostTime, m.CreateTime, m.LastUpdateTime,
							m.MsgType, m.IsSticky, m.IsTest, m.MatchId,
							m.Creator, m.LastUpdator, m.CreatorName, m.LastUpdateName, m.IsBatch, 
							mt.BettransID, 0 AS TargetId, '' as UserName, --mt.TargetId, mt.TargetName as UserName,
							m.TopLevel,
							DENSE_RANK() OVER(ORDER BY m.TopLevel, m.PostTime desc) as rownum
			FROM @Msg m 
			INNER JOIN dbo.MsgTarget mt with (nolock , index =IX_MessageId )  ON m.MessageId = mt.MessageId
			WHERE mt.isDeleted=0
				AND CASE 
					  WHEN (@targetid2 = '0') THEN 1
					  WHEN (@targetid2 <> '0' AND dbo.FixSiteID(mt.TargetID) IN (SELECT val FROM @SiteIdList)) THEN 1
					ELSE 0 END = 1
			)		
			Select  *
			from cte m with(nolock)
			WHERE CASE
				WHEN (@record <> 0 AND m.rownum <= @record) THEN 1
				WHEN (@record = 0) THEN 1
			ELSE 0 END = 1
		    order by TopLevel, posttime desc	
		
	END
END

GO
GRANT EXECUTE ON [dbo].[Dot_Msg_GetPublicMessage] TO [wsv_alp]
GO
GRANT EXECUTE ON [dbo].[Dot_Msg_GetPublicMessage] TO [bodbDownlineNetView,wsv_alpv]
GO
GRANT VIEW DEFINITION ON [dbo].[Dot_Msg_GetPublicMessage] TO vnteam