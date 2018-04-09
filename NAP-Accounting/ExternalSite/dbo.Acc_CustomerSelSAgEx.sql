ALTER PROCEDURE [dbo].[Acc_CustomerSelSAgEx]
@Currency int = NULL,
@Closed bit = NULL,
@Keyword nvarchar(50)='%',
@FirstChar nvarchar(6)='%',
@IsInternal bit = NULL,
@PageSize int=50,
@PageIndex int=1,
@TotalPages int=0 OUTPUT
AS
/*
Task : Select Super Agent list
DB: DB05.bodb02
Revisions:
    - @update2008/01/14 search username
    - phuong.nguyen, check customer's currency for Horseracing spottype
    - 20090329@Kiwi: At count @TotalPages, remove inner join custsetting, group by.	
    - 20090331@Shifu: Remove allowHRCurrency	
    - 20090522@PhuongDao: Add 1x2 Commission 		
    - 20090807@Simon: Add a column "enabled" in Select and Order by it.
    - 20090905@Shifu: Add IsInternal
    - 20100529@Lewin: Select betting user only IsInternal = 0 #IRP 411
Pattern Explanation:
Search keyword: '%keyword%'
First char
A: 'A%'
B: 'B%'
0-9: '[0-9]%'
*/

SET NOCOUNT ON

DECLARE @RowCount int, @RowStart int, @RowEnd int
SELECT @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1 

IF @TotalPages = 0
BEGIN
	SELECT @TotalPages = count(t.custid),@TotalPages=@TotalPages/@PageSize + case when @TotalPages%@PageSize > 0 then 1 else 0 end  
	From
	(
		Select m.custid
		FROM 
			customer AS m with (NOLOCK)
			INNER JOIN custinfo as ci with (NOLOCK) on m.custid = ci.custid
			INNER JOIN CustSuper as csuper with (NOLOCK) on m.custid = csuper.custid
		WHERE m.currency = case when @Currency is null then m.currency else @Currency end
			and ci.closed = case when @closed is null then ci.closed else @closed end
			and csuper.isinternal = case when @IsInternal is null then csuper.isinternal else @IsInternal end
			and m.roleid=4 and m.custid>100 and m.username like @Keyword and m.username like @FirstChar
			AND csuper.IsInternal = 0 
			and dbo.f_IsDummySuper(ci.custid) = 0
	) t
END

select * from 
(
SELECT 
	ci.enabled, 
	ci.closed, 
	ci.reject as suspended,
	csuper.isinternal,
	m.username, 
	m.custid, 
	m.ugroup, 
	m.firstname, 
	m.lastname, 
	m.phone,
	m.mobilephone,
	m.iplogin as lastloginip,
	m.currency,
	m.roleid,
	max(cs.groupa) as groupa, 
	max(cs.groupb) as groupb, 
	max(cs.groupc) as groupc, 
	max(cs.groupd) as groupd, 

	max(case when cs.bettype = 4 and cs.sporttype=1 then cs.sdiscount else 0 end) as discountcs,
	max(case when cs.bettype = 5 and cs.sporttype=1 then cs.sdiscount else 0 end) as discount1x2,		
	ci.matchlimit,
	ci.virtualmultiplier-1 as VirtualMultiplier,
	ROW_NUMBER() OVER (ORDER BY CASE when isnull(ci.enabled,0) = 0 then 3 WHEN isnull(ci.closed,0) = 1 THEN 2 WHEN isnull(ci.reject,0) = 1 THEN 1 ELSE 0 end, m.username) as RowNumber
FROM 
	customer AS m with (NOLOCK)
	INNER JOIN custinfo as ci with (NOLOCK) on m.custid = ci.custid
	INNER JOIN CustSetting as cs with (NOLOCK) on m.custid = cs.custid	
	INNER JOIN CustSuper as csuper with (NOLOCK) on m.custid = csuper.custid
WHERE m.currency = case when @Currency is null then m.currency else @Currency end
	and ci.closed = case when @closed is null then ci.closed else @closed end
	and csuper.isinternal = case when @IsInternal is null then csuper.isinternal else @IsInternal end
	and m.roleid=4 and m.custid>100 and m.username like @Keyword and m.username like @FirstChar
	AND csuper.IsInternal = 0 and dbo.f_IsDummySuper(ci.custid) = 0
	
group by
	ci.enabled, 
	ci.closed, 
	ci.reject,
	csuper.isinternal,
	m.username, 
	m.custid, 
	m.ugroup, 
	m.firstname, 
	m.lastname, 
	m.phone,
	m.mobilephone,
	m.iplogin,
	m.currency, 
	m.roleid,--phuong.nguyen, get currency name	
	ci.matchlimit,
	ci.virtualmultiplier 
--ORDER BY ci.closed, m.username
) a
WHERE a.RowNumber BETWEEN @RowStart AND @RowEnd


GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelSAgEx] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerSelSAgEx] TO [vnteam]

