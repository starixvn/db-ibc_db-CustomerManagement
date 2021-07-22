/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE Acc_CustomerLockSuspendSel
AS
/*
	Created: 20200216@Elodie
	Task : Select customer who upline don''t allow to unsuspend
	DB: DBCUST/CustDB

	Revisions:
		- 20200216@Elodie: Initial SP [Redmine:#128541]
		- 20210510@Tina: Lock account & indirect close account [redmine: #148600]
	Param's Explanation:
*/
BEGIN
	SET NOCOUNT ON
	
	SELECT ci.custid, ci.username, ci.roleid,
		--1:Open, 2:Suspended, 3:Closed
		CASE WHEN ci.Enabled = 1 THEN CASE WHEN ISNULL(cps.closed,ci.closed) = 1 THEN 'Closed' WHEN ISNULL(cps.reject,ci.reject) = 1 THEN 'Suspended' ELSE 'Open' END ELSE 'Disabled' END AS CustStatus						
	FROM CustSuspendLockUpd cs WITH (NOLOCK)
		INNER JOIN dbo.custInfo ci WITH (NOLOCK) ON cs.custid = ci.custid
		CROSS APPLY  (SELECT CASE WHEN CloseInfo > 0 THEN 1 ELSE 0 END AS closed
										, CASE WHEN SuspendInfo > 0 THEN 1 ELSE 0 END AS reject
									FROM dbo.CustProductStatus  WITH(NOLOCK)
									WHERE CustID = ci.custid 
								) AS cps	
	ORDER BY ci.username, ci.roleid
END

