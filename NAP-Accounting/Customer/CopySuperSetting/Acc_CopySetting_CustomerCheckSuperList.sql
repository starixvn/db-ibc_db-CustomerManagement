/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CopySetting_CustomerCheckSuperList] 
	@username VARCHAR(50),
	@SuperList VARCHAR(MAX) = '',
	@custid		INT = 0 OUTPUT,
	@ProductList VARCHAR(MAX) = '',
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg  NVARCHAR(1000)='' OUTPUT,
	@SettingStatus TINYINT = 0
AS
/*
	Created: 20210719@Johnson
	Task : get list products is offered to copy winlimit setting from super 
	DB: DBCUST/CustDB
	Original:

	Revision:
		- 20210716@Johnson: initial sp [redmine:#158174]
		- 20220110@Eden: Saba Casino use DCS Setting [RedmineID: #164280]
		- 20220614@Eden: DBCUST - modify sp syntax to adapt with the SQL Server upgrade to 2019 [Redmine: #171831] 
		- 20220617@Johnson: define temp table to avoid dump db [redmine:#174035]
		- 20221121@Eden: Unify RNG Lottery Customer Settings [RedmineID: #180640]
		- 20230731@Eden: Simplify Live Casino Customer Setting - [Redmine: #189389]
		- 20230928@Luke: Modify SPs to adapt in-house replication setup [Redmine: #194414]
	Parameter's Explanation:
		@custid: output source custid
		@username: source custid
		@SuperList: super list destination		
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @strUsername  NVARCHAR(100)	= '',			
			@site VARCHAR(50),
			@currency INT
			
	CREATE TABLE #tblCust(custid INT, username VARCHAR(50),bitmapIsHidden BINARY(32) )
	CREATE NONCLUSTERED INDEX IX_tblCust_custid ON #tblCust(custid ASC)
	
	INSERT INTO #tblCust(username)
	SELECT value
	FROM STRING_SPLIT(@SuperList,',')
	WHERE value <> ''
		
	IF NOT EXISTS(SELECT 1 FROM custinfo WITH(NOLOCK) 
				WHERE username = @username
					AND roleid = 4
					AND Enabled = 1
					AND custid NOT IN (SELECT custid FROM Dep_CustSuper WITH(NOLOCK))
					AND custid > 100--dummy account
				)
	BEGIN
		SELECT @ErrCode = 100,
			@ErrMsg = 'Invalid source super account.'
		RETURN;
	END	
	
	SELECT @strUsername = ''
	;WITH t AS(
		SELECT t.username, c.custid, c.roleid, c.enabled
		FROM #tblCust t 
			LEFT JOIN custinfo c WITH(NOLOCK) ON c.username = t.username
	)
	SELECT @strUsername = @strUsername +','+ username
	FROM t
	WHERE custid IS NULL
		OR custid <= 100
		OR roleid <> 4
		OR enabled = 0
		OR custid IN (SELECT custid FROM Dep_CustSuper WITH(NOLOCK))

	IF @strUsername <> ''
	BEGIN
		SELECT @strUsername = STUFF(@strUsername,1,1,'')
		SELECT @ErrCode = 101,
				@ErrMsg = 'Invalid super account(s): ' + @strUsername
		RETURN;		
	END
	
	IF EXISTS (SELECT 1 FROM #tblCust WHERE username = @username)
	BEGIN
		SELECT @strUsername = STUFF(@strUsername,1,1,'')
		SELECT @ErrCode = 102,
				@ErrMsg = 'Source account is found among copied accounts. You cannot copy an account setting to itself.'
		RETURN;	
	END
	
	IF (SELECT COUNT(1) FROM #tblCust) > 500
	BEGIN		
		SELECT @ErrCode = 103,
				@ErrMsg = 'The function can only copy up to 500 accounts per request.'
		RETURN;		
	END
		
	SELECT @site = site,
			@currency = currency,
			@custid = custid
	FROM customer WITH(NOLOCK) 
	WHERE username = @username
	
	SELECT @strUsername = ''
	SELECT @strUsername = @strUsername +','+ username
	FROM customer WITH(NOLOCK)
	WHERE username IN (SELECT username FROM #tblCust)
		AND (site <> @site OR currency <> @currency)
		
	IF @strUsername <> ''
	BEGIN
		SELECT @strUsername = STUFF(@strUsername,1,1,'')
		SELECT @ErrCode = 104,
				@ErrMsg = 'The following accounts are not the same site and currency with the source account: ' + @strUsername
		RETURN;		
	END
		
	UPDATE t
	SET t.custid = c.custid
	FROM #tblCust t
		INNER JOIN customer c WITH(NOLOCK) ON t.username = c.username
		
	DECLARE @tblProduct TABLE (productID TINYINT, SportType SMALLINT)
	DECLARE @tblProduct_hidden TABLE (productID TINYINT, SportType SMALLINT)	
	CREATE TABLE #SportBettypeFilter(ProductID TINYINT, SportType SMALLINT, Bettype SMALLINT, BitmapOrder TINYINT)
	CREATE TABLE #MatrixRefWL(SportType SMALLINT, Bettype SMALLINT, SporttypeRefWinlossLimit SMALLINT, BettypeRefWinlossLimit SMALLINT)

	CREATE TABLE #ProductSettingDetail(
		[SettingType] [smallint],
		[SportType] [smallint],
		[BetType] [smallint],
		[ProductID] [tinyint]
	)

	INSERT INTO #ProductSettingDetail(SettingType,SportType,BetType,ProductID)
	SELECT d.SettingType,d.SportType,d.BetType,d.ProductID
	FROM dbo.f_CustSetting_ProductSettingDetailSel(@SettingStatus) d
		INNER JOIN ProductSettingType t WITH(NOLOCK) ON d.SettingType = t.SettingType
	WHERE t.SettingName = 'Win Loss Limit'

	INSERT INTO #MatrixRefWL(SportType,Bettype,SporttypeRefWinlossLimit,BettypeRefWinlossLimit)
	SELECT SportType
			,CASE WHEN mt.BetType = 1021 THEN 1024  ELSE mt.BetType END
			,SporttypeRefWinlossLimit
			,BettypeRefWinlossLimit
	FROM SportBettypeSettingMatrix mt WITH(NOLOCK) 
	WHERE mt.SporttypeRefWinlossLimit  IS NOT NULL
		AND mt.BettypeRefWinlossLimit  IS NOT NULL
		AND mt.isLicensee = 0
		AND mt.site = 'ALL'
		AND mt.isDeleted = 0
	
	INSERT INTO #SportBettypeFilter(ProductID, SportType, Bettype, BitmapOrder)
	SELECT p.ProductID, p.SportType, p.Bettype, psp.bitmapOrder
	FROM #ProductSettingDetail p WITH(NOLOCK)
		INNER JOIN #MatrixRefWL mt
			ON p.SportType = mt.SporttypeRefWinlossLimit 
			AND p.Bettype = mt.BettypeRefWinlossLimit
		INNER JOIN dbo.ProductStatusProfile psp WITH (NOLOCK) 
			ON PSP.Bettype = mt.BetType
				AND PSP.Sporttype = mt.SportType		
	WHERE p.ProductID <> 41 -- Live Casino use common productstatus
	UNION ALL
	SELECT p.ProductID, p.SportType, p.Bettype, psp.bitmapOrder	
	FROM #ProductSettingDetail p WITH(NOLOCK)
		INNER JOIN dbo.ProductStatusProfile psp WITH (NOLOCK) 
			ON PSP.Bettype = p.BetType
				AND PSP.Sporttype = p.SportType		

	INSERT INTO @tblProduct(ProductID,SportType)
	SELECT DISTINCT ft.ProductID, ft.SportType		
	FROM #SportBettypeFilter ft 												
		CROSS JOIN dbo.CustProductStatus stt WITH (NOLOCK)
		CROSS APPLY dbo.f_CustSetting_ProductStatusSel(stt.bitmapIsHidden, ft.bitmapOrder) hid
	WHERE hid.value = 0
		AND stt.CustID = @custid
	
	--> GEt bitmapIsHidden of destination supers 
	UPDATE t 
	SET t.bitmapIsHidden = stt.bitmapIsHidden
	FROM #tblCust t
		INNER JOIN dbo.CustProductStatus stt WITH (NOLOCK) ON t.custid = stt.CustID
	
	INSERT INTO @tblProduct_hidden(ProductID,SportType)
	SELECT ft.ProductID, ft.SportType
	FROM #SportBettypeFilter ft 															
		CROSS JOIN #tblCust stt
		CROSS APPLY dbo.f_CustSetting_ProductStatusSel(stt.bitmapIsHidden, ft.bitmapOrder) hid
	GROUP BY stt.custid,ft.ProductID, ft.SportType
	HAVING MIN (CONVERT(INT,hid.value)) = 1 -- All sport use common settig are set hidden --> hidden

	DELETE t
	FROM @tblProduct t
		INNER JOIN @tblProduct_hidden hid
			ON t.productID = hid.productID
			AND t.SportType = hid.SportType

	--check UM if apply on any super for list product
	IF @ProductList <> ''
	BEGIN
		IF EXISTS(
		SELECT TOP (1) 1 AS Ex
			FROM customer cu WITH(NOLOCK)
			INNER JOIN site s WITH(NOLOCK) ON s.site = cu.site		
			INNER JOIN [dbo].UMConfig c WITH(NOLOCK) ON c.SuperID IN (cu.custid,0)
		WHERE CONVERT(SMALLDATETIME,GETDATE()) BETWEEN c.BeginTime AND c.EndTime
			AND c.SiteID IN (s.siteid,0)
			AND c.Currency IN (cu.currency,0)
			AND (cu.custid IN (SELECT custid FROM #tblCust WHERE custid > 0))
			AND (SportType IN (SELECT sporttype FROM @tblProduct)
				OR c.Sporttype = 0)
			AND c.SettingType IN(6,12,0,22)--settingtype win/loss limit		
			AND (c.ProductID IN(SELECT ProductID FROM @tblProduct 
								WHERE ProductID IN (SELECT value FROM STRING_SPLIT(@ProductList,','))
								)	
				OR c.ProductID = 0)
			AND c.FunctionType = 1	
		UNION ALL
		SELECT TOP (1) 1
			FROM customer cu WITH(NOLOCK)
			INNER JOIN site s WITH(NOLOCK) ON s.site = cu.site		
			INNER JOIN [dbo].UMConfig c WITH(NOLOCK) ON c.SuperID IN (cu.custid,0)
		WHERE CONVERT(SMALLDATETIME,GETDATE()) BETWEEN c.BeginTime AND c.EndTime
			AND c.SiteID IN (s.siteid,0)
			AND c.Currency IN (cu.currency,0)
			AND cu.custid = @custid
			AND (SportType IN (SELECT sporttype FROM @tblProduct)
				OR c.Sporttype = 0)
			AND c.SettingType IN(6,12,0,22)--settingtype win/loss limit		
			AND (c.ProductID IN(SELECT ProductID FROM @tblProduct 
								WHERE ProductID IN (SELECT value FROM STRING_SPLIT(@ProductList,','))
								)	
				OR c.ProductID = 0)
			AND c.FunctionType = 1
		)
		BEGIN	
			SELECT @ErrCode = 105,
					@ErrMsg = 'One or many accounts are on UM, please try again later.'
			RETURN;		
		END
	END
	
	SELECT productID,SportType FROM @tblProduct	
	
	SELECT distinct custid,username FROM #tblCust 

	DROP TABLE #MatrixRefWL
	DROP TABLE #SportBettypeFilter
	DROP TABLE #tblCust
END