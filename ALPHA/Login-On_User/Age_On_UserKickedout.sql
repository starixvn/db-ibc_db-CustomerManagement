ALTER PROCEDURE [dbo].[Age_On_UserKickedout]
	@CustID INT,
	@SubAccID INT = 0
AS
/*
	Created: Elodie
	Task : kick out user [RedmineID: #67081]
	DB: DBONUSER/ON_USER
	Original:

	Revisions:
	
	Param's Explanation:
*/
BEGIN
	SET NOCOUNT ON

	UPDATE dbo.on_user_agent WITH (ROWLOCK, UPDLOCK)
	SET iskickedout = 1
	WHERE custid = @CustID AND subaccid = @SubAccID

END

GO
GRANT EXECUTE ON [dbo].[Age_On_UserKickedout] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Age_On_UserKickedout] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Age_On_UserKickedout] TO [vnteam]