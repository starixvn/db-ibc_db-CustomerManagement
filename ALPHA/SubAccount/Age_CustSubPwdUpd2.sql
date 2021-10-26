/*<info serverAlias="DBCUST-CustDB" executers="bodbDownlineNet,VNTeam" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CustSubPwdUpd2]
	@CustID int,
	@SubAccID int,	
	@UserPwd nvarchar(50),
	@OldPwd nvarchar(50),
	@LoginIP varchar(20)='',
	@Language varchar(2) = 'E',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(100) = '' output	
AS
/*
Created: 
Task : Sub-account change his own password
DB: DBTRANS.bodb02
Original: CustSubPwdUpd2

Revisions:
    - 20090311@HanhVu: Log information into UserLog_RunSP table					   
	- 20090402@Phuc: write log into dblog.
	- 20091209@Terry: Remove Rais Error
	- 20100107@Kiwi: Amend writing log format.
	- 20101021@Henry: Record execution time
	- 20121128@Elodie: Get an error message from f_Get_MsgNameByMsgID function by language
	- 20130328@Jamie: Update Old pwd and Last Changed Pwd 
	- 20210408@Tina: Lock account & indirect close account [redmine: #148600]
	- 20210824@Elodie: Implement Protection Code [Redmine: #160151]

*/
BEGIN
	SET NOCOUNT ON

	declare @startRun datetime
	declare @endRun datetime
	declare @duration int
	set @startRun = getdate()

	Declare @SubAccname varchar(30)
	DECLARE @PwdExpiry DATETIME
	DECLARE @failedcount INT, @LogSPData VARCHAR(MAX)

	SELECT @failedcount = ISNULL(C.logincount,0), @SubAccname = C.username
	FROM custSub C WITH (NOLOCK)
	WHERE subaccid = @SubAccID and custid = @CustID

	IF EXISTS (SELECT 1 FROM CustLoginInfoSub WITH (NOLOCK) WHERE custid = @CustID AND subaccid = @SubAccID AND ISNULL(ProtectionCode,'') = @UserPwd)
	BEGIN
		 SELECT  @ErrMsg = CASE @Language
                                WHEN 'E' THEN 'Your password does not meet the minimum security requirement.'
                                ELSE [dbo].[f_Get_MsgNamebyMsgID](40061,@Language)
                              END ,
                 @ErrCode = 105
         RETURN
	END	

	IF NOT EXISTS (SELECT 1 FROM custsub WITH (NOLOCK) WHERE subaccid = @SubAccID and userpwd = @OldPwd)
	BEGIN

		SELECT @failedcount = @failedcount + 1

		IF @failedcount > 5 --Lock accounts after 5 logins failed */
		BEGIN
			UPDATE custSub WITH (ROWLOCK,UPDLOCK) SET closed = 1, logincount = 0 WHERE subaccid = @SubAccID and custid = @CustID
		
			SET @endRun = getdate()
			SET @duration  = datediff (millisecond,@startRun,@endRun)
			SELECT @ErrMsg = case @Language when 'E' then 'Account closed. Please contact your administrator!'  
			ELSE [dbo].[f_Get_MsgNamebyMsgID](80002,@Language)
			END, @ErrCode = 104

			--log data to UserLog_RunSP 
			SELECT @LogSPData = '<Age_CustSubPwdUpd2 SubAccount="' + convert(varchar(30),@SubAccname)
						 + '" IP="' + @LoginIP + '"/>'
			
			BEGIN TRY 	
			EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_RunSP
				@UserID = @CustID,
				@CustID = @CustID,
				@ActionID = 949,
				@TrackingValue = @LogSPData,
				@Duration = @Duration
			END TRY 
			BEGIN CATCH
				SELECT @LogSPData = '<Age_CustSubPwdUpd2 SubAccount="' + convert(varchar(30),@SubAccname)
											+ '" IP="' + @LoginIP + '"'
											+ 'ErrMsg="' + ERROR_MESSAGE() +'" ' + 
									
									' />'
				EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_RunSP
					@UserID = @CustID,
					@CustID = @CustID,
					@ActionID = 949,
					@TrackingValue = @LogSPData,
					@Duration = @Duration		
			
			END CATCH 
		END
		ELSE IF @failedcount <=5
		BEGIN 			
			UPDATE custSub WITH(UPDLOCK,ROWLOCK)
			SET logincount = @failedcount
			WHERE subaccid = @SubAccID and custid = @custid

			SELECT @ErrMsg = CASE WHEN @Language = 'E' THEN 'Old password is incorrect.'
												ELSE [dbo].[f_Get_MsgNamebyMsgID](40021,@Language) END,
				@ErrCode = 101		
		END

		RETURN
	END

	-- Successful
	SELECT	@PwdExpiry = DATEADD(dd, 30, GETDATE())

	UPDATE custsub WITH (ROWLOCK, UPDLOCK)
	SET userpwd = @UserPwd,
		@SubAccname = username
	WHERE subaccid = @SubAccID and custid = @CustID

	UPDATE	CustLoginInfoSub WITH (UPDLOCK,ROWLOCK)
	SET		OldUserPwd			= @OldPwd
			,PwdExpiry			= @PwdExpiry
			,LastChangedPwdDate	= GETDATE()
			,isFirstLogin		= 0 
	WHERE	SubAccID = @SubAccID and CustID = @CustID

	--904	Age_CustSubPwdUpd2	Sub-account changed his own password

	SELECT @LogSPData = '<Age_CustSubPwdUpd2 SubAccount="' + convert(varchar(30),@SubAccname)
						 + '" IP="' + @LoginIP + '"/>'

	SET @endRun = getdate()
	SET @duration  = datediff (millisecond,@startRun,@endRun)

	EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
		@UserID = @CustID,
		@CustID = @CustID,
		@ActionID = 904,
		@TrackingValue = @LogSPData	,
		@duration = @duration

END
GO
