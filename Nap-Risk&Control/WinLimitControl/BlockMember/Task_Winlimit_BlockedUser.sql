/*<info serverAlias="DBCUST-CUSTDB" executers="" viewers="" isFunction="0" isNested="0" ></info>*/
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
		- 20170810@Helen: NAP Risk & Control - Phase 4 - Win Loss Limit [Redmine: 72870]
		- 20171005@Johnson: Change request-Only notify once time for each level [Redmine:#84141]
		- 20180530@Johnson: enhance performance [Redmine: #95678]
		- 20200421@Elodie: Increase length of BettypeIDList
		- 20220722@Johnson: Scale Out DBTXN - get data on WinLimit_CustWinlostGame instead of Winlimit_CreditGame [Redmine:#175278]
		- 20230207@Johnson: get distinct data source to ignore duplicated game type in CWL notification service [redmine:#183536]
		- 20230407@Johnson: fix the case to show duplicate game name [redmine:#186608]
		- 20230830@Luke: Apply Company Max Payout rules per ticket [Redmine: #193014]
						 Change WinlostDate from DATETIME to SMALLDATETIME
		- 20230911@Tacy: CWL - Suspend member accounts when member reaches Yellow level on RNG Slots Games [RedmineID: #184911]
		- 20231101@Tacy: CWL - Support to show suspend information for suspended members [Redmine: #196155]
		- 20231214@Tacy: Risk Control - Member was not suspended after reaching Yellow Level [Redmine: #198396]
		- 20240307@Johnson: Enhance performance [redmine: #201794]
		- 20240808@Johnson: Apply Inhouse Replication for CWL [redmine: #209068]
		- 20250110@Tacy: Offer direct member for super/master [Redmine: #215809]
		- 20250328@Lani: NAP Risk & Control - Extend ExchangeID data type from TINYINT to SMALLINT [Redmine: #222190]
		- 20241107@Helios: Offer Direct Member for Super/Master [redmine: #211969]
		- 20250619@July: CWL - Alert Logic Update in Same Threshold Level [redmine: #229646]

	Param's Explanation:
	
*/
BEGIN
	SET NOCOUNT ON
	 
	DECLARE @StrData VARCHAR(MAX), @XmlData XML, @RowCount INT, @ReTry INT
	DECLARE @StartRow INT, @MaxRow INT,@Threshold INT, @StopRow INT
	DECLARE @WinlostDate SMALLDATETIME, @ReachedDate DATETIME
	DECLARE @WinlimitLevel_min INT, @WinlimitLevel_max INT, @LosslimitLevel_min INT, @LosslimitLevel_max INT
	
	-- suspend account
	DECLARE @CustID INT, @ProductID TINYINT,  @GroupID INT,
			@Message NVARCHAR(Max)

	SET @WinlimitLevel_min = 1
	SET @WinlimitLevel_max = 100
	
	SET @LosslimitLevel_min = 101
	SET @LosslimitLevel_max = 200
	
	CREATE TABLE #DataTmp_pre1 (CustId INT
							, ProductId TINYINT
							, Bettype SMALLINT
							, GroupID SMALLINT
							, TotalWinAmount MONEY
							, WinlostDate SMALLDATETIME)
	
	CREATE TABLE #DataTmp_pre (CustId INT
							, ProductId TINYINT
							, Bettype SMALLINT
							, GroupID SMALLINT
							, TotalWinAmount MONEY
							, WinlostDate SMALLDATETIME)
							
	CREATE TABLE #DataTmp (CustId INT
							, ExchangeID SMALLINT
							, SiteID INT
							, ProductId TINYINT
							, GroupID SMALLINT
							, TotalWinAmount MONEY
							, WinlostDate SMALLDATETIME
							, IsPrivateSetting BIT
							, BettypeIDList VARCHAR(MAX)							
							)
	
	CREATE CLUSTERED INDEX IX_DataTmp ON #DataTmp (CustID,WinlostDate,GroupID,ProductID)
	
	
	CREATE TABLE #CustReachCWLList(ID INT IDENTITY PRIMARY KEY
								, CustId INT
								, ProductId TINYINT
								, GroupID INT
								, WinlostDate SMALLDATETIME
								, LevelOrder TINYINT
								, LevelID TINYINT
								, IsReached BIT DEFAULT (0)	--ever reached yellow/red level within a day
								, IsSuspended BIT DEFAULT (0)
								, MaxWinLimit MONEY
								, TotalWinAmount MONEY
								, ExchangeID INT
								, SiteID INT
								, IsPrivateSetting BIT
								, MaxWinLimitSetting XML
								, TotalWinAmt_RM MONEY
								, BettypeIDList VARCHAR(MAX)
							)
		
	CREATE TABLE #HistoryData (ID INT IDENTITY PRIMARY KEY
							, CustId INT 
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
							, WinlostDate SMALLDATETIME
							, MaxWinLimitSetting XML
							, TotalWinAmt_RM MONEY
							, BettypeIDList VARCHAR(MAX)
						 )
						 
	CREATE TABLE #WinLimit_ProductSettingDetail (ProductId TINYINT
												, Bettype SMALLINT
												, GroupID SMALLINT
												, ExchangeID SMALLINT
												, SiteID INT
												, MaxWinLimitSetting NVARCHAR(MAX)
												)						 
	DECLARE @tbl_SuspendList TABLE (
				 CustId			INT
				,Username		VARCHAR(30)
				,TotalWinAmt	MONEY
				,ProductID		TINYINT
				,GroupID		INT 
				,UplineID		INT
				,UplineName		VARCHAR(30)
	)
	
	SELECT @WinlostDate = CAST(GETDATE() AS DATE)
	
	INSERT INTO #DataTmp_pre1(CustId, WinlostDate, Bettype, TotalWinAmount)
	SELECT DISTINCT CustId, WinlostDate, BetType, Winlost
	FROM WinLimit_CustWinlostGame WITH(NOLOCK)
	WHERE winlostdate = @winlostdate
	
	-- 20230407@Johnson: fix the case to show duplicate game name [redmine:#186608]
	INSERT INTO #DataTmp_pre(CustId, WinlostDate, Bettype, TotalWinAmount)
	SELECT DISTINCT CustId, WinlostDate, BetType, TotalWinAmount
	FROM #DataTmp_pre1
		
	-- Return if there is no data to process
	IF NOT EXISTS (SELECT TOP 1 1 FROM #DataTmp_pre WITH (NOLOCK))
	BEGIN
		RETURN
	END
	
	CREATE CLUSTERED INDEX IX_DataTmp_pre ON #DataTmp_pre (CustID,WinlostDate,GroupID,ProductID)
	
	UPDATE pre
		SET GroupID = GGS.GroupID, ProductId = GGS.ProductID
	FROM #DataTmp_pre pre WITH (NOLOCK)
		INNER JOIN dbo.Winlimit_GameGroupSetting GGS WITH (NOLOCK) ON pre.Bettype = GGS.BetTypeID
	
	INSERT INTO #DataTmp (CustId, WinlostDate, GroupID, TotalWinAmount,IsPrivateSetting,ProductId, BettypeIDList)
	SELECT CustId, WinlostDate, pre.GroupID, SUM(pre.TotalWinAmount),0 ,pre.ProductID, '' BettypeIDList
	FROM #DataTmp_pre pre WITH(NOLOCK)		
	GROUP BY CustId, WinlostDate, pre.GroupID,pre.ProductID
	
	UPDATE pre
	SET BettypeIDList = STUFF(tmp.BettypeIDList,1,1,'')
	FROM #DataTmp pre
	CROSS APPLY (SELECT ',' + CONVERT (VARCHAR(200), pre_1.Bettype)
					FROM #DataTmp_pre pre_1 WITH (NOLOCK) 
					WHERE pre_1.GroupID = pre.GroupID AND pre.CustId = pre_1.CustId
					FOR XML PATH ('')
					) AS Tmp (BettypeIDList)
					
	UPDATE t 
	SET ExchangeID = cc.currency
		, SiteID = s.siteid
		, IsPrivateSetting = CASE WHEN CGS.CustID IS NOT NULL THEN 1 ELSE 0 END 
	FROM #DataTmp t 
		INNER JOIN dbo.Customer cc WITH (NOLOCK) ON cc.custid = t.CustId
		INNER JOIN dbo.site s WITH (NOLOCK) ON s.site = cc.site
		-- just need one row returned, so checking level1 is fine to know whether this customer has private setting or not
		LEFT JOIN dbo.WinLimit_CustGameSetting CGS WITH (NOLOCK) ON CGS.CustID = T.CustId AND CGS.GroupID =  T.GroupID AND CGS.LevelID = 1
	OPTION(MAXDOP 8)
	
	--For Private Setting Processing
	IF EXISTS (SELECT 1 FROM #DataTmp WITH (NOLOCK) WHERE IsPrivateSetting = 1)
	BEGIN
		-- WIN LIMT
		IF EXISTS (SELECT 1 FROM #DataTmp WITH (NOLOCK) WHERE TotalWinAmount > 0) 
		BEGIN
			INSERT INTO #CustReachCWLList(CustId, ProductId, GroupID,WinlostDate,ExchangeID,SiteID, LevelOrder, MaxwinLimit, TotalWinAmount,IsPrivateSetting,MaxWinLimitSetting, BettypeIDList)
			SELECT t.CustId, t.ProductId, t.GroupID,t.WinlostDate,t.ExchangeID,t.SiteID, MAX(LS.LevelOrder) AS LevelOrder , MAX(s.MaxWinLimit) AS MaxWinLimit, MAX(t.TotalWinAmount) AS TotalWinAmount,1
					, CAST(tmp.MaxWinLimitSetting AS XML)
					, t.BettypeIDList
			FROM #DataTmp t WITH(NOLOCK)
				INNER JOIN dbo.WinLimit_CustGameSetting s WITH(NOLOCK) ON t.CustId = s.CustId AND t.ProductId = s.ProductId 
				INNER JOIN dbo.Winlimit_LevelSetting LS WITH (NOLOCK) ON LS.LevelID = S.LevelID
				INNER JOIN dbo.WinLimit_GameGroupSetting GS WITH (NOLOCK) ON GS.GroupID = S.GroupID AND GS.GroupID = T.GroupID
				CROSS APPLY (SELECT '<MaxWinLimitSetting' + x.str + '/>' 
							FROM (SELECT ' Level' + CAST(LevelID AS VARCHAR) + '="' + CAST(MaxWinLimit_RM AS VARCHAR) + '"'
								  FROM dbo.WinLimit_CustGameSetting S1 WITH (NOLOCK)
								  WHERE S1.CustID = T.CustId AND S1.ProductID = GS.ProductId AND S1.GroupID = GS.GroupID
								  FOR XML PATH('')
								) x(str)
				) AS tmp (MaxWinLimitSetting)
			WHERE	(t.TotalWinAmount > 0 AND t.TotalWinAmount >= s.MaxWinLimit AND s.LevelID >= @WinlimitLevel_min AND s.LevelID <= @WinlimitLevel_max) -- FOR WIN LIMIT
					AND s.MaxWinLimit > 0
					AND T.IsPrivateSetting = 1
			GROUP BY t.CustId, t.ProductId, t.GroupID,t.WinlostDate,t.ExchangeID,t.SiteID,tmp.MaxWinLimitSetting,t.BettypeIDList
		
		END
		-- LOSS LIMIT
		IF EXISTS (SELECT 1 FROM #DataTmp WITH (NOLOCK) WHERE TotalWinAmount < 0) 
		BEGIN
			INSERT INTO #CustReachCWLList(CustId, ProductId, GroupID,WinlostDate,ExchangeID,SiteID, LevelOrder, MaxwinLimit, TotalWinAmount,IsPrivateSetting,MaxWinLimitSetting, BettypeIDList)
			SELECT t.CustId, t.ProductId, t.GroupID,t.WinlostDate,t.ExchangeID,t.SiteID, MAX(LS.LevelOrder) AS LevelOrder , MIN(s.MaxWinLimit) AS MaxWinLimit, MAX(t.TotalWinAmount) AS TotalWinAmount,1
					, CAST(tmp.MaxWinLimitSetting AS XML)
					, t.BettypeIDList
			FROM #DataTmp t WITH(NOLOCK)
				INNER JOIN dbo.WinLimit_CustGameSetting s WITH(NOLOCK) ON t.CustId = s.CustId AND t.ProductId = s.ProductId 
				INNER JOIN dbo.Winlimit_LevelSetting LS WITH (NOLOCK) ON LS.LevelID = S.LevelID
				INNER JOIN dbo.WinLimit_GameGroupSetting GS WITH (NOLOCK) ON GS.GroupID = S.GroupID AND GS.GroupID = T.GroupID
				CROSS APPLY (SELECT '<MaxWinLimitSetting' + x.str + '/>' 
							FROM (SELECT ' Level' + CAST(LevelID AS VARCHAR) + '="' + CAST(MaxWinLimit_RM AS VARCHAR) + '"'
								  FROM dbo.WinLimit_CustGameSetting S1 WITH (NOLOCK)
								  WHERE S1.CustID = T.CustId AND S1.ProductID = GS.ProductId AND S1.GroupID = GS.GroupID
								  FOR XML PATH('')
								) x(str)
				) AS tmp (MaxWinLimitSetting)
			WHERE	( t.TotalWinAmount < 0 AND t.TotalWinAmount < = s.MaxWinLimit AND s.LevelID >= @LosslimitLevel_min AND s.LevelID <= @LosslimitLevel_max) -- FOR LOSS LIMIT
					AND s.MaxWinLimit < 0
					AND T.IsPrivateSetting = 1
			GROUP BY t.CustId, t.ProductId, t.GroupID,t.WinlostDate,t.ExchangeID,t.SiteID,tmp.MaxWinLimitSetting,t.BettypeIDList
		
		END
		
	END
	--For CURRENCY SETTING Processing
	IF EXISTS (SELECT 1 FROM #DataTmp WITH (NOLOCK) WHERE IsPrivateSetting = 0)
	BEGIN
		INSERT into #WinLimit_ProductSettingDetail(ProductId,GroupID,ExchangeID,SiteID,MaxWinLimitSetting)
		SELECT DISTINCT  t.ProductID,t.GroupID,t.ExchangeID,t.SiteID, '<MaxWinLimitSetting' + x.str + '/>' as MaxWinLimitSetting 			
		FROM (SELECT DISTINCT t.ProductID,t.GroupID,t.ExchangeID,t.SiteID
			FROM #DataTmp t
			)t			
		CROSS APPLY (
			SELECT ' Level' + CAST(LevelID AS VARCHAR) + '="' + CAST(MaxWinLimit_RM AS VARCHAR) + '"'
			FROM dbo.WinLimit_ProductSettingDetail S1 WITH (NOLOCK)
			WHERE S1.ProductID = t.ProductID AND S1.GroupID = t.GroupID AND S1.ExchangeID = t.ExchangeID AND S1.SiteID = t.SiteID			 
			FOR XML PATH('')
			  ) x(str)
			  
		-- WIN LIMT
		IF EXISTS (SELECT 1 FROM #DataTmp WITH (NOLOCK) WHERE TotalWinAmount > 0) 
		BEGIN	  
			INSERT INTO #CustReachCWLList(CustId, ProductId, GroupID,WinlostDate,ExchangeID,SiteID,LevelOrder, MaxwinLimit, TotalWinAmount,IsPrivateSetting,MaxWinLimitSetting,BettypeIDList)
			SELECT t.CustId, t.ProductId, t.GroupID,t.WinlostDate,t.ExchangeID,t.SiteID
					, MAX(LS.LevelOrder)
					, MAX(s.MaxWinLimit) 
					, MAX(t.TotalWinAmount)
					, 0
					, CAST(tmp.MaxWinLimitSetting AS XML)
					, t.BettypeIDList
			FROM #DataTmp t WITH(NOLOCK)
				INNER JOIN dbo.WinLimit_ProductSettingDetail s WITH(NOLOCK) ON t.ExchangeID = s.ExchangeID AND t.ProductId = s.ProductID AND T.SiteID = S.SiteID AND T.GroupID = S.GroupID
				INNER JOIN dbo.Winlimit_LevelSetting LS WITH (NOLOCK) ON LS.LevelID = S.LevelID
				INNER JOIN dbo.WinLimit_GameGroupSetting GS WITH (NOLOCK) ON GS.GroupID = S.GroupID
				INNER JOIN  #WinLimit_ProductSettingDetail tmp ON t.ExchangeID = tmp.ExchangeID AND t.ProductId = tmp.ProductID AND T.SiteID = tmp.SiteID AND T.GroupID = tmp.GroupID
			WHERE ( t.TotalWinAmount > 0 AND t.TotalWinAmount >= s.MaxWinLimit AND s.LevelID >= @WinlimitLevel_min AND s.LevelID <= @WinlimitLevel_max) -- FOR WIN LIMIT
					AND s.MaxWinLimit >  0
					AND T.IsPrivateSetting = 0
			GROUP BY t.CustId, t.ProductId, t.GroupID,t.WinlostDate,t.ExchangeID,t.SiteID,tmp.MaxWinLimitSetting, t.BettypeIDList
		END
		-- LOSS LIMIT
		IF EXISTS (SELECT 1 FROM #DataTmp WITH (NOLOCK) WHERE TotalWinAmount < 0) 
		BEGIN
			INSERT INTO #CustReachCWLList(CustId, ProductId, GroupID,WinlostDate,ExchangeID,SiteID,LevelOrder, MaxwinLimit, TotalWinAmount,IsPrivateSetting,MaxWinLimitSetting,BettypeIDList)
			SELECT t.CustId, t.ProductId, t.GroupID,t.WinlostDate,t.ExchangeID,t.SiteID
					, MAX(LS.LevelOrder)
					, MIN(s.MaxWinLimit) 
					, MAX(t.TotalWinAmount)
					, 0
					, CAST(tmp.MaxWinLimitSetting AS XML)
					, t.BettypeIDList
			FROM #DataTmp t WITH(NOLOCK)
				INNER JOIN dbo.WinLimit_ProductSettingDetail s WITH(NOLOCK) ON t.ExchangeID = s.ExchangeID AND t.ProductId = s.ProductID AND T.SiteID = S.SiteID AND T.GroupID = S.GroupID
				INNER JOIN dbo.Winlimit_LevelSetting LS WITH (NOLOCK) ON LS.LevelID = S.LevelID
				INNER JOIN dbo.WinLimit_GameGroupSetting GS WITH (NOLOCK) ON GS.GroupID = S.GroupID 
				INNER JOIN  #WinLimit_ProductSettingDetail tmp ON t.ExchangeID = tmp.ExchangeID AND t.ProductId = tmp.ProductID AND T.SiteID = tmp.SiteID AND T.GroupID = tmp.GroupID
			WHERE (t.TotalWinAmount < 0 AND t.TotalWinAmount < = s.MaxWinLimit AND s.LevelID >= @LosslimitLevel_min AND s.LevelID <= @LosslimitLevel_max) -- FOR LOSS LIMIT
					AND s.MaxWinLimit < 0
					AND T.IsPrivateSetting = 0
			GROUP BY t.CustId, t.ProductId, t.GroupID,t.WinlostDate,t.ExchangeID,t.SiteID,tmp.MaxWinLimitSetting, t.BettypeIDList
		
		END
	END
	
	IF NOT EXISTS (SELECT TOP 1 1 FROM #CustReachCWLList WITH(NOLOCK))
	BEGIN
		RETURN
	END
	
	SELECT @ReachedDate = GETDATE()
	
	-- Update LevelID based on LevelOrder
	UPDATE T
		SET LevelID = LS.LevelID
	FROM #CustReachCWLList T
		INNER JOIN dbo.Winlimit_LevelSetting LS WITH (NOLOCK) ON T.LevelOrder = LS.LevelOrder

	--check: ever reached yellow/red level (within a day)
	UPDATE T
		SET t.IsReached=1
	FROM #CustReachCWLList T
		CROSS APPLY (SELECT TOP 1 1 AS val 
					 FROM WinLimit_CustGameMonitoring_History g WITH (NOLOCK)
					 WHERE g.CustID=t.CustId AND g.ActionID IN (6,7)
						AND DATEDIFF(DAY, WinlostDate, @ReachedDate)=0
						AND g.LevelID BETWEEN 2 AND @WinlimitLevel_max) gm
		
	--Get: SuspendList, exclude: change setting IsSuspendedAccount 0 --> 1 only
	INSERT INTO @tbl_SuspendList (CustId, Username, UplineID, UplineName, TotalWinAmt, ProductID, GroupID)
	SELECT DISTINCT T.CustId, c.username, up.custid, up.username, t.TotalWinAmount, t.ProductId, t.GroupID
	FROM #CustReachCWLList T 
		INNER JOIN CustProductStatus cps WITH (NOLOCK) ON cps.CustID=t.CustId
		INNER JOIN Customer c WITH (NOLOCK) ON c.custid=T.CustId
		CROSS APPLY (SELECT custid, username	
					 FROM Customer sma WITH (NOLOCK)
					 WHERE sma.custid = CASE WHEN c.recommend=-4 THEN c.srecommend
											WHEN c.recommend=-3 THEN c.mrecommend
											ELSE c.recommend 
										END
					) up
		LEFT JOIN Dep_CustSuper cs WITH (NOLOCK) ON cs.custid=c.srecommend	
		LEFT JOIN WinLimit_CustGameMonitoring g WITH (NOLOCK) ON g.CustID=t.CustId AND g.ProductID=t.ProductId AND g.GroupID=t.GroupID AND g.LevelID=t.LevelID AND g.WinlostDate=t.WinlostDate --change setting only
		INNER JOIN dbo.WinLimit_ProductSettingDetail psd WITH (NOLOCK) ON T.ProductId = psd.ProductId AND t.ExchangeID = psd.ExchangeID	 AND t.SiteID = PSD.SiteID AND T.LevelID = psd.LevelID AND PSD.GroupID = T.GroupID
	WHERE T.LevelID BETWEEN 2 AND @WinlimitLevel_max AND psd.IsSuspendedAccount=1
		AND t.IsReached=0 AND cs.custid IS NULL --CREDIT ONLY
		AND cps.SuspendInfo=0 AND g.CustID IS NULL

	-- Update table Monitoring due to Changing Status of Currency Setting (Change Profile)
	UPDATE g
	SET 
		  ModifiedDate = @ReachedDate
		, IsNotified = 0
		, MaxwinLimit = t.MaxWinLimit
		, MaxWinLimitSetting = T.MaxWinLimitSetting
		, BettypeIDList = t.BettypeIDList
		, RepUpdateTime = dbo.f_GetDateTime2()
	OUTPUT inserted.CustId, inserted.ProductId,inserted.GroupID, inserted.MaxWinLimit, inserted.TotalWinAmt, inserted.WinAmt, inserted.LevelID  
			, inserted.ModifiedDate, inserted.IsNotified,inserted.ModifiedBy, inserted.CreatedBy, inserted.WinlostDate,inserted.MaxWinLimitSetting ,inserted.TotalWinAmt_RM,inserted.BettypeIDList
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
					, BettypeIDList
					) 
	FROM dbo.WinLimit_CustGameMonitoring g WITH(ROWLOCK, UPDLOCK)
		INNER JOIN #CustReachCWLList t WITH(NOLOCK) ON t.CustId = g.CustID AND g.WinlostDate = t.WinlostDate AND t.GroupID = g.GroupID AND g.ProductID = t.ProductId AND g.LevelID = t.LevelID
		INNER JOIN dbo.Winlimit_ProductSettingDetail psd WITH (NOLOCK) ON g.ProductId = psd.ProductId AND t.ExchangeID = psd.ExchangeID and g.LevelID = psd.LevelID AND psd.SiteID = t.SiteID AND psd.GroupID = t.GroupID
		CROSS APPLY (SELECT TOP 1 tmp.ActionID,tmp.IsBlockedTransfer,tmp.IsBlockedPlaceBet
					 FROM dbo.WinLimit_CustGameStatus tmp WITH (NOLOCK) 
						INNER JOIN dbo.WinLimit_GameGroupSetting GS WITH (NOLOCK) ON GS.GroupID = psd.GroupID AND tmp.BettypeID = gs.BetTypeID
					 WHERE  tmp.CustID = G.CustID AND tmp.ProductID = G.ProductID) AS CGS
	WHERE (psd.IsBlockedPlaceBet = 1 AND cgs.IsBlockedPlaceBet = 0 AND CGS.ActionID NOT IN (2,4)) 
		OR (psd.IsBlockedTransfer = 1 AND cgs.IsBlockedTransfer = 0 AND CGS.ActionID NOT IN (2,4))
		
	-- UPDATE when reaching Limit: Win or Loss 	
	UPDATE g
		SET MaxwinLimit = t.MaxWinLimit
			, TotalWinAmt = g.TotalWinAmt -  g.WinAmt + t.TotalWinAmount
			, WinAmt = t.TotalWinAmount
			, ModifiedDate = @ReachedDate
			, IsNotified = 0
			, LevelID = T.LevelID
			, MaxWinLimitSetting = t.MaxWinLimitSetting
			, TotalWinAmt_RM = CASE 
									WHEN T.ExchangeID = 20 THEN (g.TotalWinAmt -  g.WinAmt + t.TotalWinAmount) 
									ELSE  ROUND (e.actualrate * (g.TotalWinAmt -  g.WinAmt + t.TotalWinAmount),2)
								END
			, BettypeIDList = t.BettypeIDList
			, RepUpdateTime = dbo.f_GetDateTime2()
	OUTPUT inserted.CustId, inserted.ProductId,inserted.GroupID, inserted.MaxWinLimit, inserted.TotalWinAmt, inserted.WinAmt, inserted.LevelID  
			, inserted.ModifiedDate, inserted.IsNotified,inserted.ModifiedBy, inserted.CreatedBy, inserted.WinlostDate, inserted.MaxWinLimitSetting,inserted.TotalWinAmt_RM 
			, inserted.BettypeIDList 
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
					,TotalWinAmt_RM
					, BettypeIDList) 
		
	FROM dbo.WinLimit_CustGameMonitoring g WITH(ROWLOCK, UPDLOCK)
		INNER JOIN dbo.Winlimit_LevelSetting ls WITH (NOLOCK) ON g.LevelID = ls.LevelID
		INNER JOIN #CustReachCWLList t WITH(NOLOCK) ON t.CustId = g.CustID AND g.WinlostDate = t.WinlostDate AND t.GroupID = g.GroupID AND g.ProductID = t.ProductId		
		CROSS APPLY (SELECT TOP 1 tmp.ActionID,tmp.IsBlockedTransfer,tmp.IsBlockedPlaceBet
					 FROM dbo.WinLimit_CustGameStatus tmp WITH (NOLOCK) 
						INNER JOIN dbo.WinLimit_GameGroupSetting GS WITH (NOLOCK) ON GS.GroupID = t.GroupID AND tmp.BettypeID = gs.BetTypeID
					 WHERE  tmp.CustID = G.CustID AND tmp.ProductID = G.ProductID) AS CGS
		INNER JOIN dbo.Exchange e WITH (NOLOCK)  ON e.ExchangeId = T.ExchangeID
		OUTER APPLY (
			SELECT TOP 1 gh2.ModifiedDate, gh2.WinAmt, ls2.LevelOrder
			FROM dbo.WinLimit_CustGameMonitoring_History gh2 WITH(NOLOCK) 
				INNER JOIN dbo.Winlimit_LevelSetting ls2 WITH (NOLOCK) ON gh2.LevelID = ls2.LevelID
			WHERE g.CustID = gh2.CustID 
				AND g.WinlostDate = gh2.WinlostDate 
				AND g.GroupID = gh2.GroupID 
				AND g.ProductID = gh2.ProductID
				AND gh2.LevelID BETWEEN @WinlimitLevel_min AND @WinlimitLevel_max	
				AND gh2.ActionID < 200 
			ORDER BY ModifiedDate DESC
		)ls_win
	WHERE (
				-- cover for both Winlimt & LossLimit
				((	LS.LevelOrder < T.LevelOrder 
						--Enhance CWL to alert again when player reaches again the level within a day (the time reached compared to the previous reach is greater than 1 hour
						OR ( T.LevelID BETWEEN @WinlimitLevel_min AND @WinlimitLevel_max    -- LevelID of win limit
							AND LS.LevelOrder = T.LevelOrder AND DATEDIFF(MINUTE, g.ModifiedDate, @ReachedDate)>=60 AND g.WinAmt < t.TotalWinAmount )
					)
					--in case loss, if exists losslevel history which higher than losslevel customer reach again
					AND 1= (CASE WHEN T.LevelID >= @LosslimitLevel_min AND T.LevelID <= @LosslimitLevel_max 
							AND EXISTS(SELECT TOP 1 1
								FROM dbo.WinLimit_CustGameMonitoring_History gh1 WITH(NOLOCK) 
									INNER JOIN dbo.Winlimit_LevelSetting ls1 WITH (NOLOCK) ON gh1.LevelID = ls1.LevelID
								WHERE g.CustID = gh1.CustID 
									AND g.WinlostDate = gh1.WinlostDate 
									AND g.GroupID = gh1.GroupID 
									AND g.ProductID = gh1.ProductID	
									AND gh1.LevelID >= @LosslimitLevel_min AND gh1.LevelID <= @LosslimitLevel_max
									AND ls1.LevelOrder >= T.LevelOrder
									AND gh1.ActionID < 200
							)
						THEN 0 ELSE 1 END	
				))	
			-- from Loss Limit to Win limit (Level 101 -> Level 2): currently reaching loss limit (such as level 101) and then reach to winlimit (such as level 2) 
			OR (LS.LevelOrder > T.LevelOrder 
				AND T.LevelID BETWEEN @WinlimitLevel_min AND @WinlimitLevel_max    -- LevelID of win limit
				AND G.LevelID BETWEEN @LosslimitLevel_min AND @LosslimitLevel_max  -- LevelID of loss limit
				AND 1 = CASE WHEN ls_win.LevelOrder < T.LevelOrder OR ls_win.LevelOrder IS NULL THEN 1
							 --Enhance CWL to alert again when player reaches again the level within a day (the time reached compared to the previous reach is greater than 1 hour
							 WHEN ls_win.LevelOrder = t.LevelOrder AND DATEDIFF(MINUTE, ls_win.ModifiedDate, @ReachedDate)>=60 AND ls_win.WinAmt < t.TotalWinAmount THEN 1
				             ELSE 0 END
				) 
			-- Reach level again after unblocked
			--and not exists history level which customer reach
			OR (CGS.ActionID IN (2,4)
				AND NOT EXISTS(SELECT TOP 1 1
							FROM dbo.WinLimit_CustGameMonitoring_History gh3 WITH(NOLOCK) 
								INNER JOIN dbo.Winlimit_LevelSetting ls3 WITH (NOLOCK) ON gh3.LevelID = ls3.LevelID
							WHERE g.CustID = gh3.CustID 
								AND g.WinlostDate = gh3.WinlostDate 
								AND g.GroupID = gh3.GroupID 
								AND g.ProductID = gh3.ProductID
								AND 1 = CASE WHEN ((gh3.LevelID BETWEEN @WinlimitLevel_min AND @WinlimitLevel_max
													AND T.LevelID BETWEEN @WinlimitLevel_min AND @WinlimitLevel_max)
												 OR 
													(gh3.LevelID BETWEEN @LosslimitLevel_min AND @LosslimitLevel_max
													AND T.LevelID BETWEEN @LosslimitLevel_min AND @LosslimitLevel_max)
												)
												AND ls3.LevelOrder >= T.LevelOrder
											THEN 1 ELSE 0 END
								AND gh3.ActionID < 200 
							)				
				)
		)
	
	-- INSERT NEW
	INSERT INTO dbo.WinLimit_CustGameMonitoring(CustId, ProductID, GroupID,LevelID, MaxWinLimit, WinAmt, TotalWinAmt
		, IsNotified, CreatedBy,ModifiedDate ,WinlostDate,MaxWinLimitSetting,TotalWinAmt_RM,BettypeIDList, RepUpdateTime)
	
	OUTPUT inserted.CustId, inserted.ProductId,inserted.GroupID, inserted.MaxWinLimit, inserted.TotalWinAmt, inserted.WinAmt, inserted.LevelID  
				, inserted.ModifiedDate, inserted.IsNotified,inserted.ModifiedBy, inserted.CreatedBy, inserted.WinlostDate,inserted.MaxWinLimitSetting,inserted.TotalWinAmt_RM,inserted.BettypeIDList  
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
					, BettypeIDList ) 
							
	SELECT t.CustId, t.ProductId, t.GroupID,t.LevelID, t.MaxwinLimit, t.TotalWinAmount, t.TotalWinAmount, 0, NULL,@ReachedDate ,@WinlostDate,t.MaxWinLimitSetting
			, CASE WHEN T.ExchangeID = 20 THEN t.TotalWinAmount ELSE ROUND(e.actualrate * t.TotalWinAmount,2) END AS TotalWinAmt_RM, t.BettypeIDList AS BettypeIDList
			, dbo.f_GetDateTime2()
	FROM #CustReachCWLList t WITH(NOLOCK)
		LEFT JOIN dbo.WinLimit_CustGameMonitoring g WITH(NOLOCK) ON t.CustId = g.CustID AND t.WinlostDate = g.WinlostDate AND t.GroupID = g.GroupID
		INNER JOIN dbo.Exchange e WITH (NOLOCK)  ON e.ExchangeId = T.ExchangeID 
	WHERE g.CustID IS NULL
		
	-- Suspend member accounts if reaching Yellow/Red level
	WHILE EXISTS (SELECT TOP 1 1 FROM @tbl_SuspendList)
	BEGIN
		SELECT TOP 1 @CustID=CustId, @ProductID=ProductID, @GroupID=GroupID
		FROM @tbl_SuspendList

		IF ISNULL(@CustID,0)=0
			BREAK;

		--Suspend Account
		--@UserID = 10278938, --starixIT
		EXEC Acc_CustomerUpdSuspended @CustID=@CustID,@Suspended=1,@SubAccID=0,@UserID=10278938,@ActionID=75043
		
		--Send Personal Message for Agent
		SELECT @Message = CONVERT (NVARCHAR(MAX),
									(SELECT Username	AS '@Username'
										, TotalWinAmt	AS '@TotalWinAmt'
										, ProductID		AS '@ProductID'
										, UplineID		AS '@recommend'
										, UplineName	AS '@rUsername'
									FROM @tbl_SuspendList
									WHERE CustId=@CustID 
										AND ProductID=@ProductID
										AND GroupID=@GroupID
									FOR XML PATH ('Msg'), ROOT('Root')))			
									
		EXEC NAP_WinLimit_PersonalMessageIns @Message=@Message

		--update Suspend:
		UPDATE T
		SET t.IsSuspended=1
		FROM #CustReachCWLList t 
		WHERE CustId=@CustID 
		AND ProductID=@ProductID
		AND GroupID=@GroupID

		DELETE FROM @tbl_SuspendList
		WHERE CustId=@CustID
	END

	IF EXISTS (SELECT 1 FROM #HistoryData)
	BEGIN
		-- Update lates status
		UPDATE CS
			SET IsBlockedPlaceBet = CASE WHEN CS.IsBlockedPlaceBet = 1 THEN 1 ELSE PSD.IsBlockedPlaceBet END
				, IsBlockedTransfer = CASE WHEN CS.IsBlockedTransfer = 1 THEN 1 ELSE PSD.IsBlockedTransfer END
				,  ActionID =  CASE WHEN PSD.IsBlockedPlaceBet = 1 AND PSD.IsBlockedTransfer = 1 THEN 5
									WHEN PSD.IsBlockedPlaceBet = 1 AND PSD.IsSuspendedAccount = 1 AND T.IsSuspended=1 THEN 7
									WHEN PSD.IsSuspendedAccount=1 AND T.IsSuspended=1 THEN 6
								   WHEN PSD.IsBlockedPlaceBet = 1 THEN 1
								   WHEN PSD.IsBlockedTransfer = 1 THEN 3
							   ELSE 0 END
				, ModifiedDate = @ReachedDate
				, RepUpdateTime = dbo.f_GetDateTime2()
		FROM #CustReachCWLList T WITH(NOLOCK)
			INNER JOIN #HistoryData H WITH(NOLOCK) ON T.CustId = H.CustId AND T.GroupID = H.GroupID AND T.ProductId = H.ProductId AND H.WinlostDate = T.WinlostDate
			INNER JOIN dbo.WinLimit_ProductSettingDetail psd WITH (NOLOCK) ON T.ProductId = psd.ProductId AND t.ExchangeID = psd.ExchangeID AND T.SiteID = PSD.SiteID AND T.LevelID = psd.LevelID AND psd.GroupID = T.GroupID			
			INNER JOIN dbo.WinLimit_GameGroupSetting GS WITH (NOLOCK) ON GS.GroupID = psd.GroupID 
			INNER JOIN dbo.WinLimit_CustGameStatus CS WITH(NOLOCK) ON T.CustId = CS.CustId AND T.ProductId = CS.ProductID AND CS.BettypeID = GS.BetTypeID
		
		-- Insert New for Status	
		INSERT INTO dbo.WinLimit_CustGameStatus (CustID,ProductID,BettypeID,IsBlockedPlaceBet,IsBlockedTransfer,ActionID,ModifiedDate,RepUpdateTime)
		SELECT T.CustId,T.ProductId,GS.BettypeID
				, PSD.IsBlockedPlaceBet
				, PSD.IsBlockedTransfer
				, CASE WHEN PSD.IsBlockedPlaceBet = 1 AND PSD.IsBlockedTransfer = 1 THEN 5
						WHEN PSD.IsBlockedPlaceBet = 1 AND PSD.IsSuspendedAccount = 1 AND T.IsSuspended=1 THEN 7
						WHEN PSD.IsSuspendedAccount=1 AND T.IsSuspended=1 THEN 6
						WHEN PSD.IsBlockedPlaceBet = 1 THEN 1
						WHEN PSD.IsBlockedTransfer = 1 THEN 3
						ELSE 0 END AS ActionID
				,@ReachedDate AS ModifiedDate
				,dbo.f_GetDateTime2()
		FROM #CustReachCWLList T WITH(NOLOCK)
			INNER JOIN #HistoryData H WITH(NOLOCK) ON T.CustId = H.CustId AND T.GroupID = H.GroupID AND T.ProductId = H.ProductId AND H.WinlostDate = T.WinlostDate
			INNER JOIN dbo.WinLimit_ProductSettingDetail psd WITH (NOLOCK) ON T.ProductId = psd.ProductId AND t.ExchangeID = psd.ExchangeID	 AND T.SiteID = PSD.SiteID AND T.LevelID = psd.LevelID AND PSD.GroupID = T.GroupID
			INNER JOIN dbo.WinLimit_GameGroupSetting GS WITH (NOLOCK) ON GS.GroupID = psd.GroupID   
			LEFT JOIN dbo.WinLimit_CustGameStatus CS WITH (NOLOCK) ON T.CustId = CS.CustId AND T.ProductId = CS.ProductID AND GS.BetTypeID = CS.BettypeID
		WHERE CS.CustId IS NULL
		
		-- Insert History processing: process batch by batch: 500 for each batch 
		SET @Threshold = 500
		SET @StartRow = 1
		SET @MaxRow = (SELECT MAX(ID) FROM #HistoryData)
			
		IF @Threshold >= @MaxRow
			SET @Threshold = @MaxRow
	
		SET @StopRow = @Threshold
	
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
							   WHEN PSD.IsBlockedPlaceBet = 1 AND PSD.IsSuspendedAccount = 1 AND C.IsSuspended=1 THEN 7
							   WHEN PSD.IsSuspendedAccount=1 AND C.IsSuspended=1 THEN 6
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
						, gm.BettypeIDList AS 'a16'
					FROM #HistoryData GM WITH(NOLOCK)
						INNER JOIN #CustReachCWLList C WITH (NOLOCK) ON C.CustId = GM.CustID AND C.GroupID = GM.GroupID AND C.WinlostDate = GM.WinlostDate AND C.ProductId = GM.ProductID 
						INNER JOIN dbo.WinLimit_ProductSettingDetail PSD WITH (NOLOCK) ON GM.ProductID = PSD.ProductID AND C.ExchangeID = PSD.ExchangeID 
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
	DROP TABLE #DataTmp_pre1
	DROP TABLE #WinLimit_ProductSettingDetail
END
GO