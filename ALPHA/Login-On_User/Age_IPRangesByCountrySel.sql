/*<info serverAlias="DBCUST-IPDB" executers="bodbAdminNet,bodbDownlineNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Age_IPRangesByCountrySel]
	@isIPV6 BIT = 0,
	@countryCodes NVARCHAR(MAX) = ''
AS
	/*
		Created: Louis.Nguyen
		Date: 2018-03-13
		Task: Get IP Ranges by country codes
		DB: DBCUST.IPDB
		
		Revisions:
			-20180313@Louis: Create
		
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
		FROM IPTable WITH (NOLOCK) 
		WHERE EXISTS (SELECT Code FROM #CountryCodes WHERE Code = CountryShort)
	END
	ELSE
	BEGIN
		SELECT TOP 0 IPFrom, IPTo, CountryShort 
		FROM IPTable WITH (NOLOCK) 
		WHERE EXISTS (SELECT Code FROM #CountryCodes WHERE Code = CountryShort)
	END
END
GO












