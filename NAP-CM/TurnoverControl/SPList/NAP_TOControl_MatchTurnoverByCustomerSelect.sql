/*<info serverAlias="DBAGE-bodb02" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[NAP_TOControl_MatchTurnoverByCustomerSelect]
	@CustID INT,
	@RoleID TINYINT,
	@IsGroupHeadline BIT = 0,
	@SportType SMALLINT = 1
		
AS
/*
	Created: Don
	Date: 2017-03-28
	Task: ???
	DB: DBAGE.bodb02

	Revisions:
		- 20170920@Helen: TO Control Phase 3 - [Redmine: 75557]
		- 20171212@Helen: Implement some change request from OPS Team - [Redmine: 85638]
		
	Parameter's explaination: 
		Bettypes for SportBook:((bettype < 31 and bettype NOT IN (9,29,10)) OR bettype between 121 and 999 OR bettype BETWEEN 1301 and 1334)
		Bettypes get from SportBettypeMatrix: f_SportBettypeMatrix_Sel
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @MatchList TABLE (matchid INT)
		
	DECLARE @GroupHeadlineList TABLE (CustID INT PRIMARY KEY, RoleID INT, srecommend INT, IsMemberExcluded BIT)
	DECLARE @CurrentDate DATE, @srecommend INT
	
	DECLARE @EventDate_min DATETIME
	
	CREATE TABLE #TicketGroupHeadlineList (matchid INT,TotalStake MONEY, TotalHouseTO MONEY)
	CREATE TABLE #ExtraPTInfo (SuperID INT,ExtraPT DECIMAL(9,8), fromDate DATETIME, todate DATETIME)
	
	-- Check SP Version
	DECLARE @isTest BIT = 0
	SELECT  @isTest = dbo.f_CheckSPVersion(@@PROCID)
	
	CREATE TABLE  #SportBettype (Bettype SMALLINT PRIMARY KEY)
	-- Get list of Bettype of sportbook
	INSERT INTO #SportBettype (Bettype)
	SELECT DISTINCT Bettype FROM bodb02.dbo.f_SportBettypeMatrix_Sel (1, 0, 0, 2, '', '', @isTest)
		
	INSERT INTO @MatchList(matchid)
	SELECT m.matchid
	FROM bodb02.dbo.match m WITH(NOLOCK)
	WHERE m.eventstatus <> 'completed' 
		AND (
				-- Soccer
				(@SportType = 1 AND sporttype = 1) 
				OR 
				-- Other sports
				(@SportType = 99 AND sporttype > 1 AND sporttype <=99 )
			 )
			 
	SET @EventDate_min = (SELECT MIN(eventdate) FROM bodb02.dbo.match m WITH(NOLOCK))
	
	-- Process for Headline Level
	IF @IsGroupHeadline = 1
	BEGIN
		-- Get all under this Headline
		INSERT INTO @GroupHeadlineList (CustID, RoleID,srecommend,IsMemberExcluded)
		SELECT ca1.custid,ci.roleid,ci.srecommend,IsMemberExcluded =  CASE WHEN CI.roleid = 1 
											AND EXISTS (SELECT 1 FROM bodb02.dbo.custAccount CA_tmp WITH (NOLOCK) 
														WHERE CA_tmp.groupID = ca.GroupID AND CA_tmp.custID IN (ci.srecommend, ci.mrecommend, ci.recommend))
										THEN 1 ELSE 0 END	
		FROM bodb02.dbo.CustGroupHeadline ca WITH (NOLOCK)
			INNER JOIN bodb02.dbo.custAccount ca1 WITH (NOLOCK) ON ca.groupID = ca1.groupID
			INNER JOIN bodb02.dbo.custInfo ci WITH (NOLOCK) ON ci.custid = ca1.custid
		WHERE ca.custid = @CustID 
		
		-- Get Extra PT Info: 
			-- Sportbook: Categorized by SubProduct =  '' , 'MG-SuperLive', 'MuayThai'. They are the same value. 
			-- So, only based on  conditions: Productid = 1, Sporttype = 0,SubProduct= '' 
			
		INSERT INTO #ExtraPTInfo (SuperID,ExtraPT,fromDate,todate)
		SELECT GHL.CustID,ISNULL(EPT.ExtraPT,0),EPT.FromDate,EPT.ToDate
		FROM @GroupHeadlineList GHL
			LEFT JOIN dbo.Acc_GroupExtraPTSetting EPT WITH (NOLOCK) ON GHL.srecommend = EPT.SuperId 
																	AND EPT.ProductId = 1 
																	AND EPT.Sporttype = 0 
																	AND EPT.SubProduct = ''
																	AND EPT.ToDate >= @EventDate_min
																	
		
		IF EXISTS (SELECT 1 FROM @GroupHeadlineList WHERE RoleID = 4)
		BEGIN
			INSERT INTO #TicketGroupHeadlineList (matchid,TotalStake,TotalHouseTO)
			SELECT 
				b.matchid, 
				
				SUM(b.stake * (CASE WHEN b.currency = 20 THEN 1 ELSE  b.actualrate END)) AS SumOfStake, 
				SUM((1-b.tpositiontaking - ISNULL(ExtraPT_tmp.ExtraPT,0))* ABS(b.stake) * (CASE WHEN b.currency = 20 THEN 1 ELSE  b.actualrate END)) AS HouseTurnover
					 
			FROM bodb02.dbo.bettrans b WITH(NOLOCK)
				INNER JOIN @MatchList m ON b.matchid = m.matchid
				INNER JOIN #SportBettype bt WITH (NOLOCK) ON bt.Bettype = b.bettype
				OUTER APPLY (SELECT SUM(s.ExtraPT) AS ExtraPT 
						 FROM #ExtraPTInfo s WITH(NOLOCK) 
						 WHERE b.srecommend = s.SuperId AND b.winlostdate BETWEEN s.FromDate AND s.ToDate ) AS ExtraPT_tmp
						 
			WHERE b.srecommend IN (SELECT custid FROM @GroupHeadlineList GHL WHERE RoleID = 4)
				AND b.statusid NOT BETWEEN 101 AND 103
				AND b.betfrom <> 'p'
				
			GROUP BY b.matchid
			
		END
		
		IF EXISTS (SELECT 1 FROM @GroupHeadlineList WHERE RoleID = 3)
		BEGIN
			INSERT INTO #TicketGroupHeadlineList (matchid,TotalStake,TotalHouseTO)
			SELECT 
				b.matchid, 
				
				SUM(b.stake * (CASE WHEN b.currency = 20 THEN 1 ELSE  b.actualrate END)) AS SumOfStake, 
				SUM((1-b.tpositiontaking - ISNULL(ExtraPT_tmp.ExtraPT,0))* ABS(b.stake) * (CASE WHEN b.currency = 20 THEN 1 ELSE  b.actualrate END)) AS HouseTurnover
				
			FROM bodb02.dbo.bettrans b WITH(NOLOCK)
				INNER JOIN @MatchList m ON b.matchid = m.matchid
				INNER JOIN #SportBettype bt WITH (NOLOCK) ON bt.Bettype = b.bettype
				OUTER APPLY (SELECT SUM(s.ExtraPT) AS ExtraPT 
						 FROM #ExtraPTInfo s WITH(NOLOCK) 
						 WHERE b.srecommend = s.SuperId AND b.winlostdate BETWEEN s.FromDate AND s.ToDate ) AS ExtraPT_tmp
			WHERE b.mrecommend IN (SELECT custid FROM @GroupHeadlineList GHL WHERE RoleID = 3)
				AND b.statusid NOT BETWEEN 101 AND 103
				AND b.betfrom <> 'p'
			GROUP BY b.matchid	
		END
		
		IF EXISTS (SELECT 1 FROM @GroupHeadlineList WHERE RoleID = 2)
		BEGIN
			INSERT INTO #TicketGroupHeadlineList (matchid,TotalStake,TotalHouseTO)
			SELECT 
				b.matchid, 
				
				SUM(b.stake * (CASE WHEN b.currency = 20 THEN 1 ELSE  b.actualrate END)) AS SumOfStake, 
				SUM((1-b.tpositiontaking - ISNULL(ExtraPT_tmp.ExtraPT,0))* ABS(b.stake) * (CASE WHEN b.currency = 20 THEN 1 ELSE  b.actualrate END)) AS HouseTurnover
					 
			FROM bodb02.dbo.bettrans b WITH(NOLOCK)
				INNER JOIN @MatchList m ON b.matchid = m.matchid
				INNER JOIN #SportBettype bt WITH (NOLOCK) ON bt.Bettype = b.bettype
				OUTER APPLY (SELECT SUM(s.ExtraPT) AS ExtraPT 
						 FROM #ExtraPTInfo s WITH(NOLOCK) 
						 WHERE b.srecommend = s.SuperId AND b.winlostdate BETWEEN s.FromDate AND s.ToDate ) AS ExtraPT_tmp
			WHERE b.recommend IN (SELECT custid FROM @GroupHeadlineList GHL WHERE RoleID = 2)
				AND b.statusid NOT BETWEEN 101 AND 103
				AND b.betfrom <> 'p'
			GROUP BY b.matchid	
		END
		
		IF EXISTS (SELECT 1 FROM @GroupHeadlineList WHERE RoleID = 1)
		BEGIN
			INSERT INTO #TicketGroupHeadlineList (matchid,TotalStake,TotalHouseTO)
			SELECT 
				b.matchid, 
				
				SUM(b.stake * (CASE WHEN b.currency = 20 THEN 1 ELSE  b.actualrate END)) AS SumOfStake, 
				SUM((1-b.tpositiontaking - ISNULL(ExtraPT_tmp.ExtraPT,0))* ABS(b.stake) * (CASE WHEN b.currency = 20 THEN 1 ELSE  b.actualrate END)) AS HouseTurnover
					 
			FROM bodb02.dbo.bettrans b WITH(NOLOCK)
				INNER JOIN @MatchList m ON b.matchid = m.matchid
				INNER JOIN #SportBettype bt WITH (NOLOCK) ON bt.Bettype = b.bettype
				OUTER APPLY (SELECT SUM(s.ExtraPT) AS ExtraPT 
						 FROM #ExtraPTInfo s WITH(NOLOCK) 
						 WHERE b.srecommend = s.SuperId AND b.winlostdate BETWEEN s.FromDate AND s.ToDate ) AS ExtraPT_tmp
			WHERE b.custid IN (SELECT custid FROM @GroupHeadlineList GHL WHERE RoleID = 1 AND IsMemberExcluded = 0)
				AND b.statusid NOT BETWEEN 101 AND 103
				AND b.betfrom <> 'p'
			GROUP BY b.matchid		
		END
		
		SELECT 
				matchid, 
				SUM(TotalStake) AS SumOfStake, 
				SUM(TotalHouseTO) AS HouseTurnover
		FROM #TicketGroupHeadlineList  WITH(NOLOCK)
		GROUP BY matchid
		
	END
	-- Process for Super/Master/Agent Level
	ELSE 
	BEGIN
		SET @Srecommend = (SELECT srecommend FROM dbo.custInfo WITH (NOLOCK) WHERE custid = @CustID)
		
		-- Get Extra PT Info: 
			-- Sportbook: Categorized by SubProduct =  '' , 'MG-SuperLive', 'MuayThai'. They are the same value. 
			-- So, only based on  conditions: Productid = 1, Sporttype = 0,SubProduct= '' 
		INSERT INTO #ExtraPTInfo (SuperID,ExtraPT,fromDate,todate)
		SELECT @Srecommend,EPT.ExtraPT,EPT.FromDate,EPT.ToDate
		FROM Acc_GroupExtraPTSetting EPT WITH (NOLOCK)
		WHERE EPT.SuperId = @Srecommend AND EPT.ProductId = 1 AND EPT.Sporttype  = 0 AND EPT.SubProduct = '' AND EPT.ToDate >= @EventDate_min
		
		IF (@RoleID = 4)
		BEGIN
			SELECT 
				b.matchid, 
				SUM(b.stake) AS SumOfStake, 
				SUM((1-b.tpositiontaking - ISNULL(ExtraPT_tmp.ExtraPT,0))*b.stake) AS HouseTurnover
			FROM bodb02.dbo.bettrans b WITH(NOLOCK)
				INNER JOIN @MatchList m ON b.matchid = m.matchid
				INNER JOIN #SportBettype bt WITH (NOLOCK) ON bt.Bettype = b.bettype
				OUTER APPLY (SELECT SUM(s.ExtraPT) AS ExtraPT 
							 FROM #ExtraPTInfo s WITH(NOLOCK) 
							 WHERE b.srecommend = s.SuperId AND b.winlostdate BETWEEN s.FromDate AND s.ToDate ) AS ExtraPT_tmp
			WHERE b.srecommend = @CustID
				AND b.statusid NOT BETWEEN 101 AND 103
				AND b.betfrom <> 'p'
			GROUP BY b.matchid

		END
		ELSE IF (@RoleID = 3)
		BEGIN
			SELECT 
				b.matchid, 
				SUM(b.stake) AS SumOfStake, 
				SUM((1-b.tpositiontaking - ISNULL(ExtraPT_tmp.ExtraPT,0))*b.stake) AS HouseTurnover
			FROM bodb02.dbo.bettrans b WITH(NOLOCK)
				INNER JOIN @MatchList m ON b.matchid = m.matchid
				INNER JOIN #SportBettype bt WITH (NOLOCK) ON bt.Bettype = b.bettype
				OUTER APPLY (SELECT SUM(s.ExtraPT) AS ExtraPT 
						 FROM #ExtraPTInfo s WITH(NOLOCK) 
						 WHERE b.srecommend = s.SuperId AND b.winlostdate BETWEEN s.FromDate AND s.ToDate ) AS ExtraPT_tmp
			WHERE b.mrecommend = @CustID
				AND b.statusid NOT BETWEEN 101 AND 103
				AND b.betfrom <> 'p'
			GROUP BY b.matchid

		END
		ELSE IF (@RoleID = 2)
		BEGIN
			SELECT 
				b.matchid, 
				SUM(b.stake) AS SumOfStake,
				SUM((1-b.tpositiontaking - ISNULL(ExtraPT_tmp.ExtraPT,0)) * b.stake) AS HouseTurnover
			FROM bodb02.dbo.bettrans b WITH(NOLOCK)
				INNER JOIN @MatchList m ON b.matchid = m.matchid
				INNER JOIN #SportBettype bt WITH (NOLOCK) ON bt.Bettype = b.bettype
				OUTER APPLY (SELECT SUM(s.ExtraPT) AS ExtraPT 
						 FROM #ExtraPTInfo s WITH(NOLOCK) 
						 WHERE b.srecommend = s.SuperId AND b.winlostdate BETWEEN s.FromDate AND s.ToDate ) AS ExtraPT_tmp
			WHERE b.recommend = @CustID
				AND b.statusid NOT BETWEEN 101 AND 103
				AND b.betfrom <> 'p'
			GROUP BY b.matchid

		END
	END
END
GO
GRANT EXECUTE ON [dbo].[NAP_TOControl_MatchTurnoverByCustomerSelect] TO [bodbAdminNet]
GO