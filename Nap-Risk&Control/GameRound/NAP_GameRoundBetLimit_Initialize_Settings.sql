/*<info serverAlias="DBCust-CustDB" executers="wsv_nap" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROC NAP_GameRoundBetLimit_Initialize_Settings 
	@ProductID     INT           = 21
   , @SportType     SMALLINT      = 211
   , @BettypeIDs    VARCHAR(2000) = '2407'
   , @BetLimits     VARCHAR(5000) = '200000'
AS
/*	Creator	 : 20191001@Robert
	Task		 : Initialize Global Game Round Bet Limit Settings [#121318]
	DB		 : DBCUST/CustDB
	
	Revisions	 : 
			- 20191001@Robert: Risk & Control - Implement Global Game Round Bet Limit Setting for Allbet Bull Bull [#121318]				
			- 20241230@July: Scale Out DBCUST - Apply Inhouse replication for the remaning tables [Redmine: #215627]
	 
	 Ex		 :

     EXEC NAP_GameRoundBetLimit_Initialize_Settings 
         @ProductID = 21, 
         @SportType = 211, 
         @BettypeIDs = '2407', 
         @BetLimits = '200000'        
*/

    BEGIN
	   SET NOCOUNT ON;
	   DECLARE @tmp TABLE(
		   ProductID    INT
		 , SportType    SMALLINT
		 , BettypeId    INT
		 , BetLimit     MONEY);

	   INSERT INTO @tmp(ProductID
				   , SportType
				   , BettypeId
				   , BetLimit)
			SELECT @ProductID AS ProductID
				, @SportType AS SportType
				, bt.val AS BettypeId
				, limit.val AS BetLimit
			FROM dbo.strSplit
				(@BettypeIDs, ',') AS bt
			    FULL JOIN dbo.strSplit
				(@BetLimits, ',') AS limit ON bt.rank = limit.rank;

	   IF EXISTS
			   (
				  SELECT TOP 1 1
				  FROM @tmp
				  WHERE BettypeId IS NULL
					   OR BetLimit IS NULL
			   )
		  BEGIN
			 SELECT 'Existing the Bettype or BetLimit Null, Please re-check the @BettypeIDs or @BetLimits.' AS ErrMsg;
			 RETURN;
	   END;

	   IF EXISTS
			   (
				  SELECT SportType
					  , BettypeId
					  , COUNT(1) AS cnt
				  FROM @tmp
				  GROUP BY SportType
					    , BettypeId
				  HAVING COUNT(1) > 1
			   )
		  BEGIN
			 SELECT SportType
				 , BettypeId
				 , COUNT(1) AS cnt
				 , 'Duplicated Data, Please re-check the @BettypeIDs' AS ErrMsg
			 FROM @tmp
			 GROUP BY SportType
				   , BettypeId
			 HAVING COUNT(1) > 1;

			 RETURN;
	   END;

	   IF EXISTS
			   (
				  SELECT b.ProductID
					  , b.SportType
					  , b.BetType
				  FROM @tmp AS t
					 INNER JOIN dbo.GameRoundBetLimitSettings AS b WITH(NOLOCK) ON t.SportType = b.SportType
																	   AND t.BettypeId = b.BetType
			   )
		  BEGIN
			 SELECT b.ProductID
				 , b.SportType
				 , b.BetType
				 , 'Existing Sporttype, Bettype at table dbo.GameRoundBetLimitSettings, Please re-check the @BettypeIDs' AS ErrMsg
			 FROM @tmp AS t
				INNER JOIN dbo.GameRoundBetLimitSettings AS b WITH(NOLOCK) ON t.SportType = b.SportType
																  AND t.BettypeId = b.BetType;
			 RETURN;
	   END;

	   INSERT INTO dbo.GameRoundBetLimitSettings(SportType
									   , BetType
									   , ProductID
									   , GameRoundBetLimit
									   , RepUpdateTime
							)
			SELECT SportType
				, BettypeId
				, ProductID
				, BetLimit
				, dbo.f_GetDateTime2()
			FROM @tmp;
    END;
GO