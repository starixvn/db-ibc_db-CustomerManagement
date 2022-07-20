/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_InitializingGlobal_BetLimitCheck] 
	-- Add the parameters for the stored procedure here
	 @InputData				VARCHAR(MAX)=''
	, @ProductID			TINYINT=0			OUTPUT
	, @NotiCode				INT=0				OUTPUT
	, @NotiMsg				NVARCHAR(4000)='' OUTPUT
	, @ErrCode				INT=0				OUTPUT
	, @ErrMsg				NVARCHAR(4000)='' OUTPUT
AS
/*
	Task : NAP -  Flexible Initializing Stake Level/Bet Limit
	DB: DBACC/bodb02
	Original: 
	Revisions:
		- 20220210@Winfred: NAP -  Flexible Initializing check Stake Level [Redmine: #167128]
		- 20220420@Winfred: Fix setting type 7 get bettype original [Redmine: #171750]
		- 20220705@Tacy: NAP - Flexible Initializing Global Bet Limit [Redmine: #174509]
	
	Param's Explanation:
		• @pInputData : 
		<ROOT>
			<BetLimit 
					SportType="1" 
					BetType="1"
					Site="53"
					CreditCurrency="US$, Yen, $US, UT, USD" 
					DepositCurrency="US$, USDT"
					NewMinBet="1" 
					NewMaxBet="30000" 
					NewMaxPerMatch="" 
					NewMaxPerBall="" 
					CurMinBet="30000" 
					CurMaxBet="30000" 
					CurMaxPerMatch="" 
					CurMaxPerBall="" 
					GameGroupID="30000" 
			/>
	</ROOT>
*/
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @xml XML, @ErrBetType VARCHAR(10), @ValueError VARCHAR(500)='', @RowError VARCHAR(200)='', @SportType   SMALLINT , @BetType   SMALLINT 
	DECLARE @NewStakeLevelTbl TABLE (
			  RowID				INT IDENTITY (1, 1)
			, SportType			SMALLINT
			, BetType			SMALLINT
			, SiteID			INT
			, CreditCurrency	VARCHAR(500)
			, DepositCurrency	VARCHAR(500)
			, NewMinBet			DECIMAL(19, 8)
			, NewMaxBet			DECIMAL(19, 8)
			, NewMaxPerMatch	DECIMAL(19, 8)
			, NewMaxPerBall		DECIMAL(19, 8)
			, CurMinBet			DECIMAL(19, 8)
			, CurMaxBet			DECIMAL(19, 8)
			, CurMaxPerMatch	DECIMAL(19, 8)
			, CurMaxPerBall		DECIMAL(19, 8)
			, GameGroupID		INT
		)
	
	CREATE TABLE #NewInputDateTbl (
			  RowID				INT 
			, SportType			SMALLINT
			, OrgBetType		SMALLINT
			, BetType			SMALLINT
			, SiteID			INT
			, Currency			VARCHAR(50)
			, ExchangeId		INT
			, NewMinBet			DECIMAL(19, 8)
			, NewMaxBet			DECIMAL(19, 8)
			, NewMaxPerMatch	DECIMAL(19, 8)
			, NewMaxPerBall		DECIMAL(19, 8)
			, CurMinBet			DECIMAL(19, 8)
			, CurMaxBet			DECIMAL(19, 8)
			, CurMaxPerMatch	DECIMAL(19, 8)
			, CurMaxPerBall		DECIMAL(19, 8)
			, GameGroupID		INT
			, IsCredit			BIT Default((0))
			, SettingType		SMALLINT
			, ProductID		TINYINT
		)
	
	CREATE TABLE #Bettype (typeid INT PRIMARY KEY, typenamee NVARCHAR(128))
	CREATE TABLE #Sports(SportType TINYINT PRIMARY KEY, SportName NVARCHAR(50))
	CREATE TABLE #Currency(Currency	VARCHAR(50))
	CREATE TABLE #RowDuplicate(RowIDF INT, RowIDT INT)
	
	IF @InputData IS NULL OR @InputData=''
		RETURN
	
	SELECT	@ErrCode	= 0, @ErrMsg='', @NotiCode=0, @NotiMsg=''
	
	--Parse XML data
	DECLARE @iDoc INT

	EXEC sp_xml_preparedocument @iDoc OUTPUT
		, @InputData

	INSERT INTO @NewStakeLevelTbl(	SportType, BetType, SiteID, CreditCurrency, DepositCurrency, 
									NewMinBet, NewMaxBet, NewMaxPerMatch, NewMaxPerBall, 
									CurMinBet, CurMaxBet, CurMaxPerMatch, CurMaxPerBall, 
									GameGroupID)
	SELECT	SportType, BetType, Site, CreditCurrency, DepositCurrency, 
			NewMinBet, NewMaxBet, NewMaxPerMatch, NewMaxPerBall, 
			CurMinBet, CurMaxBet, CurMaxPerMatch, CurMaxPerBall, 
			GameGroupID
	FROM OPENXML(@iDoc, '/ROOT/BetLimit', 1) WITH (
				 SportType			SMALLINT
				, BetType			SMALLINT
				, Site				INT
				, CreditCurrency	VARCHAR(500)
				, DepositCurrency	VARCHAR(500)
				, NewMinBet			DECIMAL(19, 8)
				, NewMaxBet			DECIMAL(19, 8)
				, NewMaxPerMatch	DECIMAL(19, 8)
				, NewMaxPerBall		DECIMAL(19, 8)
				, CurMinBet			DECIMAL(19, 8)
				, CurMaxBet			DECIMAL(19, 8)
				, CurMaxPerMatch	DECIMAL(19, 8)
				, CurMaxPerBall		DECIMAL(19, 8)
				, GameGroupID		INT
			)
	EXEC sp_xml_removedocument @iDoc

	INSERT INTO #Sports	(SportType, SportName)	
	SELECT SportType, SportName 
	FROM dbo.Sports WITH(NOLOCK)
	
	INSERT INTO #Bettype (typeid, typenamee)	
	SELECT typeid, typenamee 
	FROM dbo.Bettype WITH(NOLOCK)

	SELECT @ErrCode=CASE WHEN ISNULL(BetType, '')=''		THEN 132
						 WHEN ISNULL(NewMinBet, 0)=0		THEN 133
						 WHEN ISNULL(NewMaxBet, 0)=0		THEN 134
						 WHEN (SportType IN (1, 161, 164, 168, 202, 199, 220, 222, 169, 175, 217, 218) OR --SportsBook, Number Game, Happy 5, RNG Keno, Virtual Sports 2, Lottery, Table Game, Sports Lottery, Bitcoin, NG2
						 	  (SportType BETWEEN 180 AND 186)	OR	--Virtual Sports (Inspired)
							  (SportType BETWEEN 213 AND 215)	OR	--NG2
							  (SportType BETWEEN 190 AND 197))		--Virtual Sports 2 (Betradar)
							AND ISNULL(NewMaxPerMatch, 0)=0					THEN 135	
						 WHEN SportType=161 AND ISNULL(NewMaxPerBall, 0)=0	THEN 136

						 WHEN SportType<>161 THEN
							CASE WHEN NewMinBet=0						THEN 137
								 WHEN NewMaxBet=0						THEN 138
								 WHEN (SportType IN (1, 164, 168, 202, 199, 220, 222, 169, 175, 217, 218) OR 
									  (SportType BETWEEN 180 AND 186)	OR	
									  (SportType BETWEEN 213 AND 215)	OR	
									  (SportType BETWEEN 190 AND 197))	
									AND NewMaxPerMatch=0				THEN 139		
							END
						 WHEN SportType=161 THEN
							CASE WHEN NewMinBet=0	
									AND NOT (NewMaxBet=0 AND NewMaxPerBall=0 AND NewMaxPerMatch=0)	THEN 137
								 WHEN NewMaxBet=0	
									AND NOT (NewMinBet=0 AND NewMaxPerBall=0 AND NewMaxPerMatch=0)	THEN 138
								 WHEN NewMaxPerMatch=0	
									AND NOT (NewMaxBet=0 AND NewMinBet=0 AND NewMaxPerBall=0)		THEN 139
							END

						 WHEN NewMinBet > NewMaxBet		THEN 153
						 WHEN  (SportType IN (1, 161, 164, 168, 202, 199, 220, 222, 169, 175, 217, 218) 
							OR (SportType BETWEEN 180 AND 186)		
							OR (SportType BETWEEN 213 AND 215)		
							OR (SportType BETWEEN 190 AND 197))	
							AND (NewMaxBet > NewMaxPerMatch)										THEN 140	
						 WHEN SportType=161 AND (NewMaxBet > NewMaxPerBall) AND NewMaxPerBall<>0	THEN 141	
						 WHEN SportType=161 AND (NewMaxPerBall > NewMaxPerMatch)					THEN 142	

						 WHEN ISNULL(CreditCurrency, '')='' AND 
							  ISNULL(DepositCurrency, '')=''	THEN 122
						 ELSE 131 
					END, 

		  @ErrMsg =	  CASE WHEN ISNULL(SportType, '')=''	THEN 'Row ' + CAST(RowID AS NVARCHAR(50))+ ': The Sport Type is required field.' 
						   WHEN ISNULL(BetType, '')=''		THEN 'Row ' + CAST(RowID AS NVARCHAR(50))+ ': The Bet Type is required field.' 
						   WHEN ISNULL(NewMinBet, 0)=0		THEN 'Row ' + CAST(RowID AS NVARCHAR(50))+ ': The New Min Bet is required field.' 
						   WHEN ISNULL(NewMaxBet, 0)=0		THEN 'Row ' + CAST(RowID AS NVARCHAR(50))+ ': The New Max Bet is required field.' 
						   WHEN (SportType IN (1, 164, 168, 202, 199, 220, 222, 169, 175, 217, 218) OR 
								(SportType BETWEEN 180 AND 186)	OR	
								(SportType BETWEEN 213 AND 215)	OR	
								(SportType BETWEEN 190 AND 197))	
								AND ISNULL(NewMaxPerMatch, 0)=0					THEN 'Row ' + CAST(RowID AS NVARCHAR(50))+ ': The New Max Per Match is required field.' 
						   WHEN SportType=161 AND ISNULL(NewMaxPerBall, 0)=0	THEN 'Row ' + CAST(RowID AS NVARCHAR(50))+ ': The New Max Per Ball is a required field.' 

						   WHEN NewMinBet > NewMaxBet													THEN 'Row ' + CAST(RowID AS NVARCHAR(50))+ ': The New Max Bet must be greater than or equal to the New Min Bet.' 
						   WHEN (SportType IN (1, 161, 164, 168, 202, 199, 220, 222, 169, 175, 217, 218) OR 
								(SportType BETWEEN 180 AND 186)	OR	
								(SportType BETWEEN 213 AND 215)	OR	
								(SportType BETWEEN 190 AND 197))	
								AND (NewMaxBet > NewMaxPerMatch)										THEN 'Row ' + CAST(RowID AS NVARCHAR(50))+ ': The New Max Bet must be less than or equal to the New Max Per Match.'
						   WHEN SportType=161 AND (NewMaxBet > NewMaxPerBall) AND NewMaxPerBall<>0		THEN 'Row ' + CAST(RowID AS NVARCHAR(50))+ ': The New Max Bet must be less than or equal to the New Max Per Ball.'
						   WHEN SportType=161 AND (NewMaxPerBall > NewMaxPerMatch)						THEN 'Row ' + CAST(RowID AS NVARCHAR(50))+ ': The New Max Per Ball must be less than or equal to the New Max Per Match.'
						
						   WHEN SportType<>161 THEN
								CASE WHEN NewMinBet=0				THEN 'Row ' + CAST(RowID AS NVARCHAR(50))+ ': The Min Bet must be different from 0.'
									 WHEN NewMaxBet=0				THEN 'Row ' + CAST(RowID AS NVARCHAR(50))+ ': The Max Bet must be different from 0.' 
									 WHEN (SportType IN (1, 164, 168, 202, 199, 220, 222, 169, 175, 217, 218) OR 
										  (SportType BETWEEN 180 AND 186)	OR	
										  (SportType BETWEEN 213 AND 215)	OR	
										  (SportType BETWEEN 190 AND 197))	
										AND NewMaxPerMatch=0											THEN 'Row ' + CAST(RowID AS NVARCHAR(50))+ ': The Max Per Match must be different from 0.'
								END
						   WHEN SportType=161 THEN
								CASE WHEN NewMinBet=0	
										AND NOT (NewMaxBet=0 AND NewMaxPerBall=0 AND NewMaxPerMatch=0)	THEN 'Row ' + CAST(RowID AS NVARCHAR(50))+ ': The Min Bet must be different from 0.'
									 WHEN NewMaxBet=0	
										AND NOT (NewMinBet=0 AND NewMaxPerBall=0 AND NewMaxPerMatch=0)	THEN 'Row ' + CAST(RowID AS NVARCHAR(50))+ ': The Max Bet must be different from 0.'
									 WHEN NewMaxPerMatch=0	
										AND NOT (NewMaxBet=0 AND NewMinBet=0 AND NewMaxPerBall=0)		THEN 'Row ' + CAST(RowID AS NVARCHAR(50))+ ': The Max Per Match must be different from 0.'
								END

						   WHEN ISNULL(CreditCurrency, '')='' AND 
								ISNULL(DepositCurrency, '')=''	THEN 'The Currency is required field.' 
						   ELSE '' 
						END 						   
	FROM @NewStakeLevelTbl tmp
	WHERE ISNULL(SportType, '')='' OR ISNULL(BetType, '')='' OR ISNULL(NewMinBet, 0)=0 OR ISNULL(NewMaxBet, 0)=0
		OR NewMinBet > NewMaxBet
		OR
			((SportType IN (1, 161, 164, 168, 202, 199, 220, 222, 169, 175, 217, 218) OR 
			 (SportType BETWEEN 180 AND 186)	OR	
			 (SportType BETWEEN 213 AND 215)	OR	
			 (SportType BETWEEN 190 AND 197))
			AND 
			 (ISNULL(NewMaxPerMatch, 0)=0 OR  NewMaxBet > NewMaxPerMatch))
		OR
			(SportType=161 
			AND
			(ISNULL(NewMaxPerBall, 0)=0 
				OR ((NewMaxBet > NewMaxPerBall) AND NewMaxPerBall<>0) 
				OR  (NewMaxPerBall > NewMaxPerMatch) 
				OR  (NewMinBet=0 AND NOT (NewMaxBet=0 AND NewMaxPerBall=0 AND NewMaxPerMatch=0)) 
				OR	(NewMaxBet=0 AND NOT (NewMinBet=0 AND NewMaxPerBall=0 AND NewMaxPerMatch=0)) 
				OR	(NewMaxPerMatch=0 AND NOT (NewMaxBet=0 AND NewMinBet=0 AND NewMaxPerBall=0))))	
		OR
			(SportType<>161 
			AND
			(NewMinBet=0 OR NewMaxBet=0 
				OR ((SportType IN (1, 164, 168, 202, 199, 220, 222, 169, 175, 217, 218) OR 
					(SportType BETWEEN 180 AND 186)	OR	
					(SportType BETWEEN 213 AND 215)	OR	
					(SportType BETWEEN 190 AND 197))	
					AND NewMaxPerMatch=0)))	

	IF	@ErrCode<>0 RETURN
	
	INSERT INTO #NewInputDateTbl(RowID, SportType, BetType, Currency, 
								NewMinBet, NewMaxBet, NewMaxPerMatch, NewMaxPerBall, 
								CurMinBet, CurMaxBet, CurMaxPerMatch, CurMaxPerBall, 
								GameGroupID, IsCredit, SiteID)
	SELECT	RowID, SportType, BetType, t.Currency, 
			NewMinBet, NewMaxBet, NewMaxPerMatch, NewMaxPerBall, 
			CurMinBet, CurMaxBet, CurMaxPerMatch, CurMaxPerBall, 
			GameGroupID, 1 AS IsCredit, SiteID
	FROM @NewStakeLevelTbl nsl
		CROSS APPLY (
				SELECT DISTINCT RTRIM(LTRIM(value)) AS Currency FROM STRING_SPLIT(nsl.CreditCurrency, ',')
			) t
	WHERE nsl.CreditCurrency<>''
	UNION ALL
	SELECT	RowID, SportType, BetType, t.Currency, 
			NewMinBet, NewMaxBet, NewMaxPerMatch, NewMaxPerBall, 
			CurMinBet, CurMaxBet, CurMaxPerMatch, CurMaxPerBall, 
			GameGroupID, 0 AS IsCredit, SiteID
	FROM @NewStakeLevelTbl nsl
		CROSS APPLY (
				SELECT DISTINCT RTRIM(LTRIM(value)) AS Currency FROM STRING_SPLIT(nsl.DepositCurrency, ',')
			) t		
	WHERE nsl.DepositCurrency<>''
	
	--Update: ExchangeId
	UPDATE a 
	SET a.ExchangeId=CASE WHEN a.IsCredit=1 AND e.OfferSite IN (0, 1) THEN e.ExchangeId
							WHEN a.IsCredit=0 AND e.OfferSite IN (0, 2) THEN e.ExchangeId
						ELSE NULL END	
	FROM  #NewInputDateTbl a
		INNER JOIN Exchange e WITH(NOLOCK) ON a.Currency=e.currency
	
	--UPDATE: SettingType, BetType, ProductID
	UPDATE a	--CREDIT
	SET a.SettingType= psd.SettingType, a.OrgBetType=psd.BetType, a.ProductID=psd.RealProductId	
	FROM  #NewInputDateTbl a
		INNER JOIN ProductSettingDetail psd WITH(NOLOCK) ON a.SportType=psd.SportType AND (psd.SettingType IN (2, 8, 9, 16, 20) OR (psd.SettingType IN (7, 17) AND a.BetType=psd.BetType))
	WHERE a.IsCredit=1 AND psd.SettingType IN (2, 7, 8, 9, 16, 17, 20) AND psd.ProductID NOT IN  (1,3,8)
	
	UPDATE a	--DEPOSIT
	SET a.SettingType= ps.SettingType, a.OrgBetType=psd.BetType, a.ProductID =ps.ProductID
	FROM  #NewInputDateTbl a
		INNER JOIN Dep_ProductSettingDetail psd WITH(NOLOCK) ON a.SportType=psd.SportType 
		INNER JOIN Dep_ProductSetting ps WITH(NOLOCK) ON ps.ProductSettingID=psd.ProductSettingID
	WHERE a.IsCredit=0  AND (ps.SettingType IN (2, 8, 10, 11, 12) OR (ps.SettingType IN (7) AND a.BetType=psd.BetType))
	
	SELECT TOP (1) @ProductID=ProductID, @SportType=SportType, @BetType=OrgBetType FROM #NewInputDateTbl tmp ORDER BY RowID
	IF 	EXISTS(SELECT TOP 1 1 FROM #NewInputDateTbl WHERE SportType<>@SportType OR @BetType<>OrgBetType)	
	BEGIN
		SELECT @ErrCode=121	
		SELECT  TOP(1) @ErrMsg='Row ' + CAST(RowID AS VARCHAR(10)) + ' : You can only upload setting for one product at a time.' 
		FROM #NewInputDateTbl WHERE SportType<>@SportType OR @BetType<>OrgBetType
		ORDER BY RowID 
		RETURN
	END	
	
	SELECT TOP(1) @ErrCode=109, @ErrBetType=CAST(tmp.BetType AS VARCHAR(10)), @ValueError=CAST(tmp.BetType AS VARCHAR(200)), @RowError=CAST(tmp.RowID  AS VARCHAR(200))
	FROM #NewInputDateTbl tmp
	WHERE NOT EXISTS(SELECT TOP 1 1 FROM #Bettype WHERE typeid= tmp.BetType) OR OrgBetType IS NULL
	IF 	@ErrCode=109			
	BEGIN
		SELECT @ErrMsg='Row ' + @RowError+ ': The Bet Type ' + @ValueError + ' does not exist.' 
		RETURN
	END	

	SELECT TOP(1) @ErrCode=108, @ErrBetType=CAST(tmp.BetType AS VARCHAR(10)), @ValueError=CAST(tmp.SportType AS VARCHAR(200)), @RowError=CAST(tmp.RowID  AS VARCHAR(200))
	FROM #NewInputDateTbl tmp
	WHERE ISNULL(tmp.SettingType, 0)=0 OR NOT EXISTS(SELECT TOP 1 1 FROM #Sports WHERE SportType= tmp.SportType)
	IF 	@ErrCode=108			
	BEGIN
		SELECT @ErrMsg='Row ' + @RowError+ ': The Sport Type ' + @ValueError + ' does not exist.' 
		RETURN
	END	
	
	SELECT TOP(1) @ErrCode=110, @ErrBetType=CAST(tmp.BetType AS VARCHAR(10)), @ValueError=CAST(tmp.currency AS VARCHAR(200)), @RowError=CAST(tmp.RowID  AS VARCHAR(200))
	FROM #NewInputDateTbl tmp
	WHERE ISNULL(tmp.Currency, '')<>'' AND tmp.IsCredit=1 AND  NOT EXISTS(SELECT TOP 1 1 FROM Exchange WITH(NOLOCK) WHERE currency= tmp.Currency  AND IsActive=1 AND OfferSite IN (0, 1))
	IF 	@ErrCode=110			
	BEGIN
		SELECT @ErrMsg='Row ' + @RowError+ ': The Credit Currency ' + @ValueError + ' does not exist.' 
		RETURN
	END	
	
	SELECT TOP(1) @ErrCode=111, @ErrBetType=CAST(tmp.BetType AS VARCHAR(10)), @ValueError=CAST(tmp.currency AS VARCHAR(200)), @RowError=CAST(tmp.RowID  AS VARCHAR(200))
	FROM #NewInputDateTbl tmp
	WHERE ISNULL(tmp.Currency, '')<>''  AND tmp.IsCredit=0 AND NOT EXISTS(SELECT TOP 1 1 FROM Exchange WITH(NOLOCK) WHERE currency= tmp.Currency AND IsActive=1 AND OfferSite IN (0, 2))
	IF 	@ErrCode=111			
	BEGIN
		SELECT @ErrMsg='Row ' + @RowError+ ': The Deposit Currency ' + @ValueError + ' does not exist.' 
		RETURN
	END
	
	SELECT TOP(1) @ErrCode=124, @ErrBetType=CAST(tmp.BetType AS VARCHAR(10)), @ValueError=CAST(tmp.SiteID AS VARCHAR(200)), @RowError=CAST(tmp.RowID  AS VARCHAR(200))
	FROM #NewInputDateTbl tmp
	WHERE tmp.SettingType=7  AND tmp.IsCredit=0  AND (tmp.SiteID=0  OR (tmp.SiteID<>0  
		AND NOT EXISTS(SELECT TOP 1 1 FROM Site WITH(NOLOCK) WHERE siteid= tmp.SiteID AND IsActive=1 AND isLicensee =1 AND isDeposit=1)))
	IF 	@ErrCode=124			
	BEGIN
		SELECT @ErrMsg='Row ' + @RowError+ ': The Site  ' + @ValueError + ' does not exist.' 
		RETURN
	END
	
	SELECT TOP(1) @ErrCode=112,  @ErrBetType=CAST(BetType AS VARCHAR(10))
	, @ValueError= CASE WHEN NOT (SportType IN (1, 161, 164, 168, 202, 199, 220, 222, 169, 175, 217, 218) OR 
								(SportType BETWEEN 180 AND 186)	OR	
								(SportType BETWEEN 213 AND 215)	OR	
								(SportType BETWEEN 190 AND 197))
							THEN CAST(tmp.CurMinBet AS VARCHAR(50)) + ' and Current Max Bet: ' + CAST(tmp.CurMaxBet AS VARCHAR(50))
						WHEN SportType=161 
							THEN CAST(tmp.CurMinBet AS VARCHAR(50)) + ' and Current Max Bet: ' + CAST(tmp.CurMaxBet AS VARCHAR(50)) + ' and Current Max Per Ball: ' + CAST(tmp.CurMaxPerBall AS VARCHAR(50)) + ' and Current Max Per Match: ' + CAST(tmp.CurMaxPerMatch AS VARCHAR(50))
						ELSE CAST(tmp.CurMinBet AS VARCHAR(50)) + ' and Current Max Bet: ' + CAST(tmp.CurMaxBet AS VARCHAR(50)) + ' and Current Max Per Match: ' + CAST(tmp.CurMaxPerMatch AS VARCHAR(50))
					END
	, @RowError=CAST(tmp.RowID  AS VARCHAR(200))
	FROM #NewInputDateTbl tmp
	WHERE  CurMinBet<>0 AND 
	(  (IsCredit=1 AND tmp.SettingType IN (7, 17) 
					AND (NOT EXISTS	(SELECT TOP 1 1 FROM StakeLevel WITH(NOLOCK) 
									 WHERE BetType=GameTypeID AND ExchangeId=tmp.ExchangeId AND MinStake=CurMinBet)
						OR NOT EXISTS(SELECT TOP 1 1 FROM StakeLevel WITH(NOLOCK) 
										WHERE BetType=GameTypeID AND ExchangeId=tmp.ExchangeId AND MinStake=CurMinBet AND MaxStake=CurMaxBet )))
	OR (IsCredit=0  AND tmp.SettingType IN (7) 
					  AND (NOT EXISTS(SELECT TOP 1 1 FROM Dep_StakeLevel WITH(NOLOCK) 
									  WHERE BetType=GameTypeID AND ExchangeId=tmp.ExchangeId AND (MinStake=CurMinBet ))
							OR NOT EXISTS(SELECT TOP 1 1 FROM Dep_StakeLevel WITH(NOLOCK) 
										  WHERE BetType=GameTypeID AND ExchangeId=tmp.ExchangeId AND MinStake=CurMinBet AND MaxStake=CurMaxBet )))
	OR (IsCredit=1 AND tmp.SettingType IN (2, 9, 16, 20)
					AND (NOT EXISTS (SELECT TOP 1 1 FROM ProductBetSetting pbs WITH (NOLOCK)
									 WHERE pbs.Bettype=tmp.BetType AND pbs.Currency=tmp.ExchangeId AND pbs.MinBet=tmp.CurMinBet)
						 OR NOT EXISTS (SELECT TOP 1 1 FROM ProductBetSetting pbs WITH (NOLOCK)
									 WHERE pbs.Bettype=tmp.BetType AND pbs.Currency=tmp.ExchangeId AND pbs.MinBet=tmp.CurMinBet AND pbs.MaxBet=tmp.CurMaxBet)))
	OR (IsCredit=0 AND tmp.SettingType IN (2, 10, 11, 12)
					AND (NOT EXISTS (SELECT TOP 1 1 FROM Dep_ProductBetSetting pbs WITH (NOLOCK)
									 WHERE pbs.Bettype=tmp.BetType AND pbs.Currency=tmp.ExchangeId AND pbs.MinBet=tmp.CurMinBet)
						 OR NOT EXISTS (SELECT TOP 1 1 FROM Dep_ProductBetSetting pbs WITH (NOLOCK)
									 WHERE pbs.Bettype=tmp.BetType AND pbs.Currency=tmp.ExchangeId AND pbs.MinBet=tmp.CurMinBet AND pbs.MaxBet=tmp.CurMaxBet))))

	IF 	@ErrCode=112			
	BEGIN
		SELECT @ErrMsg='Row ' + @RowError+ ': Bet Type ' + @ErrBetType + ' does not have any existing bet limit with Current Min Bet: ' + @ValueError + ' .' 
		RETURN
	END
	
	SELECT TOP(1) @ErrCode=114, @ErrBetType=CAST(tmp.BetType AS VARCHAR(10)), @ValueError=CAST(tmp.GameGroupID AS VARCHAR(200)), @RowError=CAST(tmp.RowID  AS VARCHAR(200))
	FROM #NewInputDateTbl tmp
	WHERE tmp.SettingType IN (8)  AND NOT EXISTS(SELECT TOP 1 1 FROM GameGroup WITH(NOLOCK) 
									WHERE RefSportType= tmp.SportType AND RefBetType=OrgBetType AND GameGroupID=tmp.GameGroupID
									AND ((tmp.IsCredit=1 AND IsDeposit=0) OR (tmp.IsCredit=0 AND IsDeposit=1)))
	IF 	@ErrCode=114
	BEGIN
		SELECT @ErrMsg='Row ' + @RowError+ ': The Game Group ID ' + @ValueError + ' of bet type ' + @ErrBetType + ' does not exist.'  
		RETURN
	END
	
	SELECT TOP(1) @ErrCode=115, @ErrBetType=CAST(tmp.BetType AS VARCHAR(10))
				, @ValueError=CASE WHEN NOT (SportType IN (1, 161, 164, 168, 202, 199, 220, 222, 169, 175, 217, 218) OR 
											(SportType BETWEEN 180 AND 186)	OR	
											(SportType BETWEEN 213 AND 215)	OR	
											(SportType BETWEEN 190 AND 197))
										THEN ': The New Min Bet, New Max Bet are the same as The Current Min Bet, and the Current Max Bet. Please input another value for the New values again.'
									WHEN SportType=161 
										THEN ': The New Min Bet, New Max Bet, New Max Per Match, New Max Per Ball are the same as The Current Min Bet, the Current Max Bet, the Current Max Per Match, and the Current Max Per Ball. Please input another value for the New values again.'
									ELSE ': The New Min Bet, New Max Bet, New Max Per Match are the same as The Current Min Bet, the Current Max Bet, and the Current Max Per Match. Please input another value for the New values again.'
								END
				, @RowError=CAST(tmp.RowID  AS VARCHAR(200))
	FROM #NewInputDateTbl tmp
	WHERE (tmp.CurMinBet=NewMinBet AND CurMaxBet=NewMaxBet
			AND NOT (SportType IN (1, 161, 164, 168, 202, 199, 220, 222, 169, 175, 217, 218) OR 
					(SportType BETWEEN 180 AND 186)	OR	
					(SportType BETWEEN 213 AND 215)	OR	
					(SportType BETWEEN 190 AND 197)))
	OR (tmp.CurMinBet=NewMinBet AND CurMaxBet=NewMaxBet AND CurMaxPerMatch=NewMaxPerMatch AND
		(SportType IN (1, 161, 164, 168, 202, 199, 220, 222, 169, 175, 217, 218) OR 
		(SportType BETWEEN 180 AND 186)	OR	
		(SportType BETWEEN 213 AND 215)	OR	
		(SportType BETWEEN 190 AND 197)))
	OR (tmp.CurMinBet=NewMinBet AND CurMaxBet=NewMaxBet AND CurMaxPerMatch=NewMaxPerMatch AND tmp.CurMaxPerBall=NewMaxPerBall AND SportType=161)

	IF 	@ErrCode=115			
	BEGIN
		SELECT @ErrMsg='Row ' + @RowError + @ValueError		
		RETURN
	END
	
	SELECT TOP(1) @ErrCode=116, @ErrBetType=CAST(tmp.BetType AS VARCHAR(10)),  @ValueError=CAST(tmp.GameGroupID AS VARCHAR(200)), @RowError=CAST(tmp.RowID  AS VARCHAR(200))
	FROM #NewInputDateTbl tmp
	WHERE tmp.SettingType IN (8) AND ISNULL(tmp.GameGroupID, 0)=0
	IF 	@ErrCode=116			
	BEGIN
		SELECT @ErrMsg='Row ' + @RowError+ ': You input missing data with the product''s format. Please input data on Game Group ID.'  
		RETURN
	END
	
	SELECT TOP(1) @ErrCode=117, @ErrBetType=CAST(tmp.BetType AS VARCHAR(10)),  @ValueError=CAST(tmp.CurMinBet AS VARCHAR(200)), @RowError=CAST(tmp.RowID  AS VARCHAR(200))
	FROM #NewInputDateTbl tmp
	WHERE (tmp.SettingType IN (7, 17, 2, 9, 16, 20, 10, 11, 12) 
			AND ((ISNULL(tmp.CurMinBet, 0)=0 AND ISNULL(tmp.CurMaxBet, 0)<>0
					AND NOT (SportType IN (1, 161, 164, 168, 202, 199, 220, 222, 169, 175, 217, 218) OR 
							(SportType BETWEEN 180 AND 186)	OR	
							(SportType BETWEEN 213 AND 215)	OR	
							(SportType BETWEEN 190 AND 197))))
			) 
		OR
			(ISNULL(tmp.CurMinBet, 0)=0 AND ISNULL(tmp.CurMaxBet, 0)<>0 AND ISNULL(tmp.CurMaxPerMatch, 0)<>0
				AND (SportType IN (1, 161, 164, 168, 202, 199, 220, 222, 169, 175, 217, 218) OR 
					(SportType BETWEEN 180 AND 186)	OR	
					(SportType BETWEEN 213 AND 215)	OR	
					(SportType BETWEEN 190 AND 197))
			)
		OR
			(ISNULL(tmp.CurMinBet, 0)=0 AND ISNULL(tmp.CurMaxBet, 0)<>0 AND ISNULL(tmp.CurMaxPerMatch, 0)<>0 AND ISNULL(tmp.CurMaxPerBall, 0)<>0
				AND SportType=161)

	IF 	@ErrCode=117			
	BEGIN
		SELECT @ErrMsg='Row ' + @RowError+ ': You input missing data with the product''s format. Please input data on Current Min Bet.'  
		RETURN
	END
	
	SELECT TOP(1) @ErrCode=118, @ErrBetType=CAST(tmp.BetType AS VARCHAR(10)),  @ValueError=CAST(tmp.CurMaxBet AS VARCHAR(200)), @RowError=CAST(tmp.RowID  AS VARCHAR(200))
	FROM #NewInputDateTbl tmp
	WHERE (tmp.SettingType IN (7, 17, 2, 9, 16, 20, 10, 11, 12) 
			AND ((ISNULL(tmp.CurMinBet, 0)<>0 AND ISNULL(tmp.CurMaxBet, 0)=0
					AND NOT (SportType IN (1, 161, 164, 168, 202, 199, 220, 222, 169, 175, 217, 218) OR 
							(SportType BETWEEN 180 AND 186)	OR	
							(SportType BETWEEN 213 AND 215)	OR	
							(SportType BETWEEN 190 AND 197))))
			) 
		OR
			(ISNULL(tmp.CurMinBet, 0)<>0 AND ISNULL(tmp.CurMaxBet, 0)=0 AND ISNULL(tmp.CurMaxPerMatch, 0)<>0
				AND (SportType IN (1, 161, 164, 168, 202, 199, 220, 222, 169, 175, 217, 218) OR 
					(SportType BETWEEN 180 AND 186)	OR	
					(SportType BETWEEN 213 AND 215)	OR	
					(SportType BETWEEN 190 AND 197))
			)
		OR
			(ISNULL(tmp.CurMinBet, 0)<>0 AND ISNULL(tmp.CurMaxBet, 0)=0 AND ISNULL(tmp.CurMaxPerMatch, 0)<>0 AND ISNULL(tmp.CurMaxPerBall, 0)<>0
				AND SportType=161)
	
	IF 	@ErrCode=118			
	BEGIN
		SELECT @ErrMsg='Row ' + @RowError+ ': You input missing data with the product''s format. Please input data on Current Max Bet.'  
		RETURN
	END

	/*--------------------------------
		MAX PER MATCH
	--------------------------------*/
	SELECT TOP(1) @ErrCode=119, @ErrBetType=CAST(tmp.BetType AS VARCHAR(10)),  @ValueError=CAST(tmp.CurMaxPerMatch AS VARCHAR(200)), @RowError=CAST(tmp.RowID  AS VARCHAR(200))
	FROM #NewInputDateTbl tmp
	WHERE (ISNULL(tmp.CurMinBet, 0)<>0 AND ISNULL(tmp.CurMaxBet, 0)<>0 AND ISNULL(tmp.CurMaxPerMatch, 0)=0
				AND (SportType IN (1, 161, 164, 168, 202, 199, 220, 222, 169, 175, 217, 218) OR 
					(SportType BETWEEN 180 AND 186)	OR	
					(SportType BETWEEN 213 AND 215)	OR	
					(SportType BETWEEN 190 AND 197))
			)
		OR
			(ISNULL(tmp.CurMinBet, 0)<>0 AND ISNULL(tmp.CurMaxBet, 0)<>0 AND ISNULL(tmp.CurMaxPerMatch, 0)=0 AND ISNULL(tmp.CurMaxPerBall, 0)<>0
				AND SportType=161)

	IF 	@ErrCode=119			
	BEGIN
		SELECT @ErrMsg='Row ' + @RowError+ ': You input missing data with the product''s format. Please input data on Current Max Per Match.'  
		RETURN
	END

	/*--------------------------------
		MAX PER BALL
	--------------------------------*/
	SELECT TOP(1) @ErrCode=120, @ErrBetType=CAST(tmp.BetType AS VARCHAR(10)),  @ValueError=CAST(tmp.CurMaxPerBall AS VARCHAR(200)), @RowError=CAST(tmp.RowID  AS VARCHAR(200))
	FROM #NewInputDateTbl tmp
	WHERE ISNULL(tmp.CurMinBet, 0)<>0 AND ISNULL(tmp.CurMaxBet, 0)<>0 AND ISNULL(tmp.CurMaxPerMatch, 0)=0 AND ISNULL(tmp.CurMaxPerBall, 0)<>0
		AND SportType=161

	IF 	@ErrCode=120			
	BEGIN
		SELECT @ErrMsg='Row ' + @RowError+ ': You input missing data with the product''s format. Please input data on Current Max Per Ball.'  
		RETURN
	END


	INSERT INTO #Currency (Currency)
	SELECT tmp.Currency
	FROM #NewInputDateTbl tmp
	WHERE IsCredit=1 AND NOT EXISTS(SELECT TOP 1 1 FROM StakeLevel WITH(NOLOCK) WHERE GameTypeID=tmp.OrgBetType AND ExchangeId=tmp.ExchangeId)
	UNION  
	SELECT tmp.Currency
	FROM #NewInputDateTbl tmp
	WHERE IsCredit=0 AND NOT EXISTS(SELECT TOP 1 1 FROM Dep_StakeLevel WITH(NOLOCK) WHERE tmp.OrgBetType=GameTypeID AND ExchangeId=tmp.ExchangeId)
	UNION
	SELECT tmp.Currency
	FROM #NewInputDateTbl tmp
	WHERE IsCredit=0 AND NOT EXISTS (SELECT TOP 1 1 FROM ProductBetSetting pbs WITH(NOLOCK) WHERE tmp.Bettype=pbs.Bettype AND tmp.SportType=pbs.Sporttype AND tmp.ExchangeId=pbs.Currency)
	UNION
	SELECT tmp.Currency
	FROM #NewInputDateTbl tmp
	WHERE IsCredit=1 AND NOT EXISTS (SELECT TOP 1 1 FROM Dep_ProductBetSetting pbs WITH(NOLOCK) WHERE tmp.Bettype=pbs.Bettype AND tmp.SportType=pbs.Sporttype AND tmp.ExchangeId=pbs.Currency)

	IF 	EXISTS(	SELECT TOP 1 1 FROM #Currency )			
	BEGIN
		SET @NotiCode=100
		SELECT @NotiMsg='There are new currencies : ' +  STUFF((SELECT DISTINCT ',' + CAST(Currency AS NVARCHAR(50))
									FROM #Currency
									FOR XML PATH('')), 1, 1, '')
	END
	
	INSERT INTO #RowDuplicate(RowIDF, RowIDT)
	SELECT DISTINCT tmp.RowID, ndt.RowID
	FROM #NewInputDateTbl tmp
	INNER JOIN #NewInputDateTbl ndt ON tmp.SportType=ndt.SportType AND tmp.BetType=ndt.BetType 
				AND tmp.ExchangeId=ndt.ExchangeId AND tmp.CurMinBet=ndt.CurMinBet AND tmp.CurMaxBet=ndt.CurMaxBet AND tmp.GameGroupID =ndt.GameGroupID
				AND tmp.NewMaxBet=ndt.NewMaxBet AND tmp.NewMinBet=ndt.NewMinBet AND tmp.IsCredit=ndt.IsCredit AND (tmp.SettingType IN (2, 8, 9, 16, 17, 20, 10, 11, 12) OR (tmp.SettingType=7 AND tmp.SiteID=ndt.SiteID))
	WHERE tmp.RowID <  ndt.RowID																									
	UNION ALL
	SELECT DISTINCT tmp.RowID, ndt.RowID  
	FROM #NewInputDateTbl tmp  
		INNER JOIN #NewInputDateTbl ndt ON tmp.SportType=ndt.SportType AND tmp.BetType=ndt.BetType
			AND tmp.ExchangeId=ndt.ExchangeId AND tmp.IsCredit=ndt.IsCredit AND tmp.SettingType=8 
	WHERE tmp.RowID <  ndt.RowID 
	IF 	EXISTS(	SELECT TOP 1 1 FROM #RowDuplicate )			
	BEGIN
		SET @ErrCode=125
		SELECT @ErrMsg=STUFF((SELECT ', row ' + CAST(RowIDF AS NVARCHAR(50)) + ' - row ' + CAST(RowIDT AS NVARCHAR(50)) 
									FROM #RowDuplicate tmp
									ORDER BY RowIDF
									FOR XML PATH('')), 1, 1, '') + ' : These rows have duplicate data' 
		RETURN
	END	
	
	SELECT TOP(1) @ErrCode=123,  @ValueError=CAST(KQ.RowID AS VARCHAR(200))
	FROM 
	(	SELECT RowID 
		FROM #NewInputDateTbl a
		WHERE a.IsCredit= 1 AND SettingType IN (2, 7, 9, 16, 17, 20) 
		AND (EXISTS (SELECT TOP 1 1 FROM StakeLevel tmp WITH(NOLOCK) 
					 WHERE tmp.GameTypeID=a.BetType AND a.ExchangeId=tmp.ExchangeId 
						  AND (a.NewMinBet=MinStake AND a.NewMaxBet=MaxStake))
			OR EXISTS (SELECT TOP 1 1 FROM ProductBetSetting pbs WITH(NOLOCK)
						WHERE pbs.Sporttype=a.SportType AND pbs.Bettype=a.BetType AND pbs.Currency=a.ExchangeId
							AND ((MinBet=NewMinBet AND MaxBet=NewMaxBet
									AND NOT (SportType IN (199, 220, 222, 169, 175, 217, 218) OR 
											(SportType BETWEEN 180 AND 186)	OR	
											(SportType BETWEEN 213 AND 215)	OR	
											(SportType BETWEEN 190 AND 197)))
								OR (MinBet=NewMinBet AND MaxBet=NewMaxBet AND MaxPerMatch=NewMaxPerMatch AND
									(SportType IN (199, 220, 222, 169, 175, 217, 218) OR 
									(SportType BETWEEN 180 AND 186)	OR	
									(SportType BETWEEN 213 AND 215)	OR	
									(SportType BETWEEN 190 AND 197)))
							))
			)
		UNION ALL
		SELECT RowID 
		FROM #NewInputDateTbl a
		WHERE a.IsCredit= 0 AND SettingType IN (7, 2, 10, 11, 12) 
				 AND ( EXISTS (SELECT TOP 1 1 FROM Dep_StakeLevel tmp WITH(NOLOCK) 
								 WHERE tmp.GameTypeID=a.BetType AND a.ExchangeId=tmp.ExchangeId 
								 AND a.NewMinBet=MinStake AND a.NewMaxBet=MaxStake AND tmp.SiteID=a.SiteID)
						OR EXISTS (SELECT TOP 1 1 FROM Dep_ProductBetSetting pbs WITH(NOLOCK)
									WHERE pbs.Sporttype=a.SportType AND pbs.Bettype=a.BetType AND pbs.Currency=a.ExchangeId
										AND ((MinBet=NewMinBet AND MaxBet=NewMaxBet
												AND NOT (SportType IN (1, 161, 164, 168, 202, 199, 220, 222, 169, 175, 217, 218) OR 
														(SportType BETWEEN 180 AND 186)	OR	
														(SportType BETWEEN 213 AND 215)	OR	
														(SportType BETWEEN 190 AND 197)))
											OR (MinBet=NewMinBet AND MaxBet=NewMaxBet AND MaxPerMatch=NewMaxPerMatch AND
												(SportType IN (1, 164, 168, 202, 199, 220, 222, 169, 175, 217, 218) OR 
												(SportType BETWEEN 180 AND 186)	OR	
												(SportType BETWEEN 213 AND 215)	OR	
												(SportType BETWEEN 190 AND 197)))
											OR (MinBet=NewMinBet AND MaxBet=NewMaxBet AND MaxPerMatch=NewMaxPerMatch AND MaxPerBall=NewMaxPerBall AND Sporttype=161)
									))
					)
	) KQ
	
	IF 	@ErrCode=123			
	BEGIN
		SELECT @ErrMsg='Row ' + @ValueError + ': This Bet Limit is already existed.' 
		RETURN
	END	
	
	DROP TABLE #NewInputDateTbl
	DROP TABLE #Currency
	DROP TABLE #RowDuplicate
END								