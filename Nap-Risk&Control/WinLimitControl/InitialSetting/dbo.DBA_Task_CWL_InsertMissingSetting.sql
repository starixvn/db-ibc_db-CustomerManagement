/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[DBA_Task_CWL_InsertMissingSetting] 
	@Mode TINYINT,
	@currencies VARCHAR(500) = ''
AS
/*
	Created: 20180326@Johnson
	Task : task insert missing  cwl setting 
	DB: DBCUST/CustDB
	Original:

	Revisions:
		- 20180326@Johnson: create sp [Redmine: #92012]
		- 20181108@Elodie: Migrate bodb_Licensee to DBCUST [Redmine:#99855]
		- 20220224@Johnson: Global setting by currency [#168583]
		- 20220614@Eden: DBCUST - modify sp syntax to adapt with the SQL Server upgrade to 2019 [Redmine: #171831]
	Param's Explanation:
	• @Mode: 1: deposit, 2: credit
	• @currencies: list currency need to add for credit
	
	*/
BEGIN
	SET NOCOUNT ON
	
	IF @mode = 1
	BEGIN		
		CREATE TABLE #Currency_Deposit (siteid INT, exchangeid INT, PRIMARY KEY (siteid,exchangeid))

		INSERT INTO #Currency_Deposit
		SELECT DISTINCT  s.siteid,ex.exchangeid AS Id
		FROM bodb_licensee.dbo.LicenseeCust lc WITH (NOLOCK)
		  INNER JOIN bodb_licensee.dbo.Licensees l WITH (NOLOCK) ON l.LicenseeID = lc.LicenseeID
		  INNER JOIN dbo.exchange ex WITH (NOLOCK) ON lc.Currency = ex.exchangeid
		  INNER JOIN dbo.site s WITH (NOLOCK) ON s.site = l.LicenseeName  AND S.isActive = 1
		WHERE ex.currency NOT IN('H', 'C')

		SELECT c.siteid, c.exchangeid, t.productid, t.groupID, 0 isPrivate
		INTO #site_currency
		FROM dbo.WinLimit_ProductGlobalSetting t WITH(NOLOCK)
			CROSS APPLY #Currency_Deposit c 
			LEFT JOIN WinLimit_ProductSettingDetail pd WITH(NOLOCK) ON t.productid = pd.productid
																		AND t.GroupID = pd.GroupID
																		AND c.siteid = pd.siteid
																		AND c.exchangeid = pd.exchangeid
		WHERE pd.siteid IS NULL
			AND t.currency = 0

		UPDATE t
		SET t.isPrivate = 1
		FROM #site_currency t
			INNER JOIN WinLimit_ProductGlobalSetting p WITH(NOLOCK) ON t.productid = p.productid
																		AND t.GroupID = p.GroupID																		
																		AND t.exchangeid = p.currency
		

		INSERT INTO WinLimit_ProductSettingDetail (ProductID, GroupID, ExchangeID, SiteID, LevelID,  IsBlockedPlaceBet, IsBlockedTransfer, MaxWinLimit_RM)
		SELECT DISTINCT p.ProductID, p.GroupID, s.ExchangeID, s.SiteID, 1 a, 0 b, 0 c,p.Level1 MaxWinLimit_RM
		FROM dbo.WinLimit_ProductGlobalSetting p WITH(NOLOCK)
			INNER JOIN #site_currency s ON p.productid = s.productid 
											AND p.groupID = s.groupID
		WHERE 1 = CASE WHEN s.isPrivate =1 AND p.currency = s.ExchangeID THEN 1
						WHEN s.isPrivate = 0 AND p.currency = 0 THEN 1 ELSE 0 END
		UNION ALL

		SELECT DISTINCT p.ProductID, p.GroupID, s.ExchangeID, s.SiteID, 2, 0, 0,p.Level2 MaxWinLimit_RM
		FROM dbo.WinLimit_ProductGlobalSetting p WITH(NOLOCK)
			INNER JOIN #site_currency s ON p.productid = s.productid 
											AND p.groupID = s.groupID
		WHERE 1 = CASE WHEN s.isPrivate =1 AND p.currency = s.ExchangeID THEN 1
						WHEN s.isPrivate = 0 AND p.currency = 0 THEN 1 ELSE 0 END											
		UNION ALL

		SELECT DISTINCT p.ProductID, p.GroupID, s.ExchangeID, s.SiteID, 3, 0 IsBlockedPlaceBet
				, p.blockedTransferLvl3 IsBlockedTransfer
				,p.Level3 MaxWinLimit_RM
		FROM dbo.WinLimit_ProductGlobalSetting p WITH(NOLOCK) 
			INNER JOIN #site_currency s ON p.productid = s.productid 
											AND p.groupID = s.groupID	
		WHERE 1 = CASE WHEN s.isPrivate =1 AND p.currency = s.ExchangeID THEN 1
						WHEN s.isPrivate = 0 AND p.currency = 0 THEN 1 ELSE 0 END									
		UNION ALL

		SELECT DISTINCT p.ProductID, p.GroupID, s.ExchangeID, s.SiteID, 101, 0 IsBlockedPlaceBet
				, 0 IsBlockedTransfer
				,p.Level101 MaxWinLimit_RM
		FROM dbo.WinLimit_ProductGlobalSetting p WITH(NOLOCK) 
			INNER JOIN #site_currency s ON p.productid = s.productid 
											AND p.groupID = s.groupID	
		WHERE 1 = CASE WHEN s.isPrivate =1 AND p.currency = s.ExchangeID THEN 1
						WHEN s.isPrivate = 0 AND p.currency = 0 THEN 1 ELSE 0 END									
		UNION ALL

		SELECT DISTINCT p.ProductID, p.GroupID, s.ExchangeID, s.SiteID, 102, 0 IsBlockedPlaceBet
				, 0 IsBlockedTransfer
				,p.Level102 MaxWinLimit_RM
		FROM dbo.WinLimit_ProductGlobalSetting p WITH(NOLOCK) 
			INNER JOIN #site_currency s ON p.productid = s.productid 
											AND p.groupID = s.groupID
		WHERE 1 = CASE WHEN s.isPrivate =1 AND p.currency = s.ExchangeID THEN 1
						WHEN s.isPrivate = 0 AND p.currency = 0 THEN 1 ELSE 0 END									

		UPDATE PSD
			SET MaxWinLimit = CASE WHEN psd.ExchangeID = 20 THEN MaxWinLimit_RM ELSE ROUND(MaxWinLimit_RM / e.actualrate,2) END
		FROM dbo.WinLimit_ProductSettingDetail PSD WITH(ROWLOCK, UPDLOCK) 
			INNER JOIN #site_currency s ON psd.productid = s.productid 
											AND psd.groupID = s.groupID
											AND psd.exchangeid = s.exchangeid
											AND psd.siteID = s.siteID
			INNER JOIN dbo.Exchange e WITH (NOLOCK)  ON e.ExchangeId = psd.ExchangeID
		WHERE PSD.MaxWinLimit_RM IS NOT NULL 
		
		DROP TABLE #Currency_Deposit
		DROP TABLE #site_currency
	END
	ELSE IF @mode = 2
	BEGIN
		DECLARE @tmpCurrency TABLE(currency INT)
		INSERT INTO @tmpCurrency (currency)
		SELECT value
		FROM STRING_SPLIT(@currencies,',')
		WHERE value <> ''

		IF @@rowcount <= 0 
		RETURN
			
		SELECT DISTINCT T.ProductID, t.GroupID, e.ExchangeID, s.SiteID, 0 isPrivate
		INTO #site_currencyCredit
		FROM dbo.WinLimit_ProductGlobalSetting t WITH(NOLOCK) 
			CROSS JOIN EXCHANGE E (NOLOCK) 
			CROSS JOIN (SELECT siteid FROM Site WITH (NOLOCK) WHERE isActive = 1 AND isLicensee = 0 ) AS S	
			LEFT JOIN WinLimit_ProductSettingDetail pd WITH(NOLOCK) ON t.productid = pd.productid
																		AND t.GroupID = pd.GroupID
																		AND s.siteid = pd.siteid
																		AND e.exchangeid = pd.exchangeid
		WHERE E.exchangeid IN (SELECT currency FROM @tmpCurrency)
			AND  pd.siteid IS NULL
			AND t.currency = 0
			
		
		UPDATE t
		SET t.isPrivate = 1
		FROM #site_currencyCredit t
			INNER JOIN WinLimit_ProductGlobalSetting p WITH(NOLOCK) ON t.productid = p.productid
																		AND t.GroupID = p.GroupID																		
																		AND t.exchangeid = p.currency

		INSERT INTO WinLimit_ProductSettingDetail (ProductID, GroupID, ExchangeID, SiteID, LevelID,  IsBlockedPlaceBet, IsBlockedTransfer, MaxWinLimit_RM)
		SELECT DISTINCT p.ProductID, p.GroupID, s.ExchangeID, s.SiteID, 1 a, 0 b, 0 c,p.Level1 MaxWinLimit_RM
		FROM dbo.WinLimit_ProductGlobalSetting p WITH(NOLOCK)
			INNER JOIN #site_currencyCredit s ON p.productid = s.productid 
											AND p.groupID = s.groupID
		WHERE 1 = CASE WHEN s.isPrivate =1 AND p.currency = s.ExchangeID THEN 1
						WHEN s.isPrivate = 0 AND p.currency = 0 THEN 1 ELSE 0 END	
			
		UNION ALL
		
		SELECT DISTINCT p.ProductID, p.GroupID, s.ExchangeID, s.SiteID, 2, 0, 0,p.Level2 MaxWinLimit_RM
		FROM dbo.WinLimit_ProductGlobalSetting p WITH(NOLOCK)
			INNER JOIN #site_currencyCredit s ON p.productid = s.productid 
											AND p.groupID = s.groupID
		WHERE 1 = CASE WHEN s.isPrivate =1 AND p.currency = s.ExchangeID THEN 1
						WHEN s.isPrivate = 0 AND p.currency = 0 THEN 1 ELSE 0 END											
		UNION ALL

		SELECT DISTINCT p.ProductID, p.GroupID, s.ExchangeID, s.SiteID, 3, 0 IsBlockedPlaceBet
				, 0 IsBlockedTransfer
				,p.Level3 MaxWinLimit_RM
		FROM dbo.WinLimit_ProductGlobalSetting p WITH(NOLOCK) 
			INNER JOIN #site_currencyCredit s ON p.productid = s.productid 
											AND p.groupID = s.groupID	
		WHERE 1 = CASE WHEN s.isPrivate =1 AND p.currency = s.ExchangeID THEN 1
						WHEN s.isPrivate = 0 AND p.currency = 0 THEN 1 ELSE 0 END									
		UNION ALL

		SELECT DISTINCT p.ProductID, p.GroupID, s.ExchangeID, s.SiteID, 101, 0 IsBlockedPlaceBet
				, 0 IsBlockedTransfer
				,p.Level101 MaxWinLimit_RM
		FROM dbo.WinLimit_ProductGlobalSetting p WITH(NOLOCK) 
			INNER JOIN #site_currencyCredit s ON p.productid = s.productid 
											AND p.groupID = s.groupID	
		WHERE 1 = CASE WHEN s.isPrivate =1 AND p.currency = s.ExchangeID THEN 1
						WHEN s.isPrivate = 0 AND p.currency = 0 THEN 1 ELSE 0 END									
		UNION ALL

		SELECT DISTINCT p.ProductID, p.GroupID, s.ExchangeID, s.SiteID, 102, 0 IsBlockedPlaceBet
				, 0 IsBlockedTransfer
				,p.Level102 MaxWinLimit_RM
		FROM dbo.WinLimit_ProductGlobalSetting p WITH(NOLOCK) 
			INNER JOIN #site_currencyCredit s ON p.productid = s.productid 
											AND p.groupID = s.groupID
		WHERE 1 = CASE WHEN s.isPrivate =1 AND p.currency = s.ExchangeID THEN 1
						WHEN s.isPrivate = 0 AND p.currency = 0 THEN 1 ELSE 0 END									

		--update exchange rate
		UPDATE PSD
			SET MaxWinLimit = CASE WHEN psd.ExchangeID = 20 THEN MaxWinLimit_RM ELSE ROUND(MaxWinLimit_RM / e.actualrate,2) END
		FROM dbo.WinLimit_ProductSettingDetail PSD WITH(ROWLOCK, UPDLOCK) 	
			INNER JOIN dbo.Exchange e WITH (NOLOCK)  ON e.ExchangeId = psd.ExchangeID
		WHERE PSD.MaxWinLimit_RM IS NOT NULL 
			AND e.exchangeid IN (SELECT currency FROM @tmpCurrency)
	END
END
GO
