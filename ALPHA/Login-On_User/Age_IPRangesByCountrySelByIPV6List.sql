/*<info serverAlias="DBCUST-IPDB" executers="bodbDownlineNet" viewers="" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[Age_IPRangesByCountrySelByIPV6List]
	@IpList	VARCHAR(MAX)
AS

/*
	Created: Kos@20230531
	Task: Alpha - Add Country info to bet list
	DB: DBCUST.IPDB

	Revisions:
		- 20230531@Kos: First revision [#Redmine: 188174]

	Parameter's Explanation:
		- @IpList: list of IP v6 seperated by comma (Ex: '2001:e68:542d:4632:e5ec:4012:101f:ded,2001:d08:1012:5b0c:1:2:436:d9cf')
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @Ip TABLE (
		Ip				VARCHAR(45),
		IpVx			TINYINT,
		IpV4Key			TINYINT,
		IpV4Value		BIGINT,
		IpV6KeyValue	BINARY(2),
		IpV6Value		BINARY(16))

	DECLARE @IpCountry TABLE (
		Ip				VARCHAR(45),
		CountryShort	VARCHAR(2),
		CountryLong		VARCHAR(100))

	INSERT INTO @Ip (
		Ip,
		IpVx,
		IpV4Key,
		IpV4Value,
		IpV6KeyValue,
		IpV6Value)
	SELECT
		Ip.value AS Ip,
		CASE
			WHEN LEFT(FullIp.FullForm,24) = '00000000000000000000FFFF' THEN 4
			ELSE 6
		END AS IpVx,
		CONVERT(TINYINT, CONVERT(BINARY(1), SUBSTRING(FullIp.FullForm, 25, 2), 2)) AS IpV4Key,
		CONVERT(BIGINT , CONVERT(BINARY(4), SUBSTRING(FullIp.FullForm, 25, 8), 2)) AS IpV4Value,
		CONVERT(BINARY(2) , LEFT(FullIp.FullForm, 4), 2) AS IpV6KeyValue,
		CONVERT(BINARY(16), FullIp.FullForm, 2) AS IpV6Value
	FROM STRING_SPLIT(@IpList, ',') AS Ip
		CROSS APPLY dbo.f_IP_FullForm (Ip.value) AS FullIp

	INSERT INTO @IpCountry (
		Ip,
		CountryShort,
		CountryLong)
	SELECT
		ip.Ip,
		im.countrySHORT,
		im.countryLONG
	FROM dbo.ipTable_mini AS im WITH (NOLOCK)
		INNER JOIN @Ip AS ip ON ip.IpV4Key = im.ipKey AND ip.IpV4Value BETWEEN im.ipFrom AND im.ipTo
	WHERE ip.IpVx = 4

	INSERT INTO @IpCountry (
		Ip,
		CountryShort,
		CountryLong)
	SELECT
		ip.Ip,
		iptable.country_code AS countrySHORT,
		c.CountryName AS countryLONG
	FROM @Ip AS ip
		INNER JOIN dbo.KeyMap_IPv6_DB1 AS km WITH (NOLOCK) ON km.KeyValue = ip.IpV6KeyValue
		INNER JOIN dbo.IPv6_DB1 AS iptable WITH (NOLOCK) ON iptable.ipKey = km.ipKey
		INNER JOIN dbo.Country AS c WITH (NOLOCK) ON c.CountryCode = iptable.country_code
	WHERE ip.IpVx = 6
		AND ip.IpV6Value BETWEEN iptable.ipFROM AND iptable.ipTO

	SELECT * FROM @IpCountry
END
GO
