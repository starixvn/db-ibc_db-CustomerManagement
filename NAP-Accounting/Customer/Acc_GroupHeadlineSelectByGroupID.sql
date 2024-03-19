/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet,wsv_nap" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_GroupHeadlineSelectByGroupID]
(
	@GroupID INT
	
)
AS
/*
	Created: Helen
	Date: 2017-09-29
	Task: Get Group Headline - [Redmine:75557]
	DB: DBCUST/CustDB

	Revisions:
		
	
*/
BEGIN
	SET NOCOUNT ON
	
	SELECT CI.username
	FROM CustGroupHeadline GH WITH (NOLOCK)
		INNER JOIN custInfo CI WITH (NOLOCK) ON GH.CustID = CI.custid
	WHERE GH.GroupID = @GroupID	
	
END
GO

GRANT EXECUTE ON [dbo].[Acc_GroupHeadlineSelectByGroupID] TO [bodbAdminNet,wsv_nap]

GO





