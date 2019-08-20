/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0" ></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerSelUnSyncRnG]
AS
/*   
	Create: 20180315@Johnson
	Task : Get list customers un-sync RnG 
	DB: DBCUST/CustDB
	Revisions:
		- 20180315@Johnson: create sp [Redmine: #91989]
		- 20180731@Winnie: Sync RNG Casino function - exclude CN88 customers [Redmine: #117672]
*/
BEGIN
	SET NOCOUNT ON 
	
	CREATE TABLE #Supers (custid INT)
	CREATE TABLE #tblCust(CustID INT, username VARCHAR(50), roleid TINYINT,UplineID INT, currency INT, SyncCS BIT, ExistsCSDB BIT DEFAULT 0)
	
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
		AND Site<>'CN88'
	
	INSERT INTO #tblCust(CustID,username,roleid,UplineID,currency,SyncCS)
	SELECT custid, username,roleid,
		CASE roleid WHEN 1 THEN recommend
					WHEN 2 THEN mrecommend
					WHEN 3 THEN srecommend END,
		currency, syncCasino
	FROM dbo.CustInfo (NOLOCK)
	WHERE srecommend IN (SELECT custid FROM #Supers) 
		AND SyncCasino = 0
		AND Enabled = 1
	
	UPDATE t
	SET ExistsCSDB = 1
	FROM #tblCust t
		INNER JOIN DBCasino.Casinoadmin.dbo.Customer cs WITH(NOLOCK) ON t.custid = cs.ibccustid
	SELECT *
	FROM(	
		SELECT t.*,upline.username as UplineUserName, e.currency as currencyName
		FROM #tblCust t
			INNER JOIN dbo.custinfo ci (nolock) on t.custid = ci.custid
			INNER JOIN dbo.Custinfo upline WITH(NOLOCK) ON t.UplineID = upline.custid
			INNER JOIN dbo.Exchange e WITH(NOLOCK) ON t.currency = e.exchangeid
		WHERE t.custid NOT IN (
			SELECT custid FROM dbo.custSuper WITH(NOLOCK) WHERE isInternal = 1
			UNION SELECT custid FROM dbo.custMaster WITH(NOLOCK) WHERE isInternal = 1
			UNION SELECT custid FROM dbo.custAgent WITH(NOLOCK) WHERE isInternal = 1
		)
		and ci.roleid > 1
		UNION 	SELECT t.*,upline.username as UplineUserName, e.currency as currencyName
		FROM #tblCust t
			INNER JOIN dbo.custinfo ci WITH(NOLOCK) ON t.custid = ci.custid
			INNER JOIN dbo.Custinfo upline WITH(NOLOCK) ON t.UplineID = upline.custid
			INNER JOIN dbo.Exchange e WITH(NOLOCK) ON t.currency = e.exchangeid
		WHERE ci.recommend IN (
			SELECT custid FROM dbo.custAgent WITH(NOLOCK) WHERE isInternal = 0
		)
		and ci.roleid = 1
	)t
	ORDER BY roleid DESC
END
GO		
		