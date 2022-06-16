/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.NAP_CWL_Update_Settings 
	@ProductId INT, 
	@GroupId   INT, 
	@Level1    MONEY, 
	@Level2    MONEY, 
	@Level3    MONEY, 
	@Level101  MONEY, 
	@Level102  MONEY, 
	@Currency  VARCHAR(MAX) = '' ---
AS

/*	
    Creator	 : 20180531@Robert
	Task		 : Update CWL Settings [#91762]
	DB		 : DBCUST.CustDB
	
	Revisions	 : 
				- 20180531@Robert: Update CWL Settings				
				- 20220223@Johnson: Global setting by currency [#168583]
				- 20220614@Eden: DBCUST - modify sp syntax to adapt with the SQL Server upgrade to 2019 [Redmine: #171831] 
				- 20220522@Robert: #168458 - CWL - Enhance Currency Win Limit Setting page
     Ex		 :

     EXEC NAP_CWL_Update_Settings 
         @ProductId    = 6
	  , @GroupId      = 3
	  , @Level1       = 20000
	  , @Level2       = 50000
	  , @Level3       = 100000
	  , @Level101     = -20000
	  , @Level102     = -50000
		
*/

    BEGIN
	   SET NOCOUNT ON;

	   DECLARE 
		   @LevelSettings TABLE
						    (
		   LevelId INT, 
		   Level   MONEY
						    );


	   DECLARE 
		   @tblCurrency TABLE
						  (
		   Currency VARCHAR(5)
						  );


	   INSERT INTO @tblCurrency
		 (
			Currency
		 )
			SELECT 
				  value
			FROM STRING_SPLIT(@currency, ',')
			WHERE value <> ''



	   INSERT INTO @LevelSettings
		 (
			LevelId, 
			Level
		 )
			SELECT 
				  1 AS LevelId, 
				  @Level1 AS Level
			UNION ALL
			SELECT 
				  2 AS LevelId, 
				  @Level2 AS Level
			UNION ALL
			SELECT 
				  3 AS LevelId, 
				  @Level3 AS Level
			UNION ALL
			SELECT 
				  101 AS LevelId, 
				  @Level101 AS Level
			UNION ALL
			SELECT 
				  102 AS LevelId, 
				  @Level102 AS Level;

	   IF(@Currency = '')
		  BEGIN
			UPDATE g
			SET 
				Level1 = @Level1, 
				Level2 = @Level2, 
				level3 = @Level3, 
				Level101 = @Level101, 
				Level102 = @Level102
			FROM Winlimit_ProductGlobalSetting g WITH (ROWLOCK, UPDLOCK)
			WHERE 
				ProductID = @ProductId
				AND GroupID = @GroupId
				AND g.Currency NOT IN (SELECT currency FROM Winlimit_ProductGlobalSetting WITH(NOLOCK)
											WHERE ProductID = @ProductId
												AND GroupID = @GroupId
												AND currency <> 0
											)
			 UPDATE psd
			   SET 
				  psd.MaxWinLimit_RM = l.Level, 
				  psd.MaxWinlimit = CASE
								    WHEN psd.ExchangeID = 20
								    THEN l.Level
								    ELSE ROUND(l.Level / e.actualrate, 2)
								END
			 FROM WinLimit_ProductSettingDetail AS psd WITH (ROWLOCK, UPDLOCK)
				 INNER JOIN @LevelSettings AS l ON psd.LevelID = l.LevelId
				 INNER JOIN Exchange e WITH(NOLOCK) ON e.ExchangeId = psd.ExchangeID
			 WHERE 
				  psd.MaxWinLimit_RM IS NOT NULL
				  AND psd.ProductID = @ProductId
				  AND psd.GroupID = @GroupId
				  AND psd.ExchangeID NOT IN (SELECT currency FROM Winlimit_ProductGlobalSetting WITH(NOLOCK)
											WHERE ProductID = @ProductId
												AND GroupID = @GroupId
												AND currency <> 0
											);
		  END;
		  ELSE
		  BEGIN
			UPDATE g
			SET 
				Level1 = @Level1, 
				Level2 = @Level2, 
				level3 = @Level3, 
				Level101 = @Level101, 
				Level102 = @Level102
			FROM Winlimit_ProductGlobalSetting g WITH (ROWLOCK, UPDLOCK)
			WHERE 
				ProductID = @ProductId
				AND GroupID = @GroupId
				AND g.Currency IN (SELECT ExchangeId 
									FROM Exchange e WITH(NOLOCK) 
									INNER JOIN @tblCurrency c ON e.currency = c.Currency
									)
											
			 UPDATE psd
			   SET 
				  psd.MaxWinLimit_RM = l.Level, 
				  psd.MaxWinlimit = CASE
								    WHEN psd.ExchangeID = 20
								    THEN l.Level
								    ELSE ROUND(l.Level / e.actualrate, 2)
								END
			 FROM WinLimit_ProductSettingDetail AS psd WITH (ROWLOCK, UPDLOCK)
				 INNER JOIN @LevelSettings AS l ON psd.LevelID = l.LevelId
				 INNER JOIN Exchange e WITH(NOLOCK) ON e.ExchangeId = psd.ExchangeID
				 INNER JOIN @tblCurrency c ON e.currency = c.Currency
			 WHERE 
				  psd.MaxWinLimit_RM IS NOT NULL
				  AND psd.ProductID = @ProductId
				  AND psd.GroupID = @GroupId;
		  END;

    END;
GO

