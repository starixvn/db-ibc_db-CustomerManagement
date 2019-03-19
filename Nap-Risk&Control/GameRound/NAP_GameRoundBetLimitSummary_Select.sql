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
	   @IsTest:
		  = 0 : just select bets reached limit belong to test currency (UUS, YNG)
		  = 1 : just select bets reached limit belong to real currency except (UUS, YNG)
		
*/

BEGIN
    SET NOCOUNT ON;

    CREATE TABLE #Result(
	    GameRound      VARCHAR(50)
	    PRIMARY KEY CLUSTERED
	  , BetCount       INT
	  , NoOfPlayers    INT);

    CREATE TABLE #GameRound_BetCount(
	    GameRound    VARCHAR(50)
	    PRIMARY KEY CLUSTERED
	  , BetCount     INT);

    CREATE TABLE #GameRound_NoOfPlayers(
	    GameRound      VARCHAR(50)
	    PRIMARY KEY CLUSTERED
	  , NoOfPlayers    INT);

    INSERT INTO #Result(GameRound)
		 (
			SELECT GameRound
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

    INSERT INTO #GameRound_BetCount(GameRound
						    , BetCount)
		 (
			SELECT g.GameRound
				, COUNT(1) AS BetCount
			FROM Intg_GameRoundBetStake AS g WITH (NOLOCK)
			    INNER JOIN #Result AS r ON g.GameRound = r.GameRound
			GROUP BY g.GameRound
		 );

    INSERT INTO #GameRound_NoOfPlayers(GameRound
							  , NoOfPlayers)
		 (
			SELECT GameRound
				, COUNT(1) AS NoOfPlayers
			FROM
				(
				    SELECT g.GameRound
					    , g.CustId
				    FROM Intg_GameRoundBetStake AS g WITH (NOLOCK)
					   INNER JOIN #Result AS r ON g.GameRound = r.GameRound
				    GROUP BY g.GameRound
						 , g.CustId
				) AS g1
			GROUP BY GameRound
		 );


    UPDATE r
		 SET
			r.BetCount = c.BetCount
		   , r.NoOfPlayers = p.NoOfPlayers
    FROM #Result AS r
	   INNER JOIN #GameRound_BetCount AS c ON r.GameRound = c.GameRound
	   INNER JOIN #GameRound_NoOfPlayers AS p ON r.GameRound = p.GameRound;

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
	   INNER JOIN Products AS p WITH (NOLOCK) ON g.ProductID = p.ProductID;

    DROP TABLE #Result;
    DROP TABLE #GameRound_BetCount;
    DROP TABLE #GameRound_NoOfPlayers;
END;
GO