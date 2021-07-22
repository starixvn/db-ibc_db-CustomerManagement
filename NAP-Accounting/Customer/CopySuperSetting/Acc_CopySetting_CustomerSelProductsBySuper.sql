/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE [dbo].[Acc_CopySetting_CustomerSelProductsBySuper] 
	  @CustID INT	
AS
/*
	Created: 20210716@Johnson
	Task : get list products is offered to copy winlimit setting from super 
	DB: DBCUST/CustDB
	Original:

	Revision:
		- 20210716@Johnson: initial sp [redmine:#158174]
		
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @tblProduct TABLE (productID INT)
	
	INSERT INTO @tblProduct(ProductID)
	SELECT 6 --casino
	
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

	INSERT INTO @tblProduct(ProductID)
	SELECT DISTINCT ft.ProductID		
	FROM #SportBettypeFilter ft 
		INNER JOIN dbo.ProductStatusProfile psp WITH (NOLOCK) ON PSP.Bettype = ft.BetType AND PSP.Sporttype = ft.SportType															
		INNER JOIN dbo.CustProductStatus stt WITH (NOLOCK)	ON stt.CustID = @custid
	WHERE (SELECT value FROM dbo.f_CustSetting_ProductStatusSel(stt.bitmapIsHidden, PSP.bitmapOrder)) = 0
	
	SELECT * FROM @tblProduct
END
GO	
