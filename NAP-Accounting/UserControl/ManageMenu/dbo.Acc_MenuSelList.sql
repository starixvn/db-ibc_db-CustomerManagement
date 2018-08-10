/*<info serverAlias="DBCUST-NAP_UserControl" executers="bodbAdminNet,bodbExtAccNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_MenuSelList] 
    
@System varchar(50) = ''                
AS 

/*
	Created by: 
	Task : SP select menu list
	DB: DBCUST/NAP_UserControl

	Revisions:
		- 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]
	Param's Explanation: 
*/

SET NOCOUNT ON

BEGIN
    SELECT MenuId, Menu, ParentId, FuncName,
    Url, Target, IsHide, [Order], System
    FROM Acc_Menu WITH (NOLOCK) 
	WHERE System = @System
	ORDER BY parentid, [Order]
END

GO
GRANT EXECUTE ON [dbo].[Acc_MenuSelList] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_MenuSelList] TO [bodbExtAccNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_MenuSelList] TO [vnteam]

