/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0" ></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerSelUnSyncRnG]
AS
/*   
	Create: 20180315@Johnson
	Task : Get list customers un-sync RnG 
	DB: DBCUST/CustDB
	Revisions:
		- 20180315@Johnson: create sp [Redmine: #91989]
*/
BEGIN
	SET NOCOUNT ON 
	
	CREATE TABLE #Supers (custid INT)
	CREATE TABLE #tblCust(CustID INT, username VARCHAR(50))
	
	INSERT INTO #Supers(custid)
	SELECT custid 
	FROM dbo.Customer ci (NOLOCK)
	WHERE ci.roleid = 4				
		AND ci.currency NOT IN (0,20,72)
		AND ci.custid NOT IN (SELECT custid from Dep_CustSuper (nolock))
		AND ci.username NOT LIKE '%3rdSuper%'
		AND ci.username NOT LIKE 'SM%'
		AND ci.username NOT IN ( 'SA-ttt', 'SA-TH' )
		AND site IN (SELECT site FROM site WHERE isLicensee = 0)
	
	INSERT INTO #tblCust(CustID,username)
	SELECT custid, username
	FROM dbo.CustInfo (NOLOCK)
	WHERE srecommend IN (SELECT custid FROM #Supers) 
		AND SyncCasino = 0
		AND Enabled = 1
	
	
	SELECT t.* FROM #tblCust t
	INNER JOIN dbo.custinfo ci (nolock) on t.custid = ci.custid
	WHERE t.custid NOT IN (
		SELECT custid FROM dbo.custSuper WITH(NOLOCK) WHERE isInternal = 1
		UNION SELECT custid FROM dbo.custMaster WITH(NOLOCK) WHERE isInternal = 1
		UNION SELECT custid FROM dbo.custAgent WITH(NOLOCK) WHERE isInternal = 1
	)
	and roleid > 1
	UNION 	SELECT t.* FROM #tblCust t
	INNER JOIN dbo.custinfo ci (nolock) on t.custid = ci.custid
	WHERE recommend IN (
		SELECT custid FROM dbo.custAgent WITH(NOLOCK) WHERE isInternal = 0
	)
	and roleid = 1
END
GO		
		