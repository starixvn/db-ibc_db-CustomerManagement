/*<info serverAlias="DBCUST-NAP_UserControl" executers="bodbExtAccNet,wsv_xnap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_eaUserInfo_Ins]
	@UserId			INT,	
	@GroupId		INT,
	@Enabled		BIT = 1,
	@Creator		INT,
	@ErrCode		INT = 0 OUTPUT
AS
	/*
		Created: Luke
		Date: 20240321
		Task: Insert user's info to eaUserInfo
		DB: DBCUST/NAP_UserControl
		
		Revisions:
			- 20240321@Luke: EXT - Failed to create external account [Redmine: #202675]

		Parameter's Explanation:
	*/
SET NOCOUNT ON

INSERT INTO dbo.eaUserInfo (UserID, GroupID, [enabled], creator, CreatedDate)
VALUES (@UserId, @GroupID, @Enabled, @Creator, CURRENT_TIMESTAMP)

SELECT @ErrCode = @@ERROR

GO