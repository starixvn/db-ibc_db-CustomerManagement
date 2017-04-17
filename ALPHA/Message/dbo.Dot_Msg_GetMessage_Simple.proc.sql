SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Dot_Msg_GetMessage_Simple]
@msgType		int = 3,
@targetid		varchar(100) = '0',
@targetid2		varchar(100) = '0'
AS
    /*
    Created: @TWTeam
    Task: Get the latest message which is private or public
    DB: DB07
    Original:
    Revisions:
    
    Param's Explanation:
    */
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT top 1 m.MessageId, m.Content_en, m.Content_cs, m.Content_ch,
					    m.Content_jp, m.Content_th, m.Content_it,
					    m.PostTime, m.IsPublic, m.IsSticky,
					    m.Creator, m.CreateTime, mg.TargetId,
					    m.CreatorName, mg.TargetName as UserName,
					    DENSE_RANK() OVER(ORDER BY m.messageid desc) as rownum
		FROM dbo.Msg m with (nolock)
		INNER JOIN MsgTarget mg with (nolock) ON m.MessageId = mg.MessageId
		where @targetid <> '0' AND mg.TargetID IN (SELECT val FROM dbo.strSplit(@targetid,','))
END

GO
GRANT EXECUTE ON [dbo].[Dot_Msg_GetMessage_Simple] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Dot_Msg_GetMessage_Simple] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Dot_Msg_GetMessage_Simple] TO vnteam