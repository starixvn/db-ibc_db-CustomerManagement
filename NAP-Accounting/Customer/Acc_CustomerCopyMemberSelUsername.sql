ALTER PROCEDURE [dbo].[Acc_CustomerCopyMemberSelUsername]
	@Username VARCHAR(50)
AS

/*
Created: 
Task : Get move bet day, balanceup day
DB: DBCust.CustDB
Original:Accounting site

Revisions:	
Param's Explanation:
	@userid: userid want to get all info related
*/		
BEGIN
    SET NOCOUNT ON
    
    DECLARE @roleid INT, @memberid INT, @agentid INT, @supperid INT, @masterid INT,
    @memberUsername VARCHAR(50), @agentUsername VARCHAR(50), @supperUsername VARCHAR(50), @masterUsername VARCHAR(50)
        
    SELECT @roleid = roleID
	FROM custinfo WITH(NOLOCK)
	WHERE username=@Username
	
	IF @roleid IS NULL
	BEGIN
	SELECT NULL AS CustId,NULL AS UserName, 1 AS RoleId
	UNION
	SELECT NULL AS CustId,NULL AS UserName, 2 AS RoleId
	UNION
	SELECT NULL AS CustId,NULL AS UserName, 3 AS RoleId
	UNION
	SELECT NULL AS CustId,NULL AS UserName, 4 AS RoleId
	RETURN
	END
    
	SELECT TOP 1 @memberid=mem.custid,@agentid=age.custid,@supperid=sup.custid,@masterid=mas.custid,
	@memberUsername=mem.username,@agentUsername=age.username,@supperUsername=sup.username,@masterUsername=mas.username
	FROM custinfo mem (NOLOCK)
	INNER JOIN custinfo age (NOLOCK) ON mem.recommend=age.custid
	INNER JOIN custinfo mas (NOLOCK) ON mem.mrecommend=mas.custid
	INNER JOIN custinfo sup (NOLOCK) ON mem.srecommend=sup.custid
	WHERE CASE WHEN @roleid=1 THEN mem.username
			   WHEN @roleid=2 THEN age.username
			   WHEN @roleid=3 THEN mas.username
			   WHEN @roleid=4 THEN sup.username END =@Username
	SELECT @memberid AS CustId,@memberUsername AS UserName, 1 AS RoleId
	UNION
	SELECT @agentid AS CustId,@agentUsername AS UserName, 2 AS RoleId
	UNION
	SELECT @masterid AS CustId,@masterUsername AS UserName, 3 AS RoleId
	UNION
	SELECT @supperid AS CustId,@supperUsername AS UserName, 4 AS RoleId
	   
    END

GO
GRANT EXECUTE ON [dbo].[Acc_CustomerCopyMemberSelUsername] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerCopyMemberSelUsername] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerCopyMemberSelUsername] TO [bodbExtAccNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerCopyMemberSelUsername] TO [vnteam] AS [dbo]
GO