 /****** Object:  UserDefinedFunction [dbo].[f_Get_GroupNameByGroupID] Script Date: 05/26/2011 10:02:37 ******/

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER FUNCTION [dbo].[f_Get_GroupNameByGroupID]
 (@GroupID INT)  
RETURNS NVARCHAR(500) AS  
/*
Created: 20110526:TOM
Task : Get Group Name by GroupID in User Control 
DB: DB03.bodb02



*/

BEGIN 

	declare @returnVal nvarchar(500)

	Select @returnVal=GroupName from dbo.Acc_GroupInfo_1 with(nolock)
	Where GroupID=@GroupID

	Return IsNull(@returnVal,'GroupID:'+convert(nvarchar(100),@GroupID))

END

GO
GRANT VIEW DEFINITION ON [dbo].[f_Get_GroupNameByGroupID] TO [vnteam]
GO
GRANT EXECUTE ON [dbo].[f_Get_GroupNameByGroupID] TO [bodbAdminNet]