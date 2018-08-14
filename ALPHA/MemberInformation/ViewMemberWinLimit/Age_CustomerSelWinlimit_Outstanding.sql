/*<info serverAlias="DB042-bodb02" executers="bodbDownlineNet,bodbDownlineNetView" viewers="vnteam" isFunction="0"></info>*/
USE bodb02
GO

ALTER PROCEDURE	dbo.Age_CustomerSelWinlimit_Outstanding
					@CustId			INT
				,	@MinCustId		INT
				,	@MaxCustID		INT
				,	@SportType		SMALLINT
				,	@BetType		SMALLINT
				,	@username		NVARCHAR(50)	= ''
				,	@PlayerId		INT				= NULL
				,	@mrecommend		INT				= 0
				,	@recommend		INT				= 0
AS
/*
	Create:	20180717@Elodie
	Task:	Outstanding of Customer
	DB:		DB042/bodb02

	Revisions:
		- 20180717@Elodie: Get outstanding of customer
	Param's Explanation:
		- @CustID: SAgentID
*/
BEGIN

	SET NOCOUNT ON

	DECLARE @RoleId TINYINT, @srecommend INT, @PlayerId_IBC INT
	CREATE TABLE #MemberBalance (CustId INT)

	SELECT @RoleId = RoleId, @srecommend = srecommend
	FROM dbo.CustInfo c WITH(NOLOCK)
	WHERE CustId = @CustId

	IF	@username = ''
		SELECT @username = NULL
	
	IF @PlayerId IS NOT NULL
	BEGIN
		SELECT @PlayerId_IBC = cm.Custid
		FROM dbo.CustUserMapping3rd cm WITH (NOLOCK)
			INNER JOIN bodb02.dbo.Products p WITH (NOLOCK) ON p.VendorID = cm.VendorID
		WHERE p.ProductID = @ProductID AND cm.PlayerID3rd = @PlayerId
	END

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
			AND	c.custid = ISNULL(@PlayerId, c.custid)
			AND c.custid BETWEEN @MinCustId AND @MaxCustID
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
			AND	c.custid = ISNULL(@PlayerId, c.custid)
			AND c.custid BETWEEN @MinCustId AND @MaxCustID
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
			AND	c.custid = ISNULL(@PlayerId, c.custid)
			AND c.custid BETWEEN @MinCustId AND @MaxCustID
			AND c.Enabled = 1
		GROUP BY c.custid
	END
	
	SELECT	mb.CustId
		,	SUM(b.actual_stake) AS Outstanding
	FROM #MemberBalance mb
		INNER JOIN	dbo.bettrans AS b WITH (NOLOCK) ON mb.CustId = b.CustId 
	WHERE b.statusID = 0 AND b.BetType = @BetType AND b.matchid = @SportType
	GROUP BY mb.custid

	DROP TABLE #MemberBalance
END
GO