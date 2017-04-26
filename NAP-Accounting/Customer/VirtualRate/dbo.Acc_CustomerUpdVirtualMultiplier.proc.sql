SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE	dbo.Acc_CustomerUpdVirtualMultiplier   
					@custid				INT
				,	@EnableVirtualrate	BIT				= 0
				,	@virtualmultiplier	VARCHAR(MAX)	= ''
				,	@UserID				INT
				,	@IP					VARCHAR(15)		= ''
				,	@IsLicenseeUser		BIT				= 0
				,	@ErrCode			INT				= 0		OUTPUT
				,	@ErrMsg				NVARCHAR(4000)	= ''	OUTPUT  
AS  
/*  
	Created:	
	Task:		Update virtualmultiplier.  
	DB:			DBTXN/CustDB
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
	Param's Explanation:  
	• @virtualmultiplier = '<ROOT>
								<Rate SportType="1" BetType="1" IsLive="0" VirtualMultiplier="1.5" />	
								<Rate SportType="1" BetType="1" IsLive="1" VirtualMultiplier="1.5" />	
								<Rate SportType="99" BetType="1" IsLive="0" VirtualMultiplier="1.5" />	
								<Rate SportType="99" BetType="1" IsLive="1" VirtualMultiplier="1.5" />	
							</ROOT>'		
	• @ErrCode:  
	    = 0: update successfully.  
	    > 0: Specific Error.  
	    
	• @ErrMsg: Error description.  
*/  
BEGIN  
	SET NOCOUNT ON  
	  
	DECLARE @startRun datetime  
	DECLARE @endRun datetime  
	DECLARE @duration int 

	DECLARE @tblVirtualrate TABLE (
									SportType INT
									,BetType INT
									,IsLive	BIT
									,VirtualMultiplier SMALLMONEY	
								)
	DECLARE @DocHandler INT		
	
	DECLARE	@lockedVRmembers	VARCHAR(MAX)												
	 
	set @startRun = getdate()  
	  
	IF @IsLicenseeUser = 0 --accounting admin (licensee user will be ignored from this check)  
	BEGIN  
		--Check permission for account site: @phuc20080213  
		EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname='[VirtualRate]',@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output  
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
	  
	--END      
	
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
					OR virtualmultiplier < 0.1
				)  
	BEGIN  
		select @ErrMsg    = N'Invalid virtual rate.', @ErrCode = 101  
		return  
	END  
	/*  
	IF @currency <> 20 AND @UserID not IN (  
			1274,    --steven  
			2433,    --WAN  
			44919,    --WONG  
			55421,    --MELVIN  
			25520,    --joe  
			360418    --dbaThien  
	)  
	BEGIN  
		select @ErrMsg    = N'You are not authorized to edit this value.', @ErrCode = 102  
		return  
	END  
	*/  
	
	-- SELECT locked VR member
	
	SELECT	@lockedVRmembers =	(
		SELECT	DISTINCT ulvrs.CustID '@CustID'
		FROM	DBLOG.bodb_CustomerLog.dbo.UserLog_VirtualRateSettings AS ulvrs WITH (NOLOCK)
		FOR XML PATH ('LockedVR')
	,	ROOT ('ROOT')
	);
		
	EXECUTE	dbo.Acc_CustomerInfo_Execrep_04   
				@custid = @custid
			,	@roleid = @roleid
			,	@action = 'VirtualMultiplier'
			,	@EnableVirtualrate = @EnableVirtualrate
			,	@virtualmultiplier = @virtualmultiplier
			,	@lockedVRmembers = @lockedVRmembers
				
	 
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
	
	IF @EnableVirtualrate = 1
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
END


GO
GRANT EXECUTE ON dbo.Acc_CustomerUpdVirtualMultiplier TO bodbAdminNet AS dbo
GO
GRANT EXECUTE ON dbo.Acc_CustomerUpdVirtualMultiplier TO bodbLicenseeNet AS dbo
GO
GRANT VIEW DEFINITION ON dbo.Acc_CustomerUpdVirtualMultiplier TO vnteam AS dbo