/*<info serverAlias="DBGLOB-GlobCustDB" executers="wsv_nap,wsv_lap,asv_cust" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE Acc_Dep_ServerDBConfigSelByCust
	@CustId INT = NULL,
	@Username VARCHAR(30) = NULL
AS
/*
	Created by: Elodie
	Date: 20240716
	Task : Get CustDBSiteConfig info
	DB: DBGLOB/GlobCustDB
	Revisions:
		- 20240716@Elodie: Initial SP 

	Example:	EXEC Acc_Dep_ServerDBConfigSelByCust @CustId = 46699667
*/
BEGIN
	SET NOCOUNT ON  	
	IF @CustId IS NOT NULL
	BEGIN
		SELECT	c.custid, s.site,
				cc.CustDBGroupID, 
				cc.LinkedServerName AS LinkedServerNameDBCUST, 
				cc.ClientAccessName AS ClientAccessNameDBCUST, 
				cc.AGIP AS AGIP_DBCUST,
				cc.FQDN AS FQDN_DBCUST,
				sc.SiteDBGroupID, 
				sc.LinkedServerName, 
				sc.ClientAccessName, 
				sc.AGIP,
				sc.FQDN
		FROM CustInfoMini c WITH (NOLOCK)
			INNER JOIN Site s WITH (NOLOCK) ON c.site = s.site
			INNER JOIN CustDBSiteConfig cc WITH (NOLOCK) ON s.CustDBGroupID = cc.CustDBGroupID
			INNER JOIN SiteDBConfig sc WITH (NOLOCK) ON s.SiteDBGroupID = sc.SiteDBGroupID 
		WHERE custid = @CustId
			AND s.isDeposit = 1
	END
	ELSE 
	BEGIN
		SELECT	c.custid, s.site,
				cc.CustDBGroupID, 
				cc.LinkedServerName AS LinkedServerNameDBCUST, 
				cc.ClientAccessName AS ClientAccessNameDBCUST, 
				cc.AGIP AS AGIP_DBCUST,
				cc.FQDN AS FQDN_DBCUST,
				sc.SiteDBGroupID, 
				sc.LinkedServerName, 
				sc.ClientAccessName, 
				sc.AGIP,
				sc.FQDN
		FROM CustInfoMini c WITH (NOLOCK)
			INNER JOIN Site s WITH (NOLOCK) ON c.site = s.site
			INNER JOIN CustDBSiteConfig cc WITH (NOLOCK) ON s.CustDBGroupID = cc.CustDBGroupID
			INNER JOIN SiteDBConfig sc WITH (NOLOCK) ON s.SiteDBGroupID = sc.SiteDBGroupID 
		WHERE username = @Username
			AND s.isDeposit = 1
	END
END
GO