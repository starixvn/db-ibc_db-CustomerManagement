  set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go


ALTER PROCEDURE [dbo].[Age_SelCustomerGivenCreditByMAg]
	@MRecommend int ,
	@Username nvarchar(30)= null,
	@Enabled bit = null,
	@Closed bit=null,
	@Suspended bit=null,
	@PageSize int=50,
	@PageIndex int=0,
	@TotalPages int output
AS

/*

Created: 20110223@Kaden
Task: Get all agent's given credit of master custid=@MRecommend. It's only use for IPhone
DB: DB05.bodb02
Original:
	-20110321@Kaden.Trinh: Rename @Keyword to @Username
	-20110321@Kaden.Trinh: add parameter status(Enabled, Closed, Suspended), so that we can search for it.  
*/

SET NOCOUNT ON

DECLARE @RowCount int, @RowStart int, @RowEnd int  
SELECT @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1   

SET @Username = isnull(@Username, '')
IF @Username = '' AND @Enabled IS NULL AND @Closed IS NULL AND @Suspended IS NULL
BEGIN
	IF @TotalPages = 0  
	BEGIN 
		SELECT @TotalPages = count(1),@TotalPages=@TotalPages/@PageSize + case when @TotalPages%@PageSize > 0 then 1 else 0 end   
		FROM
			custinfo WITH(NOLOCK) 
		WHERE
			mrecommend=@MRecommend and roleid=2
	END


	SELECT 
		c.custid, 
		c.username, 
		c.givencredit,
		c.enabled,
		c.closed, 
		isnull(c.reject,0) as suspended 
	FROM
	(
		select custid, username, reject, closed, Enabled, credit as givencredit , ROW_NUMBER() over(order by enabled desc, closed, isnull(reject,0), username) as RowNum
		from custinfo with(nolock) 
		where mrecommend=@MRecommend and roleid=2
	) as c
	WHERE RowNum between @RowStart and @RowEnd
END

ELSE IF @Username = ''
BEGIN
	IF @TotalPages = 0  
	BEGIN 
		SELECT @TotalPages = count(1),@TotalPages=@TotalPages/@PageSize + case when @TotalPages%@PageSize > 0 then 1 else 0 end   
		FROM
			Custinfo as ci with (NOLOCK)			
		WHERE ci.mrecommend = @MRecommend and ci.roleid=2 
			AND enabled = case when coalesce(@Closed,@Suspended) is not null then 1 else coalesce(@enabled, enabled) end
			AND isnull(ci.closed,0) = case when @suspended = 1 then 0 else coalesce(@closed, isnull(ci.closed, 0)) end			
			AND isnull(ci.reject,0) = case when @Closed = 0 then 0 else coalesce(@suspended, isnull(ci.reject, 0))end			
	END


	SELECT 
		c.custid, 
		c.username, 
		c.givencredit,
		c.enabled,
		c.closed, 
		isnull(c.reject,0) as suspended 
	FROM
	(
		SELECT custid, username, reject, closed, Enabled, credit as givencredit , ROW_NUMBER() over(order by enabled desc, closed, isnull(reject,0), username) as RowNum
		FROM Custinfo as ci with (NOLOCK)	
		WHERE ci.mrecommend = @MRecommend and ci.roleid=2 
			AND enabled = case when coalesce(@Closed,@Suspended) is not null then 1 else coalesce(@enabled, enabled) end
			AND isnull(ci.closed,0) = case when @suspended = 1 then 0 else coalesce(@closed, isnull(ci.closed, 0)) end			
			AND isnull(ci.reject,0) = case when @Closed = 0 then 0 else coalesce(@suspended, isnull(ci.reject, 0))end			
	) as c
	WHERE RowNum between @RowStart and @RowEnd
END
ELSE
BEGIN
	IF @TotalPages = 0  
	BEGIN 
		SELECT @TotalPages = count(1),@TotalPages=@TotalPages/@PageSize + case when @TotalPages%@PageSize > 0 then 1 else 0 end   
		FROM
			Custinfo as ci with (NOLOCK)			
		WHERE ci.mrecommend = @MRecommend and ci.roleid=2 
			AND ci.username like '%' + @Username + '%'  
			AND enabled = case when coalesce(@Closed,@Suspended) is not null then 1 else coalesce(@enabled, enabled) end
			AND isnull(ci.closed,0) = case when @suspended = 1 then 0 else coalesce(@closed, isnull(ci.closed, 0)) end
			AND isnull(ci.reject,0) = case when @Closed = 0 then 0 else coalesce(@suspended, isnull(ci.reject, 0))end			
	END


	SELECT 
		c.custid, 
		c.username, 
		c.givencredit,
		c.enabled,
		c.closed, 
		isnull(c.reject,0) as suspended 
	FROM
	(
		SELECT custid, username, reject, closed, Enabled, credit as givencredit , ROW_NUMBER() over(order by enabled desc, closed, isnull(reject,0), username) as RowNum
		FROM Custinfo as ci with (NOLOCK)	
		WHERE ci.mrecommend = @MRecommend and ci.roleid=2 
			AND ci.username like '%' + @Username + '%'  
			AND enabled = case when coalesce(@Closed,@Suspended) is not null then 1 else coalesce(@enabled, enabled) end
			AND isnull(ci.closed,0) = case when @suspended = 1 then 0 else coalesce(@closed, isnull(ci.closed, 0)) end
			AND isnull(ci.reject,0) = case when @Closed = 0 then 0 else coalesce(@suspended, isnull(ci.reject, 0))end			
	) as c
	WHERE RowNum between @RowStart and @RowEnd
END


GO
GRANT EXECUTE ON [dbo].[Age_SelCustomerGivenCreditByMAg] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Age_SelCustomerGivenCreditByMAg] TO [vnteam]
GO