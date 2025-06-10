/*<info serverAlias="DBCUST-AgencyCashService" executers="wsv_CashService"  viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Age_CashService_CustServiceTypeInitialize
	@CustID				INT				,
	@ServiceType			TINYINT			,
	@Site					NVARCHAR(50)		,
	@SubAccID				INT				= 0,
	@IP					VARCHAR(50)			= '',
	@Language				VARCHAR(2)			= 'E',
	@ErrCode				INT				= 0	 OUTPUT,
	@ErrMsg				NVARCHAR(1000)		= ''	 OUTPUT,
	@TrialEndTime			DATETIME			= NULL OUTPUT
AS 
/*  
	Created By: Helios
	Created Date: 2025-04-18
	Description: Agency Cash Service - Enable or Disable ServiceType [Redmine #223896]   
	DB: DBCust.CustDB
	
	Revisions:
		- 20250321@Helios: Agency Cash Service [Redmine: #228627] 

	Param: 
	@ServiceType : 0 - Disable  || 1 - Enable

	DECLARE @p1 INT , @p2 VARCHAR(1000) , @p3 DATETIME

	EXEC Age_CashService_CustServiceTypeInitialize @CustID													   = 34628732
								   , @ServiceType													   = 1
								   , @Site														   = N'222227'
								   , @SubAccID													   = 2
								   , @IP														   = '1.1.1.1'
								   , @Language													   = 'E'
								   , @ErrCode													   = @p1 OUTPUT
								   , @ErrMsg													   = @p2 OUTPUT
								   , @TrialEndTime												   = @p3 OUTPUT

	SELECT @p1 , @p2, @p3


*/  
BEGIN
	SET NOCOUNT ON;
	     
	DECLARE 
		@startRun		DATETIME ,
		@endRun		DATETIME ,
		@DurationTime	INT,
		@writeLog		BIT = 0
	
	SET @startRun = GETDATE ()
	SELECT @ErrCode = 0 , @ErrMsg = '' 

	IF @ServiceType = 0
	BEGIN
		SELECT  
			@ErrMsg = N'NoChange',
			@ErrCode = 0 ;
		RETURN;
	END

	-- Init CashAgentProviderConfig:
	DECLARE @SiteID INT = 0

	SELECT @SiteID = (SELECT s.siteid FROM GlobCustDB.dbo.Site s WITH (NOLOCK) WHERE Site = @Site)

	IF OBJECT_ID('tempdb..#tmp_ProviderConfig') IS NOT NULL
		DROP TABLE #tmp_ProviderConfig;

	CREATE TABLE #tmp_ProviderConfig (
	    AgentID				INT,
	    ProviderID			SMALLINT,
	    ProviderStatus		BIT,
	    ChannelContact		NVARCHAR(500),
	    RepUpdateTime			DATETIME2
	)

	INSERT INTO #tmp_ProviderConfig 
	(
		AgentID
	    , ProviderID
	    , ProviderStatus
	    , ChannelContact
	    , RepUpdateTime
	)
	SELECT 
	    @CustID AS AgentID,
	    s.ProviderID,
	    1 AS ProviderStatus,
	    N'{"Tele": "https://t.me/+XxIV3WPg3gc3NTM1"}' AS ChannelContact,
	    dbo.f_GetDateTime2() AS RepUpdateTime
	FROM CashProviderConfig s WITH (NOLOCK) 
	WHERE s.SiteID = @SiteID AND 
	NOT EXISTS ( SELECT 1
				FROM CashAgentProviderConfig c WITH (NOLOCK)
				WHERE c.AgentID = @CustID
				AND c.ProviderID = s.ProviderID
	);
	
	IF NOT EXISTS (SELECT TOP 1 1 FROM CashAgentProviderConfig capc WITH (NOLOCK) INNER JOIN  #tmp_ProviderConfig tpc ON capc.AgentID = tpc.AgentID AND capc.ProviderID = tpc.ProviderID)
	BEGIN
		BEGIN TRY
			INSERT INTO CashAgentProviderConfig 
			(
				AgentID
			    , ProviderID
			    , ProviderStatus
			    , ChannelContact
			    , RepUpdateTime
			)
			SELECT
				AgentID
			    , ProviderID
			    , ProviderStatus
			    , ChannelContact
			    , RepUpdateTime
			FROM #tmp_ProviderConfig

			IF @@rowcount > 0
				SELECT @writeLog = 1
		END TRY
		BEGIN CATCH
			SELECT @ErrMsg = N'Initialize failed.',
							--CASE @Language
							--	WHEN 'E' THEN 'Initialize failed.'
								--ELSE [dbo].[f_Get_MsgNamebyMsgID](40004,@Language)
								--END,
					@ErrCode = 201
			RETURN
		END CATCH
	END

	-- Init CashAgentBankAccountLimit:
	IF NOT EXISTS (SELECT TOP 1 1 FROM CashAgentBankAccountLimit cabal WITH (NOLOCK) WHERE cabal.AgentID = @CustID )
	BEGIN
		BEGIN TRY
			INSERT INTO CashAgentBankAccountLimit 
			(
				AgentID
			    , MinPerDeposit
			    , MaxPerDeposit
			    , MinPerWithdrawal
			    , MaxPerWithdrawal
			    , RepUpdateTime
			)
			SELECT @CustID,
				 0,
				 0,
				 0,
				 0,
				 dbo.f_GetDateTime2()

			IF @@rowcount > 0
				SELECT @writeLog = 1
		END TRY
		BEGIN CATCH
			SELECT @ErrMsg = N'Initialize failed.',
							--CASE @Language
							--	WHEN 'E' THEN 'Initialize failed.'
								--ELSE [dbo].[f_Get_MsgNamebyMsgID](40004,@Language)
								--END,
					@ErrCode = 202
			RETURN
		END CATCH	
	END

	-- Init CashDomainManagement:
	DECLARE @tmp_Domain TABLE (DomainID VARCHAR(20))

	INSERT INTO @tmp_Domain (DomainID)
	SELECT TOP 2 CAST(dm.DomainID AS VARCHAR(20)) 
	FROM GlobCustDB.dbo.DomainManagement dm WITH (NOLOCK)
	WHERE dm.isDeleted = 0
	AND dm.Status = 3
	AND dm.OfferType = 1
	AND dm.System = 'Member'
	AND @SiteID IN (SELECT TRIM(VALUE) FROM STRING_SPLIT(dm.Site,','))

	IF NOT EXISTS (SELECT TOP 1 1 FROM @tmp_Domain)
	BEGIN
		SELECT  
			@ErrMsg = N'No domains are available.',
			@ErrCode = 100 ;
		RETURN;
	END

	IF NOT EXISTS (SELECT TOP 1 1 FROM CashDomainManagement cdm WITH (NOLOCK) WHERE cdm.AgentId = @CustID)
	BEGIN
		BEGIN TRY
			INSERT INTO CashDomainManagement 
			(
				AgentId
			    , DomainId
			    , SubDomainPrefix
			    , RepUpdateTime
			)
			SELECT
				@CustID,
				DomainID,
				'simplec-' + LEFT(CAST(@CustID AS VARCHAR), 3) + 
						 DomainID + 
						 SUBSTRING(CAST(@CustID AS VARCHAR), 4, LEN(CAST(@CustID AS VARCHAR)) - 3) AS SubDomainPrefix,
				dbo.f_GetDateTime2()
			FROM @tmp_Domain

			IF @@rowcount > 0
				SELECT @writeLog = 1
		END TRY
		BEGIN CATCH
			SELECT @ErrMsg = N'Initialize failed.',
							--CASE @Language
							--	WHEN 'E' THEN 'Initialize failed.'
								--ELSE [dbo].[f_Get_MsgNamebyMsgID](40004,@Language)
								--END,
				@ErrCode = 203
			RETURN
		END CATCH		
	END

	-- Init CashAgentManagement:

	DECLARE @Mode BIT = NULL

	SELECT @Mode = (SELECT TOP 1 1 FROM CashAgentManagement cam WITH (NOLOCK) WHERE cam.AgentId = @CustID) 

	-- Cash Service is enabled for the first time, so the next step is triggered to calculate fees.
	IF ISNULL(@Mode , 0) = 0 
	BEGIN
		BEGIN TRY
			SELECT @TrialEndTime = DATEADD(DAY, 13, GETDATE ())

			INSERT INTO CashAgentManagement 
			(
				AgentId
			    , SettingInfo
			    , Mobile
			    , Contact
			    , Announcement
			    , DailyWithdrawalCount
			    , StartTime
			    , TrialEndTime
			    , RepUpdateTime
			)
			SELECT
				@CustID AS AgentId,
				3	  AS SettingInfo,
				NULL	  AS Mobile,
				N'[{"type":"line","value":""},{"type":"tele","value":""}]'	AS Contact,
				NULL										AS Announcement,
				1										AS DailyWithdrawalCount,
				GETDATE ()									AS StartTime,
				DATEADD(DAY, 13, GETDATE ())						AS TrialEndTime,
				dbo.f_GetDateTime2()							AS RepUpdateTime

			IF @@rowcount > 0
				SELECT @writeLog = 1
		END TRY
		BEGIN CATCH
			SELECT @ErrMsg = N'Initialize failed.',
							--CASE @Language
							--	WHEN 'E' THEN 'Initialize failed.'
								--ELSE [dbo].[f_Get_MsgNamebyMsgID](40004,@Language)
								--END,
				@ErrCode = 204
			RETURN
		END CATCH
	END

	-- Cash Service is reactivated, so retrieve the TrialEndTime to determine the next step.
	IF @Mode = 1
	BEGIN
		SELECT @TrialEndTime = (SELECT TOP 1 cam.TrialEndTime FROM CashAgentManagement cam WITH (NOLOCK) WHERE cam.AgentId = @CustID)
	END


	IF @writeLog = 0
	BEGIN
		SELECT  
			@ErrMsg = N'NoChange',
			@ErrCode = 0 ;
		RETURN;
	END

	IF @writeLog = 1
	BEGIN
		IF (@@error = 0)
		BEGIN
			SELECT  
				@ErrMsg = N'Init Successful!',
				@ErrCode = 0 ;
		END
			     
		--START LOG
		DECLARE @LogInfo_Tbl TABLE(UserID INT, CustID INT, ActionID INT, TrackingValue VARCHAR(MAX), TrackingValue2 VARCHAR(MAX) , Duration INT )
		DECLARE @TrackingValue VARCHAR(MAX), @TrackingValue2 VARCHAR(MAX)
		DECLARE @xml XML , @UserName NVARCHAR(50) , @ActionID INT = 300006
			SET @endRun = GETDATE ()
			SET @DurationTime = datediff (millisecond,@startRun,@endRun)

		/*CashAgentProviderConfig*/
		-- LOG NEW VALUES
		SET @xml = (
		SELECT	@CustID                         AS '@CustID',
				CustDB.dbo.f_GetSubUsername(@SubAccID) AS '@SubAccName',
				@IP                             AS '@IP',
				(
					SELECT	pc.AgentID						 AS '@CustID',
							pc.ProviderID					 AS '@ProviderID',
							pc.ProviderStatus					 AS '@ProviderStatus',
							CONVERT(NVARCHAR(500) , pc.ChannelContact) AS '@ChannelContact'
					FROM #tmp_ProviderConfig pc
					FOR XML PATH('ProviderConfig'), 
					TYPE
				)
		FOR XML PATH('ROOT'), TYPE
		);
		SET @TrackingValue = REPLACE(REPLACE(CONVERT(NVARCHAR(MAX), @xml), '&quot;', '"'), '" />', '"/"');

	
		INSERT INTO @LogInfo_Tbl (UserID, CustID, ActionID, TrackingValue, TrackingValue2, Duration)
		SELECT @CustID ,  @CustID , @ActionID , @TrackingValue , NULL , @DurationTime
	
		/*CashDomainManagement*/
		-- LOG NEW VALUES
		SET @xml = (
		SELECT	@CustID                         AS '@CustID',
				CustDB.dbo.f_GetSubUsername(@SubAccID) AS '@SubAccName',
				@IP                             AS '@IP',
				(
					SELECT	cdm.AgentId						 AS '@CustID',
							cdm.DomainId					 AS '@DomainId',
							cdm.SubDomainPrefix				 AS '@SubDomainPrefix'
					FROM CashDomainManagement cdm WITH (NOLOCK) 
					WHERE cdm.AgentId = @CustID
					FOR XML PATH('DomainManagement'), 
					TYPE
				)
		FOR XML PATH('ROOT'), TYPE
		);
		SET @TrackingValue = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')

	
		INSERT INTO @LogInfo_Tbl (UserID, CustID, ActionID, TrackingValue, TrackingValue2, Duration)
		SELECT @CustID ,  @CustID , @ActionID , @TrackingValue , NULL , @DurationTime


		/*CashAgentManagement*/
		-- LOG NEW VALUES
		SET @xml = (
		SELECT	@CustID                         AS '@CustID',
				CustDB.dbo.f_GetSubUsername(@SubAccID) AS '@SubAccName',
				@IP                             AS '@IP',
				(
					SELECT	@CustID					 AS '@CustID',
							cam.SettingInfo				 AS '@SettingInfo',
							cam.Mobile					 AS '@Mobile',
							CONVERT(NVARCHAR(500) , cam.Contact) AS '@Contact',
							CONVERT(NVARCHAR(500) , cam.Announcement)				 AS '@Announcement',
							cam.DailyWithdrawalCount						 AS '@DailyWithdrawalCount',
							CONVERT(VARCHAR(200) ,  cam.StartTime , 120)			 AS '@StartTime',
							CONVERT(VARCHAR(200) ,  cam.TrialEndTime , 120)			 AS '@TrialEndTime'
					FROM CashAgentManagement cam WITH (NOLOCK)
					WHERE cam.AgentId = @CustID
					FOR XML PATH('AgentManagement'), 
					TYPE
				)
		FOR XML PATH('ROOT'), TYPE
		);
		SET @TrackingValue = REPLACE(REPLACE(CONVERT(NVARCHAR(MAX), @xml), '&quot;', '"'), '" />', '"/"');
	
		INSERT INTO @LogInfo_Tbl (UserID, CustID, ActionID, TrackingValue, TrackingValue2, Duration)
		SELECT @CustID ,  @CustID , @ActionID , @TrackingValue , NULL , @DurationTime
	
		-- Return Data Object
		SELECT UserID, CustID, ActionID, TrackingValue, TrackingValue2 , TrackingValue AS TrackingValueMask, TrackingValue2 AS  TrackingValueMask2 , Duration 
		FROM @LogInfo_Tbl

	END
	
END