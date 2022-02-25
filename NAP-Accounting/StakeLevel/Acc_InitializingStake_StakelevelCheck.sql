/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_InitializingStake_StakelevelCheck] 
	-- Add the parameters for the stored procedure here
	 @InputData				VARCHAR(MAX) = ''
	,@Language				VARCHAR(2) = 'E'
	,@NotiCode				INT = 0				OUTPUT
	,@ErrCode				INT = 0				OUTPUT
	,@ErrMsg				NVARCHAR(4000) = '' OUTPUT
AS
/*
		Task : NAP -  Flexible Initializing Stake Level
		DB: DBCUST/CustDB
		Original: 
		Revisions:
			- 20220210@Winfred: NAP -  Flexible Initializing Stake Level [Redmine: #167128]
		
		Param's Explanation:
			• @pInputData : 
			<ROOT>
				<BetLimit 
						SportType="1" 
						BetType="1"
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
	
	DECLARE @xml XML, @ErrBetType VARCHAR(10), @ValueError VARCHAR(200) = ''
	DECLARE @NewStakeLevelTbl TABLE (
			RowID				INT IDENTITY (1,1)
			, SportType			SMALLINT
			, BetType			SMALLINT
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
			, Currency		VARCHAR(50)
			, ExchangeId	INT
			, NewMinBet		DECIMAL(19,8)
			, NewMaxBet		DECIMAL(19,8)
			, CurMinBet		DECIMAL(19,8)
			, CurMaxBet		DECIMAL(19,8)
			, GameGroupID	INT
			, IsCredit		BIT Default((0))
			, SettingType	SMALLINT
		)
	
	CREATE TABLE #Bettype (typeid INT PRIMARY KEY, typenamee NVARCHAR(128))
	CREATE TABLE #Sports(SportType TINYINT PRIMARY KEY, SportName NVARCHAR(50))
	CREATE TABLE #Currency(Currency	VARCHAR(50))
	
	IF @InputData IS NULL OR @InputData = ''
		RETURN
	
	SELECT	@ErrCode	= 0 , @ErrMsg = '' , @NotiCode = 0
	
	--Parse XML data
	DECLARE @iDoc INT

	EXEC sp_xml_preparedocument @iDoc OUTPUT
		, @InputData

	INSERT INTO @NewStakeLevelTbl(SportType, BetType, CreditCurrency, DepositCurrency, NewMinBet, NewMaxBet, CurMinBet, CurMaxBet, GameGroupID)
	SELECT SportType, BetType, CreditCurrency, DepositCurrency, NewMinBet, NewMaxBet, CurMinBet, CurMaxBet, GameGroupID
	FROM OPENXML(@iDoc, '/ROOT/BetLimit', 1) WITH (
				SportType			SMALLINT
				, BetType			SMALLINT
				, CreditCurrency	VARCHAR(500)
				, DepositCurrency	VARCHAR(500)
				, NewMinBet			DECIMAL(19,8)
				, NewMaxBet			DECIMAL(19,8)
				, CurMinBet			DECIMAL(19,8)
				, CurMaxBet			DECIMAL(19,8)
				, GameGroupID		INT
			)
	EXEC sp_xml_removedocument @iDoc

	INSERT INTO #Sports  (SportType,SportName)	
	SELECT SportType,SportName 
	FROM DBACC.bodb02.dbo.Sports WITH(NOLOCK)
	
	INSERT INTO #Bettype  (typeid,typenamee)	
	SELECT typeid,typenamee 
	FROM DBACC.bodb02.dbo.Bettype WITH(NOLOCK)
	
	IF  EXISTS(	SELECT TOP 1 1 
				FROM @NewStakeLevelTbl tmp
				WHERE ISNULL( SportType,'') = '')
		BEGIN
			SET @ErrCode = 101
			SELECT @ErrMsg = 'The Sport Type is required field.' 
			RETURN
		END
	IF  EXISTS(	SELECT TOP 1 1 
				FROM @NewStakeLevelTbl tmp
				WHERE ISNULL( BetType,'') = '')
		BEGIN
			SET @ErrCode = 102
			SELECT @ErrMsg = 'The Bet Type is required field.' 
			RETURN
		END
	IF  EXISTS(	SELECT TOP 1 1 
				FROM @NewStakeLevelTbl tmp
				WHERE ISNULL( NewMinBet,0) = 0)
		BEGIN
			SET @ErrCode = 103
			SELECT @ErrMsg = 'The New Min Bet is required field.' 
			RETURN
		END
	IF  EXISTS(	SELECT TOP 1 1 
				FROM @NewStakeLevelTbl tmp
				WHERE ISNULL( NewMinBet,0) = 0)
		BEGIN
			SET @ErrCode = 104
			SELECT @ErrMsg = 'The New Max Bet is required field.' 
			RETURN
		END
	IF  EXISTS(	SELECT TOP 1 1 
				FROM @NewStakeLevelTbl tmp
				WHERE NewMinBet > NewMaxBet)
		BEGIN
			SET @ErrCode = 105
			SELECT @ErrMsg = 'The New Max Bet must be greater than or equal to the New Min Bet.' 
			RETURN
		END	
	IF  EXISTS(	SELECT TOP 1 1 
				FROM @NewStakeLevelTbl tmp
				WHERE NewMinBet = 0)
		BEGIN
			SET @ErrCode = 106
			SELECT @ErrMsg = 'The Min Bet must be different from 0.' 
			RETURN
		END		
	IF  EXISTS(	SELECT TOP 1 1 
				FROM @NewStakeLevelTbl tmp
				WHERE NewMaxBet = 0)
		BEGIN
			SET @ErrCode = 106
			SELECT @ErrMsg = 'The Max Bet must be different from 0.' 
			RETURN
		END	
	
	INSERT INTO #NewInputDateTbl(RowID, SportType, BetType, Currency, NewMinBet, NewMaxBet, CurMinBet	
								, CurMaxBet, GameGroupID, IsCredit)
	SELECT RowID, SportType, BetType, t.Currency, NewMinBet, NewMaxBet, CurMinBet	
								, CurMaxBet, GameGroupID, 1 AS IsCredit 
	FROM @NewStakeLevelTbl nsl
		CROSS APPLY (
				SELECT DISTINCT RTRIM(LTRIM(val)) AS Currency FROM dbo.strSplit(nsl.CreditCurrency, ',')
			) t
	WHERE nsl.CreditCurrency <> ''
	UNION ALL
	SELECT RowID, SportType, BetType, t.Currency, NewMinBet, NewMaxBet, CurMinBet	
								, CurMaxBet, GameGroupID, 0 AS IsCredit 
	FROM @NewStakeLevelTbl nsl
		CROSS APPLY (
				SELECT DISTINCT RTRIM(LTRIM(val)) AS Currency FROM dbo.strSplit(nsl.DepositCurrency, ',')
			) t		
	WHERE nsl.DepositCurrency <> ''
	
	UPDATE a 
	SET a.ExchangeId = CASE WHEN a.IsCredit = 1 AND e.OfferSite IN (0,1) THEN e.ExchangeId
							WHEN a.IsCredit = 0 AND e.OfferSite IN (0,2) THEN e.ExchangeId
						ELSE NULL END	
	FROM  #NewInputDateTbl a
		INNER JOIN Exchange e WITH(NOLOCK) ON a.Currency = e.currency
	
	UPDATE a 
	SET a.SettingType =  psd.SettingType , a.OrgBetType = psd.BetType	
	FROM  #NewInputDateTbl a
		INNER JOIN ProductSettingDetail psd WITH(NOLOCK) ON a.SportType = psd.SportType
	WHERE a.IsCredit = 1 AND psd.SettingType IN (7, 17, 8)
	
	UPDATE a 
	SET a.SettingType =  ps.SettingType	, a.OrgBetType = psd.BetType
	FROM  #NewInputDateTbl a
		INNER JOIN Dep_ProductSettingDetail psd WITH(NOLOCK) ON a.SportType = psd.SportType
		INNER JOIN Dep_ProductSetting ps WITH(NOLOCK) ON ps.ProductSettingID = psd.ProductSettingID
	WHERE a.IsCredit = 0  AND ps.SettingType IN (7, 8)
		
	SELECT * FROM #NewInputDateTbl order by RowID,SportType,BetType, Currency,CurMinBet,NewMinBet	
		
	SELECT TOP(1) @ErrCode = 107 , @ErrBetType = CAST(tmp.BetType AS VARCHAR(10)) , @ValueError = CAST(tmp.SportType AS VARCHAR(200))
	FROM #NewInputDateTbl tmp
	WHERE ISNULL(tmp.SettingType,0) = 0 OR NOT EXISTS( SELECT TOP 1 1 FROM #Sports WHERE SportType =  tmp.SportType)
	IF 	@ErrCode = 107			
	BEGIN
		SELECT @ErrMsg = 'The Sport Type ' + @ValueError + ' does not exist.' 
		RETURN
	END	
	
	SELECT TOP(1) @ErrCode = 108 , @ErrBetType = CAST(tmp.BetType AS VARCHAR(10)) , @ValueError = CAST(tmp.BetType AS VARCHAR(200))
	FROM #NewInputDateTbl tmp
	WHERE NOT EXISTS( SELECT TOP 1 1 FROM #Bettype WHERE typeid =  tmp.BetType)
	IF 	@ErrCode = 108			
	BEGIN
		SELECT @ErrMsg = 'The Bet Type ' + @ValueError + ' does not exist.' 
		RETURN
	END	
	
	SELECT TOP(1) @ErrCode = 109 , @ErrBetType = CAST(tmp.BetType AS VARCHAR(10)) , @ValueError = CAST(tmp.currency AS VARCHAR(200))
	FROM #NewInputDateTbl tmp
	WHERE ISNULL(tmp.Currency,'') <> '' AND NOT EXISTS( SELECT TOP 1 1 FROM Exchange WITH(NOLOCK) WHERE currency =  tmp.Currency AND IsActive = 1 AND OfferSite IN (0,1))
	IF 	@ErrCode = 109			
	BEGIN
		SELECT @ErrMsg = 'The Credit Currency ' + @ValueError + ' does not exist.' 
		RETURN
	END	
	
	SELECT TOP(1) @ErrCode = 110 , @ErrBetType = CAST(tmp.BetType AS VARCHAR(10)) , @ValueError = CAST(tmp.currency AS VARCHAR(200))
	FROM #NewInputDateTbl tmp
	WHERE ISNULL(tmp.Currency,'') <> '' AND NOT EXISTS( SELECT TOP 1 1 FROM Exchange WITH(NOLOCK) WHERE currency =  tmp.Currency AND IsActive = 1 AND OfferSite IN (0,2))
	IF 	@ErrCode = 110			
	BEGIN
		SELECT @ErrMsg = 'The Deposit Currency ' + @ValueError + ' does not exist.' 
		RETURN
	END
	
	SELECT TOP(1) @ErrCode = CASE WHEN IsMin = 1 THEN 111 ELSE 112 END  , @ErrBetType = CAST(BetType AS VARCHAR(10)) , @ValueError = CAST((CASE WHEN IsMin = 1 THEN CurMinBet ELSE CurMaxBet END) AS VARCHAR(200))
	FROM (
		SELECT SettingType, SportType, BetType , CurMinBet, CurMaxBet, GameGroupID, IsCredit, 1 AS IsMin
		FROM #NewInputDateTbl tmp
		WHERE IsCredit = 1 AND tmp.SettingType IN (7,17) 
			AND NOT EXISTS( SELECT TOP 1 1 FROM StakeLevel WITH(NOLOCK) WHERE BetType = GameTypeID AND ExchangeId = tmp.ExchangeId AND MinStake = CurMinBet )
		UNION ALL 
		SELECT SettingType, SportType, BetType , CurMinBet, CurMaxBet, GameGroupID, IsCredit, 0 AS IsMin
		FROM #NewInputDateTbl tmp
		WHERE IsCredit = 0 AND tmp.SettingType IN (7) 
			AND NOT EXISTS( SELECT TOP 1 1 FROM Dep_StakeLevel WITH(NOLOCK) WHERE BetType = GameTypeID AND ExchangeId = tmp.ExchangeId AND MaxStake = CurMaxBet)
	) KQ
	IF 	@ErrCode = 111			
	BEGIN
		SELECT @ErrMsg = 'The Current Min Bet ' + @ValueError + ' of bet type ' + @ErrBetType + ' does not exist.' 
		RETURN
	END
	ELSE IF @ErrCode = 112
	BEGIN
		SELECT @ErrMsg = 'The Current Max Bet ' + @ValueError + ' of bet type ' + @ErrBetType + ' does not exist.' 
		RETURN
	END
	
	SELECT TOP(1) @ErrCode = 113 , @ErrBetType = CAST(tmp.BetType AS VARCHAR(10)) , @ValueError = CAST(tmp.GameGroupID AS VARCHAR(200))
	FROM #NewInputDateTbl tmp
	WHERE tmp.SettingType IN (8)  AND NOT EXISTS( SELECT TOP 1 1 FROM GameGroup WITH(NOLOCK) 
									WHERE RefSportType =  tmp.SportType AND RefBetType = BetType AND GameGroupID = tmp.GameGroupID
									AND ((tmp.IsCredit = 1 AND IsDeposit = 0) OR (tmp.IsCredit = 0 AND IsDeposit = 1)))
	IF 	@ErrCode = 113			
	BEGIN
		SELECT @ErrMsg = 'The Game Group ID ' + @ValueError + ' of bet type ' + @ErrBetType + ' does not exist.'  
		RETURN
	END
	
	SELECT TOP(1) @ErrCode = 114 , @ErrBetType = CAST(tmp.BetType AS VARCHAR(10)) , @ValueError = ''
	FROM #NewInputDateTbl tmp
	WHERE tmp.CurMinBet = NewMinBet AND CurMaxBet = NewMaxBet
	IF 	@ErrCode = 114			
	BEGIN
		SELECT @ErrMsg = 'The New Min Bet and New Max Bet are the same as The Current Min Bet and The Current Max Bet. Please input another value for the New Min Bet and the New Max Bet again.'  
		RETURN
	END
	
	SELECT TOP(1) @ErrCode = 115 , @ErrBetType = CAST(tmp.BetType AS VARCHAR(10)) ,  @ValueError = CAST(tmp.GameGroupID AS VARCHAR(200))
	FROM #NewInputDateTbl tmp
	WHERE tmp.SettingType IN (8) AND ISNULL(tmp.GameGroupID,0) = 0
	IF 	@ErrCode = 115			
	BEGIN
		SELECT @ErrMsg = 'You input missing data with the product''''s format. Please input data on Game Group ID.'  
		RETURN
	END
	
	SELECT TOP(1) @ErrCode = 116 , @ErrBetType = CAST(tmp.BetType AS VARCHAR(10)) ,  @ValueError = CAST(tmp.CurMinBet AS VARCHAR(200))
	FROM #NewInputDateTbl tmp
	WHERE tmp.SettingType IN (7,17) AND ISNULL(tmp.CurMinBet,0) = 0
	IF 	@ErrCode = 116			
	BEGIN
		SELECT @ErrMsg = 'You input missing data with the product''''s format. Please input data on Current Min Bet.'  
		RETURN
	END
	
	SELECT TOP(1) @ErrCode = 117 , @ErrBetType = CAST(tmp.BetType AS VARCHAR(10)) ,  @ValueError = CAST(tmp.CurMaxBet AS VARCHAR(200))
	FROM #NewInputDateTbl tmp
	WHERE tmp.SettingType IN (7,17) AND ISNULL(tmp.CurMaxBet,0) = 0
	IF 	@ErrCode = 117			
	BEGIN
		SELECT @ErrMsg = 'You input missing data with the product''''s format. Please input data on Current Max Bet.'  
		RETURN
	END
	
--===========================================================================================================	
	--SELECT @AffectedList =  STUFF((SELECT DISTINCT ',' + cast(custid AS VARCHAR(10))
	--								FROM @tmpCust
	--								FOR XML PATH('')), 1, 1, '')



	SELECT TOP(1) @NotiCode = 100 , @ErrBetType = CAST(tmp.BetType AS VARCHAR(10)) , @ValueError = CAST(tmp.currency AS VARCHAR(200))
	FROM #NewInputDateTbl tmp
	WHERE ISNULL(tmp.Currency,'') <> '' AND NOT EXISTS( SELECT TOP 1 1 FROM Exchange WITH(NOLOCK) WHERE currency =  tmp.Currency AND IsActive = 1 AND OfferSite IN (0,1))
	IF 	@NotiCode = 100			
	BEGIN
		SELECT @ErrMsg = 'The Credit Currency ' + @ValueError + ' does not exist.' 
		RETURN
	END	
	
	SELECT TOP(1) @ErrCode = 110 , @ErrBetType = CAST(tmp.BetType AS VARCHAR(10)) , @ValueError = CAST(tmp.currency AS VARCHAR(200))
	FROM #NewInputDateTbl tmp
	WHERE ISNULL(tmp.Currency,'') <> '' AND NOT EXISTS( SELECT TOP 1 1 FROM Exchange WITH(NOLOCK) WHERE currency =  tmp.Currency AND IsActive = 1 AND OfferSite IN (0,2))
	IF 	@ErrCode = 110			
	BEGIN
		SELECT @ErrMsg = 'The Deposit Currency ' + @ValueError + ' does not exist.' 
		RETURN
	END	
	
	INSERT INTO #Currency (Currency)
	SELECT tmp.Currency
	FROM #NewInputDateTbl tmp
	WHERE IsCredit = 1 AND NOT EXISTS( SELECT TOP 1 1 FROM StakeLevel WITH(NOLOCK) WHERE GameTypeID = tmp.OrgBetType AND ExchangeId = tmp.ExchangeId)
	UNION  
	SELECT tmp.Currency
	FROM #NewInputDateTbl tmp
	WHERE IsCredit = 0 AND NOT EXISTS( SELECT TOP 1 1 FROM Dep_StakeLevel WITH(NOLOCK) WHERE tmp.OrgBetType = GameTypeID AND ExchangeId = tmp.ExchangeId)
	
	IF 	EXISTS(	SELECT TOP 1 1 FROM #Currency )			
	BEGIN
		SET @NotiCode = 100
		SELECT @ErrMsg = '"there are new currencies : ' +  STUFF((SELECT DISTINCT ',' + cast(Currency AS nvarchar(50))
									FROM #Currency
									FOR XML PATH('')), 1, 1, '')
		
	END
	
	SELECT TOP(1) @ErrCode = 110 , @ErrBetType = CAST(tmp.BetType AS VARCHAR(10)) , @ValueError = CAST(tmp.currency AS VARCHAR(200))
	FROM #NewInputDateTbl tmp
	INNER JOIN #NewInputDateTbl ndt ON tmp.SportType = ndt.SportType AND tmp.OrgBetType = ndt.OrgBetType 
				AND tmp.ExchangeId = ndt.ExchangeId AND tmp.CurMinBet = ndt.CurMinBet AND tmp.CurMaxBet = ndt.CurMaxBet
	WHERE ISNULL(tmp.Currency,'') <> '' AND NOT EXISTS( SELECT TOP 1 1 FROM Exchange WITH(NOLOCK) WHERE currency =  tmp.Currency AND IsActive = 1 AND OfferSite IN (0,2))
	IF 	@ErrCode = 110			
	BEGIN
		SELECT @ErrMsg = 'row <row id>, row <row id>: these rows have duplicate data' 
		RETURN
	END	
	
	DROP TABLE #NewInputDateTbl
	DROP TABLE #Currency
END								