/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_UserLogCreditSel]
	@Username VARCHAR(30) ,
	@FromDate DATETIME,
	@ToDate DATETIME
AS
/*
Created: Simon
Date: 2009-09-03
Task : View Credit Log.	
DB: DBLog.bodb_CustomerLog
Original:

Revisions: 
    - 20090903@Simon: View Credit Log for UserName.	
    - 20090921:HuyNguyen:
		+ Add linked server, remove inner join that gets username and custid in customer table.	
	- 20190405@Patrick: Support archive date range [Redmine: #111476]
*/

SET NOCOUNT ON

DECLARE @custid INT
SELECT @custid = NULL
SELECT @custid = custid FROM bodb02.dbo.CustInfo WITH(NOLOCK) WHERE username = @username

DECLARE @__archiveDate DATETIME
SELECT @__archiveDate = DATEADD(DAY, 1, dbo.f_CustomerLog_GetArchiveDate())

IF @FromDate >= @__archiveDate
BEGIN
	SELECT 
		logid,
		@Username+'<br/>('+cast(@custid as varchar(30))+')' as username,
		o.username+'<br/>('+CAST(o.custid AS VARCHAR(30))+')' AS owner,
		spname,
		OldValue,
		NewValue,
		doing,
		ip,
		logdate
	FROM userlog_Credit l WITH(NOLOCK) 
		LEFT JOIN bodb02.dbo.CustInfo o WITH(NOLOCK) ON o.custid = l.userid
	WHERE l.custid=@custid AND logdate BETWEEN @FromDate AND @ToDate 
	ORDER BY logdate DESC
END
ELSE IF @ToDate < @__archiveDate
BEGIN
	SELECT 
		logid,
		@Username+'<br/>('+cast(@custid as varchar(30))+')' as username,
		o.username+'<br/>('+CAST(o.custid AS VARCHAR(30))+')' AS owner,
		spname,
		OldValue,
		NewValue,
		doing,
		ip,
		logdate
	FROM bodb_CustomerLog_Archive.dbo.UserLog_Credit l WITH(NOLOCK) 
		LEFT JOIN bodb02.dbo.CustInfo o WITH(NOLOCK) ON o.custid = l.userid
	WHERE l.custid=@custid AND logdate BETWEEN @FromDate AND @ToDate 
	ORDER BY logdate DESC
END
ELSE
BEGIN
	SELECT *
	FROM (
		SELECT 
			logid,
			@Username+'<br/>('+cast(@custid as varchar(30))+')' as username,
			o.username+'<br/>('+CAST(o.custid AS VARCHAR(30))+')' AS owner,
			spname,
			OldValue,
			NewValue,
			doing,
			ip,
			logdate
		FROM userlog_Credit l WITH(NOLOCK) 
			LEFT JOIN bodb02.dbo.CustInfo o WITH(NOLOCK) ON o.custid = l.userid
		WHERE l.custid=@custid AND logdate BETWEEN @__archiveDate AND @ToDate 

		UNION ALL
		SELECT 
			logid,
			@Username+'<br/>('+cast(@custid as varchar(30))+')' as username,
			o.username+'<br/>('+CAST(o.custid AS VARCHAR(30))+')' AS owner,
			spname,
			OldValue,
			NewValue,
			doing,
			ip,
			logdate
		FROM bodb_CustomerLog_Archive.dbo.UserLog_Credit l WITH(NOLOCK) 
			LEFT JOIN bodb02.dbo.CustInfo o WITH(NOLOCK) ON o.custid = l.userid
		WHERE l.custid=@custid AND logdate >= @FromDate AND logdate < @__archiveDate 
		
	)t ORDER BY logdate DESC
END
GO
