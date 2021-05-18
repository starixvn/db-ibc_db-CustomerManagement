ALTER PROCEDURE [dbo].[Acc_CustomerSelFinance_SAg]
	@Currency int = NULL,
	@Closed bit = NULL,
	@Keyword nvarchar(50)='',
	@FirstChar nvarchar(6)='',
	@PageSize int=50,
	@PageIndex int=1,
	@TotalRow int=0 OUTPUT
AS
/*
Created by: Elodie
Date: 20120712
Task : Select Super Finance list
DB: DB053.bodb02
Origional: Acc_CustomerSelSAg
Revisions:
    

Pattern Explanation:
	- Search keyword: '%keyword%'
	- First char
			A: 'A%'
			B: 'B%'
			0-9: '[0-9]%'
*/
SET NOCOUNT ON

DECLARE @RowCount int, @RowStart int, @RowEnd int
SELECT  @PageIndex = @PageIndex - 1, 
		@RowStart = @PageSize * @PageIndex + 1, 
		@RowEnd = @RowStart + @PageSize - 1 

IF @TotalRow = 0
BEGIN
	SELECT  @TotalRow = count(t.custid)
	From
	(
		Select m.custid
		FROM 
			Custinfo as m with (NOLOCK)
			INNER JOIN CustSuper as csuper with (NOLOCK) on m.custid = csuper.custid
		WHERE m.currency = case when @Currency is null then m.currency else @Currency end											
			and m.closed = case when @closed is null then m.closed else @closed end
			and csuper.isinternal = 1
			and m.roleid=4 and m.custid>100 and m.username like '%' + @Keyword + '%' and m.username like @FirstChar	+ '%'	
			--and m.custid NOT IN(SELECT custid from f_DepSuper_1 ('all'))	
	) t
END

select * from 
(
SELECT 
	ROW_NUMBER() OVER (ORDER BY CASE when isnull(ci.enabled,0) = 0 then 3 WHEN isnull(ci.closed,0) = 1 THEN 2 WHEN isnull(ci.reject,0) = 1 THEN 1 ELSE 0 end, m.username) as RowNumber,
	
	ci.enabled, 
	ci.closed, 
	ci.reject as suspended,
	
	m.username, 
	m.username2,	
	m.firstname, 
	m.lastname,
	m.custid,
	m.roleid	
FROM 
	customer AS m with (NOLOCK)
	INNER JOIN custinfo as ci with (NOLOCK) on m.custid = ci.custid
	INNER JOIN CustSuper as csuper with (NOLOCK) on m.custid = csuper.custid
WHERE m.currency = case when @Currency is null then m.currency else @Currency end
	and ci.closed = case when @closed is null then ci.closed else @closed end
	and csuper.isinternal = 1
	and m.roleid=4 and m.custid>100 and m.username like '%' + @Keyword + '%' and m.username like @FirstChar	+ '%'	
	--and m.custid NOT IN(SELECT custid from f_DepSuper_1 ('all'))
group by
	ci.enabled, 
	ci.closed, 
	ci.reject,
	m.username, 
	m.username2,	
	m.firstname, 
	m.lastname, 
	m.custid,
	m.roleid
) a
WHERE a.RowNumber BETWEEN @RowStart AND @RowEnd

GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelFinance_SAg] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerSelFinance_SAg] TO [vnteam]
