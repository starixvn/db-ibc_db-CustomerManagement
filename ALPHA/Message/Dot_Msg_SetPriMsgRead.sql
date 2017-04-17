USE [bodb_Message]
GO
/****** Object:  StoredProcedure [dbo].[Dot_Msg_SetPriMsgRead]    Script Date: 07/31/2009 04:31:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Dot_Msg_SetPriMsgRead]
	@UserId int,
	@UserName nvarchar(20)
AS
BEGIN
	Update dbo.MsgTarget
	SET IsRead = 1
	WHERE IsRead = 0
		AND TargetId = @UserId
		AND TargetName = @UserName
END

GO
GRANT EXECUTE ON [dbo].[Dot_Msg_SetPriMsgRead] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Dot_Msg_SetPriMsgRead] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Dot_Msg_SetPriMsgRead] TO [vnteam]