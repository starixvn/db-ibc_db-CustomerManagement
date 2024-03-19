
/*<info serverAlias="DBTXN-bodb02" executers="bodbAdminNet,wsv_nap" viewers="" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE NAP_GameRoundBetLimitMonitorSel 
                @FromDate        SMALLDATETIME, 
                @ToDate          SMALLDATETIME, 
                @ProductId       VARCHAR(200), 
                @BetType         VARCHAR(200), 
                @ExcludeTestData BIT           = 1
AS  
 
/*
Created: Jacob	
Date: 2019-03-12
Task: #109866 - Implement Game Ground Bet Limit Control

DB: DBCUST/CustDB

Revisions:
20190312@Jacob: Implement Game Ground Bet Limit Control [#109866].
20210315@Robert: 151686
*/

     DECLARE 
            @EndOfToDate DATETIME;
     SELECT 
            @EndOfToDate = DATEADD(SECOND, -1, DATEADD(DAY, 1, @ToDate)), 
            @ProductId = ISNULL(@ProductId, 0), 
            @BetType = ISNULL(@BetType, 0);
     DECLARE 
            @Products TABLE
     (
                            Id INT
     );
     DECLARE 
            @BetTypes TABLE
     (
                            Id INT
     );
     INSERT INTO @Products
            SELECT 
                   CAST(val AS INT)
            FROM dbo.strSplit(@ProductId, ',');
     INSERT INTO @BetTypes
            SELECT 
                   CAST(val AS INT)
            FROM dbo.strSplit(@BetType, ',');
     SELECT 
            s.ProductID, 
            p1.ProductName, 
            s.SportType, 
            s.BetType, 
            b1.typenamee as BetTypeName, 			
            s.BetCount, 
            s.NoOfPlayers, 
            s.TotalStake, 
            s.ReachedLimitTime, 
            s.GameRound, 
            s.GameRoundBetLimit
     FROM dbo.GameRoundBetLimitSummary s WITH(NOLOCK)
          INNER JOIN @Products p ON s.ProductID = p.Id
          INNER JOIN @BetTypes b ON s.BetType = b.Id
          INNER JOIN dbo.Products p1 WITH(NOLOCK) ON s.ProductID = p1.ProductID
          INNER JOIN dbo.bettype b1 WITH(NOLOCK) ON s.BetType = b1.typeid
     WHERE s.ReachedLimitTime BETWEEN @FromDate AND @EndOfToDate
           AND (@ExcludeTestData = 0
                OR s.IsTest = 0)
     ORDER BY 
              s.ReachedLimitTime DESC;

	 
GO