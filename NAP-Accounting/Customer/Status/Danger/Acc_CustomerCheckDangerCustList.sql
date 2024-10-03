/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap" viewers="" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerCheckDangerCustList]
    @UsernameList	VARCHAR(MAX) = '',  --List of provided usernames
    @UserID			INT, --Custid of viewer 
	@AdName			VARCHAR(30), -- UserID's username
    @DangerType     TINYINT = 0,
    @DangerLevel    INT = 0,
	@IP             VARCHAR(15) = '',
    @ErrCode        INT = 0             OUTPUT,
    @ErrMsg			NVARCHAR(MAX) = ''  OUTPUT,
	@Permission		VARCHAR(20) = '1,2,3',
	@DeniedList	NVARCHAR(MAX)=NULL

AS
SET NOCOUNT ON
/*
Created: 
Task : Validate list of username
DB: DBCUST/CUSTDB
Original:

Revisions:  
    - 20200511@Tiara: Enhance validation and error message [Redmine: #129306]
    - 20210519@Winfred: Remove constraints update range 41-50 of Dangerous Setting [Redmine: #155280]
	- 20220614@Eden: DBCUST - modify sp syntax to adapt with the SQL Server upgrade to 2019 [Redmine: #171831] 
    - 20240229@Winfred: NAP - Edit Dangerous : Cannot update danger level with range [41->46] [Redmine: #201482]
	- 20240816@Tacy: Remove linked-server/cross-db on NAP_UserControl [redmineID: #208402]
Param's Explanation:
    @UsernameList: List usernames of members will be submited

	@Permission: 1 ~ Credit sites
				 2 ~ Deposit sites
				 3 ~ SmartPunter

*/      

BEGIN
	SET NOCOUNT ON;

    DECLARE @CustId INT

    SET @ErrCode=0

    DECLARE @tmpCust TABLE (        
                      UserName				NVARCHAR(50)                    
                    , CustID                INT
                    , recommend             INT
                    , RoleID                TINYINT
                    , IsSpecialSite         BIT
                    , IsSpecialHeadline     BIT
                    , Site					NVARCHAR(50) 
                    , Currency				INT
                    , IsEnable              BIT
                    , IsView                BIT
                    , IsSmartPunter         BIT
                    , IsAllowAccess         BIT
                    , RowNum                INT IDENTITY (1,1)
                    ,   PRIMARY KEY CLUSTERED (UserName)
                    );

     -- select @ErrorCode=100: Invalid usernames: overlength
    IF EXISTS (SELECT TOP 1 1	
				FROM STRING_SPLIT(@UsernameList, ',') AS ss 
				WHERE LEN(TRIM(VALUE))>50)
    BEGIN
        SELECT @ErrCode=100
        SELECT @ErrMsg= 'Username '+    STUFF((
                SELECT ',' + TRIM(VALUE)  
                FROM STRING_SPLIT(@UsernameList, ',') AS ss 
				WHERE LEN(TRIM(VALUE))>50
                FOR XML PATH('')
            ), 1,1,'')+' do(es) not exist.' 
        RETURN
    END

    --Get list Username
    INSERT INTO @tmpCust(UserName)
    SELECT DISTINCT ss.value  
    FROM STRING_SPLIT(@UsernameList, ',') AS ss 
	WHERE value <> ''

	-- get custid, roleid, enable, recommend
    UPDATE t
    SET t.CustID=c.custid,RoleID =c.roleid, IsEnable = isnull(enabled,0), recommend = c.recommend
    FROM @tmpCust t 
        INNER JOIN dbo.custInfo c WITH(NOLOCK) ON t.UserName=c.username
    
	--Get site, currency
    UPDATE t
    SET t.Site = c.site, t.Currency=c.currency
    FROM @tmpCust t 
        INNER JOIN dbo.Customer c WITH(NOLOCK) ON t.custid= c.custid
    
    -- select @ErrorCode=100: Invalid usernames: do not exists on system
    IF EXISTS(SELECT TOP 1 1 FROM @tmpCust WHERE CustID is NULL)
    BEGIN
        SELECT @ErrCode=100
        SELECT @ErrMsg= 'Username '+    STUFF((
                SELECT ',' + UserName  
                FROM @tmpCust 
                WHERE CustID IS NULL
                FOR XML PATH('')
            ), 1,1,'')+' do(es) not exist.' 
        RETURN
    END
    --Check disable user
    IF EXISTS(SELECT TOP 1 1 FROM @tmpCust WHERE IsEnable = 0)
    BEGIN
        SELECT @ErrCode=101
        SELECT @ErrMsg= 'Username '+    STUFF((
                SELECT ',' + UserName  
                FROM @tmpCust 
                WHERE IsEnable = 0
                FOR XML PATH('')
            ), 1,1,'')+' was (were) disabled.' 
        RETURN
    END
    -- select @ErrorCode=106: Invalid usernames: do not exists on system
    IF EXISTS(SELECT TOP 1 1 FROM @tmpCust WHERE RoleID = 0)
    BEGIN
        SELECT @ErrCode=106
        SELECT @ErrMsg= 'You cannot update dangerous level for Headline account(s) '+   STUFF((
                SELECT ',' + UserName  
                FROM @tmpCust 
                WHERE RoleID = 0
                FOR XML PATH('')
            ), 1,1,'')
        RETURN
    END
    --end

    --Check permission for account site
	DECLARE @tmpSite TABLE (siteid INT,site NVARCHAR(50), SpecialGroup TINYINT )
	DECLARE @tmpExchange TABLE (exchangeID INT, Currency NVARCHAR(50), OfferSite TINYINT)

	IF ISNULL(@DeniedList,'')<>''
	BEGIN
		--get deny site
		INSERT INTO @tmpSite (siteid, site, SpecialGroup)
		SELECT vl.[ID], vl.[Name], vl.[Opt]
		FROM OPENJSON(@DeniedList) 
				WITH (  [KeyName]	VARCHAR(30),
						[Value]	NVARCHAR(MAX) AS JSON
					) AS js
		CROSS APPLY OPENJSON (js.[value])
				WITH (  [ID]	INT,
						[Name]	NVARCHAR(30),
						[Opt]	TINYINT
					) AS vl
		WHERE js.[KeyName]='Site'
	
		--get deny currency
		INSERT INTO  @tmpExchange (exchangeID, Currency, OfferSite)
		SELECT vl.[ID], vl.[Name], vl.[Opt]
		FROM OPENJSON(@DeniedList) 
				WITH (  [KeyName]	VARCHAR(30),
						[Value]	NVARCHAR(MAX) AS JSON
					) AS js
		CROSS APPLY OPENJSON (js.[value])
				WITH (  [ID]	INT,
						[Name]	NVARCHAR(30),
						[Opt]	TINYINT
					) AS vl
		WHERE js.[KeyName]='Exchange'
	END

	INSERT INTO @tmpSite (SiteId, Site)
	SELECT
		s.siteid,
		s.site
	FROM Site s WITH (NOLOCK)
	WHERE NOT EXISTS (SELECT 1 FROM @tmpSite WHERE SiteId = s.siteid)
		AND ((s.isLicensee = 0									-- Don't have Credit sites permission
				AND s.site <> 'cn88'
				AND ',' + @Permission + ',' NOT LIKE '%,1,%')
			OR (s.isLicensee = 1								-- Don't have Deposit sites permission
				AND s.site <> 'cn88'
				AND ',' + @Permission + ',' NOT LIKE '%,2,%'))

    --Check permission on site/currency
    IF EXISTS (SELECT TOP 1 1
				FROM @tmpCust T
				WHERE t.Site IN (SELECT s.site FROM @tmpSite s)
					OR t.Currency IN (SELECT e.exchangeID FROM @tmpExchange e))
    BEGIN
        SELECT @ErrCode=102
        SELECT @ErrMsg = 'You are not authorized to view account '
						+ STUFF ((
									SELECT ',' + UserName  
									FROM @tmpCust T
									WHERE t.Site IN (SELECT s.site FROM @tmpSite s)
										OR t.Currency IN (SELECT e.exchangeID FROM @tmpExchange e)
									FOR XML PATH('')
								), 1,1,'')
        RETURN
    END
    
    --Check special FI permission
    DECLARE @CheckFIPermission TABLE (IsView BIT)
    DECLARE @Username NVARCHAR (50), @i INT = 1, @Count INT
    SELECT @Count =  COUNT(*) FROM @tmpCust
    WHILE (@i < = @Count)
    BEGIN
        SELECT TOP 1 @Username = UserName
        FROM @tmpCust
        WHERE RowNum = @i
        
        INSERT INTO @CheckFIPermission (IsView)
        EXEC Acc_SelFIPermission @UserID = @UserID, @username= @Username, @CheckCustId=1
            
        UPDATE t
        SET t.IsView = CH.IsView
        FROM @tmpCust t 
        CROSS JOIN @CheckFIPermission CH
        WHERE T.UserName = @Username

        SELECT @i = @i + 1
    END

    IF EXISTS(SELECT TOP 1 1 FROM @tmpCust WHERE IsView = 0)
    BEGIN
        SELECT @ErrCode=102
        SELECT @ErrMsg= 'Username '+    STUFF((
                SELECT ',' + UserName  
                FROM @tmpCust 
                WHERE IsView = 0
                FOR XML PATH('')
            ), 1,1,'')+' is (are) special finance account(s).' 
        RETURN
    END

	--Check Is Allow access 
    Set @i = 1
    DECLARE @IsAllowAccess BIT
    WHILE (@i < = @Count)
    BEGIN
        SELECT TOP 1 @Username = UserName, @CustID = CustID
        FROM @tmpCust
        WHERE RowNum = @i
        
        EXEC Acc_CustomerIsAllowedAccess @Userid = @UserId, @username=@AdName, @DeniedList=@DeniedList, @CustName = @username, @CustID= @CustID, @CheckCustId=1, @ErrCode = @ErrCode OUTPUT, @ErrMsg = @ErrMsg OUTPUT
            
        UPDATE t
        SET t.IsAllowAccess= CASE WHEN (@ErrCode = 0 OR @ErrCode IS NULL) THEN 1 ELSE 0 END 
        FROM @tmpCust t 
        WHERE T.UserName = @Username

        SELECT @i = @i + 1
    END

    IF EXISTS(SELECT TOP 1 1 FROM @tmpCust WHERE IsAllowAccess = 0)
    BEGIN
        SELECT @ErrCode=103
        SELECT @ErrMsg= 'You are not authorized to view account '+  STUFF((
                SELECT ',' + UserName  
                FROM @tmpCust 
                WHERE IsAllowAccess = 0
                FOR XML PATH('')
            ), 1,1,'')
        RETURN
    END

    IF (',' + @Permission + ',' NOT LIKE '%,3,%')  --Skip this check if user can view smart punter accounts
    BEGIN
        --Check Is Smart Punter
        Set @i = 1
        DECLARE @IsSmartPunter BIT
        WHILE (@i < = @Count)
        BEGIN
            SELECT TOP 1 @Username = UserName, @CustId = @CustId
            FROM @tmpCust
            WHERE RowNum = @i
        
            EXEC Acc_CustomerSelCheckSmartPunter  @Custid = @CustId,@Username = @Username, @IsSmartPunter = @IsSmartPunter OUTPUT, @UserId = @UserId,@IsRestricted=0, @ActionID=0,@IP = @IP
            
            UPDATE t
            SET t.IsSmartPunter= ISNULL(@IsSmartPunter,0)
            FROM @tmpCust t 
            WHERE T.UserName = @Username

            SELECT @i = @i + 1
        END
    END
    
    IF EXISTS(SELECT TOP 1 1 FROM @tmpCust WHERE IsSmartPunter = 1)
    BEGIN
        SELECT @ErrCode=103
        SELECT @ErrMsg= 'You are not authorized to view account '+  STUFF((
                SELECT ',' + UserName  
                FROM @tmpCust 
                WHERE IsSmartPunter = 1
                FOR XML PATH('')
            ), 1,1,'')
        RETURN
    END

    --end
    --Do not allow to update danger level 41->45 for danger type 1 --50
    --IF @DangerType = 1 AND @DangerLevel BETWEEN 41 AND 46 --50
    --BEGIN   
    --    SELECT  @ErrMsg = 'You are not authorized to update danger level with range [41->46]', --50
    --            @ErrCode = 102
    --    RETURN  
    --END
    --Do not allow deposit accounts to update Super and Master danger level
    IF EXISTS (SELECT 1
                FROM Customer C WITH (NOLOCK)
                INNER JOIN @tmpCust T ON T.CustID = C.custid 
                INNER JOIN Site S WITH (NOLOCK) ON  C.site = S.site
                WHERE S.isLicensee = 1 AND C.custid = t.CustID AND T.roleid IN (3,4))
        
    BEGIN
        DECLARE @ErrMsg1 NVARCHAR(200), @ErrMsg2 NVARCHAR(200)
        SELECT @ErrCode=105

        SELECT  @ErrMsg1 = 'You cannot update dangerous level for Super accounts '+ STUFF((
                SELECT ',' + T.UserName  
                FROM @tmpCust T
                INNER JOIN Customer C WITH (NOLOCK) ON C.custid = T.CustID
                INNER JOIN Site S WITH (NOLOCK) ON  C.site = S.site
                WHERE S.isLicensee = 1 AND T.RoleID = 4
                FOR XML PATH('')
            ), 1,1,'') 
        
        SELECT @ErrMsg2 = 'Master accounts ' +  STUFF((
                SELECT ',' + T.UserName  
                FROM @tmpCust T
                INNER JOIN Customer C WITH (NOLOCK) ON C.custid = T.CustID
                INNER JOIN Site S WITH (NOLOCK) ON  C.site = S.site
                WHERE S.isLicensee = 1 AND T.RoleID = 3
                FOR XML PATH('')
            ), 1,1,'')  

        SELECT @ErrMsg = ISNULL(@ErrMsg1,'You cannot update dangerous level for  ') + ISNULL(@ErrMsg2,'')
        RETURN
    END
END
GO