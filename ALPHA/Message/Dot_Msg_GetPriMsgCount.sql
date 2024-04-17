USE [bodb_Message]
GO
/****** Object:  StoredProcedure [dbo].[Dot_Msg_GetPriMsgCount]    Script Date: 07/31/2009 04:16:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Dot_Msg_GetPriMsgCount]
	@UserId int,
	@UserName nvarchar(20)
AS
BEGIN
	Select Count(*) As Count From dbo.MsgTarget with (nolock)
	Where IsRead =0 
	AND TargetId = @UserId
	AND TargetName = @UserName
END

GO
GRANT EXECUTE ON [dbo].[Dot_Msg_GetPriMsgCount] TO [wsv_alp]
GO
GRANT EXECUTE ON [dbo].[Dot_Msg_GetPriMsgCount] TO [bodbDownlineNetView,wsv_alpv]
GO
GRANT VIEW DEFINITION ON [dbo].[Dot_Msg_GetPriMsgCount] TO [vnteam]