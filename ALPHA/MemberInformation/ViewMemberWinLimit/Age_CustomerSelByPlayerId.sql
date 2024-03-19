/*<info serverAlias="DBCUST-CustDB" executers="bodbDownlineNet,wsv_alp,bodbDownlineNetView,wsv_alpv" viewers="vnteam" isFunction="0"></info>*/
ALTER PROCEDURE	dbo.Age_CustomerSelByPlayerId
					@PlayerId		VARCHAR(50)	
				,	@ProductId		TINYINT	
				,	@CustId			INT
				,	@mrecommend		INT				= 0
				,	@recommend		INT				= 0
AS
/*
	Create:	20180815@Elodie
	Task:	Get CustID by PlayerId
	DB:		DBCUST/CustDB

	Revisions:
		- 20180815@Elodie: Get CustID by PlayerId [Redmine: 97675]
		- 20200511@Elodie: Change format of PlayerID [Redmine: #133755]
	Param's Explanation:
	Example: EXEC Age_CustomerSelByPlayerId @PlayerId = '12356', @ProductId = 42
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @RoleId TINYINT, @srecommend INT
	
	SELECT @RoleId = RoleId, @srecommend = srecommend
	FROM dbo.CustInfo c WITH(NOLOCK)
	WHERE CustId = @CustId

	IF @RoleId = 4
	BEGIN
		SELECT cm.Custid
		FROM dbo.CustUserMapping3rd cm WITH (NOLOCK)
			INNER JOIN dbo.custInfo c WITH (NOLOCK) ON c.custid = cm.Custid
			INNER JOIN DBACC.bodb02.dbo.Products p WITH (NOLOCK) ON p.VendorID = cm.VendorID
		WHERE p.ProductID = @ProductID AND cm.PlayerID3rd LIKE '%' + @PlayerId + '%'
			AND c.srecommend = @CustId
			AND c.roleid = 1
			AND c.mrecommend = @mrecommend
			AND (@recommend = 0 OR (@recommend <> 0 AND c.recommend = @recommend))
	END
	ELSE IF @RoleId = 3
	BEGIN
		SELECT cm.Custid
		FROM dbo.CustUserMapping3rd cm WITH (NOLOCK)
			INNER JOIN dbo.custInfo c WITH (NOLOCK) ON c.custid = cm.Custid
			INNER JOIN DBACC.bodb02.dbo.Products p WITH (NOLOCK) ON p.VendorID = cm.VendorID
		WHERE p.ProductID = @ProductID AND cm.PlayerID3rd LIKE '%' + @PlayerId + '%'
			AND c.mrecommend = @CustId
			AND c.roleid = 1
			AND c.srecommend = @srecommend 
			AND c.recommend = @recommend	
	END
	ELSE IF @RoleId = 2
	BEGIN
		SELECT cm.Custid
		FROM dbo.CustUserMapping3rd cm WITH (NOLOCK)
			INNER JOIN dbo.custInfo c WITH (NOLOCK) ON c.custid = cm.Custid
			INNER JOIN DBACC.bodb02.dbo.Products p WITH (NOLOCK) ON p.VendorID = cm.VendorID
		WHERE p.ProductID = @ProductID AND cm.PlayerID3rd LIKE '%' + @PlayerId + '%'
			AND c.recommend = @CustId
			AND c.roleid = 1
			AND c.srecommend = @srecommend 
	END	
END
GO