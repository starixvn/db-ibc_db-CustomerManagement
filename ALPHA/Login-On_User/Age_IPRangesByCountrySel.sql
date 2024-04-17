/*<info serverAlias="DBCUST-IPDB" executers="wsv_nap,bodbDownlineNet,wsv_alp" viewers="" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[Age_IPRangesByCountrySel]
	@isIPV6			BIT				= 0,
	@countryCodes	NVARCHAR(MAX)	= ''
AS

/*
	Created: Louis.Nguyen
	Date: 2018-03-13
	Task: Get IP Ranges by country codes
	DB: DBCUST.IPDB

	Revisions:
		- 20180313@Louis: Create [Redmine: 91633]
		- 20190627@Alvin: Switch to use table IP mini instead of IP table
		- 20230531@Kos: Return country name to show in bet list [#Redmine: 91048]
		
	Parameter's Explanation:
		@isIPV6: choose data source of ipv6 instead of ipv4
		@countryCodes: list of country codes
*/

BEGIN
	SET NOCOUNT ON

	CREATE TABLE #CountryCodes (Code NVARCHAR(MAX))

	INSERT INTO #CountryCodes(Code)
	SELECT value FROM STRING_SPLIT(@countryCodes, ',')
	
	IF @isIPV6 = 0
	BEGIN
		SELECT ipFrom, ipTo, countrySHORT, countryLONG
		FROM dbo.ipTable_mini WITH (NOLOCK)
		WHERE EXISTS (SELECT Code FROM #CountryCodes WHERE Code = CountryShort)
	END
	ELSE
	BEGIN
		SELECT TOP 0 ipFrom, ipTo, countrySHORT, countryLONG
		FROM dbo.ipTable_mini WITH (NOLOCK)
		WHERE EXISTS (SELECT Code FROM #CountryCodes WHERE Code = CountryShort)
	END
END
GO
