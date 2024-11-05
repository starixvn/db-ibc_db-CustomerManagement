/*<info serverAlias="DBGLOB-GLOBCUSTDB" executers="wsv_nap,wsv_xnap" viewers="vnteam" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerSelSiteByUserNameMoveSite]
	@username VARCHAR(50) = ''
AS 
/*	Created by: [Khoa] 
	Date: 20100130
	Task: Get Site by username
	DB: DBCUST.CustDB

	Revisions:
		- 20150610@Kos: Separate CustDB to DBCUST server (Move SP to DBCUST.CustDB)
		- 20160114@Helen: Cricket - [Redmine: #50027]
		- 20241010@Helen: move site for CREDIT - [Redmine:#212007]

	Param's Explanation:
*/

BEGIN
	SET NOCOUNT ON

	SELECT site, roleid, custid 
	FROM custinfoMini WITH (NOLOCK) 
	WHERE username = @username AND [site] <> 'IMBC'
	
END
GO

