/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_alp" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_OnUser_Agent_LoginTime_Sel_Wrapper]
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
	BEGIN TRY --on DBONUSER
		EXEC DBONUSER.ON_USER.dbo.Age_OnUser_Agent_LoginTime_Sel @CustID = @CustID, @SubAccID = @SubAccID, @LoginTime = @LoginTime OUTPUT
	END TRY
	BEGIN CATCH --on DBCUST
		BEGIN TRY
			EXEC ON_USER.dbo.Age_OnUser_Agent_LoginTime_Sel @CustID = @CustID, @SubAccID = @SubAccID, @LoginTime = @LoginTime OUTPUT
		END TRY
		BEGIN CATCH
			RETURN
		END CATCH
	END CATCH
END
GO