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
				,	@Is_VRAccumulate_Balance	BIT = NULL --Checked Apply All Downline or not
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
	DECLARE	@UnlockSC3		BIT, --Unlock VR Soccer all Masters
			@UnlockSC2		BIT, --Unlock VR Soccer all Agents
			@UnlockSC1		BIT, --Unlock VR Soccer all Members

			@UnlockBB3		BIT, --Unlock VR Basketball all Masters
			@UnlockBB2		BIT, --Unlock VR Basketball all Agents
			@UnlockBB1		BIT, --Unlock VR Basketball all Members

			@UnlockOS3		BIT, --Unlock VR Other Sports all Masters
			@UnlockOS2		BIT, --Unlock VR Other Sports all Agents
			@UnlockOS1		BIT, --Unlock VR Other Sports all Members

			@Enable3		BIT, --Enable VR all Masters
			@Enable2		BIT, --Enable VR all Agents
			@Enable1		BIT --Enable VR all Members

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

	EXECUTE	dbo.Acc_CustomerInfo_Execrep_04   
				@custid = @custid
			,	@roleid = @roleid
			,	@action = 'VirtualMultiplier'
			,	@EnableVirtualrate = @EnableVirtualrate
			,	@virtualmultiplier = @virtualmultiplier
			
	DECLARE   @Old_VRLockedStatus_Soccer BIT = 0
			, @IsUpdate_VRLockedStatus_Soccer BIT = 0
			, @Old_VRLockedStatus_OS BIT = 0
			, @IsUpdate_VRLockedStatus_OS BIT = 0
			, @Old_VRLockedStatus_Basketball BIT = 0
			, @IsUpdate_VRLockedStatus_Basketball BIT = 0
			, @Old_VRAccumulate_Balance BIT = 0
			, @IsUpdate_VRAccumulate_Balance BIT = 0


	IF EXISTS ( SELECT 1 FROM VRCustLockStatus WITH(NOLOCK) WHERE custid = @custid AND Type = 1)
		SET @Old_VRLockedStatus_Soccer = 1

	SET @VRLockedStatus_Soccer = ISNULL(@VRLockedStatus_Soccer,@Old_VRLockedStatus_Soccer)

	IF @VRLockedStatus_Soccer <> @Old_VRLockedStatus_Soccer
	BEGIN
		SET @IsUpdate_VRLockedStatus_Soccer = 1
	END 

	IF EXISTS ( SELECT 1 FROM VRCustLockStatus WITH(NOLOCK) WHERE custid = @custid AND Type = 2)
		SET @Old_VRLockedStatus_OS = 1
	
	SET @VRLockedStatus_OS = ISNULL(@VRLockedStatus_OS,@Old_VRLockedStatus_OS)

	IF @VRLockedStatus_OS <> @Old_VRLockedStatus_OS
	BEGIN
		SET @IsUpdate_VRLockedStatus_OS = 1
	END

	IF EXISTS ( SELECT 1 FROM VRCustLockStatus WITH(NOLOCK) WHERE custid = @custid AND Type = 3)			
		SET @Old_VRLockedStatus_BasketBall = 1																
	
	SET @VRLockedStatus_BasketBall = ISNULL(@VRLockedStatus_Basketball,@Old_VRLockedStatus_Basketball)		

	IF @VRLockedStatus_BasketBall <> @Old_VRLockedStatus_Basketball										
	BEGIN																									
		SET @IsUpdate_VRLockedStatus_Basketball = 1															
	END	

	IF EXISTS ( SELECT 1 FROM VRCustLockStatus WITH(NOLOCK) WHERE custid = @custid AND Type = 4)			
		SET @Old_VRAccumulate_Balance = 1																
	
	SET @VRAccumulate_Balance = ISNULL(@VRAccumulate_Balance,@Old_VRAccumulate_Balance)		

	IF @VRAccumulate_Balance <> @Old_VRAccumulate_Balance										
	BEGIN																									
		SET @IsUpdate_VRAccumulate_Balance = 1															
	END	

	IF @IsUpdate_VRLockedStatus_OS = 1 OR @IsUpdate_VRLockedStatus_Soccer = 1 OR @IsUpdate_VRLockedStatus_Basketball = 1 OR (@IsUpdate_VRAccumulate_Balance = 1  AND @Is_VRAccumulate_Balance = 0)
	BEGIN
		--Update VR lock status
		EXEC Acc_VRCustLockStatusUpd 
			@custid = @custid
			,@UserID = @UserID
			,@VRLockedStatus_Soccer = @VRLockedStatus_Soccer
			,@VRLockedStatus_OS = @VRLockedStatus_OS
			,@VRLockedStatus_BasketBall = @VRLockedStatus_BasketBall
			,@VRAccumulate_Balance = @VRAccumulate_Balance
			,@IP = @IP
			,@UpdateBy = 'Manual'
			,@ErrCode = @ErrCode OUTPUT
			,@ErrMsg = @ErrMsg OUTPUT

		IF @ErrCode <> 0
			RETURN
	END

	IF @AdditionalActions <> ''
	BEGIN
		CREATE TABLE #tempCustID(custid INT, roleid TINYINT, virtualmultiplier SMALLMONEY, type TINYINT)
		IF @roleid = 4
		BEGIN
			INSERT INTO #tempCustID(custid, roleid, virtualmultiplier, type)
			SELECT c.custid, c.roleid, c.VirtualMultiplier, s.Type
			FROM custinfo c WITH (NOLOCK)
				LEFT JOIN VRCustLockStatus s WITH (NOLOCK) ON c.custid = s.CustID
			WHERE c.srecommend = @custid 
		END
		ELSE IF @roleid = 3
		BEGIN
			INSERT INTO #tempCustID(custid, roleid, virtualmultiplier, type)
			SELECT c.custid, c.roleid, c.VirtualMultiplier, s.Type
			FROM custinfo c WITH (NOLOCK)
				LEFT JOIN VRCustLockStatus s WITH (NOLOCK) ON c.custid = s.CustID
			WHERE c.mrecommend = @custid 
		END
		ELSE IF @roleid = 2
		BEGIN
			INSERT INTO #tempCustID(custid, roleid, virtualmultiplier, type)
			SELECT c.custid, c.roleid, c.VirtualMultiplier, s.Type
			FROM custinfo c WITH (NOLOCK)
				LEFT JOIN VRCustLockStatus s WITH (NOLOCK) ON c.custid = s.CustID
			WHERE c.recommend = @custid 
		END

		-- For read xml					
		EXEC sp_xml_preparedocument @DocHandler OUTPUT, @AdditionalActions

		SELECT
			@UnlockSC3 = CASE WHEN @roleid = 4 AND Data.UnlockSC3 = 1 
								AND EXISTS(
									SELECT TOP 1 1 
									FROM #tempCustID WITH (NOLOCK) 
									WHERE Type = 1 AND roleid = 3
								) THEN 1 ELSE 0 END,
			@UnlockSC2 = CASE WHEN @roleid IN(4,3) AND Data.UnlockSC2 = 1 
								AND EXISTS(
									SELECT TOP 1 1 
									FROM #tempCustID WITH (NOLOCK) 
									WHERE Type = 1 AND roleid = 2
								) THEN 1 ELSE 0 END,
			@UnlockSC1 = CASE WHEN @roleid IN (4,3,2) AND Data.UnlockSC1 = 1 
								AND EXISTS(
									SELECT TOP 1 1 
									FROM #tempCustID WITH (NOLOCK) 
									WHERE Type = 1 AND roleid = 1
								) THEN 1 ELSE 0 END,

			@UnlockBB3 = CASE WHEN @roleid = 4 AND Data.UnlockBB3 = 1 
								AND EXISTS(
									SELECT TOP 1 1 
									FROM #tempCustID WITH (NOLOCK) 
									WHERE Type = 3 AND roleid = 3
								) THEN 1 ELSE 0 END,
			@UnlockBB2 = CASE WHEN @roleid IN(4,3) AND Data.UnlockBB2 = 1 
								AND EXISTS(
									SELECT TOP 1 1 
									FROM #tempCustID WITH (NOLOCK) 
									WHERE Type = 3 AND roleid = 2
								) THEN 1 ELSE 0 END,
			@UnlockBB1 = CASE WHEN @roleid IN (4,3,2) AND Data.UnlockBB1 = 1 
								AND EXISTS(
									SELECT TOP 1 1 
									FROM #tempCustID WITH (NOLOCK) 
									WHERE Type = 3 AND roleid = 1
								) THEN 1 ELSE 0 END,

			@UnlockOS3 = CASE WHEN @roleid = 4 AND Data.UnlockOS3 = 1 
								AND EXISTS(
									SELECT TOP 1 1 
									FROM #tempCustID WITH (NOLOCK) 
									WHERE Type = 2 AND roleid = 3
								) THEN 1 ELSE 0 END,
			@UnlockOS2 = CASE WHEN @roleid IN(4,3) AND Data.UnlockOS2 = 1 
								AND EXISTS(
									SELECT TOP 1 1 
									FROM #tempCustID WITH (NOLOCK) 
									WHERE Type = 2 AND roleid = 2
								) THEN 1 ELSE 0 END,
			@UnlockOS1 = CASE WHEN @roleid IN (4,3,2) AND Data.UnlockOS1 = 1 
								AND EXISTS(
									SELECT TOP 1 1 
									FROM #tempCustID WITH (NOLOCK) 
									WHERE Type = 2 AND roleid = 1
								) THEN 1 ELSE 0 END,

			@Enable3 = CASE WHEN @roleid  = 4 
								AND Data.Enable3 = 1 
								AND EXISTS(
										SELECT TOP 1 1
										FROM #tempCustID c WITH (NOLOCK)
										WHERE c.roleid = 3 AND c.VirtualMultiplier = 0
									) THEN 1 ELSE 0 END,
			@Enable2 = CASE WHEN @roleid IN (4,3) 
								AND Data.Enable2 = 1 
								AND EXISTS(
										SELECT TOP 1 1
										FROM #tempCustID c WITH (NOLOCK)
										WHERE c.roleid = 2 AND c.VirtualMultiplier = 0
									) THEN 1 ELSE 0 END,
			@Enable1 = CASE WHEN @roleid IN (4,3,2) 
								AND Data.Enable1 = 1 
								AND EXISTS(
										SELECT TOP 1 1
										FROM #tempCustID c WITH (NOLOCK)
										WHERE c.roleid = 1 AND c.VirtualMultiplier = 0
									) THEN 1 ELSE 0 END
		FROM OPENXML (@DocHandler, '/ROOT/VR',1) 
		WITH (
			UnlockSC3		BIT,
			UnlockSC2		BIT,
			UnlockSC1		BIT,

			UnlockBB3		BIT,
			UnlockBB2		BIT,
			UnlockBB1		BIT,

			UnlockOS3		BIT,
			UnlockOS2		BIT,
			UnlockOS1		BIT,

			Enable3			BIT,
			Enable2			BIT,
			Enable1			BIT
		) AS Data

		EXEC sp_xml_removedocument @DocHandler
		-- end read xml	
		DROP TABLE #tempCustID
	END

	DECLARE  
		@LogSPDataEnable VARCHAR(MAX) = ''
		,@LogSPDataUnlockSC VARCHAR(MAX) = ''
		,@LogSPDataUnlockBB VARCHAR(MAX) = ''
		,@LogSPDataUnlockOS	VARCHAR(MAX) = ''
		,@IsUnlockSCDownLine BIT = 0
		,@IsUnlockBBDownLine BIT = 0
		,@IsUnlockOSDownLine BIT = 0
		,@IsEnableDownline BIT = 0
		,@ISVR_AccBalance BIT = 0

	--Soccer unlock downline log
	IF (@roleid = 4 AND (@UnlockSC3 = 1 OR @UnlockSC2 = 1 OR @UnlockSC1 = 1))
		OR (@roleid = 3 AND (@UnlockSC2 = 1 OR @UnlockSC1 = 1))
		OR (@roleid = 2 AND @UnlockSC1 = 1)
	BEGIN
		SET @IsUnlockSCDownLine = 1

		SELECT @LogSPDataUnlockSC = '<Acc_CustomerUpdVirtualMultiplier CustID="' + cast(@custid as varchar(50))+ '" ' +  							
							CASE WHEN @UnlockSC3 = 1 THEN 'UnlockMaster-Soccer="1" ' ELSE '' END + 
							CASE WHEN @UnlockSC2 = 1 THEN 'UnlockAgent-Soccer="1" ' ELSE '' END + 
							CASE WHEN @UnlockSC1 = 1 THEN 'UnlockMember-Soccer="1" ' ELSE '' END + 
							'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" '+  
							'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(50)),space(1)) + '" '+  
							'IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+'" />'
	END

	--Basketball unlock downline log
	IF (@roleid = 4 AND (@UnlockBB3 = 1 OR @UnlockBB2 = 1 OR @UnlockBB1 = 1))
		OR (@roleid = 3 AND (@UnlockBB2 = 1 OR @UnlockBB1 = 1))
		OR (@roleid = 2 AND @UnlockBB1 = 1)
	BEGIN
		SET @IsUnlockBBDownLine = 1

		SELECT @LogSPDataUnlockBB = '<Acc_CustomerUpdVirtualMultiplier CustID="' + cast(@custid as varchar(50))+ '" ' +  							
							CASE WHEN @UnlockBB3 = 1 THEN 'UnlockMaster-Basketball="1" ' ELSE '' END + 
							CASE WHEN @UnlockBB2 = 1 THEN 'UnlockAgent-Basketball="1" ' ELSE '' END + 
							CASE WHEN @UnlockBB1 = 1 THEN 'UnlockMember-Basketball="1" ' ELSE '' END + 
							'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" '+  
							'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(50)),space(1)) + '" '+  
							'IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+'" />'
	END

	--Other sports unlock downline log
	IF (@roleid = 4 AND (@UnlockOS3 = 1 OR @UnlockOS2 = 1 OR @UnlockOS1 = 1))
		OR (@roleid = 3 AND (@UnlockOS2 = 1 OR @UnlockOS1 = 1))
		OR (@roleid = 2 AND @UnlockOS1 = 1)
	BEGIN
		SET @IsUnlockOSDownLine = 1

		SELECT @LogSPDataUnlockOS = '<Acc_CustomerUpdVirtualMultiplier CustID="' + cast(@custid as varchar(50))+ '" ' +  							
							CASE WHEN @UnlockOS3 = 1 THEN 'UnlockMaster-OtherSports="1" ' ELSE '' END + 
							CASE WHEN @UnlockOS2 = 1 THEN 'UnlockAgent-OtherSports="1" ' ELSE '' END + 
							CASE WHEN @UnlockOS1 = 1 THEN 'UnlockMember-OtherSports="1" ' ELSE '' END + 
							'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" '+  
							'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(50)),space(1)) + '" '+  
							'IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+'" />'
	END

	--Enable downline log
	IF (@roleid = 4 AND (@Enable3 = 1 OR @Enable2 = 1 OR @Enable1 = 1))
		OR (@roleid = 3 AND (@Enable2 = 1 OR @Enable1 = 1))
		OR (@roleid = 2 AND @Enable1 = 1)
	BEGIN
		SET @IsEnableDownLine = 1

		SELECT @LogSPDataEnable = '<Acc_CustomerUpdVirtualMultiplier CustID="' + cast(@custid as varchar(50))+ '" ' +  							
							CASE WHEN @Enable3 = 1 THEN 'EnableMaster="1" ' ELSE '' END + 
							CASE WHEN @Enable2 = 1 THEN 'EnableAgent="1" ' ELSE '' END + 
							CASE WHEN @Enable1 = 1 THEN 'EnableMember="1" ' ELSE '' END + 
							'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" '+  
							'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(50)),space(1)) + '" '+  
							'IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+'" />'
	END

	IF @IsUnlockSCDownLine  = 1 OR @IsUnlockBBDownLine = 1 OR @IsUnlockOSDownLine = 1 OR @IsEnableDownline = 1
	BEGIN
		SELECT @AdditionalActions = '<ROOT><VR UnlockSC3="' + cast(@UnlockSC3 as char(1)) + '" ' +
												'UnlockSC2="' + cast(@UnlockSC2 as char(1)) + '" ' +
												'UnlockSC1="' + cast(@UnlockSC1 as char(1)) + '" ' +
												'UnlockBB3="' + cast(@UnlockBB3 as char(1)) + '" ' +
												'UnlockBB2="' + cast(@UnlockBB2 as char(1)) + '" ' +
												'UnlockBB1="' + cast(@UnlockBB1 as char(1)) + '" ' +
												'UnlockOS3="' + cast(@UnlockOS3 as char(1)) + '" ' +
												'UnlockOS2="' + cast(@UnlockOS2 as char(1)) + '" ' +
												'UnlockOS1="' + cast(@UnlockOS1 as char(1)) + '" ' +
												'Enable3="' + cast(@Enable3 as char(1)) + '" ' +
												'Enable2="' + cast(@Enable2 as char(1)) + '" ' +
												'Enable1="' + cast(@Enable1 as char(1)) + '" /></ROOT>'
	END
	
	/* @Is_VRAccumulate_Balance:
	0 (UnCheck)   : Is Manual Update
	1 (Check)     : Is Apply For All Downline */
	IF (@roleid = 4 AND (@Is_VRAccumulate_Balance = 1 ))
		OR (@roleid = 3 AND (@Is_VRAccumulate_Balance = 1))
		OR (@roleid = 2 AND (@Is_VRAccumulate_Balance = 1))
	BEGIN
		SET @ISVR_AccBalance = 1
	END

	IF @IsUnlockSCDownLine  = 1 OR @IsUnlockBBDownLine = 1 OR @IsUnlockOSDownLine = 1
	BEGIN
		EXECUTE	dbo.Acc_CustomerInfo_Execrep_04   
				@custid = @custid
			,	@roleid = @roleid
			,	@action = 'UnlockVRDownline'
			,   @AdditionalActions = @AdditionalActions
	END

	IF @IsEnableDownline  = 1
	BEGIN
		EXECUTE	dbo.Acc_CustomerInfo_Execrep_04   
				@custid = @custid
			,	@roleid = @roleid
			,	@action = 'EnableVRDownline'
			,   @AdditionalActions = @AdditionalActions
	END
				
	IF @ISVR_AccBalance  = 1
	BEGIN
	DECLARE @LogSPData_AccBalance varchar(MAX) = ''

		EXECUTE dbo.Acc_CustomerInfo_Execrep_04
				@custid = @custid
			,	@roleid = @roleid
			,	@action = 'ApplyVRAccBalanceAllDownlines'
			,   @VRAccumulate_Balance = @VRAccumulate_Balance

		SELECT @LogSPData_AccBalance = '<R VRAccumulatedBalance="'+ coalesce(cast(@VRAccumulate_Balance as varchar(1)),space(1)) + '" '	
				+ 'IP="' + coalesce(cast(@IP as varchar(15)),space(1)) + '" '							
				+ 'ApplyAllDownlines="1" '
				+ 'UpdatedBy="'+ coalesce(cast('Manual' as varchar(100)),space(1)) + + '" ' 					
				+ ' />'	
	END



				
	Declare @LogSPData varchar(MAX) = '',
			@LogSPData2 varchar(MAX)= ''  
	
	IF @OldEnableVirtualrate <> @EnableVirtualrate 
	BEGIN
		Select @LogSPData = '<Acc_CustomerUpdVirtualMultiplier CustID="'+ cast(@custid as varchar(50))+ '" ' +  
						'EnableVirtualrate="'+ cast(@EnableVirtualrate as varchar(50))+ '" ' +  						
						'UserID="'+ cast(@UserID as varchar(50))+ '" ' +  
						'ErrCode="'+ cast(@ErrCode as varchar(50)) + '" '+  
						'ErrMsg="'+ cast(@ErrMsg as varchar(50)) + '" '+  
						'IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+'" />'  
	  
	END
	
	--IF @EnableVirtualrate = 1
	BEGIN		
		SELECT @LogSPData2 =
		(
			SELECT SportType
				,BetType
				,IsLive
				,VirtualMultiplier
			FROM @tblVirtualrate
			ORDER BY sporttype,isLive DESC,bettype
			FOR XML  RAW('s')
		)
		
		Select @LogSPData2 = '<Acc_CustomerUpdVirtualMultiplier CustID="'+ cast(@custid as varchar(50))+ '" ' +  							
							'CopyFrom="'+ coalesce(cast(@CopyFrom as varchar(50)),space(1))+ '" ' + 
							'UserID="'+ cast(@UserID as varchar(50))+ '" ' +  
							'ErrCode="'+ cast(@ErrCode as varchar(50)) + '" '+  
							'ErrMsg="'+ cast(@ErrMsg as varchar(50)) + '" '+  
							'IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+'">'  
							+ @LogSPData2 +
							'</Acc_CustomerUpdVirtualMultiplier>'							
	END
		  
	set @endRun = getdate()  
	set @duration  = datediff (millisecond,@startRun,@endRun) 
	  
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
		
		IF @LogSPData2 <> ''
		BEGIN TRY  
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP  
				@UserID = @UserID,  
				@CustID = @CustID,  
				@ActionID = 801,  
				@TrackingValue = @LogSPData2,  
				@duration = @duration  
		END TRY  
		BEGIN CATCH  
			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP  
				@UserID = @UserID,  
				@CustID = @CustID,  
				@ActionID = 801,  
				@TrackingValue = @LogSPData2,  
				@duration = @duration  
		END CATCH  

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
		
		IF @LogSPData2 <> ''
		BEGIN TRY  
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP  
				@UserID = @UserID,  
				@CustID = @CustID,  
				@ActionID = 2800,  
				@TrackingValue = @LogSPData2,  
				@duration = @duration  
		END TRY  
		BEGIN CATCH  
			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP  
				@UserID = @UserID,  
				@CustID = @CustID,  
				@ActionID = 2800,  
				@TrackingValue = @LogSPData2,  
				@duration = @duration  
		END CATCH    
	END

	IF @LogSPDataEnable <> ''
	BEGIN
		EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
				@UserId				= @UserId,
				@CustId				= @CustId,
				@ActionId			= 832,
				@TrackingValue		= @LogSPDataEnable,
				@Duration			= @Duration	
	END

	IF @LogSPData_AccBalance <> ''				
	BEGIN														
		EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper				
				@UserId				= @UserId,					
				@CustId				= @CustId,					
				@ActionId			= 839,
				@TrackingValue		= @LogSPData_AccBalance,			
				@Duration			= @Duration					
	END		

	IF @LogSPDataUnlockSC <> ''
	BEGIN
		EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
				@UserId				= @UserId,
				@CustId				= @CustId,
				@ActionId			= 840,
				@TrackingValue		= @LogSPDataUnlockSC,
				@Duration			= @Duration	
	END

	IF @LogSPDataUnlockBB <> ''
	BEGIN
		EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
				@UserId				= @UserId,
				@CustId				= @CustId,
				@ActionId			= 841,
				@TrackingValue		= @LogSPDataUnlockBB,
				@Duration			= @Duration	
	END

	IF @LogSPDataUnlockOS <> ''
	BEGIN
		EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
				@UserId				= @UserId,
				@CustId				= @CustId,
				@ActionId			= 842,
				@TrackingValue		= @LogSPDataUnlockOS,
				@Duration			= @Duration	
	END

END


GO
