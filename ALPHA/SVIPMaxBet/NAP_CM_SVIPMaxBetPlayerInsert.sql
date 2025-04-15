/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap,wsv_lap" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[NAP_CM_SVIPMaxBetPlayerInsert] 
	  @CustIDs		VARCHAR(MAX)	=	''
	, @SportTypes	VARCHAR(300)	= '0'
	, @Bettypes 	VARCHAR(100)	= '0'
	, @Multiplier	DECIMAL(9,2)	= 1
	, @Note			NVARCHAR(1000)  = ''
	, @UserID		INT				= 0
	, @IsTest		TINYINT			= 0
	, @IP			VARCHAR(50)		= ''
	, @ErrCode		TINYINT			= 0  OUTPUT
	, @ErrMsg		NVARCHAR(MAX)	= '' OUTPUT
AS
/*
	Created: Winfred
	Date: 20250224
	Task : [NAP CM] Customer - Increase Bet Limit
	DB: DBCUST/CustDB
	Original:

	Revisions:
		- 20250224@Winfred: [NAP CM] Customer - Increase Bet Limit [RedmineID: #218073] 
		- 20250301@Winfred: [NAP CM] Customer - Increase Bet Limit - Apply Inhouse replication [RedmineID: #220294] 

	Param's Explanation:
	Sample Format Json:
	exec NAP_CM_SVIPMaxBetPlayerInsert 
	@CustIDs = '[{"CustID":"148596221","siteid":"909"},{"CustID":"148596222","siteid":"909"},{"CustID":"148596223","siteid":"909"},{"CustID":"148596224","siteid":"909"},{"CustID":"148596225","siteid":"909"}
				,{"CustID":"148596226","siteid":"909"},{"CustID":"148596227","siteid":"909"},{"CustID":"148596228","siteid":"909"},{"CustID":"148596229","siteid":"909"},{"CustID":"148596230","siteid":"909"}
				,{"CustID":"148596231","siteid":"909"},{"CustID":"148596232","siteid":"909"},{"CustID":"148596233","siteid":"909"},{"CustID":"148596234","siteid":"909"},{"CustID":"148596235","siteid":"909"}
				,{"CustID":"148596236","siteid":"909"},{"CustID":"148596237","siteid":"909"},{"CustID":"148596238","siteid":"909"},{"CustID":"148596239","siteid":"909"},{"CustID":"148596240","siteid":"909"}
				,{"CustID":"148596241","siteid":"909"},{"CustID":"148596242","siteid":"909"},{"CustID":"148596243","siteid":"909"},{"CustID":"148596244","siteid":"909"},{"CustID":"148596245","siteid":"909"}
				]', @SportTypes = '0', @Bettypes = '0', @Multiplier = 0, @IsTest = 1, @UserID = 8, @IP = '11.12.11.10' , @Note = ''
			,@ErrCode			= @ErrCode OUTPUT
			,@ErrMsg			= @ErrMsg OUTPUT
*/ 
BEGIN
	SET NOCOUNT ON;

	DECLARE @StartRun	  DATETIME
		, @EndRun		  DATETIME
		, @Duration		  INT
		, @logSpData	  NVARCHAR(MAX)
		, @xml			  XML
	
	SET @StartRun=GETDATE()

	CREATE TABLE #tempCust(custid INT, siteid INT , SportType SMALLINT, Bettype SMALLINT)
	
	BEGIN TRY
		INSERT INTO #tempCust(CustID,siteid,SportType, Bettype)
		SELECT CustID, siteid, s.SportType , b.Bettype
		FROM OPENJSON(@CustIDs) WITH (
						 CustID	INT '$.CustID'
						,siteid	INT	'$.siteid'
					)
			CROSS APPLY ( SELECT VALUE AS SportType FROM STRING_SPLIT(@SportTypes,',') WHERE VALUE <> '' ) s  
			CROSS APPLY ( SELECT VALUE AS Bettype FROM STRING_SPLIT(@Bettypes,',') WHERE VALUE <> '' ) b
	END TRY
	BEGIN CATCH
		SELECT  @ErrMsg = N'Invalid Json Input'	, @ErrCode = 101 ;	
		RETURN
	END CATCH

	INSERT INTO SVIPMaxBetPlayer(SiteID, custid, SportType, Bettype, Multiplier, Note, IsTest, LastModifiedUser, LastModifiedTime, RepUpdateTime)
	SELECT  SiteID, custid, SportType, Bettype, @Multiplier AS Multiplier, 
			@Note AS Note, @IsTest AS IsTest, @UserID AS LastModifiedUser, GETDATE() AS LastModifiedTime, [dbo].[f_GetDateTime2]()
	FROM #tempCust

	INSERT INTO SVIPMaxBetHistory(SiteID, custid, SportType, Bettype, Multiplier, IsTest, [Action], LastModifiedUser, LastModifiedTime, RepUpdateTime)
	SELECT  SiteID, custid, SportType, Bettype, @Multiplier AS Multiplier, 
			@IsTest AS IsTest, 'Insert' AS [Action], @UserID AS LastModifiedUser, GETDATE() AS LastModifiedTime, [dbo].[f_GetDateTime2]()
	FROM #tempCust

	-- Log new updated data
	SET @xml = (
			SELECT	@UserID					AS '@UserID',				
					@IP						AS '@IP',							
					@IsTest					AS '@IsTest',	
					COALESCE(CAST(@ErrMsg	AS VARCHAR(400)),SPACE(1))	AS '@ErrMsg',
					COALESCE(CAST(@ErrCode	AS VARCHAR(50)),SPACE(1))	AS '@ErrCode',
					(
						SELECT DISTINCT 
							cs.SiteID		AS '@SiteID',
							cs.custid		AS '@custid',
							cs.SportType	AS '@SportType',
							cs.Bettype		AS '@Bettype',					
							@Note			AS '@Note',	
							@Multiplier 	AS '@Multiplier'
						FROM	#tempCust AS cs	
						ORDER BY cs.custid
						FOR XML PATH('SVIP'),
						TYPE
					)
			FOR XML PATH('R'),
			TYPE
		)
	SET @logSpData = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')

	SELECT @EndRun	= GETDATE(), @Duration = DATEDIFF(MILLISECOND, @StartRun, @EndRun)

	EXEC  Acc_WriteLog_UserLog_RunSP_Wrapper
				@CustID  = @UserID,
				@UserID = @UserID,
				@ActionID = 31928,
				@TrackingValue = @LogSPData,
				@duration = @Duration

	DROP TABLE #tempCust
END
GO
