/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerSelFinance_MAg]
	@SRecommend int,
	@Username varchar(30)=null,
	@PageSize int = 20000,
	@PageIndex int = 1,
	@TotalRow int = 1 output
AS
/*
	Created by: Elodie
	Date: 20120712
	Task: Master Finance List 
	DB: DBCUST.CustDB
	Original: Acc_CustomerSelBySAg
	
	Revisions:
	- 20210408@Tina: Lock account & indirect close account [redmine: #148600]
		
*/

SET NOCOUNT ON
DECLARE @RowCount int, @RowStart int, @RowEnd int
SELECT  @PageIndex = @PageIndex - 1, 
		@RowStart = @PageSize * @PageIndex + 1, 
		@RowEnd = @RowStart + @PageSize - 1 
		
SET @Username = isnull(@Username, '')

IF @Username = ''
BEGIN
	IF @TotalRow = 0
		SELECT 
			@TotalRow = count(1)
		FROM 
			Custinfo as ci with (NOLOCK)
		WHERE 
			ci.SRecommend = @SRecommend and ci.roleid=3
			
	select * from 
	(
		SELECT 
			ROW_NUMBER() OVER (ORDER BY m.username) as RowNumber,
			m.username, 
			m.username2,			
			isnull(m.firstname, '') as firstname , 
			isnull(m.lastname, '') as lastname, 
			m.custid,
			m.roleid		
		FROM 
			customer m with (NOLOCK)
			INNER JOIN CustMaster cm with(NOLOCK) on m.custid = cm.custid 
		WHERE m.SRecommend = @SRecommend and m.roleid=3 	
		group by
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
			ci.SRecommend = @SRecommend and ci.roleid=3
			AND ci.username like '%' + @Username + '%'  

	select * from 
	(

		SELECT 
			ROW_NUMBER() OVER (ORDER BY m.username) as RowNumber,
			m.username, 
			isnull(m.username2,'') as username2,
			isnull(m.firstname, '') as firstname , 
			isnull(m.lastname, '') as lastname, 		
			m.custid,
			m.roleid			
		FROM 
			customer AS m with (NOLOCK)
			INNER JOIN CustMaster cm with(NOLOCK) on m.custid = cm.custid 
		WHERE m.SRecommend = @SRecommend and m.roleid=3
			AND m.username like '%' + @Username + '%'  
		group by
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