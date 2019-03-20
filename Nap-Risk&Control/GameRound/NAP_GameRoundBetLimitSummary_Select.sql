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
	  , BetCount     INT);

    CREATE TABLE #GameRound_NoOfPlayers(
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
						    , BetCount)
		 (
			SELECT g.GameRound
				, r.SportType
				, r.BetType
				, COUNT(1) AS BetCount
			FROM Intg_GameRoundBetStake AS g WITH (NOLOCK)
			    INNER JOIN #Result AS r ON g.GameRound = r.GameRound
									 AND CAST(g.GameType AS INT) = r.BetType
			GROUP BY g.GameRound
				  , r.SportType
				  , r.BetType
		 );

    CREATE INDEX IDX_GameRound_BetCount_GameRound_SportType_BetType ON #GameRound_BetCount(GameRound, SportType, BetType);

    INSERT INTO #GameRound_NoOfPlayers(GameRound
							  , SportType
							  , BetType
							  , NoOfPlayers)
		 (
			SELECT g1.GameRound
				, g1.SportType
				, g1.BetType
				, COUNT(1) AS NoOfPlayers
			FROM
				(
				    SELECT g.GameRound
					    , g.CustId
					    , r.SportType
					    , r.BetType
				    FROM Intg_GameRoundBetStake AS g
					   INNER JOIN #Result AS r ON g.GameRound = r.GameRound
											AND CAST(g.GameType AS INT) = r.BetType
				    GROUP BY g.GameRound
						 , g.CustId
						 , r.SportType
						 , r.BetType
				) AS g1
			GROUP BY g1.GameRound
				  , g1.SportType
				  , g1.BetType
		 );

    CREATE INDEX IDX_GameRound_NoOfPlayers_BetCount_GameRound_SportType_BetType ON #GameRound_NoOfPlayers(GameRound, SportType, BetType);

    UPDATE r
		 SET
			r.BetCount = c.BetCount
		   , r.NoOfPlayers = p.NoOfPlayers
    FROM #Result AS r
	   INNER JOIN #GameRound_BetCount AS c ON r.GameRound = c.GameRound
									  AND r.SportType = c.SportType
									  AND r.BetType = c.BetType
	   INNER JOIN #GameRound_NoOfPlayers AS p ON r.GameRound = p.GameRound
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
	   INNER JOIN Products AS p WITH (NOLOCK) ON g.ProductID = p.ProductID;

    DROP TABLE #Result;
    DROP TABLE #GameRound_BetCount;
    DROP TABLE #GameRound_NoOfPlayers;
END;
GO