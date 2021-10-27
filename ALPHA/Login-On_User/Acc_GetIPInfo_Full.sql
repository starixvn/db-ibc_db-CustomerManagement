/*<info serverAlias="DBCUST-IPDB" executers="bodbAdminNet,bodbDownlineNet,bodbExtAccNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE Acc_GetIPInfo_Full
	@IP VARCHAR(45)
AS
/*
	Created by: Jamie
	Date: 2010-04-01
	Task: Get IP Info 
	DB: DBCUST/IPDB 
	Original: GetIPInfo_Full

	Revisions:	
		- 20180710@Razor: Grant permission for bodbExtAccNet
		- 20211018@Elodie: Support IPv6 Phase 1 - Support for 3rd party product bet tickets  [Redmine:#90903]
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @IPFull VARCHAR(45), @IPvX TINYINT
	DECLARE @v4IPKey TINYINT, @v4IPLong BIGINT, @v6KeyValue BINARY(2), @v6IPValue BINARY(16)

	SELECT	@IPFull		= fip.FullForm,
			@IPVx		= CASE WHEN LEFT(@IPFull,24) = '00000000000000000000FFFF' THEN 4 ELSE 6 END,
			@v4IPKey    = CASE @IPvX WHEN 4 THEN CONVERT(TINYINT, CONVERT(BINARY(1), SUBSTRING(@IPFull,25,2), 2)) END,
			@v4IPLong   = CASE @IPvX WHEN 4 THEN CONVERT(BIGINT , CONVERT(BINARY(4), SUBSTRING(@IPFull,25,8), 2)) END,
			@v6KeyValue = CASE @IPvX WHEN 6 THEN CONVERT(BINARY(2) , LEFT(@IPFull,4), 2) END,
			@v6IPValue  = CASE @IPvX WHEN 6 THEN CONVERT(BINARY(16), @IPFull, 2) END
	FROM dbo.f_IP_FullForm (@IP) fip

	IF @IPVx = 4
	BEGIN
		SELECT countrySHORT, countryLONG, ipRegion, ipCity
		FROM iptable WITH (NOLOCK)
		WHERE ipKeyFrom = @v4IPKey
			AND @v4IPLong BETWEEN ipFrom AND ipTo

		IF @@ROWCOUNT = 0
			SELECT ipKeyFrom, ipKeyTo, ipFrom, ipTo, countrySHORT, countryLONG, ipRegion, ipCity
			FROM iptable WITH (NOLOCK)
			WHERE @v4IPKey BETWEEN ipKeyFrom AND ipKeyTo
				AND @v4IPLong BETWEEN ipFrom AND ipTo
	END
	ELSE IF @IPVx = 6
	BEGIN
		SELECT iptable.country_code AS countrySHORT, c.CountryName AS countryLONG, iptable.region_name AS ipRegion, iptable.city_name AS ipCity
			FROM
				dbo.KeyMap_IPv6_DB3 km WITH (NOLOCK)
				INNER JOIN dbo.IPv6_DB3 iptable WITH (NOLOCK) ON km.ipKey = iptable.ipKey
				INNER JOIN dbo.Country c WITH (NOLOCK) ON c.CountryCode = iptable.country_code
			WHERE
				km.KeyValue = @v6KeyValue AND @v6IPValue BETWEEN iptable.ipFROM AND iptable.ipTO
	END
END