ALTER PROCEDURE  [dbo].[Agw_SelCustomerGivenCreditByMAg]
	@MRecommend int ,
	@Keyword nvarchar(30)='%',
	@PageSize int=50,
	@PageIndex int=0,
	@TotalPages int output
AS

/*

Created: 20081025@QuiNV
Task: Get all agent's given credit of master custid=@MRecommend
DB: DBCUST.custDB
Original:
Revisions: 
	- 20150612@Kathy: Move sp from DB05.bodb02 to DBCUST.CustDB [Redmine:#36216]

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
	from custinfo with(nolock) 
	where mrecommend=@MRecommend and roleid=2 and username like @Keyword
	) as c
 
END


SELECT c.custid, c.username, c.givencredit FROM
(
select custid, username, credit as givencredit , ROW_NUMBER() over(order by username) as RowNum
from custinfo with(nolock) 
where mrecommend=@MRecommend and roleid=2 and username like @Keyword

) as c

WHERE RowNum between @RowStart and @RowEnd

GO
GRANT EXECUTE ON [dbo].[Agw_SelCustomerGivenCreditByMAg] TO [wsv_alp] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Agw_SelCustomerGivenCreditByMAg] TO [vnteam] AS [dbo]