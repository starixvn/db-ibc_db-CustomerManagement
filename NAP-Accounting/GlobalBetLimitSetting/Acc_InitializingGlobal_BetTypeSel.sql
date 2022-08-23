/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_InitializingGlobal_BetTypeSel] 
	-- Add the parameters for the stored procedure here
	  @ProductID			TINYINT
	  ,@pMutilSportType		VARCHAR(Max) = ''
	  ,@pMutilBettypeType	VARCHAR(Max) = ''
AS
/*
		Task : NAP -  Flexible Initializing Stake Level/Bet Limit
		DB: DBACC/bodb02
		Original: 
		Revisions:
			- 20220210@Winfred: NAP -  Flexible Initializing Stake Level [Redmine: #167128]
			- 20220705@Tacy: NAP - Flexible Initializing Global Bet Limit [Redmine: #174509]
		
		Param's Explanation:
			@ProductID  0 : All, <> 0 : ProductID
			@SportType  0 : All, <> 0 : SportType
	*/
BEGIN
	SET NOCOUNT ON;
	
	CREATE TABLE #Bettype (typeid INT PRIMARY KEY, typenamee NVARCHAR(128))

	INSERT INTO #Bettype  (typeid,typenamee)	
	SELECT typeid,typenamee 
	FROM dbo.Bettype WITH(NOLOCK)
	
	SELECT BetType , typenamee
	FROM (				
		SELECT DISTINCT
			 psd.BetType
			 ,b.typenamee 
		FROM ProductSettingDetail psd WITH(NOLOCK)
			INNER JOIN ProductBetSetting pb WITH (NOLOCK) ON pb.Bettype=psd.BetType AND pb.Sporttype=psd.SportType
			INNER JOIN #Bettype b WITH(NOLOCK) ON psd.BetType = b.typeid
		WHERE (psd.SettingType IN (2,7,9,16,17,20)) 
			AND (@ProductID = 0 OR psd.ProductID = @ProductID) 
			AND (@pMutilSportType = '0' OR psd.SportType IN (SELECT val FROM dbo.strSplit(@pMutilSportType, ',')))
			AND (@pMutilBettypeType = '0' OR psd.BetType IN (SELECT val FROM dbo.strSplit(@pMutilBettypeType, ',')))
			AND (psd.ProductID NOT IN (1,3,8) OR psd.SportType NOT IN (161,164,168,202,1))
		UNION
		SELECT DISTINCT
			 slg.GameTypeID AS BetType
			 ,b.typenamee 
		FROM ProductSettingDetail psd WITH(NOLOCK)
			INNER JOIN StakeLevel sl WITH(NOLOCK) ON psd.BetType = sl.GameTypeID
			INNER JOIN StakeLevelGroupDetail slg WITH(NOLOCK) ON sl.StakeLevelID = slg.StakeLevelID
			INNER JOIN #Bettype b WITH(NOLOCK) ON slg.GameTypeID = b.typeid
		WHERE (psd.SettingType IN (8)) 
			AND (@ProductID = 0 OR psd.ProductID = @ProductID) 
			AND (@pMutilSportType = '0' OR psd.SportType IN (SELECT val FROM dbo.strSplit(@pMutilSportType, ',')))
			AND (@pMutilBettypeType = '0' OR psd.BetType IN (SELECT val FROM dbo.strSplit(@pMutilBettypeType, ',')))
		UNION
		SELECT DISTINCT
			 psd.BetType
			 ,b.typenamee 
		FROM Dep_ProductSetting ps WITH(NOLOCK)
			INNER JOIN Dep_ProductSettingDetail psd WITH(NOLOCK) ON ps.ProductSettingID = psd.ProductSettingID
			INNER JOIN Dep_ProductBetSetting pb WITH (NOLOCK) ON pb.Bettype=psd.BetType AND pb.Sporttype=psd.SportType
			INNER JOIN #Bettype b WITH(NOLOCK) ON psd.BetType = b.typeid
		WHERE (ps.SettingType IN (2,7,10,11,12)) 
			AND (@ProductID = 0 OR ps.ProductID = @ProductID) 
			AND (@pMutilSportType = '0' OR psd.SportType IN (SELECT val FROM dbo.strSplit(@pMutilSportType, ',')))
			AND (@pMutilBettypeType = '0' OR psd.BetType IN (SELECT val FROM dbo.strSplit(@pMutilBettypeType, ',')))
		UNION
		SELECT DISTINCT
			 slg.GameTypeID AS BetType
			 ,b.typenamee 
		FROM Dep_ProductSetting ps WITH(NOLOCK)
			INNER JOIN Dep_ProductSettingDetail psd WITH(NOLOCK) ON ps.ProductSettingID = psd.ProductSettingID
			INNER JOIN Dep_StakeLevel sl WITH(NOLOCK) ON psd.BetType = sl.GameTypeID
			INNER JOIN Dep_StakeLevelGroupDetail slg WITH(NOLOCK) ON sl.StakeLevelID = slg.StakeLevelID
			INNER JOIN #Bettype b WITH(NOLOCK) ON slg.GameTypeID = b.typeid
		WHERE (ps.SettingType IN (8)) 
			AND (@ProductID = 0 OR ps.ProductID = @ProductID) 
			AND (@pMutilSportType = '0' OR psd.SportType IN (SELECT val FROM dbo.strSplit(@pMutilSportType, ',')))
			AND (@pMutilBettypeType = '0' OR psd.BetType IN (SELECT val FROM dbo.strSplit(@pMutilBettypeType, ',')))	
			) KQ
	ORDER BY BetType
   
   DROP TABLE #Bettype
END
GO
