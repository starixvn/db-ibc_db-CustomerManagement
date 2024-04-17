/*<info serverAlias="DBCUST-IPDB" executers="wsv_nap,wsv_alp,wsv_xnap,wsv_lap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_GetInfoListIPs]
	@IPs		VARCHAR(MAX) = ''
AS
/*
	Created: Winfred
	Date: 20230425
	Task : Alpha - Notify abnormal login via Telegram chatbot
	DB: DBCUST/IPDB
	Original:

	Revisions:
		- 20230425@Winfred: Alpha - Notify abnormal login via Telegram chatbot - Get info IP [RedmineID: #183746] 

	Param's Explanation:

	Example: Acc_GetInfoListIPs 
	
*/ 
BEGIN
	SET NOCOUNT ON; 
	
	CREATE TABLE #ListIPInfo( IP VARCHAR(45), IPFull VARCHAR(45), IPvX TINYINT, v4IPKey TINYINT, v4IPLong BIGINT, 
			v6KeyValue BINARY(2), v6IPValue BINARY(16), CountryName NVARCHAR(200), city_name VARCHAR(128))
	
	INSERT INTO #ListIPInfo( IP, IPFull, IPvX, v4IPKey, v4IPLong, v6KeyValue, v6IPValue)
	SELECT  VALUE AS IPs , 
			fip.FullForm, 
		    CASE WHEN LEFT(fip.FullForm,24) = '00000000000000000000FFFF' THEN 4 ELSE 6 END AS IPvX,
			CASE WHEN LEFT(fip.FullForm,24) = '00000000000000000000FFFF' THEN CONVERT(TINYINT, CONVERT(BINARY(1), SUBSTRING(fip.FullForm,25,2), 2)) END AS v4IPKey,
			CASE WHEN LEFT(fip.FullForm,24) = '00000000000000000000FFFF' THEN CONVERT(BIGINT , CONVERT(BINARY(4), SUBSTRING(fip.FullForm,25,8), 2)) END AS v4IPLong,
			CASE WHEN LEFT(fip.FullForm,24) <> '00000000000000000000FFFF' THEN CONVERT(BINARY(2) , LEFT(fip.FullForm,4), 2) END AS v6KeyValue,
			CASE WHEN LEFT(fip.FullForm,24) <> '00000000000000000000FFFF' THEN CONVERT(BINARY(16), fip.FullForm, 2) END AS v6IPValue
	FROM STRING_SPLIT(@IPs,',') s
		CROSS APPLY dbo.f_IP_FullForm (s.VALUE) fip
	WHERE VALUE <> ''

	UPDATE a
	SET a.CountryName = i.countryLONG,
		a.city_name = i.ipCity
	FROM #ListIPInfo a
		INNER JOIN iptable i WITH (NOLOCK) ON i.ipKeyFrom = a.v4IPKey AND a.v4IPLong  BETWEEN  i.ipFrom AND i.ipTo
	WHERE a.IPvX = 4

	UPDATE a
	SET a.CountryName = i.countryLONG,
		a.city_name = i.ipCity
	FROM #ListIPInfo a
		INNER JOIN iptable i WITH (NOLOCK) ON a.v4IPKey BETWEEN i.ipKeyFrom AND i.ipKeyTo AND a.v4IPLong  BETWEEN  i.ipFrom AND i.ipTo
	WHERE a.IPvX = 4 AND a.CountryName IS NULL
	
	UPDATE a
	SET a.CountryName = c.CountryName,
		a.city_name = iptable.city_name
	FROM #ListIPInfo a
		INNER JOIN dbo.KeyMap_IPv6_DB3 km WITH (NOLOCK) ON a.v6KeyValue = km.KeyValue 
		INNER JOIN dbo.IPv6_DB3 iptable WITH (NOLOCK) ON km.ipKey = iptable.ipKey
		INNER JOIN dbo.Country c WITH (NOLOCK) ON c.CountryCode = iptable.country_code
	WHERE a.IPvX = 6 AND a.v6IPValue BETWEEN iptable.ipFROM AND iptable.ipTO

	SELECT IP, CountryName, city_name
	FROM #ListIPInfo 
	ORDER BY IP
	
	DROP TABLE #ListIPInfo
END
GO
