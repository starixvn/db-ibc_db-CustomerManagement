/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_InitializingStake_StakelevelIns] 
	-- Add the parameters for the stored procedure here
	 @InputData	VARCHAR(MAX) = ''
	,@UserID	INT
	,@IP		VARCHAR(50)		= ''
	,@ErrCode	INT = 0				OUTPUT
	,@ErrMsg	NVARCHAR(4000) = '' OUTPUT
AS
/*
	Task : NAP -  Flexible Initializing Stake Level
	DB: DBCUST/CustDB
	Original: 
	Revisions:
		- 20220210@Winfred: NAP -  Flexible Initializing insert Stake Level [Redmine: #167128]
		- 20220420@Winfred: Fix setting type 7 get bettype original [Redmine: #171750]
		- 20220520@Tacy: insert history of update global stake level [RedmineID: #170739]
		- 20220614@Eden: DBCUST - modify sp syntax to adapt with the SQL Server upgrade to 2019 [Redmine: #171831] 
	Param's Explanation:
		• @pInputData : 
		<ROOT>
			<BetLimit 
					SportType="1" 
					BetType="1"
					Site="53"
					CreditCurrency = "US$, Yen, $US, UT, USD" 
					DepositCurrency = "US$, USDT"
					NewMinBet="1" 
					NewMaxBet="30000" 
					CurMinBet="30000" 
					CurMaxBet="30000" 
					GameGroupID="30000" 
			/>
	</ROOT>
*/
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @SettingList VARCHAR(MAX)
	DECLARE @xml XML, @StartRun	DATETIME, @EndRun DATETIME, @Duration INT, @logSpData NVARCHAR(MAX)
	DECLARE @Dep_MaxSLID INT
	DECLARE @NewStakeLevelTbl TABLE (
			RowID				INT IDENTITY (1,1)
			, SportType			SMALLINT
			, BetType			SMALLINT
			, SiteID			INT
			, CreditCurrency	VARCHAR(500)
			, DepositCurrency	VARCHAR(500)
			, NewMinBet			DECIMAL(19,8)
			, NewMaxBet			DECIMAL(19,8)
			, CurMinBet			DECIMAL(19,8)
			, CurMaxBet			DECIMAL(19,8)
			, GameGroupID		INT
		)
	
	CREATE TABLE #NewInputDateTbl (
			  RowID			INT 
			, SportType		SMALLINT
			, OrgBetType	SMALLINT
			, BetType		SMALLINT
			, SiteID		INT
			, Currency		VARCHAR(50)
			, ExchangeId	INT
			, MinLabel		VARCHAR(50)
			, MaxLabel		VARCHAR(50)
			, NewMinBet		DECIMAL(19,8)
			, NewMaxBet		DECIMAL(19,8)
			, CurMinBet		DECIMAL(19,8)
			, CurMaxBet		DECIMAL(19,8)
			, GameGroupID	INT
			, IsCredit		BIT DEFAULT((0))
			, SettingType	SMALLINT
		)

	DECLARE @History_StakeLevelTbl TABLE (
			  StakeLevelID	INT
			, GameTypeID	INT
			, MaxLabel		NVARCHAR(50)
			, MaxStake		DECIMAL(19,8)
			, MaxGameStake	DECIMAL(19,8)
			, SiteID		INT
			, UpdateTime	DATETIME
			, IsGroup		BIT
			, IsCredit		BIT
		)	

	IF @InputData IS NULL OR @InputData = ''
		RETURN
		
	SELECT	@ErrCode = 0 , @ErrMsg = '' 
	
	SET @StartRun = GETDATE()	
	--Parse XML data
	DECLARE @iDoc INT
	BEGIN TRY
		EXEC sp_xml_preparedocument @iDoc OUTPUT
			, @InputData

		INSERT INTO @NewStakeLevelTbl(SportType, BetType, SiteID, CreditCurrency, DepositCurrency, NewMinBet, NewMaxBet, CurMinBet, CurMaxBet, GameGroupID)
		SELECT SportType, BetType, Site, CreditCurrency, DepositCurrency, NewMinBet, NewMaxBet, CurMinBet, CurMaxBet, GameGroupID
		FROM OPENXML(@iDoc, '/ROOT/BetLimit', 1) WITH (
					SportType			SMALLINT
					, BetType			SMALLINT
					, Site				INT
					, CreditCurrency	VARCHAR(500)
					, DepositCurrency	VARCHAR(500)
					, NewMinBet			DECIMAL(19,8)
					, NewMaxBet			DECIMAL(19,8)
					, CurMinBet			DECIMAL(19,8)
					, CurMaxBet			DECIMAL(19,8)
					, GameGroupID		INT
				)
		EXEC sp_xml_removedocument @iDoc
		
		INSERT INTO #NewInputDateTbl(RowID, SportType, BetType, Currency, NewMinBet, NewMaxBet, CurMinBet, CurMaxBet, GameGroupID, IsCredit, SiteID)
		SELECT RowID, SportType, BetType, t.Currency, NewMinBet, NewMaxBet, CurMinBet, CurMaxBet, GameGroupID, 1 AS IsCredit, SiteID
		FROM @NewStakeLevelTbl nsl
			CROSS APPLY (
					SELECT DISTINCT RTRIM(LTRIM(value)) AS Currency FROM STRING_SPLIT(nsl.CreditCurrency, ',') WHERE value <> ''
				) t
		WHERE nsl.CreditCurrency <> ''
		UNION ALL
		SELECT RowID, SportType, BetType, t.Currency, NewMinBet, NewMaxBet, CurMinBet, CurMaxBet, GameGroupID, 0 AS IsCredit, SiteID 
		FROM @NewStakeLevelTbl nsl
			CROSS APPLY (
					SELECT DISTINCT RTRIM(LTRIM(value)) AS Currency FROM STRING_SPLIT(nsl.DepositCurrency, ',') WHERE value <> ''
				) t		
		WHERE nsl.DepositCurrency <> ''
		
		UPDATE a 
		SET a.ExchangeId = CASE WHEN a.IsCredit = 1 AND e.OfferSite IN (0,1) THEN e.ExchangeId
								WHEN a.IsCredit = 0 AND e.OfferSite IN (0,2) THEN e.ExchangeId
							ELSE NULL END
			,a.MinLabel  =  CASE WHEN CAST(NewMinBet AS BIGINT) < NewMinBet 
							THEN REPLACE(RTRIM(REPLACE(NewMinBet, '0', ' ')), ' ', '0') 
							ELSE REPLACE(REPLACE(RTRIM(REPLACE(NewMinBet, '0', ' ')), ' ', '0'),'.','') END 
			,a.MaxLabel  =  CASE WHEN CAST(NewMaxBet AS BIGINT) < NewMaxBet 
							THEN REPLACE(RTRIM(REPLACE(NewMaxBet, '0', ' ')), ' ', '0') 
							ELSE REPLACE(REPLACE(RTRIM(REPLACE(NewMaxBet, '0', ' ')), ' ', '0'),'.','') END 								
		FROM  #NewInputDateTbl a
			INNER JOIN Exchange e WITH(NOLOCK) ON a.Currency = e.currency
		
		UPDATE t
		SET MaxLabel = REVERSE(STUFF (REVERSE(t.MaxLabel),CHARINDEX('.',REVERSE(t.MaxLabel),0) + 4,0,','))
		FROM #NewInputDateTbl t
		WHERE NewMaxBet > 999
		
		UPDATE t
		SET MaxLabel = REVERSE(STUFF (REVERSE(t.MaxLabel),CHARINDEX('.',REVERSE(t.MaxLabel),0) + 8,0,','))
		FROM #NewInputDateTbl t
		WHERE NewMaxBet > 999999
		
		UPDATE t
		SET MinLabel = REVERSE(STUFF (REVERSE(t.MinLabel),CHARINDEX('.',REVERSE(t.MinLabel),0) + 4,0,','))
		FROM #NewInputDateTbl t
		WHERE NewMinBet > 999
		
		UPDATE t
		SET MinLabel = REVERSE(STUFF (REVERSE(t.MinLabel),CHARINDEX('.',REVERSE(t.MinLabel),0) + 8,0,','))
		FROM #NewInputDateTbl t
		WHERE NewMinBet > 999999
		
		UPDATE a 
		SET a.SettingType =  psd.SettingType , a.OrgBetType = psd.BetType	
		FROM  #NewInputDateTbl a
			INNER JOIN ProductSettingDetail psd WITH(NOLOCK) ON a.SportType = psd.SportType AND ( psd.SettingType  = 8 OR (psd.SettingType IN (7, 17) AND a.BetType = psd.BetType))
		WHERE a.IsCredit = 1 AND psd.SettingType IN (7, 17, 8)
		
		UPDATE a 
		SET a.SettingType =  ps.SettingType	, a.OrgBetType = psd.BetType
		FROM  #NewInputDateTbl a
			INNER JOIN Dep_ProductSettingDetail psd WITH(NOLOCK) ON a.SportType = psd.SportType
			INNER JOIN Dep_ProductSetting ps WITH(NOLOCK) ON ps.ProductSettingID = psd.ProductSettingID
		WHERE a.IsCredit = 0   AND ( ps.SettingType = 8 OR (ps.SettingType IN (7) AND a.BetType = psd.BetType))
	END TRY
	BEGIN CATCH
		SELECT  @ErrCode = ERROR_NUMBER(),@ErrMsg = ERROR_MESSAGE();		
		RETURN
	END CATCH
		
	BEGIN TRY
		-- Credit Group Stake Level
		INSERT INTO StakeLevel(GameTypeID,ExchangeId,GameGroupID)
		SELECT DISTINCT a.OrgBetType AS GameTypeID,ExchangeId,GameGroupID
		FROM #NewInputDateTbl a 
		WHERE a.IsCredit =  1 AND SettingType IN (8) 
		AND NOT EXISTS( SELECT TOP 1 1 FROM StakeLevel tmp WITH(NOLOCK) 
						WHERE tmp.GameTypeID = a.OrgBetType AND a.ExchangeId = tmp.ExchangeId 
							  AND a.GameGroupID = tmp.GameGroupID)
		ORDER BY a.OrgBetType
		
		;WITH STAKE_TEMP AS (
			SELECT t.StakeLevelID,s.BetType AS GameTypeID,s.MinLabel,s.MaxLabel,s.NewMinBet AS MinStake,s.NewMaxBet AS MaxStake,s.ExchangeId,s.GameGroupID
			FROM #NewInputDateTbl s 
			CROSS APPLY (
				SELECT StakeLevelID  FROM StakeLevel WITH(NOLOCK) WHERE GameTypeID = s.OrgBetType AND ExchangeId = s.ExchangeId AND GameGroupID = s.GameGroupID
			) t
			WHERE s.IsCredit =  1 AND SettingType IN (8)
		)
		MERGE StakeLevelGroupDetail as g 
		USING STAKE_TEMP s on g.StakeLevelID = s.StakeLevelID AND g.GameTypeID = s.GameTypeID
		WHEN MATCHED THEN UPDATE SET 
							g.MinLabel = s.MinLabel,
							g.MaxLabel = s.MaxLabel,
							g.MinStake = s.MinStake,
							g.MaxStake = s.MaxStake
		WHEN NOT MATCHED THEN 
							INSERT (StakeLevelID,GameTypeID,MinLabel,MaxLabel,MinStake,MaxStake)
							VALUES (s.StakeLevelID,s.GameTypeID,s.MinLabel,s.MaxLabel,s.MinStake,s.MaxStake)					
							
							OUTPUT deleted.StakeLevelID, deleted.GameTypeID, deleted.MaxLabel, deleted.MaxStake, deleted.MaxGameStake, GETDATE(), 1, 1
								INTO @History_StakeLevelTbl(StakeLevelID, GameTypeID, MaxLabel, MaxStake, MaxGameStake, UpdateTime, IsGroup, IsCredit);

		-- Credit Stake Level
		INSERT INTO StakeLevel(GameTypeID, MinLabel, MaxLabel, MinStake, MaxStake,ExchangeId)
		SELECT DISTINCT a.BetType AS GameTypeID,MinLabel,MaxLabel,NewMinBet,NewMaxBet, ExchangeId
		FROM #NewInputDateTbl a 
		WHERE a.IsCredit =  1 AND SettingType IN (7,17) 
		AND NOT EXISTS( SELECT TOP 1 1 FROM StakeLevel tmp WITH(NOLOCK) 
						WHERE tmp.GameTypeID = a.BetType AND a.ExchangeId = tmp.ExchangeId 
							  AND (a.CurMinBet = MinStake AND a.CurMaxBet = MaxStake))
		ORDER BY a.BetType
		
		UPDATE dst	
		SET dst.MinLabel = a.MinLabel, dst.MaxLabel = a.MaxLabel , dst.MinStake = a.NewMinBet,dst.MaxStake = a.NewMaxBet
		OUTPUT deleted.StakeLevelID, deleted.GameTypeID, deleted.MaxLabel, deleted.MaxStake, GETDATE(), 0, 1
			INTO @History_StakeLevelTbl(StakeLevelID, GameTypeID, MaxLabel, MaxStake, UpdateTime, IsGroup, IsCredit)
		FROM StakeLevel dst	 WITH (ROWLOCK, UPDLOCK)
			INNER JOIN  #NewInputDateTbl a	ON 	dst.GameTypeID = a.BetType AND a.ExchangeId = dst.ExchangeId 
								 AND a.CurMinBet = MinStake AND a.CurMaxBet = MaxStake
		WHERE a.IsCredit = 1 AND SettingType IN (7,17) 

		--CREDIT: delete update MinStake only
		DELETE his
		FROM @History_StakeLevelTbl his
			INNER JOIN StakeLevel sl ON sl.StakeLevelID=his.StakeLevelID
									AND sl.MaxStake=his.MaxStake
									AND sl.MaxLabel=his.MaxLabel
		WHERE IsGroup=0

		DELETE his
		FROM @History_StakeLevelTbl his
			INNER JOIN StakeLevelGroupDetail slg ON slg.StakeLevelID=his.StakeLevelID
												AND slg.GameTypeID=his.GameTypeID
												AND slg.MaxStake=his.MaxStake
												AND slg.MaxLabel=his.MaxLabel
		WHERE IsGroup=1

		--CREDIT: Insert history of update global StakeLevel
		IF EXISTS (SELECT 1 FROM @History_StakeLevelTbl WHERE IsGroup=0 AND IsCredit=1)
		BEGIN
			SET @SettingList = (SELECT	StakeLevelID	AS '@StakeLevelID',
										GameTypeID		AS '@GameTypeID',
										MaxLabel		AS '@MaxLabel',
										MaxStake		AS '@MaxStake',
										'NULL'			AS '@MaxGameStake',
										'NULL'			AS '@SiteID',
										UpdateTime		AS '@UpdateTime'	
								FROM @History_StakeLevelTbl
								WHERE IsGroup=0 AND IsCredit=1
								FOR XML PATH('r') , ROOT('root')
								)

			EXEC Task_DetectBet_StakeLevelHistory_Insert @SettingList=@SettingList, @IsGroup=0, @ErrMsg=@ErrMsg OUTPUT

			IF @ErrMsg<>''
				RETURN
		END

		IF EXISTS (SELECT 1 FROM @History_StakeLevelTbl WHERE IsGroup=1 AND IsCredit=1)
		BEGIN
			SET @SettingList = (SELECT	StakeLevelID	AS '@StakeLevelID',
										GameTypeID		AS '@GameTypeID',
										MaxLabel		AS '@MaxLabel',
										MaxStake		AS '@MaxStake',
										MaxGameStake	AS '@MaxGameStake',
										'NULL'			AS '@SiteID',
										UpdateTime		AS '@UpdateTime'	
								FROM @History_StakeLevelTbl
								WHERE IsGroup=1 AND IsCredit=1
								FOR XML PATH('r') , ROOT('root')
								)

			EXEC Task_DetectBet_StakeLevelHistory_Insert @SettingList=@SettingList, @IsGroup=1, @ErrMsg=@ErrMsg OUTPUT

			IF @ErrMsg<>''
				RETURN
		END

	END TRY
	BEGIN CATCH
		SELECT  @ErrCode = ERROR_NUMBER(),@ErrMsg = ERROR_MESSAGE();		
		RETURN
	END CATCH
	
	BEGIN TRY	
		-- Deposit Stake Level
		SELECT @Dep_MaxSLID = MAX(StakeLevelID) FROM DEP_StakeLevel WITH(NOLOCK)
		
		INSERT INTO Dep_StakeLevel(GameTypeID,MinLabel,MaxLabel,MinStake,MaxStake,ExchangeId,GameGroupID,SiteID,StakeLevelID)
		SELECT GameTypeID,MinLabel,MaxLabel,MinStake,MaxStake,ExchangeId,GameGroupID ,SiteID, StakeLevelID = @Dep_MaxSLID + ROW_NUMBER() OVER(ORDER BY GameTypeID,exchangeid)  
		FROM (
			SELECT DISTINCT a.OrgBetType AS GameTypeID,a.ExchangeId,0 AS GameGroupID, a.MinLabel, a.MaxLabel, a.NewMinBet AS MinStake, a.NewMaxBet AS MaxStake,SiteID
			FROM #NewInputDateTbl a
			WHERE a.IsCredit =  0 AND SettingType IN (7) 
				 AND NOT EXISTS( SELECT TOP 1 1 FROM Dep_StakeLevel tmp WITH(NOLOCK) 
								 WHERE tmp.GameTypeID = a.BetType AND a.ExchangeId = tmp.ExchangeId 
								 AND a.CurMinBet = MinStake AND a.CurMaxBet = MaxStake AND tmp.SiteID = a.SiteID)
			UNION
			SELECT DISTINCT a.OrgBetType AS GameTypeID,a.ExchangeId,a.GameGroupID, NULL AS MinLabel, NULL AS MaxLabel, NULL AS MinStake, NULL AS MaxStake,SiteID
			FROM #NewInputDateTbl a
			WHERE a.IsCredit =  0 AND SettingType IN (8) 
				 AND NOT EXISTS( SELECT TOP 1 1 FROM Dep_StakeLevel tmp WITH(NOLOCK) 
								 WHERE tmp.GameTypeID = a.OrgBetType AND a.ExchangeId = tmp.ExchangeId 
								 AND a.GameGroupID = tmp.GameGroupID)
		 ) KQ 
		
		;WITH STAKE_TEMP AS (
			SELECT t.StakeLevelID,s.BetType AS GameTypeID,s.MinLabel,s.MaxLabel,s.NewMinBet AS MinStake,s.NewMaxBet AS MaxStake,s.ExchangeId,s.GameGroupID
			FROM #NewInputDateTbl s 
			CROSS APPLY (
				SELECT StakeLevelID  FROM Dep_StakeLevel WITH(NOLOCK) WHERE GameTypeID = s.OrgBetType AND ExchangeId = s.ExchangeId AND GameGroupID = s.GameGroupID
			) t
			WHERE s.IsCredit =  0 AND SettingType IN (8)
		)
		MERGE Dep_StakeLevelGroupDetail as g 
		USING STAKE_TEMP s on g.StakeLevelID = s.StakeLevelID AND g.GameTypeID = s.GameTypeID
		WHEN MATCHED THEN UPDATE SET 
							g.MinLabel = s.MinLabel,
							g.MaxLabel = s.MaxLabel,
							g.MinStake =  s.MinStake,
							g.MaxStake =  s.MaxStake
		WHEN NOT MATCHED THEN 
							INSERT (StakeLevelID,GameTypeID,MinLabel,MaxLabel,MinStake,MaxStake)
							VALUES (s.StakeLevelID,s.GameTypeID,s.MinLabel,s.MaxLabel,s.MinStake,s.MaxStake)					
							
							OUTPUT deleted.StakeLevelID, deleted.GameTypeID, deleted.MaxLabel, deleted.MaxStake, deleted.MaxGameStake, GETDATE(), 1, 0
								INTO @History_StakeLevelTbl(StakeLevelID, GameTypeID, MaxLabel, MaxStake, MaxGameStake, UpdateTime, IsGroup, IsCredit)
							;
		UPDATE dst	
		SET dst.MinLabel = a.MinLabel, dst.MaxLabel = a.MaxLabel , dst.MinStake = a.NewMinBet,dst.MaxStake = a.NewMaxBet
		OUTPUT deleted.StakeLevelID, deleted.GameTypeID, deleted.MaxLabel, deleted.MaxStake, deleted.SiteID, GETDATE(), 0, 0
			INTO @History_StakeLevelTbl(StakeLevelID, GameTypeID, MaxLabel, MaxStake, SiteID, UpdateTime, IsGroup, IsCredit)
		FROM Dep_StakeLevel dst	 WITH (ROWLOCK, UPDLOCK)
			INNER JOIN  #NewInputDateTbl a	ON 	dst.GameTypeID = a.BetType AND a.ExchangeId = dst.ExchangeId 
								 AND a.CurMinBet = MinStake AND a.CurMaxBet = MaxStake AND a.SiteID = dst.SiteID
		WHERE a.IsCredit =  0 AND SettingType IN (7) 		
		
		--Delete update MinStake only
		DELETE his
		FROM @History_StakeLevelTbl his
			INNER JOIN Dep_StakeLevel sl ON sl.StakeLevelID=his.StakeLevelID
										AND sl.MaxStake=his.MaxStake
										AND sl.MaxLabel=his.MaxLabel
		WHERE IsGroup=0 AND IsCredit=0

		DELETE his
		FROM @History_StakeLevelTbl his
			INNER JOIN Dep_StakeLevelGroupDetail slg ON slg.StakeLevelID=his.StakeLevelID
												AND slg.GameTypeID=his.GameTypeID
												AND slg.MaxStake=his.MaxStake
												AND slg.MaxLabel=his.MaxLabel
		WHERE IsGroup=1 AND IsCredit=0

		--DEPOSIT: Insert history of update global StakeLevel
		IF EXISTS (SELECT 1 FROM @History_StakeLevelTbl WHERE IsGroup=0 AND IsCredit=0)
		BEGIN
			SET @SettingList = (SELECT	StakeLevelID	AS '@StakeLevelID',
										GameTypeID		AS '@GameTypeID',
										MaxLabel		AS '@MaxLabel',
										MaxStake		AS '@MaxStake',
										'NULL'			AS '@MaxGameStake',
										SiteID			AS '@SiteID',
										UpdateTime		AS '@UpdateTime'	
								FROM @History_StakeLevelTbl
								WHERE IsGroup=0 AND IsCredit=0
								FOR XML PATH('r') , ROOT('root')
								)

			EXEC Task_DetectBet_Dep_StakeLevelHistory_Insert @SettingList=@SettingList, @IsGroup=0, @ErrMsg=@ErrMsg OUTPUT

			IF @ErrMsg<>''
				RETURN
		END

		IF EXISTS (SELECT 1 FROM @History_StakeLevelTbl WHERE IsGroup=1 AND IsCredit=0)
		BEGIN
			SET @SettingList = (SELECT	StakeLevelID	AS '@StakeLevelID',
										GameTypeID		AS '@GameTypeID',
										MaxLabel		AS '@MaxLabel',
										MaxStake		AS '@MaxStake',
										MaxGameStake	AS '@MaxGameStake',
										'NULL'			AS '@SiteID',
										UpdateTime		AS '@UpdateTime'	
								FROM @History_StakeLevelTbl
								WHERE IsGroup=1 AND IsCredit=0
								FOR XML PATH('r') , ROOT('root')
								)

			EXEC Task_DetectBet_Dep_StakeLevelHistory_Insert @SettingList=@SettingList, @IsGroup=1, @ErrMsg=@ErrMsg OUTPUT

			IF @ErrMsg<>''
				RETURN
		END
	END TRY
	BEGIN CATCH
		SELECT  @ErrCode = ERROR_NUMBER(),@ErrMsg = ERROR_MESSAGE();		
		RETURN
	END CATCH
	SELECT @EndRun	= GETDATE(), @Duration = DATEDIFF(MILLISECOND, @StartRun, @EndRun)
	DECLARE @NewLog VARCHAR(MAX)
	SET @NewLog = '<Acc_InitializingStake_StakelevelIns  IP="'+ COALESCE(CAST(@IP AS VARCHAR(15)),SPACE(1))+'" >'
	SELECT @logSpData = REPLACE(REPLACE(@InputData, '<ROOT>', @NewLog),'/ROOT','/Acc_InitializingStake_StakelevelIns')
	EXEC  Acc_WriteLog_UserLog_RunSP_Wrapper
				@UserID = @UserID,
				@ActionID = 6063,
				@TrackingValue = @LogSPData,
				@duration = @Duration
		
			
	DROP TABLE #NewInputDateTbl
END								