ALTER PROCEDURE [dbo].[Acc_Con_AdminPolicyIns]
	@CustID INT, 
	@UserID INT, 
	@GroupID INT, 
	@System VARCHAR (50)='ACCOUNTING'
AS
/*
Created: 
Task : Add account in User control 
DB: DB03.bodb02
Original:

Revisions:
	- 20110526@Tom: Remove condition @System 
	
*/
INSERT  INTO accCustomer_1 (custid, createdate, creator, groupid)
VALUES                    (@custid, getdate(), @UserID, @GroupID);
INSERT INTO Acc_MemberPolicy_1 (CustID, FuncID, Policy, CreateDate, ModifyDate, Creator)
SELECT @Custid AS custid,
       FuncID,
       -- 0 is default value of the member policy  when create new admin
       0 AS Policy,
       getdate() AS Createdate,
       getdate() AS ModifyDate,
       @UserID AS Creator
FROM   Acc_GroupPolicy_1 WITH (NOLOCK)
WHERE  GroupId = @GroupID;


GO
GRANT VIEW DEFINITION
   ON [dbo].[Acc_Con_AdminPolicyIns] TO [vnteam];


GO
GRANT EXECUTE
   ON [dbo].[Acc_Con_AdminPolicyIns] TO [bodbAdminNet];

