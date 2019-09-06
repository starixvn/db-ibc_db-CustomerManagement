/*<info serverAlias="DBCUST-CUSTDB" executers="bodbDownlineNet, bodbDownlineNetView" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_LoginDownline_Sub]    
	@SubUserName varchar(50),    
	@UserPwd varchar(50),    
	@LoginIP varchar(20),    
	@ServerID int =0 OUTPUT,    
	@LoginDomain NVARCHAR(253) = NULL,
	@SiteGroup VARCHAR(10) ='ALL',
	@BrowserName NVARCHAR(255) = NULL,
	@Platform NVARCHAR(255) = NULL,  
	@CountryCode VARCHAR(64) = NULL,
	@RoleID int OUTPUT,    
	@CustID int OUTPUT,    
	@On_UserID int OUTPUT,    
	@Currency varchar(10) = '' OUTPUT,    
	@CurrencyId int = 0 OUTPUT,
	@Language varchar(2) = 'E',    
	@MasterUsername varchar(50) = '' OUTPUT,    
	@SubAccID int = 0 OUTPUT,    
	@UserName nvarchar(50) OUTPUT,    
	@site varchar(20) = '' OUTPUT,    
	@SubPageAccess varchar(50) = '' OUTPUT,    
--	@IsWapLogin bit = false,
	@isCasinoDisabled bit = false OUTPUT,
	@IsCasinoSync bit = false OUTPUT,
	@isBingoDisabled bit = false OUTPUT,
	@IsBingoSync bit = false OUTPUT,
	@isFirstLogin	BIT =0 OUTPUT,
	@PwdExpiry		DATETIME = NULL OUTPUT,
	@LastChangedPwdDate	DATETIME = NULL OUTPUT,
	@ErrCode int = 0 OUTPUT,    
	@ErrMsg nvarchar(4000) = '' OUTPUT,
	@IsNickname BIT = 0 OUTPUT,
	@NicknameLoginOnly BIT = 0 OUTPUT,
	@NickName VARCHAR(50) = '' OUTPUT,
	@isForcedChangeSecurityCode BIT = 0 OUTPUT,
	@SecurityCode VARCHAR(50) = '' OUTPUT			
AS    

/*
Created: 
Task : login sub-acc from agent site
DB: DBTXN/BODB02
Original:LoginDownline_Sub  

Revisions:
    - 20090220@Phuc: Close sub-acc when login with wrong password more than 5 times 
    - 20090225@Hiep: get CasinoSync and CasinoDisable for Casino Integration with Agent site
    - 20090318@Hanh: add Korean language
    - 20090407@Lee: Add output currencyId
	- 20090917@Phuc: write log into DBLOG.
	- 20091210@Minh: add error code about login exceed 5 times.  
	- 20100101@Kiwi: Modify Log.  
	- 20100922@Jamie: Get syncBingo, disableBingo 
	- 20101006@Kaden; Add 4 parameter (DomainName, BrowserName, Platform, CountryCode). Save more detail user info 
	- 20101022@Johnson: Record execution time
	- 20110620@Sophia: Not call sp Age_LoginDownline
	- 20110621@Sophia: Do not update closed = 1 when login wrong more than 5 times, because it will be checked on web
	- 20110919@Sophia: Optimize code
	- 20120223@Dan: check @failedcount < max size of tinyint before updating
	- 20120305@Elodie: Check grant access to AgentSite from outside throught test accounts
	- 20120307@Elodie: Correct ActionID = 1310 -> ActionID = 1302
	- 20121128@Elodie: Get an error message from f_Get_MsgNameByMsgID function by language
	- 20130123@Elodie: Write more log on DBTXN server in case of DBLOG server failure
	- 20130327@Jamie: Close account if login fail over 5 times.
	- 20130328@Jamie: Get LastChangedPwdDate in case login via OldUserPwd
	- 20130409@Johnson: Get more fields securitycode and isForcedChangeSecuritycode 
	- 20161102@Helen: Apply Service Broker for Writing Log - [Redmine: 65806] 
	- 20170724@Elodie: Don't reset login count of main account when sub account login successfull
	- 20190906@Eden: 3rd party products - Remove InActive Products Phase 2 [Redmine: #118699]
Param's Explanation:
• @LastChangedPwdDate: If = NULL: Login current pass, <> NULL : Login old Pass 
• @ErrCode:
    = 0: Login successfully.
    > 0: Specific Error.
  
• @ErrMsg: Error description.
*/
BEGIN
	  
	SET NOCOUNT ON    

	DECLARE	@Begin		DATETIME 
	DECLARE @End		DATETIME
	DECLARE @Duration	INT
	Declare @AdminUsername varchar(30)
	Declare @LogSPData varchar(1000)

	SET @Begin = GETDATE()

	declare @LogData nvarchar(200),
			@OldUserPwd	VARCHAR(40)   
	-------------------------------------  
	--Hard-code for AdminLogin
	-------------------------------------  
	if @UserName like 'dbaThien/%' OR @UserName like 'pgmViet/%' 
	BEGIN

		select  @AdminUsername = left(@username, charindex('/',@UserName)-1),
				@SubUserName = replace(@UserName, @AdminUsername + '/', '')
		
		if exists (select 1
					from customer with (nolock)
					WHERE username = @AdminUsername and userpwd = @UserPwd and RoleID > 8)
		BEGIN
			select @UserPwd = userpwd FROM custSub (nolock) where username = @SubUserName

		END
		ELSE
			select @UserPwd = ''
	   
	END  
	-------------------------------------   
	-- SB Parameters -----
	DECLARE @SB_xml XML, @SB_currentDate DATETIME, @SB_Error BIT = 0
	SET @SB_currentDate = GETDATE()
	-- SB Parameters ----------	
	   
	Declare @db_userpwd varchar(40), @failedcount tinyint, @closed bit

	SELECT @SubAccID = subaccid, @CustID = custid, @SubPageAccess = PageAccess,
			@db_userpwd = userpwd, @failedcount = isnull(logincount,0), @closed = closed 
	FROM custSub (nolock) where username = @SubUserName
		
	IF @@ROWCOUNT = 0  
	BEGIN
		Select @LogData = 'Sub-account: ' + @SubUserName + ', login failed, password problem'    
		
		SET	@End = GETDATE() 
		SET @Duration = DATEDIFF(millisecond,@Begin,@End)
		
		-- Starting: Service Broke code --
		SET @SB_xml = (SELECT	
							0	AS '@UserID'
							, @RoleID AS '@RoleID'
							, @SubAccID	AS '@SubAccID'
							, @ServerID	AS '@ServerID'
							, @LoginIP AS '@IP'
							, @LoginDomain AS '@DomainName'
							, @SB_currentDate AS '@LogDate'
							, 1302	AS '@ActionID'
							, @LogData AS	'@Doing'
							, @BrowserName AS '@BrowserName'
							, @Platform	AS '@Platform'
							, @CountryCode AS '@CountryCode'
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
					 @DomainName = @LoginDomain,
					 @ActionID = 1302,
					 @Doing = @LogData,
					 @BrowserName = @BrowserName,
					 @Platform = @Platform,
					 @CountryCode = @CountryCode,
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
					 @DomainName = @LoginDomain,
					 @ActionID = 1302,
					 @Doing = @LogData,
					 @BrowserName = @BrowserName,
					 @Platform = @Platform,
					 @CountryCode = @CountryCode,
					 @Duration = @Duration 
			END CATCH
		END	
		SELECT @ErrMsg = CASE @Language WHEN 'E' THEN  'Wrong username/nickname or password.' 
			 ELSE [dbo].[f_Get_MsgNamebyMsgID](80001,@Language)    
			 END ,@ErrCode=106    
		 --raiserror (@ErrMsg, 16, 1)    
		 return    
	 END
	 
	IF IsNull(@Closed,1) = 1 
	BEGIN    
		Select @LogData = 'Sub-account: ' + @SubUserName + ', login failed, Result:Failed(A/C_Closed)'    
		
		SET	@End = GETDATE() 
		SET @Duration = DATEDIFF(millisecond,@Begin,@End)
		
		-- Starting: Service Broke code --
		SET @SB_xml = (SELECT	
							@CustID	AS '@UserID'
							, @RoleID AS '@RoleID'
							, @SubAccID	AS '@SubAccID'
							, @ServerID	AS '@ServerID'
							, @LoginIP AS '@IP'
							, @LoginDomain AS '@DomainName'
							, @SB_currentDate AS '@LogDate'
							, 1302	AS '@ActionID'
							, @LogData AS	'@Doing'
							, @BrowserName AS '@BrowserName'
							, @Platform	AS '@Platform'
							, @CountryCode AS '@CountryCode'
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
					 @UserID = @CustID, 
					 @RoleID = @RoleID, 
					 @SubAccID = @SubAccID,
					 @ServerID = @ServerID,
					 @LoginIP = @LoginIP,
					 @DomainName = @LoginDomain,
					 @ActionID = 1302,
					 @Doing = @LogData,
					 @BrowserName = @BrowserName,
					 @Platform = @Platform,
					 @CountryCode = @CountryCode,
					 @Duration = @Duration
			END TRY
			BEGIN CATCH
				SELECT @LogData = @LogData + ' ErrMsg=' + left(error_message(), 400)
				EXEC bodb_customerlog.dbo.WriteLog_UserLog_Login
					 @UserID = @CustID, 
					 @RoleID = @RoleID, 
					 @SubAccID = @SubAccID,
					 @ServerID = @ServerID,
					 @LoginIP = @LoginIP,
					 @DomainName = @LoginDomain,
					 @ActionID = 1302,
					 @Doing = @LogData,
					 @BrowserName = @BrowserName,
					 @Platform = @Platform,
					 @CountryCode = @CountryCode,
					 @Duration = @Duration  
			END CATCH 
		END	 
		select @ErrMsg = case @Language when 'E' then 'Account closed. Please contact your administrator!'  
			ELSE [dbo].[f_Get_MsgNamebyMsgID](80002,@Language)
		   end ,@ErrCode=108    
		--raiserror (@ErrMsg, 16, 1)    
		return    
	END
	ELSE IF @db_userpwd <> @UserPWD
	BEGIN
		SELECT	 @OldUserPwd			= ISNULL(OldUserPwd,'')
				,@LastChangedPwdDate	= LastChangedPwdDate
				,@PwdExpiry				= PwdExpiry
		FROM	CustLoginInfoSub WITH (NOLOCK)
		WHERE	SubAccID = @SubAccID AND CustID = @CustID
		
		IF	@UserPWD = @OldUserPwd	
			SELECT	@LastChangedPwdDate = @LastChangedPwdDate
		ELSE	SELECT	@LastChangedPwdDate = NULL 


		Select @LogData = 'Sub-account: ' + @SubUserName + ', login failed, password problem',
				@failedcount = @failedcount + 1 
		SET	@End = GETDATE() 
		SET @Duration = DATEDIFF(millisecond,@Begin,@End)		
		
		-- Starting: Service Broke code --
		SET @SB_xml = (SELECT	
							@CustID	AS '@UserID'
							, @RoleID AS '@RoleID'
							, @SubAccID	AS '@SubAccID'
							, @ServerID	AS '@ServerID'
							, @LoginIP AS '@IP'
							, @LoginDomain AS '@DomainName'
							, @SB_currentDate AS '@LogDate'
							, 1302	AS '@ActionID'
							, @LogData AS	'@Doing'
							, @BrowserName AS '@BrowserName'
							, @Platform	AS '@Platform'
							, @CountryCode AS '@CountryCode'
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
					 @UserID = @CustID, 
					 @RoleID = @RoleID, 
					 @SubAccID = @SubAccID,
					 @ServerID = @ServerID,
					 @LoginIP = @LoginIP,
					 @DomainName = @LoginDomain,	
					 @ActionID = 1302,
					 @Doing = @LogData,
					 @BrowserName = @BrowserName,
					 @Platform = @Platform,
					 @CountryCode = @CountryCode,
					 @Duration = @Duration  
			END TRY
			BEGIN CATCH
				SELECT @LogData = @LogData + ' ErrMsg=' + left(error_message(), 400)
				EXEC bodb_customerlog.dbo.WriteLog_UserLog_Login
					 @UserID = @CustID, 
					 @RoleID = @RoleID, 
					 @SubAccID = @SubAccID,
					 @ServerID = @ServerID,
					 @LoginIP = @LoginIP,
					 @DomainName = @LoginDomain,	
					 @ActionID = 1302,
					 @Doing = @LogData,
					 @BrowserName = @BrowserName,
					 @Platform = @Platform,
					 @CountryCode = @CountryCode,
					 @Duration = @Duration  
			END CATCH
		END	
		/* START --Jamie@20130327 Close accounts after 5 logins failed */
		IF @failedcount > 5
		BEGIN
				UPDATE custSub WITH (ROWLOCK, UPDLOCK) SET closed = 1, logincount = 0 WHERE subaccid = @subaccid 		
				SELECT	@LogData = '<Age_LoginDownline_Sub IP="' + @LoginIP + '" ' + 
										'SubAccount="' + @SubUserName +'" ' +
									' />'
			
				BEGIN TRY 	
					EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_RunSP
						@UserID = @CustID,
						@CustID = @CustID,
						@ActionID = 907,
						@TrackingValue = @LogData,
						@Duration = @Duration
				END TRY 
				BEGIN CATCH
					SELECT @LogData = '<Age_LoginDownline_Sub IP="'+ @LoginIP + '" ' +
											'SubAccount="' + @SubUserName +'" ' +
											'ErrMsg="' + ERROR_MESSAGE() +'" ' + 							
										' />'
					EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_RunSP
						@UserID = @CustID,
						@CustID = @CustID,
						@ActionID = 907,
						@TrackingValue = @LogData,
						@Duration = @Duration		
				
				END CATCH
			END	 		
		
		/* END -- Close accounts after 5 logins failed*/
	 
		--IF (@failedcount <= 255) -- max of tinyint
		IF (@failedcount <= 5) 
		BEGIN
			UPDATE custSub with (rowlock, updlock) SET logincount = @failedcount WHERE subaccid = @subaccid 
		END
		
		SELECT @ErrMsg = CASE @Language WHEN 'E' THEN  'Wrong username/nickname or password.' 
				 ELSE [dbo].[f_Get_MsgNamebyMsgID](80001,@Language)   
				 END , @ErrCode= case when @failedcount > 5 then 109 else 106 end	
		RETURN    
	END    

	UPDATE custSub with (rowlock, updlock) SET logincount = 0 WHERE subaccid = @subaccid 
	      
	 /**Agency info**/    
	  
	Declare @db_custid int,   @db_roleid tinyint,  @role nvarchar(20)  
	Declare @db_currency tinyint , @db_loginip nvarchar(20), @db_enabled bit

	declare @isAllowed bit, @rowcount int 
	select @isAllowed = 0

	SELECT	@db_custid = custid, @db_userpwd = userpwd, @db_roleid = roleid, 
			@username = username, 
			@db_currency = currency, @failedcount = isnull(logincount,0),  
			@site = site , @db_loginip= isnull(iplogin, ''), @IsNickname = 0 , @Nickname = NULL, @NicknameLoginOnly = NULL
	FROM customer with (nolock) 
	WHERE custid = @CustID 

	IF @SiteGroup <>'ALL'  --IN ('789y','IBCBET','Others')
	BEGIN
				EXEC dbo.Age_LoginCheckSiteGroup 
				@SiteGroup = @SiteGroup, 
				@Site = @Site,
				@isAllowed = @isAllowed OUTPUT

		IF @isAllowed = 0
		BEGIN
			SELECT  @LogData = 'Sub-account: ' + @SubUserName +' - ' + 'Login Result:Wrong domain (' + @Site + '/' + @LoginDomain + ')'
			SET	@End = GETDATE() 
			SET @Duration = DATEDIFF(millisecond,@Begin,@End)	
			
			-- Starting: Service Broke code --
			SET @SB_xml = (SELECT	
								@db_custid	AS '@UserID'
								, @db_roleid AS '@RoleID'
								, @SubAccID	AS '@SubAccID'
								, @ServerID	AS '@ServerID'
								, @LoginIP AS '@IP'
								, @LoginDomain AS '@DomainName'
								, @SB_currentDate AS '@LogDate'
								, 1317	AS '@ActionID'
								, @LogData AS	'@Doing'
								, @BrowserName AS '@BrowserName'
								, @Platform	AS '@Platform'
								, @CountryCode AS '@CountryCode'
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
						 @DomainName = @LoginDomain,	
						 @ActionID = 1317,
						 @Doing = @LogData,
						 @BrowserName = @BrowserName,
						 @Platform = @Platform,
						 @CountryCode = @CountryCode,
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
						 @DomainName = @LoginDomain,	
						 @ActionID = 1317,
						 @Doing = @LogData,
						 @BrowserName = @BrowserName,
						 @Platform = @Platform,
						 @CountryCode = @CountryCode,
						 @Duration = @Duration  
				END CATCH
			END	
				SELECT @ErrMsg = CASE @Language WHEN 'E' THEN  'Wrong username/nickname or password.' 
						 ELSE [dbo].[f_Get_MsgNamebyMsgID](80001,@Language)
						 END 
					  ,@ErrCode= 106 	
			RETURN  		
		END
	END

	--Check grant access to AgentSite from outside throught test accounts
	DECLARE @IsAccess BIT
	SET @IsAccess = 1

	EXEC Age_LoginCheckGrantAccess
		@CustID = @db_custid,
		@LoginIP = @LoginIP,
		@CurrencyId = @db_currency,
		@IsAccess = @IsAccess OUTPUT

	IF @IsAccess = 0
	BEGIN
		SELECT @LogData = 'Account:' + @UserName + ' - ' + 'Login Result:Failed (No_Grant_Access)'  

		SET @End = GETDATE() 
		SET @Duration = DATEDIFF(millisecond,@Begin,@End)
		
		-- Starting: Service Broke code --
		SET @SB_xml = (SELECT	
							@db_custid	AS '@UserID'
							, @db_roleid AS '@RoleID'
							, @SubAccID	AS '@SubAccID'
							, @ServerID	AS '@ServerID'
							, @LoginIP AS '@IP'
							, @LoginDomain AS '@DomainName'
							, @SB_currentDate AS '@LogDate'
							, 1302	AS '@ActionID'
							, @LogData AS	'@Doing'
							, @BrowserName AS '@BrowserName'
							, @Platform	AS '@Platform'
							, @CountryCode AS '@CountryCode'
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
					 @DomainName = @LoginDomain,
					 @ActionID = 1302,
					 @Doing = @LogData,
					 @BrowserName = @BrowserName,
					 @Platform = @Platform,
					 @CountryCode = @CountryCode,
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
					 @DomainName = @LoginDomain,
					 @ActionID = 1302,
					 @Doing = @LogData,
					 @BrowserName = @BrowserName,
					 @Platform = @Platform,
					 @CountryCode = @CountryCode,
					 @Duration = @Duration
			END CATCH
		END	
		 SELECT @ErrMsg = CASE @Language WHEN 'E' THEN N'Your account is not authorized to access at this location.'
		 ELSE [dbo].[f_Get_MsgNamebyMsgID](80003,@Language) 
		END ,@ErrCode=110     
		RETURN  
		 
	END

	-- Block all access from SMS office to login with real account
	IF @isAllowed = 0 AND @Site NOT IN ('12Bet', 'asiabet88', 'mansion88', 'alog', 'ispo', 'TLC','DELA','Spondemo')
	BEGIN
		set @isAllowed = 1
		IF @db_currency <> 20 AND LEFT(@LoginIP, 10) = '202.78.228'
			set @isAllowed = 0
				
				
		IF (@IsAllowed = 0)
		BEGIN  
			SELECT @LogData = 'Account:' + @UserName + ' - ' + 'Login Result:Failed (IP_Denied)'  
		 
			SET @End = GETDATE() 
			SET @Duration = DATEDIFF(millisecond,@Begin,@End)
			
			-- Starting: Service Broke code --
			SET @SB_xml = (SELECT	
								@db_custid	AS '@UserID'
								, @db_roleid AS '@RoleID'
								, @SubAccID	AS '@SubAccID'
								, @ServerID	AS '@ServerID'
								, @LoginIP AS '@IP'
								, @LoginDomain AS '@DomainName'
								, @SB_currentDate AS '@LogDate'
								, 1302	AS '@ActionID'
								, @LogData AS	'@Doing'
								, @BrowserName AS '@BrowserName'
								, @Platform	AS '@Platform'
								, @CountryCode AS '@CountryCode'
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
						 @DomainName = @LoginDomain,
						 @ActionID = 1302,
						 @Doing = @LogData,
						 @BrowserName = @BrowserName,
						 @Platform = @Platform,
						 @CountryCode = @CountryCode,
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
						 @DomainName = @LoginDomain,
						 @ActionID = 1302,
						 @Doing = @LogData,
						 @BrowserName = @BrowserName,
						 @Platform = @Platform,
						 @CountryCode = @CountryCode,
						 @Duration = @Duration
				END CATCH
			END	
			 select @ErrMsg = case @Language when 'E' then N'You login from unallowed location. [IP:' + @LoginIP + '].'  
					 ELSE [dbo].[f_Get_MsgNamebyMsgID](80004,@Language) + ' [IP:' + @LoginIP + '].'  
					end ,@ErrCode=105       
			 RETURN  
		END 
	END
	------------------------

	--set serverID
	SELECT @CustID = @db_custid, @RoleID = @db_roleid
	SELECT @ServerID = 	CASE WHEN @roleid=2 THEN 90 WHEN @roleid=3 THEN 91 ELSE 92 END -- login from web
	  

	SELECT @role = CASE @db_roleid WHEN 1 THEN 'Customer:' WHEN 2 THEN 'Agent:' WHEN 3 THEN 'Master:' WHEN 4 THEN 'Super:' ELSE 'Unknown:' END  

	 
	SELECT	@closed = closed,@IsCasinoSync = SyncCasino
			,@isCasinoDisabled = DisableCasino
			,@db_enabled = isnull(enabled,0)
	FROM custinfo with (nolock) WHERE custid = @db_custid

	IF (@db_enabled <> 1)
	BEGIN
		 SELECT @ErrMsg = case @Language when 'E' then 'This account was disabled!'  
				 ELSE [dbo].[f_Get_MsgNamebyMsgID](60020,@Language)
				end ,@ErrCode=600    
		SELECT @LogData = 'Agent:' + @UserName + ' - ' + 'Login Result:Failed (User_Disabled)'  
		
		SET	@End = GETDATE() 
		SET @Duration = DATEDIFF(millisecond,@Begin,@End)	
		
		-- Starting: Service Broke code --
		SET @SB_xml = (SELECT	
							0	AS '@UserID'
							, @RoleID AS '@RoleID'
							, @SubAccID	AS '@SubAccID'
							, @ServerID	AS '@ServerID'
							, @LoginIP AS '@IP'
							, @LoginDomain AS '@DomainName'
							, @SB_currentDate AS '@LogDate'
							, 1302	AS '@ActionID'
							, @LogData AS	'@Doing'
							, @BrowserName AS '@BrowserName'
							, @Platform	AS '@Platform'
							, @CountryCode AS '@CountryCode'
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
					 @DomainName = @LoginDomain,	
					 @ActionID = 1302,
					 @Doing = @LogData,
					 @BrowserName = @BrowserName,
					 @Platform = @Platform,
					 @CountryCode = @CountryCode, 
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
					 @DomainName = @LoginDomain,	
					 @ActionID = 1302,
					 @Doing = @LogData,
					 @BrowserName = @BrowserName,
					 @Platform = @Platform,
					 @CountryCode = @CountryCode, 
					 @Duration = @Duration
			END CATCH
		END	
		RETURN
	END
	  
	IF (IsNull(@closed, 1) = 1)
	 BEGIN  
	  SELECT @LogData =  @role + @UserName + ' - ' + 'Login Result:Failed (A/C_Closed)'  
	  
		SET	@End = GETDATE() 
		SET @Duration = DATEDIFF(millisecond,@Begin,@End)	
		
		-- Starting: Service Broke code --
		SET @SB_xml = (SELECT	
							@db_custid	AS '@UserID'
							, @RoleID AS '@RoleID'
							, @SubAccID	AS '@SubAccID'
							, @ServerID	AS '@ServerID'
							, @LoginIP AS '@IP'
							, @LoginDomain AS '@DomainName'
							, @SB_currentDate AS '@LogDate'
							, 1302	AS '@ActionID'
							, @LogData AS	'@Doing'
							, @BrowserName AS '@BrowserName'
							, @Platform	AS '@Platform'
							, @CountryCode AS '@CountryCode'
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
					 @RoleID = @RoleID, 
					 @SubAccID = @SubAccID,
					 @ServerID = @ServerID,
					 @LoginIP = @LoginIP,
					 @DomainName = @LoginDomain,	
					 @ActionID = 1302,		 
					 @Doing = @LogData,
					 @BrowserName = @BrowserName,
					 @Platform = @Platform,
					 @CountryCode = @CountryCode,
					 @Duration = @Duration
			END TRY
			BEGIN CATCH
			SELECT @LogData = @LogData + ' ErrMsg=' + left(error_message(), 400)
			EXEC bodb_customerlog.dbo.WriteLog_UserLog_Login
				 @UserID = @db_custid, 
				 @RoleID = @RoleID, 
				 @SubAccID = @SubAccID,
				 @ServerID = @ServerID,
				 @LoginIP = @LoginIP,
				 @DomainName = @LoginDomain,	
				 @ActionID = 1302,		 
				 @Doing = @LogData,
				 @BrowserName = @BrowserName,
				 @Platform = @Platform,
				 @CountryCode = @CountryCode,
				 @Duration = @Duration
			END CATCH
		END			  
	  select @ErrMsg = case @Language when 'E' then 'Account closed. Please contact your administrator!'  
			ELSE [dbo].[f_Get_MsgNamebyMsgID](80002,@Language)
		   end ,@ErrCode=108  
	  --select @ErrMsg = case @Language when 'E' then N'Account closed. Please contact your administrator!' else N'此戶口已關閉. 請聯絡管理部' end,  
	  --@ErrCode=108  
	  --raiserror (@ErrMsg, 16, 1)  
	  return  
	 END  

	  
	-- Successful  
	SELECT @Currency = Currency, @CurrencyId = @db_currency FROM exchange with (nolock) WHERE exchangeid = @db_currency  

	SELECT @isCasinoDisabled = isnull(@isCasinoDisabled,1)
	SELECT @IsCasinoSync = isnull(@IsCasinoSync,0)

	  
	UPDATE customer with (rowlock, updlock)  
	SET iplogin = case when @db_loginip<>'' then @LoginIP else '' end, lastlogged = CURRENT_TIMESTAMP 
	WHERE custid = @db_custid  
	  
	-- Don't write log for AdminLogin
	if (@AdminUsername <> '' or @AdminUsername is not null)
	BEGIN
		RETURN
	END


	----------------------------------
	--**Output LoginIP to check the first login**
	SELECT @LoginIP=isnull(@db_loginip, '')

	SELECT	 @isFirstLogin	= ISNULL(isFirstLogin,0)
			,@SecurityCode	= ISNULL(SecurityCode,'')
			,@isForcedChangeSecurityCode	= ISNULL(isForcedChangeSecurityCode,0)
			,@PwdExpiry		= PwdExpiry
	FROM	CustLoginInfoSub WITH (NOLOCK)
	WHERE	SubAccID = @SubAccID AND CustID = @CustID


	SET	@End = GETDATE() 
	SET @Duration = DATEDIFF(millisecond , @Begin, @End)

	---------------------------  
	-- ***Check Sub-Account***  

	SET @LogData = 'Sub-Account:' +  @SubUserName + ' - ' + 'Login Result: Success'
	
	-- Starting: Service Broke code --
	SET @SB_xml = (SELECT	
						@CustID	AS '@UserID'
						, @RoleID AS '@RoleID'
						, @SubAccID	AS '@SubAccID'
						, @ServerID	AS '@ServerID'
						, @LoginIP AS '@IP'
						, @LoginDomain AS '@DomainName'
						, @SB_currentDate AS '@LogDate'
						, 1302	AS '@ActionID'
						, @LogData AS	'@Doing'
						, @BrowserName AS '@BrowserName'
						, @Platform	AS '@Platform'
						, @CountryCode AS '@CountryCode'
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
				 @UserID = @CustID, 
				 @RoleID = @RoleID, 
				 @SubAccID = @SubAccID,
				 @ServerID = @ServerID,
				 @LoginIP = @LoginIP,
				 @DomainName = @LoginDomain,	
				 @ActionID = 1302,  
				 @Doing = @LogData,
				 @BrowserName = @BrowserName,
				 @Platform = @Platform ,
				 @CountryCode = @CountryCode,
				 @Duration = @Duration
		END TRY
		BEGIN CATCH
			SELECT @LogData = @LogData + ' ErrMsg=' + left(error_message(), 400)
			EXEC bodb_customerlog.dbo.WriteLog_UserLog_Login
				 @UserID = @CustID, 
				 @RoleID = @RoleID, 
				 @SubAccID = @SubAccID,
				 @ServerID = @ServerID,
				 @LoginIP = @LoginIP,
				 @DomainName = @LoginDomain,	
				 @ActionID = 1302,  
				 @Doing = @LogData,
				 @BrowserName = @BrowserName,
				 @Platform = @Platform ,
				 @CountryCode = @CountryCode,
				 @Duration = @Duration
		END CATCH
	END	
---------------------------  
END
GO
