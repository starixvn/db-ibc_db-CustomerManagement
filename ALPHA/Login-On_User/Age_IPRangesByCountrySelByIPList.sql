/*<info serverAlias="DBCUST-IPDB" executers="bodbAdminNet,bodbDownlineNet" viewers="" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[Age_IPRangesByCountrySelByIPList]
	@IpList	VARCHAR(MAX)
AS

/*
	Created: Kos@20230531
	Task: Alpha - Add Country info to bet list
	DB: DBCUST.IPDB

	Revisions:
		- 20230531@Kos: First revision [#Redmine: 188174]

	Parameter's Explanation:
		- @IpList: list of IP v4 seperated by comma (Ex: '115.134.56.247,82.118.29.215')
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @Ip TABLE (IpKey TINYINT, IpValue BIGINT)

	INSERT INTO @Ip (IpKey, IpValue)
	SELECT
		CONVERT(TINYINT, CONVERT(BINARY(1), SUBSTRING(FullIp.FullForm, 25, 2), 2)) AS IpKey,
		CONVERT(BIGINT , CONVERT(BINARY(4), SUBSTRING(FullIp.FullForm, 25, 8), 2)) AS IpValue
	FROM STRING_SPLIT(@IpList, ',') AS Ip
		CROSS APPLY dbo.f_IP_FullForm (Ip.value) AS FullIp

	SELECT
		im.ipFrom,
		im.ipTo,
		im.countrySHORT,
		im.countryLONG
	FROM dbo.ipTable_mini AS im WITH (NOLOCK)
	WHERE EXISTS (SELECT 1 FROM @Ip
				WHERE IpKey = im.ipKey
					AND IpValue BETWEEN ipFrom AND ipTo)
END
GO
