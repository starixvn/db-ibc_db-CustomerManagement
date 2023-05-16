/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_ReferenceSetting_BetTypeSel] 
	-- Add the parameters for the stored procedure here
	  @pMutilProductID	VARCHAR(Max)='',
	  @pMutilSportType	VARCHAR(Max)='',
	  @pMutilBetType	VARCHAR(Max)=''
AS
/*
	Task : NAP - New function to manage SportBettypeSettingMatrix table
	DB: DBTP/bodb02
	Original: 
	Revisions:
		- 20230301@Tacy: Create SP [Redmine: #184255] 
		
	Param's Explanation:
		@pMutilProductID  0 : All, <> 0 : ProductID

	Example:
		EXEC [Acc_ReferenceSetting_BetTypeSel] @pMutilProductID='1', @pMutilSportType='43',@pMutilBetType='0'
*/
BEGIN
	SET NOCOUNT ON;

	IF @pMutilProductID='' OR @pMutilSportType='' OR @pMutilBetType=''
		RETURN

	CREATE TABLE #Products(
			ProductID	SMALLINT PRIMARY KEY, 
			ProductName NVARCHAR(50)
	)

	CREATE TABLE #Sports(
			SportType SMALLINT PRIMARY KEY, 
			SportName NVARCHAR(50)
	)
	
	CREATE TABLE #Bettype (
			BetType INT PRIMARY KEY, 
			typenamee NVARCHAR(128)
	)

	INSERT INTO #Products (ProductID, ProductName)
	SELECT ProductID, ProductName
	FROM Products WITH (NOLOCK)
	WHERE Enabled=1
	AND ProductID IN (SELECT TRIM(value) val FROM STRING_SPLIT(@pMutilProductID, ','))

	INSERT INTO #Sports (SportType, SportName)	
	EXEC Acc_SporttypeSel @Mode=1
	
	DELETE FROM #Sports
	WHERE SportType NOT IN (SELECT TRIM(value) val FROM STRING_SPLIT(@pMutilSportType, ','))

	INSERT INTO #Bettype (BetType, typenamee)	
	SELECT typeid,typenamee 
	FROM dbo.Bettype WITH(NOLOCK)
	WHERE @pMutilBetType='0' OR typeid IN (SELECT TRIM(value) val FROM STRING_SPLIT(@pMutilBetType, ','))

	SELECT b.BetType, b.typenamee
	FROM #Bettype b
	CROSS APPLY (SELECT TOP 1 1 value
				 FROM SportBettypeSettingMatrix sm WITH (NOLOCK)
					INNER JOIN #Products p WITH (NOLOCK) ON p.ProductID=sm.RealProductId
					INNER JOIN #Sports s WITH (NOLOCK) ON s.SportType=sm.SportType
				 WHERE sm.BetType=b.BetType) sm
	ORDER BY b.BetType
   
   DROP TABLE #Bettype,#Products,#Sports
END
GO