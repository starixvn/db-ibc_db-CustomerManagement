ALTER PROCEDURE [dbo].[Acc_Con_AdminPolicySelByCustID]
	@CustID INT, 
	@GroupID INT=NULL OUTPUT, 
	@System VARCHAR (50)='ACCOUNTING'
AS
/*
	Created by: []
	Task: Get functionID by CustID 
	DB: DB03.BODB02
	
	Revisions:
		- 20101123@Jamie: Change to use acc_functioninfo instead of acc_functioninfo_1 
		- 20110526@Tom: Remove condition @System 
		- 20150107@Johnson: add more system 'NAPU3' [redmine: #28516]
*/
SET NOCOUNT ON;
SELECT   c.username,
         fi.funcname,
         fi.funcdesc,
         mp.funcid,
         mp.policy,
         gp.policy AS gpolicy,
         (Isnull(mp.policy, 0) | Isnull(gp.policy, 0)) & Isnull(fi.funcrender, 0) AS actual_policy,
         fi.parentid,
         COUNT(fip.funcid) AS subfunccount,
         fi.displayorder
FROM     acc_memberpolicy_1 AS mp WITH (NOLOCK)
         INNER JOIN
         acccustomer_1 AS ac WITH (NOLOCK)
         ON ac.custid = mp.custid
         INNER JOIN
         acc_functioninfo AS fi WITH (NOLOCK)
         ON mp.funcid = fi.funcid --or mp.funcid=fi.parentid
         INNER JOIN
         customer AS c WITH (NOLOCK)
         ON c.custid = mp.custid
         INNER JOIN
         acc_grouppolicy_1 AS gp WITH (NOLOCK)
         ON gp.groupid = ac.groupid
            AND gp.funcid = mp.funcid
         LEFT OUTER JOIN
         acc_functioninfo AS fip WITH (NOLOCK)
         ON fi.funcid = fip.parentid
            AND fip.parentid <> fip.funcid
WHERE    mp.custid = @CustID
		AND fi.system = @system
GROUP BY c.username, fi.funcname, fi.funcdesc, mp.funcid, mp.policy, fi.displayorder, gp.policy, fi.funcrender, fi.parentid
ORDER BY fi.parentid, COUNT(fip.funcid) DESC, fi.displayorder;
SELECT @GroupID = groupid
FROM   acccustomer_1 WITH (NOLOCK)
WHERE  custid = @custid;


GO
GRANT VIEW DEFINITION
   ON [dbo].[Acc_Con_AdminPolicySelByCustID] TO [vnteam];


GO
GRANT EXECUTE
   ON [dbo].acc_con_adminpolicyselbycustid TO [bodbadminnet];


GO
GRANT EXECUTE
   ON [dbo].acc_con_adminpolicyselbycustid TO [bodbExtAccNet];

