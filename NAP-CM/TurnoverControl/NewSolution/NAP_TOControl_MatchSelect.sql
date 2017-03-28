/*<info serverAlias="DBAGE-bodb02" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/

CREATE PROCEDURE [dbo].[NAP_TOControl_MatchSelect]
	@LeagueID INT,
	@FromDate DATETIME = NULL,
	@ToDate DATETIME = NULL
AS
/*
	Created: Don
	Date: 2017-03-27
	Task: Retrieve list of matches
	DB: DBAGE.bodb02

	Revisions:

	Parameter's explaination:
*/
BEGIN
	SET NOCOUNT ON

	SELECT m.matchid, m.eventdate, m.homeid, m.awayid
	FROM dbo.match m WITH (NOLOCK)
	WHERE m.leagueid = 	@LeagueID 
		AND m.eventdate BETWEEN @FromDate AND @ToDate 
		AND m.matchcode NOT LIKE '%hedge%'
		AND eventstatus <> 'completed'
	ORDER BY m.eventdate

END
GO