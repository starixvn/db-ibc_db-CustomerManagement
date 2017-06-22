/****** Object:  Stored Procedure dbo.Acc_CustomerSelOnline    Script Date: 9/20/2011 8:47:06 PM ******/
ALTER PROCEDURE [dbo].[Acc_CustomerSelOnline]
	@custid int
AS
/*
Created: 20090122@nqminh
Task : Select customer online list
DB: DB03.on_user
Original:

Revisions:
	- 20110803@Lukas: Get lastlogged from bodb02.dbo.customer
	- 20110912@Sophia: Add table on_user_agent
	- 20121001@Jamie: Do not get DomainID field 
Param's Explanation:
• @userid: customer id
*/

SET NOCOUNT ON
DECLARE @lastlogged DATETIME, @RoleID INT

SELECT @lastlogged = lastlogged , @RoleID = RoleID
FROM bodb02.dbo.customer WITH(NOLOCK)
WHERE custid = @custid


IF @RoleID = 1 
SELECT on_sessionid, custid, @lastlogged AS reload_time, ServerID, on_userid, IP, iskickedout, subaccid, NetSessionID, Country, MachineIP
FROM on_user WITH (nolock)
WHERE custid = @custid
ELSE 
IF @RoleID BETWEEN 2 AND 4
SELECT on_sessionid, custid, @lastlogged AS reload_time, ServerID, on_userid, IP, iskickedout, subaccid, NetSessionID, Country, MachineIP
FROM on_user_agent WITH (nolock)
WHERE custid = @custid
ORDER BY on_userid

GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelOnline] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelOnline] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelOnline] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelOnline] TO [bodbExtAccNet] AS [dbo]