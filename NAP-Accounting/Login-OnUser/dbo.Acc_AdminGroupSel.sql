 ALTER PROCEDURE [dbo].[Acc_AdminGroupSel]
	@username	VARCHAR(30)='',
	@groupID	INT =0 OUTPUT,
	@groupName	VARCHAR(30) = '' OUTPUT
 AS
	/*
		Created: Johnson
		Date: 2014-01-06
		Task: get group info of user for checking on NAP U3 site [Redmine #28516]
		DB: DBPOLICY/bodb02
		
		Revisions:
		
		Parameter's Explanation:
	*/
 BEGIN
	SET NOCOUNT ON
	
	SELECT @groupID = gp.GroupID,
			@groupName = gp.GroupName
	FROM customer c WITH(NOLOCK)
		INNER JOIN AccCustomer_1 ac WITH(NOLOCK) ON c.custid = ac.custid
		INNER JOIN Acc_groupinfo_1 gp WITH(NOLOCK) ON ac.GroupID = gp.GroupID
	WHERE c.username = @username
	
 END
 GO
 GRANT EXECUTE ON [dbo].[Acc_AdminGroupSel] TO [bodbAdminNet]