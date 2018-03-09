ALTER PROCEDURE [dbo].[U3_LoginDownline_Admin]
	@UserName varchar(50),
	@LoginIP varchar(20),
	@LoginTime datetime = null,
	@ServerID int = 0 OUTPUT,
	@LoginDomain NVARCHAR(253) = NULL,
	@BrowserName NVARCHAR(255) = NULL,
	@Platform NVARCHAR(255) = NULL,  
	@CountryCode VARCHAR(64) = NULL,
	@RoleID int OUTPUT,
	@CustID int OUTPUT,
	@site varchar(20) = '' OUTPUT,  
	@On_UserID int OUTPUT,
	@Currency varchar(10) = '' OUTPUT,
	@CurrencyId int = 0 OUTPUT,
	@CasinoDisable bit = false OUTPUT,	
	@CasinoSync bit = false OUTPUT,
	@BingoDisable bit = false OUTPUT,
	@BingoSync bit = false OUTPUT,
	@Language varchar(2)= 'E',
	@accUserID int = 0, --UserID of Admin
	@accUsername varchar(50) = '' OUTPUT,
	@accUserPwd varchar(50) = '' OUTPUT,
	@SecurityCode VARCHAR(50) = '' OUTPUT,
	@isForcedChangeSecurityCode BIT = 0 OUTPUT,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS
/*
Created: 
Task : Admin login agency system.
DB: DBTXN/bodb02
Original:LoginDownline_Admin

Param's Explanation:
• @Username: agent username
• @LoginIP.
• @ServerID. 
• @RoleID agent roleid output.
• @accUserID UserID of Admin.
• @accUsername admin username.
• @accUserPwd admin password.

Revisions:
	- 20090304@Sifu: Get CasinoDisabled information from CustInfo table
	- 20090312@Phuc: not update logincount.
	- 20090407@Lee: Add output currencyId
	- 20091112@Simon: Write time into Log.
	- 20100101@Kiwi: Modify Log.
	- 20100807@Lee: Add output @site.
	- 20100922@Jamie: Get SyncBingo, DisableBingo 
	- 20101006@Kaden; Add 4 parameter (DomainName, BrowserName, Platform, CountryCode). Save more detail user info
	- 20101022@Johnson: Record execution time
	- 20121128@Elodie: Get an error message from f_Get_MsgNameByMsgID function by language
	- 20130123@Elodie: Write more log on DBTXN server in case of DBLOG server failure
	- 20130426@Johnson: get field SecurityCode 
	- 20130507@Johnson: get field isForcedChangeSecurityCode
	- 20161102@Helen: Apply Service Broker for Writing Log - [Redmine: 65806] 
*/
BEGIN
	SET NOCOUNT ON 

	DECLARE @Begin		DATETIME 
	DECLARE @End		DATETIME
	DECLARE @Duration	INT

	SET @Begin = GETDATE()
	 
	declare @LogData nvarchar(200),	@logincount int,@locked int

	-- SB Parameters -----
	DECLARE @SB_xml XML, @SB_currentDate DATETIME, @SB_Error BIT = 0
	SET @SB_currentDate = GETDATE()
	-- SB Parameters ----------	
	
	IF ISDATE(@LoginTime) = 0 OR DATEDIFF(SECOND, @LoginTime, CURRENT_TIMESTAMP) > 5 OR DATEDIFF(SECOND, @LoginTime, CURRENT_TIMESTAMP) < 0
	BEGIN	
		SELECT @ErrMsg = CASE @Language WHEN 'E' THEN 'Login error! Session expired.'  
					ELSE [dbo].[f_Get_MsgNamebyMsgID](80005,@Language)
				END , @ErrCode=105    
		RETURN    
	END

	if not exists (SELECT 1
					FROM customer as c with (NOLOCK)
						inner join custinfo as ci with (NOLOCK) on c.custid = ci.custid
					WHERE  c.roleID in (2,3,4) and c.username = @Username)
	BEGIN
		RETURN
	END
	else
	BEGIN
		Select	@CustID  = CustInfo.CustID, @RoleID = CustInfo.RoleID, @Currency = Exchange.Currency, @CurrencyId = Exchange.ExchangeId
				,@CasinoDisable = CustInfo.DisableCasino, @CasinoSync = CustInfo.SyncCasino
				,@BingoDisable = CustInfo.DisableBingo, @BingoSync = CustInfo.syncBingo 
		from 
			CustInfo with (NOLOCK) 
			INNER JOIN Exchange with (NOLOCK) ON CustInfo.Currency=  Exchange.ExchangeID
		where CustInfo.username = @UserName
		
		Select @site = site 
		from
			Customer with(NOLOCK)
		where CustId = @CustID
		
		SELECT @SecurityCode = ISNULL(SecurityCode,''),
			@isForcedChangeSecurityCode = ISNULL(isForcedChangeSecurityCode,0)
		FROM dbo.CustLoginInfo WITH(NOLOCK)
		WHERE custid = @custid
		------------------------
		--Login from Account site	
		select @accUsername = username, @accUserPwd = userpwd from customer with (nolock) where custid = @accUserID
		
		select @ServerID = case @RoleID when 2 then 90 when 3 then 91 else 92 end  
		------------------------

		Select @LogData = 'Admin ' + @accUsername + ' - Login to ' + @UserName 
		
		DECLARE @SubAccID int
		SELECT @SubAccID = @accUserID * (-1) -- Admin Login
		
		SET @End = GETDATE()
		SET @Duration = DATEDIFF(millisecond, @Begin, @End)
		
		-- Starting: Service Broke code --
		SET @SB_xml = (SELECT	
							@CustID	AS '@UserID'
							, @RoleID AS '@RoleID'
							, @SubAccID	AS '@SubAccID'
							, @ServerID	AS '@ServerID'
							, @LoginIP AS '@IP'
							, @LoginDomain AS '@DomainName'
							, @SB_currentDate AS '@LogDate'
							, 1301	AS '@ActionID'
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
					 @ActionID = 1301,
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
					 @ActionID = 1301,
					 @Doing = @LogData,
					 @BrowserName = @BrowserName,
					 @Platform = @Platform,
					 @CountryCode = @CountryCode,
					 @Duration = @Duration
			END CATCH
		END
		
		-- Starting: Service Broke code --
		SET @SB_xml = (SELECT	
							@accUserID	AS '@UserID'
							, @RoleID AS '@RoleID'
							, @SubAccID	AS '@SubAccID'
							, @ServerID	AS '@ServerID'
							, @LoginIP AS '@IP'
							, @LoginDomain AS '@DomainName'
							, @SB_currentDate AS '@LogDate'
							, 1301	AS '@ActionID'
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
					 @UserID = @accUserID, 
					 @RoleID = @RoleID, 
					 @SubAccID = @SubAccID,
					 @ServerID = @ServerID,
					 @LoginIP = @LoginIP,
					 @DomainName = @LoginDomain,	
					 @ActionID = 1301,
					 @Doing = @LogData,
					 @BrowserName = @BrowserName,
					 @Platform = @Platform,
					 @CountryCode = @CountryCode,
					 @Duration = @Duration
			END TRY
			BEGIN CATCH
				SELECT @LogData = @LogData + ' ErrMsg=' + left(error_message(), 400)
				EXEC bodb_customerlog.dbo.WriteLog_UserLog_Login
					 @UserID = @accUserID, 
					 @RoleID = @RoleID, 
					 @SubAccID = @SubAccID,
					 @ServerID = @ServerID,
					 @LoginIP = @LoginIP,
					 @DomainName = @LoginDomain,	
					 @ActionID = 1301,
					 @Doing = @LogData,
					 @BrowserName = @BrowserName,
					 @Platform = @Platform,
					 @CountryCode = @CountryCode,
					 @Duration = @Duration
			END CATCH
		END	
		RETURN
	END
END
GO
GRANT EXECUTE ON [dbo].[Age_LoginDownline_Admin] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Age_LoginDownline_Admin] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Age_LoginDownline_Admin] TO [vnteam]