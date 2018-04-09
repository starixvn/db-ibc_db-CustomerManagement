/*<info serverAlias="DBAGE-bodb_Age" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [bodb_Age]
GO

ALTER PROCEDURE  [dbo].[Acc_CustGroupSel]
	@GroupName	VARCHAR(50) = NULL,
	@Userid		INT			= NULL
AS

/*
	Created by: [Henry]
	Date: 2011-04-01
	Task: Select the list super/master of Acc_CustGroup
	DB: DBAGE/bodb_AGE
	
	Revisions:
		- 20130121@Dan: Move sp from DB053/bodb02 to DBAGE/bodb_AGE
		- 20160620@Winnie: #48948 Hide_special_sites_from_unautorized_users
		- 20160721@Percy: Return NormalGroup and ExtraPTGroup columns [RedmineID: #60883]
		- 20170413@Percy: Change way get to-be-primary group [RedmineID: #74292]
		- 20170926@Percy: Move the table: Acc_GroupExtraPTSetting from DBACC.bodb_ACC to DBAGE.bodb02 [RedmineID: #83600]
*/

BEGIN
	SET NOCOUNT ON 

	DECLARE @today DATETIME
	SELECT  @today = CONVERT(DATE, GETDATE())
	
	IF @GroupName = ''
		SET @GroupName = NULL

	DECLARE @GroupId INT
	
	DECLARE @GroupExtraPT TABLE (GroupName VARCHAR(50))
	DECLARE @GroupExtraPTSetting TABLE (SuperId INT, GroupId INT, GroupName VARCHAR(50), EffectiveDate DATETIME, IsPrimary BIT)

	INSERT INTO @GroupExtraPT (GroupName)
	SELECT GroupName FROM OPENQUERY(DBACC, 'SELECT GroupName FROM bodb_Acc.dbo.Acc_DWLList_ExtraPT WITH(NOLOCK)')

	INSERT INTO @GroupExtraPTSetting (SuperId, GroupId, GroupName, EffectiveDate, IsPrimary)
	SELECT SuperId, GroupId, GroupName, EffectiveDate, CONVERT(BIT, 1) AS IsPrimary
	FROM
	(
		SELECT
			SuperId, GroupId, GroupName, MIN(FromDate) AS EffectiveDate,
			ROW_NUMBER() OVER(PARTITION BY SuperId, GroupId, GroupName ORDER BY MIN(FromDate) DESC) AS RN
		FROM bodb02.dbo.Acc_GroupExtraPTSetting WITH(NOLOCK)
		WHERE CONVERT(DATE, GETDATE()) BETWEEN FromDate AND ToDate
		GROUP BY SuperId, GroupId, GroupName
	) A
	WHERE RN = 1
	
	UNION
	SELECT
		SuperId, GroupId, GroupName, FromDate, CONVERT(BIT, 0)
	FROM bodb02.dbo.Acc_GroupExtraPTSetting WITH(NOLOCK)
	WHERE FromDate > CONVERT(DATE, GETDATE())
	
	SELECT TOP 1 @GroupId = GroupId FROM @GroupExtraPTSetting WHERE IsPrimary = 1

	DELETE @GroupExtraPTSetting WHERE IsPrimary = 0 AND GroupId = @GroupId

	DELETE tmp
	FROM (
		SELECT ROW_NUMBER() OVER(PARTITION BY SuperId, GroupId, GroupName ORDER BY EffectiveDate) AS RN
		FROM @GroupExtraPTSetting WHERE IsPrimary = 0
	) AS tmp
	WHERE RN > 1

	IF @Userid IS NULL
	BEGIN	
		;WITH CTE AS
		(
			SELECT
				c.CustID,
				c.roleid,
				c.GroupName,
				CASE WHEN e.GroupName IS NULL THEN c.GroupName ELSE NULL END AS Normal,
				CASE WHEN e.GroupName IS NULL THEN NULL ELSE
					CASE WHEN s.GroupName IS NULL THEN e.GroupName + ',,0'
						 ELSE s.GroupName + ',' + CONVERT(VARCHAR(10), s.EffectiveDate, 101) + ',' + CONVERT(VARCHAR(1), s.IsPrimary) END
				END AS Extra
			FROM
				dbo.Acc_CustGroup c WITH(NOLOCK)
				LEFT JOIN @GroupExtraPT e ON c.GroupName = e.GroupName
				LEFT JOIN @GroupExtraPTSetting s ON c.CustID = s.SuperId AND c.GroupName = s.GroupName
		)
		SELECT a.CustID, c.username,c.firstname, c.lastname, a.roleid, a.GroupName , c.iplogin, NormalGroup, ExtraPTGroup
		FROM
		(
			SELECT 
				a.CustID, a.roleid, a.GroupName,
				(SELECT STUFF((SELECT ';' + Normal FROM CTE WHERE custid = a.CustID FOR XML PATH('')), 1, 1, '')) AS NormalGroup,
				(SELECT STUFF((SELECT ';' + Extra  FROM CTE WHERE custid = a.CustID FOR XML PATH('')), 1, 1, '')) AS ExtraPTGroup
			FROM CTE a
			WHERE a.GroupName = COALESCE(@GroupName,a.GroupName)
			GROUP BY a.CustID, a.roleid, a.GroupName
		) a
		INNER JOIN bodb02.dbo.customer c WITH(NOLOCK) ON a.CustID = c.CustID
		ORDER BY GroupName, username
	END
	ELSE
	BEGIN
		DECLARE @SearchQuery varchar(1024)
		DECLARE @tmp TABLE (siteid INT,site NVARCHAR(50), SpecialGroup TINYINT )
		DECLARE @tmpUserid VARCHAR(50)
		CREATE TABLE #TempCustGroup(CustID INT,Username VARCHAR(50),Firstname NVARCHAR(50),Lastname NVARCHAR(50),RoleId TINYINT,Groupname VARCHAR(50),iplogin NVARCHAR(20),recommendId INT,site VARCHAR(10))
	
		SELECT @tmpUserid=CAST(@Userid AS VARCHAR(50))
		SELECT @SearchQuery = 'SELECT * 
		FROM OPENQUERY(DBPOLICY, 
		''SELECT siteid , site,SpecialGroup FROM bodb02.dbo.f_GetDeniedSiteByUser( ''''' + @tmpUserid + ''''')'')'

		INSERT INTO  @tmp (siteid , site,SpecialGroup)
		EXECUTE(@SearchQuery)	
	
		INSERT INTO #TempCustGroup(CustID, Username, Firstname, Lastname, RoleId, Groupname, iplogin, recommendId, site)
		SELECT a.CustID, c.username, c.firstname, c.lastname, a.roleid, a.GroupName, c.iplogin, c.recommend, site
		FROM dbo.Acc_CustGroup a WITH (NOLOCK)
			INNER JOIN bodb02.dbo.Customer c WITH (NOLOCK) ON a.CustID = c.CustID
		ORDER BY a.GroupName, c.username	
	
		UPDATE a
		SET a.site = b.site
		FROM #TempCustGroup a
			INNER JOIN bodb02.dbo.Customer b (NOLOCK) ON a.recommendId = b.custid
		WHERE a.RoleId = 1
	
		DELETE FROM #TempCustGroup WHERE site IN (SELECT site FROM @tmp)

		;WITH CTE AS
		(
			SELECT
				c.CustID,
				c.roleid,
				c.GroupName,
				CASE WHEN e.GroupName IS NULL THEN c.GroupName ELSE NULL END AS Normal,
				CASE WHEN e.GroupName IS NULL THEN NULL ELSE
					CASE WHEN s.GroupName IS NULL THEN e.GroupName + ',,0'
						 ELSE s.GroupName + ',' + CONVERT(VARCHAR(10), s.EffectiveDate, 101) + ',' + CONVERT(VARCHAR(1), s.IsPrimary) END
				END AS Extra
			FROM
				#TempCustGroup c
				LEFT JOIN @GroupExtraPT e ON c.GroupName = e.GroupName
				LEFT JOIN @GroupExtraPTSetting s ON c.CustID = s.SuperId AND c.GroupName = s.GroupName
		)
		SELECT a.CustID, c.username,c.firstname, c.lastname, a.roleid, a.GroupName , c.iplogin, NormalGroup, ExtraPTGroup
		FROM
		(
			SELECT 
				a.CustID, a.roleid, a.GroupName,
				(SELECT STUFF((SELECT ';' + Normal FROM CTE WHERE custid = a.CustID FOR XML PATH('')), 1, 1, '')) AS NormalGroup,
				(SELECT STUFF((SELECT ';' + Extra  FROM CTE WHERE custid = a.CustID FOR XML PATH('')), 1, 1, '')) AS ExtraPTGroup
			FROM CTE a
			WHERE a.GroupName = COALESCE(@GroupName,a.GroupName)
			GROUP BY a.CustID, a.roleid, a.GroupName
		) a
			INNER JOIN bodb02.dbo.Customer c WITH(NOLOCK) ON a.CustID = c.CustID
		ORDER BY GroupName, username

		DROP TABLE #TempCustGroup
	END
END
GO