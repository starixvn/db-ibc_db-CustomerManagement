/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap" viewers="" isFunction="0" isNested="0"></info>*/

ALTER PROC NAP_CWL_Initialize_Settings 
	@ProductID                              INT
   , @BetTypeID_Begin                        INT
   , @BetTypeID_End                          INT
   , @BettypeIDs                             VARCHAR(2000) = ''
   , @RepresentativeBettype				INT		    
   , @GroupID                                INT
   , @GroupName                              VARCHAR(200)
   , @IsDeposit                              BIT = 0
   , @Level1                                 MONEY         = 10000
   , @Level2                                 MONEY         = 30000
   , @Level3                                 MONEY         = 100000
   , @Level101                               MONEY         = -10000
   , @Level102                               MONEY         = -30000  
   , @Currency						     	 VARCHAR(MAX)  = ''
   , @IsBlockedPlaceBet_DepositSite_Level1   BIT           = 0
   , @IsBlockedPlaceBet_DepositSite_Level2   BIT           = 0
   , @IsBlockedPlaceBet_DepositSite_Level3   BIT           = 0
   , @IsBlockedPlaceBet_DepositSite_Level101 BIT           = 0
   , @IsBlockedPlaceBet_DepositSite_Level102 BIT           = 0
   , @IsBlockedPlaceBet_CreditSite_Level1    BIT           = 0
   , @IsBlockedPlaceBet_CreditSite_Level2    BIT           = 0
   , @IsBlockedPlaceBet_CreditSite_Level3    BIT           = 0
   , @IsBlockedPlaceBet_CreditSite_Level101  BIT           = 0
   , @IsBlockedPlaceBet_CreditSite_Level102  BIT           = 0
   , @IsBlockedTransfer_DepositSite_Level1   BIT           = 0
   , @IsBlockedTransfer_DepositSite_Level2   BIT           = 0
   , @IsBlockedTransfer_DepositSite_Level3   BIT           = 0
   , @IsBlockedTransfer_DepositSite_Level101 BIT           = 0
   , @IsBlockedTransfer_DepositSite_Level102 BIT           = 0
   , @IsBlockedTransfer_CreditSite_Level1    BIT           = 0
   , @IsBlockedTransfer_CreditSite_Level2    BIT           = 0
   , @IsBlockedTransfer_CreditSite_Level3    BIT           = 0
   , @IsBlockedTransfer_CreditSite_Level101  BIT           = 0
   , @IsBlockedTransfer_CreditSite_Level102  BIT           = 0
   , @IsSuspendedAccount_DepositSite_Level1   BIT          = 0
   , @IsSuspendedAccount_DepositSite_Level2   BIT          = 0
   , @IsSuspendedAccount_DepositSite_Level3   BIT          = 0
   , @IsSuspendedAccount_DepositSite_Level101 BIT          = 0
   , @IsSuspendedAccount_DepositSite_Level102 BIT          = 0
   , @IsSuspendedAccount_CreditSite_Level1    BIT          = 0
   , @IsSuspendedAccount_CreditSite_Level2    BIT          = 0
   , @IsSuspendedAccount_CreditSite_Level3    BIT          = 0
   , @IsSuspendedAccount_CreditSite_Level101  BIT          = 0
   , @IsSuspendedAccount_CreditSite_Level102  BIT          = 0
AS

/*	Creator	 : 20180319@Robert
	Task		 : Initialize CWL Settings [#91762]
	DB		 : DBCUST/CustDB
	
	Revisions	 : 
				- 20180319@Robert: Initialize CWL Settings
				- 20181108@Elodie: Migrate bodb_Licensee to DBCUST [Redmine:#99855]
				- 20191103@Robert: create new table WinLimit_ProductOffer [#122849]				
				- 20220223@Johnson: Global setting by currency [#168583]
				- 20220614@Eden: DBCUST - modify sp syntax to adapt with the SQL Server upgrade to 2019 [Redmine: #171831] 
				- 20220804@Johnson: call sp NAP_CWL_ProductOffer_Initialize_Settings manually to scale out [redmine: #175278]
				- 20230914@Johnson: Add IsDeposit to separate credit & deposit global setting [redmine:#193708]
				- 20231002@Tacy: CWL - Suspend member accounts when member reaches Yellow level on RNG Slots Games [RedmineID: #184911]
				- 20231215@Tacy: CWL - Not apply suspended account for UUS [RedmineID: #195092]

     Ex		 :

     EXEC NAP_CWL_Initialize_Settings 
         @ProductID = 27, 
         @BetTypeID_Begin = 2801, 
         @BetTypeID_End = 2812, 
         @GroupID = 12, 
         @GroupName = 'Virtual Sports2', 
         @Level1 = 100000, 
         @Level2 = 300000, 
         @Level3 = 500000, 
         @Level101 = -100000, 
         @Level102 = -300000;
		
*/

BEGIN
    SET NOCOUNT ON;

    CREATE TABLE #Currency_Deposit(
	    siteid     INT
	  , exchangeid INT
	  , PRIMARY KEY(siteid, exchangeid));

    CREATE TABLE #Temp(
	    ProductID INT
	  , BetTypeID INT
	  , GroupID   INT
	  , GroupName VARCHAR(200));

    DECLARE @bettype INT;

    DECLARE @tbSuspendedSites TABLE (SiteID INT);
	
	DECLARE @tmpCurrency TABLE(
		Currency INT		
	)
	
    DECLARE @LicenseeCust TABLE(
	    LicenseeID INT
	  , Currency   INT);

    DECLARE @Licensees TABLE(
	    LicenseeID   INT
	  , LicenseeName VARCHAR(50));

    DECLARE @LevelSettings TABLE(
	    LevelId                       INT
	  , Level                         MONEY
	  , IsBlockedPlaceBet_DepositSite BIT
	  , IsBlockedPlaceBet_CreditSite  BIT
	  , IsBlockedTransfer_DepositSite BIT
	  , IsBlockedTransfer_CreditSite  BIT
	  , IsSuspendedAccount_DepositSite BIT
	  , IsSuspendedAccount_CreditSite  BIT);

	--List sites: apply suspend account
	INSERT INTO @tbSuspendedSites (SiteID)
	SELECT SiteID FROM f_NAP_CWL_SuspendedSite() 

    INSERT INTO @LevelSettings(LevelId
					    , Level
					    , IsBlockedPlaceBet_DepositSite
					    , IsBlockedPlaceBet_CreditSite
					    , IsBlockedTransfer_DepositSite
					    , IsBlockedTransfer_CreditSite
						, IsSuspendedAccount_DepositSite
						, IsSuspendedAccount_CreditSite)
		 SELECT 1 AS                                     LevelId
			 , @Level1 AS                               Level
			 , @IsBlockedPlaceBet_DepositSite_Level1 AS IsBlockedPlaceBet_DepositSite
			 , @IsBlockedPlaceBet_CreditSite_Level1 AS  IsBlockedPlaceBet_CreditSite
			 , @IsBlockedTransfer_DepositSite_Level1 AS IsBlockedTransfer_DepositSite
			 , @IsBlockedTransfer_CreditSite_Level1 AS  IsBlockedTransfer_CreditSite
			 , @IsSuspendedAccount_DepositSite_Level1 AS IsSuspendedAccount_DepositSite
			 , @IsSuspendedAccount_CreditSite_Level1 AS  IsSuspendedAccount_CreditSite
		 UNION ALL
		 SELECT 2 AS                                     LevelId
			 , @Level2 AS                               Level
			 , @IsBlockedPlaceBet_DepositSite_Level2 AS IsBlockedPlaceBet_DepositSite
			 , @IsBlockedPlaceBet_CreditSite_Level2 AS  IsBlockedPlaceBet_CreditSite
			 , @IsBlockedTransfer_DepositSite_Level2 AS IsBlockedTransfer_DepositSite
			 , @IsBlockedTransfer_CreditSite_Level2 AS  IsBlockedTransfer_CreditSite
			 , @IsSuspendedAccount_DepositSite_Level2 AS IsSuspendedAccount_DepositSite
			 , @IsSuspendedAccount_CreditSite_Level2 AS  IsSuspendedAccount_CreditSite
		 UNION ALL
		 SELECT 3 AS                                     LevelId
			 , @Level3 AS                               Level
			 , @IsBlockedPlaceBet_DepositSite_Level3 AS IsBlockedPlaceBet_DepositSite
			 , @IsBlockedPlaceBet_CreditSite_Level3 AS  IsBlockedPlaceBet_CreditSite
			 , @IsBlockedTransfer_DepositSite_Level3 AS IsBlockedTransfer_DepositSite
			 , @IsBlockedTransfer_CreditSite_Level3 AS  IsBlockedTransfer_CreditSite
			 , @IsSuspendedAccount_DepositSite_Level3 AS IsSuspendedAccount_DepositSite
			 , @IsSuspendedAccount_CreditSite_Level3 AS  IsSuspendedAccount_CreditSite
		 UNION ALL
		 SELECT 101 AS                                     LevelId
			 , @Level101 AS                               Level
			 , @IsBlockedPlaceBet_DepositSite_Level101 AS IsBlockedPlaceBet_DepositSite
			 , @IsBlockedPlaceBet_CreditSite_Level101 AS  IsBlockedPlaceBet_CreditSite
			 , @IsBlockedTransfer_DepositSite_Level101 AS IsBlockedTransfer_DepositSite
			 , @IsBlockedTransfer_CreditSite_Level101 AS  IsBlockedTransfer_CreditSite
			 , @IsSuspendedAccount_DepositSite_Level101 AS IsSuspendedAccount_DepositSite
			 , @IsSuspendedAccount_CreditSite_Level101 AS  IsSuspendedAccount_CreditSite
		 UNION ALL
		 SELECT 102 AS                                     LevelId
			 , @Level102 AS                               Level
			 , @IsBlockedPlaceBet_DepositSite_Level102 AS IsBlockedPlaceBet_DepositSite
			 , @IsBlockedPlaceBet_CreditSite_Level102 AS  IsBlockedPlaceBet_CreditSite
			 , @IsBlockedTransfer_DepositSite_Level102 AS IsBlockedTransfer_DepositSite
			 , @IsBlockedTransfer_CreditSite_Level102 AS  IsBlockedTransfer_CreditSite
			 , @IsSuspendedAccount_DepositSite_Level102 AS IsSuspendedAccount_DepositSite
			 , @IsSuspendedAccount_CreditSite_Level102 AS  IsSuspendedAccount_CreditSite;
	
	
	INSERT INTO @tmpCurrency(Currency)
	SELECT e.ExchangeID
	FROM STRING_SPLIT(@currency, ',') t
		INNER JOIN  exchange e WITH(NOLOCK) ON t.value = e.currency
	WHERE t.value <> ''
	
	IF NOT EXISTS (SELECT 1 FROM @tmpCurrency)
	INSERT INTO @tmpCurrency(Currency)
	SELECT 0--all currencies
	
    INSERT INTO @LicenseeCust(LicenseeID
					   , Currency)
		 SELECT DISTINCT 
			   LicenseeID
			 , Currency
		 FROM bodb_licensee.dbo.LicenseeCust AS lc;

    INSERT INTO @Licensees(LicenseeID
					, LicenseeName)
		 SELECT LicenseeID
			 , LicenseeName
		 FROM bodb_licensee.dbo.Licensees;


    INSERT INTO #Currency_Deposit(siteid
						  , exchangeid)
		 SELECT DISTINCT 
			   s.siteid
			 , lc.Currency AS Id
		 FROM @LicenseeCust AS lc
				 INNER JOIN @Licensees AS l
				   ON l.LicenseeID = lc.LicenseeID
				 INNER JOIN dbo.site AS s WITH (NOLOCK)
				   ON s.site = l.LicenseeName
					 AND S.isActive = 1
		 WHERE lc.Currency NOT IN(27, 28);

    WITH CTE_BettypeRanges
	    AS (SELECT BettypeId = ROW_NUMBER() OVER(ORDER BY(SELECT NULL))
		   FROM(VALUES(0), (0), (0), (0), (0), (0), (0), (0), (0), (0)) AS x10(x)
				  CROSS JOIN(VALUES(0), (0), (0), (0), (0), (0), (0), (0), (0), (0)) AS x100(x) 
				  CROSS JOIN(VALUES(0), (0), (0), (0), (0), (0), (0), (0), (0), (0)) AS x1000(x) 
				  CROSS JOIN(VALUES(0), (0), (0), (0), (0), (0), (0), (0), (0), (0)) AS x10000(x) 
				  CROSS JOIN(VALUES(0), (0), (0), (0), (0), (0), (0), (0), (0), (0)) AS x100000(x))

	    INSERT INTO #Temp(ProductID
					, BetTypeID
					, GroupID
					, GroupName)
			 SELECT ProductID
				 , BettypeId
				 , GroupID
				 , GroupName
			 FROM CTE_BettypeRanges
					 CROSS JOIN
			 (
				SELECT @ProductID AS ProductID
					, @GroupID AS   GroupID
					, @GroupName AS GroupName
			 ) AS ProductGroup
			 WHERE BettypeId BETWEEN @BetTypeID_Begin AND @BetTypeID_End;

    INSERT INTO #Temp(ProductID
				, BetTypeID
				, GroupID
				, GroupName)
		 SELECT settings.ProductID
			 , value AS BettypeID
			 , settings.GroupID
			 , settings.GroupName
		 FROM STRING_SPLIT(@BettypeIDs, ',')
				 CROSS APPLY
		 (
			SELECT @ProductID AS ProductID
				, @GroupID AS   GroupID
				, @GroupName AS GroupName
		 ) AS settings
		 WHERE value > 0;

    DELETE FROM #Temp
    WHERE BetTypeID = 0;

    INSERT INTO Winlimit_Group(GroupID
					    , GroupName)
		 SELECT DISTINCT 
			   t.GroupID
			 , t.GroupName
		 FROM #Temp AS t
		 WHERE NOT EXISTS
		 (
			SELECT g.GroupID
			FROM Winlimit_Group AS g WITH (NOLOCK)
			WHERE t.GroupID = g.GroupID
		 );

    INSERT INTO Winlimit_ProductSetting(ProductID
							   , BettypeID
							   , LevelID
							   , SettingStatus)
		 SELECT b.ProductID
			 , b.BetTypeID
			 , l.LevelID
			 , 0 AS SettingStatus
		 FROM
		 (
			SELECT ProductID
				, MIN(BetTypeID) AS BetTypeID
			FROM #Temp
			GROUP BY ProductID
		 ) AS b, 
		 (SELECT * FROM Winlimit_LevelSetting WHERE LevelID <=200) AS l
		 WHERE NOT EXISTS
		 (
			SELECT t.BettypeID
			FROM Winlimit_ProductSetting AS t WITH (NOLOCK)
			WHERE b.ProductID = t.ProductID
		 );


    INSERT INTO dbo.Winlimit_GameGroupSetting(ProductID
								    , BetTypeID
								    , GroupID)
		 SELECT DISTINCT 
			   t.ProductID
			 , t.BetTypeID
			 , t.GroupID
		 FROM #Temp AS t
		 WHERE NOT EXISTS
		 (
			SELECT g.BetTypeID
			FROM Winlimit_GameGroupSetting AS g WITH (NOLOCK)
			WHERE t.ProductID = g.ProductID
				 AND t.BetTypeID = g.BetTypeID
				 AND t.GroupID = g.GroupID
		 );

    INSERT INTO Winlimit_ProductGlobalSetting(ProductID
								    , BetTypeID
								    , GroupID
								    , GroupName
								    , Level1
								    , Level2
								    , Level3
								    , Level101
								    , Level102
								    , blockedTransferLvl3
									, Currency
									, IsDeposit)
		 SELECT DISTINCT t.ProductID
			 , t.BetTypeID
			 , t.GroupID
			 , t.GroupName
			 , @Level1 AS                               Level1
			 , @Level2 AS                               Level2
			 , @Level3 AS                               Level3
			 , @Level101 AS                             Level101
			 , @Level102 AS                             Level102
			 , @IsBlockedTransfer_DepositSite_Level3 AS BlockedTransferLv3
			 , c.Currency
			 , @IsDeposit
		 FROM #Temp AS t
			CROSS APPLY @tmpCurrency c
		 WHERE t.BetTypeID =
		 (
			SELECT MIN(BetTypeID)
			FROM #Temp
		 )
			  AND NOT EXISTS
		 (
			SELECT setting.BetTypeID
			FROM Winlimit_ProductGlobalSetting AS setting WITH (NOLOCK)
			WHERE t.ProductID = setting.ProductID
				 AND t.GroupID = setting.GroupID
				 AND t.GroupName = setting.GroupName
				 AND c.Currency = setting.Currency
				 AND setting.IsDeposit = @IsDeposit
		 );
		
    ;WITH CTE_ProductSettingDetail
	    AS (SELECT p.ProductID
			   , p.GroupId
			   , e.exchangeid
			   , s.siteid
			   , l.LevelID
			   , 0 AS       MaxWinLimit
			   , CASE
				    WHEN s.isLicensee = 1
				    THEN l.IsBlockedPlaceBet_DepositSite
				    ELSE l.IsBlockedPlaceBet_CreditSite
				END AS     IsBlockedPlaceBet
			   , CASE
				    WHEN s.isLicensee = 1
				    THEN l.IsBlockedTransfer_DepositSite
				    ELSE l.IsBlockedTransfer_CreditSite
				END AS     IsBlockedTransfer
			   , CASE
				    WHEN s.isLicensee = 1
				    THEN l.IsSuspendedAccount_DepositSite
					WHEN s.siteid IN (SELECT ss.SiteID FROM @tbSuspendedSites ss) 
						AND l.LevelId BETWEEN 2 AND 100	--WinLevel
						AND e.ExchangeId<>20
						THEN l.IsSuspendedAccount_CreditSite
					ELSE 0
				END AS     IsSuspendedAccount
			   , l.Level AS MaxWinLimit_RM
			   , e.actualrate
		   FROM exchange AS e WITH (NOLOCK), 
		   (
			  SELECT DISTINCT 
				    ProductID
				  , GroupID
			  FROM #Temp
		   ) AS p, 
		   (
			  SELECT LevelID
				  , Level
				  , IsBlockedPlaceBet_DepositSite
				  , IsBlockedPlaceBet_CreditSite
				  , IsBlockedTransfer_DepositSite
				  , IsBlockedTransfer_CreditSite
				  , IsSuspendedAccount_DepositSite
				  , IsSuspendedAccount_CreditSite
			  FROM @LevelSettings
		   ) AS l, 
			   Site AS s
		   WHERE e.currency NOT IN('H', 'C')
				AND EXISTS (SELECT 1 FROM @tmpCurrency t WHERE currency = 0 OR e.Exchangeid = t.currency)
			    AND s.isActive = 1
			    AND ((s.isLicensee = 1 
					AND @IsDeposit = 1
				    AND e.exchangeid IN
				   (
					  SELECT exchangeid
					  FROM #Currency_Deposit
					  WHERE siteid = s.siteid
				   ))
				    OR (s.isLicensee = 0
					AND @IsDeposit = 0	
				    AND e.exchangeid IN
				   (
					  SELECT Id
					  FROM f_Nap_WinLimit_CreditCurrencySel()
				   ))))

	    INSERT INTO WinLimit_ProductSettingDetail(ProductID
									    , GroupID
									    , ExchangeID
									    , SiteID
									    , LevelID
									    , IsBlockedPlaceBet
									    , IsBlockedTransfer
										, IsSuspendedAccount
									    , MaxWinLimit_RM
									    , MaxWinLimit)
			 SELECT setting.ProductID
				 , setting.GroupID
				 , setting.exchangeid
				 , setting.siteid
				 , setting.LevelID
				 , setting.IsBlockedPlaceBet
				 , setting.IsBlockedTransfer
				 , setting.IsSuspendedAccount
				 , setting.MaxWinLimit_RM
				 , CASE
					  WHEN setting.exchangeid = 20
					  THEN setting.MaxWinLimit_RM
					  ELSE ROUND(setting.MaxWinLimit_RM / setting.ActualRate, 2)
				   END AS MaxWinLimit
			 FROM
			 (
				SELECT ProductId
					, GroupId
					, ExChangeId
					, SiteId
					, LevelId
					, MaxWinLimit_RM
					, IsBlockedPlaceBet
					, IsBlockedTransfer
					, IsSuspendedAccount
					, ActualRate
				FROM CTE_ProductSettingDetail
			 ) AS setting
			 WHERE NOT EXISTS
			 (
				SELECT d.ExchangeID
				FROM WinLimit_ProductSettingDetail AS d WITH (NOLOCK)
				WHERE setting.ProductID = d.ProductID
					 AND setting.GroupID = d.GroupID
					 AND setting.exchangeid = d.ExchangeID
					 AND setting.siteid = d.SiteID
					 AND setting.LevelId = d.LevelID
			 )
			 ORDER BY setting.LevelID
				   , setting.siteid
				   , setting.exchangeid;

    SELECT GroupID
	    , GroupName
    FROM Winlimit_Group WITH (NOLOCK)
    WHERE GroupID = @GroupID;

    SELECT ProductID
	    , BetTypeID
	    , GroupID
    FROM Winlimit_GameGroupSetting WITH (NOLOCK)
    WHERE ProductID = @ProductID
		AND BetTypeID IN(SELECT BetTypeID FROM #Temp);

    SELECT ProductID
	    , GroupID
	    , ExchangeID
	    , SiteID
	    , LevelID
	    , MaxWinLimit
	    , IsBlockedPlaceBet
	    , IsBlockedTransfer
		, IsSuspendedAccount
	    , MaxWinLimit_RM
    FROM WinLimit_ProductSettingDetail cs WITH (NOLOCK)
    WHERE ProductID = @ProductID
		AND GroupID = @GroupID
		AND EXISTS (SELECT 1 FROM @tmpCurrency t WHERE currency = 0 OR cs.Exchangeid = t.currency);

    SELECT ProductID
	    , BettypeID
	    , LevelID
	    , SettingStatus
    FROM Winlimit_productsetting WITH (NOLOCK)
    WHERE ProductID = @ProductID
		AND BettypeID IN(SELECT BetTypeID FROM #Temp);

    SELECT ProductID
	    , BetTypeID
	    , GroupID
	    , GroupName
	    , Level1
	    , Level2
	    , Level3
	    , Level101
	    , Level102
    FROM Winlimit_ProductGlobalSetting AS setting WITH (NOLOCK)
    WHERE EXISTS
    (
	   SELECT t.BetTypeID
	   FROM #Temp AS t WITH (NOLOCK)
	   WHERE t.ProductID = setting.ProductID
		    AND t.GroupID = setting.GroupID
		    AND t.GroupName = setting.GroupName
    )
	AND EXISTS (SELECT 1 FROM @tmpCurrency t WHERE currency = 0 OR Setting.Currency = t.currency);

  
	EXEC dbo.NAP_CWL_Update_Settings 
	@ProductId    = @ProductID
  , @GroupId      = @GroupID
  , @Level1       = @Level1
  , @Level2       = @Level2
  , @Level3       = @Level3
  , @Level101     = @Level101
  , @Level102     = @Level102
  , @Currency	   = @Currency
  , @IsDeposit	   = @IsDeposit
    
    DROP TABLE #Temp;
    DROP TABLE #Currency_Deposit;
END;
GO
