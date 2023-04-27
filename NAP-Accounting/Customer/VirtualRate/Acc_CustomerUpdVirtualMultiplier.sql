/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,bodbLicenseeNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE	[dbo].[Acc_CustomerUpdVirtualMultiplier]   
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

	Param's Explanation:  
	- @virtualmultiplier = '<ROOT>
								<Rate SportType="1" BetType="1" IsLive="0" VirtualMultiplier="1.5" />	
								<Rate SportType="1" BetType="1" IsLive="1" VirtualMultiplier="1.5" />	
								<Rate SportType="99" BetType="1" IsLive="0" VirtualMultiplier="1.5" />	
								<Rate SportType="99" BetType="1" IsLive="1" VirtualMultiplier="1.5" />	
							</ROOT>'	
	- @AdditionalActions = '<ROOT>
								<VR Unlock3="1"  Unlock2="0" Unlock1="1" Enable3="0"  Enable2="1" Enable1="0" />	
							</ROOT>'	
	- @ErrCode:  
	    = 0: update successfully.  
	    > 0: Specific Error.  
	    
	- @ErrMsg: Error description.  
*/  
BEGIN  
	SET NOCOUNT ON  
	  
	DECLARE @startRun datetime  
	DECLARE @endRun datetime  
	DECLARE @duration int 
	DECLARE	@Unlock3		BIT, --Unlock VR all Masters
			@Unlock2		BIT, --Unlock VR all Agents
			@Unlock1		BIT, --Unlock VR all Members
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
	  
	IF @AdditionalActions <> ''
	BEGIN
		-- For read xml					
		EXEC sp_xml_preparedocument @DocHandler OUTPUT, @AdditionalActions

		SELECT
			@Unlock3 =ISNULL(Data.Unlock3,0),
			@Unlock2 =ISNULL(Data.Unlock2,0),
			@Unlock1 =ISNULL(Data.Unlock1,0),
			@Enable3 =ISNULL(Data.Enable3,0),
			@Enable2 =ISNULL(Data.Enable2,0),
			@Enable1 =ISNULL(Data.Enable1,0)
		FROM OPENXML (@DocHandler, '/ROOT/VR',1) 
		WITH (
			Unlock3		BIT,
			Unlock2		BIT,
			Unlock1		BIT,
			Enable3		BIT,
			Enable2		BIT,
			Enable1		BIT
		) AS Data

		EXEC sp_xml_removedocument @DocHandler
		-- end read xml	
	END		   
	
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
	
	DECLARE   @Old_VRLockedStatus_Soccer BIT = 0
			, @IsUpdate_VRLockedStatus_Soccer BIT = 0
			, @Old_VRLockedStatus_OS BIT = 0
			, @IsUpdate_VRLockedStatus_OS BIT = 0
			, @Old_VRLockedStatus_Basketball BIT = 0			
			, @IsUpdate_VRLockedStatus_Basketball BIT = 0		

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

	IF @IsUpdate_VRLockedStatus_OS = 1 OR @IsUpdate_VRLockedStatus_Soccer = 1 OR @IsUpdate_VRLockedStatus_Basketball = 1	
	BEGIN
		--Update VR lock status
		EXEC Acc_VRCustLockStatusUpd 
			@custid = @custid
			,@UserID = @UserID
			,@VRLockedStatus_Soccer = @VRLockedStatus_Soccer
			,@VRLockedStatus_OS = @VRLockedStatus_OS
			,@VRLockedStatus_BasketBall = @VRLockedStatus_BasketBall		
			,@IP = @IP
			,@UpdateBy = 'Manual'
			,@ErrCode = @ErrCode OUTPUT
			,@ErrMsg = @ErrMsg OUTPUT

		IF @ErrCode <> 0
			RETURN
	END

	DECLARE @LogSPData3 varchar(MAX)= ''  
		,@IsUnlockDownLine BIT = 0
		,@IsEnableDownline BIT = 0

	IF (@roleid = 4 AND ( @Unlock1 = 1 OR @Unlock2 = 1 OR @Unlock3 = 1 OR @Enable1 = 1 OR @Enable2 = 1 OR @Enable3 = 1))
		OR (@roleid = 3 AND ( @Unlock1 = 1 OR @Unlock2 = 1 OR @Enable1 = 1 OR @Enable2 = 1))
		OR (@roleid = 2 AND ( @Unlock1 = 1 OR @Enable1 = 1))
	BEGIN --Update Enable VR/ Unlock VR status for all downlines

		IF (@roleid = 4 AND ( @Unlock1 = 1 OR @Unlock2 = 1 OR @Unlock3 = 1))
			OR (@roleid = 3 AND ( @Unlock1 = 1 OR @Unlock2 = 1))
			OR (@roleid = 2 AND ( @Unlock1 = 1 ))
		BEGIN
			SET @IsUnlockDownLine = 1
		END

		IF (@roleid = 4 AND ( @Enable1 = 1 OR @Enable2 = 1 OR @Enable3 = 1))
			OR (@roleid = 3 AND ( @Enable1 = 1 OR @Enable2 = 1))
			OR (@roleid = 2 AND (@Enable1 = 1))
		BEGIN
			SET @IsEnableDownline = 1
		END

		Select @LogSPData3 = '<Acc_CustomerUpdVirtualMultiplier CustID="' + cast(@custid as varchar(50))+ '" ' +  							
							CASE WHEN @Unlock3 = 1 THEN 'UnlockMaster="1" ' ELSE '' END + 
							CASE WHEN @Unlock2 = 1 THEN 'UnlockAgent="1" ' ELSE '' END + 
							CASE WHEN @Unlock1 = 1 THEN 'UnlockMember="1" ' ELSE '' END + 
							CASE WHEN @Enable3 = 1 THEN 'EnableMaster="1" ' ELSE '' END + 
							CASE WHEN @Enable2 = 1 THEN 'EnableAgent="1" ' ELSE '' END + 
							CASE WHEN @Enable1 = 1 THEN 'EnableMember="1" ' ELSE '' END + 
							'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" '+  
							'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(50)),space(1)) + '" '+  
							'IP="'+ coalesce(cast(@IP as varchar(15)),space(1))+'" />'  
	END

	IF @IsUnlockDownLine  = 1
	BEGIN
		EXECUTE	dbo.Acc_CustomerInfo_Execrep_04   
				@custid = @custid
			,	@roleid = @roleid
			,	@action = 'UnlockVRDownline'
			,   @AdditionalActions = @AdditionalActions
	END
		
	EXECUTE	dbo.Acc_CustomerInfo_Execrep_04   
				@custid = @custid
			,	@roleid = @roleid
			,	@action = 'VirtualMultiplier'
			,	@EnableVirtualrate = @EnableVirtualrate
			,	@virtualmultiplier = @virtualmultiplier

	IF @IsEnableDownline  = 1
	BEGIN
		EXECUTE	dbo.Acc_CustomerInfo_Execrep_04   
				@custid = @custid
			,	@roleid = @roleid
			,	@action = 'EnableVRDownline'
			,   @AdditionalActions = @AdditionalActions
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

	IF @LogSPData3 <> ''
	BEGIN
		EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
				@UserId				= @UserId,
				@CustId				= @CustId,
				@ActionId			= 832,
				@TrackingValue		= @LogSPData3,
				@Duration			= @Duration	
	END
END
GO