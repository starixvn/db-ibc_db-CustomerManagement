/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_InitializingStake_BetTypeSel] 
	-- Add the parameters for the stored procedure here
	  @ProductID			TINYINT
	  ,@pMutilSportType		VARCHAR(Max) = ''
	  ,@pMutilBettypeType	VARCHAR(Max) = ''
AS
/*
		Task : NAP -  Flexible Initializing Stake Level
		DB: DBCUST/CustDB
		Original: 
		Revisions:
			- 20220210@Winfred: NAP -  Flexible Initializing Stake Level [Redmine: #167128]
		
		Param's Explanation:
			@ProductID  0 : All, <> 0 : ProductID
			@SportType  0 : All, <> 0 : SportType
	*/
BEGIN
	SET NOCOUNT ON;
	
	CREATE TABLE #Bettype (typeid INT PRIMARY KEY, typenamee NVARCHAR(128))

	INSERT INTO #Bettype  (typeid,typenamee)	
	SELECT typeid,typenamee 
	FROM DBACC.bodb02.dbo.Bettype WITH(NOLOCK)
	
	SELECT BetType , typenamee
	FROM (				
		SELECT DISTINCT
			 psd.BetType
			 ,b.typenamee 
		FROM ProductSettingDetail psd WITH(NOLOCK)
			INNER JOIN #Bettype b WITH(NOLOCK) ON psd.BetType = b.typeid
		WHERE (psd.SettingType IN (7, 8, 17)) 
			AND (@ProductID = 0 OR psd.ProductID = @ProductID) 
			AND (@pMutilSportType = '0' OR psd.SportType IN (SELECT val FROM dbo.strSplit(@pMutilSportType, ',')))
			AND (@pMutilBettypeType = '0' OR psd.BetType IN (SELECT val FROM dbo.strSplit(@pMutilBettypeType, ',')))
		UNION
		SELECT DISTINCT
			 psd.BetType
			 ,b.typenamee 
		FROM Dep_ProductSetting ps WITH(NOLOCK)
			INNER JOIN Dep_ProductSettingDetail psd WITH(NOLOCK) ON ps.ProductSettingID = psd.ProductSettingID
			INNER JOIN #Bettype b WITH(NOLOCK) ON psd.BetType = b.typeid
		WHERE (ps.SettingType IN (7, 8)) 
			AND (@ProductID = 0 OR ps.ProductID = @ProductID) 
			AND (@pMutilSportType = '0' OR psd.SportType IN (SELECT val FROM dbo.strSplit(@pMutilSportType, ',')))
			AND (@pMutilBettypeType = '0' OR psd.BetType IN (SELECT val FROM dbo.strSplit(@pMutilBettypeType, ',')))
			) KQ
	ORDER BY BetType
   
   DROP TABLE #Bettype
END
GO
