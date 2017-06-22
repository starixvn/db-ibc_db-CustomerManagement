ALTER PROCEDURE  [dbo].[Age_CustomerSelMAgentList]
	@SRecommend INT
AS
/*
	Created: 
	Date:  
	Task : 
	DB: DBCUST.CustDB
	Revisions: 
		- 20150610@Kos: Separate CustDB to DBCUST server (Move SP to DBCUST.CustDB)

	Param's Explanation:
	• @SRecommend: Super Agent ID
*/

--Original: CustomerSelMAgentList
SELECT username, CustID 
FROM customer WITH (NOLOCK) 
WHERE roleid = 3 and SRecommend = @SRecommend
ORDER BY username




GO
GRANT EXECUTE ON [dbo].[Age_CustomerSelMAgentList] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Age_CustomerSelMAgentList] TO [bodbDownlineNetView]
