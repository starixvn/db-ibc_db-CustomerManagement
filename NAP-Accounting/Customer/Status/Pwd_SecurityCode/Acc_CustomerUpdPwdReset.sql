USE [CustDB]
GO
/****** Object:  StoredProcedure [dbo].[Acc_CustomerUpdPwdReset]    Script Date: 06/10/2015 14:28:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Acc_CustomerUpdPwdReset    Script Date: 12/5/2013 4:34:23 PM ******/

ALTER PROCEDURE [dbo].[Acc_CustomerUpdPwdReset]
	@CustID int,
	@UserPwd nvarchar(50),
	@UserID int,
	@isABS	BIT = 0,
	@Language varchar(2) = 'E',
	@LoginIP VARCHAR(15) ='',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS

/*	Creator:[Creator]
	Date: 2008
	Task: Update user's password 
	DB: DBTXN/bodb02
	
	History:
		- 20080213@PhucPham: Check permission for Account site
		- 20090311@PhuongDao: Write log for updating user's password and add a param - @LoginIP 
		- 20090321@PhuongDao: Not checking permission if the admin changes his own password. 
		- 20090828@HuyNguyen: replace [Customer] --> [Password]
		- 20090917@Phuc: Write log to dblog	
		- 20100101@Lewin: Remove string 'Reset password ' from param @LogSPData
		- 20101021@Henry: Record execution time
		- 20110907@Lukas: change linked-server from DB052 -> DB053
		- 20120228@Johnson: Check ABS permission
		- 20120604@Elodie: Modify the content of a log in User Control
		- 20130310@Lukas: change linked-server alias & add more write log section
		- 20130328@Jamie: Update old userpwd on CustLoginInfo
		- 20130704@Kathy: Synchronize user data between Accounting and AdminSite: update password in AdminSiteUser table		
		- 20150609@Kathy: Migrate custDB to new server DBCust (Move Acc_CustomerSelCheckEnable to DBCUST.CustDB) [Redmine:#36216]

*/

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
		
	EXEC DBPOLICY.bodb02.dbo.Acc_Con_CheckPermission @custid=@UserID,@funcname=@funcname,@ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
	If @ErrCode <> 0
		RETURN
END

--Check disable user
EXEC dbo.Acc_CustomerSelCheckEnable @custid = @custid, @ErrCode=@ErrCode output,@ErrMsg=@ErrMsg output
if @ErrCode <>0 return
--end

declare @PwdExpiry datetime,
		@OldUserPwd VARCHAR(40),
		@OldPwdExpiry DATETIME
select @pwdexpiry = dateadd(dd, 30, getdate())

SELECT	@OldUserPwd = userpwd, @OldPwdExpiry = pwdexpiry
FROM	customer WITH (NOLOCK)
WHERE	custid = @CustID 

 Declare @RoleID int, @LogSPData nvarchar(max)
 select @RoleID = roleid from Customer with (NOLOCK) where custid=@CustID
 
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
		SELECT @LogSPData = '<Acc_CustomerUpdPwdReset CustID="' + convert(varchar(20), @CustID) +'" IP="' + @LoginIP +'" />'

		set @endRun = getdate()
		set @duration  = datediff (millisecond,@startRun,@endRun)

		/*900 Acc_CustomerUpdPwdReset Reset downline's password */
		BEGIN TRY
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
				@UserID = @UserID,
				@CustID = @CustID,
				@ActionID = 900,
				@TrackingValue = @LogSPData,
				@duration = @duration
		END TRY
		BEGIN CATCH
			SELECT @LogSPData = '<Acc_CustomerUpdPwdReset CustID="' + convert(varchar(20), @CustID) 
								+ '" IP="' + @LoginIP
								+ '" ErrMsg="' + ISNULL(CONVERT(VARCHAR(400),ERROR_MESSAGE()),space(1)) +'" />'
			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
				@UserID = @UserID,
				@CustID = @CustID,
				@ActionID = 900,
				@TrackingValue = @LogSPData,
				@duration = @duration
		END CATCH
	end
Else
	Begin
		SELECT @LogSPData = '<Acc_CustomerUpdPwdReset><IP>' + @LoginIP + '</IP></Acc_CustomerUpdPwdReset>'

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
			SELECT @LogSPData = '<Acc_CustomerUpdPwdReset ErrMsg="' + ISNULL(CONVERT(VARCHAR(400),ERROR_MESSAGE()),space(1))			
						+ '"><IP>' + @LoginIP + '</IP></Acc_CustomerUpdPwdReset>'
			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_UserControl
				@custID = @CustID,
				@Doing = @LogSPData,
				@userid = @UserID,
				@TypeID =1,
				@actionid =1710,
				@duration = @duration  
		END CATCH
End

GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdPwdReset] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerUpdPwdReset] TO [bodbExtAccNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerUpdPwdReset] TO [vnteam] AS [dbo]