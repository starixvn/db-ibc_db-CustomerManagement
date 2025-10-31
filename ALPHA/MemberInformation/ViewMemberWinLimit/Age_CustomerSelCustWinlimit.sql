/*<info serverAlias="DBCUST-CustDB" executers="wsv_alp,wsv_alpv" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE	dbo.Age_CustomerSelCustWinlimit
					@CustId			INT
				,	@ProductID		TINYINT
				,	@BetType		SMALLINT
				,	@SportType		SMALLINT
				,	@username		NVARCHAR(50)	= ''
				,	@PlayerId_IBC	INT				= NULL
				,	@mrecommend		INT				= 0
				,	@recommend		INT				= 0
				,	@PageSize		INT				= 500
				,	@PageIndex		INT				= 1
				,	@TotalRows		INT				= 0			OUTPUT
				,     @SettingStatus    TINYINT = 0
				,	@isDirectDownline BIT
				,   @AccountType	TINYINT 		= 2
AS
/*
	Create:	20150715@Patrick
	Task:	Member win limit of Super
	DB:		DBCUST/Custdb

	Revisions:
		- 20160216@Billy:	Implement Max Win Loss Limit for DCS Product - [Redmine: #52268]
		- 20160318@Billy:	Fix MaxLossLimit for RnG Casino - [Redmine: #54335]
		- 20170116@Helen:  Alpha - Member Win Limit report - Current Win Loss amount and Balance show zero while member actually has tickets on RNG - [Redmine:70397]
		- 20180125@Winnie: Hide inactive products [RedmineID: #86086]
		- 20180703@Elodie: Poker Games Product - Support search by PlayerID [Redmine: #97675]
		- 20200511@Elodie: Change format of PlayerID [Redmine: #133755]
		- 20210513@Tina: Lock account & indirect close account [redmine: #148600]
		- 20220110@Eden: Saba Casino use DCS Setting [RedmineID: #164280]
		- 20221121@Eden: Unify RNG Lottery Customer Settings [RedmineID: #180640]
		- 20230804@Eden: Win loss limit - Change SP to allow dynamic seting [RedmineID: #180640]
		- 20230905@Eden: Enhance BBIN display [Redmine: #193539]
		- 20230928@Luke: Modify SPs to adapt in-house replication setup [Redmine: #194414]
		- 20240316@Eden: Unify Live RNG Casino [Redmine: #198960]
		- 20241107@Helios: Offer Direct Member for Super/Master [redmine: #211969]
		- 20250724@Helios: Agency Cash Service -Customer Setting Sprint 7 [redmine: #233474]
		- 20251031@Dave: Adjust Live Casino PT & Commission [Redmine: #242260]
		
	Param's Explanation:
		- @CustID: SAgentID
*/
BEGIN

	SET NOCOUNT ON

	DECLARE @RoleId TINYINT, @RowCount INT, @RowStart INT, @RowEnd INT, @srecommend INT, @VendorID SMALLINT, @Site NVARCHAR(50),@siteid SMALLINT=0, @currency smallint;
	SELECT @PageIndex = @PageIndex - 1
		, @RowStart = @PageSize * @PageIndex + 1
		, @RowEnd = @RowStart + @PageSize - 1

	CREATE TABLE #MemberBalance (
		CustId INT,
		closed BIT,
		reject BIT,
		Locked TINYINT,
		ServiceType TINYINT
	)

	SELECT @RoleId = RoleId, @srecommend = srecommend, @Site = s.site, @siteid = s.siteid
	FROM dbo.Customer c WITH(NOLOCK)
		INNER JOIN dbo.Site s WITH (NOLOCK) ON c.site = s.site
	WHERE c.CustId = @CustId

	--> Get Representative sporttype, bettype of this sport( use for settingtype 22 storeing way)
	SELECT @SportType = ISNULL(SporttypeRefWinlossLimit,@SportType), 
			@BetType = ISNULL(BettypeRefWinlossLimit,@BetType)
	FROM	dbo.f_CustSetting_ProductProfileSel(22, @SettingStatus,@siteid,@currency) AS s
		INNER JOIN f_CustSetting_SportBetTypeSettingMatrix (@SettingStatus) st
			ON st.SporttypeRefWinlossLimit = s.SportType 
			AND st.BettypeRefWinlossLimit = s.Bettype
			AND st.isLicensee = 0 AND st.Site IN (@Site, 'ALL')
	WHERE st.SportType = @SportType
		AND st.bettype = @BetType
		AND st.isDeleted = 0


	SELECT @VendorID = VendorID FROM DBACC.bodb02.dbo.Products WITH (NOLOCK) WHERE ProductID = @ProductID

	IF	@username = ''
		SELECT @username = NULL

	IF @RoleId = 4
	BEGIN
		IF @isDirectDownline = 0			-- Get Normal Member
		BEGIN
			INSERT INTO #MemberBalance(CustId, closed, reject, Locked, ServiceType)
			SELECT  
					c.custid
			,		cps.closed
			,		cps.reject
			,		cps.Locked
			,		cps.ServiceType
			FROM dbo.CustInfo c WITH(NOLOCK)
			CROSS APPLY (SELECT TOP 1 CASE WHEN CloseInfo > 0 THEN 1 ELSE 0 END AS closed
									, CASE WHEN SuspendInfo > 0 THEN 1 ELSE 0 END AS reject
									, ISNULL(Locked, 0) AS Locked
									, ISNULL(ServiceType, 0) AS ServiceType
								FROM dbo.CustProductStatus WITH(NOLOCK)
								WHERE CustID = c.custid
							) AS cps
			WHERE c.srecommend = @CustId
				AND roleid = 1
				AND c.mrecommend = @mrecommend
				AND (@recommend = 0 OR (@recommend <> 0 AND c.recommend = @recommend))
				AND	c.username LIKE '%' + ISNULL(@username, c.username) + '%'
				AND	c.custid = ISNULL(@PlayerId_IBC, c.custid)
				AND c.Enabled = 1
				AND cps.ServiceType = CASE WHEN @AccountType = 2 THEN cps.ServiceType ELSE @AccountType END
			GROUP BY c.custid, cps.closed, cps.reject, cps.Locked, cps.ServiceType
		END
		ELSE							-- Get Super Direct Member
		BEGIN
			INSERT INTO #MemberBalance(CustId, closed, reject, Locked, ServiceType)
			SELECT  
					c.custid
			,		cps.closed
			,		cps.reject
			,		cps.Locked
			,		cps.ServiceType
			FROM dbo.CustInfo c WITH(NOLOCK)
			CROSS APPLY (SELECT TOP 1 CASE WHEN CloseInfo > 0 THEN 1 ELSE 0 END AS closed
									, CASE WHEN SuspendInfo > 0 THEN 1 ELSE 0 END AS reject
									, ISNULL(Locked, 0) AS Locked
									, ISNULL(ServiceType, 0) AS ServiceType
								FROM dbo.CustProductStatus WITH(NOLOCK)
								WHERE CustID = c.custid
							) AS cps
			WHERE c.srecommend = @CustID
				AND c.recommend = -4
				AND roleid = 1
				AND (@recommend = 0 OR (@recommend <> 0 AND c.recommend = @recommend))
				AND	c.username LIKE '%' + ISNULL(@username, c.username) + '%'
				AND	c.custid = ISNULL(@PlayerId_IBC, c.custid)
				AND c.Enabled = 1
				AND cps.ServiceType = CASE WHEN @AccountType = 2 THEN cps.ServiceType ELSE @AccountType END
			GROUP BY c.custid, cps.closed, cps.reject, cps.Locked, cps.ServiceType
		END
	END
	ELSE IF @RoleId = 3
	BEGIN
		IF @isDirectDownline = 0			-- Get Normal Member
		BEGIN
			INSERT INTO #MemberBalance(CustId, closed, reject, Locked, ServiceType)
			SELECT  
					c.custid
			,		cps.closed
			,		cps.reject
			,		cps.Locked
			,		cps.ServiceType
			FROM dbo.CustInfo c WITH(NOLOCK)
			CROSS APPLY (SELECT TOP 1 CASE WHEN CloseInfo > 0 THEN 1 ELSE 0 END AS closed
									, CASE WHEN SuspendInfo > 0 THEN 1 ELSE 0 END AS reject
									, ISNULL(Locked, 0) AS Locked
									, ISNULL(ServiceType, 0) AS ServiceType
								FROM dbo.CustProductStatus WITH(NOLOCK)
								WHERE CustID = c.custid
							) AS cps
			WHERE c.mrecommend = @CustId
				AND roleid = 1
				AND c.srecommend = @srecommend 
				AND c.recommend = @recommend
				AND	c.username LIKE '%' + ISNULL(@username, c.username) + '%'
				AND	c.custid = ISNULL(@PlayerId_IBC, c.custid)
				AND c.Enabled = 1
				AND cps.ServiceType = CASE WHEN @AccountType = 2 THEN cps.ServiceType ELSE @AccountType END
			GROUP BY c.custid, cps.closed, cps.reject, cps.Locked, cps.ServiceType
		END
		ELSE							-- Get Master Direct Member
		BEGIN
			INSERT INTO #MemberBalance(CustId, closed, reject, Locked, ServiceType)
			SELECT  
					c.custid
			,		cps.closed
			,		cps.reject
			,		cps.Locked
			,		cps.ServiceType
			FROM dbo.CustInfo c WITH(NOLOCK)
			CROSS APPLY (SELECT TOP 1 CASE WHEN CloseInfo > 0 THEN 1 ELSE 0 END AS closed
									, CASE WHEN SuspendInfo > 0 THEN 1 ELSE 0 END AS reject
									, ISNULL(Locked, 0) AS Locked
									, ISNULL(ServiceType, 0) AS ServiceType
								FROM dbo.CustProductStatus WITH(NOLOCK)
								WHERE CustID = c.custid
							) AS cps
			WHERE c.mrecommend = @CustId
				AND roleid = 1
				AND c.srecommend = @srecommend 
				AND c.recommend = -3
				AND	c.username LIKE '%' + ISNULL(@username, c.username) + '%'
				AND	c.custid = ISNULL(@PlayerId_IBC, c.custid)
				AND c.Enabled = 1
				AND cps.ServiceType = CASE WHEN @AccountType = 2 THEN cps.ServiceType ELSE @AccountType END
			GROUP BY c.custid, cps.closed, cps.reject, cps.Locked, cps.ServiceType
		END
	END
	ELSE IF @RoleId = 2
	BEGIN
		INSERT INTO #MemberBalance(CustId, closed, reject, Locked, ServiceType)
		SELECT  
				c.custid
		,		cps.closed
		,		cps.reject
		,		cps.Locked
		,		cps.ServiceType
		FROM dbo.CustInfo c WITH(NOLOCK)
		CROSS APPLY (SELECT TOP 1 CASE WHEN CloseInfo > 0 THEN 1 ELSE 0 END AS closed
								, CASE WHEN SuspendInfo > 0 THEN 1 ELSE 0 END AS reject
								, ISNULL(Locked, 0) AS Locked
								, ISNULL(ServiceType, 0) AS ServiceType
							FROM dbo.CustProductStatus WITH(NOLOCK)
							WHERE CustID = c.custid
						) AS cps
		WHERE c.recommend = @CustId
			AND roleid = 1
			AND c.srecommend = @srecommend
			AND	c.username LIKE '%' + ISNULL(@username, c.username) + '%'
			AND	c.custid = ISNULL(@PlayerId_IBC, c.custid)
			AND c.Enabled = 1
			AND cps.ServiceType = CASE WHEN @AccountType = 2 THEN cps.ServiceType ELSE @AccountType END
		GROUP BY c.custid, cps.closed, cps.reject, cps.Locked, cps.ServiceType
	END
	
	--Calc total rows
	SELECT @TotalRows = COUNT(1)
	FROM #MemberBalance
	
	SELECT	tmp.RowNumber
		,	tmp.closed
		,	tmp.Enabled
		,	tmp.suspended
		,	tmp.username
		,	tmp.firstname
		,	tmp.lastname
		,	tmp.credit
		,	tmp.CustId
		,	SUBSTRING(PlayerID3rd, PATINDEX('%$%', PlayerID3rd) + 1, (LEN(PlayerId3rd) - PATINDEX('%$%', PlayerID3rd))) AS PlayerId
		,	tmp.IsAutoReset
		,	CASE WHEN @ProductID = 47 THEN -3 ELSE tmp.MaxWinLimit END AS MaxWinLimit
		,	tmp.MaxLossLimit
		,	tmp.Locked
		,   tmp.ClosedReason
		,	tmp.ServiceType
	FROM	(
		SELECT	ROW_NUMBER() OVER (ORDER BY ci.Enabled DESC, mb.closed ASC, ISNULL(mb.reject, 0) ASC, ci.username ASC) AS RowNumber
			,	ci.username
			,	CAST(mb.closed AS BIT) closed
			,	ci.enabled
			,	CAST(ISNULL(mb.reject, 0) AS BIT) AS suspended
			,   mb.Locked
			,   li.ClosedReason
			,	ci.credit
			,	mb.CustId				
			,	c.firstname
			,	c.lastname
			,	cwllm.IsAutoReset
			,	cwllm.MaxWinLimit
			,	cwllm.MaxLossLimit
			,	mb.ServiceType
		FROM		#MemberBalance mb
		INNER JOIN	dbo.custInfo ci WITH (NOLOCK) 
				ON	mb.CustId = ci.custid
		INNER JOIN	dbo.customer c WITH (NOLOCK) 
				ON	mb.CustId = c.CustId
		INNER JOIN	dbo.CustWinLossLimit_Member AS cwllm WITH (NOLOCK) 
				ON	ci.CustId = cwllm.CustId 
				AND	cwllm.SportType = @SportType 
				AND	cwllm.BetType = @BetType
		INNER JOIN CustLoginInfo_Member li WITH (NOLOCK) ON li.CustID = ci.custid
		GROUP BY	ci.username, mb.closed, ci.Enabled, ISNULL(mb.reject, 0), mb.Locked, ci.credit, c.firstname, c.lastname
				,	cwllm.IsAutoReset, cwllm.MaxWinLimit, cwllm.MaxLossLimit, mb.custid, li.ClosedReason, mb.ServiceType
	) tmp
		LEFT JOIN dbo.CustUserMapping3rd cm ON cm.Custid = tmp.CustId AND cm.VendorID = @VendorID
	WHERE	tmp.RowNumber BETWEEN @RowStart AND @RowEnd
	ORDER BY	RowNumber ASC
	OPTION (RECOMPILE)

	DROP TABLE #MemberBalance
END
GO