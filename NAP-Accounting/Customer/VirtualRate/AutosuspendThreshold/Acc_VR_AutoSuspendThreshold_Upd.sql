/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_VR_AutoSuspendThreshold_Upd]
	  @SportType		INT = 43
	, @XML				VARCHAR(MAX)
	, @UserID			INT
	, @IP				VARCHAR(50)		= ''
	, @ErrCode			INT				= 0		OUTPUT
	, @ErrMsg			NVARCHAR(MAX)	= ''	OUTPUT
AS
/*    
	Created: 20200305@Eden    
	Task :  Update Global AutoSuspendThreshold
	DB: CustDB/DBCUST
	    
	Revisions:    
		- 20200305@Eden : First commit [Redmind: #128749]

	Param's Explanation:
	•	@XML = 
			'<Root>
						<Row LevelID = "15" VRAutoSuspendThresholdLive="1.00" VRAutoSuspendThresholdNonLive="2.00"/>
						<Row LevelID = "17" VRAutoSuspendThresholdLive="1.00" VRAutoSuspendThresholdNonLive="2.00"/>
			</Root>'
	
	• Example :
		DECLARE  @ErrCode INT = 0, @ErrMsg NVARCHAR(MAX) = ''	
		EXEC [Acc_VR_AutoSuspendThreshold_Upd]
			@UserID = 8,
			@IP = '10.1.1.0',
			@XML = 
			'<Root>
						<Row LevelID = "5" VRAutoSuspendThresholdLive="1.00" VRAutoSuspendThresholdNonLive="2.00"/>
						<Row LevelID = "7" VRAutoSuspendThresholdLive="1.00" VRAutoSuspendThresholdNonLive="2.00"/>
			</Root>'
			,@ErrCode = @ErrCode OUTPUT
			,@ErrMsg = @ErrMsg OUTPUT

		SELECT @ErrCode,@ErrMsg
  
*/ 
BEGIN
	DECLARE @StartRun DATETIME  
	DECLARE @EndRun DATETIME  
	DECLARE @Duration INT 
	DECLARE @ActionID INT = 811
	DECLARE @TrackingValue1 VARCHAR(MAX) = '' -- New values
			,@TrackingValue2 VARCHAR(MAX)= '' -- Old values

	SELECT @ErrCode = 0, @ErrMsg = ''
	
	CREATE TABLE #NewAutoSuspendThresholdTbl (
		  LevelID					SMALLINT
		, VRAutoSuspendThresholdLive	SMALLMONEY
		, VRAutoSuspendThresholdNonLive	SMALLMONEY
		)

	SELECT @StartRun = GETDATE()   

	DECLARE @iDoc INT

	BEGIN TRY
		EXEC sp_xml_preparedocument @iDoc OUTPUT
			, @XML

		INSERT INTO #NewAutoSuspendThresholdTbl
		SELECT *
		FROM OPENXML(@iDoc, '/Root/Row', 1) WITH (
				  LevelID					SMALLINT
				, VRAutoSuspendThresholdLive	SMALLMONEY
				, VRAutoSuspendThresholdNonLive	SMALLMONEY
				)
	
		EXEC sp_xml_removedocument @iDoc
	END TRY
	BEGIN CATCH
		SELECT @ErrMsg = N'Invalid XML format'
			, @ErrCode = 3  
		RETURN  
	END CATCH

	DELETE tmp
	FROM #NewAutoSuspendThresholdTbl tmp 
		INNER JOIN VRSettingHierarchy h WITH(NOLOCK) ON tmp.LevelID = h.LevelID
	WHERE h.VRAutoSuspendThresholdLive = tmp.VRAutoSuspendThresholdLive
		AND h.VRAutoSuspendThresholdNonLive = tmp.VRAutoSuspendThresholdNonLive

	IF NOT EXISTS( SELECT TOP 1 1 FROM #NewAutoSuspendThresholdTbl)
	BEGIN
		RETURN --no changed
	END

	--Old values
	SELECT @TrackingValue2 = (
		SELECT tmp.LevelID, 
			   h.SportType, 
			   lg.GroupName LeagueGroup,
			   bg.GroupName BettypeGroup,
			   h.BetType,
			   h.VRAutoSuspendThresholdLive,
			   h.VRAutoSuspendThresholdNonLive,
			   h.SortOrder
		FROM #NewAutoSuspendThresholdTbl tmp
			 INNER JOIN VRSettingHierarchy h WITH(NOLOCK)
			   ON tmp.LevelID = h.LevelID
			 LEFT JOIN VRLeagueGroup lg WITH(NOLOCK) ON h.VRLeagueGroupID = lg.GroupID
			 LEFT JOIN VRBettypeGroup bg WITH(NOLOCK) ON h.VRBetTypeGroupID = bg.GroupID
	FOR XML  RAW('r')
	)

	SELECT @TrackingValue2 = '<Root>' + ISNULL(@TrackingValue2,'') + '</Root>'
	
	UPDATE h
	SET h.VRAutoSuspendThresholdLive = tmp.VRAutoSuspendThresholdLive,
		h.VRAutoSuspendThresholdNonLive = tmp.VRAutoSuspendThresholdNonLive
	FROM #NewAutoSuspendThresholdTbl tmp 
		INNER JOIN VRSettingHierarchy h WITH(ROWLOCK) ON tmp.LevelID = h.LevelID
	
	--New values
	SELECT @TrackingValue1 = (
		SELECT tmp.LevelID, 
			   h.SportType, 
			   lg.GroupName LeagueGroup,
			   bg.GroupName BettypeGroup,
			   h.BetType,
			   h.VRAutoSuspendThresholdLive,
			   h.VRAutoSuspendThresholdNonLive,
			   h.SortOrder
		FROM #NewAutoSuspendThresholdTbl tmp
			 INNER JOIN VRSettingHierarchy h WITH(NOLOCK)
			   ON tmp.LevelID = h.LevelID
			 LEFT JOIN VRLeagueGroup lg WITH(NOLOCK) ON h.VRLeagueGroupID = lg.GroupID
			 LEFT JOIN VRBettypeGroup bg WITH(NOLOCK) ON h.VRBetTypeGroupID = bg.GroupID
	FOR XML  RAW('r')
	)

	SELECT @TrackingValue1 = '<Root>' + ISNULL(@TrackingValue1,'') + '</Root>'

	SELECT @EndRun = GETDATE()    
	SELECT @Duration  = DATEDIFF (MILLISECOND,@startRun,@endRun)

	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.[Writelog_VirtualRate_UpdateSetting] @CustID=0
						,@SportType=@SportType
						,@ActionID=@ActionID
						,@TrackingValue1=@TrackingValue1
						,@TrackingValue2=@TrackingValue2
						,@WithCompression = 1
						,@UserID=@UserID
						,@LogTime=@StartRun
						,@Duration=@Duration
						,@IP=@IP
	END TRY  
	BEGIN CATCH
		EXEC bodb_CustomerLog.dbo.[Writelog_VirtualRate_UpdateSetting] @CustID=0
						,@SportType=@SportType
						,@ActionID=@ActionID
						,@TrackingValue1=@TrackingValue1
						,@TrackingValue2=@TrackingValue2
						,@WithCompression = 0
						,@UserID=@UserID
						,@LogTime=@StartRun
						,@Duration=@Duration
						,@IP=@IP
	END CATCH

	DROP TABLE #NewAutoSuspendThresholdTbl   
END