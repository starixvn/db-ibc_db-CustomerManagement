/*<info serverAlias="DBGLOB-GLOBCUSTDB" executers="wsv_nap" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerSelExistingUsernames]
    @Usernames VARCHAR(MAX)
AS
/*
Created: Kan
Task : Get existing username list from a string separated by (,)
DB: DBCust.CustDB
Original: Accounting site

Revisions:
    - 20180530@Kan: Get existing username list from a string separated by (,) [RedmineId: #84739] 
	- 20181002@Dominic: Check existing username/username2 in archived DB  [Redmine:99882]
	- 20190422@Elodie: Offer unique nickname for CN88 [Redmine:112287]
	- 20220614@Eden: DBCUST - modify sp syntax to adapt with the SQL Server upgrade to 2019 [Redmine: #171831]
	- 20240108@Eden: DCS Sportsbook Credit[redmine: #193083]
	- 20240704@Helen: Revise code for scaleout dbcust - [Redmine:199915]

Param's Explanation:
    @Usernames: username string want to check
*/		
BEGIN
    SET NOCOUNT ON

    CREATE TABLE #TempUsername (Username VARCHAR(30))

    INSERT INTO #TempUsername(Username)
    SELECT DISTINCT LTRIM(RTRIM(value)) FROM STRING_SPLIT(@Usernames,',') WHERE value <> ''

    SELECT t.Username,
		CASE 
			WHEN c.username IS NULL 
			AND c2.username2 IS NULL
			AND cb.username IS NULL
			AND cb2.username2 IS NULL THEN 0
		ELSE 1 END AS Existing
	FROM #TempUsername t
		LEFT JOIN dbo.CustInfoMini c WITH (NOLOCK) ON c.username = t.Username
		LEFT JOIN dbo.CustInfoMini c2 WITH (NOLOCK) ON c2.username2 = t.Username
		LEFT JOIN dbo.CustSubMini cb WITH (NOLOCK) ON cb.username = t.Username
		LEFT JOIN dbo.CustSubMini cb2 WITH (NOLOCK) ON cb2.username2 = t.Username
END
GO
