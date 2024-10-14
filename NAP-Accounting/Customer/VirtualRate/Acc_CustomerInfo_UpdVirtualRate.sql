/*<info serverAlias="DBCUST-CustDB" executers="wsv_alp,wsv_nap,wsv_xnap" viewers="" isFunction="0" isNested="1"></info>*/
CREATE PROCEDURE [dbo].[Acc_CustomerInfo_UpdVirtualRate] 
					@custid						INT				
				,	@roleid						TINYINT			
				,	@action						VARCHAR(30)		= ''
				,	@custlist					VARCHAR(MAX) 	= ''
				,	@EnableVirtualrate			BIT				= 0
				,	@virtualmultiplier			VARCHAR(MAX)	= ''
				,   @VRlockStatusType			TINYINT			= NULL -- 0: all, 1:soccer, 2: Other sports, 3: Basketball 
				,	@Suspended					BIT				= 0
				,	@Closed						BIT				= 0
				,	@rowcount					INT				= 0		OUTPUT
				,	@SystemID TINYINT=1
				,	@Sporttype					INT				= NULL 
				,   @AdditionalActions			VARCHAR(MAX) = ''
				,	@VRAccumulate_Balance		BIT				= 0
AS 
/*
	Created:	Winfred
	Date:		20240701
	Task:		Update customer/custinfo settings Virtual Rate
	DB:			DBCUST/CustDB
	Original:	Acc_CustomerInfo_Execrep_04

	Revisions:
		- 20240701@Winfred: Scale Out DBCUST - Apply In-house Replication for Virtual Rate Setting [redmine: #207029]

	Param's Explanation:
		@Action: 
			+ 'VirtualMultiplier': Virtual Rate [@virtualmultiplier]
			+ 'Suspended': Suspended/Reject		[@Suspended]
			+ 'Closed': Closed					[@Closed]
					
			+ 'NewVRUpd': Update VR setting of an account for Esport  [@virtualmultiplier] - Redmine: #114830 and for Soccer [Redmine: #126243]

		- @AdditionalActions : Use for update VR
							 = '<ROOT>
								<VR UnlockSC3="1"  UnlockSC2="0" UnlockSC1="1" UnlockBB3="1"  UnlockBB2="0" UnlockBB1="1" UnlockOS3="1"  UnlockOS2="0" UnlockOS1="1" Enable3="0"  Enable2="1" Enable1="0" />	
							</ROOT>'
   
*/
SET NOCOUNT ON; 

IF	@action = 'NewVRUpd'
BEGIN
	CREATE TABLE #New_VRCustSetting (LevelID INT, ValueIDLive TINYINT, ValueIDNonLive TINYINT)
	DECLARE @DocHandlerSport INT	

	IF @VirtualMultiplier <> ''
	BEGIN				
		EXEC sp_xml_preparedocument @DocHandlerSport OUTPUT, @virtualmultiplier

		INSERT INTO #New_VRCustSetting(LevelID, ValueIDLive, ValueIDNonLive)
		SELECT Data.LevelID,
			Data.ValueIDLive,
			Data.ValueIDNonLive
		FROM OPENXML (@DocHandlerSport, '/Root/Row',1) 
		WITH (
			LevelID	INT,
			ValueIDLive TINYINT,
			ValueIDNonLive TINYINT	
		) AS Data

		EXEC sp_xml_removedocument @DocHandlerSport
	END

	--DELETE FROM #New_VRCustSetting WHERE ValueIDLive = 0 AND ValueIDNonLive = 0

	IF (OBJECT_ID('VRCustSetting') IS NOT NULL AND OBJECT_ID('VRSettingHierarchy') IS NOT NULL )
	BEGIN

		UPDATE main
		SET main.ValueIDLIVE = vr.ValueIDLive
			, main.ValueIDNonLIVE = vr.ValueIDNonLIVE
			, main.RepUpdateTime = [dbo].[f_GetDateTime2]()
		FROM VRCustSetting main
			INNER JOIN #New_VRCustSetting VR ON main.CustID = @custid AND VR.LevelID = main.LevelID
			INNER JOIN VRSettingHierarchy H WITH (NOLOCK) ON VR.LevelID = H.LevelID
		WHERE H.SportType = @Sporttype

		DELETE V
		OUTPUT deleted.custid, deleted.LevelID, [dbo].[f_GetDateTime2]() 
		INTO VRCustSetting_Del_Inhouse(custid,LevelID,RepUpdateTime)
		FROM VRCustSetting V WITH (ROWLOCK) 
			INNER JOIN VRSettingHierarchy H WITH (NOLOCK) ON V.LevelID = H.LevelID
		WHERE custid = @custid
			AND (V.LevelID NOT IN (SELECT LevelID FROM #New_VRCustSetting)
				OR (ValueIDLive = 0 AND ValueIDNonLive = 0)
				)
			AND H.SportType = @Sporttype
			
		INSERT INTO [dbo].[VRCustSetting]
           ([CustID]
           ,[LevelID]
           ,[ValueIDLIVE]
           ,[ValueIDNonLIVE]
		   ,RepUpdateTime)
		SELECT @custid [CustID]
           ,VR.[LevelID]
           ,VR.[ValueIDLIVE]
           ,VR.[ValueIDNonLIVE]
		   , [dbo].[f_GetDateTime2]() AS RepUpdateTime
		FROM #New_VRCustSetting VR WITH (NOLOCK) INNER JOIN VRSettingHierarchy H WITH (NOLOCK) ON VR.LevelID = H.LevelID
		WHERE VR.[LevelID] NOT IN (SELECT LevelID FROM [VRCustSetting] WITH (NOLOCK) WHERE CustID=@custid)
			AND H.SportType = @Sporttype
			AND (VR.ValueIDLive <> 0 OR VR.ValueIDNonLive <> 0)
	END
END
ELSE IF	@action = 'VirtualMultiplier'
BEGIN
	DECLARE	@tblVirtualrate		TABLE (
									SportType			INT
								,	BetType				INT
								,	IsLive				BIT
								,	VirtualMultiplier	SMALLMONEY	
								);
								
	DECLARE	@DocHandler				INT
		,	@EnableVirtualrateOld	BIT;

	DECLARE	@virtualXML_Soccer	TABLE (
									seqNo				TINYINT PRIMARY KEY
								,	Pos			VARBINARY(64)
								,	Val			VARBINARY(64)
								);
	DECLARE	@virtualXML_Basketball		TABLE ( --Basketball
									seqNo				TINYINT PRIMARY KEY
								,	Pos			VARBINARY(64)
								,	Val			VARBINARY(64)
								);
	DECLARE	@virtualXML_OS		TABLE ( --other sport except basketball and Esport
									seqNo				TINYINT PRIMARY KEY
								,	Pos			VARBINARY(64)
								,	Val			VARBINARY(64)
								);


	CREATE TABLE #tblCustVR (custID INT)
	CREATE TABLE #tmpCustBatchVR (CustID INT PRIMARY KEY)	
	DECLARE @batchUpdate INT = 2000,
			@maxcustid INT					
	
	IF	@virtualmultiplier <> ''
	BEGIN			
		-- For read xml					
		EXECUTE sp_xml_preparedocument @DocHandler OUTPUT, @virtualmultiplier;

		INSERT INTO	@tblVirtualrate (
						SportType
					,	BetType
					,	IsLive
					,	VirtualMultiplier
				)
		SELECT	Data.SportType
			,	Data.BetType
			,	Data.IsLive
			,	Data.VirtualMultiplier
		FROM OPENXML (@DocHandler, '/ROOT/Rate',1) 
		WITH (	SportType			SMALLINT
			,	BetType				SMALLINT
			,	IsLive				BIT
			,	VirtualMultiplier	SMALLMONEY	
		) AS Data;

		EXECUTE sp_xml_removedocument @DocHandler;
		-- end read xml
	END;	
	
	SELECT	@EnableVirtualrateOld = virtualmultiplier
	FROM	CustInfo WITH (NOLOCK)
	WHERE	custid = @custid;
	
	DECLARE @BetTradeAccount TABLE (CustID INT)
	
	IF	(OBJECT_ID('CustVirtualSetting') IS NOT NULL AND (SELECT TOP 1 1 FROM @tblVirtualrate) IS NOT NULL)
	BEGIN
		INSERT INTO @virtualXML_Soccer
			(	seqNo, Pos, Val                       )
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
				WHERE	ipvs.seqNo = pvs.seqNo AND tmp.SportType = 1
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
				WHERE	ipvs.seqNo = pvs.seqNo AND tmp.SportType = 1
				FOR XML PATH ('')						
			), 2) AS Val
		) p2;
		INSERT INTO @virtualXML_Basketball																														
			(	seqNo, Pos, Val                       )																				
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
				WHERE	ipvs.seqNo = pvs.seqNo AND tmp.SportType = 2									
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
				WHERE	ipvs.seqNo = pvs.seqNo AND tmp.SportType = 2									
				FOR XML PATH ('')																						
			), 2) AS Val																				
		) p2;																							
		INSERT INTO @virtualXML_OS 
			(	seqNo, Pos, Val                       )
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
				WHERE	ipvs.seqNo = pvs.seqNo AND tmp.SportType NOT IN (1, 2, 43)								
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
				WHERE	ipvs.seqNo = pvs.seqNo AND tmp.SportType NOT IN (1, 2, 43)								
				FOR XML PATH ('')						
			), 2) AS Val
		) p2;

		--> Update VR for itself --soccer
		UPDATE cvs
		SET cvs.bitmapVirtual = bm.bitmap
			, cvs.RepUpdateTime = [dbo].[f_GetDateTime2]()
		FROM		CustVirtualSetting	AS cvs WITH(UPDLOCK, ROWLOCK)
		INNER JOIN	custInfo			AS ci WITH(NOLOCK)
				ON	ci.custid = cvs.custid
		INNER JOIN	@virtualXML_Soccer			AS tmp
				ON	cvs.seqNo = tmp.seqNo
		CROSS APPLY (SELECT TOP 1 bitmap FROM dbo.f_GenerateVirtualSetting_inline(cvs.bitmapVirtual, tmp.Val, tmp.Pos)) AS bm
		WHERE	ci.custid = @custid;

		--> Update VR for itself --Basketball									
		UPDATE cvs																
		SET cvs.bitmapVirtual = bm.bitmap	
			, cvs.RepUpdateTime = [dbo].[f_GetDateTime2]()									
		FROM		CustVirtualSetting	AS cvs WITH(UPDLOCK, ROWLOCK)			
		INNER JOIN	custInfo			AS ci WITH(NOLOCK)						
				ON	ci.custid = cvs.custid										
		INNER JOIN	@virtualXML_Basketball			AS tmp						
				ON	cvs.seqNo = tmp.seqNo										
		CROSS APPLY (SELECT TOP 1 bitmap FROM dbo.f_GenerateVirtualSetting_inline(cvs.bitmapVirtual, tmp.Val, tmp.Pos)) AS bm	
		WHERE	ci.custid = @custid;											

		--> Update VR for itself --Other sports
		UPDATE cvs
		SET cvs.bitmapVirtual = bm.bitmap
			, cvs.RepUpdateTime = [dbo].[f_GetDateTime2]()
		FROM		CustVirtualSetting	AS cvs WITH(UPDLOCK, ROWLOCK)
		INNER JOIN	custInfo			AS ci WITH(NOLOCK)
				ON	ci.custid = cvs.custid
		INNER JOIN	@virtualXML_OS			AS tmp
				ON	cvs.seqNo = tmp.seqNo
		CROSS APPLY (SELECT TOP 1 bitmap FROM dbo.f_GenerateVirtualSetting_inline(cvs.bitmapVirtual, tmp.Val, tmp.Pos)) AS bm
		WHERE	ci.custid = @custid;

		--update batch 2k cust for CustVirtualSetting coz each customer has 3 seqNo
		SET @batchUpdate = 2000	

		IF @roleid = 1
		BEGIN
			RETURN --Not update VR for its downline
		END
		ELSE IF NOT EXISTS (SELECT 1 FROM @virtualXML_Soccer) 
				AND NOT EXISTS (SELECT 1 FROM @virtualXML_OS)
				AND NOT EXISTS (SELECT 1 FROM @virtualXML_Basketball)			
		BEGIN
			RETURN --Not update VR for its downline
		END
		ELSE IF @roleid = 4
		BEGIN
			DELETE #tblCustVR
			
			INSERT INTO #tblCustVR(custID)
			SELECT ci.custid
			FROM dbo.custInfo ci WITH (NOLOCK)
			WHERE	ci.srecommend = @custid AND ci.custid <> @custid

			SELECT @maxcustid = ISNULL(MAX(custID),0)
			FROM #tblCustVR

			--> not scan to update for downline with have VR status Locked all sports
			DELETE t
			FROM #tblCustVR t
				INNER JOIN VRCustLockStatus l1 WITH(NOLOCK) ON t.custID = l1.CustID AND l1.Type = 1
				INNER JOIN VRCustLockStatus l2 WITH(NOLOCK) ON t.custID = l2.CustID AND l2.Type = 2
				INNER JOIN VRCustLockStatus l3 WITH(NOLOCK) ON t.custID = l3.CustID AND l3.Type = 3		
			WHILE(1=1)
			BEGIN
				TRUNCATE TABLE #tmpCustBatchVR
				
				DELETE TOP (@batchUpdate) t
				OUTPUT DELETED.custid INTO #tmpCustBatchVR
				FROM #tblCustVR t
				
				IF @@rowcount = 0 
					BREAK;
				
				--> Update Soccer VR
				UPDATE cvs
				SET cvs.bitmapVirtual = bm.bitmap
					, cvs.RepUpdateTime = [dbo].[f_GetDateTime2]()	
				FROM	#tmpCustBatchVR tmpCust
					CROSS APPLY (
						SELECT TOP 3 cvs.seqNo, cvs.bitmapVirtual, cvs.RepUpdateTime
						FROM CustVirtualSetting	AS cvs WITH (UPDLOCK, ROWLOCK)
						WHERE cvs.custID = tmpCust.custID
					) cvs
					CROSS APPLY (
						SELECT TOP 1 bm.bitmap
						FROM @virtualXML_Soccer	AS tmp
							CROSS APPLY dbo.f_GenerateVirtualSetting_inline(cvs.bitmapVirtual, tmp.Val, tmp.Pos) AS bm
						WHERE cvs.seqNo = tmp.seqNo
					) bm
				 WHERE	NOT EXISTS (
						SELECT	1
						FROM	VRCustLockStatus lm WITH(NOLOCK)
						WHERE	lm.custID = tmpCust.custid 
								AND lm.Type = 1
					)

				--> Update Basketball VR												
				UPDATE cvs																
				SET cvs.bitmapVirtual = bm.bitmap
					, cvs.RepUpdateTime = [dbo].[f_GetDateTime2]()											
				FROM	#tmpCustBatchVR tmpCust											
					CROSS APPLY (														
						SELECT TOP 3 cvs.seqNo, cvs.bitmapVirtual, cvs.RepUpdateTime						
						FROM CustVirtualSetting	AS cvs WITH (UPDLOCK, ROWLOCK)			
						WHERE cvs.custID = tmpCust.custID								
					) cvs																
					CROSS APPLY (														
						SELECT TOP 1 bm.bitmap											
						FROM @virtualXML_Basketball	AS tmp								
							CROSS APPLY dbo.f_GenerateVirtualSetting_inline(cvs.bitmapVirtual, tmp.Val, tmp.Pos) AS bm		
						WHERE cvs.seqNo = tmp.seqNo										
					) bm																
				 WHERE	NOT EXISTS (													
						SELECT	1														
						FROM	VRCustLockStatus lm WITH(NOLOCK)						
						WHERE	lm.custID = tmpCust.custid 								
								AND lm.Type = 3											
					)																	

				--> Update OtherSport VR
				UPDATE cvs
				SET cvs.bitmapVirtual = bm.bitmap
					, cvs.RepUpdateTime = [dbo].[f_GetDateTime2]()		
				FROM	#tmpCustBatchVR tmpCust
					CROSS APPLY (
						SELECT TOP 3 cvs.seqNo, cvs.bitmapVirtual, cvs.RepUpdateTime
						FROM CustVirtualSetting	AS cvs WITH (UPDLOCK, ROWLOCK)
						WHERE cvs.custID = tmpCust.custID
					) cvs
					CROSS APPLY (
						SELECT TOP 1 bm.bitmap
						FROM @virtualXML_OS	AS tmp
							CROSS APPLY dbo.f_GenerateVirtualSetting_inline(cvs.bitmapVirtual, tmp.Val, tmp.Pos) AS bm
						WHERE cvs.seqNo = tmp.seqNo
					) bm
				 WHERE	NOT EXISTS (
						SELECT	1
						FROM	VRCustLockStatus lm WITH(NOLOCK)
						WHERE	lm.custID = tmpCust.custid 
								AND lm.Type = 2
					)
			END	
			
			--> Update for new accounts
			UPDATE cvs					
			SET cvs.bitmapVirtual = bm.bitmap
				, cvs.RepUpdateTime = [dbo].[f_GetDateTime2]()	
			FROM		CustVirtualSetting	AS cvs WITH (UPDLOCK, ROWLOCK)
			INNER JOIN	custInfo			AS ci WITH (NOLOCK)
					ON	ci.custid = cvs.custid
			INNER JOIN	@virtualXML_Soccer			AS tmp
					ON	cvs.seqNo = tmp.seqNo
			CROSS APPLY (SELECT TOP 1 bitmap FROM dbo.f_GenerateVirtualSetting_inline(cvs.bitmapVirtual, tmp.Val, tmp.Pos)) AS bm
			WHERE	ci.srecommend = @custid
				AND ci.custID > @maxcustid
				AND	NOT EXISTS (
						SELECT	1
						FROM	VRCustLockStatus lm WITH(NOLOCK)
						WHERE	lm.custID = ci.custid 
								AND lm.Type = 1
					)

			UPDATE cvs																
			SET cvs.bitmapVirtual = bm.bitmap
				, cvs.RepUpdateTime = [dbo].[f_GetDateTime2]()											
			FROM		CustVirtualSetting	AS cvs WITH (UPDLOCK, ROWLOCK)			
			INNER JOIN	custInfo			AS ci WITH (NOLOCK)						
					ON	ci.custid = cvs.custid										
			INNER JOIN	@virtualXML_Basketball			AS tmp						
					ON	cvs.seqNo = tmp.seqNo										
			CROSS APPLY (SELECT TOP 1 bitmap FROM dbo.f_GenerateVirtualSetting_inline(cvs.bitmapVirtual, tmp.Val, tmp.Pos)) AS bm		
			WHERE	ci.srecommend = @custid											
				AND ci.custID > @maxcustid											
				AND	NOT EXISTS (													
						SELECT	1													
						FROM	VRCustLockStatus lm WITH(NOLOCK)					
						WHERE	lm.custID = ci.custid 								
								AND lm.Type = 3										
					)																

			UPDATE cvs
			SET cvs.bitmapVirtual = bm.bitmap
				, cvs.RepUpdateTime = [dbo].[f_GetDateTime2]()	
			FROM		CustVirtualSetting	AS cvs WITH (UPDLOCK, ROWLOCK)
			INNER JOIN	custInfo			AS ci WITH (NOLOCK)
					ON	ci.custid = cvs.custid
			INNER JOIN	@virtualXML_OS			AS tmp
					ON	cvs.seqNo = tmp.seqNo
			CROSS APPLY (SELECT TOP 1 bitmap FROM dbo.f_GenerateVirtualSetting_inline(cvs.bitmapVirtual, tmp.Val, tmp.Pos)) AS bm
			WHERE	ci.srecommend = @custid
				AND ci.custID > @maxcustid
				AND	NOT EXISTS (
						SELECT	1
						FROM	VRCustLockStatus lm WITH(NOLOCK)
						WHERE	lm.custID = ci.custid 
								AND lm.Type = 2
					)
		END;
		ELSE IF @roleid = 3
		BEGIN
			DELETE #tblCustVR

			INSERT INTO #tblCustVR(custID)
			SELECT ci.custid
			FROM dbo.custInfo ci WITH (NOLOCK)
			WHERE	ci.mrecommend = @custid  AND ci.custid <> @custid

			SELECT @maxcustid = ISNULL(MAX(custID),0)
			FROM #tblCustVR

			--> not scan to update for downline with have VR status Locked all sports
			DELETE t
			FROM #tblCustVR t
				INNER JOIN VRCustLockStatus l1 WITH(NOLOCK) ON t.custID = l1.CustID AND l1.Type = 1
				INNER JOIN VRCustLockStatus l2 WITH(NOLOCK) ON t.custID = l2.CustID AND l2.Type = 2
				INNER JOIN VRCustLockStatus l3 WITH(NOLOCK) ON t.custID = l3.CustID AND l3.Type = 3			
			WHILE(1=1)
			BEGIN
				TRUNCATE TABLE #tmpCustBatchVR
				
				DELETE TOP (@batchUpdate) t
				OUTPUT DELETED.custid INTO #tmpCustBatchVR
				FROM #tblCustVR t
				
				IF @@rowcount = 0 
					BREAK;

				--> Update Soccer VR
				UPDATE cvs
				SET cvs.bitmapVirtual = bm.bitmap
				, cvs.RepUpdateTime =  [dbo].[f_GetDateTime2]()
				FROM	#tmpCustBatchVR tmpCust
					CROSS APPLY (
						SELECT TOP 3 cvs.seqNo, cvs.bitmapVirtual, cvs.RepUpdateTime
						FROM CustVirtualSetting	AS cvs WITH (UPDLOCK, ROWLOCK)
						WHERE cvs.custID = tmpCust.custID
					) cvs
					CROSS APPLY (
						SELECT TOP 1 bm.bitmap
						FROM @virtualXML_Soccer	AS tmp
							CROSS APPLY dbo.f_GenerateVirtualSetting_inline(cvs.bitmapVirtual, tmp.Val, tmp.Pos) AS bm
						WHERE cvs.seqNo = tmp.seqNo
					) bm
				 WHERE	NOT EXISTS (
						SELECT	1
						FROM	VRCustLockStatus lm WITH(NOLOCK)
						WHERE	lm.custID = tmpCust.custid 
								AND lm.Type = 1
					)

				--> Update Basketball VR												
				UPDATE cvs																
				SET cvs.bitmapVirtual = bm.bitmap
				, cvs.RepUpdateTime =  [dbo].[f_GetDateTime2]()										
				FROM	#tmpCustBatchVR tmpCust											
					CROSS APPLY (														
						SELECT TOP 3 cvs.seqNo, cvs.bitmapVirtual, cvs.RepUpdateTime						
						FROM CustVirtualSetting	AS cvs WITH (UPDLOCK, ROWLOCK)			
						WHERE cvs.custID = tmpCust.custID								
					) cvs																
					CROSS APPLY (														
						SELECT TOP 1 bm.bitmap											
						FROM @virtualXML_Basketball	AS tmp								
							CROSS APPLY dbo.f_GenerateVirtualSetting_inline(cvs.bitmapVirtual, tmp.Val, tmp.Pos) AS bm			
						WHERE cvs.seqNo = tmp.seqNo										
					) bm																
				 WHERE	NOT EXISTS (													
						SELECT	1														
						FROM	VRCustLockStatus lm WITH(NOLOCK)						
						WHERE	lm.custID = tmpCust.custid 								
								AND lm.Type = 3											
					)																	

				--> Update OtherSport VR
				UPDATE cvs
				SET cvs.bitmapVirtual = bm.bitmap
				  , cvs.RepUpdateTime = [dbo].[f_GetDateTime2]()
				FROM	#tmpCustBatchVR tmpCust
					CROSS APPLY (
						SELECT TOP 3 cvs.seqNo, cvs.bitmapVirtual, cvs.RepUpdateTime
						FROM CustVirtualSetting	AS cvs WITH (UPDLOCK, ROWLOCK)
						WHERE cvs.custID = tmpCust.custID
					) cvs
					CROSS APPLY (
						SELECT TOP 1 bm.bitmap
						FROM @virtualXML_OS	AS tmp
							CROSS APPLY dbo.f_GenerateVirtualSetting_inline(cvs.bitmapVirtual, tmp.Val, tmp.Pos) AS bm
						WHERE cvs.seqNo = tmp.seqNo
					) bm
				 WHERE	NOT EXISTS (
						SELECT	1
						FROM	VRCustLockStatus lm WITH(NOLOCK)
						WHERE	lm.custID = tmpCust.custid 
								AND lm.Type = 2
					)
			END	
			
			--> Update for new accounts
			UPDATE cvs
			SET cvs.bitmapVirtual = bm.bitmap
				, cvs.RepUpdateTime = [dbo].[f_GetDateTime2]()
			FROM		CustVirtualSetting	AS cvs WITH (UPDLOCK, ROWLOCK)
			INNER JOIN	custInfo			AS ci WITH (NOLOCK)
					ON	ci.custid = cvs.custid
			INNER JOIN	@virtualXML_Soccer			AS tmp
					ON	cvs.seqNo = tmp.seqNo
			CROSS APPLY (SELECT TOP 1 bitmap FROM dbo.f_GenerateVirtualSetting_inline(cvs.bitmapVirtual, tmp.Val, tmp.Pos)) AS bm
			WHERE	ci.mrecommend = @custid
				AND ci.custID > @maxcustid
				AND	NOT EXISTS (
						SELECT	1
						FROM	VRCustLockStatus lm WITH(NOLOCK)
						WHERE	lm.custID = ci.custid 
								AND lm.Type = 1
					)

			UPDATE cvs																		
			SET cvs.bitmapVirtual = bm.bitmap
				, cvs.RepUpdateTime = [dbo].[f_GetDateTime2]()											
			FROM		CustVirtualSetting	AS cvs WITH (UPDLOCK, ROWLOCK)					
			INNER JOIN	custInfo			AS ci WITH (NOLOCK)								
					ON	ci.custid = cvs.custid												
			INNER JOIN	@virtualXML_Basketball			AS tmp								
					ON	cvs.seqNo = tmp.seqNo												
			CROSS APPLY (SELECT TOP 1 bitmap FROM dbo.f_GenerateVirtualSetting_inline(cvs.bitmapVirtual, tmp.Val, tmp.Pos)) AS bm		
			WHERE	ci.mrecommend = @custid													
				AND ci.custID > @maxcustid													
				AND	NOT EXISTS (															
						SELECT	1															
						FROM	VRCustLockStatus lm WITH(NOLOCK)							
						WHERE	lm.custID = ci.custid 										
								AND lm.Type = 3												
					)																		

			UPDATE cvs
			SET cvs.bitmapVirtual = bm.bitmap
				, cvs.RepUpdateTime = [dbo].[f_GetDateTime2]()
			FROM		CustVirtualSetting	AS cvs WITH (UPDLOCK, ROWLOCK)
			INNER JOIN	custInfo			AS ci WITH (NOLOCK)
					ON	ci.custid = cvs.custid
			INNER JOIN	@virtualXML_OS			AS tmp
					ON	cvs.seqNo = tmp.seqNo
			CROSS APPLY (SELECT TOP 1 bitmap FROM dbo.f_GenerateVirtualSetting_inline(cvs.bitmapVirtual, tmp.Val, tmp.Pos)) AS bm
			WHERE	ci.mrecommend = @custid
				AND ci.custID > @maxcustid
				AND	NOT EXISTS (
						SELECT	1
						FROM	VRCustLockStatus lm WITH(NOLOCK)
						WHERE	lm.custID = ci.custid 
								AND lm.Type = 2
					)
		END;
		ELSE IF @roleid = 2
		BEGIN
			DELETE #tblCustVR

			INSERT INTO #tblCustVR(custID)
			SELECT ci.custid
			FROM dbo.custInfo ci WITH (NOLOCK)
			WHERE	ci.recommend = @custid  AND ci.custid <> @custid

			SELECT @maxcustid = ISNULL(MAX(custID),0)
			FROM #tblCustVR
			
			--> not scan to update for downline with have VR status Locked all sports
			DELETE t
			FROM #tblCustVR t
				INNER JOIN VRCustLockStatus l1 WITH(NOLOCK) ON t.custID = l1.CustID AND l1.Type = 1
				INNER JOIN VRCustLockStatus l2 WITH(NOLOCK) ON t.custID = l2.CustID AND l2.Type = 2
				INNER JOIN VRCustLockStatus l3 WITH(NOLOCK) ON t.custID = l3.CustID AND l3.Type = 3		
			WHILE(1=1)
			BEGIN
				TRUNCATE TABLE #tmpCustBatchVR
				
				DELETE TOP (@batchUpdate) t
				OUTPUT DELETED.custid INTO #tmpCustBatchVR
				FROM #tblCustVR t
				
				IF @@rowcount = 0 
					BREAK;
				
				--> Update Soccer VR
				UPDATE cvs
				SET cvs.bitmapVirtual = bm.bitmap
				, cvs.RepUpdateTime = [dbo].[f_GetDateTime2]()
				FROM	#tmpCustBatchVR tmpCust
					CROSS APPLY (
						SELECT TOP 3 cvs.seqNo, cvs.bitmapVirtual, cvs.RepUpdateTime
						FROM CustVirtualSetting	AS cvs WITH (UPDLOCK, ROWLOCK)
						WHERE cvs.custID = tmpCust.custID
					) cvs
					CROSS APPLY (
						SELECT TOP 1 bm.bitmap
						FROM @virtualXML_Soccer	AS tmp
							CROSS APPLY dbo.f_GenerateVirtualSetting_inline(cvs.bitmapVirtual, tmp.Val, tmp.Pos) AS bm
						WHERE cvs.seqNo = tmp.seqNo
					) bm
				 WHERE	NOT EXISTS (
						SELECT	1
						FROM	VRCustLockStatus lm WITH(NOLOCK)
						WHERE	lm.custID = tmpCust.custid 
								AND lm.Type = 1
					)

				--> Update Basketball VR												
				UPDATE cvs																
				SET cvs.bitmapVirtual = bm.bitmap
				, cvs.RepUpdateTime = [dbo].[f_GetDateTime2]()										
				FROM	#tmpCustBatchVR tmpCust											
					CROSS APPLY (														
						SELECT TOP 3 cvs.seqNo, cvs.bitmapVirtual, cvs.RepUpdateTime						
						FROM CustVirtualSetting	AS cvs WITH (UPDLOCK, ROWLOCK)			
						WHERE cvs.custID = tmpCust.custID								
					) cvs																
					CROSS APPLY (														
						SELECT TOP 1 bm.bitmap											
						FROM @virtualXML_Basketball	AS tmp								
							CROSS APPLY dbo.f_GenerateVirtualSetting_inline(cvs.bitmapVirtual, tmp.Val, tmp.Pos) AS bm		
						WHERE cvs.seqNo = tmp.seqNo										
					) bm																
				 WHERE	NOT EXISTS (													
						SELECT	1														
						FROM	VRCustLockStatus lm WITH(NOLOCK)						
						WHERE	lm.custID = tmpCust.custid 								
								AND lm.Type = 3											
					)																	

				--> Update OtherSport VR
				UPDATE cvs
				SET cvs.bitmapVirtual = bm.bitmap
				, cvs.RepUpdateTime = [dbo].[f_GetDateTime2]()
				FROM	#tmpCustBatchVR tmpCust
					CROSS APPLY (
						SELECT TOP 3 cvs.seqNo, cvs.bitmapVirtual, cvs.RepUpdateTime
						FROM CustVirtualSetting	AS cvs WITH (UPDLOCK, ROWLOCK)
						WHERE cvs.custID = tmpCust.custID
					) cvs
					CROSS APPLY (
						SELECT TOP 1 bm.bitmap
						FROM @virtualXML_OS	AS tmp
							CROSS APPLY dbo.f_GenerateVirtualSetting_inline(cvs.bitmapVirtual, tmp.Val, tmp.Pos) AS bm
						WHERE cvs.seqNo = tmp.seqNo
					) bm
				 WHERE	NOT EXISTS (
						SELECT	1
						FROM	VRCustLockStatus lm WITH(NOLOCK)
						WHERE	lm.custID = tmpCust.custid 
								AND lm.Type = 2
					)
			END	
			
			--> Update for new accounts
			UPDATE cvs
			SET cvs.bitmapVirtual = bm.bitmap
				, cvs.RepUpdateTime = [dbo].[f_GetDateTime2]()
			FROM		CustVirtualSetting	AS cvs WITH (UPDLOCK, ROWLOCK)
			INNER JOIN	custInfo			AS ci WITH (NOLOCK)
					ON	ci.custid = cvs.custid
			INNER JOIN	@virtualXML_Soccer			AS tmp
					ON	cvs.seqNo = tmp.seqNo
			CROSS APPLY (SELECT TOP 1 bitmap FROM dbo.f_GenerateVirtualSetting_inline(cvs.bitmapVirtual, tmp.Val, tmp.Pos)) AS bm
			WHERE	ci.recommend = @custid
				AND ci.custID > @maxcustid
				AND	NOT EXISTS (
						SELECT	1
						FROM	VRCustLockStatus lm WITH(NOLOCK)
						WHERE	lm.custID = ci.custid 
								AND lm.Type = 1
					)

			UPDATE cvs																
			SET cvs.bitmapVirtual = bm.bitmap
				, cvs.RepUpdateTime = [dbo].[f_GetDateTime2]()										
			FROM		CustVirtualSetting	AS cvs WITH (UPDLOCK, ROWLOCK)			
			INNER JOIN	custInfo			AS ci WITH (NOLOCK)						
					ON	ci.custid = cvs.custid										
			INNER JOIN	@virtualXML_Basketball			AS tmp						
					ON	cvs.seqNo = tmp.seqNo										
			CROSS APPLY (SELECT TOP 1 bitmap FROM dbo.f_GenerateVirtualSetting_inline(cvs.bitmapVirtual, tmp.Val, tmp.Pos)) AS bm		
			WHERE	ci.recommend = @custid											
				AND ci.custID > @maxcustid											
				AND	NOT EXISTS (													
						SELECT	1													
						FROM	VRCustLockStatus lm WITH(NOLOCK)					
						WHERE	lm.custID = ci.custid 								
								AND lm.Type = 3										
					)																

			UPDATE cvs
			SET cvs.bitmapVirtual = bm.bitmap
				, cvs.RepUpdateTime = [dbo].[f_GetDateTime2]()
			FROM		CustVirtualSetting	AS cvs WITH (UPDLOCK, ROWLOCK)
			INNER JOIN	custInfo			AS ci WITH (NOLOCK)
					ON	ci.custid = cvs.custid
			INNER JOIN	@virtualXML_OS			AS tmp
					ON	cvs.seqNo = tmp.seqNo
			CROSS APPLY (SELECT TOP 1 bitmap FROM dbo.f_GenerateVirtualSetting_inline(cvs.bitmapVirtual, tmp.Val, tmp.Pos)) AS bm
			WHERE	ci.recommend = @custid
				AND ci.custID > @maxcustid
				AND	NOT EXISTS (
						SELECT	1
						FROM	VRCustLockStatus lm WITH(NOLOCK)
						WHERE	lm.custID = ci.custid 
								AND lm.Type = 2
					)
		END;
	END;

	DROP TABLE #tblCustVR
	DROP TABLE #tmpCustBatchVR
END;
ELSE IF	OBJECT_ID('custinfo') IS NOT NULL
BEGIN
    IF @action = 'ApplyVRAccBalanceAllDownlines' 
	BEGIN
		IF OBJECT_ID('VRCustLockStatus') IS NOT NULL	
		BEGIN
			
			CREATE TABLE #TblCustDownline_VRAccBalance			(custID INT)
			CREATE TABLE #TblCustDownline_tmpBatch_VRAccBalance (CustID INT PRIMARY KEY)	
			DECLARE @VRAccBalance_batchUpdate INT = 2000
		
			IF @roleid = 4
			BEGIN
				INSERT INTO #TblCustDownline_VRAccBalance(custID)
				SELECT c.custid
				FROM CustInfo c WITH (NOLOCK)
				WHERE c.srecommend = @custid
					AND c.Enabled = 1
			END
			ELSE IF @roleid = 3
			BEGIN
				INSERT INTO #TblCustDownline_VRAccBalance(custID)
				SELECT c.custid
				FROM CustInfo c WITH (NOLOCK)
				WHERE c.mrecommend = @custid
					AND c.Enabled = 1
			END
			ELSE IF @roleid = 2
			BEGIN
				INSERT INTO #TblCustDownline_VRAccBalance(custID)
				SELECT c.custid
				FROM CustInfo c WITH (NOLOCK)
				WHERE c.recommend = @custid
					AND c.Enabled = 1
			END

			IF NOT EXISTS( SELECT TOP 1 1 FROM #TblCustDownline_VRAccBalance)
				RETURN

			IF @VRAccumulate_Balance = 0
			BEGIN
				WHILE(1=1)
				BEGIN
					TRUNCATE TABLE #TblCustDownline_tmpBatch_VRAccBalance
				
					DELETE TOP (@VRAccBalance_batchUpdate) t
					OUTPUT DELETED.custid INTO #TblCustDownline_tmpBatch_VRAccBalance
					FROM #TblCustDownline_VRAccBalance t
				
					IF @@rowcount = 0 
						BREAK;

					DELETE vr
					OUTPUT deleted.custid, deleted.Type, [dbo].[f_GetDateTime2]() 
					INTO VRCustLockStatus_Del_Inhouse(custid,Type,RepUpdateTime)
					FROM VRCustLockStatus vr WITH (ROWLOCK, UPDLOCK)
					INNER JOIN #TblCustDownline_tmpBatch_VRAccBalance tmp ON vr.CustID = tmp.CustID
					WHERE vr.Type = 4
				END		
			END

			ELSE
			BEGIN
				WHILE(1=1)
				BEGIN
					TRUNCATE TABLE #TblCustDownline_tmpBatch_VRAccBalance
				
					DELETE TOP (@VRAccBalance_batchUpdate) tem
					OUTPUT DELETED.custid INTO #TblCustDownline_tmpBatch_VRAccBalance
					FROM #TblCustDownline_VRAccBalance tem WITH (NOLOCK)
					WHERE NOT EXISTS (SELECT 1 FROM VRCustLockStatus vr WITH (NOLOCK) WHERE vr.CustID = tem.custID AND vr.Type = 4) 
				
					IF @@rowcount = 0 
						BREAK;

					INSERT INTO VRCustLockStatus (CustID , Type, RepUpdateTime)
					SELECT CustID , 4, [dbo].[f_GetDateTime2]() AS RepUpdateTime
					FROM #TblCustDownline_tmpBatch_VRAccBalance
				END		
			END

			DROP TABLE #TblCustDownline_VRAccBalance	
			DROP TABLE #TblCustDownline_tmpBatch_VRAccBalance
		
		END
	END

	ELSE IF @Action = 'EnableVRLockStatus'--execrep just use for enable 
	BEGIN
		--IF OBJECT_ID (N'VRCustLockStatus', N'U') IS NOT NULL --check table is existing ?
		IF OBJECT_ID('VRCustLockStatus') IS NOT NULL
		BEGIN
			CREATE TABLE #TblCustDownline (custID INT)
			CREATE TABLE #TblCustDownline_tmpBatch (CustID INT PRIMARY KEY)	
			DECLARE @VRlock_batchUpdate INT = 2000
			CREATE TABLE #TblType (Type TINYINT)

			IF @VRlockStatusType = 0
			BEGIN
				INSERT INTO #TblType (Type)
				SELECT 1	UNION ALL		--soccer
				SELECT 2	UNION ALL		--Other sports			
				SELECT 3					--Basketball			
			END
			ELSE IF @VRlockStatusType = 1
			BEGIN
				INSERT INTO #TblType (Type)
				SELECT 1  --soccer
			END
			ELSE IF @VRlockStatusType = 2
			BEGIN
				INSERT INTO #TblType (Type)
				SELECT 2  --Other sports
			END
			ELSE IF @VRlockStatusType = 3			
			BEGIN								
				INSERT INTO #TblType (Type)		
				SELECT 3  --Basketball			
			END	
			ELSE
			BEGIN
				RETURN
			END

			--> Insert for main account
			INSERT INTO VRCustLockStatus(CustID,Type,RepUpdateTime)
			SELECT @custid,Type, [dbo].[f_GetDateTime2]() AS RepUpdateTime
			FROM #TblType t
			WHERE NOT EXISTS ( SELECT 1 FROM VRCustLockStatus WITH(NOLOCK) WHERE custid = @custid and Type = t.Type)

			--Process locked for downline by batch update
			IF @roleid = 4
			BEGIN
				INSERT INTO #TblCustDownline(custID)
				SELECT ci.custid
				FROM dbo.custInfo ci WITH (NOLOCK)
				WHERE	ci.srecommend = @custid AND ci.custid <> @custid
			END
			ELSE IF @roleid = 3
			BEGIN
				INSERT INTO #TblCustDownline(custID)
				SELECT ci.custid
				FROM dbo.custInfo ci WITH (NOLOCK)
				WHERE ci.mrecommend = @custid AND ci.custid <> @custid
			END
			ELSE IF @roleid = 2
			BEGIN
				INSERT INTO #TblCustDownline(custID)
				SELECT ci.custid
				FROM dbo.custInfo ci WITH (NOLOCK)
				WHERE ci.recommend = @custid AND ci.custid <> @custid
			END

			IF NOT EXISTS( SELECT TOP 1 1 FROM #TblCustDownline)
				RETURN

			WHILE(1=1)
			BEGIN
				TRUNCATE TABLE #TblCustDownline_tmpBatch
				
				DELETE TOP (@VRlock_batchUpdate) t
				OUTPUT DELETED.custid INTO #TblCustDownline_tmpBatch
				FROM #TblCustDownline t
				
				IF @@rowcount = 0 
					BREAK;

				INSERT INTO VRCustLockStatus(CustID,Type,RepUpdateTime)
				SELECT t.CustID,tp.Type, [dbo].[f_GetDateTime2]() AS RepUpdateTime
				FROM  #TblCustDownline_tmpBatch t
					CROSS JOIN #TblType tp
					LEFT JOIN VRCustLockStatus v WITH(NOLOCK) ON t.CustID = v.CustID AND tp.Type = v.Type
				WHERE v.CustID IS NULL
			END		
			
			DROP TABLE #TblCustDownline	
			DROP TABLE #TblCustDownline_tmpBatch
			DROP TABLE #TblType
		END
	END
	
	ELSE IF @Action IN ('EnableABDownline', 'UnlockVRDownline')
	BEGIN
		IF @RoleID = 1 
			RETURN

		CREATE TABLE #tblCustVR_Additional (custID INT, type TINYINT)
		CREATE TABLE #tmpCustBatchVR_Additional (CustID INT, type TINYINT)	
		DECLARE @batchUpdate_Additional INT = 2000

		DECLARE	@RoleID_Unlock3_SC		TINYINT,
				@RoleID_Unlock2_SC		TINYINT,
				@RoleID_Unlock1_SC		TINYINT,

				@RoleID_Unlock3_BB		TINYINT,
				@RoleID_Unlock2_BB		TINYINT,
				@RoleID_Unlock1_BB		TINYINT,

				@RoleID_Unlock3_OS		TINYINT,
				@RoleID_Unlock2_OS		TINYINT,
				@RoleID_Unlock1_OS		TINYINT,

				@RoleID_EnableAB3		TINYINT,
				@RoleID_EnableAB2		TINYINT,
				@RoleID_EnableAB1		TINYINT
		DECLARE @DocHandler_EnableUnlockVR INT
		EXEC sp_xml_preparedocument @DocHandler_EnableUnlockVR OUTPUT, @AdditionalActions

		SELECT
					@RoleID_Unlock3_SC = CASE WHEN @roleid = 4			AND Data.UnlockSC3 = 1 THEN 3 ELSE 0 END,
					@RoleID_Unlock2_SC = CASE WHEN @roleid IN (4,3)		AND Data.UnlockSC2 = 1 THEN 2 ELSE 0 END,
					@RoleID_Unlock1_SC = CASE WHEN @roleid IN (4,3,2)	AND Data.UnlockSC1 = 1 THEN 1 ELSE 0 END,

					@RoleID_Unlock3_BB = CASE WHEN @roleid = 4			AND Data.UnlockBB3 = 1 THEN 3 ELSE 0 END,
					@RoleID_Unlock2_BB = CASE WHEN @roleid IN (4,3)		AND Data.UnlockBB2 = 1 THEN 2 ELSE 0 END,
					@RoleID_Unlock1_BB = CASE WHEN @roleid IN (4,3,2)	AND Data.UnlockBB1 = 1 THEN 1 ELSE 0 END,

					@RoleID_Unlock3_OS = CASE WHEN @roleid = 4			AND Data.UnlockOS3 = 1 THEN 3 ELSE 0 END,
					@RoleID_Unlock2_OS = CASE WHEN @roleid IN (4,3)		AND Data.UnlockOS2 = 1 THEN 2 ELSE 0 END,
					@RoleID_Unlock1_OS = CASE WHEN @roleid IN (4,3,2)	AND Data.UnlockOS1 = 1 THEN 1 ELSE 0 END,

					@RoleID_EnableAB3 = CASE WHEN @roleid = 4			AND Data.EnableAB3 = 1 THEN 3 ELSE 0 END,
					@RoleID_EnableAB2 = CASE WHEN @roleid IN (4,3)		AND Data.EnableAB2 = 1 THEN 2 ELSE 0 END,
					@RoleID_EnableAB1 = CASE WHEN @roleid IN (4,3,2)	AND Data.EnableAB1 = 1 THEN 1 ELSE 0 END
		FROM OPENXML (@DocHandler_EnableUnlockVR, '/ROOT/VR',1) 
		WITH (
			UnlockSC3		TINYINT,
			UnlockSC2		TINYINT,
			UnlockSC1		TINYINT,

			UnlockBB3		TINYINT,
			UnlockBB2		TINYINT,
			UnlockBB1		TINYINT,

			UnlockOS3		TINYINT,
			UnlockOS2		TINYINT,
			UnlockOS1		TINYINT,

			EnableAB3		TINYINT,
			EnableAB2		TINYINT,
			EnableAB1		TINYINT
		) AS Data

		EXEC sp_xml_removedocument @DocHandler_EnableUnlockVR

		IF @action = 'EnableABDownline' AND OBJECT_ID('VRCustLockStatus') IS NOT NULL
		BEGIN
			TRUNCATE TABLE #tblCustVR_Additional

			IF @roleid = 4
			BEGIN	
				INSERT INTO #tblCustVR_Additional(custID, type)
				SELECT custid, 4 AS type
				FROM custInfo WITH (NOLOCK)
				WHERE srecommend = @custid
					AND roleid IN (@RoleID_EnableAB3, @RoleID_EnableAB2, @RoleID_EnableAB1)
			END

			ELSE IF @roleid = 3
			BEGIN
				INSERT INTO #tblCustVR_Additional(custID, type)
				SELECT custid, 4 AS type
				FROM custInfo WITH (NOLOCK)
				WHERE mrecommend = @custid
					AND roleid IN (@RoleID_EnableAB2, @RoleID_EnableAB1)
			END

			ELSE IF @roleid = 2
			BEGIN
				INSERT INTO #tblCustVR_Additional(custID, type)
				SELECT custid, 4 AS type
				FROM custInfo WITH (NOLOCK)
				WHERE recommend = @custid
					AND roleid = @RoleID_EnableAB1
			END

			SET @batchUpdate_Additional = 2000

			WHILE(1=1)
			BEGIN
				TRUNCATE TABLE #tmpCustBatchVR_Additional
				
				DELETE TOP (@batchUpdate_Additional) t
					OUTPUT deleted.custid, deleted.type 
					INTO #tmpCustBatchVR_Additional(CustID, type)
				FROM #tblCustVR_Additional t
				
				IF @@rowcount = 0 
					BREAK;
					
				INSERT INTO VRCustLockStatus(CustID, Type,RepUpdateTime)
				SELECT t.custID, t.type, [dbo].[f_GetDateTime2]() AS RepUpdateTime
				FROM #tmpCustBatchVR_Additional t
				WHERE NOT EXISTS(
					SELECT TOP 1 1
					FROM VRCustLockStatus v WITH (NOLOCK)
					WHERE t.CustID = v.CustID AND t.type = v.Type
				)
			END	
		END
		ELSE IF @action = 'UnlockVRDownline' AND OBJECT_ID('VRCustLockStatus') IS NOT NULL
		BEGIN
			CREATE TABLE #unlockTempCust(custid INT, roleid TINYINT)

			TRUNCATE TABLE #tblCustVR_Additional

			IF @roleid = 4
			BEGIN	
				INSERT INTO #unlockTempCust(custid, roleid)
				SELECT c.custid, c.roleid
				FROM custInfo c WITH (NOLOCK)
				WHERE c.srecommend = @custid

				INSERT INTO #tblCustVR_Additional(custID, type)
				SELECT t.custid, 1 AS type
				FROM #unlockTempCust t WITH (NOLOCK)
				WHERE t.roleid IN (@RoleID_Unlock1_SC, @RoleID_Unlock2_SC, @RoleID_Unlock3_SC)
				UNION ALL
				SELECT t.custid, 3 AS type
				FROM #unlockTempCust t WITH (NOLOCK)
				WHERE t.roleid IN (@RoleID_Unlock1_BB, @RoleID_Unlock2_BB, @RoleID_Unlock3_BB)
				UNION ALL
				SELECT t.custid, 2 AS type
				FROM  #unlockTempCust t WITH (NOLOCK)
				WHERE t.roleid IN (@RoleID_Unlock1_OS, @RoleID_Unlock2_OS, @RoleID_Unlock3_OS)
			END

			ELSE IF @roleid = 3
			BEGIN
				INSERT INTO #unlockTempCust(custid, roleid)
				SELECT c.custid, c.roleid
				FROM custInfo c WITH (NOLOCK)
				WHERE c.mrecommend = @custid

				INSERT INTO #tblCustVR_Additional(custID, type)
				SELECT t.custid, 1 AS type
				FROM #unlockTempCust t WITH (NOLOCK)
				WHERE t.roleid IN (@RoleID_Unlock1_SC, @RoleID_Unlock2_SC)
				UNION ALL
				SELECT t.custid, 3 AS type
				FROM #unlockTempCust t WITH (NOLOCK)
				WHERE t.roleid IN (@RoleID_Unlock1_BB, @RoleID_Unlock2_BB)
				UNION ALL
				SELECT t.custid, 2 AS type
				FROM  #unlockTempCust t WITH (NOLOCK)
				WHERE t.roleid IN (@RoleID_Unlock1_OS, @RoleID_Unlock2_OS)
			END

			ELSE IF @roleid = 2
			BEGIN
				INSERT INTO #unlockTempCust(custid, roleid)
				SELECT c.custid, c.roleid
				FROM custInfo c WITH (NOLOCK)
				WHERE c.recommend = @custid

				INSERT INTO #tblCustVR_Additional(custID, type)
				SELECT t.custid, 1 AS type
				FROM #unlockTempCust t WITH (NOLOCK)
				WHERE t.roleid = @RoleID_Unlock1_SC
				UNION ALL
				SELECT t.custid, 3 AS type
				FROM #unlockTempCust t WITH (NOLOCK)
				WHERE t.roleid = @RoleID_Unlock1_BB
				UNION ALL
				SELECT t.custid, 2 AS type
				FROM  #unlockTempCust t WITH (NOLOCK)
				WHERE t.roleid = @RoleID_Unlock1_OS
			END

			SET @batchUpdate_Additional = 2000

			WHILE(1=1)
			BEGIN
				TRUNCATE TABLE #tmpCustBatchVR_Additional
				
				DELETE TOP (@batchUpdate_Additional) t
				OUTPUT deleted.custid, deleted.type INTO #tmpCustBatchVR_Additional(CustID, type)
				FROM #tblCustVR_Additional t
				
				IF @@rowcount = 0 
					BREAK;
					
				DELETE c
				OUTPUT deleted.custid, deleted.Type, [dbo].[f_GetDateTime2]() 
				INTO VRCustLockStatus_Del_Inhouse(custid,Type,RepUpdateTime)
				FROM VRCustLockStatus c WITH(ROWLOCK)
					INNER JOIN #tmpCustBatchVR_Additional t
						ON c.CustID = t.CustID AND c.Type = t.type
			END	
			DROP TABLE #unlockTempCust
		END

		DROP TABLE #tmpCustBatchVR_Additional
		DROP TABLE #tblCustVR_Additional
	END
	ELSE IF @Action = ('DisableVR2Downline')
	BEGIN
		IF OBJECT_ID('VRSettingManualUpdAcc') IS NULL RETURN
		IF OBJECT_ID('VRCustSetting') IS NULL RETURN
		IF OBJECT_ID('CustSettingAutoSuspend') IS NULL RETURN

		CREATE TABLE #tmpCustVR2Downline (CustID INT PRIMARY KEY,RoleID TINYINT)

		--> Get all downline of direct account
		IF @RoleId = 4
		BEGIN
			INSERT INTO #tmpCustVR2Downline(CustID,roleid)
			SELECT ci.custid,ci.roleid
			FROM custinfo ci WITH(NOLOCK)
			WHERE ci.roleid IN (1,2,3)
				AND ci.srecommend = @CustId
				AND ci.enabled = 1
		END
		ELSE IF @RoleId = 3
		BEGIN
			INSERT INTO #tmpCustVR2Downline(CustID,roleid)
			SELECT ci.custid,ci.roleid
			FROM custinfo ci WITH(NOLOCK)
			WHERE ci.roleid IN (1,2)
				AND ci.mrecommend = @CustId
				AND ci.enabled = 1
		END
		ELSE IF @RoleId = 2
		BEGIN
			INSERT INTO #tmpCustVR2Downline(CustID,roleid)
			SELECT ci.custid,ci.roleid
			FROM custinfo ci WITH(NOLOCK)
			WHERE ci.roleid IN (1)
				AND ci.recommend = @CustId
				AND ci.enabled = 1
		END

		--Set Manual VR for all downline
		WHILE 1 = 1
		BEGIN
			INSERT INTO [VRSettingManualUpdAcc](CustID,SportType,RepUpdateTime)
			SELECT TOP (2000) t.CustID, @Sporttype AS SportType, [dbo].[f_GetDateTime2]() AS RepUpdateTime
			FROM #tmpCustVR2Downline t
				LEFT JOIN [VRSettingManualUpdAcc] v WITH(NOLOCK)
					ON t.CustID = v.CustID 
					AND v.SportType = @Sporttype
			WHERE v.CustID IS NULL

			IF @@ROWCOUNT = 0
				BREAK;
		END

		DECLARE @VRCustSetting TABLE (CustID int, LevelID int)
		DECLARE @VRCustSettingBatch TABLE (CustID int, LevelID int)

		DeletePrivateVR: --Step Delete all private VR of Master/Agent/Member

		INSERT INTO @VRCustSetting(CustID,LevelID)
		SELECT vr.CustID,vr.LevelID
		FROM VRCustSetting vr WITH(NOLOCK)
			INNER JOIN VRSettingHierarchy h WITH(NOLOCK) ON vr.LevelID = h.LevelID
			INNER JOIN #tmpCustVR2Downline t ON vr.CustID = t.CustID
		WHERE h.SportType = @Sporttype
		ORDER by vr.CustID,VR.LevelID

		--Delete all private VR of Master/Agent/Member( VR will follow  their Super)
		WHILE 1 = 1
		BEGIN
			DELETE FROM @VRCustSettingBatch

			DELETE TOP(2000) t
			OUTPUT deleted.CustID,deleted.LevelID INTO @VRCustSettingBatch(CustID,LevelID)
			FROM @VRCustSetting t

			IF @@ROWCOUNT = 0
				BREAK;

			DELETE vr
			OUTPUT deleted.custid, deleted.LevelID, [dbo].[f_GetDateTime2]() 
			INTO VRCustSetting_Del_Inhouse(custid,LevelID,RepUpdateTime)
			FROM VRCustSetting vr WITH(ROWLOCK,UPDLOCK)
				INNER JOIN @VRCustSettingBatch t 
					ON vr.CustID = t.CustID
					AND vr.LevelID = t.LevelID
		END

		IF EXISTS(
			SELECT TOP 1 1
			FROM VRCustSetting vr WITH(NOLOCK)
				INNER JOIN VRSettingHierarchy h WITH(NOLOCK) ON vr.LevelID = h.LevelID
				INNER JOIN #tmpCustVR2Downline t ON vr.CustID = t.CustID
			WHERE h.SportType = @Sporttype
		)
		BEGIN
			PRINT 'Delete Again'
			GOTO DeletePrivateVR --Delete Again
		END

		--Set OverrideAS = 1 ( Esport Level) for all members
		IF @Sporttype = 43
		BEGIN
			IF @roleid = 1
			BEGIN
				INSERT INTO #tmpCustVR2Downline(CustID,roleid)
				SELECT @custid, 1
			END

			DECLARE @OverrideAS_True varbinary(128)  = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF

			WHILE 1 = 1
			BEGIN
				UPDATE TOP (2000) v
				SET OverrideASLive = @OverrideAS_True
					,OverrideASNonLive = @OverrideAS_True
					,v.RepUpdateTime = [dbo].[f_GetDateTime2]()
				FROM #tmpCustVR2Downline t
					INNER JOIN CustSettingAutoSuspend v WITH(NOLOCK)
						ON t.CustID = v.CustID 
						AND v.SportType = @Sporttype
				WHERE t.roleid = 1
				AND NOT(  
						OverrideASLive = @OverrideAS_True
						AND OverrideASNonLive = @OverrideAS_True
					)

				IF @@ROWCOUNT = 0
					BREAK;
			END

			WHILE 1 = 1
			BEGIN
				INSERT INTO CustSettingAutoSuspend(CustID,SportType,AutoSuspendLive,AutoSuspendNonLive,OverrideASLive,OverrideASNonLive,RepUpdateTime)
				SELECT TOP (2000) t.CustID, @Sporttype AS SportType, @OverrideAS_True, @OverrideAS_True, @OverrideAS_True, @OverrideAS_True, [dbo].[f_GetDateTime2]()
				FROM #tmpCustVR2Downline t
					LEFT JOIN CustSettingAutoSuspend v WITH(NOLOCK)
						ON t.CustID = v.CustID 
						AND v.SportType = @Sporttype
				WHERE v.CustID IS NULL
					AND t.roleid = 1

				IF @@ROWCOUNT = 0
					BREAK;
			END	
		END
		DROP TABLE #tmpCustVR2Downline
	END
	ELSE IF @Action IN ('DisableABDownline','LockVRDownline')
	BEGIN
		CREATE TABLE #lockTempCust_Additional(custid INT, type TINYINT)
		CREATE TABLE #lockTempCust_Batch(custid INT, type TINYINT)
		DECLARE @lockBatchSize INT = 2000

		IF @roleid = 1
			RETURN

		DECLARE	@RoleID_Lock3_SC		TINYINT,
				@RoleID_Lock2_SC		TINYINT,
				@RoleID_Lock1_SC		TINYINT,

				@RoleID_Lock3_BB		TINYINT,
				@RoleID_Lock2_BB		TINYINT,
				@RoleID_Lock1_BB		TINYINT,

				@RoleID_Lock3_OS		TINYINT,
				@RoleID_Lock2_OS		TINYINT,
				@RoleID_Lock1_OS		TINYINT,

				@RoleID_Disable3_AB		TINYINT,
				@RoleID_Disable2_AB		TINYINT,
				@RoleID_Disable1_AB		TINYINT
		DECLARE @DocHandler_LockVR INT
		EXEC sp_xml_preparedocument @DocHandler_LockVR OUTPUT, @AdditionalActions

		SELECT
					@RoleID_Lock3_SC = CASE WHEN @roleid = 4			AND Data.UnlockSC3 = 0 THEN 3 ELSE 0 END,
					@RoleID_Lock2_SC = CASE WHEN @roleid IN (4,3)		AND Data.UnlockSC2 = 0 THEN 2 ELSE 0 END,
					@RoleID_Lock1_SC = CASE WHEN @roleid IN (4,3,2)		AND Data.UnlockSC1 = 0 THEN 1 ELSE 0 END,

					@RoleID_Lock3_BB = CASE WHEN @roleid = 4			AND Data.UnlockBB3 = 0 THEN 3 ELSE 0 END,
					@RoleID_Lock2_BB = CASE WHEN @roleid IN (4,3)		AND Data.UnlockBB2 = 0 THEN 2 ELSE 0 END,
					@RoleID_Lock1_BB = CASE WHEN @roleid IN (4,3,2)		AND Data.UnlockBB1 = 0 THEN 1 ELSE 0 END,

					@RoleID_Lock3_OS = CASE WHEN @roleid = 4			AND Data.UnlockOS3 = 0 THEN 3 ELSE 0 END,
					@RoleID_Lock2_OS = CASE WHEN @roleid IN (4,3)		AND Data.UnlockOS2 = 0 THEN 2 ELSE 0 END,
					@RoleID_Lock1_OS = CASE WHEN @roleid IN (4,3,2)		AND Data.UnlockOS1 = 0 THEN 1 ELSE 0 END,

					@RoleID_Disable3_AB = CASE WHEN @roleid = 4			AND Data.EnableAB3 = 0 THEN 3 ELSE 0 END,
					@RoleID_Disable2_AB = CASE WHEN @roleid IN (4,3)	AND Data.EnableAB2 = 0 THEN 2 ELSE 0 END,
					@RoleID_Disable1_AB = CASE WHEN @roleid IN (4,3,2)	AND Data.EnableAB1 = 0 THEN 1 ELSE 0 END
		FROM OPENXML (@DocHandler_LockVR, '/ROOT/VR',1) 
		WITH (
			UnlockSC3		TINYINT,
			UnlockSC2		TINYINT,
			UnlockSC1		TINYINT,

			UnlockBB3		TINYINT,
			UnlockBB2		TINYINT,
			UnlockBB1		TINYINT,

			UnlockOS3		TINYINT,
			UnlockOS2		TINYINT,
			UnlockOS1		TINYINT,

			EnableAB3		TINYINT,
			EnableAB2		TINYINT,
			EnableAB1		TINYINT
		) AS Data

		EXEC sp_xml_removedocument @DocHandler_LockVR

		IF @action = 'DisableABDownline' AND OBJECT_ID('VRCustLockStatus') IS NOT NULL
		BEGIN
			TRUNCATE TABLE #lockTempCust_Additional

			IF @roleid = 4
			BEGIN	
				INSERT INTO #lockTempCust_Additional(custID, type)
				SELECT custid, 4 AS type
				FROM custInfo WITH (NOLOCK)
				WHERE srecommend = @custid
					AND roleid IN (@RoleID_Disable3_AB, @RoleID_Disable2_AB, @RoleID_Disable1_AB)
			END

			ELSE IF @roleid = 3
			BEGIN
				INSERT INTO #lockTempCust_Additional(custID, type)
				SELECT custid, 4 AS type
				FROM custInfo WITH (NOLOCK)
				WHERE mrecommend = @custid
					AND roleid IN (@RoleID_Disable2_AB, @RoleID_Disable1_AB)
			END

			ELSE IF @roleid = 2
			BEGIN
				INSERT INTO #lockTempCust_Additional(custID, type)
				SELECT custid, 4 AS type
				FROM custInfo WITH (NOLOCK)
				WHERE recommend = @custid
					AND roleid = @RoleID_Disable1_AB
			END

			WHILE(1=1)
			BEGIN
				TRUNCATE TABLE #lockTempCust_Batch
				
				DELETE TOP (@lockBatchSize) t
					OUTPUT deleted.custid, deleted.type 
					INTO #lockTempCust_Batch(CustID, type)
				FROM #lockTempCust_Additional t
				
				IF @@rowcount = 0 
					BREAK;
					
				DELETE v
				OUTPUT deleted.custid, deleted.Type, [dbo].[f_GetDateTime2]() 
				INTO VRCustLockStatus_Del_Inhouse(custid,Type,RepUpdateTime)
				FROM VRCustLockStatus v WITH (ROWLOCK)
					INNER JOIN #lockTempCust_Batch t ON v.CustID = t.custid AND v.Type = t.type
			END				
		END
		ELSE IF @action = 'LockVRDownline' AND OBJECT_ID('VRCustLockStatus') IS NOT NULL
		BEGIN
			CREATE TABLE #lockTempCust(custid INT, roleid TINYINT)

			IF @roleid = 4
			BEGIN
				INSERT INTO #lockTempCust(custid, roleid)
				SELECT custid, roleid 
				FROM custinfo with (NOLOCK)
				WHERE srecommend = @custid

				INSERT INTO #lockTempCust_Additional(custid, type)
				SELECT custid, 1 AS type
				FROM #lockTempCust
				WHERE roleid IN (@RoleID_Lock3_SC, @RoleID_Lock2_SC,@RoleID_Lock1_SC)
				UNION ALL
				SELECT custid, 2 AS type
				FROM #lockTempCust
				WHERE roleid IN (@RoleID_Lock3_OS, @RoleID_Lock2_OS,@RoleID_Lock1_OS)
				UNION ALL
				SELECT custid, 3 AS type
				FROM #lockTempCust
				WHERE roleid IN (@RoleID_Lock3_BB, @RoleID_Lock2_BB,@RoleID_Lock1_BB)
			END
			ELSE IF @roleid = 3
			BEGIN
				INSERT INTO #lockTempCust(custid, roleid)
				SELECT custid, roleid 
				FROM custinfo with (NOLOCK)
				WHERE mrecommend = @custid

				INSERT INTO #lockTempCust_Additional(custid, type)
				SELECT custid, 1 AS type
				FROM #lockTempCust
				WHERE roleid IN (@RoleID_Lock2_SC,@RoleID_Lock1_SC)
				UNION ALL
				SELECT custid, 2 AS type
				FROM #lockTempCust
				WHERE roleid IN (@RoleID_Lock2_OS,@RoleID_Lock1_OS)
				UNION ALL
				SELECT custid, 3 AS type
				FROM #lockTempCust
				WHERE roleid IN (@RoleID_Lock2_BB,@RoleID_Lock1_BB)
			END
			ELSE IF @roleid = 2
			BEGIN
				INSERT INTO #lockTempCust(custid, roleid)
				SELECT custid, roleid 
				FROM custinfo with (NOLOCK)
				WHERE recommend = @custid

				INSERT INTO #lockTempCust_Additional(custid, type)
				SELECT custid, 1 AS type
				FROM #lockTempCust
				WHERE roleid IN (@RoleID_Lock1_SC)
				UNION ALL
				SELECT custid, 2 AS type
				FROM #lockTempCust
				WHERE roleid IN (@RoleID_Lock1_OS)
				UNION ALL
				SELECT custid, 3 AS type
				FROM #lockTempCust
				WHERE roleid IN (@RoleID_Lock1_BB)
			END

			IF NOT EXISTS( SELECT TOP 1 1 FROM #lockTempCust_Additional)
				RETURN

			WHILE(1=1)
			BEGIN
				DELETE #lockTempCust_Batch

				DELETE TOP (@lockBatchSize) t 
					OUTPUT DELETED.custid, DELETED.type
					INTO #lockTempCust_Batch(custid, type)
				FROM #lockTempCust_Additional t

				IF @@ROWCOUNT = 0
					BREAK

				INSERT INTO VRCustLockStatus(CustID, Type,RepUpdateTime)
				SELECT t.custid, t.type , [dbo].[f_GetDateTime2]()
				FROM #lockTempCust_Batch t
				WHERE NOT EXISTS(
					SELECT TOP 1 1
					FROM VRCustLockStatus v WITH (NOLOCK) 
					WHERE v.CustID = t.custid AND v.Type = t.type
				)
			END	
			DROP TABLE #lockTempCust
		END
		DROP TABLE	#lockTempCust_Additional, 
					#lockTempCust_Batch
	END
END

GO
