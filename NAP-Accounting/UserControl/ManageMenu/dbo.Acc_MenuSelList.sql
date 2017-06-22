  ALTER PROCEDURE [dbo].[Acc_MenuSelList] 
    
@System varchar(50) = ''                
AS 

/*
Created by: 
Task : SP select menu list
DB: DB03.bodb02

Revisions:
Param's Explanation: 
*/

SET NOCOUNT ON

BEGIN
    SELECT MenuId, Menu, ParentId, FuncName,
    Url, Target, IsHide, [Order], System
    FROM Acc_Menu (nolock) 
	WHERE System = @System
	ORDER BY parentid, [Order]
END

GO
GRANT EXECUTE ON [dbo].[Acc_MenuSelList] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_MenuSelList] TO [bodbExtAccNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_MenuSelList] TO [vnteam]

