/*<info serverAlias="DBAGE-bodb02" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[NAP_TOControl_LeagueSelect]
	@SportID INT = 1,
	@FromDate DATETIME = NULL,
	@ToDate DATETIME = NULL,
	@Mode TINYINT = 0
AS
/*
	Created: Don
	Date: 2017-03-27
	Task: Retrieve list of leagues
	DB: DBAGE.bodb02

	Revisions:

	Parameter's explaination:
*/
BEGIN
	SET NOCOUNT ON

	SELECT DISTINCT l.leagueid, l.leaguename 
	FROM dbo.League l WITH(NOLOCK) 
		INNER JOIN dbo.match m WITH(NOLOCK) ON m.leagueid = l.leagueid
	WHERE l.sporttype = @SportID		
		AND l.IsActive = 1
		AND 1 = CASE WHEN @Mode = 0 AND m.eventstatus <> 'completed' AND m.matchcode NOT LIKE '%hedge%' THEN 1
					 WHEN @Mode = 1 THEN 1
					 WHEN @Mode = 2 AND @FromDate IS NOT NULL AND @ToDate IS NOT NULL AND m.eventdate BETWEEN @FromDate AND @ToDate THEN 1
					 WHEN @Mode = 3 AND m.eventstatus = 'running' AND m.matchcode NOT LIKE '%hedge%' AND m.eventdate = CONVERT(DATE, GETDATE()) THEN 1
					 ELSE 0 END	
	ORDER BY l.leaguename

END
GO