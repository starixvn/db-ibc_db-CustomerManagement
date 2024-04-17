SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE Age_MessageNoticeSelByCustID 
	@custID int
AS
BEGIN
    /*
    Created: 20090122@AnhPham
    Task: Get data from table "MESSAGE_NOTICE" by @custID
    DB: DB03.On_User
    Original:
    Revisions:
		- 20110427@Simon: Add Popup Message For Betting Limit.
    
    Param's Explanation:
        . @custID: ID of agent
    */

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Select statements for procedure here
	SELECT TypeID
	FROM MESSAGE_NOTICE WITH (NOLOCK)
	WHERE @custID = custID AND 0 = isViewed
END
GO

GRANT EXECUTE ON [dbo].[Age_MessageNoticeSelByCustID] TO [wsv_alp]
GO
GRANT EXECUTE ON [dbo].[Age_MessageNoticeSelByCustID] TO [bodbDownlineNetView,wsv_alpv] 
GO
GRANT VIEW DEFINITION ON [dbo].[Age_MessageNoticeSelByCustID] TO [vnteam] 
GO