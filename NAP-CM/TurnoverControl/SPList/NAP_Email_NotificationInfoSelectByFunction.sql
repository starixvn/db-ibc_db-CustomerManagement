/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_Email_NotificationInfoSelectByFunction_xtest]
(
	@fromdate DATETIME 
	, @todate DATETIME 
	, @ActionIDs VARCHAR(300) = '1000'
	, @NotifiedByFunction_Flag TINYINT = 1
	
)
AS
/*
	Created: Helen
	Date: 2017-09-29
	Task: Email Notifications
	DB: DBCUST.CustDB

	Revisions:
		
	Parameter's explaination: 
		- @NotifiedByFunction_Flag
			1: TO Control
			2: Loss monitoring
			+ 1: for the next one
		- @ActionIDs
			- Change Group Headline:1003
			- Add Group Headline: 1000
			- Remove Group Headline: 1002
			- New direct customers: 600,601,602
*/
BEGIN
	SET NOCOUNT ON
	
	-- Process time value to get data properly
	SET @todate = DATEADD(D,1,@todate)
	SET @todate = CONVERT(VARCHAR(10),@todate,101)
	SET @fromdate = CONVERT(VARCHAR(10),@fromdate,101)
	
	-- FOR TO Control
	IF @NotifiedByFunction_Flag = 1
	BEGIN
		SELECT EN.NotificationInfo,EN.CreatedDate,EN.ActionID
		FROM dbo.EmailNotification EN WITH (NOLOCK)
			INNER JOIN dbo.strSplit(@ActionIDs,',') AC ON EN.ActionID =AC.val 
		WHERE EN.IsNotifiedbyTOControl = 0 AND EN.CreatedDate >= @fromdate AND CreatedDate < @todate
		
	END
	
END
GO

GRANT EXECUTE ON [dbo].[NAP_Email_NotificationInfoSelectByFunction_xtest] TO [bodbAdminNet]

GO





