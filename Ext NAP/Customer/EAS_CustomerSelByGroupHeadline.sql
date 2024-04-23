/*<info serverAlias="DBCUST-CustDB" executers="wsv_xnap" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_CustomerSelByGroupHeadline]     
     @UserName	VARCHAR(30)=''
	,@GroupHeadline	VARCHAR(30)=''
	,@Status	TINYINT=0
	,@GroupName	VARCHAR(100)
	,@UserID	INT
AS    
    
/*    
    Created by: Tacy@20240325
    Task : GET customer by group headline    
    DB: DBCUST-CustDB    
    
	Revisions:
        - 20240325@Tacy: Create SP [redmine: #202501]
		
	Param's Explanation:
		* @Status : 0 ~ All
					1 ~ Open
					2 ~ Suspended
					3 ~ Closed
					4 ~ Disabled
*/    
BEGIN    
    SET NOCOUNT ON ;

	--check user belong to ext group
	DECLARE @tblUserInfo TABLE 
	(
		UserID		INT
      , UserName	VARCHAR(30)
	  , firstname	NVARCHAR(50)
	  , lastname	NVARCHAR(50)
	  , GroupID		INT
	  , GroupName	VARCHAR(100)
	  , [Enabled]	BIT
	)

	INSERT INTO @tblUserInfo (UserID, UserName, firstname, lastname, GroupID, GroupName, [Enabled])
	EXEC DBPOL.NAP_UserControl.[dbo].[EAS_UserInfoSelByUserID] @UserID=@UserID

	IF NOT EXISTS (SELECT TOP 1 1 FROM @tblUserInfo WHERE GroupID IN (1,2)) AND
		NOT EXISTS (SELECT TOP 1 1 FROM @tblUserInfo WHERE GroupName=@GroupName)
		RETURN

	--Get special site
	DECLARE @DenySite TABLE (siteid INT, site NVARCHAR(50), SpecialGroup TINYINT)
	
	INSERT INTO  @DenySite (siteid, site, SpecialGroup)
	SELECT siteid, site, SpecialGroup 
	FROM NAP_UserControl.dbo.f_GetDeniedSiteByUser (@UserID)
	
	DECLARE @IsInternalAdmin BIT = 0
	
	EXEC dbo.Acc_CustomerIsInternalAdmin @Custid = @UserID, @IsInternalAdmin = @IsInternalAdmin OUTPUT	
	
	-----------------------------------------------------------------------------------------------------------------------
	-----------------------------------------------------------------------------------------------------------------------
    CREATE TABLE #tmpDirectCust 
    (
        CustID INT PRIMARY KEY
	  , ClosedReason TINYINT NULL
    )

    CREATE TABLE #tmpGroupHeadline 
    (
        CustHeadlineID	INT PRIMARY KEY
      , GroupHeadline	VARCHAR(30)
      , GroupHeadlineID	SMALLINT 
    )

    CREATE TABLE #tmpResult
    (
		CustHeadlineID	INT
      , GroupHeadline	VARCHAR(30)
      , CustID	 INT
      , UserName VARCHAR(30)
	  , IsSuspend BIT
      , IsClosed BIT
      , IsEnable BIT
	  , ClosedReason TINYINT NULL
    )

    CREATE TABLE #tmpResultAll
    (
		CustHeadlineID	INT
      , GroupHeadline	VARCHAR(30)
      , CustID	 INT PRIMARY KEY
      , UserName VARCHAR(30)
	  , IsSuspend BIT
      , IsClosed BIT
      , IsEnable BIT
	  , ClosedReason TINYINT NULL
    )    
    
    --get Direct account (direct account: not belong to any ext group)     
	INSERT INTO #tmpDirectCust (custid, ClosedReason)
        SELECT cs.custid, cl.ClosedReason        FROM dbo.CustSuper cs WITH (NOLOCK)  			LEFT JOIN CustLoginInfo cl WITH(NOLOCK) ON cs.custid=cl.CustID  		WHERE cs.IsInternal = 0	UNION        SELECT a.custid, cl.ClosedReason        FROM dbo.f_GetDirectAgency(4) a            INNER JOIN dbo.CustMaster cm WITH(NOLOCK) ON cm.custid = a.custid			LEFT JOIN CustLoginInfo cl WITH(NOLOCK) ON a.custid=cl.CustID  		WHERE cm.isInternal = 0     UNION            SELECT a.custid, cl.ClosedReason        FROM dbo.f_GetDirectAgency(3) a            CROSS APPLY (SELECT TOP 1 IsInternal FROM dbo.CustAgent ca WITH(NOLOCK) WHERE ca.custid = a.custid) ca			LEFT JOIN CustLoginInfo cl WITH(NOLOCK) ON a.custid=cl.CustID  		WHERE ca.IsInternal = 0    UNION            SELECT a.custid, cl.ClosedReason        FROM dbo.f_GetDirectAgency(2) a			OUTER APPLY (SELECT TOP 1 ca.custid 						 FROM dbo.CustAgent ca WITH(NOLOCK) 						 WHERE ca.custid=a.recommend							AND ca.IsInternal = 1) ca			LEFT JOIN CustLoginInfo_Member cl WITH(NOLOCK) ON a.custid=cl.CustID       		WHERE ca.custid IS NULL

    --Get Headline
    INSERT INTO #tmpGroupHeadline(CustHeadlineID, GroupHeadline, GroupHeadlineID)    
	SELECT hl.CustID, cu.username, hl.GroupID
    FROM dbo.CustGroupHeadline hl WITH (NOLOCK)
        INNER JOIN dbo.Customer cu WITH (NOLOCK) ON hl.CustID = cu.custid
		CROSS APPLY (SELECT TOP 1 1 AS Val
						 FROM Acc_CustGroup ag WITH (NOLOCK)
						 WHERE ag.CustID=cu.srecommend
							AND ag.GroupName=@GroupName) g
	WHERE @groupheadline = '' OR cu.username=@GroupHeadline

	--GET RESULT
    INSERT INTO #tmpResultAll (CustHeadlineID, GroupHeadline
							, CustID, UserName, ClosedReason)    
    SELECT hl.CustHeadlineID, hl.GroupHeadline
		, ca.custid, ci.username
		, ISNULL(d.ClosedReason, 0) AS ClosedReason
    FROM custaccount ca WITH(NOLOCK)    
        INNER JOIN #tmpGroupHeadline hl WITH(NOLOCK) ON  hl.GroupHeadlineID = ca.groupid
        INNER JOIN Customer ci WITH(NOLOCK) ON  ci.custid = ca.custid 
        INNER JOIN #tmpDirectCust d ON  d.custid = ca.custid      
    WHERE (@username = '' OR ci.username=@UserName)
        AND hl.GroupHeadlineID <> 0
    UNION ALL    
    SELECT  0 AS CustHeadlineID, 'Not assigned to group' AS GroupHeadline 
		, c.custid, ci.username
		, ISNULL(c.ClosedReason,0) AS ClosedReason
    FROM #tmpDirectCust c    
        INNER JOIN Customer ci WITH(NOLOCK) ON  ci.custid = c.custid     
	WHERE NOT EXISTS (SELECT 1 FROM custaccount ca WITH(NOLOCK) WHERE ca.custid = c.custid AND ca.groupID  <> 0) 
        AND (@username = '' OR ci.username=@UserName) 
        AND @groupheadline=''

	--filter: ext group 
	DELETE d
	FROM #tmpResultAll d 
	INNER JOIN Customer c WITH (NOLOCK) ON c.custid=d.CustID
	OUTER APPLY (SELECT TOP 1 1 AS Val
						 FROM Acc_CustGroup ag WITH (NOLOCK)
						 WHERE ag.CustID=c.srecommend
							AND ag.GroupName=@GroupName
						 ) g
	WHERE c.Site='CN88' OR (g.Val IS NULL AND (d.CustHeadlineID=0 OR c.roleid=4))

	--UPDATE STATUS: Open, Suspended, Closed, Disabled
    UPDATE t
	SET t.IsEnable=ci.Enabled
		,t.IsSuspend=cs.reject
		,t.IsClosed=cs.closed
    FROM #tmpResultAll t
		INNER JOIN custInfo ci WITH (NOLOCK) ON ci.custid=t.CustID
		CROSS APPLY (SELECT CASE WHEN CloseInfo > 0 THEN 1 ELSE 0 END AS closed
							, CASE WHEN SuspendInfo > 0 THEN 1 ELSE 0 END AS reject
					 FROM dbo.CustProductStatus cps WITH(NOLOCK)
					 WHERE cps.CustID = t.custid
					) AS cs 
		
    --get resulset for SELECT all status: Open, Suspended, Closed, Disabled
	INSERT INTO #tmpResult (CustHeadlineID, GroupHeadline, CustID, UserName
							, IsEnable, IsSuspend, IsClosed, ClosedReason)          
	SELECT r.CustHeadlineID, r.GroupHeadline
		, r.CustID, r.UserName
		, IsEnable, IsSuspend, IsClosed
		, ClosedReason
    FROM #tmpResultAll r
	INNER JOIN Customer c WITH (NOLOCK) ON c.custid=r.CustID
    WHERE (@IsInternalAdmin=0 OR c.site NOT IN (SELECT site FROM @DenySite))
		AND CASE 
				WHEN @Status = 0									THEN 1	--Status = 'All'
				WHEN @Status = 1 AND IsSuspend = 0 AND IsClosed = 0	THEN 1	--Status = 'Open'
				WHEN @Status = 2 AND IsSuspend = 1 AND IsClosed =0	THEN 1	--Status = 'Suspended'
				WHEN @Status = 3 AND IsEnable = 1 AND IsClosed =1	THEN 1	--Status = 'Closed'
				WHEN @Status = 4 AND r.IsEnable=0					THEN 1	--Status = 'Disabled'
				ELSE 0
			END = 1

    --resulset   
    SELECT CustHeadlineID, GroupHeadline
		, CustID, UserName
		, IsEnable, IsSuspend, IsClosed
		, ISNULL(ClosedReason,0) AS ClosedReason
    FROM  #tmpResult r
	ORDER BY CustHeadlineID, UserName   
END
GO