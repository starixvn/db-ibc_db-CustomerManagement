/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE [dbo].[Acc_InitializingGlobal_BetLimitSel] 
	-- Add the parameters for the stored procedure here
	 @ProductID				TINYINT
	,@pMutilSportType		VARCHAR(MAX) = ''
	,@pMutilBetType			VARCHAR(MAX) = ''
	,@pMutilCurrencyCredit	VARCHAR(MAX) = ''
	,@pMutilCurrencyDeposit	VARCHAR(MAX) = ''
	,@ExportData			INT	=	0
	,@PageSize				INT	=	50
	,@PageIndex				INT	=	0
	,@TotalRows 			INT	=	0 OUTPUT
AS
/*
		Task : NAP -  Flexible Initializing Stake Level/Bet Limit
		DB: DBACC/bodb02
		Original: 
		Revisions:
			- 20220210@Winfred: NAP - Flexible Initializing Stake Level [Redmine: #167128]
			- 20220705@Tacy: NAP - Flexible Initializing Global Bet Limit [Redmine: #174509]
		
		Param's Explanation:
			@ProductID				0 : All, <> 0 : ProductID
			@pMutilSportType		0 : All, <> 0 : SportType
			@pMutilBetType			0 : All, <> 0 : Bettype
			@pMutilCurrencyCredit	0 : All, <> 0 : Currency Credit
			@pMutilCurrencyDeposit  0 : All, <> 0 : Currency Deposit
			@ExportData				0 : Pages, <> 0 : All data

*/
BEGIN
	SET NOCOUNT ON

	DECLARE @rowstart	INT,
			@rowend		INT

	SELECT	@RowStart = @PageSize * @PageIndex + 1, 
			@RowEnd = @RowStart + @PageSize - 1 	
	
	CREATE TABLE #Bettype (
			typeid		INT PRIMARY KEY, 
			typenamee	NVARCHAR(128)
	)

	CREATE TABLE #Sports(
			SportType TINYINT PRIMARY KEY, 
			SportName NVARCHAR(50)
	)

	CREATE TABLE #ProductSettingDetail(
			SportType			TINYINT,
			SportName			NVARCHAR(50),
			BetType				INT, 
			typenamee			NVARCHAR(128),
			SettingType			SMALLINT,
			IsCredit			BIT DEFAULT((0))
	)

	CREATE TABLE #BetLimit(
			SportType			TINYINT, 
			SportName			NVARCHAR(50),
			BetType				INT, 
			typenamee			NVARCHAR(128),
			ExchangeIdCredit	INT,
			ExchangeIdDeposit	INT,
			NewMinBet			DECIMAL(19,8),
			NewMaxBet			DECIMAL(19,8),
			NewMaxPerMatch		DECIMAL(19,8),
			NewMaxPerBall		DECIMAL(19,8),
			CurMinBet			DECIMAL(19,8),
			CurMaxBet			DECIMAL(19,8),
			CurMaxPerMatch		DECIMAL(19,8),
			CurMaxPerBall		DECIMAL(19,8),
			GameGroupID			INT, 
			SiteID				INT
	)
		
	INSERT INTO #Sports (SportType, SportName)	
	SELECT SportType,SportName 
	FROM dbo.Sports WITH(NOLOCK)
	
	INSERT INTO #Bettype (typeid, typenamee)	
	SELECT typeid,typenamee 
	FROM dbo.Bettype WITH(NOLOCK)

	INSERT INTO #ProductSettingDetail (SportType, SportName, BetType, typenamee, SettingType, IsCredit)				
	SELECT SportType, SportName, BetType, typenamee, SettingType, IsCredit
	FROM 
	(
		SELECT DISTINCT
			psd.BetType
			,b.typenamee 
			,psd.SportType
			,s.SportName
			, psd.SettingType
			,1 AS IsCredit
		FROM ProductSettingDetail psd WITH(NOLOCK)
			INNER JOIN #Sports s WITH(NOLOCK) ON psd.SportType = s.SportType
			INNER JOIN #Bettype b WITH(NOLOCK) ON psd.BetType = b.typeid
		WHERE (psd.SettingType IN (2,7,8,9,16,17,20)) 
			AND (@ProductID = 0 OR psd.ProductID = @ProductID) 
			AND (@pMutilSportType = '0' OR psd.SportType IN (SELECT RTRIM(LTRIM(value)) val FROM STRING_SPLIT(@pMutilSportType, ',')))
			AND psd.ProductID NOT IN  (1,3,8) AND psd.SettingStatus<>2
			AND @pMutilCurrencyCredit<>''
		UNION ALL
		SELECT DISTINCT
			  psd.BetType
			,b.typenamee 
			,psd.SportType
			,s.SportName
			,ps.SettingType
			,0 AS IsCredit
		FROM Dep_ProductSetting ps WITH(NOLOCK)
			INNER JOIN Dep_ProductSettingDetail psd WITH(NOLOCK) ON ps.ProductSettingID = psd.ProductSettingID
			INNER JOIN #Sports s WITH(NOLOCK) ON psd.SportType = s.SportType
			INNER JOIN #Bettype b WITH(NOLOCK) ON psd.BetType = b.typeid
		WHERE (ps.SettingType IN (2,7,8,10,11,12)) 
			AND (@ProductID = 0 OR ps.ProductID = @ProductID) 
			AND (@pMutilSportType = '0' OR psd.SportType IN (SELECT RTRIM(LTRIM(value)) val FROM STRING_SPLIT(@pMutilSportType, ',')))
			AND @pMutilCurrencyDeposit<>'' AND psd.SettingStatus<>2
	) KQ
	ORDER BY SportType,BetType

	--SettingType IN (7,8,17)
	IF EXISTS (SELECT 1 FROM #ProductSettingDetail WHERE SettingType IN (7,8,17))
	BEGIN
		INSERT INTO #BetLimit(SportType, SportName,BetType, typenamee,ExchangeIdCredit,ExchangeIdDeposit,
								CurMinBet,CurMaxBet,GameGroupID, SiteID)
		-- Credit Stakelevel							
		SELECT a.SportType,a.SportName,a.BetType,a.typenamee,s.ExchangeId,0 AS ExchangeIdDeposit, 
			  s.MinStake AS CurMinBet, S.MaxStake AS CurMaxBet, S.GameGroupID, 0 AS SiteID
		FROM #ProductSettingDetail a
		INNER JOIN StakeLevel s WITH(NOLOCK) ON s.GameTypeID = a.BetType
		WHERE a.SettingType IN ( 7, 17) 
			AND a.IsCredit = 1 
			AND (@pMutilCurrencyCredit = '0' OR s.ExchangeId IN (SELECT RTRIM(LTRIM(value)) val FROM STRING_SPLIT(@pMutilCurrencyCredit, ',')))
			AND (@pMutilBetType = '0' OR s.GameTypeID IN (SELECT RTRIM(LTRIM(value)) val FROM STRING_SPLIT(@pMutilBetType, ',')))
		UNION ALL -- Credit Group Stakelevel	
		SELECT a.SportType,a.SportName,slg.GameTypeID AS BetType,b.typenamee,s.ExchangeId,0 AS ExchangeIdDeposit, 
			  slg.MinStake AS CurMinBet, slg.MaxStake AS CurMaxBet, S.GameGroupID, 0 AS SiteID
		FROM #ProductSettingDetail a
		INNER JOIN StakeLevel s WITH(NOLOCK) ON s.GameTypeID = a.BetType
		INNER JOIN StakeLevelGroupDetail slg WITH(NOLOCK) ON s.StakeLevelID = slg.StakeLevelID
		INNER JOIN #Bettype b WITH(NOLOCK) ON slg.GameTypeID = b.typeid
		WHERE a.SettingType IN (8) 
			AND a.IsCredit = 1 
			AND (@pMutilCurrencyCredit = '0' OR s.ExchangeId IN (SELECT val FROM dbo.strSplit(@pMutilCurrencyCredit, ',')))
			AND (@pMutilBetType = '0' OR slg.GameTypeID IN (SELECT val FROM dbo.strSplit(@pMutilBetType, ',')))
		UNION ALL -- Deposit Stakelevel
		SELECT a.SportType,a.SportName,a.BetType,a.typenamee,0 AS ExchangeIdCredit,s.ExchangeId AS ExchangeIdDeposit, 
			  s.MinStake AS CurMinBet, S.MaxStake AS CurMaxBet, S.GameGroupID, s.SiteID AS SiteID
		FROM #ProductSettingDetail a
		INNER JOIN Dep_StakeLevel s WITH(NOLOCK) ON s.GameTypeID = a.BetType
		WHERE a.SettingType IN ( 7) 
			AND a.IsCredit = 0 
			AND (@pMutilCurrencyDeposit = '0' OR s.ExchangeId IN (SELECT RTRIM(LTRIM(value)) val FROM STRING_SPLIT(@pMutilCurrencyDeposit, ',')))
			AND (@pMutilBetType = '0' OR s.GameTypeID IN (SELECT RTRIM(LTRIM(value)) val FROM STRING_SPLIT(@pMutilBetType, ',')))
		UNION ALL -- Deposit Group Stakelevel
		SELECT a.SportType,a.SportName,slg.GameTypeID AS BetType,b.typenamee,0 AS ExchangeIdCredit,s.ExchangeId AS ExchangeIdDeposit, 
			  slg.MinStake AS CurMinBet, slg.MaxStake AS CurMaxBet, S.GameGroupID, 0 AS SiteID
		FROM #ProductSettingDetail a
		INNER JOIN Dep_StakeLevel s WITH(NOLOCK) ON s.GameTypeID = a.BetType
		INNER JOIN Dep_StakeLevelGroupDetail slg WITH(NOLOCK) ON s.StakeLevelID = slg.StakeLevelID
		INNER JOIN #Bettype b WITH(NOLOCK) ON slg.GameTypeID = b.typeid
		WHERE a.SettingType IN (8) 
			AND a.IsCredit = 0 
			AND (@pMutilCurrencyDeposit = '0' OR s.ExchangeId IN (SELECT RTRIM(LTRIM(value)) val FROM STRING_SPLIT(@pMutilCurrencyDeposit, ',')))
			AND (@pMutilBetType = '0' OR slg.GameTypeID IN (SELECT RTRIM(LTRIM(value)) val FROM STRING_SPLIT(@pMutilBetType, ',')))

		DELETE #ProductSettingDetail WHERE SettingType IN (7,8,17)
	END

	--SettingType NOT IN (7,8,17)
	--CREDIT: 
	IF EXISTS (SELECT 1 FROM #ProductSettingDetail WHERE SettingType NOT IN (7,8,17))
	BEGIN
		INSERT INTO #BetLimit(SportType, SportName, BetType, typenamee
							, ExchangeIdCredit, ExchangeIdDeposit
							, CurMinBet, CurMaxBet, CurMaxPerMatch, CurMaxPerBall
							, SiteID)
		-- Credit: exclude: Sportsbook, Number Game, Happy 5, RNG Keno.
		SELECT a.SportType, a.SportName, a.BetType, a.typenamee, pbs.Currency, 0 AS ExchangeIdDeposit
			, pbs.MinBet AS CurMinBet, pbs.MaxBet AS CurMaxBet
			, CASE WHEN (A.SportType IN (199, 220, 222, 169, 175, 217, 218) OR 
						(A.SportType BETWEEN 180 AND 186)	OR	
						(A.SportType BETWEEN 213 AND 215)	OR	
						(A.SportType BETWEEN 190 AND 197)) THEN pbs.MaxPerMatch END AS CurMaxPerMatch
			, NULL AS CurMaxPerBall
			, 0 AS SiteID
		FROM #ProductSettingDetail a
			INNER JOIN ProductBetSetting pbs WITH (NOLOCK) ON pbs.Sporttype=a.SportType AND pbs.Bettype=a.BetType
		WHERE a.SettingType NOT IN (7,8,17)
			AND a.IsCredit = 1 
			AND (@pMutilCurrencyCredit = '0' OR pbs.Currency IN (SELECT RTRIM(LTRIM(value)) val FROM STRING_SPLIT(@pMutilCurrencyCredit, ',')))
			AND (@pMutilBetType = '0' OR pbs.Bettype IN (SELECT RTRIM(LTRIM(value)) val FROM STRING_SPLIT(@pMutilBetType, ',')))
			AND a.SportType NOT IN (161,164,168,202,1) 
		UNION ALL
		-- Deposit
		SELECT a.SportType, a.SportName, a.BetType, a.typenamee, 0 AS ExchangeIdCredit, pbs.Currency
			, pbs.MinBet AS CurMinBet, pbs.MaxBet AS CurMaxBet
			, CASE WHEN (A.SportType IN (1, 161, 164, 168, 202, 199, 220, 222, 169, 175, 217, 218) OR 
						(A.SportType BETWEEN 180 AND 186)	OR	
						(A.SportType BETWEEN 213 AND 215)	OR	
						(A.SportType BETWEEN 190 AND 197)) THEN pbs.MaxPerMatch END AS CurMaxPerMatch
			, CASE WHEN A.SportType=161 THEN pbs.MaxPerBall END AS CurMaxPerBall
			, 0 AS SiteID
		FROM #ProductSettingDetail a
			INNER JOIN Dep_ProductBetSetting pbs WITH (NOLOCK) ON pbs.Sporttype=a.SportType AND pbs.Bettype=a.BetType
		WHERE a.SettingType NOT IN (7,8,17)
			AND a.IsCredit = 0
			AND (@pMutilCurrencyDeposit = '0' OR pbs.Currency IN (SELECT RTRIM(LTRIM(value)) val FROM STRING_SPLIT(@pMutilCurrencyDeposit, ',')))
			AND (@pMutilBetType = '0' OR pbs.Bettype IN (SELECT RTRIM(LTRIM(value)) val FROM STRING_SPLIT(@pMutilBetType, ',')))
	END
	
	--ExportData
	IF @ExportData = 1
	BEGIN
		SELECT SportType, SportName, BetType, typenamee, ExchangeIdCredit, ExchangeIdDeposit 
			, CurMinBet, CurMaxBet, CurMaxPerMatch, CurMaxPerBall
			, NewMinBet, NewMaxBet, NewMaxPerMatch, NewMaxPerBall
			, GameGroupID, ec.currency AS CurrencyCredit, eD.currency AS CurrencyDeposit, t.SiteID, s.site
		FROM #BetLimit t
		 LEFT JOIN Exchange eC WITH(NOLOCK)  ON t.ExchangeIdCredit = eC.ExchangeId
		 LEFT JOIN Exchange eD WITH(NOLOCK)  ON t.ExchangeIdDeposit = eD.ExchangeId
		 LEFT JOIN Site s WITH(NOLOCK)  ON t.SiteID = s.siteid
		ORDER by SportType desc, BetType,ExchangeIdCredit DESC,ExchangeIdDeposit,GameGroupID	
	END
	ELSE
	BEGIN
		SELECT @TotalRows = COUNT(1)
		FROM #BetLimit

		SELECT SportType, SportName, BetType, typenamee, ExchangeIdCredit, ExchangeIdDeposit 
			, CurMinBet, CurMaxBet, CurMaxPerMatch, CurMaxPerBall
			, NewMinBet, NewMaxBet, NewMaxPerMatch, NewMaxPerBall
			, GameGroupID, ec.currency AS CurrencyCredit, eD.currency AS CurrencyDeposit, t.SiteID, s.site
		FROM (
			SELECT ROW_NUMBER() OVER(ORDER by SportType desc, BetType,ExchangeIdCredit DESC,ExchangeIdDeposit,GameGroupID) rn, *
			FROM #BetLimit
		   )t
		 LEFT JOIN Exchange eC WITH(NOLOCK)  ON t.ExchangeIdCredit = eC.ExchangeId
		 LEFT JOIN Exchange eD WITH(NOLOCK)  ON t.ExchangeIdDeposit = eD.ExchangeId
		 LEFT JOIN Site s WITH(NOLOCK)  ON t.SiteID = s.siteid
		WHERE rn BETWEEN @RowStart AND @RowEnd
	END	

	DROP TABLE #BetLimit
	DROP TABLE #Bettype
	DROP TABLE #ProductSettingDetail
	DROP TABLE #Sports
END
GO