 ALTER PROCEDURE [dbo].[Acc_MenuIns] 
    @Menu           VARCHAR(50),
    @ParentId       INT,
    @FuncName   VARCHAR(50),
    @Url			VARCHAR(100),
	@System			VARCHAR(50),
    @Target         VARCHAR(50),
    @IsHide         BIT,
    @ORDER          INT,
	@ErrCode		int output,
	@ErrMsg			varchar(200) output
                
AS 
/*
Created by: Robert
Task : insert menu
DB: DB03.bodb02


Revisions:
Param's Explanation:
*/

SET NOCOUNT ON

BEGIN
    INSERT INTO Acc_MeNu(Menu, ParentId, FuncName, Url, Target, IsHide, [ORDER], [SyStem])
    VALUES(@Menu, @ParentId, @FuncName, @Url, @Target, @IsHide, @ORDER, @System)
END

GO
GRANT EXECUTE ON [dbo].[Acc_MenuIns] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_MenuIns] TO [vnteam]

