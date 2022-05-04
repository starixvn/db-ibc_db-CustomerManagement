/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_DormantAccountListByHeadline_Sel]
(
	@FilterHeadlineType  TINYINT     = NULL, 
	@FilterHeadlineGroup VARCHAR(30) = NULL, 
	@NotAssignGroupOnly  BIT         = 0, --= 1: only show Not Assign Group Headline 
	@FilterRoleID        VARCHAR(20) = NULL, 
	@FilterStageID       TINYINT     = 0, 
	@FilterDateType      TINYINT     = 0, 
	@FromDate            DATETIME    = NULL, 
	@ToDate              DATETIME    = NULL, 
	@SortType            TINYINT     = 1, -- 1: Headline ASC, 2: Headline DESC
	@PageSize            INT         = 50, 
	@PageIndex           INT         = 1, 
	@TotalItems          INT         = 0 OUTPUT
)
AS
/*
	Created: 20210622@Eden
	Task : get the dormant SMA accounts of Headline Group which are being processed by the archive account process. 
		NAP --> ADMIN -->  Dormant SMA Account list
	DB: DBCUST/CUSTDB
	Original:

	Revisions:  
		- 20210622@Eden: All sites - Dormant SMA Account List [RedmineID: #155969]
		- 20220504@Elodie: Tuning SP [RedmineID: #172311]

	Parameter Definition
		-@FilterStageID: apply for headline dirrect acccounts
			0: All Stages <default>
			1: Close Account
			2: Disable Account
			3: Delete Setting
			4: Delete Account

		-@FilterDateType: apply for headline dirrect acccounts' downlines
			0: All Archive Date Types <default>
			1: Close Date
			2: Disable Date
			3: Delete Setting Date
			4: Delete Account Date

		-@FilterRoleID (Level): list of roleID
			'' or NULL - All 
			4 - Super
			3 - Master
			2 - Agent 
			1 - Member

		-@FilterHeadlineType:
			1: Vip
			0: Normal
			NULL : All

	Example: 
	DECLARE @TotalItems	INT 
	EXEC Acc_DormantAccountListByHeadline_Sel 
		--@FilterRoleID    = '2',
		--@FilterHeadlineType = 1,
		--@FilterHeadlineGroup = '305RM',
		--@NotAssignGroupOnly = 1,
		@PageSize	= 50,
		@PageIndex	= 1,
		@TotalItems = @TotalItems OUTPUT
	SELECT @TotalItems
	
	*/
BEGIN
	SET NOCOUNT ON
	DECLARE @RowCount int, @RowStart int, @RowEnd int
	DECLARE @CustID_ByUserName INT
	DECLARE @NotAssignGroupName VARCHAR(30) = 'Not assigned to group'

	 CREATE TABLE #tmpDirectCust 
    (
        CustID INT PRIMARY KEY
    )

	CREATE TABLE #tmpGroupHeadline 
    (
        CustHeadlineID INT PRIMARY KEY
      , HeadlineGroup VARCHAR(30)
      , GroupID SMALLINT 
      , HeadlineType TINYINT NULL
    )

	CREATE TABLE #tmpGroup
    (
        CustHeadlineID INT
      , HeadlineGroup VARCHAR(30)
      , CustID INT
      , UserName VARCHAR(30)
	  , RoleId TINYINT
      , HeadlineType TINYINT
	  , StageID TINYINT
	  , recommend INT
    ) 

	CREATE TABLE #TmpSuper_Archive
    (	
		DirectCustID INT
      , CustID INT PRIMARY KEY
	  , RoleID TINYINT
	  , StageID TINYINT
      , TobeReducedCredit MONEY
      , ReducedCredit MONEY
      , mrecommend INT
    ) 
	
	CREATE TABLE #CustHeadline_Archived
	(
		CustHeadlineID   INT, 
		HeadlineGroup    VARCHAR(30), 
		CustID           INT, 
		UserName         VARCHAR(30), 
		RoleId           TINYINT, 
		HeadlineType     TINYINT, 
		StageID          TINYINT, 
		Cnt_Stage1Member INT, 
		Cnt_Stage2Member INT, 
		Cnt_Stage3Member INT, 
		Cnt_Stage4Member INT, 
		Cnt_Stage1Agent  INT, 
		Cnt_Stage2Agent  INT, 
		Cnt_Stage3Agent  INT, 
		Cnt_Stage4Agent  INT, 
		Cnt_Stage1Master INT, 
		Cnt_Stage2Master INT, 
		Cnt_Stage3Master INT, 
		Cnt_Stage4Master INT,
		ToBeClearedGivenCredit_dl MONEY,
		ClearedGivenCredit_dl MONEY,
		RN				 INT IDENTITY(1,1) PRIMARY KEY
	);
	CREATE TABLE #ArchiveSMA
	(
		CustID			INT, 
		RoleId			TINYINT, 
		srecommend		INT, 
		mrecommend		INT, 
		TotalDownline	INT
	)
	CREATE TABLE #FilterRole(RoleID TINYINT)

	CREATE TABLE #Exclude(
		recommend  INT, 
		mrecommend INT,
		srecommend INT
	)
	CREATE NONCLUSTERED INDEX ix_TmpExclude_recommend ON #Exclude(recommend)
	CREATE NONCLUSTERED INDEX ix_TmpExclude_mrecommend ON #Exclude(mrecommend)
	CREATE NONCLUSTERED INDEX ix_TmpExclude_srecommend ON #Exclude(srecommend)

	SELECT @ToDate = CONVERT(VARCHAR(10),CONVERT(DATE,@ToDate)) + ' 23:59:59.998'
	
	IF ISNULL(@FilterRoleID,'') != ''
		INSERT INTO #FilterRole(RoleID)
		SELECT t.val FROM dbo.f_StringSplit(@FilterRoleID,',') t WHERE val IN(1,2,3,4)
	ELSE
		INSERT INTO #FilterRole(RoleID)
		SELECT 1 UNION ALL
		SELECT 2 UNION ALL
		SELECT 3 UNION ALL
		SELECT 4 

	IF @NotAssignGroupOnly = 1 --Disable Search by Headline Group and Headline Type
		SELECT @FilterHeadlineGroup = @NotAssignGroupName, @FilterHeadlineType = NULL 

	IF ISNULL(@FilterHeadlineGroup,'') != ''
		SET @FilterHeadlineGroup = '%' + @FilterHeadlineGroup + '%'
	
	SELECT @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1 

	--> Get Headline info
	IF @NotAssignGroupOnly = 0
	BEGIN
		INSERT INTO #tmpGroupHeadline(CustHeadlineID, HeadlineGroup, GroupID, HeadlineType)    
		SELECT hl.CustID, cu.username, hl.GroupID, hl.HeadlineType
		FROM dbo.CustGroupHeadline hl WITH (NOLOCK)
			INNER JOIN dbo.custInfo cu WITH (NOLOCK) ON hl.CustID = cu.custid
		WHERE hl.HeadlineType = CASE WHEN @FilterHeadlineType IS NULL THEN hl.HeadlineType ELSE @FilterHeadlineType END
			AND cu.username LIKE CASE WHEN ISNULL(@FilterHeadlineGroup,'') = '' THEN cu.username ELSE @FilterHeadlineGroup END
			AND hl.GroupID <> 0
			AND cu.currency <> 20
	END

	INSERT INTO #tmpDirectCust(CustID)
	SELECT c.CustID  
	FROM CustDirectAccount c WITH(NOLOCK)
		INNER JOIN dbo.Customer cu WITH (NOLOCK) 
			ON c.CustID = cu.custid 
		INNER JOIN #FilterRole r 
			ON r.RoleID = cu.RoleID
	WHERE cu.currency <> 20
		AND cu.srecommend NOT IN( SELECT custid FROM Dep_CustSuper WITH(NOLOCK))

	--Deleted accounts
	INSERT INTO #tmpDirectCust(CustID)
	SELECT c.CustID  
	FROM CustDirectAccount c WITH(NOLOCK)
		INNER JOIN dbo.Cust_ArchiveAccount cu WITH (NOLOCK) 
			ON c.CustID = cu.custid
			AND cu.StageID = 4
		INNER JOIN #FilterRole r 
			ON r.RoleID = cu.RoleID
	WHERE NOT EXISTS( SELECT 1 FROM #tmpDirectCust WHERE CustID = c.CustID)
	
	--> Assigned to group
	INSERT INTO #tmpGroup(CustHeadlineID,HeadlineGroup,CustID,UserName,HeadlineType,RoleId,StageID,recommend)
    SELECT  hl.CustHeadlineID, hl.HeadlineGroup, ca.custid, ISNULL(ci.username,ar.Username) Username, hl.HeadlineType, ISNULL(ci.roleid,ar.roleid) RoleId, ar.StageID,ISNULL(ci.recommend,ar.recommend)
    FROM custAccount ca WITH(NOLOCK)    
        INNER JOIN #tmpGroupHeadline hl WITH(NOLOCK) ON  hl.groupid = ca.groupid
		INNER JOIN #tmpDirectCust d ON  d.custid = ca.custid 
        LEFT JOIN custinfo ci WITH(NOLOCK) ON  ci.custid = ca.custid 
		LEFT JOIN Cust_ArchiveAccount ar WITH(NOLOCK) ON  ar.custid = ca.custid   
    WHERE ISNULL(ar.StageID,0) = CASE WHEN @FilterStageID = 0 THEN ISNULL(ar.StageID,0) ELSE @FilterStageID END
		AND	ca.GroupID <> 0

	--> Not assigned to group
	IF @NotAssignGroupOnly = 1 
		OR ( @NotAssignGroupName LIKE '%' + ISNULL(@FilterHeadlineGroup,'') + '%'  
			AND @FilterHeadlineType IS NULL )
	BEGIN
		INSERT INTO #tmpGroup(CustHeadlineID,HeadlineGroup,CustID,UserName,HeadlineType,RoleId,StageID,recommend)
		SELECT  0 CustHeadlineID, @NotAssignGroupName HeadlineGroup, c.custid, ISNULL(ci.username,ar.Username) Username, NULL AS HeadlineType, ISNULL(ci.roleid,ar.roleid) RoleId, ar.StageID,ISNULL(ci.recommend,ar.recommend)   
		FROM #tmpDirectCust c    
			LEFT JOIN custinfo ci WITH(NOLOCK) ON  ci.custid = c.custid 
			LEFT JOIN Cust_ArchiveAccount ar WITH(NOLOCK) ON  ar.custid = c.custid 
		WHERE NOT EXISTS (SELECT 1 FROM custaccount ca WITH(NOLOCK) WHERE ca.custid = c.custid AND ca.groupID  <> 0) 
			AND ISNULL(ar.StageID,0) = CASE WHEN @FilterStageID = 0 THEN ISNULL(ar.StageID,0) ELSE @FilterStageID END
	END
	
	--Delete direct acc have data stage 1 but open status
	IF @FilterStageID = 1
	BEGIN
		DELETE t
		FROM #tmpGroup t
			INNER JOIN CustProductStatus c WITH(NOLOCK) ON t.custid = c.custid AND c.closeinfo = 0
		WHERE t.StageID = 1
	END

	--not view finance accounts
	DELETE t
	FROM #tmpGroup t
		INNER JOIN CustSuper fn WITH(NOLOCK,FORCESEEK)
			ON t.CustID = fn.custid 
	WHERE fn.IsInternal = 1 
		AND t.RoleId = 4

	DELETE t
	FROM #tmpGroup t
		INNER JOIN CustMaster fn WITH(NOLOCK,FORCESEEK)
			ON t.CustID = fn.custid 
	WHERE fn.IsInternal = 1 
		AND t.RoleId = 3

	DELETE t
	FROM #tmpGroup t
		INNER JOIN CustAgent fn WITH(NOLOCK,FORCESEEK)
			ON t.CustID = fn.custid 
	WHERE fn.IsInternal = 1 
		AND t.RoleId = 2

	DELETE t
	FROM #tmpGroup t
		INNER JOIN CustAgent fn WITH(NOLOCK,FORCESEEK)
			ON t.recommend = fn.custid 
	WHERE fn.IsInternal = 1 
		AND t.RoleId = 1

	INSERT INTO #ArchiveSMA (custid, roleid, srecommend, mrecommend, TotalDownline)
	SELECT ca.CustID, RoleID, srecommend, mrecommend, TotalDownline
	FROM Cust_ArchiveAccount ca WITH (NOLOCK) WHERE StageID = 1 and RoleID IN (2,3,4)

	IF @FilterDateType IN(0,1) --include filter Closed Stage
	BEGIN
		INSERT INTO #Exclude(recommend,mrecommend,srecommend)
		SELECT c.custid,MAX(c.mrecommend) as mrecommend,MAX(c.srecommend) as srecommend
		FROM #ArchiveSMA c WITH(NOLOCK) 		
			INNER JOIN custInfo dl WITH(NOLOCK) ON dl.recommend = c.custid AND dl.roleid = 1
		WHERE c.RoleID = 2
		GROUP BY c.custid
		HAVING COUNT(dl.custid) > MAX(c.TotalDownline)
		UNION
		SELECT 0,c.custid,MAX(c.srecommend) as srecommend
		FROM #ArchiveSMA c WITH(NOLOCK) 
			INNER JOIN custInfo dl WITH(NOLOCK) ON dl.mrecommend = c.custid AND dl.roleid IN (1,2)
		WHERE c.roleid = 3
		GROUP BY c.custid
		HAVING COUNT(dl.custid) > MAX(c.TotalDownline)
		UNION 
		SELECT 0,0,c.custid as srecommend
		FROM #ArchiveSMA c WITH(NOLOCK) 
			INNER JOIN custInfo dl WITH(NOLOCK) 
				ON dl.srecommend = c.custid AND dl.roleid IN (1,2,3)
		WHERE c.roleid = 4
		GROUP BY c.custid
		HAVING COUNT(dl.custid) > MAX(c.TotalDownline)
	END

	--> Get Archived downlines info
	IF @FilterDateType = 0
	BEGIN
		INSERT INTO #TmpSuper_Archive(DirectCustID,CustID,RoleID,StageID,TobeReducedCredit,ReducedCredit,mrecommend)
		SELECT t.CustID,ar.custid,ar.roleid,ar.stageid,c.credit,ar.ReducedCredit,ar.mrecommend
		FROM Cust_ArchiveAccount ar WITH(NOLOCK) 
			INNER JOIN #tmpGroup t ON ar.srecommend = t.CustID AND t.RoleId = 4
			LEFT JOIN Custinfo c WITH(NOLOCK) ON ar.CustID = c.custid
			LEFT JOIN CustProductStatus ci WITH(NOLOCK) ON ar.CustID = ci.custid AND ci.CloseInfo > 0
			LEFT JOIN CustProductStatus agci WITH(NOLOCK) ON ar.recommend = agci.custid AND agci.CloseInfo > 0 
		WHERE t.CustID = ar.srecommend
			AND (	ISNULL(ar.ClosedDate,'') BETWEEN @FromDate AND @ToDate
					OR ISNULL(ar.DisabledDate,'') BETWEEN @FromDate AND @ToDate
					OR ISNULL(ar.SettingDeletedDate,'') BETWEEN @FromDate AND @ToDate
					OR ISNULL(ar.AccountDeletedDate,'') BETWEEN @FromDate AND @ToDate
				)
			AND (ar.StageID >= 2 
					OR (ci.CustID IS NOT NULL AND ar.roleid > 2 )
					OR (agci.CustID IS NOT NULL AND ar.roleid <= 2 )
				)
			AND (ar.StageID >= 2 
					OR (NOT EXISTS ( SELECT 1 FROM #Exclude ex WHERE ar.custID IN (ex.mrecommend,ex.srecommend) AND ar.RoleID > 2)
						AND NOT EXISTS ( SELECT 1 FROM #Exclude ex WHERE ar.recommend = ex.recommend AND ar.RoleID <= 2)
					)
				)

		INSERT INTO #CustHeadline_Archived(CustHeadlineID,HeadlineGroup,CustID,UserName,HeadlineType,RoleId,StageID
											,Cnt_Stage1Member,Cnt_Stage2Member,Cnt_Stage3Member,Cnt_Stage4Member
											,Cnt_Stage1Agent,Cnt_Stage2Agent,Cnt_Stage3Agent,Cnt_Stage4Agent
											,Cnt_Stage1Master,Cnt_Stage2Master,Cnt_Stage3Master,Cnt_Stage4Master,ToBeClearedGivenCredit_dl,ClearedGivenCredit_dl)
		SELECT CustHeadlineID,HeadlineGroup,CustID,UserName,HeadlineType,RoleId,StageID
											,Cnt_Stage1Member,Cnt_Stage2Member,Cnt_Stage3Member,Cnt_Stage4Member
											,Cnt_Stage1Agent,Cnt_Stage2Agent,Cnt_Stage3Agent,Cnt_Stage4Agent
											,Cnt_Stage1Master,Cnt_Stage2Master,Cnt_Stage3Master,Cnt_Stage4Master,ToBeClearedGivenCredit_dl,ClearedGivenCredit_dl
		FROM (
			SELECT CustHeadlineID,HeadlineGroup,CustID,UserName,HeadlineType,RoleId,StageID
												,Cnt_Stage1Member,Cnt_Stage2Member,Cnt_Stage3Member,Cnt_Stage4Member
												,Cnt_Stage1Agent,Cnt_Stage2Agent,Cnt_Stage3Agent,Cnt_Stage4Agent
												,Cnt_Stage1Master,Cnt_Stage2Master,Cnt_Stage3Master,Cnt_Stage4Master,ToBeClearedGivenCredit_dl,ClearedGivenCredit_dl
			FROM #tmpGroup t 
				CROSS APPLY (	SELECT	SUM( CASE WHEN ar.RoleID = 1 AND ar.StageID = 1 THEN 1 ELSE 0 END) Cnt_Stage1Member,
										SUM( CASE WHEN ar.RoleID = 1 AND ar.StageID = 2 THEN 1 ELSE 0 END) Cnt_Stage2Member,
										SUM( CASE WHEN ar.RoleID = 1 AND ar.StageID = 3 THEN 1 ELSE 0 END) Cnt_Stage3Member,
										SUM( CASE WHEN ar.RoleID = 1 AND ar.StageID = 4 THEN 1 ELSE 0 END) Cnt_Stage4Member,
										SUM( CASE WHEN ar.RoleID = 2 AND ar.StageID = 1 THEN 1 ELSE 0 END) Cnt_Stage1Agent,
										SUM( CASE WHEN ar.RoleID = 2 AND ar.StageID = 2 THEN 1 ELSE 0 END) Cnt_Stage2Agent,
										SUM( CASE WHEN ar.RoleID = 2 AND ar.StageID = 3 THEN 1 ELSE 0 END) Cnt_Stage3Agent,
										SUM( CASE WHEN ar.RoleID = 2 AND ar.StageID = 4 THEN 1 ELSE 0 END) Cnt_Stage4Agent,
										SUM( CASE WHEN ar.RoleID = 3 AND ar.StageID = 1 THEN 1 ELSE 0 END) Cnt_Stage1Master,
										SUM( CASE WHEN ar.RoleID = 3 AND ar.StageID = 2 THEN 1 ELSE 0 END) Cnt_Stage2Master,
										SUM( CASE WHEN ar.RoleID = 3 AND ar.StageID = 3 THEN 1 ELSE 0 END) Cnt_Stage3Master,
										SUM( CASE WHEN ar.RoleID = 3 AND ar.StageID = 4 THEN 1 ELSE 0 END) Cnt_Stage4Master,
										SUM( CASE WHEN ar.RoleID = 3 AND ar.StageID = 1 THEN ar.TobeReducedCredit ELSE 0 END + --credit of all masters were archived
											 CASE WHEN ar.RoleID = 2 AND ar.StageID = 1 AND ISNULL(magar.StageID,0) <> 1 THEN ar.TobeReducedCredit ELSE 0 END --Credit of all agents but their master were not archived
											) ToBeClearedGivenCredit_dl,
										SUM( CASE WHEN ar.RoleID = 3 AND ar.StageID >= 2 THEN ar.ReducedCredit ELSE 0 END + --credit of all masters were archived
											 CASE WHEN ar.RoleID = 2 AND ar.StageID >= 2 AND ISNULL(magar.StageID,0) < 2 THEN ar.ReducedCredit ELSE 0 END --Credit of all agents but their master were not archived
											) ClearedGivenCredit_dl
								FROM #TmpSuper_Archive ar
									OUTER APPLY (SELECT mag.StageID 
												 FROM #TmpSuper_Archive mag WITH(NOLOCK) 
												 WHERE ar.mrecommend = mag.CustID 
														AND mag.roleid = 3
												) magar
								WHERE t.CustID = ar.DirectCustID
								HAVING COUNT(1) > 0
								) arc
			WHERE t.RoleId = 4
			UNION ALL
			SELECT CustHeadlineID,HeadlineGroup,CustID,UserName,HeadlineType,RoleId,StageID
												,Cnt_Stage1Member,Cnt_Stage2Member,Cnt_Stage3Member,Cnt_Stage4Member
												,Cnt_Stage1Agent,Cnt_Stage2Agent,Cnt_Stage3Agent,Cnt_Stage4Agent
												,Cnt_Stage1Master,Cnt_Stage2Master,Cnt_Stage3Master,Cnt_Stage4Master,ToBeClearedGivenCredit_dl,ClearedGivenCredit_dl
			FROM #tmpGroup t 
				CROSS APPLY (	SELECT SUM( CASE WHEN ar.RoleID = 1 AND ar.StageID = 1 THEN 1 ELSE 0 END) Cnt_Stage1Member,
										SUM( CASE WHEN ar.RoleID = 1 AND ar.StageID = 2 THEN 1 ELSE 0 END) Cnt_Stage2Member,
										SUM( CASE WHEN ar.RoleID = 1 AND ar.StageID = 3 THEN 1 ELSE 0 END) Cnt_Stage3Member,
										SUM( CASE WHEN ar.RoleID = 1 AND ar.StageID = 4 THEN 1 ELSE 0 END) Cnt_Stage4Member,
										SUM( CASE WHEN ar.RoleID = 2 AND ar.StageID = 1 THEN 1 ELSE 0 END) Cnt_Stage1Agent,
										SUM( CASE WHEN ar.RoleID = 2 AND ar.StageID = 2 THEN 1 ELSE 0 END) Cnt_Stage2Agent,
										SUM( CASE WHEN ar.RoleID = 2 AND ar.StageID = 3 THEN 1 ELSE 0 END) Cnt_Stage3Agent,
										SUM( CASE WHEN ar.RoleID = 2 AND ar.StageID = 4 THEN 1 ELSE 0 END) Cnt_Stage4Agent,
										0 AS Cnt_Stage1Master,
										0 AS Cnt_Stage2Master,
										0 AS Cnt_Stage3Master,
										0 AS Cnt_Stage4Master,
										SUM( CASE WHEN ar.RoleID = 2 AND ar.StageID = 1 THEN c.credit ELSE 0 END) ToBeClearedGivenCredit_dl,
										SUM( CASE WHEN ar.RoleID = 2 AND ar.StageID >= 2 THEN ar.ReducedCredit ELSE 0 END) ClearedGivenCredit_dl
								FROM Cust_ArchiveAccount ar WITH(NOLOCK) 
									LEFT JOIN Custinfo c WITH(NOLOCK) ON ar.CustID = c.custid
									LEFT JOIN CustProductStatus ci WITH(NOLOCK) ON ar.CustID = ci.custid AND ci.CloseInfo > 0
									LEFT JOIN CustProductStatus agci WITH(NOLOCK) ON ar.recommend = agci.custid AND agci.CloseInfo > 0
								WHERE t.CustID = ar.mrecommend
									AND (	ISNULL(ar.ClosedDate,'') BETWEEN @FromDate AND @ToDate
											OR ISNULL(ar.DisabledDate,'') BETWEEN @FromDate AND @ToDate
											OR ISNULL(ar.SettingDeletedDate,'') BETWEEN @FromDate AND @ToDate
											OR ISNULL(ar.AccountDeletedDate,'') BETWEEN @FromDate AND @ToDate
										)
									AND (ar.StageID >= 2 
											OR (ci.CustID IS NOT NULL AND ar.roleid > 2 )
											OR (agci.CustID IS NOT NULL AND ar.roleid <= 2 )
										)
									AND (ar.StageID >= 2 
											OR (NOT EXISTS ( SELECT 1 FROM #Exclude ex WHERE ar.custID IN (ex.mrecommend) AND ar.RoleID > 2)
												AND NOT EXISTS ( SELECT 1 FROM #Exclude ex WHERE ar.recommend = ex.recommend AND ar.RoleID <= 2)
											)
										)
								HAVING COUNT(1) > 0
								) arc
			WHERE t.RoleId = 3
			UNION ALL
			SELECT CustHeadlineID,HeadlineGroup,CustID,UserName,HeadlineType,RoleId,StageID
												,Cnt_Stage1Member,Cnt_Stage2Member,Cnt_Stage3Member,Cnt_Stage4Member
												,Cnt_Stage1Agent,Cnt_Stage2Agent,Cnt_Stage3Agent,Cnt_Stage4Agent
												,Cnt_Stage1Master,Cnt_Stage2Master,Cnt_Stage3Master,Cnt_Stage4Master,ToBeClearedGivenCredit_dl,ClearedGivenCredit_dl
			FROM #tmpGroup t 
				CROSS APPLY (	SELECT SUM( CASE WHEN ar.RoleID = 1 AND ar.StageID = 1 THEN 1 ELSE 0 END) Cnt_Stage1Member,
										SUM( CASE WHEN ar.RoleID = 1 AND ar.StageID = 2 THEN 1 ELSE 0 END) Cnt_Stage2Member,
										SUM( CASE WHEN ar.RoleID = 1 AND ar.StageID = 3 THEN 1 ELSE 0 END) Cnt_Stage3Member,
										SUM( CASE WHEN ar.RoleID = 1 AND ar.StageID = 4 THEN 1 ELSE 0 END) Cnt_Stage4Member,
										0 AS Cnt_Stage1Agent,
										0 AS Cnt_Stage2Agent,
										0 AS Cnt_Stage3Agent,
										0 AS Cnt_Stage4Agent,
										0 AS Cnt_Stage1Master,
										0 AS Cnt_Stage2Master,
										0 AS Cnt_Stage3Master,
										0 AS Cnt_Stage4Master,
										0 ToBeClearedGivenCredit_dl,
										0 ClearedGivenCredit_dl
								FROM Cust_ArchiveAccount ar WITH(NOLOCK) 
									LEFT JOIN CustProductStatus agci WITH(NOLOCK) ON ar.recommend = agci.custid AND agci.CloseInfo > 0
								WHERE t.CustID = ar.recommend
									AND (	ISNULL(ar.ClosedDate,'') BETWEEN @FromDate AND @ToDate
											OR ISNULL(ar.DisabledDate,'') BETWEEN @FromDate AND @ToDate
											OR ISNULL(ar.SettingDeletedDate,'') BETWEEN @FromDate AND @ToDate
											OR ISNULL(ar.AccountDeletedDate,'') BETWEEN @FromDate AND @ToDate
										)
									AND (ar.StageID >= 2 
											OR agci.CustID IS NOT NULL
										)
									AND (ar.StageID >= 2 
											OR NOT EXISTS ( SELECT 1 FROM #Exclude ex WHERE ar.recommend = ex.recommend AND ar.RoleID <= 2)
										)
								HAVING COUNT(1) > 0
								) arc
			WHERE t.RoleId = 2
			UNION ALL
			SELECT CustHeadlineID,HeadlineGroup,CustID,UserName,HeadlineType,RoleId,StageID
												,Cnt_Stage1Member,Cnt_Stage2Member,Cnt_Stage3Member,Cnt_Stage4Member
												,Cnt_Stage1Agent,Cnt_Stage2Agent,Cnt_Stage3Agent,Cnt_Stage4Agent
												,Cnt_Stage1Master,Cnt_Stage2Master,Cnt_Stage3Master,Cnt_Stage4Master,ToBeClearedGivenCredit_dl,ClearedGivenCredit_dl
			FROM #tmpGroup t 
				CROSS APPLY (	SELECT  0 AS Cnt_Stage1Member,
										0 AS Cnt_Stage2Member,
										0 AS Cnt_Stage3Member,
										0 AS Cnt_Stage4Member,
										0 AS Cnt_Stage1Agent,
										0 AS Cnt_Stage2Agent,
										0 AS Cnt_Stage3Agent,
										0 AS Cnt_Stage4Agent,
										0 AS Cnt_Stage1Master,
										0 AS Cnt_Stage2Master,
										0 AS Cnt_Stage3Master,
										0 AS Cnt_Stage4Master,
										0 ToBeClearedGivenCredit_dl,
										0 ClearedGivenCredit_dl
								FROM Cust_ArchiveAccount ar WITH(NOLOCK)
									LEFT JOIN CustProductStatus agci WITH(NOLOCK) ON ar.recommend = agci.custid AND agci.CloseInfo > 0 
								WHERE t.CustID = ar.CustID
									AND (	ISNULL(ar.ClosedDate,'') BETWEEN @FromDate AND @ToDate
											OR ISNULL(ar.DisabledDate,'') BETWEEN @FromDate AND @ToDate
											OR ISNULL(ar.SettingDeletedDate,'') BETWEEN @FromDate AND @ToDate
											OR ISNULL(ar.AccountDeletedDate,'') BETWEEN @FromDate AND @ToDate
										)
									AND (ar.StageID >= 2 
											OR agci.CustID IS NOT NULL
										)
									AND (ar.StageID >= 2 
											OR NOT EXISTS ( SELECT 1 FROM #Exclude ex WHERE ar.recommend = ex.recommend AND ar.RoleID <= 2)
										)
								HAVING COUNT(1) > 0
								) arc
			WHERE t.RoleId = 1
			) temp
		ORDER BY CASE WHEN CustHeadlineID <> 0 THEN 0 ELSE 1 END,
			    CASE WHEN @SortType = 1 THEN HeadlineGroup END ASC ,
				CASE WHEN @SortType = 2 THEN HeadlineGroup END DESC,
				UserName
	END
	ELSE
	BEGIN
		INSERT INTO #TmpSuper_Archive(DirectCustID,CustID,RoleID,StageID,TobeReducedCredit,ReducedCredit,mrecommend)
		SELECT t.CustID,ar.custid,ar.roleid,ar.stageid,c.credit,ar.ReducedCredit,ar.mrecommend
		FROM Cust_ArchiveAccount ar WITH(NOLOCK) 
			INNER JOIN #tmpGroup t ON ar.srecommend = t.CustID AND t.RoleId = 4
			LEFT JOIN Custinfo c WITH(NOLOCK) ON ar.CustID = c.custid
			LEFT JOIN CustProductStatus ci WITH(NOLOCK) ON ar.CustID = ci.custid AND ci.CloseInfo > 0
			LEFT JOIN CustProductStatus agci WITH(NOLOCK) ON ar.recommend = agci.custid AND agci.CloseInfo > 0 
		WHERE t.CustID = ar.srecommend
			AND ISNULL(ar.ClosedDate,'') >= CASE WHEN @FilterDateType = 1 THEN @FromDate ELSE ISNULL(ar.ClosedDate,'') END
									AND ISNULL(ar.ClosedDate,'') <= CASE WHEN @FilterDateType = 1 THEN @ToDate ELSE ISNULL(ar.ClosedDate,'') END
									AND ISNULL(ar.DisabledDate,'') >= CASE WHEN @FilterDateType = 2 THEN @FromDate ELSE ISNULL(ar.DisabledDate,'') END
									AND ISNULL(ar.DisabledDate,'') <= CASE WHEN @FilterDateType = 2 THEN @ToDate ELSE ISNULL(ar.DisabledDate,'') END
									AND ISNULL(ar.SettingDeletedDate,'') >= CASE WHEN @FilterDateType = 3 THEN @FromDate ELSE ISNULL(ar.SettingDeletedDate,'') END
									AND ISNULL(ar.SettingDeletedDate,'') <= CASE WHEN @FilterDateType = 3 THEN @ToDate ELSE ISNULL(ar.SettingDeletedDate,'') END
									AND ISNULL(ar.AccountDeletedDate,'') >= CASE WHEN @FilterDateType = 4 THEN @FromDate ELSE ISNULL(ar.AccountDeletedDate,'') END
									AND ISNULL(ar.AccountDeletedDate,'') <= CASE WHEN @FilterDateType = 4 THEN @ToDate ELSE ISNULL(ar.AccountDeletedDate,'') END
			AND (ar.StageID >= 2 
					OR (ci.CustID IS NOT NULL AND ar.roleid > 2 )
					OR (agci.CustID IS NOT NULL AND ar.roleid <= 2 )
				)
			AND (ar.StageID >= 2 
					OR (NOT EXISTS ( SELECT 1 FROM #Exclude ex WHERE ar.custID IN (ex.mrecommend,ex.srecommend) AND ar.RoleID > 2)
						AND NOT EXISTS ( SELECT 1 FROM #Exclude ex WHERE ar.recommend = ex.recommend AND ar.RoleID <= 2)
					)
				)

		INSERT INTO #CustHeadline_Archived(CustHeadlineID,HeadlineGroup,CustID,UserName,HeadlineType,RoleId,StageID
											,Cnt_Stage1Member,Cnt_Stage2Member,Cnt_Stage3Member,Cnt_Stage4Member
											,Cnt_Stage1Agent,Cnt_Stage2Agent,Cnt_Stage3Agent,Cnt_Stage4Agent
											,Cnt_Stage1Master,Cnt_Stage2Master,Cnt_Stage3Master,Cnt_Stage4Master,ToBeClearedGivenCredit_dl,ClearedGivenCredit_dl)
		SELECT CustHeadlineID,HeadlineGroup,CustID,UserName,HeadlineType,RoleId,StageID
											,Cnt_Stage1Member,Cnt_Stage2Member,Cnt_Stage3Member,Cnt_Stage4Member
											,Cnt_Stage1Agent,Cnt_Stage2Agent,Cnt_Stage3Agent,Cnt_Stage4Agent
											,Cnt_Stage1Master,Cnt_Stage2Master,Cnt_Stage3Master,Cnt_Stage4Master,ToBeClearedGivenCredit_dl,ClearedGivenCredit_dl
		FROM (
			SELECT CustHeadlineID,HeadlineGroup,CustID,UserName,HeadlineType,RoleId,StageID
												,Cnt_Stage1Member,Cnt_Stage2Member,Cnt_Stage3Member,Cnt_Stage4Member
												,Cnt_Stage1Agent,Cnt_Stage2Agent,Cnt_Stage3Agent,Cnt_Stage4Agent
												,Cnt_Stage1Master,Cnt_Stage2Master,Cnt_Stage3Master,Cnt_Stage4Master,ToBeClearedGivenCredit_dl,ClearedGivenCredit_dl
			FROM #tmpGroup t 
				CROSS APPLY (	SELECT	SUM( CASE WHEN ar.RoleID = 1 AND ar.StageID = 1 THEN 1 ELSE 0 END) Cnt_Stage1Member,
										SUM( CASE WHEN ar.RoleID = 1 AND ar.StageID = 2 THEN 1 ELSE 0 END) Cnt_Stage2Member,
										SUM( CASE WHEN ar.RoleID = 1 AND ar.StageID = 3 THEN 1 ELSE 0 END) Cnt_Stage3Member,
										SUM( CASE WHEN ar.RoleID = 1 AND ar.StageID = 4 THEN 1 ELSE 0 END) Cnt_Stage4Member,
										SUM( CASE WHEN ar.RoleID = 2 AND ar.StageID = 1 THEN 1 ELSE 0 END) Cnt_Stage1Agent,
										SUM( CASE WHEN ar.RoleID = 2 AND ar.StageID = 2 THEN 1 ELSE 0 END) Cnt_Stage2Agent,
										SUM( CASE WHEN ar.RoleID = 2 AND ar.StageID = 3 THEN 1 ELSE 0 END) Cnt_Stage3Agent,
										SUM( CASE WHEN ar.RoleID = 2 AND ar.StageID = 4 THEN 1 ELSE 0 END) Cnt_Stage4Agent,
										SUM( CASE WHEN ar.RoleID = 3 AND ar.StageID = 1 THEN 1 ELSE 0 END) Cnt_Stage1Master,
										SUM( CASE WHEN ar.RoleID = 3 AND ar.StageID = 2 THEN 1 ELSE 0 END) Cnt_Stage2Master,
										SUM( CASE WHEN ar.RoleID = 3 AND ar.StageID = 3 THEN 1 ELSE 0 END) Cnt_Stage3Master,
										SUM( CASE WHEN ar.RoleID = 3 AND ar.StageID = 4 THEN 1 ELSE 0 END) Cnt_Stage4Master,
										SUM( CASE WHEN ar.RoleID = 3 AND ar.StageID = 1 THEN ar.TobeReducedCredit ELSE 0 END + --credit of all masters were archived
											 CASE WHEN ar.RoleID = 2 AND ar.StageID = 1 AND ISNULL(magar.StageID,0) <> 1 THEN ar.TobeReducedCredit ELSE 0 END --Credit of all agents but their master were not archived
											) ToBeClearedGivenCredit_dl,
										SUM( CASE WHEN ar.RoleID = 3 AND ar.StageID >= 2 THEN ar.ReducedCredit ELSE 0 END + --credit of all masters were archived
											 CASE WHEN ar.RoleID = 2 AND ar.StageID >= 2 AND ISNULL(magar.StageID,0) < 2 THEN ar.ReducedCredit ELSE 0 END --Credit of all agents but their master were not archived
											) ClearedGivenCredit_dl
								FROM #TmpSuper_Archive ar
									OUTER APPLY (SELECT mag.StageID 
												 FROM #TmpSuper_Archive mag WITH(NOLOCK) 
												 WHERE ar.mrecommend = mag.CustID 
														AND mag.roleid = 3
												) magar
								WHERE t.CustID = ar.DirectCustID
								HAVING COUNT(1) > 0
								) arc
			WHERE t.RoleId = 4
			UNION ALL
			SELECT CustHeadlineID,HeadlineGroup,CustID,UserName,HeadlineType,RoleId,StageID
												,Cnt_Stage1Member,Cnt_Stage2Member,Cnt_Stage3Member,Cnt_Stage4Member
												,Cnt_Stage1Agent,Cnt_Stage2Agent,Cnt_Stage3Agent,Cnt_Stage4Agent
												,Cnt_Stage1Master,Cnt_Stage2Master,Cnt_Stage3Master,Cnt_Stage4Master,ToBeClearedGivenCredit_dl,ClearedGivenCredit_dl
			FROM #tmpGroup t 
				CROSS APPLY (	SELECT SUM( CASE WHEN ar.RoleID = 1 AND ar.StageID = 1 THEN 1 ELSE 0 END) Cnt_Stage1Member,
										SUM( CASE WHEN ar.RoleID = 1 AND ar.StageID = 2 THEN 1 ELSE 0 END) Cnt_Stage2Member,
										SUM( CASE WHEN ar.RoleID = 1 AND ar.StageID = 3 THEN 1 ELSE 0 END) Cnt_Stage3Member,
										SUM( CASE WHEN ar.RoleID = 1 AND ar.StageID = 4 THEN 1 ELSE 0 END) Cnt_Stage4Member,
										SUM( CASE WHEN ar.RoleID = 2 AND ar.StageID = 1 THEN 1 ELSE 0 END) Cnt_Stage1Agent,
										SUM( CASE WHEN ar.RoleID = 2 AND ar.StageID = 2 THEN 1 ELSE 0 END) Cnt_Stage2Agent,
										SUM( CASE WHEN ar.RoleID = 2 AND ar.StageID = 3 THEN 1 ELSE 0 END) Cnt_Stage3Agent,
										SUM( CASE WHEN ar.RoleID = 2 AND ar.StageID = 4 THEN 1 ELSE 0 END) Cnt_Stage4Agent,
										0 AS Cnt_Stage1Master,
										0 AS Cnt_Stage2Master,
										0 AS Cnt_Stage3Master,
										0 AS Cnt_Stage4Master,
										SUM( CASE WHEN ar.RoleID = 2 AND ar.StageID = 1 THEN c.credit ELSE 0 END) ToBeClearedGivenCredit_dl,
										SUM( CASE WHEN ar.RoleID = 2 AND ar.StageID >= 2 THEN ar.ReducedCredit ELSE 0 END) ClearedGivenCredit_dl
								FROM Cust_ArchiveAccount ar WITH(NOLOCK) 
									LEFT JOIN Custinfo c WITH(NOLOCK) ON ar.CustID = c.custid
									LEFT JOIN CustProductStatus ci WITH(NOLOCK) ON ar.CustID = ci.custid AND ci.CloseInfo > 0
									LEFT JOIN CustProductStatus agci WITH(NOLOCK) ON ar.recommend = agci.custid AND agci.CloseInfo > 0
								WHERE t.CustID = ar.mrecommend
									AND ISNULL(ar.ClosedDate,'') >= CASE WHEN @FilterDateType = 1 THEN @FromDate ELSE ISNULL(ar.ClosedDate,'') END
									AND ISNULL(ar.ClosedDate,'') <= CASE WHEN @FilterDateType = 1 THEN @ToDate ELSE ISNULL(ar.ClosedDate,'') END
									AND ISNULL(ar.DisabledDate,'') >= CASE WHEN @FilterDateType = 2 THEN @FromDate ELSE ISNULL(ar.DisabledDate,'') END
									AND ISNULL(ar.DisabledDate,'') <= CASE WHEN @FilterDateType = 2 THEN @ToDate ELSE ISNULL(ar.DisabledDate,'') END
									AND ISNULL(ar.SettingDeletedDate,'') >= CASE WHEN @FilterDateType = 3 THEN @FromDate ELSE ISNULL(ar.SettingDeletedDate,'') END
									AND ISNULL(ar.SettingDeletedDate,'') <= CASE WHEN @FilterDateType = 3 THEN @ToDate ELSE ISNULL(ar.SettingDeletedDate,'') END
									AND ISNULL(ar.AccountDeletedDate,'') >= CASE WHEN @FilterDateType = 4 THEN @FromDate ELSE ISNULL(ar.AccountDeletedDate,'') END
									AND ISNULL(ar.AccountDeletedDate,'') <= CASE WHEN @FilterDateType = 4 THEN @ToDate ELSE ISNULL(ar.AccountDeletedDate,'') END
									AND (ar.StageID >= 2 
											OR (ci.CustID IS NOT NULL AND ar.roleid > 2 )
											OR (agci.CustID IS NOT NULL AND ar.roleid <= 2 )
										)
									AND (ar.StageID >= 2 
											OR (NOT EXISTS ( SELECT 1 FROM #Exclude ex WHERE ar.custID IN (ex.mrecommend) AND ar.RoleID > 2)
												AND NOT EXISTS ( SELECT 1 FROM #Exclude ex WHERE ar.recommend = ex.recommend AND ar.RoleID <= 2)
											)
										)
								HAVING COUNT(1) > 0
								) arc
			WHERE t.RoleId = 3
			UNION ALL
			SELECT CustHeadlineID,HeadlineGroup,CustID,UserName,HeadlineType,RoleId,StageID
												,Cnt_Stage1Member,Cnt_Stage2Member,Cnt_Stage3Member,Cnt_Stage4Member
												,Cnt_Stage1Agent,Cnt_Stage2Agent,Cnt_Stage3Agent,Cnt_Stage4Agent
												,Cnt_Stage1Master,Cnt_Stage2Master,Cnt_Stage3Master,Cnt_Stage4Master,ToBeClearedGivenCredit_dl,ClearedGivenCredit_dl
			FROM #tmpGroup t 
				CROSS APPLY (	SELECT SUM( CASE WHEN ar.RoleID = 1 AND ar.StageID = 1 THEN 1 ELSE 0 END) Cnt_Stage1Member,
										SUM( CASE WHEN ar.RoleID = 1 AND ar.StageID = 2 THEN 1 ELSE 0 END) Cnt_Stage2Member,
										SUM( CASE WHEN ar.RoleID = 1 AND ar.StageID = 3 THEN 1 ELSE 0 END) Cnt_Stage3Member,
										SUM( CASE WHEN ar.RoleID = 1 AND ar.StageID = 4 THEN 1 ELSE 0 END) Cnt_Stage4Member,
										0 AS Cnt_Stage1Agent,
										0 AS Cnt_Stage2Agent,
										0 AS Cnt_Stage3Agent,
										0 AS Cnt_Stage4Agent,
										0 AS Cnt_Stage1Master,
										0 AS Cnt_Stage2Master,
										0 AS Cnt_Stage3Master,
										0 AS Cnt_Stage4Master,
										0 ToBeClearedGivenCredit_dl,
										0 ClearedGivenCredit_dl
								FROM Cust_ArchiveAccount ar WITH(NOLOCK) 
									LEFT JOIN CustProductStatus agci WITH(NOLOCK) ON ar.recommend = agci.custid AND agci.CloseInfo > 0
								WHERE t.CustID = ar.recommend
									AND ISNULL(ar.ClosedDate,'') >= CASE WHEN @FilterDateType = 1 THEN @FromDate ELSE ISNULL(ar.ClosedDate,'') END
									AND ISNULL(ar.ClosedDate,'') <= CASE WHEN @FilterDateType = 1 THEN @ToDate ELSE ISNULL(ar.ClosedDate,'') END
									AND ISNULL(ar.DisabledDate,'') >= CASE WHEN @FilterDateType = 2 THEN @FromDate ELSE ISNULL(ar.DisabledDate,'') END
									AND ISNULL(ar.DisabledDate,'') <= CASE WHEN @FilterDateType = 2 THEN @ToDate ELSE ISNULL(ar.DisabledDate,'') END
									AND ISNULL(ar.SettingDeletedDate,'') >= CASE WHEN @FilterDateType = 3 THEN @FromDate ELSE ISNULL(ar.SettingDeletedDate,'') END
									AND ISNULL(ar.SettingDeletedDate,'') <= CASE WHEN @FilterDateType = 3 THEN @ToDate ELSE ISNULL(ar.SettingDeletedDate,'') END
									AND ISNULL(ar.AccountDeletedDate,'') >= CASE WHEN @FilterDateType = 4 THEN @FromDate ELSE ISNULL(ar.AccountDeletedDate,'') END
									AND ISNULL(ar.AccountDeletedDate,'') <= CASE WHEN @FilterDateType = 4 THEN @ToDate ELSE ISNULL(ar.AccountDeletedDate,'') END
									AND (ar.StageID >= 2 
											OR agci.CustID IS NOT NULL
										)
									AND (ar.StageID >= 2 
											OR NOT EXISTS ( SELECT 1 FROM #Exclude ex WHERE ar.recommend = ex.recommend AND ar.RoleID <= 2)
										)
								HAVING COUNT(1) > 0
								) arc
			WHERE t.RoleId = 2
			UNION ALL
			SELECT CustHeadlineID,HeadlineGroup,CustID,UserName,HeadlineType,RoleId,StageID
												,Cnt_Stage1Member,Cnt_Stage2Member,Cnt_Stage3Member,Cnt_Stage4Member
												,Cnt_Stage1Agent,Cnt_Stage2Agent,Cnt_Stage3Agent,Cnt_Stage4Agent
												,Cnt_Stage1Master,Cnt_Stage2Master,Cnt_Stage3Master,Cnt_Stage4Master,ToBeClearedGivenCredit_dl,ClearedGivenCredit_dl
			FROM #tmpGroup t 
				CROSS APPLY (	SELECT  0 AS Cnt_Stage1Member,
										0 AS Cnt_Stage2Member,
										0 AS Cnt_Stage3Member,
										0 AS Cnt_Stage4Member,
										0 AS Cnt_Stage1Agent,
										0 AS Cnt_Stage2Agent,
										0 AS Cnt_Stage3Agent,
										0 AS Cnt_Stage4Agent,
										0 AS Cnt_Stage1Master,
										0 AS Cnt_Stage2Master,
										0 AS Cnt_Stage3Master,
										0 AS Cnt_Stage4Master,
										0 ToBeClearedGivenCredit_dl,
										0 ClearedGivenCredit_dl
								FROM Cust_ArchiveAccount ar WITH(NOLOCK)
									LEFT JOIN CustProductStatus agci WITH(NOLOCK) ON ar.recommend = agci.custid AND agci.CloseInfo > 0
								WHERE t.CustID = ar.CustID
									AND ISNULL(ar.ClosedDate,'') >= CASE WHEN @FilterDateType = 1 THEN @FromDate ELSE ISNULL(ar.ClosedDate,'') END
									AND ISNULL(ar.ClosedDate,'') <= CASE WHEN @FilterDateType = 1 THEN @ToDate ELSE ISNULL(ar.ClosedDate,'') END
									AND ISNULL(ar.DisabledDate,'') >= CASE WHEN @FilterDateType = 2 THEN @FromDate ELSE ISNULL(ar.DisabledDate,'') END
									AND ISNULL(ar.DisabledDate,'') <= CASE WHEN @FilterDateType = 2 THEN @ToDate ELSE ISNULL(ar.DisabledDate,'') END
									AND ISNULL(ar.SettingDeletedDate,'') >= CASE WHEN @FilterDateType = 3 THEN @FromDate ELSE ISNULL(ar.SettingDeletedDate,'') END
									AND ISNULL(ar.SettingDeletedDate,'') <= CASE WHEN @FilterDateType = 3 THEN @ToDate ELSE ISNULL(ar.SettingDeletedDate,'') END
									AND ISNULL(ar.AccountDeletedDate,'') >= CASE WHEN @FilterDateType = 4 THEN @FromDate ELSE ISNULL(ar.AccountDeletedDate,'') END
									AND ISNULL(ar.AccountDeletedDate,'') <= CASE WHEN @FilterDateType = 4 THEN @ToDate ELSE ISNULL(ar.AccountDeletedDate,'') END
									AND (ar.StageID >= 2 
											OR agci.CustID IS NOT NULL
										)
									AND (ar.StageID >= 2 
											OR NOT EXISTS ( SELECT 1 FROM #Exclude ex WHERE ar.recommend = ex.recommend AND ar.RoleID <= 2)
										)
								HAVING COUNT(1) > 0
								) arc
			WHERE t.RoleId = 1
			) temp
		ORDER BY CASE WHEN CustHeadlineID <> 0 THEN 0 ELSE 1 END,
				CASE WHEN @SortType = 1 THEN HeadlineGroup END ASC ,
				CASE WHEN @SortType = 2 THEN HeadlineGroup END DESC,
				UserName
	END

	SELECT @TotalItems = COUNT(1) 
	FROM #CustHeadline_Archived

	SELECT t.RN AS RowNumber,t.CustHeadlineID,t.HeadlineGroup,t.CustID,t.UserName,t.HeadlineType,t.RoleId
		,StageID = CASE WHEN cps.CloseInfo > 0 OR t.StageID > 1 THEN t.StageID END
		,StatusID =  CASE WHEN ci.Enabled = 1 AND cps.CloseInfo = 0 AND cps.SuspendInfo = 0 THEN 1 --Open 
						  WHEN ci.Enabled = 1 AND cps.CloseInfo = 0 AND cps.SuspendInfo > 0 THEN 2 --Suspended 
						  WHEN ci.Enabled = 1 AND cps.CloseInfo > 0 THEN 3 --Closed    
						  WHEN ci.Enabled = 0 THEN 4 --Disabled
						  WHEN ci.custid IS NULL THEN 5 --Deleted
						END            
		,ToBeClearedGivenCredit = CASE WHEN ar.StageID > 1 THEN NULL
										WHEN ar.StageID = 1 AND cps.CloseInfo > 0 THEN ci.credit
										ELSE t.ToBeClearedGivenCredit_dl --downline ToBeClearedGivenCredit 
									END
		,ClearedGivenCredit    = ISNULL(CASE WHEN ar.StageID > 1 THEN ar.ReducedCredit
										ELSE t.ClearedGivenCredit_dl --dl.ClearedGivenCredit
									END,0)
		,lastlogged       = CASE WHEN ar.StageID = 4 THEN ar.Lastlogged
								ELSE c.lastlogged 
							END             
		,ClosedDate       = CASE WHEN cps.CloseInfo > 0 THEN ar.ClosedDate END
		,DisabledDate     = ar.DisabledDate      
		,SettingDeletedDate = ar.SettingDeletedDate
		,AccountDeletedDate = ar.AccountDeletedDate
		,t.Cnt_Stage1Member,t.Cnt_Stage2Member,t.Cnt_Stage3Member,t.Cnt_Stage4Member
		,t.Cnt_Stage1Agent,t.Cnt_Stage2Agent,t.Cnt_Stage3Agent,t.Cnt_Stage4Agent
		,t.Cnt_Stage1Master,t.Cnt_Stage2Master,t.Cnt_Stage3Master,t.Cnt_Stage4Master
	FROM #CustHeadline_Archived t
		LEFT JOIN custinfo ci WITH(NOLOCK) ON t.CustID = ci.custid
		LEFT JOIN customer c WITH(NOLOCK) ON t.CustID = c.custid
		LEFT JOIN CustProductStatus cps WITH(NOLOCK) ON t.CustID = cps.custid
		LEFT JOIN Cust_ArchiveAccount ar WITH(NOLOCK) ON t.CustID = ar.custid
	WHERE t.RN BETWEEN @rowstart AND @rowend 	
	ORDER BY t.RN

	--get yesterday balance
	DECLARE @CustIdList VARCHAR(MAX) = ''

	IF @TotalItems = 0
	BEGIN
		SELECT 0 AS CustId, CAST(0 AS MONEY) AS	YesterdayTotalBalance WHERE 1 <> 1
		RETURN
	END

	SELECT @CustIdList = @CustIdList + ',' + CONVERT(varchar,CustID)
	FROM  #CustHeadline_Archived
	WHERE RN BETWEEN @rowstart AND @rowend 	
		AND ISNULL(StageID,0) <> 4 -- not get balance for deleted account

	SELECT @CustIdList = STUFF(@CustIdList,1,1,'')

	EXEC DBAGE.bodb02.dbo.Acc_CustomerSelBalanceInfo @CustIdList = @CustIdList

	--RETURNLB:

	DROP TABLE #FilterRole
	DROP TABLE #tmpDirectCust
	DROP TABLE #tmpGroup
	DROP TABLE #tmpGroupHeadline
	DROP TABLE #CustHeadline_Archived
	DROP TABLE #Exclude
	DROP TABLE #TmpSuper_Archive
END
GO


