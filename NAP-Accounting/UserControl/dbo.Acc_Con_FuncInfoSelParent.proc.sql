/*<info serverAlias="DBCUST-NAP_UserControl" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_Con_FuncInfoSelParent]
@System varchar(50)='ACCOUNTING'
AS
/*
Task: Select function Info BY System 
DB: DBCUST/NAP_UserControl

Revision
	- 20101123@Jamie: Change to use acc_functioninfo instead of acc_functioninfo_1
	- 20150112@Johnson: filter by @sytem to support NAPU3 [Redmine: #28516]
	- 20180808@Helen: DB05.DBPOLICY migration  [Redmine:99462]
	
*/
BEGIN
	SET NOCOUNT ON 

	Select FuncId, FuncName
	from acc_functioninfo WITH (NOLOCK)
	where System = @System
END	

GO
GRANT VIEW DEFINITION ON [dbo].[Acc_Con_FuncInfoSelParent] TO [vnteam]
go
GRANT EXECUTE ON [dbo].[Acc_Con_FuncInfoSelParent] TO [bodbAdminNet]