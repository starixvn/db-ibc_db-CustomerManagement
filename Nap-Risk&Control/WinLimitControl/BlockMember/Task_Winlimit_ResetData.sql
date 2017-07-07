USE bodb02
GO
ALTER PROCEDURE dbo.Task_Winlimit_ResetData @WinlostDate SMALLDATETIME
AS
/*   
	Create: 20151019@Patrick
	Task : Reset data
	DB: DBTXN/bodb02
	Revisions:
	
		- 20160714@Helen: CWL - Phase 2 [Redmine: 57722]
		- 20161130@Helen: CWL - Phase 3 [Redmine: 61220]
	Param's Explanation:
		
*/
BEGIN
	--get product setting
	CREATE TABLE #BlockedListMember (CustId INT, ProductId TINYINT, BetType SMALLINT)

	INSERT INTO #BlockedListMember(CustId,ProductId , BetType)
	SELECT CustId, ProductId, BetTypeID
	FROM DBCUST.CUSTDB.dbo.WinLimit_CustGameStatus WITH(NOLOCK)
	WHERE IsBlockedPlaceBet = 1 OR IsBlockedTransfer = 1

	DELETE g
	FROM dbo.Winlimit_CreditGame g WITH(ROWLOCK)
		LEFT JOIN #BlockedListMember t ON g.CustId = t.CustId AND g.BetType = t.BetType
	WHERE WinlostDate < @WinlostDate
		AND t.CustId IS NULL
	OPTION (MAXDOP 4)
	
	DELETE g
	FROM dbo.Winlimit_DebitGame g WITH(ROWLOCK)
		LEFT JOIN #BlockedListMember t ON g.CustId = t.CustId AND g.BetType = t.BetType
	WHERE WinlostDate < @WinlostDate
		AND t.CustId IS NULL
	OPTION (MAXDOP 4)

	DROP TABLE #BlockedListMember
END
GO



