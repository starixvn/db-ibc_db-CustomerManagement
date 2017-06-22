ALTER PROCEDURE [dbo].[Acc_CustomerSelFinance_Ag]
	@MRecommend int,
	@Username varchar(30)=null,
	@Enabled bit = null,
	@Closed bit=null,
	@Suspended bit = null,
	@PageSize int = 20000,
	@PageIndex int = 1,
	@TotalRow int = 1 output
AS
/*
	Created by: Elodie
	Date: 20120712
	Task: Agent Finance List 
	DB: DB053.BODB02
	Original: Acc_CustomerSelByMAg
	
	Revisions:
		
*/
SET NOCOUNT ON
DECLARE @RowCount int, @RowStart int, @RowEnd int
SELECT  @PageIndex = @PageIndex - 1, 
		@RowStart = @PageSize * @PageIndex + 1, 
		@RowEnd = @RowStart + @PageSize - 1 
		
SET @Username = isnull(@Username, '')

IF @Username = '' AND @Enabled IS NULL AND @Closed IS NULL AND @Suspended IS NULL
BEGIN
	IF @TotalRow = 0
		SELECT 
			@TotalRow = count(1)
		FROM
			Custinfo as ci with (NOLOCK)			
		WHERE 	
			ci.MRecommend = @MRecommend and ci.roleid=2 
	select * from 
	(
		SELECT 
			ROW_NUMBER() OVER (ORDER BY ci.enabled desc, ci.closed, isnull(ci.reject,0), m.username) as RowNumber,
			
			ci.enabled,
			ci.closed, 
			isnull(ci.reject,0) as suspended,	
			
			m.username, 
			m.username2,			
			isnull(m.firstname, '') as firstname , 
			isnull(m.lastname, '') as lastname, 
			m.custid,
			m.roleid
		FROM 
			customer m with (NOLOCK)
			INNER JOIN custinfo ci with (NOLOCK) on m.custid = ci.custid								
			INNER JOIN CustAgent as ca with (NOLOCK) on m.custid = ca.custid
		WHERE ci.MRecommend = @MRecommend and ci.roleid=2
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
	where a.rownumber between @rowstart and @rowend
END
ELSE IF @Username = ''
BEGIN
	IF @TotalRow = 0
		SELECT 
			@TotalRow = count(1)
		FROM 
			Custinfo as ci with (NOLOCK)			
		WHERE 	
			ci.MRecommend = @MRecommend and ci.roleid=2 
			AND enabled = case when coalesce(@Closed,@Suspended) is not null then 1 else coalesce(@enabled, enabled) end
			AND isnull(ci.closed,0) = case when @suspended = 1 then 0 else coalesce(@closed, isnull(ci.closed, 0)) end			
			AND isnull(ci.reject,0) = case when @Closed = 0 then 0 else coalesce(@suspended, isnull(ci.reject, 0))end			
	select * from 
	(
		SELECT 
			ROW_NUMBER() OVER (ORDER BY ci.enabled desc, ci.closed, isnull(ci.reject,0), m.username) as RowNumber,
			
			ci.enabled,
			ci.closed, 
			isnull(ci.reject,0) as suspended,	
			
			m.username, 
			isnull(m.username2, '') as username2,			
			isnull(m.firstname, '') as firstname , 
			isnull(m.lastname, '') as lastname, 
			m.custid,
			m.roleid
		FROM 
			customer AS m with (NOLOCK)
			INNER JOIN custinfo ci with (NOLOCK) on m.custid = ci.custid												
			INNER JOIN CustAgent as ca with (NOLOCK) on m.custid = ca.custid
		WHERE ci.MRecommend = @MRecommend and ci.roleid=2 
			AND enabled = case when coalesce(@Closed,@Suspended) is not null then 1 else coalesce(@enabled, enabled) end
			AND isnull(closed,0) = case when @suspended = 1 then 0 else coalesce(@closed, isnull(closed, 0)) end
			AND isnull(reject,0) = case when @Closed = 0 then 0 else coalesce(@suspended, isnull(reject, 0))end			
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
	where a.rownumber between @rowstart and @rowend
END
ELSE
BEGIN
	IF @TotalRow = 0
		SELECT 
			@TotalRow = count(1)
		FROM 
			Custinfo as ci with (NOLOCK)
		WHERE 	
			ci.MRecommend = @MRecommend and ci.roleid=2 
			AND ci.username like '%' + @Username + '%'  
			AND enabled = case when coalesce(@Closed,@Suspended) is not null then 1 else coalesce(@enabled, enabled) end
			AND isnull(ci.closed,0) = case when @suspended = 1 then 0 else coalesce(@closed, isnull(ci.closed, 0)) end
			AND isnull(ci.reject,0) = case when @Closed = 0 then 0 else coalesce(@suspended, isnull(ci.reject, 0))end			
	select * from 
	(
		SELECT 
			ROW_NUMBER() OVER (ORDER BY ci.enabled desc, ci.closed, isnull(ci.reject,0), m.username) as RowNumber,
			
			ci.enabled,
			ci.closed, 
			isnull(ci.reject,0) as suspended,	
			
			m.username, 
			isnull(m.username2,'') as username2,
			isnull(m.firstname, '') as firstname , 
			isnull(m.lastname, '') as lastname, 		
			m.custid,
			m.roleid
		FROM 
			customer AS m with (NOLOCK)
			INNER JOIN custinfo ci with (NOLOCK) on m.custid = ci.custid	
			INNER JOIN CustAgent as ca with (NOLOCK) on m.custid = ca.custid
		WHERE ci.MRecommend = @MRecommend and ci.roleid=2 
			AND ci.username like '%' + @Username + '%'  
			AND enabled = case when coalesce(@Closed,@Suspended) is not null then 1 else coalesce(@enabled, enabled) end
			AND isnull(closed,0) = case when @suspended = 1 then 0 else coalesce(@closed, isnull(closed, 0)) end
			AND isnull(reject,0) = case when @Closed = 0 then 0 else coalesce(@suspended, isnull(reject, 0))end								
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
	where a.rownumber between @rowstart and @rowend
END

GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelFinance_Ag] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerSelFinance_Ag] TO [vnteam]




