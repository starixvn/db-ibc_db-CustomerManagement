/*<info serverAlias="DBCUST-CUSTDB" executers="bodbDownlineNet,bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_MessageNoticeUpd_Wrapper]
	@custID			int, 	
	@userID			int,
	@TypeID			int=1 -- 1: Position taking. 2: Betting Limit.
AS

/*
	Created: 20210510@Eden
	Task : call DBONUSER.ON_USER.dbo.Age_MessageNoticeUpd
	DB: DBCUST/CustDB

	Revisions:
		- 20210510@Eden: Enhancement for not relying on DB On_User [redmine: #154507]
	Param's Explanation:

*/

BEGIN
	BEGIN TRY --on DBONUSER
		EXEC DBONUSER.ON_USER.dbo.Age_MessageNoticeUpd @CustID = @CustID, @userID = @userID, @TypeID = @TypeID
	END TRY
	BEGIN CATCH --on DBCUST
		BEGIN TRY
			EXEC ON_USER.dbo.Age_MessageNoticeUpd @CustID = @CustID, @userID = @userID, @TypeID = @TypeID
		END TRY
		BEGIN CATCH
			RETURN
		END CATCH
	END CATCH
END
GO