/*<info serverAlias="DBACC-bodb02" executers="" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Task_BetMonitoring_CustTotalBetUpd_Job]
AS
/*  
	Creator: Elodie
	Date: 20160705
	Task: Update the sum of bet ticket's sportbook - [Redmine:#58401]
	DB: DBACC/bodb02
  
	Revisions:  
		- 20170808@Winnie: Change Data Type of Sporttype [RedmineID: #73545]
		- 20210512@Eden: Migrate bodb_Acc to main server [#152636]
		
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @WinLostDate SMALLDATETIME = DATEADD(dd, -1, GETDATE())
	DECLARE @ModifiedDate SMALLDATETIME = GETDATE()  

	SELECT @WinLostDate =  CONVERT(NVARCHAR(10), @WinLostDate, 120)
	
	CREATE TABLE #tmpCustBetting (CustID INT, SportType SMALLINT, BetCount INT)
	CREATE CLUSTERED INDEX CIX_tmpCustBetting ON #tmpCustBetting(CustID,SportType) 
	
	INSERT INTO #tmpCustBetting (CustID, SportType, BetCount)
	SELECT b.CustID, m.sporttype, SUM(1)
	FROM dbo.bettrans b WITH (NOLOCK)
		INNER JOIN dbo.match m WITH (NOLOCK) ON b.matchid = m.matchid
	WHERE winlostdate = @WinLostDate
		AND b.statusID IN (112,113,111) --WON,LOSE,DRAW
		AND m.sporttype <= 99
	GROUP BY b.CustID, m.sporttype 

	MERGE INTO BetMonitoring_CustTotalBet AS Target  
	USING (SELECT CustID, SportType, BetCount FROM #tmpCustBetting) AS Source (CustID, SportType, BetCount) ON Target.CustID = Source.CustID AND Target.SportType = Source.SportType
	WHEN MATCHED THEN  
	UPDATE SET BetCount += Source.BetCount, ModifiedDate = @ModifiedDate
	WHEN NOT MATCHED BY TARGET THEN  
	INSERT (CustID, SportType, BetCount, ModifiedDate) VALUES (CustID, SportType, BetCount, @ModifiedDate );	
END
GO