/*<info serverAlias="DBCUST-CUSTDB" selecters="wsv_nap,wsv_alp,wsv_xnap,wsv_alpv" viewers="" isFunction="1" isNested="1"></info>*/
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
		- 20241107@Eden: Offer Direct Member for Super/Master [redmine: #211969]   
*/
RETURN
	WITH Temp AS (
		SELECT CAST('IBCIndo' AS VARCHAR(50)) AS Site, CAST(300 AS INT) AS Limit, CAST(150 AS INT) AS DirectMember_Limit
	)
	SELECT Site,Limit,DirectMember_Limit FROM Temp WHERE Site = @Site 




