/*<info serverAlias="DBAGE-bodb02" executers="wsv_CashService"  viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Task_CashService_CashPromotionCal
	@ProductDetails NVARCHAR(MAX) = 'All',
	@MoveBetsDay	SMALLDATETIME,
	@BalanceUpDay	SMALLDATETIME,	
	@TransDate 		DATETIME,
	@AgentPromotion VARCHAR(MAX)
AS 
/*  
	Created By: Elodie
	Created Date: 2025-07-07
	Description: Agency Cash Service - Calculate and add pending bonus transaction for qualified members [Redmine #232347]
	DB: DBAGE.bodb02
	
	Revisions:
		- 20250707@Elodie: Initial SP [Redmine: #232347] 

	Param:
		exec Task_CashService_BonusTransaction_Ins 			
			@ProductDetails = @ProductDetails, 
			@MoveBetsDay = '2025-07-01', 
			@BalanceUpDay = '2025-07-01',
			@AgentPromotion = @AgentPromotion,
*/  
BEGIN
	SET NOCOUNT ON
	
	DECLARE @SBRNGGamesProductIds VARCHAR(MAX),
			@RNGCasinoProductIds VARCHAR(MAX),
			@LiveCasinoProductIds VARCHAR(MAX)

	CREATE TABLE #TmpCondSumWL(
		SportType	SMALLINT,
		BetType		INT,
		LeagueGroupID SMALLINT, 
		TicketType TINYINT,
		ProductId TINYINT
	)
	DECLARE @SportBettypeMatrix TABLE (BetType SMALLINT, RefTable TINYINT,  LeagueGroupID SMALLINT, TicketType TINYINT, SportType SMALLINT, ProductID INT)
	DECLARE @ExistingProductDetails TABLE (ProductId INT,Sporttype SMALLINT,Bettype INT, LeagueGroupID SMALLINT, TicketType TINYINT)
	DECLARE @isTest BIT = 0, @__ProductDetails XML
	SELECT  @isTest = dbo.f_CheckSPVersion(@@PROCID)	

	SELECT @__ProductDetails = CONVERT(XML, @ProductDetails)
	INSERT INTO @ExistingProductDetails(ProductId,Sporttype,Bettype,LeagueGroupID,TicketType)
	SELECT ProductId,Sporttype,Bettype,LeagueGroupID,TicketType
	FROM dbo.f_ProductDetail_ConditionSel(@ProductDetails, @__ProductDetails)

	DECLARE @AgentPromotion_Tbl TABLE(
		AgentID INT,
		SiteDBGroupID TINYINT,
		PromotionID INT,
		FromDate DATE,
		ToDate DATE,
		ProductCategoryID TINYINT,
		ProductIds VARCHAR(MAX),
		[Percentage] SMALLMONEY,
		MaxPayout MONEY,
		MinValue MONEY
	)
	DECLARE @AgentPromotionTmp TABLE(
		AgentID INT,
		SiteDBGroupID TINYINT,
		PromotionID INT,
		FromDate DATE,
		ToDate DATE,
		ProductCategoryID TINYINT,
		ProductIds VARCHAR(MAX),
		[Percentage] SMALLMONEY,
		MaxPayout MONEY,
		MinValue MONEY
	)
	CREATE TABLE #Turnover_Tbl (
		CustId INT,
		AgentId INT,
		ProductCategoryID TINYINT,
		Turnover MONEY,
		PromotionID INT,
		CONSTRAINT PK_Turnover PRIMARY KEY (CustId, ProductCategoryID, PromotionID)
	)

	--Clean old data
	DELETE CashPromotionCal WITH (ROWLOCK) WHERE TransDate < DATEADD(mm,-3, GETDATE())

	--Parse Json
	INSERT INTO @AgentPromotion_Tbl (AgentID, SiteDBGroupID, PromotionID, FromDate, ToDate, ProductCategoryID, ProductIds, Percentage, MaxPayout, MinValue)
	SELECT
		Parent.AgentID,
		Parent.SiteDBGroupID,
		Parent.PromotionID,
		Parent.FromDate,		
		Parent.ToDate,
		Child.ProductCategoryID,
		Child.ProductList,
		Child.Percentage,
		Child.MaxPayout,
		Child.MinValue
	FROM OPENJSON(@AgentPromotion)
		WITH (
			AgentID INT,
			SiteDBGroupID TINYINT,
			PromotionID INT,
			FromDate DATE,	
			ToDate DATE,
			Details NVARCHAR(MAX) AS JSON
		) AS Parent
		CROSS APPLY OPENJSON(Parent.Details)
		WITH (
			ProductCategoryID TINYINT,
			ProductList VARCHAR(MAX),
			Percentage SMALLMONEY,
			MaxPayout MONEY,
			MinValue MONEY
		) AS Child

	-- Sportsbook & RNG Games
	BEGIN
		INSERT INTO @AgentPromotionTmp (AgentID, SiteDBGroupID, PromotionID, FromDate, ToDate, ProductCategoryID, ProductIds, Percentage, MaxPayout, MinValue)
		SELECT AgentID, SiteDBGroupID, PromotionID, FromDate, ToDate, ProductCategoryID, ProductIds, Percentage, MaxPayout, MinValue
		FROM @AgentPromotion_Tbl	
		WHERE ProductCategoryID IN (1, 44) -- Sportsbook, RNG Games

		SELECT @SBRNGGamesProductIds = dbo.f_AddRelatedProducts(5) -- ProductId 5: VS
		SELECT @SBRNGGamesProductIds = '1' + ',' + @SBRNGGamesProductIds

		INSERT INTO @SportBettypeMatrix (BetType, RefTable, LeagueGroupID, ticketType, SportType, ProductID)
		SELECT f.BetType, f.RefTable, ISNULL(e.LeagueGroupID,0) AS LeagueGroupID, ISNULL(e.TicketType,0) AS TicketType, ISNULL(SportType,0) AS SportType, f.ProductID
		FROM dbo.f_SportBettypeMatrixByProduct_Sel(@SBRNGGamesProductIds, @IsTest) f
			LEFT JOIN @ExistingProductDetails e ON e.ProductId = f.ProductID
		WHERE EXISTS(SELECT 1
					WHERE e.ProductId IS NULL -- get products don't have product details
						OR 
							(
								e.Bettype = f.BetType -- get products have product details and choose promotion/prize/lucky draw bettype
								OR (
											e.Bettype = 0  AND  (e.ProductId = 1 OR  f.BetType NOT IN (SELECT g.Bettype FROM f_GetProductDetail() g WHERE g.ProductId <> 1) ) --get normal bettype
										)
							)
					)
		INSERT INTO #TmpCondSumWL(SportType, BetType, LeagueGroupID, TicketType, ProductId) 
		SELECT f.SportType, f.BetType, f.LeagueGroupID, f.TicketType, f.ProductId
		FROM dbo.f_SumWinloss_ConditionSel(@SBRNGGamesProductIds) f
			LEFT JOIN @ExistingProductDetails e ON f.ProductID = e.ProductId 
		WHERE e.ProductId IS NULL OR (e.Bettype = f.BetType AND e.Sporttype = f.SportType AND e.TicketType = f.TicketType AND e.LeagueGroupID = f.LeagueGroupID AND e.ProductID = f.ProductId)

		-- Calculate Bonus Amount of Sportsbook	& RNG Games		
		MERGE INTO #Turnover_Tbl AS target
		USING (
			SELECT
				m.custid AS CustId, ap.AgentId,
				ap.ProductCategoryID AS ProductCategoryID,
				SUM(b.TurnoverNoDraw) AS Turnover,
				ap.PromotionID
			FROM bodb_AGE.dbo.bettrans_compact b WITH(NOLOCK)
			INNER JOIN CustInfo m WITH(NOLOCK) ON m.custid = b.custid
			INNER JOIN @AgentPromotionTmp ap ON m.recommend = ap.AgentID
			INNER JOIN vw_CustInfoExtra ce WITH(NOLOCK) ON m.custid = ce.custid
			INNER JOIN @SportBettypeMatrix s ON b.bettype = s.bettype
				AND ((s.ProductID <> 1 AND ap.ProductCategoryID = 44) OR (s.ProductID = 1 AND ap.ProductCategoryID = 1 AND b.sporttype = s.SportType AND b.LeagueGroupID = s.LeagueGroupID AND b.TicketType = s.TicketType))
			CROSS APPLY (SELECT FromDate, ToDate FROM dbo.f_MBU_RangeDate(ap.FromDate, ap.ToDate, @BalanceUpDay, @MoveBetsDay) WHERE RangeType = 1) t		
			WHERE roleID = 1 AND ce.ServiceType = 1						
				AND b.winlostdate BETWEEN t.FromDate AND t.ToDate
				AND b.TicketType <> 1 -- exclude CashOut
			GROUP BY m.custid, ap.AgentId, ap.ProductCategoryID, ap.PromotionID
		) AS source ON target.CustId = source.CustId AND target.ProductCategoryID = source.ProductCategoryID AND target.PromotionID = source.PromotionID
		WHEN MATCHED THEN
			UPDATE SET target.Turnover = target.Turnover + source.Turnover
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (CustId, AgentId, ProductCategoryID, Turnover, PromotionID)
			VALUES (source.CustId, source.AgentId, source.ProductCategoryID, source.Turnover, source.PromotionID);	
			
		-- Calculate Bonus Amount of Sportsbook from Sum_WinLoss				
		MERGE INTO #Turnover_Tbl AS target
		USING (
			SELECT
				b.custid AS CustId, ap.AgentId,
				ap.ProductCategoryID AS ProductCategoryID,
				SUM(b.TunroverNoDraw) AS Turnover,
				ap.PromotionID
			FROM dbo.Sum_WinLoss b WITH(NOLOCK)
				INNER JOIN @AgentPromotionTmp ap ON b.recommend = ap.AgentID
				INNER JOIN vw_CustInfoExtra ce WITH(NOLOCK) ON b.custid = ce.custid
				INNER JOIN #TmpCondSumWL t ON b.sporttype = t.sporttype AND b.bettype = t.bettype AND ISNULL(b.leagueGroupID,0) = t.LeagueGroupID AND ISNULL(b.ticketType,0) = t.TicketType
					AND ((t.ProductID <> 1 AND ap.ProductCategoryID = 44) OR (t.ProductID = 1 AND ap.ProductCategoryID = 1))
				CROSS APPLY (SELECT FromDate, ToDate FROM dbo.f_MBU_RangeDate(ap.FromDate, ap.ToDate, @BalanceUpDay, @MoveBetsDay) WHERE RangeType = 2) r		
			WHERE roleID = 1 AND ce.ServiceType = 1
				AND Winlostdate BETWEEN r.FromDate AND r.ToDate
			GROUP BY b.CustID, ap.AgentId, ap.ProductCategoryID, ap.PromotionID
		) AS source ON target.CustId = source.CustId AND target.ProductCategoryID = source.ProductCategoryID AND target.PromotionID = source.PromotionID
		WHEN MATCHED THEN
			UPDATE SET target.Turnover = target.Turnover + source.Turnover
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (CustId, AgentId, ProductCategoryID, Turnover, PromotionID)
			VALUES (source.CustId, source.AgentId, source.ProductCategoryID, source.Turnover, source.PromotionID);				
			
		DELETE FROM @AgentPromotionTmp			
		TRUNCATE TABLE #TmpCondSumWL
		DELETE FROM @SportBettypeMatrix	
	END
	
	-- RNG Casino
	BEGIN
		INSERT INTO @AgentPromotionTmp (AgentID, SiteDBGroupID, PromotionID, FromDate, ToDate, ProductCategoryID, ProductIds, Percentage, MaxPayout, MinValue)
		SELECT AgentID, SiteDBGroupID, PromotionID, FromDate, ToDate, ProductCategoryID, ProductIds, Percentage, MaxPayout, MinValue
		FROM @AgentPromotion_Tbl	
		WHERE ProductCategoryID IN (53) -- RNG Casino
		
		SELECT @RNGCasinoProductIds =  STRING_AGG(ProductID, ',')
		FROM (
			SELECT DISTINCT LTRIM(RTRIM(value)) AS ProductID
			FROM @AgentPromotionTmp
			CROSS APPLY STRING_SPLIT(ProductIds, ',')
			WHERE ISNULL(ProductIds, '') <> ''
		) AS DistinctValues

		SELECT @RNGCasinoProductIds = dbo.f_AddRelatedProducts(@RNGCasinoProductIds)

		INSERT INTO @SportBettypeMatrix (BetType, RefTable, LeagueGroupID, ticketType, SportType, ProductID)
		SELECT f.BetType, f.RefTable, ISNULL(e.LeagueGroupID,0) AS LeagueGroupID, ISNULL(e.TicketType,0) AS TicketType, ISNULL(SportType,0) AS SportType, f.ProductID
		FROM dbo.f_SportBettypeMatrixByProduct_Sel(@RNGCasinoProductIds, @IsTest) f
			LEFT JOIN @ExistingProductDetails e ON e.ProductId = f.ProductID
		WHERE EXISTS(SELECT 1
					WHERE e.ProductId IS NULL -- get products don't have product details
						OR 
							(
								e.Bettype = f.BetType -- get products have product details and choose promotion/prize/lucky draw bettype
								OR (
											e.Bettype = 0  AND  f.BetType NOT IN (SELECT g.Bettype FROM f_GetProductDetail() g WHERE g.ProductId <> 1)  -- get normal bettype
										)
							)
					)
				AND EXISTS (SELECT 1 FROM dbo.RefResource rf WITH (NOLOCK) -- count Slots game only
					WHERE rf.RefId='RNG_BT_Group'
						AND CAST(rf.ResourceId AS SMALLINT) = f.BetType
						AND CAST(rf.Resource_en AS TINYINT) = 1) --GameGroupID:  1 Slot Games | 2 Others
				-- Exclude Progressive Games Contribution Bettype
				AND NOT EXISTS (SELECT 1 FROM dbo.f_ProgressiveGamesContribution_Bettype_Sel(@RNGCasinoProductIds) WHERE ProductId = f.ProductID AND ContributionBettype = f.BetType )
		
		-- Calculate Bonus Amount of RNG Casino		
		MERGE INTO #Turnover_Tbl AS target
		USING (
			SELECT
				b.custid AS CustId, ap.AgentId,
				ap.ProductCategoryID AS ProductCategoryID,
				SUM(b.BetStake) AS Turnover,
				ap.PromotionID
			FROM @AgentPromotionTmp ap
				INNER JOIN dbo.bettransRnG b WITH (NOLOCK) ON b.recommend = ap.AgentID
				CROSS APPLY (SELECT FromDate, ToDate FROM dbo.f_MBU_RangeDate(ap.FromDate, ap.ToDate, @BalanceUpDay, @MoveBetsDay) WHERE RangeType = 1) r	
				CROSS APPLY (SELECT TOP 1 ServiceType FROM CustProductStatus ct WITH (NOLOCK) WHERE b.custid = ct.custid) ce			
				INNER JOIN @SportBettypeMatrix s ON b.gameId = s.Bettype AND s.RefTable = 1 
				CROSS APPLY (SELECT TRIM(value) AS ProductID FROM STRING_SPLIT(ap.ProductIds, ',')) AS p					
			WHERE ce.ServiceType = 1
				AND b.winlostdate BETWEEN r.FromDate AND r.ToDate
				AND b.statusID IN (111, 112, 113)
				AND s.ProductID = p.ProductID
			GROUP BY b.custid, ap.AgentId, ap.ProductCategoryID, ap.PromotionID
		) AS source 
		ON target.CustId = source.CustId AND target.ProductCategoryID = source.ProductCategoryID AND target.PromotionID = source.PromotionID
		WHEN MATCHED THEN
			UPDATE SET target.Turnover = target.Turnover + source.Turnover
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (CustId, AgentId, ProductCategoryID, Turnover, PromotionID)
			VALUES (source.CustId, source.AgentId, source.ProductCategoryID, source.Turnover, source.PromotionID);
			
		-- Calculate Bonus Amount of RNG Casino
		MERGE INTO #Turnover_Tbl AS target	
		USING (
			SELECT
				b.custid AS CustId, ap.AgentId,
				ap.ProductCategoryID AS ProductCategoryID,
				SUM(b.BetStake) AS Turnover,
				ap.PromotionID
			FROM dbo.bettransRnG14 b WITH (NOLOCK)
				INNER JOIN @AgentPromotionTmp ap ON b.recommend = ap.AgentID
				INNER JOIN vw_CustInfoExtra ce WITH(NOLOCK) ON b.custid = ce.custid
				INNER JOIN @SportBettypeMatrix s ON b.gameId = s.Bettype AND s.RefTable = 1
				CROSS APPLY (SELECT TRIM(value) AS ProductID FROM STRING_SPLIT(ap.ProductIds, ',')) AS p
				CROSS APPLY (SELECT FromDate, ToDate FROM dbo.f_MBU_RangeDate(ap.FromDate, ap.ToDate, @BalanceUpDay, @MoveBetsDay) WHERE RangeType = 2) r
			WHERE ce.ServiceType = 1
				AND b.winlostdate BETWEEN r.FromDate AND r.ToDate
				AND b.statusID IN (111, 112, 113)
				AND s.ProductID = p.ProductID
			GROUP BY b.custid, ap.AgentId, ap.ProductCategoryID, ap.PromotionID
		) AS source ON target.CustId = source.CustId AND target.ProductCategoryID = source.ProductCategoryID AND target.PromotionID = source.PromotionID
		WHEN MATCHED THEN
			UPDATE SET target.Turnover = target.Turnover + source.Turnover
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (CustId, AgentId, ProductCategoryID, Turnover, PromotionID)
			VALUES (source.CustId, source.AgentId, source.ProductCategoryID, source.Turnover, source.PromotionID);	

		DELETE FROM @AgentPromotionTmp				
		DELETE FROM @SportBettypeMatrix	
	END

	-- Live Casino
	BEGIN
		INSERT INTO @AgentPromotionTmp (AgentID, SiteDBGroupID, PromotionID, FromDate, ToDate, ProductCategoryID, ProductIds, Percentage, MaxPayout, MinValue)
		SELECT AgentID, SiteDBGroupID, PromotionID, FromDate, ToDate, ProductCategoryID, ProductIds, Percentage, MaxPayout, MinValue
		FROM @AgentPromotion_Tbl	
		WHERE ProductCategoryID IN (41) -- Live Casino
		
		SELECT @LiveCasinoProductIds =  STRING_AGG(ProductID, ',')
		FROM (
			SELECT DISTINCT LTRIM(RTRIM(value)) AS ProductID
			FROM @AgentPromotionTmp
				CROSS APPLY STRING_SPLIT(ProductIds, ',')
			WHERE ISNULL(ProductIds, '') <> ''
		) AS DistinctValues

		SELECT @LiveCasinoProductIds = dbo.f_AddRelatedProducts(@LiveCasinoProductIds)

		INSERT INTO @SportBettypeMatrix (BetType, RefTable, LeagueGroupID, ticketType, SportType, ProductID)
		SELECT f.BetType, f.RefTable, ISNULL(e.LeagueGroupID,0) AS LeagueGroupID, ISNULL(e.TicketType,0) AS TicketType, ISNULL(SportType,0) AS SportType, f.ProductID
		FROM dbo.f_SportBettypeMatrixByProduct_Sel(@LiveCasinoProductIds, @IsTest) f
			LEFT JOIN @ExistingProductDetails e ON e.ProductId = f.ProductID
		WHERE EXISTS(SELECT 1
					WHERE e.ProductId IS NULL -- get products don't have product details
						OR (e.Bettype = 0  AND  f.BetType NOT IN (SELECT g.Bettype FROM f_GetProductDetail() g WHERE g.ProductId <> 1)) -- get normal bettype 												
					)
			AND NOT (SubProduct = 'Tips' OR f.Bettype = 3149) -- exclude Tips Bettype
		
		-- Calculate Bonus Amount of Live Casino
		MERGE INTO #Turnover_Tbl AS target
		USING (
			SELECT
				b.custid AS CustId, ap.AgentId,
				ap.ProductCategoryID AS ProductCategoryID,
				SUM(b.NetStake) AS Turnover,
				ap.PromotionID
			FROM dbo.bettransLC b WITH (NOLOCK)
				INNER JOIN @AgentPromotionTmp ap ON b.recommend = ap.AgentID
				INNER JOIN vw_CustInfoExtra ce WITH(NOLOCK) ON b.custid = ce.custid
				INNER JOIN @SportBettypeMatrix s ON b.gameId = s.Bettype AND s.RefTable = 2
				CROSS APPLY (SELECT TRIM(value) AS ProductID FROM STRING_SPLIT(ap.ProductIds, ',')) AS p
				CROSS APPLY (SELECT FromDate, ToDate FROM dbo.f_MBU_RangeDate(ap.FromDate, ap.ToDate, @BalanceUpDay, @MoveBetsDay) WHERE RangeType = 1) r
			WHERE ce.ServiceType = 1
				AND b.winlostdate BETWEEN r.FromDate AND r.ToDate
				AND b.statusID IN (111, 112, 113)
				AND s.ProductID = p.ProductID
			GROUP BY b.custid, ap.AgentId, ap.ProductCategoryID, ap.PromotionID					
		) AS source ON target.CustId = source.CustId AND target.ProductCategoryID = source.ProductCategoryID AND target.PromotionID = source.PromotionID
		WHEN MATCHED THEN
			UPDATE SET target.Turnover = target.Turnover + source.Turnover
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (CustId,  AgentId, ProductCategoryID, Turnover, PromotionID)
			VALUES (source.CustId,  source.AgentId, source.ProductCategoryID, source.Turnover, source.PromotionID);	

		-- Calculate Bonus Amount of Live Casino
		MERGE INTO #Turnover_Tbl AS target
		USING (
			SELECT
				b.custid AS CustId, ap.AgentId,
				ap.ProductCategoryID AS ProductCategoryID,
				SUM(b.NetStake) AS Turnover,
				ap.PromotionID
			FROM dbo.bettransLC14 b WITH (NOLOCK)
				INNER JOIN @AgentPromotionTmp ap ON b.recommend = ap.AgentID
				INNER JOIN vw_CustInfoExtra ce WITH(NOLOCK) ON b.custid = ce.custid
				INNER JOIN @SportBettypeMatrix s ON b.gameId = s.Bettype AND s.RefTable = 2
				CROSS APPLY (SELECT TRIM(value) AS ProductID FROM STRING_SPLIT(ap.ProductIds, ',')) AS p
				CROSS APPLY (SELECT FromDate, ToDate FROM dbo.f_MBU_RangeDate(ap.FromDate, ap.ToDate, @BalanceUpDay, @MoveBetsDay) WHERE RangeType = 2) r
			WHERE ce.ServiceType = 1
				AND b.winlostdate BETWEEN r.FromDate AND r.ToDate
				AND b.statusID IN (111, 112, 113)
				AND s.ProductID = p.ProductID
			GROUP BY b.custid, ap.AgentId, ap.ProductCategoryID, ap.PromotionID			
		) AS source ON target.CustId = source.CustId AND target.ProductCategoryID = source.ProductCategoryID AND target.PromotionID = source.PromotionID
		WHEN MATCHED THEN
			UPDATE SET target.Turnover = target.Turnover + source.Turnover
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (CustId,  AgentId, ProductCategoryID, Turnover, PromotionID)
			VALUES (source.CustId,  source.AgentId, source.ProductCategoryID, source.Turnover, source.PromotionID);

		DELETE FROM @AgentPromotionTmp			
		DELETE FROM @SportBettypeMatrix	
	END
	

	MERGE INTO CashPromotionCal AS Target
	USING (
		SELECT 
			@TransDate AS TransDate,
			t.CustId,
			ap.AgentID AS AgentId,
			ap.SiteDBGroupID AS SiteDBGroupID,
			t.ProductCategoryID,
			CASE 
				WHEN (t.Turnover * ap.Percentage) / 100 > ap.MaxPayout AND ap.MaxPayout <> 0 
				THEN ap.MaxPayout 
				ELSE (t.Turnover * ap.Percentage) / 100 
			END AS Bonus,
			(
				SELECT 
					ap.PromotionID AS PromotionID, 
					CONVERT(VARCHAR(10), ap.FromDate, 120) AS FromDate, 
					CONVERT(VARCHAR(10), ap.ToDate, 120) AS ToDate
				FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
			) AS ExtraInfo,
			ap.PromotionID PromotionID
		FROM #Turnover_Tbl t
			INNER JOIN @AgentPromotion_Tbl ap ON t.PromotionID = ap.PromotionID AND t.ProductCategoryID = ap.ProductCategoryID AND t.AgentId = ap.AgentID
		WHERE t.Turnover >= ap.MinValue AND t.Turnover > 0
	) AS Source
	ON Target.TransDate = Source.TransDate
	AND Target.CustId = Source.CustId
	AND Target.ProductCategoryID = Source.ProductCategoryID
	AND Target.PromotionID = Source.PromotionID
	WHEN MATCHED THEN
		UPDATE SET target.Bonus = source.Bonus
	WHEN NOT MATCHED BY TARGET THEN
		INSERT (
			TransDate, CustId, AgentId, SiteDBGroupID, ProductCategoryID, Bonus, ExtraInfo, PromotionID
		)
		VALUES (
			Source.TransDate, Source.CustId, Source.AgentId, Source.SiteDBGroupID,
			Source.ProductCategoryID, Source.Bonus, Source.ExtraInfo, Source.PromotionID
		);
		
	DROP TABLE #TmpCondSumWL
	DROP TABLE #Turnover_Tbl
END
