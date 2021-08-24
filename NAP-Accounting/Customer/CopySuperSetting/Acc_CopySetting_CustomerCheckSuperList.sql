/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE [dbo].[Acc_CopySetting_CustomerCheckSuperList] 
	@username VARCHAR(50),
	@SuperList VARCHAR(MAX) = '',
	@custid		INT = 0 OUTPUT,
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg  NVARCHAR(1000)='' OUTPUT
AS
/*
	Created: 20210719@Johnson
	Task : get list products is offered to copy winlimit setting from super 
	DB: DBCUST/CustDB
	Original:

	Revision:
		- 20210716@Johnson: initial sp [redmine:#158174]
	
	Parameter's Explanation:
		@custid: output source custid
		@username: source custid
		@SuperList: super list destination
		@ProductList: List product need to copy setting
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @strUsername  NVARCHAR(100)	= '',			
			@site VARCHAR(50),
			@currency INT
			
	DECLARE @tblCust TABLE(custid INT, username NVARCHAR(50))
	
	INSERT INTO @tblCust(username)
	SELECT val
	FROM dbo.strSplit(@SuperList,',')
		
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
		FROM @tblCust t 
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
	
	IF EXISTS (SELECT 1 FROM @tblCust WHERE username = @username)
	BEGIN
		SELECT @strUsername = STUFF(@strUsername,1,1,'')
		SELECT @ErrCode = 102,
				@ErrMsg = 'Source account is found among copied accounts. You cannot copy an account setting to itself.'
		RETURN;	
	END
	
	IF (SELECT COUNT(1) FROM @tblCust) > 500
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
	WHERE username IN (SELECT username FROM @tblCust)
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
	FROM @tblCust t
		INNER JOIN customer c WITH(NOLOCK) ON t.username = c.username
		
	DECLARE @tblProduct TABLE (productID INT, SportType INT)
	
	INSERT INTO @tblProduct(ProductID,sporttype)
	SELECT 6, 208 --casino
	
	SELECT DISTINCT ProductID, SportType,Bettype
	INTO #SportBettypeFilter
	FROM dbo.ProductSettingDetail WITH(NOLOCK)
	WHERE ProductID IN (5,--VS
						41,--Live CS
						22,--Macau Games
						24,--FW
						44,--RnG lottery
						38,--Virtual Games
						6--VGaming
					)
		AND SettingStatus = 0

	INSERT INTO @tblProduct(ProductID,SportType)
	SELECT DISTINCT ft.ProductID, ft.SportType		
	FROM #SportBettypeFilter ft 
		INNER JOIN dbo.ProductStatusProfile psp WITH (NOLOCK) ON PSP.Bettype = ft.BetType AND PSP.Sporttype = ft.SportType															
		INNER JOIN dbo.CustProductStatus stt WITH (NOLOCK)	ON stt.CustID = @custid
	WHERE (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(stt.bitmapIsHidden, PSP.bitmapOrder)) = 0
	EXCEPT 
	SELECT DISTINCT ft.ProductID, ft.SportType		
	FROM #SportBettypeFilter ft 
		INNER JOIN dbo.ProductStatusProfile psp WITH (NOLOCK) ON PSP.Bettype = ft.BetType AND PSP.Sporttype = ft.SportType															
		CROSS APPLY (SELECT * FROM dbo.CustProductStatus stt WITH (NOLOCK)	
					WHERE stt.CustID IN (SELECT custid FROM @tblCust)
					) stt
	WHERE (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(stt.bitmapIsHidden, PSP.bitmapOrder)) = 1
	
	SELECT * FROM @tblProduct	
	
	SELECT * FROM @tblCust 
END