
 ALTER PROCEDURE [dbo].[Acc_MenuDel] 
    @MenuId     INT,
	@ErrCode	INT=0 OUTPUT,
    @ErrMsg     VARCHAR(200)='' OUTPUT
AS
/*
Created by: Robert
Task : delete menu
DB: DB03.bodb02


Revisions:
Param's Explanation:
*/
BEGIN
	SET NOCOUNT ON
    IF not exists (SELECT 1 FROM Acc_Menu (nolock) WHERE MenuId = @MenuId)
    BEGIN
        SELECT @ErrCode = 100, @ErrMsg = 'Invalid MenuId'
        RETURN
    END

	DELETE FROM Acc_menu WITH (UPDLOCK,ROWLOCK) 
    WHERE MenuId = @MenuId
END

GO
GRANT EXECUTE ON [dbo].[Acc_MenuDel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_MenuDel] TO [vnteam]