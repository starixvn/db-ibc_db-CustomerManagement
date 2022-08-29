/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_InitializingGlobal_SportTypeSel] 
	-- Add the parameters for the stored procedure here
	  @ProductID		TINYINT
	  ,@pMutilSportType	VARCHAR(Max) = ''
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
	
	CREATE TABLE #Sports(SportType TINYINT PRIMARY KEY, SportName NVARCHAR(50))

	INSERT INTO #Sports  (SportType,SportName)	
	SELECT SportType,SportName 
	FROM dbo.Sports WITH(NOLOCK)
	
	SELECT SportType , SportName
	FROM (			
		SELECT DISTINCT
			 psd.SportType
			 ,s.SportName
		FROM ProductSettingDetail psd WITH(NOLOCK)
			INNER JOIN #Sports s WITH(NOLOCK) ON psd.SportType = s.SportType
		WHERE (@ProductID = 0 OR psd.ProductID = @ProductID) AND (@pMutilSportType = '0' OR psd.SportType IN (SELECT RTRIM(LTRIM(value)) val FROM STRING_SPLIT(@pMutilSportType, ',')))
			AND (psd.SettingType IN (2,7,8,9,16,17,20))
			AND psd.ProductID NOT IN (1,3,8)
			AND psd.SettingStatus<>2
		UNION
		SELECT DISTINCT
			 psd.SportType
			 ,s.SportName
		FROM Dep_ProductSetting ps WITH(NOLOCK)
			INNER JOIN Dep_ProductSettingDetail psd WITH(NOLOCK) ON ps.ProductSettingID = psd.ProductSettingID
			INNER JOIN #Sports s WITH(NOLOCK) ON psd.SportType = s.SportType
		WHERE (@ProductID = 0 OR ps.ProductID = @ProductID) AND (@pMutilSportType = '0' OR psd.SportType IN (SELECT RTRIM(LTRIM(value)) val FROM STRING_SPLIT(@pMutilSportType, ',')))
			AND (ps.SettingType IN (2,7,8,10,11,12))	
			AND psd.SettingStatus<>2
	) KQ
	ORDER BY SportType, SportName
   
   DROP TABLE #Sports
END
GO
