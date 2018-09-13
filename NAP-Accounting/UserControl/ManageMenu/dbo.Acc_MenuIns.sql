 /*<info serverAlias="DBCUST-NAP_UserControl" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
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
	DB: DBCUST/NAP_UserControl

	Revisions:
		- 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]
		
	Param's Explanation:
*/

BEGIN
	SET NOCOUNT ON
    INSERT INTO Acc_MeNu(Menu, ParentId, FuncName, Url, Target, IsHide, [ORDER], [SyStem])
    VALUES(@Menu, @ParentId, @FuncName, @Url, @Target, @IsHide, @ORDER, @System)
END

GO
GRANT EXECUTE ON [dbo].[Acc_MenuIns] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_MenuIns] TO [vnteam]

