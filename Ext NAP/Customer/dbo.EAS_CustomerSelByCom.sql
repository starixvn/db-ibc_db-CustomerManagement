/*<info serverAlias="DBCUST-CUSTDB" executers="bodbExtAccNet,wsv_xnap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_CustomerSelByCom]  
    @GroupName		VARCHAR(50) = '',
    @UserName		VARCHAR(30) = NULL,
    @Status			TINYINT = 0,
	@Currencies 	VARCHAR(MAX) = '',
	@UserID			INT,
	@IsDataLimited	BIT	= 0,
	@IsNoDownlines	BIT = 0,
	@PageIndex		INT = 1 OUTPUT,
	@PageSize		INT = 500,
	@TotalRows		INT = 0 OUTPUT
AS  
/*  
	Created by: Scott  
	Date: 2012-12-17  
	Task : Customer list by company
	DB: DBCUST/CustDB
	Original SP: Acc_CustomerSelBySAg
	Revisions:  
		- 20130121@Dan: Move sp from DB053/bodb02 to DBEAS/bodb_EAS, call to bodb_AGE for Acc_CustGroup
		- 20130517@Lukas: 
				fix bug - wrong comm rate 
				add filter to reduce workload
		- 20131023@Elodie: Get more field HideVirtualSports, DisableCasinoBonus, DisableHRFixedOdds			
		- 20140120@Elodie: Hot fix to get information of disabled customer
		- 20140626@Logan:   1.Add Keno status [Redmine: #18268]
							2.Code aligning
		- 20140822@Logan:   Add Esports status [Redmine: #20666]
		- 20150514@Kathy: Add Gold Deluxe product [Redmine:#34486] 
		- 20150612@Kathy: Move sp from DBEAS.bodb_EAS to DBCUST.CustDB, use temp GameType [Redmine:#36216]
		- 20150825@Helen: Colossus Bet - [Redmine: #41264]
		- 20150904@Helen: commission setting for MO [Redmine #41470]
		- 20151019@Helen: Display wrong comm rate of Group A,B,C,D [Redmine: #45851]
		- 20151028@Helen: Member Information to support Muay Thai  [Redmine: #45496]
		- 20151209@Helen: Member information for Cockfighting [Redmine: #48133]
		- 20160114@Helen: Cricket - [Redmine: #50027]
		- 20160127@Billy: Member information for AllBet - [Redmine: #51713]
		- 20160411@Winnie: VoidBridge - [Redmine: #55546]
		- 20160606@Elodie: Hot fix to order list customer [Redmine: #58862]
		- 20160624@Winnie: Enhance Performance for Customer List SPs [Redmine: #59854]
		- 20160801@Elodie: NG2 Product - [Redmine: #60809]
		- 20160907@Elodie: Apply User Control permission of View/Access Special Site [Redmine: #63012]
		- 20160810@Winnie: #61733 Allbet VIP Barcarat
		- 20170120@Elodie: Don't offer Massac(1507), Malta(1509) anymore [#70693]
		- 20161031@Winnie: FishingWorld - [Redmine: #65474]
		- 20160801@Elodie: Implementing NewProductStatus Plugin - [Redmine #70722]	
		- 20170417@Winnie: Change to call the sp Acc_CheckShowProduct- [Redmine #72336]	
		- 20170601@Elodie: Migrate Inspired VS to DCS structure, add BetRadar VS product [Redmine: #77274]
		- 20170801@Elodie: Add Keno Lottery Product - [Redmine #74313]
		- 20170606@Winnie: Apply color for closed account  - [Redmine #74494]	
		- 20170629@Winnie: Offer Enable/Disable GoldDeluxe [RedmineID: #72957]
		- 20170828@Elodie: EXT - Support Security Code on Customer List - [Redmine: #81091]
		- 20170808@Elodie: Lucky3 Product - [Redmine: #75521]
		- 20171001@Elodie: BullFighting Product - [Redmine: #81664]
		- 20180125@Winnie: Hide inactive products [RedmineID: #86086]
		- 20180703@Elodie: Poker Games Product - [Redmine: #97675]
		- 20180830@Elodie: Add new bettype of Poker Games Product - [Redmine: #97675]
		- 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]
		- 20180907@Winnie: EXT-Function to control data range for SMA - [Redmine: #100067]
		- 20180731@Razor: Splitting Super Profile [#86934]
		- 20180919@Winnie: Add new bettype of Esports Product - [Redmine: #101526]
		- 20181122@Elodie: DB053/bodb_Age Migration [Redmine:#104770]
		- 20190806@Eden: add bettype 1525,1526 for Keno gametype - [Redmine: #116466]
		- 20190906@Eden: 3rd party products - Remove InActive Products Phase 2 [Redmine: #118699]
		- 20181112@Elodie: Rewrite SP for function customer list - [Redmine: #104570]
		- 20200918@Winfred: Reinsert MyanmarOdds [Redmine: #141926]
		- 20201113@Johnson: get sub group for supers list [redmine:#145199]
		- 20201209@Johnson: remove default value for @GroupName [redmine:#145199]
		- 20201222@Johnson: put WITH NOLOCK for Acc_CustGroup [redmine:#147578]
		- 20210408@Tina: Lock account & indirect close account [redmine: #148600]
		- 20220110@Eden: Saba Casino use DCS Setting [RedmineID: #164280]
		- 20240103@Johnson: Support Multiple Currencies [RedmineID: #196959]
		- 20240223@Luke: EXT - Support one more filter to filter "No Downline" Supers [Redmine: #201009]
		- 20230310@Helios: Customer Setting - Migrate Sportsbook to DCS [RedmineID: #193083] 

	Explanation's Param:
		@Status = 
			0: All
			1: Open
			2: Suspended
			3: Closed
			4: Disabled
			5: Locked

	Example: EXEC EAS_CustomerSelByCom @GroupName='ACCUUS', @UserID = 8   
*/
BEGIN
    SET NOCOUNT ON

    DECLARE @tmpSuperList TABLE (custID INT, Downlines INT, username VARCHAR(30), LimitDays SMALLINT, MinDate SMALLDATETIME, SubGroup VARCHAR(1000), RowNumber INT)
	DECLARE @DenySite TABLE (siteid INT, site NVARCHAR(50), SpecialGroup TINYINT)
	DECLARE @IsInternalAdmin BIT = 0
	DECLARE @RowStart INT, @RowEnd INT
	
	SELECT @RowStart = @PageSize * (@PageIndex - 1)  + 1
	SELECT @RowEnd = @RowStart + @PageSize - 1 

	-- get data for filtered customers		
	INSERT INTO  @DenySite (siteid , site, SpecialGroup)
	SELECT siteid , site, SpecialGroup 
	FROM NAP_UserControl.dbo.f_GetDeniedSiteByUser (@UserId)

	EXEC dbo.Acc_CustomerIsInternalAdmin @Custid = @UserID, @IsInternalAdmin = @IsInternalAdmin OUTPUT	

    --@Status: 0: All, 1: Open, 2:Suppended, 3: Closed, 4: Disabled
	IF @UserName IS NULL
	BEGIN
		INSERT INTO @tmpSuperList(CustID, Downlines, username, LimitDays, MinDate, RowNumber)
		SELECT ci.custID, d.Downlines, ci.username, LimitDays, MinDate,
			ROW_NUMBER() OVER(ORDER BY ci.enabled desc, cps.closed, ISNULL(cps.reject,0), c.username) as RowNumber
		FROM dbo.custinfo ci WITH(NOLOCK)
			INNER JOIN Customer c WITH(NOLOCK) ON c.custid = ci.custid
			CROSS APPLY  (SELECT CASE WHEN CloseInfo > 0 THEN 1 ELSE 0 END AS closed
										, CASE WHEN SuspendInfo > 0 THEN 1 ELSE 0 END AS reject
										, Locked
									FROM dbo.CustProductStatus  WITH(NOLOCK)
									WHERE CustID = ci.custid
								) AS cps
			LEFT JOIN dbo.Age_CustDateLimit l WITH(NOLOCK) ON c.CustID=l.CustId
			CROSS APPLY (SELECT COUNT(1) Downlines 
							FROM custInfo cif WITH (NOLOCK)
							WHERE cif.srecommend = ci.custID AND cif.roleid = 3 
						) d
		WHERE ci.custid IN (SELECT custid FROM dbo.Acc_CustGroup  WITH(NOLOCK) WHERE GroupName = @GroupName)
			AND ci.roleid = 4	
			AND 1 = CASE WHEN @Currencies = '' 
								OR ci.currency IN (SELECT value FROM STRING_SPLIT(@Currencies,',') 
												)
								THEN 1 ELSE 0 END	
			AND enabled =			CASE WHEN @Status IN (1,2,3) THEN 1
										 WHEN @Status = 4 THEN 0 ELSE enabled END

			AND ISNULL(cps.closed, 0) =	CASE WHEN @Status IN (1,2) THEN 0 
										 WHEN @Status = 3 THEN 1 ELSE ISNULL(cps.closed, 0) END

			AND ISNULL(cps.reject, 0) = CASE WHEN @Status = 1 THEN 0
										 WHEN @Status = 2 THEN 1 ELSE ISNULL(cps.reject, 0) END
			AND (@IsInternalAdmin = 0 OR site NOT IN (SELECT site FROM @DenySite ))
			AND (@IsDataLimited=0 OR (@IsDataLimited=1 AND (l.LimitDays IS NOT NULL OR l.MinDate IS NOT NULL)))
			AND ISNULL(cps.Locked,0) >= CASE WHEN @Status = 5 THEN 1 ELSE 0 END
			AND 1 = CASE WHEN @IsNoDownlines = 0 THEN 1
						WHEN @IsNoDownlines = 1 AND Downlines = 0 THEN 1
						ELSE 0 END

		SELECT @TotalRows = @@ROWCOUNT
	END
	ELSE
	BEGIN
		INSERT INTO @tmpSuperList(CustID, Downlines, username, LimitDays, MinDate, RowNumber)
		SELECT ci.custID, d.Downlines, ci.username, LimitDays, MinDate,
			ROW_NUMBER() OVER(ORDER BY ci.enabled desc, cps.closed, ISNULL(cps.reject,0), c.username) as RowNumber
		FROM dbo.custinfo ci WITH(NOLOCK)
			INNER JOIN Customer c WITH(NOLOCK) ON c.custid = ci.custid
			CROSS APPLY  (SELECT CASE WHEN CloseInfo > 0 THEN 1 ELSE 0 END AS closed
										, CASE WHEN SuspendInfo > 0 THEN 1 ELSE 0 END AS reject
										, Locked
									FROM dbo.CustProductStatus  WITH(NOLOCK)
									WHERE CustID = ci.custid
								) AS cps
			LEFT JOIN dbo.Age_CustDateLimit l WITH(NOLOCK) ON c.CustID=l.CustId
			CROSS APPLY (SELECT COUNT(1) Downlines 
							FROM custInfo cif WITH (NOLOCK)
							WHERE cif.srecommend = ci.custID AND cif.roleid = 3 
						) d
		WHERE ci.custid IN (SELECT custid FROM dbo.Acc_CustGroup  WITH(NOLOCK) WHERE GroupName = @GroupName)
			AND ci.roleid = 4	
			AND 1 = CASE WHEN @Currencies = '' 
								OR ci.currency IN (SELECT value FROM STRING_SPLIT(@Currencies,',') 
												)
								THEN 1 ELSE 0 END	
			AND enabled =			CASE WHEN @Status IN (1,2,3) THEN 1
										 WHEN @Status = 4 THEN 0 ELSE enabled END

			AND ISNULL(cps.closed, 0) =	CASE WHEN @Status IN (1,2) THEN 0 
										 WHEN @Status = 3 THEN 1 ELSE ISNULL(cps.closed, 0) END

			AND ISNULL(cps.reject, 0) = CASE WHEN @Status = 1 THEN 0
										 WHEN @Status = 2 THEN 1 ELSE ISNULL(cps.reject, 0) END
			AND (@IsInternalAdmin = 0 OR site NOT IN (SELECT site FROM @DenySite ))
			AND (@IsDataLimited=0 OR (@IsDataLimited=1 AND (l.LimitDays IS NOT NULL OR l.MinDate IS NOT NULL)))
			AND c.username LIKE @UserName + '%'
			AND ISNULL(cps.Locked,0) >= CASE WHEN @Status = 5 THEN 1 ELSE 0 END
			AND 1 = CASE WHEN @IsNoDownlines = 0 THEN 1
						WHEN @IsNoDownlines = 1 AND Downlines = 0 THEN 1
						ELSE 0 END

		SELECT @TotalRows = @@ROWCOUNT
	END	

	IF @RowStart > @TotalRows
	BEGIN
		SET @PageIndex = 1
		SELECT @RowStart = @PageSize * (@PageIndex - 1)  + 1
		SELECT @RowEnd = @RowStart + @PageSize - 1 
	END
	
	--check not subgroup 
	IF NOT EXISTS (SELECT 1 
				FROM NAP_UserControl.dbo.eaGroup WITH(NOLOCK)
				WHERE GroupName = @GroupName
					AND ParentID > 0
				)
	BEGIN			
		;WITH tmp AS(
			SELECT custid,
				STUFF((
				SELECT ',' + GroupName 
				FROM Acc_CustGroup WITH(NOLOCK)
				WHERE CustID = t.custid
					AND GroupName IN (SELECT GroupName 
									FROM NAP_UserControl.dbo.eaGroup WITH(NOLOCK) 
									WHERE ParentID > 0
									)
					FOR XML PATH('')),1,1,'') as SubGroup	
			FROM @tmpSuperList t			
		)
		UPDATE t2
		SET t2.SubGroup = tmp.SubGroup
		FROM @tmpSuperList t2 
			INNER JOIN tmp ON tmp.custid = t2.custid
	END
	
	SELECT	c.custid,
			c.username,
			ci.enabled,
			(SELECT e.currency FROM Exchange e WITH(NOLOCK) WHERE e.ExchangeId =c.currency) as currency,
			cps.closed,
			
			ISNULL(cps.reject, 0) AS suspended,
			c.roleid,
			ISNULL(cp.firstname, '') AS firstname,
			ISNULL(cp.lastname, '') AS lastname,			
			c.creatdate as createdate,
			ISNULL(c.iplogin, '') as lastloginip,
			CAST(1 AS BIT) AS UplineDoubleCommLosing,
			ci.DoubleCommLosing,
			ISNULL(cl.ClosedReason,0) AS ClosedReason,	
			sl.Downlines,
			sl.LimitDays,
			sl.MinDate,	
			sl.SubGroup,

			MAX(CASE WHEN cda.SportType = 1 and cda.BetType = 1 THEN cda.Discount ELSE 0 END) AS groupa,
			MAX(CASE WHEN cda.SportType = 1 and cda.BetType = 3 THEN cda.Discount ELSE 0 END) AS groupb,
			MAX(CASE WHEN cda.SportType = 1 and cda.BetType = 7 THEN cda.Discount ELSE 0 END) AS groupc,
			MAX(CASE WHEN cda.SportType = 1 and cda.BetType = 8 THEN cda.Discount ELSE 0 END) AS groupd,
			MAX(CASE WHEN cda.SportType = 2 and cda.BetType = 1 THEN 1		    ELSE 0 END) AS IsMyanmarOdds,
			MAX(CASE WHEN cda.SportType = 2 and cda.BetType = 1 THEN cda.Discount ELSE 0 END) AS discountMyanmarOdds,
			MAX(CASE WHEN cda.SportType = 1 and cda.BetType = 5 THEN cda.Discount ELSE 0 END) AS discount1x2,
			MAX(CASE WHEN cda.SportType = 1 and cda.BetType = 4 THEN cda.Discount ELSE 0 END) AS discountcs,
			ISNULL(cps.Locked,0) AS Locked

	FROM @tmpSuperList sl
		INNER JOIN dbo.customer c WITH(NOLOCK) on sl.custid = c.custid
		INNER JOIN dbo.custinfo ci WITH(NOLOCK) on ci.custid = c.custid
		CROSS APPLY  (SELECT CASE WHEN CloseInfo > 0 THEN 1 ELSE 0 END AS closed
										, CASE WHEN SuspendInfo > 0 THEN 1 ELSE 0 END AS reject
										, Locked
									FROM dbo.CustProductStatus  WITH(NOLOCK)
									WHERE CustID = ci.custid
								) AS cps
		INNER JOIN dbo.CustSuperProfile cp WITH(NOLOCK) ON cp.CustId = c.CustId
		LEFT JOIN CustDiscount3rd_Agent cda WITH (NOLOCK) ON c.custid = cda.CustID AND cda.SportType IN (1,2)
		LEFT JOIN CustLoginInfo cl WITH(NOLOCK) ON c.custid=cl.CustID

	WHERE RowNumber BETWEEN @RowStart AND @RowEnd

	GROUP BY c.custid, c.username, ci.enabled, cps.closed, cps.reject, c.roleid, c.currency,
			cp.firstname, cp.lastname, c.creatdate, c.iplogin,		 
			ci.DoubleCommLosing, cl.ClosedReason, sl.Downlines,
			sl.LimitDays, sl.MinDate, sl.SubGroup, cl.SecurityCode, sl.RowNumber,cps.Locked
	
	ORDER BY RowNumber
			   
END
GO