/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_InitializingStake_StakelevelCheck] 
	-- Add the parameters for the stored procedure here
	 @InputData				VARCHAR(MAX) = ''
	,@NotiCode				INT = 0				OUTPUT
	,@NotiMsg				NVARCHAR(4000) = '' OUTPUT
	,@ErrCode				INT = 0				OUTPUT
	,@ErrMsg				NVARCHAR(4000) = '' OUTPUT
AS
/*
	Task : NAP -  Flexible Initializing Stake Level 
	DB: DBCUST/CustDB
	Original: 
	Revisions:
		- 20220210@Winfred: NAP -  Flexible Initializing check Stake Level [Redmine: #167128]
	
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
	CREATE TABLE #RowDuplicate(RowIDF INT, RowIDT INT)
	
	IF @InputData IS NULL OR @InputData = ''
		RETURN
	
	SELECT	@ErrCode	= 0 , @ErrMsg = '' , @NotiCode = 0 ,  @NotiMsg = ''
	
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

	SELECT @ErrCode = CASE WHEN ISNULL( SportType,'') = ''	THEN 101
						   WHEN ISNULL( BetType,'') = ''	THEN 102
						   WHEN ISNULL( NewMinBet,0) = 0	THEN 103
						   WHEN ISNULL( NewMaxBet,0) = 0	THEN 104
						   WHEN NewMinBet > NewMaxBet		THEN 105
						   WHEN NewMinBet = 0				THEN 106
						   WHEN NewMaxBet = 0				THEN 107
						   ELSE 101 END ,
		  @ErrMsg =	  CASE WHEN ISNULL( SportType,'') = ''	THEN 'The Sport Type is required field.' 
						   WHEN ISNULL( BetType,'') = ''	THEN 'The Bet Type is required field.' 
						   WHEN ISNULL( NewMinBet,0) = 0	THEN 'The New Min Bet is required field.' 
						   WHEN ISNULL( NewMaxBet,0) = 0	THEN 'The New Max Bet is required field.' 
						   WHEN NewMinBet > NewMaxBet		THEN 'The New Max Bet must be greater than or equal to the New Min Bet.' 
						   WHEN NewMinBet = 0				THEN 'The Min Bet must be different from 0.'
						   WHEN NewMaxBet = 0				THEN 'The Max Bet must be different from 0.' 
						   ELSE '' END 						   
	FROM @NewStakeLevelTbl tmp
	WHERE ISNULL( SportType,'') = '' OR ISNULL( BetType,'') = '' OR ISNULL( NewMinBet,0) = 0 OR ISNULL( NewMaxBet,0) = 0
		OR NewMinBet > NewMaxBet OR NewMinBet = 0 OR NewMaxBet = 0
	
	IF	@ErrCode <> 0 RETURN
	
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
	
	SELECT TOP(1) @ErrCode = 108 , @ErrBetType = CAST(tmp.BetType AS VARCHAR(10)) , @ValueError = CAST(tmp.SportType AS VARCHAR(200))
	FROM #NewInputDateTbl tmp
	WHERE ISNULL(tmp.SettingType,0) = 0 OR NOT EXISTS( SELECT TOP 1 1 FROM #Sports WHERE SportType =  tmp.SportType)
	IF 	@ErrCode = 108			
	BEGIN
		SELECT @ErrMsg = 'The Sport Type ' + @ValueError + ' does not exist.' 
		RETURN
	END	
	
	SELECT TOP(1) @ErrCode = 109 , @ErrBetType = CAST(tmp.BetType AS VARCHAR(10)) , @ValueError = CAST(tmp.BetType AS VARCHAR(200))
	FROM #NewInputDateTbl tmp
	WHERE NOT EXISTS( SELECT TOP 1 1 FROM #Bettype WHERE typeid =  tmp.BetType)
	IF 	@ErrCode = 109			
	BEGIN
		SELECT @ErrMsg = 'The Bet Type ' + @ValueError + ' does not exist.' 
		RETURN
	END	
	
	SELECT TOP(1) @ErrCode = 110 , @ErrBetType = CAST(tmp.BetType AS VARCHAR(10)) , @ValueError = CAST(tmp.currency AS VARCHAR(200))
	FROM #NewInputDateTbl tmp
	WHERE ISNULL(tmp.Currency,'') <> '' AND tmp.IsCredit = 1 AND  NOT EXISTS( SELECT TOP 1 1 FROM Exchange WITH(NOLOCK) WHERE currency =  tmp.Currency  AND IsActive = 1 AND OfferSite IN (0,1))
	IF 	@ErrCode = 110			
	BEGIN
		SELECT @ErrMsg = 'The Credit Currency ' + @ValueError + ' does not exist.' 
		RETURN
	END	
	
	SELECT TOP(1) @ErrCode = 111 , @ErrBetType = CAST(tmp.BetType AS VARCHAR(10)) , @ValueError = CAST(tmp.currency AS VARCHAR(200))
	FROM #NewInputDateTbl tmp
	WHERE ISNULL(tmp.Currency,'') <> ''  AND tmp.IsCredit = 0 AND NOT EXISTS( SELECT TOP 1 1 FROM Exchange WITH(NOLOCK) WHERE currency =  tmp.Currency AND IsActive = 1 AND OfferSite IN (0,2))
	IF 	@ErrCode = 111			
	BEGIN
		SELECT @ErrMsg = 'The Deposit Currency ' + @ValueError + ' does not exist.' 
		RETURN
	END
	
	SELECT TOP(1) @ErrCode = CASE WHEN IsMin = 1 THEN 112 ELSE 113 END  , @ErrBetType = CAST(BetType AS VARCHAR(10)) , @ValueError = CAST((CASE WHEN IsMin = 1 THEN CurMinBet ELSE CurMaxBet END) AS VARCHAR(200))
	FROM (
		SELECT SettingType, SportType, BetType , CurMinBet, CurMaxBet, GameGroupID, IsCredit, 1 AS IsMin
		FROM #NewInputDateTbl tmp
		WHERE IsCredit = 1 AND tmp.SettingType IN (7,17)  AND CurMinBet <> 0
			AND NOT EXISTS( SELECT TOP 1 1 FROM StakeLevel WITH(NOLOCK) WHERE BetType = GameTypeID AND ExchangeId = tmp.ExchangeId AND MinStake = CurMinBet  )
		UNION ALL 
		SELECT SettingType, SportType, BetType , CurMinBet, CurMaxBet, GameGroupID, IsCredit, 0 AS IsMin
		FROM #NewInputDateTbl tmp
		WHERE IsCredit = 0 AND tmp.SettingType IN (7)  AND CurMaxBet <> 0
			AND NOT EXISTS( SELECT TOP 1 1 FROM Dep_StakeLevel WITH(NOLOCK) WHERE BetType = GameTypeID AND ExchangeId = tmp.ExchangeId AND MaxStake = CurMaxBet AND CurMaxBet <> 0)
	) KQ
	IF 	@ErrCode = 112			
	BEGIN
		SELECT @ErrMsg = 'The Current Min Bet ' + @ValueError + ' of bet type ' + @ErrBetType + ' does not exist.' 
		RETURN
	END
	ELSE IF @ErrCode = 113
	BEGIN
		SELECT @ErrMsg = 'The Current Max Bet ' + @ValueError + ' of bet type ' + @ErrBetType + ' does not exist.' 
		RETURN
	END
	
	SELECT TOP(1) @ErrCode = 114 , @ErrBetType = CAST(tmp.BetType AS VARCHAR(10)) , @ValueError = CAST(tmp.GameGroupID AS VARCHAR(200))
	FROM #NewInputDateTbl tmp
	WHERE tmp.SettingType IN (8)  AND NOT EXISTS( SELECT TOP 1 1 FROM GameGroup WITH(NOLOCK) 
									WHERE RefSportType =  tmp.SportType AND RefBetType = OrgBetType AND GameGroupID = tmp.GameGroupID
									AND ((tmp.IsCredit = 1 AND IsDeposit = 0) OR (tmp.IsCredit = 0 AND IsDeposit = 1)))
	IF 	@ErrCode = 114
	BEGIN
		SELECT @ErrMsg = 'The Game Group ID ' + @ValueError + ' of bet type ' + @ErrBetType + ' does not exist.'  
		RETURN
	END
	
	SELECT TOP(1) @ErrCode = 115 , @ErrBetType = CAST(tmp.BetType AS VARCHAR(10)) , @ValueError = ''
	FROM #NewInputDateTbl tmp
	WHERE tmp.CurMinBet = NewMinBet AND CurMaxBet = NewMaxBet
	IF 	@ErrCode = 115			
	BEGIN
		SELECT @ErrMsg = 'The New Min Bet and New Max Bet are the same as The Current Min Bet and The Current Max Bet. Please input another value for the New Min Bet and the New Max Bet again.'  
		RETURN
	END
	
	SELECT TOP(1) @ErrCode = 116 , @ErrBetType = CAST(tmp.BetType AS VARCHAR(10)) ,  @ValueError = CAST(tmp.GameGroupID AS VARCHAR(200))
	FROM #NewInputDateTbl tmp
	WHERE tmp.SettingType IN (8) AND ISNULL(tmp.GameGroupID,0) = 0
	IF 	@ErrCode = 116			
	BEGIN
		SELECT @ErrMsg = 'You input missing data with the product''''s format. Please input data on Game Group ID.'  
		RETURN
	END
	
	SELECT TOP(1) @ErrCode = 117 , @ErrBetType = CAST(tmp.BetType AS VARCHAR(10)) ,  @ValueError = CAST(tmp.CurMinBet AS VARCHAR(200))
	FROM #NewInputDateTbl tmp
	WHERE tmp.SettingType IN (7,17) AND ISNULL(tmp.CurMinBet,0) = 0 AND ISNULL(tmp.CurMaxBet,0) <> 0
	IF 	@ErrCode = 117			
	BEGIN
		SELECT @ErrMsg = 'You input missing data with the product''''s format. Please input data on Current Min Bet.'  
		RETURN
	END
	
	SELECT TOP(1) @ErrCode = 118 , @ErrBetType = CAST(tmp.BetType AS VARCHAR(10)) ,  @ValueError = CAST(tmp.CurMaxBet AS VARCHAR(200))
	FROM #NewInputDateTbl tmp
	WHERE tmp.SettingType IN (7,17) AND ISNULL(tmp.CurMaxBet,0) = 0 AND ISNULL(tmp.CurMinBet,0) <> 0
	IF 	@ErrCode = 118			
	BEGIN
		SELECT @ErrMsg = 'You input missing data with the product''''s format. Please input data on Current Max Bet.'  
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
		SELECT @NotiMsg = 'there are new currencies : ' +  STUFF((SELECT DISTINCT ',' + cast(Currency AS nvarchar(50))
									FROM #Currency
									FOR XML PATH('')), 1, 1, '')
		
	END
	
	INSERT INTO #RowDuplicate(RowIDF,RowIDT)
	SELECT DISTINCT tmp.RowID , ndt.RowID
	FROM #NewInputDateTbl tmp
	INNER JOIN #NewInputDateTbl ndt ON tmp.SportType = ndt.SportType AND tmp.OrgBetType = ndt.OrgBetType 
				AND tmp.ExchangeId = ndt.ExchangeId AND tmp.CurMinBet = ndt.CurMinBet AND tmp.CurMaxBet = ndt.CurMaxBet AND tmp.GameGroupID  = ndt.GameGroupID
				AND tmp.CurMinBet <> 0 AND  ndt.CurMinBet <> 0 AND tmp.CurMaxBet <> 0 AND ndt.CurMaxBet <> 0
	WHERE tmp.RowID <  ndt.RowID
	IF 	EXISTS(	SELECT TOP 1 1 FROM #RowDuplicate )			
	BEGIN
		SET @ErrCode = 119
		SELECT @ErrMsg = STUFF((SELECT ', row ' + cast(RowIDF AS nvarchar(50)) + ' - row ' + cast(RowIDT AS nvarchar(50)) 
									FROM #RowDuplicate tmp
									ORDER BY RowIDF
									FOR XML PATH('')), 1, 1, '') + ' : these rows have duplicate data' 
		RETURN
	END	
	
	DROP TABLE #NewInputDateTbl
	DROP TABLE #Currency
	DROP TABLE #RowDuplicate
END								