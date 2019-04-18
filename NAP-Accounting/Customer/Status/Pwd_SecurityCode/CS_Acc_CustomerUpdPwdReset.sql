/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,bodbExtAccNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[CS_Acc_CustomerUpdPwdReset]
	@CustID int,
	@UserPwd nvarchar(50),
	@UserID int,
	@isABS	BIT = 0,
	@Language varchar(2) = 'E',
	@LoginIP VARCHAR(15) ='',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS

/*	Creator: 20190326@Johnson	
	Task: Update user's password for cn88
	DB: DBCUST/CustDB
	Original: Acc_CustomerUpdPwdReset 
	
	Revisions:
		- 20190326@Johnson: clone new sp for cn88 [redmine: #105660]		
*/
BEGIN
	SET NOCOUNT ON

	declare @startRun datetime
	declare @endRun datetime
	declare @duration int
	declare @funcname NVARCHAR(50)
	set @startRun = getdate()

	IF @UserID <> @CustID
	BEGIN
		--Check permission for account site: @phuc20080213
		IF @isABS = 1 
			SELECT @funcname = '[ABSAdminUserControl]'
		ELSE 
			SELECT @funcname = '[Password]'
			
		EXEC NAP_UserControl.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname=@funcname,@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
		If @ErrCode <> 0
			RETURN
	END

	--Check disable user
	EXEC dbo.Acc_CustomerSelCheckEnable @custid = @custid, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
	if @ErrCode <>0 return
	--end

	declare @PwdExpiry datetime,
			@OldUserPwd VARCHAR(40),
			@OldPwdExpiry DATETIME,
			@roleid  	TINYINT,
			@LogSPData 	NVARCHAR(MAX)
	
	SELECT	@OldUserPwd = userpwd, @OldPwdExpiry = pwdexpiry, @roleid = roleid
	FROM	customer WITH (NOLOCK)
	WHERE	custid = @CustID 
	
	SELECT @pwdexpiry = dbo.f_CS_GetPwdExpiryDate(@roleid)
			
	UPDATE customer  with (ROWLOCK, UPDLOCK)
				SET userpwd=@UserPwd, pwdexpiry=@PwdExpiry 
				where custid=@CustID	
	BEGIN TRY 			
			IF(@RoleID >4)
				EXEC DBPRO.bodb02.dbo.DOT_Admin_ChangeAdminUserPassword @CustID, @UserPwd
	END TRY
	BEGIN CATCH
		UPDATE customer  with (ROWLOCK, UPDLOCK)
				SET userpwd=@OldUserPwd, pwdexpiry = @OldPwdExpiry
				where custid=@CustID
 		select @ErrMsg = 'Update password does not successfully.'
 		RETURN
	END CATCH

	IF @RoleID BETWEEN 2 AND 4
	BEGIN
			
		UPDATE	CustLoginInfo WITH (UPDLOCK,ROWLOCK)
		SET		OldUserPwd			=	@OldUserPwd
				,LastChangedPwdDate	=	GETDATE()
		WHERE	CustID = @CustID

	END

	IF(@RoleID <5)
		Begin
			SELECT @LogSPData = '<CS_Acc_CustomerUpdPwdReset CustID="' + convert(varchar(20), @CustID) +'" IP="' + @LoginIP +'" />'

			set @endRun = getdate()
			set @duration  = datediff (millisecond,@startRun,@endRun)

			/*900 Acc_CustomerUpdPwdReset Reset downline's password */
			BEGIN TRY
				EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
					@UserID = @UserID,
					@CustID = @CustID,
					@ActionID = 937,
					@TrackingValue = @LogSPData,
					@duration = @duration
			END TRY
			BEGIN CATCH
				SELECT @LogSPData = '<CS_Acc_CustomerUpdPwdReset CustID="' + convert(varchar(20), @CustID) 
									+ '" IP="' + @LoginIP
									+ '" ErrMsg="' + ISNULL(CONVERT(VARCHAR(400),ERROR_MESSAGE()),space(1)) +'" />'
				EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
					@UserID = @UserID,
					@CustID = @CustID,
					@ActionID = 937,
					@TrackingValue = @LogSPData,
					@duration = @duration
			END CATCH
		end
	Else
		Begin
			SELECT @LogSPData = '<CS_Acc_CustomerUpdPwdReset><IP>' + @LoginIP + '</IP></CS_Acc_CustomerUpdPwdReset>'

			set @endRun = getdate()
			set @duration  = datediff (millisecond,@startRun,@endRun)
			BEGIN TRY
				EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_UserControl
					@custID = @CustID,
					@Doing = @LogSPData,
					@userid = @UserID,
					@TypeID =1,
					@actionid =1710,
					@duration = @duration  
			END TRY
			BEGIN CATCH
				SELECT @LogSPData = '<CS_Acc_CustomerUpdPwdReset ErrMsg="' + ISNULL(CONVERT(VARCHAR(400),ERROR_MESSAGE()),space(1))			
							+ '"><IP>' + @LoginIP + '</IP></CS_Acc_CustomerUpdPwdReset>'
				EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_UserControl
					@custID = @CustID,
					@Doing = @LogSPData,
					@userid = @UserID,
					@TypeID =1,
					@actionid =1710,
					@duration = @duration  
			END CATCH
	End
END
GO