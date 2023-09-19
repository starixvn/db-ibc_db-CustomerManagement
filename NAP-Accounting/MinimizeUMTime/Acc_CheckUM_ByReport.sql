/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet, bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[Acc_CheckUM_ByReport]
	@CustId 	INT = NULL
	,@SiteID 	INT = 0
	,@SiteName 	NVARCHAR(50) = ''
AS
/*
	Created: 20220816@Eddie
	Task :  Check UM config by Report
	DB: DBCUST.CustDB
	Revisions:	
		- 20220816@Eddie: Initialize SPs [RedmineID: #174852]
		- 20230208@Eddie: add parameter @SiteName and remove @MarketName [RedmineID: #182841]
		- 20230720@Lewis: Add conditions [RedmineID: #186142]
	
	Param's Explanation:

*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @current_date SMALLDATETIME = CONVERT(SMALLDATETIME, GETDATE())

	SELECT @CustId = ISNULL(@CustId, -1), @SiteID = ISNULL(@SiteID, 0), @SiteName = ISNULL(@SiteName, '')
	
	DECLARE @Results TABLE(
		FunctionTypeName VARCHAR(300)
		,BeginTime    	 SMALLDATETIME
		,EndTime      	 SMALLDATETIME
	)
	
	IF @CustId <> -1
	BEGIN
		SELECT	@SiteID = s.siteid
		FROM dbo.customer c WITH (NOLOCK)
			INNER JOIN Site s WITH (NOLOCK) ON s.site = c.site
		WHERE c.custid = @CustId
	END

	IF (@SiteName <> '' AND @SiteID = 0)
	BEGIN
		SELECT @SiteID = siteid 
		FROM Site WITH (NOLOCK) 
		WHERE site = @SiteName
	END

	IF( @SiteID <> 0 OR @SiteName <> '' )
	BEGIN
		INSERT INTO @Results(FunctionTypeName, BeginTime, EndTime)
		SELECT [FunctionTypeName] = (SELECT FunctionTypeName FROM dbo.f_CustReport_UM_ProductsSel(uc.FunctionType))
			, DATEADD(HOUR, 12, uc.BeginTime) AS BeginTime
			, DATEADD(HOUR, 12, uc.EndTime)   AS EndTime
		FROM dbo.UMConfig uc WITH (NOLOCK)
		WHERE (uc.SiteID = @SiteID OR uc.SiteID = 0 ) AND ( @current_date BETWEEN uc.BeginTime AND uc.EndTime )
	END

	SELECT FunctionTypeName, BeginTime, EndTime FROM @Results
END
GO