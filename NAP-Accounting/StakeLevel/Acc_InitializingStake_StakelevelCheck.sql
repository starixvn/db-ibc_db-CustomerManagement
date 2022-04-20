/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_InitializingStake_StakelevelCheck] 
	-- Add the parameters for the stored procedure here
	 @InputData				VARCHAR(MAX) = ''
	,@ProductID				TINYINT = 0			OUTPUT
	,@NotiCode				INT = 0				OUTPUT
	,@NotiMsg				NVARCHAR(4000) = '' OUTPUT
	,@ErrCode				INT = 0				OUTPUT
	,@ErrMsg				NVARCHAR(4000) = '' OUTPUT
AS
/*
	Task : NAP -  Flexible Initializing Stake Level 
	DB: DBACC/bodb02
	Original: 
	Revisions:
		- 20220210@Winfred: NAP -  Flexible Initializing check Stake Level [Redmine: #167128]
		- 20220420@Winfred: Fix setting type 7 get bettype original [Redmine: #171750]
	
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
	
	DECLARE @xml XML, @ErrBetType VARCHAR(10), @ValueError VARCHAR(500) = '' , @RowError VARCHAR(200) = '',@SportType   SMALLINT  ,@BetType   SMALLINT 
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
			, NewMinBet		DECIMAL(19,8)
			, NewMaxBet		DECIMAL(19,8)
			, CurMinBet		DECIMAL(19,8)
			, CurMaxBet		DECIMAL(19,8)
			, GameGroupID	INT
			, IsCredit		BIT Default((0))
			, SettingType	SMALLINT
			, ProductID		TINYINT
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

	INSERT INTO #Sports  (SportType,SportName)	
	SELECT SportType,SportName 
	FROM dbo.Sports WITH(NOLOCK)
	
	INSERT INTO #Bettype  (typeid,typenamee)	
	SELECT typeid,typenamee 
	FROM dbo.Bettype WITH(NOLOCK)

	SELECT @ErrCode = CASE WHEN ISNULL( SportType,'') = ''	THEN 101
						   WHEN ISNULL( BetType,'') = ''	THEN 102
						   WHEN ISNULL( NewMinBet,0) = 0	THEN 103
						   WHEN ISNULL( NewMaxBet,0) = 0	THEN 104
						   WHEN NewMinBet > NewMaxBet		THEN 105
						   WHEN NewMinBet = 0				THEN 106
						   WHEN NewMaxBet = 0				THEN 107
						   WHEN ISNULL( CreditCurrency,'') = '' AND 
								ISNULL( DepositCurrency,'') = ''	THEN 122
						   ELSE 101 END ,
		  @ErrMsg =	  CASE WHEN ISNULL( SportType,'') = ''	THEN 'Row ' + CAST(RowID AS NVARCHAR(50))+ ': The Sport Type is required field.' 
						   WHEN ISNULL( BetType,'') = ''	THEN 'Row ' + CAST(RowID AS NVARCHAR(50))+ ': The Bet Type is required field.' 
						   WHEN ISNULL( NewMinBet,0) = 0	THEN 'Row ' + CAST(RowID AS NVARCHAR(50))+ ': The New Min Bet is required field.' 
						   WHEN ISNULL( NewMaxBet,0) = 0	THEN 'Row ' + CAST(RowID AS NVARCHAR(50))+ ': The New Max Bet is required field.' 
						   WHEN NewMinBet > NewMaxBet		THEN 'Row ' + CAST(RowID AS NVARCHAR(50))+ ': The New Max Bet must be greater than or equal to the New Min Bet.' 
						   WHEN NewMinBet = 0				THEN 'Row ' + CAST(RowID AS NVARCHAR(50))+ ': The Min Bet must be different from 0.'
						   WHEN NewMaxBet = 0				THEN 'Row ' + CAST(RowID AS NVARCHAR(50))+ ': The Max Bet must be different from 0.' 
						   WHEN ISNULL( CreditCurrency,'') = '' AND 
								ISNULL( DepositCurrency,'') = ''	THEN 'The Currency is required field.' 
						   ELSE '' END 						   
	FROM @NewStakeLevelTbl tmp
	WHERE ISNULL( SportType,'') = '' OR ISNULL( BetType,'') = '' OR ISNULL( NewMinBet,0) = 0 OR ISNULL( NewMaxBet,0) = 0
		OR NewMinBet > NewMaxBet OR NewMinBet = 0 OR NewMaxBet = 0
	
	IF	@ErrCode <> 0 RETURN
	
	INSERT INTO #NewInputDateTbl(RowID, SportType, BetType, Currency, NewMinBet, NewMaxBet, CurMinBet	
								, CurMaxBet, GameGroupID, IsCredit, SiteID)
	SELECT RowID, SportType, BetType, t.Currency, NewMinBet, NewMaxBet, CurMinBet	
								, CurMaxBet, GameGroupID, 1 AS IsCredit, SiteID
	FROM @NewStakeLevelTbl nsl
		CROSS APPLY (
				SELECT DISTINCT RTRIM(LTRIM(val)) AS Currency FROM dbo.strSplit(nsl.CreditCurrency, ',')
			) t
	WHERE nsl.CreditCurrency <> ''
	UNION ALL
	SELECT RowID, SportType, BetType, t.Currency, NewMinBet, NewMaxBet, CurMinBet	
								, CurMaxBet, GameGroupID, 0 AS IsCredit, SiteID
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
	SET a.SettingType =  psd.SettingType , a.OrgBetType = psd.BetType , a.ProductID = psd.RealProductId	
	FROM  #NewInputDateTbl a
		INNER JOIN ProductSettingDetail psd WITH(NOLOCK) ON a.SportType = psd.SportType AND ( psd.SettingType  = 8 OR (psd.SettingType IN (7, 17) AND a.BetType = psd.BetType))
	WHERE a.IsCredit = 1 AND psd.SettingType IN (7, 17, 8)
	
	UPDATE a 
	SET a.SettingType =  ps.SettingType	, a.OrgBetType = psd.BetType , a.ProductID  = ps.ProductID
	FROM  #NewInputDateTbl a
		INNER JOIN Dep_ProductSettingDetail psd WITH(NOLOCK) ON a.SportType = psd.SportType 
		INNER JOIN Dep_ProductSetting ps WITH(NOLOCK) ON ps.ProductSettingID = psd.ProductSettingID
	WHERE a.IsCredit = 0  AND ( ps.SettingType = 8 OR (ps.SettingType IN (7) AND a.BetType = psd.BetType))
	
	SELECT TOP (1) @ProductID = ProductID , @SportType = SportType, @BetType = OrgBetType FROM #NewInputDateTbl tmp ORDER BY RowID
	IF 	EXISTS( SELECT TOP 1 1 FROM #NewInputDateTbl WHERE SportType <> @SportType OR @BetType <> OrgBetType)	
	BEGIN
		SELECT @ErrCode = 121	
		SELECT  TOP(1) @ErrMsg = 'Row ' + CAST(RowID AS VARCHAR(10)) + ' : You can only upload setting for one product at a time.' 
		FROM #NewInputDateTbl WHERE SportType <> @SportType OR @BetType <> OrgBetType
		ORDER BY RowID 
		RETURN
	END	
	
	SELECT TOP(1) @ErrCode = 109 , @ErrBetType = CAST(tmp.BetType AS VARCHAR(10)) , @ValueError = CAST(tmp.BetType AS VARCHAR(200)), @RowError = CAST(tmp.RowID  AS VARCHAR(200))
	FROM #NewInputDateTbl tmp
	WHERE NOT EXISTS( SELECT TOP 1 1 FROM #Bettype WHERE typeid =  tmp.BetType) OR OrgBetType IS NULL
	IF 	@ErrCode = 109			
	BEGIN
		SELECT @ErrMsg = 'Row ' + @RowError+ ': The Bet Type ' + @ValueError + ' does not exist.' 
		RETURN
	END	

	SELECT TOP(1) @ErrCode = 108 , @ErrBetType = CAST(tmp.BetType AS VARCHAR(10)) , @ValueError = CAST(tmp.SportType AS VARCHAR(200)) , @RowError = CAST(tmp.RowID  AS VARCHAR(200))
	FROM #NewInputDateTbl tmp
	WHERE ISNULL(tmp.SettingType,0) = 0 OR NOT EXISTS( SELECT TOP 1 1 FROM #Sports WHERE SportType =  tmp.SportType)
	IF 	@ErrCode = 108			
	BEGIN
		SELECT @ErrMsg = 'Row ' + @RowError+ ': The Sport Type ' + @ValueError + ' does not exist.' 
		RETURN
	END	
	
	SELECT TOP(1) @ErrCode = 110 , @ErrBetType = CAST(tmp.BetType AS VARCHAR(10)) , @ValueError = CAST(tmp.currency AS VARCHAR(200)), @RowError = CAST(tmp.RowID  AS VARCHAR(200))
	FROM #NewInputDateTbl tmp
	WHERE ISNULL(tmp.Currency,'') <> '' AND tmp.IsCredit = 1 AND  NOT EXISTS( SELECT TOP 1 1 FROM Exchange WITH(NOLOCK) WHERE currency =  tmp.Currency  AND IsActive = 1 AND OfferSite IN (0,1))
	IF 	@ErrCode = 110			
	BEGIN
		SELECT @ErrMsg = 'Row ' + @RowError+ ': The Credit Currency ' + @ValueError + ' does not exist.' 
		RETURN
	END	
	
	SELECT TOP(1) @ErrCode = 111 , @ErrBetType = CAST(tmp.BetType AS VARCHAR(10)) , @ValueError = CAST(tmp.currency AS VARCHAR(200)), @RowError = CAST(tmp.RowID  AS VARCHAR(200))
	FROM #NewInputDateTbl tmp
	WHERE ISNULL(tmp.Currency,'') <> ''  AND tmp.IsCredit = 0 AND NOT EXISTS( SELECT TOP 1 1 FROM Exchange WITH(NOLOCK) WHERE currency =  tmp.Currency AND IsActive = 1 AND OfferSite IN (0,2))
	IF 	@ErrCode = 111			
	BEGIN
		SELECT @ErrMsg = 'Row ' + @RowError+ ': The Deposit Currency ' + @ValueError + ' does not exist.' 
		RETURN
	END
	
	SELECT TOP(1) @ErrCode = 120 , @ErrBetType = CAST(tmp.BetType AS VARCHAR(10)) , @ValueError = CAST(tmp.SiteID AS VARCHAR(200)), @RowError = CAST(tmp.RowID  AS VARCHAR(200))
	FROM #NewInputDateTbl tmp
	WHERE tmp.SettingType = 7  AND tmp.IsCredit = 0  AND (tmp.SiteID = 0  OR (tmp.SiteID <> 0  
		AND NOT EXISTS( SELECT TOP 1 1 FROM Site WITH(NOLOCK) WHERE siteid =  tmp.SiteID AND IsActive = 1 AND isLicensee =1 AND isDeposit = 1)))
	IF 	@ErrCode = 120			
	BEGIN
		SELECT @ErrMsg = 'Row ' + @RowError+ ': The Site  ' + @ValueError + ' does not exist.' 
		RETURN
	END
	
	SELECT TOP(1) @ErrCode = 112,  @ErrBetType = CAST(BetType AS VARCHAR(10))
	 , @ValueError = CAST(tmp.CurMinBet AS VARCHAR(50)) + ' and Current Max Bet: ' + CAST(tmp.CurMaxBet AS VARCHAR(50))
	 , @RowError = CAST(tmp.RowID  AS VARCHAR(200))
	FROM #NewInputDateTbl tmp
	WHERE  CurMinBet <> 0 AND ((IsCredit = 1 AND tmp.SettingType IN (7,17) 
							AND (NOT EXISTS( SELECT TOP 1 1 FROM StakeLevel WITH(NOLOCK) 
							WHERE BetType = GameTypeID AND ExchangeId = tmp.ExchangeId AND MinStake = CurMinBet  )
							 OR NOT EXISTS( SELECT TOP 1 1 FROM StakeLevel WITH(NOLOCK) 
							WHERE BetType = GameTypeID AND ExchangeId = tmp.ExchangeId AND MinStake = CurMinBet AND MaxStake = CurMaxBet )))
	OR (IsCredit = 0  AND tmp.SettingType IN (7) 
							AND (NOT EXISTS( SELECT TOP 1 1 FROM Dep_StakeLevel WITH(NOLOCK) 
							WHERE BetType = GameTypeID AND ExchangeId = tmp.ExchangeId AND (MinStake = CurMinBet ))
							OR NOT EXISTS( SELECT TOP 1 1 FROM Dep_StakeLevel WITH(NOLOCK) 
							WHERE BetType = GameTypeID AND ExchangeId = tmp.ExchangeId AND MinStake = CurMinBet AND MaxStake = CurMaxBet ))))
	
	IF 	@ErrCode = 112			
	BEGIN
		SELECT @ErrMsg = 'Row ' + @RowError+ ': Bet Type ' + @ErrBetType + ' does not have any existing stake level with Current Min Bet: ' + @ValueError + ' .' 
		RETURN
	END
	
	SELECT TOP(1) @ErrCode = 114 , @ErrBetType = CAST(tmp.BetType AS VARCHAR(10)) , @ValueError = CAST(tmp.GameGroupID AS VARCHAR(200)), @RowError = CAST(tmp.RowID  AS VARCHAR(200))
	FROM #NewInputDateTbl tmp
	WHERE tmp.SettingType IN (8)  AND NOT EXISTS( SELECT TOP 1 1 FROM GameGroup WITH(NOLOCK) 
									WHERE RefSportType =  tmp.SportType AND RefBetType = OrgBetType AND GameGroupID = tmp.GameGroupID
									AND ((tmp.IsCredit = 1 AND IsDeposit = 0) OR (tmp.IsCredit = 0 AND IsDeposit = 1)))
	IF 	@ErrCode = 114
	BEGIN
		SELECT @ErrMsg = 'Row ' + @RowError+ ': The Game Group ID ' + @ValueError + ' of bet type ' + @ErrBetType + ' does not exist.'  
		RETURN
	END
	
	SELECT TOP(1) @ErrCode = 115 , @ErrBetType = CAST(tmp.BetType AS VARCHAR(10)) , @ValueError = '', @RowError = CAST(tmp.RowID  AS VARCHAR(200))
	FROM #NewInputDateTbl tmp
	WHERE tmp.CurMinBet = NewMinBet AND CurMaxBet = NewMaxBet
	IF 	@ErrCode = 115			
	BEGIN
		SELECT @ErrMsg = 'Row ' + @RowError+ ': The New Min Bet and New Max Bet are the same as The Current Min Bet and The Current Max Bet. Please input another value for the New Min Bet and the New Max Bet again.'  
		RETURN
	END
	
	SELECT TOP(1) @ErrCode = 116 , @ErrBetType = CAST(tmp.BetType AS VARCHAR(10)) ,  @ValueError = CAST(tmp.GameGroupID AS VARCHAR(200)), @RowError = CAST(tmp.RowID  AS VARCHAR(200))
	FROM #NewInputDateTbl tmp
	WHERE tmp.SettingType IN (8) AND ISNULL(tmp.GameGroupID,0) = 0
	IF 	@ErrCode = 116			
	BEGIN
		SELECT @ErrMsg = 'Row ' + @RowError+ ': You input missing data with the product''s format. Please input data on Game Group ID.'  
		RETURN
	END
	
	SELECT TOP(1) @ErrCode = 117 , @ErrBetType = CAST(tmp.BetType AS VARCHAR(10)) ,  @ValueError = CAST(tmp.CurMinBet AS VARCHAR(200)), @RowError = CAST(tmp.RowID  AS VARCHAR(200))
	FROM #NewInputDateTbl tmp
	WHERE tmp.SettingType IN (7,17) AND ISNULL(tmp.CurMinBet,0) = 0 AND ISNULL(tmp.CurMaxBet,0) <> 0
	IF 	@ErrCode = 117			
	BEGIN
		SELECT @ErrMsg = 'Row ' + @RowError+ ': You input missing data with the product''s format. Please input data on Current Min Bet.'  
		RETURN
	END
	
	SELECT TOP(1) @ErrCode = 118 , @ErrBetType = CAST(tmp.BetType AS VARCHAR(10)) ,  @ValueError = CAST(tmp.CurMaxBet AS VARCHAR(200)), @RowError = CAST(tmp.RowID  AS VARCHAR(200))
	FROM #NewInputDateTbl tmp
	WHERE tmp.SettingType IN (7,17) AND ISNULL(tmp.CurMaxBet,0) = 0 AND ISNULL(tmp.CurMinBet,0) <> 0
	IF 	@ErrCode = 118			
	BEGIN
		SELECT @ErrMsg = 'Row ' + @RowError+ ': You input missing data with the product''s format. Please input data on Current Max Bet.'  
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
		SELECT @NotiMsg = 'There are new currencies : ' +  STUFF((SELECT DISTINCT ',' + CAST(Currency AS NVARCHAR(50))
									FROM #Currency
									FOR XML PATH('')), 1, 1, '')
	END
	
	INSERT INTO #RowDuplicate(RowIDF,RowIDT)
	SELECT DISTINCT tmp.RowID , ndt.RowID
	FROM #NewInputDateTbl tmp
	INNER JOIN #NewInputDateTbl ndt ON tmp.SportType = ndt.SportType AND tmp.BetType = ndt.BetType 
				AND tmp.ExchangeId = ndt.ExchangeId AND tmp.CurMinBet = ndt.CurMinBet AND tmp.CurMaxBet = ndt.CurMaxBet AND tmp.GameGroupID  = ndt.GameGroupID
				AND tmp.NewMaxBet = ndt.NewMaxBet AND tmp.NewMinBet = ndt.NewMinBet AND tmp.IsCredit = ndt.IsCredit AND (tmp.SettingType = 8 OR (tmp.SettingType = 7 AND tmp.SiteID = ndt.SiteID))
	WHERE tmp.RowID <  ndt.RowID 
	UNION ALL
	SELECT DISTINCT tmp.RowID , ndt.RowID  
	FROM #NewInputDateTbl tmp  
		INNER JOIN #NewInputDateTbl ndt ON tmp.SportType = ndt.SportType AND tmp.BetType = ndt.BetType AND tmp.GameGroupID  = ndt.GameGroupID  
			AND tmp.ExchangeId = ndt.ExchangeId AND tmp.IsCredit = ndt.IsCredit AND tmp.SettingType = 8 
	WHERE tmp.RowID <  ndt.RowID 
	IF 	EXISTS(	SELECT TOP 1 1 FROM #RowDuplicate )			
	BEGIN
		SET @ErrCode = 119
		SELECT @ErrMsg = STUFF((SELECT ', row ' + CAST(RowIDF AS NVARCHAR(50)) + ' - row ' + CAST(RowIDT AS NVARCHAR(50)) 
									FROM #RowDuplicate tmp
									ORDER BY RowIDF
									FOR XML PATH('')), 1, 1, '') + ' : These rows have duplicate data' 
		RETURN
	END	
	
	SELECT TOP(1) @ErrCode = 123 ,  @ValueError = CAST(KQ.RowID AS VARCHAR(200))
	FROM 
	(	SELECT RowID 
		FROM #NewInputDateTbl a
		WHERE a.IsCredit =  1 AND SettingType IN (7,17) 
		AND EXISTS( SELECT TOP 1 1 FROM StakeLevel tmp WITH(NOLOCK) 
						WHERE tmp.GameTypeID = a.BetType AND a.ExchangeId = tmp.ExchangeId 
							  AND (a.NewMinBet = MinStake AND a.NewMaxBet = MaxStake))
		UNION ALL
		SELECT RowID 
		FROM #NewInputDateTbl a
		WHERE a.IsCredit =  0 AND SettingType IN (7) 
				 AND EXISTS( SELECT TOP 1 1 FROM Dep_StakeLevel tmp WITH(NOLOCK) 
								 WHERE tmp.GameTypeID = a.BetType AND a.ExchangeId = tmp.ExchangeId 
								 AND a.NewMinBet = MinStake AND a.NewMaxBet = MaxStake AND tmp.SiteID = a.SiteID)
	) KQ
	
	IF 	@ErrCode = 123			
	BEGIN
		SELECT @ErrMsg = 'Row ' + @ValueError + ': This stake level is already existed.' 
		RETURN
	END	
	
	DROP TABLE #NewInputDateTbl
	DROP TABLE #Currency
	DROP TABLE #RowDuplicate
END								