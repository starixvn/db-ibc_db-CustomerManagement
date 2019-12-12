/*<info serverAlias="DBCUST-CUSTDB" executers="bodbExtAccNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_CustomerSelByMAg] 
    @mrecommend		INT,
	@UserName		VARCHAR(30) = NULL,
    @Status			TINYINT = 0,
	@UserID			INT,
	@PageIndex		INT = 1,
	@PageSize		INT = 500,
	@TotalRows		INT = 0 OUTPUT
 
AS  
/*  
	Created by: Scott  
	Date: 2012-12-17  
	Task : Customer list by MASTER
	DB: DBCUST/CustDB
	Original SP: Acc_CustomerSelByMAg
	Revisions:  
		- 20130121@Dan: Move sp from DB053/bodb02 to DBEAS/bodb_EAS
		- 20130517@Lukas: 
				fix bug - wrong comm rate 
				add filter to reduce workload
		- 20131023@Elodie: Get more field HideVirtualSports, DisableCasinoBonus, DisableHRFixedOdds			
		- 20140120@Elodie: Hot fix to get information of disabled customer
		- 20140626@Logan: 1.Add Keno status [Redmine: #18268]
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
		- 20171027@Johnson: fix the unsynchronized setting, add SyncGDUpline [Redmine: #72973]
		- 20171001@Elodie: BullFighting Product - [Redmine: #81664]
		- 20180125@Winnie: Hide inactive products [RedmineID: #86086]
		- 20180703@Elodie: Poker Games Product - [Redmine: #97675]
		- 20180830@Elodie: Add new bettype of Poker Games Product - [Redmine: #97675]
		- 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]
		- 20180919@Winnie: Add new bettype of Esports Product - [Redmine: #101526]
		- 20190119@Kan: Add DoubleCommLosingUpline - [Redmine: #106591]
		- 20190731@Eden: add bettype 1525,1526 for Keno gametype - [Redmine: #116466]
		- 20190906@Eden: 3rd party products - Remove InActive Products Phase 2 [Redmine: #118699]
		- 20181112@Elodie: Rewrite SP for function customer list - [Redmine: #104570]

	Example: EXEC EAS_CustomerSelByMAg @mrecommend=4797617, @UserID = 8   
    
*/
BEGIN
    SET NOCOUNT ON  

    DECLARE @tmpAgentList TABLE (custID INT, username VARCHAR(30), RowNumber INT)
	DECLARE @DenySite TABLE (siteid INT, site NVARCHAR(50), SpecialGroup TINYINT)
	DECLARE @IsInternalAdmin BIT = 0, @UplineDoubleCommLosing BIT = 0
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
		INSERT INTO @tmpAgentList(CustID, username, RowNumber)
		SELECT ci.custID, ci.username,
			ROW_NUMBER() OVER(ORDER BY ci.enabled desc, ci.closed, ISNULL(ci.reject,0), c.username) as RowNumber
		FROM dbo.custinfo ci WITH(NOLOCK)
			INNER JOIN Customer c WITH(NOLOCK) ON c.custid = ci.custid
			LEFT JOIN dbo.Age_CustDateLimit l WITH(NOLOCK) ON c.CustID=l.CustId
		WHERE ci.mrecommend = @mrecommend
			AND ci.roleid = 2	
			AND enabled =			CASE WHEN @Status IN (1,2,3) THEN 1
										 WHEN @Status = 4 THEN 0 ELSE enabled END

			AND ISNULL(closed, 0) =	CASE WHEN @Status IN (1,2) THEN 0 
										 WHEN @Status = 3 THEN 1 ELSE ISNULL(closed, 0) END

			AND ISNULL(reject, 0) = CASE WHEN @Status = 1 THEN 0
										 WHEN @Status = 2 THEN 1 ELSE ISNULL(reject, 0) END
			AND (@IsInternalAdmin = 0 OR site NOT IN (SELECT site FROM @DenySite ))

		SELECT @TotalRows = @@ROWCOUNT
	END
	ELSE
	BEGIN
		INSERT INTO @tmpAgentList(CustID, username, RowNumber)
		SELECT ci.custID, ci.username,
			ROW_NUMBER() OVER(ORDER BY ci.enabled desc, ci.closed, ISNULL(ci.reject,0), c.username) as RowNumber
		FROM dbo.custinfo ci WITH(NOLOCK)
			INNER JOIN Customer c WITH(NOLOCK) ON c.custid = ci.custid
			LEFT JOIN dbo.Age_CustDateLimit l WITH(NOLOCK) ON c.CustID=l.CustId
		WHERE ci.mrecommend = @mrecommend
			AND ci.roleid = 2			
			AND enabled =			CASE WHEN @Status IN (1,2,3) THEN 1
										 WHEN @Status = 4 THEN 0 ELSE enabled END

			AND ISNULL(closed, 0) =	CASE WHEN @Status IN (1,2) THEN 0 
										 WHEN @Status = 3 THEN 1 ELSE ISNULL(closed, 0) END

			AND ISNULL(reject, 0) = CASE WHEN @Status = 1 THEN 0
										 WHEN @Status = 2 THEN 1 ELSE ISNULL(reject, 0) END
			AND (@IsInternalAdmin = 0 OR site NOT IN (SELECT site FROM @DenySite ))
			AND c.username LIKE @UserName + '%'

		SELECT @TotalRows = @@ROWCOUNT
	END

	SELECT @UplineDoubleCommLosing = DoubleCommLosing FROM dbo.Custinfo WITH(NOLOCK) WHERE custid = @mrecommend

	SELECT	c.custid,
			c.username,
			ci.enabled,
			ci.closed,
			ISNULL(ci.reject, 0) AS suspended,
			c.roleid,
			ISNULL(c.firstname, '') AS firstname,
			ISNULL(c.lastname, '') AS lastname,			
			c.creatdate as createdate,
			ISNULL(c.iplogin, '') as lastloginip,
			@UplineDoubleCommLosing AS UplineDoubleCommLosing,
			ci.DoubleCommLosing,
			ISNULL(cl.ClosedReason,0) AS ClosedReason,			

			MAX(CASE WHEN cs.bettype = 1 and cs.sporttype=1 THEN cs.groupa ELSE 0 END) AS groupa,
			MAX(CASE WHEN cs.bettype = 1 and cs.sporttype=1 THEN cs.groupb ELSE 0 END) AS groupb,
			MAX(CASE WHEN cs.bettype = 1 and cs.sporttype=1 THEN cs.groupc ELSE 0 END) AS groupc,
			MAX(CASE WHEN cs.bettype = 1 and cs.sporttype=1 THEN cs.groupd ELSE 0 END) AS groupd,

			MAX(CASE WHEN cs.bettype = 5 and cs.sporttype = 1 then cs.discount ELSE 0 END) AS discount1x2,
			MAX(CASE WHEN cs.bettype = 4 and cs.sporttype = 1 then cs.discount ELSE 0 END) AS discountcs
           			
	FROM @tmpAgentList al
		INNER JOIN dbo.customer c WITH(NOLOCK) on al.custid = c.custid
		INNER JOIN dbo.custinfo ci WITH(NOLOCK) on ci.custid = c.custid
		LEFT JOIN dbo.CustSetting as cs WITH(NOLOCK) on c.custid = cs.custid AND cs.sporttype = 1 AND cs.bettype IN (1,5,4)
		LEFT JOIN CustLoginInfo cl WITH(NOLOCK) ON c.custid=cl.CustID
	WHERE RowNumber BETWEEN @RowStart AND @RowEnd	
	GROUP BY c.custid, c.username, ci.enabled, ci.closed, ci.reject, c.roleid, 
			c.firstname, c.lastname, c.creatdate, c.iplogin,		 
			ci.DoubleCommLosing, cl.ClosedReason,
			cl.SecurityCode, al.RowNumber
	
	ORDER BY RowNumber
END
GO