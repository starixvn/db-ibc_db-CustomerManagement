ALTER PROCEDURE [dbo].[Age_CustomerSelP2PComm_Ag]
	@Recommend int
AS 
/*
	Created: 20110818@TOM
	Task : Select member commission information of P2P Game
	DB: DB053.bodb02
	Original: 
	
	Revisions:	
		- 20120418@Johnson: Get commission for master
	Parameters Explanation:
*/
BEGIN
	SET NOCOUNT ON
	
	SELECT CIF.USERNAME , PGC.GROUPID ,PGC.adiscount mdiscount, PGC.discount adiscount, PGC.playerdiscount discount 
	FROM CUSTINFO CIF WITH(NOLOCK)
		INNER JOIN P2PGROUPCOMM PGC WITH(NOLOCK) ON PGC.CUSTID = CIF.CUSTID 
	WHERE CIF.RECOMMEND = @Recommend AND CIF.ROLEID = 1 
	ORDER BY CIF.USERNAME , PGC.GROUPID 
	
END
GO
GRANT EXECUTE ON [dbo].[Age_CustomerSelP2PComm_Ag] TO [wsv_alp]
GO
GRANT EXECUTE ON [dbo].[Age_CustomerSelP2PComm_Ag] TO [wsv_alpv]
Go
GRANT VIEW DEFINITION ON [dbo].[Age_CustomerSelP2PComm_Ag] TO [vnteam]
