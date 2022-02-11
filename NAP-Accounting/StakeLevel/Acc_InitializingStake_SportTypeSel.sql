/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_InitializingStake_SportTypeSel] 
	-- Add the parameters for the stored procedure here
	  @ProductID		TINYINT
	  ,@pMutilSportType	VARCHAR(Max) = ''
AS
BEGIN
	/*
		Task : NAP -  Flexible Initializing Stake Level
		DB: DBCUST/CustDB
		Original: 
		Revisions:
			- 20220210@Winfred: NAP -  Flexible Initializing Stake Level [Redmine: #167128]
	*/
	SET NOCOUNT ON;
	--@ProductID  0 : All, <> 0 : ProductID
	--@SportType  0 : All, <> 0 : SportType
	
	CREATE TABLE #Sports(SportType TINYINT PRIMARY KEY, SportName NVARCHAR(50))

	INSERT INTO #Sports  (SportType,SportName)	
	SELECT SportType,SportName 
	FROM DBACC.bodb02.dbo.Sports WITH(NOLOCK)
				
	SELECT DISTINCT
		 psd.SportType
		 ,s.SportName
	FROM ProductSettingDetail psd WITH(NOLOCK)
		INNER JOIN #Sports s WITH(NOLOCK) ON psd.SportType = s.SportType
	WHERE (@ProductID = 0 OR psd.ProductID = @ProductID) AND (@pMutilSportType = '0' OR psd.SportType IN (SELECT val FROM dbo.strSplit(@pMutilSportType, ',')))
		AND (psd.SettingType IN (7, 8, 17))
	ORDER BY psd.SportType, s.SportName
   
   DROP TABLE #Sports
END
GO
