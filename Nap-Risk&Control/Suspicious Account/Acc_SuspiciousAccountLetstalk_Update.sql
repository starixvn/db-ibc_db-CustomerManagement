/*<info serverAlias="DBCust-CustDB" executers="wsv_nap" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Acc_SuspiciousAccountLetstalk_Update(
	@MemNotify    XML)
/*
 Created: Robert
 Date: 20200305@Robert  
 Task :#129119 - [NAP] Auto notify newly created suspicious account
 DB: DBCust.CustDB
 Original:
 Revisions:
	- 20200305@Robert: #129119 - [NAP] Auto notify newly created suspicious account
	- 20241230@July: Scale Out DBCUST - Apply Inhouse replication for the remaning tables [Redmine: #215627]

 Param's Explanation:
 
 */
AS
    BEGIN
	   SET NOCOUNT ON;
	   CREATE TABLE #tempMemNotify(
		   CustID           INT
		 , NotifyStatus1    TINYINT
		 , NotifyStatus2    TINYINT);

	   INSERT INTO #tempMemNotify
			SELECT Tbl.Col.value
				  ('@custid', 'INT')
				, Tbl.Col.value
				  ('@NotifyStatus1', 'TINYINT')
				, Tbl.Col.value
				  ('@NotifyStatus2', 'TINYINT')
			FROM @MemNotify.nodes
				('//notify/row') AS Tbl(Col);

	   UPDATE s
			SET 
			    s.NotifyStatus1 = t.NotifyStatus1
			  , s.NotifyStatus2 = t.NotifyStatus2
			  , s.RepUpdateTime = dbo.f_GetDateTime2()
	   FROM dbo.SuspiciousCust s
		  INNER JOIN #tempMemNotify t ON s.CustID = t.CustID;
    END;