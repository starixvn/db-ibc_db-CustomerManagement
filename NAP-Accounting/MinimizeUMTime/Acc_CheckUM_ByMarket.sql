/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[Acc_CheckUM_ByMarket]
	@MarketId	INT = NULL
AS
	/*
	Created: 20220816@Eddie
	Task :  Check UM config by Market
	DB: DBCUST.CustDB
	Revisions:	
		- 20220816@Eddie: Initialize SPs [RedmineID: #174852]
	
	Param's Explanation:
		- @MarketId : 
			0 : 'All'
			-1: 'IBCBET'
			-2: '789y'
			-3: 'IBCIndo'			
	*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @Market_spec TABLE(MarketId INT PRIMARY KEY, MarketName VARCHAR(300))
	
	INSERT INTO @Market_spec(MarketId, MarketName)
	EXEC dbo.Acc_UMTool_MarketSel;
	
	SELECT uc.FunctionType, ms.MarketName, uc.BeginTime, uc.EndTime, uc.ShowTime  
	FROM dbo.UMConfig uc WITH (NOLOCK)
		INNER JOIN @Market_spec ms ON ms.MarketId = uc.SiteID
	WHERE uc.FunctionType NOT IN (1, 2, 101)
		AND (uc.SiteID = @MarketId OR @MarketId IS NULL)
	
END
GO