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
	
	Example:  EXEC NAP_LimitLoss_MonitorGroupHeadline @GroupHeadlineID = 5
	
*/
BEGIN
	SET NOCOUNT ON

	SELECT custid
	INTO #GroupList
	FROM bodb02.dbo.CustAccount WITH (NOLOCK)
	WHERE groupID = @GroupHeadlineID

	SELECT	c.CustId, c.Username, c.roleid, e.currency, t.YesterdayBalance, t.TotalBalance, t.MaxLoss, t.LevelID,
			CASE WHEN ISNULL(t.OldLevelID,0) > t.LevelID THEN -1
				 WHEN ISNULL(t.OldLevelID,0) < t.LevelID THEN 1
				 ELSE 0 END AS Movement,
			CASE WHEN ISNULL(t.MaxLoss,0) = 0 THEN 100 
				 WHEN ISNULL(t.TotalBalance,0) >=0 THEN 0
				 ELSE CAST((t.TotalBalance/t.MaxLoss*100) AS INT) END AS PercentageLoss,
			CASE WHEN t.MaxLoss IS NULL THEN 1
				 ELSE 0 END AS NoSetting
	FROM #GroupList gl
		INNER JOIN bodb02.dbo.custInfo c WITH (NOLOCK) ON gl.CustID = c.custid
		INNER JOIN bodb02.dbo.exchange e WITH (NOLOCK) ON c.currency = e.exchangeid
		LEFT JOIN LimitLoss_Setting t WITH(NOLOCK) ON t.CustID = gl.custid
	ORDER BY NoSetting, PercentageLoss DESC, t.TotalBalance, c.username
END

