/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_xnap" viewers="" isFunction="0"></info>*/
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
		- 20201116@Johnson: get sub group for supers list [redmine:#145199]
		- 20201211@Johnson: enhance sort super list [redmine:#146741]
		- 20201222@Johnson: Exclude disabled accounts [redmine:#147578]
		- 20210408@Tina: Lock account & indirect close account [redmine: #148600]
		- 20220614@Eden: DBCUST - modify sp syntax to adapt with the SQL Server upgrade to 2019 [Redmine: #171831] 

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
	CREATE TABLE #SuperList (custid INT, username VARCHAR(50), closed BIT, suspended BIT, Enabled BIT, SubGroup VARCHAR(1000), rn INT)
	
	INSERT INTO @tmpGroup (GroupName)
	SELECT value
	FROM STRING_SPLIT (@SubGroup,',')
	WHERE value <> ''
	
	INSERT INTO #SuperList(custid,username,closed,suspended,enabled)
	SELECT ci.custid, 
		ci.username, 
		cps.closed, 
		ISNULL(cps.reject, 0) AS suspended,
		ci.enabled			
	FROM Acc_CustGroup c WITH(NOLOCK)
		INNER JOIN custinfo ci WITH(NOLOCK) ON c.custid = ci.custid
		CROSS APPLY  (SELECT CASE WHEN CloseInfo > 0 THEN 1 ELSE 0 END AS closed
										, CASE WHEN SuspendInfo > 0 THEN 1 ELSE 0 END AS reject
									FROM dbo.CustProductStatus  WITH(NOLOCK)
									WHERE CustID = ci.custid
								) AS cps
	WHERE c.GroupName = @GroupName
		AND ci.roleid = 4
		AND ci.enabled = 1
		AND ci.username LIKE '%'+@username+'%'
	
	SELECT @TotalRows = @@ROWCOUNT
	
	;WITH tmp AS(
		SELECT custid,
			STUFF((
			SELECT ',' + GroupName 
			FROM Acc_CustGroup WITH(NOLOCK)
			WHERE CustID = t.custid
				AND GroupName IN (SELECT GroupName 
								FROM NAP_UserControl.dbo.eaGroup WITH(NOLOCK) 
								WHERE ParentID > 0
								)
				FOR XML PATH('')),1,1,'') as SubGroup	
		FROM #SuperList t			
	)
	UPDATE t2
	SET t2.SubGroup = tmp.SubGroup
	FROM #SuperList t2 
		INNER JOIN tmp ON tmp.custid = t2.custid
	
	;WITH tmp AS (
		SELECT t.custid, 
		ROW_NUMBER() OVER (ORDER BY CASE WHEN ISNULL(subGroup,'') <> '' THEN 1 ELSE 0 END ASC,t.enabled DESC, t.closed ASC, t.suspended ASC, t.username) rn
		FROM #SuperList t
	)
	UPDATE t2
	SET t2.rn = tmp.rn
	FROM #SuperList t2 
		INNER JOIN tmp ON tmp.custid = t2.custid
	
	SELECT custid,
		username,
		closed,
		suspended,
		enabled,
		SubGroup
	FROM #SuperList
	WHERE rn BETWEEN @RowStart AND @RowEnd
	ORDER BY rn ASC
		
	SELECT s.custid, GroupName
	FROM #SuperList s
		INNER JOIN Acc_CustGroup c WITH(NOLOCK) ON s.custid = c.custid
	WHERE c.GroupName IN (SELECT GroupName FROM @tmpGroup)
		AND rn BETWEEN @RowStart AND @RowEnd
END	
