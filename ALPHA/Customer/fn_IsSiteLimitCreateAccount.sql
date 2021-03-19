/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,bodbDownlineNet,bodbExtAccNet,bodbDownlineNetView" viewers="" isFunction="1" isNested="1"></info>*/
CREATE FUNCTION fn_IsSiteLimitCreateAccount (@Site VARCHAR(50) = '' )
RETURNS INT
AS
/*
	Created By: Winfred
	Created Date: 20210319
	Description: Check Site to limit create accounts [Redmine #151526]
	DB: DBCust.CustDB
	
	Revisions:
		- 20210319@Winfred: Check Site to limit create accounts [Redmine: #151526]
*/
BEGIN
	RETURN CASE WHEN @Site in ('IBCIndo') THEN 300 ELSE 0 END	
END



