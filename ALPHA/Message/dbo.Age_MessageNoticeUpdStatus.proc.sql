SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[Age_MessageNoticeUpdStatus] 
	@custID		int,
	@isViewed	BIT, -- 1: Status is viewed.
	@TypeID		TINYINT = 1 -- 1: Position taking. 2: Betting Limit. 3: Status	
AS
BEGIN
    /*
    Created: 20090119@AnhPham
    Task: set value of field "isViewed" in table “MESSAGE_NOTICE”
    DB: DB03.On_User
    Original:
    Revisions:
		- 20110427@Simon: Add Popup Message For Betting Limit.
		
    Param's Explanation:
        . @custID: ID of agent
        . @isViewed: status will be updated
    */

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Update statements for procedure here
	UPDATE MESSAGE_NOTICE WITH(ROWLOCK)
	SET isViewed = @isViewed
	WHERE custID = @custID AND TypeID = @TypeID
END

GO
GRANT EXECUTE ON [dbo].[Age_MessageNoticeUpdStatus] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Age_MessageNoticeUpdStatus] TO [vnteam] 
GO