/*<info serverAlias="DBGLOB-GlobCustDB,DBTXN-CustDB, DBACC-bodb02, DBAGE-bodb02, DBEXT-bodb02" executers="wsv_nap,wsv_alp,wsv_alpv,wsv_xnap,wsv_lap,asv_cust" viewers="" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[Acc_ServerDBConfigSel]	
	@Site NVARCHAR(50) = NULL
AS
/*
	Created by: Elodie
	Date: 20240716
	Task : Get SiteDBConfig, CustDBConfig info
	Revisions:
		- 20240716@Elodie: Initial SP
		- 20250610@Tacy: Setup KL [Redmine: #223922]

	Example:	EXEC Acc_ServerDBConfigSel @SiteDBGroupID = 1
				EXEC Acc_ServerDBConfigSel
*/
BEGIN
	SET NOCOUNT ON  	
	IF @Site IS NOT NULL
	BEGIN 
		SELECT	sc.SiteDBGroupID, 
				sc.LinkedServerName, 
				sc.ClientAccessName, 
				CASE sc.SiteDBGroupID 
					WHEN 0 THEN '10.146.11.130' 
					WHEN 1 THEN '10.146.11.160' 
					WHEN 2 THEN '10.146.11.161' 
					WHEN 3 THEN '10.146.11.162' 
				END AS AGIP,
				cc.CustDBGroupID, 
				cc.LinkedServerName AS LinkedServerNameDBCUST, 
				cc.ClientAccessName AS ClientAccessNameDBCUST, 
				CASE cc.CustDBGroupID 
					WHEN 0 THEN '10.146.11.150' 
					WHEN 1 THEN '10.146.11.160' 
					WHEN 2 THEN '10.146.11.161' 
					WHEN 3 THEN '10.146.11.162' 
				END AS AGIP_DBCUST
		FROM site s WITH (NOLOCK) 
			INNER JOIN CustDBSiteConfig cc WITH (NOLOCK) ON s.CustDBGroupID = cc.CustDBGroupID
			INNER JOIN SiteDBConfig sc WITH (NOLOCK) ON s.SiteDBGroupID = sc.SiteDBGroupID			
		WHERE s.site = @Site
	END
	ELSE
	BEGIN 
		SELECT	sc.SiteDBGroupID, 
				sc.LinkedServerName, 
				sc.ClientAccessName, 
				CASE sc.SiteDBGroupID 
					WHEN 0 THEN '10.146.11.130' 
					WHEN 1 THEN '10.146.11.160' 
					WHEN 2 THEN '10.146.11.161' 
					WHEN 3 THEN '10.146.11.162' 
				END AS AGIP, 
				cc.CustDBGroupID, 
				cc.LinkedServerName AS LinkedServerNameDBCUST, 
				cc.ClientAccessName AS ClientAccessNameDBCUST, 
				CASE cc.CustDBGroupID 
					WHEN 0 THEN '10.146.11.150' 
					WHEN 1 THEN '10.146.11.160' 
					WHEN 2 THEN '10.146.11.161' 
					WHEN 3 THEN '10.146.11.162' 
				END AS AGIP_DBCUST
		FROM SiteDBConfig sc WITH (NOLOCK)
			INNER JOIN CustDBSiteConfig cc WITH (NOLOCK) ON sc.SiteDBGroupID = cc.CustDBGroupID
	END		
END
