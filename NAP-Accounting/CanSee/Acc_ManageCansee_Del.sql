/*<info serverAlias="DBGLOB-GlobCustDB" executers="wsv_nap" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[Acc_ManageCansee_Del] 
	-- Add the parameters for the stored procedure here
	  @FileSetting	VARCHAR(MAX)
	, @UserID		INT
	, @IP			VARCHAR(50)		= ''
	, @ErrCode		INT				= 0		OUTPUT
	, @ErrMsg		NVARCHAR(200)	= ''	OUTPUT
AS
BEGIN
	/*
		Task : NAP -  Manage ProductLaunchSiteCurrency - CanSee
		DB: DBGLOB-GlobCustDB
		Original: 
		Revisions:
			- 20200617@Winfred: NAP -  Manage ProductLaunchSiteCurrency / CanSee [Redmine: #131241]
			- 20250108@Virgil: Scale Out DBCUST - Apply In-house replication for profile setting tables [Redmine: #214117]
			- 20250218@Johnson: move sp to GlobCustDB [redmine: #216870]
	*/
	SET NOCOUNT ON;
	--SportType,BetType,Currency,SiteID
	DECLARE @StartRun	DATETIME
		, @EndRun		DATETIME
		, @Duration		INT
		, @iDoc			INT
		, @logSpData		 NVARCHAR(MAX)
		, @xml			 XML
		, @RowTotal INT = 0
		, @CurrentRow INT = 0;	
	CREATE TABLE #File_Temp(
		SportType SMALLINT,
		Currency INT,
		BetType SMALLINT,
		SiteID INT
	)
	--Check if XML is null or empty
	IF @FileSetting IS NULL OR @FileSetting = ''
		RETURN
	SET @StartRun = GETDATE()	
	BEGIN TRY
		-- Create table temp data delete
		EXEC sp_xml_preparedocument @iDoc OUTPUT, @FileSetting
		INSERT #File_Temp(SportType,Currency,BetType,SiteID)
		SELECT SportType,Currency,BetType,SiteID
		FROM OPENXML(@iDoc,'/ROOT/File',1) WITH (
				SportType SMALLINT,
				Currency INT,
				BetType SMALLINT,
				SiteID INT
			)
		EXEC sp_xml_removedocument @iDoc
		-- Log row IsTest = 1
		SELECT @logSpData = (
			SELECT plsc.SportType,plsc.Currency,plsc.BetType,plsc.SiteID 
			FROM ProductLaunchedSiteCurrency plsc WITH(NOLOCK)
			INNER JOIN #File_Temp a on a.SiteID = plsc.SiteID  AND a.Currency = plsc.Currency 
							AND a.SportType = plsc.SportType   AND a.BetType = plsc.BetType
				WHERE 	plsc.IsTest = 1	
			FOR XML RAW('File'))
		
		SET  @logSpData = '<ROOT>' + @logSpData + '</ROOT>'

		-- Delete row IsTest = 1
		DELETE plsc
		OUTPUT deleted.SiteID, deleted.Currency, deleted.SportType, deleted.BetType, deleted.LaunchedLevel, [dbo].[f_GetDateTime2]() 
		INTO dbo.ProductLaunchedSiteCurrency_Del_InHouse(SiteID, Currency, SportType, BetType, LaunchedLevel, RepUpdateTime)
		FROM dbo.ProductLaunchedSiteCurrency plsc WITH(ROWLOCK)
			INNER JOIN #File_Temp a on a.SiteID = plsc.SiteID  AND a.Currency = plsc.Currency 
						AND a.SportType = plsc.SportType   AND a.BetType = plsc.BetType
						--AND a.LaunchedLevel = plsc.LaunchedLevel
		WHERE plsc.IsTest = 1	
				
	END TRY
	BEGIN CATCH
		SELECT  @ErrCode = ERROR_NUMBER(),@ErrMsg = ERROR_MESSAGE();		
		RETURN
	END CATCH
	
	SELECT @EndRun	= GETDATE(), @Duration = DATEDIFF(MILLISECOND, @StartRun, @EndRun)
	EXEC  Acc_WriteLog_UserLog_RunSP_Wrapper
			@UserID = @UserID
			,@ActionID = 6062
			,@TrackingValue = @LogSPData
			,@duration = @Duration
	
	-- Check Delete IsTest = 0
	IF EXISTS(	SELECT TOP 1 1 
				FROM dbo.ProductLaunchedSiteCurrency plsc WITH(NOLOCK)
					INNER JOIN #File_Temp a on a.SiteID = plsc.SiteID  AND a.Currency = plsc.Currency 
								AND a.SportType = plsc.SportType   AND a.BetType = plsc.BetType
				WHERE 	plsc.IsTest = 0 			
			)
	BEGIN
		SELECT @ErrMsg = 'The IsTest of row(s) is Prod. Please update IsTest before deleting.!'
		,@ErrCode  = 101 
	END		
				
	DROP TABLE #File_Temp	
END
GO
