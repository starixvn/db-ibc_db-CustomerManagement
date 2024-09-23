/*<info serverAlias="DBCust-CustDB" executers="wsv_nap" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_WinLimit_CustGameMonitoring_HistoryIns] @CustId    INT,
                                                                   @ProductId INT,
                                                                   @GroupId   INT,
                                                                   @ActionId  INT,
                                                                   @UserId    INT
AS
	
/*
Created: Jacob	
Date: 2016-06-30
Task: #38608 - Implement function to control Player's Win Limit on specific Product

DB: DBCust/CustDB

Revisions:
	- 20170321@Jacob: Risk & Control - Phase 3A [#72604]. 
	- 20170515@Helen: NAP Risk & Control - CHANGE REQUEST [Redmine: 75332] 
	- 20170808@Jacob: Risk & Control - Phase 4 [#72870]
	- 20240808@Johnson: Apply Inhouse Replication for CWL [redmine: #209068]
Parameters Explanation:	
EXEC [NAP_WinLimit_CustGameMonitoring_HistoryIns] 
   @CustId = 662531, 
   @ProductId =22,
   @BetTypeId=4001,  
   @ActionId =2,
   @UserId=1
*/
BEGIN
     SET NOCOUNT ON;
     DECLARE @StartRun DATETIME, @EndRun DATETIME, @Duration INT, @LogSPData VARCHAR(300);
     SELECT @StartRun = GETDATE();
     INSERT INTO dbo.WinLimit_CustGameMonitoring_History
     (CustID,
      ProductID,
      GroupId,
      BettypeIDList,
      WinlostDate,
      LevelID,
      MaxWinLimit,
      MaxWinLimitSetting,
      TotalWinAmt,
      TotalWinAmt_RM,
      WinAmt,
      ActionID,
      ModifiedDate,
      IsNotified,
      ModifiedBy,
      CreatedBy,
	  RepUpdateTime
     )
            SELECT TOP 1 CustID,
                         ProductID,
                         GroupId,
                         BettypeIDList,
                         WinlostDate,
                         LevelID,
                         MaxWinLimit,
                         MaxWinLimitSetting,
                         TotalWinAmt,
                         TotalWinAmt_RM,
                         WinAmt,
                         @ActionId,
                         GETDATE(),
                         1,
                         @UserId,
                         @UserId,
						 SYSDATETIME()
            FROM dbo.WinLimit_CustGameMonitoring WITH (NOLOCK)
            WHERE CustId = @CustId
                  AND ProductId = @ProductId
                  AND GroupId = @GroupId
            ORDER BY ModifiedDate DESC;
END
GO