/*<info serverAlias="DBONUSER-ON_USER" executers="bodbAdminNet, bodbDownlineNet, bodbDownlineNetView" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE [dbo].[Age_On_UserKickedout_KL]
	@CustID INT,
	@SubAccID INT = 0
AS
/*
	Created: Elodie
	Task : kick out user [RedmineID: #67081]
	DB: DBONUSER/ON_USER
	Original:

	Revisions:
		- 20190620@Elodie: Add permission for bodbAdminNet  [Redmine: #116825]
		- 20231218@Johnson: setup KL DR [redmine: #195700]
	Param's Explanation:
*/
BEGIN
	SET NOCOUNT ON

	--UPDATE dbo.on_user_agent WITH (ROWLOCK, UPDLOCK)
	--SET iskickedout = 1
	--WHERE custid = @CustID AND subaccid = @SubAccID
	RETURN
END
GO