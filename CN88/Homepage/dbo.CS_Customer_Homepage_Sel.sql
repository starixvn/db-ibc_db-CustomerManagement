/*<info serverAlias="DBCUST-CustDB" executers="bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[CS_Customer_Homepage_Sel]
	@CustId INT,	
	@subAccID INT = 0,
	@IsAllDownline BIT,
	@fromdate DATETIME,
	@todate	DATETIME		
AS
/*
	Created: 20190304@Johnson
	DB: DBCUST/CustDB
	Task: get general info for home page

	Revisions:
		- 20190304@Johnson: Initialize SP [RedmineID: #105338]
		- 20190527@Paul: Apply new status [RedmineID: #113198]
		- 20190715@Elodie: Sub account management [Redmine:#116825] 
*/

BEGIN
	SET NOCOUNT ON
	
	DECLARE @credit MONEY,
			@CreditBalance MONEY,
			@roleid TINYINT,
			@cntNewMember INT,
			@LastLogin SMALLDATETIME,
			@LastChangePwd DATETIME
	
	CREATE TABLE #tblStatus (roleid TINYINT, cntActive INT, cntViewOnly INT, cntSuspended INT, cntInactive INT)
	
	SELECT	@credit = credit, @roleid = roleid
	FROM dbo.CustInfo WITH(NOLOCK)
	WHERE custid = @custid
		
	--get credit balance	
	IF @roleid = 4
	BEGIN
		SELECT @CreditBalance = SUM(Credit)
		FROM dbo.Custinfo WITH(NOLOCK)
		WHERE srecommend = @custid	
			AND roleid = 3
		
		SELECT @cntNewMember = COUNT(1)
		FROM dbo.Customer WITH(NOLOCK)
		WHERE srecommend = @custid	
			AND roleid = 1
			AND creatdate BETWEEN @fromdate AND @todate	
	END
	ELSE IF @roleid = 3
	BEGIN
		SELECT @CreditBalance = SUM(Credit)
		FROM dbo.Custinfo WITH(NOLOCK)
		WHERE mrecommend = @custid	
			AND roleid = 2
		
		SELECT @cntNewMember = COUNT(1)
		FROM dbo.Customer WITH(NOLOCK)
		WHERE mrecommend = @custid	
			AND roleid = 1
			AND creatdate BETWEEN @fromdate AND @todate			
	END
	ELSE IF @roleid = 2
	BEGIN
		SELECT @CreditBalance = SUM(Credit),
			@cntNewMember = COUNT(1)
		FROM dbo.Custinfo ci WITH(NOLOCK)
			INNER JOIN Customer c (NOLOCK) on c.custid = ci.custid
		WHERE c.recommend = @custid	
			AND c.roleid = 1
	END
	
	--get last login date
	SELECT @LastLogin = lastlogged
	FROM dbo.Customer WITH(NOLOCK)
	WHERE custid = @custid
	
	IF @subAccID = 0
	BEGIN
		SELECT @LastChangePwd = LastChangedPwdDate
		FROM dbo.CustLoginInfo WITH(NOLOCK)
		WHERE custid = @custid				
	END
	ELSE
	BEGIN
		SELECT @LastChangePwd = LastChangedPwdDate
		FROM dbo.CustLoginInfoSub WITH(NOLOCK)
		WHERE custid = @custid
			AND subAccID = @subAccID
	END
	
	IF @subAccID = 0 OR @IsAllDownline = 1
	BEGIN
		IF @roleid = 4
		BEGIN
			INSERT INTO #tblStatus(roleid, cntActive, cntViewOnly, cntSuspended, cntInactive)
			SELECT roleid, 
				ISNULL(SUM(CASE	WHEN cs.CustStatus = 4 THEN 1 ELSE 0 END), 0) AS cntActive,
				ISNULL(SUM(CASE WHEN cs.CustStatus = 3 THEN 1 ELSE 0 END), 0) AS cntViewOnly,
				ISNULL(SUM(CASE WHEN cs.CustStatus = 2 THEN 1 ELSE 0 END), 0) AS cntSuspended,
				ISNULL(SUM(CASE WHEN cs.CustStatus = 1 THEN 1 ELSE 0 END), 0) AS cntInactive
			FROM custinfo ci WITH(NOLOCK)
				CROSS APPLY dbo.f_CS_GetCustomerStatus(ci.custid) cs
			WHERE srecommend = @custid	
				AND roleid IN (1,2,3)				
			GROUP BY roleid	
		END
		ELSE IF @roleid = 3
		BEGIN
			INSERT INTO #tblStatus(roleid, cntActive, cntViewOnly, cntSuspended, cntInactive)
			SELECT roleid, 
				ISNULL(SUM(CASE	WHEN cs.CustStatus = 4 THEN 1 ELSE 0 END), 0) AS cntActive,
				ISNULL(SUM(CASE WHEN cs.CustStatus = 3 THEN 1 ELSE 0 END), 0) AS cntViewOnly,
				ISNULL(SUM(CASE WHEN cs.CustStatus = 2 THEN 1 ELSE 0 END), 0) AS cntSuspended,
				ISNULL(SUM(CASE WHEN cs.CustStatus = 1 THEN 1 ELSE 0 END), 0) AS cntInactive
			FROM custinfo ci WITH(NOLOCK)
				CROSS APPLY dbo.f_CS_GetCustomerStatus(ci.custid) cs
			WHERE mrecommend = @custid	
				AND roleid IN (1,2)
			GROUP BY roleid	
		END
		ELSE IF @roleid = 2
		BEGIN
			INSERT INTO #tblStatus(roleid, cntActive, cntViewOnly, cntSuspended, cntInactive)
			SELECT roleid, 
				ISNULL(SUM(CASE	WHEN cs.CustStatus = 4 THEN 1 ELSE 0 END), 0) AS cntActive,
				ISNULL(SUM(CASE WHEN cs.CustStatus = 3 THEN 1 ELSE 0 END), 0) AS cntViewOnly,
				ISNULL(SUM(CASE WHEN cs.CustStatus = 2 THEN 1 ELSE 0 END), 0) AS cntSuspended,
				ISNULL(SUM(CASE WHEN cs.CustStatus = 1 THEN 1 ELSE 0 END), 0) AS cntInactive
			FROM custinfo ci WITH(NOLOCK)
				CROSS APPLY dbo.f_CS_GetCustomerStatus(ci.custid) cs
			WHERE ci.recommend = @custid	
				AND ci.roleid = 1
			GROUP BY ci.roleid	
		END
	END
	BEGIN
		IF @roleid = 4
		BEGIN
			INSERT INTO #tblStatus(roleid, cntActive, cntViewOnly, cntSuspended, cntInactive)
			SELECT roleid, 
				ISNULL(SUM(CASE	WHEN cs.CustStatus = 4 THEN 1 ELSE 0 END), 0) AS cntActive,
				ISNULL(SUM(CASE WHEN cs.CustStatus = 3 THEN 1 ELSE 0 END), 0) AS cntViewOnly,
				ISNULL(SUM(CASE WHEN cs.CustStatus = 2 THEN 1 ELSE 0 END), 0) AS cntSuspended,
				ISNULL(SUM(CASE WHEN cs.CustStatus = 1 THEN 1 ELSE 0 END), 0) AS cntInactive
			FROM custinfo ci WITH(NOLOCK)
				INNER JOIN dbo.CS_SubAccManagement sm WITH (NOLOCK) ON ci.mrecommend = sm.DownlineId
				CROSS APPLY dbo.f_CS_GetCustomerStatus(ci.custid) cs
			WHERE srecommend = @custid AND sm.SubAccId = @subAccID
				AND roleid IN (1,2,3)				
			GROUP BY roleid	
		END
	END

	SELECT @credit as Credit,
		@credit - @CreditBalance as CreditBalance,
		ISNULL(@cntNewMember,0) as cntNewMember,
		@LastLogin as LastLogin,
		@LastChangePwd as LastChangePwd
	
	SELECT roleid, cntActive, cntViewOnly, cntSuspended, cntInactive
	FROM #tblStatus
END	