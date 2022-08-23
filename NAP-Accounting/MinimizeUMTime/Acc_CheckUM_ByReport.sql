/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet, bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[Acc_CheckUM_ByReport]
	@CustId 	INT = NULL,
	@MarketName	VARCHAR(300) = ''
AS
	/*
	Created: 20220816@Eddie
	Task :  Check UM config by Report
	DB: DBCUST.CustDB
	Revisions:	
		- 20220816@Eddie: Initialize SPs [RedmineID: #174852]
	
	Param's Explanation:
		- @MarketName : 
			1. 'All'    (0 )
			2. 'IBCBET' (-1)
			3. '789y'   (-2)
			4. 'IBCIndo'(-3)			
	*/
BEGIN
	SET NOCOUNT ON
	
	SELECT @CustId = ISNULL(@CustId, -1), @MarketName = ISNULL(@MarketName, '')
	
	DECLARE @Market_spec TABLE(MarketId INT PRIMARY KEY, MarketName VARCHAR(300))
	
	INSERT INTO @Market_spec(MarketId, MarketName)
	EXEC dbo.Acc_UMTool_MarketSel;
	
	DECLARE @UMInfoTmp TABLE(
		CustId 		 INT, 
		FunctionType TINYINT,
		SiteId       INT,
		SiteName 	 VARCHAR(300),
		MarketName 	 VARCHAR(300),
		BeginTime    SMALLDATETIME,
		EndTime      SMALLDATETIME
	)
	
	DECLARE @Results TABLE(
		FunctionTypeName VARCHAR(300),
		MarketName 	 	 VARCHAR(300),
		BeginTime    	 SMALLDATETIME,
		EndTime      	 SMALLDATETIME
	)
	
	IF @CustId <> -1
	BEGIN
	
		INSERT INTO @UMInfoTmp(CustId, FunctionType, SiteId, SiteName, MarketName, BeginTime, EndTime)
		SELECT	c.custid, uc.FunctionType, uc.SiteID, c.site,
			CASE	
				WHEN c.site = 'IBCIndo' THEN 'IBCIndo'
				WHEN c.site = '789y' 	THEN '789y'
				ELSE 'IBCBET'
			END AS MarketName,
			DATEADD(HOUR, 12, uc.BeginTime) AS BeginTime,
			DATEADD(HOUR, 12, uc.EndTime)   AS EndTime
		FROM dbo.customer c WITH (NOLOCK)
			INNER JOIN dbo.UMConfig uc WITH(NOLOCK) ON uc.SuperID = c.custid
			INNER JOIN @Market_spec ms ON ms.MarketId = uc.SiteID
		WHERE c.custid = @CustId
			AND ( CONVERT(SMALLDATETIME,GETDATE()) BETWEEN uc.BeginTime AND uc.EndTime )
		
		SELECT CustId
		, [FunctionTypeName] = (SELECT FunctionTypeName FROM dbo.f_CustReport_UM_ProductsSel(FunctionType))
		, MarketName
		, BeginTime
		, EndTime 
		FROM @UMInfoTmp
		WHERE (MarketName LIKE '%' + @MarketName + '%') OR (@MarketName = '')
	END
	ELSE
	BEGIN
		IF @MarketName <> ''
		BEGIN
			INSERT INTO @Results(FunctionTypeName, MarketName, BeginTime, EndTime)
			SELECT [FunctionTypeName] = (SELECT FunctionTypeName FROM dbo.f_CustReport_UM_ProductsSel(uc.FunctionType))
			, ms.MarketName
			, DATEADD(HOUR, 12, uc.BeginTime) AS BeginTime
			, DATEADD(HOUR, 12, uc.EndTime)   AS EndTime
			FROM dbo.UMConfig uc WITH (NOLOCK)
				INNER JOIN @Market_spec ms ON ms.MarketId = uc.SiteID
			WHERE ms.MarketName LIKE '%' + @MarketName + '%'
				AND ( CONVERT(SMALLDATETIME,GETDATE()) BETWEEN uc.BeginTime AND uc.EndTime )
		END
		
		SELECT * FROM @Results
	END
END
GO