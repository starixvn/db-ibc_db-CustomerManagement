/*<info serverAlias="DBCust-CustDB" executers="wsv_nap" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_WinLimit_CurrencySettingUpd] 
	@xml	XML,
	@UserID INT         = 0, 
	@IP		VARCHAR(20) = ''
AS

/*
Created: Franklin	
Date: 2016-06-22
Task: #57722 - Implement Game Win Limit Control phase2

DB: DBCUST/CustDB

Revisions:
	- 20160923@Jacob: Risk & Control - Phase 3 [#61220].
	- 20170808@Jacob: Risk & Control - Phase 4 [#72870]
	- 20220522@Robert: #168458 - CWL - Enhance Currency Win Limit Setting page
	- 20220623@Johnson: enhance flow update [redmine:#168458]
	- 20230911@Tacy: CWL - Suspend member accounts when member reaches Yellow level on RNG Slots Games [RedmineID: #184911]
	- 20240809@Johnson: Apply Inhouse Replication for CWL [redmine: #209068]
Parameters Explanation:	
   @xml = '<Root>
				<r Product="1" Group="1" Currency="1" Site="1" Level="1" WinLimit="1000.0" PlaceBet="0" Transfer="0" Suspend="0"/>
				<r Product="1" Group="1" Currency="2" Site="1" Level="1" WinLimit="1000.0" PlaceBet="0" Transfer="0" Suspend="0"/>
			</Root>'
   @UserID: User making this action.
   @IP: IP of the machine making this action.
*/

BEGIN
	SET NOCOUNT ON;
	DECLARE 
		   @StartRun       DATETIME
		 , @EndRun         DATETIME
		 , @Duration       INT		
	
	SELECT 
			@StartRun = GETDATE();
			
	DECLARE @ProductId         INT,
			@GroupId           INT,
			@CurrencyId        INT,
			@SiteId            INT,
			@LevelId           INT,
			@MaxWinLimit       MONEY,
			@IsBlockedPlaceBet BIT,
			@IsBlockedTransfer BIT,
			@IsSuspendedAccount BIT


	DECLARE @OldMaxWinLimit MONEY, 
		@OldIsBlockedPlaceBet BIT, 
		@OldIsBlockedTransfer BIT, 
		@OldIsSuspendedAccount BIT, 
		@TrackingValue1 VARCHAR(500),
		@TrackingValue2 VARCHAR(500)
	
	CREATE TABLE #tblSetting (ProductId         INT,
	                           GroupId           INT,
	                           CurrencyId        INT,
	                           SiteId            INT,
	                           LevelId           INT,
	                           MaxWinLimit       MONEY,
	                           IsBlockedPlaceBet BIT,
							   IsBlockedTransfer BIT,
							   IsSuspendedAccount BIT,
							   IsFinished BIT DEFAULT(0))
							   
	INSERT INTO #tblSetting(ProductID,GroupID,CurrencyId,SiteID,LevelId,MaxWinLimit,IsBlockedPlaceBet,IsBlockedTransfer,IsSuspendedAccount)
	SELECT 
		t.c.value('@Product', 'INT') AS ProductId
		,t.c.value('@Group', 'INT') AS GroupId
		,t.c.value('@Currency', 'INT') AS CurrencyId
		,t.c.value('@Site', 'INT') AS SiteId
		,t.c.value('@Level', 'INT') AS LevelId
		,t.c.value('@WinLimit', 'MONEY') AS MaxWinLimit
		,t.c.value('@PlaceBet', 'BIT') AS IsBlockedPlaceBet
		,t.c.value('@Transfer', 'BIT') AS IsBlockedTransfer
		,t.c.value('@Suspend', 'BIT') AS IsSuspendedAccount
	FROM @xml.nodes('Root/r') t(c)
	
	WHILE (1=1)
	BEGIN
		UPDATE TOP (1) t
		SET @ProductId = ProductID,        
		    @GroupId = GroupId,         
		    @CurrencyId = CurrencyId,      
		    @SiteId = SiteId,         
		    @LevelId = LevelId,        
		    @MaxWinLimit = MaxWinLimit,      
		    @IsBlockedPlaceBet = IsBlockedPlaceBet,
		    @IsBlockedTransfer = IsBlockedTransfer,
			@IsSuspendedAccount = IsSuspendedAccount,
			IsFinished = 1
		FROM #tblSetting t
		WHERE IsFinished = 0
		
		IF @@ROWCOUNT = 0
			BREAK;
		
	    IF EXISTS
			  (
				 SELECT 
					   1
				 FROM dbo.WinLimit_ProductSettingDetail WITH(NOLOCK)
				 WHERE ProductID = @ProductId
					  AND GroupId = @GroupId
					  AND ExchangeID = @CurrencyId
					  AND LevelID = @LevelId
					  AND SiteID = @SiteId
			   )
		  BEGIN -- Update			 
			 SELECT 
				   @OldMaxWinLimit = MaxWinLimit_RM, 
				   @OldIsBlockedPlaceBet = IsBlockedPlaceBet, 
				   @OldIsBlockedTransfer = IsBlockedTransfer,
				   @OldIsSuspendedAccount = IsSuspendedAccount
			 FROM dbo.WinLimit_ProductSettingDetail WITH(NOLOCK)
			 WHERE ProductID = @ProductId
				  AND GroupId = @GroupId
				  AND ExchangeID = @CurrencyId
				  AND LevelID = @LevelId
				  AND SiteID = @SiteId;

			 UPDATE s
			   SET 
				  s.MaxWinLimit_RM = @MaxWinLimit, 
				  s.IsBlockedPlaceBet = @IsBlockedPlaceBet, 
				  s.IsBlockedTransfer = CASE
									   WHEN st.isDeposit = 0
									   THEN 0
									   ELSE @IsBlockedTransfer
								    END,
				  s.IsSuspendedAccount = CASE
									   WHEN st.isDeposit = 1
									   THEN 0
									   ELSE @IsSuspendedAccount
								    END,
				  s.RepUpdateTime = SYSDATETIME()											
			 FROM dbo.WinLimit_ProductSettingDetail s WITH (ROWLOCK, UPDLOCK)
				 INNER JOIN dbo.Site st WITH(ROWLOCK) ON s.SiteID = st.siteid
			 WHERE 
				  s.ProductID = @ProductId
				  AND s.GroupId = @GroupId
				  AND s.ExchangeID = @CurrencyId
				  AND s.LevelID = @LevelId
				  AND s.SiteID = @SiteId;


			 EXEC Task_Winlimit_CurrencyMaxWinLimitUpd 
				 @IsCurrencySetting = 1, 
				 @ProductID = @ProductId, 
				 @GroupId = @GroupId, 
				 @CurrencyId = @CurrencyId, 
				 @LevelID = @LevelId, 
				 @SiteId = @SiteId;
			 BEGIN -- Write Log

				SELECT 
					  @EndRun = GETDATE(), 
					  @Duration = DATEDIFF(millisecond, @StartRun, @EndRun);
				SET @TrackingValue1 = '<NAP_WinLimit_CurrencySettingUpd ';
				SET @TrackingValue1 = @TrackingValue1 + '" ProductID ="' + CONVERT(VARCHAR(20), @ProductId);
				SET @TrackingValue1 = @TrackingValue1 + '" GroupId="' + CONVERT(VARCHAR(20), @GroupId);
				SET @TrackingValue1 = @TrackingValue1 + '" ExchangeID="' + CONVERT(VARCHAR(20), @CurrencyId);
				SET @TrackingValue1 = @TrackingValue1 + '" LevelID="' + CONVERT(VARCHAR(20), @LevelId);
				SET @TrackingValue1 = @TrackingValue1 + '" MaxWinLimit_RM="' + CONVERT(VARCHAR(20), @OldMaxWinLimit);
				SET @TrackingValue1 = @TrackingValue1 + '" IsBlockedPlaceBet="' + CONVERT(VARCHAR(20), @OldIsBlockedPlaceBet);
				SET @TrackingValue1 = @TrackingValue1 + '" IsBlockedTransfer="' + CONVERT(VARCHAR(20), @OldIsBlockedTransfer);
				SET @TrackingValue1 = @TrackingValue1 + '" IsSuspendedAccount="' + CONVERT(VARCHAR(20), @OldIsSuspendedAccount);
				SET @TrackingValue1 = @TrackingValue1 + '" UserId="' + CONVERT(VARCHAR(20), @UserId);
				SET @TrackingValue1 = @TrackingValue1 + '" SiteId="' + CONVERT(VARCHAR(20), @SiteId);
				SET @TrackingValue1 = @TrackingValue1 + '" IP="' + COALESCE(CAST(@IP AS VARCHAR(15)), SPACE(1)) + '" />';
				
				SET @TrackingValue2 = '<NAP_WinLimit_CurrencySettingUpd ';
				SET @TrackingValue2 = @TrackingValue2 + '" ProductID ="' + CONVERT(VARCHAR(20), @ProductId);
				SET @TrackingValue2 = @TrackingValue2 + '" GroupId="' + CONVERT(VARCHAR(20), @GroupId);
				SET @TrackingValue2 = @TrackingValue2 + '" ExchangeID="' + CONVERT(VARCHAR(20), @CurrencyId);
				SET @TrackingValue2 = @TrackingValue2 + '" LevelID="' + CONVERT(VARCHAR(20), @LevelId);
				SET @TrackingValue2 = @TrackingValue2 + '" MaxWinLimit_RM="' + CONVERT(VARCHAR(20), @MaxWinLimit);
				SET @TrackingValue2 = @TrackingValue2 + '" IsBlockedPlaceBet="' + CONVERT(VARCHAR(20), @IsBlockedPlaceBet);
				SET @TrackingValue2 = @TrackingValue2 + '" IsBlockedTransfer="' + CONVERT(VARCHAR(20), @IsBlockedTransfer);
				SET @TrackingValue2 = @TrackingValue2 + '" IsSuspendedAccount="' + CONVERT(VARCHAR(20), @IsSuspendedAccount);
				SET @TrackingValue2 = @TrackingValue2 + '" UserId="' + CONVERT(VARCHAR(20), @UserId);
				SET @TrackingValue2 = @TrackingValue2 + '" SiteId="' + CONVERT(VARCHAR(20), @SiteId);
				SET @TrackingValue2 = @TrackingValue2 + '" IP="' + COALESCE(CAST(@IP AS VARCHAR(15)), SPACE(1)) + '" />';
				BEGIN TRY
				    EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
					    @UserID = @UserID, 
					    @ActionID = 31201, 
					    @TrackingValue = @TrackingValue1, 
					    @TrackingValue2 = @TrackingValue2, 
					    @Duration = @Duration;
				END TRY
				BEGIN CATCH
				END CATCH;
			 END;
		  END;
		  ELSE
		  BEGIN -- Insert data
			 INSERT INTO dbo.WinLimit_ProductSettingDetail
			    (
				   ProductID, 
				   GroupId, 
				   ExchangeID, 
				   SiteID, 
				   LevelID, 
				   MaxWinLimit_RM, 
				   IsBlockedPlaceBet, 
				   IsBlockedTransfer,
				   IsSuspendedAccount
			    )
			 VALUES
				  (
				   @ProductId, 
				   @GroupId, 
				   @CurrencyId, 
				   @SiteId, 
				   @LevelId, 
				   @MaxWinLimit, 
				   @IsBlockedPlaceBet, 
				   @IsBlockedTransfer,
				   @IsSuspendedAccount
				  );
			 EXEC Task_Winlimit_CurrencyMaxWinLimitUpd 
				 @IsCurrencySetting = 1, 
				 @ProductID = @ProductId, 
				 @GroupId = @GroupId, 
				 @CurrencyId = @CurrencyId, 
				 @LevelID = @LevelId, 
				 @SiteId = @SiteId;
			 BEGIN -- Write log

				SELECT 
					  @EndRun = GETDATE(), 
					  @Duration = DATEDIFF(millisecond, @StartRun, @EndRun);
				SET @TrackingValue1 = '<NAP_WinLimit_CurrencySettingUpd ';
				SET @TrackingValue1 = @TrackingValue1 + '" ProductID ="' + CONVERT(VARCHAR(20), @ProductId);
				SET @TrackingValue1 = @TrackingValue1 + '" GroupId="' + CONVERT(VARCHAR(20), @GroupId);
				SET @TrackingValue1 = @TrackingValue1 + '" ExchangeID="' + CONVERT(VARCHAR(20), @CurrencyId);
				SET @TrackingValue1 = @TrackingValue1 + '" SiteID="' + CONVERT(VARCHAR(20), @SiteId);
				SET @TrackingValue1 = @TrackingValue1 + '" LevelID="' + CONVERT(VARCHAR(20), @LevelId);
				SET @TrackingValue1 = @TrackingValue1 + '" MaxWinLimit_RM="' + CONVERT(VARCHAR(20), @MaxWinLimit);
				SET @TrackingValue1 = @TrackingValue1 + '" IsBlockedPlaceBet="' + CONVERT(VARCHAR(20), @IsBlockedPlaceBet);
				SET @TrackingValue1 = @TrackingValue1 + '" IsBlockedTransfer="' + CONVERT(VARCHAR(20), @IsBlockedTransfer);
				SET @TrackingValue1 = @TrackingValue1 + '" IsSuspendedAccount="' + CONVERT(VARCHAR(20), @IsSuspendedAccount);
				SET @TrackingValue1 = @TrackingValue1 + '" UserId="' + CONVERT(VARCHAR(20), @UserId);
				SET @TrackingValue1 = @TrackingValue1 + '" IP="' + COALESCE(CAST(@IP AS VARCHAR(15)), SPACE(1)) + '" />';
				BEGIN TRY
				    EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
					    @UserID = @UserID, 
					    @ActionID = 31201, 
					    @TrackingValue = @TrackingValue1, 
					    @Duration = @Duration;
				END TRY
				BEGIN CATCH
				END CATCH;
			 END;
		  END;
		END--while()
    END;