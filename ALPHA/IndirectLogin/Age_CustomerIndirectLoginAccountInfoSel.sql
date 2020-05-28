/*<info serverAlias="DBCUST-CustDB" executers="bodbDownlineNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CustomerIndirectLoginAccountInfoSel]
	@custid 	INT,
	@SubAccID INT = 0
AS	
/*
	Created: 20200527@Johnson
	Task : get status login info of indirect login account
	DB: DBCUST/CustDB

	Revisions:
		- 20200527@Johnson: initial sp [redmine:#133846]
	
	Parameter's explaination:		
*/		
BEGIN
	SET NOCOUNT ON
	
	DECLARE @LoginIP VARCHAR(20)='',  --- if output=NULL then account is the first login
			@ServerID INT ,
			@RoleID INT,  
			@Currency VARCHAR(10) = '',  
			@CurrencyId INT = 0,
			@MasterUsername VARCHAR(30) = '',  
			@UserName VARCHAR(30) = '',    			 
			@SubPageAccess VARCHAR(50) = '',   
			@SubUserName VARCHAR(30) = '',   
			@site VARCHAR(20) = '',  
			@isCasinoDisabled BIT = 0,
			@IsCasinoSync BIT = 0,			
			@isFirstLogin	BIT = 0,
			@PwdExpiry		DATETIME = NULL,					
			@NicknameLoginOnly BIT = 0,			
			@SecurityCode VARCHAR(50) = '',
			@isForcedChangeSecurityCode BIT = 0
	
	SELECT 
		@RoleID = roleid, 
		@currencyId = currency, 
		@site = site , 
		@loginip= ISNULL(iplogin, ''), 
		@UserName = username
	FROM customer WITH (NOLOCK)
	WHERE custid = @CustID	
	
	SELECT @ServerID = CASE WHEN @roleid=2 THEN 90 WHEN @roleid=3 THEN 91 WHEN @roleid = 4 THEN 92 ELSE 93 END -- login from web
	
	SELECT @Currency = Currency
	FROM exchange WITH (NOLOCK) 
	WHERE exchangeid = @currencyId
	
	IF @RoleID = 2  
		SELECT @MasterUsername = LOWER(username) FROM customer (NOLOCK) WHERE custid = (SELECT mrecommend FROM customer (NOLOCK) WHERE custid = @CustID)  
	ELSE IF @RoleID = 3  
		SELECT @MasterUsername = LOWER(@UserName)  
	ELSE IF @RoleID = 4  
		SELECT @MasterUsername = NULL 
		
	SELECT 
		@IsCasinoSync = SyncCasino, 
		@isCasinoDisabled = DisableCasino
	FROM custinfo WITH (NOLOCK) 
	WHERE custid = @CustID
	
	IF @SubAccID > 0 
	BEGIN
		SELECT	 @isFirstLogin	= ISNULL(isFirstLogin,0)
				,@PwdExpiry		= PwdExpiry
				,@securitycode	= ISNULL(SecurityCode,'')
				,@isForcedChangeSecurityCode = ISNULL(isForcedChangeSecurityCode,0)
		FROM	CustLoginInfoSub WITH (NOLOCK)
		WHERE	SubAccID = @SubAccID AND CustID = @CustID
		
		SELECT @NicknameLoginOnly = NicknameLoginOnly,
			@SubUserName = username, 					 
			@SubPageAccess = PageAccess
		FROM dbo.custSub WITH (NOLOCK) 
		WHERE subaccid = @SubAccID 
	END
	ELSE 
	BEGIN
		SELECT	@isFirstLogin	= ISNULL(isFirstLogin,0),
				@securityCode	= ISNULL(SecurityCode,''),
				@isForcedChangeSecurityCode = ISNULL(isForcedChangeSecurityCode,0)
		FROM	CustLoginInfo WITH (NOLOCK)
		WHERE	CustID = @CustID
		
		SELECT	@PwdExpiry	= PwdExpiry
		FROM	Customer WITH (NOLOCK)
		WHERE	CustID = @CustID
		
		IF @RoleID = 2  
			SELECT @NicknameLoginOnly = NicknameLoginOnly FROM CustAgent WITH (NOLOCK) WHERE CustID = @CustID   
		ELSE IF @RoleID = 3  
			SELECT @NicknameLoginOnly = NicknameLoginOnly FROM CustMaster WITH (NOLOCK) WHERE CustID = @CustID  
		ELSE IF @RoleID = 4  
			SELECT @NicknameLoginOnly = NicknameLoginOnly FROM CustSuper WITH (NOLOCK) WHERE CustID = @CustID 
	END
	
	SELECT @LoginIP 	as LoginIP,  --- if output=NULL then account is the first login
			@ServerID 	as ServerID ,
			@RoleID 	as RoleID,  
			@Currency 	as Currency,  
			@CurrencyId as CurrencyId,
			@MasterUsername as MasterUsername,  
			@UserName 	as UserName,    			 
			@SubPageAccess 	as SubPageAccess,   
			@SubUserName 	as SubUserName,   
			@site 		as site,  
			@isCasinoDisabled as isCasinoDisabled,
			@IsCasinoSync 	as IsCasinoSync,			
			@isFirstLogin 	as isFirstLogin,
			@PwdExpiry 	as PwdExpiry,					
			@NicknameLoginOnly as NicknameLoginOnly,			
			@SecurityCode 	as SecurityCode,
			@isForcedChangeSecurityCode as isForcedChangeSecurityCode
	
END	