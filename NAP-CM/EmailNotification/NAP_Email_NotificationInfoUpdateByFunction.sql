/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_Email_NotificationInfoUpdateByFunction]
(
	@NotificationIDList VARCHAR(MAX)
	, @NotifiedByFunction_Flag TINYINT = 1
	, @IsNotifiedValue TINYINT = 1
	
)
AS
/*
	Created: Helen
	Date: 2017-09-29
	Task: Email Notifications - [Redmine:75557]
	DB: DBCUST/CustDB

	Revisions:
		- 20171012@Elodie: Update email notifications for Loss Limit monitoring function [Redmine:#82892]
	Parameter's explaination: 
		- @NotificationIDList: ID of table EmailNotification
			
		- @NotifiedByFunction_Flag: 
			1: TO Control
			2: Loss monitoring
			+ 1: for the next one
		- @IsNotifiedByFunction:
			+ Update IsNotifiedbyTOContol = 1 for list of valid ID sent email
			+ Update IsNotifiedbyTOContol = 0 for list of valid ID but NOT sent email yet
			+ Update IsNotifiedbyTOContol = 2 for list of NOT valid ID sent email
	
			
*/
BEGIN
	SET NOCOUNT ON
	-- FOR TO Control
	IF @NotifiedByFunction_Flag = 1
	BEGIN
		UPDATE EN	
			SET IsNotifiedbyTOControl = @IsNotifiedValue
		FROM dbo.EmailNotification EN WITH (ROWLOCK,UPDLOCK)
			INNER JOIN dbo.strSplit(@NotificationIDList,',') AC ON EN.ID = AC.val 
		
	END
	-- FOR Loss monitoring
	ELSE IF @NotifiedByFunction_Flag = 2
	BEGIN
		UPDATE EN	
			SET EN.IsNotifiedbyLossMonitoring = @IsNotifiedValue
		FROM dbo.EmailNotification EN WITH (ROWLOCK,UPDLOCK)
			INNER JOIN dbo.strSplit(@NotificationIDList,',') AC ON EN.ID = AC.val 
		
	END
END
GO

GRANT EXECUTE ON [dbo].[NAP_Email_NotificationInfoUpdateByFunction] TO [bodbAdminNet]

GO





