/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_Email_NotificationInfoInsert]
(
	@ActionID INT
	 , @NotificationInfo VARCHAR(MAX) = ''
	 , @CreateDate DATETIME
)
AS
/*
	Created: Helen
	Date: 2017-09-29
	Task: Email Notifications - [Redmine:75557]
	DB: DBCUST/CustDB

	Revisions:
		
	Parameter's explaination: 
*/
BEGIN
	SET NOCOUNT ON
	
	INSERT INTO dbo.EmailNotification (NotificationInfo, CreatedDate, ActionID)
	VALUES (@NotificationInfo,@CreateDate,@ActionID)
	
END

GO

GRANT EXECUTE ON [dbo].[NAP_Email_NotificationInfoInsert] TO [bodbAdminNet]

GO





