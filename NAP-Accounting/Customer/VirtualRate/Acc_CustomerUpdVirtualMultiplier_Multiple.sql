/*<info serverAlias="DBCUST-CustDB" executers="bodbadminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE	[dbo].[Acc_CustomerUpdVirtualMultiplier_Multiple]
					@VirtualMultiplier		VARCHAR(MAX)	= ''
				,	@UserID					INT  
				,	@IP						VARCHAR(15)		= ''
				,	@SportType				SMALLINT		= 0
				,	@ErrCode				INT				= 0			OUTPUT 
				,	@ErrMsg					NVARCHAR(4000)	= ''		OUTPUT  
AS  
/*  
	Created:	20160406@Billy
	Task:		Multiple update Virtual Multiplier for multiple customers
	DB:			DBCUST/CustDB
	Original:  
  
	Revisions: 
		- 20160614@Elodie: Update enable virtualrate [Redmine:#58700]
		- 20170328@Elodie: Expand the range of VR setting [RedmineID:#73808]
		- 20170426@Elodie: When the [VR Auto Adjustment] job runs to update members to +200%, ignore the BA accounts with margin >= 4% [RedmineID:#75075]
		- 20170522@Elodie: When the [VR Auto Adjustment] job runs to update members to +200%, update VR = 0 for the BA accounts with margin >= 4% [RedmineID:#76701]
		- 20170915@Winnie: Update logic to VR auto-adjustment job Phase 2 RedmineID:#82312
		- 20171004@Winnie: NAP CM - Missing log data when update VR setting by Auto-adjustment [RedmineID:#84112]
		- 20180924@Elodie: Migrate bodb_Licensee to DBCUST [Redmine:#99855]
		- 20190725@Elodie: Extend range and interval steps [Redmine:#117609]
		- 20210224@Eden: Implement Lock for VR update [Redmine:#149370]

	Param's Explanation:  
		- @SportType = 0 : All
					 = 1 : Soccer
					 = 2 : Other Sports
		- @VirtualMultiplier = '<ROOT>
									<Rate CustIds="1,2,3,4,5,6" VirtualMultiplier="0.7" />	
									<Rate CustIds="11,22,33,44,55,66" VirtualMultiplier="1.5" />
								</ROOT>'
*/  
BEGIN  
	SET NOCOUNT ON;  

	CREATE TABLE	#log (
						CustID		INT
					,	LogValue	NVARCHAR(MAX)
					,	isFinished	BIT
							CONSTRAINT DF_#log_isFinished DEFAULT 0
					);
	  
	DECLARE	@startRun		DATETIME;  
	DECLARE	@endRun			DATETIME;  
	DECLARE	@duration		INT; 
	DECLARE @ListCustID		VARCHAR(MAX);
	DECLARE	@tblVirtualrate	TABLE (
								CustIDs				VARCHAR(MAX)
							,	VirtualMultiplier	SMALLMONEY	
							);
	CREATE TABLE #CustList (CustID INT PRIMARY KEY)
	CREATE TABLE #BACust (CustID INT PRIMARY KEY)
	CREATE TABLE #tmpCustVirtualSetting(
	[custid] [int] NOT NULL,
	[seqNo] [tinyint] NOT NULL,
	[bitmapVirtual] [binary](64) NOT NULL CONSTRAINT [DF_CustVirtualSetting_bitmapVirtual]  DEFAULT (0x00),
		 CONSTRAINT [PK_CustVirtualSetting] PRIMARY KEY CLUSTERED 
		(
			[custid] ASC,
			[seqNo] ASC
		))

	DECLARE @CustStr VARCHAR(MAX) = '', @VR_ExcludeBA_XML XML						
	DECLARE	@DocHandler		INT;														
	 
	SET	@startRun = GETDATE();  
	
	IF	@VirtualMultiplier <> ''
	BEGIN
		-- For read xml					
		EXECUTE	sp_xml_preparedocument
					@DocHandler			OUTPUT
				,	@virtualmultiplier;

		INSERT INTO	@tblVirtualrate (
						CustIDs
					,	VirtualMultiplier
					)
		SELECT	Data.CustIds
			,	Data.VirtualMultiplier
		FROM OPENXML (@DocHandler, '/ROOT/Rate', 1) 
		WITH (
			CustIds				VARCHAR(MAX)
		,	VirtualMultiplier	SMALLMONEY	
		) AS Data;

		EXECUTE	sp_xml_removedocument
					@DocHandler;
		-- end read xml	
	END;		
		  
	IF	EXISTS	(	SELECT	1
					FROM	@tblVirtualrate
					WHERE	virtualmultiplier > 3.0 
						OR	virtualmultiplier < 0.05
				)  
	BEGIN  
		SELECT	@ErrMsg = N'Invalid virtual rate.'
			,	@ErrCode = 101;
		RETURN;
	END;

	SELECT @ListCustID=Custids FROM @tblVirtualrate

	INSERT INTO #tmpCustVirtualSetting
           ([custid]
           ,[seqNo]
           ,[bitmapVirtual])
	SELECT [custid]
           ,[seqNo]
           ,[bitmapVirtual]
	FROM CustVirtualSetting c
	INNER JOIN	dbo.strSplit(@ListCustID, ',') AS ss ON c.custid=ss.val
	
	--When the [VR Auto Adjustment] job runs to update members to +200% (1st and 16th of every month), update VR of the BA accounts = 0 with margin >= 4%
	IF EXISTS (SELECT 1 FROM @tblVirtualrate WHERE VirtualMultiplier = 3)
	BEGIN
		INSERT INTO #CustList (CustID)
		SELECT CONVERT(INT,ss.val)
		FROM @tblVirtualrate AS tv
			CROSS APPLY	dbo.strSplit(tv.CustIDs, ',') AS ss
		WHERE VirtualMultiplier = 3

		INSERT INTO #BACust(CustID)
		SELECT CustID
		FROM bodb_licensee.dbo.[LicenseeBAHistory] ba WITH (NOLOCK)
		WHERE ba.Status = 'Running'

		SELECT @CustStr =  ISNULL(STUFF(( select ',' + CAST(c.custid AS VARCHAR(20))
		FROM #CustList c
			INNER JOIN #BACust ba ON ba.CustID = c.CustID
		FOR XML PATH('')), 1,1,''),'')

		INSERT INTO @tblVirtualrate (CustIDs, VirtualMultiplier)
		SELECT @CustStr, 1

		DELETE tmp
		FROM #CustList tmp 
			INNER JOIN #BACust ba ON ba.CustID = tmp.CustID

		SELECT @CustStr =  ISNULL(STUFF(( select ',' + CAST(custid AS VARCHAR(20))
		FROM #CustList
		FOR XML PATH('')), 1,1,''),'')

		UPDATE tmp
		SET tmp.CustIDs = @CustStr
		FROM @tblVirtualrate tmp
		WHERE VirtualMultiplier = 3.0

		SELECT @VR_ExcludeBA_XML =(
								SELECT (
										SELECT	CustIDs	AS '@CustIds'
											,	VirtualMultiplier	AS '@VirtualMultiplier'
										FROM @tblVirtualrate
										FOR XML PATH('Rate')
											, TYPE
										)
								FOR XML PATH('ROOT')
									, TYPE
								)

		SELECT @VirtualMultiplier = CONVERT(VARCHAR(MAX),@VR_ExcludeBA_XML)
	END

	-- Get Log data for each customer
	DECLARE	@CustID			INT
		,	@LogSPData		NVARCHAR(MAX) = ''
		,	@LogSPData_OLD	NVARCHAR(MAX) = '';
	IF(@SportType=0)
	BEGIN
		INSERT INTO #log
			(	CustID, LogValue, isFinished)
		SELECT	CAST(ss.val AS INT)
			,	(	SELECT	ss.val		AS '@CustID'
						,	@UserID		AS '@UserID'
						,	@SportType  AS '@SportType'
						,	@ErrCode	AS '@ErrCode'
						,	@ErrMsg		AS '@ErrMsg'
						,	@IP			AS '@IP'
						,	1			AS '@EnableVirtualrate'
						,	(	SELECT	pvs.sporttype			AS '@SportType'
									,	pvs.bettype				AS '@BetType'
									,	pvs.islive				AS '@IsLive'
									,	tv.VirtualMultiplier	AS '@VirtualMultiplier'
								FROM	dbo.ProfileVirtualSetting AS pvs WITH (NOLOCK)						
								ORDER BY pvs.sporttype ASC, pvs.islive DESC, pvs.bettype ASC
								FOR XML PATH ('s')
							,	TYPE
							)
					FOR XML PATH ('Acc_CustomerUpdVirtualMultiplier_Multiple')
				)
			,	0
		FROM		@tblVirtualrate AS tv
		CROSS APPLY	dbo.strSplit(tv.CustIDs, ',') AS ss;
	END
	ELSE IF(@SportType=1)
	BEGIN
		INSERT INTO #log
			(	CustID, LogValue, isFinished)
		SELECT	CAST(ss.val AS INT)
			,	(	SELECT	ss.val		AS '@CustID'
						,	@UserID		AS '@UserID'
						,	@SportType  AS '@SportType'
						,	@ErrCode	AS '@ErrCode'
						,	@ErrMsg		AS '@ErrMsg'
						,	@IP			AS '@IP'
						,	1			AS '@EnableVirtualrate'
						,	(	SELECT	pvs.sporttype			AS '@SportType'
									,	pvs.bettype				AS '@BetType'
									,	pvs.islive				AS '@IsLive'
									,	tv.VirtualMultiplier	AS '@VirtualMultiplier'
								FROM	dbo.ProfileVirtualSetting AS pvs WITH (NOLOCK)	
								WHERE pvs.sporttype =1			
								ORDER BY pvs.sporttype ASC, pvs.islive DESC, pvs.bettype ASC
								FOR XML PATH ('s')
							,	TYPE
							)
					FOR XML PATH ('Acc_CustomerUpdVirtualMultiplier_Multiple')
				)
			,	0
		FROM		@tblVirtualrate AS tv
		CROSS APPLY	dbo.strSplit(tv.CustIDs, ',') AS ss;
	END
	ELSE IF(@SportType=2)
	BEGIN 
		INSERT INTO #log
				(	CustID, LogValue, isFinished)
			SELECT	CAST(ss.val AS INT)
				,	(	SELECT	ss.val		AS '@CustID'
							,	@UserID		AS '@UserID'
							,	@SportType  AS '@SportType'
							,	@ErrCode	AS '@ErrCode'
							,	@ErrMsg		AS '@ErrMsg'
							,	@IP			AS '@IP'
							,	1			AS '@EnableVirtualrate'
							,	(	SELECT	pvs.sporttype			AS '@SportType'
										,	pvs.bettype				AS '@BetType'
										,	pvs.islive				AS '@IsLive'
										,	tv.VirtualMultiplier	AS '@VirtualMultiplier'
									FROM	dbo.ProfileVirtualSetting AS pvs WITH (NOLOCK)	
									WHERE pvs.sporttype <>1			
									ORDER BY pvs.sporttype ASC, pvs.islive DESC, pvs.bettype ASC
									FOR XML PATH ('s')
								,	TYPE
								)
						FOR XML PATH ('Acc_CustomerUpdVirtualMultiplier_Multiple')
					)
				,	0
			FROM		@tblVirtualrate AS tv
			CROSS APPLY	dbo.strSplit(tv.CustIDs, ',') AS ss;
	END

	-- Update via Execrep
	EXECUTE	dbo.Acc_CustSetting_10 
				@VirtualMultiplier = @VirtualMultiplier
				,@SportType=@SportType;
	
	-- Update enable virtual rate via Execrep
	EXECUTE	dbo.Acc_CustomerInfo_Execrep_04 @custid = 0, @roleid = 0, @action = 'EnableVirtualMultiplier', @EnableVirtualMultiplier = @VirtualMultiplier;

	--Process to lock VR status When setting VR >= 0 
	DECLARE @tbl_PositiveVR TABLE(CustID INT, Isfinished BIT default 0)

	IF	@VirtualMultiplier <> ''
	BEGIN
		-- For read xml					
		EXECUTE	sp_xml_preparedocument
					@DocHandler			OUTPUT
				,	@virtualmultiplier;

		INSERT INTO	@tbl_PositiveVR (CustID)
		SELECT	CAST(ss.val AS INT)
		FROM OPENXML (@DocHandler, '/ROOT/Rate', 1) 
		WITH (
			CustIds				VARCHAR(MAX)
		,	VirtualMultiplier	SMALLMONEY	
		) AS Data
		CROSS APPLY	dbo.f_StringSplit(Data.CustIds, ',') AS ss
		WHERE Data.VirtualMultiplier >= 1.00
		OPTION (MAXRECURSION 0)

		EXECUTE	sp_xml_removedocument
					@DocHandler;
		-- end read xml	
	END;	
	
	--Delete invalid accounts
	DELETE t
	FROM @tbl_PositiveVR t
		LEFT JOIN custInfo c WITH(NOLOCK) ON t.CustID = c.custid
	WHERE c.custid IS NULL	
	
	DECLARE @VRLockedStatus_Soccer BIT,  @VRLockedStatus_OS	BIT, @tmpCustID INT

	SELECT @VRLockedStatus_Soccer = CASE WHEN @SportType IN (0,1) THEN 1 END,
		   @VRLockedStatus_OS = CASE WHEN @SportType IN (0,2) THEN 1 END

	WHILE 1 = 1
	BEGIN
		UPDATE TOP(1)  c
		SET c.Isfinished = 1,
			@tmpCustID = c.CustID
		FROM @tbl_PositiveVR c
		WHERE Isfinished = 0

		IF @@ROWCOUNT = 0 BREAK;

		--Update VR lock status to locked
		EXEC Acc_VRCustLockStatusUpd 
			 @custid = @tmpCustID
			,@UserID = @UserID
			,@VRLockedStatus_Soccer = @VRLockedStatus_Soccer
			,@VRLockedStatus_OS = @VRLockedStatus_OS
			,@IP = @IP
			,@UpdateBy = '3m perf check'
	END

	SET	@endRun = GETDATE();
	SET	@duration = DATEDIFF(MILLISECOND, @startRun, @endRun);

	WHILE 0 = 0
	BEGIN
	    UPDATE	TOP(1) #log
		SET	isFinished = 1
		,	@CustID = CustID
		,	@LogSPData = LogValue
		WHERE	isFinished = 0;
		IF	@@ROWCOUNT = 0
			BREAK;			
		
		IF(@SportType=0)
		BEGIN
			SELECT @LogSPData_OLD=(	SELECT	@CustID		AS '@CustID'
							,	@UserID		AS '@UserID'
							,	@SportType  AS '@SportType'
							,	@ErrCode	AS '@ErrCode'
							,	@ErrMsg		AS '@ErrMsg'
							,	@IP			AS '@IP'
							,	1			AS '@EnableVirtualrate'
							,	(	SELECT	pvs.sporttype			AS '@SportType'
										,	pvs.bettype				AS '@BetType'
										,	pvs.islive				AS '@IsLive'
										,	dbo.f_GetVirtualSetting(cvs.bitmapVirtual, pvs.profileID)	AS '@VirtualMultiplier'
									FROM	dbo.ProfileVirtualSetting AS pvs WITH (NOLOCK)	
									INNER JOIN #tmpCustVirtualSetting AS cvs  ON cvs.seqNo = pvs.seqNo  								
									WHERE   cvs.custid=@CustID 
									ORDER BY pvs.sporttype ASC, pvs.islive DESC, pvs.bettype ASC
									FOR XML PATH ('s')
								,	TYPE
								)
						FOR XML PATH ('Acc_CustomerUpdVirtualMultiplier_Multiple')
					)
			END
			ELSE IF (@SportType=1)
			BEGIN
				SELECT @LogSPData_OLD=(	SELECT	@CustID		AS '@CustID'
							,	@UserID		AS '@UserID'
							,	@SportType  AS '@SportType'
							,	@ErrCode	AS '@ErrCode'
							,	@ErrMsg		AS '@ErrMsg'
							,	@IP			AS '@IP'
							,	1			AS '@EnableVirtualrate'
							,	(	SELECT	pvs.sporttype			AS '@SportType'
										,	pvs.bettype				AS '@BetType'
										,	pvs.islive				AS '@IsLive'
										,	dbo.f_GetVirtualSetting(cvs.bitmapVirtual, pvs.profileID)	AS '@VirtualMultiplier'
									FROM	dbo.ProfileVirtualSetting AS pvs WITH (NOLOCK)	
									INNER JOIN #tmpCustVirtualSetting AS cvs   ON cvs.seqNo = pvs.seqNo  								
									WHERE   cvs.custid=@CustID	AND pvs.sporttype = 1 
									ORDER BY pvs.sporttype ASC, pvs.islive DESC, pvs.bettype ASC
									FOR XML PATH ('s')
								,	TYPE
								)
						FOR XML PATH ('Acc_CustomerUpdVirtualMultiplier_Multiple')
					)
			END
			ELSE IF
			(@SportType=2)
			BEGIN
					SELECT @LogSPData_OLD=(	SELECT	@CustID		AS '@CustID'
							,	@UserID		AS '@UserID'
							,	@SportType  AS '@SportType'
							,	@ErrCode	AS '@ErrCode'
							,	@ErrMsg		AS '@ErrMsg'
							,	@IP			AS '@IP'
							,	1			AS '@EnableVirtualrate'
							,	(	SELECT	pvs.sporttype			AS '@SportType'
										,	pvs.bettype				AS '@BetType'
										,	pvs.islive				AS '@IsLive'
										,	dbo.f_GetVirtualSetting(cvs.bitmapVirtual, pvs.profileID)	AS '@VirtualMultiplier'
									FROM	dbo.ProfileVirtualSetting AS pvs WITH (NOLOCK)	
									INNER JOIN #tmpCustVirtualSetting AS cvs  ON cvs.seqNo = pvs.seqNo  								
									WHERE   cvs.custid=@CustID	AND pvs.sporttype <> 1 
									ORDER BY pvs.sporttype ASC, pvs.islive DESC, pvs.bettype ASC
									FOR XML PATH ('s')
								,	TYPE
								)
						FOR XML PATH ('Acc_CustomerUpdVirtualMultiplier_Multiple')
					)
			END
		
	
		BEGIN TRY
			EXECUTE	DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
						@UserID = @UserID
					,	@CustID = @CustID
					,	@ActionID = 807
					,	@TrackingValue = @LogSPData
					,	@TrackingValue2= @LogSPData_OLD
					,	@Duration = @duration;			
		END TRY
		BEGIN CATCH
			EXECUTE	bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
						@UserID = @UserID
					,	@CustID = @CustID
					,	@ActionID = 807
					,	@TrackingValue = @LogSPData
					,	@TrackingValue2= @LogSPData_OLD
					,	@Duration = @duration;
		END CATCH;
	END;

	DROP TABLE #log;
END

GO