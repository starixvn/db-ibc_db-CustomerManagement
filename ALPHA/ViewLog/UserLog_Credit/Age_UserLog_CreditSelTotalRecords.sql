/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Age_UserLog_CreditSelTotalRecords]    
	@CustName varchar(50),
	@UserId INT,
	@UserRoleId TINYINT,
    @FromDate DATETIME ,
    @ToDate DATETIME
AS 
/* 
	Created: 20210914@Elodie
    Task: ViewLog credit on ALPHA
    DB: DBLOG/bodb_CustomerLog

	Revisions:
		- 20110623@Elodie: Initial SP [Redmine: #160429]

    Param's Explaination:    
		- @CustName: a customer which we want to view actions affect to.
		- @FromDate: date range to view log
		- @ToDate: date range to view log
		- @IsInternal: Accounting: 1 Agent:0
*/
BEGIN
	
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON
	CREATE TABLE #DownlineList (CustId INT, Roleid TINYINT, UserName VARCHAR(30))

	DECLARE @__archiveDate DATETIME
	SELECT @__archiveDate = DATEADD(DAY, 1, dbo.f_CustomerLog_GetArchiveDate())
	
	IF @UserRoleId = 4
		INSERT INTO #DownlineList (CustId, Roleid, UserName)
		SELECT CustId, Roleid, UserName
		FROM bodb02.dbo.Customer ci WITH (NOLOCK)
		WHERE ci.srecommend = @UserId
	ELSE IF @UserRoleId = 3
		INSERT INTO #DownlineList (CustId, Roleid, UserName)
		SELECT CustId, Roleid, UserName
		FROM bodb02.dbo.Customer ci WITH (NOLOCK)
		WHERE ci.mrecommend = @UserId
	ELSE IF @UserRoleId = 2
		INSERT INTO #DownlineList (CustId, Roleid, UserName)
		SELECT CustId, Roleid, UserName
		FROM bodb02.dbo.Customer ci WITH (NOLOCK)
		WHERE ci.recommend = @UserId

	DELETE FROM #DownlineList WHERE username NOT LIKE '%' + @CustName +'%'

	IF @FromDate >= @__archiveDate
	BEGIN
		SELECT COUNT(LogID)                           
		FROM dbo.UserLog_Credit AS uc WITH (NOLOCK)
			INNER JOIN #DownlineList dl ON uc.custid = dl.CustId
			INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON uc.ActionID = la.ActionID
			INNER JOIN bodb02.dbo.CustInfo AS ci with(nolock) ON ci.custid = uc.UserID
		WHERE LogDate BETWEEN @FromDate AND @ToDate                           
			AND IsInternal <= 0
			AND (ci.roleid <= 4 OR uc.ActionID = 1221)
	END
	ELSE IF @ToDate < @__archiveDate
	BEGIN
		SELECT COUNT(LogID)                           
		FROM bodb_CustomerLog_Archive.dbo.UserLog_Credit AS uc WITH (NOLOCK)
			INNER JOIN #DownlineList dl ON uc.custid = dl.CustId
			INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON uc.ActionID = la.ActionID
			INNER JOIN bodb02.dbo.CustInfo AS ci with(nolock) ON ci.custid = uc.UserID
		WHERE LogDate BETWEEN @FromDate AND @ToDate                           
			AND IsInternal <= 0
			AND (ci.roleid <= 4 OR uc.ActionID = 1221)
	END
	ELSE
	BEGIN
		SELECT SUM(cnt)
		FROM (
			SELECT COUNT(LogID) cnt                       
			FROM dbo.UserLog_Credit AS uc WITH (NOLOCK)
				INNER JOIN #DownlineList dl ON uc.custid = dl.CustId
				INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON uc.ActionID = la.ActionID
				INNER JOIN bodb02.dbo.CustInfo AS ci with(nolock) ON ci.custid = uc.UserID
			WHERE LogDate BETWEEN @FromDate AND @ToDate                           
				AND IsInternal <= 0
				AND (ci.roleid <= 4 OR uc.ActionID = 1221)

			UNION ALL
			SELECT COUNT(LogID) cnt                        
			FROM bodb_CustomerLog_Archive.dbo.UserLog_Credit AS uc WITH (NOLOCK)
				INNER JOIN #DownlineList dl ON uc.custid = dl.CustId
				INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON uc.ActionID = la.ActionID
				INNER JOIN bodb02.dbo.CustInfo AS ci with(nolock) ON ci.custid = uc.UserID
			WHERE LogDate BETWEEN @FromDate AND @ToDate                           
				AND IsInternal <= 0
				AND (ci.roleid <= 4 OR uc.ActionID = 1221)
		)t
	END			
END
GO
