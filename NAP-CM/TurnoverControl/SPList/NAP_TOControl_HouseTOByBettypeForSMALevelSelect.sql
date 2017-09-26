/*<info serverAlias="DBAGE-bodb02" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_TOControl_HouseTOByBettypeForSMALevelSelect]
(
	@CustID INT,
	@matchid INT,
	@IsGroupHeadline BIT = 0,
	@EventDate DATETIME
)	
AS

/*
	Created: Don
	Date: 2017-03-27
	Task: Retrieve balance information
	DB: DBAGE.bodb02
	Original: DBAGE.bodb02.NAP_SMATurnoverBalanceInfoSel

	Revisions:
		- 20170920@Helen: TO Control Phase 3 - [Redmine: 75557]
	Parameter's explaination: 
	
	
*/
BEGIN
	SET NOCOUNT ON
	
	-- CALL wrong SP
	IF @IsGroupHeadline = 1 RETURN
	
	CREATE TABLE #HouseTO_1_3_5_7_8_15 (liveindicator BIT, bettype SMALLINT, betteam_h MONEY, betteam_a MONEY,betteam_1 MONEY,betteam_x MONEY, betteam_2 MONEY )
	
	CREATE TABLE #HouseTO_99 (liveindicator BIT, bettype SMALLINT, total MONEY )
	
	DECLARE @RoleID INT , @ExtraPT DECIMAL(9,8), @srecommend INT, @EventDate_min DATETIME
	
	CREATE TABLE  #SportBettype (Bettype SMALLINT PRIMARY KEY)
	-- Get list of Bettype of sportbook
	-- Check SP Version
	DECLARE @isTest BIT = 0
	SELECT  @isTest = dbo.f_CheckSPVersion(@@PROCID)
	
	INSERT INTO #SportBettype (Bettype)
	SELECT DISTINCT Bettype FROM bodb02.dbo.f_SportBettypeMatrix_Sel (1, 0, 0, 2, '', '', @isTest)
	
	SELECT @RoleID = RoleID,@srecommend = srecommend FROM CustInfo WITH(NOLOCK) WHERE CustID = @CustID
	
	SET @ExtraPT = ISNULL((SELECT SUM(ExtraPT) 
							FROM dbo.Acc_GroupExtraPTSetting s WITH(NOLOCK) 
							WHERE s.SuperId = @SRecommend 
								AND s.ProductId = 1 
								AND s.Sporttype  = 0 
								AND @EventDate BETWEEN s.FromDate AND s.ToDate)
							,0)	
	
	IF EXISTS (SELECT matchid FROM match WITH (NOLOCK) WHERE matchid = @matchid)
	BEGIN
		IF(@RoleID=4)
		BEGIN
			INSERT INTO #HouseTO_1_3_5_7_8_15 (liveindicator,bettype,betteam_h,betteam_a,betteam_1,betteam_x,betteam_2)
			SELECT b.liveindicator, b.bettype
				, SUM(ISNULL(CASE WHEN b.betteam='h' THEN (1-tpositiontaking - @ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_h
				, SUM(ISNULL(CASE WHEN b.betteam='a' THEN (1-tpositiontaking - @ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_a
				, SUM(ISNULL(CASE WHEN b.betteam='1' THEN (1-tpositiontaking - @ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_1
				, SUM(ISNULL(CASE WHEN b.betteam='x' THEN (1-tpositiontaking - @ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_x
				, SUM(ISNULL(CASE WHEN b.betteam='2' THEN (1-tpositiontaking - @ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_2
			FROM bettrans b WITH(NOLOCK)
				INNER JOIN #SportBettype bt WITH (NOLOCK) ON bt.Bettype = b.bettype 
			WHERE b.matchid = @matchid
				AND b.srecommend = @custid
				AND b.statusid NOT IN (101,102,103)
				AND b.bettype IN(1,3,5,7,8,15)
				AND b.betfrom <> 'p'
			GROUP BY b.liveindicator,b.bettype
			
			INSERT INTO #HouseTO_99 (liveindicator,bettype,total)
			SELECT b.liveindicator,-1 bettype,
				CAST(SUM(ISNULL((1-tpositiontaking- @ExtraPT)*abs(stake),0)) AS VARCHAR(30)) BalanceInfo
			FROM bettrans b WITH(NOLOCK)
				INNER JOIN #SportBettype bt WITH (NOLOCK) ON bt.Bettype = b.bettype 
			WHERE b.matchid = @matchid
				AND b.srecommend = @custid
				AND b.statusid NOT IN (101,102,103)
				AND b.bettype NOT IN(SELECT bettype FROM dbo.f_VSHorseRacingByBettype())
				AND b.bettype NOT IN(1,3,5,7,8,15)
				AND b.betfrom <> 'p'
				
			GROUP BY b.liveindicator
			
		END
		ELSE IF (@RoleID=3)
		BEGIN
			INSERT INTO #HouseTO_1_3_5_7_8_15 (liveindicator,bettype,betteam_h,betteam_a,betteam_1,betteam_x,betteam_2)
			SELECT b.liveindicator, b.bettype
				, SUM(ISNULL(CASE WHEN b.betteam='h' THEN (1-tpositiontaking - @ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_h
				, SUM(ISNULL(CASE WHEN b.betteam='a' THEN (1-tpositiontaking - @ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_a
				, SUM(ISNULL(CASE WHEN b.betteam='1' THEN (1-tpositiontaking - @ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_1
				, SUM(ISNULL(CASE WHEN b.betteam='x' THEN (1-tpositiontaking - @ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_x
				, SUM(ISNULL(CASE WHEN b.betteam='2' THEN (1-tpositiontaking - @ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_2
			FROM bettrans b WITH(NOLOCK) 
			WHERE b.matchid = @matchid
				AND b.mrecommend = @custid
				AND b.statusid NOT IN (101,102,103)
				AND b.bettype IN(1,3,5,7,8,15)
				AND b.betfrom <> 'p'
			GROUP BY b.liveindicator, b.bettype
			
			INSERT INTO #HouseTO_99 (liveindicator,bettype,total)
			SELECT b.liveindicator, -1 bettype,
				CAST(SUM(ISNULL((1-tpositiontaking - @ExtraPT)*abs(stake),0)) AS VARCHAR(30)) BalanceInfo
			FROM bettrans b WITH(NOLOCK) 
				INNER JOIN #SportBettype bt WITH (NOLOCK) ON bt.Bettype = b.bettype
			WHERE b.matchid = @matchid
				AND b.mrecommend = @custid
				AND b.statusid NOT IN (101,102,103)
				AND b.bettype NOT IN(SELECT bettype FROM dbo.f_VSHorseRacingByBettype())
				AND b.bettype NOT IN(1,3,5,7,8,15)
				AND b.betfrom <> 'p'
				
			GROUP BY b.liveindicator	
		END
		ELSE IF (@RoleID=2)
		BEGIN
			INSERT INTO #HouseTO_1_3_5_7_8_15 (liveindicator,bettype,betteam_h,betteam_a,betteam_1,betteam_x,betteam_2)
			SELECT b.liveindicator, b.bettype
				, SUM(ISNULL(CASE WHEN b.betteam='h' THEN (1-tpositiontaking - @ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_h
				, SUM(ISNULL(CASE WHEN b.betteam='a' THEN (1-tpositiontaking - @ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_a
				, SUM(ISNULL(CASE WHEN b.betteam='1' THEN (1-tpositiontaking - @ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_1
				, SUM(ISNULL(CASE WHEN b.betteam='x' THEN (1-tpositiontaking - @ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_x
				, SUM(ISNULL(CASE WHEN b.betteam='2' THEN (1-tpositiontaking - @ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_2
			FROM bettrans b WITH(NOLOCK) 
			WHERE b.matchid = @matchid
				AND b.recommend = @custid
				AND b.statusid NOT IN (101,102,103)
				AND b.bettype IN(1,3,5,7,8,15)
				AND b.betfrom <> 'p'
			GROUP BY b.liveindicator, b.bettype
			
			INSERT INTO #HouseTO_99 (liveindicator,bettype,total)
			SELECT b.liveindicator, -1 bettype,
				CAST(SUM(ISNULL((1-tpositiontaking - @ExtraPT)*abs(stake),0)) AS VARCHAR(30)) BalanceInfo
			FROM bettrans b WITH(NOLOCK) 
				INNER JOIN #SportBettype bt WITH (NOLOCK) ON bt.Bettype = b.bettype
			WHERE b.matchid = @matchid
				AND b.recommend = @custid
				AND b.statusid NOT IN (101,102,103)
				AND b.bettype NOT IN(SELECT bettype FROM dbo.f_VSHorseRacingByBettype())
				AND b.bettype NOT IN(1,3,5,7,8,15)
				AND b.betfrom <> 'p'
				
			GROUP BY b.liveindicator	
		END
	END
	ELSE --------------Get from bettrans14-------------
	BEGIN
		IF(@RoleID=4)
		BEGIN
			INSERT INTO #HouseTO_1_3_5_7_8_15 (liveindicator,bettype,betteam_h,betteam_a,betteam_1,betteam_x,betteam_2)
			SELECT b.liveindicator, b.bettype
				, SUM(ISNULL(CASE WHEN b.betteam='h' THEN (1-tpositiontaking - @ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_h
				, SUM(ISNULL(CASE WHEN b.betteam='a' THEN (1-tpositiontaking - @ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_a
				, SUM(ISNULL(CASE WHEN b.betteam='1' THEN (1-tpositiontaking - @ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_1
				, SUM(ISNULL(CASE WHEN b.betteam='x' THEN (1-tpositiontaking - @ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_x
				, SUM(ISNULL(CASE WHEN b.betteam='2' THEN (1-tpositiontaking - @ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_2
			FROM bettrans14 b WITH(NOLOCK) 
			WHERE b.matchid = @matchid
				AND b.srecommend = @custid
				AND b.statusid NOT IN (101,102,103)
				AND b.bettype IN(1,3,5,7,8,15)
				AND b.betfrom <> 'p'
				
			GROUP BY b.liveindicator, b.bettype
			
			INSERT INTO #HouseTO_99 (liveindicator,bettype,total)
			SELECT b.liveindicator, -1 bettype,
				CAST(SUM(ISNULL((1-tpositiontaking - @ExtraPT)*abs(stake),0)) AS VARCHAR(30)) BalanceInfo
			FROM bettrans14 b WITH(NOLOCK) 
				INNER JOIN #SportBettype bt WITH (NOLOCK) ON bt.Bettype = b.bettype
			WHERE b.matchid = @matchid
				AND b.srecommend = @custid
				AND b.statusid NOT IN (101,102,103)
				AND b.bettype NOT IN(SELECT bettype FROM dbo.f_VSHorseRacingByBettype())
				AND b.bettype NOT IN(1,3,5,7,8,15)
				AND b.betfrom <> 'p'
				
			GROUP BY b.liveindicator	
		END
		ELSE IF (@RoleID=3)
		BEGIN
			INSERT INTO #HouseTO_1_3_5_7_8_15 (liveindicator,bettype,betteam_h,betteam_a,betteam_1,betteam_x,betteam_2)
			SELECT b.liveindicator, b.bettype
				, SUM(ISNULL(CASE WHEN b.betteam='h' THEN (1-tpositiontaking - @ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_h
				, SUM(ISNULL(CASE WHEN b.betteam='a' THEN (1-tpositiontaking - @ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_a
				, SUM(ISNULL(CASE WHEN b.betteam='1' THEN (1-tpositiontaking - @ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_1
				, SUM(ISNULL(CASE WHEN b.betteam='x' THEN (1-tpositiontaking - @ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_x
				, SUM(ISNULL(CASE WHEN b.betteam='2' THEN (1-tpositiontaking - @ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_2
			FROM bettrans14 b WITH(NOLOCK) 
			WHERE b.matchid = @matchid
				AND b.mrecommend = @custid
				AND b.statusid NOT IN (101,102,103)
				AND b.bettype IN(1,3,5,7,8,15)
				AND b.betfrom <> 'p'
				
			GROUP BY b.liveindicator, b.bettype
			
			INSERT INTO #HouseTO_99 (liveindicator,bettype,total)
			SELECT b.liveindicator, -1 bettype,
				CAST(SUM(ISNULL((1-tpositiontaking - @ExtraPT)*abs(stake),0)) AS VARCHAR(30)) BalanceInfo
			FROM bettrans14 b WITH(NOLOCK) 
				INNER JOIN #SportBettype bt WITH (NOLOCK) ON bt.Bettype = b.bettype
			WHERE b.matchid = @matchid
				AND b.mrecommend = @custid
				AND b.statusid NOT IN (101,102,103)
				AND b.bettype NOT IN(SELECT bettype FROM dbo.f_VSHorseRacingByBettype())
				AND b.bettype NOT IN(1,3,5,7,8,15)
				AND b.betfrom <> 'p'
				
			GROUP BY b.liveindicator	
		END
		ELSE IF (@RoleID=2)
		BEGIN
			INSERT INTO #HouseTO_1_3_5_7_8_15 (liveindicator,bettype,betteam_h,betteam_a,betteam_1,betteam_x,betteam_2)
			SELECT b.liveindicator, b.bettype
				, SUM(ISNULL(CASE WHEN b.betteam='h' THEN (1-tpositiontaking - @ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_h
				, SUM(ISNULL(CASE WHEN b.betteam='a' THEN (1-tpositiontaking - @ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_a
				, SUM(ISNULL(CASE WHEN b.betteam='1' THEN (1-tpositiontaking - @ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_1
				, SUM(ISNULL(CASE WHEN b.betteam='x' THEN (1-tpositiontaking - @ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_x
				, SUM(ISNULL(CASE WHEN b.betteam='2' THEN (1-tpositiontaking - @ExtraPT)*abs(stake) ELSE 0 END,0)) AS betteam_2
			FROM bettrans14 b WITH(NOLOCK) 
			WHERE b.matchid = @matchid
				AND b.recommend = @custid
				AND b.statusid NOT IN (101,102,103)
				AND b.bettype IN(1,3,5,7,8,15) 
				AND b.betfrom <> 'p'
				
			GROUP BY b.liveindicator, b.bettype
			
			INSERT INTO #HouseTO_99 (liveindicator,bettype,total)
			SELECT b.liveindicator, -1 bettype,
				CAST(SUM(ISNULL((1-tpositiontaking - @ExtraPT)*abs(stake),0)) AS VARCHAR(30)) BalanceInfo
			FROM bettrans14 b WITH(NOLOCK)
				INNER JOIN #SportBettype bt WITH (NOLOCK) ON bt.Bettype = b.bettype 
			WHERE b.matchid = @matchid
				AND b.recommend = @custid
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
	SELECT Bettype AS BettypeID
			, CASE WHEN ISNULL(Live,'') = '' THEN '0 - 0' ELSE Live END AS Live
			, CASE WHEN ISNULL(NonLive,'') = '' THEN '0 - 0' ELSE NonLive END AS NonLive
			, Total 
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
	
END
GO
GRANT EXECUTE ON [dbo].[NAP_TOControl_HouseTOByBettypeForSMALevelSelect] TO [bodbAdminNet]
go
