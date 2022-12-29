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
		- 20211125@Eden: Override Auto Suspend [Redmine: #164888] 
		- 20220617@Johnson: define temp table to avoid dump db [redmine:#174035]
		- 20221103@Johnson: Change data type of CustSettingAutoSuspend [Redmine: #179782]
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
						<Row LevelID = "15" IsLiveAutoSuspend="0" IsNonLiveAutoSuspend="0" IsOverrideASLive="1" IsOverrideASNonLive="0"/>
						<Row LevelID = "17" IsLiveAutoSuspend="0" IsNonLiveAutoSuspend="0" IsOverrideASLive="0" IsOverrideASNonLive="0"/>
						<Row LevelID = "21" IsLiveAutoSuspend="0" IsNonLiveAutoSuspend="1" IsOverrideASLive="0" IsOverrideASNonLive="0"/>
						<Row LevelID = "22" IsLiveAutoSuspend="0" IsNonLiveAutoSuspend="1" IsOverrideASLive="0" IsOverrideASNonLive="0"/>
						<Row LevelID = "24" IsLiveAutoSuspend="0" IsNonLiveAutoSuspend="0" IsOverrideASLive="0" IsOverrideASNonLive="0"/>
						<Row LevelID = "25" IsLiveAutoSuspend="0" IsNonLiveAutoSuspend="1" IsOverrideASLive="0" IsOverrideASNonLive="0"/>
			</Root>'
			,@ErrCode = @ErrCode OUTPUT
			,@ErrMsg = @ErrMsg OUTPUT
			,@SportType = 43

		SELECT @ErrCode,@ErrMsg
  
*/ 
BEGIN
	DECLARE @StartRun DATETIME  
	DECLARE @EndRun DATETIME  
	DECLARE @Duration INT 
	DECLARE @ActionID INT = 809
	DECLARE @TrackingValue1 VARCHAR(MAX) = '' -- New values
			,@TrackingValue2 VARCHAR(MAX)= '' -- Old values
	DECLARE @InitialBitMap_0 VARBINARY(128) =  0x0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
	DECLARE @InitialBitMap VARBINARY(128) = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF

	SELECT @ErrCode = 0, @ErrMsg = ''
	
	CREATE TABLE #NewDisableStatTbl (
		  LevelID				SMALLINT
		, IsLiveAutoSuspend		BIT
		, IsNonLiveAutoSuspend	BIT
		, IsOverrideASLive		BIT
		, IsOverrideASNonLive	BIT
		)

	SELECT @StartRun = GETDATE()   


	IF EXISTS(SELECT TOP 1 1 FROM Custinfo WITH(NOLOCK) WHERE custid = @CustID and roleid <> 1)
		RETURN

	DECLARE @iDoc INT

	BEGIN TRY
		EXEC sp_xml_preparedocument @iDoc OUTPUT
			, @AutoSuspendXML

		INSERT INTO #NewDisableStatTbl(
			LevelID,
			IsLiveAutoSuspend,
			IsNonLiveAutoSuspend,
			IsOverrideASLive,
			IsOverrideASNonLive
		)
		SELECT LevelID,
			IsLiveAutoSuspend,
			IsNonLiveAutoSuspend,
			IsOverrideASLive,
			IsOverrideASNonLive
		FROM OPENXML(@iDoc, '/Root/Row', 1) WITH (
				  LevelID					SMALLINT
				, IsLiveAutoSuspend			BIT
				, IsNonLiveAutoSuspend		BIT
				, IsOverrideASLive			BIT
				, IsOverrideASNonLive		BIT
				)
	
		EXEC sp_xml_removedocument @iDoc
	END TRY
	BEGIN CATCH
		SELECT @ErrMsg = N'Invalid XML format'
			, @ErrCode = 3  
		RETURN  
	END CATCH
	
	CREATE TABLE #temp(LevelID INT,BetType SMALLINT,IsLiveAutoSuspend BIT, IsNonLiveAutoSuspend BIT, SportType SMALLINT, IsOverrideASLive BIT, IsOverrideASNonLive BIT)
	
	INSERT INTO #temp(LevelID,BetType,IsLiveAutoSuspend,IsNonLiveAutoSuspend,SportType,IsOverrideASLive,IsOverrideASNonLive)
	SELECT DISTINCT h.LevelID
		,h.BetType
		,Live.value as IsLiveAutoSuspend
		,NonLive.value IsNonLiveAutoSuspend
		,h.SportType
		,O_Live.value AS IsOverrideASLive
		,O_NonLive.value AS IsOverrideASNonLive	
	FROM #NewDisableStatTbl tmp 
		INNER JOIN VRSettingHierarchy h WITH(NOLOCK) ON tmp.LevelID = h.LevelID
		OUTER APPLY (	SELECT AutoSuspendLive, 
							   AutoSuspendNonLive, 
							   OverrideASLive, 
							   OverrideASNonLive
						FROM dbo.CustSettingAutoSuspend WITH(NOLOCK) 
						WHERE custid = @CustID AND SportType = @SportType
					) at
		OUTER APPLY dbo.f_VRCustSetting_ProductStatusSel (ISNULL(at.AutoSuspendLive,@InitialBitMap),h.BitmapOrderAutoSuspend) Live
		OUTER APPLY dbo.f_VRCustSetting_ProductStatusSel (ISNULL(at.AutoSuspendNonLive,@InitialBitMap),h.BitmapOrderAutoSuspend) NonLive
		OUTER APPLY dbo.f_VRCustSetting_ProductStatusSel (ISNULL(at.OverrideASLive,@InitialBitMap_0),h.BitmapOrderAutoSuspend) O_Live
		OUTER APPLY dbo.f_VRCustSetting_ProductStatusSel (ISNULL(at.OverrideASNonLive,@InitialBitMap_0),h.BitmapOrderAutoSuspend) O_NonLive

	CREATE CLUSTERED INDEX PK_temp_LevelID ON #temp(LevelID)

	DELETE a
	FROM #NewDisableStatTbl a
		INNER JOIN #temp tmp  ON a.LevelID = tmp.LevelID
	WHERE (tmp.BetType = -1 AND tmp.SportType = 43) 
		OR (ISNULL(a.IsLiveAutoSuspend,tmp.IsLiveAutoSuspend) = tmp.IsLiveAutoSuspend 
			AND ISNULL(a.IsNonLiveAutoSuspend, tmp.IsNonLiveAutoSuspend)  = tmp.IsNonLiveAutoSuspend
			AND ISNULL(a.IsOverrideASLive, tmp.IsOverrideASLive)  = tmp.IsOverrideASLive
			AND ISNULL(a.IsOverrideASNonLive, tmp.IsOverrideASNonLive)  = tmp.IsOverrideASNonLive
			)
		OR (tmp.SportType <> @SportType)

	UPDATE a
	SET  a.IsLiveAutoSuspend = ISNULL(a.IsLiveAutoSuspend,tmp.IsLiveAutoSuspend)
		,a.IsNonLiveAutoSuspend = ISNULL(a.IsNonLiveAutoSuspend,tmp.IsNonLiveAutoSuspend)
		,a.IsOverrideASLive = ISNULL(a.IsOverrideASLive,tmp.IsOverrideASLive)
		,a.IsOverrideASNonLive = ISNULL(a.IsOverrideASNonLive,tmp.IsOverrideASNonLive)
	FROM #NewDisableStatTbl a
		INNER JOIN #temp tmp  ON a.LevelID = tmp.LevelID
	
	IF NOT EXISTS( SELECT TOP 1 1 FROM #NewDisableStatTbl)
	BEGIN
		RETURN --no changed
	END

	DECLARE @xmlStrAutoSuspendLive XML
	DECLARE @xmlStrAutoSuspendNonLive XML
	DECLARE @xmlStrOverrideASLive XML
	DECLARE @xmlStrOverrideASNonLive XML
	
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

	SET @xmlStrOverrideASLive =(
			SELECT (
					SELECT h.BitmapOrderAutoSuspend	AS '@b'
						 , tmp.IsOverrideASLive AS '@s'
					FROM #NewDisableStatTbl tmp
						INNER JOIN VRSettingHierarchy h WITH(NOLOCK) ON tmp.LevelID = h.LevelID
					FOR XML PATH('r')
						, TYPE
					)
			FOR XML PATH('root')
				, TYPE
			)

	SET @xmlStrOverrideASNonLive =(
			SELECT (
					SELECT h.BitmapOrderAutoSuspend	AS '@b'
						 , tmp.IsOverrideASNonLive AS '@s'
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
			Live.value as IsLiveAutoSuspend,
			NonLive.value IsNonLiveAutoSuspend,
			h.SortOrder,
			O_Live.value AS IsOverrideASLive,
			O_NonLive.value AS IsOverrideASNonLive
		FROM #NewDisableStatTbl tmp
			INNER JOIN VRSettingHierarchy h WITH(NOLOCK)
				ON tmp.LevelID = h.LevelID
			LEFT JOIN VRLeagueGroup lg WITH(NOLOCK) ON h.VRLeagueGroupID = lg.GroupID
			LEFT JOIN VRBettypeGroup bg WITH(NOLOCK) ON h.VRBetTypeGroupID = bg.GroupID
			OUTER APPLY (	SELECT AutoSuspendLive, 
								AutoSuspendNonLive, 
								OverrideASLive, 
								OverrideASNonLive
						FROM dbo.CustSettingAutoSuspend WITH(NOLOCK) 
						WHERE custid = @CustID AND SportType = @SportType
					) at
			OUTER APPLY dbo.f_VRCustSetting_ProductStatusSel (ISNULL(at.AutoSuspendLive,@InitialBitMap),h.BitmapOrderAutoSuspend) Live
			OUTER APPLY dbo.f_VRCustSetting_ProductStatusSel (ISNULL(at.AutoSuspendNonLive,@InitialBitMap),h.BitmapOrderAutoSuspend) NonLive
			OUTER APPLY dbo.f_VRCustSetting_ProductStatusSel (ISNULL(at.OverrideASLive,@InitialBitMap_0),h.BitmapOrderAutoSuspend) O_Live
			OUTER APPLY dbo.f_VRCustSetting_ProductStatusSel (ISNULL(at.OverrideASNonLive,@InitialBitMap_0),h.BitmapOrderAutoSuspend) O_NonLive
	FOR XML  RAW('r')
	)

	SELECT @TrackingValue2 = '<Root>' + ISNULL(@TrackingValue2,'') + '</Root>'
	
	IF EXISTS ( SELECT TOP 1 1 FROM CustSettingAutoSuspend WITH(NOLOCK) WHERE CustID = @CustID AND SportType = @SportType)
	BEGIN
		UPDATE CustSettingAutoSuspend WITH(ROWLOCK, UPDLOCK)
		SET AutoSuspendLive = (SELECT bitmap FROM dbo.f_VRCustSetting_GenerateProductStatus_multiple (ISNULL(AutoSuspendLive,@InitialBitMap), CONVERT(VARCHAR(MAX),@xmlStrAutoSuspendLive))) ,
			AutoSuspendNonLive = (SELECT bitmap FROM dbo.f_VRCustSetting_GenerateProductStatus_multiple (ISNULL(AutoSuspendNonLive,@InitialBitMap), CONVERT(VARCHAR(MAX),@xmlStrAutoSuspendNonLive))),
			OverrideASLive = (SELECT bitmap FROM dbo.f_VRCustSetting_GenerateProductStatus_multiple (ISNULL(OverrideASLive,@InitialBitMap_0), CONVERT(VARCHAR(MAX),@xmlStrOverrideASLive))),
			OverrideASNonLive = (SELECT bitmap FROM dbo.f_VRCustSetting_GenerateProductStatus_multiple (ISNULL(OverrideASNonLive,@InitialBitMap_0), CONVERT(VARCHAR(MAX),@xmlStrOverrideASNonLive)))	
		WHERE CustID = @CustID AND SportType = @SportType
	END
	ELSE
	BEGIN
		INSERT INTO CustSettingAutoSuspend (CustID,AutoSuspendLive,AutoSuspendNonLive,Sporttype,OverrideASLive,OverrideASNonLive)
		SELECT @CustID
			,a1.bitmap
			,a2.bitmap
			,@SportType
			,a3.bitmap
			,a4.bitmap
		FROM dbo.f_VRCustSetting_GenerateProductStatus_multiple (@InitialBitMap, CONVERT(VARCHAR(MAX),@xmlStrAutoSuspendLive)) a1
			,dbo.f_VRCustSetting_GenerateProductStatus_multiple (@InitialBitMap, CONVERT(VARCHAR(MAX),@xmlStrAutoSuspendNonLive)) a2
			,dbo.f_VRCustSetting_GenerateProductStatus_multiple (@InitialBitMap_0, CONVERT(VARCHAR(MAX),@xmlStrOverrideASLive)) a3
			,dbo.f_VRCustSetting_GenerateProductStatus_multiple (@InitialBitMap_0, CONVERT(VARCHAR(MAX),@xmlStrOverrideASNonLive)) a4
	END
	
	DELETE 
	FROM CustSettingAutoSuspend WITH(ROWLOCK, UPDLOCK)
	WHERE CustID = @CustID
		AND ISNULL(AutoSuspendLive,@InitialBitMap) = @InitialBitMap
		AND ISNULL(AutoSuspendNonLive,@InitialBitMap) = @InitialBitMap
		AND ISNULL(OverrideASLive,@InitialBitMap_0) = @InitialBitMap_0
		AND ISNULL(OverrideASNonLive,@InitialBitMap_0) = @InitialBitMap_0
		AND SportType = @SportType

	SELECT @TrackingValue1 = (
		SELECT tmp.LevelID, 
			h.SportType, 
			lg.GroupName LeagueGroup,
			bg.GroupName BettypeGroup,
			h.BetType,
			Live.value as IsLiveAutoSuspend,
			NonLive.value IsNonLiveAutoSuspend,
			h.SortOrder,
			O_Live.value AS IsOverrideASLive,
			O_NonLive.value AS IsOverrideASNonLive
		FROM #NewDisableStatTbl tmp
			INNER JOIN VRSettingHierarchy h WITH(NOLOCK)
				ON tmp.LevelID = h.LevelID
			LEFT JOIN VRLeagueGroup lg WITH(NOLOCK) ON h.VRLeagueGroupID = lg.GroupID
			LEFT JOIN VRBettypeGroup bg WITH(NOLOCK) ON h.VRBetTypeGroupID = bg.GroupID
			OUTER APPLY (	SELECT AutoSuspendLive, 
								AutoSuspendNonLive, 
								OverrideASLive, 
								OverrideASNonLive
						FROM dbo.CustSettingAutoSuspend WITH(NOLOCK) 
						WHERE custid = @CustID AND SportType = @SportType
					) at
			OUTER APPLY dbo.f_VRCustSetting_ProductStatusSel (ISNULL(at.AutoSuspendLive,@InitialBitMap),h.BitmapOrderAutoSuspend) Live
			OUTER APPLY dbo.f_VRCustSetting_ProductStatusSel (ISNULL(at.AutoSuspendNonLive,@InitialBitMap),h.BitmapOrderAutoSuspend) NonLive
			OUTER APPLY dbo.f_VRCustSetting_ProductStatusSel (ISNULL(at.OverrideASLive,@InitialBitMap_0),h.BitmapOrderAutoSuspend) O_Live
			OUTER APPLY dbo.f_VRCustSetting_ProductStatusSel (ISNULL(at.OverrideASNonLive,@InitialBitMap_0),h.BitmapOrderAutoSuspend) O_NonLive
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