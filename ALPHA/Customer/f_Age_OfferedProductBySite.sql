/*<info serverAlias="DBAGE-bodb02, DBACC-bodb02" executers="" viewers="" isFunction="1" isNested="1"></info>*/

ALTER FUNCTION dbo.f_Age_OfferedProductBySite(@Site VARCHAR(50))
RETURNS BIT
AS
/*
	Created: 20231206@Tacy
	Task: check offered Saba Promotion by site 
	DB: DBAGE-bodb02, DBACC-bodb02
	
	Revisions:
		- 20231206@Tacy: Create function [RedmineID: #194981]
		- 20240109@Johnson: offered Saba Promotion for 777 [RedmineID:#194591]

	Example:
*/
BEGIN
	RETURN 
	(	SELECT CASE WHEN s.SiteLabel IN ('789y') THEN 0 ELSE 1 END IsOffered
		FROM Site s WITH (NOLOCK)
		WHERE s.site=@Site
	)
END
GO