/*<info serverAlias="DBACC-bodb02" executers="wsv_xnap,wsv_alp,wsv_alpv" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_GetPTProductBySuper] 
	-- Add the parameters for the stored procedure here
	@Supers VARCHAR(MAX),
	@SettingStatus TINYINT = 0 
AS
/*
	Created: 20201020@Winfred
	DB: DBACC-bodb02
	Task: Get value PT setting product for customer

	Revisions:
		- 20201020@Winfred: Get value PT setting product for customer [Redmine: #139937]
		- 20201207@Winfred: Get value PT GDG for customer [Redmine: #144105]
		- 20201208@Winfred: Get value PT Leap Gaming VS3 for customer [Redmine: #131370]
		- 20201210@Tina: add BG (Big Gaming)
		- 20201230@Eden: Enhance Sp and include MaxGame [Redmine: #147232]
		- 20210302@Winfred: add Habanero  [RedmineID: #145459]
		- 20210324@Winfred: Get value PT Creative Gaming for customer [Redmine: #146016]
		- 20210426@Tina: Add VGaming [Redmine: #153938]
		- 20210506@Winfred: Get value PT  AdvantPlay for customer [Redmine: #154258]
		- 20210514@Winfred: Get value PT  AdvantPlay Mini for customer [Redmine: #155133]
		- 20210728@Winfred: Grant Permission Alpha [Redmine: #155133]
		- 20210809@Winfred: add Bitcoin Betting [RedmineID: #159039]
		- 20220317@Johnson: add FGG [redmine: #165682]
		- 20220110@Eden: Saba Casino use DCS Setting [RedmineID: #164280]
		- 20220912@Tacy: Add SEAL Entertainment [RedmineID: #176209]
		- 20220919@Tacy: Add Microgaming [RedmineID: #175853]
		- 20220921@Winfred:  Macau Game Setting Page - Rename the setting page into RNG Slot and hide all bet limit setting [Redmine: #174513]
		- 20221121@Eden: Unify RNG Lottery Customer Settings [RedmineID: #180640]
		- 202211201@Tacy: Non-sports products - Remove GDG and Fishing World [RedmineID: #174511]
		- 20230118@Helios: add JiliGame [RedmineId: #182869]
		- 20221123@Elodie: Migrate NG and Keno to DCS structure [Redmine: #179711]
		- 20230628@Tacy: NG2 - Remove Setting [Redmine: #189762]
		- 20230728@Eden: Simplify Live Casino Customer Setting [RedmineID: #189389]
		- 20230928@Luke: Modify SPs to adapt in-house replication setup [Redmine: #194414]
		- 20231113@Tacy: ExtNAP/Alpha - Return Offered product lists by site/currency [Redmine: #196141]
		- 20231206@Tacy: offer Saba Promotion, exclude 789y, 777 [Redmine: #194981]
		- 20231019@Helios: Customer Setting - Migrate Sportsbook to DCS [RedmineID: #193083] 
		- 20240316@Eden: Unify Live RNG Casino [Redmine: #198960]
		- 20240521@Helios: Unify RNG Games [Redmine: #204358]

	Param's Explanation:
	Example: EXEC EAS_GetPTProductBySuper @Supers = '45823486,45823577,45823478,44614982,33546025'
		
*/
BEGIN
	
	SET NOCOUNT ON;
	CREATE TABLE #tblCustomer(	CustID INT , 
								SportType SMALLINT DEFAULT(0),
								BetType SMALLINT DEFAULT(0),
								ProductID TINYINT DEFAULT(0),
								SuperPT SMALLMONEY DEFAULT(0),
								IsHidden BIT DEFAULT(0)
								)

	CREATE TABLE #Tmp_ProductProfile(	SportType SMALLINT,
								BetType SMALLINT ,
								ProductID TINYINT,
								RealProductID TINYINT)

	CREATE TABLE #Supers (CustID INT, Site VARCHAR(10)) 

	CREATE TABLE #SportBettypeDummy(RealProductId TINYINT, SportType SMALLINT,Bettype SMALLINT, ProductId TINYINT)

	--Live & RNG Casino
	INSERT INTO #SportBettypeDummy (RealProductId, SportType, Bettype, ProductId)  
	SELECT DISTINCT p.ProductID, s.SportType, s.BetType, s.DummyProductID  
	FROM f_CustSetting_Product (@SettingStatus) p   
	CROSS APPLY (	 SELECT s.RealProductId, s.SportTypeRefPT as SportType
					, s.BetTypeRefPT AS BetType  
					, s.ProductID AS DummyProductID  
					FROM f_CustSetting_SportBetTypeSettingMatrix (@SettingStatus) s  
					WHERE s.ProductID IN (53,41)  
						AND s.RealProductId=p.ProductID  
						AND s.isDeleted=0 AND s.isLicensee=0 AND s.Site = 'ALL'  
						AND s.SportType <> 242 --IBCBet Live Casino  
				) s 
	WHERE CasinoType IN (1,2) AND Enabled=1 AND GroupType=0  
	AND Environment <= @SettingStatus  

	UNION ALL

	-- RNG Games
	SELECT DISTINCT p.ProductID, s.SportType, s.BetType, s.DummyProductID  
	FROM f_CustSetting_Product (@SettingStatus) p   
	CROSS APPLY (	 SELECT s.RealProductId, s.SportTypeRefPT as SportType
					, s.BetTypeRefPT AS BetType  
					, s.ProductID AS DummyProductID  
					FROM f_CustSetting_SportBetTypeSettingMatrix (@SettingStatus) s  
					WHERE s.ProductID = 44
						AND s.RealProductId=p.ProductID  
						AND s.isDeleted=0 AND s.isLicensee=0 AND s.Site = 'ALL'  
				) s 
	WHERE Enabled=1 AND GroupType=0  
	AND Environment <= @SettingStatus  

	INSERT INTO #Supers(CustID)
	SELECT DISTINCT value
	FROM STRING_SPLIT(@Supers, ',') AS ss
	WHERE value <> ''
	OPTION (maxrecursion 0)    

	--update super's site
	UPDATE s
	SET s.Site=c.site
	FROM #Supers s 
	INNER JOIN Customer c WITH (NOLOCK) ON c.custid=s.CustID

	INSERT INTO #Tmp_ProductProfile( ProductID,SportType,BetType,RealProductID)
	SELECT ProductID,SportType,BetType,RealProductID
	FROM dbo.f_CustSetting_SportBetTypeSettingSelect(NULL,1,@SettingStatus)
	UNION ALL
	SELECT ProductID,SportType,BetType,RealProductID
	FROM dbo.f_CustSetting_SportBetTypeSettingSelect(NULL,18,@SettingStatus)
	UNION ALL
	SELECT ProductID,SportType,BetType,RealProductID
	FROM dbo.f_CustSetting_SportBetTypeSettingSelect(NULL,28,@SettingStatus)
	WHERE SportType = 9914 AND Bettype = 915

	-- Only get representation bettype for each sport of RNG Lottery, Live Casino
	;WITH tmp AS(
		SELECT  ProductID,SportType,BetType,RealProductID
			,RowNum = ROW_NUMBER() OVER ( PARTITION BY ProductID,Sporttype ORDER BY Bettype)
		FROM #Tmp_ProductProfile 
		WHERE ProductID IN (41,44)
	)
	DELETE t
	FROM #Tmp_ProductProfile t 
		INNER JOIN tmp ON t.ProductID = tmp.ProductID
			AND t.SportType = tmp.SportType
			AND t.BetType = tmp.BetType
	WHERE tmp.RowNum > 1

	-- DCS Setting
	INSERT INTO #tblCustomer (CustID,SportType,BetType,ProductID)
	SELECT s.CustID,b.SportType,b.BetType
		,CASE WHEN b.SportType=242 THEN 46 ELSE b.RealProductId END --IBCBet Live Casino
	FROM #Tmp_ProductProfile b
		CROSS APPLY #Supers s
	WHERE B.ProductID IN (41,53,42,44,66,69,64,6,5,1)

	--Get PT DCS
	UPDATE a
	SET a.SuperPT = cast(b.SuperPT AS SMALLMONEY) / 100,
		a.IsHidden = case when b.CustID IS NULL THEN 1 ELSE 0 END
	FROM #tblCustomer a
	LEFT JOIN CustPTSetting3rd_Agent b WITH(NOLOCK) 
				ON a.custID = b.CustID 
				AND a.BetType = b.BetType 
				AND a.SportType = b.SportType

	DELETE FROM #tblCustomer WHERE IsHidden = 1

	--Live & RNG Casino , RNG Games
	INSERT #tblCustomer(CustID,SportType,BetType,ProductID,SuperPT)
	SELECT ss.CustID, c.SportType, c.BetType, c.RealProductId, b.SuperPT
	FROM #Supers ss 
	INNER JOIN #tblCustomer b ON  ss.CustID = b.CustID
	INNER JOIN #SportBettypeDummy c WITH(NOLOCK)	
		ON  c.ProductId = b.ProductID 
		AND c.SportType = b.SportType 
		AND c.Bettype	= b.BetType 
	WHERE b.ProductID IN (41,53,44)
	
	SELECT a.CustID,a.SuperPT,a.ProductID,p.ProductName
	FROM #tblCustomer a 
		INNER JOIN f_CustSetting_Product (@SettingStatus)  p on a.ProductID = p.ProductID  
	WHERE a.ProductID NOT IN (41,53,44) -- Not show dummy product
		AND p.Environment <= @SettingStatus
	UNION
	SELECT s.CustID, 0 AS SuperPT, p.ProductID,p.ProductName
	FROM #Supers s
		CROSS APPLY (SELECT p.ProductID,p.ProductName 
					 FROM f_CustSetting_Product (@SettingStatus) p WHERE p.ProductID=37) p
	WHERE dbo.f_Age_OfferedProductBySite(s.Site)=1
	ORDER BY CustID, ProductID
	
	DROP TABLE #tblCustomer		
	DROP TABLE #Supers
	DROP TABLE #Tmp_ProductProfile
	DROP TABLE #SportBettypeDummy
END
GO