/*<info serverAlias="DBONUSER-ON_USER" executers="wsv_nap, bodbDownlineNet,wsv_alp, bodbDownlineNetView,wsv_alpv" viewers="" isFunction="0"></info>*/

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
		- 20190620@Elodie: Add permission for wsv_nap  [Redmine: #116825]

	Param's Explanation:
*/
BEGIN
	SET NOCOUNT ON

	UPDATE dbo.on_user_agent WITH (ROWLOCK, UPDLOCK)
	SET iskickedout = 1
	WHERE custid = @CustID AND subaccid = @SubAccID

END
GO