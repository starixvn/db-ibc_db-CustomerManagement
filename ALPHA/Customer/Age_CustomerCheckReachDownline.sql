/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView,bodbExtAccNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CustomerCheckReachDownline] 
	@prefix		VARCHAR(50),
	@custid		INT,
	@roleid		INT,
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		VARCHAR(250) = '' OUTPUT,
	@Language	VARCHAR(2) = 'E'

AS
	/*
		Created: Winnie
		Date: 2019-01-21
		Task: Check reach downline
		DB:  DBCUST/CUSTDB
		
		Revisions:
			- 20190121@Winnie: Check reach downline RedmineID:#108146					
		Parameter's Explanation:
			- @custid: id of upline 
			- @prefix: prefix's name of new member
			- @roleid: roleid of upline
			- @username: username suggest
				Exec [Age_CustomerSelSuggestUsername_xpre] 'HI',641918,4,@seqname
	*/ 
BEGIN	
	SET NOCOUNT ON
	DECLARE @seqname	VARCHAR(10) = ''
	DECLARE @downline	INT
	
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
		SELECT @downline=COUNT(1) 
		FROM custInfo WITH(NOLOCK)
			WHERE srecommend = @custid AND roleid IN(2,3,1)

		IF ISNULL(@seqname,'')='' OR @downline=1296
		BEGIN
			SELECT @ErrCode=100
			SELECT @ErrMsg=
					CASE @Language 
						WHEN 'E' THEN 'Sorry, you cannot create more accounts because the total downlines have reached the limit. Please contact your upline for further assistance.'						
					END				
		END
			
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
		SELECT @downline=COUNT(1) 
		FROM custInfo WITH(NOLOCK)
			WHERE srecommend = @custid AND roleid IN(2,1)

		IF ISNULL(@seqname,'')='' OR @downline=1296
		BEGIN
			SELECT @ErrCode=100
			SELECT @ErrMsg=
					CASE @Language 
						WHEN 'E' THEN 'Sorry, you cannot create more accounts because the total downlines have reached the limit. Please contact your upline for further assistance.'						
					END			
		END
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
		END

		SELECT @downline=COUNT(1) 
		FROM custInfo WITH(NOLOCK)
			WHERE srecommend = @custid AND roleid = 1
		
		IF ISNULL(@seqname,'')='' OR @downline=46656
		BEGIN
			SELECT @ErrCode=100
			SELECT @ErrMsg=
					CASE @Language 
						WHEN 'E' THEN 'Sorry, you cannot create more accounts because the total downlines have reached the limit. Please contact your upline for further assistance.'						
					END			
		END

	END
	
END
GO
