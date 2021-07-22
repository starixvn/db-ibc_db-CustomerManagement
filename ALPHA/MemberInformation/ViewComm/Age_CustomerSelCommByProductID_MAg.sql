/*<info serverAlias="DBCUST-CUSTDB" executers="bodbDownlineNet,bodbDownlineNetView" viewers="vnteam" isFunction="0"></info>*/
USE CustDB
GO

ALTER PROCEDURE [dbo].[Age_CustomerSelCommByProductID_MAg]
	@ProductID INT,
	@MRecommend INT,
	@SettingStatus TINYINT = 0
AS

/*
	Created: 20151209@Dominic
	Task : Select member commission information for DCS Products
	DB: DBCUST/CustDB
	Revisions: 
		- 20180703@Elodie: Add info of SP
		- 20200321@Tiara: Handle dummy product for Sexy Gaming/Allbet/SA Gaming [Redmine: #130678]
		- 20200406@Elodie: Add BBIN Product [Redmine: #131363]
		- 20200403@Elodie: Add Table Games Product [Redmine: #129440]
		- 20200615@Elodie: Implement new setting type 19 [Redmine: #135363]
		- 20201009@Tina: Add new parameter @SettingStatus [Redmine: #143077]
		- 20210408@Tina: Lock account & indirect close account [redmine: #148600]

	Param's Explanation: 
		- @SettingStatus: 0: Pro, 1: UAT

*/
BEGIN
	SET NOCOUNT ON

	DECLARE @DummyProductID INT, @SportType INT
	CREATE TABLE #SportBettypeFilter ( ProductID TINYINT, SportType SMALLINT, Bettype SMALLINT, IsLive BIT, SettingType SMALLINT)
	
	SELECT DISTINCT @DummyProductID = s.ProductID
	FROM ProductSettingDetail S WITH(NOLOCK)
	WHERE ProductID = @ProductID

	INSERT INTO #SportBettypeFilter  (ProductID, SportType, Bettype, IsLive, SettingType)
	SELECT ProductID, SportType, Bettype, IsLive, SettingType
	FROM dbo.f_CustSetting_SportBetTypeSettingSelect(@DummyProductID,3,@SettingStatus)
	WHERE RealProductId = @ProductID
	
	INSERT INTO #SportBettypeFilter  (ProductID, SportType, Bettype, IsLive, SettingType)
	SELECT ProductID, SportType, Bettype, IsLive, SettingType
	FROM dbo.f_CustSetting_SportBetTypeSettingSelect(@DummyProductID,19,@SettingStatus)
	WHERE RealProductId = @ProductID

	SELECT 
		CAST(cps.closed AS BIT) closed,
		ci.enabled, 
		CAST(cps.reject AS BIT) as suspended, 
		m.username, 
		m.custid, 
		m.ugroup, 
		m.firstname, 
		m.lastname, 
		ci.credit,
		cs.SportType,
		cs.MasterDiscount * 100 AS MasterDiscount,
		cs.AgentDiscount * 100 AS AgentDiscount,
		cs.PlayerDiscount * 100 AS PlayerDiscount,
		cps.Locked,
		cl.ClosedReason
	FROM 
		customer AS m with (NOLOCK)
		INNER JOIN CustInfo as ci with (NOLOCK) on m.CustID = ci.CustID
		CROSS JOIN #SportBettypeFilter f WITH(NOLOCK)
		INNER JOIN CustDiscount3rd_Member as cs with (NOLOCK) 
				ON m.CustID = cs.CustID
					AND cs.SportType = f.sporttype
					AND cs.BetType = f.BetType
		CROSS APPLY  (SELECT CASE WHEN CloseInfo > 0 THEN 1 ELSE 0 END AS closed
										, CASE WHEN SuspendInfo > 0 THEN 1 ELSE 0 END AS reject
										, ISNULL(Locked, 0) Locked
									FROM dbo.CustProductStatus  WITH(NOLOCK)
									WHERE CustID = ci.custid
								) AS cps
		LEFT JOIN CustLoginInfo_Member cl WITH (NOLOCK) ON cl.CustID = ci.custid
	WHERE m.MRecommend = @MRecommend and m.roleid=1 
	ORDER BY 
		case 
			when isnull(ci.enabled, 0) = 0 then 3 
			when isnull(cps.closed, 0) = 1 then 2 
			when isnull(cps.reject, 0) = 1 then 1 
			else 0 
		end, 
		m.username,
		cs.SportType
END
GO