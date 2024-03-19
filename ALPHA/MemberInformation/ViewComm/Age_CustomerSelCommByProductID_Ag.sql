/*<info serverAlias="DBCUST-CUSTDB" executers="bodbDownlineNet,wsv_alp,bodbDownlineNetView,wsv_alpv" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CustomerSelCommByProductID_Ag]
	@ProductID INT,
	@Recommend INT,
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
		- 20221121@Eden: Unify RNG Lottery Customer Settings [RedmineID: #180640]
		- 20230728@Helios: Customer Setting - Simplify Live Casino Customer Setting [RedmineID: #189389] 
		- 20230928@Luke: Modify SPs to adapt in-house replication setup [Redmine: #194414]

	Param's Explanation: 
		- @SettingStatus: 0: Pro, 1: UAT 

*/
BEGIN
	SET NOCOUNT ON
	DECLARE  @SportType INT
	CREATE TABLE #SportBettypeFilter ( ProductID TINYINT, SportType SMALLINT, Bettype SMALLINT, IsLive BIT, SettingType SMALLINT, RealProductID TINYINT)

	INSERT INTO #SportBettypeFilter  (ProductID, SportType, Bettype, IsLive, SettingType, RealProductID)
	SELECT ProductID, SportType, Bettype, IsLive, SettingType, RealProductID
	FROM dbo.f_CustSetting_SportBetTypeSettingSelect(NULL,3,@SettingStatus)
	--WHERE RealProductId = @ProductID

	INSERT INTO #SportBettypeFilter  (ProductID, SportType, Bettype, IsLive, SettingType, RealProductID)
	SELECT ProductID, SportType, Bettype, IsLive, SettingType, RealProductID
	FROM dbo.f_CustSetting_SportBetTypeSettingSelect(NULL,19,@SettingStatus)
	--WHERE RealProductId = @ProductID

	UPDATE sb	
	SET sb.RealProductID = m.RealProductId
	FROM #SportBettypeFilter sb
	INNER JOIN SportBettypeSettingMatrix m WITH (NOLOCK) ON sb.SportType = m.SportType AND sb.BetType = m.BetType AND sb.RealProductID = m.ProductID AND m.isLicensee = 0 AND m.Site = 'All'
	WHERE m.ProductID IS NOT NULL
		AND m.isDeleted = 0

	DELETE FROM #SportBettypeFilter WHERE ISNULL(RealProductID , 0) <> @ProductID 
		
	SELECT 
		CAST(cps.closed AS BIT) closed,
		ci.enabled, 
		CAST(isnull(cps.reject,0) AS BIT) as suspended, 
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
	WHERE m.Recommend = @Recommend and m.roleid=1 
	--AND RealProductID = @ProductID
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