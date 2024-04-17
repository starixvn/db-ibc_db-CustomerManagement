/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap,wsv_alp,bodbDownlineNetView,wsv_alpv,bodbExtAccNet,wsv_xnap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CustomerCheckReachDownline] 
	@prefix		VARCHAR(50),
	@custid		INT,
	@roleid		INT,
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		NVARCHAR(250) = '' OUTPUT,
	@Language	VARCHAR(2)		= 'E'

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
			WHERE srecommend = @custid AND roleid =3

		IF ISNULL(@seqname,'')='' AND @downline>=1296
		BEGIN
			SELECT @ErrCode=40039
			SELECT @ErrMsg = CASE @Language WHEN 'E' THEN 'Sorry, you cannot create more accounts because the total downlines have reached the limit (1296 accounts). Please contact your upline for further assistance.'
							 ELSE [dbo].[f_Get_MsgNamebyMsgID](40039, @Language) END		
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
			WHERE mrecommend = @custid AND roleid =2

		IF ISNULL(@seqname,'')='' AND @downline>=1296
		BEGIN
			
			SELECT @ErrCode=40039
			SELECT @ErrMsg = CASE @Language WHEN 'E' THEN 'Sorry, you cannot create more accounts because the total downlines have reached the limit (1296 accounts). Please contact your upline for further assistance.'
							 ELSE [dbo].[f_Get_MsgNamebyMsgID](40039, @Language) END	
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
			WHERE recommend = @custid AND roleid = 1
		
		IF ISNULL(@seqname,'')='' AND @downline>=46656
		BEGIN
			SELECT @ErrCode=40040
			SELECT @ErrMsg = CASE @Language WHEN 'E' THEN 'Sorry, you cannot create more accounts because the total downlines have reached the limit (46656 accounts). Please contact your upline for further assistance.'
							 ELSE [dbo].[f_Get_MsgNamebyMsgID](40040, @Language) END
		END

	END
	
END
GO
