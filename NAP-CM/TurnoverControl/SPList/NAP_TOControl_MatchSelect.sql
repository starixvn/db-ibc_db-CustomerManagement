/*<info serverAlias="DBAGE-bodb02" executers="bodbAdminNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/
USE bodb02
GO

ALTER PROCEDURE [dbo].[NAP_TOControl_MatchSelect]
	@LeagueID INT = 0,
	@FromDate DATETIME = NULL,
	@ToDate DATETIME = NULL
AS
/*
	Created: Don
	Date: 2017-03-27
	Task: Retrieve list of matches
	DB: DBAGE.bodb02

	Revisions:
		- 20170920@Helen: TO Control Phase 3 - [Redmine: 75557]
	Parameter's explaination:
*/
BEGIN
	SET NOCOUNT ON

	SELECT m.matchid, m.eventdate, m.homeid, m.awayid,m.IsNeutral
	FROM dbo.match m WITH (NOLOCK)
	WHERE (@LeagueID = 0 OR m.leagueid = @LeagueID )
		AND m.eventdate BETWEEN @FromDate AND @ToDate 
		AND m.matchcode NOT LIKE '%hedge%'
	ORDER BY m.eventdate

END
GO
GRANT EXECUTE ON [dbo].[NAP_TOControl_MatchSelect] TO [bodbAdminNet]
GO