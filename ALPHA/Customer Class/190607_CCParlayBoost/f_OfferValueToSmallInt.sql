/*<info serverAlias="DBCust-CustDB,DBTP-bodb02" selecters="" viewers="" isFunction="1"></info>*/
ALTER FUNCTION	dbo.f_OfferValueToSmallInt (
					@OfferValue VARCHAR(MAX)
				)  
RETURNS TABLE
AS
/*
	Created:	20231002@Winfred
	Database:	DBCust/CustDB,DBTP-bodb02
	Original:	
	Revision:
		- 20231002@Winfred: [NAP CM] Customer Class - Allow to offer Parlay Boost on rule setting [RedmineID: #190607] 

	Param's Explanation:
*/
RETURN SELECT CAST(ISNULL((
				  CASE WHEN ',' + @OfferValue + ',' LIKE '%,1,%' THEN 1 ELSE 0 END * POWER(2, 0)
				+ CASE WHEN ',' + @OfferValue + ',' LIKE '%,2,%' THEN 1 ELSE 0 END * POWER(2, 1) 
				+ CASE WHEN ',' + @OfferValue + ',' LIKE '%,3,%' THEN 1 ELSE 0 END * POWER(2, 2)
				+ CASE WHEN ',' + @OfferValue + ',' LIKE '%,4,%' THEN 1 ELSE 0 END * POWER(2, 3)
				+ CASE WHEN ',' + @OfferValue + ',' LIKE '%,5,%' THEN 1 ELSE 0 END * POWER(2, 4)
				+ CASE WHEN ',' + @OfferValue + ',' LIKE '%,6,%' THEN 1 ELSE 0 END * POWER(2, 5)
				+ CASE WHEN ',' + @OfferValue + ',' LIKE '%,7,%' THEN 1 ELSE 0 END * POWER(2, 6)
				+ CASE WHEN ',' + @OfferValue + ',' LIKE '%,8,%' THEN 1 ELSE 0 END * POWER(2, 7)
				+ CASE WHEN ',' + @OfferValue + ',' LIKE '%,9,%' THEN 1 ELSE 0 END * POWER(2, 8)
				+ CASE WHEN ',' + @OfferValue + ',' LIKE '%,10,%' THEN 1 ELSE 0 END * POWER(2, 9)
				+ CASE WHEN ',' + @OfferValue + ',' LIKE '%,11,%' THEN 1 ELSE 0 END * POWER(2, 10)
				+ CASE WHEN ',' + @OfferValue + ',' LIKE '%,12,%' THEN 1 ELSE 0 END * POWER(2, 11)
				+ CASE WHEN ',' + @OfferValue + ',' LIKE '%,13,%' THEN 1 ELSE 0 END * POWER(2, 12)
				+ CASE WHEN ',' + @OfferValue + ',' LIKE '%,14,%' THEN 1 ELSE 0 END * POWER(2, 13)
				+ CASE WHEN ',' + @OfferValue + ',' LIKE '%,15,%' THEN 1 ELSE 0 END * POWER(2, 14)
				),0) AS SMALLINT) AS value