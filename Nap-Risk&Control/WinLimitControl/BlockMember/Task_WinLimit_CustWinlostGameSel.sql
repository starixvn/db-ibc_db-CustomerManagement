/*<info serverAlias="DBTXN-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0" ></info>*/
ALTER PROCEDURE [dbo].[Task_Winlimit_CustWinlostGameSel]
AS
/*   
	Create: 20220721@Johnson
	Task : Get data winlimit game - [Redmine:175278]
	DB: DBTXN/bodb02 -- deploy at sitedb & DBTXN
	
	Revisions:
		- 20220721@Johnson: Initial sp [Redmine: 175278]
		
	Param's Explanation:
	
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @WinlostDate SMALLDATETIME
	
	SELECT @WinlostDate = CAST(GETDATE() AS DATE)
	
	SELECT CustId, WinlostDate, BetType, SUM(Winlost) Winlost
	FROM (
		SELECT CustId, WinlostDate, BetType, Winlost
		FROM dbo.Winlimit_CreditGame c WITH (NOLOCK)
		WHERE WinlostDate = @WinlostDate

		UNION ALL
		
		SELECT CustId, WinlostDate, BetType, - Winlost
		FROM dbo.Winlimit_DebitGame c WITH (NOLOCK)
		WHERE WinlostDate = @WinlostDate
			
	)t
	GROUP BY CustId, WinlostDate, BetType
END	