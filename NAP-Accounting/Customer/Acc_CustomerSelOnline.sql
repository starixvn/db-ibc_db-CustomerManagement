/*<info serverAlias="DBONUSER-on_user" executers="wsv_nap,wsv_alp,wsv_alpv,wsv_xnap" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE [dbo].[Acc_CustomerSelOnline]
	@custid INT,
	@availableTime INT = 300
AS
/*
Created: 20090122@nqminh
Task : Select customer online list
DB: DBONUSER.on_user
Original:

Revisions:
	- 20110803@Lukas: Get lastlogged from bodb02.dbo.customer
	- 20110912@Sophia: Add table on_user_agent
	- 20121001@Jamie: Do not get DomainID field 
	- 20180504@Louis: Update Online List [RedmineID: #94480]
	- 20190425@Johnson: add headline for cn88 [Redmine: #105338]
	- 20251108@Elodie: Increase @availableTime from 70 to 300 seconds
Param's Explanation:
• @userid: customer id
• @availableTime: time-diff between reload time and current time by seconds
*/

SET NOCOUNT ON
DECLARE @lastlogged DATETIME, @RoleID INT

DECLARE @currentTime DATETIME
SET @currentTime = getdate()

SELECT @lastlogged = lastlogged , @RoleID = RoleID
FROM bodb02.dbo.customer WITH(NOLOCK)
WHERE custid = @custid

IF @RoleID = 1 
	SELECT on_sessionid, custid, ServerID, on_userid, IP, iskickedout, subaccid, NetSessionID, Country, MachineIP, @lastlogged as reload_time
	FROM on_user WITH (nolock)
	WHERE custid = @custid AND reload_time >= DATEADD(SECOND, -@availableTime, @currentTime) AND iskickedout = 0 AND ServerID <> 0
ELSE 
	IF @RoleID BETWEEN 2 AND 4 OR @roleid = 0
	SELECT on_sessionid, custid, ServerID, on_userid, IP, iskickedout, subaccid, NetSessionID, Country, MachineIP, LoginTime as reload_time
	FROM on_user_agent WITH (nolock)
	WHERE custid = @custid AND reload_time >= DATEADD(SECOND, -@availableTime, @currentTime) AND iskickedout = 0 AND ServerID <> 0
	ORDER BY on_userid ASC
GO	