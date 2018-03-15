/*<info serverAlias="DBCUST-CUSTDB" executers="bodbExtAccNet" viewers="vnteam" isFunction="0"></info>*/

ALTER PROCEDURE [dbo].[EAS_CustomerSelSportsByProduct]
	@ProductID INT
AS
/*
	Created: 20180315@Johnson
	Task : Get sport/bettypes by product for multiple update status on EXT
	DB: DBCUST/CustDB
	Original:

	Revisions:
		- 20180315@Johnson: new direction for status [Redmineid: #87328]
*/	
BEGIN
	SET NOCOUNT ON
	DECLARE @SportBettype TABLE(Sporttype INT, 
								Bettype INT)
	IF @ProductID = 3 --Number Game
	BEGIN
		INSERT INTO @SportBettype(sporttype,bettype)
		SELECT 161,81
	END
	ELSE IF @ProductID=6 -- Casino
	BEGIN
		INSERT INTO @SportBettype(sporttype,bettype)
		SELECT 208,2101
	END
	ELSE IF @ProductID=8--Keno
	BEGIN
		INSERT INTO @SportBettype(sporttype,bettype)
		SELECT 202,1501
		UNION
		SELECT 202,1503
		UNION
		SELECT 202,1504
		UNION
		SELECT 202,1505
		UNION
		SELECT 202,1508
		UNION
		SELECT 202,1511
		UNION
		SELECT 202,1513
		UNION
		SELECT 202,1514
		UNION
		SELECT 202,1515
		UNION
		SELECT 202,1516
	END
	ELSE IF @ProductID=12 -- GD
	BEGIN
		INSERT INTO @SportBettype(sporttype,bettype)
		SELECT 255,1701
	END	
	ELSE IF @ProductID=15 -- CB
	BEGIN
		INSERT INTO @SportBettype(sporttype,bettype)
		SELECT 204,18000
	END
	ELSE --DCS products
	BEGIN
		INSERT INTO @SportBettype(sporttype,bettype)
		SELECT DISTINCT SportType,Bettype
		FROM dbo.ProductSettingDetail WITH(NOLOCK)
		WHERE ProductID = @ProductID AND SettingType IN (11,13)
	END
	
	SELECT * FROM @SportBettype
END
GO	