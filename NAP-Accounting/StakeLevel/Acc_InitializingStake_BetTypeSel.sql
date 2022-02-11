/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_InitializingStake_BetTypeSel] 
	-- Add the parameters for the stored procedure here
	  @ProductID			TINYINT
	  ,@pMutilSportType		VARCHAR(Max) = ''
	  ,@pMutilBettypeType	VARCHAR(Max) = ''
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
	
	CREATE TABLE #Bettype (typeid INT PRIMARY KEY, typenamee NVARCHAR(128))

	INSERT INTO #Bettype  (typeid,typenamee)	
	SELECT typeid,typenamee 
	FROM DBACC.bodb02.dbo.Bettype WITH(NOLOCK)
				
	SELECT DISTINCT
		 psd.BetType
		 ,b.typenamee 
	FROM ProductSettingDetail psd WITH(NOLOCK)
		INNER JOIN #Bettype b WITH(NOLOCK) ON psd.BetType = b.typeid
	WHERE (psd.SettingType IN (7, 8, 17)) 
		AND (@ProductID = 0 OR psd.ProductID = @ProductID) 
		AND (@pMutilSportType = '0' OR psd.SportType IN (SELECT val FROM dbo.strSplit(@pMutilSportType, ',')))
		AND (@pMutilBettypeType = '0' OR psd.BetType IN (SELECT val FROM dbo.strSplit(@pMutilBettypeType, ',')))
	ORDER BY psd.BetType
   
   DROP TABLE #Bettype
END
GO
