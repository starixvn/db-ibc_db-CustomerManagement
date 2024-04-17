ALTER PROCEDURE  [dbo].[Agw_CheckExistedUserName]
	@custid int,
	@username nvarchar(30)=null,
	@subfix nvarchar(3) output,
	@isExisted bit output
AS
/*
DBCUST.CustDB
Creator: QuiNV
Date: 08/01/2009
Task: Check a member username is existed or not, if it is existed, output max subfix username

Revisions:
	- 20150612@Kathy: Move sp from DBAGE.bodb02 to DBCUST.CustDB [Redmine:#36216]

*/
SET NOCOUNT ON

DECLARE @agentUserName nvarchar(30)

if exists (SELECT 1 FROM customer with(nolock) WHERE recommend=@custid and roleid=1 and username=@username)
BEGIN
SELECT @isExisted=1
END
else
SELECT @isExisted=0

SELECT @agentUserName = username
FROM customer with (nolock)
WHERE custid=@custid and roleid=2

SELECT @subfix = isnull(right(max(username),3), '000')  
FROM customer with (nolock)  
WHERE recommend = @custid and roleid = 1  
 and charindex(@agentUserName, username) = 1  
 and len(username) = len(@agentUserName) + 3

GO
GRANT EXECUTE ON [dbo].[Agw_CheckExistedUserName] TO [wsv_alp] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Agw_CheckExistedUserName] TO [wsv_alpv] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Agw_CheckExistedUserName] TO [vnteam] AS [dbo]