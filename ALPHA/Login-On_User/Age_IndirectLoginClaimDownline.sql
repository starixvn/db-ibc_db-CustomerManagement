/*<info serverAlias="DBCUST-CUSTDB" executers="bodbDownlineNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_IndirectLoginClaimDownline]  
    @CustID INT = 0,
	@UplineUsername VARCHAR(30)='',	
	@UplineCustid INT, 
	@UplineSubAccID INT=0,
	@LoginIP VARCHAR(20)='' OUTPUT,  --- if output=NULL then account is the first login
	@ServerID INT = 0 OUTPUT,
	@LoginDomain NVARCHAR(253) = NULL,
	@BrowserName NVARCHAR(255) = NULL,
	@Platform NVARCHAR(255) = NULL,  
	@CountryCode VARCHAR(64) = NULL,
	@RoleID INT OUTPUT,  
	@Currency VARCHAR(10) = '' OUTPUT,  
	@CurrencyId INT = 0 OUTPUT,
	@MasterUsername VARCHAR(30) = '' OUTPUT,  
	@UserName VARCHAR(30) = '' OUTPUT,    
	@SubAccID INT = 0, --Sub-AccountID,  
	@SubPageAccess VARCHAR(50) = '' OUTPUT,   
	@SubUserName VARCHAR(30) = '' OUTPUT,   
	@site VARCHAR(20) = '' OUTPUT,  
	@LoginTime DATETIME = null, --VARCHAR(50) = NULL,
	@Language VARCHAR(2) = 'E',  
	@isFirstLogin	BIT = 0 OUTPUT,
	@PwdExpiry		DATETIME = NULL OUTPUT,
	@ErrCode INT = 0 OUTPUT,  
	@ErrMsg NVARCHAR(4000) = '' OUTPUT,
	@IsNickname BIT = 0 OUTPUT,
	@NicknameLoginOnly BIT = 0 OUTPUT,
	@Nickname VARCHAR(50) = '' OUTPUT,
	@SecurityCode VARCHAR(50) = '' OUTPUT,
	@isForcedChangeSecurityCode BIT = 0 OUTPUT,
	@IsProtectedMode BIT = 0 OUTPUT,

	@LanguageUsage  VARCHAR(2) = '' OUTPUT
AS
	/*
	Created: 20200529@Johnson
	Task : verify login for indirect login account
	DB: DBCUST/CustDB

	Revisions:
		- 20200529@Johnson: initial sp [redmine: #132782]
		- 20210510@Eden: Enhancement for not relying on DB On_User [redmine: #154507]
		- 20210408@Tina: Lock account & indirect close account [redmine: #148600]
		- 20210824@Elodie: Implement Protection Code [Redmine: #160151]
		- 20220110@Eden: Saba Casino use DCS Setting [RedmineID: #164280]
		- 20230214@Helios: Enhance language part [RedmineID: #183700]

	Param's Explanation:		
	*/
BEGIN

	SET NOCOUNT ON

	DECLARE @Begin DATETIME, @End DATETIME, @Duration INT, @inputLoginIP VARCHAR(15)
	DECLARE @LogData NVARCHAR(200), @role NVARCHAR(20), @db_currency TINYINT, @db_loginip NVARCHAR(20), @rowcount INT
			,@DownlineUsername VARCHAR(30) = @username
			
	SET @Begin = GETDATE() 
	SELECT @inputLoginIP = @LoginIP 	
	SET @ServerID = 0 

	SELECT @RoleID = RoleID 
	FROM customer c WITH (NOLOCK) 
	WHERE CustID = @CustID
	
	IF (@SubAccID = 0
		AND EXISTS (SELECT 1 
					FROM custinfo ci WITH(NOLOCK) 
						INNER JOIN CustProductStatus ps WITH (NOLOCK) ON ci.custid = ps.CustID
					WHERE ci.custid = @custid
						AND (ps.CloseInfo > 0 OR enabled = 0))
		) 
		OR (@SubAccID > 0
			AND EXISTS (SELECT 1 FROM custsub WITH(NOLOCK) 
						WHERE SubAccID = @SubAccID 
							AND closed = 1
						)
			)
	BEGIN
		SELECT @LogData = 'From account: ' + @UplineUsername + ' - To account: ' + @DownlineUsername + ' Login Result:Failed(Account_Closed)'
				
		SET @End = GETDATE()
		SET @Duration = DATEDIFF(millisecond,@Begin,@End)		

		EXEC dbo.Acc_WriteLog_UserLog_Login_Wrapper
			@UserID = @CustID, 
			@RoleID = @RoleID, 
			@SubAccID = @SubAccID,
			@ServerID = @ServerID,
			@LoginIP = @inputLoginIP,
			@DomainName = @LoginDomain,	
			@ActionID = 1337,
			@Doing = @LogData,
			@BrowserName = @BrowserName,
			@Platform = @Platform,
			@CountryCode = @CountryCode,
			@Duration = @Duration
			
		SELECT @ErrMsg = CASE @Language WHEN 'E' THEN 'Account closed. Please contact your administrator!'  
								ELSE [dbo].[f_Get_MsgNamebyMsgID](80002,@Language) 
							END ,@ErrCode=108    				
		RETURN	
	END
	ELSE IF(@SubAccID = 0
		AND EXISTS (SELECT 1 FROM CustProductStatus WITH(NOLOCK) WHERE custid = @custid AND ISNULL(Locked,0) > 0))	
	BEGIN
		SELECT @LogData = 'From account: ' + @UplineUsername + ' - To account: ' + @DownlineUsername + ' Login Result:Failed(Account_Locked)'
				
		SET @End = GETDATE()
		SET @Duration = DATEDIFF(millisecond,@Begin,@End)		

		EXEC dbo.Acc_WriteLog_UserLog_Login_Wrapper
			@UserID = @CustID, 
			@RoleID = @RoleID, 
			@SubAccID = @SubAccID,
			@ServerID = @ServerID,
			@LoginIP = @inputLoginIP,
			@DomainName = @LoginDomain,	
			@ActionID = 1337,
			@Doing = @LogData,
			@BrowserName = @BrowserName,
			@Platform = @Platform,
			@CountryCode = @CountryCode,
			@Duration = @Duration
			
		SELECT @ErrMsg = CASE @Language WHEN 'E' THEN 'This account is locked, please unlock it and try again.'  
								ELSE [dbo].[f_Get_MsgNamebyMsgID](40057,@Language) 
							END ,@ErrCode=109    				
		RETURN
	END
	
	IF NOT EXISTS (SELECT 1 FROM CustInDirectLogin WITH(NOLOCK)
					WHERE custid = @UplineCustid
						AND SubAccID = @UplineSubAccID
						AND CustIDIndirect = @custid
						AND SubAccIDIndirect = @subAccID
				)
	BEGIN
		SELECT @LogData = 'From account: ' + @UplineUsername + ' - To account: ' + @DownlineUsername + ' Login Result:Failed(Invalid_Indirect_Login_Account)'
				
		SET @End = GETDATE()
		SET @Duration = DATEDIFF(millisecond,@Begin,@End)		

		EXEC dbo.Acc_WriteLog_UserLog_Login_Wrapper
			@UserID = @CustID, 
			@RoleID = @RoleID, 
			@SubAccID = @SubAccID,
			@ServerID = @ServerID,
			@LoginIP = @inputLoginIP,
			@DomainName = @LoginDomain,	
			@ActionID = 1337,
			@Doing = @LogData,
			@BrowserName = @BrowserName,
			@Platform = @Platform,
			@CountryCode = @CountryCode,
			@Duration = @Duration
			
		SELECT @ErrMsg = CASE @Language 
				WHEN 'E' THEN 'Invalid account or it is not your downline.'
				ELSE [dbo].[f_Get_MsgNamebyMsgID](40052,@Language)
			END	,@ErrCode=101		
		RETURN	
	END
	
	IF ISDATE(@LoginTime) = 0 OR DATEDIFF(SECOND, @LoginTime, CURRENT_TIMESTAMP) > 10
	BEGIN
		SELECT @LogData = 'From account: ' + @UplineUsername + ' - To account: ' + @DownlineUsername + ' Login Result:Failed(Session_Expired)'
		-- ***Check Sub-Account***  
		
		SET @End = GETDATE()
		SET @Duration = DATEDIFF(millisecond,@Begin,@End)		

		EXEC dbo.Acc_WriteLog_UserLog_Login_Wrapper
			@UserID = @CustID, 
			@RoleID = @RoleID, 
			@SubAccID = @SubAccID,
			@ServerID = @ServerID,
			@LoginIP = @inputLoginIP,
			@DomainName = @LoginDomain,	
			@ActionID = 1337,
			@Doing = @LogData,
			@BrowserName = @BrowserName,
			@Platform = @Platform,
			@CountryCode = @CountryCode,
			@Duration = @Duration

		SELECT @ErrMsg = CASE @Language WHEN 'E' THEN 'Login error! Session expired.'  
				ELSE [dbo].[f_Get_MsgNamebyMsgID](80005,@Language) END , @ErrCode=105    

		RETURN    
	END
		
	IF @SubAccID > 0
	BEGIN
		SELECT 
			@SubUserName = username, 
			@CustID = custid,			 
			@SubPageAccess = PageAccess
		FROM custSub WITH (NOLOCK)
		WHERE subaccid = @SubAccID

		IF @@ROWCOUNT = 0  
		BEGIN
			SELECT @LogData = 'From account: ' + @UplineUsername + ' - To account: ' + @DownlineUsername +' Login Result: Failed(User_Not_Found)'      
			EXEC dbo.Acc_WriteLog_UserLog_Login_Wrapper
				@UserID = 0, 
				@RoleID = @RoleID, 
				@SubAccID = @SubAccID,
				@ServerID = @ServerID,
				@LoginIP = @inputLoginIP,
				@DomainName = @LoginDomain,
				@ActionID = 1337,
				@Doing = @LogData,
				@BrowserName = @BrowserName,
				@Platform = @Platform,
				@CountryCode = @CountryCode
								
			SELECT @ErrMsg = CASE @Language WHEN 'E' THEN  'Wrong username/nickname or password.' 
						ELSE [dbo].[f_Get_MsgNamebyMsgID](80001,@Language)   
						END ,@ErrCode=106   
			RETURN    
		END
	END
		
	SELECT 
		@RoleID = roleid, 
		@db_currency = currency, 
		@site = site , 
		@db_loginip= ISNULL(iplogin, ''), 
		@UserName = username
	FROM 
		customer WITH (NOLOCK)
	WHERE 
		custid = @CustID

	SET @rowcount = @@ROWCOUNT

	SELECT @ServerID = CASE WHEN @roleid=2 THEN 90 WHEN @roleid=3 THEN 91 WHEN @roleid = 4 THEN 92 ELSE 93 END -- login from web

	-- user not found  
	IF @rowcount = 0  
	BEGIN  
		SELECT @LogData = 'From account: ' + @UplineUsername + ' - To account: ' + @DownlineUsername + ' Login Result:Failed(User_Not_Found)' 
		
		EXEC dbo.Acc_WriteLog_UserLog_Login_Wrapper
			@UserID = @CustID, 
			@RoleID = @RoleID, 
			@SubAccID = @SubAccID,
			@ServerID = @ServerID,
			@LoginIP = @inputLoginIP,
			@DomainName = @LoginDomain,
			@ActionID = 1337,
			@Doing = @LogData,
			@BrowserName = @BrowserName,
			@Platform = @Platform,
			@CountryCode = @CountryCode		
				
		SELECT @ErrMsg = CASE @Language WHEN 'E' THEN  'Wrong username/nickname or password.' 
					ELSE [dbo].[f_Get_MsgNamebyMsgID](80001,@Language)  
					END ,@ErrCode=106  
		RETURN  
	END 
	  
	-- Successful  
	SELECT 
		@Currency = Currency, 
		@CurrencyId = @db_currency 
	FROM 
		exchange WITH (NOLOCK) 
	WHERE exchangeid = @db_currency  

	IF @RoleID = 2  
		SELECT @MasterUsername = LOWER(username) FROM customer (NOLOCK) WHERE custid = (SELECT mrecommend FROM customer (NOLOCK) WHERE custid = @CustID)  
	ELSE IF @RoleID = 3  
		SELECT @MasterUsername = LOWER(@UserName)  
	ELSE IF @RoleID = 4  
		SELECT @MasterUsername = NULL  

/*
	GET ON_USER_AGENT INFO - CHECK (SECOND LOGIN) - (FIRST LOGIN) < 5 RETURN 
*/
	DECLARE	@1stLoginTime DATETIME

	EXEC Age_OnUser_Agent_LoginTime_Sel_Wrapper @CustID = @CustID, @SubAccID = @SubAccID, @LoginTime = @1stLoginTime OUTPUT
		
	IF DATEDIFF(SECOND, @1stLoginTime, CURRENT_TIMESTAMP)< 5
	BEGIN 		
		SELECT @LogData =  'From account: ' + @UplineUsername + ' - To account: ' + @DownlineUsername + ' Login Result:Failed(Unknown_Login)'	
			
		EXEC dbo.Acc_WriteLog_UserLog_Login_Wrapper
			@UserID = @CustID, 
			@RoleID = @RoleID, 
			@SubAccID = @SubAccID,
			@ServerID = @ServerID,
			@LoginIP = @inputLoginIP,
			@DomainName = @LoginDomain,	
			@ActionID = 1337,
			@Doing = @LogData,
			@BrowserName = @BrowserName,
			@Platform = @Platform,
			@CountryCode = @CountryCode,
			@Duration = @Duration
			
		SELECT @ErrMsg = CASE @Language WHEN 'E' THEN 'Login error! Session expired.'  
				ELSE [dbo].[f_Get_MsgNamebyMsgID](80005,@Language)
			END , @ErrCode=107    
		RETURN
	END 	
	  
	SELECT @LogData = 'From account: ' + @UplineUsername + ' - To account: ' + @DownlineUsername + ' Login Result:Success'  

	----------------------------------
	--**Output LoginIP to check the first login**
	SELECT @LoginIP=ISNULL(@db_loginip, '')

	IF @SubAccID > 0 
	BEGIN
		SELECT	 @isFirstLogin	= ISNULL(isFirstLogin,0)
				,@PwdExpiry		= PwdExpiry
				,@securitycode	= ISNULL(SecurityCode,'')
				,@isForcedChangeSecurityCode = ISNULL(isForcedChangeSecurityCode,0)
				,@LanguageUsage = CASE WHEN ISNULL(LanguageUsage , '') = '' THEN '' ELSE LanguageUsage END -- LanguageUsage in CustLoginInfoSub Is Exists or Not
		FROM	CustLoginInfoSub WITH (NOLOCK)
		WHERE	SubAccID = @SubAccID AND CustID = @CustID
		
		SELECT @IsProtectedMode = ISNULL(IsProtectedMode,0)
		FROM	CustLoginInfo WITH (NOLOCK)
		WHERE	CustID = @CustID

		SELECT @NicknameLoginOnly = NicknameLoginOnly,
			@Nickname = username2,
			@IsNickname = CASE WHEN ISNULL(username2,'') = '' THEN 0 ELSE 1 END
		FROM dbo.custSub WITH (NOLOCK) 
		WHERE subaccid = @SubAccID  		
	END
	ELSE 
	BEGIN
		SELECT	@isFirstLogin	= ISNULL(isFirstLogin,0),
				@securityCode	= ISNULL(SecurityCode,''),
				@isForcedChangeSecurityCode = ISNULL(isForcedChangeSecurityCode,0),
				@IsProtectedMode = ISNULL(IsProtectedMode,0),
				@LanguageUsage = CASE WHEN ISNULL(LanguageUsage , '') = '' THEN '' ELSE LanguageUsage END -- LanguageUsage in CustLoginInfoSub Is Exists or Not
		FROM	CustLoginInfo WITH (NOLOCK)
		WHERE	CustID = @CustID
		
		SELECT	@PwdExpiry	= PwdExpiry,
				@Nickname = username2,
				@IsNickname = CASE WHEN ISNULL(username2,'') = '' THEN 0 ELSE 1 END
		FROM	Customer WITH (NOLOCK)
		WHERE	CustID = @CustID
		
		IF @RoleID = 2  
			SELECT @NicknameLoginOnly = NicknameLoginOnly FROM CustAgent WITH (NOLOCK) WHERE CustID = @CustID   
		ELSE IF @RoleID = 3  
			SELECT @NicknameLoginOnly = NicknameLoginOnly FROM CustMaster WITH (NOLOCK) WHERE CustID = @CustID  
		ELSE IF @RoleID = 4  
			SELECT @NicknameLoginOnly = NicknameLoginOnly FROM CustSuper WITH (NOLOCK) WHERE CustID = @CustID 
	END
	
	IF @SubAccID = 0
	BEGIN
		UPDATE customer WITH (ROWLOCK, UPDLOCK)  
		SET logincount = 0, lastlogged = CURRENT_TIMESTAMP 
		WHERE custid = @CustID
	END
	ELSE 
	BEGIN 
		UPDATE custsub WITH(UPDLOCK,ROWLOCK)
		SET logincount = 0
		WHERE subAccID = @SubAccID
		
		UPDATE customer WITH (ROWLOCK, UPDLOCK)  
		SET lastlogged = CURRENT_TIMESTAMP 
		WHERE custid = @CustID
	END
	
	SET @End = GETDATE()
	SET @Duration = DATEDIFF(millisecond,@Begin,@End)
	--------------------------- 
	EXEC dbo.Acc_WriteLog_UserLog_Login_Wrapper
			@UserID = @CustID, 
			@RoleID = @RoleID, 
			@SubAccID = @SubAccID,
			@ServerID = @ServerID,
			@LoginIP = @inputLoginIP,
			@DomainName = @LoginDomain,	
			@ActionID = 1337,
			@Doing = @LogData,
			@BrowserName = @BrowserName,
			@Platform = @Platform,
			@CountryCode = @CountryCode,
			@Duration = @Duration		
END	
