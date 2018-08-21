/*<info serverAlias="DBCUST-NAP_UserControl" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Acc_Con_AdminPolicyIns]
	@CustID INT, 
	@UserID INT, 
	@GroupID INT, 
	@System VARCHAR (50)='ACCOUNTING'
AS
/*
Created: 
Task : Add account in User control 
DB: DBCUST/NAP_UserControl
Original:

Revisions:
	- 20110526@Tom: Remove condition @System 
	- 20180808@Helen: DB05.DBPOLICY migration  - Move to DBCUST [Redmine:99462]
	
*/
BEGIN

	INSERT  INTO dbo.accCustomer (custid, createdate, creator, groupid)
	VALUES (@custid, getdate(), @UserID, @GroupID)
	
	INSERT INTO dbo.Acc_MemberPolicy (CustID, FuncID, Policy, CreateDate, ModifyDate, Creator)
	SELECT @Custid AS custid,
		   FuncID,
		   -- 0 is default value of the member policy  when create new admin
		   0 AS Policy,
		   getdate() AS Createdate,
		   getdate() AS ModifyDate,
		   @UserID AS Creator
	FROM   dbo.Acc_GroupPolicy WITH (NOLOCK)
	WHERE  GroupId = @GroupID;
END	
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Con_AdminPolicyIns] TO [vnteam]
GO
GRANT EXECUTE  ON [dbo].[Acc_Con_AdminPolicyIns] TO [bodbAdminNet]
GO

