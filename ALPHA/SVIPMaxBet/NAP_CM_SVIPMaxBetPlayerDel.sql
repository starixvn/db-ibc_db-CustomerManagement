/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap,wsv_lap" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[NAP_CM_SVIPMaxBetPlayerDel] 
	  @CustIDs		VARCHAR(MAX)	=	''
	, @SportTypes	VARCHAR(300)	= '0'
	, @Bettypes 	VARCHAR(100)	= '0'
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
	exec NAP_CM_SVIPMaxBetPlayerDel 
	@CustIDs = '[{"CustID":148596221,"siteid":"909"},{"CustID":148596222,"siteid":"909"},{"CustID":148596223,"siteid":"909"},{"CustID":148596224,"siteid":"909"},{"CustID":148596225,"siteid":"909"}
				,{"CustID":148596226,"siteid":"909"},{"CustID":148596227,"siteid":"909"},{"CustID":148596228,"siteid":"909"},{"CustID":148596229,"siteid":"909"},{"CustID":148596230,"siteid":"909"}
				,{"CustID":148596231,"siteid":"909"},{"CustID":148596232,"siteid":"909"},{"CustID":148596233,"siteid":"909"},{"CustID":148596234,"siteid":"909"},{"CustID":148596235,"siteid":"909"}
				,{"CustID":148596236,"siteid":"909"},{"CustID":148596237,"siteid":"909"},{"CustID":148596238,"siteid":"909"},{"CustID":148596239,"siteid":"909"},{"CustID":148596240,"siteid":"909"}
				,{"CustID":148596241,"siteid":"909"},{"CustID":148596242,"siteid":"909"},{"CustID":148596243,"siteid":"909"},{"CustID":148596244,"siteid":"909"},{"CustID":148596245,"siteid":"909"}
				]', @SportTypes = '0', @Bettypes = '0', @Multiplier = 0, @IsTest = 1, @UserID = 8, @IP = '11.12.11.10' , @Note = ''
			,@ErrCode			= @ErrCode OUTPUT
			,@ErrMsg			= @ErrMsg OUTPUT
*/ 
BEGIN
	SET NOCOUNT ON;

	DECLARE @StartRun		DATETIME
		, @EndRun			DATETIME
		, @Duration			INT
		, @logSpData		NVARCHAR(MAX)
		, @logSpData_Old   NVARCHAR(MAX)
		, @xml				XML
	
	SET @StartRun=GETDATE()

	CREATE TABLE #tempCust(custid INT, siteid INT , SportType SMALLINT, Bettype SMALLINT)
	CREATE TABLE #tempLog(custid INT, siteid INT , SportType SMALLINT, Bettype SMALLINT, Note			NVARCHAR(1000), Multiplier	DECIMAL(9,2))
	CREATE CLUSTERED INDEX CIX_tempCust ON #tempCust(custid, siteid, SportType, Bettype)
	
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
	   
	IF EXISTS(SELECT TOP 1 1 FROM SVIPMaxBetPlayer a WITH(NOLOCK)
				 INNER JOIN #tempCust b ON a.siteid = b.siteid
					AND a.custid = b.custid AND a.SportType = b.SportType AND a.Bettype = b.Bettype AND a.IsTest <> @IsTest)
	BEGIN
		SELECT @ErrCode = 105 , @ErrMsg = 'Cannot Delete PROD data' 
		RETURN
	END	

	INSERT INTO #tempLog(SiteID, custid, SportType, Bettype, Note, Multiplier)
	SELECT mp.SiteID, mp.custid, mp.SportType, mp.Bettype, mp.Note, mp.Multiplier
	FROM #tempCust a
		CROSS APPLY (SELECT TOP 1 SiteID, custid, SportType, Bettype, Note, Multiplier 
					 FROM SVIPMaxBetPlayer WITH(NOLOCK)
					 WHERE siteid = a.siteid
					AND custid = a.custid AND SportType = a.SportType AND Bettype = a.Bettype) mp
	
	DELETE a 
	OUTPUT DELETED.SiteID, DELETED.custid, DELETED.SportType, DELETED.Bettype, [dbo].[f_GetDateTime2]() 
	INTO SVIPMaxBetPlayer_Del_InHouse(SiteID, custid, SportType, Bettype, RepUpdateTime )
	FROM SVIPMaxBetPlayer a WITH(ROWLOCK,UPDLOCK)
		CROSS APPLY (SELECT TOP 1 SiteID, custid, SportType, Bettype, Multiplier 
					 FROM #tempCust WITH(NOLOCK)
					 WHERE siteid = a.siteid
					AND custid = a.custid AND SportType = a.SportType AND Bettype = a.Bettype) mp

	INSERT INTO SVIPMaxBetHistory(SiteID, custid, SportType, Bettype, Multiplier, IsTest, [Action], LastModifiedUser, LastModifiedTime, RepUpdateTime)
	SELECT  SiteID, custid, SportType, Bettype, Multiplier AS Multiplier, 
			@IsTest AS IsTest, 'Delete' AS [Action], @UserID AS LastModifiedUser, GETDATE() AS LastModifiedTime, [dbo].[f_GetDateTime2]()
	FROM #tempLog

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
							cs.Note			AS '@Note',
							Multiplier 		AS '@Multiplier'
						FROM	#tempLog AS cs	
						ORDER BY cs.custid
						FOR XML PATH('SVIP'),
						TYPE
					)
			FOR XML PATH('R'),
			TYPE
		)
	SET @logSpData_Old = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')

	SELECT @EndRun	= GETDATE(), @Duration = DATEDIFF(MILLISECOND, @StartRun, @EndRun)

	EXEC  Acc_WriteLog_UserLog_RunSP_Wrapper
				@CustID  = @UserID,
				@UserID = @UserID,
				@ActionID = 31930,
			    @TrackingValue2 = @logSpData_Old,
				@duration = @Duration

	DROP TABLE #tempCust
	DROP TABLE #tempLog
END
GO
