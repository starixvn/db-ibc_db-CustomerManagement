/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0" ></info>*/
ALTER PROCEDURE [dbo].[Task_Winlimit_CustWinlostGameIns]
	@xmlData XML
AS
/*   
	Create: 20220721@Johnson
	Task : Import data winlimit game - [Redmine:175278]
	DB: DBCUST/CUSTDB
	
	Revisions:
		- 20220721@Johnson: Initial sp [Redmine: 175278]
		
	Param's Explanation:
		- @xmlData = '<Root>
						<r id="1" d="2020-07-01" b="2001" wl="1000" />
						<r id="1" d="2020-07-01" b="2008" wl="2000" />
						<r id="2" d="2020-07-01" b="2001" wl="1000" />
						<r id="3" d="2020-07-01" b="2001" wl="1000" />
					</Root>'
		
	
*/
BEGIN
	SET NOCOUNT ON
	
	CREATE TABLE #DataTmp (CustId INT							
							, Bettype SMALLINT							
							, WinlostDate SMALLDATETIME
							, Winlost MONEY
							PRIMARY KEY (custid,bettype,winlostdate)
							)
	
	INSERT INTO #DataTmp (custid,winlostdate,bettype,winlost)	
	SELECT t.c.value('@id[1]','int'),
		t.c.value('@d[1]','smalldatetime'),
		t.c.value('@b[1]','smallint'),
		t.c.value('@wl[1]','money')
	FROM @xmlData.nodes('Root/r')as t(c)

	MERGE WinLimit_CustWinlostGame as Target
	USING #DataTmp as Source ON source.custid = target.custid
								AND source.Bettype = target.Bettype
								AND source.WinlostDate = target.WinlostDate
	WHEN MATCHED AND source.Winlost <> target.Winlost THEN UPDATE SET target.Winlost = source.Winlost
	WHEN NOT MATCHED THEN INSERT(custid,winlostdate,bettype,winlost) VALUES(source.custid,source.winlostdate,source.bettype,source.winlost);
	
	DROP TABLE #DataTmp
END	