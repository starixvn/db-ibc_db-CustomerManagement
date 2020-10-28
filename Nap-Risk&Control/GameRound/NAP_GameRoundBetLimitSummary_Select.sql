/*<info serverAlias="DBTXN-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE NAP_GameRoundBetLimitSummary_Select 
	@IsTest       BIT = 1
   , @SportType    INT = 0
   , @BetType      INT = 0
AS
/*	Creator: 20190313@Robert
	Task:  When a game round has been reached a limit, need to select information and send email to admin
	DB: DBTXN/bodb02	
	Revisions: 
		 - 20190313@Robert: #109866 - Risk & Control - Implement Global Game Round Bet Limit Setting and Report/Notification
		 - 20200316@Robert: #124754 - Game Round Bet Limit - Integrate Virtual Games
		 - 20200325@Robert:	#130682 - Global Game Round Bet Limit - Integrate Sexy Gaming
		 - 20200325@Robert:	#130686 - Global Game Round Bet Limit - Integrate GT Casino
		 - 20201028@Robert:	#131586 - Global Game Round Bet Limit - Integrate WM Live Casino
     Param:
*/

    BEGIN
	   SET NOCOUNT ON;

	   CREATE TABLE #Result(
		   GameRound      VARCHAR(50)
		 , SportType      SMALLINT
		 , BetType        VARCHAR(20)
		 , BetCount       INT DEFAULT 0
		 , NoOfPlayers    INT DEFAULT 0);

	   CREATE TABLE #GameRound_BetCount(
		   GameRound    VARCHAR(50)
		 , SportType    SMALLINT
		 , BetType      INT
		 , BetCount     INT
		 , CustId       INT
		 , Currency     INT
		 , BetChoice    VARCHAR(50));

	   CREATE TABLE #GameRound_NoOfPlayers(
		   GameRound      VARCHAR(50)
		 , SportType      SMALLINT
		 , BetType        INT
		 , NoOfPlayers    INT
		 , CustId         INT
		 , Currency       INT);

	   CREATE TABLE #BetCount(
		   GameRound    VARCHAR(50)
		 , SportType    SMALLINT
		 , BetType      INT
		 , BetCount     INT);
	   CREATE TABLE #NoOfPlayers(
		   GameRound      VARCHAR(50)
		 , SportType      SMALLINT
		 , BetType        INT
		 , NoOfPlayers    INT);

	   INSERT INTO #Result(GameRound
					 , SportType
					 , BetType)
			(
			    SELECT GameRound
				    , SportType
				    , CAST(BetType AS VARCHAR(20))
			    FROM GameRoundBetLimitSummary AS g WITH(NOLOCK)
			    WHERE g.IsTest = @IsTest
					AND g.SportType = CASE
									  WHEN @SportType > 0
									  THEN @SportType
									  ELSE g.SportType
								   END
					AND g.BetType = CASE
									WHEN @BetType > 0
									THEN @BetType
									ELSE g.BetType
								 END
					AND g.IsNotified = CASE
									   WHEN @SportType > 0
										   OR @BetType > 0
									   THEN g.IsNotified
									   ELSE 0
								    END
			);

	   CREATE INDEX IDX_Result_GameRound_SportType_BetType ON #Result(BetType, SportType);

	   INSERT INTO #GameRound_BetCount(GameRound
							   , SportType
							   , BetType
							   , BetCount
							   , CustId
							   , Currency
							   , BetChoice)
			(
			    SELECT g1.GameRound
				    , g1.SportType
				    , g1.BetType
				    , COUNT(1) AS BetCount
				    , g1.CustId
				    , g1.currency
				    , g1.BetChoice
			    FROM
				    (
					   SELECT g.GameRound
						   , r.SportType
						   , r.BetType
						   , g.CustId
						   , ci.currency
						   , ISNULL(g.BetChoice, '') AS BetChoice
					   FROM #Result AS r
						  CROSS APPLY
						   (
							  SELECT gt.GameRound
								  , gt.CustId
								  , gt.BetChoice
								  , gt.GameType
							  FROM Intg_GameRoundBetStake AS gt WITH(NOLOCK)
							  WHERE gt.GameType = R.BetType
						   ) AS g
						  INNER JOIN SportBettypeMatrix AS sb WITH(NOLOCK) ON sb.BetType = r.BetType
																    AND sb.SportType > 0
																    AND sb.IsLive = sb.IsLive
						  INNER JOIN CustDB.dbo.custInfo AS ci ON ci.custid = g.CustId
					   WHERE sb.ProductID IN(21, 38, 39, 45, 46, 51) -- Products need to be grouped by BetChoice
					   GROUP BY g.GameRound
							, r.SportType
							, r.BetType
							, g.CustId
							, ci.currency
							, ISNULL(g.BetChoice, '')
				    ) AS g1
			    GROUP BY g1.GameRound
					 , g1.SportType
					 , g1.BetType
					 , g1.CustId
					 , g1.currency
					 , g1.BetChoice
			    UNION ALL
			    SELECT g.GameRound
				    , r.SportType
				    , r.BetType
				    , COUNT(1) AS BetCount
				    , g.CustId
				    , ci.currency
				    , '' AS BetChoice
			    FROM #Result AS r
				   CROSS APPLY
				    (
					   SELECT gt.GameRound
						   , gt.CustId
						   , gt.BetChoice
						   , gt.GameType
					   FROM Intg_GameRoundBetStake AS gt WITH(NOLOCK)
					   WHERE gt.GameType = R.BetType
				    ) AS g
				   INNER JOIN SportBettypeMatrix AS sb WITH(NOLOCK) ON sb.BetType = r.BetType
															AND sb.SportType > 0
															AND sb.IsLive = sb.IsLive
				   INNER JOIN CustDB.dbo.custInfo AS ci ON ci.custid = g.CustId
			    WHERE sb.ProductID = 12 -- Gold Deluxe			
			    GROUP BY g.GameRound
					 , r.SportType
					 , r.BetType
					 , g.CustId
					 , ci.currency
			);

	   CREATE INDEX IDX_GameRound_BetCount_GameRound_SportType_BetType ON #GameRound_BetCount(GameRound, SportType, BetType);

	   INSERT INTO #GameRound_NoOfPlayers(GameRound
								 , SportType
								 , BetType
								 , NoOfPlayers
								 , CustId
								 , Currency)
			(
			    SELECT g1.GameRound
				    , g1.SportType
				    , g1.BetType
				    , COUNT(1) AS NoOfPlayers
				    , g1.CustId
				    , g1.currency
			    FROM
				    (
					   SELECT g.GameRound
						   , g.CustId
						   , r.SportType
						   , r.BetType
						   , ci.currency
					   FROM #Result AS r
						  CROSS APPLY
						   (
							  SELECT gt.GameRound
								  , gt.CustId
								  , gt.BetChoice
								  , gt.GameType
							  FROM Intg_GameRoundBetStake AS gt WITH(NOLOCK)
							  WHERE gt.GameType = R.BetType
						   ) AS g
						  INNER JOIN CustDB.dbo.custInfo AS ci ON g.CustId = ci.custid
					   GROUP BY g.GameRound
							, g.CustId
							, r.SportType
							, r.BetType
							, ci.currency
				    ) AS g1
			    GROUP BY g1.GameRound
					 , g1.SportType
					 , g1.BetType
					 , g1.CustId
					 , g1.currency
			);

	   CREATE INDEX IDX_GameRound_NoOfPlayers_BetCount_GameRound_SportType_BetType ON #GameRound_NoOfPlayers(GameRound, SportType, BetType);

	   IF @IsTest = 0
		  BEGIN
			 DELETE #GameRound_BetCount
			 WHERE Currency IN(20, 72);

			 DELETE FROM #GameRound_NoOfPlayers
			 WHERE Currency IN(20, 72);
	   END;

	   INSERT INTO #BetCount(GameRound
					   , SportType
					   , BetType
					   , BetCount)
			SELECT GameRound
				, SportType
				, BetType
				, SUM(BetCount) AS BetCount
			FROM #GameRound_BetCount
			GROUP BY GameRound
				  , SportType
				  , BetType;

	   INSERT INTO #NoOfPlayers(GameRound
						 , SportType
						 , BetType
						 , NoOfPlayers)
			SELECT GameRound
				, SportType
				, BetType
				, SUM(NoOfPlayers) AS NoOfPlayers
			FROM #GameRound_NoOfPlayers
			GROUP BY GameRound
				  , SportType
				  , BetType;

	   UPDATE r
			SET 
			    r.BetCount = c.BetCount
			  , r.NoOfPlayers = p.NoOfPlayers
	   FROM #Result AS r
		  INNER JOIN #BetCount AS c ON r.GameRound = c.GameRound
								 AND r.SportType = c.SportType
								 AND r.BetType = c.BetType
		  INNER JOIN #NoOfPlayers AS p ON r.GameRound = p.GameRound
								    AND r.SportType = p.SportType
								    AND r.BetType = p.BetType;

	   SELECT g.ProductID
		   , p.ProductName
		   , g.SportType
		   , g.BetType
		   , g.GameRound
		   , r.BetCount
		   , r.NoOfPlayers
		   , g.TotalStake
		   , g.ReachedLimitTime
		   , g.GameRoundBetLimit
	   FROM GameRoundBetLimitSummary AS g WITH(NOLOCK)
		  INNER JOIN #Result AS r ON g.GameRound = r.GameRound
							    AND g.SportType = r.SportType
							    AND g.BetType = r.BetType
		  INNER JOIN Products AS p WITH(NOLOCK) ON g.ProductID = p.ProductID
	   WHERE r.BetCount > 0
		    AND r.NoOfPlayers > 0;
	   DROP TABLE #Result;
	   DROP TABLE #GameRound_BetCount;
	   DROP TABLE #GameRound_NoOfPlayers;
	   DROP TABLE #BetCount;
	   DROP TABLE #NoOfPlayers;
    END;
GO