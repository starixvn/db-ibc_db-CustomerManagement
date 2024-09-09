/*<info serverAlias="DBACC-bodb02" executers="wsv_xnap,wsv_alp,wsv_alpv" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_GetPTProductBySMA] 
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
		- 20221121@Eden: Unify RNG Lottery Customer Settings [RedmineID: #180640]
		- 20230118@Helios: add JiliGame [RedmineId: #182869]
		- 20221120@Tacy: Non-sports products - Remove GDG and Fishing World [RedmineID: #174511]
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
								roleid TINYINT,
								IsHidden BIT DEFAULT(0))

	CREATE TABLE #Tmp_ProductProfile(	SportType SMALLINT,
								BetType SMALLINT ,
								ProductID TINYINT,
								RealProductID TINYINT)

	CREATE TABLE #SMATemp (CustID INT, roleid TINYINT, Site VARCHAR(10)) 

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
	--RNG Games
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

	INSERT INTO #SMATemp(CustID)
	SELECT DISTINCT value
	FROM STRING_SPLIT(@CustIds, ',') AS ss
	WHERE value <> ''
	OPTION (maxrecursion 0)  
	
	UPDATE s
	SET s.roleid = c.roleid, s.Site=c.site
	FROM #SMATemp s
		INNER JOIN Customer c WITH(NOLOCK) ON s.CustID = c.custid
	
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
	INSERT INTO #tblCustomer (CustID,SportType,BetType,ProductID,roleid)
	SELECT s.CustID,b.SportType,b.BetType
		,CASE WHEN b.SportType=242 THEN 46 ELSE b.RealProductId END --IBCBet Live Casino
		,s.roleid
	FROM #Tmp_ProductProfile b
		CROSS APPLY #SMATemp s
	WHERE B.ProductID IN (41,53,42,44,66,69,64,6,5,1) 

	--Get PT DCS
	UPDATE a
	SET a.ValuePT = CASE WHEN a.roleid = 4 THEN cast(b.SuperPT AS SMALLMONEY) / 100  
						WHEN a.roleid = 3 THEN cast(b.MasterPT AS SMALLMONEY) / 100 
						WHEN a.roleid = 2 THEN cast(b.AgentPT AS SMALLMONEY) / 100 
						ELSE cast(b.SuperPT AS SMALLMONEY) / 100  END,
		a.IsHidden = case when b.CustID IS NULL THEN 1 ELSE 0 END
	FROM #tblCustomer a
	LEFT JOIN CustPTSetting3rd_Agent b WITH(NOLOCK) 
		ON a.custID = b.CustID 
		AND a.BetType = b.BetType 
		AND a.SportType = b.SportType

	DELETE FROM #tblCustomer WHERE IsHidden = 1
	
	--Live & RNG Casino , RNG Games
	INSERT #tblCustomer(CustID,SportType,BetType,ProductID,ValuePT,roleid)
	SELECT ss.CustID, c.SportType, c.BetType, c.RealProductId, b.ValuePT, ss.roleid
	FROM #SMATemp ss 
	INNER JOIN #tblCustomer b ON  ss.CustID = b.CustID
	INNER JOIN #SportBettypeDummy c WITH(NOLOCK)	
		ON  c.ProductId = b.ProductID 
		AND c.SportType = b.SportType 
		AND c.Bettype	= b.BetType 
	WHERE b.ProductID IN (41,53,44)
	
	SELECT a.CustID ,a.ValuePT,a.ProductID
	FROM #tblCustomer a
	WHERE a.ProductID NOT IN (41,53,44) -- Not show dummy product
	UNION
	SELECT s.CustID, 0 AS SuperPT, 37 AS ProductID
	FROM #SMATemp s
	WHERE dbo.f_Age_OfferedProductBySite(s.Site)=1
	ORDER BY CustID, ProductID
	
	DROP TABLE #tblCustomer			
	DROP TABLE #Tmp_ProductProfile
	DROP TABLE #SMATemp
	DROP TABLE #SportBettypeDummy
END
GO
