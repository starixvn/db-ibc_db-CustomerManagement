ALTER PROCEDURE dbo.Acc_Con_MemPolicySel
	@system VARCHAR (50)='Accounting', 
	@custid INT
AS
/*
	Created by: []
	Task: Update department of account in User Control 
	DB: DB03.BODB02
 
	Revisions:
		
*/
SET NOCOUNT ON;
SELECT   Acc_FunctionInfo.FuncID,
         Acc_FunctionInfo.FuncName,
         Acc_FunctionInfo.FuncDesc,
         Acc_MemberPolicy.Policy,
         Acc_FunctionInfo.ParentID
FROM     Acc_FunctionInfo WITH (NOLOCK), Acc_MemberPolicy WITH (NOLOCK)
WHERE    Acc_FunctionInfo.FuncID != Acc_MemberPolicy.FuncID
         AND Acc_MemberPolicy.Custid = @custid
         AND Acc_FunctionInfo.system = @system
GROUP BY Acc_FunctionInfo.FuncID, Acc_FunctionInfo.FuncName, Acc_FunctionInfo.FuncDesc, Acc_MemberPolicy.Policy, Acc_FunctionInfo.ParentID
ORDER BY Acc_FunctionInfo.ParentID;


GO
GRANT EXECUTE
    ON [dbo].[Acc_Con_MemPolicySel] TO [bodbAdminNet];

