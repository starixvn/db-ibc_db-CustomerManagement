ALTER PROCEDURE [dbo].[Acc_CustomerSelUsedCredit_Ag]
	@agentID int
AS
/*	Created by: 
	Task: Get Used Credit for agent 
	DB: DBTRANS.BODB02 
	Original: \account\hAgentUsedCredit.asp
	
*/
SET NOCOUNT ON

SELECT c.username, c.firstname, c.lastname, ci.credit, ci.closed
FROM customer c (nolock)
	inner join custInfo ci on c.custid = ci.custid
WHERE c.recommend = @agentID
	AND c.roleid = 1
ORDER BY
	ci.closed ASC, 
	c.Username   
  

GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelUsedCredit_Ag] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelUsedCredit_Ag] TO [bodbExtAccNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerSelUsedCredit_Ag] TO [vnteam]