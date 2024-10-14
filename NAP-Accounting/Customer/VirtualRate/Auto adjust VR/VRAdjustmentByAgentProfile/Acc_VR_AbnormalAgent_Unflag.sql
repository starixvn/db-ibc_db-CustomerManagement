/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap,wsv_lap" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Acc_VR_AbnormalAgent_Unflag   
	 @CustIDList VARCHAR(max)
	,@Type TINYINT
	,@IsTest BIT = 0
AS  
/*  
	Created:	20200827@Eden
	Task:		Check and Unflag Abnormal agents base on VRAgentAutoAdjustment table
	DB:			DBCUST/CustDB
	Original:	
  
	Revisions:  
	    - 20200827@Eden: First commit [#140421]
		- 20200918@Eden: Apply small changes to the Agent profiling and VR updating auto job [#141927]
		- 20210226@Eden: Implement Lock for VR update [Redmine:#149370]
		- 20220105@Eden: Enhance to write more logs for Virtual Rate jobs [Redmine:#166626]
		- 20230307@Johnson: Return Basketball VR to its original state [redmine:#184339]
		- 20230427@Luke: Separate lock function for Basketball [Redmine: #185991]
		- 20230710@Winfred: VR Auto Job - Update the Agent VR to follow UPLINE VR setting [Redmine: #185994]
		- 20240530@Winfred: Auto adjusment for VR job - Update Lock status follow Upline Status [Redmine: #202848]
		- 20240701@Winfred: Scale Out DBCUST - Apply In-house Replication for Virtual Rate Setting  [redmine: #207029]
		
	Param's Explanation:  
		@Type = 
			1: All VR sport exxclude BasketBall and Esport
	Examples:
		EXEC Acc_VR_AbnormalAgent_Unflag 
		@CustIDList  = '<Root>
							<Row CustID="1" TotalWL="1000" />	
						</Root>'
		,@Type = 1
		,@IsTest = 1
*/  
BEGIN  
	SET NOCOUNT ON  
	DECLARE @startRun datetime  
	DECLARE @endRun datetime  
	DECLARE @duration int 
	SET @startRun = getdate()
	DECLARE @VRLockedStatus_Soccer_upline BIT = 0
	DECLARE @VRLockedStatus_OS_upline BIT = 0
	DECLARE @VRLockedStatus_Basketball_upline BIT = 0

	DECLARE @AgentTbl TABLE ( CustID INT PRIMARY KEY, TotalWL DECIMAL (19, 4), VRLockedStatus_Soccer_upline BIT, VRLockedStatus_OS_upline BIT, VRLockedStatus_Basketball_upline BIT)

	DECLARE @DocHandler INT	

	--Parse input XML
	IF @CustIDList <> ''
	BEGIN				
		EXEC sp_xml_preparedocument @DocHandler OUTPUT, @CustIDList

		INSERT INTO @AgentTbl(CustID,TotalWL)
		SELECT DISTINCT Data.CustID,
			Data.TotalWL
		FROM OPENXML (@DocHandler, '/Root/Row',1) 
		WITH (
			CustID	INT,
			TotalWL DECIMAL (19, 4)
		) AS Data

		EXEC sp_xml_removedocument @DocHandler
	END	

	IF @IsTest = 1 -- UUS only 
	BEGIN
		DELETE t
		FROM @AgentTbl t
			INNER JOIN custInfo ci WITH(NOLOCK) ON t.CustID = ci.custid
		WHERE ci.currency <> 20
	END

	DELETE t
	FROM VRAgentAutoAdjustment v WITH(NOLOCK)
		INNER JOIN @AgentTbl t ON v.AgentID = t.CustID
	WHERE v.Type = @Type
		AND v.Status <> 2
		
	--/* Start : Delete Agents list who have VR <> 0 
	DECLARE @temp TABLE (CustID INT PRIMARY KEY)
	INSERT INTO @TEMP(CustID)
	SELECT DISTINCT t.custid
	FROM @AgentTbl t 
		INNER JOIN CustVirtualSetting AS cvs WITH(NOLOCK)
			ON cvs.custid = t.CustID
		INNER JOIN ProfileVirtualSetting AS pvs WITH(NOLOCK)
			ON cvs.seqNo = pvs.seqNo
	WHERE pvs.sporttype NOT IN(43)
		AND dbo.f_GetVirtualSetting(cvs.bitmapVirtual, pvs.profileID) <> 1

	DELETE FROM @AgentTbl WHERE CustID  IN (SELECT custID FROM @temp)

	UPDATE t
	SET t.VRLockedStatus_Soccer_upline = CASE WHEN sc.Lock = 1 THEN 1 ELSE 0 END ,
		t.VRLockedStatus_OS_upline = CASE WHEN os.Lock = 1 THEN 1 ELSE 0 END ,
		t.VRLockedStatus_Basketball_upline = CASE WHEN bk.Lock = 1 THEN 1 ELSE 0 END
	FROM @AgentTbl t
		INNER JOIN custInfo c WITH(NOLOCK) ON c.CustID = t.CustID 
		OUTER APPLY (SELECT 1 as Lock FROM VRCustLockStatus WITH(NOLOCK) WHERE custid = c.mrecommend AND Type = 1) sc
		OUTER APPLY (SELECT 1 as Lock FROM VRCustLockStatus WITH(NOLOCK) WHERE custid = c.mrecommend AND Type = 2) os
		OUTER APPLY (SELECT 1 as Lock FROM VRCustLockStatus WITH(NOLOCK) WHERE custid = c.mrecommend AND Type = 3) bk
	 --*/ END: Delete Agents list who have VR <> 0 

	--get Agents and their dowlines need to update VR = Upline
	DECLARE @Update_CustTbl TABLE (CustID INT PRIMARY KEY, recommend INT, mrecommend INT, IsFinish BIT DEFAULT 0, IsLog BIT DEFAULT 0)

	INSERT INTO @Update_CustTbl(CustID, recommend,mrecommend)
	SELECT c.custid, c.recommend,c.mrecommend
	FROM @AgentTbl t
		INNER JOIN custInfo c WITH(NOLOCK) ON c.recommend = t.CustID 
	WHERE c.Enabled = 1
	
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

	--SET Other sport VR = super's
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
			ON cvs.custid = t.mrecommend
			INNER JOIN ProfileVirtualSetting AS pvs WITH(NOLOCK)
			ON cvs.seqNo = pvs.seqNo
	WHERE pvs.sporttype NOT IN(43);

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

	DECLARE @tempUpdate_tbl TABLE (CustID INT)
	WHILE 1 = 1
	BEGIN
		DELETE FROM @tempUpdate_tbl

		UPDATE TOP(2000) t
		SET t.IsFinish = 1
		OUTPUT inserted.CustID INTO @tempUpdate_tbl(CustID)
		FROM @Update_CustTbl t
		WHERE t.IsFinish = 0

		IF @@ROWCOUNT = 0 BREAK;
		
		UPDATE cvs
		SET cvs.bitmapVirtual = bm.bitmap
			,cvs.RepUpdateTime = [dbo].[f_GetDateTime2]()
		FROM CustVirtualSetting	AS cvs WITH(UPDLOCK, ROWLOCK)
			INNER JOIN @tempUpdate_tbl t ON cvs.custid = t.CustID			
			INNER JOIN	@virtualXML	AS tmp
					ON	cvs.seqNo = tmp.seqNo
					AND cvs.custid = tmp.CustID
			CROSS APPLY (SELECT TOP 1 bitmap FROM dbo.f_GenerateVirtualSetting_inline(cvs.bitmapVirtual, tmp.Val, tmp.Pos)) AS bm

		WAITFOR DELAY '00:00:00.010'
	END

	--> Update Status = 3
	UPDATE v
	SET v.Status = 3,
		v.RepUpdateTime = [dbo].[f_GetDateTime2]()
	FROM VRAgentAutoAdjustment v WITH(ROWLOCK)
		INNER JOIN @AgentTbl t ON v.AgentID = t.CustID
	WHERE v.Type = @Type

	DECLARE @NewLogData VARCHAR(MAX)
	DECLARE @custID INT, @TotalWL DECIMAL (19, 4)
	--Log Update VR for each customer + Unlock VR status
	WHILE 1 = 1
	BEGIN
		UPDATE TOP(1)  c
		SET c.islog = 1,
			@custID = c.CustID,
			@TotalWL = CASE WHEN a.CustID = c.CustID THEN a.TotalWL ELSE null END,
			@VRLockedStatus_Soccer_upline = a.VRLockedStatus_Soccer_upline,
			@VRLockedStatus_OS_upline = a.VRLockedStatus_OS_upline,
			@VRLockedStatus_Basketball_upline = a.VRLockedStatus_Basketball_upline
		FROM @Update_CustTbl c
			LEFT JOIN @AgentTbl a ON c.recommend = a.CustID
		WHERE c.Islog = 0

		IF @@ROWCOUNT = 0 BREAK;

		--Update VR lock status to unlocked
		EXEC Acc_VRCustLockStatusUpd 
			 @custid = @custid
			,@UserID = 0
			,@VRLockedStatus_Soccer = @VRLockedStatus_Soccer_upline
			,@VRLockedStatus_OS = @VRLockedStatus_OS_upline
			,@VRLockedStatus_Basketball = @VRLockedStatus_Basketball_upline		
			,@IP = ''
			,@UpdateBy = 'Agent profile check'

		SELECT @NewLogData = '<R LockSoccerUpline="'+ coalesce(cast(@VRLockedStatus_Soccer_upline as varchar(1)),space(1)) + '" '
							+' LockBasketballUpline="'+ coalesce(cast(@VRLockedStatus_Basketball_upline as varchar(1)),space(1)) + '" '
							+' LockOSUpline="'+ coalesce(cast(@VRLockedStatus_OS_upline as varchar(1)),space(1)) + '" '
							+ 'Type="'
									+ CASE	WHEN @Type = 1 THEN 'Sportsbook except Esports' 
											ELSE space(1) 
										END+ '" '
							+ ISNULL('TotalMemberWL="' + cast(@TotalWL as varchar(50)) + '" ', '') 
							+ ' />'
	
		EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
			@UserId				= 0,
			@custID				= @custID,
			@ActionId			= 838,
			@TrackingValue		= @NewLogData
	END

	set @endRun = getdate()  
	set @duration  = datediff (millisecond,@startRun,@endRun) 

	SELECT @NewLogData = CONVERT( VARCHAR(MAX), 
			(	SELECT  CustID AS '@AgentID',
						@Type AS '@Type',
						@TotalWL AS '@TotalWL'
				FROM @AgentTbl
				FOR XML PATH('Row'), ROOT ('R'), TYPE)
		)

	EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
		@UserId				= 0,
		@ActionId			= 823,
		@TrackingValue		= @NewLogData,
		@Duration			= @Duration

END
GO
