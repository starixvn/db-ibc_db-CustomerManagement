/*<info serverAlias="DBCUST-AgencyCashService" executers="wsv_CashService"  viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Age_CashService_GeneralSetting_Upd
	@CustID			INT,				-- SMA Input
	@SettingInfo		TINYINT,
	@Mobile			VARCHAR(50),
	@Contact			NVARCHAR(200),
	@Announcement		NVARCHAR(500)		= NULL,
	@SubAccID			INT				= 0,
	@IP				VARCHAR(50)			= '',
	@Language			VARCHAR(2)			= 'E',
	@ErrCode			INT				= 0		OUTPUT,
	@ErrMsg			NVARCHAR(1000)		= ''		OUTPUT
AS 
/* 
	Created By: Helios
	Created Date: 2025-04-18
	Description: Agency Cash Service - Get Member Site Management [Redmine #223896]
	DB: DBCust.AgencyCashService
	
	Revisions:
		- 20250321@Helios: Agency Cash Service [Redmine: #223896]
		- 20250623@Helios: Offer CashService - Enhance writelog with Masked: CashAgentManagement.Contact , Mobile [RedmineID: #231204]   

	Param:
		DECLARE @p1 INT , @p2 NVARCHAR(1000)
		exec Age_CashService_GeneralSetting_Upd	
										@CustID =  1176087,
										@SettingInfo =  0,
										@Mobile =  '66-43789353',
										@Contact =  '[{"type":"line","value":"testline"},{"type":"tele","value":"testtele"}]',
										@Announcement =  'Takjshdkasjkjashdkajsmnvikuhyjdkajs',
										@SubAccID = 0,
										@IP = '1.1.1.1',
										@Language = 'E',
										@ErrCode =  @p1 OUTPUT,
										@ErrMsg =  @p2 OUTPUT
		select @p1 , @p2

*/  
BEGIN
	SET NOCOUNT ON;
	
	DECLARE 
		@startRun		DATETIME ,
		@endRun		DATETIME ,
		@DurationTime	INT
	
	SET @startRun = GETDATE ()
	SELECT @ErrCode = 0 , @ErrMsg = '' 

	DECLARE @old_ManagedAgents TABLE (
	    SettingInfo		TINYINT ,
	    Mobile			VARCHAR(50),
	    Contact			NVARCHAR(200),
	    Announcement		NVARCHAR(500)
	)

	IF @SettingInfo IS NULL OR @Mobile IS NULL OR @Mobile = '' OR @Contact IS NULL OR @Contact = ''
	BEGIN
		SELECT  @ErrMsg = N'Invalid parameters', @ErrCode = 100;
		RETURN
	END


	DECLARE @tmp_Contact TABLE (
		ContactType			NVARCHAR(50),
		ContactValues		NVARCHAR(150)
	)
	-- check parse data
	INSERT INTO @tmp_Contact 
	(
		ContactType
	    , ContactValues
	)
	SELECT 
	    [type],
	    [value]
	FROM OPENJSON(@Contact)
	WITH (
	    [type] NVARCHAR(50) '$.type',
	    [value] NVARCHAR(150) '$.value'
	);

	IF NOT EXISTS (SELECT TOP 1 1 FROM @tmp_Contact)
	OR NOT EXISTS (SELECT TOP 1 1 FROM @tmp_Contact WHERE ContactType = 'line')
	OR EXISTS (SELECT 1 FROM @tmp_Contact WHERE ContactType = 'line' AND (ContactValues IS NULL OR ContactValues = ''))
	BEGIN
		SELECT  @ErrMsg = N'Invalid parameters' , @ErrCode = 101 ;	
		RETURN
	END

	DECLARE @_existAgents BIT = NULL
	SELECT @_existAgents = (SELECT TOP 1 1 FROM CashAgentManagement WITH (NOLOCK) WHERE AgentId = @CustID)
	
	IF @_existAgents = 1 
	BEGIN
		-- INSERT FOR WRITE LOG
		INSERT INTO @old_ManagedAgents 
		(
			SettingInfo
			, Mobile
			, Contact
			, Announcement
		)
		SELECT 
			SettingInfo
		    , Mobile
		    , Contact
		    , Announcement
		FROM CashAgentManagement cam WITH (NOLOCK)
		WHERE cam.AgentId = @CustID

		-- UPDATE SETTING
		UPDATE a
			SET a.SettingInfo		= @SettingInfo
			,   a.Mobile		= @Mobile
			,   a.Contact		= @Contact
			,   a.Announcement	= @Announcement
			,   a.RepUpdateTime	= dbo.f_GetDateTime2()
		FROM CashAgentManagement a WITH (ROWLOCK ,UPDLOCK)
		WHERE a.AgentId = @CustID
	END

	IF (@@error = 0)
	BEGIN
		SELECT  
			@ErrMsg = N'Action completed successfully.',
			@ErrCode = 0 ;
	END

	
	--START LOG
	--DECLARE @LogInfo_Tbl TABLE(UserID INT, CustID INT, ActionID INT, TrackingValue NVARCHAR(MAX), TrackingValue2 NVARCHAR(MAX) , Duration INT )
	DECLARE @TrackingValue NVARCHAR(MAX), @TrackingValue2 NVARCHAR(MAX) , @TrackingValueMask NVARCHAR(MAX), @TrackingValueMask2 NVARCHAR(MAX)
	DECLARE @xml XML , @UserName NVARCHAR(50) , @ActionID INT = 305006
		SET @endRun = GETDATE ()
		SET @DurationTime = datediff (millisecond,@startRun,@endRun)

	-- LOG NEW VALUES
	SET @xml = (
		SELECT	@CustID									AS '@CustID',
				CustDB.dbo.f_GetSubUsername(@SubAccID)					AS '@SubAccName',
				@IP										AS '@IP',
				(
					SELECT	
							@SettingInfo					AS '@SettingInfo',
							@Mobile						AS '@Mobile',
							CONVERT(NVARCHAR(500) , @Contact)		AS '@Contact',
							CONVERT(NVARCHAR(500) , @Announcement)	AS '@Announcement'
					FOR XML PATH('CashAgentManagement'), 
					TYPE
				)
		FOR XML PATH('ROOT'),TYPE
	);
	SET @TrackingValueMask = REPLACE(REPLACE(CONVERT(NVARCHAR(MAX), @xml), '&quot;', '"'), '" />', '"/"');
	SELECT @TrackingValue = REPLACE(REPLACE(@TrackingValueMask, ISNULL(@Mobile, ''), ''),ISNULL(@Contact, ''),'');


	-- LOG OLD VALUES
	SET @xml = (
		SELECT	@CustID									AS '@CustID',
				CustDB.dbo.f_GetSubUsername(@SubAccID)					AS '@SubAccName',
				@IP										AS '@IP',
				(
					SELECT	
							a.SettingInfo					AS '@SettingInfo',
							a.Mobile						AS '@Mobile',
							CONVERT(NVARCHAR(500) , a.Contact)		AS '@Contact',
							CONVERT(NVARCHAR(500) , a.Announcement)	AS '@Announcement'
					FROM @old_ManagedAgents a
					FOR XML PATH('CashAgentManagement'), 
					TYPE
				)
		FOR XML PATH('ROOT'),TYPE
	);
	SET @TrackingValueMask2 = REPLACE(REPLACE(CONVERT(NVARCHAR(MAX), @xml), '&quot;', '"'), '" />', '"/"');


	SET @xml = (
		SELECT	@CustID									AS '@CustID',
				CustDB.dbo.f_GetSubUsername(@SubAccID)					AS '@SubAccName',
				@IP										AS '@IP',
				(
					SELECT	
							a.SettingInfo					AS '@SettingInfo',
							''							AS '@Mobile',
							''							AS '@Contact',
							CONVERT(NVARCHAR(500) , a.Announcement)	AS '@Announcement'
					FROM @old_ManagedAgents a
					FOR XML PATH('CashAgentManagement'), 
					TYPE
				)
		FOR XML PATH('ROOT'),TYPE
	);
	SELECT @TrackingValue2 =  REPLACE(CONVERT(NVARCHAR(MAX), @xml), '" />', '"/"')

	--INSERT INTO @LogInfo_Tbl (UserID, CustID, ActionID, TrackingValue, TrackingValue2, Duration)
	--SELECT @CustID ,  @CustID , @ActionID , @TrackingValue , @TrackingValue2 , @DurationTime


	-- Return Data Object
	SELECT
		@custid		  AS UserID
	    , @custid		  AS CustID
	    , @ActionID		  AS ActionID
	    , @TrackingValue	  AS TrackingValue
	    , @TrackingValue2	  AS TrackingValue2
	    , @TrackingValueMask  AS TrackingValueMask
	    , @TrackingValueMask2 AS TrackingValueMask2
	    , @DurationTime	  AS Duration

END
