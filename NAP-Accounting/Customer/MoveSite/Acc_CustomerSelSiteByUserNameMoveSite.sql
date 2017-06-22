CREATE PROCEDURE [dbo].[Acc_CustomerSelSiteByUserNameMoveSite]
	@username VARCHAR(50) = ''
AS 
/*	Created by: [Khoa] 
	Date: 20100130
	Task: Get Site by username
	DB: DBCUST.CustDB

	Revisions:
		- 20150610@Kos: Separate CustDB to DBCUST server (Move SP to DBCUST.CustDB)
		- 20160114@Helen: Cricket - [Redmine: #50027]
	Param's Explanation:
*/

BEGIN
	SET NOCOUNT ON

	SELECT site, roleid, custid 
	FROM customer WITH (NOLOCK) 
	WHERE username = @username AND [site] <> 'IMBC'
	
END


GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelSiteByUserNameMoveSite] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelSiteByUserNameMoveSite] TO [bodbExtAccNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerSelSiteByUserNameMoveSite] TO [vnteam]

