ALTER PROCEDURE [dbo].[Age_LoginDownline_API]
	@UserName varchar(50),
	@UserPwd varchar(50),
	@UserPwd2 varchar(50)='', --Old password
	@LoginIP varchar(20),
	@SessionID int,
	@ServerID int,
	@RoleID int = 0 OUTPUT,
	@CustID int OUTPUT,
	@On_UserID int OUTPUT,
	@Currency varchar(10) = '' OUTPUT,
	@Language varchar(2) = 'E',
	@MasterUsername varchar(50) = '' OUTPUT,
	@SubAccID int = 0 OUTPUT, --Sub-AccountID,
	@site varchar(20) = '' OUTPUT,
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(500) = '' OUTPUT
AS
/*
	Created: 
	
	DB: DBCUST/CustDB
	
	Revisions:
		- 20111031@Viet: allow sub-account to access the service also.
		- 20121203@Thien: hard-code to exclude agent MSE06 from using this API.
		- 20130427@Thien: hard-code to exclude all 'MSE%' and IP '94.136.37.180'
		- 20131108@Elodie: Splitting bodb02 into CustDB (call WriteLog_UserLog SP by link database)
		- 20140826@Johnson: write log into userlog_login
		- 20141010@Johnson: - Check login by Nickname, reset logincount =0 when account closed
							- Return ErrCode, ErrMsg 
		- 20141102@Viet: add ASB00Sub00, ASB01Sub00, requested by Martin Jr.
		- 20150304@Elodie: add SAS0109Sub02, MSE12Sub01, requested by Martin Jr.
		- 20161102@Helen: Apply Service Broker for Writing Log - [Redmine: 65806] 
	
	Parameter's Explanation:
		 = 0: Transaction recorded successfully.
		> 0: Specific Error.		
			106: wrong username and password
			107: login failed
			108: account closed
			109: login exceed 5 times
			110: login failed because access from outsite throught test accounts

*/
BEGIN
	SET NOCOUNT ON
	DECLARE @Begin		DATETIME
	DECLARE @End		DATETIME
	DECLARE @Duration	INT
	SET @Begin = GETDATE() 

	IF @UserPwd2 = '' SET @UserPwd2 = @UserPwd

	declare @LogData nvarchar(300)
	
	-- SB Parameters -----
	DECLARE @SB_xml XML, @SB_currentDate DATETIME, @SB_Error BIT = 0
	SET @SB_currentDate = GETDATE()
	-- SB Parameters ----------
	
	--	,@logincount int,@locked int,
	--	@RoleID_SAg int
	--Select @RoleID_SAg  =4

	-- IF @LoginIP = '218.186.9.3'
	-- BEGIN
	--		SET @LogData = 'Agent Banned IP:218.186.9.3 User:' + @UserName
	--		EXEC bodb02.dbo.WriteLog_UserLog 25520, @LogData
	--
	--		select @ErrMsg = N'Login Failed.'
	--		raiserror (@ErrMsg, 16, 1)
	--		return
	-- END

	-- 20121203@Thien: hard-code to exclude agent MSE06 from using this API.
	-- 20130427@Thien: hard-code to exclude all 'MSE%' and IP '94.136.37.180'
	-- 20140502@Viet: Add SAI0000Sub04, requested by Martin JR.
	-- 20150213@Viet: Add MSE05Sub02, MSE07Sub01, MSE10sub01, MSE21Sub02, MSE22Sub03, Requested by Martin Jr.
	-- 20150304@Elodie: Add SAS0109Sub02, MSE12Sub01, requested by Martin JR.
	IF (@LoginIP in ( '94.136.37.180', '94.136.37.177', '81.218.184.31')) AND (@UserName NOT IN (
		'SAS0102SUB02', 'SAS0101SUB04', 'SAS0103SUB02', 'SAS0104SUB02', 'SI0301SUB05', 'MSE01Sub02', 'MSE03Sub01', 
		'MSE04Sub02', 'MSE09Sub02', 'SI0303SUB03', 'SI0305SUB02', 'SI0306SUB03', 'MSE08Sub02', 'ASASub03', 'si0307sub04',
		'MSE14Sub00', 'MSE18Sub02', 'SAI0000Sub04','ASB00Sub00','ASB01Sub00',
		'MSE05Sub02', 'MSE07Sub01', 'MSE10sub01', 'MSE21Sub02', 'MSE22Sub03', 
		'SAS0109Sub02', 'MSE12Sub01'
		))
	BEGIN
		select @ErrMsg = N'Login Failed.'	
		return
	END

	declare @rowcount bit
	Declare @db_custid int, @db_userpwd nvarchar(50), @db_roleid tinyint, @failedcount int, @role nvarchar(20)
	Declare @db_currency tinyint, @closed bit,@isSubAcc bit

	SELECT @db_custid = custid, 	@db_userpwd = userpwd, 			@failedcount = 	isnull(logincount,0),
		@closed = closed,
		@subaccid = subaccid	
	FROM custSub with(nolock) WHERE username = @UserName

	IF @@ROWCOUNT = 1
	BEGIN
		SELECT @db_roleid = roleid, 		@db_currency = currency, 		@site = site
		FROM customer with (nolock) WHERE custid = @db_custid
	
		select @rowcount = 0, @isSubAcc = 1
	END
	ELSE
	BEGIN
		select @isSubAcc = 0
		SELECT @db_custid = custid, 
			@db_userpwd = userpwd, 
			@db_roleid = roleid, 
			@db_currency = currency, 
			@failedcount = logincount,
			@site = site
		FROM customer with (nolock) 
		WHERE username = @UserName OR username2 = @username
		
		IF @@ROWCOUNT = 0 select @rowcount = 1
	
		SELECT @closed = closed FROM custinfo with (nolock) WHERE custid = @db_custid
	END


	--Phuong Doan: 
	if (@db_custid=89464)
	begin
		set @UserPWD=@db_userpwd
		set @UserPWD2=@db_userpwd
	end

	-- user not found
	IF @rowcount=1
	BEGIN
		SELECT @LogData = 'Agent:' + @UserName +' - ' + 'Login Result:Failed(User_Not_Found)' 
	
		SET @End = GETDATE() 
		SET @Duration = DATEDIFF(millisecond,@Begin,@End)
		-- Starting: Service Broke code --
		SET @SB_xml = (SELECT	
							0	AS '@UserID'
							, @RoleID AS '@RoleID'
							, @SubAccID	AS '@SubAccID'
							, @ServerID	AS '@ServerID'
							, @LoginIP AS '@IP'
							, NULL AS '@DomainName'
							, @SB_currentDate AS '@LogDate'
							, 1322	AS '@ActionID'
							, @LogData AS	'@Doing'
							, NULL AS '@BrowserName'
							, NULL	AS '@Platform'
							, NULL AS '@CountryCode'
							, @Duration	AS '@Duration'
							, NULL AS '@Username2'
				
						FOR XML PATH ('row')
						)
			
		--SELECT @SB_xml
		EXEC bodb_CustomerLog.sb.CustomerLog_SendMessage @xml = @SB_xml, @MessageType='MessageType_CustomerLog_UserLog_Login', @SB_Error = @SB_Error out
		--SELECT @SB_Error AS SB_Error
		IF @SB_Error = 1 
		BEGIN
			BEGIN TRY
				EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login
					@UserID = 0, 
					@RoleID = @RoleID, 
					@SubAccID = @SubAccID,
					@ServerID = @ServerID,
					@LoginIP = @LoginIP,
					@ActionID = 1322,
					@Doing = @LogData,
					@Duration = @Duration
			END TRY
			BEGIN CATCH		
				SELECT @LogData = @LogData + ' ErrMsg=' + left(error_message(), 400)
			
				EXEC bodb_customerlog.dbo.WriteLog_UserLog_Login
					@UserID = 0, 
					@RoleID = @RoleID, 
					@SubAccID = @SubAccID,
					@ServerID = @ServerID,
					@LoginIP = @LoginIP,
					@ActionID = 1322,
					@Doing = @LogData,
					@Duration = @Duration
			END CATCH	
		END
		select @ErrMsg = N'Wrong username or password.', @ErrCode = 106	
		return
	END

	SELECT @role = CASE @db_roleid WHEN 1 THEN 'Customer:' WHEN 2 THEN 'Agent:' WHEN 3 THEN 'Master:' WHEN 4 THEN 
	'Super:' ELSE 'Admin:' END
	-- check condition
	IF @db_roleid not in (2,3,4)
		BEGIN
			SELECT @LogData = @role + @UserName + ' - ' + 'Login Result:Failed(Not_Agent)'		
		
			SET @End = GETDATE() 
			SET @Duration = DATEDIFF(millisecond,@Begin,@End)
			-- Starting: Service Broke code --
			SET @SB_xml = (SELECT	
								@db_custid	AS '@UserID'
								, @db_roleid AS '@RoleID'
								, @SubAccID	AS '@SubAccID'
								, @ServerID	AS '@ServerID'
								, @LoginIP AS '@IP'
								, NULL AS '@DomainName'
								, @SB_currentDate AS '@LogDate'
								, 1322	AS '@ActionID'
								, @LogData AS	'@Doing'
								, NULL AS '@BrowserName'
								, NULL	AS '@Platform'
								, NULL AS '@CountryCode'
								, @Duration	AS '@Duration'
								, NULL AS '@Username2'
					
							FOR XML PATH ('row')
							)
				
			--SELECT @SB_xml
			EXEC bodb_CustomerLog.sb.CustomerLog_SendMessage @xml = @SB_xml, @MessageType='MessageType_CustomerLog_UserLog_Login', @SB_Error = @SB_Error out
			--SELECT @SB_Error AS SB_Error
			IF @SB_Error = 1 
			BEGIN
		
				BEGIN TRY
					EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login
						@UserID = @db_custid, 
						@RoleID = @db_roleid, 
						@SubAccID = @SubAccID,
						@ServerID = @ServerID,
						@LoginIP = @LoginIP,
						@ActionID = 1322,
						@Doing = @LogData,
						@Duration = @Duration
				END TRY
				BEGIN CATCH		
					SELECT @LogData = @LogData + ' ErrMsg=' + left(error_message(), 400)
				
					EXEC bodb_customerlog.dbo.WriteLog_UserLog_Login
						@UserID = @db_custid, 
						@RoleID = @db_roleid, 
						@SubAccID = @SubAccID,
						@ServerID = @ServerID,
						@LoginIP = @LoginIP,
						@ActionID = 1322,
						@Doing = @LogData,
						@Duration = @Duration
				END CATCH	
			END
			select @ErrMsg = N'Login Failed.', @ErrCode = 107		
			return
		END

	IF IsNull(@closed, 1) = 1
		BEGIN
			SELECT @LogData = @role + @UserName + ' - ' + 'Login Result:Failed(A/C_Closed)'
		
			SET @End = GETDATE() 
			SET @Duration = DATEDIFF(millisecond,@Begin,@End)
			-- Starting: Service Broke code --
			SET @SB_xml = (SELECT	
								@db_custid	AS '@UserID'
								, @db_roleid AS '@RoleID'
								, @SubAccID	AS '@SubAccID'
								, @ServerID	AS '@ServerID'
								, @LoginIP AS '@IP'
								, NULL AS '@DomainName'
								, @SB_currentDate AS '@LogDate'
								, 1322	AS '@ActionID'
								, @LogData AS	'@Doing'
								, NULL AS '@BrowserName'
								, NULL	AS '@Platform'
								, NULL AS '@CountryCode'
								, @Duration	AS '@Duration'
								, NULL AS '@Username2'
					
							FOR XML PATH ('row')
							)
				
			--SELECT @SB_xml
			EXEC bodb_CustomerLog.sb.CustomerLog_SendMessage @xml = @SB_xml, @MessageType='MessageType_CustomerLog_UserLog_Login', @SB_Error = @SB_Error out
			--SELECT @SB_Error AS SB_Error
			IF @SB_Error = 1 
			BEGIN
			
				BEGIN TRY
					EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login
						@UserID = @db_custid, 
						@RoleID = @db_roleid, 
						@SubAccID = @SubAccID,
						@ServerID = @ServerID,
						@LoginIP = @LoginIP,
						@ActionID = 1322,
						@Doing = @LogData,
						@Duration = @Duration
				END TRY
				BEGIN CATCH		
					SELECT @LogData = @LogData + ' ErrMsg=' + left(error_message(), 400)
				
					EXEC bodb_customerlog.dbo.WriteLog_UserLog_Login
						@UserID = @db_custid, 
						@RoleID = @db_roleid, 
						@SubAccID = @SubAccID,
						@ServerID = @ServerID,
						@LoginIP = @LoginIP,
						@ActionID = 1322,
						@Doing = @LogData,
						@Duration = @Duration
				END CATCH	
			END
			select @ErrMsg = case @Language when 'E' then N'Account closed. Please contact your administrator!' 
					else N'此戶口已關閉. 請聯絡管理部' end, @ErrCode = 108
			return
		END
	ELSE IF @db_userpwd <> @UserPWD
		BEGIN			
			SELECT @LogData = @role + @UserName + ' - ' + 'Login Result:Failed(Password)'
				,@failedcount = @failedcount + 1
		
			SET @End = GETDATE() 
			SET @Duration = DATEDIFF(millisecond,@Begin,@End)
			
			-- Starting: Service Broke code --
			SET @SB_xml = (SELECT	
								@db_custid	AS '@UserID'
								, @db_roleid AS '@RoleID'
								, @SubAccID	AS '@SubAccID'
								, @ServerID	AS '@ServerID'
								, @LoginIP AS '@IP'
								, NULL AS '@DomainName'
								, @SB_currentDate AS '@LogDate'
								, 1322	AS '@ActionID'
								, @LogData AS	'@Doing'
								, NULL AS '@BrowserName'
								, NULL	AS '@Platform'
								, NULL AS '@CountryCode'
								, @Duration	AS '@Duration'
								, NULL AS '@Username2'
					
							FOR XML PATH ('row')
							)
				
			--SELECT @SB_xml
			EXEC bodb_CustomerLog.sb.CustomerLog_SendMessage @xml = @SB_xml, @MessageType='MessageType_CustomerLog_UserLog_Login', @SB_Error = @SB_Error out
			--SELECT @SB_Error AS SB_Error
			IF @SB_Error = 1 
			BEGIN
				BEGIN TRY
					EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login
						@UserID = @db_custid, 
						@RoleID = @db_roleid, 
						@SubAccID = @SubAccID,
						@ServerID = @ServerID,
						@LoginIP = @LoginIP,
						@ActionID = 1322,
						@Doing = @LogData,
						@Duration = @Duration
				END TRY
				BEGIN CATCH		
					SELECT @LogData = @LogData + ' ErrMsg=' + left(error_message(), 400)
				
					EXEC bodb_customerlog.dbo.WriteLog_UserLog_Login
						@UserID = @db_custid, 
						@RoleID = @db_roleid, 
						@SubAccID = @SubAccID,
						@ServerID = @ServerID,
						@LoginIP = @LoginIP,
						@ActionID = 1322,
						@Doing = @LogData,
						@Duration = @Duration
				END CATCH		
			END
			IF @isSubAcc = 0
			BEGIN
				IF @failedcount > 5 and @isSubAcc = 0
				BEGIN
					UPDATE custinfo with (rowlock, updlock) SET closed = 1 WHERE custid = @db_custid
				
					UPDATE customer with (rowlock, updlock) SET logincount = 0 WHERE custid = @db_custid
				
					DECLARE @LogSPData VARCHAR(500)
				
					--log data to UserLog_RunSP 
	    			SELECT @LogSPData = '<Age_LoginDownline_API IP="'+ @LoginIP + '" />'		    
					BEGIN TRY 	
					EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_RunSP
						@UserID = @db_custid,
						@CustID = @db_custid,
						@ActionID = 925,
						@TrackingValue = @LogSPData,
						@Duration = @Duration
					END TRY 
					BEGIN CATCH
						SELECT @LogSPData = '<Age_LoginDownline_API IP="'+ @LoginIP + '" ' +
													'ErrMsg="' + ERROR_MESSAGE() +'" ' + 
										
											' />'
						EXEC bodb_customerlog.dbo.WriteLog_UserLog_RunSP
							@UserID = @db_custid,
							@CustID = @db_custid,
							@ActionID = 925,
							@TrackingValue = @LogSPData,
							@Duration = @Duration		
				
					END CATCH 
				END
				ELSE
					UPDATE customer with (rowlock, updlock) SET logincount = @failedcount WHERE custid = @db_custid
			END
			ELSE
			BEGIN
				IF @failedcount < 256
				BEGIN
					UPDATE custSub with (rowlock, updlock) SET logincount = @failedcount WHERE subaccid = @subaccid 
				END
			END
		
			select @ErrMsg = N'Wrong username or password.', 
					@ErrCode = case when @failedcount > 5 then 109 else 106 end
			SELECT @CustID = @db_custid
			return
		
		END

	-- Successful
	SELECT @Currency = Currency FROM exchange with (nolock) WHERE exchangeid = @db_currency
	SELECT @CustID = @db_custid, @RoleID = @db_roleid

	if @RoleID = 2
		select @MasterUsername = lower(username) from customer where custid = (select mrecommend from customer where custid = @CustID)
	else if @RoleID = 3
		select @MasterUsername = lower(@UserName)
	else if @RoleID = 4
		select @MasterUsername = null

	if @isSubAcc = 0
	begin
		UPDATE customer with (rowlock, updlock)
		SET logincount = 0, iplogin = @LoginIP, lastlogged = CURRENT_TIMESTAMP
		WHERE custid = @db_custid
	end 
	else
	begin
		UPDATE custSub with (rowlock, updlock) SET logincount = 0 WHERE subaccid = @subaccid 
	end

	SELECT @LogData = @role + @UserName + ' - ' + 'Login Result:Success'
	---------------------------
	-- ***Check Sub-Account***
	if @SubAccID > 0
		SET @LogData = 'SubAccountID:' +  convert(varchar(20), @SubAccID) + ' - ' + @LogData
	---------------------------
	SET @End = GETDATE() 
	SET @Duration = DATEDIFF(millisecond,@Begin,@End)
	
	-- Starting: Service Broke code --
	SET @SB_xml = (SELECT	
						@db_custid	AS '@UserID'
						, @db_roleid AS '@RoleID'
						, @SubAccID	AS '@SubAccID'
						, @ServerID	AS '@ServerID'
						, @LoginIP AS '@IP'
						, NULL AS '@DomainName'
						, @SB_currentDate AS '@LogDate'
						, 1322	AS '@ActionID'
						, @LogData AS	'@Doing'
						, NULL AS '@BrowserName'
						, NULL	AS '@Platform'
						, NULL AS '@CountryCode'
						, @Duration	AS '@Duration'
						, NULL AS '@Username2'
			
					FOR XML PATH ('row')
					)
		
	--SELECT @SB_xml
	EXEC bodb_CustomerLog.sb.CustomerLog_SendMessage @xml = @SB_xml, @MessageType='MessageType_CustomerLog_UserLog_Login', @SB_Error = @SB_Error out
	--SELECT @SB_Error AS SB_Error
	IF @SB_Error = 1 
	BEGIN
			
		BEGIN TRY
			EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login
				@UserID = @db_custid, 
				@RoleID = @db_roleid, 
				@SubAccID = @SubAccID,
				@ServerID = @ServerID,
				@LoginIP = @LoginIP,
				@ActionID = 1322,
				@Doing = @LogData,
				@Duration = @Duration
		END TRY
		BEGIN CATCH		
			SELECT @LogData = @LogData + ' ErrMsg=' + left(error_message(), 400)
		
			EXEC bodb_customerlog.dbo.WriteLog_UserLog_Login
				@UserID = @db_custid, 
				@RoleID = @db_roleid, 
				@SubAccID = @SubAccID,
				@ServerID = @ServerID,
				@LoginIP = @LoginIP,
				@ActionID = 1322,
				@Doing = @LogData,
				@Duration = @Duration
		END CATCH
	END			
END


GO
GRANT EXECUTE ON [dbo].[Age_LoginDownline_API] TO [wsv_alp] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Age_LoginDownline_API] TO [wsv_alpv] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Age_LoginDownline_API] TO [vnteam] AS [dbo]


