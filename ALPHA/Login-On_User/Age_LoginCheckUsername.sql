/*<info serverAlias="DBCUST-CustDB" executers="wsv_alp, wsv_alpv" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE Age_LoginCheckUsername
	@UserName VARCHAR(50),  
	@CustID INT = 0 OUTPUT, 
	@SubAccID INT = 0 OUTPUT, --Sub-AccountID,  
	@LoginIP VARCHAR(20)= '',
	@LoginDomain NVARCHAR(253),
	@SiteGroup VARCHAR(10) = 'ALL',
	@IsNickname BIT = 0 OUTPUT,
	@NickName VARCHAR(50) = '' OUTPUT,
	@Site 	VARCHAR(10) = '' OUTPUT,
	@SiteID INT = 0 OUTPUT,
	@RoleID TINYINT = 0 OUTPUT
AS
/*
	Created by: Elodie
	Date: 2024-12-20
	Task: Check Username is valid
	DB: DBCUST/CustDB

	Revisions:
		- 20241220@Elodie: Initial SP [Redmine: #215625]
		
	Param's Explanation: 
	• @SiteGroup: Check the site and corresponding domain
		+ ALL: All add domains 
		+ 789y: Allow customers of 789y ONLY
		+ CN88:	Allow customers of CN88 ONLY
		+ IBCIndo: Allow customers of IBCIndo ONLY
		+ IBCBET | Others: Allow all customers except 789y, CN88, IBCIndo
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @IsSubAccount BIT, @closed BIT, @inputLoginIP VARCHAR(15),
		@db_custid INT, @db_loginip NVARCHAR(20), @db_enabled BIT, @db_currency tinyint,
		-- For checking login domain
		@IsMatched BIT, @rowcount INT, @isAllowed BIT, @IsAccess BIT,
		@Locked TINYINT

	SELECT @inputLoginIP = @LoginIP		
	SELECT @isAllowed = 0
		
	------- START: Thien@20130420: Prevent hacking from Viettel IPs ---
	IF @LoginIP IN ('210.211.126.116', '115.84.183.21', '115.78.129.42', '117.7.123.40', '210.211.126.71', '210.211.125.25', '101.99.3.227', '210.211.126.81',
					'117.7.97.115', '115.84.182.37', '115.78.129.42', '210.211.126.117', '115.84.183.11', '115.84.182.241', '210.211.126.199', '210.211.105.232',
					'210.211.120.18', '210.211.120.22', '210.211.120.23', '210.211.125.45', '117.7.109.98', '117.7.113.19', '117.7.119.52', '115.84.182.36',
					'117.7.112.247', '117.7.99.153', '117.2.217.87', '210.211.122.27', '117.3.169.84', '210.211.126.242', '210.211.125.215', '115.77.201.21',
					'171.237.114.124', '42.119.12.181', '210.211.122.6', '210.211.125.212', '117.3.169.84', '27.73.28.214')
		OR (@LoginIP like '210.211%'
		--or @LoginIP like '117.7%' or @LoginIP like '115.84%' or @LoginIP like '115.77%'
		)
		OR (@LoginDomain like '%ibc88.com%')
	BEGIN
		SELECT @CustID = 0, @SubAccID = 0
		RETURN
	END
	------- END: Thien@20130420: Prevent hacking from Viettel IPs ---

	-----Begin login using Sub account
	DECLARE @SubNicknameLoginOnly BIT, @db_Username2 VARCHAR(50) = @UserName
	SET @SubNicknameLoginOnly = 0

	IF EXISTS (SELECT 1 FROM custsub WITH (NOLOCK) WHERE username = @UserName OR UserName2 = @db_Username2)
		SET @IsSubAccount = 1
	ELSE
		SET @IsSubAccount = 0

	IF (@IsSubAccount = 1)
	BEGIN
		IF EXISTS (SELECT 1 FROM custsub AS c WITH (NOLOCK) WHERE UserName2 = @db_Username2)
		BEGIN
			----use nickname
			SELECT	@SubAccID = subaccid, @CustID = custid, @closed = closed,
					@Nickname = UserName2, @IsNickname = 1
			FROM custSub c WITH (NOLOCK)
			WHERE username2 = @db_Username2	

			SELECT @RoleID = roleid, @Site = c.site, @db_currency = currency, @SiteID=s.siteid
			FROM customer c WITH (NOLOCK)
				INNER JOIN Site s WITH (NOLOCK) ON s.site=c.site
			WHERE custid = @CustID

			SET @rowcount = @@ROWCOUNT	
		END
		ELSE
		BEGIN 			
			---check Nicknameloginonly
			SELECT @SubAccID = subaccid, @CustID = custid, @IsNickname = 0, @Nickname = UserName2, @SubNicknameLoginOnly = ISNULL(NicknameLoginOnly,0), @closed = closed
			FROM custsub with (nolock) 				
			WHERE username = @UserName				

			SELECT @RoleID = roleid, @Site = c.site, @db_currency = currency, @SiteID=s.siteid
			FROM customer c WITH (NOLOCK)
				INNER JOIN Site s WITH (NOLOCK) ON s.site=c.site 
			WHERE custid = @CustID

			SET @rowcount = @@ROWCOUNT

			IF @SubNicknameLoginOnly = 1 
			BEGIN  
				SELECT @CustID = 0, @SubAccID = 0
				RETURN  
			END  
		END
	-------end 20110608: login using Nickname
		-- check sub-account --
		
		-- Checking login domain and site
		IF(@rowcount <> 0)
		BEGIN
			EXECUTE @IsMatched = [dbo].[f_CheckAgentLoginDomain] @Site, @LoginDomain
			IF(@IsMatched = 0)
			BEGIN
				SELECT @CustID = 0, @SubAccID = 0
				RETURN
			END
			
			-- Check 789y or IBCBET Site 
			IF @SiteGroup <> 'ALL' 
			BEGIN
				EXEC dbo.Age_LoginCheckSiteGroup 
					@SiteGroup = @SiteGroup, 
					@Site = @Site,
					@isAllowed = @isAllowed OUTPUT
			
				IF @isAllowed = 0
				BEGIN
					SELECT @CustID = 0, @SubAccID = 0
					RETURN				
				END
			END
		END
		-- End Checking login domain
	    
		IF (@rowcount = 0)
		BEGIN
			SELECT @CustID = 0, @SubAccID = 0  
			RETURN    
		END
	          
		--Check grant access to AgentSite from outside throught test accounts	
		SELECT @IsAccess = 1
		EXEC Age_LoginCheckGrantAccess
			@CustID = @CustID,
			@LoginIP = @inputLoginIP,
			@CurrencyId = @db_currency,
			@IsAccess = @IsAccess OUTPUT

		IF @IsAccess = 0
		BEGIN
			SELECT @CustID = 0, @SubAccID = 0   
			RETURN  			 
		END

		-- Block all access from SMS office to login with real account
		IF @isAllowed = 0 AND @Site NOT IN ('12Bet', 'asiabet88', 'mansion88', 'alog', 'ispo', 'TLC','DELA','Spondemo')
		BEGIN
			SET @isAllowed = 1
			IF @db_currency <> 20 AND LEFT(@inputLoginIP, 10) = '202.78.228'
				SET @isAllowed = 0							
					
			IF (@IsAllowed = 0)
			BEGIN  
				SELECT @CustID = 0, @SubAccID = 0      
				RETURN  
			END 
		END
		------------------------
		
		--IF ISNULL(@Closed,1) = 1
		--BEGIN    
		--	SELECT @CustID = 0, @SubAccID = 0  
		--	RETURN    
		--END				

		--Get username, password from customer table to login in the context of agent    
		SELECT @db_custid = custid, @RoleID = roleid, @Site = c.site, @UserName = username,
			@db_loginip= ISNULL(iplogin, ''), @SiteID = s.siteid
		FROM customer c WITH (NOLOCK) 
			INNER JOIN Site s WITH (NOLOCK) ON s.site=c.site
		WHERE custid = @CustID    
			AND mrecommend <> 927780

	END
	----- end of login using Sub account
	ELSE
	BEGIN 
		----- begin 20110608: login using Nickname
		DECLARE @NicknameLoginOnly BIT 
		SET  @NicknameLoginOnly = 0

		IF EXISTS (SELECT 1 FROM customer AS c WITH (NOLOCK) WHERE c.username2 = @UserName)
		BEGIN
			----use nickname
			SELECT	@db_custid = custid, @RoleID = roleid, @db_currency = currency, 
					@site = c.site , @db_loginip= isnull(iplogin, ''), @Nickname = UserName2, @UserName = Username, @IsNickname = 1, @SiteID=s.siteid
			FROM customer c WITH (NOLOCK) 
				INNER JOIN Site s WITH (NOLOCK) ON s.site=c.site
			WHERE username2 = @UserName
					and mrecommend <> 927780

			SET @rowcount = @@ROWCOUNT		
		END
		ELSE
		BEGIN 
			---check Nicknameloginonly
			SELECT @db_custid = custid, @RoleID = roleid,  @IsNickname = 0 ,@Nickname = UserName2
			FROM customer with (nolock) 
			WHERE username = @UserName and mrecommend <> 927780
		
			IF @RoleID = 2  
				SELECT @NicknameLoginOnly = NicknameLoginOnly FROM CustAgent WITH (NOLOCK) WHERE CustID = @db_custid   
			ELSE IF @RoleID = 3  
				SELECT @NicknameLoginOnly = NicknameLoginOnly FROM CustMaster WITH (NOLOCK) WHERE CustID = @db_custid  
			ELSE IF @RoleID = 4  
				SELECT @NicknameLoginOnly = NicknameLoginOnly FROM CustSuper WITH (NOLOCK) WHERE CustID = @db_custid 

			IF @NicknameLoginOnly = 1 
			BEGIN  				
				SELECT @CustID = 0		
				RETURN 
			END  
			----use username
			SELECT @db_custid = custid, @RoleID = roleid, @db_currency = currency, 
					@site = c.site , @db_loginip= isnull(iplogin, ''),  @IsNickname = 0, @Nickname = UserName2, @SiteID=s.siteid
			FROM customer c WITH (NOLOCK) 
				INNER JOIN Site s WITH (NOLOCK) ON s.site=c.site
			WHERE username = @UserName
					and mrecommend <> 927780

			SET @rowcount = @@ROWCOUNT
		END
		-------end 20110608: login using Nickname
	END 

	-- Checking login domain and site
	IF(@rowcount <> 0)
	BEGIN
		EXEC @IsMatched = [dbo].[f_CheckAgentLoginDomain] @Site, @LoginDomain
		IF(@IsMatched = 0)
		BEGIN			
			SELECT @CustID = 0
			RETURN
		END

		-- Check 789y or IBCBET Site 
		IF @SiteGroup <>'ALL'   ---IN ('789y','IBCBET','Others')
		BEGIN
			EXEC dbo.Age_LoginCheckSiteGroup 
				@SiteGroup = @SiteGroup, 
				@Site = @Site,
				@isAllowed = @isAllowed OUTPUT

			IF @isAllowed = 0 
			BEGIN
				SELECT @CustID = 0 
				RETURN
			END 
		END
	END
	-- End Checking login domain

	-- user not found  
	IF (@rowcount = 0)
	BEGIN  
		SELECT @CustID = 0       
		RETURN  
	END 
		
	--Check grant access to AgentSite from outside throught test accounts	
	SELECT @IsAccess = 1
	EXEC Age_LoginCheckGrantAccess
		@CustID = @db_custid,
		@LoginIP = @inputLoginIP,
		@CurrencyId = @db_currency,
		@IsAccess = @IsAccess OUTPUT

	IF @IsAccess = 0
	BEGIN
		SELECT @CustID = 0    
		RETURN  
			 
	END

	--set serverID
	SELECT @CustID = @db_custid

	-- check condition  
	IF @RoleID NOT IN (2,3,4)
	BEGIN  
		SELECT @CustID = 0 
		RETURN  
	END  

	SELECT @db_enabled = ISNULL(enabled,0)
	FROM custinfo WITH (NOLOCK) WHERE custid = @db_custid

	SELECT @Locked = CASE WHEN @IsSubAccount = 1 THEN 0 ELSE CPS.Locked END, 
		@closed = CASE WHEN CloseInfo > 0 THEN 1 ELSE 0 END
	FROM CustProductStatus CPS WITH (NOLOCK)
	WHERE CPS.CustID = @db_custid
	
	IF @db_enabled <> 1
	BEGIN
		 SELECT @CustID = 0
		RETURN
	END
	  
	--IF ISNULL(@closed, 1) = 1
	--BEGIN  
	--	SELECT @CustID = 0 
	--	RETURN  
	--END
	--ELSE IF ISNULL(@Locked, 0) > 0
	--BEGIN  
	--	SELECT @CustID = 0 
	--	RETURN  
	--END  		
	-- Username valid  	
END