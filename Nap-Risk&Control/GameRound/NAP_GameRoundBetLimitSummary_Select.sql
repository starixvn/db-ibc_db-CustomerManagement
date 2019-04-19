/*<info serverAlias="DBTXN-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE NAP_GameRoundBetLimitSummary_Select
	@IsTest       BIT = 0
   , @SportType    INT = 0
   , @BetType      INT = 0
AS
/*	Creator: 20190313@Robert
	Task:  When a game round has been reached a limit, need to select information and send email to admin
	DB: DBTXN/bodb02	
	Revisions: 
		 - 20190313@Robert: #109866 - Risk & Control - Implement Global Game Round Bet Limit Setting and Report/Notification
     Param:
*/

BEGIN
    SET NOCOUNT ON;

    CREATE TABLE #Result(
	    GameRound      VARCHAR(50)
	  , SportType      SMALLINT
	  , BetType        INT
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


    INSERT INTO #Result(GameRound
				  , SportType
				  , BetType)
		 (
			SELECT GameRound
				, SportType
				, BetType
			FROM GameRoundBetLimitSummary AS g WITH (NOLOCK)
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

    CREATE INDEX IDX_Result_GameRound_SportType_BetType ON #Result(GameRound, SportType, BetType);

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
				    FROM Intg_GameRoundBetStake AS g WITH (NOLOCK)
					   INNER JOIN SportBettypeMatrix AS sb WITH (NOLOCK) ON sb.BetType = g.GameType
					   INNER JOIN CustDB.dbo.custInfo AS ci ON ci.custid = g.CustId
					   INNER JOIN #Result AS r ON g.GameRound = r.GameRound
											AND CAST(g.GameType AS INT) = r.BetType
				    WHERE sb.ProductID = 21 -- Allbet
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
			FROM Intg_GameRoundBetStake AS g WITH (NOLOCK)
			    INNER JOIN SportBettypeMatrix AS sb WITH (NOLOCK) ON sb.BetType = g.GameType
			    INNER JOIN CustDB.dbo.custInfo AS ci ON ci.custid = g.CustId
			    INNER JOIN #Result AS r ON g.GameRound = r.GameRound
									 AND CAST(g.GameType AS INT) = r.BetType
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
				    FROM Intg_GameRoundBetStake AS g
					   INNER JOIN CustDB.dbo.custInfo AS ci ON g.CustId = ci.custid
					   INNER JOIN #Result AS r ON g.GameRound = r.GameRound
											AND CAST(g.GameType AS INT) = r.BetType
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

    SELECT GameRound
	    , SportType
	    , BetType
	    , SUM(BetCount) AS BetCount
    INTO #BetCount
    FROM #GameRound_BetCount
    GROUP BY GameRound
		 , SportType
		 , BetType;


    SELECT GameRound
	    , SportType
	    , BetType
	    , SUM(NoOfPlayers) AS NoOfPlayers
    INTO #NoOfPlayers
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
    FROM GameRoundBetLimitSummary AS g WITH (NOLOCK)
	   INNER JOIN #Result AS r ON g.GameRound = r.GameRound
							AND g.SportType = r.SportType
							AND g.BetType = r.BetType
	   INNER JOIN Products AS p WITH (NOLOCK) ON g.ProductID = p.ProductID
    WHERE r.BetCount > 0
		AND r.NoOfPlayers > 0;
    DROP TABLE #Result;
    DROP TABLE #GameRound_BetCount;
    DROP TABLE #GameRound_NoOfPlayers;
    DROP TABLE #BetCount;
    DROP TABLE #NoOfPlayers;
END;
GO