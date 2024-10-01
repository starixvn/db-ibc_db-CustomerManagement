/*<info serverAlias="DBCust-CustDB" executers="" viewers="" isFunction="0" isNested="0"></info>*/
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
		- 20170515@Helen: NAP Risk & Control - CHANGE REQUEST [Redmine: 75332]
		- 20240905@Elodie: New currency BTS [Redmine: 209780]
		- 20240808@Johnson: Apply Inhouse Replication for CWL [redmine: #209068]
		- 20240926@Johnson: Enhance sp [redmine: #209068]
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
     
    
	IF @IsCurrencySetting = - 1 -- run daily for both currency & cust setting
	BEGIN
		CREATE TABLE #tmpProductSettingDetail(
			[ProductID] [tinyint] NOT NULL,
			[GroupID] [smallint] NOT NULL,
			[ExchangeID] [int] NOT NULL,
			[SiteID] [int] NOT NULL,
			[LevelID] [tinyint] NOT NULL,
			[MaxWinLimit] [money] NOT NULL					
			PRIMARY KEY CLUSTERED 
			([ProductID] ASC,[GroupID] ASC,[ExchangeID] ASC,[SiteID] ASC,[LevelID] ASC)
		)
		
		DECLARE @tmpProductSetting TABLE (
			[ProductID] [tinyint] NOT NULL,
			[GroupID] [smallint] NOT NULL,
			[ExchangeID] [int] NOT NULL,
			[SiteID] [int] NOT NULL,
			[LevelID] [tinyint] NOT NULL,
			[MaxWinLimit] [money] NOT NULL		
			PRIMARY KEY CLUSTERED 
			([ProductID] ASC,[GroupID] ASC,[ExchangeID] ASC,[SiteID] ASC,[LevelID] ASC)
		)
		
		CREATE TABLE #tmpCustGameSetting(
			[CustID] [int] NOT NULL,
			[ProductID] [tinyint] NOT NULL,
			[GroupID] [smallint] NOT NULL,
			[LevelID] [tinyint] NOT NULL,
			[MaxWinLimit] [money] NOT NULL
		 PRIMARY KEY CLUSTERED 
			([CustID] ASC,[ProductID] ASC,[GroupID] ASC,[LevelID] ASC)
		)
		
		DECLARE @tmpCustSetting TABLE (
			[CustID] [int] NOT NULL,
			[ProductID] [tinyint] NOT NULL,
			[GroupID] [smallint] NOT NULL,
			[LevelID] [tinyint] NOT NULL,
			[MaxWinLimit] [money] NOT NULL
		 PRIMARY KEY CLUSTERED 
			([CustID] ASC,[ProductID] ASC,[GroupID] ASC,[LevelID] ASC)				
		)
		
		INSERT INTO #tmpProductSettingDetail(ProductID,GroupID,ExchangeID,SiteID,LevelID,MaxWinLimit)
		SELECT psd.ProductID,psd.GroupID,psd.ExchangeID,psd.SiteID,psd.LevelID
			   ,CASE WHEN psd.ExchangeID IN (20, 218) THEN MaxWinLimit_RM ELSE ROUND(MaxWinLimit_RM / e.actualrate,2) END
		FROM WinLimit_ProductSettingDetail PSD WITH(ROWLOCK, UPDLOCK)         
			INNER JOIN Exchange e WITH (NOLOCK)  ON e.ExchangeId = psd.ExchangeID
		WHERE PSD.MaxWinLimit_RM IS NOT NULL
			AND MaxWinLimit <> CASE WHEN psd.ExchangeID IN (20, 218) THEN MaxWinLimit_RM ELSE ROUND(MaxWinLimit_RM / e.actualrate,2) END
		
		WHILE(1=1)
		BEGIN
			DELETE TOP (2000) t
			OUTPUT DELETED.ProductID, DELETED.GroupID, DELETED.ExchangeID, DELETED.SiteID, DELETED.LevelID, DELETED.MaxWinLimit
			INTO @tmpProductSetting(ProductID,GroupID,ExchangeID,SiteID,LevelID,MaxWinLimit)
			FROM #tmpProductSettingDetail t
			
			IF @@ROWCOUNT = 0
				BREAK;
				
			UPDATE PSD
				SET MaxWinLimit =t.MaxWinLimit,
					RepUpdateTime = dbo.f_GetDateTime2()	
			 FROM WinLimit_ProductSettingDetail PSD WITH(ROWLOCK, UPDLOCK)         
				INNER JOIN @tmpProductSetting t ON psd.ProductID = t.ProductID
										AND psd.GroupID = t.GroupID
										AND psd.ExchangeID = t.ExchangeID
										AND psd.SiteID = t.SiteID
										AND psd.LevelID = t.LevelID	
										
			DELETE @tmpProductSetting
			
			WAITFOR DELAY '0:0:0.05'
		END
		
		INSERT INTO #tmpCustGameSetting([CustID],[ProductID],[GroupID],[LevelID],[MaxWinLimit])
		SELECT psd.CustID,psd.ProductID,psd.GroupID,psd.LevelID,
			CASE WHEN CI.currency IN (20, 218) THEN MaxWinLimit_RM ELSE ROUND(MaxWinLimit_RM / e.actualrate,2) END
		FROM WinLimit_CustGameSetting PSD WITH(ROWLOCK, UPDLOCK)         
			INNER JOIN custInfo CI WITH (NOLOCK) ON CI.custid = PSD.CustID
			INNER JOIN Exchange e WITH (NOLOCK)  ON e.ExchangeId = CI.currency
			
		WHERE PSD.MaxWinLimit_RM IS NOT NULL
			AND MaxWinLimit <> CASE WHEN CI.currency IN (20, 218) THEN MaxWinLimit_RM ELSE ROUND(MaxWinLimit_RM / e.actualrate,2) END
		
		WHILE(1=1)
		BEGIN
			DELETE TOP (2000) t
			OUTPUT DELETED.CustID, DELETED.ProductID, DELETED.GroupID, DELETED.LevelID, DELETED.MaxWinLimit
			INTO @tmpCustSetting(CustID,ProductID,GroupID,LevelID,MaxWinLimit)
			FROM #tmpCustGameSetting t
			
			IF @@ROWCOUNT = 0
				BREAK;
				
			UPDATE PSD
				SET MaxWinLimit = t.MaxWinLimit,
					RepUpdateTime = dbo.f_GetDateTime2()
			FROM WinLimit_CustGameSetting PSD WITH(ROWLOCK, UPDLOCK)         
				INNER JOIN @tmpCustSetting t ON psd.CustID = t.CustID
										AND psd.ProductID = t.ProductID
										AND psd.GroupID = t.GroupID										
										AND psd.LevelID = t.LevelID	
										
			DELETE @tmpCustSetting	
			WAITFOR DELAY '0:0:0.05'			
		END	
		
		DROP TABLE #tmpCustGameSetting
		DROP TABLE #tmpProductSettingDetail
	END
	ELSE IF @IsCurrencySetting = 1 -- currency setting
	BEGIN
		UPDATE PSD
			SET MaxWinLimit = CASE WHEN psd.ExchangeID IN (20, 218) THEN MaxWinLimit_RM ELSE ROUND(MaxWinLimit_RM / e.actualrate,2) END,
				RepUpdateTime = dbo.f_GetDateTime2()
		FROM WinLimit_ProductSettingDetail PSD WITH(ROWLOCK, UPDLOCK)          
			INNER JOIN Exchange e WITH (NOLOCK)  ON e.ExchangeId = psd.ExchangeID
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
           SET  MaxWinLimit = CASE WHEN CI.currency IN (20, 218) THEN MaxWinLimit_RM ELSE ROUND(CGS.MaxWinLimit_RM / e.actualrate,2) END,
				RepUpdateTime = dbo.f_GetDateTime2()
        FROM dbo.WinLimit_CustGameSetting CGS WITH(ROWLOCK, UPDLOCK)         
			INNER JOIN custInfo CI WITH (NOLOCK) ON CI.custid = CGS.CustID
			INNER JOIN Exchange e WITH (NOLOCK)  ON e.ExchangeId = CI.currency
         WHERE CGS.CustID = @CustID  
               AND CGS.ProductID = @ProductID  
               AND CGS.Groupid = @GroupId  
               AND CGS.LevelId = @LevelId
	END
END



