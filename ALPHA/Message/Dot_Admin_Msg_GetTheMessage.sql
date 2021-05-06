/*<info serverAlias="DBMSG-bodb_Message" executers="Dot_Admin" viewers="vnteam" isFunction="0" isNested="0"></info>*/
USE [bodb_Message]
GO
	
CREATE PROCEDURE [dbo].[Dot_Admin_Msg_GetTheMessage]
@MessageID int = 0
AS

/*
	Created: 
	Task : 
	DB: DBMSG.bodb_Message
	Revisions:
		2017/04/17@Mike(DB07):initial version copy from Dot_Msg_GetTheMessage
		2017/04/24@Mike(DB07):Add TopLevel
		2018/08/10@Mike(DB07):add select content_zhcn
		2019/12/20@JackChang(DB05):add select MsgContentsType
		2020/04/15@Jack Chang(DB05):Add select Remark
		- 20210309@Max: [Alpha] Duplicated message shown in Personal message [Redmine: #149622]
	Param's Explanation:
*/

BEGIN
	DECLARE @Content_en[nvarchar](4000) ,
		@Content_ch [nvarchar](4000) ,
		@Content_cs [nvarchar](4000) ,
		@Content_jp [nvarchar](4000) ,
		@Content_it [nvarchar](4000) ,
		@Content_th [nvarchar](4000) ,
		@Content_ko [nvarchar](4000) ,
		@PostTime [datetime] ,
		@IsSticky [bit] ,
		@Creator [int] ,
		@CreatorName [nvarchar](50) ,
		@CreateTime [datetime] ,
		@MsgType [tinyint] ,
		@LastUpdator [int] ,
		@LastUpdateName[varchar](50) ,
		@LastUpdateTime [datetime] ,
		@Content_es [nvarchar](4000) ,
		@Content_vn [nvarchar](4000) ,
		@Content_id [nvarchar](4000) ,
		@Content_el [nvarchar](4000) ,
		@Content_mx [nvarchar](4000) ,
		@MsgContentsType [tinyint] ,
		@TopLevel [tinyint] ,
		@Content_zhcn [nvarchar](4000) ,
		@Remark [varchar](300) ,
		@IsTest BIT,@MatchId INT, @IsBatch BIT

	CREATE TABLE #MsgTarget_total (TargetId INT, TargetName NVARCHAR(60), BetTransId VARCHAR(MAX))
	CREATE TABLE #MsgTarget_dup (TargetId INT, TargetName NVARCHAR(60))
	
	SELECT @MessageId = MessageId, @Content_en = Content_en , @Content_cs = Content_cs, @Content_ch = Content_ch,
		   @Content_jp = Content_jp, @Content_th = Content_th, @Content_it = Content_it, @Content_ko = Content_ko,
		   @Content_es = Content_es, @Content_vn = Content_vn, @Content_id = Content_id, @Content_el = Content_el,
		   @Content_mx = Content_mx, @Content_zhcn = Content_zhcn,
		   @PostTime = PostTime, @CreateTime = CreateTime, @LastUpdateTime = LastUpdateTime,
		   @MsgType = MsgType, @IsSticky = IsSticky, @IsTest = IsTest, @MatchId = MatchId, @IsBatch = IsBatch,
		   @Creator = Creator , @LastUpdator = LastUpdator, 
		   @CreatorName = CreatorName, @LastUpdateName = LastUpdateName,
		   @TopLevel = TopLevel, @MsgContentsType = MsgContentsType, @Remark = Remark
	FROM dbo.Msg  WITH (NOLOCK)
	WHERE MessageId = @MessageID AND isDeleted = 0
	
	INSERT INTO #MsgTarget_total (TargetId, TargetName, BetTransId)
	SELECT TargetId,TargetName,BetTransId
	FROM dbo.MsgTarget WITH (NOLOCK)
	WHERE MessageId = @MessageID AND isDeleted = 0

	INSERT INTO #MsgTarget_dup (TargetId, TargetName)
	SELECT TargetId, TargetName
	FROM #MsgTarget_total
	GROUP BY TargetId,TargetName
	HAVING COUNT(1) > 1
	
	IF EXISTS (SELECT TOP 1 1 FROM #MsgTarget_dup)
	BEGIN
		SELECT  
			@MessageId AS MessageId, @Content_en AS Content_en, @Content_cs AS Content_cs, @Content_ch AS Content_ch,
			   @Content_jp AS Content_jp, @Content_th AS Content_th, @Content_it AS Content_it, @Content_ko AS Content_ko,
			   @Content_es AS Content_es, @Content_vn AS Content_vn, @Content_id AS Content_id, @Content_el AS Content_el,
			   @Content_mx AS Content_mx, @Content_zhcn AS Content_zhcn,
			   @PostTime AS PostTime, @CreateTime AS CreateTime, @LastUpdateTime AS LastUpdateTime,
			   @MsgType AS MsgType, @IsSticky AS IsSticky, @IsTest AS IsTest, @MatchId AS MatchId, @IsBatch AS IsBatch,
			   @Creator AS Creator, @LastUpdator AS LastUpdator, 
			   @CreatorName AS CreatorName, @LastUpdateName AS LastUpdateName,
			   mt.TargetName as UserName
			   ,mt.BettransID as BettransID
			   , mt.TargetId, 
			   @TopLevel, @MsgContentsType, @Remark
		FROM #MsgTarget_total AS mt
			LEFT JOIN #MsgTarget_dup d ON mt.TargetId = d.TargetId
		WHERE d.TargetId IS NULL	
		
		UNION ALL
		
		SELECT  
			@MessageId AS MessageId, @Content_en AS Content_en, @Content_cs AS Content_cs, @Content_ch AS Content_ch,
			   @Content_jp AS Content_jp, @Content_th AS Content_th, @Content_it AS Content_it, @Content_ko AS Content_ko,
			   @Content_es AS Content_es, @Content_vn AS Content_vn, @Content_id AS Content_id, @Content_el AS Content_el,
			   @Content_mx AS Content_mx, @Content_zhcn AS Content_zhcn,
			   @PostTime AS PostTime, @CreateTime AS CreateTime, @LastUpdateTime AS LastUpdateTime,
			   @MsgType AS MsgType, @IsSticky AS IsSticky, @IsTest AS IsTest, @MatchId AS MatchId, @IsBatch AS IsBatch,
			   @Creator AS Creator, @LastUpdator AS LastUpdator, 
			   @CreatorName AS CreatorName, @LastUpdateName AS LastUpdateName,
			   mt.TargetName as UserName
				,STUFF(tmp.BettransID,1,1,'') as BettransID
			   , mt.TargetId, 
			   @TopLevel, @MsgContentsType, @Remark
		FROM #MsgTarget_dup AS mt
			OUTER APPLY (SELECT  ',' + ISNULL(BetTransId ,'')
						FROM #MsgTarget_total 
						WHERE TargetId = mt.TargetId
						FOR XML PATH('')
						) AS tmp(BettransID)

	END
	ELSE
	BEGIN
		SELECT  
			@MessageId AS MessageId, @Content_en AS Content_en, @Content_cs AS Content_cs, @Content_ch AS Content_ch,
			   @Content_jp AS Content_jp, @Content_th AS Content_th, @Content_it AS Content_it, @Content_ko AS Content_ko,
			   @Content_es AS Content_es, @Content_vn AS Content_vn, @Content_id AS Content_id, @Content_el AS Content_el,
			   @Content_mx AS Content_mx, @Content_zhcn AS Content_zhcn,
			   @PostTime AS PostTime, @CreateTime AS CreateTime, @LastUpdateTime AS LastUpdateTime,
			   @MsgType AS MsgType, @IsSticky AS IsSticky, @IsTest AS IsTest, @MatchId AS MatchId, @IsBatch AS IsBatch,
			   @Creator AS Creator, @LastUpdator AS LastUpdator, 
			   @CreatorName AS CreatorName, @LastUpdateName AS LastUpdateName,
			   mt.TargetName as UserName
			   ,mt.BettransID as BettransID
			   ,mt.TargetId, 
			   @TopLevel AS TopLevel, @MsgContentsType AS MsgContentsType, @Remark AS Remark
		FROM #MsgTarget_total AS mt	
	END

	DROP TABLE #MsgTarget_dup
	DROP TABLE #MsgTarget_total
END
GO
