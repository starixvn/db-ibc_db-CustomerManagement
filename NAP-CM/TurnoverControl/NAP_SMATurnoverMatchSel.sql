/*<info serverAlias="DBAGE-bodb02" executers="bodbAdminNet" viewers="vnteam" isFunction="0"></info>*/
USE [bodb02]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[NAP_SMATurnoverMatchSel]
	@LeagueID INT,
	@FromDate DATETIME,
	@ToDate DATETIME
AS
/*
	Created: Elodie
	Date: 20130515
	Task : Retrieve match information by matchid
	DB: DBAGE/bodb02

	Revisions:
		- 20130711@Elodie: show match by league
	
	Parameter's explaination: 
	
	Example: EXEC Acc_SMATurnoverMatchSel @@LeagueID = 4305925, @FromDate = '2013-07-06', @ToDate = '2013-07-11'
	
*/
SET NOCOUNT ON

SELECT matchid, eventdate, homeid, awayid
FROM match m WITH (NOLOCK)	
WHERE leagueid = @LeagueID AND eventdate BETWEEN @FromDate AND @ToDate and eventstatus <> 'completed' and matchcode not like '%hedge%'
order by eventdate

