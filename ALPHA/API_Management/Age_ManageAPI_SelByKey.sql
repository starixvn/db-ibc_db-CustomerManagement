/*<info serverAlias="DBCUST-CustDB" executers="bodbDownlineNet,wsv_alp" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_ManageAPI_SelByKey]
	-- Add the parameters for the stored procedure here
	  @APIkey	VARCHAR(200)
AS
/*
	Task : Alpha - API Management - Support data through API
	DB: DBCUST/CustDB
	Original: 
	Revisions:
		- 20221026@Tacy: Create SP [Redmine: #171247]

	Param's Explanation: 
*/
BEGIN
	SET NOCOUNT ON;
	
	IF @APIkey IS NULL OR @APIkey=''
		RETURN

	SELECT api.CustID, ci.roleid, APIName, ExpiredDate, 
		APIKey, APISecret, ScopeIDList, Passphrase
	FROM APIInfo api WITH (NOLOCK)
		INNER JOIN custinfo ci WITH (NOLOCK) ON ci.custid=api.CustID
	WHERE APIKey=@APIkey
END
GO
