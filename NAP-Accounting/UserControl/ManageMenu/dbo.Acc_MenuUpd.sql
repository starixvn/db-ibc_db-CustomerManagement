/*<info serverAlias="DBCUST-NAP_UserControl" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_MenuUpd] 
    @MenuId            INT,
    @Menu           VARCHAR(50),    
    @FuncName   VARCHAR(50),
    @Url            VARCHAR(100),
    @Target         VARCHAR(50),
    @IsHide         BIT,
    @ORDER          INT,    
    @ErrCode        INT OUTPUT,
    @ErrMsg            VARCHAR(200) OUTPUT
               
AS
/*
	Created by: Robert
	Task : update menu
	DB: DB: DBCUST/NAP_UserControl

	Revisions:
			- 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST  [Redmine:99462]
	Param's Explanation:
*/

SET NOCOUNT ON

BEGIN
    IF not exists (SELECT 1 FROM Acc_Menu WITH (nolock) WHERE MenuId = @MenuId)
    BEGIN
        SELECT @ErrCode = 100, @ErrMsg = 'Invalid MenuId'
        RETURN
    END

    IF not exists(SELECT 1 FROM acc_functioninfo WITH (NOLOCK) WHERE FuncName=@FuncName)
    BEGIN
        SELECT @ErrCode = 101, @ErrMsg = 'Invalid FuncName'
        RETURN
    END

    UPDATE Acc_Menu WITH (UPDLOCK, ROWLOCK) SET
        Menu = @Menu,        
        FuncName = @FuncName,
        Url = @Url,		
        Target = @Target,
        IsHide = @IsHide,
        [ORDER] = @ORDER 
    WHERE MenuId = @MenuId
END
GO
GRANT EXECUTE ON [dbo].[Acc_MenuUpd] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_MenuUpd] TO [vnteam]