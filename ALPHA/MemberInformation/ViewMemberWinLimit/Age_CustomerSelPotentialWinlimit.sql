/*<info serverAlias="DBCUST-CustDB" executers="wsv_alp,wsv_alpv" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE	dbo.Age_CustomerSelPotentialWinlimit
				@CustId					INT
				,   @RoleId				TINYINT
				,	@username			NVARCHAR(50)	= ''
				,   @problemAccount 	TINYINT = 2
				,	@Status		 		VARCHAR(30) = ''
				, 	@IsGetAll			BIT = 0
				,	@PageSize			INT	= 100
				,	@PageIndex			INT	= 1
				,	@TotalRows			INT	= 0			OUTPUT
AS
/*
	Create:	20250529@Razor
	Task:	Potential Member win limit
	DB:		DBCUST/Custdb

	Revisions:
		- 20250529@Razor:	Potential Member win limit - [Redmine: #228570]
		- 20250612@Razor:	Sort by status - [Redmine: #226060]
		- 20250623@Razor:	Support Direct member - [Redmine: #230794]
		- 20250801@Johnson: Include Parlay to Potential Win Limit - [Redmine: #233805]
	Param's Explanation:
		@problemAccount:	2 = All, 1 = Yes, 0 = No
		@Status:			All, Disabled, Closed, Suspended, Locked, Open

*/
BEGIN

	SET NOCOUNT ON

	CREATE TABLE #Data(
		Custid INT,
		Username NVARCHAR(50),
		LastLogged DATETIME,
		Status	VARCHAR(10),
		IsProblemAccount BIT,
		Credit MONEY,
		IsAutoReset BIT,
		PotentialWinLimit MONEY,
		IncludeParlay BIT,
		SportType INT,
		BetType INT
	)

	INSERT INTO #Data
	SELECT 
		c.custid
		, ci.username
		, c.lastlogged
		, CASE WHEN ci.Enabled = 0 THEN 'Disabled'
			 WHEN cs.closed = 1 THEN 'Closed'
			 WHEN cs.reject = 1 THEN 'Suspended'
			 WHEN cs.Locked > 0 THEN 'Locked'
			 ELSE 'Open'
			END AS Status
		, ISNULL(pa.IsPA,0) AS IsProblemAccount
		, ci.credit
		, cpw.IsAutoReset
		, cpw.PotentialWinLimit
		, dbo.f_CustPotentialWinLimit_GetOfferOption(cpw.OfferOption, 1) AS IncludeParlay
		, cpw.SportType
		, cpw.BetType
	FROM dbo.CustPotentialWinlimit AS cpw WITH(NOLOCK) 
		INNER JOIN custInfo ci WITH(NOLOCK) ON cpw.custid = ci.custid
		INNER JOIN customer c WITH(NOLOCK) ON ci.custid = c.custid
		OUTER APPLY (SELECT TOP 1 cc.CustomerClass 
					FROM CategoryConfig cc WITH (NOLOCK) 
					WHERE cc.CustomerClass=ci.CustomerClass AND HiddenSite NOT IN (1,3)
					) cc
		OUTER APPLY (SELECT 1 AS IsPA
					 FROM ProblemAccountClassification p WITH(NOLOCK) 
					 WHERE c.custid = p.custid AND cc.CustomerClass IS NOT NULL
					 ) pa	--Problem Account
		CROSS APPLY  (	SELECT CASE WHEN CloseInfo > 0 THEN 1 ELSE 0 END AS closed
							, CASE WHEN SuspendInfo > 0 THEN 1 ELSE 0 END AS reject
							, Locked
						FROM dbo.CustProductStatus WITH(NOLOCK)
						WHERE CustID = ci.custid
					) AS cs
	WHERE 
		1 = CASE 
				WHEN @RoleId = 2 AND ci.recommend = @CustId AND c.roleid = 1 THEN 1
				WHEN @RoleId = 3 AND ci.mrecommend = @CustId AND ci.recommend = -3 AND c.roleid = 1 THEN 1
				WHEN @RoleId = 4 AND ci.srecommend = @CustId AND ci.recommend = -4 AND c.roleid = 1 THEN 1
				ELSE 0
			END
		AND cpw.PotentialWinLimit > 0
		AND ci.username LIKE  '%' + ISNULL(@Username,'') + '%'
		AND (	CASE WHEN ci.Enabled = 0 THEN 'Disabled'
					WHEN cs.closed = 1 THEN 'Closed'
					WHEN cs.reject = 1 THEN 'Suspended'
					WHEN cs.Locked > 0 THEN 'Locked'
					ELSE 'Open'
				END = @Status
				OR CASE WHEN @Status = 'All' THEN 1 ELSE 0 END = 1
			)
		AND (ISNULL(pa.IsPA,0) = @ProblemAccount OR @ProblemAccount = 2)

	SELECT @TotalRows = COUNT(1) FROM #Data

	IF @IsGetAll = 1
	BEGIN
		SELECT *
		FROM #Data
		ORDER BY 
			CASE Status
				WHEN 'Open' THEN 1
				WHEN 'Closed' THEN 2
				WHEN 'Suspended' THEN 3
				WHEN 'Locked' THEN 4
				WHEN 'Disabled' THEN 5
			END,
			Username
	END
	ELSE
	BEGIN
		SELECT ROW_NUMBER() OVER (ORDER BY 
			CASE Status
				WHEN 'Open' THEN 1
				WHEN 'Closed' THEN 2
				WHEN 'Suspended' THEN 3
				WHEN 'Locked' THEN 4
				WHEN 'Disabled' THEN 5
			END,
			Username) AS RowNumber
			, *
		FROM #Data
		ORDER BY 
			CASE Status
				WHEN 'Open' THEN 1
				WHEN 'Closed' THEN 2
				WHEN 'Suspended' THEN 3
				WHEN 'Locked' THEN 4
				WHEN 'Disabled' THEN 5
			END,
			Username
		OFFSET @PageSize * (@PageIndex - 1) ROWS
		FETCH NEXT @PageSize ROWS ONLY
	END

	DROP TABLE #Data
END
GO