/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE Acc_CustomerLockSuspendSel
AS
/*
	Created: 20200216@Elodie
	Task : Select customer who upline don''t allow to unsuspend
	DB: DBCUST/CustDB

	Revisions:
		- 20200216@Elodie: Initial SP [Redmine:#128451]
	Param's Explanation:
*/
BEGIN
	SET NOCOUNT ON
	
	SELECT ci.custid, ci.username, ci.roleid,
		--1:Open, 2:Suspended, 3:Closed
		CASE WHEN ci.Enabled = 1 THEN CASE WHEN ci.closed = 1 THEN 'Closed' WHEN ci.reject = 1 THEN 'Suspended' ELSE 'Open' END ELSE 'Disabled' END AS CustStatus						
	FROM CustSuspendLockUpd cs WITH (NOLOCK)
		INNER JOIN dbo.custInfo ci WITH (NOLOCK) ON cs.custid = ci.custid	
	ORDER BY ci.username, ci.roleid
END

