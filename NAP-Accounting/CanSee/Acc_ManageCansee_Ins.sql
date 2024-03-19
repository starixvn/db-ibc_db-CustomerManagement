/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet,wsv_nap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_ManageCansee_Ins] 
	-- Add the parameters for the stored procedure here
	  @FileSetting	VARCHAR(MAX)
	, @UserID		INT
	, @IP			VARCHAR(50)		= ''
	, @ErrCode		INT				= 0		OUTPUT
	, @ErrMsg		NVARCHAR(200)	= ''	OUTPUT
AS
/*
	Task : NAP -  Manage ProductLaunchSiteCurrency - CanSee
	DB: DBCUST/CustDB
	Original: 
	Revisions:
		- 20200617@Winfred: NAP -  Manage ProductLaunchSiteCurrency / CanSee [Redmine: #131241]
		- 20221021@Tacy: NAP - Manage Product Setting - Enhance Can See function [Redmine: #178092]
		- 20221117@Tacy: HotFix - NAP - Manage Product Setting - CANSEE - Error when uploaded excel file [RedmineID: #180627]
		- 20230113@Tacy: Alpha/NAP - Split 789y Site [RedmineID: #181596]
		- 20230308@Tacy: NAP - Enhance CanSee (not allow: both site=0 and currency=0) [RedmineID: #183826]
*/
BEGIN
	SET NOCOUNT ON;
	
	--Check if XML is null or empty
	IF @FileSetting IS NULL OR @FileSetting = ''
		RETURN
		
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
		, @SportTypeErr NVARCHAR(10)
		, @CurrencyErr NVARCHAR(10)
		, @BetTypeErr NVARCHAR(10)
		, @SiteIDErr NVARCHAR(10)
			
	CREATE TABLE #Data_Input(
		ID	INT IDENTITY (1,1),
		SportType SMALLINT,
		Currency INT,
		BetType SMALLINT,
		SiteID INT,
		IsLaunched BIT,
		IsTest TINYINT,
		LaunchedLevel SMALLINT
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
	
	CREATE TABLE #Sports (SportType INT, SportName VARCHAR(50))
	
	INSERT INTO #Sports  (SportType, SportName)	
	EXEC DBACC.bodb02.dbo.Acc_SporttypeSel @Mode=1

	BEGIN TRY
		EXEC sp_xml_preparedocument @iDoc OUTPUT, @FileSetting
		INSERT #File_Temp(SportType,Currency,BetType,SiteID,IsLaunched,IsTest,LaunchedLevel)
		SELECT SportType,Currency,BetType,SiteID,IsLaunched,IsTest,LaunchedLevel
		FROM OPENXML(@iDoc,'/ROOT/File',1) WITH (
				SportType	NVARCHAR(MAX),
				Currency	NVARCHAR(MAX),
				BetType		NVARCHAR(MAX),
				SiteID		NVARCHAR(MAX),
				IsLaunched	NVARCHAR(MAX),
				IsTest		NVARCHAR(MAX),
				LaunchedLevel NVARCHAR(MAX)
			)
		EXEC sp_xml_removedocument @iDoc
	END TRY
	BEGIN CATCH
		SELECT  @ErrCode = ERROR_NUMBER(),@ErrMsg = ERROR_MESSAGE();		
		RETURN
	END CATCH
	-- Delete row null
	DELETE #File_Temp
	WHERE LEN(SportType)  = 0 AND LEN(Currency)  = 0 AND LEN(BetType)  = 0 AND LEN(SiteID)  = 0 AND 
		  LEN(IsLaunched)  = 0 AND LEN(IsTest)  = 0 AND LEN(LaunchedLevel)  = 0
	-- Check Simple Data 
	UPDATE 	#File_Temp
	SET		SportType		= CASE WHEN LEN(SportType)		= 0 THEN NULL ELSE SportType		END,
			BetType     	= CASE WHEN LEN(BetType)    	= 0 THEN NULL ELSE BetType      	END,
			Currency     	= CASE WHEN LEN(Currency)    	= 0 THEN NULL ELSE Currency      	END,
			SiteID	     	= CASE WHEN LEN(SiteID)		   	= 0 THEN NULL ELSE SiteID	      	END,
			IsLaunched     	= CASE WHEN LEN(IsLaunched)    	= 0 THEN NULL ELSE IsLaunched      	END,
			IsTest	     	= CASE WHEN LEN(IsTest)	    	= 0 THEN NULL ELSE IsTest	      	END,
			LaunchedLevel   = CASE WHEN LEN(LaunchedLevel)  = 0 THEN NULL ELSE LaunchedLevel  	END
	WHERE LEN(SportType)  = 0 OR LEN(Currency)  = 0 OR LEN(BetType)  = 0 OR LEN(SiteID)  = 0 OR 
		  LEN(IsLaunched)  = 0 OR LEN(IsTest)  = 0 OR LEN(LaunchedLevel)  = 0
	
	SELECT TOP(1) @MatrixError 	= CONVERT(VARCHAR(5),ID), 
	              @ValueError 	= CASE WHEN LaunchedLevel	IS  NULL OR LaunchedLevel	NOT IN (0,1) THEN ISNULL(LaunchedLevel,'NULL')
								  ELSE NULL END,
				  @ErrCode      = CASE WHEN LaunchedLevel	IS  NULL OR LaunchedLevel	NOT IN (0,1) THEN 1007									   
				                       ELSE 1008 END,
				  @ColumnName   = CASE WHEN LaunchedLevel	IS  NULL OR LaunchedLevel	NOT IN (0,1)	THEN 'LaunchedLevel'
									   WHEN IsTest			IS  NULL OR IsTest		NOT IN (0,1)		THEN 'IsTest'
									   WHEN IsLaunched		IS  NULL OR IsLaunched	NOT IN (0,1)		THEN 'IsLaunched'
									   WHEN SportType	IS  NULL OR ISNUMERIC(SportType) <> 1			THEN 'SportType'
									   WHEN BetType	IS  NULL OR ISNUMERIC(BetType)	 <> 1				THEN 'BetType'	
									   WHEN Currency	IS  NULL OR ISNUMERIC(Currency)	 <> 1			THEN 'Currency'
									   WHEN SiteID	IS  NULL OR ISNUMERIC(SiteID)	 <> 1				THEN 'SiteID'
								  ELSE NULL END
	FROM #File_Temp a
	WHERE   IsTest			IS  NULL OR IsTest			NOT IN (0,1) 
			OR IsLaunched		IS  NULL OR IsLaunched		NOT IN (0,1) 
			OR LaunchedLevel	IS  NULL OR LaunchedLevel	NOT IN (0,1) 
			OR SportType	IS  NULL OR ISNUMERIC(SportType) <> 1
		    OR BetType	IS  NULL OR ISNUMERIC(BetType)	 <> 1
		    OR Currency	IS  NULL OR ISNUMERIC(Currency)	 <> 1
		    OR SiteID	IS  NULL OR ISNUMERIC(SiteID)	 <> 1
	
	IF @ErrCode <> 0
	   BEGIN
	     IF @ErrCode = 1007
		 SELECT  @ErrMsg = 'Invalid "' + @ColumnName + ' : '+ ISNULL(@ValueError,'')  +'" on row "' + ISNULL(@MatrixError,'') + '".Please check them again.'  
		 IF @ErrCode = 1008
		  SELECT @ErrMsg = 'Invalid "' + @ColumnName + '" on row "' + @MatrixError + '".Please check them again.'  

	     RETURN
	  END
	
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
	--Check SportType, Currency, BetType, SiteID
	SELECT TOP(1) @MatrixError 	= CONVERT(VARCHAR(5),I.ID),
			@ErrCode = 1007,
			@ValueError = CASE WHEN s.SportType		IS NULL THEN i.SportType
							   WHEN b.typeid		IS NULL THEN i.BetType
							   WHEN p.SiteID		IS NULL AND i.SiteID <> 0 THEN i.SiteID
						  ELSE i.Currency END,

			@ColumnName = CASE WHEN s.SportType		IS NULL THEN 'Sporttype'
			                   WHEN b.typeid		IS NULL THEN 'Bettype'
							   WHEN p.SiteID		IS NULL AND i.SiteID <> 0 THEN 'SiteID'
						  ELSE 'Currency' END
	FROM #Data_Input i
	     LEFT JOIN #Sports s		WITH(NOLOCK) ON s.SportType = i.SportType
		 LEFT JOIN #Bettype b	WITH(NOLOCK) ON b.typeid = i.BetType
		 LEFT JOIN [Site] p	WITH(NOLOCK) ON p.SiteID = i.SiteID
		 LEFT JOIN exchange bg	WITH(NOLOCK) ON bg.exchangeid = i.Currency
	WHERE s.SportType		IS NULL 
		OR b.typeid			IS NULL 
		OR (p.SiteID		IS NULL AND i.SiteID <> 0)
		OR (bg.exchangeid IS NULL AND i.Currency <> 0)

	IF @ErrCode <> 0
	BEGIN
		SELECT @ErrMsg = 'Row "' + ISNULL(@MatrixError,'') + '" - ' + @ColumnName + ' = "' + ISNULL(@ValueError,'') + '" does not exist.'
		RETURN
	END
	
	--Check SiteID: isActive???
	SELECT TOP(1) @MatrixError 	= CONVERT(VARCHAR(5),I.ID),
			@ErrCode = 1006,
			@ValueError = s.siteid,
			@ColumnName = 'SiteID'
	FROM #Data_Input i
		 INNER JOIN [Site] s WITH(NOLOCK) ON s.SiteID = i.SiteID
	WHERE s.isActive=0

	IF @ErrCode <> 0
	BEGIN
		SELECT @ErrMsg = 'Row "' + ISNULL(@MatrixError,'') + '" - ' + @ColumnName + ' = "' + ISNULL(@ValueError,'') + '" is inactivated.'
		RETURN
	END

	SELECT TOP(1) @MatrixError 	= CONVERT(VARCHAR(5),I.ID), 
	              @ValueError 	= CASE  WHEN i.BetType >= 19999 THEN i.BetType
										ELSE i.IsLaunched END ,
				  @ErrCode      = CASE	WHEN i.BetType >= 19999 THEN 1009
										ELSE 1010	END				  
	FROM #Data_Input i
	WHERE i.BetType >= 19999 OR i.IsLaunched = 0
	
	IF @ErrCode <> 0
	   BEGIN
	     IF @ErrCode = 1009
		 SELECT @ErrMsg = 'BetType must be less than 19999 on row "' + @MatrixError + '".'
		 IF @ErrCode = 1010 
		 SELECT @ErrMsg = 'Row "' + @MatrixError +'" - The value of IsLaunched must be different from 0.'	                              
	     RETURN
	   END
	
	SELECT @MatrixError = STUFF((
		SELECT ',' + CAST(KQ.ID AS NVARCHAR(5)) + ''
		FROM (
			SELECT DISTINCT I.ID
			FROM #Data_Input i
			LEFT JOIN #Data_Input p ON i.SiteID = p.SiteID  AND i.Currency = p.Currency 
							AND i.SportType = p.SportType   AND i.BetType = p.BetType
			LEFT JOIN ProductLaunchedSiteCurrency q ON i.SiteID = q.SiteID  AND i.Currency = q.Currency 
							AND i.SportType = q.SportType   AND i.BetType = q.BetType				
			WHERE (q.SiteID IS NOT NULL) OR (I.ID <> p.ID)
			 ) KQ
			 ORDER BY KQ.ID
            FOR XML PATH('')
         ), 1, 1, '')
         
	IF ISNULL(@MatrixError,'') <> ''
		SET  @ErrCode     = 1011
	
	SET @MatrixError =  REPLACE(@MatrixError, ',', '>,<');
	IF @ErrCode <> 0
	BEGIN 
		SELECT @ErrMsg = 'Row <' + @MatrixError +'> : SiteID - Currency  - SportType  - BetType of rows cannot be same.'	
	    RETURN
	END  
	   
	--Check if: both currency=0 and siteID=0:
    SELECT TOP(1) @MatrixError = CONVERT(VARCHAR(5),I.ID),
                  @ErrCode = 1012
    FROM #Data_Input i
    WHERE i.Currency=0 and i.SiteID=0

    IF @ErrCode <> 0
    BEGIN
            SELECT @ErrMsg = 'Row <' + @MatrixError +'> : The value of SiteID and Currency must be different from 0.'
            RETURN
    END

	SELECT  @RowTotal = COUNT(*) FROM #Data_Input	
	WHILE @CurrentRow <> @RowTotal
	BEGIN
		SELECT @CurrentRow= @CurrentRow + 1, @startRun = GETDATE()
		BEGIN TRY
			INSERT INTO ProductLaunchedSiteCurrency (SiteID,Currency,SportType,IsLaunched,IsTest,BetType,LaunchedLevel)
			SELECT SiteID,Currency,SportType,IsLaunched,IsTest,BetType,LaunchedLevel
			FROM #Data_Input
			WHERE ID = @CurrentRow
			
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
							'IP="'+ COALESCE(CAST(@IP as VARCHAR(20)),SPACE(1)) + '" />'
		FROM #Data_Input
		WHERE ID = @CurrentRow

		SELECT @EndRun	= GETDATE(), @Duration = DATEDIFF(MILLISECOND, @StartRun, @EndRun)

		EXEC  Acc_WriteLog_UserLog_RunSP_Wrapper
				@UserID = @UserID,
				@ActionID = 6060,
				@TrackingValue = @LogSPData,
				@duration = @Duration
	END
	DROP TABLE #Bettype,#Sports,#Data_Input,#File_Temp
END
GO
