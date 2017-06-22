ALTER PROCEDURE [dbo].[Acc_MatchLogSel]
	@matchcode VARCHAR(50) ,
	@FromDate DATETIME,
	@ToDate DATETIME
AS
/*
Created: Daniel
Date: 2009-12-25
Task : View match Log for settlement.	
DB: DBLog.bodb_CustomerLog
Original:

Revisions: 
*/

SET NOCOUNT ON

DECLARE @match table (matchid INT)

INSERT INTO @match
SELECT matchid FROM bodb02.dbo.match WITH(NOLOCK) WHERE matchcode = @matchcode

SELECT 
	logid,
	logdate,
	custid,
	username,
	m.matchid,
	ActionNameEN,
    finalhomescore,
    finalawayscore,  
    hthomescore,
    htawayscore,
    GoalRecord,
    betstatus,
    Remark,
	IP
FROM Userlog_Settle l WITH(NOLOCK)
	INNER JOIN @match m ON l.matchid = m.matchid
	LEFT JOIN LogAction la WITH (NOLOCK) ON l.ActionID = la.ActionID
	LEFT JOIN bodb02.dbo.CustInfo o WITH(NOLOCK) ON o.custid = l.userid
WHERE logdate BETWEEN @FromDate AND @ToDate 
ORDER BY logdate DESC


GO
GRANT EXECUTE ON [dbo].[Acc_MatchLogSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_MatchLogSel] TO [vnteam]
