/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,bodbLicenseeNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE	dbo.Acc_VR_CustomerUpdFollowParent
	 @CustIDList VARCHAR(max)
	,@Sporttype INT
	,@IsTest BIT = 0
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
		- 20210226@Eden: Implement Lock for VR update [Redmine:#149370]
		- 20220105@Eden: Enhance to write more logs for Virtual Rate jobs [Redmine:#166626]
		- 20230307@Johnson: Return Basketball VR to its original state [redmine:#184339]
	Param's Explanation:  
	Examples:
		EXEC Acc_VR_CustomerUpdFollowParent 
		@CustIDList = '<Root>
						<Row CustID="1" WL="1000" TotalTO="2000" AIOTO="20000"  />	
					</Root>'
		,@Sporttype = 99
		,@IsTest = 1
*/  
BEGIN  
	SET NOCOUNT ON  
	DECLARE @startRun datetime  
	DECLARE @endRun datetime  
	DECLARE @duration int 
	SET @startRun = getdate()


	DECLARE @Input_CustTbl TABLE (
		CustID  INT, 
		WL      DECIMAL (19, 4), 
		TotalTO DECIMAL (19, 4), 
		AIOTO   DECIMAL (19, 4)
		)

	DECLARE @Update_CustTbl TABLE(
		CustID  INT, 
		AgentID INT, 
		IsLog   BIT DEFAULT 0, 
		WL      DECIMAL (19, 4), 
		TotalTO DECIMAL (19, 4), 
		AIOTO   DECIMAL (19, 4)
	)

	DECLARE @DocHandler INT	

	--Parse input XML
	IF @CustIDList <> ''
	BEGIN				
		EXEC sp_xml_preparedocument @DocHandler OUTPUT, @CustIDList

		INSERT INTO @Input_CustTbl(CustID,WL,TotalTO,AIOTO)
		SELECT DISTINCT Data.CustID,
			Data.WL,
			Data.TotalTO,
			Data.AIOTO
		FROM OPENXML (@DocHandler, '/Root/Row',1) 
		WITH (
			CustID	INT,
			WL DECIMAL (19, 4),
			TotalTO DECIMAL (19, 4),
			AIOTO DECIMAL (19, 4)
		) AS Data

		EXEC sp_xml_removedocument @DocHandler
	END	

	IF @IsTest = 1 -- UUS only 
	BEGIN
		DELETE t
		FROM @Input_CustTbl t
			INNER JOIN custInfo ci WITH(NOLOCK) ON t.CustID = ci.custid
		WHERE ci.currency <> 20
	END

	DECLARE @CustID INT		
		, @WL DECIMAL (19, 4)
		, @TotalTO DECIMAL (19, 4)
		, @AIOTO DECIMAL (19, 4)

	--> Scan all members with Status = 2
	INSERT INTO @Update_CustTbl(CustID,AgentID,WL,TotalTO,AIOTO)
	SELECT v.custid,c.recommend,t.WL,t.TotalTO,t.AIOTO
	FROM VRCustAutoAdjustment v WITH(NOLOCK)
		 INNER JOIN @Input_CustTbl t ON v.CustID = t.CustID
		 INNER JOIN custInfo c WITH(NOLOCK) ON t.custid = c.custid AND c.roleid = 1
	WHERE v.SportType = @Sporttype
		AND v.[Status] = 2

	DELETE FROM @Update_CustTbl WHERE AgentID IS NULL

	IF @Sporttype IN (99,100)
	BEGIN
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
		WHERE pvs.sporttype NOT IN (1, 43);

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

	--Log for each Customer + Unlock VR lock status
	DECLARE @LogData VARCHAR(MAX), @VRLockedStatus_Soccer BIT 

	IF @Sporttype = 100 
		SET @VRLockedStatus_Soccer = 0 --unlock VR lock status for soccer 
	WHILE 1 = 1
	BEGIN
		UPDATE TOP (1) @Update_CustTbl
		SET IsLog = 1,
			@CustID = CustID,
			@WL = WL,
			@TotalTO = TotalTO,
			@AIOTO = AIOTO
		WHERE IsLog = 0

		IF @@ROWCOUNT = 0
			BREAK;

		--Update VR lock status to unlock
		EXEC Acc_VRCustLockStatusUpd 
			 @custid = @custid
			,@UserID = 0
			,@VRLockedStatus_Soccer = @VRLockedStatus_Soccer
			,@VRLockedStatus_OS = 0
			,@IP = ''
			,@UpdateBy = 'China/Desktop check'

		SELECT @LogData = '<R '
						+ 'Sporttype="'
									+ CASE WHEN @Sporttype = 100 THEN 'Sportsbook except Esports' ELSE coalesce(cast(@Sporttype as varchar(50)),space(1)) END
									+ '" '
						+ 'WinLoss="' + coalesce(cast(@WL as varchar(50)),space(1)) + '" ' 
						+ 'TotalTurnover="' + coalesce(cast(@TotalTO as varchar(50)),space(1)) + '" ' 
						+ 'AIOTurnover="' + coalesce(cast(@AIOTO as varchar(50)),space(1)) + '" ' 
						+ ' />' 
		
		EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
			@UserId				= 0,
			@CustID             = @CustID,
			@ActionId			= 816,
			@TrackingValue		= @LogData,
			@Duration			= @Duration
	END
	
	set @endRun = getdate()  
	set @duration  = datediff (millisecond,@startRun,@endRun) 

	DECLARE @NewLogData VARCHAR(MAX)
	SELECT @NewLogData = CONVERT( VARCHAR(MAX), 
			(	SELECT  a.CustID AS '@CustID',
						a.WL AS '@WL', 
						a.TotalTO AS '@TotalTO',
						a.AIOTO AS '@AIOTO',
						CASE WHEN b.custID IS NOT NULL THEN 1 ELSE 0 END  AS '@IsUpdated',
						@Sporttype AS '@Sporttype'
				FROM @Input_CustTbl a
					LEFT JOIN @Update_CustTbl b ON a.CustID = b.CustID
				FOR XML PATH('Row'), ROOT ('R'), TYPE)
			)

	EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
		@UserId				= 0,
		@ActionId			= 815,
		@TrackingValue		= @NewLogData,
		@Duration			= @Duration

END
GO
