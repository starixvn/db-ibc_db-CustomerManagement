ALTER PROCEDURE [dbo].[Age_CustomerCheckExists]
	@username	 VARCHAR(50),
	@isExists	 BIT = 0 OUTPUT
AS
/*
	Created: Johnson
	Date: 2015-04-06
	Task: Check user name is valid or not for creating customer
	DB: DBCUST.CustDB
	
	Revisions:
		- 20150610@Kos: Separate CustDB to DBCUST server (Move SP to DBCUST.CustDB)
	Parameter's Explanation:
*/	
BEGIN
	SET NOCOUNT ON
	
	IF EXISTS(SELECT 1 FROM customer WITH(NOLOCK) WHERE username = @username)
		OR EXISTS (SELECT 1 FROM customer WITH (NOLOCK) WHERE username2 = @username)
		OR EXISTS(SELECT 1 FROM custsub WITH (NOLOCK) WHERE username = @username)
			SELECT @isExists = 1
	ELSE 
			SELECT @isExists = 0
END


GO
GRANT EXECUTE ON [dbo].[Age_CustomerCheckExists] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Age_CustomerCheckExists] TO [bodbDownlineNetView]
GO
GRANT EXECUTE ON [dbo].[Age_CustomerCheckExists] TO [bodbExtAccNet]
 