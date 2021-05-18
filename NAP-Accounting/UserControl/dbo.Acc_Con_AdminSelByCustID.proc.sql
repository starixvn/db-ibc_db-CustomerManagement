/*<info serverAlias="DBCUST-NAP_UserControl" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_Con_AdminSelByCustID]
	@CustID INT, 
	@System VARCHAR (50)='ACCOUNTING'
AS
/*
	Created by: []
	Task: Get info of account by ID in User Control 
	DB: DBCUST/NAP_UserControl
 
	Revisions:
		- 20110526@Tom: Remove condition @System
		- 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]
		- 20210408@Tina: Lock account & indirect close account [redmine: #148600]
*/
BEGIN
	SELECT c.custid,
	   c.username,
	   c.firstname,
	   c.lastname,
	   ac.groupid,
	   c.roleid,
	   CASE WHEN cps.CloseInfo > 0 THEN 1 ELSE 0 END AS closed,
	   c.userpwd
	FROM   AccCustomer AS ac WITH (NOLOCK)
		   INNER JOIN CUSTDB.dbo.Customer AS c WITH (NOLOCK)  ON c.custid = ac.custid
		   INNER JOIN CUSTDB.dbo.CustProductStatus AS cps WITH (NOLOCK)  ON cps.custid = c.custid
	WHERE  ac.custid = @custid
	
END	
GO

