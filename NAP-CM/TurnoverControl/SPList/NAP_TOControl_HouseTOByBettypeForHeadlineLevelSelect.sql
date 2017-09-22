/*<info serverAlias="DBAGE-bodb02" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_TOControl_HouseTOByBettypeForHeadlineLevelSelect]
(
	@CustID INT,
	@matchid INT,
	@IsGroupHeadline BIT = 0,
	@EventDate DATETIME
)	
AS

/*
	Created: Helen
	Date: 2017-09-21
	Task: Retrieve balance information
	DB: DBAGE.bodb02
	
	Revisions:
	
	Parameter's explaination: 
	
*/
BEGIN
	SET NOCOUNT ON
	
	-- CALL wrong SP
	IF @IsGroupHeadline = 0 RETURN
	
	CREATE TABLE #HouseTO_1_3_5_7_8_15 (liveindicator BIT, bettype SMALLINT, betteam_h MONEY, betteam_a MONEY,betteam_1 MONEY,betteam_x MONEY, betteam_2 MONEY )
	
	CREATE TABLE #HouseTO_99 (liveindicator BIT, bettype SMALLINT, total MONEY )
	
	CREATE TABLE  #SportBettype (Bettype SMALLINT PRIMARY KEY)
	
	DECLARE @ExtraPTInfo AS TABLE(SuperID INT,ExtraPT DECIMAL(9,8))
	
	DECLARE @GroupHeadlineList TABLE (CustID INT PRIMARY KEY, RoleID INT, srecommend INT, IsMemberExcluded BIT)
	
	DECLARE @RoleID INT , @srecommend INT, @EventDate_min DATETIME
	
	-- Get list of Bettype of sportbook
	-- Check SP Version
	DECLARE @isTest BIT = 0
	SELECT  @isTest = dbo.f_CheckSPVersion(@@PROCID)
	
	INSERT INTO #SportBettype (Bettype)
	SELECT DISTINCT Bettype FROM bodb02.dbo.f_SportBettypeMatrix_Sel (1, 0, 0, 2, '', '', @isTest)
	
	SELECT @RoleID = RoleID,@srecommend = srecommend FROM CustInfo WITH(NOLOCK) WHERE CustID = @CustID
	
	-- Get all under this Headline
	INSERT INTO @GroupHeadlineList (CustID, RoleID,srecommend,IsMemberExcluded)
	SELECT ca1.custid,ci.roleid,ci.srecommend
			,IsMemberExcluded =  CASE WHEN CI.roleid = 1 AND EXISTS (SELECT 1 FROM bodb02.dbo.custAccount CA_tmp WITH (NOLOCK)
																	WHERE CA_tmp.groupID = ca.GroupID AND CA_tmp.custID IN (ci.srecommend, ci.mrecommend, ci.recommend))
												THEN 1 
									  ELSE 0 
								 END
	FROM bodb02.dbo.CustGroupHeadline ca WITH (NOLOCK)
		INNER JOIN bodb02.dbo.custAccount ca1 WITH (NOLOCK) ON ca.groupID = ca1.groupID
		INNER JOIN bodb02.dbo.custInfo ci WITH (NOLOCK) ON ci.custid = ca1.custid
	WHERE ca.custid = @CustID 
	
	-- Get extra PT info
	INSERT INTO @ExtraPTInfo (SuperID,ExtraPT)
	SELECT DISTINCT GHL.CustID,ISNULL(EPT.ExtraPT,0)
	FROM @GroupHeadlineList GHL
		LEFT JOIN dbo.Acc_GroupExtraPTSetting EPT WITH (NOLOCK) ON GHL.srecommend = EPT.SuperId 
																AND EPT.ProductId = 1 
																AND EPT.Sporttype = 0 
																AND @EventDate BETWEEN EPT.FromDate AND EPT.ToDate 
	
	IF EXISTS (SELECT matchid FROM match WITH (NOLOCK) WHERE matchid = @matchid)
	BEGIN
		IF EXISTS (SELECT 1 FROM @GroupHeadlineList WHERE RoleID = 4)
		BEGIN
			INSERT INTO #HouseTO_1_3_5_7_8_15 (liveindicator,bettype,betteam_h,betteam_a,betteam_1,betteam_x,betteam_2)
			SELECT b.liveindicator, b.bettype
				, SUM(ISNULL(CASE WHEN b.betteam='h' THEN (1-tpositiontaking - s.ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_h
				, SUM(ISNULL(CASE WHEN b.betteam='a' THEN (1-tpositiontaking - s.ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_a
				, SUM(ISNULL(CASE WHEN b.betteam='1' THEN (1-tpositiontaking - s.ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_1
				, SUM(ISNULL(CASE WHEN b.betteam='x' THEN (1-tpositiontaking - s.ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_x
				, SUM(ISNULL(CASE WHEN b.betteam='2' THEN (1-tpositiontaking - s.ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_2
			FROM bettrans b WITH(NOLOCK)
				INNER JOIN @ExtraPTInfo s  ON b.srecommend = s.SuperId  
			WHERE b.matchid = @matchid
				AND b.srecommend IN (SELECT custid FROM @GroupHeadlineList GHL WHERE RoleID = 4)
				AND b.statusid NOT IN (101,102,103)
				AND b.bettype IN(1,3,5,7,8,15)
				AND b.betfrom <> 'p'
			GROUP BY b.liveindicator,b.bettype
			
			INSERT INTO #HouseTO_99 (liveindicator,bettype,total)
			SELECT b.liveindicator,-1 bettype,
				CAST(SUM(ISNULL((1-tpositiontaking- s.ExtraPT)*abs(stake),0)) AS VARCHAR(30)) BalanceInfo
			FROM bettrans b WITH(NOLOCK)
				INNER JOIN #SportBettype bt WITH (NOLOCK) ON bt.Bettype = b.bettype 
				INNER JOIN @ExtraPTInfo s  ON b.srecommend = s.SuperId  
			WHERE b.matchid = @matchid
				AND b.srecommend IN (SELECT custid FROM @GroupHeadlineList GHL WHERE RoleID = 4)
				AND b.statusid NOT IN (101,102,103)
				AND b.bettype NOT IN(SELECT bettype FROM dbo.f_VSHorseRacingByBettype())
				AND b.bettype NOT IN(1,3,5,7,8,15)
				
				AND b.betfrom <> 'p'
			GROUP BY b.liveindicator
			
		END
		IF EXISTS (SELECT 1 FROM @GroupHeadlineList WHERE RoleID = 3)
		BEGIN
			INSERT INTO #HouseTO_1_3_5_7_8_15 (liveindicator,bettype,betteam_h,betteam_a,betteam_1,betteam_x,betteam_2)
			SELECT b.liveindicator, b.bettype
				, SUM(ISNULL(CASE WHEN b.betteam='h' THEN (1-tpositiontaking - s.ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_h
				, SUM(ISNULL(CASE WHEN b.betteam='a' THEN (1-tpositiontaking - s.ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_a
				, SUM(ISNULL(CASE WHEN b.betteam='1' THEN (1-tpositiontaking - s.ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_1
				, SUM(ISNULL(CASE WHEN b.betteam='x' THEN (1-tpositiontaking - s.ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_x
				, SUM(ISNULL(CASE WHEN b.betteam='2' THEN (1-tpositiontaking - s.ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_2
			FROM bettrans b WITH(NOLOCK)
				INNER JOIN @ExtraPTInfo s  ON b.srecommend = s.SuperId  
			WHERE b.matchid = @matchid
				AND b.mrecommend IN (SELECT custid FROM @GroupHeadlineList GHL WHERE RoleID = 3)
				AND b.statusid NOT IN (101,102,103)
				AND b.bettype IN(1,3,5,7,8,15)
				AND b.betfrom <> 'p'
			GROUP BY b.liveindicator, b.bettype
			
			INSERT INTO #HouseTO_99 (liveindicator,bettype,total)
			SELECT b.liveindicator, -1 bettype,
				CAST(SUM(ISNULL((1-tpositiontaking - s.ExtraPT)*abs(stake),0)) AS VARCHAR(30)) BalanceInfo
			FROM bettrans b WITH(NOLOCK)
				INNER JOIN #SportBettype bt WITH (NOLOCK) ON bt.Bettype = b.bettype 
				INNER JOIN @ExtraPTInfo s  ON b.srecommend = s.SuperId  
			WHERE b.matchid = @matchid
				AND b.mrecommend IN (SELECT custid FROM @GroupHeadlineList GHL WHERE RoleID = 3)
				AND b.statusid NOT IN (101,102,103)
				AND b.bettype NOT IN(SELECT bettype FROM dbo.f_VSHorseRacingByBettype())
				AND b.bettype NOT IN(1,3,5,7,8,15)
				
				AND b.betfrom <> 'p'
			GROUP BY b.liveindicator	
		END
		IF EXISTS (SELECT 1 FROM @GroupHeadlineList WHERE RoleID = 2)
		BEGIN
			INSERT INTO #HouseTO_1_3_5_7_8_15 (liveindicator,bettype,betteam_h,betteam_a,betteam_1,betteam_x,betteam_2)
			SELECT b.liveindicator, b.bettype
				, SUM(ISNULL(CASE WHEN b.betteam='h' THEN (1-tpositiontaking - s.ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_h
				, SUM(ISNULL(CASE WHEN b.betteam='a' THEN (1-tpositiontaking - s.ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_a
				, SUM(ISNULL(CASE WHEN b.betteam='1' THEN (1-tpositiontaking - s.ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_1
				, SUM(ISNULL(CASE WHEN b.betteam='x' THEN (1-tpositiontaking - s.ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_x
				, SUM(ISNULL(CASE WHEN b.betteam='2' THEN (1-tpositiontaking - s.ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_2
			FROM bettrans b WITH(NOLOCK)
				INNER JOIN @ExtraPTInfo s  ON b.srecommend = s.SuperId  
			WHERE b.matchid = @matchid
				AND b.recommend IN (SELECT custid FROM @GroupHeadlineList GHL WHERE RoleID = 2)
				AND b.statusid NOT IN (101,102,103)
				AND b.bettype IN(1,3,5,7,8,15)
				AND b.betfrom <> 'p'
			GROUP BY b.liveindicator, b.bettype
			
			INSERT INTO #HouseTO_99 (liveindicator,bettype,total)
			SELECT b.liveindicator, -1 bettype,
				CAST(SUM(ISNULL((1-tpositiontaking - s.ExtraPT)*abs(stake),0)) AS VARCHAR(30)) BalanceInfo
			FROM bettrans b WITH(NOLOCK) 
				INNER JOIN #SportBettype bt WITH (NOLOCK) ON bt.Bettype = b.bettype 
				INNER JOIN @ExtraPTInfo s  ON b.srecommend = s.SuperId  
			WHERE b.matchid = @matchid
				AND b.recommend IN (SELECT custid FROM @GroupHeadlineList GHL WHERE RoleID = 2)
				AND b.statusid NOT IN (101,102,103)
				AND b.bettype NOT IN(SELECT bettype FROM dbo.f_VSHorseRacingByBettype())
				AND b.bettype NOT IN(1,3,5,7,8,15)
				
				AND b.betfrom <> 'p'
			GROUP BY b.liveindicator	
		END
		
		IF EXISTS (SELECT 1 FROM @GroupHeadlineList WHERE RoleID = 1 AND IsMemberExcluded = 0)
		BEGIN
			INSERT INTO #HouseTO_1_3_5_7_8_15 (liveindicator,bettype,betteam_h,betteam_a,betteam_1,betteam_x,betteam_2)
			SELECT b.liveindicator, b.bettype
				, SUM(ISNULL(CASE WHEN b.betteam='h' THEN (1-tpositiontaking - s.ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_h
				, SUM(ISNULL(CASE WHEN b.betteam='a' THEN (1-tpositiontaking - s.ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_a
				, SUM(ISNULL(CASE WHEN b.betteam='1' THEN (1-tpositiontaking - s.ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_1
				, SUM(ISNULL(CASE WHEN b.betteam='x' THEN (1-tpositiontaking - s.ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_x
				, SUM(ISNULL(CASE WHEN b.betteam='2' THEN (1-tpositiontaking - s.ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_2
			FROM bettrans b WITH(NOLOCK)
				INNER JOIN @ExtraPTInfo s  ON b.srecommend = s.SuperId  
			WHERE b.matchid = @matchid
				AND b.custid IN (SELECT custid FROM @GroupHeadlineList GHL WHERE RoleID = 1  AND IsMemberExcluded = 0)
				AND b.statusid NOT IN (101,102,103)
				AND b.bettype IN(1,3,5,7,8,15)
				AND b.betfrom <> 'p'
			GROUP BY b.liveindicator, b.bettype
			
			INSERT INTO #HouseTO_99 (liveindicator,bettype,total)
			SELECT b.liveindicator, -1 bettype,
				CAST(SUM(ISNULL((1-tpositiontaking - s.ExtraPT)*abs(stake),0)) AS VARCHAR(30)) BalanceInfo
			FROM bettrans b WITH(NOLOCK)
				INNER JOIN #SportBettype bt WITH (NOLOCK) ON bt.Bettype = b.bettype  
				INNER JOIN @ExtraPTInfo s  ON b.srecommend = s.SuperId  
			WHERE b.matchid = @matchid
				AND b.custid IN (SELECT custid FROM @GroupHeadlineList GHL WHERE RoleID = 1  AND IsMemberExcluded = 0)
				AND b.statusid NOT IN (101,102,103)
				AND b.bettype NOT IN(SELECT bettype FROM dbo.f_VSHorseRacingByBettype())
				AND b.bettype NOT IN(1,3,5,7,8,15)
				
				AND b.betfrom <> 'p'
			GROUP BY b.liveindicator	
		END
		
	END
	ELSE --------------Get from bettrans14-------------
	BEGIN
		IF EXISTS (SELECT 1 FROM @GroupHeadlineList WHERE RoleID = 4)
		BEGIN
			INSERT INTO #HouseTO_1_3_5_7_8_15 (liveindicator,bettype,betteam_h,betteam_a,betteam_1,betteam_x,betteam_2)
			SELECT b.liveindicator, b.bettype
				, SUM(ISNULL(CASE WHEN b.betteam='h' THEN (1-tpositiontaking - s.ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_h
				, SUM(ISNULL(CASE WHEN b.betteam='a' THEN (1-tpositiontaking - s.ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_a
				, SUM(ISNULL(CASE WHEN b.betteam='1' THEN (1-tpositiontaking - s.ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_1
				, SUM(ISNULL(CASE WHEN b.betteam='x' THEN (1-tpositiontaking - s.ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_x
				, SUM(ISNULL(CASE WHEN b.betteam='2' THEN (1-tpositiontaking - s.ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_2
			FROM bettrans14 b WITH(NOLOCK) 
				INNER JOIN @ExtraPTInfo s  ON b.srecommend = s.SuperId 	
			WHERE b.matchid = @matchid
				AND b.srecommend IN (SELECT custid FROM @GroupHeadlineList GHL WHERE RoleID = 4)
				AND b.statusid NOT IN (101,102,103)
				AND b.bettype IN(1,3,5,7,8,15)
				AND b.betfrom <> 'p'
			GROUP BY b.liveindicator, b.bettype
			
			INSERT INTO #HouseTO_99 (liveindicator,bettype,total)
			SELECT b.liveindicator, -1 bettype,
				CAST(SUM(ISNULL((1-tpositiontaking - s.ExtraPT)*abs(stake),0)) AS VARCHAR(30)) BalanceInfo
			FROM bettrans14 b WITH(NOLOCK)
				INNER JOIN #SportBettype bt WITH (NOLOCK) ON bt.Bettype = b.bettype 
				INNER JOIN @ExtraPTInfo s  ON b.srecommend = s.SuperId  
			WHERE b.matchid = @matchid
				AND b.srecommend IN (SELECT custid FROM @GroupHeadlineList GHL WHERE RoleID = 4)
				AND b.statusid NOT IN (101,102,103)
				AND b.bettype NOT IN(SELECT bettype FROM dbo.f_VSHorseRacingByBettype())
				AND b.bettype NOT IN(1,3,5,7,8,15)
				
				AND b.betfrom <> 'p'
			GROUP BY b.liveindicator	
		END
		IF EXISTS (SELECT 1 FROM @GroupHeadlineList WHERE RoleID = 3)
		BEGIN
			INSERT INTO #HouseTO_1_3_5_7_8_15 (liveindicator,bettype,betteam_h,betteam_a,betteam_1,betteam_x,betteam_2)
			SELECT b.liveindicator, b.bettype
				, SUM(ISNULL(CASE WHEN b.betteam='h' THEN (1-tpositiontaking - s.ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_h
				, SUM(ISNULL(CASE WHEN b.betteam='a' THEN (1-tpositiontaking - s.ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_a
				, SUM(ISNULL(CASE WHEN b.betteam='1' THEN (1-tpositiontaking - s.ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_1
				, SUM(ISNULL(CASE WHEN b.betteam='x' THEN (1-tpositiontaking - s.ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_x
				, SUM(ISNULL(CASE WHEN b.betteam='2' THEN (1-tpositiontaking - s.ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_2
			FROM bettrans14 b WITH(NOLOCK)
				INNER JOIN @ExtraPTInfo s  ON b.srecommend = s.SuperId  
			WHERE b.matchid = @matchid
				AND b.mrecommend IN (SELECT custid FROM @GroupHeadlineList GHL WHERE RoleID = 3)
				AND b.statusid NOT IN (101,102,103)
				AND b.bettype IN(1,3,5,7,8,15)
				AND b.betfrom <> 'p'
			GROUP BY b.liveindicator, b.bettype
			
			INSERT INTO #HouseTO_99 (liveindicator,bettype,total)
			SELECT b.liveindicator, -1 bettype,
				CAST(SUM(ISNULL((1-tpositiontaking - s.ExtraPT)*abs(stake),0)) AS VARCHAR(30)) BalanceInfo
			FROM bettrans14 b WITH(NOLOCK) 
				INNER JOIN #SportBettype bt WITH (NOLOCK) ON bt.Bettype = b.bettype 
				INNER JOIN @ExtraPTInfo s  ON b.srecommend = s.SuperId 
			WHERE b.matchid = @matchid
				AND b.mrecommend IN (SELECT custid FROM @GroupHeadlineList GHL WHERE RoleID = 3)
				AND b.statusid NOT IN (101,102,103)
				AND b.bettype NOT IN(SELECT bettype FROM dbo.f_VSHorseRacingByBettype())
				AND b.bettype NOT IN(1,3,5,7,8,15)
				
				AND b.betfrom <> 'p'
			GROUP BY b.liveindicator	
		END
		IF EXISTS (SELECT 1 FROM @GroupHeadlineList WHERE RoleID = 2)
		BEGIN
			INSERT INTO #HouseTO_1_3_5_7_8_15 (liveindicator,bettype,betteam_h,betteam_a,betteam_1,betteam_x,betteam_2)
			SELECT b.liveindicator, b.bettype
				, SUM(ISNULL(CASE WHEN b.betteam='h' THEN (1-tpositiontaking - s.ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_h
				, SUM(ISNULL(CASE WHEN b.betteam='a' THEN (1-tpositiontaking - s.ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_a
				, SUM(ISNULL(CASE WHEN b.betteam='1' THEN (1-tpositiontaking - s.ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_1
				, SUM(ISNULL(CASE WHEN b.betteam='x' THEN (1-tpositiontaking - s.ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_x
				, SUM(ISNULL(CASE WHEN b.betteam='2' THEN (1-tpositiontaking - s.ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_2
			FROM bettrans14 b WITH(NOLOCK) 
				INNER JOIN @ExtraPTInfo s  ON b.srecommend = s.SuperId 
			WHERE b.matchid = @matchid
				AND b.recommend IN (SELECT custid FROM @GroupHeadlineList GHL WHERE RoleID = 2)
				AND b.statusid NOT IN (101,102,103)
				AND b.bettype IN(1,3,5,7,8,15) 
				AND b.betfrom <> 'p'
			GROUP BY b.liveindicator, b.bettype
			
			INSERT INTO #HouseTO_99 (liveindicator,bettype,total)
			SELECT b.liveindicator, -1 bettype,
				CAST(SUM(ISNULL((1-tpositiontaking - s.ExtraPT)*abs(stake),0)) AS VARCHAR(30)) BalanceInfo
			FROM bettrans14 b WITH(NOLOCK)
				INNER JOIN #SportBettype bt WITH (NOLOCK) ON bt.Bettype = b.bettype 
				INNER JOIN @ExtraPTInfo s  ON b.srecommend = s.SuperId  
			WHERE b.matchid = @matchid
				AND b.recommend IN (SELECT custid FROM @GroupHeadlineList GHL WHERE RoleID = 2)
				AND b.statusid NOT IN (101,102,103)
				AND b.bettype NOT IN(SELECT bettype FROM dbo.f_VSHorseRacingByBettype())
				AND b.bettype NOT IN(1,3,5,7,8,15)
				
				AND b.betfrom <> 'p'
			GROUP BY b.liveindicator	
		END
		
		IF EXISTS (SELECT 1 FROM @GroupHeadlineList WHERE RoleID = 1 AND IsMemberExcluded = 0)
		BEGIN
			INSERT INTO #HouseTO_1_3_5_7_8_15 (liveindicator,bettype,betteam_h,betteam_a,betteam_1,betteam_x,betteam_2)
			SELECT b.liveindicator, b.bettype
				, SUM(ISNULL(CASE WHEN b.betteam='h' THEN (1-tpositiontaking - s.ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_h
				, SUM(ISNULL(CASE WHEN b.betteam='a' THEN (1-tpositiontaking - s.ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_a
				, SUM(ISNULL(CASE WHEN b.betteam='1' THEN (1-tpositiontaking - s.ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_1
				, SUM(ISNULL(CASE WHEN b.betteam='x' THEN (1-tpositiontaking - s.ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_x
				, SUM(ISNULL(CASE WHEN b.betteam='2' THEN (1-tpositiontaking - s.ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_2
			FROM bettrans14 b WITH(NOLOCK) 
				INNER JOIN @ExtraPTInfo s  ON b.srecommend = s.SuperId 
			WHERE b.matchid = @matchid
				AND b.custid IN (SELECT custid FROM @GroupHeadlineList GHL WHERE RoleID = 1  AND IsMemberExcluded = 0)
				AND b.statusid NOT IN (101,102,103)
				AND b.bettype IN(1,3,5,7,8,15) 
				AND b.betfrom <> 'p'
			GROUP BY b.liveindicator, b.bettype
			
			INSERT INTO #HouseTO_99 (liveindicator,bettype,total)
			SELECT b.liveindicator, -1 bettype,
				CAST(SUM(ISNULL((1-tpositiontaking - s.ExtraPT)*abs(stake),0)) AS VARCHAR(30)) BalanceInfo
			FROM bettrans14 b WITH(NOLOCK)
				INNER JOIN #SportBettype bt WITH (NOLOCK) ON bt.Bettype = b.bettype 
				INNER JOIN @ExtraPTInfo s  ON b.srecommend = s.SuperId  
			WHERE b.matchid = @matchid
				AND b.custid IN (SELECT custid FROM @GroupHeadlineList GHL WHERE RoleID = 1  AND IsMemberExcluded = 0)
				AND b.statusid NOT IN (101,102,103)
				AND b.bettype NOT IN(SELECT bettype FROM dbo.f_VSHorseRacingByBettype())
				AND b.bettype NOT IN(1,3,5,7,8,15)
				
				AND b.betfrom <> 'p'
			GROUP BY b.liveindicator
		END
	END
	
	-- Insert Total by bettype	
	INSERT INTO #HouseTO_1_3_5_7_8_15 (liveindicator,bettype,betteam_1,betteam_2,betteam_x,betteam_h,betteam_a)	
	SELECT 2,bettype, SUM(betteam_1),SUM(betteam_2),SUM(betteam_x),SUM(betteam_h),SUM(betteam_a)
	FROM #HouseTO_1_3_5_7_8_15
	GROUP BY bettype

	INSERT INTO #HouseTO_99 (liveindicator,bettype,total)	
	SELECT 2,bettype, SUM(total)
	FROM #HouseTO_99
	GROUP BY bettype

	------- FINAL RESULT --------
	SELECT Bettype AS BettypeID, Live, NonLive, Total 
	FROM
	(
	  SELECT CASE WHEN liveindicator = 1 THEN 'Live' 
				  WHEN liveindicator = 0 THEN 'NonLive'
				  ELSE 'Total' END liveindicator
			, Bettype
			, CASE	WHEN Bettype IN (5,15) THEN CAST(betteam_1 AS VARCHAR(30))  + ' - ' + CAST(betteam_x AS VARCHAR(30)) + ' - ' + CAST(betteam_2 AS VARCHAR(30)) 
					ELSE CAST(betteam_h AS VARCHAR(30))  + ' - ' + CAST(betteam_a AS VARCHAR(30))  
			  END AS value
	  FROM #HouseTO_1_3_5_7_8_15 BT1 WITH (NOLOCK)
	  
	  UNION All
	  SELECT CASE WHEN liveindicator = 1 THEN 'Live' 
				  WHEN liveindicator = 0 THEN 'NonLive'
				  ELSE 'Total' END liveindicator
			, Bettype
			, CAST (Total AS VARCHAR(30)) AS value
	 FROM #HouseTO_99 WITH (NOLOCK)
	) tmp
	PIVOT
	(
	  MAX(value)
	  FOR liveindicator in (Live,NonLive,Total)
	) piv;
	
	DROP TABLE #HouseTO_1_3_5_7_8_15
	DROP TABLE #HouseTO_99
	
END
GO
GRANT EXECUTE ON [dbo].[NAP_TOControl_HouseTOByBettypeForHeadlineLevelSelect] TO [bodbAdminNet]
GO
