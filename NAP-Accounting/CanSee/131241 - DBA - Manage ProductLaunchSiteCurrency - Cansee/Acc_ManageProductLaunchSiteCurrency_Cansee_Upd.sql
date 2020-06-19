/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[Acc_ManageProductLaunchSiteCurrency_Cansee_Upd] 
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
			- 20200617@Winfred: NAP -  Manage ProductLaunchSiteCurrency / CanSee [[Redmine: #131241]]
	*/
	SET NOCOUNT ON;
	--SportType,BetType,Currency,SiteID,IsLaunched,IsTest,LaunchedLevel
	DECLARE @StartRun	DATETIME
		, @EndRun		DATETIME
		, @Duration		INT
		, @iDoc			INT
		, @logSpData		 NVARCHAR(MAX)
		, @logSpData_Old   NVARCHAR(MAX)
		, @xml			 XML
		, @MatrixError NVARCHAR(MAX) = ''
		, @ValueError NVARCHAR(MAX) = ''
		, @ColumnName NVARCHAR(200)
		, @RowTotal INT = 0
		, @CurrentRow INT = 0
			
	CREATE TABLE #Data_Input(
		ID	INT IDENTITY (1,1),
		SportType INT,
		Currency INT,
		BetType INT,
		SiteID INT,
		IsLaunched BIT,
		IsTest INT,
		LaunchedLevel INT
	)	
		
	CREATE TABLE #File_Temp(
		ID	INT IDENTITY (1,1),
		SportType		NVARCHAR(MAX),
		Currency		NVARCHAR(MAX),
		BetType			NVARCHAR(MAX),
		SiteID			NVARCHAR(MAX),
		IsLaunched		NVARCHAR(MAX),
		IsTest			NVARCHAR(MAX),
		LaunchedLevel	NVARCHAR(MAX)
	)
	
	CREATE TABLE #Bettype (typeid INT , typenamee NVARCHAR(128))
	INSERT INTO #Bettype  (typeid,typenamee)	
	SELECT typeid,typenamee 
	FROM DBACC.bodb02.dbo.Bettype WITH(NOLOCK)
	
	CREATE TABLE #Sports (SportType INT )
	INSERT INTO #Sports  (SportType)	
	SELECT SportType 
	FROM DBACC.bodb02.dbo.Sports WITH(NOLOCK)
	
	--Check if XML is null or empty
	IF @FileSetting IS NULL OR @FileSetting = ''
		RETURN
	BEGIN TRY
		EXEC sp_xml_preparedocument @iDoc OUTPUT, @FileSetting
		INSERT #File_Temp(SportType,Currency,BetType,SiteID,IsLaunched,IsTest,LaunchedLevel)
		SELECT SportType,Currency,BetType,SiteID,IsLaunched,IsTest,LaunchedLevel
		FROM OPENXML(@iDoc,'/ROOT/File',1) WITH (
				SportType NVARCHAR(MAX),
				Currency  NVARCHAR(MAX),
				BetType   NVARCHAR(MAX)	,
				SiteID    NVARCHAR(MAX),
				IsLaunched NVARCHAR(MAX),
				IsTest NVARCHAR(MAX),
				LaunchedLevel NVARCHAR(MAX)
			)
		EXEC sp_xml_removedocument @iDoc
	END TRY
	BEGIN CATCH
		SELECT  @ErrCode = ERROR_NUMBER(),@ErrMsg = ERROR_MESSAGE();		
		RETURN
	END CATCH
	
	BEGIN TRY
		INSERT INTO #Data_Input
		(	SportType	,
			Currency	,
			BetType		,
			SiteID		,
			IsLaunched	,
			IsTest		,
			LaunchedLevel
		)
		SELECT 
			SportType	,
			Currency	,
			BetType		,
			SiteID		,
			IsLaunched	,
			IsTest		,
			LaunchedLevel
		FROM #File_Temp
	END TRY
	BEGIN CATCH
	    SELECT @ErrCode = ERROR_NUMBER(), @ErrMsg = ERROR_MESSAGE()
		RETURN
	END CATCH
		
	SELECT TOP(1) @MatrixError 	= CONVERT(VARCHAR(5),I.ID), 
	              @ValueError 	= CASE  WHEN i.BetType >= 19999 THEN i.BetType							   
								  ELSE p.ID END ,
				  @ErrCode      = CASE	WHEN i.BetType >= 19999 THEN 1009								   
								  ELSE 1011 END
	FROM #Data_Input i
		INNER JOIN #Data_Input p ON i.SiteID = p.SiteID  AND i.Currency = p.Currency 
						AND i.SportType = p.SportType   AND i.BetType = p.BetType
	WHERE i.BetType >= 19999 OR I.ID <> p.ID
	
	IF @ErrCode <> 0
	   BEGIN
	     IF @ErrCode = 1009
		 SELECT @ErrMsg = 'BetType must be less than 19999 on row "' + @MatrixError + '".'	                              
		 IF @ErrCode = 1011 
		 SELECT @ErrMsg = 'Row "' + @MatrixError +'"  does not Double ( ' + @ValueError +').'	
	     RETURN
	   END
		
	SELECT  @RowTotal = COUNT(*) FROM #Data_Input	
	WHILE @CurrentRow <> @RowTotal
	BEGIN
		SELECT @CurrentRow= @CurrentRow + 1, @startRun = GETDATE()
		
		SELECT @logSpData_Old = '<R SiteID="'+ COALESCE(CAST(p.SiteID AS VARCHAR(10)), SPACE(1)) + '" ' +
		                    'Currency="' + COALESCE(CAST(p.Currency  AS VARCHAR(10)), SPACE(1)) + '" ' +
		                    'SportType="' + COALESCE(CAST(p.SportType   AS VARCHAR(10)), SPACE(1)) + '" ' +
							'BetType="' + COALESCE(CAST(p.BetType  AS VARCHAR(10)), SPACE(1)) + '" ' +
							'IsLaunched="' + COALESCE(CAST(p.IsLaunched  AS VARCHAR(2)), SPACE(1)) + '" ' +
							'IsTest="' + COALESCE(CAST(p.IsTest  AS VARCHAR(2)), SPACE(1)) + '" ' +							
							'LaunchedLevel="' + COALESCE(CAST(p.LaunchedLevel  AS VARCHAR(2)), SPACE(1)) + '" ' +	
							'LoginIP="'+ COALESCE(CAST(@IP as VARCHAR(20)),SPACE(1)) + '" />'
		FROM ProductLaunchedSiteCurrency p WITH(NOLOCK)
			INNER JOIN #Data_Input i on i.SiteID = p.SiteID  AND i.Currency = p.Currency 
						AND i.SportType = p.SportType   AND i.BetType = p.BetType
		WHERE i.ID = @CurrentRow				
		
		BEGIN TRY
			UPDATE p
			SET 
				P.IsTest = i.IsTest,
				P.IsLaunched = i.IsLaunched,
				p.LaunchedLevel = i.LaunchedLevel
			FROM ProductLaunchedSiteCurrency p
			INNER JOIN #Data_Input i on i.SiteID = p.SiteID  AND i.Currency = p.Currency 
						AND i.SportType = p.SportType   AND i.BetType = p.BetType
			WHERE i.ID = @CurrentRow
		END TRY
		BEGIN CATCH
			SELECT  @ErrCode = ERROR_NUMBER(),@ErrMsg = ERROR_MESSAGE()
			RETURN
		END CATCH
		
		SELECT @LogSPData = '<R SiteID="'+ COALESCE(CAST(SiteID AS VARCHAR(10)), SPACE(1)) + '" ' +
		                    'Currency="' + COALESCE(CAST(Currency  AS VARCHAR(10)), SPACE(1)) + '" ' +
		                    'SportType="' + COALESCE(CAST(SportType   AS VARCHAR(10)), SPACE(1)) + '" ' +
							'BetType="' + COALESCE(CAST(BetType  AS VARCHAR(10)), SPACE(1)) + '" ' +
							'IsLaunched="' + COALESCE(CAST(IsLaunched  AS VARCHAR(2)), SPACE(1)) + '" ' +
							'IsTest="' + COALESCE(CAST(IsTest  AS VARCHAR(2)), SPACE(1)) + '" ' +							
							'LaunchedLevel="' + COALESCE(CAST(LaunchedLevel  AS VARCHAR(2)), SPACE(1)) + '" ' +	
							'LoginIP="'+ COALESCE(CAST(@IP as VARCHAR(20)),SPACE(1)) + '" />'
		FROM #Data_Input
		WHERE ID = @CurrentRow

		SELECT @EndRun	= GETDATE(), @Duration = DATEDIFF(MILLISECOND, @StartRun, @EndRun)

		EXEC  DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
				@UserID = @UserID,
				@ActionID = 95023,
				@TrackingValue = @LogSPData,
				@TrackingValue2 = @logSpData_Old,
				@duration = @Duration
		
	END
	DROP TABLE #Bettype,#Sports,#Data_Input,#File_Temp
END
GO
