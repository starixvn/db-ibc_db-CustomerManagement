/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_Email_NotificationInfoUpdateByFunction]
(
	@NotificationIDList VARCHAR(MAX)
	, @NotifiedByFunction_Flag TINYINT = 1
	
)
AS
/*
	Created: Helen
	Date: 2017-09-29
	Task: Email Notifications - [Redmine:75557]
	DB: DBCUST/CustDB

	Revisions:
		
	Parameter's explaination: 
		- @NotificationIDList: ID of table EmailNotification
			
		- @NotifiedByFunction_Flag: 
			1: TO Control
			
*/
BEGIN
	SET NOCOUNT ON
	-- FOR TO Control
	IF @NotifiedByFunction_Flag = 1
	BEGIN
		UPDATE EN	
			SET IsNotifiedbyTOControl = 1
		FROM dbo.EmailNotification EN WITH (ROWLOCK,UPDLOCK)
			INNER JOIN dbo.strSplit(@NotificationIDList,',') AC ON EN.ID = AC.val 
		
	END
	
END
GO

GRANT EXECUTE ON [dbo].[NAP_Email_NotificationInfoUpdateByFunction] TO [bodbAdminNet]

GO





