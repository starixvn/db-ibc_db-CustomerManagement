/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_InitializingStake_SportTypeSel] 
	-- Add the parameters for the stored procedure here
	  @ProductID		TINYINT
	  ,@pMutilSportType	VARCHAR(Max) = ''
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
	
	CREATE TABLE #Sports(SportType TINYINT PRIMARY KEY, SportName NVARCHAR(50))

	INSERT INTO #Sports  (SportType,SportName)	
	SELECT SportType,SportName 
	FROM DBACC.bodb02.dbo.Sports WITH(NOLOCK)
	
	SELECT SportType , SportName
	FROM (			
		SELECT DISTINCT
			 psd.SportType
			 ,s.SportName
		FROM ProductSettingDetail psd WITH(NOLOCK)
			INNER JOIN #Sports s WITH(NOLOCK) ON psd.SportType = s.SportType
		WHERE (@ProductID = 0 OR psd.ProductID = @ProductID) AND (@pMutilSportType = '0' OR psd.SportType IN (SELECT val FROM dbo.strSplit(@pMutilSportType, ',')))
			AND (psd.SettingType IN (7, 8, 17))
		UNION
		SELECT DISTINCT
			 psd.SportType
			 ,s.SportName
		FROM Dep_ProductSetting ps WITH(NOLOCK)
			INNER JOIN Dep_ProductSettingDetail psd WITH(NOLOCK) ON ps.ProductSettingID = psd.ProductSettingID
			INNER JOIN #Sports s WITH(NOLOCK) ON psd.SportType = s.SportType
		WHERE (@ProductID = 0 OR ps.ProductID = @ProductID) AND (@pMutilSportType = '0' OR psd.SportType IN (SELECT val FROM dbo.strSplit(@pMutilSportType, ',')))
			AND (ps.SettingType IN (7, 8))	
	) KQ
	ORDER BY SportType, SportName
   
   DROP TABLE #Sports
END
GO
