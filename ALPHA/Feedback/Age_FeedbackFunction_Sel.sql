/*<info serverAlias="DBBOT-bodb_ChatBot" executers="bodbDownlineNet,wsv_alp,bodbDownlineNetView,wsv_alpv"  viewers="" isFunction="0" isNested="0"></info>*/
 ALTER PROCEDURE [dbo].[Age_FeedbackFunction_Sel]
	-- Add the parameters for the stored procedure here
	  @FuncID	INT
AS
/*
	Task : Alpha - Get user's feedback on specific function
	DB: DBBOT/bodb_ChatBot
	Original:
	
	Revisions:
		- 20230328@Tacy: Create SP [Redmine: #185515]

	Param's Explanation: 
*/
BEGIN
	SET NOCOUNT ON;

	SELECT ff.FuncID
		, FuncNameEN 
		, FuncNameCN3
		, FuncNameCS
		, FuncNameCH
		, FuncNameTH
		, FuncNameJP
		, FuncNameKO
	FROM Age_FeedbackFunc ff WITH (NOLOCK)
	WHERE ff.FuncID=@FuncID

	SELECT fa.AreaID
		, AreaNameEN
		, AreaNameCN3
		, AreaNameCS
		, AreaNameCH
		, AreaNameTH
		, AreaNameJP
		, AreaNameKO
	FROM Age_FeedbackArea fa WITH (NOLOCK)
	WHERE fa.FuncID=@FuncID
END
GO
