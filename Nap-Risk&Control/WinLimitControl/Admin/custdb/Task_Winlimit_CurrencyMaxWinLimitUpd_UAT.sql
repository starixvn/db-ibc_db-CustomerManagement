ALTER PROCEDURE [dbo].[Task_Winlimit_CurrencyMaxWinLimitUpd] 
(
	@ProductId         INT = NULL,
	@GroupId           INT = NULL,
	@CurrencyId        INT = NULL,
	@SiteId            INT = NULL,
	@LevelId           INT = NULL,
	@CustID INT = NULL,
	@IsCurrencySetting  SMALLINT = -1
)
AS
/*   
	Create: 20161012@Helen
	Task : NAP Risk & Control - Phase 3 [Redmine: 61220]
	DB: DBCUST/CustDB
	
	Revisions:
		
	Param's Explanation:
	
	/* Debug
	
	EXEC Task_Winlimit_CurrencyMaxWinLimitUpd
	
	DECLARE @Fromdate DATE= GETDATE(), @Todate DATE= GETDATE()  
	
	SELECT ROUND(MaxWinLimit_RM * FEX.MYR,2),MaxWinLimit_RM,FEX.MYR
	FROM WinLimit_ProductSettingDetail PSD 
		INNER JOIN Lrf_f_GetExchangeDaily(@Fromdate, @Todate) fEx  ON fEx.ExchangeId = psd.ExchangeID
	WHERE PSD.MaxWinLimit_RM IS NOT NULL and psd.exchangeid = 20
	
	*/
	
*/
BEGIN
	
	 SET NOCOUNT ON;  
     DECLARE @Fromdate DATE= GETDATE(), @Todate DATE= GETDATE()  
     
     IF EXISTS (SELECT 1 FROM Lrf_f_GetExchangeDaily(@Fromdate, @Todate))
     BEGIN
     
		IF @IsCurrencySetting = - 1 -- run daily for both currency & cust setting
		BEGIN
			 UPDATE PSD
				SET MaxWinLimit = CASE WHEN psd.ExchangeID = 20 THEN MaxWinLimit_RM ELSE ROUND(MaxWinLimit_RM / FEX.MYR,2) END
			 FROM WinLimit_ProductSettingDetail_UAT PSD 
				INNER JOIN Lrf_f_GetExchangeDaily(@Fromdate, @Todate) fEx  ON fEx.ExchangeId = psd.ExchangeID
			WHERE PSD.MaxWinLimit_RM IS NOT NULL
				
			UPDATE PSD
				SET MaxWinLimit = CASE WHEN CI.currency = 20 THEN MaxWinLimit_RM ELSE ROUND(MaxWinLimit_RM / FEX.MYR,2) END
			FROM WinLimit_CustGameSetting_UAT PSD 
				INNER JOIN custInfo CI WITH (NOLOCK) ON CI.custid = PSD.CustID
				INNER JOIN Lrf_f_GetExchangeDaily(@Fromdate, @Todate) fEx  ON fEx.ExchangeId = CI.currency
			WHERE PSD.MaxWinLimit_RM IS NOT NULL
		END
		ELSE IF @IsCurrencySetting = 1 -- currency setting
		BEGIN
			UPDATE PSD
				SET MaxWinLimit = CASE WHEN psd.ExchangeID = 20 THEN MaxWinLimit_RM ELSE ROUND(MaxWinLimit_RM / FEX.MYR,2) END
			FROM WinLimit_ProductSettingDetail_UAT PSD 
				INNER JOIN Lrf_f_GetExchangeDaily(@Fromdate, @Todate) fEx  ON fEx.ExchangeId = psd.ExchangeID
			WHERE PSD.MaxWinLimit_RM IS NOT NULL 
					AND PSD.ProductID = @ProductId
					AND PSD.GroupId = @GroupId
					AND PSD.ExchangeID = @CurrencyId
					AND PSD.SiteID = @SiteId
					AND PSD.LevelID = @LevelId
		END
		ELSE IF @IsCurrencySetting = 0 -- Customer setting
		BEGIN
		
			UPDATE CGS 
               SET  MaxWinLimit = CASE WHEN CI.currency = 20 THEN MaxWinLimit_RM ELSE ROUND(CGS.MaxWinLimit_RM / FEX.MYR,2) END  
            FROM dbo.WinLimit_CustGameSetting_UAT CGS WITH(ROWLOCK, UPDLOCK)         
				INNER JOIN custInfo CI WITH (NOLOCK) ON CI.custid = CGS.CustID
				INNER JOIN Lrf_f_GetExchangeDaily(@Fromdate, @Todate) fEx  ON fEx.ExchangeId = CI.currency
             WHERE CGS.CustID = @CustID  
                   AND CGS.ProductID = @ProductID  
                   AND CGS.Groupid = @GroupId  
                   AND CGS.LevelId = @LevelId
		END
			
			
	END
	ELSE 
	BEGIN
		PRINT 'There is no data for this date in ExchangeOanda. Please try again later.'
	END
END



