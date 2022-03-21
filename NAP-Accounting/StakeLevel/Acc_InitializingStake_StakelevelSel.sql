/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_InitializingStake_StakelevelSel] 
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
		Task : NAP -  Flexible Initializing Stake Level
		DB: DBACC/bodb02
		Original: 
		Revisions:
			- 20220210@Winfred: NAP -  Flexible Initializing Stake Level [Redmine: #167128]
		
		Param's Explanation:
			@ProductID		  0 : All, <> 0 : ProductID
			@pMutilSportType	  0 : All, <> 0 : SportType
			@pMutilBetType  0 : All, <> 0 : Bettype
			@pMutilCurrencyCredit  0 : All, <> 0 : Currency Credit
			@pMutilCurrencyDeposit  0 : All, <> 0 : Currency Deposit
			@ExportData  0 : Pages, <> 0 : All data

	*/
BEGIN
	
	SET NOCOUNT ON;
	
	DECLARE @rowstart INT,@rowend INT
	SELECT @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1 	
	
	CREATE TABLE #Bettype (typeid INT PRIMARY KEY, typenamee NVARCHAR(128))
	CREATE TABLE #Sports(SportType TINYINT PRIMARY KEY, SportName NVARCHAR(50))
	CREATE TABLE #ProductSettingDetail(SportType TINYINT , SportName NVARCHAR(50),BetType INT, typenamee NVARCHAR(128),SettingType SMALLINT,IsCredit BIT Default((0)))
	CREATE TABLE #StakeLevel(SportType TINYINT , SportName NVARCHAR(50),BetType INT, typenamee NVARCHAR(128),
							ExchangeIdCredit INT,ExchangeIdDeposit INT,NewMinStake	DECIMAL(19,8),NewMaxStake DECIMAL(19,8),
							CurMinStake	DECIMAL(19,8),CurMaxStake DECIMAL(19,8),GameGroupID	INT, SiteID	INT )
		
	INSERT INTO #Sports  (SportType,SportName)	
	SELECT SportType,SportName 
	FROM dbo.Sports WITH(NOLOCK)
	
	INSERT INTO #Bettype  (typeid,typenamee)	
	SELECT typeid,typenamee 
	FROM dbo.Bettype WITH(NOLOCK)

	INSERT INTO #ProductSettingDetail(SportType,SportName,BetType,typenamee,SettingType,IsCredit)				
	SELECT SportType,SportName,BetType,typenamee,SettingType,IsCredit
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
		WHERE (psd.SettingType IN (7, 8, 17)) 
			AND (@ProductID = 0 OR psd.ProductID = @ProductID) 
			AND (@pMutilSportType = '0' OR psd.SportType IN (SELECT val FROM dbo.strSplit(@pMutilSportType, ',')))
		UNION ALL
		SELECT DISTINCT
			  psd.BetType
			 ,b.typenamee 
			 ,psd.SportType
			 ,s.SportName
			 , ps.SettingType
			 ,0 AS IsCredit
		FROM Dep_ProductSetting ps WITH(NOLOCK)
			INNER JOIN Dep_ProductSettingDetail psd WITH(NOLOCK) ON ps.ProductSettingID = psd.ProductSettingID
			INNER JOIN #Sports s WITH(NOLOCK) ON psd.SportType = s.SportType
			INNER JOIN #Bettype b WITH(NOLOCK) ON psd.BetType = b.typeid
		WHERE (ps.SettingType IN (7, 8)) 
			AND (@ProductID = 0 OR ps.ProductID = @ProductID) 
			AND (@pMutilSportType = '0' OR psd.SportType IN (SELECT val FROM dbo.strSplit(@pMutilSportType, ',')))
	) KQ
	ORDER BY SportType,BetType
   
	INSERT INTO #StakeLevel(SportType, SportName ,BetType, typenamee ,ExchangeIdCredit ,ExchangeIdDeposit ,
							NewMinStake ,NewMaxStake ,CurMinStake ,CurMaxStake ,GameGroupID, SiteID)
	-- Credit Stakelevel							
	SELECT a.SportType,a.SportName,a.BetType,a.typenamee,s.ExchangeId,0 AS ExchangeIdDeposit, 
		  0 AS NewMinStake, 0 AS NewMaxStake, s.MinStake AS CurMinStake, S.MaxStake AS CurMaxStake, S.GameGroupID, 0 AS SiteID
	FROM #ProductSettingDetail a
	INNER JOIN StakeLevel s WITH(NOLOCK) ON s.GameTypeID = a.BetType
	WHERE a.SettingType IN ( 7 , 17) 
		AND a.IsCredit = 1 
		AND (@pMutilCurrencyCredit = '0' OR s.ExchangeId IN (SELECT val FROM dbo.strSplit(@pMutilCurrencyCredit, ',')))
		AND (@pMutilBetType = '0' OR s.GameTypeID IN (SELECT val FROM dbo.strSplit(@pMutilBetType, ',')))
	UNION ALL -- Credit Group Stakelevel	
	SELECT a.SportType,a.SportName,slg.GameTypeID AS BetType,b.typenamee,s.ExchangeId,0 AS ExchangeIdDeposit, 
		  0 AS NewMinStake, 0 AS NewMaxStake, slg.MinStake AS CurMinStake, slg.MaxStake AS CurMaxStake, S.GameGroupID, 0 AS SiteID
	FROM #ProductSettingDetail a
	INNER JOIN StakeLevel s WITH(NOLOCK) ON s.GameTypeID = a.BetType
	INNER JOIN StakeLevelGroupDetail slg WITH(NOLOCK) ON s.StakeLevelID = slg.StakeLevelID
	INNER JOIN #Bettype b WITH(NOLOCK) ON slg.GameTypeID = b.typeid
	WHERE a.SettingType IN (8) 
		AND a.IsCredit = 1 
		AND (@pMutilCurrencyCredit = '0' OR s.ExchangeId IN (SELECT val FROM dbo.strSplit(@pMutilCurrencyCredit, ',')))
		AND (@pMutilBetType = '0' OR s.GameTypeID IN (SELECT val FROM dbo.strSplit(@pMutilBetType, ',')))
	UNION ALL -- Deposit Stakelevel
	SELECT a.SportType,a.SportName,a.BetType,a.typenamee,0 AS ExchangeIdCredit,s.ExchangeId AS ExchangeIdDeposit, 
		  0 AS NewMinStake, 0 AS NewMaxStake, s.MinStake AS CurMinStake, S.MaxStake AS CurMaxStake, S.GameGroupID, s.SiteID AS SiteID
	FROM #ProductSettingDetail a
	INNER JOIN Dep_StakeLevel s WITH(NOLOCK) ON s.GameTypeID = a.BetType
	WHERE a.SettingType IN ( 7) 
		AND a.IsCredit = 0 
		AND (@pMutilCurrencyDeposit = '0' OR s.ExchangeId IN (SELECT val FROM dbo.strSplit(@pMutilCurrencyDeposit, ',')))
		AND (@pMutilBetType = '0' OR s.GameTypeID IN (SELECT val FROM dbo.strSplit(@pMutilBetType, ',')))
	UNION ALL -- Deposit Group Stakelevel
	SELECT a.SportType,a.SportName,slg.GameTypeID AS BetType,b.typenamee,0 AS ExchangeIdCredit,s.ExchangeId AS ExchangeIdDeposit, 
		  0 AS NewMinStake, 0 AS NewMaxStake, slg.MinStake AS CurMinStake, slg.MaxStake AS CurMaxStake, S.GameGroupID, 0 AS SiteID
	FROM #ProductSettingDetail a
	INNER JOIN Dep_StakeLevel s WITH(NOLOCK) ON s.GameTypeID = a.BetType
	INNER JOIN Dep_StakeLevelGroupDetail slg WITH(NOLOCK) ON s.StakeLevelID = slg.StakeLevelID
	INNER JOIN #Bettype b WITH(NOLOCK) ON slg.GameTypeID = b.typeid
	WHERE a.SettingType IN (8) 
		AND a.IsCredit = 0 
		AND (@pMutilCurrencyDeposit = '0' OR s.ExchangeId IN (SELECT val FROM dbo.strSplit(@pMutilCurrencyDeposit, ',')))
		AND (@pMutilBetType = '0' OR s.GameTypeID IN (SELECT val FROM dbo.strSplit(@pMutilBetType, ',')))
	IF @ExportData = 1
	BEGIN
		
		SELECT SportType, SportName ,BetType, typenamee ,ExchangeIdCredit ,ExchangeIdDeposit ,
			  NewMinStake ,NewMaxStake ,CurMinStake ,CurMaxStake ,GameGroupID, ec.currency AS CurrencyCredit, eD.currency AS CurrencyDeposit, t.SiteID, s.site
		FROM #StakeLevel t
		 LEFT JOIN Exchange eC WITH(NOLOCK)  ON t.ExchangeIdCredit = eC.ExchangeId
		 LEFT JOIN Exchange eD WITH(NOLOCK)  ON t.ExchangeIdDeposit = eD.ExchangeId
		 LEFT JOIN Site s WITH(NOLOCK)  ON t.SiteID = s.siteid
		ORDER by SportType desc, BetType,ExchangeIdCredit DESC ,ExchangeIdDeposit ,GameGroupID	
	END
	ELSE
	BEGIN
		SELECT @TotalRows = COUNT(1)
		FROM #StakeLevel

		SELECT SportType, SportName ,BetType, typenamee ,ExchangeIdCredit ,ExchangeIdDeposit ,
			  NewMinStake ,NewMaxStake ,CurMinStake ,CurMaxStake ,GameGroupID, ec.currency AS CurrencyCredit, eD.currency AS CurrencyDeposit, t.SiteID, s.site
		FROM(
			SELECT ROW_NUMBER() OVER(ORDER by SportType desc, BetType,ExchangeIdCredit DESC ,ExchangeIdDeposit ,GameGroupID) rn, *
			FROM #StakeLevel
		   )t
		 LEFT JOIN Exchange eC WITH(NOLOCK)  ON t.ExchangeIdCredit = eC.ExchangeId
		 LEFT JOIN Exchange eD WITH(NOLOCK)  ON t.ExchangeIdDeposit = eD.ExchangeId
		 LEFT JOIN Site s WITH(NOLOCK)  ON t.SiteID = s.siteid
		WHERE rn BETWEEN @RowStart AND @RowEnd
	END	
	
   DROP TABLE #Bettype
   DROP TABLE #Sports 
   DROP TABLE #ProductSettingDetail 
   DROP TABLE #StakeLevel
END
GO
