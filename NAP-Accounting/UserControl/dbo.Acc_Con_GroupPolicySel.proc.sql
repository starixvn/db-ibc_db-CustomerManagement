/*<info serverAlias="DBCUST-NAP_UserControl" executers="bodbAdminNet,wsv_nap" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_Con_GroupPolicySel]
@Groupid INT,
@system	 VARCHAR(50)='ACCOUNTING'
AS
/*
Task: SELECT group info 
DB: DBCUST/NAP_UserControl

Revision
	- 20101123@Jamie: Change to use acc_functioninfo instead of acc_functioninfo_1
	- 20150112@Johnson: add filter by system to support NAPU3 site [redmine: #28979]
	- 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]
*/
BEGIN
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
	FROM     Acc_GroupPolicy AS gp WITH (NOLOCK)
			 INNER JOIN
			 Acc_groupInfo AS gi WITH (NOLOCK)
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

END
GO
GRANT VIEW DEFINITION
    ON [dbo].[Acc_Con_GroupPolicySel] TO [vnteam];


GO
GRANT EXECUTE
    ON [dbo].Acc_Con_GroupPolicySel TO [bodbAdminNet,wsv_nap];

