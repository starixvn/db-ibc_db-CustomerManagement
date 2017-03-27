/*<info serverAlias="DBAGE-bodb02" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[NAP_TOControl_SportTypeSelect]
	@Mode TINYINT = 0,
	@FromDate DATETIME = NULL,
	@ToDate DATETIME = NULL
AS
/*
	Created: Don
	Date: 2017-03-27
	Task: Retrieve list of sports
	DB: DBAGE.bodb02

	Revisions:

	Parameter's explaination: @Mode  = 0: Sport which have a unsettled match
									 = 1: All sports
									 = 2: Get sport in turnover usage list
									 = 3: Get sport in turnover monitor list
*/
BEGIN
	SET NOCOUNT ON

	SELECT DISTINCT s.sporttype, s.sportname 
	FROM dbo.sports s WITH(NOLOCK) 
		INNER JOIN dbo.match m WITH (NOLOCK) ON s.sporttype = m.sporttype
	WHERE 1 = CASE  WHEN @Mode = 0 AND m.eventstatus <> 'completed' AND m.matchcode NOT LIKE '%hedge%' THEN 1
					WHEN @Mode = 1 THEN 1
					WHEN @Mode = 2 AND @FromDate IS NOT NULL AND @ToDate IS NOT NULL AND m.eventdate BETWEEN @FromDate AND @ToDate THEN 1
					WHEN @Mode = 3 AND m.eventstatus = 'running' AND m.matchcode NOT LIKE '%hedge%' AND m.eventdate = CONVERT(DATE, GETDATE()) THEN 1
					ELSE 0 END
		AND s.sporttype < 99								
	ORDER BY s.sporttype

END
GO