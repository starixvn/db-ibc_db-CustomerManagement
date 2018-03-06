/*<info serverAlias="DBAGE-bodb_Age" executers="bodbAdminNet" viewers="vnteam" isFunction="0"></info>*/
USE [bodb_AGE]
GO

ALTER PROCEDURE [dbo].[NAP_LimitLoss_MonitorListDetail]
	@ActionID TINYINT = 1
AS
/*
	Created: Elodie
	Date: 20180301
	Task : SMA Loss monitor report in details
	DB: DBAGE/bodb_Age

	Revisions:
		- 20180301@Elodie: SMA Loss monitor report in details [Redmine:#91064]

	Parameter's explaination: 
		@ActionID:	1	Alert on report
					2	Send email notification to recipient
					3	Send lettalk notification to recipient

	Example:  EXEC NAP_LimitLoss_MonitorListDetail @ActionID = 1
	
*/
BEGIN
	SET NOCOUNT ON
	DECLARE @LevelThreshold TINYINT
	CREATE TABLE #GroupList (CustID INT PRIMARY KEY, GroupID SMALLINT, IsGroupHeadline BIT)
	CREATE TABLE #MonitorList (CustID INT PRIMARY KEY, MaxLoss MONEY, TotalBalance MONEY, LevelID TINYINT, YesterdayBalance MONEY, OldLevelID TINYINT, GroupHeadlineID INT)

	SELECT @LevelThreshold = MIN(LevelID) FROM dbo.LimitLoss_ActionConfig WITH (NOLOCK) WHERE ActionID >=@ActionID

	INSERT INTO #GroupList(CustID, GroupID, IsGroupHeadline)
	SELECT custid, ca.groupID, ca.IsGroupHeadLine
	FROM bodb02.dbo.CustAccount ca WITH (NOLOCK)
		INNER JOIN dbo.LimitLoss_HeadlineSetting hs WITH (NOLOCK) ON ca.groupID = hs.GroupHeadlineID

	--Insert SMA setting
	INSERT INTO #MonitorList (CustID, MaxLoss, TotalBalance, LevelID, YesterdayBalance, OldLevelID, GroupHeadlineID)
	SELECT CustID, MaxLoss, TotalBalance, LevelID, YesterdayBalance, OldLevelID, 0
	FROM dbo.LimitLoss_Setting t WITH(NOLOCK) 
	WHERE t.LevelID >= @LevelThreshold
		AND NOT EXISTS (SELECT 1 FROM #GroupList WHERE CustID = t.CustID)       
	
	--Insert Headline setting
	INSERT INTO #MonitorList (CustID, MaxLoss, TotalBalance, LevelID, YesterdayBalance, OldLevelID, GroupHeadlineID)
	SELECT CustID, MaxLoss, TotalBalance, LevelID, YesterdayBalance, OldLevelID, t.GroupHeadlineID
	FROM dbo.LimitLoss_HeadlineSetting t WITH(NOLOCK)	
		INNER JOIN #GroupList l ON t.GroupHeadlineID = l.GroupID AND l.IsGroupHeadline = 1
	WHERE t.LevelID >= @LevelThreshold

	--Result 
	SELECT	c.CustId, c.Username, c.roleid, CASE WHEN t.GroupHeadlineID <> 0 THEN 'RM' ELSE e.currency END AS currency, 
			t.GroupHeadlineID, t.YesterdayBalance, t.TotalBalance, t.MaxLoss, t.LevelID,
			CASE WHEN t.OldLevelID > t.LevelID THEN -1
				 WHEN t.OldLevelID < t.LevelID THEN 1
				 ELSE 0 END AS Movement,
			CASE WHEN t.MaxLoss = 0 THEN 100 
				 WHEN t.TotalBalance >=0 THEN 0
				ELSE (t.TotalBalance/t.MaxLoss*100) END AS PercentageLoss
	FROM #MonitorList t WITH(NOLOCK) 
		INNER JOIN bodb02.dbo.custInfo c WITH (NOLOCK) ON t.CustID = c.custid
		INNER JOIN bodb02.dbo.exchange e WITH (NOLOCK) on c.currency = e.exchangeid
	ORDER BY PercentageLoss DESC, t.TotalBalance, c.username

	SELECT	c.CustId, c.Username, 
			c.roleid, CASE WHEN gl.GroupID <> 0 THEN 'RM' ELSE e.currency END AS currency, 
			gl.GroupID AS GroupHeadlineID, t.YesterdayBalance, t.TotalBalance, t.MaxLoss, t.LevelID,
			CASE WHEN t.OldLevelID > t.LevelID THEN -1
					WHEN t.OldLevelID < t.LevelID THEN 1
					ELSE 0 END AS Movement,
			CASE WHEN t.MaxLoss = 0 THEN 100 
					WHEN t.TotalBalance >=0 THEN 0
				ELSE (t.TotalBalance/t.MaxLoss*100) END AS PercentageLoss
	FROM #GroupList gl 
		INNER JOIN dbo.LimitLoss_HeadlineSetting hs WITH(NOLOCK) ON hs.GroupHeadlineID = gl.GroupID
		INNER JOIN dbo.LimitLoss_Setting t ON gl.CustID = t.CustID 
		INNER JOIN bodb02.dbo.custInfo c WITH (NOLOCK) ON t.CustID = c.custid	
		INNER JOIN bodb02.dbo.exchange e WITH (NOLOCK) on c.currency = e.exchangeid
	WHERE t.MaxLoss IS NOT NULL
		AND hs.LevelID >= @LevelThreshold
END
GO
