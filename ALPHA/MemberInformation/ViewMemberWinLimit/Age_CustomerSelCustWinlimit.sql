/*<info serverAlias="DBCUST-CustDB" executers="bodbDownlineNet,bodbDownlineNetView" viewers="vnteam" isFunction="0"></info>*/
USE CustDB
GO

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

	Param's Explanation:
		- @CustID: SAgentID
*/
BEGIN

	SET NOCOUNT ON

	DECLARE @RoleId TINYINT, @RowCount INT, @RowStart INT, @RowEnd INT, @srecommend INT, @VendorID SMALLINT
	SELECT @PageIndex = @PageIndex - 1
		, @RowStart = @PageSize * @PageIndex + 1
		, @RowEnd = @RowStart + @PageSize - 1

	CREATE TABLE #MemberBalance (CustId INT)

	SELECT @RoleId = RoleId, @srecommend = srecommend
	FROM dbo.CustInfo c WITH(NOLOCK)
	WHERE CustId = @CustId

	SELECT @VendorID = VendorID FROM DBACC.bodb02.dbo.Products WITH (NOLOCK) WHERE ProductID = @ProductID

	IF	@username = ''
		SELECT @username = NULL

	IF @RoleId = 4
	BEGIN
		INSERT INTO #MemberBalance(CustId)
		SELECT c.custid
		FROM dbo.CustInfo c WITH(NOLOCK)
		WHERE c.srecommend = @CustId
			AND roleid = 1
			AND c.mrecommend = @mrecommend
			AND (@recommend = 0 OR (@recommend <> 0 AND c.recommend = @recommend))
			AND	c.username LIKE '%' + ISNULL(@username, c.username) + '%'
			AND	c.custid = ISNULL(@PlayerId_IBC, c.custid)
			AND c.Enabled = 1
		GROUP BY c.custid
	END
	ELSE IF @RoleId = 3
	BEGIN
		INSERT INTO #MemberBalance(CustId)
		SELECT c.custid
		FROM dbo.CustInfo c WITH(NOLOCK)
		WHERE c.mrecommend = @CustId
			AND roleid = 1
			AND c.srecommend = @srecommend 
			AND c.recommend = @recommend
			AND	c.username LIKE '%' + ISNULL(@username, c.username) + '%'
			AND	c.custid = ISNULL(@PlayerId_IBC, c.custid)
			AND c.Enabled = 1
		GROUP BY c.custid
	END
	ELSE IF @RoleId = 2
	BEGIN
		INSERT INTO #MemberBalance(CustId)
		SELECT c.custid
		FROM dbo.CustInfo c WITH(NOLOCK)
		WHERE c.recommend = @CustId
			AND roleid = 1
			AND c.srecommend = @srecommend
			AND	c.username LIKE '%' + ISNULL(@username, c.username) + '%'
			AND	c.custid = ISNULL(@PlayerId_IBC, c.custid)
			AND c.Enabled = 1
		GROUP BY c.custid
	END
	
	--Calc total rows
	SELECT @TotalRows = COUNT(1)
	FROM #MemberBalance
	
	
	IF EXISTS (SELECT 1 FROM dbo.ProductSettingDetail AS psd WHERE psd.SportType = @SportType AND psd.BetType = @BetType)
	BEGIN
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
			,	tmp.MaxWinLimit
			,	tmp.MaxLossLimit
			,	tmp.Locked
			,   tmp.ClosedReason
		FROM	(
			SELECT	ROW_NUMBER() OVER (ORDER BY ci.Enabled DESC, cps.closed, ISNULL(cps.reject, 0), ci.username) AS RowNumber
				,	ci.username
				,	CAST(cps.closed AS BIT) closed
				,	ci.enabled
				,	CAST(ISNULL(cps.reject, 0) AS BIT) AS suspended
				,   cps.Locked
				,   li.ClosedReason
				,	ci.credit
				,	mb.CustId				
				,	c.firstname
				,	c.lastname
				,	cwllm.IsAutoReset
				,	cwllm.MaxWinLimit
				,	cwllm.MaxLossLimit
			FROM		#MemberBalance mb
			INNER JOIN	dbo.custInfo ci WITH (NOLOCK) 
					ON	mb.CustId = ci.custid
			INNER JOIN	dbo.customer c WITH (NOLOCK) 
					ON	mb.CustId = c.CustId
			INNER JOIN	dbo.CustWinLossLimit_Member AS cwllm WITH (NOLOCK) 
					ON	ci.CustId = cwllm.CustId 
					AND	cwllm.SportType = @SportType 
					AND	cwllm.BetType = @BetType
			CROSS APPLY  (SELECT CASE WHEN CloseInfo > 0 THEN 1 ELSE 0 END AS closed
										, CASE WHEN SuspendInfo > 0 THEN 1 ELSE 0 END AS reject
										, ISNULL(Locked, 0) Locked
									FROM dbo.CustProductStatus  WITH(NOLOCK)
									WHERE CustID = ci.custid
								) AS cps
			INNER JOIN CustLoginInfo_Member li WITH (NOLOCK) ON li.CustID = ci.custid
			GROUP BY	ci.username, cps.closed, ci.Enabled, ISNULL(cps.reject, 0), cps.Locked, ci.credit, c.firstname, c.lastname
					,	cwllm.IsAutoReset, cwllm.MaxWinLimit, cwllm.MaxLossLimit, mb.custid, li.ClosedReason
		) tmp
			LEFT JOIN dbo.CustUserMapping3rd cm ON cm.Custid = tmp.CustId AND cm.VendorID = @VendorID
		WHERE	tmp.RowNumber BETWEEN @RowStart AND @RowEnd
		ORDER BY	RowNumber
		OPTION (RECOMPILE)
	END
	ELSE
	BEGIN
		SELECT	RowNumber, closed, enabled, suspended, username, firstname, lastname, credit, CustId, IsAutoReset, MaxWinLimit, MaxLossLimit, Locked, ClosedReason
		FROM (
			SELECT ROW_NUMBER() OVER (ORDER BY c.enabled DESC, cps.closed, ISNULL(cps.reject, 0), c.username) AS RowNumber
				, c.username
				, CAST(cps.closed AS BIT) closed
				, c.enabled
				, CAST(ISNULL(cps.reject, 0) AS BIT) AS suspended
				, cps.Locked
				, li.ClosedReason
				, c.credit
				, b.CustId
				, cc.firstname
				, cc.lastname
				, IsAutoReset
				, MaxWinLimit
				, CASE WHEN @SportType = 255 THEN NULL ELSE MaxLossLimit END MaxLossLimit
			FROM #MemberBalance b 
				INNER JOIN dbo.custInfo c WITH(NOLOCK) ON b.CustId = c.custid
				INNER JOIN dbo.customer cc WITH(NOLOCK) ON b.CustId = cc.CustId
				INNER JOIN dbo.CustWinLimit cwl WITH(NOLOCK) ON c.CustId = cwl.CustId AND cwl.SportType = @SportType AND cwl.BetType = @BetType
				CROSS APPLY  (SELECT CASE WHEN CloseInfo > 0 THEN 1 ELSE 0 END AS closed
										, CASE WHEN SuspendInfo > 0 THEN 1 ELSE 0 END AS reject
										, ISNULL(Locked, 0) Locked
									FROM dbo.CustProductStatus  WITH(NOLOCK)
									WHERE CustID = c.custid
								) AS cps
				INNER JOIN CustLoginInfo_Member li WITH (NOLOCK) ON li.CustID = c.custid
			GROUP BY c.username, cps.closed, enabled, ISNULL(cps.reject, 0), cps.Locked, credit, firstname, lastname
				, IsAutoReset, MaxWinLimit, MaxLossLimit, b.custid, li.ClosedReason
		)tmp
		WHERE tmp.RowNumber BETWEEN @RowStart AND @RowEnd
		ORDER BY RowNumber
		OPTION (RECOMPILE)
	END

	DROP TABLE #MemberBalance
END
GO