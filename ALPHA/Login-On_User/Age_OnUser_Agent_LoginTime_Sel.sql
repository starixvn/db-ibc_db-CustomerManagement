/*<info serverAlias="DBONUSER-ON_USER" executers="bodbDownlineNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_OnUser_Agent_LoginTime_Sel]
	@CustID INT , 
	@SubAccID INT = 0 , --Sub-AccountID,  
	@LoginTime DATETIME = NULL OUTPUT
AS

/*
	Created: 20210510@Eden
	Task : get On_User_Agent.LoginTime
	DB: DBCUST/CustDB

	Revisions:
		- 20210510@Eden: Enhancement for not relying on DB On_User [redmine: #154507]
	Param's Explanation:

*/

BEGIN
	IF EXISTS (	SELECT	TOP 1 1 
				FROM	dbo.On_User_Agent WITH (NOLOCK) 
				WHERE	CustID = @CustID AND SubAccID = @SubAccID AND ServerID<>0 AND isKickedOut = 0)
	BEGIN
		SELECT	@LoginTime = LoginTime 
		FROM	dbo.On_User_Agent WITH (NOLOCK) 
		WHERE	CustID = @CustID AND SubAccID = @SubAccID AND ServerID<>0 AND isKickedOut = 0
	END		
END
GO