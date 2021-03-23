/*<info serverAlias="DBCUST-CUSTDB" selecters="bodbAdminNet,bodbDownlineNet,bodbExtAccNet,bodbDownlineNetView" viewers="" isFunction="1" isNested="1"></info>*/
ALTER FUNCTION fn_LimitCreateAccountSiteConfig (@Site VARCHAR(50) = '' )
RETURNS TABLE
AS
/*
	Created By: Winfred
	Created Date: 20210319
	Description: Check Site to limit create accounts [Redmine #151526]
	DB: DBCust.CustDB
	
	Revisions:
		- 20210319@Winfred: Check Site to limit create accounts [Redmine: #151526]
*/
RETURN
	WITH Temp AS (
		SELECT CAST('IBCIndo' AS VARCHAR(50)) AS Site, CAST(5 AS INT) AS Limit
	)
	SELECT Site,Limit FROM Temp WHERE Site = @Site 




