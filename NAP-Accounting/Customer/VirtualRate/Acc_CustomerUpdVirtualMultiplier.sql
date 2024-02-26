/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,bodbLicenseeNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE	dbo.Acc_CustomerUpdVirtualMultiplier   
					@custid				INT
				,	@EnableVirtualrate	BIT				= 0
				,	@virtualmultiplier	VARCHAR(MAX)	= ''
				,	@UserID				INT
				,	@IP					VARCHAR(15)		= ''
				,	@IsLicenseeUser		BIT				= 0
				,	@ErrCode			INT				= 0		OUTPUT
				,	@ErrMsg				NVARCHAR(4000)	= ''	OUTPUT  
				,   @VRLockedStatus_Soccer		BIT = NULL
				,   @VRLockedStatus_OS			BIT = NULL
				,	@VRLockedStatus_BasketBall	BIT = NULL
				,	@VRAccumulate_Balance		BIT = NULL
				,   @CopyFrom					INT = NULL --Source CustID of Copy VR function
				,   @AdditionalActions VARCHAR(MAX) = ''
AS  
/*  
	Created:	
	Task:		Update virtualmultiplier.  
	DB:			DBCUST/CustDB
	Original:	
  
	Revisions:  
	    - 20090917@Phuc:	Write log into dblog.  
	    - 20091008@Kiwi:	Remove WriteLog_UserLog  
	    - 20100107@Lewin: Change LogSPData format, write log by new function  
	    - 20101021@Henry: Record execution time  
	    - 20110907@Sophia: Change Linked Server from DB052 to DB053  
	    - 20110914@Henry: Allow Licensee user to change Virtual-rate when turn on/off BA  
	    - 20121126@Lukas: do not allow run this function during peak hour at weekend  
	    - 20121126@Thien: revise Lukas's version, to put restriction in all days with different limitation  
	    - 20121126@Thien: revise again, to put into ExecRep (Acc_ExecRep_04)  
	    - 20121206@Scott : Check Allowed downlines during peak hour at weekend  
	    - 20120306@Lukas: change linked-server alias  
	    - 20131108@Elodie: Splitting bodb02 into CustDB (call Acc_ExecRep_Cust_04 instead of Acc_ExecRep_04)
		- 20141125@Jamie: Use Acc_CustomerInfo_Execrep_04 instead of Acc_ExecRep_Cust_04 [Redmine:#26497]
	    - 20141226@Johnson: Separate virtual rate by sporttype, bettype [Redmine: #25840]		
	    - 20150610@Kathy: Migrate custDB to new server DBCust (Move Acc_CustomerSelCheckAllowedDownlines to DBCUST.CustDB) [Redmine:#36216]
		- 20151109@Billy: Change LogSPData definition to support over-8000-characters log - [Redmine: #46541]
		- 20160128@Billy: Update Virtual Rate's range from [-0.8, 1.6] to [-0.9, 1.6] - [Redmine: #51611]
		- 20160422@Billy:	Exclude Auto Adjusted VR Members when update VR - [Redmine: #56525]
		- 20170328@Elodie: Expand the range of VR setting [RedmineID:#73808]
		- 20180808@Helen: DB05.DBPOLICY migration - Move to DBCUST [Redmine:99462]
		- 20190725@Elodie: Extend range and interval steps [Redmine:#117609]
		- 20200811@Eden: Adjust VR setting for Other Sports of Haifa, IBO, Mansion88 & Happy8 [redmine: #139229]
		- 20200827@Eden: VR Adjustment by Agent profile [#140421]
		- 20200826@Eden: Adjust VR setting for Soccer of Haifa, IBO [redmine: #140368]
		- 20210223@Eden: Implement Lock for VR update [Redmine:#149370]
		- 20210308@Eden: Copy and apply VR settings to multiple member accounts [Redmine:#149372]
		- 20210325@Eden: Implement option to override Lock VR status and values for Master/Agent and even unlocked status of members [Redmine:#152094]
		- 20230427@Luke: Separate lock function for Basketball [Redmine: #185991]
		- 20230711@Helios: VR Accumulate Balance [Redmine: #189649] 
		- 20230721@Luke: Unlock VR for Soccer, Basketball, Other Sports [Redmine: #191162]
		- 20231129@Luke: NAP - Virtual rate - Enhance VR [Redmine: #194939]

	Param's Explanation:  
	- @virtualmultiplier = '<ROOT>
								<Rate SportType="1" BetType="1" IsLive="0" VirtualMultiplier="1.5" />	
								<Rate SportType="1" BetType="1" IsLive="1" VirtualMultiplier="1.5" />	
								<Rate SportType="99" BetType="1" IsLive="0" VirtualMultiplier="1.5" />	
								<Rate SportType="99" BetType="1" IsLive="1" VirtualMultiplier="1.5" />	
							</ROOT>'	
	- @AdditionalActions = '<ROOT>
								<VR UnlockSC3="1"  UnlockSC2="0" UnlockSC1="1" UnlockBB3="1"  UnlockBB2="0" UnlockBB1="1" UnlockOS3="1"  UnlockOS2="0" UnlockOS1="1" Enable3="0"  Enable2="1" Enable1="0" />	
							</ROOT>'	
	- @ErrCode:  
	    = 0: update successfully.  
	    > 0: Specific Error.  
	    
	- @ErrMsg: Error description.  

	- @Is_VRAccumulate_Balance:
		0 (UnCheck)   : Is Manual Update
		1 (Check)     : Is Apply For All Downline
*/  
BEGIN  
	SET NOCOUNT ON  
	  
	DECLARE @startRun datetime  
	DECLARE @endRun datetime  
	DECLARE @duration int 
	DECLARE	@UnlockSC3		TINYINT, --Unlock VR Soccer all Masters
			@UnlockSC2		TINYINT, --Unlock VR Soccer all Agents
			@UnlockSC1		TINYINT, --Unlock VR Soccer all Members

			@UnlockBB3		TINYINT, --Unlock VR Basketball all Masters
			@UnlockBB2		TINYINT, --Unlock VR Basketball all Agents
			@UnlockBB1		TINYINT, --Unlock VR Basketball all Members

			@UnlockOS3		TINYINT, --Unlock VR Other Sports all Masters
			@UnlockOS2		TINYINT, --Unlock VR Other Sports all Agents
			@UnlockOS1		TINYINT, --Unlock VR Other Sports all Members

			@EnableAB3		TINYINT, --Enable VR+ all Masters
			@EnableAB2		TINYINT, --Enable VR+ all Agents
			@EnableAB1		TINYINT	 --Enable VR+ all Members

	DECLARE @tblVirtualrate TABLE (
									SportType INT
									,BetType INT
									,IsLive	BIT
									,VirtualMultiplier SMALLMONEY	
								)
	DECLARE @DocHandler INT		

	set @startRun = getdate()  
	  
	IF @IsLicenseeUser = 0 --accounting admin (licensee user will be ignored from this check)  
	BEGIN  
		--Check permission for account site: @phuc20080213  
		EXEC NAP_UserControl.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[VirtualRate]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output  
		If @ErrCode <> 0  
			RETURN  
	END  
	  
	--end  
	  
	--Check disable user  
	EXEC dbo.Acc_CustomerSelCheckEnable @custid = @custid, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output  
	if @ErrCode <>0 return  
	--end  
	  
	declare @roleid tinyint,  
			@OldEnableVirtualrate BIT  
	  
	select @OldEnableVirtualrate = virtualmultiplier, @roleid = roleid from custinfo with (nolock) where custid = @custid  
	  
	--Check Allowed downlines during peak hour at weekend      
	EXEC dbo.Acc_CustomerSelCheckAllowedDownlines    @custid=@custid,  
										@roleid=@roleid,  
										@isExecRep=1,  
										@Language='E',  
										@ErrMsg=@ErrMsg output,  
										@ErrCode=@ErrCode output  
	IF @ErrCode <>0 RETURN  		   

	IF @virtualmultiplier <> ''
	BEGIN
		-- For read xml					
		EXEC sp_xml_preparedocument @DocHandler OUTPUT, @virtualmultiplier

		INSERT INTO @tblVirtualrate(
					SportType,
					BetType,
					IsLive,
					VirtualMultiplier
				)
		SELECT
			Data.SportType,
			Data.BetType,
			Data.IsLive,
			Data.VirtualMultiplier
		FROM OPENXML (@DocHandler, '/ROOT/Rate',1) 
		WITH (
			SportType	SMALLINT,
			BetType		SMALLINT,
			IsLive		BIT,
			VirtualMultiplier SMALLMONEY	
		) AS Data

		EXEC sp_xml_removedocument @DocHandler
		-- end read xml	
	END		
		  
	IF EXISTS (SELECT TOP 1 1
				FROM @tblVirtualrate
				WHERE virtualmultiplier > 3 
					OR virtualmultiplier < 0.05
				)  
	BEGIN  
		select @ErrMsg    = N'Invalid virtual rate.', @ErrCode = 101  
		return  
	END 

	--Get current Virtual Rate of selected account 
	DECLARE @tblVirtualRate_old TABLE(sporttype SMALLINT, bettype SMALLINT, islive BIT, virtualMultiplier SMALLMONEY)

	INSERT INTO @tblVirtualRate_old(sporttype, bettype, islive, virtualMultiplier)
	SELECT pvs.sporttype,
			pvs.bettype,
			pvs.islive,
			dbo.f_GetVirtualSetting(cvs.bitmapVirtual, pvs.profileID) AS virtualMultiplier
	FROM CustVirtualSetting cvs WITH(NOLOCK)
		INNER JOIN ProfileVirtualSetting pvs WITH(NOLOCK) ON  cvs.seqNo = pvs.seqNo
	WHERE cvs.custid = @CustID
		AND pvs.isActive = 1
		AND pvs.sporttype NOT IN (43)


	--Get all locked VR/enable VR+ status and VR value bitmap of downlines
	CREATE TABLE #tempCustID(custid INT, roleid TINYINT, type TINYINT PRIMARY KEY(custid, type))
	CREATE TABLE #downlinesVRValue(custid INT, seqNo TINYINT, bitmapVirtual BINARY(64))
	IF @roleid = 4
	BEGIN
		INSERT INTO #tempCustID(custid, roleid, type)
		SELECT c.custid, c.roleid, s.Type
		FROM custinfo c WITH (NOLOCK)
			INNER JOIN VRCustLockStatus s WITH (NOLOCK) ON c.custid = s.CustID
		WHERE c.srecommend = @custid 

		INSERT INTO #downlinesVRValue(custid, seqNo, bitmapVirtual)
		SELECT c.custid, seqNo, bitmapVirtual
		FROM custinfo c WITH (NOLOCK)
			INNER JOIN CustVirtualSetting cvs WITH (NOLOCK) ON c.custid = cvs.custid 
		WHERE c.srecommend = @custid AND c.roleid IN (1,2,3)
	END
	ELSE IF @roleid = 3
	BEGIN
		INSERT INTO #tempCustID(custid, roleid, type)
		SELECT c.custid, c.roleid, s.Type
		FROM custinfo c WITH (NOLOCK)
			INNER JOIN VRCustLockStatus s WITH (NOLOCK) ON c.custid = s.CustID
		WHERE c.mrecommend = @custid 

		INSERT INTO #downlinesVRValue(custid, seqNo, bitmapVirtual)
		SELECT c.custid, seqNo, bitmapVirtual
		FROM custinfo c WITH (NOLOCK)
			INNER JOIN CustVirtualSetting cvs WITH (NOLOCK) ON c.custid = cvs.custid 
		WHERE c.mrecommend = @custid AND c.roleid IN (1,2)
	END
	ELSE IF @roleid = 2
	BEGIN
		INSERT INTO #tempCustID(custid, roleid, type)
		SELECT c.custid, c.roleid, s.Type
		FROM custinfo c WITH (NOLOCK)
			INNER JOIN VRCustLockStatus s WITH (NOLOCK) ON c.custid = s.CustID
		WHERE c.recommend = @custid 

		INSERT INTO #downlinesVRValue(custid, seqNo, bitmapVirtual)
		SELECT c.custid, seqNo, bitmapVirtual
		FROM custinfo c WITH (NOLOCK)
			INNER JOIN CustVirtualSetting cvs WITH (NOLOCK) ON c.custid = cvs.custid 
		WHERE c.recommend = @custid AND c.roleid = 1
	END
	ELSE
	BEGIN
		INSERT INTO #tempCustID(custid, roleid, type)
		SELECT c.custid, c.roleid, s.Type
		FROM custinfo c WITH (NOLOCK)
			INNER JOIN VRCustLockStatus s WITH (NOLOCK) ON c.custid = s.CustID
		WHERE c.custid = @custid 		
	END

	DECLARE   @Old_VRLockedStatus_Soccer			BIT = 0
			, @IsUpdate_VRLockedStatus_Soccer		BIT = 0
			, @Old_VRLockedStatus_OS				BIT = 0
			, @IsUpdate_VRLockedStatus_OS			BIT = 0
			, @Old_VRLockedStatus_Basketball		BIT = 0
			, @IsUpdate_VRLockedStatus_Basketball	BIT = 0
			, @Old_VRAccumulate_Balance				BIT = 0
			, @IsUpdate_VRAccumulate_Balance		BIT = 0
			, @LogSPData_SC							VARCHAR(MAX) = ''	
			, @LogSPData_OS							VARCHAR(MAX) = ''
			, @LogSPData_BB							VARCHAR(MAX) = ''
			, @LogSPData_AB							VARCHAR(MAX) = ''
	
	--Soccer lock/update status
	IF EXISTS ( SELECT 1 FROM #tempCustID WITH(NOLOCK) WHERE custid = @custid AND Type = 1)
		SET @Old_VRLockedStatus_Soccer = 1

	SET @VRLockedStatus_Soccer = ISNULL(@VRLockedStatus_Soccer,@Old_VRLockedStatus_Soccer)

	IF @VRLockedStatus_Soccer <> @Old_VRLockedStatus_Soccer
	BEGIN
		SET @IsUpdate_VRLockedStatus_Soccer = 1

		SELECT @LogSPData_SC = '<R VRLock="'+ coalesce(cast(@VRLockedStatus_Soccer as varchar(1)),space(1)) + '" '
								+ 'IP="' + coalesce(cast(@IP as varchar(15)),space(1)) + '" '
								+ IIF(ISNULL(@CopyFrom,0) = 0, 'UpdatedBy="Manual"', 'CopyFrom="'+cast(@CopyFrom as varchar(50))+'"')
								+ '/>' 		
	END 

	--Other Sports lock/update status
	IF EXISTS ( SELECT 1 FROM #tempCustID WITH(NOLOCK) WHERE custid = @custid AND Type = 2)
		SET @Old_VRLockedStatus_OS = 1
	
	SET @VRLockedStatus_OS = ISNULL(@VRLockedStatus_OS,@Old_VRLockedStatus_OS)

	IF @VRLockedStatus_OS <> @Old_VRLockedStatus_OS
	BEGIN
		SET @IsUpdate_VRLockedStatus_OS = 1

		SELECT @LogSPData_OS = '<R VRLock="'+ coalesce(cast(@VRLockedStatus_OS as varchar(1)),space(1)) + '" '
								+ 'IP="' + coalesce(cast(@IP as varchar(15)),space(1)) + '" '
								+ IIF(ISNULL(@CopyFrom,0) = 0, 'UpdatedBy="Manual"', 'CopyFrom="'+cast(@CopyFrom as varchar(50))+'"')
								+ '/>' 		
	END

	--Basketball lock/update status
	IF EXISTS ( SELECT 1 FROM #tempCustID WITH(NOLOCK) WHERE custid = @custid AND Type = 3)			
		SET @Old_VRLockedStatus_BasketBall = 1																
	
	SET @VRLockedStatus_BasketBall = ISNULL(@VRLockedStatus_Basketball,@Old_VRLockedStatus_Basketball)		

	IF @VRLockedStatus_BasketBall <> @Old_VRLockedStatus_Basketball										
	BEGIN																									
		SET @IsUpdate_VRLockedStatus_Basketball = 1		
		
		SELECT @LogSPData_BB = '<R VRLock="'+ coalesce(cast(@VRLockedStatus_Basketball as varchar(1)),space(1)) + '" '	
								+ 'IP="' + coalesce(cast(@IP as varchar(15)),space(1)) + '" '
								+ IIF(ISNULL(@CopyFrom,0) = 0, 'UpdatedBy="Manual"', 'CopyFrom="'+cast(@CopyFrom as varchar(50))+'"')
								+ '/>' 	 								
	END	

	--VR+ enable/update status
	IF EXISTS ( SELECT 1 FROM #tempCustID WITH(NOLOCK) WHERE custid = @custid AND Type = 4)			
		SET @Old_VRAccumulate_Balance = 1																
	
	SET @VRAccumulate_Balance = ISNULL(@VRAccumulate_Balance,@Old_VRAccumulate_Balance)		

	IF @VRAccumulate_Balance <> @Old_VRAccumulate_Balance										
	BEGIN																									
		SET @IsUpdate_VRAccumulate_Balance = 1	

		SELECT @LogSPData_AB = '<R VRAccumulatedBalance="'+ coalesce(cast(@VRAccumulate_Balance as varchar(1)),space(1)) + '" '	
								+ 'IP="' + coalesce(cast(@IP as varchar(15)),space(1)) + '" '
								+ IIF(ISNULL(@CopyFrom,0) = 0, 'UpdatedBy="Manual"', 'CopyFrom="'+cast(@CopyFrom as varchar(50))+'"')
								+ '/>' 								
	END	

	IF @AdditionalActions <> ''
	BEGIN
		-- For read xml					
		EXEC sp_xml_preparedocument @DocHandler OUTPUT, @AdditionalActions

		SELECT
			@UnlockSC3 = CASE WHEN @roleid = 4 AND Data.UnlockSC3 = 1 
								AND EXISTS(
									SELECT TOP 1 1 
									FROM #tempCustID WITH (NOLOCK) 
									WHERE Type = 1 AND roleid = 3
								) THEN 1
								WHEN @roleid = 4 AND Data.UnlockSC3 = 0 THEN 0
								ELSE 2 END,
			@UnlockSC2 = CASE WHEN @roleid IN (4,3) AND Data.UnlockSC2 = 1 
								AND EXISTS(
									SELECT TOP 1 1 
									FROM #tempCustID WITH (NOLOCK) 
									WHERE Type = 1 AND roleid = 2
								) THEN 1 
								WHEN @roleid IN (4,3) AND Data.UnlockSC2 = 0 THEN 0
								ELSE 2 END,
			@UnlockSC1 = CASE WHEN @roleid IN (4,3,2) AND Data.UnlockSC1 = 1 
								AND EXISTS(
									SELECT TOP 1 1 
									FROM #tempCustID WITH (NOLOCK) 
									WHERE Type = 1 AND roleid = 1
								) THEN 1
								WHEN @roleid IN (4,3,2) AND Data.UnlockSC1 = 0 THEN 0 
								ELSE 2 END,

			@UnlockBB3 = CASE WHEN @roleid = 4 AND Data.UnlockBB3 = 1 
								AND EXISTS(
									SELECT TOP 1 1 
									FROM #tempCustID WITH (NOLOCK) 
									WHERE Type = 3 AND roleid = 3
								) THEN 1 
								WHEN @roleid = 4 AND Data.UnlockBB3 = 0 THEN 0
								ELSE 2 END,
			@UnlockBB2 = CASE WHEN @roleid IN (4,3) AND Data.UnlockBB2 = 1 
								AND EXISTS(
									SELECT TOP 1 1 
									FROM #tempCustID WITH (NOLOCK) 
									WHERE Type = 3 AND roleid = 2
								) THEN 1 
								WHEN @roleid IN (4,3) AND Data.UnlockBB2 = 0 THEN 0
								ELSE 2 END,
			@UnlockBB1 = CASE WHEN @roleid IN (4,3,2) AND Data.UnlockBB1 = 1 
								AND EXISTS(
									SELECT TOP 1 1 
									FROM #tempCustID WITH (NOLOCK) 
									WHERE Type = 3 AND roleid = 1
								) THEN 1 
								WHEN @roleid IN (4,3,2) AND Data.UnlockBB1 = 0 THEN 0 
								ELSE 2 END,

			@UnlockOS3 = CASE WHEN @roleid = 4 AND Data.UnlockOS3 = 1 
								AND EXISTS(
									SELECT TOP 1 1 
									FROM #tempCustID WITH (NOLOCK) 
									WHERE Type = 2 AND roleid = 3
								) THEN 1 
								WHEN @roleid = 4 AND Data.UnlockOS3 = 0 THEN 0 
								ELSE 2 END,
			@UnlockOS2 = CASE WHEN @roleid IN (4,3) AND Data.UnlockOS2 = 1 
								AND EXISTS(
									SELECT TOP 1 1 
									FROM #tempCustID WITH (NOLOCK) 
									WHERE Type = 2 AND roleid = 2
								) THEN 1 
								WHEN @roleid IN(4,3) AND Data.UnlockOS2 = 0 THEN 0
								ELSE 2 END,
			@UnlockOS1 = CASE WHEN @roleid IN (4,3,2) AND Data.UnlockOS1 = 1 
								AND EXISTS(
									SELECT TOP 1 1 
									FROM #tempCustID WITH (NOLOCK) 
									WHERE Type = 2 AND roleid = 1
								) THEN 1 
								WHEN @roleid IN (4,3,2) AND Data.UnlockOS1 = 0 THEN 0
								ELSE 2 END,

			@EnableAB3 = CASE WHEN @roleid = 4 AND Data.EnableAB3 = 0 
								AND EXISTS(
									SELECT TOP 1 1 
									FROM #tempCustID WITH (NOLOCK) 
									WHERE Type = 4 AND roleid = 3
								) THEN 0 
								WHEN @roleid = 4 AND Data.EnableAB3 = 1 THEN 1  
								ELSE 2 END,
			@EnableAB2 = CASE WHEN @roleid IN (4,3) AND Data.EnableAB2 = 0 
								AND EXISTS(
									SELECT TOP 1 1 
									FROM #tempCustID WITH (NOLOCK) 
									WHERE Type = 4 AND roleid = 2
								) THEN 0
								WHEN @roleid IN (4,3) AND Data.EnableAB2 = 1 THEN 1
								ELSE 2 END,
			@EnableAB1 = CASE WHEN @roleid IN (4,3,2) AND Data.EnableAB1 = 0
								AND EXISTS(
									SELECT TOP 1 1 
									FROM #tempCustID WITH (NOLOCK) 
									WHERE Type = 4 AND roleid = 1
								) THEN 0
								WHEN @roleid IN (4,3,2) AND Data.EnableAB1 = 1 THEN 1
								ELSE 2 END
		FROM OPENXML (@DocHandler, '/ROOT/VR',1) 
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

		EXEC sp_xml_removedocument @DocHandler
		-- end read xml	
	END

	SELECT @AdditionalActions = '<ROOT><VR UnlockSC3="' + cast(@UnlockSC3 as char(1)) + '" ' +
											'UnlockSC2="' + cast(@UnlockSC2 as char(1)) + '" ' +
											'UnlockSC1="' + cast(@UnlockSC1 as char(1)) + '" ' +
											'UnlockBB3="' + cast(@UnlockBB3 as char(1)) + '" ' +
											'UnlockBB2="' + cast(@UnlockBB2 as char(1)) + '" ' +
											'UnlockBB1="' + cast(@UnlockBB1 as char(1)) + '" ' +
											'UnlockOS3="' + cast(@UnlockOS3 as char(1)) + '" ' +
											'UnlockOS2="' + cast(@UnlockOS2 as char(1)) + '" ' +
											'UnlockOS1="' + cast(@UnlockOS1 as char(1)) + '" ' +
											'EnableAB3="' + cast(@EnableAB3 as char(1)) + '" ' +
											'EnableAB2="' + cast(@EnableAB2 as char(1)) + '" ' +
											'EnableAB1="' + cast(@EnableAB1 as char(1)) + '" /></ROOT>'

	DECLARE  
		@Log_EnableAB_Downlines			VARCHAR(MAX) = ''
		,@Log_UnlockSC_Downlines		VARCHAR(MAX) = ''
		,@Log_UnlockBB_Downlines		VARCHAR(MAX) = ''
		,@Log_UnlockOS_Downlines		VARCHAR(MAX) = ''
		,@Log_DisableAB_Downlines		VARCHAR(MAX) = ''
		,@Log_LockSC_Downlines			VARCHAR(MAX) = ''
		,@Log_LockBB_Downlines			VARCHAR(MAX) = ''
		,@Log_LockOS_Downlines			VARCHAR(MAX) = ''
		,@EnableABDownline				BIT = 0
		,@UnlockSCDownLine				BIT = 0
		,@UnlockBBDownLine				BIT = 0
		,@UnlockOSDownLine				BIT = 0
		,@DisableABDownline				BIT = 0
		,@LockSCDownLine				BIT = 0
		,@LockBBDownLine				BIT = 0
		,@LockOSDownLine				BIT = 0

	--Soccer additional actions
	IF (@roleid = 4 AND (@UnlockSC3 = 1 OR @UnlockSC2 = 1 OR @UnlockSC1 = 1))	--Unlock
		OR (@roleid = 3 AND (@UnlockSC2 = 1 OR @UnlockSC1 = 1))
		OR (@roleid = 2 AND @UnlockSC1 = 1)
	BEGIN
		SET @UnlockSCDownLine = 1
		SELECT @Log_UnlockSC_Downlines = '<Acc_CustomerUpdVirtualMultiplier CustID="' + cast(@custid as varchar(50))+ '" ' +  							
						CASE WHEN @UnlockSC3 = 1 THEN 'LockMaster-Soccer="0" ' ELSE '' END + 
						CASE WHEN @UnlockSC2 = 1 THEN 'LockAgent-Soccer="0" ' ELSE '' END +
						CASE WHEN @UnlockSC1 = 1 THEN 'LockMember-Soccer="0" ' ELSE '' END + 
						'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" '+  
						'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(50)),space(1)) + '" '+  
						'IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+'" />'
	END

	IF (@roleid = 4 AND (@UnlockSC3 = 0 OR @UnlockSC2 = 0 OR @UnlockSC1 = 0))	--Lock
		OR (@roleid = 3 AND (@UnlockSC2 = 0 OR @UnlockSC1 = 0))
		OR (@roleid = 2 AND @UnlockSC1 = 0)
	BEGIN
		SET @LockSCDownLine = 1
		SELECT @Log_LockSC_Downlines = '<Acc_CustomerUpdVirtualMultiplier CustID="' + cast(@custid as varchar(50))+ '" ' +  							
							CASE WHEN @UnlockSC3 = 0 THEN 'LockMaster-Soccer="1" ' ELSE '' END + 
							CASE WHEN @UnlockSC2 = 0 THEN 'LockAgent-Soccer="1" ' ELSE '' END +
							CASE WHEN @UnlockSC1 = 0 THEN 'LockMember-Soccer="1" ' ELSE '' END + 
							'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" '+  
							'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(50)),space(1)) + '" '+  
							'IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+'" />'
	END

	--OtherSports additional actions
	IF (@roleid = 4 AND (@UnlockOS3 = 1 OR @UnlockOS2 = 1 OR @UnlockOS1 = 1))	--Unlock
		OR (@roleid = 3 AND (@UnlockOS2 = 1 OR @UnlockOS1 = 1))
		OR (@roleid = 2 AND @UnlockOS1 = 1)
	BEGIN
		SET @UnlockOSDownLine = 1
		SELECT @Log_UnlockOS_Downlines = '<Acc_CustomerUpdVirtualMultiplier CustID="' + cast(@custid as varchar(50))+ '" ' +  							
							CASE WHEN @UnlockOS3 = 1 THEN 'LockMaster-OtherSports="0" ' ELSE '' END + 
							CASE WHEN @UnlockOS2 = 1 THEN 'LockAgent-OtherSports="0" ' ELSE '' END + 
							CASE WHEN @UnlockOS1 = 1 THEN 'LockMember-OtherSports="0" ' ELSE '' END + 
							'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" '+  
							'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(50)),space(1)) + '" '+  
							'IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+'" />'	
	END

	IF (@roleid = 4 AND (@UnlockOS3 = 0 OR @UnlockOS2 = 0 OR @UnlockOS1 = 0))	--Lock
		OR (@roleid = 3 AND (@UnlockOS2 = 0 OR @UnlockOS1 = 0))
		OR (@roleid = 2 AND @UnlockOS1 = 0)
	BEGIN
		SET @LockOSDownLine = 1
		SELECT @Log_LockOS_Downlines = '<Acc_CustomerUpdVirtualMultiplier CustID="' + cast(@custid as varchar(50))+ '" ' +  							
							CASE WHEN @UnlockOS3 = 0 THEN 'LockMaster-OtherSports="1" ' ELSE '' END + 
							CASE WHEN @UnlockOS2 = 0 THEN 'LockAgent-OtherSports="1" ' ELSE '' END + 
							CASE WHEN @UnlockOS1 = 0 THEN 'LockMember-OtherSports="1" ' ELSE '' END + 
							'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" '+  
							'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(50)),space(1)) + '" '+  
							'IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+'" />'	
	END

	--Basketball additional actions
	IF (@roleid = 4 AND (@UnlockBB3 = 1 OR @UnlockBB2 = 1 OR @UnlockBB1 = 1))	--Unlock
		OR (@roleid = 3 AND (@UnlockBB2 = 1 OR @UnlockBB1 = 1))
		OR (@roleid = 2 AND @UnlockBB1 = 1)
	BEGIN
		SET @UnlockBBDownLine = 1
		SELECT @Log_UnlockBB_Downlines = '<Acc_CustomerUpdVirtualMultiplier CustID="' + cast(@custid as varchar(50))+ '" ' +  							
							CASE WHEN @UnlockBB3 = 1 THEN 'LockMaster-Basketball="0" ' ELSE '' END + 
							CASE WHEN @UnlockBB2 = 1 THEN 'LockAgent-Basketball="0" ' ELSE '' END +
							CASE WHEN @UnlockBB1 = 1 THEN 'LockMember-Basketball="0" ' ELSE '' END + 
							'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" '+  
							'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(50)),space(1)) + '" '+  
							'IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+'" />'
	END

	IF (@roleid = 4 AND (@UnlockBB3 = 0 OR @UnlockBB2 = 0 OR @UnlockBB1 = 0))	--Lock
		OR (@roleid = 3 AND (@UnlockBB2 = 0 OR @UnlockBB1 = 0))
		OR (@roleid = 2 AND @UnlockBB1 = 0)
	BEGIN
		SET @LockBBDownLine = 1
		SELECT @Log_LockBB_Downlines = '<Acc_CustomerUpdVirtualMultiplier CustID="' + cast(@custid as varchar(50))+ '" ' +  							
						CASE WHEN @UnlockBB3 = 0 THEN 'LockMaster-Basketball="1" ' ELSE '' END + 
						CASE WHEN @UnlockBB2 = 0 THEN 'LockAgent-Basketball="1" ' ELSE '' END +
						CASE WHEN @UnlockBB1 = 0 THEN 'LockMember-Basketball="1" ' ELSE '' END + 
						'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" '+  
						'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(50)),space(1)) + '" '+  
						'IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+'" />'
	END

	--VR+ additional actions
	IF (@roleid = 4 AND (@EnableAB3 = 1 OR @EnableAB2 = 1 OR @EnableAB1 = 1))	--Enable
		OR (@roleid = 3 AND (@EnableAB2 = 1 OR @EnableAB1 = 1))
		OR (@roleid = 2 AND @EnableAB1 = 1)
	BEGIN
		SET @EnableABDownLine = 1
		SELECT @Log_EnableAB_Downlines = '<Acc_CustomerUpdVirtualMultiplier CustID="' + cast(@custid as varchar(50))+ '" ' +  							
							CASE WHEN @EnableAB3 = 1 THEN 'VRAccumulatedBalance-Master="1" ' ELSE '' END + 
							CASE WHEN @EnableAB2 = 1 THEN 'VRAccumulatedBalance-Agent="1" ' ELSE '' END +
							CASE WHEN @EnableAB1 = 1 THEN 'VRAccumulatedBalance-Member="1" ' ELSE '' END + 
							'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" '+  
							'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(50)),space(1)) + '" '+  
							'IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+'" />'
	END

	IF (@roleid = 4 AND (@EnableAB3 = 0 OR @EnableAB2 = 0 OR @EnableAB1 = 0))	--Disable
		OR (@roleid = 3 AND (@EnableAB2 = 0 OR @EnableAB1 = 0))
		OR (@roleid = 2 AND @EnableAB1 = 0)
	BEGIN
		SET @DisableABDownline = 1
		SELECT @Log_DisableAB_Downlines = '<Acc_CustomerUpdVirtualMultiplier CustID="' + cast(@custid as varchar(50))+ '" ' +  							
							CASE WHEN @EnableAB3 = 0 THEN 'VRAccumulatedBalance-Master="0" ' ELSE '' END + 
							CASE WHEN @EnableAB2 = 0 THEN 'VRAccumulatedBalance-Agent="0" ' ELSE '' END +
							CASE WHEN @EnableAB1 = 0 THEN 'VRAccumulatedBalance-Member="0" ' ELSE '' END + 
							'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" '+  
							'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(50)),space(1)) + '" '+  
							'IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+'" />'
	END

	--UPDATE
	--TODO: Step 1
	--Unlock selected account's VR/ Enable selected account's VR+ if any
	DELETE
	FROM VRCustLockStatus WITH (ROWLOCK)
	WHERE custid = @custid 
		AND 1 = CASE WHEN (@IsUpdate_VRLockedStatus_Soccer = 1 AND @VRLockedStatus_Soccer = 0 AND Type = 1) 
						OR (@IsUpdate_VRLockedStatus_OS = 1 AND @VRLockedStatus_OS = 0 AND Type = 2)
						OR (@IsUpdate_VRLockedStatus_Basketball = 1 AND @VRLockedStatus_BasketBall = 0 AND Type = 3)
					THEN 1
					ELSE 0
				END
	
	IF @IsUpdate_VRAccumulate_Balance = 1 AND @VRAccumulate_Balance = 1 
	BEGIN
		INSERT INTO VRCustLockStatus(CustID, type)
		SELECT @custid, 4 AS Type
	END

	--TODO: Step 2
	--Unlock downlines's VR/ Enable downlines's VR+ if any
	IF @UnlockSCDownLine  = 1 OR @UnlockBBDownLine = 1 OR @UnlockOSDownLine = 1
	BEGIN
		EXECUTE	dbo.Acc_CustomerInfo_Execrep_04
				@custid = @custid
			,	@roleid = @roleid
			,	@action = 'UnlockVRDownline'
			,   @AdditionalActions = @AdditionalActions
	END

	IF @EnableABDownline  = 1
	BEGIN
		EXECUTE	dbo.Acc_CustomerInfo_Execrep_04   
				@custid = @custid
			,	@roleid = @roleid
			,	@action = 'EnableABDownline'
			,   @AdditionalActions = @AdditionalActions
	END

	--TODO: Step 3
	--Update VR value if any
	EXECUTE	dbo.Acc_CustomerInfo_Execrep_04   
				@custid = @custid
			,	@roleid = @roleid
			,	@action = 'VirtualMultiplier'
			,	@EnableVirtualrate = @EnableVirtualrate
			,	@virtualmultiplier = @virtualmultiplier
		
	--TODO: Step 4
	--Lock selected account's VR/ Disable selected account's VR+ if any 
	IF @IsUpdate_VRLockedStatus_Soccer = 1 AND @VRLockedStatus_Soccer = 1
	BEGIN
		INSERT INTO VRCustLockStatus(CustID, type)
		SELECT @custid, 1 AS Type
	END
	IF @IsUpdate_VRLockedStatus_OS = 1 AND @VRLockedStatus_OS = 1
	BEGIN
		INSERT INTO VRCustLockStatus(CustID, type)
		SELECT @custid, 2 AS Type
	END
	IF @IsUpdate_VRLockedStatus_Basketball = 1 AND @VRLockedStatus_BasketBall = 1
	BEGIN
		INSERT INTO VRCustLockStatus(CustID, type)
		SELECT @custid, 3 AS Type
	END
	
	IF @IsUpdate_VRAccumulate_Balance = 1 AND @VRAccumulate_Balance = 0
	BEGIN
		DELETE 
		FROM VRCustLockStatus WITH (ROWLOCK)
		WHERE custid = @custid AND Type = 4
	END

	--TODO: Step 5
	--Lock downlines's VR/ Disable downlines's VR+ if any 
	IF @LockSCDownLine  = 1 OR @LockBBDownLine = 1 OR @LockOSDownLine = 1
	BEGIN
		EXECUTE	dbo.Acc_CustomerInfo_Execrep_04
				@custid = @custid
			,	@roleid = @roleid
			,	@action = 'LockVRDownline'
			,   @AdditionalActions = @AdditionalActions
	END

	IF @DisableABDownline  = 1
	BEGIN
		EXECUTE	dbo.Acc_CustomerInfo_Execrep_04
				@custid = @custid
			,	@roleid = @roleid
			,	@action = 'DisableABDownline'
			,   @AdditionalActions = @AdditionalActions
	END

	--Check if selected account's VR value has changed
	DECLARE @IsUpdateVRUpline BIT = 0
	IF EXISTS(
		SELECT TOP 1 1
		FROM @tblVirtualrate new 
			INNER JOIN @tblVirtualRate_old old ON new.SportType = old.sporttype AND new.BetType = old.bettype AND new.IsLive = old.islive
		WHERE new.VirtualMultiplier <> old.virtualMultiplier
	)
	SET @IsUpdateVRUpline = 1

	--Check if VR value of downlines has changed
	DECLARE @IsUpdateVRDownlines BIT = 0
	IF EXISTS(
			SELECT TOP 1 1
			FROM #DownlinesVRValue t
				CROSS APPLY CustVirtualSetting cvs WITH (NOLOCK)
			WHERE t.custid = cvs.custid AND t.seqNo = cvs.seqNo AND t.bitmapVirtual <> cvs.bitmapVirtual
	)
	SET @IsUpdateVRDownlines = 1

	--Write log change VR value
	DECLARE @VRTrackingValue VARCHAR(MAX) = '',
			@VRTrackingValue2 VARCHAR(MAX) = ''
	IF @IsUpdateVRDownlines = 1 OR @IsUpdateVRUpline = 1
	BEGIN
		SELECT @VRTrackingValue = 		
		(
			SELECT SportType
				,BetType
				,IsLive
				,VirtualMultiplier
			FROM @tblVirtualrate
			ORDER BY sporttype,isLive DESC,bettype
			FOR XML  RAW('s')
		)

		SELECT @VRTrackingValue = '<Acc_CustomerUpdVirtualMultiplier CustID="'+ cast(@custid as varchar(50))+ '" ' +  
									'CopyFrom="'+ coalesce(cast(@CopyFrom as varchar(50)),space(1))+ '" ' + 
									'UserID="'+ cast(@UserID as varchar(50))+ '" ' + 
									CASE @roleid WHEN 1 THEN ''
													ELSE 'IsUpdateVR="' + cast(@IsUpdateVRUpline as varchar(2)) +'" ' 
												END +
									CASE @roleid WHEN 1 THEN ''
													ELSE 'IsApplyDownlines="' + cast(@IsUpdateVRDownlines as varchar(2)) + '" ' 
												END +
									'ErrCode="'+ cast(@ErrCode as varchar(50)) + '" '+  
									'ErrMsg="'+ cast(@ErrMsg as varchar(50)) + '" '+  
									'IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+'">'  
									+ @VRTrackingValue +
									'</Acc_CustomerUpdVirtualMultiplier>'

		SELECT @VRTrackingValue2 = 		
		(
			SELECT SportType
				,BetType
				,IsLive
				,VirtualMultiplier
			FROM @tblVirtualRate_old
			ORDER BY sporttype,isLive DESC,bettype
			FOR XML  RAW('s')
		)

		SELECT @VRTrackingValue2 = '<Acc_CustomerUpdVirtualMultiplier CustID="'+ cast(@custid as varchar(50))+ '" ' 
									 + @VRTrackingValue2 +
									'</Acc_CustomerUpdVirtualMultiplier>'
	END

	Declare @LogSPData varchar(MAX) = ''
			--,@LogSPData2 varchar(MAX)= ''  
	
	IF @OldEnableVirtualrate <> @EnableVirtualrate 
	BEGIN
		Select @LogSPData = '<Acc_CustomerUpdVirtualMultiplier CustID="'+ cast(@custid as varchar(50))+ '" ' +  
						'EnableVirtualrate="'+ cast(@EnableVirtualrate as varchar(50))+ '" ' +  						
						'UserID="'+ cast(@UserID as varchar(50))+ '" ' +  
						'ErrCode="'+ cast(@ErrCode as varchar(50)) + '" '+  
						'ErrMsg="'+ cast(@ErrMsg as varchar(50)) + '" '+  
						'IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+'" />'  
	  
	END
		  
	set @endRun = getdate()  
	set @duration  = datediff (millisecond,@startRun,@endRun) 
	  
	--WRITE LOG
	--Step 1: Unlock selected account's VR/ Enable selected account's VR+ log
	IF @LogSPData_SC <> '' AND @VRLockedStatus_Soccer = 0		--Unlock Soccer
	BEGIN
		EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
				@UserId				= @UserId,
				@CustId				= @CustId,
				@ActionId			= 844,
				@TrackingValue		= @LogSPData_SC,
				@Duration			= @Duration	
	END

	IF @LogSPData_OS <> '' AND @VRLockedStatus_OS = 0			--Unlock Other sports
	BEGIN
		EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
				@UserId				= @UserId,
				@CustId				= @CustId,
				@ActionId			= 845,
				@TrackingValue		= @LogSPData_OS,
				@Duration			= @Duration			
	END

	IF @LogSPData_BB <> '' AND @VRLockedStatus_BasketBall = 0	--Unlock Basketball
	BEGIN
		EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
				@UserId				= @UserId,
				@CustId				= @CustId,
				@ActionId			= 846,
				@TrackingValue		= @LogSPData_BB,
				@Duration			= @Duration			
	END

	IF @LogSPData_AB <> '' AND @VRAccumulate_Balance = 1		--Enable VR+
	BEGIN
		EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
				@UserId				= @UserId,
				@CustId				= @CustId,
				@ActionId			= 847,
				@TrackingValue		= @LogSPData_AB,
				@Duration			= @Duration	
	END

	--Step 2: Unlock downlines's VR/ Enable downlines's VR+ log
	IF @Log_UnlockSC_Downlines <> ''	--Unlock Soccer
	BEGIN
		EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
				@UserId				= @UserId,
				@CustId				= @CustId,
				@ActionId			= 840,
				@TrackingValue		= @Log_UnlockSC_Downlines,
				@Duration			= @Duration	
	END

	IF @Log_UnlockOS_Downlines <> ''	--Unlock Other sports
	BEGIN
		EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
				@UserId				= @UserId,
				@CustId				= @CustId,
				@ActionId			= 842,
				@TrackingValue		= @Log_UnlockOS_Downlines,
				@Duration			= @Duration	
	END

	IF @Log_UnlockBB_Downlines <> ''	--Unlock Basketball
	BEGIN
		EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
				@UserId				= @UserId,
				@CustId				= @CustId,
				@ActionId			= 841,
				@TrackingValue		= @Log_UnlockBB_Downlines,
				@Duration			= @Duration	
	END

	IF @Log_EnableAB_Downlines <> ''	--Enable VR+			
	BEGIN														
		EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper				
				@UserId				= @UserId,					
				@CustId				= @CustId,					
				@ActionId			= 843,
				@TrackingValue		= @Log_EnableAB_Downlines,			
				@Duration			= @Duration					
	END		

	--Step 3: Change VR status/value log
	IF @IsLicenseeUser=0  --For accounting admin  
	BEGIN  
		/*801 Acc_CustomerUpdVirtualMult Update Virtual Rate */  
		IF @LogSPData <> ''
		BEGIN TRY
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP  
				@UserID = @UserID,  
				@CustID = @CustID,  
				@ActionID = 806,  
				@TrackingValue = @LogSPData,  
				@duration = @duration  
		END TRY
		BEGIN CATCH  
			Select @LogSPData = '<Acc_CustomerUpdVirtualMultiplier CustID="'+ cast(@custid as varchar(50))+ '" ' +  
						'EnableVirtualrate="'+ cast(@EnableVirtualrate as varchar(50))+ '" ' +  						
						'UserID="'+ cast(@UserID as varchar(50))+ '" ' +  
						'ErrCode="'+ cast(@ErrCode as varchar(50)) + '" '+  
						'ErrMsg="'+ cast(ERROR_MESSAGE() as varchar(50)) + '" '+  
						'IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+'" />'  
	                      
			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP  
				@UserID = @UserID,  
				@CustID = @CustID,  
				@ActionID = 806,  
				@TrackingValue = @LogSPData,  
				@duration = @duration  
		END CATCH 
		
		--IF @LogSPData2 <> ''
		--BEGIN TRY  
		--	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP  
		--		@UserID = @UserID,  
		--		@CustID = @CustID,  
		--		@ActionID = 801,  
		--		@TrackingValue = @LogSPData2,  
		--		@duration = @duration  
		--END TRY  
		--BEGIN CATCH  
		--	EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP  
		--		@UserID = @UserID,  
		--		@CustID = @CustID,  
		--		@ActionID = 801,  
		--		@TrackingValue = @LogSPData2,  
		--		@duration = @duration  
		--END CATCH  
		IF @VRTrackingValue <> ''
		BEGIN
			IF @roleid = 4
				EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper				
					@UserId				= @UserId,					
					@CustId				= @CustId,					
					@ActionId			= 95116,
					@TrackingValue		= @VRTrackingValue,	
					@TrackingValue2		= @VRTrackingValue2,
					@Duration			= @Duration	
			ELSE IF @roleid = 3
				EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper				
					@UserId				= @UserId,					
					@CustId				= @CustId,					
					@ActionId			= 95117,
					@TrackingValue		= @VRTrackingValue,
					@TrackingValue2		= @VRTrackingValue2,
					@Duration			= @Duration	
			ELSE IF @roleid = 2
				EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper				
					@UserId				= @UserId,					
					@CustId				= @CustId,					
					@ActionId			= 95118,
					@TrackingValue		= @VRTrackingValue,		
					@TrackingValue2		= @VRTrackingValue2,
					@Duration			= @Duration	
			ELSE IF @roleid = 1
				EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper				
					@UserId				= @UserId,					
					@CustId				= @CustId,					
					@ActionId			= 801,
					@TrackingValue		= @VRTrackingValue,
					@TrackingValue2		= @VRTrackingValue2,
					@Duration			= @Duration	
		END
	END  
	ELSE -- For Licensee user  
	BEGIN  
		IF @LogSPData <> ''
		BEGIN TRY
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP  
				@UserID = @UserID,  
				@CustID = @CustID,  
				@ActionID = 2802,  
				@TrackingValue = @LogSPData,  
				@duration = @duration  
		END TRY
		BEGIN CATCH  
			Select @LogSPData = '<Acc_CustomerUpdVirtualMultiplier CustID="'+ cast(@custid as varchar(50))+ '" ' +  
						'EnableVirtualrate="'+ cast(@EnableVirtualrate as varchar(50))+ '" ' +  						
						'UserID="'+ cast(@UserID as varchar(50))+ '" ' +  
						'ErrCode="'+ cast(@ErrCode as varchar(50)) + '" '+  
						'ErrMsg="'+ cast(ERROR_MESSAGE() as varchar(50)) + '" '+  
						'IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+'" />'  
	                      
			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP  
				@UserID = @UserID,  
				@CustID = @CustID,  
				@ActionID = 2802,  
				@TrackingValue = @LogSPData,  
				@duration = @duration  
		END CATCH 
		
		--IF @LogSPData2 <> ''
		--BEGIN TRY  
		--	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP  
		--		@UserID = @UserID,  
		--		@CustID = @CustID,  
		--		@ActionID = 2800,  
		--		@TrackingValue = @LogSPData2,  
		--		@duration = @duration  
		--END TRY  
		--BEGIN CATCH  
		--	EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP  
		--		@UserID = @UserID,  
		--		@CustID = @CustID,  
		--		@ActionID = 2800,  
		--		@TrackingValue = @LogSPData2,  
		--		@duration = @duration  
		--END CATCH   
		IF @VRTrackingValue <> ''
		BEGIN
			IF @roleid = 4
				EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper				
					@UserId				= @UserId,					
					@CustId				= @CustId,					
					@ActionId			= 2803,
					@TrackingValue		= @VRTrackingValue,	
					@TrackingValue2		= @VRTrackingValue2,
					@Duration			= @Duration	
			ELSE IF @roleid = 3
				EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper				
					@UserId				= @UserId,					
					@CustId				= @CustId,					
					@ActionId			= 2804,
					@TrackingValue		= @VRTrackingValue,
					@TrackingValue2		= @VRTrackingValue2,
					@Duration			= @Duration	
			ELSE IF @roleid = 2
				EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper				
					@UserId				= @UserId,					
					@CustId				= @CustId,					
					@ActionId			= 2805,
					@TrackingValue		= @VRTrackingValue,		
					@TrackingValue2		= @VRTrackingValue2,
					@Duration			= @Duration	
			ELSE IF @roleid = 1
				EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper				
					@UserId				= @UserId,					
					@CustId				= @CustId,					
					@ActionId			= 2800,
					@TrackingValue		= @VRTrackingValue,
					@TrackingValue2		= @VRTrackingValue2,
					@Duration			= @Duration	
		END
	END
	
	--Step 4: Lock selected account's VR/ Disable selected account's VR+ log
	IF @LogSPData_SC <> '' AND @VRLockedStatus_Soccer = 1		--Lock Soccer
	BEGIN
		EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
				@UserId				= @UserId,
				@CustId				= @CustId,
				@ActionId			= 844,
				@TrackingValue		= @LogSPData_SC,
				@Duration			= @Duration	
	END

	IF @LogSPData_OS <> '' AND @VRLockedStatus_OS = 1			--Lock Other sports
	BEGIN
		EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
				@UserId				= @UserId,
				@CustId				= @CustId,
				@ActionId			= 845,
				@TrackingValue		= @LogSPData_OS,
				@Duration			= @Duration	
	END

	IF @LogSPData_BB <> '' AND @VRLockedStatus_BasketBall = 1	--Lock Basketball
	BEGIN
		EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
				@UserId				= @UserId,
				@CustId				= @CustId,
				@ActionId			= 846,
				@TrackingValue		= @LogSPData_BB,
				@Duration			= @Duration	
	END

	IF @LogSPData_AB <> '' AND @VRAccumulate_Balance = 0		--Disable VR+
	BEGIN
		EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
				@UserId				= @UserId,
				@CustId				= @CustId,
				@ActionId			= 847,
				@TrackingValue		= @LogSPData_AB,
				@Duration			= @Duration	
	END

	--Step 5: Lock downlines's VR/ Disable downlines's VR+ log
	IF @Log_LockSC_Downlines <> ''		--Lock Soccer
	BEGIN
		EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper	
				@UserId				= @UserId,
				@CustId				= @CustId,
				@ActionId			= 840,
				@TrackingValue		= @Log_LockSC_Downlines,
				@Duration			= @Duration	
	END

	IF @Log_LockOS_Downlines <> ''		--Lock Other sports
	BEGIN
		EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
				@UserId				= @UserId,
				@CustId				= @CustId,
				@ActionId			= 842,
				@TrackingValue		= @Log_LockOS_Downlines,
				@Duration			= @Duration	
	END

	IF @Log_LockBB_Downlines <> ''		--Lock Basketball
	BEGIN
		EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
				@UserId				= @UserId,
				@CustId				= @CustId,
				@ActionId			= 841,
				@TrackingValue		= @Log_LockBB_Downlines,
				@Duration			= @Duration	
	END

	IF @Log_DisableAB_Downlines <> ''	--Disable VR+					
	BEGIN														
		EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper				
				@UserId				= @UserId,					
				@CustId				= @CustId,					
				@ActionId			= 843,
				@TrackingValue		= @Log_DisableAB_Downlines,			
				@Duration			= @Duration					
	END	
END
GO
