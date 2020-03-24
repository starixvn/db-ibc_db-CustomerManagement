/*<info serverAlias="DBCUST-CUSTDB" executers="bodbDownlineNet,bodbDownlineNetView" viewers="vnteam" isFunction="0"></info>*/
USE CustDB
GO

ALTER PROCEDURE [dbo].[Age_CustomerSelCommByProductID_MAg]
	@ProductID INT,
	@MRecommend INT
AS

/*
	Created: 20151209@Dominic
	Task : Select member commission information for DCS Products
	DB: DBCUST/CustDB
	Revisions: 
		- 20180703@Elodie: Add info of SP
		- 20200321@Tiara: Handle dummy product for Sexy Gaming/Allbet/SA Gaming [Redmine: #130678]
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @SportType INT
	CREATE TABLE #SportBettypeFilter
	(ProductID TINYINT, 
	SportType SMALLINT, 
	Bettype SMALLINT, 
	IsLive BIT, 
	SettingType SMALLINT)
	
	IF @ProductID IN (39,45,21) --Handle dummy product 41
	BEGIN
		SELECT DISTINCT @SportType = S.SportType
		FROM DBAGE.bodb02.dbo.SportBettypeMatrix S WITH(NOLOCK)
		WHERE ProductID = @ProductID

		INSERT INTO #SportBettypeFilter  (ProductID, SportType, Bettype, IsLive, SettingType)
		SELECT	ProductID, SportType, Bettype, IsLive, SettingType
		FROM	ProductSettingDetail WITH(NOLOCK)
		WHERE	ProductID = 41 AND SportType = @SportType
		AND		SettingType = 3	-- comm
	END
	ELSE
	BEGIN
		INSERT INTO #SportBettypeFilter  (ProductID, SportType, Bettype, IsLive, SettingType)
		SELECT * 
		FROM dbo.f_CustSetting_SportBetTypeSettingSelect(@ProductID,3)
	END
	
	SELECT 
		ci.closed,
		ci.enabled, 
		isnull(ci.reject,0) as suspended, 
		m.username, 
		m.custid, 
		m.ugroup, 
		m.firstname, 
		m.lastname, 
		ci.credit,
		cs.SportType,
		cs.MasterDiscount * 100 AS MasterDiscount,
		cs.AgentDiscount * 100 AS AgentDiscount,
		cs.PlayerDiscount * 100 AS PlayerDiscount
	FROM 
		customer AS m with (NOLOCK)
		INNER JOIN CustInfo as ci with (NOLOCK) on m.CustID = ci.CustID
		CROSS JOIN #SportBettypeFilter f WITH(NOLOCK)
		INNER JOIN CustDiscount3rd_Member as cs with (NOLOCK) 
				ON m.CustID = cs.CustID
					AND cs.SportType = f.sporttype
					AND cs.BetType = f.BetType
	WHERE m.MRecommend = @MRecommend and m.roleid=1 
	ORDER BY 
		case 
			when isnull(ci.enabled, 0) = 0 then 3 
			when isnull(ci.closed, 0) = 1 then 2 
			when isnull(ci.reject, 0) = 1 then 1 
			else 0 
		end, 
		m.username,
		cs.SportType
END
GO