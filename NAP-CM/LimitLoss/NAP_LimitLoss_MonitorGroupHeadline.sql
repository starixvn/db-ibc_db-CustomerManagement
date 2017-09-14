/*<info serverAlias="DBAGE-bodb_Age" executers="bodbAdminNet" viewers="vnteam" isFunction="0"></info>*/
USE [bodb_AGE]
GO

ALTER PROCEDURE [dbo].[NAP_LimitLoss_MonitorGroupHeadline]
	@GroupHeadlineID INT
AS
/*
	Created: Elodie
	Date: 20170915
	Task : Group Headline Loss monitor report
	DB: DBAGE/bodb_Age

	Revisions:

	Parameter's explaination: 
	
	Example:  EXEC NAP_LimitLoss_MonitorGroupHeadline @CustID = 12345
	
*/
BEGIN
	SET NOCOUNT ON

	SELECT custid
	INTO #GroupList
	FROM bodb02.dbo.CustAccount WITH (NOLOCK)
	WHERE groupID = @GroupHeadlineID

	CREATE TABLE #LossSetting (CustID)
	SELECT	c.CustId, c.Username, c.roleid, e.currency, t.YesterdayBalance, t.TotalBalance, t.MaxLoss, t.LevelID,
			CASE WHEN t.OldLevelID > t.LevelID THEN -1
				 WHEN t.OldLevelID < t.LevelID THEN 1
				 ELSE 0 END AS Movement,
			CASE WHEN t.MaxLoss = 0 THEN 100 
				 WHEN t.TotalBalance >=0 THEN 0
				 ELSE CAST((t.TotalBalance/t.MaxLoss*100) AS INT) END AS PercentageLoss
	FROM #GroupList
		LEFT JOIN (SELECT * FROM dbo.LimitLoss_Setting t WITH(NOLOCK) 

		
		INNER JOIN bodb02.dbo.custInfo c WITH (NOLOCK) ON t.CustID = c.custid
		INNER JOIN bodb02.dbo.exchange e WITH (NOLOCK) on c.currency = e.exchangeid
	WHERE t.LevelID > 0
	ORDER BY PercentageLoss DESC, t.TotalBalance, c.username
END

