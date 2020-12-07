/*<info serverAlias="DBACC-bodb02" executers="bodbExtAccNet,bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_GetPTProductBySuper] 
	-- Add the parameters for the stored procedure here
	@Supers VARCHAR(MAX)
AS
/*
	Created: 20201020@Winfred
	DB: DBACC-bodb02
	Task: Get value PT setting product for customer

	Revisions:
		- 20201020@Winfred: Get value PT setting product for customer [Redmine: #139937]
		- 20201207@Winfred: Get value PT GDG for customer [Redmine: #144105]
		
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
	-- DCS Setting
	INSERT INTO #tblCustomer (CustID,SportType,BetType,ProductID)
	SELECT ss.val,b.SportType,b.BetType,
	CASE WHEN b.SportType = 211 THEN  21
		 WHEN b.SportType = 241 THEN  47
		 WHEN b.SportType = 225 THEN  52
		 WHEN b.SportType = 233 THEN  51
		 WHEN b.SportType = 242 THEN  46
		 WHEN b.SportType = 243 THEN  45
		 WHEN b.SportType = 244 THEN  39
		 WHEN b.SportType = 220 THEN  28
		 WHEN b.SportType = 222 THEN  40
		 WHEN b.SportType = 224 THEN  50
		 WHEN b.SportType = 236 THEN  59
		ELSE b.ProductID END ProductID
	FROM dbo.strSplit(@Supers, ',') AS ss
	INNER JOIN ProductSettingDetail b WITH(NOLOCK)ON b.SettingType in (1,18) 
	WHERE B.ProductID IN (41,22,42) -- Live Casino, Macau Games ,Saba.club
	or (B.ProductID IN (16) and SportType = 43 and BetType = 1) -- Sportsbook 2
	or (B.ProductID IN (5) and SportType = 180 and BetType = 1201) -- Virtual Sports
	or (B.ProductID IN (24) and SportType = 219 and BetType = 1011) -- Fishing World
	or (B.ProductID IN (44) and SportType = 220 and BetType = 1021) -- Lottery
	or (B.ProductID IN (44) and SportType = 222 and BetType = 4901) -- Table Game
	or (B.ProductID IN (44) and SportType = 224 and BetType = 5500) -- RNG War
	or (B.ProductID IN (38) and SportType = 245 and BetType = 4601) -- Virtual Games
	or (B.ProductID IN (23) and SportType = 213 and BetType = 2501) -- NG2
	--Get PT DCS
	UPDATE a
	SET a.SuperPT = cast(b.SuperPT AS SMALLMONEY) / 100   
	FROM #tblCustomer a
	INNER JOIN CustPTSetting3rd_Agent b WITH(NOLOCK) ON a.custID = b.CustID 
						AND a.BetType = b.BetType AND a.SportType = b.SportType
	
	 -- On Macau Games(PP, Arcadia Gaming, SG, PG Soft, Joker)
	INSERT #tblCustomer(CustID,SportType,BetType,ProductID,SuperPT)
	SELECT ss.val,c.SportType,c.BetType,
		CASE 
		 WHEN c.SportType = 232 THEN  55
		 WHEN c.SportType = 234 THEN  56
		 WHEN c.SportType = 247 THEN  36
		 WHEN c.SportType = 165 THEN  34
		 WHEN c.SportType = 248 THEN  32
		ELSE c.ProductID END ProductID, b.SuperPT
	FROM dbo.strSplit(@Supers, ',') AS ss 
	INNER JOIN #tblCustomer b ON  b.ProductID = 22 and b.SportType = 212 and ss.val = b.CustID
	INNER JOIN ProductSettingDetail c WITH(NOLOCK)	ON  c.SettingType = 8 
					and c.ProductID = b.ProductID and c.SportType <> 212
		
	-- Non DCS Setting
	
	-- Sportsbook - Soccer
	INSERT #tblCustomer(CustID,SportType,BetType,ProductID,SuperPT)
	SELECT ss.val, b.BetType, b.SportType, 1 AS ProductID, b.spositiontaking
	FROM dbo.strSplit(@Supers, ',') AS ss
	INNER JOIN CustSetting b WITH(NOLOCK) ON ss.val = b.CustID 
	WHERE b.BetType = 1 AND b.SportType = 1
	
	-- Number Game
	INSERT #tblCustomer(CustID,SportType,BetType,ProductID,SuperPT)
	SELECT ss.val, b.BetType, b.SportType, 3 AS ProductID, b.spositiontaking
	FROM dbo.strSplit(@Supers, ',') AS ss
	INNER JOIN CustSetting3rd b WITH(NOLOCK) ON ss.val = b.CustID 
	WHERE b.BetType = 81 AND b.SportType = 161
	
	-- RNG Keno
	INSERT #tblCustomer(CustID,SportType,BetType,ProductID,SuperPT)
	SELECT	cs.CustID ,	cs.Sporttype, cs.Bettype, 8 AS ProductID, cs.spositiontaking AS SuperPT
	FROM dbo.strSplit(@Supers, ',') ss 
		INNER JOIN dbo.CustSettingGame cs WITH (NOLOCK) ON ss.val = cs.CustID 
	WHERE cs.Bettype = 1501 AND cs.Sporttype = 202
	
	-- Gold Deluxe
	INSERT #tblCustomer(CustID,SportType,BetType,ProductID,SuperPT)
	SELECT  cs.CustID,	cs.Sporttype, cs.Bettype, 12 AS ProductID, cs.spositiontaking AS SuperPT
     FROM  dbo.strSplit(@Supers, ',') ss
		INNER JOIN dbo.CustSettingGame cs WITH(NOLOCK) ON ss.val = cs.CustID 
     WHERE  cs.sporttype = 255 AND cs.bettype = 1701
	
	SELECT a.CustID,a.SuperPT,a.ProductID,p.ProductName
	FROM #tblCustomer a 
	INNER JOIN Products  p WITH (NOLOCK) on a.ProductID = p.ProductID  
	ORDER BY a.CustID,a.ProductID
	
	DROP TABLE #tblCustomer							
END
GO
