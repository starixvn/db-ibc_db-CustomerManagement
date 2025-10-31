/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_alp,wsv_alpv" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CustomerSelCommByProductID_MAg]
	@ProductID INT,
	@MRecommend INT,
	@SettingStatus TINYINT = 0,
	@isDirectDownline BIT
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
		- 20241107@Helios: Offer Direct Member for Super/Master [redmine: #211969]
		- 20250724@Helios: Agency Cash Service -Customer Setting Sprint 7 [redmine: #233474] 
		- 20251031@Dave: Adjust Live Casino PT & Commission [Redmine: #242260]
	Param's Explanation: 
		- @SettingStatus: 0: Pro, 1: UAT
		- @isDirectDownline:
				0 : Normal Member of Master
				1 : Get Super Direct Member : Master Com , Agent Comm = 0

*/
BEGIN
	SET NOCOUNT ON

	DECLARE @SportType INT, @site NVARCHAR(50), @siteid SMALLINT = 0, @currency SMALLINT = 0;
	CREATE TABLE #SportBettypeFilter ( ProductID TINYINT, SportType SMALLINT, Bettype SMALLINT, IsLive BIT, SettingType SMALLINT, RealProductID TINYINT)
	CREATE TABLE #CustTemp(custID INT PRIMARY KEY, username VARCHAR(50), ugroup VARCHAR(10), firstname NVARCHAR(254), lastname NVARCHAR(254), enabled BIT, credit MONEY, DoubleCommLosing BIT, AgentID INT)

	SELECT @site = si.site, @siteid = si.siteid, @currency = cs.currency
	FROM dbo.Customer AS cs WITH (NOLOCK)
		INNER JOIN dbo.Site AS si WITH (NOLOCK) ON cs.site = si.site
	WHERE cs.custid = @MRecommend;

	INSERT INTO #SportBettypeFilter  (ProductID, SportType, Bettype, IsLive, SettingType, RealProductID)
	SELECT ProductID, SportType, Bettype, IsLive, SettingType, RealProductID
	FROM dbo.f_CustSetting_ProductProfileSel(3,@SettingStatus,@siteid,@currency)
	
	INSERT INTO #SportBettypeFilter  (ProductID, SportType, Bettype, IsLive, SettingType, RealProductID)
	SELECT ProductID, SportType, Bettype, IsLive, SettingType, RealProductID
	FROM dbo.f_CustSetting_ProductProfileSel(19,@SettingStatus,@siteid,@currency)

	INSERT INTO #SportBettypeFilter  (ProductID, SportType, Bettype, IsLive, SettingType, RealProductID)
	SELECT ProductID, SportType, Bettype, IsLive, SettingType, RealProductID
	FROM dbo.f_CustSetting_ProductProfileSel(25,@SettingStatus,@siteid,@currency)

	UPDATE sb	
	SET sb.RealProductID = m.RealProductId
	FROM #SportBettypeFilter sb
	INNER JOIN f_CustSetting_SportBetTypeSettingMatrix (@SettingStatus) m
		ON sb.SportType = m.SportType AND sb.BetType = m.BetType AND sb.RealProductID = m.ProductID AND m.isLicensee = 0 AND m.Site IN (@site, 'All')
	WHERE m.ProductID IS NOT NULL
		AND m.isdeleted = 0

	DELETE FROM #SportBettypeFilter WHERE ISNULL(RealProductID , 0) <> @ProductID 

	CREATE TABLE #Tmp_CustCollect (CustID INT , Enabled BIT , credit MONEY ,  DoubleCommLosing BIT , PRIMARY KEY CLUSTERED (CustID))
	
	IF ISNULL(@isDirectDownline , 0) = 0
	-- Get Master Direct Member & Normal Member
	BEGIN
		INSERT INTO #Tmp_CustCollect 
		(
			CustID
		    , Enabled
		    , credit
		    , DoubleCommLosing
		)
		SELECT CustID
		    , [Enabled]
		    , credit
		    , DoubleCommLosing
		FROM custInfo i WITH (NOLOCK)
		WHERE i.roleid = 1 AND i.mrecommend = @MRecommend
	END
	ELSE
	-- Get Super Direct Member
	BEGIN
		INSERT INTO #Tmp_CustCollect 
		(
			CustID
		    , Enabled
		    , credit
		    , DoubleCommLosing
		)
		SELECT CustID
		    , [Enabled]
		    , credit
		    , DoubleCommLosing
		FROM custInfo i WITH (NOLOCK)
		WHERE i.roleid = 1 AND i.srecommend = @MRecommend AND recommend = -4 
	END

	/* 	adiscount  : MComm,	discount   : AComm,	playerdiscount   : PComm	*/

	-- Get data SportsBook
	IF @ProductID = 1
	BEGIN
		INSERT INTO #CustTemp(custid, username, ugroup, firstname, lastname, Enabled, credit, DoubleCommLosing, AgentID)
		SELECT c.custid, c.username, c.ugroup, c.firstname, c.lastname, ci.Enabled, ci.credit, ci.DoubleCommLosing, CASE WHEN c.recommend IN (-3,-4) THEN c.recommend ELSE 0 END AS AgentID
		FROM Customer c WITH (NOLOCK)
			INNER JOIN #Tmp_CustCollect ci ON c.custid = ci.custid
				
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
		    , CASE WHEN @isDirectDownline = 1 THEN 0 ELSE MAX (CASE WHEN cdm.SportType = 1 AND cdm.BetType = 1 THEN cdm.MasterDiscount ELSE 0 END) * 100 END	AS adiscount
		    , CASE 
			     WHEN (@isDirectDownline = 1)					
			       OR (@isDirectDownline = 0 AND ci.AgentID IN (-3,-4))
			     THEN 0 
			     ELSE MAX (CASE WHEN cdm.SportType = 1 AND cdm.BetType = 1 THEN cdm.AgentDiscount  ELSE 0 END) * 100						 END AS discount
		    , MAX (CASE WHEN cdm.SportType = 1 AND cdm.BetType = 1 THEN cdm.PlayerDiscount ELSE 0 END) * 100								     AS playerdiscount										
	    
		    -- Others Comm
		    , CASE WHEN @isDirectDownline = 1 THEN 0 ELSE MAX (CASE WHEN cdm.SportType = 1 AND cdm.BetType = 4 THEN cdm.MasterDiscount ELSE 0 END) * 100 END  AS adiscountcs		
		    , CASE 
			     WHEN (@isDirectDownline = 1)
			       OR (@isDirectDownline = 0 AND ci.AgentID IN (-3,-4))			     
			     THEN 0 
			     ELSE MAX (CASE WHEN cdm.SportType = 1 AND cdm.BetType = 4 THEN cdm.AgentDiscount  ELSE 0 END) * 100						 END AS discountcs																								
		    , MAX (CASE WHEN cdm.SportType = 1 AND cdm.BetType = 4 THEN cdm.PlayerDiscount ELSE 0 END) * 100								     AS playerdiscountcs									

		    -- 1X2
		    , CASE WHEN @isDirectDownline = 1 THEN 0 ELSE MAX (CASE WHEN cdm.SportType = 1 AND cdm.BetType = 5 THEN cdm.MasterDiscount ELSE 0 END) * 100 END  AS adiscount1x2		
		    , CASE 
				WHEN (@isDirectDownline = 1)
				  OR (@isDirectDownline = 0 AND ci.AgentID IN (-3,-4))				
				THEN 0 		    
				ELSE MAX (CASE WHEN cdm.SportType = 1 AND cdm.BetType = 5 THEN cdm.AgentDiscount  ELSE 0 END) * 100						END AS discount1x2																								
		    , MAX (CASE WHEN cdm.SportType = 1 AND cdm.BetType = 5 THEN cdm.PlayerDiscount ELSE 0 END) * 100								    AS playerdiscount1x2									

			-- Cricket
		    , CASE WHEN @isDirectDownline = 1 THEN 0 ELSE ISNULL ( cdm_Cricket.MasterDiscount , 0 ) * 100								END AS adiscount_cricket									
		    , CASE 
				WHEN (@isDirectDownline = 1)
				OR (@isDirectDownline = 0 AND ci.AgentID IN (-3,-4))
			      THEN 0 
				ELSE ISNULL ( cdm_Cricket.AgentDiscount  , 0 ) * 100														END AS discount_cricket																							
		    , ISNULL ( cdm_Cricket.playerdiscount , 0 ) * 100  playerdiscount_cricket																	
		    , cps.Locked
		    , cl.ClosedReason
			, cps.ServiceType
		FROM
			#CustTemp AS ci WITH (NOLOCK)
		CROSS JOIN #SportBettypeFilter f WITH(NOLOCK)
		INNER JOIN CustDiscount3rd_Member cdm WITH (NOLOCK) ON cdm.CustID = ci.custID AND f.SportType = cdm.SportType AND f.Bettype = cdm.BetType
		LEFT JOIN CustDiscount3rd_Member cdm_Cricket WITH (NOLOCK) ON cdm_Cricket.CustID = ci.custid  AND cdm_Cricket.SportType = 50 AND cdm_Cricket.BetType = 501
		CROSS APPLY (
				SELECT CASE WHEN CloseInfo > 0 THEN 1 ELSE 0 END AS closed , CASE WHEN SuspendInfo > 0 THEN 1 ELSE 0 END AS reject , ISNULL ( Locked , 0 ) Locked , ServiceType
				FROM dbo.CustProductStatus WITH (NOLOCK)
				WHERE CustID = ci.custid
			) AS cps
		LEFT JOIN CustLoginInfo_Member cl WITH (NOLOCK) ON cl.CustID = ci.custid

		GROUP BY
			ci.enabled , cps.closed , cps.reject , cps.Locked , ci.username , ci.custid , ci.ugroup ,
			ci.firstname , ci.lastname , ci.credit , ci.DoubleCommLosing , cdm_Cricket.AgentDiscount , cdm_Cricket.MasterDiscount , cdm_Cricket.PlayerDiscount , cl.ClosedReason, ci.AgentID , cps.ServiceType
		ORDER BY
			CASE
				WHEN ISNULL ( ci.enabled , 0 ) = 0
					THEN 3
				WHEN ISNULL ( cps.closed , 0 ) = 1
					THEN 2
				WHEN ISNULL ( cps.reject , 0 ) = 1
					THEN 1
				ELSE 0
			END ASC
		    , ci.username ASC
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
			CASE WHEN @isDirectDownline = 1 THEN 0 ELSE cs.MasterDiscount * 100											END AS MasterDiscount,
			CASE WHEN (@isDirectDownline = 1) OR (@isDirectDownline = 0 AND m.recommend IN (-3,-4)) THEN 0 ELSE cs.AgentDiscount * 100		END AS AgentDiscount,
			cs.PlayerDiscount * 100 AS PlayerDiscount,
			cps.Locked,
			cl.ClosedReason,
			cps.ServiceType
		FROM 
			customer AS m with (NOLOCK)
			INNER JOIN #Tmp_CustCollect ci on m.CustID = ci.CustID
			CROSS JOIN #SportBettypeFilter f WITH(NOLOCK)
			INNER JOIN CustDiscount3rd_Member as cs with (NOLOCK) 
					ON m.CustID = cs.CustID
						AND cs.SportType = f.sporttype
						AND cs.BetType = f.BetType
			CROSS APPLY  (SELECT CASE WHEN CloseInfo > 0 THEN 1 ELSE 0 END AS closed
											, CASE WHEN SuspendInfo > 0 THEN 1 ELSE 0 END AS reject
											, ISNULL(Locked, 0) Locked
											, ServiceType
										FROM dbo.CustProductStatus  WITH(NOLOCK)
										WHERE CustID = ci.custid
									) AS cps
			LEFT JOIN CustLoginInfo_Member cl WITH (NOLOCK) ON cl.CustID = ci.custid
		
		ORDER BY 
			case 
				when isnull(ci.enabled, 0) = 0 then 3 
				when isnull(cps.closed, 0) = 1 then 2 
				when isnull(cps.reject, 0) = 1 then 1 
				else 0 
			end ASC, 
			m.username ASC,
			cs.SportType ASC
	END
END
GO