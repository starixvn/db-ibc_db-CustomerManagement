/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[CS_CustomerSelByGroupHeadline]     
    @siteid VARCHAR(200)='329'
  , @currency INT = 0
  , @Active BIT
  , @ViewOnly BIT
  , @Suspended BIT
  , @Inactive BIT
  , @Disabled BIT
  , @roleid INT=0
  , @username VARCHAR(30) = ''
  , @groupheadline VARCHAR(30) = ''    
  , @Owner NVARCHAR(100) = ''
  , @HeadlineType VARCHAR(20) = ''
  , @IsTest BIT = 0
  , @Userid INT=NULL
AS    
    
/*    
    Created by: Winnie    
    Date: 2019-05-28   
    Task : GET customer by group headline  CN88
    DB: DBACC/bodb02    
    Original SP:
    Revisions:
        - 20190528@Winnie: NAP - Support CN88 Headline RedmineID: #112999
       		
    Example: 
	exec [CS_CustomerSelByGroupHeadline] @currency=0,@Active =1
	  , @ViewOnly =1
	  , @Suspended =1
	  , @Inactive =1
		, @Disabled =0,@roleid=0,@username=default,@groupheadline=default,@Owner='',@HeadlineType='1',@siteid='329'

*/    
BEGIN    
    SET NOCOUNT ON    
    
    DECLARE @tmp TABLE (siteid INT,site NVARCHAR(50), SpecialGroup TINYINT )
    DECLARE @tmpUserid VARCHAR(50)
    SELECT @tmpUserid=CAST(@Userid AS VARCHAR(50))

	DECLARE @SearchQuery varchar(1024)
	SELECT @SearchQuery = 'SELECT * 
	FROM OPENQUERY(DBPOL, 
	''SELECT siteid , site,SpecialGroup FROM NAP_UserControl.dbo.f_GetDeniedSiteByUser ( ''''' + @tmpUserid + ''''')'')'

	INSERT INTO  @tmp (siteid , site,SpecialGroup)
	EXECUTE(@SearchQuery)
    
  
    CREATE TABLE #tmpDirectCust 
    (
        CustID INT PRIMARY KEY
      , Site VARCHAR(50)
      , Currency INT
      , RoleID INT
	  , ClosedReason TINYINT NULL
    )

     CREATE TABLE #tmpGroupHeadline 
    (
        HeadlineID INT PRIMARY KEY
      , GroupName NVARCHAR(100)
      , GroupID SMALLINT 
      , HeadlineType TINYINT NULL
      , OwnerName NVARCHAR(100) NULL
      , OwnerID INT NULL
    )

    CREATE TABLE #tmpResult
    (
        CustHeadlineID INT
      , GroupName NVARCHAR(100)
      , CustID INT
      , UserName NVARCHAR(100)
      , Status TINYINT    
      , Site VARCHAR(50)
      , Currency INT
      , RoleID INT
      , HeadlineType TINYINT
      , OwnerName NVARCHAR(100)
	  , ClosedReason TINYINT NULL
	  
    )

    CREATE TABLE #tmpResultAll
    (
        CustHeadlineID INT
      , GroupName NVARCHAR(100)
      , CustID INT
      , UserName NVARCHAR(100)     
      , Site VARCHAR(50)
      , Currency INT
      , RoleID INT
      , HeadlineType TINYINT
      , OwnerName NVARCHAR(100)
	  , ClosedReason TINYINT NULL
	  , Enabled BIT
    )   
    
    --get super account     
    IF (@roleid = 0 OR @roleid = 4)    
    BEGIN     
		INSERT INTO #tmpDirectCust (custid, site, currency, roleid,ClosedReason)
        SELECT c.custid, c.site, c.currency, c.roleid,cl.ClosedReason
        FROM dbo.Customer c WITH(NOLOCK) 
			INNER JOIN dbo.CustSuper cs WITH(NOLOCK) ON c.custid = cs.custid AND cs.IsInternal = 0 AND c.roleid = 4   
			LEFT JOIN CustLoginInfo cl WITH(NOLOCK) ON c.custid=cl.CustID  
        WHERE (@currency = 0 OR c.currency = @currency)
            AND ((@IsTest = 0 AND c.currency NOT IN (20, 27, 28)) OR @IsTest = 1)
    END

    --get direct master    
    IF (@roleid = 0 OR @roleid = 3)    
    BEGIN     
        INSERT INTO #tmpDirectCust (custid, site, currency, roleid,ClosedReason)
        SELECT c.custid, c.site, c.currency, c.roleid ,cl.ClosedReason     
        FROM dbo.f_GetDirectAgency(4) a
            INNER JOIN dbo.Customer c WITH(NOLOCK) ON a.custid = c.custid
            INNER JOIN dbo.CustMaster cm WITH(NOLOCK) ON cm.custid = c.custid AND cm.isInternal = 0
			LEFT JOIN CustLoginInfo cl WITH(NOLOCK) ON c.custid=cl.CustID  
         WHERE (@currency = 0 OR c.currency = @currency)
            AND ((@IsTest = 0 AND c.currency NOT IN (20, 27, 28)) OR @IsTest = 1)
    END     
    
    --get direct agent    
    IF (@roleid = 0 OR @roleid = 2 )    
    BEGIN     
        INSERT INTO #tmpDirectCust (custid, site, currency, roleid,ClosedReason)
        SELECT c.custid, c.site, c.currency, c.roleid,cl.ClosedReason     
        FROM dbo.f_GetDirectAgency(3) a
            INNER JOIN dbo.Customer c WITH(NOLOCK) ON a.custid = c.custid
            INNER JOIN dbo.CustAgent ca WITH(NOLOCK) ON ca.custid = c.custid AND ca.IsInternal = 0  
			LEFT JOIN CustLoginInfo cl WITH(NOLOCK) ON c.custid=cl.CustID    
        WHERE (@currency = 0 OR c.currency = @currency)
            AND ((@IsTest = 0 AND c.currency NOT IN (20, 27, 28)) OR @IsTest = 1)
    END
    
    --get direct memeber    
    IF (@roleid = 0 OR @roleid = 1)    
    BEGIN     
        INSERT INTO #tmpDirectCust (custid, site, currency, roleid,ClosedReason   )
        SELECT c.custid, cc.site, c.currency, c.roleid ,cl.ClosedReason   
        FROM dbo.f_GetDirectAgency(2) a
            INNER JOIN dbo.Customer c WITH(NOLOCK) ON a.custid = c.custid
            INNER JOIN dbo.Customer cc WITH(NOLOCK) ON c.recommend = cc.custid 
			LEFT JOIN CustLoginInfo_Member cl WITH(NOLOCK) ON c.custid=cl.CustID       
        WHERE c.recommend NOT IN (    SELECT custid
                                    FROM dbo.CustAgent WITH(NOLOCK)
                                    WHERE IsInternal = 1)
           AND (@currency = 0 OR c.currency = @currency)
           AND ((@IsTest = 0 AND c.currency NOT IN (20, 27, 28)) OR @IsTest = 1)
    END
    
    --apply filter by site    
    DELETE #tmpDirectCust    
    WHERE (@siteid <> ''  AND     
      (site NOT IN (SELECT [site] FROM [site] WHERE siteid IN (SELECT  val FROM dbo.strSplit(@siteid,','))) OR site IS NULL)) 
       OR [site] NOT IN (SELECT [SITE] FROM [SITE] WHERE islicensee = 0 AND isactive=1)    
   
    --apply filter by Owner and Headline Type    
    INSERT INTO #tmpGroupHeadline(HeadlineID, GroupName, GroupID, HeadlineType, OwnerName)    
	SELECT hl.CustID, cu.username, hl.GroupID, hl.HeadlineType, hl.OwnerName
    FROM dbo.CustGroupHeadline hl WITH (NOLOCK)
        INNER JOIN dbo.custInfo cu WITH (NOLOCK) ON hl.CustID = cu.custid
	WHERE (@Owner = '' OR hl.OwnerName = @Owner) AND (@HeadlineType = '' OR hl.HeadlineType IN (SELECT val FROM dbo.strSplit(@HeadlineType, ',')))		

    INSERT INTO #tmpResultAll 
    SELECT  hl.HeadlineID Custheadlineid ,hl.GroupName groupname, ca.custid ,ci.username    
            ,d.site, d.currency, ci.roleid, hl.HeadlineType, ISNULL(hl.OwnerName,'') AS OwnerName,ISNULL(d.ClosedReason,0) AS ClosedReason,ci.Enabled 
    FROM custaccount ca WITH(NOLOCK)    
        INNER JOIN #tmpGroupHeadline hl WITH(NOLOCK) ON  hl.groupid = ca.groupid
        INNER JOIN custinfo ci WITH(NOLOCK) ON  ci.custid = ca.custid     
        INNER JOIN #tmpDirectCust d ON  d.custid = ca.custid      
    WHERE (@username = '' OR ci.username=@username) 
        AND (@groupheadline = '' OR hl.GroupName=@groupheadline)    
        AND hl.GroupID <> 0
    
    UNION ALL    
    SELECT  0 custheadlineid,'Not assigned to group' , c.custid ,ci.username,  
            c.site, c.currency, ci.roleid, hl.HeadlineType, ISNULL(hl.OwnerName, '') AS OwnerName,ISNULL(c.ClosedReason,0) AS ClosedReason,ci.Enabled 
    FROM #tmpDirectCust c    
        INNER JOIN custinfo ci WITH(NOLOCK) ON  ci.custid = c.custid     
        LEFT JOIN #tmpGroupHeadline hl WITH(NOLOCK) ON  ci.custid = hl.HeadlineID
	WHERE NOT EXISTS (SELECT 1 FROM custaccount ca WITH(NOLOCK) WHERE ca.custid = c.custid AND ca.groupID  <> 0) 
        AND (@username = '' OR ci.username=@username) 
        AND @groupheadline='' AND @HeadlineType = '' 
        AND (@Owner = '' OR (@Owner <> '' AND hl.OwnerName = @Owner))
	
	IF (@Disabled = 1)    
    BEGIN     
        INSERT INTO #tmpResult(CustHeadlineID, GroupName, CustID, UserName,Status, Site, Currency, RoleID, HeadlineType, OwnerName , ClosedReason)
        SELECT CustHeadlineID, GroupName, t.CustID, UserName,
		0 AS Status,	
		Site, Currency, RoleID, HeadlineType, OwnerName , ClosedReason    
        FROM #tmpResultAll t  			
        WHERE  t.Enabled=0 
    END    

    IF (@Inactive = 1)    
    BEGIN     
        INSERT INTO #tmpResult(CustHeadlineID, GroupName, CustID, UserName,Status, Site, Currency, RoleID, HeadlineType, OwnerName , ClosedReason   )
        SELECT CustHeadlineID, GroupName, t.CustID, UserName,
		1 AS Status,		
		Site, Currency, RoleID, HeadlineType, OwnerName , ClosedReason  
        FROM #tmpResultAll    t 
			CROSS APPLY dbo.f_CS_GetCustomerStatus(t.CustID) a			
        WHERE  a.CustStatus=1 AND t.Enabled=1
    END     


    
    IF (@suspended = 1)    
    BEGIN     
        INSERT INTO #tmpResult(CustHeadlineID, GroupName, CustID, UserName,Status, Site, Currency, RoleID, HeadlineType, OwnerName , ClosedReason)
        SELECT CustHeadlineID, GroupName, t.CustID, UserName,
		2 AS Status,		
		Site, Currency, RoleID, HeadlineType, OwnerName , ClosedReason
        FROM #tmpResultAll t  
			CROSS APPLY dbo.f_CS_GetCustomerStatus(t.CustID) a			
        WHERE   a.CustStatus=2  AND t.Enabled=1
    END     
    
    IF (@ViewOnly = 1)    
    BEGIN     
        INSERT INTO #tmpResult(CustHeadlineID, GroupName, CustID, UserName,Status, Site, Currency, RoleID, HeadlineType, OwnerName , ClosedReason)
        SELECT CustHeadlineID, GroupName, t.CustID, UserName,
		3 AS Status,		
		Site, Currency, RoleID, HeadlineType, OwnerName , ClosedReason 
        FROM #tmpResultAll  t 
			CROSS APPLY dbo.f_CS_GetCustomerStatus(t.CustID) a	
         WHERE   a.CustStatus=3  AND t.Enabled=1
    END     
    
    IF (@Active = 1)    
    BEGIN     
        INSERT INTO #tmpResult(CustHeadlineID, GroupName, CustID, UserName,Status, Site, Currency, RoleID, HeadlineType, OwnerName , ClosedReason)
        SELECT CustHeadlineID, GroupName, t.CustID, UserName,
		4 AS Status,		
		Site, Currency, RoleID, HeadlineType, OwnerName , ClosedReason
        FROM #tmpResultAll    t
			CROSS APPLY dbo.f_CS_GetCustomerStatus(t.CustID) a	
        WHERE  a.CustStatus=4  AND t.Enabled=1
    END     
    
    --resulset            
    SELECT r.*, e.currency AS CurrencyName
    FROM  #tmpResult r
        INNER JOIN dbo.Exchange e WITH (NOLOCK) ON r.Currency = e.exchangeid
        WHERE (@Userid IS NULL OR (@Userid IS NOT NULL AND site NOT IN (SELECT site FROM @tmp )))
    ORDER BY custheadlineid,Status DESC,custid

END

GO
GRANT EXECUTE ON [dbo].CS_CustomerSelByGroupHeadline TO [bodbAdminNet]
GO 
