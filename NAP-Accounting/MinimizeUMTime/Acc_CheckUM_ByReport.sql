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
	
	DECLARE @current_date SMALLDATETIME = CONVERT(SMALLDATETIME, GETDATE())

	SELECT @CustId = ISNULL(@CustId, -1), @MarketName = ISNULL(@MarketName, '')
	
	DECLARE @Market_spec TABLE(MarketId INT PRIMARY KEY, MarketName VARCHAR(300))
	
	INSERT INTO @Market_spec(MarketId, MarketName)
	EXEC dbo.Acc_UMTool_MarketSel;
	
	DECLARE @Results TABLE(
		FunctionTypeName VARCHAR(300),
		MarketName 	 	 VARCHAR(300),
		BeginTime    	 SMALLDATETIME,
		EndTime      	 SMALLDATETIME
	)
	
	IF @CustId <> -1
	BEGIN
		SELECT	@MarketName = CASE	
				WHEN c.site = 'IBCIndo' THEN 'IBCIndo'
				WHEN c.site = '789y' 	THEN '789y'
				ELSE 'IBCBET'
			END
		FROM dbo.customer c WITH (NOLOCK)
		WHERE c.custid = @CustId
	END	

	IF @MarketName <> ''
	BEGIN
		INSERT INTO @Results(FunctionTypeName, MarketName, BeginTime, EndTime)
		SELECT [FunctionTypeName] = (SELECT FunctionTypeName FROM dbo.f_CustReport_UM_ProductsSel(uc.FunctionType))
			, ms.MarketName
			, DATEADD(HOUR, 12, uc.BeginTime) AS BeginTime
			, DATEADD(HOUR, 12, uc.EndTime)   AS EndTime
		FROM dbo.UMConfig uc WITH (NOLOCK)
			INNER JOIN @Market_spec ms ON ms.MarketId = uc.SiteID
		WHERE ( ms.MarketName LIKE '%' + @MarketName + '%' OR ms.MarketName = 'All' )
			AND ( @current_date BETWEEN uc.BeginTime AND uc.EndTime )
	END

	SELECT * FROM @Results
END
GO