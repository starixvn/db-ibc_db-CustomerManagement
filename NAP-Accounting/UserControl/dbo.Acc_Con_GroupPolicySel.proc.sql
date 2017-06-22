ALTER PROCEDURE [dbo].[Acc_Con_GroupPolicySel]
@Groupid INT,
@system	 VARCHAR(50)='ACCOUNTING'
AS
/*
Task: SELECT group info 
DB: DB03.BODB02 

Revision
	20101123@Jamie: Change to use acc_functioninfo instead of acc_functioninfo_1
	- 20150112@Johnson: add filter by system to support NAPU3 site [redmine: #28979]
*/
SET NOCOUNT ON;
SELECT   gp.createdate,
         gp.modifydate,
         gp.policy,
         gp.groupid,
         fi.funcid,
         gi.groupname,
         fi.funcname,
         fi.funcdesc,
         fi.parentid,
         count(fip.funcID) AS SubFuncCount,
         fi.DisplayOrder
FROM     Acc_GroupPolicy_1 AS gp WITH (NOLOCK)
         INNER JOIN
         Acc_groupInfo_1 AS gi WITH (NOLOCK)
         ON gp.groupid = gi.groupid
         INNER JOIN
         acc_functioninfo AS fi WITH (NOLOCK)
         ON gp.funcid = fi.funcid
         LEFT OUTER JOIN
         acc_functioninfo AS fip WITH (NOLOCK)
         ON fi.funcID = fip.ParentID
            AND fip.parentid <> fip.funcid
WHERE    gp.groupid = @Groupid
		AND fi.system = @system
GROUP BY gp.createdate, gp.modifydate, gp.policy, gp.groupid, fi.funcid, gi.groupname, fi.funcname, fi.funcdesc, fi.parentid, fi.DisplayOrder
ORDER BY fi.parentid, count(fip.funcID) DESC, fi.DisplayOrder;


GO
GRANT VIEW DEFINITION
    ON [dbo].[Acc_Con_GroupPolicySel] TO [vnteam];


GO
GRANT EXECUTE
    ON [dbo].Acc_Con_GroupPolicySel TO [bodbAdminNet];

