/*<info serverAlias="DBCUST-IPDB" executers="bodbAdminNet,bodbDownlineNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Age_IPRangesByCountrySel]
	@isIPV6 BIT = 0,
	@countryCodes NVARCHAR(MAX) = ''
AS
	/*
		Created: Louis.Nguyen
		Date: 2018-03-13
		Task: Get IP Ranges by country codes
		DB: DBCUST/IPDB
		
		Revisions:
			- 20180313@Louis: Create [Redmine: 91633]
			- 20190627@Alvin: Switch to use table IP mini instead of IP table
			- 20211018@Elodie: Support IPv6 Phase 1 - Support for 3rd party product bet tickets  [Redmine:#160390]

		Parameter's Explanation:
			@isIPV6: choose data source of ipv6 instead of ipv4
			@countryCodes: list of country codes
	*/
BEGIN
	SET NOCOUNT ON 
	CREATE TABLE #CountryCodes(Code NVARCHAR(MAX))
	INSERT INTO #CountryCodes(Code) 
	SELECT val FROM strSplit(@countryCodes, ',')
	
	IF @isIPV6 = 0
	BEGIN			
		SELECT IPFrom, IPTo, CountryShort 
		FROM ipTable_mini WITH (NOLOCK) 
		WHERE EXISTS (SELECT Code FROM #CountryCodes WHERE Code = CountryShort)
	END
	ELSE
	BEGIN
		SELECT IPFrom, IPTo, country_code AS CountryShort
		FROM
			dbo.IPv6_DB1 iptable WITH (NOLOCK)
		WHERE EXISTS (SELECT Code FROM #CountryCodes WHERE Code = iptable.country_code)		
	END
END
GO












