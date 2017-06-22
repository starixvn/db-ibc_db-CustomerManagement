ALTER PROCEDURE [dbo].[Acc_CustomerSelMatchLimit] 
	@custid		INT,
	@matchlimit SMALLMONEY OUTPUT
AS
/*
	Created: 
	Task : Get max exposure value of customer
	DB: DBCUST.CustDB
	Revisions:
		- 20150610@Kos: Separate CustDB to DBCUST server (Move SP to DBCUST.CustDB)
	Parameters Explanation:
	
*/
SET NOCOUNT ON

SELECT @matchlimit = matchlimit 
FROM custinfo WITH (NOLOCK) 
WHERE custid = @custid


GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelMatchLimit] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerSelMatchLimit] TO [vnteam] AS [dbo]

 