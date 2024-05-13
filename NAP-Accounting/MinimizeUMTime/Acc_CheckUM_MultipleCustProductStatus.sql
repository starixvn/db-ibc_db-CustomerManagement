/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap,wsv_alp,wsv_alpv,wsv_xnap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CheckUM_MultipleCustProductStatus]
	@CustIDs	VARCHAR(MAX) ,
	@ProductID tinyint = NULL,
	@FunctionType tinyint = 1,
	@GroupID TINYINT = NULL,
	@SettingStatus TINYINT = 0
AS
BEGIN
/*
Created: 20200723@Eden
Task :  Check UM of Status (multiple Credit customer)
DB: DBCUST.CustDB
Revisions:	
	- 20200723@Eden: Minimize UM Time - Lock Update Customer setting [Redmine: #136464]
	- 20220614@Eden: DBCUST - modify sp syntax to adapt with the SQL Server upgrade to 2019 [Redmine: #171831] 
	- 20220615@Tacy: Hot modify Select Into statement to avoid dump [Redmine: #174035]
	- 20220627@Eden:  Implement the dependency between Macau Games Product Status and Jackpot Status [Redmine: #171715]
	- 20240215@Eden: Unify Live Casino & RNG slot/RNG Casino [Redmine: #198960]

Param's Explanation:
	- @FunctionType : Affect funtion
		1. Edit
		
Examples : 
		EXEC [Acc_CheckUM_MultipleCustProductStatus] @CustIDs = '1,2,0,20,1287,1296' 
			, @ProductID = 41, @FunctionType = 1
		EXEC [Acc_CheckUM_MultipleCustProductStatus] @CustIDs = '1,2,0,20,1287,1296' 
			, @ProductID = 23, @FunctionType = 1
*/
SET NOCOUNT ON	
	CREATE TABLE #Customers (CustID INT PRIMARY KEY)

	CREATE TABLE #UMConfig (
			CustID			INT,
			ProductID		TINYINT, 
			SportType		SMALLINT, 
			BetType			SMALLINT, 
			SettingType		TINYINT,
			BeginTime		SMALLDATETIME,
			EndTime			SMALLDATETIME,
			Time_Stamp		VARBINARY(8),
			SiteID			INT,
			currency		TINYINT
	)

	CREATE TABLE #Products([ProductID] [tinyint])

	INSERT INTO #Customers(CustID)
	SELECT value FROM STRING_SPLIT(@CustIDs,',') WHERE value <> ''

	IF ISNULL(@ProductID,0)<> 0 -- Check by Product
	BEGIN
		INSERT INTO #UMConfig (CustID,ProductID,Sporttype,Bettype,SettingType,BeginTime,EndTime,Time_Stamp,Currency,SiteID)
		SELECT s.CustID,c.ProductID,c.Sporttype,c.Bettype,c.SettingType,c.BeginTime,c.EndTime,c.Time_Stamp,c.Currency,c.SiteID
		FROM #Customers s
			CROSS APPLY [dbo].f_CustSetting_SportUMByCust(s.CustID) c
		WHERE c.SettingType IN (4,11,13,21,0)
			AND c.FunctionType IN( @FunctionType, 0)
			AND c.ProductID IN (@ProductID, 0)
	END
	ELSE IF ISNULL(@GroupID,0)<> 0 -- Check by Group Product
	BEGIN
		INSERT INTO #Products(ProductID)
		SELECT DISTINCT d.ProductID
		FROM custdb.dbo.f_CustSetting_ProductProfileSel(NULL,@SettingStatus,NULL,NULL) d
		WHERE SettingType IN (4,11,13,21)
			AND d.GroupID = @GroupID

		INSERT INTO #UMConfig (CustID,ProductID,Sporttype,Bettype,SettingType,BeginTime,EndTime,Time_Stamp,Currency,SiteID)
		SELECT s.CustID,c.ProductID,c.Sporttype,c.Bettype,c.SettingType,c.BeginTime,c.EndTime,c.Time_Stamp,c.Currency,c.SiteID
		FROM #Customers s
			CROSS APPLY [dbo].f_CustSetting_SportUMByCust(s.CustID) c
			INNER JOIN #Products d ON d.ProductID IN (c.ProductID, 0)
		WHERE c.SettingType IN (4,11,13,21,0)
			AND c.FunctionType IN( @FunctionType, 0)
	END

	--Delete Non-offered Products
	DELETE ft
	FROM #UMConfig ft
		INNER JOIN dbo.ProductStatusProfile psp WITH (NOLOCK) ON PSP.Sporttype = ft.SportType															
		INNER JOIN dbo.CustProductStatus stt WITH (NOLOCK)	ON stt.CustID = ft.CustID
		CROSS APPLY dbo.f_CustSetting_ProductStatusSel(stt.bitmapIsHidden, PSP.bitmapOrder) Hd
	WHERE hd.value = 1

	DELETE ft
	FROM #UMConfig ft
		INNER JOIN SportNonOfferedSiteCurrency nof WITH(NOLOCK)
			ON ft.SportType = nof.SportType
			AND nof.siteID IN (ft.SiteID, 0)
			AND nof.Currency IN (ft.Currency, 0)
	WHERE NOT EXISTS(	SELECT 1 
						FROM ProductSettingDetail p WITH(NOLOCK) 
						WHERE nof.SportType = p.SportType 
							AND nof.BetType <> p.BetType 
							AND p.SettingStatus = 0 
					)

	SELECT DISTINCT CustID,ProductID,Sporttype,Bettype,SettingType,BeginTime,EndTime,Time_Stamp
	FROM #UMConfig

	DROP TABLE #Customers
	DROP TABLE #UMConfig
	DROP TABLE #Products
END
GO