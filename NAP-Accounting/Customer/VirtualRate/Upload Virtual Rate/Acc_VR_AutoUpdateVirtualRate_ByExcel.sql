/*<info serverAlias="DBCUST-CUSTDB" executers="" viewers="" isFunction="0" isNested="0" ></info>*/
ALTER PROCEDURE [dbo].[Acc_VR_AutoUpdateVirtualRate_ByExcel]
	 @SportType INT = 43
	,@SessionID UNIQUEIDENTIFIER = NULL
	,@UserID INT = NULL
	,@IP VARCHAR(15) = ''
	,@ErrCode INT = 0 OUTPUT
	,@ErrMsg NVARCHAR(200) = '' OUTPUT
AS
/*   
	Create: 20200310@Eden
	Task : Update VR Setting base on VRSetting_AutoUpdate_ByExcel table
	DB: DBCUST/CustDB
	Revisions:
		- 20200310@Eden: Initial version [Redmine:#128749]
		
	Param's Explanation:
	
*/
BEGIN
	SET NOCOUNT ON

	IF EXISTS ( SELECT TOP 1 1
				FROM VRSetting_AutoUpdate_ByExcel vv WITH(NOLOCK)
					LEFT JOIN VRValueMapping vrv WITH(NOLOCK)
						ON vv.VirtualMultiplier = vrv.Value
				WHERE vrv.ValueID IS NULL
					AND vv.SessionID = @SessionID
		)
	BEGIN
		SET @ErrMsg =  'VirtualMultiplier of VRSetting_AutoUpdate_ByExcel is not valid' 
		RETURN
	END

	;WITH VRlive AS(
		SELECT vv.CustID, 
			   h.LevelID, 
			   vrv.ValueID
		FROM VRSettingHierarchy h WITH(NOLOCK)
			 INNER JOIN VRSetting_AutoUpdate_ByExcel vv WITH(NOLOCK)
			   ON h.LevelID = vv.LevelID
			 LEFT JOIN VRCustSetting vr WITH(NOLOCK)
			   ON vr.CustID = vv.CustID
				  AND vr.LevelID = h.LevelID
			 INNER JOIN VRValueMapping vrv WITH(NOLOCK)
			   ON vv.VirtualMultiplier = vrv.Value
		WHERE vv.Islive = 1
			AND (vrv.ValueID <> ISNULL(vr.ValueIDLIVE,0) 
				 OR (vv.CustId = 0 AND h.LevelID IN (154,1))
			)
			AND vv.SportType = @SportType
			AND vv.SessionID = @SessionID
	)
	,VRNonlive AS
	(
		SELECT vv.CustID, 
			   h.LevelID, 
			   vrv.ValueID
		FROM VRSettingHierarchy h WITH(NOLOCK)
			 INNER JOIN VRSetting_AutoUpdate_ByExcel vv WITH(NOLOCK)
			   ON h.LevelID = vv.LevelID
			 LEFT JOIN VRCustSetting vr WITH(NOLOCK)
			   ON vr.CustID = vv.CustID
				  AND vr.LevelID = h.LevelID
			 INNER JOIN VRValueMapping vrv WITH(NOLOCK)
			   ON vv.VirtualMultiplier = vrv.Value
		WHERE vv.Islive = 0
			AND (vrv.ValueID <> ISNULL(vr.ValueIDNonLIVE,0)
				 OR (vv.CustId = 0 AND h.LevelID IN (154,1))
			)
			AND vv.SportType = @SportType
			AND vv.SessionID = @SessionID
	)
	SELECT ISNULL(a1.CustID,a2.CustID) AS CustID
		,ISNULL(a1.LevelID,a2.LevelID) AS LevelID
		,COALESCE(a1.ValueID,vr.ValueIDLIVE,0) AS ValueIDLive 
		,COALESCE(a2.ValueID,vr.ValueIDNonLIVE,0) AS ValueIDNonLive
	INTO #Tmp1
	FROM VRlive a1
		FULL OUTER JOIN VRNonlive a2
			ON a1.CustID = a2.CustID
			AND a1.LevelID = a2.LevelID
	LEFT JOIN VRCustSetting vr WITH(NOLOCK)
		ON vr.CustID = ISNULL(a1.CustID,a2.CustID)
			AND vr.LevelID = ISNULL(a1.LevelID,a2.LevelID)

	CREATE CLUSTERED INDEX PK_Tmp1_LevelID ON #Tmp1(CustID,LevelID)

	;WITH TMP AS(
		SELECT CustID,LevelID,ValueIDLive,ValueIDNonLive FROM #TMP1 
		UNION ALL
		SELECT vr.CustID,vr.LevelID,vr.ValueIDLive,vr.ValueIDNonLive
		FROM VRCustSetting vr WITH(NOLOCK)
			INNER JOIN VRSettingHierarchy h ON h.LevelID = vr.LevelID AND h.SportType = @SportType
		WHERE EXISTS (SELECT 1 FROM  #TMP1 t WHERE t.CustID = vr.CustID)
			AND NOT EXISTS (SELECT 1 FROM  #TMP1 t WHERE t.CustID = vr.CustID AND t.LevelID = vr.LevelID)
	)
	SELECT   CustID
			,CONVERT(VARCHAR(MAX),(SELECT LevelID,ValueIDLive,ValueIDNonLive FROM TMP b WHERE a.CustID = b.CustID FOR XML RAW('Row'), ROOT ('Root')))  AS VirtualMultiplier
			,0 AS IsProcessed
	INTO #VRUpdated
	FROM TMP a
	GROUP BY CustID

	DECLARE @CustID INT
		, @VirtualMultiplier VARCHAR(MAX) = ''

	WHILE 1 = 1
	BEGIN
		UPDATE TOP (1) #VRUpdated 
		SET @CustID = custID,
			@VirtualMultiplier = VirtualMultiplier,
			IsProcessed = 1
		WHERE IsProcessed = 0

		IF @@ROWCOUNT = 0
			BREAK;

		EXEC [Acc_CustVirtualMultiplier_Upd]
			  @CustID = @CustID
			, @SportType = @SportType
			, @VirtualMultiplier = @VirtualMultiplier
			, @UserID  = @UserID
			, @IP  = @IP
			, @ErrCode = @ErrCode OUT
			, @ErrMsg = @ErrMsg OUT

		--IF @ErrCode <> 0
		--	--print error
		--	PRINT 'CustID = ' + CONVERT (VARCHAR(10),@CustID) + ' - ' + @ErrMsg 
		--ELSE 
		--	PRINT 'CustID = ' + CONVERT (VARCHAR(10),@CustID) + ' - SUCCEED'
	END

	DELETE FROM VRSetting_AutoUpdate_ByExcel WITH(ROWLOCK) WHERE SessionID = @SessionID

	DROP TABLE #VRUpdated
	DROP TABLE #Tmp1

END
GO
