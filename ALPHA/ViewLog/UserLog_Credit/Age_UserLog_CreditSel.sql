/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="wsv_alp,bodbDownlineNetView,wsv_alpv" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Age_UserLog_CreditSel]    
	@CustName varchar(50),
	@UserId INT,
	@UserRoleId TINYINT,
    @FromDate DATETIME ,
    @ToDate DATETIME ,    
    @PageIndex INT ,
    @PageSize INT
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
		- @ActionTypeId: action type
		- @IsInternal: Accounting: 1 Agent:0
		- @PageIndex: from 0
		- @PageSize: total record per request
*/
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON 
	CREATE TABLE #DownlineList (CustId INT, Roleid TINYINT, UserName VARCHAR(30))

	SET @PageIndex = ABS(@PageIndex)
	SET @PageSize = ABS(@PageSize)  

	DECLARE @lbound INT 
	DECLARE @ubound INT

	SET @lbound = @PageIndex * @PageSize       
	
	SET @ubound = @lbound + @PageSize 
	IF ( @PageIndex > 0 ) 
		SET @lbound = @lbound + 1

	DECLARE @ActionName AS NVARCHAR(256)
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
		SELECT	LogID,
			UserID,
			CustID,
			Roleid,
			LogDate,
			OldValue,
			NewValue,
			IP,
			Doing,
			ActionID,
			IsInternal,
			ActionTypeID,
			SPName,
			UserName,
			CustName,                                                             
			ActionName
		FROM    ( SELECT    ROW_NUMBER() OVER (ORDER BY dl.UserName, LogDate DESC) AS RowNum,
							LogID,
							UserID,
							uc.CustID,
							dl.Roleid,
							LogDate,
							OldValue,
							NewValue,
							IP,
							CASE WHEN la.ActionID = 1221 THEN la.ActionNameEN ELSE Doing END AS Doing,
							la.ActionID,
							IsInternal,
							la.ActionTypeID,
							la.SPName,
							Username =	CASE 
												WHEN ci.RoleId > 4 THEN 'Admin'
												ELSE ci.Username
											END,
							dl.UserName as CustName,                                         
							la.ActionNameEN As ActionName
					FROM dbo.UserLog_Credit AS uc WITH (NOLOCK)
							INNER JOIN #DownlineList dl ON uc.custid = dl.CustId
							INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON uc.ActionID = la.ActionID
							INNER JOIN bodb02.dbo.CustInfo AS ci with(nolock) ON ci.custid = uc.UserID
					WHERE LogDate BETWEEN @FromDate AND @ToDate                            
							AND IsInternal <= 0
							AND (ci.roleid <= 4 OR uc.ActionID = 1221)
				) AS MyTable
		WHERE   RowNum BETWEEN @lbound AND @ubound
	END
	ELSE IF @ToDate < @__archiveDate
	BEGIN
		SELECT	LogID,
			UserID,
			CustID,
			Roleid,
			LogDate,
			OldValue,
			NewValue,
			IP,
			Doing,
			ActionID,
			IsInternal,
			ActionTypeID,
			SPName,
			UserName,
			CustName,                                                             
			ActionName
		FROM    ( SELECT    ROW_NUMBER() OVER (ORDER BY dl.UserName, LogDate DESC) AS RowNum,
							LogID,
							UserID,
							uc.CustID,
							dl.Roleid,
							LogDate,
							OldValue,
							NewValue,
							IP,
							CASE WHEN la.ActionID = 1221 THEN la.ActionNameEN ELSE Doing END AS Doing,
							la.ActionID,
							IsInternal,
							la.ActionTypeID,
							la.SPName,
							Username =	CASE 
												WHEN ci.RoleId > 4 THEN 'Admin'
												ELSE ci.Username
											END,
							dl.UserName as CustName,                                       
							la.ActionNameEN As ActionName
					FROM    bodb_CustomerLog_Archive.dbo.UserLog_Credit AS uc WITH (NOLOCK)
							INNER JOIN #DownlineList dl ON uc.custid = dl.CustId
							INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON uc.ActionID = la.ActionID
							INNER JOIN bodb02.dbo.CustInfo AS ci with(nolock) ON ci.custid = uc.UserID
					WHERE   LogDate BETWEEN @FromDate AND @ToDate                            
							AND IsInternal <= 0
							AND (ci.roleid <= 4 OR uc.ActionID = 1221)
				) AS MyTable
		WHERE   RowNum BETWEEN @lbound AND @ubound
	END
	ELSE
	BEGIN
		SELECT	LogID,
			UserID,
			CustID,
			Roleid,
			LogDate,
			OldValue,
			NewValue,
			IP,
			Doing,
			ActionID,
			IsInternal,
			ActionTypeID,
			SPName,
			UserName,
			CustName,                                                             
			ActionName
		FROM ( 
			SELECT    ROW_NUMBER() OVER (ORDER BY UserName, LogDate DESC) AS RowNum, *
			FROM (
				SELECT 		LogID,
							UserID,
							uc.CustID,
							dl.Roleid,
							LogDate,
							OldValue,
							NewValue,
							IP,
							CASE WHEN la.ActionID = 1221 THEN la.ActionNameEN ELSE Doing END AS Doing,
							la.ActionID,
							IsInternal,
							la.ActionTypeID,
							la.SPName,
							Username =	CASE 
												WHEN ci.RoleId > 4 THEN 'Admin'
												ELSE ci.Username
											END,
							dl.UserName as CustName,                                           
							la.ActionNameEN As ActionName
					FROM      dbo.UserLog_Credit AS uc WITH (NOLOCK)
							INNER JOIN #DownlineList dl ON uc.custid = dl.CustId
							INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON uc.ActionID = la.ActionID
							INNER JOIN bodb02.dbo.CustInfo AS ci with(nolock) ON ci.custid = uc.UserID
					WHERE   LogDate BETWEEN @__archiveDate AND @ToDate                            
							AND IsInternal <= 0
							AND (ci.roleid <= 4 OR uc.ActionID = 1221)

				UNION ALL
				SELECT 		LogID,
							UserID,
							uc.CustID,
							dl.Roleid,
							LogDate,
							OldValue,
							NewValue,
							IP,
							CASE WHEN la.ActionID = 1221 THEN la.ActionNameEN ELSE Doing END AS Doing,
							la.ActionID,
							IsInternal,
							la.ActionTypeID,
							la.SPName,
							Username =	CASE 
												WHEN ci.RoleId > 4 THEN 'Admin'
												ELSE ci.Username
											END,
							dl.UserName as CustName,                                         
							la.ActionNameEN As ActionName
					FROM    bodb_CustomerLog_Archive.dbo.UserLog_Credit AS uc WITH (NOLOCK)
							INNER JOIN #DownlineList dl ON uc.custid = dl.CustId
							INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON uc.ActionID = la.ActionID
							INNER JOIN bodb02.dbo.CustInfo AS ci with(nolock) ON ci.custid = uc.UserID
					WHERE   LogDate >= @FromDate AND LogDate < @__archiveDate                            
							AND IsInternal <= 0
							AND (ci.roleid <= 4 OR uc.ActionID = 1221)
				) AS MyTable1
			) AS MyTable
		WHERE   RowNum BETWEEN @lbound AND @ubound
	END
END
GO
