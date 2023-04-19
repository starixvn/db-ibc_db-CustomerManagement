/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView,bodbExtAccNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CustomerSelSuggestUsernameNew] 
	@prefix		VARCHAR(50),	
	@roleid		INT,
	@seqname	VARCHAR(10) = '' OUTPUT	
AS
	/*
		Created: 20230414@Johnson		
		Task: Suggest available suffix for new member
		Clone SP: Age_CustomerSelSuggestUsername
		DB:  DBCUST/CUSTDB
		
		Revisions:
			- 20230414@Johnson: initial sp [redmine:#183697] 
		Parameter's Explanation:			
			- @prefix: prefix's name of new member
			- @roleid: roleid of upline
			- @username: username suggest
				Exec [Age_CustomerSelSuggestUsernameNew] 'agent01',1176086,2,@seqname
	*/ 
BEGIN	
	SET NOCOUNT ON
	
	SELECT top 1 @seqname = SeqName
	FROM age_custSeq WITH(NOLOCK)
	WHERE type = CASE WHEN @roleid IN (3,4) THEN 2 
					WHEN @roleid = 2 THEN 1 ELSE 0 END
	AND NOT exists (
		SELECT top 1 1
		FROM dbo.customer WITH(NOLOCK)			
		WHERE @prefix + SeqName  = username
		)
	ORDER BY SeqName ASC
END
GO
