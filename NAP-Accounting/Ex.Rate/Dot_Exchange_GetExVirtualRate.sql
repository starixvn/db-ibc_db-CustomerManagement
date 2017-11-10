/*<info serverAlias="DBCust-CustDB" executers="Dot_Member" viewers="vnteam" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[Dot_Exchange_GetExVirtualRate]
/*
	Created: 20171110@Harper
	Description: Get conversion rate of real currencies to Exchange virtual rate [RedmineID: #82408]
	DB: DBCust.CustDB

	Param's Explanation:
	
	EXEC Dot_Exchange_GetExVirtualRate
*/
AS 
BEGIN

	SELECT e.exchangeid, e.currency, e.Code, e.ExVirtualRate
	FROM dbo.exchange e WITH (NOLOCK)
	WHERE ExVirtualRate IS NOT NULL

END
GO