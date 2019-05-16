/*<info serverAlias="DBLOG-bodb_CustomerLog" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER procedure [dbo].[Acc_UserLogRunSPSel]
	@Username varchar(30) ,
	@FromDate datetime,
	@ToDate datetime
as
/*
Created: 
Task : View log Run SP
DB: DB052.bodb_CustomerLog
Original:

Revisions:
	- 20090921:HuyNguyen:
		+ Add linked server, remove inner join that gets username and custid in customer table.	
	- 20190405@Patrick: Support archive date range [Redmine: #111476]

Param's Explanation:
• @Username:Customer who will be shown his logs
*/
SET NOCOUNT ON
Declare @custid int
Select @custid = null
Select @custid = custid From bodb02.dbo.CustInfo with(nolock) where username = @username

DECLARE @__archiveDate DATETIME
SELECT @__archiveDate = DATEADD(DAY, 1, dbo.f_CustomerLog_GetArchiveDate())

IF @FromDate >= @__archiveDate
BEGIN
	Select 
		logid,
		@Username+'<br/>('+cast(@custid as varchar(30))+')' as username,
		o.username+'<br/>('+cast(o.custid as varchar(30))+')' as owner,
		spname,
		doing,
		logdate
	from userlog_runsp l with(nolock) 
		inner join bodb02.dbo.CustInfo o with(nolock) on o.custid = l.userid
	where l.custid=@custid and logdate between @FromDate and @ToDate 
	order by logid desc,spname
END
ELSE IF @ToDate < @__archiveDate
BEGIN
	Select 
		logid,
		@Username+'<br/>('+cast(@custid as varchar(30))+')' as username,
		o.username+'<br/>('+cast(o.custid as varchar(30))+')' as owner,
		spname,
		doing,
		logdate
	from bodb_CustomerLog_Archive.dbo.UserLog_RunSP l with(nolock) 
		inner join bodb02.dbo.CustInfo o with(nolock) on o.custid = l.userid
	where l.custid=@custid and logdate between @FromDate and @ToDate 
	order by logid desc,spname
END
ELSE
BEGIN
	SELECT *
	FROM (
		Select 
			logid,
			@Username+'<br/>('+cast(@custid as varchar(30))+')' as username,
			o.username+'<br/>('+cast(o.custid as varchar(30))+')' as owner,
			spname,
			doing,
			logdate
		from userlog_runsp l with(nolock) 
			inner join bodb02.dbo.CustInfo o with(nolock) on o.custid = l.userid
		where l.custid=@custid and logdate between @__archiveDate and @ToDate 

		UNION ALL
		Select 
			logid,
			@Username+'<br/>('+cast(@custid as varchar(30))+')' as username,
			o.username+'<br/>('+cast(o.custid as varchar(30))+')' as owner,
			spname,
			doing,
			logdate
		from bodb_CustomerLog_Archive.dbo.UserLog_RunSP l with(nolock) 
			inner join bodb02.dbo.CustInfo o with(nolock) on o.custid = l.userid
		where l.custid=@custid and logdate >= @FromDate and logdate < @__archiveDate 
	)t order by logid desc,spname
END

GO
