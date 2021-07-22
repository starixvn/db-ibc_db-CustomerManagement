/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
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
DB: DBCUST.CustDB
Origional: Acc_CustomerSelSAg
Revisions:
    - 20210408@Tina: Lock account & indirect close account [redmine: #148600]

Pattern Explanation:
	- Search keyword: '%keyword%'
	- First char
			A: 'A%'
			B: 'B%'
			0-9: '[0-9]%'
*/
BEGIN
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
			and csuper.isinternal = 1
			and m.roleid=4 and m.custid>100 and m.username like '%' + @Keyword + '%' and m.username like @FirstChar	+ '%'	
	) t
END

select * from 
(
SELECT 
	ROW_NUMBER() OVER (ORDER BY m.username) as RowNumber,
	m.username, 
	m.username2,	
	m.firstname, 
	m.lastname,
	m.custid,
	m.roleid	
FROM 
	customer AS m with (NOLOCK)
	INNER JOIN CustSuper as csuper with (NOLOCK) on m.custid = csuper.custid
WHERE m.currency = case when @Currency is null then m.currency else @Currency end
	and csuper.isinternal = 1
	and m.roleid=4 and m.custid>100 and m.username like '%' + @Keyword + '%' and m.username like @FirstChar	+ '%'	
group by
	m.username, 
	m.username2,	
	m.firstname, 
	m.lastname, 
	m.custid,
	m.roleid
) a
WHERE a.RowNumber BETWEEN @RowStart AND @RowEnd
END
GO
