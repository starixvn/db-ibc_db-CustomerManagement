/*<info serverAlias="DBCUST-NAP_UserControl" executers="bodbAdminNet" viewers="vnteam" isFunction="1" isNested="1"></info>*/
ALTER FUNCTION [dbo].[f_Get_GroupNameByGroupID]
 (@GroupID INT)  
RETURNS NVARCHAR(500) AS  
/*
Created: 20110526:TOM
Task : Get Group Name by GroupID in User Control 
DB: DBCUST/NAP_UserControl

Revisions:  
	- 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]	
*/
BEGIN 

	declare @returnVal nvarchar(500)

	Select @returnVal=GroupName from dbo.Acc_GroupInfo with(nolock)
	Where GroupID=@GroupID

	Return IsNull(@returnVal,'GroupID:'+convert(nvarchar(100),@GroupID))

END

GO
GRANT VIEW DEFINITION ON [dbo].[f_Get_GroupNameByGroupID] TO [vnteam]
GO
GRANT EXECUTE ON [dbo].[f_Get_GroupNameByGroupID] TO [bodbAdminNet]