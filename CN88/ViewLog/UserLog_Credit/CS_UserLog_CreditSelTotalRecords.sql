/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_UserLog_CreditSelTotalRecords]    
    @CustID INT,
    @FromDate DATETIME,
    @ToDate DATETIME,
    @IsInternal TINYINT    
AS 
/* Created:20100121@Lewin
    Task: ViewLog function 331
    DB: bodb_CustomerLog

	Description:
	- count total record with input conditions
	
    Param's Explaination:    
	- @CustID: a customer which we want to view actions affect to.
	- @FromDate: date range to view log
	- @ToDate: date range to view log	
	- @IsInternal: AccountingSite: 1 Agent:0

	Revisions:
		- 20140708@Dom: Do not show any log info (including log of Supers, Masters, Agents and Members) updated by Admin relate to all log categories [Redmine: #18125]
		- 20190405@Patrick: Support archive date range [Redmine: #111476]
	
*/
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

DECLARE @__archiveDate DATETIME
SELECT @__archiveDate = DATEADD(DAY, 1, dbo.f_CustomerLog_GetArchiveDate())
IF @IsInternal = 1
BEGIN
	IF @FromDate >= @__archiveDate
	BEGIN
		SELECT COUNT(LogID)                         
		FROM dbo.UserLog_Credit AS uc WITH (NOLOCK)
			INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON uc.ActionID = la.ActionID
			INNER JOIN bodb02.dbo.CustInfo AS ci with(nolock) ON ci.custid = uc.UserID
		WHERE uc.CustID = @CustID
			AND LogDate BETWEEN @FromDate AND @ToDate                           
			AND IsInternal <= @IsInternal
	END
	ELSE IF @ToDate < @__archiveDate
	BEGIN
		SELECT COUNT(LogID)                      
		FROM bodb_CustomerLog_Archive.dbo.UserLog_Credit AS uc WITH (NOLOCK)
			INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON uc.ActionID = la.ActionID
			INNER JOIN bodb02.dbo.CustInfo AS ci with(nolock) ON ci.custid = uc.UserID
		WHERE uc.CustID = @CustID
			AND LogDate BETWEEN @FromDate AND @ToDate                           
			AND IsInternal <= @IsInternal
	END
	ELSE
	BEGIN
		SELECT SUM(cnt)
		FROM (
			SELECT COUNT(LogID) cnt                          
			FROM dbo.UserLog_Credit AS uc WITH (NOLOCK)
				INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON uc.ActionID = la.ActionID
				INNER JOIN bodb02.dbo.CustInfo AS ci with(nolock) ON ci.custid = uc.UserID
			WHERE uc.CustID = @CustID
				AND LogDate BETWEEN @__archiveDate AND @ToDate                           
				AND IsInternal <= @IsInternal

			UNION ALL
			SELECT COUNT(LogID) cnt                          
			FROM bodb_CustomerLog_Archive.dbo.UserLog_Credit AS uc WITH (NOLOCK)
				INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON uc.ActionID = la.ActionID
				INNER JOIN bodb02.dbo.CustInfo AS ci with(nolock) ON ci.custid = uc.UserID
			WHERE uc.CustID = @CustID
				AND LogDate >= @FromDate AND LogDate < @__archiveDate                           
				AND IsInternal <= @IsInternal
		)t
	END
END
ELSE 
BEGIN
	IF @FromDate >= @__archiveDate
	BEGIN
		SELECT COUNT(LogID)                           
		FROM dbo.UserLog_Credit AS uc WITH (NOLOCK)
			INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON uc.ActionID = la.ActionID
			INNER JOIN bodb02.dbo.CustInfo AS ci with(nolock) ON ci.custid = uc.UserID
		WHERE uc.CustID = @CustID
			AND LogDate BETWEEN @FromDate AND @ToDate                           
			AND IsInternal <= @IsInternal
			AND ci.roleid <= 4
	END
	ELSE IF @ToDate < @__archiveDate
	BEGIN
		SELECT COUNT(LogID)                           
		FROM bodb_CustomerLog_Archive.dbo.UserLog_Credit AS uc WITH (NOLOCK)
			INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON uc.ActionID = la.ActionID
			INNER JOIN bodb02.dbo.CustInfo AS ci with(nolock) ON ci.custid = uc.UserID
		WHERE uc.CustID = @CustID
			AND LogDate BETWEEN @FromDate AND @ToDate                           
			AND IsInternal <= @IsInternal
			AND ci.roleid <= 4
	END
	ELSE
	BEGIN
		SELECT SUM(cnt)
		FROM (
			SELECT COUNT(LogID) cnt                       
			FROM dbo.UserLog_Credit AS uc WITH (NOLOCK)
				INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON uc.ActionID = la.ActionID
				INNER JOIN bodb02.dbo.CustInfo AS ci with(nolock) ON ci.custid = uc.UserID
			WHERE uc.CustID = @CustID
				AND LogDate BETWEEN @FromDate AND @ToDate                           
				AND IsInternal <= @IsInternal
				AND ci.roleid <= 4

			UNION ALL
			SELECT COUNT(LogID) cnt                        
			FROM bodb_CustomerLog_Archive.dbo.UserLog_Credit AS uc WITH (NOLOCK)
				INNER JOIN dbo.LogAction AS la WITH (NOLOCK) ON uc.ActionID = la.ActionID
				INNER JOIN bodb02.dbo.CustInfo AS ci with(nolock) ON ci.custid = uc.UserID
			WHERE uc.CustID = @CustID
				AND LogDate BETWEEN @FromDate AND @ToDate                           
				AND IsInternal <= @IsInternal
				AND ci.roleid <= 4
		)t
	END
	
END

GO
