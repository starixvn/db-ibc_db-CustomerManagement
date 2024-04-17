/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap,bodbDownlineNet,wsv_alp,bodbExtAccNet,wsv_xnap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_MessageNoticeDownlineUpd_Wrapper]
	@CustID			INT, 	
	@UserID			INT,
	@TypeID			INT, -- 3: Status
	@IsDisabled		VARCHAR(MAX) = NULL
AS

/*
	Created: 20210510@Eden
	Task : call DBONUSER.ON_USER.dbo.Age_MessageNoticeDownlineUpd
	DB: DBCUST/CustDB

	Revisions:
		- 20210510@Eden: Enhancement for not relying on DB On_User [redmine: #154507]
	Param's Explanation:

*/

BEGIN
	BEGIN TRY --on DBONUSER
		EXEC DBONUSER.ON_USER.dbo.Age_MessageNoticeDownlineUpd @CustID = @CustID, @userID = @userID, @TypeID = @TypeID, @IsDisabled = @IsDisabled
	END TRY
	BEGIN CATCH --on DBCUST
		BEGIN TRY
			EXEC ON_USER.dbo.Age_MessageNoticeDownlineUpd @CustID = @CustID, @userID = @userID, @TypeID = @TypeID, @IsDisabled = @IsDisabled
		END TRY
		BEGIN CATCH
			RETURN
		END CATCH
	END CATCH
END
GO