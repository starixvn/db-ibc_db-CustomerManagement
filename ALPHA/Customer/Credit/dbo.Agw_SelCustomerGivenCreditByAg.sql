ALTER PROCEDURE  [dbo].[Agw_SelCustomerGivenCreditByAg]
	@Recommend int ,
	@Keyword nvarchar(30)='%',
	@PageSize int=50,
	@PageIndex int=0,
	@TotalPages int output
AS

/*

Created: 20081025@QuiNV
Task: Get all member's given credit of agent custid=@Recommend
DB: DBCUST.custDB
Original:
Revisions
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
	where recommend=@Recommend and roleid=1 and username like @Keyword
	) as c
 
END

SELECT c.custid, c.username, c.givencredit FROM
(
select custid, username, credit as givencredit , ROW_NUMBER() over(order by username) as RowNum
from custinfo with(nolock) 
where recommend=@Recommend and roleid=1 and username like @Keyword

) as c

WHERE RowNum between @RowStart and @RowEnd

GO
GRANT EXECUTE ON [dbo].[Agw_SelCustomerGivenCreditByAg] TO [bodbDownlineNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Agw_SelCustomerGivenCreditByAg] TO [vnteam] AS [dbo]