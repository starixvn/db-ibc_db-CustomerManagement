USE [bodb_AGE]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Age_CustomerSelSuggestUsername_xpre    Script Date: 3/20/2013 1:50:37 PM ******/
ALTER PROCEDURE [dbo].[Age_CustomerSelSuggestUsername] 
	@prefix		VARCHAR(50),
	@custid		INT,
	@roleid		INT,
	@seqname	VARCHAR(10) = '' OUTPUT	
AS
	/*
		Created: Johnson
		Date: 2012-07-25
		Task: Suggest available suffix for new member
		DB:  DBAGE/bodb_AGE
		
		Revisions:
			- 20120803@Johnson: revise sp
			- 20130121@Dan: Move sp from DB053/bodb02 to DBAGE/bodb_AGE
			- 20130507@Jamie: Enhance Perf at Member Level 
		Parameter's Explanation:
			- @custid: id of upline 
			- @prefix: prefix's name of new member
			- @roleid: roleid of upline
			- @username: username suggest
				Exec [Age_CustomerSelSuggestUsername_xpre] 'HI',641918,4,@seqname
	*/ 
SET NOCOUNT ON
	
	IF @roleid = 4
	BEGIN
		SELECT top 1 @seqname = SeqName
		FROM age_custSeq WITH(NOLOCK)
		WHERE type = 2
		AND @prefix + SeqName NOT IN (
			SELECT username
			FROM bodb02.dbo.custInfo WITH(NOLOCK)
			WHERE srecommend = @custid AND roleid = 3
			)
		ORDER BY SeqName ASC
	END
	ELSE IF @roleid = 3 
	BEGIN
		SELECT top 1 @seqname = SeqName
		FROM age_custSeq WITH(NOLOCK)
		WHERE type = 2
		AND @prefix + SeqName NOT IN (
			SELECT username
			FROM bodb02.dbo.custInfo WITH(NOLOCK)
			WHERE mrecommend = @custid AND roleid = 2
			)
		ORDER BY SeqName ASC
	END
	ELSE IF @roleid =2 
	BEGIN
		DECLARE @rowcnt INT 
		
		SELECT	@rowcnt = COUNT(1)
		FROM	bodb02.dbo.custInfo  WITH(NOLOCK)
		WHERE	Recommend = @CustID AND RoleID = 1 
	
		IF @rowcnt > 7000
		BEGIN 
			CREATE TABLE #tmpSeq (
				Username	NVARCHAR(30),
				SeqName		VARCHAR(3)
			)

			INSERT INTO #tmpSeq(
				Username,
				SeqName
			)
			SELECT   @prefix + SeqName 
					,SeqName
			FROM age_custSeq with (nolock)
			WHERE type = 1  

			CREATE CLUSTERED INDEX IX_tmpSeq_Useranme  
			ON #tmpSeq (Username,SeqName)	

			SELECT TOP 1 @seqname = SeqName
			FROM	#tmpSeq S with (nolock)
				LEFT JOIN bodb02.dbo.custInfo c WITH(NOLOCK) on s.username = c.username and c.recommend = @custid AND c.roleid = 1
			WHERE  c.username is null 	
			
			DROP TABLE #tmpSeq
		 
		END
		ELSE 
		BEGIN
			SELECT top 1 @seqname = SeqName
			FROM age_custSeq WITH(NOLOCK)
			WHERE type = 1
			AND @prefix + SeqName NOT IN (
				SELECT username			
				FROM bodb02.dbo.custInfo WITH(NOLOCK)
				WHERE recommend = @custid AND roleid = 1
				)
			ORDER BY SeqName ASC
		END
		
	END

GO
GRANT EXECUTE ON [dbo].[Age_CustomerSelSuggestUsername] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Age_CustomerSelSuggestUsername] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Age_CustomerSelSuggestUsername] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Age_CustomerSelSuggestUsername] TO [bodbExtAccNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Age_CustomerSelSuggestUsername] TO [vnteam] AS [dbo]