/*<info serverAlias="DBCUST-CUSTDB" executers="" viewers="vnteam" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Task_Winlimit_InsertHistoryData @XmlData NVARCHAR(MAX)
AS
/*   
	Create: 20160623@Helen
	Task : Winlimit - Insert history data
	DB: DBCUST/CUSTDB
	Revisions:
		- 20170321@Helen: NAP Risk & Control - Phase 3A [Redmine: 72604]
		- 20170810@Helen: NAP Risk & Control - Phase 4 - Win Loss Limit [Redmine: 72870]
		- 20220615@Tacy: Hot modify Select Into statement to avoid dump [Redmine: #174035]
		- 20230830@Luke: Apply Company Max Payout rules per ticket [Redmine: #193014]
		
	Param's Explanation:
		
*/
BEGIN
	SET NOCOUNT ON

	CREATE TABLE #TempData (
			CustId INT 
			, ProductId TINYINT 
			, GroupID INT 
			, MaxWinLimit MONEY 
			, TotalWinAmt MONEY 
			, WinAmt MONEY  
			, LevelID TINYINT 
			, ActionID TINYINT 
			, ModifiedDate DATETIME  
			, IsNotified BIT  
			, ModifiedBy INT  
			, CreatedBy  INT 
			, WinlostDate DATETIME  
			, MaxWinLimitSetting XML 
			, TotalWinAmt_RM MONEY
			, BettypeIDList VARCHAR(500)
			, TransID BIGINT
	)

	DECLARE @_hdoc INT
	EXEC sp_xml_preparedocument @_hdoc OUTPUT, @XmlData

	INSERT INTO #TempData (CustId, ProductId, GroupID, MaxWinLimit, TotalWinAmt, WinAmt, LevelID, ActionID, ModifiedDate, 
						IsNotified, ModifiedBy, CreatedBy, WinlostDate, MaxWinLimitSetting, TotalWinAmt_RM, BettypeIDList, TransID)
	SELECT 
		CustId
		, ProductId 
		, GroupID
		, MaxWinLimit 
		, TotalWinAmt 
		, WinAmt 
		, LevelID 
		, ActionID 
		, ISNULL(ModifiedDate, GETDATE()) AS ModifiedDate
		, ISNULL(IsNotified, 0) AS IsNotified
		, ModifiedBy 
		, CreatedBy 
		, WinlostDate 
		, MaxWinLimitSetting
		, TotalWinAmt_RM
		, BettypeIDList
		, TransID
	FROM OPENXML(@_hdoc,'/root/r', 2)   
	WITH (CustId INT 'a1'
		, ProductId TINYINT 'a2'
		, GroupID INT 'a3'
		, MaxWinLimit MONEY 'a4'
		, TotalWinAmt MONEY 'a5'
		, WinAmt MONEY  'a6'
		, LevelID TINYINT  'a7'
		, ActionID TINYINT 'a8'
		, ModifiedDate DATETIME  'a9'
		, IsNotified BIT  'a10'
		, ModifiedBy INT  'a11'
		, CreatedBy  INT 'a12'
		, WinlostDate DATETIME  'a13'
		, MaxWinLimitSetting XML 'a14/node()'
		, TotalWinAmt_RM MONEY 'a15'
		, BettypeIDList VARCHAR(500) 'a16'
		, TransID BIGINT 'a17'
	)   
	
	EXEC sp_xml_removedocument @_hdoc  

	-- process for levelid 255: Max payout
	IF EXISTS (SELECT TOP 1 1 FROM #TempData WHERE ActionID >= 200)
	BEGIN

		INSERT INTO dbo.WinLimit_CustGameMonitoring_History( CustId, ProductId,GroupID, MaxWinLimit, TotalWinAmt,WinAmt,LevelID,ActionID,ModifiedDate
			, IsNotified, ModifiedBy, CreatedBy, WinlostDate,MaxWinLimitSetting,TotalWinAmt_RM,BettypeIDList, TransID)

		SELECT CustId, ProductId,GroupID, MaxWinLimit, TotalWinAmt,t.WinAmt,LevelID,ActionID,ModifiedDate
			, IsNotified, ModifiedBy, CreatedBy, WinlostDate,MaxWinLimitSetting,TotalWinAmt_RM, BettypeIDList AS BettypeIDList, TransID
		FROM #TempData t WITH (NOLOCK)
			OUTER APPLY (SELECT TOP 1 h.WinAmt 
						FROM WinLimit_CustGameMonitoring_History h WITH (NOLOCK)
						WHERE h.CustID = t.CustId 
							AND h.ProductID = t.ProductId 
							AND h.GroupID = t.GroupID 
							AND h.TransID = t.TransID
							AND h.ActionID = t.ActionID
						ORDER BY LogID DESC
						) AS temp
							
		WHERE t.ActionID = 255 -- to make sure sending right notification, should filter by 255 rather than actionid >= 200
			AND (temp.WinAmt IS NULL OR temp.WinAmt <> t.WinAmt)

	END
	ELSE
	BEGIN
		INSERT INTO dbo.WinLimit_CustGameMonitoring_History( CustId, ProductId,GroupID, MaxWinLimit, TotalWinAmt,WinAmt,LevelID,ActionID,ModifiedDate
			, IsNotified, ModifiedBy, CreatedBy, WinlostDate,MaxWinLimitSetting,TotalWinAmt_RM,BettypeIDList, TransID)

		SELECT CustId, ProductId,GroupID, MaxWinLimit, TotalWinAmt,WinAmt,LevelID,ActionID,ModifiedDate
			, IsNotified, ModifiedBy, CreatedBy, WinlostDate,MaxWinLimitSetting,TotalWinAmt_RM, BettypeIDList AS BettypeIDList, TransID
		FROM #TempData WITH (NOLOCK)
		WHERE ActionID < 200
	END

	DROP TABLE #TempData
END
GO