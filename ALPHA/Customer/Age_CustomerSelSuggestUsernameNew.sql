/*<info serverAlias="DBGLOB-GlobCustDB" executers="wsv_nap,wsv_alp,wsv_alpv,wsv_xnap,asv_CashService" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CustomerSelSuggestUsernameNew] 
	@prefix		VARCHAR(50),	
	@roleid		INT,
	@seqname	VARCHAR(10) = ''  OUTPUT,
	@ErrCode 	INT = 0			  OUTPUT,
	@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS
	/*
		Created: 20230414@Johnson		
		Task: Suggest available suffix for new member
		Clone SP: Age_CustomerSelSuggestUsername
		DB:  DBCUST/CUSTDB
		
		Revisions:
			- 20230414@Johnson: initial sp [redmine:#183697] 
			- 20230420@Johnson: check username2 [redmine:#187266]
			- 20230808@Helios: Add Errorlog, ErrMsg [Redmine: #190167]
			- 20240704@Helen: Scale out dbcust - [Redmine:206823]

		Parameter's Explanation:			
			- @prefix: prefix's name of new member
			- @roleid: roleid of upline
			- @username: username suggest
				Exec [Age_CustomerSelSuggestUsernameNew] 'agent01',1176086,2,@seqname,@ErrMsg
	*/ 
BEGIN	
	SET NOCOUNT ON
	
	SELECT top 1 @seqname = SeqName
	FROM age_custSeq WITH(NOLOCK)
	WHERE type = CASE WHEN @roleid IN (3,4) THEN 2 
					WHEN @roleid = 2 THEN 1 ELSE 0 END
	AND NOT exists (
		SELECT top 1 1
		FROM dbo.CustInfoMini WITH(NOLOCK)			
		WHERE @prefix + SeqName  = username OR @prefix + SeqName  = username2
		)
	AND NOT exists (
		SELECT top 1 1
		FROM dbo.CustSubMini WITH(NOLOCK)			
		WHERE @prefix + SeqName  = username OR @prefix + SeqName = username2
		)
	ORDER BY SeqName ASC

	IF ISNULL (@seqname , '') = '' 
	BEGIN
		IF @roleid = 2	-- Agent Create Member
		BEGIN
			SELECT @ErrMsg = 'Sorry, you cannot create more accounts because the total downlines have reached the limit (46656). Please contact your upline for further assistance.'
		     , @ErrCode = 40040
		END
		ELSE			
		BEGIN
			SELECT @ErrMsg = 'Sorry, you cannot create more accounts because the total downlines have reached the limit (1296). Please contact your upline for further assistance.'
		     , @ErrCode = 40039
		END
	END
		
END
GO
