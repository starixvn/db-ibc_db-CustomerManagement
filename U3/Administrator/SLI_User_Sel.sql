/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
USE CustDB
GO

ALTER PROCEDURE [dbo].[SLI_User_Sel]
	@Username	VARCHAR(50) = NULL
	,@GroupId	TINYINT = NULL
AS

/*
	Created: 20190106@Percy
	DB: DBCUST.CustDB
	Task: NAP U3 - Administrator - View users

	Revisions:
		- 20190106@Percy: Initialize SP [RedmineID: #123584]

	Param's Explanation:
		@GroupId
			= NULL	: all groups
			= 0		: User
			= 1		: Administrator
*/

BEGIN
	SET NOCOUNT ON

	SELECT
		CustId			= sc.CustId
		,UserName		= c.username
		,FirstName		= c.firstname
		,LastName		= c.lastname
		,GroupId		= sc.GroupId
		,Creator		= cre.username
		,CreatedDate	= sc.CreatedDate
		,closed			= ci.closed
	FROM NAP_UserControl.dbo.SLI_Users sc WITH (NOLOCK)
		INNER JOIN dbo.custinfo ci WITH (NOLOCK) ON sc.CustId = ci.custid
		INNER JOIN dbo.Customer c WITH (NOLOCK) ON sc.CustId = c.custid
		LEFT JOIN dbo.Customer cre WITH (NOLOCK) ON sc.Creator = cre.custid
	WHERE (@GroupId IS NULL OR sc.GroupId = @GroupId)
		AND (@Username IS NULL OR c.username = @Username)
	ORDER BY c.username
END
GO