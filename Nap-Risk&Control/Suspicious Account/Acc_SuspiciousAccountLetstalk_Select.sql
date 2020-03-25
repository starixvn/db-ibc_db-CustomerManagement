/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE dbo.Acc_SuspiciousAccountLetstalk_Select
/*
 Created: Robert
 Date: 20200305@Robert  
 Task :#129119 - [NAP] Auto notify newly created suspicious account
 DB: DBACC.bodb02
 Original:
 Revisions:
	- 20200305@Robert: #129119 - [NAP] Auto notify newly created suspicious account
  
 Param's Explanation:
 
 */
AS
    BEGIN
	   CREATE TABLE #TmpAcc(
		   CustId           INT
		 , UserName         VARCHAR(50)
		 , NotifyStatus1    INT
		 , NotifyStatus2    INT
		 , credit           MONEY
		 , currency         INT);

	   INSERT INTO #TmpAcc(CustId
					 , UserName
					 , NotifyStatus1
					 , NotifyStatus2
					 , credit
					 , currency)
			SELECT s.CustID
				, c.UserName
				, s.NotifyStatus1
				, s.NotifyStatus2
				, c.credit
				, c.currency
			FROM SuspiciousCust AS s WITH(NOLOCK)
			    INNER JOIN dbo.custInfo AS c WITH(NOLOCK) ON s.CustID = c.custid
			WHERE NotifyStatus1 = 1
				 OR NotifyStatus2 = 1;

	   CREATE NONCLUSTERED INDEX IX_TmpAcc_Currency ON #TmpAcc(currency);
	   SELECT t.CustId
		   , t.UserName
		   , t.NotifyStatus1
		   , t.NotifyStatus2
		   , t.credit
		   , e.currency
	   FROM #TmpAcc AS t
		  INNER JOIN dbo.Exchange AS e WITH(NOLOCK) ON t.currency = e.exchangeid
	   ORDER BY t.UserName ASC;

	   DROP TABLE #TmpAcc;
    END;