 ALTER PROCEDURE [dbo].[Acc_CustomerSelMAgEx]
	@Currency int = NULL,
	@Closed bit = NULL,
	@IsInternal bit = NULL,
	@Keyword nvarchar(50)='%',
	@FirstChar nvarchar(6)='%',
	@PageSize int=50,
	@PageIndex int=1,
	@TotalPages int=0 OUTPUT
AS
/*
Created by: Jamie
Date: 2010-06-04
Task : Select Direct Master Agent list for specific Site [Thai]
DB: DB05.bodb02
Original: magentsite/account\customerlist.asp
		  SP: Acc_CustomerSelMAgByCom 

Revisions:
	
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
	SELECT @TotalPages = count(t.custid),@TotalPages=@TotalPages/@PageSize + case when @TotalPages%@PageSize>0 then 1 else 0 end 
	From(
			select m.custid
				FROM 
				customer AS m with (NOLOCK)
				INNER JOIN custinfo as ci with (NOLOCK) on m.custid = ci.custid
				INNER JOIN CustMaster cm WITH (NOLOCK) ON m.custid = cm.custid
			WHERE m.SRecommend < 100 and m.roleid=3
				and m.currency = case when @Currency is null then m.currency else @Currency end
				and ci.closed = case when @closed is null then ci.closed else @closed end
				AND cm.isinternal = case when @IsInternal is null then cm.isinternal else @IsInternal end
				and m.username like @Keyword and m.username like @FirstChar
				and dbo.f_IsDummySuper(m.SRecommend) = 0
		) t
END
Select * From 
(
	SELECT 		
		ci.enabled, 
		ci.closed, 
		ci.roleid,
		ci.reject as suspended,
		m.username, 
		m.custid,
		m.srecommend,
		m.ugroup, 
		m.firstname, 
		m.lastname, 
		m.phone,
		m.mobilephone,
		ci.matchlimit,
		ci.virtualmultiplier-1 as VirtualMultiplier,
		m.iplogin as lastloginip,
		max(cs.groupa) as groupa, 
		max(cs.groupb) as groupb, 
		max(cs.groupc) as groupc, 
		max(cs.groupd) as groupd, 
		max(case when cs.bettype = 4 and cs.sporttype=1 then cs.adiscount else 0 end) as discountcs,
		max(case when cs.bettype = 5 and cs.sporttype=1 then cs.adiscount else 0 end) as discount1x2,		
		m.currency as exchangeid,
		m.currency,
		cm.isinternal,
		ROW_NUMBER() OVER (ORDER BY CASE when isnull(ci.enabled,0) = 0 then 3 WHEN isnull(ci.closed,0) = 1 THEN 2 WHEN isnull(ci.reject,0) = 1 THEN 1 ELSE 0 end, m.username) as RowNumber
	FROM 
		customer AS m with (NOLOCK)
		INNER JOIN custinfo as ci with (NOLOCK) on m.custid = ci.custid
		INNER JOIN CustSetting as cs with (NOLOCK) on m.custid = cs.custid
		INNER JOIN CustMaster cm WITH (NOLOCK) ON m.custid = cm.custid
	WHERE m.SRecommend < 100 and m.roleid=3
		and m.currency = case when @Currency is null then m.currency else @Currency end
		and ci.closed = case when @closed is null then ci.closed else @closed end
		AND cm.isinternal = case when @IsInternal is null then cm.isinternal else @IsInternal end
		and m.username like @Keyword and m.username like @FirstChar
		and dbo.f_IsDummySuper(m.SRecommend) = 0
	group by
		ci.enabled, 
		ci.closed,
		ci.roleid, 
		ci.reject,
		ci.matchlimit,
		ci.virtualmultiplier,
		m.username, 
		m.custid, 
		m.ugroup, 
		m.firstname, 
		m.lastname, 
		m.phone,
		m.mobilephone,
		m.iplogin,
		m.srecommend,
		m.currency,
		cm.isinternal
) a
WHERE a.RowNumber BETWEEN @RowStart AND @RowEnd

GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelMAgEx] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerSelMAgEx] TO [vnteam]