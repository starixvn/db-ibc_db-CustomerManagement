/*<info serverAlias="DBCust-CustDB" selecters="bodbAdminNet,wsv_nap,wsv_alp,wsv_xnap,wsv_alpv" viewers="" isFunction="1"></info>*/
ALTER FUNCTION [dbo].[f_CustSetting_SportUMByCust](@CustID INT)
RETURNS TABLE
AS
/*
Created: 20200629@Eden
Task :  get UM config data by CustID
DB: DBCUST.CustDB
Revisions:	
	- 20200629@Eden: Minimize UM Time - Lock Update Customer setting [Redmine: #136464]
	- 20201005@Eden: Minimize UM Time Phase 2 [Redmine: #142115]
Param's Explanation:
Examples : 
	SELECT * FROM [dbo].[f_CustSetting_SportUMByCust](1)
*/

RETURN
	SELECT c.ProductID,
			c.SportType,
			c.BetType,
			c.IsLive,
			c.SettingType,
			DATEADD(HOUR, 12, c.BeginTime) AS BeginTime,
			DATEADD(HOUR, 12, c.EndTime) AS EndTime,
			c.Time_Stamp,
			c.FunctionType,
			ISNULL(s.siteid,ags.siteid) AS SiteID,
			cu.currency,
			c.LockAddingNew
	FROM customer cu WITH(NOLOCK)
		INNER JOIN customer su WITH(NOLOCK) ON cu.srecommend = su.custid
		LEFT JOIN customer ag WITH(NOLOCK) ON cu.recommend = ag.custid
		LEFT JOIN site s WITH(NOLOCK) ON s.site = cu.site
		LEFT JOIN site ags WITH(NOLOCK) ON ag.site = ags.site
		INNER JOIN [dbo].UMConfig c WITH(NOLOCK) ON c.SuperID IN (su.custid,0)
	WHERE CONVERT(SMALLDATETIME,GETDATE()) BETWEEN c.BeginTime AND c.EndTime
		AND c.SiteID IN (ISNULL(s.siteid,ags.siteid),0)
		AND c.Currency IN (cu.currency,0)
		AND cu.custid = @CustID
GO