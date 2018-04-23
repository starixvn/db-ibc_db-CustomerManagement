/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0" ></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerSelRnGStatus]
	@strUserName VARCHAR(4000)
AS
/*   
	Create: 20180316@Johnson
	Task : Get Sync RnG Status for customers 
	DB: DBCUST/CustDB
	Revisions:
		- 20180315@Johnson: create sp [Redmine: #91989]
*/
BEGIN
	SET NOCOUNT ON 	
	DECLARE @tmpCust table (CustID INT,Username VARCHAR(50), roleid TINYINT,UplineID INT, currency INT, SyncCS BIT, ExistsCSDB BIT DEFAULT 0)
	
	INSERT INTO @tmpCust(custid,username,roleid,UplineID,currency,syncCS)
	SELECT custid, username, roleid, 
		CASE roleid WHEN 1 THEN recommend
					WHEN 2 THEN mrecommend
					WHEN 3 THEN srecommend END,
		currency, syncCasino
	FROM dbo.Custinfo WITH(NOLOCK)
	WHERE username IN (SELECT val FROM strSplit(@strUserName,','))
	
	UPDATE t
	SET ExistsCSDB = 1
	FROM @tmpCust t
		INNER JOIN DBCasino.Casinoadmin.dbo.Customer cs WITH(NOLOCK) ON t.custid = cs.ibccustid
	
	SELECT t.*, ci.username as UplineUserName, e.currency as currencyName
	FROM @tmpCust t
		INNER JOIN dbo.Custinfo ci WITH(NOLOCK) ON t.UplineID = ci.custid
		INNER JOIN dbo.Exchange e WITH(NOLOCK) ON t.currency = e.exchangeid
	WHERE t.custid IS NOT NULL
	ORDER BY roleid DESC	
END
GO	