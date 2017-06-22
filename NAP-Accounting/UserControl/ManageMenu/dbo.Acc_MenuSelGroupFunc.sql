 Alter PROCEDURE [dbo].[Acc_MenuSelGroupFunc]    
	@ErrCode		int output,
	@ErrMsg			varchar(200) output
                
AS 
/*
Created by: Robert
Task : select group function
DB: DB03.bodb02

Revisions:
	- 20101129@Steven: Change to use acc_functioninfo instead of acc_functioninfo_1
Param's Explanation:

*/

SET NOCOUNT ON

BEGIN
    select FuncName from acc_functioninfo (nolock) where System='Accounting' order by FuncName 
END

GO
GRANT EXECUTE ON [dbo].[Acc_MenuSelGroupFunc] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_MenuSelGroupFunc] TO [vnteam]

