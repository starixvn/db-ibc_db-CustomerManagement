/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,bodbLicenseeNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE	dbo.Acc_VRCustLockStatusUpd   
					@custid							INT
				,	@UserID							INT
				,   @VRLockedStatus_Soccer			BIT = NULL
				,   @VRLockedStatus_OS				BIT = NULL
				,	@VRLockedStatus_Basketball		BIT = NULL
				,	@VRAccumulate_Balance			BIT = NULL
				,   @UpdateBy						VARCHAR(100)	= 'Manual'
				,	@IP								VARCHAR(15)		= ''
				,	@ErrCode						INT				= 0		OUTPUT
				,	@ErrMsg							NVARCHAR(4000)	= ''	OUTPUT  
AS  
/*  
	Created:	20210224@Eden
	Task:		Update VRLockedStatus  
	DB:			DBCUST/CustDB
	Original:	
  
	Revisions:  
	    - 20210224@Eden: Implement Lock for VR update [Redmine:#149370]
		- 20230427@Luke: Separate lock function for Basketball [Redmine: #185991]
		- 20230711@Helios: VR Accumulate Balance [Redmine: #189649]
		- 20231129@Luke: NAP - Virtual rate - Enhance VR [Redmine: #194939]

	Param's Explanation:  	
	-@ErrCode:  
	    = 0: update successfully.  
	    > 0: Specific Error.  
	    
	-@ErrMsg: Error description.  

	- @UpdateBy :
		3m perf check 
		China/Desktop check  
		Agent profile check
		Manual

	DECLARE @ErrCode INT, @ErrMsg NVARCHAR(4000)
	EXEC Acc_VRCustLockStatusUpd 
		 @custid = 1176092
		,@UserID = 8
		,@VRLockedStatus_Soccer = 1
		,@VRLockedStatus_OS = 0
		,@VRLockedStatus_Basketball = 0
		,@IP = '1.1.1.1'
		,@UpdateBy = 'Manual'
		,@ErrCode = @ErrCode OUT
		,@ErrMsg = @ErrMsg OUT
		SELECT @ErrCode,@ErrMsg
*/  
BEGIN  
	SET NOCOUNT ON  
	  
	DECLARE @startRun datetime  
	DECLARE @endRun datetime  
	DECLARE @duration int 
	DECLARE @ActionID INT
	DECLARE @RoleID TINYINT
	DECLARE @LogSPData_SC VARCHAR(1000)
	DECLARE @LogSPData_OS VARCHAR(1000)
	DECLARE @LogSPData_BB VARCHAR(1000)
	DECLARE @LogSPData_AB VARCHAR(1000)
	DECLARE @Old_VRLockedStatus_Soccer BIT = 0
	DECLARE @Old_VRLockedStatus_OS BIT = 0
	DECLARE @Old_VRLockedStatus_Basketball BIT = 0
	DECLARE @Old_VRAcc_Balance		 BIT = 0
	DECLARE @IsUpdateVRLockedStatus_Soccer BIT = 0
	DECLARE @IsUpdateVRLockedStatus_OS BIT = 0
	DECLARE @IsUpdateVRLockedStatus_Basketball BIT = 0
	DECLARE @IsUpdateVRAcc_Balance BIT = 0
	DECLARE @IsCallExecrep_Soccer BIT = 0
	DECLARE @IsCallExecrep_OS BIT = 0
	DECLARE @IsCallExecrep_Basketball BIT = 0	

	set @startRun = getdate() 
	SELECT @ErrCode = 0, @ErrMsg = ''

	IF EXISTS ( SELECT 1 FROM VRCustLockStatus WITH(NOLOCK) WHERE custid = @custid AND Type = 1)
		SET @Old_VRLockedStatus_Soccer = 1

	IF EXISTS ( SELECT 1 FROM VRCustLockStatus WITH(NOLOCK) WHERE custid = @custid AND Type = 2)
		SET @Old_VRLockedStatus_OS = 1

	IF EXISTS ( SELECT 1 FROM VRCustLockStatus WITH(NOLOCK) WHERE custid = @custid AND Type = 3)			
		SET @Old_VRLockedStatus_Basketball = 1	
		
	IF EXISTS ( SELECT 1 FROM VRCustLockStatus WITH(NOLOCK) WHERE custid = @custid AND Type = 4)			
		SET @Old_VRAcc_Balance = 1	

	SELECT  @IsUpdateVRLockedStatus_Soccer = CASE WHEN @VRLockedStatus_Soccer = @Old_VRLockedStatus_Soccer OR @VRLockedStatus_Soccer IS NULL THEN 0 ELSE 1 END,
			@IsUpdateVRLockedStatus_OS = CASE WHEN @VRLockedStatus_OS = @Old_VRLockedStatus_OS OR @VRLockedStatus_OS IS NULL THEN 0 ELSE 1 END,
			@IsUpdateVRLockedStatus_Basketball = CASE WHEN @VRLockedStatus_Basketball = @Old_VRLockedStatus_Basketball OR @VRLockedStatus_Basketball IS NULL THEN 0 ELSE 1 END,
			@IsUpdateVRAcc_Balance = CASE WHEN @VRAccumulate_Balance = @Old_VRAcc_Balance OR @VRAccumulate_Balance IS NULL THEN 0 ELSE 1 END	

	SELECT @RoleID = roleid FROM custInfo WITH(NOLOCK) WHERE custid = @custid

	IF @IsUpdateVRLockedStatus_Soccer = 1
	BEGIN
		IF @VRLockedStatus_Soccer = 0
		BEGIN
			DELETE FROM VRCustLockStatus WITH(ROWLOCK) WHERE custid = @custid AND Type = 1 
		END
		ELSE IF @RoleID = 1 -- insert directly for Member
		BEGIN
			INSERT INTO VRCustLockStatus(CustID,Type)
			SELECT @custid,1
			WHERE NOT EXISTS (SELECT 1 FROM VRCustLockStatus WITH(NOLOCK) WHERE custid = @custid AND Type = 1 )
		END
		ELSE --use execrep SP for SMA
		BEGIN 
			SET @IsCallExecrep_Soccer = 1
		END

		SELECT @LogSPData_SC = '<R VRLock="'+ coalesce(cast(@VRLockedStatus_Soccer as varchar(1)),space(1)) + '" '
						+ 'IP="' + coalesce(cast(@IP as varchar(15)),space(1)) + '" '
						+ 'UpdatedBy="'+ coalesce(cast(@UpdateBy as varchar(100)),space(1)) + + '" ' 
						+ ' />'	

	END

	IF @IsUpdateVRLockedStatus_OS = 1
	BEGIN
		IF @VRLockedStatus_OS = 0
		BEGIN
			DELETE FROM VRCustLockStatus WITH(ROWLOCK) WHERE custid = @custid AND Type = 2 
		END
		ELSE IF @RoleID = 1 -- insert directly for Member
		BEGIN
			INSERT INTO VRCustLockStatus(CustID,Type)
			SELECT @custid,2
			WHERE NOT EXISTS (SELECT 1 FROM VRCustLockStatus WITH(NOLOCK) WHERE custid = @custid AND Type = 2 )
		END
		ELSE --use execrep SP for SMA
		BEGIN 
			SET @IsCallExecrep_OS = 1
		END

		SELECT @LogSPData_OS = '<R VRLock="'+ coalesce(cast(@VRLockedStatus_OS as varchar(1)),space(1)) + '" '
						+ 'IP="' + coalesce(cast(@IP as varchar(15)),space(1)) + '" '
						+ 'UpdatedBy="'+ coalesce(cast(@UpdateBy as varchar(100)),space(1)) + + '" ' 
						+ ' />'	

	END

	IF @IsUpdateVRLockedStatus_Basketball = 1																			
	BEGIN																												
		IF @VRLockedStatus_Basketball = 0																				
		BEGIN																											
			DELETE FROM VRCustLockStatus WITH(ROWLOCK) WHERE custid = @custid AND Type = 3 						
		END																											
		ELSE IF @RoleID = 1 -- insert directly for Member															
		BEGIN																											
			INSERT INTO VRCustLockStatus(CustID,Type)																	
			SELECT @custid,3																							
			WHERE NOT EXISTS (SELECT 1 FROM VRCustLockStatus WITH(NOLOCK) WHERE custid = @custid AND Type = 3 )			
		END																												
		ELSE --use execrep SP for SMA																					
		BEGIN 																											
			SET @IsCallExecrep_Basketball = 1																			
		END																												

		SELECT @LogSPData_BB = '<R VRLock="'+ coalesce(cast(@VRLockedStatus_Basketball as varchar(1)),space(1)) + '" '	
						+ 'IP="' + coalesce(cast(@IP as varchar(15)),space(1)) + '" '									
						+ 'UpdatedBy="'+ coalesce(cast(@UpdateBy as varchar(100)),space(1)) + + '" ' 					
						+ ' />'																							

	END	

	IF @IsUpdateVRAcc_Balance = 1																			
	BEGIN																												
		IF @VRAccumulate_Balance = 0																				
		BEGIN																											
			DELETE FROM VRCustLockStatus WITH(ROWLOCK) WHERE custid = @custid AND Type = 4						
		END																											
		ELSE														
		BEGIN																											
			INSERT INTO VRCustLockStatus(CustID,Type)																	
			SELECT @custid,4																							
		END																																																					

		SELECT @LogSPData_AB = '<R VRAccumulatedBalance="'+ coalesce(cast(@VRAccumulate_Balance as varchar(1)),space(1)) + '" '	
						+ 'IP="' + coalesce(cast(@IP as varchar(15)),space(1)) + '" '
						+ 'UpdatedBy="'+ coalesce(cast(@UpdateBy as varchar(100)),space(1)) + + '" ' 					
						+ ' />'																							
	END	
	
	--Call SP execrep 
	IF @IsCallExecrep_Soccer = 1 AND @IsCallExecrep_OS = 1 AND @IsCallExecrep_Basketball = 1
	BEGIN
		EXEC [Acc_CustomerInfo_Execrep_04]
						@custid = @custid
					,	@roleid = @roleid
					,	@action = 'EnableVRLockStatus'
					,   @VRlockStatusType = 0 --ALL
	END
	ELSE
	BEGIN
		IF @IsCallExecrep_Soccer = 1
		BEGIN
			EXEC [Acc_CustomerInfo_Execrep_04]
							@custid = @custid
						,	@roleid = @roleid
						,	@action = 'EnableVRLockStatus'
						,   @VRlockStatusType = 1 --Soccer
		END
		IF @IsCallExecrep_OS = 1
		BEGIN
			EXEC [Acc_CustomerInfo_Execrep_04]
							@custid = @custid
						,	@roleid = @roleid
						,	@action = 'EnableVRLockStatus'
						,   @VRlockStatusType = 2 --Other sport
		END
		IF @IsCallExecrep_Basketball = 1
		BEGIN
			EXEC [Acc_CustomerInfo_Execrep_04]
							@custid = @custid
						,	@roleid = @roleid
						,	@action = 'EnableVRLockStatus'
						,   @VRlockStatusType = 3 --Basketball
		END
	END
		  
	set @endRun = getdate()  
	set @duration  = datediff (millisecond,@startRun,@endRun) 		
	  
	IF @IsUpdateVRLockedStatus_Soccer = 1
	BEGIN
		EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
				@UserId				= @UserId,
				@CustId				= @CustId,
				@ActionId			= 829,
				@TrackingValue		= @LogSPData_SC,
				@Duration			= @Duration
	END

	IF @IsUpdateVRLockedStatus_OS = 1
	BEGIN
		EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
				@UserId				= @UserId,
				@CustId				= @CustId,
				@ActionId			= 830,
				@TrackingValue		= @LogSPData_OS,
				@Duration			= @Duration
	END

		IF @IsUpdateVRLockedStatus_Basketball = 1					
	BEGIN														
		EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper				
				@UserId				= @UserId,					
				@CustId				= @CustId,					
				@ActionId			= 837,						
				@TrackingValue		= @LogSPData_BB,			
				@Duration			= @Duration					
	END		

	IF @IsUpdateVRAcc_Balance = 1			
	BEGIN														
		EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper				
				@UserId				= @UserId,					
				@CustId				= @CustId,					
				@ActionId			= 839,
				@TrackingValue		= @LogSPData_AB,			
				@Duration			= @Duration					
	END		
END


GO
