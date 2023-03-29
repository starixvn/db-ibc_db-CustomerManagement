/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,bodbLicenseeNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Acc_VR_AbnormalAgent_Flag   
	@Type TINYINT
	,@IsTest BIT = 0
AS  
/*  
	Created:	20200827@Eden
	Task:		Check and Flag Abnormal agents base on VRAgentAutoAdjustment table
	DB:			DBCUST/CustDB
	Original:	
  
	Revisions:  
	    - 20200827@Eden: First commit [#140421]
		- 20200911@Eden: Enhance to include new Agents with tickets the Abnormal checking [#141467]
		- 20200918@Eden: Apply small changes to the Agent profiling and VR updating auto job [#141927]
		- 20210226@Eden: Implement Lock for VR update [Redmine:#149370]
		- 20210830@Eden: Max Payout Per Match [redmine: #158073]
		- 20220105@Eden: Enhance to write more logs for Virtual Rate jobs [Redmine:#166626]
		- 20230307@VN-Johnson: Return Basketball VR to its original state [redmine:#184339]
	Param's Explanation:  
		@Type = 
			1: All VR sport exxclude BasketBall and Esport
	Examples:
		EXEC Acc_VR_AbnormalAgent_Flag 
		 @Type = 1
		,@IsTest = 1
*/  
BEGIN  
	SET NOCOUNT ON  
	DECLARE @startRun datetime  
	DECLARE @endRun datetime  
	DECLARE @duration int 
	SET @startRun = getdate()

	DECLARE @AgentTbl TABLE(
		 CustID              INT PRIMARY KEY ,
		 [SiteID]			 INT ,
		 [AgentCredit]       MONEY , 
		 [AVGMemCredit]      MONEY , 
		 [AVGMemMaxBet]      MONEY , 
		 [AVGMemMaxPerMatch] MONEY , 
		 IsAbnormal          BIT DEFAULT 0
	)

	INSERT INTO @AgentTbl(CustID)
	SELECT v.AgentID
	FROM VRAgentAutoAdjustment v WITH(NOLOCK)
		INNER JOIN Customer c WITH(NOLOCK)
			ON v.AgentID = c.custid
	WHERE v.Type = @Type
		AND c.creatdate >= CONVERT(DATE,GETDATE() - 3)
		AND v.Status = 0
		
	IF @IsTest = 1 -- UUS only 
	BEGIN
		DELETE t
		FROM @AgentTbl t
			INNER JOIN custInfo ci WITH(NOLOCK) ON t.CustID = ci.custid
		WHERE ci.currency <> 20
	END

	/* -- Start : Delete Agents who have VR = 0 or VR is disable
	DECLARE @temp TABLE (CustID INT PRIMARY KEY)
	INSERT INTO @TEMP(CustID)
	SELECT DISTINCT t.custid
	FROM @AgentTbl t 
			INNER JOIN CustVirtualSetting AS cvs WITH(NOLOCK)
			ON cvs.custid = t.CustID
			INNER JOIN ProfileVirtualSetting AS pvs WITH(NOLOCK)
			ON cvs.seqNo = pvs.seqNo
			INNER JOIN custInfo c WITH(NOLOCK) 
			ON c.custid = t.CustID AND c.VirtualMultiplier = 1
	WHERE pvs.sporttype NOT IN( 2, 43)
		AND dbo.f_GetVirtualSetting(cvs.bitmapVirtual, pvs.profileID) <> 1

	DELETE FROM @AgentTbl WHERE CustID NOT IN ( SELECT custID FROM @temp)
	*/ --END: Delete Agents who have VR = 0 or VR is disable 

	;WITH tmp AS(
		SELECT t.CustID,
			AVG(c.credit) AS [AVGMemCredit],
			AVG(st.maxpermatch) AS [AVGMemMaxPerMatch],
			AVG(st.maxbet) AS [AVGMemMaxBet]
		FROM custInfo c WITH(NOLOCK)
			INNER JOIN @AgentTbl t ON c.recommend = t.CustID 
			INNER JOIN CustBetSetting_Member st WITH(NOLOCK) ON c.custid = st.custid AND st.sporttype = 1 AND st.bettype = 1
		WHERE c.roleid = 1 AND c.Enabled = 1
		GROUP BY t.CustID
	)
	UPDATE t 
	SET t.AVGMemCredit = CASE WHEN ag.currency <> 20 THEN tmp.AVGMemCredit*actualrate ELSE tmp.AVGMemCredit END,
		t.AVGMemMaxBet = CASE WHEN ag.currency <> 20 THEN tmp.AVGMemMaxBet*actualrate ELSE tmp.AVGMemMaxBet END,
		t.AVGMemMaxPerMatch = CASE WHEN ag.currency <> 20 THEN tmp.AVGMemMaxPerMatch*actualrate ELSE tmp.AVGMemMaxPerMatch END,
		t.AgentCredit = CASE WHEN ag.currency <> 20 THEN ag.credit*actualrate ELSE ag.credit END,
		t.SiteID = s.siteid
	FROM @AgentTbl t 
		INNER JOIN tmp ON t.CustID = tmp.CustID
		INNER JOIN custInfo ag WITH(NOLOCK) ON ag.custid = t.CustID 
		INNER JOIN Customer agc WITH(NOLOCK) ON ag.custid = agc.custid
		INNER JOIN Site s WITH(NOLOCK) ON s.site = agc.site
		INNER JOIN exchange e WITH(NOLOCK) ON ag.currency = e.ExchangeId
	
	UPDATE t 
	SET IsAbnormal = 1
	FROM  @AgentTbl t 
		INNER JOIN VRAgentProfile vr WITH(NOLOCK) 
			ON t.SiteID = vr.SiteID AND vr.Type = @Type
	WHERE t.AgentCredit > vr.AgentCredit
		AND t.AVGMemCredit > vr.AVGMemCredit
		AND t.AVGMemMaxBet > vr.AVGMemMaxBet
		AND t.AVGMemMaxPerMatch > vr.AVGMemMaxPerMatch
	
	--get Agents and their dowlines need to update VR = 0
	DECLARE @Update_CustTbl TABLE (CustID INT PRIMARY KEY, IsFinish BIT DEFAULT 0, IsLog BIT DEFAULT 0)

	INSERT INTO @Update_CustTbl(CustID)
	SELECT c.custid
	FROM @AgentTbl t
		INNER JOIN custInfo c WITH(NOLOCK) ON c.recommend = t.CustID 
	WHERE t.IsAbnormal = 1
		AND c.Enabled = 1
		
	----Exclude list of Auto Update VR Job 
	--DELETE t
	--FROM @Update_CustTbl t
	--WHERE EXISTS (
	--				SELECT 1
	--				FROM DBLOG.bodb_CustomerLog.dbo.UserLog_VirtualRateSettings AS ulvrs WITH (NOLOCK)
	--				WHERE ulvrs.CustID = t.CustID
	--				)

	IF NOT EXISTS( SELECT 1 FROM @Update_CustTbl)
		RETURN

	--process update VR = 0
	DECLARE	@tblVirtualrate		TABLE (
								SportType			INT
							,	BetType				INT
							,	IsLive				BIT
							,	VirtualMultiplier	SMALLMONEY	
							);
										
	INSERT INTO	@tblVirtualrate (
							SportType
						,	BetType
						,	IsLive
						,	VirtualMultiplier
					)
	SELECT	sporttype,bettype,islive,1.00
	FROM ProfileVirtualSetting 	WITH (NOLOCK)	

	DECLARE	@virtualXML	TABLE (
									seqNo		TINYINT PRIMARY KEY
								,	Pos			VARBINARY(64)
								,	Val			VARBINARY(64)
								);
										
	INSERT INTO @virtualXML(seqNo, Pos, Val )
	SELECT	seqNo, p1.Pos, p2.Val
	FROM (
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
				WHERE	ipvs.seqNo = pvs.seqNo
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
				WHERE	ipvs.seqNo = pvs.seqNo
				FOR XML PATH ('')						
			), 2) AS Val
		) p2;

	DECLARE @tempUpdate_tbl TABLE (CustID INT)
	WHILE 1 = 1
	BEGIN
		DELETE FROM @tempUpdate_tbl

		UPDATE TOP(3000) t
		SET t.IsFinish = 1
		OUTPUT inserted.CustID INTO @tempUpdate_tbl(CustID)
		FROM @Update_CustTbl t
		WHERE t.IsFinish = 0

		IF @@ROWCOUNT = 0 BREAK;
		
		UPDATE cvs
			SET cvs.bitmapVirtual = bm.bitmap
		FROM		CustVirtualSetting	AS cvs WITH(UPDLOCK, ROWLOCK)			
			INNER JOIN	@virtualXML			AS tmp
					ON	cvs.seqNo = tmp.seqNo
			CROSS APPLY (SELECT TOP 1 bitmap FROM dbo.f_GenerateVirtualSetting_inline(cvs.bitmapVirtual, tmp.Val, tmp.Pos)) AS bm
		WHERE	cvs.custid IN ( SELECT custid FROM @tempUpdate_tbl)

		WAITFOR DELAY '00:00:00.010'
	END

	UPDATE v
	SET v.Status = 2,
		v.VR0_Date = GETDATE()
	FROM VRAgentAutoAdjustment v WITH(ROWLOCK)
		INNER JOIN @AgentTbl t ON v.AgentID = t.CustID
	WHERE v.Type = @Type
		AND v.Status = 0
		AND t.IsAbnormal = 1

	DECLARE @NewLogData VARCHAR(MAX)
	DECLARE @custID INT
	--Log Update VR for each customer + Lock VR status
	WHILE 1 = 1
	BEGIN
		UPDATE TOP(1)  c
		SET c.islog = 1,
			@custID = c.CustID
		FROM @Update_CustTbl c
		WHERE Islog = 0

		IF @@ROWCOUNT = 0 BREAK;

		--Update VR lock status to locked
		EXEC Acc_VRCustLockStatusUpd 
			 @custid = @custid
			,@UserID = 0
			,@VRLockedStatus_Soccer = 1
			,@VRLockedStatus_OS = 1
			,@IP = ''
			,@UpdateBy = 'Agent profile check'

		SELECT @NewLogData = '<R '
							+ 'Type="'
									+ CASE	WHEN @Type = 1 THEN 'Sportsbook except Esports' 
											ELSE space(1) 
										END+ '" '
							+ ' />'
	
		EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
			@UserId				= 0,
			@custID				= @custID,
			@ActionId			= 822,
			@TrackingValue		= @NewLogData
	END

	set @endRun = getdate()  
	set @duration  = datediff (millisecond,@startRun,@endRun) 

	SELECT @NewLogData = CONVERT( VARCHAR(MAX), 
			(	SELECT  CustID AS '@AgentID',
						@Type AS '@Type' 
				FROM @AgentTbl
				WHERE IsAbnormal = 1
				FOR XML PATH('Row'), ROOT ('R'), TYPE)
		)

	EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
		@UserId				= 0,
		@ActionId			= 821,
		@TrackingValue		= @NewLogData,
		@Duration			= @Duration

END
GO
