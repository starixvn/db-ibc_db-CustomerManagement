/*<info serverAlias="DBGLOB-GlobCustDB" executers="wsv_nap,wsv_alp,wsv_alpv,wsv_xnap,wsv_lap,wsv_CashService,asv_CashService" viewers="" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[Acc_ServerDBConfigSelByCust]
	@CustID INT = NULL,
	@username VARCHAR(30) = NULL
AS
/*
	Created by: Elodie
	Date: 20240716
	Task : Get SiteDBConfig, CustDBConfig info by customer
	DB: DBCUST/CustDB
	Revisions:
		- 20240716@Elodie: Initial SP

	Example:	EXEC Acc_ServerDBConfigSelByCust @CustID = 791048 
				EXEC Acc_ServerDBConfigSelByCust @username = 'supertest1'
				
*/
BEGIN
	SET NOCOUNT ON  
	
	IF @CustID IS NOT NULL
	BEGIN 
		IF EXISTS (SELECT TOP 1 1  FROM CustInfoMini c WITH (NOLOCK) WHERE custid = @CustID AND c.roleid <= 4)
		BEGIN
			SELECT	sc.SiteDBGroupID, 
					sc.LinkedServerName, 
					sc.ClientAccessName, 
					sc.AGIP,
					cc.CustDBGroupID, 
					cc.LinkedServerName AS LinkedServerNameDBCUST, 
					cc.ClientAccessName AS ClientAccessNameDBCUST, 
					cc.AGIP AS AGIP_DBCUST,
					c.Site
			FROM CustInfoMini c WITH (NOLOCK)		
				LEFT JOIN site s WITH (NOLOCK) ON c.site = s.site
				INNER JOIN CustDBSiteConfig cc WITH (NOLOCK) ON ISNULL(s.CustDBGroupID,0) = cc.CustDBGroupID
				INNER JOIN SiteDBConfig sc WITH (NOLOCK) ON ISNULL(s.SiteDBGroupID,0) = sc.SiteDBGroupID
			WHERE CustID = @CustID
		END
		ELSE
		BEGIN
			SELECT	sc.SiteDBGroupID, 
					sc.LinkedServerName, 
					sc.ClientAccessName, 
					sc.AGIP,
					cc.CustDBGroupID, 
					cc.LinkedServerName AS LinkedServerNameDBCUST, 
					cc.ClientAccessName AS ClientAccessNameDBCUST, 
					cc.AGIP AS AGIP_DBCUST,
					NULL AS Site
			FROM CustDBSiteConfig cc WITH (NOLOCK) 
				CROSS JOIN SiteDBConfig sc WITH (NOLOCK) 
			WHERE cc.CustDBGroupID = 0 AND sc.SiteDBGroupID = 0
		END
	END
	ELSE IF @username IS NOT NULL
	BEGIN 
		IF EXISTS (SELECT TOP 1 1  FROM CustInfoMini c WITH (NOLOCK) WHERE username = @username AND c.roleid <= 4)
		BEGIN
			SELECT	sc.SiteDBGroupID, 
					sc.LinkedServerName, 
					sc.ClientAccessName, 
					sc.AGIP,
					cc.CustDBGroupID, 
					cc.LinkedServerName AS LinkedServerNameDBCUST, 
					cc.ClientAccessName AS ClientAccessNameDBCUST, 
					cc.AGIP AS AGIP_DBCUST,
					c.Site
			FROM CustInfoMini c WITH (NOLOCK)		
				LEFT JOIN site s WITH (NOLOCK) ON c.site = s.site
				INNER JOIN CustDBSiteConfig cc WITH (NOLOCK) ON ISNULL(s.CustDBGroupID,0) = cc.CustDBGroupID
				INNER JOIN SiteDBConfig sc WITH (NOLOCK) ON ISNULL(s.SiteDBGroupID,0) = sc.SiteDBGroupID
			WHERE username = @username
		END
		ELSE
		BEGIN
			SELECT	sc.SiteDBGroupID, 
					sc.LinkedServerName, 
					sc.ClientAccessName, 
					sc.AGIP,
					cc.CustDBGroupID, 
					cc.LinkedServerName AS LinkedServerNameDBCUST, 
					cc.ClientAccessName AS ClientAccessNameDBCUST, 
					cc.AGIP AS AGIP_DBCUST,
					NULL AS Site
			FROM CustDBSiteConfig cc WITH (NOLOCK) 
				CROSS JOIN SiteDBConfig sc WITH (NOLOCK) 
			WHERE cc.CustDBGroupID = 0 AND sc.SiteDBGroupID = 0
		END
	END
END
