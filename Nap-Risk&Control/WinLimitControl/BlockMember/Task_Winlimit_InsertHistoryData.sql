/*<info serverAlias="DBCUST-CUSTDB" executers="" viewers="vnteam" isFunction="0"></info>*/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE dbo.Task_Winlimit_InsertHistoryData @XmlData NVARCHAR(MAX)
AS
/*   
	Create: 20160623@Helen
	Task : Winlimit - Insert history data
	DB: DBCUST/CUSTDB
	Revisions:
		- 20170321@Helen: NAP Risk & Control - Phase 3A [Redmine: 72604]
		
	Param's Explanation:
		
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @_hdoc INT
	EXEC sp_xml_preparedocument @_hdoc OUTPUT, @XmlData

	SELECT 
		CustId
		, ProductId 
		, GroupID
		, MaxWinLimit 
		, TotalWinAmt 
		, WinAmt 
		, LevelID 
		, ActionID 
		, ModifiedDate 
		, IsNotified 
		, ModifiedBy 
		, CreatedBy 
		, WinlostDate 
		, MaxWinLimitSetting
		, TotalWinAmt_RM
	INTO #TempData   
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
	)   
	
	EXEC sp_xml_removedocument @_hdoc  

	INSERT INTO WinLimit_CustGameMonitoring_History( CustId, ProductId,GroupID, MaxWinLimit, TotalWinAmt,WinAmt,LevelID,ActionID,ModifiedDate
		, IsNotified, ModifiedBy, CreatedBy, WinlostDate,MaxWinLimitSetting,TotalWinAmt_RM,BettypeID)

	SELECT CustId, ProductId,GroupID, MaxWinLimit, TotalWinAmt,WinAmt,LevelID,ActionID,ModifiedDate
		, IsNotified, ModifiedBy, CreatedBy, WinlostDate,MaxWinLimitSetting,TotalWinAmt_RM, GroupID AS BettypeID

	FROM #TempData
	
	DROP TABLE #TempData
END
GO

