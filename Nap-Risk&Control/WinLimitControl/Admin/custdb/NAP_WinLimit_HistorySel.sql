/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet,wsv_nap" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_WinLimit_HistorySel] @ProductId INT,
                                                 @CustId    INT
AS

/*
Created: Franklin	
Date: 2016-06-22
Task: #57722 - Implement Game Win Limit Control phase2

DB: DBCUST/CustDB

Revisions:
	- 20160923@Jacob: Risk & Control - Phase 3 [#61220].
	- 20170313@Jacob: Risk & Control - Phase 3A [#72604].
	- 20210423@Helen: CWL - Support to add 2 columns IsNotified and LogID into CWL History Monitoring Page - [Redmine:153291]
	- 20230829@Luke: Apply Company Max Payout rules per ticket [Redmine: #193014]

	Parameters Explanation:	
	   @ProductId: Product ID
	   @CustId: Cust ID
	Example:
	EXEC [NAP_WinLimit_HistorySel] @ProductId = 4, @CustId = 1368173
*/
BEGIN
	 
	 SET NOCOUNT ON;
	 DECLARE @CurrencyCode VARCHAR(20);
     SELECT @CurrencyCode = e.Currency
     FROM dbo.Customer c WITH (NOLOCK)
          INNER JOIN dbo.exchange e WITH (NOLOCK) ON c.Currency = e.ExchangeId
     WHERE c.CustId = @CustId;
         
	SELECT h.GroupId,
            h.ModifiedDate,
            h.MaxWinLimitSetting,
            h.TotalWinAmt AS TotalWinAmount,
            @CurrencyCode Currency,
            h.TotalWinAmt_RM AS TotalWinAmountRM,
            h.LevelID AS ReachedLimitLevel,
            a.ActionName,
            CASE
                WHEN h.ModifiedBy IS NULL THEN 'System'
                ELSE tmp.ProceededBy
			END AS ProceededBy
            ,h.logID
            ,h.IsNotified
           
    FROM dbo.WinLimit_CustGameMonitoring_History h WITH (NOLOCK)
         INNER JOIN dbo.Winlimit_ActionSetting a WITH (NOLOCK) ON a.ActionID = h.ActionID
         OUTER APPLY (SELECT TOP 1 c.username AS ProceededBy
					  FROM dbo.custInfo c WITH (NOLOCK)
					  WHERE c.custid = h.ModifiedBy
				 ) AS tmp
    WHERE h.ProductID = @ProductId
          AND h.CustID = @CustId
		  AND h.ActionID < 200		--Exclude max payout setting (ActionID = 255)
     ORDER BY h.ModifiedDate DESC
END     
GO