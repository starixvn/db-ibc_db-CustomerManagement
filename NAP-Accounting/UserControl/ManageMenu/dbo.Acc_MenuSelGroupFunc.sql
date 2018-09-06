 /*<info serverAlias="DBCUST-NAP_UserControl" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_MenuSelGroupFunc]    
	@ErrCode		int output,
	@ErrMsg			varchar(200) output
                
AS 
/*
Created by: Robert
Task : select group function
DB: DBCUST/NAP_UserControl

Revisions:
	- 20101129@Steven: Change to use acc_functioninfo instead of acc_functioninfo_1
	- 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]
	
Param's Explanation:

*/
BEGIN
	SET NOCOUNT ON
    select FuncName from acc_functioninfo (nolock) where System='Accounting' order by FuncName 
END

GO
GRANT EXECUTE ON [dbo].[Acc_MenuSelGroupFunc] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_MenuSelGroupFunc] TO [vnteam]

