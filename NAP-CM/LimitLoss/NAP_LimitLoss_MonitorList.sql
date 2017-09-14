/*<info serverAlias="DBAGE-bodb_Age" executers="bodbAdminNet" viewers="vnteam" isFunction="0"></info>*/
USE [bodb_AGE]
GO

ALTER PROCEDURE [dbo].[NAP_LimitLoss_MonitorList]
AS
/*
	Created: Elodie
	Date: 20140526
	Task : SMA Loss monitor report
	DB: DBAGE/bodb_Age

	Revisions:
		- 20140620@Elodie: Add icon to indicate loss movement [Redmine:#17906]
		- 20160607@Aaron: Get CustId [Redmine: #58855]
	Parameter's explaination: 
	
	Example:  EXEC NAP_LimitLoss_MonitorList
	
*/
SET NOCOUNT ON

SELECT	c.CustId, c.Username, c.roleid, e.currency, t.YesterdayBalance, t.TotalBalance, t.MaxLoss, t.LevelID,
		CASE WHEN t.OldLevelID > t.LevelID THEN -1
			 WHEN t.OldLevelID < t.LevelID THEN 1
			 ELSE 0 END AS Movement,
		CASE WHEN t.MaxLoss = 0 THEN 100 
			 WHEN t.TotalBalance >=0 THEN 0
			 ELSE CAST((t.TotalBalance/t.MaxLoss*100) AS INT) END AS PercentageLoss
	FROM dbo.LimitLoss_Setting t WITH(NOLOCK) 
		INNER JOIN bodb02.dbo.custInfo c WITH (NOLOCK) ON t.CustID = c.custid
		INNER JOIN bodb02.dbo.exchange e WITH (NOLOCK) on c.currency = e.exchangeid
	WHERE t.LevelID > 0
	ORDER BY PercentageLoss DESC, t.TotalBalance, c.username

GO
GRANT EXECUTE ON [dbo].[NAP_LimitLoss_MonitorList] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_LimitLoss_MonitorList] TO [vnteam]
