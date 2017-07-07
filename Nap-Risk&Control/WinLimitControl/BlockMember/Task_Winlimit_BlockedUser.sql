/*<info serverAlias="DBCUST-CUSTDB" executers="" viewers="vnteam" isFunction="0"></info>*/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Task_Winlimit_BlockedUser]
AS
/*   
	Create: 20160623@Helen
	Task : Task scan winlimit amount & blocked member when they are reached max winlimit setting  - [Redmine:57722]
	DB: DBCUST/CustDB
	Revisions:
		- 20161011@Helen: NAP Risk & Control - Phase 3 [Redmine: 61220]
		- 20170321@Helen: NAP Risk & Control - Phase 3A [Redmine: 72604]
		- 20170515@Helen: NAP Risk & Control - CHANGE REQUEST [Redmine: 75332]

	Param's Explanation:
	
*/
BEGIN
	SET NOCOUNT ON

	
	CREATE TABLE #DataTmp_pre (CustId INT, ExchangeID TINYINT,SiteID INT, ProductId TINYINT, Bettype SMALLINT, TotalWinAmount MONEY, WinlostDate SMALLDATETIME)
	
	CREATE TABLE #DataTmp (CustId INT, ExchangeID TINYINT,SiteID INT, ProductId TINYINT, GroupID SMALLINT, TotalWinAmount MONEY, WinlostDate SMALLDATETIME, IsPrivateSetting BIT)
	
	CREATE TABLE #HistoryData (ID INT IDENTITY, CustId INT 
							, ProductId TINYINT 
							, GroupID INT 
							, MaxWinLimit MONEY 
							, TotalWinAmt MONEY 
							, WinAmt MONEY 
							, LevelID TINYINT  
							, ActionID TINYINT 
							, ModifiedDate DATETIME  
							, IsNotified BIT  
							, ModifiedBy INT 
							, CreatedBy  INT 
							, WinlostDate DATETIME
							, MaxWinLimitSetting XML
							, TotalWinAmt_RM MONEY
							, BettypeID SMALLINT  )

	DECLARE @WinlostDate SMALLDATETIME, @ReachedDate DATETIME
	SELECT @WinlostDate = CAST(GETDATE() AS DATE)

	INSERT INTO #DataTmp_pre(CustId, WinlostDate, Bettype, TotalWinAmount)
	SELECT CustId, WinlostDate, BetType, SUM(Winlost)
	FROM (
		SELECT CustId, WinlostDate, BetType, Winlost
		FROM DBTXN.bodb02.dbo.Winlimit_CreditGame c WITH(NOLOCK)
		WHERE WinlostDate = @WinlostDate

		UNION ALL
		
		SELECT CustId, WinlostDate, BetType, - Winlost
		FROM DBTXN.bodb02.dbo.Winlimit_DebitGame c WITH(NOLOCK)
		WHERE WinlostDate = @WinlostDate
			
	)t
	GROUP BY CustId, WinlostDate, BetType

	IF NOT EXISTS (SELECT TOP 1 1 FROM #DataTmp_pre)
	BEGIN
		RETURN
	END
	
	INSERT INTO #DataTmp (CustId, WinlostDate, GroupID, TotalWinAmount,IsPrivateSetting,ProductId)
	SELECT CustId, WinlostDate, GGS.GroupID, SUM(T.TotalWinAmount),0 ,GGS.ProductID
	FROM #DataTmp_pre T
		INNER JOIN Winlimit_GameGroupSetting GGS WITH (NOLOCK) ON T.Bettype = GGS.BetTypeID
	GROUP BY CustId, WinlostDate, GGS.GroupID,GGS.ProductID
	
	UPDATE t 
	SET ExchangeID = cc.currency
		, SiteID = s.siteid
		, IsPrivateSetting = CASE WHEN CGS.CustID IS NOT NULL THEN 1 ELSE 0 END 
	FROM #DataTmp t
		INNER JOIN custInfo CI (NOLOCK) ON t.CustId = ci.custid
		INNER JOIN Customer cc WITH(NOLOCK) ON cc.custid = ci.recommend
		INNER JOIN [site] s WITH (NOLOCK) ON s.site = cc.site
		-- just need one row returned, so checking level1 is fine to know whether this customer has private setting or not
		LEFT JOIN WinLimit_CustGameSetting CGS WITH (NOLOCK) ON CGS.CustID = T.CustId AND CGS.GroupID =  T.GroupID AND CGS.LevelID = 1
	OPTION(MAXDOP 8)
		
	CREATE TABLE #CustReachCWLList (ID INT IDENTITY PRIMARY KEY, CustId INT, ProductId TINYINT, GroupID INT,WinlostDate SMALLDATETIME,LevelID TINYINT, MaxWinLimit MONEY
		, TotalWinAmount MONEY
		, ExchangeID INT
		, SiteID INT
		, IsPrivateSetting BIT
		, MaxWinLimitSetting XML
		, TotalWinAmt_RM MONEY)
	
	--for private setting
	INSERT INTO #CustReachCWLList(CustId, ProductId, GroupID,WinlostDate,ExchangeID,SiteID, LevelID, MaxwinLimit, TotalWinAmount,IsPrivateSetting,MaxWinLimitSetting)
	SELECT t.CustId, t.ProductId, t.GroupID,t.WinlostDate,t.ExchangeID,t.SiteID, MAX(s.LevelID) AS LevelID , MAX(s.MaxWinLimit) AS MaxWinLimit, MAX(t.TotalWinAmount) AS TotalWinAmount,1
			, CAST(tmp.MaxWinLimitSetting AS XML)
	FROM #DataTmp t
		INNER JOIN WinLimit_CustGameSetting s WITH(NOLOCK) ON t.CustId = s.CustId AND t.ProductId = s.ProductId 
		INNER JOIN WinLimit_GameGroupSetting GS WITH (NOLOCK) ON GS.GroupID = S.GroupID AND GS.GroupID = T.GroupID
		CROSS APPLY (SELECT '<MaxWinLimitSetting' + x.str + '/>' 
					FROM (SELECT ' Level' + CAST(LevelID AS VARCHAR) + '="' + CAST(MaxWinLimit_RM AS VARCHAR) + '"'
						  FROM WinLimit_CustGameSetting S1 WITH (NOLOCK)
						  WHERE S1.CustID = T.CustId AND S1.ProductID = GS.ProductId AND S1.GroupID = GS.GroupID
						  FOR XML PATH('')
						) x(str)
		) AS tmp (MaxWinLimitSetting)
	WHERE t.TotalWinAmount >= s.MaxWinLimit
		AND s.MaxWinLimit > 0
		AND T.IsPrivateSetting = 1
		
	GROUP BY t.CustId, t.ProductId, t.GroupID,t.WinlostDate,t.ExchangeID,t.SiteID,tmp.MaxWinLimitSetting
	
	--for currency setting
	INSERT INTO #CustReachCWLList(CustId, ProductId, GroupID,WinlostDate,ExchangeID,SiteID,LevelID, MaxwinLimit, TotalWinAmount,IsPrivateSetting,MaxWinLimitSetting)
	SELECT t.CustId, t.ProductId, t.GroupID,t.WinlostDate,t.ExchangeID,t.SiteID,MAX(s.LevelID), MAX(s.MaxWinLimit), MAX(t.TotalWinAmount),0
		  ,CAST(tmp.MaxWinLimitSetting AS XML)
	FROM #DataTmp t
		INNER JOIN dbo.WinLimit_ProductSettingDetail s WITH(NOLOCK) ON t.ExchangeID = s.ExchangeID AND t.ProductId = s.ProductID AND T.SiteID = S.SiteID AND T.GroupID = S.GroupID
		INNER JOIN WinLimit_GameGroupSetting GS WITH (NOLOCK) ON GS.GroupID = S.GroupID 
		CROSS APPLY (SELECT '<MaxWinLimitSetting' + x.str + '/>'  
					FROM (SELECT ' Level' + CAST(LevelID AS VARCHAR) + '="' + CAST(MaxWinLimit_RM AS VARCHAR) + '"'
						  FROM WinLimit_ProductSettingDetail S1 WITH (NOLOCK)
						  WHERE S1.ProductID = GS.ProductId AND S1.GroupID = GS.GroupID AND S1.ExchangeID = T.ExchangeID AND S.SiteID = S1.SiteID
						  FOR XML PATH('')
						) x(str)
		) AS tmp (MaxWinLimitSetting)
		
	WHERE t.TotalWinAmount >= s.MaxWinLimit
		AND s.MaxWinLimit > 0
		AND T.IsPrivateSetting = 0
	GROUP BY t.CustId, t.ProductId, t.GroupID,t.WinlostDate,t.ExchangeID,t.SiteID,tmp.MaxWinLimitSetting
	
	IF NOT EXISTS (SELECT TOP 1 1 FROM #CustReachCWLList)
	BEGIN
		RETURN
	END
	
	SELECT @ReachedDate = GETDATE()
	
	-- Update due to change status of currency setting
	UPDATE g
	SET 
		  ModifiedDate = @ReachedDate
		, IsNotified = 0
		, MaxwinLimit = t.MaxWinLimit
		, MaxWinLimitSetting = T.MaxWinLimitSetting
		
	OUTPUT inserted.CustId, inserted.ProductId,inserted.GroupID, inserted.MaxWinLimit, inserted.TotalWinAmt, inserted.WinAmt, inserted.LevelID  
			, inserted.ModifiedDate, inserted.IsNotified,inserted.ModifiedBy, inserted.CreatedBy, inserted.WinlostDate,inserted.MaxWinLimitSetting ,inserted.TotalWinAmt_RM
	INTO #HistoryData(CustId
					, ProductId 
					, GroupID 
					, MaxWinLimit 
					, TotalWinAmt 
					, WinAmt 
					, LevelID 
					, ModifiedDate 
					, IsNotified 
					, ModifiedBy 
					, CreatedBy 
					, WinlostDate
					, MaxWinLimitSetting
					
					, TotalWinAmt_RM ) 
	FROM dbo.WinLimit_CustGameMonitoring g WITH(ROWLOCK, UPDLOCK)
		INNER JOIN #CustReachCWLList t ON t.CustId = g.CustID AND g.WinlostDate = t.WinlostDate AND t.GroupID = g.GroupID AND g.ProductID = t.ProductId AND g.LevelID = t.LevelID
		INNER JOIN Winlimit_ProductSettingDetail psd WITH (NOLOCK) ON g.ProductId = psd.ProductId AND t.ExchangeID = psd.ExchangeID and g.LevelID = psd.LevelID AND psd.SiteID = t.SiteID AND psd.GroupID = t.GroupID
		CROSS APPLY (SELECT TOP 1 tmp.ActionID,tmp.IsBlockedTransfer,tmp.IsBlockedPlaceBet
					 FROM WinLimit_CustGameStatus tmp WITH (NOLOCK) 
						INNER JOIN WinLimit_GameGroupSetting GS WITH (NOLOCK) ON GS.GroupID = psd.GroupID AND tmp.BettypeID = gs.BetTypeID
					 WHERE  tmp.CustID = G.CustID AND tmp.ProductID = G.ProductID) AS CGS
		
		
	WHERE (psd.IsBlockedPlaceBet = 1 AND cgs.IsBlockedPlaceBet = 0 AND CGS.ActionID NOT IN (2,4)) OR (psd.IsBlockedTransfer = 1 AND cgs.IsBlockedTransfer = 0 AND CGS.ActionID NOT IN (2,4))
		
	-- UPDATE	
	
	UPDATE g
	
	SET MaxwinLimit = t.MaxWinLimit
		, TotalWinAmt = g.TotalWinAmt -  CASE WHEN CGS.ActionID IN (2,4) THEN 0 ELSE g.WinAmt END + t.TotalWinAmount
		, WinAmt = t.TotalWinAmount
		, ModifiedDate = @ReachedDate
		, IsNotified = 0
		, LevelID = T.LevelID
		, MaxWinLimitSetting = t.MaxWinLimitSetting
		, TotalWinAmt_RM = CASE 
								WHEN T.ExchangeID = 20 THEN (g.TotalWinAmt -  CASE WHEN CGS.ActionID IN (2,4) THEN 0 ELSE g.WinAmt END + t.TotalWinAmount) 
								ELSE  ROUND (e.actualrate * (g.TotalWinAmt -  CASE WHEN CGS.ActionID IN (2,4) THEN 0 ELSE g.WinAmt END + t.TotalWinAmount),2)
							END
		
	OUTPUT inserted.CustId, inserted.ProductId,inserted.GroupID, inserted.MaxWinLimit, inserted.TotalWinAmt, inserted.WinAmt, inserted.LevelID  
			, inserted.ModifiedDate, inserted.IsNotified,inserted.ModifiedBy, inserted.CreatedBy, inserted.WinlostDate, inserted.MaxWinLimitSetting,inserted.TotalWinAmt_RM  
	INTO #HistoryData(CustId
					, ProductId 
					, GroupID 
					, MaxWinLimit 
					, TotalWinAmt 
					, WinAmt 
					, LevelID 
					, ModifiedDate 
					, IsNotified 
					, ModifiedBy 
					, CreatedBy 
					, WinlostDate
					, MaxWinLimitSetting
					,TotalWinAmt_RM) 
		
	FROM dbo.WinLimit_CustGameMonitoring g WITH(ROWLOCK, UPDLOCK)
		INNER JOIN #CustReachCWLList t ON t.CustId = g.CustID AND g.WinlostDate = t.WinlostDate AND t.GroupID = g.GroupID AND g.ProductID = t.ProductId
		
		CROSS APPLY (SELECT TOP 1 tmp.ActionID,tmp.IsBlockedTransfer,tmp.IsBlockedPlaceBet
					 FROM WinLimit_CustGameStatus tmp WITH (NOLOCK) 
						INNER JOIN WinLimit_GameGroupSetting GS WITH (NOLOCK) ON GS.GroupID = t.GroupID AND tmp.BettypeID = gs.BetTypeID
					 WHERE  tmp.CustID = G.CustID AND tmp.ProductID = G.ProductID) AS CGS
		INNER JOIN Exchange e WITH (NOLOCK)  ON e.ExchangeId = T.ExchangeID
	WHERE G.LevelID < T.LevelID
		-- Reach level again after unblocked
		OR ( CGS.ActionID IN (2,4))
	
	-- INSERT NEW
	INSERT INTO dbo.WinLimit_CustGameMonitoring(CustId, ProductID, GroupID,LevelID, MaxWinLimit, WinAmt, TotalWinAmt
		, IsNotified, CreatedBy,ModifiedDate ,WinlostDate,MaxWinLimitSetting,TotalWinAmt_RM,BettypeID)
	
	OUTPUT inserted.CustId, inserted.ProductId,inserted.GroupID, inserted.MaxWinLimit, inserted.TotalWinAmt, inserted.WinAmt, inserted.LevelID  
				, inserted.ModifiedDate, inserted.IsNotified,inserted.ModifiedBy, inserted.CreatedBy, inserted.WinlostDate,inserted.MaxWinLimitSetting,inserted.TotalWinAmt_RM,inserted.BettypeID  
	INTO #HistoryData(CustId
					, ProductId 
					, GroupID 
					, MaxWinLimit 
					, TotalWinAmt 
					, WinAmt 
					, LevelID 
					, ModifiedDate 
					, IsNotified 
					, ModifiedBy 
					, CreatedBy 
					, WinlostDate
					, MaxWinLimitSetting
					, TotalWinAmt_RM
					, BettypeID ) 
							
	SELECT t.CustId, t.ProductId, t.GroupID,t.LevelID, t.MaxwinLimit, t.TotalWinAmount, t.TotalWinAmount, 0, NULL,@ReachedDate ,@WinlostDate,t.MaxWinLimitSetting
			, CASE WHEN T.ExchangeID = 20 THEN t.TotalWinAmount ELSE ROUND(e.actualrate * t.TotalWinAmount,2) END AS TotalWinAmt_RM, t.GroupID AS BettypeID
	FROM #CustReachCWLList t
		LEFT JOIN dbo.WinLimit_CustGameMonitoring g WITH(NOLOCK) ON t.CustId = g.CustID AND t.WinlostDate = g.WinlostDate AND t.GroupID = g.GroupID
		INNER JOIN Exchange e WITH (NOLOCK)  ON e.ExchangeId = T.ExchangeID 
		
	WHERE g.CustID IS NULL
	
	DECLARE @StrData VARCHAR(MAX), @XmlData XML, @RowCount INT, @ReTry INT
	
	DECLARE @StartRow INT = 1, @MaxRow INT,@Threshold INT = 500, @StopRow INT
			
	SET @MaxRow = (SELECT MAX(ID) FROM #HistoryData)
	
	IF @Threshold >= @MaxRow
		SET @Threshold = @MaxRow
	
	SET @StopRow = @Threshold
	
	IF EXISTS (SELECT 1 FROM #HistoryData)
	BEGIN
		-- Update lates status
		UPDATE CS
			SET IsBlockedPlaceBet = CASE WHEN CS.IsBlockedPlaceBet = 1 THEN 1 ELSE PSD.IsBlockedPlaceBet END
				, IsBlockedTransfer = CASE WHEN CS.IsBlockedTransfer = 1 THEN 1 ELSE PSD.IsBlockedTransfer END
				,  ActionID =  CASE WHEN PSD.IsBlockedPlaceBet = 1 AND PSD.IsBlockedTransfer = 1 THEN 5
								   WHEN PSD.IsBlockedPlaceBet = 1 THEN 1
								   WHEN PSD.IsBlockedTransfer = 1 THEN 3
							   ELSE 0 END
				, ModifiedDate = @ReachedDate
		FROM #CustReachCWLList T
			INNER JOIN #HistoryData H ON T.CustId = H.CustId AND T.GroupID = H.GroupID AND T.ProductId = H.ProductId AND H.WinlostDate = T.WinlostDate
			INNER JOIN WinLimit_ProductSettingDetail psd WITH (NOLOCK) ON T.ProductId = psd.ProductId AND t.ExchangeID = psd.ExchangeID AND T.SiteID = PSD.SiteID AND T.LevelID = psd.LevelID AND psd.GroupID = T.GroupID			
			INNER JOIN WinLimit_GameGroupSetting GS WITH (NOLOCK) ON GS.GroupID = psd.GroupID 
			INNER JOIN WinLimit_CustGameStatus CS (NOLOCK) ON T.CustId = CS.CustId AND T.ProductId = CS.ProductID AND CS.BettypeID = GS.BetTypeID
		
		
		-- Insert Status	
		INSERT INTO WinLimit_CustGameStatus (CustID,ProductID,BettypeID,IsBlockedPlaceBet,IsBlockedTransfer,ActionID,ModifiedDate)
		SELECT T.CustId,T.ProductId,GS.BettypeID
				, PSD.IsBlockedPlaceBet
				, PSD.IsBlockedTransfer
				, CASE WHEN PSD.IsBlockedPlaceBet = 1 AND PSD.IsBlockedTransfer = 1 THEN 5
								   WHEN PSD.IsBlockedPlaceBet = 1 THEN 1
								   WHEN PSD.IsBlockedTransfer = 1 THEN 3
							   ELSE 0 END AS ActionID
				,@ReachedDate AS ModifiedDate
		FROM #CustReachCWLList T
			INNER JOIN #HistoryData H ON T.CustId = H.CustId AND T.GroupID = H.GroupID AND T.ProductId = H.ProductId AND H.WinlostDate = T.WinlostDate
			INNER JOIN WinLimit_ProductSettingDetail psd WITH (NOLOCK) ON T.ProductId = psd.ProductId AND t.ExchangeID = psd.ExchangeID	 AND T.SiteID = PSD.SiteID AND T.LevelID = psd.LevelID AND PSD.GroupID = T.GroupID
			INNER JOIN WinLimit_GameGroupSetting GS WITH (NOLOCK) ON GS.GroupID = psd.GroupID   
			LEFT JOIN WinLimit_CustGameStatus CS WITH (NOLOCK) ON T.CustId = CS.CustId AND T.ProductId = CS.ProductID AND GS.BetTypeID = CS.BettypeID
		WHERE CS.CustId IS NULL
					 
		WHILE 1 = 1 --exec by batch
		BEGIN
			--clear data
			
			SET @XmlData = ''
			SET @StrData = ''

			SET @XmlData = (
					SELECT C.CustId AS 'a1'
						, C.ProductId AS 'a2'
						, C.GroupID AS 'a3'
						, C.MaxWinLimit AS 'a4'
						, GM.TotalWinAmt AS 'a5'
						, GM.WinAmt  AS 'a6'
						, GM.LevelID  AS 'a7'
						, CASE WHEN PSD.IsBlockedPlaceBet = 1 AND PSD.IsBlockedTransfer = 1 THEN 5
							   WHEN PSD.IsBlockedPlaceBet = 1 THEN 1
							   WHEN PSD.IsBlockedTransfer = 1 THEN 3
							   ELSE 0 END AS 'a8'
						, GM.ModifiedDate  AS 'a9'
						, GM.IsNotified  AS 'a10'
						, GM.ModifiedBy  AS 'a11'
						, GM.CreatedBy  AS 'a12'
						, GM.WinlostDate  AS 'a13'
						, gm.MaxWinLimitSetting AS 'a14'
						, gm.TotalWinAmt_RM AS 'a15'
					FROM #HistoryData GM
						INNER JOIN #CustReachCWLList C WITH (NOLOCK) ON C.CustId = GM.CustID AND C.GroupID = GM.GroupID AND C.WinlostDate = GM.WinlostDate AND C.ProductId = GM.ProductID 
						INNER JOIN WinLimit_ProductSettingDetail PSD WITH (NOLOCK) ON GM.ProductID = PSD.ProductID AND C.ExchangeID = PSD.ExchangeID 
																					AND PSD.SiteID = C.SiteID AND PSD.LevelID = c.LevelID AND PSD.GroupID = C.GroupID
						
					WHERE GM.ID >= @StartRow AND GM.ID <= @StopRow
					
					FOR XML PATH('r'), ROOT ('root'), TYPE
				)
			
			SET @StrData = CONVERT(NVARCHAR(MAX), @XmlData)
		
			
			IF @StrData IS NULL
				BREAK

			EXEC dbo.Task_Winlimit_InsertHistoryData @XmlData = @StrData
			
			IF @StopRow = @MaxRow BREAK
						
			SET @StartRow = @StopRow + 1
			
			SET @StopRow = 1 + @StopRow + @Threshold
			
			IF @StopRow >= @MaxRow
				SET @StopRow = @MaxRow
		
		END
	END	
	DROP TABLE #HistoryData
	DROP TABLE #DataTmp
	DROP TABLE #CustReachCWLList
	DROP TABLE #DataTmp_pre
	
	
END

