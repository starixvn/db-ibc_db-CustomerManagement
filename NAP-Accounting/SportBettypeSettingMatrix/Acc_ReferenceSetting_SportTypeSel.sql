/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet,wsv_nap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_ReferenceSetting_SportTypeSel] 
	-- Add the parameters for the stored procedure here
	  @pMutilProductID	VARCHAR(Max)='',
	  @pMutilSportType	VARCHAR(Max)=''
AS
/*
	Task : NAP - New function to manage SportBettypeSettingMatrix table
	DB: DBACC/bodb02
	Original: 
	Revisions:
		- 20230301@Tacy: Create SP [Redmine: #184255] 
		- 20230803@Tacy: NAP - Manage SportBettypeSettingMatrix - Add more fields [Redmine: #192732]

	Param's Explanation:
		@pMutilProductID  0 : All, <> 0 : ProductID
		@pMutilSportType  0 : All, <> 0 : SportType

	Example:
		EXEC [Acc_ReferenceSetting_SportTypeSel] @pMutilProductID='16', @pMutilSportType='0'
*/
BEGIN
	SET NOCOUNT ON;
	
	IF @pMutilProductID='' OR @pMutilSportType=''
		RETURN

	CREATE TABLE #Products(
			ProductID	SMALLINT PRIMARY KEY, 
			ProductName NVARCHAR(50)
	)

	CREATE TABLE #Sports(
			SportType SMALLINT PRIMARY KEY, 
			SportName NVARCHAR(50)
	)

	INSERT INTO #Products (ProductID, ProductName)
	SELECT ProductID,ProductName 
	FROM dbo.products WITH(NOLOCK)
	WHERE Enabled=1
	AND ProductID IN (SELECT TRIM(value) val FROM STRING_SPLIT(@pMutilProductID, ','))

	INSERT INTO #Sports (SportType,SportName)	
	EXEC Acc_SporttypeSel @Mode=1

	DELETE FROM #Sports
	WHERE @pMutilSportType<>'0' AND SportType NOT IN (SELECT TRIM(value) val FROM STRING_SPLIT(@pMutilSportType, ','))
	
	SELECT s.SportType, s.SportName
	FROM #Sports s
		CROSS APPLY (SELECT TOP 1 1 as value					
					 FROM SportBettypeSettingMatrix sm WITH (NOLOCK) 
					 INNER JOIN #Products p ON p.ProductID=sm.RealProductId
					 WHERE s.SportType=sm.SportType AND sm.isDeleted=0) sm
	ORDER BY S.SportType

   DROP TABLE #Sports, #Products
END
GO