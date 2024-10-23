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
				sc.AGIP,
				cc.CustDBGroupID, 
				cc.LinkedServerName AS LinkedServerNameDBCUST, 
				cc.ClientAccessName AS ClientAccessNameDBCUST, 
				cc.AGIP AS AGIP_DBCUST
		FROM site s WITH (NOLOCK) 
			INNER JOIN CustDBSiteConfig cc WITH (NOLOCK) ON s.CustDBGroupID = cc.CustDBGroupID
			INNER JOIN SiteDBConfig sc WITH (NOLOCK) ON s.SiteDBGroupID = sc.SiteDBGroupID			
		WHERE s.site = @Site
	END
	ELSE
	BEGIN 
		SELECT sc.SiteDBGroupID, sc.LinkedServerName, sc.ClientAccessName, sc.AGIP, cc.CustDBGroupID, cc.LinkedServerName AS LinkedServerNameDBCUST, cc.ClientAccessName AS ClientAccessNameDBCUST, cc.AGIP AS AGIP_DBCUST 
		FROM SiteDBConfig sc WITH (NOLOCK)
			INNER JOIN CustDBSiteConfig cc WITH (NOLOCK) ON sc.SiteDBGroupID = cc.CustDBGroupID
	END		
END
