/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
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
		DB: DBCUST/CustDB
		Original: 
		Revisions:
			- 20200617@Winfred: NAP -  Manage ProductLaunchSiteCurrency / CanSee [Redmine: #131241]
	*/
	SET NOCOUNT ON;
	--SportType,BetType,Currency,SiteID,IsLaunched,IsTest,LaunchedLevel
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
		INSERT #File_Temp(SportType,Currency,BetType,SiteID,IsLaunched,IsTest,LaunchedLevel)
		SELECT SportType,Currency,BetType,SiteID,IsLaunched,IsTest,LaunchedLevel
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
		FROM dbo.ProductLaunchedSiteCurrency plsc
			INNER JOIN #File_Temp a on a.SiteID = plsc.SiteID  AND a.Currency = plsc.Currency 
						AND a.SportType = plsc.SportType   AND a.BetType = plsc.BetType
						--AND a.LaunchedLevel = plsc.LaunchedLevel
		WHERE 	plsc.IsTest = 1	
				
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
				FROM dbo.ProductLaunchedSiteCurrency plsc
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
