/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet, bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[Acc_CheckUM_ByReport]
	@CustId 	INT = NULL
	,@SiteID 	INT = 0
AS
/*
	Created: 20220816@Eddie
	Task :  Check UM config by Report
	DB: DBCUST.CustDB
	Revisions:	
		- 20220816@Eddie: Initialize SPs [RedmineID: #174852]
		- 20230113@Eddie: Remove @MarketName and use sitelable [RedmineID: #181596]
	
	Param's Explanation:

*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @current_date SMALLDATETIME = CONVERT(SMALLDATETIME, GETDATE())

	SELECT @CustId = ISNULL(@CustId, -1), @SiteID = ISNULL(@SiteID, 0)
	
	DECLARE @Results TABLE(
		FunctionTypeName VARCHAR(300)
		,SiteLable 	 	 VARCHAR(300)
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

	IF @SiteID <> 0
	BEGIN
		INSERT INTO @Results(FunctionTypeName, SiteLable, BeginTime, EndTime)
		SELECT [FunctionTypeName] = (SELECT FunctionTypeName FROM dbo.f_CustReport_UM_ProductsSel(uc.FunctionType))
			, s.SiteLabel
			, DATEADD(HOUR, 12, uc.BeginTime) AS BeginTime
			, DATEADD(HOUR, 12, uc.EndTime)   AS EndTime
		FROM dbo.UMConfig uc WITH (NOLOCK)
			INNER JOIN Site s WITH (NOLOCK) ON s.siteid = uc.SiteID
		WHERE uc.SiteID = @SiteID AND ( @current_date BETWEEN uc.BeginTime AND uc.EndTime )
	END

	SELECT FunctionTypeName, SiteLable, BeginTime, EndTime FROM @Results
END
GO