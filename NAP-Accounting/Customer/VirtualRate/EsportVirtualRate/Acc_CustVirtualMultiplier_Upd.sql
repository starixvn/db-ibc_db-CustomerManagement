/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE [dbo].[Acc_CustVirtualMultiplier_Upd]
	@CustID INT
	, @SportType INT
	, @VirtualMultiplier VARCHAR(MAX) = ''
	, @UserID INT
	, @IP VARCHAR(15) = ''
	, @ErrCode INT OUT
	, @ErrMsg NVARCHAR(200) OUT
AS
/*    
	Created: 20190626@Dominic    
	Task :  Update VR setting of an account for a specific sport  [Redmine: #114830]
	DB: DBCUST/CustDB    
	Parameters:
	Param's Explanation:  
		• @VirtualMultiplier = '<Root>
									<Row LevelID="1" ValueIDLive="1" ValueIDNonLive="2" />	
								</Root>'		    
	Revisions:    
		- 20190626@Dominic : First commit
		- 20191105@Eden : Esport VR Phase 2 - Integrate Auto Suspend [Redmind: #121876]
  
*/ 
BEGIN
	SELECT @ErrCode = 0, @ErrMsg = ''
	DECLARE @StartRun DATETIME  
	DECLARE @EndRun DATETIME  
	DECLARE @Duration INT 
	DECLARE @ActionID INT = 808
	DECLARE @RoleID TINYINT
	DECLARE @ActualRate FLOAT
	DECLARE @SportVRLevelID INT
	DECLARE @TrackingValue1 VARCHAR(MAX) = '', @TrackingValue2 VARCHAR(MAX)= ''

	CREATE TABLE #New_VRCustSetting (CustID INT, LevelID INT, ValueIDLive TINYINT, ValueIDNonLive TINYINT)
	CREATE TABLE #Old_VRCustSetting (CustID INT, LevelID INT, ValueIDLive TINYINT, ValueIDNonLive TINYINT)
	CREATE TABLE #VRLineCustID (CustID INT, RoleID TINYINT)

	CREATE TABLE #Log (IsNew BIT, LevelID INT, ValueIDLive TINYINT, ValueIDNonLive TINYINT
						, FollowingCustID INT,FollowingValueIDLive TINYINT,FollowingValueIDNonLive TINYINT
						, RowNo_Live INT, RowNo_NonLive INT
						, FollowingLevelID INT
					)
	
	SELECT @StartRun = GETDATE()    

	 --Check disable user
	 IF @CustID > 0    
		EXEC dbo.Acc_CustomerSelCheckEnable @custid = @custid, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output    
	 
	 IF @ErrCode <> 0 RETURN 


	DECLARE @DocHandler INT	

	--Parse input XML
	IF @VirtualMultiplier <> ''
	BEGIN		
		BEGIN TRY		
			EXEC sp_xml_preparedocument @DocHandler OUTPUT, @virtualmultiplier

			INSERT INTO #New_VRCustSetting(CustID, LevelID, ValueIDLive, ValueIDNonLive)
			SELECT @CustID,
				Data.LevelID,
				Data.ValueIDLive,
				Data.ValueIDNonLive
			FROM OPENXML (@DocHandler, '/Root/Row',1) 
			WITH (
				LevelID	INT,
				ValueIDLive TINYINT,
				ValueIDNonLive TINYINT	
			) AS Data

			EXEC sp_xml_removedocument @DocHandler
		END TRY
		BEGIN CATCH
			SELECT @ErrMsg = N'Invalid XML format'
				, @ErrCode = 3  
			RETURN  
		END CATCH
	END	

	CREATE UNIQUE CLUSTERED INDEX PK_LevelID ON #New_VRCustSetting(CustID, LevelID)

	--Check invalid ValueIDs
	IF EXISTS (
					SELECT 1 
					FROM #New_VRCustSetting 
					WHERE ValueIDLive NOT IN (SELECT ValueID FROM VRValueMapping (NOLOCK))
				)  
		OR EXISTS (
					SELECT 1 
					FROM #New_VRCustSetting 
					WHERE ValueIDNonLive NOT IN (SELECT ValueID FROM VRValueMapping (NOLOCK))
				)
	BEGIN  
		SELECT @ErrMsg = N'Invalid virtual rate'
				, @ErrCode = 1  
		RETURN  
	END  

	SELECT @SportVRLevelID = LevelID
	FROM VRSettingHierarchy h (NOLOCK)
	WHERE SportType = @SportType AND VRLeagueGroupID=-1 

	IF @CustID = 0 AND NOT EXISTS (SELECT 1 FROM #New_VRCustSetting WHERE LevelID = @SportVRLevelID)
	BEGIN
		SELECT @ErrMsg = N'Global VR setting must have a value on sport level'
				, @ErrCode = 2  
		RETURN 
	END

	--> call sp process update auto suspend
	EXEC Acc_CustVirtualMultiplier_AutoSuspendUpd
			@CustID = @CustID,
			@UserID = @UserID,
			@IP = @IP,
			@AutoSuspendXML = @virtualmultiplier,
			@ErrCode = @ErrCode OUTPUT,
			@ErrMsg = @ErrMsg OUTPUT

	IF @ErrCode > 0
		RETURN

	--Get Upline's custIDs
	IF @CustID > 0 --Not Global
		INSERT INTO #VRLineCustID(CustID, RoleID)
		SELECT CustID,MAX(RoleID) RoleID
		FROM (
			SELECT upv.Val CustID, ROW_NUMBER() OVER (ORDER BY (SELECT 0)) RoleID
			FROM (
				SELECT custid,recommend,mrecommend,srecommend,0 [Global]
				FROM Customer (NOLOCK)
				WHERE CustID=@CustID
			) t
			UNPIVOT
			(
			  Val
			  FOR col IN (custid,recommend,mrecommend,srecommend,[Global])
			) upv
		) tmp
		GROUP BY CustID
	ELSE --Global
		INSERT INTO #VRLineCustID(CustID, RoleID)
		SELECT 0, 5

	--Capture current VR setting
	INSERT INTO #Old_VRCustSetting(CustID, LevelID, ValueIDLive, ValueIDNonLive)
	SELECT vr.CustID, vr.LevelID, ValueIDLive, ValueIDNonLive
	FROM VRSettingHierarchy h (NOLOCK)
	INNER JOIN VRCustSetting vr (NOLOCK)
		ON h.LevelID = vr.LevelID
	WHERE CustID IN (SELECT CustID FROM #VRLineCustID) 
		AND h.SportType = @SportType

	CREATE UNIQUE CLUSTERED INDEX PK_LevelID ON #Old_VRCustSetting(CustID, LevelID)

	--Capture new VR setting
	INSERT INTO #New_VRCustSetting(CustID, LevelID, ValueIDLive, ValueIDNonLive)
	SELECT vr.CustID, vr.LevelID, ValueIDLive, ValueIDNonLive
	FROM #Old_VRCustSetting vr
	WHERE vr.CustID <> @CustID
	
	--Prepare data to write logs - Old data
	;WITH VR_Hierachy AS (
	   SELECT LevelID SrcLevelID, LevelID, ParentLevelID, 1 LayerNo
	   FROM VRSettingHierarchy h (NOLOCK)
	   WHERE SportType = @SportType 
	   UNION ALL
	   SELECT p.SrcLevelID, c.LevelID, c.ParentLevelID, p.LayerNo + 1  LayerNo
	   FROM VRSettingHierarchy c (NOLOCK)
		 INNER JOIN VR_Hierachy p on p.ParentLevelID = c.LevelID  -- this is the recursion
	)
	INSERT INTO #Log(IsNew, LevelID, ValueIDLive, ValueIDNonLive, FollowingCustID, FollowingValueIDLive, FollowingValueIDNonLive,
					RowNo_Live, RowNo_NonLive, FollowingLevelID)
	SELECT 0 IsNew, LevelID,ValueIDLive,ValueIDNonLive,FollowingCustID,FollowingValueIDLive,FollowingValueIDNonLive,
				RowNo_Live, RowNo_NonLive, FollowingLevelID
	FROM (
		SELECT h.SrcLevelID LevelID
			, ISNULL(vrc.ValueIDLive, 0) ValueIDLive, ISNULL(vrc.ValueIDNonLive,0) ValueIDNonLive
			, vr.CustID FollowingCustID
			, vr.LevelID FollowingLevelID
			, vr.ValueIDLive FollowingValueIDLive, vr.ValueIDNonLive FollowingValueIDNonLive
			, ROW_NUMBER() OVER(PARTITION BY h.SrcLevelID ORDER BY CASE WHEN ISNULL(vr.ValueIDLive, 0) = 0 THEN 2 ELSE 1 END, RoleID, LayerNo) RowNo_Live
			, ROW_NUMBER() OVER(PARTITION BY h.SrcLevelID ORDER BY CASE WHEN ISNULL(vr.ValueIDNonLive,0) = 0 THEN 2 ELSE 1 END, RoleID, LayerNo) RowNo_NonLive
		FROM VR_Hierachy h
		CROSS JOIN #VRLineCustID c
		LEFT JOIN #Old_VRCustSetting vrc (NOLOCK) 
			ON vrc.LevelID = h.SrcLevelID
				AND vrc.CustID = @CustID
		LEFT JOIN #Old_VRCustSetting vr (NOLOCK) 
			ON vr.LevelID = h.LevelID
				AND vr.CustID = c.CustID
	) as tmp
	WHERE RowNo_Live=1 OR RowNo_NonLive=1

	--Prepare data to write logs - New data
	;WITH VR_Hierachy AS (
	   SELECT LevelID SrcLevelID, LevelID, ParentLevelID, 1 LayerNo
	   FROM VRSettingHierarchy h (NOLOCK)
	   WHERE SportType = @SportType 
	   UNION ALL
	   SELECT p.SrcLevelID, c.LevelID, c.ParentLevelID, p.LayerNo + 1  LayerNo
	   FROM VRSettingHierarchy c (NOLOCK)
		 INNER JOIN VR_Hierachy p on p.ParentLevelID = c.LevelID  -- this is the recursion
	)
	INSERT INTO #Log(IsNew, LevelID, ValueIDLive, ValueIDNonLive, FollowingCustID, FollowingValueIDLive, FollowingValueIDNonLive,
					RowNo_Live, RowNo_NonLive, FollowingLevelID)
	SELECT 1 IsNew, LevelID,ValueIDLive,ValueIDNonLive,FollowingCustID,FollowingValueIDLive,FollowingValueIDNonLive,
			RowNo_Live, RowNo_NonLive, FollowingLevelID
	FROM (
		SELECT h.SrcLevelID LevelID
			, ISNULL(vrc.ValueIDLive, 0) ValueIDLive, ISNULL(vrc.ValueIDNonLive,0) ValueIDNonLive
			, vr.CustID FollowingCustID
			, vr.LevelID FollowingLevelID
			, vr.ValueIDLive FollowingValueIDLive, vr.ValueIDNonLive FollowingValueIDNonLive
			, ROW_NUMBER() OVER(PARTITION BY h.SrcLevelID ORDER BY CASE WHEN ISNULL(vr.ValueIDLive, 0) = 0 THEN 2 ELSE 1 END, RoleID, LayerNo) RowNo_Live
			, ROW_NUMBER() OVER(PARTITION BY h.SrcLevelID ORDER BY CASE WHEN ISNULL(vr.ValueIDNonLive,0) = 0 THEN 2 ELSE 1 END, RoleID, LayerNo) RowNo_NonLive
		FROM VR_Hierachy h
		CROSS JOIN #VRLineCustID c
		LEFT JOIN #New_VRCustSetting vrc (NOLOCK) 
			ON vrc.LevelID = h.SrcLevelID
				AND vrc.CustID = @CustID
		LEFT JOIN #New_VRCustSetting vr (NOLOCK) 
			ON vr.LevelID = h.LevelID
				AND vr.CustID = c.CustID
	) as tmp
	WHERE RowNo_Live=1 OR RowNo_NonLive=1

	SELECT @RoleID = roleid 
	FROM #VRLineCustID
	WHERE custid = @custid

	EXECUTE	dbo.Acc_CustomerInfo_Execrep_04   
				@custid = @CustID
				, @roleid = @RoleID
				, @action = 'EsportVRUpd'
				, @virtualmultiplier = @virtualmultiplier


	SELECT @EndRun = GETDATE()    
	SELECT @Duration  = DATEDIFF (MILLISECOND,@startRun,@endRun)

	SELECT @TrackingValue1 = (
		SELECT LevelID
			, ValueIDLive
			, ValueIDNonLive 
		FROM #New_VRCustSetting
		WHERE CustID = @CustID
		FOR XML  RAW('r')
	)

	SELECT @TrackingValue1 = '<Root>' + ISNULL(@TrackingValue1,'') + '</Root>'

	--Prepare XML log
	SELECT @TrackingValue2 = (
		SELECT vrl.IsNew
		, h.VRLeagueGroupID
		, h.VRBetTypeGroupID
		, h.BetType
		, h.LevelID
		, CAST(CAST(ISNULL(v1.Value,-1) AS FLOAT) AS VARCHAR(10)) ValueLive
		, CAST(CAST(ISNULL(v2.Value,-1) AS FLOAT) AS VARCHAR(10)) FollowingValueLive
		--, vrl.ValueIDLive, vrl.FollowingValueIDLive
		, vrl.FollowingCustID FollowingCustIDLive, vrl.FollowingLevelID FollowingLevelIDLive
		, CAST(CAST(ISNULL(v3.Value,-1) AS FLOAT) AS VARCHAR(10)) ValueNonLive
		, CAST(CAST(ISNULL(v4.Value,-1) AS FLOAT) AS VARCHAR(10)) FollowingValueNonLive
		--, vrnl.ValueIDNonLive, vrnl.FollowingValueIDNonLive
		, vrnl.FollowingCustID FollowingCustIDNonLive
		, vrnl.FollowingLevelID FollowingLevelIDNonLive
		, h.SortOrder
		FROM VRSettingHierarchy h 
			INNER JOIN #Log vrl (NOLOCK) 
				ON vrl.LevelID = h.LevelID
					AND vrl.RowNo_Live = 1
			INNER JOIN #Log vrnl (NOLOCK) 
				ON vrnl.LevelID = h.LevelID
					AND vrnl.IsNew = vrl.IsNew
					AND vrnl.RowNo_NonLive = 1
			INNER JOIN VRValueMapping v1 ON v1.ValueID = vrl.ValueIDLive
			INNER JOIN VRValueMapping v2 ON v2.ValueID = vrl.FollowingValueIDLive
			INNER JOIN VRValueMapping v3 ON v3.ValueID = vrnl.ValueIDNonLive
			INNER JOIN VRValueMapping v4 ON v4.ValueID = vrnl.FollowingValueIDNonLive
		WHERE h.SportType = @SportType 
		ORDER BY h.SortOrder
		FOR XML  RAW('r')
	)


	SELECT @ActualRate = e.actualrate
	FROM Customer c (NOLOCK)
		INNER JOIN exchange e (NOLOCK) ON  e.exchangeid = c.currency  
	WHERE CustID = @CustID

	SELECT @TrackingValue2 = '<Root actualrate="' + CAST(ISNULL(@ActualRate,0) AS VARCHAR(10)) + '" >' + @TrackingValue2  + '</Root>'

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

	DROP TABLE #New_VRCustSetting
	DROP TABLE #Old_VRCustSetting
	DROP TABLE #VRLineCustID
	DROP TABLE #Log
END