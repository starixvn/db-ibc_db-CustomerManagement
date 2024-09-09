/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap,wsv_alp,wsv_alpv,wsv_xnap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CheckUM]
	@CustID	int ,
	@ProductID tinyint = NULL,
	@SportType smallint = NULL,
	@SettingType tinyint = NULL,
	@FunctionType tinyint = NULL,
	@Language VARCHAR(2) = 'E',
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg	NVARCHAR(4000) = '' OUTPUT,
	@ReturnUMData BIT = 1 ,
	@SettingStatus TINYINT = 0,
	@GroupID TINYINT = NULL -- If @GroupID <> NULL, Check UM by group
AS
BEGIN
/*
Created: 20200629@Eden
Task :  Check UM config
DB: DBCUST.CustDB
Revisions:	
	- 20200629@Eden: Minimize UM Time - Lock Update Customer setting [Redmine: #136464]
	- 20201005@Eden: Minimize UM Time Phase 2 [Redmine: #142115]
	- 20220615@Tacy: Hot modify Select Into statement to avoid dump [Redmine: #174035]
	- 20240404@Eden: Unify Live Casino & RNG slot/RNG Casino [Redmine: #198960]
	- 20240521@Helios: Unify RNG Games - Use ProductSettingProfile Table instead of ProductSettingDetail table [Redmine: #204358] 

Param's Explanation:
	- @FunctionType : Affect funtion
		1. Edit
		2. Adding New Customer
	- @ReturnUMData : 
		1 : Return table to show announcement
		0 : Return Error for lock action funtion SP
		
Examples : 
	DECLARE @ErrCode INT = 0, @ErrMsg	NVARCHAR(4000) = ''
	EXEC [Acc_CheckUM] @CustID = 1, @ProductID = 38, @SportType = 245, @SettingType = 1
		, @FunctionType = 1,@ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT SELECT @ErrCode, @ErrMsg
	EXEC [Acc_CheckUM] @CustID = 1, @ProductID = 1, @SportType = 0, @SettingType = 0
		, @FunctionType = 1 ,@ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT
		SELECT @ErrCode, @ErrMsg
	EXEC [Acc_CheckUM] @CustID = 1, @ProductID = 8, @SportType = 0, @SettingType = 0
		, @FunctionType = 1 ,@ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT ,@Language = 'CT'
		SELECT @ErrCode, @ErrMsg
	EXEC [Acc_CheckUM] @CustID = 1
*/


SET NOCOUNT ON	
	DECLARE @UMProduct TABLE(
		 ProductID    TINYINT, 
		 SportType    SMALLINT, 
		 SettingType  TINYINT, 
		 Functiontype TINYINT, 
		 BeginTime    SMALLDATETIME, 
		 EndTime      SMALLDATETIME, 
		 Time_Stamp   BINARY(8), 
		 Currency     INT, 
		 SiteID       INT
		);

	DECLARE @Product TABLE(ProductID  TINYINT PRIMARY KEY)

	IF NOT EXISTS (SELECT TOP 1 1 FROM [dbo].UMConfig c WITH(NOLOCK))
	BEGIN
		GOTO RETURNDATA;
	END

	IF @ProductID IS NULL AND @GroupID IS NULL AND @FunctionType IS NULL -- For Announcement
	BEGIN
		CREATE TABLE #tmpUM (
				ProductID		TINYINT, 
				SportType		SMALLINT, 
				BetType			SMALLINT,
				IsLive			BIT,
				SettingType		TINYINT, 
				BeginTime		SMALLDATETIME, 
				EndTime			SMALLDATETIME, 
				Time_Stamp		BINARY(8), 
				Functiontype	TINYINT, 
				SiteID			INT,
				Currency		INT
		)

		INSERT INTO #tmpUM (ProductID, SportType, BetType, IsLive, SettingType, BeginTime, EndTime, Time_Stamp, Functiontype, SiteID, Currency)
		SELECT c.ProductID,
				c.SportType,
				c.BetType,
				c.IsLive,
				c.SettingType,
				DATEADD(HOUR, 12, c.BeginTime) AS BeginTime,
				DATEADD(HOUR, 12, c.EndTime) AS EndTime,
				CAST(c.Time_Stamp AS BINARY(8)) AS Time_Stamp,
				c.FunctionType,
				ISNULL(s.siteid,ags.siteid) AS SiteID,
				cu.currency
		FROM customer cu WITH(NOLOCK)
			INNER JOIN customer su WITH(NOLOCK) ON cu.srecommend = su.custid
			LEFT JOIN customer ag WITH(NOLOCK) ON cu.recommend = ag.custid
			LEFT JOIN site s WITH(NOLOCK) ON s.site = cu.site
			LEFT JOIN site ags WITH(NOLOCK) ON ag.site = ags.site
			INNER JOIN [dbo].UMConfig c WITH(NOLOCK) ON c.SuperID IN (su.custid,0)
		WHERE CONVERT(SMALLDATETIME,GETDATE()) BETWEEN c.ShowTime AND c.EndTime
			AND c.SiteID IN (ISNULL(s.siteid,ags.siteid),0)
			AND c.Currency IN (cu.currency,0)
			AND cu.custid = @CustID
		UNION ALL --dupliate to show announcement for Addnew
		SELECT c.ProductID,
				c.SportType,
				c.BetType,
				c.IsLive,
				c.SettingType,
				DATEADD(HOUR, 12, c.BeginTime) AS BeginTime,
				DATEADD(HOUR, 12, c.EndTime) AS EndTime,
				CAST(c.Time_Stamp AS BINARY(8)),
				FunctionType = 2,
				ISNULL(s.siteid,ags.siteid) AS SiteID,
				cu.currency
		FROM customer cu WITH(NOLOCK)
			INNER JOIN customer su WITH(NOLOCK) ON cu.srecommend = su.custid
			LEFT JOIN customer ag WITH(NOLOCK) ON cu.recommend = ag.custid
			LEFT JOIN site s WITH(NOLOCK) ON s.site = cu.site
			LEFT JOIN site ags WITH(NOLOCK) ON ag.site = ags.site
			INNER JOIN [dbo].UMConfig c WITH(NOLOCK) ON c.SuperID IN (su.custid,0)
		WHERE CONVERT(SMALLDATETIME,GETDATE()) BETWEEN c.ShowTime AND c.EndTime
			AND c.SiteID IN (ISNULL(s.siteid,ags.siteid),0)
			AND c.Currency IN (cu.currency,0)
			AND cu.custid = @CustID
			AND c.FunctionType = 1 AND c.LockAddingNew = 1

		--Delete Non-offered Products
		DELETE ft
		FROM #tmpUM ft
			INNER JOIN dbo.ProductStatusProfile psp WITH (NOLOCK) ON PSP.Sporttype = ft.SportType															
			INNER JOIN dbo.CustProductStatus stt WITH (NOLOCK)	ON stt.CustID = @CustID
			CROSS APPLY dbo.f_CustSetting_ProductStatusSel(stt.bitmapIsHidden, PSP.bitmapOrder) Hd
		WHERE hd.value = 1

		DELETE ft
		FROM #tmpUM ft
			INNER JOIN SportNonOfferedSiteCurrency nof WITH(NOLOCK)
				ON ft.SportType = nof.SportType
				AND nof.siteID IN (ft.SiteID, 0)
				AND nof.Currency IN (ft.Currency, 0)
		WHERE NOT EXISTS(	SELECT 1 
							FROM ProductSettingProfile p WITH(NOLOCK) 
							WHERE nof.SportType = p.SportType 
								AND nof.BetType <> p.BetType 
								AND p.SettingStatus = 0 
						)

		UPDATE #tmpUM
		SET  ProductID = 0
			,SportType = 0
			,SettingType = 0
			,BetType = 0
			,IsLive = 0
		WHERE FunctionType = 2

		INSERT INTO @UMProduct(
			 ProductID
			,SportType
			,SettingType
			,Functiontype
			,BeginTime
			,EndTime
			,Time_Stamp
			,Currency
			,SiteID
		)
		SELECT c.ProductID, 
			   c.Sporttype, 
			   c.SettingType, 
			   c.FunctionType,
			   MIN(c.BeginTime) AS BeginTime, 
			   MAX(c.EndTime) AS EndTime, 
			   MAX(c.Time_Stamp) AS Time_Stamp,
			   MAX(c.Currency) AS Currency,
			   MAX(c.SiteID) AS SiteID
		FROM #tmpUM c
		GROUP BY c.ProductID, 
				 c.Sporttype, 
				 c.SettingType,
				 c.FunctionType
		
		DROP TABLE #tmpUM

		GOTO RETURNDATA;
	END
	ELSE IF @GroupID IS NULL 
	BEGIN
		INSERT INTO @UMProduct(
			 ProductID
			,SportType
			,SettingType
			,Functiontype
			,BeginTime
			,EndTime
			,Time_Stamp
			,Currency
			,SiteID
		)
		SELECT c.ProductID, 
			   c.Sporttype, 
			   c.SettingType, 
			   c.FunctionType,
			   MIN(c.BeginTime) AS BeginTime, 
			   MAX(c.EndTime) AS EndTime, 
			   MAX(c.Time_Stamp) AS Time_Stamp,
			   MAX(c.Currency) AS Currency,
			   MAX(c.SiteID) AS SiteID
		FROM [dbo].f_CustSetting_SportUMByCust(@CustID) c
		WHERE c.SportType IN(ISNULL(@SportType, c.Sporttype), 0)
			AND c.SettingType IN(ISNULL(@SettingType, c.SettingType), 0)
			AND c.FunctionType = ISNULL(@FunctionType,c.FunctionType)
			AND c.ProductID IN(ISNULL(@ProductID, c.ProductID), 0)
		GROUP BY c.ProductID, 
				 c.Sporttype, 
				 c.SettingType,
				 c.FunctionType

		IF @FunctionType = 2 -- Adding New 
		BEGIN
			INSERT INTO @UMProduct(
				 ProductID
				,SportType
				,SettingType
				,Functiontype
				,BeginTime
				,EndTime
				,Time_Stamp
				,Currency
				,SiteID
			)
			SELECT c.ProductID, 
				   c.Sporttype, 
				   c.SettingType, 
				   c.FunctionType,
				   MIN(c.BeginTime) AS BeginTime, 
				   MAX(c.EndTime) AS EndTime, 
				   MAX(c.Time_Stamp) AS Time_Stamp,
				   MAX(c.Currency) AS Currency,
				   MAX(c.SiteID) AS SiteID
			FROM [dbo].f_CustSetting_SportUMByCust(@CustID) c
			WHERE c.FunctionType = 1 AND c.LockAddingNew = 1
			GROUP BY c.ProductID, 
					 c.Sporttype, 
					 c.SettingType,
					 c.FunctionType
		END
	END
	ELSE -- Check By GroupID
	BEGIN
		INSERT INTO @Product(ProductID)
		SELECT DISTINCT ProductID
		FROM dbo.f_CustSetting_ProductProfileSel(NULL,@SettingStatus,NULL,NULL)
		WHERE GroupID = @GroupID
			AND ISNULL(ProductID,0) <> 0 
		UNION ALL
		SELECT 0
		
		INSERT INTO @UMProduct(
			 ProductID
			,SportType
			,SettingType
			,Functiontype
			,BeginTime
			,EndTime
			,Time_Stamp
			,Currency
			,SiteID
		)
		SELECT c.ProductID, 
			   c.Sporttype, 
			   c.SettingType, 
			   c.FunctionType,
			   MIN(c.BeginTime) AS BeginTime, 
			   MAX(c.EndTime) AS EndTime, 
			   MAX(c.Time_Stamp) AS Time_Stamp,
			   MAX(c.Currency) AS Currency,
			   MAX(c.SiteID) AS SiteID
		FROM [dbo].f_CustSetting_SportUMByCust(@CustID) c
		WHERE c.SportType IN(ISNULL(@SportType, c.Sporttype), 0)
			AND c.SettingType IN(ISNULL(@SettingType, c.SettingType), 0)
			AND c.FunctionType = ISNULL(@FunctionType,c.FunctionType)
			AND c.ProductID IN (SELECT ProductID FROM @Product)
		GROUP BY c.ProductID, 
				 c.Sporttype, 
				 c.SettingType,
				 c.FunctionType
	END

	--Delete Non-offered Products
	DELETE ft
	FROM @UMProduct ft
		INNER JOIN dbo.ProductStatusProfile psp WITH (NOLOCK) ON PSP.Sporttype = ft.SportType															
		INNER JOIN dbo.CustProductStatus stt WITH (NOLOCK)	ON stt.CustID = @CustID
		CROSS APPLY dbo.f_CustSetting_ProductStatusSel(stt.bitmapIsHidden, PSP.bitmapOrder) Hd
	WHERE hd.value = 1

	DELETE ft
	FROM @UMProduct ft
		INNER JOIN SportNonOfferedSiteCurrency nof WITH(NOLOCK)
			ON ft.SportType = nof.SportType
			AND nof.siteID IN (ft.SiteID, 0)
			AND nof.Currency IN (ft.Currency, 0)
	WHERE NOT EXISTS(	SELECT 1 
						FROM ProductSettingProfile p WITH(NOLOCK) 
						WHERE nof.SportType = p.SportType 
							AND nof.BetType <> p.BetType 
							AND p.SettingStatus = 0 
					)

	DECLARE @ErrorTemplate NVARCHAR(4000)
	DECLARE @FromTime VARCHAR(30), @ToTime VARCHAR(30), @ProductName VARCHAR(30) 

	SELECT @ErrMsg = ''

	IF EXISTS(SELECT 1 FROM @UMProduct) AND @FunctionType = 2
	BEGIN
		SELECT @FromTime = CONVERT(VARCHAR,MIN(t.BeginTime),103) + ' ' + LTRIM(LEFT(CONVERT(VARCHAR, MIN(t.BeginTime),8),5)),
			@ToTime = CONVERT(VARCHAR,MAX(t.EndTime),103) + ' ' + LTRIM(LEFT(CONVERT(VARCHAR, MAX(t.EndTime),8),5))
		FROM @UMProduct t

		SELECT @ErrCode = 90016
		SELECT @ErrorTemplate = [dbo].[f_Get_MsgNamebyMsgID](90016,@Language)
		SELECT @ErrMsg =   REPLACE(REPLACE(@ErrorTemplate,'<FromTime>',@FromTime),'<ToTime>',@ToTime)
	END

	RETURNDATA:

	IF @ReturnUMData = 1
		SELECT ProductID
			,SportType
			,SettingType
			,Functiontype
			,BeginTime
			,EndTime
			,Time_Stamp 
		FROM @UMProduct
END
GO