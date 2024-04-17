/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap,wsv_alp,bodbExtAccNet,wsv_xnap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_MessageNoticeDownlineUpdStatus_Wrapper]
	@custID		int,
	@isViewed	BIT, -- 1: Status is viewed.
	@TypeID		TINYINT
AS

/*
	Created: 20210510@Eden
	Task : call DBONUSER.ON_USER.dbo.Age_MessageNoticeDownlineUpdStatus
	DB: DBCUST/CustDB

	Revisions:
		- 20210510@Eden: Enhancement for not relying on DB On_User [redmine: #154507]
	Param's Explanation:

*/

BEGIN
	BEGIN TRY --on DBONUSER
		EXEC DBONUSER.ON_USER.dbo.Age_MessageNoticeDownlineUpdStatus @CustID = @CustID, @isViewed = @isViewed, @TypeID = @TypeID
	END TRY
	BEGIN CATCH --on DBCUST
		BEGIN TRY
			EXEC ON_USER.dbo.Age_MessageNoticeDownlineUpdStatus @CustID = @CustID, @isViewed = @isViewed, @TypeID = @TypeID
		END TRY
		BEGIN CATCH
			RETURN
		END CATCH
	END CATCH
END
GO