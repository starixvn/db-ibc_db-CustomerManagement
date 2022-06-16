
/*<info serverAlias="DBCust-CustDB" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/

CREATE PROCEDURE [dbo].[NAP_WinLimit_CurrencySettingByProductSel] 
	@ProductId INT, 
	@GroupId   INT
AS  
   
/*
Created: Robert
Date: 2022-05-18
Task: #168458 - CWL - Enhance Currency Win Limit Setting page

DB: DBCUST/CustDB

Revisions:
20220518@Robert: Enhance Currency Win Limit Setting page [168458]
Parameters Explanation:     
     
Example:
EXEC [NAP_WinLimit_CurrencySelAll] 
*/

    BEGIN
	   SET NOCOUNT ON;
	   DECLARE 
		   @SiteId INT;

	   CREATE TABLE #tplCurrencySetting
				 (
		   ExchangeId        INT, 
		   Level1            DECIMAL, 
		   Level2            DECIMAL, 
		   Level3            DECIMAL, 
		   Level101          DECIMAL, 
		   Level102          DECIMAL, 
		   IsBlockedPlaceBet BIT, 
		   IsBlockedTransfer BIT
				 );
	   CREATE INDEX IDX_tplCurrencySetting_ExchangeId ON #tplCurrencySetting(ExchangeId);

	   CREATE TABLE #tplLicensee
				 (
		   SiteId    INT, 
		   SiteName  VARCHAR(50), 
		   GroupName VARCHAR(50)
				 );
	   CREATE INDEX IDX_tplLicensee_SiteId ON #tplLicensee(SiteId);

	   SELECT TOP 1 
			@SiteId = w.SiteID
	   FROM [dbo].[WinLimit_ProductSettingDetail] w(NOLOCK)
	   WHERE w.ProductID = @ProductId
		    AND w.GroupID = @GroupId
	   GROUP BY 
			  w.SiteID
	   ORDER BY 
			  COUNT(1) DESC;


	   INSERT INTO #tplCurrencySetting
		 (
			ExchangeId, 
			Level1, 
			Level2, 
			Level3, 
			Level101, 
			Level102
		 )
			SELECT 
				  piv.ExchangeID, 
				  piv.[1] Level1, 
				  piv.[2] Level2, 
				  piv.[3] Level3, 
				  piv.[101] Level101, 
				  piv.[102] Level102
			FROM(SELECT 
					  w.ExchangeID, 
					  w.LevelID, 
					  w.MaxWinLimit_RM
				FROM [dbo].[WinLimit_ProductSettingDetail] w WITH(NOLOCK)
				WHERE w.ProductID = @ProductId
					 AND w.GroupID = @GroupId
					 AND w.SiteID = @SiteId) src PIVOT(MAX(MaxWinLimit_RM) FOR [LevelID] IN(
																			  [1], 
																			  [2], 
																			  [3], 
																			  [101], 
																			  [102])) piv;




	   BEGIN -- select licensee site
		  CREATE TABLE #Party
					(
			  PartyId    INT
			  PRIMARY KEY, 
			  PartyName  VARCHAR(50), 
			  BranchName VARCHAR(50), 
			  ParentId   INT
					);
		  CREATE TABLE #PartyGroup
					(
			  PartyGroupId   INT
			  PRIMARY KEY, 
			  PartyGroupName VARCHAR(50)
					);
		  CREATE TABLE #DepositLicenseeProduct
					(
			  ProductId    INT, 
			  LicenseeId   INT, 
			  LicenseeName VARCHAR(50), 
			  PartyId      INT
					);
		  INSERT INTO #Party
			(
			    PartyId, 
			    PartyName, 
			    BranchName, 
			    ParentId
			)
		  EXEC DBLIC.bodb_licensee.dbo.LA_PartyListSel;
		  INSERT INTO #PartyGroup
			(
			    PartyGroupId, 
			    PartyGroupName
			)
			    SELECT 
					 p.PartyId, 
					 p.PartyName
			    FROM #Party p
			    WHERE p.ParentId = 0;
		  INSERT INTO #DepositLicenseeProduct
			(
			    ProductId, 
			    LicenseeId, 
			    LicenseeName, 
			    PartyId
			)
			    SELECT DISTINCT 
					 lp3rd.ProductID, 
					 lp3rd.LicenseeId, 
					 l.LicenseeName, 
					 pt.PartyId
			    FROM(SELECT 
						 CASE
							WHEN ProductID = 14
							THEN 13
							ELSE ProductID
						 END AS ProductID, 
						 LicenseeId
				    FROM bodb_licensee.dbo.LicenseeProduct3rd WITH(NOLOCK)
				    WHERE ProductID IN
								  (
									 SELECT 
										   CASE
											  WHEN ProductId = 13
											  THEN 14
											  ELSE ProductId
										   END
									 FROM dbo.f_Nap_WinLimit_ProductSettingSel(@ProductId)
								   )) AS lp3rd
				   INNER JOIN bodb_licensee.dbo.Licensees l WITH(NOLOCK) ON l.LicenseeID = lp3rd.licenseeId
				   INNER JOIN DBLIC.bodb_licensee.dbo.OAS_Party pt WITH(NOLOCK) ON pt.OldRefID = lp3rd.licenseeId
																	  AND pt.PartyType = 1;


		  INSERT INTO #tplLicensee
			(
			    SiteId, 
			    SiteName, 
			    GroupName
			)
			    SELECT DISTINCT 
					 s.siteid, 
					 s.site, 
					 pg.PartyGroupName
			    FROM #DepositLicenseeProduct dlp
				    INNER JOIN #Party p ON dlp.PartyId = p.PartyId
				    INNER JOIN #PartyGroup pg ON p.ParentId = pg.PartyGroupId
				    INNER JOIN dbo.Site s WITH(NOLOCK) ON s.site = dlp.LicenseeName
												  AND S.isActive = 1
												  AND S.isLicensee = 1;



		  SELECT TOP 1 
			    @SiteId = w.SiteID
		  FROM [dbo].[WinLimit_ProductSettingDetail] w(NOLOCK)
			  INNER JOIN #tplLicensee s(NOLOCK) ON w.SiteID = s.siteid
		  WHERE w.ProductID = @ProductId
			   AND w.GroupID = @GroupId
		  GROUP BY 
				 w.SiteID
		  ORDER BY 
				 COUNT(1) DESC;
	   END;



	   UPDATE t
		SET 
		    t.IsBlockedPlaceBet = w.IsBlockedPlaceBet, 
		    t.IsBlockedTransfer = CASE
								WHEN s.isDeposit = 1
								THEN w.IsBlockedTransfer
								ELSE 0
							 END
	   FROM #tplCurrencySetting t
		   INNER JOIN [dbo].[WinLimit_ProductSettingDetail] w WITH(NOLOCK) ON t.ExchangeId = w.ExchangeID
		   INNER JOIN dbo.Site s(NOLOCK) ON s.siteid = w.SiteID
	   WHERE 
		    w.ProductID = @ProductId
		    AND w.SiteID = @SiteId
		    AND w.GroupID = @GroupId
		    AND w.LevelID = 3;

	   SELECT 
			t.ExchangeId, 
			e.currency, 
			t.Level1, 
			t.Level2, 
			t.Level3, 
			t.Level101, 
			t.Level102, 
			t.IsBlockedPlaceBet, 
			t.IsBlockedTransfer
	   FROM #tplCurrencySetting t
		   INNER JOIN dbo.exchange e WITH(NOLOCK) ON t.ExchangeId = e.ExchangeId;

	   DROP TABLE #tplCurrencySetting;
	   DROP TABLE #tplLicensee;
	   DROP TABLE #Party;
	   DROP TABLE #PartyGroup;
	   DROP TABLE #DepositLicenseeProduct;

    END;
GO