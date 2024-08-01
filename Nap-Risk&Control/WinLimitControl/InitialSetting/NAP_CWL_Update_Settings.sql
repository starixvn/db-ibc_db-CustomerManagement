/*<info serverAlias="DBCUST-CustDB" executers="wsv_nap" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.NAP_CWL_Update_Settings 
	@ProductId INT, 
	@GroupId   INT, 
	@Level1    MONEY, 
	@Level2    MONEY, 
	@Level3    MONEY, 
	@Level101  MONEY, 
	@Level102  MONEY, 
	@Currency  VARCHAR(MAX) = '', ---
	@IsDeposit BIT = 0
AS

/*	
    Creator	 : 20180531@Robert
	Task		 : Update CWL Settings [#91762]
	DB		 : DBCUST.CustDB
	
	Revisions	 : 
				- 20180531@Robert: Update CWL Settings				
				- 20220223@Johnson: Global setting by currency [#168583]
				- 20220614@Eden: DBCUST - modify sp syntax to adapt with the SQL Server upgrade to 2019 [Redmine: #171831] 
				- 20230914@Johnson: Add IsDeposit to separate credit & deposit global setting [redmine:#193708]
				- 20240719@Tacy: Update setting by batch [redmine: #208200]
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

	   DECLARE @tmpProductSettingDetail TABLE(
				ProductID	TINYINT NOT NULL,
				GroupID		SMALLINT NOT NULL,
				ExchangeID	INT NOT NULL,
				SiteID		INT NOT NULL,
				LevelID		TINYINT NOT NULL,
				MaxWinLimit MONEY NOT NULL,
				MaxWinLimit_RM MONEY NULL,
				PRIMARY KEY CLUSTERED 
				(
					ProductID ASC,
					GroupID ASC,
					ExchangeID ASC,
					SiteID ASC,
					LevelID ASC
				)
		)

	   DECLARE @tmpProductSettingDetail_batch TABLE(
				ProductID	TINYINT NOT NULL,
				GroupID		SMALLINT NOT NULL,
				ExchangeID	INT NOT NULL,
				SiteID		INT NOT NULL,
				LevelID		TINYINT NOT NULL,
				MaxWinLimit MONEY NOT NULL,
				MaxWinLimit_RM MONEY NULL,
				PRIMARY KEY CLUSTERED 
				(
					ProductID ASC,
					GroupID ASC,
					ExchangeID ASC,
					SiteID ASC,
					LevelID ASC
				)
		)

	   DECLARE 
		   @LevelSettings TABLE
						    (
		   LevelId INT, 
		   Level   MONEY
						    );


	   DECLARE 
		   @tblCurrency TABLE
						  (
		   Currency VARCHAR(3)
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
				AND IsDeposit = @IsDeposit
				AND g.Currency NOT IN (SELECT currency FROM Winlimit_ProductGlobalSetting WITH(NOLOCK)
											WHERE ProductID = @ProductId
												AND GroupID = @GroupId
												AND currency <> 0
												AND IsDeposit = @IsDeposit
											)
			 
			 INSERT INTO @tmpProductSettingDetail (ProductID, GroupID, ExchangeID, SiteID, LevelID, MaxWinLimit_RM, MaxWinLimit)
			 SELECT psd.ProductID, psd.GroupID, psd.ExchangeID, psd.SiteID, psd.LevelID,
					l.Level AS MaxWinLimit_RM, 
					CASE
						WHEN psd.ExchangeID = 20
						THEN l.Level
						ELSE ROUND(l.Level / e.actualrate, 2)
					END AS MaxWinlimit
			 FROM WinLimit_ProductSettingDetail AS psd WITH (NOLOCK)
				 INNER JOIN @LevelSettings AS l ON psd.LevelID = l.LevelId
				 INNER JOIN Exchange e WITH(NOLOCK) ON e.ExchangeId = psd.ExchangeID
				 INNER JOIN  Site s WITH(NOLOCK) ON psd.SiteID = s.SiteID
			 WHERE 
				  psd.MaxWinLimit_RM IS NOT NULL
				  AND psd.ProductID = @ProductId
				  AND psd.GroupID = @GroupId
				  AND ((s.isLicensee = 1 AND @IsDeposit = 1)
						OR (s.isLicensee = 0 AND @IsDeposit = 0)
						)
				  AND psd.ExchangeID NOT IN (SELECT currency FROM Winlimit_ProductGlobalSetting WITH(NOLOCK)
											WHERE ProductID = @ProductId
												AND GroupID = @GroupId
												AND IsDeposit = @IsDeposit
												AND currency <> 0
											)
				--get Diff value only
				  AND l.Level <> psd.MaxWinLimit_RM
				  AND CASE
						WHEN psd.ExchangeID = 20
						THEN l.Level
						ELSE ROUND(l.Level / e.actualrate, 2)
					END <> psd.MaxWinlimit
				;
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
				AND IsDeposit = @IsDeposit	
				AND g.Currency IN (SELECT ExchangeId 
									FROM Exchange e WITH(NOLOCK) 
									INNER JOIN @tblCurrency c ON e.currency = c.Currency
									)
											
			 INSERT INTO @tmpProductSettingDetail (ProductID, GroupID, ExchangeID, SiteID, LevelID, MaxWinLimit_RM, MaxWinLimit)
			 SELECT psd.ProductID, psd.GroupID, psd.ExchangeID, psd.SiteID, psd.LevelID,
					l.Level AS MaxWinLimit_RM, 
					CASE
						WHEN psd.ExchangeID = 20
						THEN l.Level
						ELSE ROUND(l.Level / e.actualrate, 2)
					END AS MaxWinlimit
			 FROM WinLimit_ProductSettingDetail AS psd WITH (NOLOCK)
				 INNER JOIN @LevelSettings AS l ON psd.LevelID = l.LevelId
				 INNER JOIN Exchange e WITH(NOLOCK) ON e.ExchangeId = psd.ExchangeID
				 INNER JOIN @tblCurrency c ON e.currency = c.Currency
				 INNER JOIN  Site s WITH(NOLOCK) ON psd.SiteID = s.SiteID
			 WHERE 
				  psd.MaxWinLimit_RM IS NOT NULL
				  AND psd.ProductID = @ProductId
				  AND psd.GroupID = @GroupId
				  AND ((s.isLicensee = 1 AND @IsDeposit = 1)
						OR (s.isLicensee = 0 AND @IsDeposit = 0)
						)
				--get Diff value only
				  AND l.Level <> psd.MaxWinLimit_RM
				  AND CASE
						WHEN psd.ExchangeID = 20
						THEN l.Level
						ELSE ROUND(l.Level / e.actualrate, 2)
					END <> psd.MaxWinlimit
		  END;

		DECLARE @Batch INT = 2000;

		WHILE (1=1)
		BEGIN
			DELETE FROM @tmpProductSettingDetail_batch

			DELETE TOP (@Batch) T
			OUTPUT deleted.ProductID, deleted.GroupID, deleted.ExchangeID, deleted.SiteID
				, deleted.LevelID, deleted.MaxWinLimit_RM, deleted.MaxWinLimit
				INTO @tmpProductSettingDetail_batch(ProductID, GroupID, ExchangeID, SiteID, LevelID, MaxWinLimit_RM, MaxWinLimit)
			FROM @tmpProductSettingDetail T

			IF @@ROWCOUNT=0
				BREAK

			UPDATE psd
			SET psd.MaxWinLimit=t.MaxWinLimit
				,psd.MaxWinLimit_RM=t.MaxWinLimit_RM
			FROM WinLimit_ProductSettingDetail psd WITH (ROWLOCK, UPDLOCK)
			INNER JOIN @tmpProductSettingDetail_batch t
					ON t.ProductID=psd.ProductID
					AND t.GroupID=psd.GroupID
					AND t.ExchangeID=psd.ExchangeID
					AND t.SiteID=psd.SiteID
					AND t.LevelID=psd.LevelID

			WAITFOR DELAY '00:00:0.200'
		END
    END;
GO