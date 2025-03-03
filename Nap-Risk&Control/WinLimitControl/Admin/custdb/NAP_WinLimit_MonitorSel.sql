/*<info serverAlias="DBCUST-CustDB" executers="wsv_nap" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE NAP_WinLimit_MonitorSel @FromDate			DATETIME,
                                        @ToDate				DATETIME,
                                        @ProductId			INT         = 0,
                                        @UserName			NVARCHAR(50)= '',
                                        @MultiSite			VARCHAR(Max)= '0',
                                        @CurrencyId			INT         = 0,
                                        @LevelId			VARCHAR(50) = '1,2,3,101,102',
                                        @ExcludeTestData	BIT         = 1
AS  
/*  
	Created: Franklin   
	Date: 2016-06-22  
	Task: #57722 - Implement Game Win Limit Control phase2  
  
	DB: DBCUST/CustDB  
  
	Revisions:  
		- 20160923@Jacob: Risk & Control - Phase 3 [#61220].  
		- 20170321@Hellen: Risk & Control - Phase 3A [#72604].  
		- 20170515@Helen: NAP Risk & Control - CHANGE REQUEST [Redmine: 75332] 
		- 20170808@Jacob: Risk & Control - Phase 4 [#72870]
		- 20171016@Jacob: Support multiple selection on dropdownlist "Reached Limit Level" [#84893]
		- 20220614@Eden: DBCUST - modify sp syntax to adapt with the SQL Server upgrade to 2019 [Redmine: #171831] 
		- 20230215@Tacy: CWL - Split 789y site [RedmineID: #182387]
		- 20230829@Luke: Apply Company Max Payout rules per ticket [Redmine: #193014]
		- 20231101@Tacy: CWL - Support to show suspend information for suspended members [Redmine: #196155]
		- 20250225@Virgil: CWL - Support export data in Win Loss Limit Monitor [Redmine: #217147]

	Parameters Explanation:   
	   @FromDate: From date  
	   @ToDate: To Date  
	   @ProductId: Product ID  
	   @UserName: UserName  
	   @MultiSite	: 0 ~ all site; <>0 ~ Site 
	   @CurrencyId: Currency ID  
	   @LevelId: Level Id  
     
	Example:  
	EXEC NAP_WinLimit_MonitorSel @FromDate = '20160101', @ToDate = '20191231'  
*/

BEGIN
    SET NOCOUNT ON;

    BEGIN --LevelIdTable
        DECLARE @Levels TABLE(LevelId INT);
        INSERT INTO @Levels(LevelId)
            SELECT CONVERT(INT, value)
            FROM STRING_SPLIT(@LevelId, ',')
			WHERE value <> ''
    END;
	BEGIN --Site
		DECLARE @Site TABLE (siteID INT)
		
		IF @MultiSite='0'
		BEGIN
			INSERT INTO @Site(siteID)
			SELECT siteid
			FROM Site WITH (NOLOCK)
			WHERE isActive=1
		END
		ELSE
		BEGIN
			INSERT INTO @Site(siteID)
			SELECT TRIM(value) SiteID
			FROM STRING_SPLIT(@MultiSite, ',')
		END
	END;
    BEGIN -- #WinLimitMonitor  
        CREATE TABLE #WinLimitMonitor (
			CustId				INT,
			UserName			NVARCHAR(50),
			ProductId			INT,
			GroupId				INT,
			ReachedLimitLevel	SMALLINT,
			TotalWinAmount		MONEY,
			TotalWinAmountRM	MONEY,
			ModifiedDate		DATETIME,
			CurrencyId			INT,
			SiteId				INT,
			IsNotified			BIT,
			IsSuspendedAccount	BIT,
			MaxWinLimitSetting	XML,
			MaxWinLimit_RM		MONEY,
			BettypeIDList		VARCHAR(1024)
        );
        INSERT INTO #WinLimitMonitor (
			CustId,
			UserName,
			ProductId,
			GroupId,
			ReachedLimitLevel,
			TotalWinAmount,
			TotalWinAmountRM,
			ModifiedDate,
			CurrencyId,
			SiteId,
			IsNotified,
			IsSuspendedAccount,
			MaxWinLimitSetting,
			MaxWinLimit_RM,
			BettypeIDList
        )
            SELECT cm.CustID,
                    ci.username,
                    cm.ProductID,
                    cm.GroupID,
                    cm.LevelID,
                    cm.TotalWinAmt,
                    cm.TotalWinAmt_RM,
                    cm.ModifiedDate,
                    c.currency,
                    s.siteid,
                    cmh_notified.IsNotified,
					CASE WHEN cmh_suspended.IsSuspended IS NOT NULL THEN 1 ELSE 0 END IsSuspendedAccount,
                    cm.MaxWinLimitSetting,
					CASE
						WHEN cm.Levelid = 1 THEN cm.MaxWinLimitSetting.value ('(/MaxWinLimitSetting/@Level1)[1]', 'MONEY')
						WHEN cm.LevelID = 2 THEN cm.MaxWinLimitSetting.value ('(/MaxWinLimitSetting/@Level2)[1]', 'MONEY')
						WHEN cm.LevelID = 3 THEN cm.MaxWinLimitSetting.value ('(/MaxWinLimitSetting/@Level3)[1]', 'MONEY')
						WHEN cm.LevelID = 101 THEN cm.MaxWinLimitSetting.value ('(/MaxWinLimitSetting/@Level101)[1]', 'MONEY')
						WHEN cm.LevelID = 102 THEN cm.MaxWinLimitSetting.value ('(/MaxWinLimitSetting/@Level102)[1]', 'MONEY')
					END AS MaxWinLimit_RM,
					cm.BettypeIDList
            FROM WinLimit_CustGameMonitoring cm WITH (NOLOCK)
                    CROSS APPLY
            (
                SELECT TOP 1 IsNotified
                FROM WinLimit_CustGameMonitoring_History cmh WITH (NOLOCK)
                WHERE cm.CustID = cmh.CustID
                        AND cm.ProductID = cmh.ProductID
                        AND cm.GroupID = cmh.GroupID
                        AND cm.LevelID = cmh.LevelID
                        AND cm.WinlostDate = cmh.WinlostDate
						AND cmh.ActionID < 200
                ORDER BY IsNotified
            ) AS cmh_notified
					OUTER APPLY 
			(
                SELECT TOP 1 1 AS IsSuspended
                FROM WinLimit_CustGameMonitoring_History cmh WITH (NOLOCK)
                WHERE cm.CustID = cmh.CustID
                        AND cm.ProductID = cmh.ProductID
                        AND cm.GroupID = cmh.GroupID
                        AND cm.WinlostDate = cmh.WinlostDate
						AND cmh.ActionID IN (6,7)
            ) AS cmh_suspended
                    INNER JOIN dbo.custInfo ci WITH (NOLOCK) ON cm.CustID = ci.CustID
                    INNER JOIN dbo.Customer c WITH (NOLOCK) ON c.custid = ci.recommend
                    INNER JOIN dbo.Site s WITH (NOLOCK) ON s.site = c.site
                    INNER JOIN @Levels l ON cm.LevelID = l.LevelId
					CROSS APPLY (SELECT 1 val FROM @Site ss WHERE ss.siteID=s.siteid) ss 
            WHERE cm.ModifiedDate BETWEEN @FromDate AND @Todate
                    AND (@ProductId = 0
                        OR cm.ProductID = @ProductId)
                    AND (@CurrencyId = 0
                        OR ci.currency = @CurrencyId)
                    AND (@ExcludeTestData = 0
                        OR ci.currency NOT IN(20, 72)) -- UUS & YNG  
                    AND ci.roleid = 1
                    AND (LEN(@UserName) = 0
                        OR ci.username = @UserName);
    END;

    BEGIN -- Query data  
        SELECT m.CustId,
            m.UserName,
            m.SiteId,
            m.CurrencyId,
            m.ProductId,
            m.GroupId,
            m.TotalWinAmount,
            m.TotalWinAmountRM,
            m.ModifiedDate AS ReachedLimitTime,
            m.ReachedLimitLevel,
            m.MaxWinLimitSetting,
        (
            SELECT COUNT(1)
            FROM dbo.WinLimit_CustGameMonitoring_History h WITH (NOLOCK)
            WHERE h.ModifiedDate BETWEEN CONVERT(DATETIME, CONVERT(NVARCHAR(101), m.ModifiedDate, 111)+' 00:00:00') AND CONVERT(DATETIME, CONVERT(NVARCHAR(101), m.ModifiedDate, 111)+' 23:59:59.997')
                AND h.LevelID = m.ReachedLimitLevel
                AND h.CustID = m.CustId
                AND h.ProductID = m.ProductId
                AND h.GroupID = m.GroupId
                AND h.ActionID NOT IN(2, 4)
				AND h.ActionID < 200
        ) AS NumberReachedLimit,
            m.IsNotified,
			IsSuspendedAccount,
            cs.IsBlockedPlaceBet,
            cs.IsBlockedTransfer,
            CASE
                WHEN cm.ModifiedDate IS NOT NULL
                THEN 1
                ELSE 0
            END AS IsEnableUnBlock,
			MaxWinLimit_RM,
			BettypeIDList
        FROM #WinLimitMonitor m
            CROSS APPLY
        (
            SELECT TOP 1 IsBlockedPlaceBet,
                        IsBlockedTransfer
            FROM WinLimit_CustGameStatus cs WITH (NOLOCK)
                INNER JOIN dbo.WinLimit_GameGroupSetting gs WITH (NOLOCK) ON cs.BettypeID = gs.BetTypeID
                                                                            AND GS.GroupID = M.GroupId
            WHERE cs.CustID = m.CustId
        ) AS cs
            LEFT JOIN
        (
            SELECT CustID,
                ProductID,
                GroupID,
                MAX(ModifiedDate) AS ModifiedDate
            FROM dbo.WinLimit_CustGameMonitoring WITH (NOLOCK)
            GROUP BY CustID,
                    ProductID,
                    GroupID
        ) AS cm ON cm.CustId = m.CustId
                AND cm.ModifiedDate = m.ModifiedDate
                AND cm.ProductID = m.ProductID
                AND cm.GroupID = m.GroupId
        ORDER BY ReachedLimitTime DESC;
    END;

    DROP TABLE #WinLimitMonitor;
END;
GO
