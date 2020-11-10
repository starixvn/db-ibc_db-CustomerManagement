/*<info serverAlias="DBCUST-CUSTDB" executers="bodbExtAccNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_CustomerSelBySubGroup] 
	@username  VARCHAR(50) = '',
	@GroupName VARCHAR(50),
    @SubGroup	VARCHAR(MAX),
	@PageIndex	INT = 1 OUTPUT,
	@PageSize	INT = 500,
	@TotalRows	INT = 0 OUTPUT
AS
/*	Created 20200804@Johnson  
	Task : Customer list assign supers to sub groups
	DB: DBCUST/CustDB
	
	Revisions:  
		- 20200804@Johnson: initial sp [redmine:#136501]
	
	Parameter's explanation:
		- @GroupName: main group
		- @SubGroup: list of sub groups of main group need to get super list to assign
	
*/		
BEGIN
	SET NOCOUNT ON 
	DECLARE @RowStart INT, @RowEnd INT

	SELECT @RowStart = @PageSize * (@PageIndex - 1)  + 1
	SELECT @RowEnd = @RowStart + @PageSize - 1 
	
	DECLARE @tmpGroup TABLE (GroupName VARCHAR(50))
	CREATE TABLE #SuperList (custid INT, username VARCHAR(50), closed BIT, suspended BIT, Enabled BIT, rn INT)
	
	INSERT INTO @tmpGroup (GroupName)
	SELECT val
	FROM strSplit (@SubGroup,',')
	
	INSERT INTO #SuperList(custid,username,closed,suspended,enabled,rn)
	SELECT ci.custid, 
		ci.username, 
		ci.closed, 
		ISNULL(ci.reject, 0) AS suspended,
		ci.enabled,		
		ROW_NUMBER() OVER (ORDER BY ci.enabled DESC, ci.closed ASC, ci.reject ASC, ci.username) rn
	FROM Acc_CustGroup c WITH(NOLOCK)
		INNER JOIN custinfo ci WITH(NOLOCK) ON c.custid = ci.custid
	WHERE c.GroupName = @GroupName
		AND ci.roleid = 4
		AND ci.username LIKE '%'+@username+'%'
	
	SELECT @TotalRows = @@ROWCOUNT
	
	SELECT custid,
		username,
		closed,
		suspended,
		enabled
	FROM #SuperList
	WHERE rn BETWEEN @RowStart AND @RowEnd
		
	SELECT s.custid, GroupName
	FROM #SuperList s
		INNER JOIN Acc_CustGroup c WITH(NOLOCK) ON s.custid = c.custid
	WHERE c.GroupName IN (SELECT GroupName FROM @tmpGroup)
		AND rn BETWEEN @RowStart AND @RowEnd
END	
	