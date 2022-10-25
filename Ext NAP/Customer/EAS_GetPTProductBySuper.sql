/*<info serverAlias="DBACC-bodb02" executers="bodbExtAccNet,bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0"></info>*/
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

	Param's Explanation:
	Example: EXEC EAS_GetPTProductBySuper @Supers = '45823486,45823577,45823478,44614982,33546025'
		
*/
BEGIN
	
	SET NOCOUNT ON;
	CREATE TABLE #tblCustomer(	CustID INT , 
								SportType SMALLINT DEFAULT(0),
								BetType SMALLINT DEFAULT(0),
								ProductID TINYINT DEFAULT(0),
								SuperPT SMALLMONEY DEFAULT(0))

	CREATE TABLE #ProductSettingDetail(	SportType SMALLINT,
								BetType SMALLINT ,
								ProductID TINYINT,
								RealProductID TINYINT)

	CREATE TABLE #Supers (CustID INT) 

	INSERT INTO #Supers(CustID)
	SELECT value
	FROM STRING_SPLIT(@Supers, ',') AS ss
	WHERE value <> ''
	OPTION (maxrecursion 0)    

	INSERT INTO #ProductSettingDetail( ProductID,SportType,BetType,RealProductID)
	SELECT ProductID,SportType,BetType,CASE WHEN ProductID = 53 THEN ProductID ELSE RealProductId END AS RealProductID
	FROM dbo.f_CustSetting_SportBetTypeSettingSelect(NULL,1,@SettingStatus)
	UNION ALL
	SELECT ProductID,SportType,BetType,CASE WHEN ProductID = 53 THEN ProductID ELSE RealProductId END AS RealProductID
	FROM dbo.f_CustSetting_SportBetTypeSettingSelect(NULL,18,@SettingStatus)

	-- Only get representation bettype for each sport of RNG Lottery, Live Casino
	;WITH tmp AS(
		SELECT  ProductID,SportType,BetType,RealProductID
			,RowNum = ROW_NUMBER() OVER ( PARTITION BY ProductID,Sporttype ORDER BY Bettype)
		FROM #ProductSettingDetail 
		WHERE ProductID IN (41,44)
	)
	DELETE t
	FROM #ProductSettingDetail t 
		INNER JOIN tmp ON t.ProductID = tmp.ProductID
			AND t.SportType = tmp.SportType
			AND t.BetType = tmp.BetType
	WHERE tmp.RowNum > 1

	-- DCS Setting
	INSERT INTO #tblCustomer (CustID,SportType,BetType,ProductID)
	SELECT s.CustID,b.SportType,b.BetType,b.RealProductId
	FROM #ProductSettingDetail b
		CROSS APPLY #Supers s
	WHERE (B.ProductID IN (41,53,42,44,66,69,64,6) -- Live Casino, Macau Games , Saba.club, RNG Lottery, VGaming,Bitcoin,Virtual Games
			--or (B.ProductID IN (16) and SportType = 43 and BetType = 1) -- Sportsbook 2
			or (B.ProductID IN (5) and SportType = 180 and BetType = 1201) -- Virtual Sports
			or (B.ProductID IN (24) and SportType = 219 and BetType = 1011) -- Fishing World
			--or (B.ProductID IN (38) and SportType = 245 and BetType = 4601) -- Virtual Games
			or (B.ProductID IN (23) and SportType = 213 and BetType = 2501) -- NG2			
			)

	--Get PT DCS
	UPDATE a
	SET a.SuperPT = cast(b.SuperPT AS SMALLMONEY) / 100   
	FROM #tblCustomer a
	INNER JOIN CustPTSetting3rd_Agent b WITH(NOLOCK) ON a.custID = b.CustID 
						AND a.BetType = b.BetType AND a.SportType = b.SportType
	
	 -- On Macau Games(PP, Arcadia Gaming, SG, PG Soft, Joker, MaxGame, SEAL, Microgaming)
	INSERT #tblCustomer(CustID,SportType,BetType,ProductID,SuperPT)
	SELECT ss.CustID,c.SportType,c.BetType, c.RealProductId AS ProductID, b.SuperPT
	FROM #Supers ss 
	INNER JOIN #tblCustomer b ON  b.ProductID = 53 and b.SportType = 212 and ss.CustID = b.CustID
	INNER JOIN ProductSettingDetail c WITH(NOLOCK)	
		ON  c.SettingType = 8 AND c.ProductID = b.ProductID --AND c.SportType <> 212
	WHERE c.SettingStatus <= CASE WHEN @SettingStatus = 1 THEN 1 ELSE 0 END

	-- Non DCS Setting
	
	-- Sportsbook - Soccer
	INSERT #tblCustomer(CustID,SportType,BetType,ProductID,SuperPT)
	SELECT ss.CustID, b.BetType, b.SportType, 1 AS ProductID, b.spositiontaking
	FROM #Supers ss
		INNER JOIN CustSetting b WITH(NOLOCK) ON ss.CustID = b.CustID 
	WHERE b.BetType = 1 AND b.SportType = 1
	
	-- Number Game
	INSERT #tblCustomer(CustID,SportType,BetType,ProductID,SuperPT)
	SELECT ss.CustID, b.BetType, b.SportType, 3 AS ProductID, b.spositiontaking
	FROM #Supers ss
	INNER JOIN CustSetting3rd b WITH(NOLOCK) ON ss.CustID = b.CustID 
	WHERE b.BetType = 81 AND b.SportType = 161
	
	-- RNG Keno
	INSERT #tblCustomer(CustID,SportType,BetType,ProductID,SuperPT)
	SELECT ss.CustID ,cs.Sporttype, cs.Bettype, 8 AS ProductID, cs.spositiontaking AS SuperPT
	FROM #Supers ss
		INNER JOIN dbo.CustSettingGame cs WITH (NOLOCK) ON ss.CustID = cs.CustID 
	WHERE cs.Bettype = 1501 AND cs.Sporttype = 202
	
	SELECT a.CustID,a.SuperPT,a.ProductID,p.ProductName
	FROM #tblCustomer a 
		INNER JOIN Products  p WITH (NOLOCK) on a.ProductID = p.ProductID  
	ORDER BY a.CustID,a.ProductID
	
	DROP TABLE #tblCustomer							
END
GO
