/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,bodbLicenseeNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE	dbo.Acc_VR_CustomerUpdFollowParent   
	 @CustIDList VARCHAR(max)
	,@Sporttype INT
AS  
/*  
	Created:	
	Task:		Update VR follow Parent for Customers
	DB:			DBCUST/CustDB
	Original:	
  
	Revisions:  
	    - 20200805@Eden: First commit [#138168]
		- 20200811@Eden: Adjust VR setting for Other Sports of Haifa, IBO, Mansion88 & Happy8 [redmine: #139229]
		- 20200826@Eden: Adjust VR setting for Soccer of Haifa, IBO [redmine: #140368]

	Param's Explanation:  
	Examples:
		EXEC Acc_VR_CustomerUpdFollowParent @CustIDList = '1,2'
		,@Sporttype = 99
*/  
BEGIN  
	SET NOCOUNT ON  
	DECLARE @startRun datetime  
	DECLARE @endRun datetime  
	DECLARE @duration int 
	SET @startRun = getdate()

	DECLARE @Input_CustTbl TABLE ( CustID INT)
	DECLARE @Update_CustTbl TABLE ( CustID INT, AgentID INT, IsLog BIT DEFAULT 0)

	INSERT INTO @Input_CustTbl(CustID)
	SELECT p.val
	FROM dbo.f_StringSplit(@CustIDList,',') p
	OPTION (MAXRECURSION 0)
	 
	DECLARE @CustID INT
		, @BasketBallLevelID INT
		, @Update_CustIDList VARCHAR(MAX) = ''

	SELECT @BasketBallLevelID = levelID
	FROM VRSettingHierarchy  WITH(NOLOCK)
	WHERE SportType = 2
		AND VRLeagueGroupID = -1
		AND BetType = -1

	--> Scan all members with Status = 2
	INSERT INTO @Update_CustTbl(CustID,AgentID)
	SELECT v.custid,c.recommend
	FROM VRCustAutoAdjustment v WITH(NOLOCK)
		 INNER JOIN @Input_CustTbl t ON v.CustID = t.CustID
		 INNER JOIN custInfo c WITH(NOLOCK) ON t.custid = c.custid AND c.roleid = 1
	WHERE v.SportType = @Sporttype
		AND v.[Status] = 2

	DELETE FROM @Update_CustTbl WHERE AgentID IS NULL

	IF @Sporttype IN (99,100)
	BEGIN
		--SET basketball VR = follow upline (at basketball level) - VR2
		DELETE vr
		FROM VRCustSetting vr WITH(ROWLOCK)
			INNER JOIN @Update_CustTbl t ON vr.CustID = t.CustID 
		WHERE vr.LevelID = @BasketBallLevelID

		--SET Other sport VR = follow upline ( their agent VR ) - VR1
		DECLARE	@tblVirtualrate		TABLE (
									CustID				INT
								,	SportType			INT
								,	BetType				INT
								,	IsLive				BIT
								,	VirtualMultiplier	SMALLMONEY	
								);
										
		INSERT INTO	@tblVirtualrate (CustID,SportType,BetType,IsLive,VirtualMultiplier)
		SELECT t.custid, 
			   pvs.sporttype, 
			   pvs.bettype, 
			   pvs.islive, 
			   dbo.f_GetVirtualSetting(cvs.bitmapVirtual, pvs.profileID) AS virtualMultiplier
		FROM @Update_CustTbl t 
			 INNER JOIN CustVirtualSetting AS cvs WITH(NOLOCK)
				ON cvs.custid = t.AgentID
			 INNER JOIN ProfileVirtualSetting AS pvs WITH(NOLOCK)
			   ON cvs.seqNo = pvs.seqNo
		WHERE pvs.sporttype NOT IN (1, 2, 43);

		IF @Sporttype = 100 -- SET Soccer VR = follow upline ( their agent VR ) - VR1
		BEGIN
			INSERT INTO	@tblVirtualrate (CustID,SportType,BetType,IsLive,VirtualMultiplier)
			SELECT t.custid, 
				   pvs.sporttype, 
				   pvs.bettype, 
				   pvs.islive, 
				   dbo.f_GetVirtualSetting(cvs.bitmapVirtual, pvs.profileID) AS virtualMultiplier
			FROM @Update_CustTbl t 
				 INNER JOIN CustVirtualSetting AS cvs WITH(NOLOCK)
					ON cvs.custid = t.AgentID
				 INNER JOIN ProfileVirtualSetting AS pvs WITH(NOLOCK)
				   ON cvs.seqNo = pvs.seqNo
			WHERE pvs.sporttype = 1
		END

		DECLARE	@virtualXML	TABLE (
								seqNo		TINYINT
							,	Pos			VARBINARY(64)
							,	Val			VARBINARY(64)
							,	CustID		INT
							);
										
		INSERT INTO @virtualXML(CustID,seqNo, Pos, Val)
		SELECT	t.CustID, pvs.seqNo, p1.Pos, p2.Val
		FROM @Update_CustTbl t 
				CROSS APPLY (
					SELECT	DISTINCT seqNo
					FROM	ProfileVirtualSetting WITH (NOLOCK)
				) pvs
				CROSS APPLY (
					SELECT CONVERT(VARBINARY(64), (
						SELECT	CONVERT(VARCHAR, CAST(ipvs.profileID - 64 * (ipvs.seqNo - 1) AS BINARY(1)), 2)
						FROM		@tblVirtualrate			AS tmp
							INNER JOIN	ProfileVirtualSetting	AS ipvs WITH (NOLOCK)
								ON	tmp.sporttype	= ipvs.sporttype
									AND	tmp.bettype		= ipvs.bettype
									AND	tmp.isLive		= ipvs.islive
						WHERE	ipvs.seqNo = pvs.seqNo AND tmp.CustID = t.CustID
						FOR XML PATH ('')						
					), 2) AS Pos
				) p1
				CROSS APPLY (
					SELECT CONVERT(VARBINARY(64), (
						SELECT	CONVERT(VARCHAR, CAST(CASE WHEN CAST(VirtualMultiplier * 100 AS INT) > 200 THEN ((CAST(VirtualMultiplier * 100 AS INT) - 200) / 5 + 200) ELSE CAST(VirtualMultiplier * 100 AS INT) END AS BINARY(1)), 2)
						FROM		@tblVirtualrate			AS tmp
							INNER JOIN	ProfileVirtualSetting	AS ipvs WITH (NOLOCK)
								ON	tmp.sporttype	= ipvs.sporttype
									AND	tmp.bettype		= ipvs.bettype
									AND	tmp.isLive		= ipvs.islive
						WHERE	ipvs.seqNo = pvs.seqNo AND tmp.CustID = t.CustID
						FOR XML PATH ('')						
					), 2) AS Val
				) p2

		UPDATE cvs
		SET cvs.bitmapVirtual = bm.bitmap
		FROM CustVirtualSetting	AS cvs WITH(UPDLOCK, ROWLOCK)			
			INNER JOIN	@virtualXML	AS tmp
					ON	cvs.seqNo = tmp.seqNo
					AND cvs.custid = tmp.CustID
			CROSS APPLY (SELECT TOP 1 bitmap FROM dbo.f_GenerateVirtualSetting_inline(cvs.bitmapVirtual, tmp.Val, tmp.Pos)) AS bm

	END

	--> Update Status = 3 : done update VR follow parent
	UPDATE v
	SET v.Status = 3
	FROM VRCustAutoAdjustment v WITH(ROWLOCK)
		INNER JOIN @Input_CustTbl t ON v.CustID = t.CustID
	WHERE v.SportType = @Sporttype

	--Log for each Customer
	DECLARE @LogData VARCHAR(MAX)

	WHILE 1 = 1
	BEGIN
		UPDATE TOP (1) @Update_CustTbl
		SET IsLog = 1,
			@CustID = CustID
		WHERE IsLog = 0

		IF @@ROWCOUNT = 0
			BREAK;

		SELECT @LogData = '<R '
						+ 'Sporttype="'
									+ CASE WHEN @Sporttype = 100 THEN 'Sportsbook except Esports' ELSE coalesce(cast(@Sporttype as varchar(50)),space(1)) END
									+ '" ' 
						+ ' />'
		
		EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
			@UserId				= 0,
			@CustID             = @CustID,
			@ActionId			= 816,
			@TrackingValue		= @LogData,
			@Duration			= @Duration

		SELECT @Update_CustIDList = @Update_CustIDList + ',' + CONVERT(varchar,@CustID)

	END
	
	SELECT @Update_CustIDList = STUFF(@Update_CustIDList,1,1,'')

	set @endRun = getdate()  
	set @duration  = datediff (millisecond,@startRun,@endRun) 
	DECLARE @NewLogData VARCHAR(MAX)
	SELECT @NewLogData = '<R '
						+ 'InputCustIDList="'+ coalesce(cast(@CustIDList as varchar(MAX)),space(1)) + '" '
						+ 'UpdatedCustIDList="'+ coalesce(cast(@Update_CustIDList as varchar(MAX)),space(1)) + '" '
						+ 'Sporttype="'+ coalesce(cast(@Sporttype as varchar(50)),space(1)) + '" ' 
						+ ' />'

	EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
		@UserId				= 0,
		@ActionId			= 815,
		@TrackingValue		= @NewLogData,
		@Duration			= @Duration

END
GO
