USE [CustDB];
GO
IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[dbo].[NAP_WinLimit_HistorySel]')
          AND type IN(N'P', N'PC')
)
    DROP PROCEDURE [dbo].[NAP_WinLimit_HistorySel];
GO
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE [dbo].[NAP_WinLimit_HistorySel] @ProductId INT,
                                                 @CustId    INT
AS

/*
Created: Franklin	
Date: 2016-06-22
Task: #57722 - Implement Game Win Limit Control phase2

DB: DBCUST/CustDB

Revisions:
20160923@Jacob: Risk & Control - Phase 3 [#61220].
20170313@Jacob: Risk & Control - Phase 3A [#72604].

Parameters Explanation:	
   @ProductId: Product ID
   @CustId: Cust ID
Example:
EXEC [NAP_WinLimit_HistorySel] @ProductId = 4, @CustId = 1368173
*/


     SET NOCOUNT ON;
     BEGIN -- Currency
         DECLARE @CurrencyCode VARCHAR(20);
         SELECT @CurrencyCode = e.Currency
         FROM dbo.Customer c WITH (NOLOCK)
              INNER JOIN dbo.exchange e WITH (NOLOCK) ON c.Currency = e.ExchangeId
         WHERE c.CustId = @CustId;
     END;
     BEGIN -- temp table data
         CREATE TABLE #WinLimitHistory
         (GroupId            INT,
          ReachedLimitLevel  SMALLINT,
          TotalWinAmount     MONEY,
          TotalWinAmountRM   MONEY,
          MaxWinLimitSetting XML,
          ActionName         NVARCHAR(50),
          ModifiedDate       DATETIME,
          ModifiedBy         INT,
          CreatedBy          INT
         );
         INSERT INTO #WinLimitHistory
         (GroupId,
          ReachedLimitLevel,
          TotalWinAmount,
          TotalWinAmountRM,
          MaxWinLimitSetting,
          ActionName,
          ModifiedDate,
          ModifiedBy,
          CreatedBy
         )
                SELECT h.GroupId,
                       h.LevelID,
                       h.TotalWinAmt,
                       h.TotalWinAmt_RM,
                       h.MaxWinLimitSetting,
                       a.ActionName,
                       h.ModifiedDate,
                       h.ModifiedBy,
                       h.CreatedBy
                FROM dbo.WinLimit_CustGameMonitoring_History h WITH (NOLOCK)
                     INNER JOIN dbo.Winlimit_ActionSetting a WITH (NOLOCK) ON a.ActionID = h.ActionID
                WHERE h.ProductID = @ProductId
                      AND h.CustID = @CustId;
     END;
     BEGIN -- Query data
         SELECT h.GroupId,
                h.ModifiedDate,
                h.MaxWinLimitSetting,
                h.TotalWinAmount,
                @CurrencyCode Currency,
                h.TotalWinAmountRM,
                h.ReachedLimitLevel,
                h.ActionName,
                CASE
                    WHEN h.ModifiedBy IS NULL
                    THEN 'System'
                    ELSE
         (
             SELECT c.username
             FROM dbo.custInfo c WITH (NOLOCK)
             WHERE c.custid = h.ModifiedBy
         )
                END AS ProceededBy
         FROM #WinLimitHistory h
         ORDER BY h.ModifiedDate DESC;
     END;
     DROP TABLE #WinLimitHistory;
GO
GRANT EXECUTE ON [dbo].[NAP_WinLimit_HistorySel] TO [bodbAdminNet];
GO
GRANT VIEW DEFINITION ON [dbo].[NAP_WinLimit_HistorySel] TO [vnteam];
GO