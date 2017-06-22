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
*/

SET NOCOUNT ON

DECLARE @RowCount int, @RowStart int, @RowEnd int
SELECT @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1 

DECLARE @CustList TABLE(	
	username nvarchar(30)	
)
	
Declare @roleid tinyint

select @roleid = roleid
from custinfo with (nolock)
where custid = @custid

if @roleid = 2
BEGIN	
	INSERT INTO @CustList
	SELECT username
	from custinfo with (nolock)
	where roleid = 1 and recommend = @custid
	order by enabled desc, closed, reject, username	
END
else if @roleid = 3
BEGIN
	INSERT INTO @CustList		
	SELECT username
	from custinfo with (nolock)
	where roleid = 2 and mrecommend = @custid
	order by enabled desc, closed, reject, username	
END
else if @roleid = 4
BEGIN
	INSERT INTO @CustList
	SELECT username
	from custinfo with (nolock)
	where roleid = 3 and srecommend = @custid
	order by enabled desc, closed, reject, username	
END

--Paging
IF @TotalPages = 0
BEGIN
	SELECT 
		@TotalPages = COUNT(1),@TotalPages=@TotalPages/@PageSize + CASE WHEN @TotalPages%@PageSize > 0 THEN 1 ELSE 0 END
	FROM @CustList c 
END
		
SELECT UserName
FROM 
(
	SELECT 
		UserName,
		ROW_NUMBER() OVER (ORDER BY (SELECT 0)) AS RowNumber 
	FROM @CustList 
) c
WHERE c.RowNumber BETWEEN @RowStart AND @RowEnd


GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelList] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelList] TO [bodbExtAccNet]
--GO
--GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerSelList] TO [ITTim]
--GO
--GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerSelList] TO [ITVivi]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerSelList] TO [vnteam]