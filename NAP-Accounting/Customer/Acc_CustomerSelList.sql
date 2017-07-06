/*<info serverAlias="DBCust-CustDB" executers="bodbadminNet,bodbDownlineNet,bodbDownlineNetView,bodbExtAccNet" viewers="vnteam" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerSelList]
	@custid int,
	@PageSize int = 500,
	@PageIndex int = 1,
	@TotalPages int = 1 output
AS

/*
	Created by: []
	Date:[]
	Task: Customer List in left panel 
	DB: DBCUST.CustDB
	
	Revisions:	
		- 2009115@Ryan: apply paging.
		- 20110301@Johnson: change the length of username in @CustList upto 30
		- 20150610@Kos: Separate CustDB to DBCUST server (Move SP to DBCUST.CustDB)
		- 20170620@Winnie: Apply color for closed accounts [RedmineID: #74494]
*/

SET NOCOUNT ON

DECLARE @RowCount int, @RowStart int, @RowEnd int
SELECT @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1 

DECLARE @CustList TABLE(	
	username nvarchar(30),
	ClosedReason TINYINT
)
	
Declare @roleid tinyint

select @roleid = roleid
from custinfo with (nolock)
where custid = @custid

if @roleid = 2
BEGIN	
	INSERT INTO @CustList(username,ClosedReason)
	SELECT c.username,cl.ClosedReason
	from custinfo c with (nolock)
	LEFT JOIN CustLoginInfo_Member cl WITH(NOLOCK) ON c.custid=cl.CustID
	where c.roleid = 1 and c.recommend = @custid
	order by c.enabled desc, c.closed, c.reject, c.username	
END
else if @roleid = 3
BEGIN
	INSERT INTO @CustList(username,ClosedReason)		
	SELECT  c.username,cl.ClosedReason
	from custinfo c with (nolock)
	LEFT JOIN CustLoginInfo cl WITH(NOLOCK) ON c.custid=cl.CustID
	where c.roleid = 2 and c.mrecommend = @custid
	order by c.enabled desc, c.closed, c.reject, c.username	
END
else if @roleid = 4
BEGIN
	INSERT INTO @CustList(username,ClosedReason)		
	SELECT  c.username,cl.ClosedReason
	from custinfo  c with (nolock)
	LEFT JOIN CustLoginInfo cl WITH(NOLOCK) ON c.custid=cl.CustID
	where c.roleid = 3 and c.srecommend = @custid
	order by c.enabled desc, c.closed, c.reject, c.username	
END

--Paging
IF @TotalPages = 0
BEGIN
	SELECT 
		@TotalPages = COUNT(1),@TotalPages=@TotalPages/@PageSize + CASE WHEN @TotalPages%@PageSize > 0 THEN 1 ELSE 0 END
	FROM @CustList c 
END
		
SELECT UserName,ClosedReason
FROM 
(
	SELECT 
		UserName,ClosedReason,
		ROW_NUMBER() OVER (ORDER BY (SELECT 0)) AS RowNumber 
	FROM @CustList 
) c
WHERE c.RowNumber BETWEEN @RowStart AND @RowEnd

GO
