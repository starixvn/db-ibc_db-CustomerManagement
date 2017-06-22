ALTER PROCEDURE [dbo].[Acc_Con_Batch_AdminPolicySel]
	@CustIDs NVARCHAR (4000), 
	@GroupID INT=NULL OUTPUT, 
	@System VARCHAR (50)='ACCOUNTING'
AS
/*
	Created by: []
	Task: Get functionID by CustIDs 
	DB: DB03.BODB02
	
	Revisions:
		- 20101123@Jamie: Change to use acc_functioninfo instead of acc_functioninfo_1 
		- 20110526@Tom: Remove condition @System
*/
SET NOCOUNT ON;
SELECT TOP 1 @GroupID = GroupID
FROM   AccCustomer_1 WITH (NOLOCK)
WHERE  Custid IN (SELECT val
                  FROM   dbo.strSplit_Key (@CustIDs, ','));
SELECT   fi.funcid,
         fi.funcname,
         fi.funcdesc,
         f.policy,
         gp.policy AS gpolicy,
         fi.parentid,
         count(fip.funcID) AS SubFuncCount,
         fi.DisplayOrder
FROM     acc_functioninfo AS fi WITH (NOLOCK)
         INNER JOIN
         (SELECT   funcid,
                   min(policy) AS policy,
                   ac.groupid AS groupid
          FROM     acc_memberpolicy_1 AS mp WITH (NOLOCK)
                   INNER JOIN
                   AccCustomer_1 AS ac WITH (NOLOCK)
                   ON ac.custid = mp.custid
          WHERE    mp.custid IN (SELECT val
                                 FROM   dbo.strSplit_Key (@CustIDs, ','))
          GROUP BY mp.funcid, ac.groupid) AS f
         ON fi.funcid = f.funcid
         INNER JOIN
         Acc_GroupPolicy_1 AS gp WITH (NOLOCK)
         ON gp.groupid = f.groupid
            AND gp.funcID = f.funcID
         LEFT OUTER JOIN
         acc_functioninfo AS fip WITH (NOLOCK)
         ON fi.funcID = fip.ParentID
            AND fip.parentid <> fip.funcid
GROUP BY fi.funcid, fi.funcname, fi.funcdesc, f.policy, gp.policy, fi.parentid, fi.DisplayOrder
ORDER BY fi.parentid, count(fip.funcID) DESC, fi.DisplayOrder;


GO
GRANT VIEW DEFINITION
    ON [dbo].[Acc_Con_Batch_AdminPolicySel] TO [vnteam];


GO
GRANT EXECUTE
    ON [dbo].Acc_Con_Batch_AdminPolicySel TO [bodbAdminNet];

