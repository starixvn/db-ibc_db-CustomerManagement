/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_alp,wsv_xnap" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CustomerUpdPwd_Multiple]
    @CustIDList VARCHAR(MAX) ,
    @UserPwd NVARCHAR(50) ,
    @UserID INT ,
    @Language VARCHAR(2) = 'E' ,
    @SubAccID INT = 0 , --Sub-AccountID
    @LoginIP VARCHAR(20) = '' ,
	@ErrMsg		NVARCHAR(MAX) = '' OUTPUT
AS 
/*
	Created: Tacy@20240308
	Task : Reset password
	DB: DBCust/Custdb
	Original: Age_CustomerUpdPwd

	Revisions: 
		- 20240308@Tacy: Create SP [Redmine: #201432] 
		- 20241206@Johnson: Apply In-house replication for Credit Setting [RedmineID: #212684]
	Param's Explanation:
		• @ErrMsg: Error description.
			@ErrMsg = <Root>
							<Error CustID="20650722" ErrCode="105" ErrMsg="Your password does not meet the minimum security requirement."/>
						</Root>
*/
BEGIN
    SET NOCOUNT ON
    
	declare @startRun datetime
			,@endRun datetime
			,@duration int

	DECLARE @TempErrMsg NVARCHAR(1000)
	DECLARE @TempErrCode INT
	
	SET @ErrMsg = '<ROOT>';
	set @startRun = getdate()

	DECLARE @tblCust TABLE (
		 CustID		INT PRIMARY KEY
		,IsFinished BIT DEFAULT(0)
	)

	--Parse CustID
	INSERT INTO @tblCust (CustID)
	SELECT CONVERT(INT, value)
	FROM string_split(@CustIDList, ',')
	WHERE value <> ''

    DECLARE  @ErrLog	NVARCHAR(50)
			,@CustID	INT
			,@PwdExpiry DATETIME
			,@OldPwd	VARCHAR(40)
			,@roleid	TINYINT

    WHILE EXISTS (SELECT TOP 1 1 FROM @tblCust WHERE IsFinished=0)
	BEGIN
		GetCustId:
			UPDATE TOP (1) T
			SET	t.IsFinished=1
				,@CustID = CustID
			FROM @tblCust t
			WHERE IsFinished=0
		
		SELECT @TempErrCode = NULL, @TempErrMsg = NULL

		--Check disable user
		EXEC dbo.Acc_CustomerSelCheckEnable @custid = @custid,
			@ErrCode = @TempErrCode OUTPUT, @ErrMsg = @TempErrMsg OUTPUT

		IF @TempErrCode <> 0 
		BEGIN
							
			GOTO SetErr
		END

		IF EXISTS (SELECT 1 FROM custSub WITH(NOLOCK) WHERE custid = @custid AND subaccID = @SubAccID)
		BEGIN
			SELECT  @TempErrMsg ='You dont have permission to do this action.',
					@TempErrCode = 101

			GOTO SetErr
		END
		
		IF @UserID <> @CustID AND CURRENT_USER <> 'wsv_nap' AND EXISTS (SELECT 1 FROM custInfo WITH (NOLOCK) WHERE custid = @CustID AND LockUpd = 1 AND roleid = 1)
		BEGIN
			SELECT  @TempErrMsg = CASE @Language
								WHEN 'E' THEN 'You are currently not authorized to perform this action. Please contact the Customer Service Department for further assistance.'
								ELSE [dbo].[f_Get_MsgNamebyMsgID](40033,@Language)
								END ,
					@TempErrCode = 102
			GOTO SetErr
		END

		IF EXISTS (SELECT 1 FROM CustLoginInfo WITH (NOLOCK) WHERE custid = @CustID AND ISNULL(ProtectionCode,'') = @UserPwd)
		BEGIN
			SELECT  @TempErrMsg = CASE @Language
								WHEN 'E' THEN 'Your password does not meet the minimum security requirement.'
								ELSE [dbo].[f_Get_MsgNamebyMsgID](40061,@Language)
								END ,
					@TempErrCode = 105
				
			GOTO SetErr
		END	

		SELECT	@OldPwd	= userpwd, @roleid = roleid
		FROM	Customer WITH (NOLOCK) 
		WHERE	custid = @CustID

		--force change pwd if upline reset pwd
		IF @custid <> @userid
		BEGIN
			SELECT  @pwdexpiry = CASE WHEN @roleid = 1 THEN DATEADD(dd, -1, GETDATE()) ELSE '01/01/1900' END
		END
		ELSE 
			SELECT  @pwdexpiry = DATEADD(dd, 30, GETDATE())

		UPDATE  customer WITH (ROWLOCK, UPDLOCK)
		SET     userpwd = @UserPwd ,
				pwdexpiry = @PwdExpiry,
				RepUpdateTime = dbo.f_GetDateTime2()
		WHERE   custid = @CustID
    
		IF @roleid <> 1
		BEGIN
			UPDATE	CustLoginInfo WITH (ROWLOCK, UPDLOCK)
			SET		OldUserPwd			= @OldPwd
					,LastChangedPwdDate = GETDATE()				
			WHERE	custid = @CustID
		END
		ELSE
		BEGIN
			UPDATE	CustLoginInfo_Member WITH (ROWLOCK, UPDLOCK)
			SET	gesture = NULL
			WHERE	custid = @CustID
		END
	
		DECLARE @LogData NVARCHAR(4000)

		SELECT  @LogData = '<Age_CustomerUpdPwd_Multiple  UserID="' + CONVERT(VARCHAR(20), @CustID)
				+ '" IP="' + @LoginIP +'" '

		---------------------------
		-- ***Check Sub-Account***
		IF @SubAccID > 0 
			SET @LogData =  @LogData + 'SubAccount="' + dbo.f_GetSubUsername(@SubAccID) + '"'
		---------------------------

		SET @LogData = @LogData + ' />'
	
		set @endRun = getdate()
		set @duration  = datediff (millisecond,@startRun,@endRun)
		set @startRun = @endRun
	
		BEGIN TRY	
			/*954	Age_CustomerUpdPwd_Multiple	Reset Password*/
			EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
				@UserID = @UserID,
				@CustID = @CustID,
				@ActionID = 954,
				@TrackingValue = @LogData	,
				@duration = @duration
		END TRY
		BEGIN CATCH		
			SELECT  @LogData = '<Age_CustomerUpdPwd_Multiple  UserID="' + CONVERT(VARCHAR(20), @CustID)
				+ '" IP="' + @LoginIP +'" '
			---------------------------
			-- ***Check Sub-Account***
			IF @SubAccID > 0 
				SET @LogData =  @LogData + 'SubAccount="' + dbo.f_GetSubUsername(@SubAccID) + '" '
			---------------------------
			
			SET @LogData = @LogData + 'ErrCode="' + coalesce(cast(ERROR_NUMBER() as varchar(50)),space(1)) + '" ' 
									+ 'ErrMsg="' + coalesce(cast(ERROR_MESSAGE() as varchar(2000)),space(1)) + '" ' 	
							+ '/>'
	
			EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
				@UserID = @UserID,
				@CustID = @CustID,
				@ActionID = 954,
				@TrackingValue = @LogData	,
				@duration = @duration	
		END CATCH
	END
	
	IF @TempErrCode <> 0
	BEGIN
		SetErr:
		BEGIN
			SET @ErrMsg += '<Error CustID="' + CAST(@CustID AS VARCHAR(30))
						+ '" ErrCode="' + CAST(ISNULL(@TempErrCode,'0') AS VARCHAR(5))
						+ '" ErrMsg="' + ISNULL(@TempErrMsg,'') + '" />'
							
			GOTO GetCustId
		END
	END

	SET @ErrMsg += '</ROOT>'
END
GO