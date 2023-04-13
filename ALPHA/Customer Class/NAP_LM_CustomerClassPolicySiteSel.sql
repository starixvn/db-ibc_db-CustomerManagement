/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,bodbLicenseeNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_LM_CustomerClassPolicySiteSel] 
	@PolicyID INT
	,@Site NVARCHAR(MAX)
	,@Platform NVARCHAR(MAX)
	,@IsTest TINYINT
	,@PageSize INT = 500
	,@PageIndex INT = 1
	,@TotalItems INT = 1 OUTPUT
AS
/*
	Created: Winfred
	Date: 20221209
	Task : [NAP CM] Build Customer Class Management [#180904]
	DB: DBCUST/CustDB
	Original:

	Revisions:
		- 20221209@Winfred: [NAP CM] Build Customer Class Management [RedmineID: #180904] 

	Param's Explanation:
	Example: NAP_LM_CustomerClassPolicySiteSel @PolicyID = 1, @Site = '12Bet', @Platform = 1
*/ 
BEGIN
	SET NOCOUNT ON;

	DECLARE @RowStart INT, @RowEnd INT
	SELECT @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1

	CREATE TABLE #CustomerClass( PolicyID INT, Site NVARCHAR(50), Currency TINYINT, Platform TINYINT)
	CREATE TABLE #CustomerClassSiteManagement ( PolicyID INT, Site NVARCHAR(50), Currency TINYINT, CurrencyName	nvarchar(50), Platform VARCHAR(MAX) , RowNumber INT)
	CREATE CLUSTERED INDEX CIX_CustomerClass ON #CustomerClass(PolicyID, Site, Currency, Platform)
	CREATE NONCLUSTERED INDEX inx_temp ON #CustomerClassSiteManagement( PolicyID, RowNumber )
	INCLUDE (Site, Currency)
	 
	INSERT INTO #CustomerClass(PolicyID, Site, Currency, Platform)
	SELECT a.PolicyID,
			a.Site,
			a.Currency,
			a.Platform
		FROM CustomerClassSiteManagement a WITH(NOLOCK)
			INNER JOIN CustomerClassPolicyManagement b WITH(NOLOCK) ON a.PolicyID = b.PolicyID
		WHERE (@PolicyID = 0 OR a.PolicyID = @PolicyID) AND b.IsTest <= @IsTest
		AND (a.Platform IN (SELECT VALUE AS Platform FROM STRING_SPLIT(@Platform,',') WHERE VALUE <> ''))  
		AND (a.Site IN (SELECT VALUE AS site FROM STRING_SPLIT(@Site,',') WHERE VALUE <> '')) 
	
	-- Get all Platform for policy 
	INSERT INTO #CustomerClassSiteManagement(PolicyID, Site, Currency, CurrencyName, Platform, RowNumber)
	SELECT DISTINCT a.PolicyID,
			a.Site,
			a.Currency,
			e.currency AS CurrencyName,
			d.Platforms,
			DENSE_RANK() OVER( ORDER BY a.PolicyID, a.Site, d.Platforms) AS RowNumber
	FROM #CustomerClass a WITH(NOLOCK)
		INNER JOIN exchange e WITH(NOLOCK) ON a.Currency = e.ExchangeId
		CROSS APPLY(
			SELECT STRING_AGG(Platform, ',') WITHIN GROUP (ORDER BY Platform)  AS Platforms
			FROM (SELECT DISTINCT CAST(Platform AS VARCHAR(20)) AS Platform
				FROM CustomerClassSiteManagement WITH(NOLOCK)
				WHERE PolicyID = a.PolicyID AND a.Site = Site AND a.Currency = currency) mis
		) d
	
	--Paging
	SELECT @TotalItems = MAX(RowNumber) FROM #CustomerClassSiteManagement c 
	DELETE FROM #CustomerClassSiteManagement  WHERE  RowNumber NOT BETWEEN @RowStart AND @RowEnd 
	-- Group Currency

	SELECT DISTINCT  a.PolicyID,
			b.PolicyTitle,
			a.Site,
			d.CurrencyName,
			a.Platform, a.RowNumber
	FROM #CustomerClassSiteManagement a 
			INNER JOIN CustomerClassPolicyManagement b WITH(NOLOCK) ON a.PolicyID = b.PolicyID
			CROSS APPLY(
				SELECT STRING_AGG(CAST(CurrencyName AS VARCHAR(200)), ',') WITHIN GROUP (ORDER BY CurrencyName)  AS CurrencyName
				FROM (SELECT DISTINCT CurrencyName
				FROM #CustomerClassSiteManagement 
				WHERE PolicyID = a.PolicyID AND a.Site = Site AND a.Platform = Platform ) mis
			) d
	DROP TABLE #CustomerClass
END
GO
