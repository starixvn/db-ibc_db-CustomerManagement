/*<info serverAlias="DBCUST-CUSTDB" executers="bodbDownlineNet, bodbDownlineNetView" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[CS_LoginDownline_Admin]
	@UserName VARCHAR(50),
	@LoginIP VARCHAR(20),
	@LoginTime DATETIME = NULL,
	@ServerID INT = 0 OUTPUT,
	@LoginDomain NVARCHAR(253) = NULL,
	@BrowserName NVARCHAR(255) = NULL,
	@Platform NVARCHAR(255) = NULL,  
	@CountryCode VARCHAR(64) = NULL,
	@RoleID INT OUTPUT,
	@CustID INT OUTPUT,
	@NickName VARCHAR(50) = '' OUTPUT,
	@site VARCHAR(20) = '' OUTPUT,  
	@On_UserID INT OUTPUT,
	@Currency VARCHAR(10) = '' OUTPUT,
	@CurrencyId INT = 0 OUTPUT,
	@CasinoDisable BIT = 0 OUTPUT,	
	@CasinoSync BIT = 0 OUTPUT,
	@BingoDisable BIT = 0 OUTPUT,
	@BingoSync BIT = 0 OUTPUT,
	@Language VARCHAR(2)= 'E',
	@accUserID INT = 0, --UserID of Admin
	@accUsername VARCHAR(50) = '' OUTPUT,
	@accUserPwd VARCHAR(50) = '' OUTPUT,
	@SecurityCode VARCHAR(50) = '' OUTPUT,
	@isForcedChangeSecurityCode BIT = 0 OUTPUT,
	@ErrCode INT = 0 OUTPUT,
	@ErrMsg NVARCHAR(4000) = '' OUTPUT,
	@Status TINYINT = 1 OUTPUT,
	@IsAllDownline BIT = 1 OUTPUT
AS
/*
	Created: 20190518@Elodie
	Task : Admin login agency system.
	DB: DBCUST/CUSTDB
	Original: LoginDownline_Admin

	Param's Explanation:
		• @Username: agent username
		• @LoginIP.
		• @ServerID. 
		• @RoleID agent roleid output.
		• @accUserID UserID of Admin.
		• @accUsername admin username.
		• @accUserPwd admin password.

	Revisions:
		- 20190527@Elodie: New account status for CN88 [Redmine: 113198]
		- 20190731@Percy: Alway return @IsAllDownline = 1 for internal login [RedmineID: #116825]
*/
BEGIN
	SET NOCOUNT ON 

	SELECT @IsAllDownline = 1 -- Alway return 1 for internal login

	DECLARE @Begin DATETIME, @End DATETIME, @Duration INT
	DECLARE @LogData NVARCHAR(200),	@logincount INT, @locked INT
    
	SET @Begin = GETDATE()
	
	IF ISDATE(@LoginTime) = 0 OR DATEDIFF(SECOND, @LoginTime, CURRENT_TIMESTAMP) > 5 OR DATEDIFF(SECOND, @LoginTime, CURRENT_TIMESTAMP) < 0
	BEGIN	
		SELECT @ErrMsg = CASE @Language WHEN 'E' THEN 'Login error! Session expired.'  
					ELSE [dbo].[f_Get_MsgNamebyMsgID](80005,@Language)
				END , @ErrCode=105    
		RETURN    
	END

	IF NOT EXISTS (	SELECT 1
					FROM customer AS c WITH(NOLOCK)
						INNER JOIN custinfo AS ci WITH(NOLOCK) ON c.custid = ci.custid
					WHERE  c.roleID in (2,3,4,0) AND c.username = @Username)
	BEGIN
		RETURN
	END
	ELSE
	BEGIN
		SELECT	@CustID  = CustInfo.CustID, @RoleID = CustInfo.RoleID, @Currency = Exchange.Currency, @CurrencyId = Exchange.ExchangeId
				,@CasinoDisable = CustInfo.DisableCasino, @CasinoSync = CustInfo.SyncCasino
				,@BingoDisable = CustInfo.DisableBingo, @BingoSync = CustInfo.syncBingo 
		FROM CustInfo with (NOLOCK) 
			INNER JOIN Exchange with (NOLOCK) ON CustInfo.Currency=  Exchange.ExchangeID
		WHERE CustInfo.username = @UserName
		
		SELECT @NickName = f.NickName, @site = site 
		FROM dbo.Customer WITH (NOLOCK)
			CROSS APPLY dbo.f_CS_GetNickName(UserName2,0) f			
		WHERE custid = @CustID
		
		SELECT @SecurityCode = ISNULL(SecurityCode,''),
			@isForcedChangeSecurityCode = ISNULL(isForcedChangeSecurityCode,0)
		FROM dbo.CustLoginInfo WITH(NOLOCK)
		WHERE custid = @custid

		SELECT @Status = CustStatus FROM dbo.f_CS_GetCustomerStatus (@CustID)

		------------------------
		--Login from Account site	
		SELECT @accUsername = username, @accUserPwd = userpwd FROM customer WITH(NOLOCK) WHERE custid = @accUserID
		
		SELECT @ServerID = CASE @RoleID WHEN 2 THEN 90 WHEN 3 THEN 91 WHEN 4 THEN 92 ELSE 93 END  
		------------------------

		SELECT @LogData = 'Admin ' + @accUsername + ' - Login to ' + @UserName 
		
		DECLARE @SubAccID INT
		SELECT @SubAccID = @accUserID * (-1) -- Admin Login
		
		SET @End = GETDATE()
		SET @Duration = DATEDIFF(millisecond, @Begin, @End)
		
		EXEC dbo.CS_WriteLog_UserLog_Login_Wrapper
			@UserID = @CustID, 
			@RoleID = @RoleID, 
			@SubAccID = @SubAccID,
			@ServerID = @ServerID,
			@LoginIP = @LoginIP,
			@DomainName = @LoginDomain,	
			@ActionID = 1332,
			@Doing = @LogData,
			@BrowserName = @BrowserName,
			@Platform = @Platform,
			@CountryCode = @CountryCode,
			@Duration = @Duration

		EXEC dbo.CS_WriteLog_UserLog_Login_Wrapper
			@UserID = @accUserID, 
			@RoleID = @RoleID, 
			@SubAccID = @SubAccID,
			@ServerID = @ServerID,
			@LoginIP = @LoginIP,
			@DomainName = @LoginDomain,	
			@ActionID = 1332,
			@Doing = @LogData,
			@BrowserName = @BrowserName,
			@Platform = @Platform,
			@CountryCode = @CountryCode,
			@Duration = @Duration
		
		RETURN
	END
END
GO
