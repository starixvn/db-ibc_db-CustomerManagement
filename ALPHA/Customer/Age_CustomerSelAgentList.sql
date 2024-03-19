ALTER PROCEDURE [dbo].[Age_CustomerSelAgentList]
	@MRecommend INT
AS
/*
	Created: 
	Date: 
	Task: 
	DB: DBCUST.CustDB
	
	Revisions:
		- 20150610@Kos: Separate CustDB to DBCUST server (Move SP to DBCUST.CustDB)
	Parameter's Explanation:
*/
--Original: sp CustomerSelAgentList

BEGIN
	SET NOCOUNT ON

	SELECT username, CustID
	FROM customer WITH (NOLOCK)
	WHERE roleid = 2 and Mrecommend = @MRecommend
	ORDER BY username
END




GO
GRANT EXECUTE ON [dbo].[Age_CustomerSelAgentList] TO [bodbDownlineNet,wsv_alp]
GO
GRANT EXECUTE ON [dbo].[Age_CustomerSelAgentList] TO [bodbDownlineNetView,wsv_alpv]
