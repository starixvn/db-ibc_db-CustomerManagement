/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_alp,wsv_alpv" viewers="vnteam" isFunction="0"></info>*/
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
		- 20221121@Eden: Unify RNG Lottery Customer Settings [RedmineID: #180640]
		- 20230728@Helios: Customer Setting - Simplify Live Casino Customer Setting [RedmineID: #189389]
		- 20230928@Luke: Modify SPs to adapt in-house replication setup [Redmine: #194414]
		- 20231019@Helios: Customer Setting - Migrate Sportsbook to DCS [RedmineID: #193083]
		- 20240316@Eden: Unify Live RNG Casino [Redmine: #198960] 
		- 20241022@Johnson: remove MyanmarOdds [redmine: #201396]
	Param's Explanation: 
		- @SettingStatus: 0: Pro, 1: UAT

*/
BEGIN
	SET NOCOUNT ON

	DECLARE @SportType INT
	CREATE TABLE #SportBettypeFilter ( ProductID TINYINT, SportType SMALLINT, Bettype SMALLINT, IsLive BIT, SettingType SMALLINT, RealProductID TINYINT)
	CREATE TABLE #CustTemp(custID INT PRIMARY KEY, username VARCHAR(50), ugroup VARCHAR(10), firstname NVARCHAR(254), lastname NVARCHAR(254), enabled BIT, credit MONEY, DoubleCommLosing BIT)


	INSERT INTO #SportBettypeFilter  (ProductID, SportType, Bettype, IsLive, SettingType, RealProductID)
	SELECT ProductID, SportType, Bettype, IsLive, SettingType, RealProductID
	FROM dbo.f_CustSetting_SportBetTypeSettingSelect(NULL,3,@SettingStatus)
	
	INSERT INTO #SportBettypeFilter  (ProductID, SportType, Bettype, IsLive, SettingType, RealProductID)
	SELECT ProductID, SportType, Bettype, IsLive, SettingType, RealProductID
	FROM dbo.f_CustSetting_SportBetTypeSettingSelect(NULL,19,@SettingStatus)

	INSERT INTO #SportBettypeFilter  (ProductID, SportType, Bettype, IsLive, SettingType, RealProductID)
	SELECT ProductID, SportType, Bettype, IsLive, SettingType, RealProductID
	FROM dbo.f_CustSetting_SportBetTypeSettingSelect(NULL,25,@SettingStatus)

	UPDATE sb	
	SET sb.RealProductID = m.RealProductId
	FROM #SportBettypeFilter sb
	INNER JOIN f_CustSetting_SportBetTypeSettingMatrix (@SettingStatus) m
		ON sb.SportType = m.SportType AND sb.BetType = m.BetType AND sb.RealProductID = m.ProductID AND m.isLicensee = 0 AND m.Site = 'All'
	WHERE m.ProductID IS NOT NULL
		AND m.isdeleted = 0

	DELETE FROM #SportBettypeFilter WHERE ISNULL(RealProductID , 0) <> @ProductID 

	-- Get data SportsBook
	IF @ProductID = 1
	BEGIN
		INSERT INTO #CustTemp(custid, username, ugroup, firstname, lastname, Enabled, credit, DoubleCommLosing)
		SELECT c.custid, c.username, c.ugroup, c.firstname, c.lastname, ci.Enabled, ci.credit, ci.DoubleCommLosing
		FROM Customer c WITH (NOLOCK)
			INNER JOIN custInfo ci WITH (NOLOCK) ON c.custid = ci.custid
		WHERE c.mrecommend = @MRecommend AND c.roleid = 1
				
		SELECT
			cps.closed
		    , ci.enabled
		    , ISNULL ( cps.reject , 0 )		    AS suspended
		    , ci.username
		    , ci.custid
		    , ci.ugroup
		    , ci.firstname
		    , ci.lastname
		    , ci.credit
		    , ci.DoubleCommLosing
		    , MAX (CASE WHEN cdm.SportType = 1 AND cdm.BetType = 1 THEN cdm.MasterDiscount ELSE 0 END) * 100	AS adiscount
		    , MAX (CASE WHEN cdm.SportType = 1 AND cdm.BetType = 1 THEN cdm.AgentDiscount  ELSE 0 END) * 100	AS discount
		    , MAX (CASE WHEN cdm.SportType = 1 AND cdm.BetType = 1 THEN cdm.PlayerDiscount ELSE 0 END) * 100	AS playerdiscount
	    
		    -- Others Comm
		    , MAX (CASE WHEN cdm.SportType = 1 AND cdm.BetType = 4 THEN cdm.MasterDiscount ELSE 0 END) * 100	AS adiscountcs
		    , MAX (CASE WHEN cdm.SportType = 1 AND cdm.BetType = 4 THEN cdm.AgentDiscount  ELSE 0 END) * 100	AS discountcs
		    , MAX (CASE WHEN cdm.SportType = 1 AND cdm.BetType = 4 THEN cdm.PlayerDiscount ELSE 0 END) * 100	AS playerdiscountcs

		    -- 1X2
		    , MAX (CASE WHEN cdm.SportType = 1 AND cdm.BetType = 5 THEN cdm.MasterDiscount ELSE 0 END) * 100	AS adiscount1x2
		    , MAX (CASE WHEN cdm.SportType = 1 AND cdm.BetType = 5 THEN cdm.AgentDiscount  ELSE 0 END) * 100	AS discount1x2
		    , MAX (CASE WHEN cdm.SportType = 1 AND cdm.BetType = 5 THEN cdm.PlayerDiscount ELSE 0 END) * 100	AS playerdiscount1x2

			-- Cricket
		    , ISNULL ( cdm_Cricket.MasterDiscount , 0 ) * 100  adiscount_cricket
		    , ISNULL ( cdm_Cricket.AgentDiscount  , 0 ) * 100  discount_cricket
		    , ISNULL ( cdm_Cricket.playerdiscount , 0 ) * 100  playerdiscount_cricket
		    , cps.Locked
		    , cl.ClosedReason
		FROM
			#CustTemp AS ci WITH (NOLOCK)
		CROSS JOIN #SportBettypeFilter f WITH(NOLOCK)
		INNER JOIN CustDiscount3rd_Member cdm WITH (NOLOCK) ON cdm.CustID = ci.custID AND f.SportType = cdm.SportType AND f.Bettype = cdm.BetType
		LEFT JOIN CustDiscount3rd_Member cdm_Cricket WITH (NOLOCK) ON cdm_Cricket.CustID = ci.custid  AND cdm_Cricket.SportType = 50 AND cdm_Cricket.BetType = 501
		CROSS APPLY (
				SELECT CASE WHEN CloseInfo > 0 THEN 1 ELSE 0 END AS closed , CASE WHEN SuspendInfo > 0 THEN 1 ELSE 0 END AS reject , ISNULL ( Locked , 0 ) Locked
				FROM dbo.CustProductStatus WITH (NOLOCK)
				WHERE CustID = ci.custid
			) AS cps
		LEFT JOIN CustLoginInfo_Member cl WITH (NOLOCK) ON cl.CustID = ci.custid

		GROUP BY
			ci.enabled , cps.closed , cps.reject , cps.Locked , ci.username , ci.custid , ci.ugroup ,
			ci.firstname , ci.lastname , ci.credit , ci.DoubleCommLosing , cdm_Cricket.AgentDiscount , cdm_Cricket.MasterDiscount , cdm_Cricket.PlayerDiscount , cl.ClosedReason
		ORDER BY
			CASE
				WHEN ISNULL ( ci.enabled , 0 ) = 0
					THEN 3
				WHEN ISNULL ( cps.closed , 0 ) = 1
					THEN 2
				WHEN ISNULL ( cps.reject , 0 ) = 1
					THEN 1
				ELSE 0
			END
		    , ci.username
	END

	-- Get data BitCoin or LiveCasino
	ELSE
	BEGIN
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
END
GO