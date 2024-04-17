/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap,bodbDownlineNet,wsv_alp,bodbDownlineNetView,wsv_alpv,bodbExtAccNet,wsv_xnap" viewers="" isFunction="0"></info>*/
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
		DB:  DBCUST/CUSTDB
		
		Revisions:
			- 20120803@Johnson: revise sp
			- 20130121@Dan: Move sp from DB053/bodb02 to DBAGE/bodb_AGE
			- 20130507@Jamie: Enhance Perf at Member Level 
			- 20181123@Helen: DB053.bodb_AGE/BODB02 & DB052.bodb_Summary Migration [Redmine: 104770]
			
		Parameter's Explanation:
			- @custid: id of upline 
			- @prefix: prefix's name of new member
			- @roleid: roleid of upline
			- @username: username suggest
				Exec [Age_CustomerSelSuggestUsername_xpre] 'HI',641918,4,@seqname
	*/ 
BEGIN	
	SET NOCOUNT ON
	
	IF @roleid = 4
	BEGIN
		SELECT top 1 @seqname = SeqName
		FROM age_custSeq WITH(NOLOCK)
		WHERE type = 2
		AND @prefix + SeqName NOT IN (
			SELECT username
			FROM dbo.custInfo WITH(NOLOCK)
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
			FROM dbo.custInfo WITH(NOLOCK)
			WHERE mrecommend = @custid AND roleid = 2
			)
		ORDER BY SeqName ASC
	END
	ELSE IF @roleid =2 
	BEGIN
		DECLARE @rowcnt INT 
		
		SELECT	@rowcnt = COUNT(1)
		FROM	dbo.custInfo  WITH(NOLOCK)
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
				LEFT JOIN dbo.custInfo c WITH(NOLOCK) on s.username = c.username and c.recommend = @custid AND c.roleid = 1
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
				FROM dbo.custInfo WITH(NOLOCK)
				WHERE recommend = @custid AND roleid = 1
				)
			ORDER BY SeqName ASC
		END
		
	END
END
GO
