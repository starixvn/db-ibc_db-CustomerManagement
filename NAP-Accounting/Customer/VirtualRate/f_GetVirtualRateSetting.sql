/*<info serverAlias="DBCUST-CustDB,DBACC-bodb02,DBLIC-bodb_Licensee" executers="" viewers="" isFunction="1"></info>*/

CREATE FUNCTION [dbo].[f_GetVirtualRateSetting] (@bitmap binary(64), @profileID smallint)  
RETURNS TABLE AS  
/*
	Created: Viet @ 15.OCT.2015
	DB: DBLIC.bodb_licensee

	Revision:				
		- 20170328@Elodie: Expand the range of VR setting [RedmineID:#73808]
	Param's Explanation:	
*/
	
RETURN SELECT (CASE WHEN CAST(substring(@bitmap, 1+((@profileID-1)%64), 1) as int) > 200 THEN ((CAST(substring(@bitmap, 1+((@profileID-1)%64), 1) as int) - 200)*5 + 200) ELSE CAST(substring(@bitmap, 1+((@profileID-1)%64), 1) as int) END) / 100.0 AS VAL
