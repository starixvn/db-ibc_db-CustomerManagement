ALTER PROCEDURE [dbo].[Acc_Con_FuncInfoSelByFuncID]
@FuncId INT
AS
/*
Task: Select function Info BY FuncID 
DB: DB03.BODB02 

Revision
	20101123@Jamie: Change to use acc_functioninfo instead of acc_functioninfo_1
*/
SET NOCOUNT ON;
SELECT FuncId,
       FuncName,
       FuncDesc,
       FileNames,
       (SELECT count(funcid)
        FROM   acc_functioninfo AS acc1 WITH (NOLOCK)
        WHERE  acc1.parentid = acc.funcid
               AND acc1.parentid <> acc1.funcid) AS SubFuncCount
FROM   acc_functioninfo AS acc WITH (NOLOCK)
WHERE  FuncId = @FuncId;


GO
GRANT VIEW DEFINITION
    ON [dbo].[Acc_Con_FuncInfoSelByFuncID] TO [vnteam];


GO
GRANT EXECUTE
    ON [dbo].[Acc_Con_FuncInfoSelByFuncID] TO [bodbAdminNet];


GO
GRANT EXECUTE
    ON [dbo].[Acc_Con_FuncInfoSelByFuncID] TO [bodbExtAccNet];

