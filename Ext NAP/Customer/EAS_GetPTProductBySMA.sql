/*<info serverAlias="DBACC-bodb02" executers="bodbExtAccNet,bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[EAS_GetPTProductBySMA] 
	-- Add the parameters for the stored procedure here
	@CustIds VARCHAR(MAX),
	@SettingStatus TINYINT = 0 
AS
/*
	Created: 20211105@Winfred
	DB: DBACC-bodb02
	Task: Get value PT setting product for customer SMA

	Revisions:
		- 20211105@Winfred: Get value PT setting product for customer SMA [Redmine: #159664]
		- 20220509@Winfred: Hotfix miss Get value PT FGG And vitual games [Redmine: #159664]
		- 20220110@Eden: Saba Casino use DCS Setting [RedmineID: #164280]
		- 20220922@Tacy: add SEAL Entertainment [RedmineId: #176209]
		- 20220922@Tacy: add Microgaming [RedmineId: #175853]
		- 20220921@Winfred:  Macau Game Setting Page - Rename the setting page into RNG Slot and hide all bet limit setting [Redmine: #174513]

	Param's Explanation:
	- @CustIds = '45823486,45823577,45823478,44614982,33546025'="45823478" roleid="3"/>
						</ROOT>'
	Example: EXEC EAS_GetPTProductBySMA @CustIds = '45823486,45823577,45823478,44614982,33546025'
		
*/
BEGIN
	
	SET NOCOUNT ON;
	CREATE TABLE #tblCustomer(	CustID INT , 
								SportType SMALLINT DEFAULT(0),
								BetType SMALLINT DEFAULT(0),
								ProductID TINYINT DEFAULT(0),
								ValuePT SMALLMONEY DEFAULT(0),
								roleid TINYINT)

	CREATE TABLE #ProductSettingDetail(	SportType SMALLINT,
								BetType SMALLINT ,
								ProductID TINYINT,
								RealProductID TINYINT)

	CREATE TABLE #SMATemp (CustID INT,roleid	TINYINT) 

	INSERT INTO #SMATemp(CustID)
	SELECT DISTINCT value
	FROM STRING_SPLIT(@CustIds, ',') AS ss
	WHERE value <> ''
	OPTION (maxrecursion 0)  
	
	UPDATE s
	SET s.roleid = ci.roleid
	FROM #SMATemp s
		INNER JOIN custInfo ci WITH(NOLOCK) ON s.CustID = ci.custid
	
	INSERT INTO #ProductSettingDetail( ProductID,SportType,BetType,RealProductID)
	SELECT ProductID,SportType,BetType,RealProductID
	FROM dbo.f_CustSetting_SportBetTypeSettingSelect(NULL,1,@SettingStatus)
	UNION ALL
	SELECT ProductID,SportType,BetType,RealProductID
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
	INSERT INTO #tblCustomer (CustID,SportType,BetType,ProductID,roleid)
	SELECT s.CustID,b.SportType,b.BetType,b.RealProductId,s.roleid
	FROM #ProductSettingDetail b
		CROSS APPLY #SMATemp s
	WHERE (B.ProductID IN (41,53,42,44,66,69,64,6) -- Live Casino, Macau Games , Saba.club, RNG Lottery, VGaming,Bitcoin,Virtual Games , FGG
			--or (B.ProductID IN (16) and SportType = 43 and BetType = 1) -- Sportsbook 2
			or (B.ProductID IN (5) and SportType = 180 and BetType = 1201) -- Virtual Sports
			or (B.ProductID IN (24) and SportType = 219 and BetType = 1011) -- Fishing World
			--or (B.ProductID IN (38) and SportType = 245 and BetType = 4601) -- Virtual Games
			or (B.ProductID IN (23) and SportType = 213 and BetType = 2501) -- NG2			
			)

	--Get PT DCS
	UPDATE a
	SET a.ValuePT = CASE WHEN a.roleid = 4 THEN cast(b.SuperPT AS SMALLMONEY) / 100  
						WHEN a.roleid = 3 THEN cast(b.MasterPT AS SMALLMONEY) / 100 
						WHEN a.roleid = 2 THEN cast(b.AgentPT AS SMALLMONEY) / 100 
						ELSE cast(b.SuperPT AS SMALLMONEY) / 100  END
	FROM #tblCustomer a
	INNER JOIN CustPTSetting3rd_Agent b WITH(NOLOCK) ON a.custID = b.CustID 
						AND a.BetType = b.BetType AND a.SportType = b.SportType
	
	 -- On Macau Games(PP, Arcadia Gaming, SG, PG Soft, Joker, MaxGame, SEAL, Microgaming)
	INSERT #tblCustomer(CustID,SportType,BetType,ProductID,ValuePT,roleid)
	SELECT ss.CustID,c.SportType,c.BetType,c.RealProductId AS ProductID, b.ValuePT,ss.roleid
	FROM #SMATemp ss 
	INNER JOIN #tblCustomer b ON  b.ProductID = 53 and b.SportType = 212 and ss.CustID = b.CustID
	INNER JOIN ProductSettingDetail c WITH(NOLOCK)	
		ON  c.SettingType = 8 AND c.ProductID = b.ProductID AND c.SportType <> 212
	WHERE c.SettingStatus <= CASE WHEN @SettingStatus = 1 THEN 1 ELSE 0 END

	-- Non DCS Setting
	
	-- Sportsbook - Soccer
	INSERT #tblCustomer(CustID,SportType,BetType,ProductID,ValuePT,roleid)
	SELECT ss.CustID, b.BetType, b.SportType, 1 AS ProductID, 
					CASE WHEN ss.roleid = 4 THEN b.spositiontaking 
						WHEN ss.roleid = 3 THEN b.mpositiontaking
						WHEN ss.roleid = 2 THEN b.apositiontaking
						ELSE b.spositiontaking END AS ValuePT,ss.roleid
	FROM #SMATemp ss
		INNER JOIN CustSetting b WITH(NOLOCK) ON ss.CustID = b.CustID 
	WHERE b.BetType = 1 AND b.SportType = 1
	
	-- Number Game
	INSERT #tblCustomer(CustID,SportType,BetType,ProductID,ValuePT,roleid)
	SELECT ss.CustID, b.BetType, b.SportType, 3 AS ProductID, 
				   CASE WHEN ss.roleid = 4 THEN b.spositiontaking 
						WHEN ss.roleid = 3 THEN b.mpositiontaking
						WHEN ss.roleid = 2 THEN b.apositiontaking
						ELSE b.spositiontaking END AS ValuePT,ss.roleid
	FROM #SMATemp ss
	INNER JOIN CustSetting3rd b WITH(NOLOCK) ON ss.CustID = b.CustID 
	WHERE b.BetType = 81 AND b.SportType = 161
	
	-- RNG Keno
	INSERT #tblCustomer(CustID,SportType,BetType,ProductID,ValuePT,roleid)
	SELECT ss.CustID ,cs.Sporttype, cs.Bettype, 8 AS ProductID,  
				   CASE WHEN ss.roleid = 4 THEN cs.spositiontaking 
						WHEN ss.roleid = 3 THEN cs.mpositiontaking
						WHEN ss.roleid = 2 THEN cs.apositiontaking
						ELSE cs.spositiontaking END AS ValuePT,ss.roleid
	FROM #SMATemp ss
		INNER JOIN dbo.CustSettingGame cs WITH (NOLOCK) ON ss.CustID = cs.CustID 
	WHERE cs.Bettype = 1501 AND cs.Sporttype = 202
	
	-- Gold Deluxe
	--INSERT #tblCustomer(CustID,SportType,BetType,ProductID,ValuePT,roleid)
	--SELECT ss.CustID, cs.Sporttype, cs.Bettype, 12 AS ProductID,   
	--			   CASE WHEN ss.roleid = 4 THEN cs.spositiontaking 
	--					WHEN ss.roleid = 3 THEN cs.mpositiontaking
	--					WHEN ss.roleid = 2 THEN cs.apositiontaking
	--					ELSE cs.spositiontaking END AS ValuePT,ss.roleid
	--FROM #SMATemp ss
	--INNER JOIN dbo.CustSettingGame cs WITH(NOLOCK) ON ss.CustID = cs.CustID 
	--WHERE  cs.sporttype = 255 AND cs.bettype = 1701
	
	SELECT a.CustID ,a.ValuePT,a.ProductID
	FROM #tblCustomer a
	ORDER BY a.CustID,a.ProductID
	
	DROP TABLE #tblCustomer							
END
GO
