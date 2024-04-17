ALTER PROCEDURE  [dbo].[Agw_CustomerSelByMAg]
	@MRecommend int ,
	@Keyword nvarchar(30)='%',
	@PageSize int=50,
	@PageIndex int=0,
	@TotalPages int=0 output
AS

/*

Created: 20080909@QuiNV
Task: Get all agent of master custid=@MRecommend
DB: DBCUST.CustDB
Original:

Revisions:
	- 20150612@Kathy: Move sp from DBAGE.bodb02 to DBCUST.CustDB [Redmine:#36216]


*/

SET NOCOUNT ON

DECLARE @RowCount int, @RowStart int, @RowEnd int  
SELECT @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1   


IF @TotalPages = 0  
BEGIN  
 SELECT @TotalPages = count(c.custid),@TotalPages=@TotalPages/@PageSize + case when @TotalPages%@PageSize > 0 then 1 else 0 end   
 FROM
	(
	select custid
	from customer with(nolock) 
	where mrecommend=@MRecommend and roleid=2 and username like @Keyword
	) as c
 
END

SELECT c.custid, c.username FROM
(
select custid, username, ROW_NUMBER() over (order by username) as RowNum
from customer with(nolock) 
WHERE mrecommend=@MRecommend and roleid=2 and username like @Keyword
) as c

WHERE RowNum between @RowStart and @RowEnd

GO
GRANT EXECUTE ON [dbo].[Agw_CustomerSelByMAg] TO [wsv_alp] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Agw_CustomerSelByMAg] TO [vnteam] AS [dbo]