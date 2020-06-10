/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustVirtualMultiplier_AutoSuspendUpd]
	  @CustID			INT
	, @SportType		INT = 43
	, @AutoSuspendXML	VARCHAR(MAX)
	, @UserID			INT
	, @IP				VARCHAR(50)		= ''
	, @ErrCode			INT				= 0		OUTPUT
	, @ErrMsg			NVARCHAR(MAX)	= ''	OUTPUT
AS
/*    
	Created: 20191025@Eden    
	Task :  Update AutoSuspend status
	DB: CustDB@DBCUST;;;
	    
	Revisions:    
		- 20191025@Eden : First commit [Redmind: #121876]
		- 20200610@Eden: Virtual Rate for Basketball [Redmine: #134978] 

	Param's Explanation:
	• @AutoSuspendXML
		<Root>
				<Row LevelID = "15" IsLiveAutoSuspend="0" IsNonLiveAutoSuspend="1"/>
		</Root>
	
	• Example :
		DECLARE  @ErrCode INT = 0, @ErrMsg NVARCHAR(MAX) = ''	
		EXEC Acc_CustVirtualMultiplier_AutoSuspendUpd
			@CustID = 1176092,
			@UserID = 8,
			@IP = '10.1.1.0',
			@AutoSuspendXML = 
			'<Root>
						<Row LevelID = "15" IsLiveAutoSuspend="0" IsNonLiveAutoSuspend="0"/>
						<Row LevelID = "17" IsLiveAutoSuspend="0" IsNonLiveAutoSuspend="0"/>
						<Row LevelID = "21" IsLiveAutoSuspend="0" IsNonLiveAutoSuspend="1"/>
						<Row LevelID = "22" IsLiveAutoSuspend="0" IsNonLiveAutoSuspend="1"/>
						<Row LevelID = "24" IsLiveAutoSuspend="0" IsNonLiveAutoSuspend="0"/>
						<Row LevelID = "25" IsLiveAutoSuspend="0" IsNonLiveAutoSuspend="1"/>
			</Root>'
			,@ErrCode = @ErrCode OUTPUT
			,@ErrMsg = @ErrMsg OUTPUT

		SELECT @ErrCode,@ErrMsg
  
*/ 
BEGIN
	DECLARE @StartRun DATETIME  
	DECLARE @EndRun DATETIME  
	DECLARE @Duration INT 
	DECLARE @ActionID INT = 809
	DECLARE @TrackingValue1 VARCHAR(MAX) = '' -- New values
			,@TrackingValue2 VARCHAR(MAX)= '' -- Old values

	SELECT @ErrCode = 0, @ErrMsg = ''
	
	CREATE TABLE #NewDisableStatTbl (
		  LevelID				SMALLINT
		, IsLiveAutoSuspend		BIT
		, IsNonLiveAutoSuspend	BIT
		)

	SELECT @StartRun = GETDATE()   


	IF EXISTS(SELECT TOP 1 1 FROM Custinfo WITH(NOLOCK) WHERE custid = @CustID and roleid <> 1)
		RETURN

	DECLARE @iDoc INT

	BEGIN TRY
		EXEC sp_xml_preparedocument @iDoc OUTPUT
			, @AutoSuspendXML

		INSERT INTO #NewDisableStatTbl
		SELECT *
		FROM OPENXML(@iDoc, '/Root/Row', 1) WITH (
				  LevelID					SMALLINT
				, IsLiveAutoSuspend			BIT
				, IsNonLiveAutoSuspend		BIT
				)
	
		EXEC sp_xml_removedocument @iDoc
	END TRY
	BEGIN CATCH
		SELECT @ErrMsg = N'Invalid XML format'
			, @ErrCode = 3  
		RETURN  
	END CATCH


	SELECT DISTINCT h.LevelID
		,h.BetType
		,dbo.f_GetProductStatus(at.AutoSuspendLive,h.BitmapOrderAutoSuspend) as IsLiveAutoSuspend
		,dbo.f_GetProductStatus(at.AutoSuspendNonLive,h.BitmapOrderAutoSuspend) as IsNonLiveAutoSuspend
	INTO #temp
	FROM #NewDisableStatTbl tmp 
		INNER JOIN VRSettingHierarchy h WITH(NOLOCK) ON tmp.LevelID = h.LevelID
			OUTER APPLY ( SELECT AutoSuspendLive, AutoSuspendNonLive FROM dbo.CustSettingAutoSuspend WITH(NOLOCK) WHERE custid = @CustID AND SportType = @SportType) at

	CREATE CLUSTERED INDEX PK_temp_LevelID ON #temp(LevelID)

	DELETE a
	FROM #NewDisableStatTbl a
		INNER JOIN #temp tmp  ON a.LevelID = tmp.LevelID
	WHERE tmp.BetType = -1 
		OR (ISNULL(a.IsLiveAutoSuspend,tmp.IsLiveAutoSuspend) = tmp.IsLiveAutoSuspend AND ISNULL(a.IsNonLiveAutoSuspend, tmp.IsNonLiveAutoSuspend)  = tmp.IsNonLiveAutoSuspend)

	UPDATE a
	SET  a.IsLiveAutoSuspend = ISNULL(a.IsLiveAutoSuspend,tmp.IsLiveAutoSuspend)
		,a.IsNonLiveAutoSuspend = ISNULL(a.IsNonLiveAutoSuspend,tmp.IsNonLiveAutoSuspend)
	FROM #NewDisableStatTbl a
		INNER JOIN #temp tmp  ON a.LevelID = tmp.LevelID
	
	IF NOT EXISTS( SELECT TOP 1 1 FROM #NewDisableStatTbl)
	BEGIN
		RETURN --no changed
	END

	DECLARE @xmlStrAutoSuspendLive XML
	DECLARE @xmlStrAutoSuspendNonLive XML
	DECLARE @InitialBitMap VARBINARY(30) = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
	
	SET @xmlStrAutoSuspendLive =(
			SELECT (
					SELECT h.BitmapOrderAutoSuspend	AS '@b'
						 , tmp.IsLiveAutoSuspend AS '@s'
					FROM #NewDisableStatTbl tmp
						INNER JOIN VRSettingHierarchy h WITH(NOLOCK) ON tmp.LevelID = h.LevelID
					FOR XML PATH('r')
						, TYPE
					)
			FOR XML PATH('root')
				, TYPE
			)

	SET @xmlStrAutoSuspendNonLive =(
			SELECT (
					SELECT h.BitmapOrderAutoSuspend	AS '@b'
						 , tmp.IsNonLiveAutoSuspend AS '@s'
					FROM #NewDisableStatTbl tmp
						INNER JOIN VRSettingHierarchy h WITH(NOLOCK) ON tmp.LevelID = h.LevelID
					FOR XML PATH('r')
						, TYPE
					)
			FOR XML PATH('root')
				, TYPE
			)

	SELECT @TrackingValue2 = (
		SELECT tmp.LevelID, 
			   h.SportType, 
			   lg.GroupName LeagueGroup,
			   bg.GroupName BettypeGroup,
			   h.BetType,
			   dbo.f_GetProductStatus(ISNULL(at.AutoSuspendLive,@InitialBitMap),h.BitmapOrderAutoSuspend) as IsLiveAutoSuspend,
			   dbo.f_GetProductStatus(ISNULL(at.AutoSuspendNonLive,@InitialBitMap),h.BitmapOrderAutoSuspend) as IsNonLiveAutoSuspend,
			   h.SortOrder
		FROM #NewDisableStatTbl tmp
			 INNER JOIN VRSettingHierarchy h WITH(NOLOCK)
			   ON tmp.LevelID = h.LevelID
			 LEFT JOIN VRLeagueGroup lg WITH(NOLOCK) ON h.VRLeagueGroupID = lg.GroupID
			 LEFT JOIN VRBettypeGroup bg WITH(NOLOCK) ON h.VRBetTypeGroupID = bg.GroupID
			 OUTER APPLY ( SELECT AutoSuspendLive, AutoSuspendNonLive FROM dbo.CustSettingAutoSuspend WITH(NOLOCK) WHERE custid = @CustID AND SportType = @SportType) at
	FOR XML  RAW('r')
	)

	SELECT @TrackingValue2 = '<Root>' + ISNULL(@TrackingValue2,'') + '</Root>'

	IF EXISTS ( SELECT TOP 1 1 FROM CustSettingAutoSuspend WITH(NOLOCK) WHERE CustID = @CustID AND SportType = @SportType)
	BEGIN
		UPDATE CustSettingAutoSuspend WITH(ROWLOCK, UPDLOCK)
		SET AutoSuspendLive = (SELECT bitmap FROM dbo.f_GenerateProductStatus_multiple (AutoSuspendLive, CONVERT(VARCHAR(MAX),@xmlStrAutoSuspendLive))) ,
			AutoSuspendNonLive = (SELECT bitmap FROM dbo.f_GenerateProductStatus_multiple (AutoSuspendNonLive, CONVERT(VARCHAR(MAX),@xmlStrAutoSuspendNonLive)))	
		WHERE CustID = @CustID AND SportType = @SportType
	END
	ELSE
	BEGIN
		INSERT INTO CustSettingAutoSuspend (CustID,AutoSuspendLive,AutoSuspendNonLive,Sporttype)
		SELECT @CustID
			,a1.bitmap
			,a2.bitmap
			,@SportType
		FROM dbo.f_GenerateProductStatus_multiple (@InitialBitMap, CONVERT(VARCHAR(MAX),@xmlStrAutoSuspendLive)) a1
			,dbo.f_GenerateProductStatus_multiple (@InitialBitMap, CONVERT(VARCHAR(MAX),@xmlStrAutoSuspendNonLive)) a2
	END
	
	DELETE FROM CustSettingAutoSuspend WITH(ROWLOCK, UPDLOCK)
	WHERE CustID = @CustID
		AND AutoSuspendLive = @InitialBitMap
		AND AutoSuspendNonLive = @InitialBitMap
		AND SportType = @SportType

	SELECT @TrackingValue1 = (
		SELECT tmp.LevelID, 
			   h.SportType, 
			   lg.GroupName LeagueGroup,
			   bg.GroupName BettypeGroup,
			   h.BetType,
			   dbo.f_GetProductStatus(ISNULL(at.AutoSuspendLive,@InitialBitMap),h.BitmapOrderAutoSuspend) as IsLiveAutoSuspend,
			   dbo.f_GetProductStatus(ISNULL(at.AutoSuspendNonLive,@InitialBitMap),h.BitmapOrderAutoSuspend) as IsNonLiveAutoSuspend,
			   h.SortOrder
		FROM #NewDisableStatTbl tmp
			 INNER JOIN VRSettingHierarchy h WITH(NOLOCK)
			   ON tmp.LevelID = h.LevelID
			 LEFT JOIN VRLeagueGroup lg WITH(NOLOCK) ON h.VRLeagueGroupID = lg.GroupID
			 LEFT JOIN VRBettypeGroup bg WITH(NOLOCK) ON h.VRBetTypeGroupID = bg.GroupID
			 OUTER APPLY ( SELECT AutoSuspendLive, AutoSuspendNonLive FROM dbo.CustSettingAutoSuspend WITH(NOLOCK) WHERE custid = @CustID AND SportType = @SportType) at
	FOR XML  RAW('r')
	)

	SELECT @TrackingValue1 = '<Root>' + ISNULL(@TrackingValue1,'') + '</Root>'

	SELECT @EndRun = GETDATE()    
	SELECT @Duration  = DATEDIFF (MILLISECOND,@startRun,@endRun)

	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.[Writelog_VirtualRate_UpdateSetting] @CustID=@CustID
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
		EXEC bodb_CustomerLog.dbo.[Writelog_VirtualRate_UpdateSetting] @CustID=@CustID
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

	DROP TABLE #NewDisableStatTbl
	DROP TABLE #temp     
END