/*<info serverAlias="DBPOL-NAP_UserControl" executers="wsv_xnap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_UserRecheckIn]
	@On_UserID		INT,
	@isKickedOut	BIT = 0 OUTPUT
AS
	/*
		Created: Dan
		Date: 2012-11-16
		Task: User re-checkin 
		DB: DBPOL/NAP_UserControl
		Revisions:
			- 20190502@Kan: DBPOL/NAP_UserControl Migration, Move sp from DBEAS/bodb_EAS to DBPOL/NAP_UserControl [Redmine: #111865]
		
		Paramter's Explanation:
	*/
SET NOCOUNT ON

	IF EXISTS (SELECT 1 FROM eaOn_User WITH(NOLOCK) WHERE on_userid = @on_userid AND isKickedOut = 1)
		SELECT @isKickedOut = 1
	ELSE
	BEGIN
		SELECT @isKickedOut = 0
		
		UPDATE eaOn_User WITH(UPDLOCK,ROWLOCK)
		SET reload_time = getdate()
		WHERE on_userid = @on_userid
		
		IF @@ROWCOUNT = 0
			SELECT @isKickedOut = 1
	END

GO 
