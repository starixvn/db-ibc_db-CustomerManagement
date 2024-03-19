/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,wsv_nap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_DormantDownlineListByHeadline_Sel] (
	@FilterUsername VARCHAR(30) = NULL, 
	@FilterHeadlineType  TINYINT   = NULL, 
	@FilterHeadlineGroup VARCHAR(30) = NULL, 
	@NotAssignGroupOnly  BIT         = 0, --= 1: only show Not Assign Group Headline 
	@FilterRoleID   TINYINT = 0, 
	@FilterStageID  TINYINT = 0, 
	@FilterDateType TINYINT = NULL, 
	@FromDate       DATETIME = NULL, 
	@ToDate         DATETIME = NULL, 
	@SortType      TINYINT = 1, 
	@PageSize       INT     = 50, 
	@PageIndex      INT     = 1, 
	@TotalItems     INT     = 0 OUTPUT
)
AS
/*
	Created: 20210622@Eden
	Task : get the dormant downline accounts which are being processed by the archive account process.
	DB: DBCUST/CUSTDB
	Original:

	Revisions:  
	- 20210622@Eden: All sites - Dormant SMA Account List [RedmineID: #155969]
	- 20230823@Eden : Archive super level 789y (Stage 3 and Stage 4) [Redmine: #183447]


	Parameter Definition
		-@FilterDateType: apply for headline dirrect acccounts' downlines
			NULL: not apply filter <default>
			0: All Archive Date Types
			1: Close Date
			2: Disable Date
			3: Delete Setting Date
			4: Delete Account Date


		-@FilterStageID: apply for headline dirrect acccounts
			0: All Stages <default>
			1: Close Account
			2: Disable Account
			3: Delete Setting
			4: Delete Account

		-@FilterRoleID (Level)
			0 - All 
			3 - Master
			2 - Agent 
			1 - Member
		-@SortType : Order by
			1 : By Username ASC
			2 : By Username DESC
			3 : By StageID ASC, Username ASC
			4 : By StageID DESC, Username ASC

	Example: 
	DECLARE @TotalItems	INT 
	EXEC Acc_DormantDownlineListByHeadline_Sel 
		@FilterUsername = 'drtest07_S1',
		@FilterHeadlineType = NULL,
		@FilterRoleID    = 0,
		@FilterStageID	= 0,
		@PageSize	= 50,
		@PageIndex	= 1,
		@TotalItems = @TotalItems OUTPUT
	SELECT @TotalItems
	
	*/
BEGIN
	SET NOCOUNT ON
	DECLARE @RowCount int, @RowStart int, @RowEnd int
	DECLARE @CustID_ByUserName INT
	DECLARE @Cust_RoleID TINYINT, @recommend INT
	DECLARE @NotAssignGroupName VARCHAR(30) = 'Not assigned to group'

	SELECT @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1

	CREATE TABLE #FilterCustByUserName(CustID INT, recommend INT, mrecommend INT, srecommend INT,RoleID TINYINT)
	CREATE TABLE #Cust_info(CustID INT, DirectCustID INT, DirectUsername VARCHAR(30), HeadlineType TINYINT,CustHeadlineID INT, HeadlineGroup VARCHAR(30), recommend INT, mrecommend INT, srecommend INT,RoleID TINYINT)
	CREATE TABLE #Cust_ArchiveAccount_Temp(
		 CustID                 INT, 
		 Username               VARCHAR(30), 
		 RoleID                 TINYINT, 
		 StatusID               TINYINT, 
		 StageID				TINYINT, 
		 ToBeClearedGivenCredit MONEY, 
		 ClearedGivenCredit     MONEY, 
		 lastlogged             DATETIME,
		 ClosedDate             DATETIME, 
		 DisabledDate           DATETIME, 
		 SettingDeletedDate     DATETIME, 
		 IsWarningTicket		BIT,
		 AccountDeletedDate		DATETIME
	);
	
	CREATE TABLE #Cust_ArchiveAccount(
		 CustID                 INT, 
		 Username               VARCHAR(30), 
		 RoleID                 TINYINT, 
		 StatusID               TINYINT, 
		 StageID				TINYINT, 
		 ToBeClearedGivenCredit MONEY, 
		 ClearedGivenCredit     MONEY, 
		 lastlogged             DATETIME,
		 ClosedDate             DATETIME, 
		 DisabledDate           DATETIME, 
		 SettingDeletedDate     DATETIME, 
		 IsWarningTicket		BIT,
		 AccountDeletedDate		DATETIME,
		 RowNumber              INT IDENTITY(1,1) PRIMARY KEY CLUSTERED
	);

	CREATE NONCLUSTERED INDEX ix_TmpCust_ArchiveAccount_CustID ON #Cust_ArchiveAccount(CustID) INCLUDE(stageid,roleid)

	CREATE TABLE #Exclude(
		recommend  INT, 
		mrecommend INT
	);
	CREATE NONCLUSTERED INDEX ix_TmpExclude_recommend ON #Exclude(recommend)
	CREATE NONCLUSTERED INDEX ix_TmpExclude_mrecommend ON #Exclude(mrecommend)

	CREATE TABLE #Warning(
		mrecommend INT, 
		recommend  INT
	);
	CREATE NONCLUSTERED INDEX ix_TmpWarning_recommend ON #Exclude(recommend)
	CREATE NONCLUSTERED INDEX ix_TmpWarning_mrecommend ON #Exclude(mrecommend)

	IF @NotAssignGroupOnly = 1 --Disable Search by Headline Group and Headline Type
		SELECT @FilterHeadlineGroup = @NotAssignGroupName, @FilterHeadlineType = NULL 

	IF ISNULL(@FilterHeadlineGroup,'') != ''
		SET @FilterHeadlineGroup = '%' + @FilterHeadlineGroup + '%'

	IF ISNULL(@FilterUsername,'') != '' -- Show page detail
	BEGIN 
		INSERT INTO #FilterCustByUserName(CustID,recommend,mrecommend,srecommend,RoleID)
		SELECT c.CustID,c.recommend,c.mrecommend,c.srecommend,c.RoleID
		FROM custInfo c WITH(NOLOCK) 
		WHERE c.username = @FilterUsername
			AND c.currency <> 20
			AND c.srecommend NOT IN( SELECT custid FROM Dep_CustSuper WITH(NOLOCK))

		IF NOT EXISTS(SELECT 1 FROM #FilterCustByUserName)
		BEGIN
			INSERT INTO #FilterCustByUserName(CustID,recommend,mrecommend,srecommend,RoleID)
			SELECT CustID,recommend,mrecommend,srecommend,c.RoleID
			FROM Cust_ArchiveAccount c WITH(NOLOCK) 
			WHERE username = @FilterUsername
				AND c.StageID = 4
		END

		--not view finance accounts
		DELETE t
		FROM #FilterCustByUserName t
			INNER JOIN CustSuper fn WITH(NOLOCK,FORCESEEK)
				ON t.CustID = fn.custid 
		WHERE fn.IsInternal = 1 
			AND t.RoleId = 4

		DELETE t
		FROM #FilterCustByUserName t
			INNER JOIN CustMaster fn WITH(NOLOCK,FORCESEEK)
				ON t.CustID = fn.custid 
		WHERE fn.IsInternal = 1 
			AND t.RoleId = 3

		DELETE t
		FROM #FilterCustByUserName t
			INNER JOIN CustAgent fn WITH(NOLOCK,FORCESEEK)
				ON t.CustID = fn.custid 
		WHERE fn.IsInternal = 1 
			AND t.RoleId = 2

		DELETE t
		FROM #FilterCustByUserName t
			INNER JOIN CustAgent fn WITH(NOLOCK,FORCESEEK)
				ON t.recommend = fn.custid 
		WHERE fn.IsInternal = 1 
			AND t.RoleId = 1

		INSERT INTO #Cust_info(CustID,DirectCustID,DirectUsername,HeadlineType,CustHeadlineID,HeadlineGroup,recommend,mrecommend,srecommend,RoleID)
		SELECT t.CustID AS CustID
			, c.CustID AS DirectCustID
			, ISNULL(dri.username,ar.username) AS DirectUsername
			, hl.HeadlineType
			, ISNULL(hl.CustID,0) AS CustHeadlineID
			, ISNULL(chl.username,@NotAssignGroupName) AS HeadlineGroup
			, t.recommend,t.mrecommend,t.srecommend,t.RoleID
		FROM CustDirectAccount c WITH(NOLOCK)
			INNER JOIN #FilterCustByUserName t ON c.CustID IN ( t.CustID,t.recommend,t.mrecommend,t.srecommend)
			LEFT JOIN dbo.custAccount ca WITH (NOLOCK) ON c.CustID = ca.custid AND groupID <> 0
			LEFT JOIN dbo.CustGroupHeadline hl WITH (NOLOCK) ON ca.groupID = hl.GroupID
			LEFT JOIN custInfo chl WITH(NOLOCK) ON chl.custid = hl.CustID
			LEFT JOIN custInfo dri WITH(NOLOCK) ON dri.custid = c.CustID
			LEFT JOIN Cust_ArchiveAccount ar WITH(NOLOCK) ON ar.CustID = c.CustID AND ar.StageID = 4

		DELETE c
		FROM #Cust_info c
		WHERE c.HeadlineType <> @FilterHeadlineType
			OR (c.HeadlineType IS NULL AND @FilterHeadlineType IS NOT NULL)

		DELETE c
		FROM #Cust_info c
		WHERE c.HeadlineGroup NOT LIKE @FilterHeadlineGroup

		SELECT c.CustID,c.DirectCustID,c.DirectUsername,c.HeadlineType,c.CustHeadlineID,c.HeadlineGroup,c.recommend,c.mrecommend,c.srecommend,c.RoleID,
			@FilterUsername AS Username,ISNULL(sr.Username,asr.Username) AS SuperName, ISNULL(mr.Username,amr.Username) AS MasterName,ISNULL(rc.Username,arc.Username) AS AgentName 
		FROM #Cust_info c
			LEFT JOIN custinfo sr WITH(NOLOCK)
				ON c.srecommend = sr.custid
			LEFT JOIN custinfo mr WITH(NOLOCK)
				ON c.mrecommend = mr.custid
			LEFT JOIN custinfo rc WITH(NOLOCK)
				ON c.recommend = rc.custid
			LEFT JOIN Cust_ArchiveAccount asr WITH(NOLOCK)
				ON c.srecommend = asr.custid
			LEFT JOIN Cust_ArchiveAccount amr WITH(NOLOCK)
				ON c.mrecommend = amr.custid
			LEFT JOIN Cust_ArchiveAccount arc WITH(NOLOCK)
				ON c.recommend = arc.custid

		SELECT TOP (1) @CustID_ByUserName = CustID, @Cust_RoleID = roleid, @recommend = recommend FROM #Cust_info
	END

	SELECT @ToDate = CONVERT(VARCHAR(10),CONVERT(DATE,@ToDate)) + ' 23:59:59.998'

	IF @Cust_RoleID = 4
	BEGIN
		INSERT INTO #Exclude(recommend,mrecommend)
		SELECT a.recommend,a.mrecommend
		FROM custInfo a WITH(NOLOCK) 
			INNER JOIN Cust_ArchiveAccount c WITH(NOLOCK) 
				ON a.custid = c.CustID
			INNER JOIN CustProductStatus cps WITH (NOLOCK) ON cps.CustID = a.custid
		WHERE a.srecommend = @CustID_ByUserName AND a.RoleID IN(2,3,4)
			AND cps.CloseInfo = 0
		UNION
		SELECT a.custid,MAX(a.mrecommend) as mrecommend
		FROM custInfo a WITH(NOLOCK) 
			INNER JOIN Cust_ArchiveAccount c WITH(NOLOCK) 
				ON a.custid = c.CustID
			INNER JOIN custInfo dl WITH(NOLOCK) 
				ON dl.recommend = a.custid AND dl.roleid = 1
		WHERE a.srecommend = @CustID_ByUserName 
			AND a.roleid = 2
		GROUP BY a.custid
		HAVING COUNT(dl.custid) > MAX(c.TotalDownline)
		UNION
		SELECT 0,a.custid
		FROM custInfo a WITH(NOLOCK) 
			INNER JOIN Cust_ArchiveAccount c WITH(NOLOCK) 
				ON a.custid = c.CustID
			INNER JOIN custInfo dl WITH(NOLOCK) 
				ON dl.mrecommend = a.custid AND dl.roleid IN (1,2)
		WHERE a.srecommend = @CustID_ByUserName
			AND a.roleid = 3 
		GROUP BY a.custid
		HAVING COUNT(dl.custid) > MAX(c.TotalDownline)

		INSERT INTO #Warning(recommend,mrecommend)
		SELECT DISTINCT a.custid,a.mrecommend
		FROM Customer a WITH(NOLOCK) 
			INNER JOIN Cust_ArchiveAccount c WITH(NOLOCK) 
				ON a.custid = c.CustID
			INNER JOIN Customer dl WITH(NOLOCK) 
				ON dl.recommend = a.custid AND dl.roleid = 1
		WHERE a.srecommend = @CustID_ByUserName 
			AND a.roleid = 2
			AND dl.lastlogged > c.ClosedDate

		INSERT INTO #Cust_ArchiveAccount_Temp(
			 CustID                
			,Username              
			,RoleID              
			,StatusID              
			,StageID          
			,ToBeClearedGivenCredit
			,ClearedGivenCredit    
			,lastlogged                    
			,ClosedDate            
			,DisabledDate          
			,SettingDeletedDate
			,IsWarningTicket     
		)     
		SELECT bc.CustID,
			   ci.Username, 
			   ci.roleID,
			   CASE WHEN ci.Enabled = 0 THEN 4
					ELSE 3
			   END AS StatusID,
			   bc.StageID,
			   CASE WHEN bc.StageID = 1 THEN ci.credit
					--ELSE 0 
			   END AS ToBeClearedGivenCredit,
			   CASE WHEN bc.StageID <> 1 THEN bc.ReducedCredit
					--ELSE 0 
			   END AS ClearedGivenCredit,
			   c.lastlogged,
			   bc.ClosedDate,
			   bc.DisabledDate,
			   bc.SettingDeletedDate,
			   IsWarningTicket = CASE WHEN w.recommend IS NOT NULL THEN 1 
									  WHEN wm.mrecommend IS NOT NULL THEN 1
									ELSE 0 END
		FROM Cust_ArchiveAccount bc WITH(NOLOCK)
			 INNER JOIN custInfo ci WITH(NOLOCK) ON bc.CustID = ci.custid
			 INNER JOIN Customer c WITH(NOLOCK) ON bc.custid = c.custid
			 LEFT JOIN #Warning w ON ci.recommend = w.recommend
			 LEFT JOIN #Warning wm ON ci.custid = wm.mrecommend
		WHERE ci.roleid = CASE WHEN ISNULL(@FilterRoleID,0) <> 0 THEN @FilterRoleID ELSE ci.roleid END 
			  AND bc.StageID = CASE WHEN ISNULL(@FilterStageID,0) = 0 THEN bc.StageID ELSE @FilterStageID END 
			  AND bc.srecommend = @CustID_ByUserName
			  AND NOT EXISTS( SELECT 1 FROM #Exclude WHERE ci.recommend = recommend AND ci.roleid IN (1,2))
			  AND NOT EXISTS( SELECT 1 FROM #Exclude WHERE ci.custid = mrecommend)
			  AND ci.custid <> @CustID_ByUserName
			  AND bc.StageID <> 4
		ORDER BY bc.StageID, ci.Username

		--> Get data for S4
		INSERT INTO #Cust_ArchiveAccount_Temp(
			 CustID                
			,Username              
			,RoleID              
			,StatusID              
			,StageID          
			,ToBeClearedGivenCredit
			,ClearedGivenCredit    
			,lastlogged                    
			,ClosedDate            
			,DisabledDate          
			,SettingDeletedDate
			,IsWarningTicket 
			,AccountDeletedDate    
		)     
		SELECT bc.CustID,
			   bc.Username, 
			   bc.roleID,
			   5 AS StatusID, --Deleted
			   bc.StageID,
			   NULL AS ToBeClearedGivenCredit,
			   bc.ReducedCredit AS ClearedGivenCredit,
			   bc.lastlogged,
			   bc.ClosedDate,
			   bc.DisabledDate,
			   bc.SettingDeletedDate,
			   0 AS IsWarningTicket,
			   bc.AccountDeletedDate
		FROM Cust_ArchiveAccount bc WITH(NOLOCK)
		WHERE bc.roleid = CASE WHEN ISNULL(@FilterRoleID,0) <> 0 THEN @FilterRoleID ELSE bc.roleid END 
			  AND bc.StageID = CASE WHEN ISNULL(@FilterStageID,0) = 0 THEN bc.StageID ELSE @FilterStageID END 
			  AND bc.srecommend = @CustID_ByUserName
			  AND bc.custid <> @CustID_ByUserName
			  AND bc.StageID = 4
		ORDER BY bc.Username

	END
	IF @Cust_RoleID = 3
	BEGIN
		INSERT INTO #Exclude(recommend,mrecommend)
		SELECT a.recommend,a.mrecommend
		FROM custInfo a WITH(NOLOCK) 
			INNER JOIN Cust_ArchiveAccount c WITH(NOLOCK) 
				ON a.custid = c.CustID
			INNER JOIN CustProductStatus cps WITH (NOLOCK) ON cps.CustID = a.custid
		WHERE a.mrecommend = @CustID_ByUserName AND a.RoleID IN(2,3)
			AND cps.CloseInfo = 0
		UNION
		SELECT a.custid,MAX(a.mrecommend) as mrecommend
		FROM custInfo a WITH(NOLOCK) 
			INNER JOIN Cust_ArchiveAccount c WITH(NOLOCK) 
				ON a.custid = c.CustID
			INNER JOIN custInfo dl WITH(NOLOCK) 
				ON dl.recommend = a.custid AND dl.roleid = 1
		WHERE a.mrecommend = @CustID_ByUserName 
			AND a.roleid = 2
		GROUP BY a.custid
		HAVING COUNT(dl.custid) > MAX(c.TotalDownline)

		INSERT INTO #Warning(recommend,mrecommend)
		SELECT DISTINCT a.custid,a.mrecommend
		FROM Customer a WITH(NOLOCK) 
			INNER JOIN Cust_ArchiveAccount c WITH(NOLOCK) 
				ON a.custid = c.CustID
			INNER JOIN Customer dl WITH(NOLOCK) 
				ON dl.recommend = a.custid AND dl.roleid = 1
		WHERE a.mrecommend = @CustID_ByUserName 
			AND a.roleid = 2
			AND dl.lastlogged > c.ClosedDate

		INSERT INTO #Cust_ArchiveAccount_Temp(
			 CustID                
			,Username              
			,RoleID              
			,StatusID              
			,StageID          
			,ToBeClearedGivenCredit
			,ClearedGivenCredit    
			,lastlogged                    
			,ClosedDate            
			,DisabledDate          
			,SettingDeletedDate
			,IsWarningTicket     
		)     
		SELECT bc.CustID,
			   ci.Username, 
			   ci.roleID,
			   CASE WHEN ci.Enabled = 0 THEN 4
					ELSE 3
			   END AS StatusID,
			   bc.StageID,
			   CASE WHEN bc.StageID = 1 THEN ci.credit
					--ELSE 0 
			   END AS ToBeClearedGivenCredit,
			   CASE WHEN bc.StageID <> 1 THEN bc.ReducedCredit
					--ELSE 0 
			   END AS ClearedGivenCredit,
			   c.lastlogged,
			   bc.ClosedDate,
			   bc.DisabledDate,
			   bc.SettingDeletedDate,
			   IsWarningTicket = CASE WHEN w.recommend IS NOT NULL THEN 1 
									ELSE 0 END
		FROM Cust_ArchiveAccount bc WITH(NOLOCK)
			 INNER JOIN custInfo ci WITH(NOLOCK) ON bc.CustID = ci.custid
			 INNER JOIN Customer c WITH(NOLOCK) ON bc.custid = c.custid
			 LEFT JOIN #Warning w ON ci.recommend = w.recommend
		WHERE ci.roleid = CASE WHEN ISNULL(@FilterRoleID,0) <> 0 THEN @FilterRoleID ELSE ci.roleid END 
			  AND bc.StageID = CASE WHEN ISNULL(@FilterStageID,0) = 0 THEN bc.StageID ELSE @FilterStageID END
			  AND bc.mrecommend = @CustID_ByUserName
			  AND NOT EXISTS( SELECT 1 FROM #Exclude WHERE ci.recommend = recommend  AND ci.roleid IN (1,2))
			  AND ci.custid <> @CustID_ByUserName
			  AND bc.StageID <> 4
		ORDER BY bc.StageID, ci.Username

		--> Get data for S4
		INSERT INTO #Cust_ArchiveAccount_Temp(
			 CustID                
			,Username              
			,RoleID              
			,StatusID              
			,StageID          
			,ToBeClearedGivenCredit
			,ClearedGivenCredit    
			,lastlogged                    
			,ClosedDate            
			,DisabledDate          
			,SettingDeletedDate
			,IsWarningTicket 
			,AccountDeletedDate    
		)     
		SELECT bc.CustID,
			   bc.Username, 
			   bc.roleID,
			   5 AS StatusID, --Deleted
			   bc.StageID,
			   NULL AS ToBeClearedGivenCredit,
			   bc.ReducedCredit AS ClearedGivenCredit,
			   bc.lastlogged,
			   bc.ClosedDate,
			   bc.DisabledDate,
			   bc.SettingDeletedDate,
			   0 AS IsWarningTicket,
			   bc.AccountDeletedDate
		FROM Cust_ArchiveAccount bc WITH(NOLOCK)
		WHERE bc.roleid = CASE WHEN ISNULL(@FilterRoleID,0) <> 0 THEN @FilterRoleID ELSE bc.roleid END 
			  AND bc.StageID = CASE WHEN ISNULL(@FilterStageID,0) = 0 THEN bc.StageID ELSE @FilterStageID END
			  AND bc.mrecommend = @CustID_ByUserName
			  AND bc.custid <> @CustID_ByUserName
			  AND bc.StageID = 4
		ORDER BY bc.Username
	END
	IF @Cust_RoleID = 2
	BEGIN
		INSERT INTO #Exclude(recommend)
		SELECT a.custid
		FROM custInfo a WITH(NOLOCK) 
			INNER JOIN Cust_ArchiveAccount c WITH(NOLOCK) 
				ON a.custid = c.CustID
			INNER JOIN CustProductStatus cps WITH (NOLOCK) ON cps.CustID = a.custid
		WHERE a.custid = @CustID_ByUserName
			AND cps.CloseInfo = 0
		UNION
		SELECT a.custid
		FROM custInfo a WITH(NOLOCK) 
			INNER JOIN Cust_ArchiveAccount c WITH(NOLOCK) 
				ON a.custid = c.CustID
			INNER JOIN custInfo dl WITH(NOLOCK) 
				ON dl.recommend = a.custid AND dl.roleid = 1
		WHERE a.custid = @CustID_ByUserName 
		GROUP BY a.custid
		HAVING COUNT(dl.custid) > MAX(c.TotalDownline)

		INSERT INTO #Warning(recommend)
		SELECT DISTINCT a.custid
		FROM Customer a WITH(NOLOCK) 
			INNER JOIN Cust_ArchiveAccount c WITH(NOLOCK) 
				ON a.custid = c.CustID
			INNER JOIN Customer dl WITH(NOLOCK) 
				ON dl.recommend = a.custid AND dl.roleid = 1
		WHERE a.custid = @CustID_ByUserName 
			AND dl.lastlogged > c.ClosedDate

		INSERT INTO #Cust_ArchiveAccount_Temp(
			 CustID                
			,Username              
			,RoleID              
			,StatusID              
			,StageID          
			,ToBeClearedGivenCredit
			,ClearedGivenCredit    
			,lastlogged                    
			,ClosedDate            
			,DisabledDate          
			,SettingDeletedDate
			,IsWarningTicket     
		)     
		SELECT bc.CustID,
			   ci.Username, 
			   ci.roleID,
			   CASE WHEN ci.Enabled = 0 THEN 4 --Disabled
					ELSE 3 --Closed
			   END AS StatusID,
			   bc.StageID,
			   CASE WHEN bc.StageID = 1 THEN ci.credit
					--ELSE 0 
			   END AS ToBeClearedGivenCredit,
			   CASE WHEN bc.StageID <> 1 THEN bc.ReducedCredit
					--ELSE 0 
			   END AS ClearedGivenCredit,
			   c.lastlogged,
			   bc.ClosedDate,
			   bc.DisabledDate,
			   bc.SettingDeletedDate,
			   IsWarningTicket = CASE WHEN w.recommend IS NOT NULL THEN 1 
									ELSE 0 END
		FROM Cust_ArchiveAccount bc WITH(NOLOCK)
			 INNER JOIN custInfo ci WITH(NOLOCK) ON bc.CustID = ci.custid
			 INNER JOIN Customer c WITH(NOLOCK) ON bc.custid = c.custid
			 LEFT JOIN #Warning w ON ci.recommend = w.recommend
		WHERE ci.roleid = CASE WHEN ISNULL(@FilterRoleID,0) <> 0 THEN @FilterRoleID ELSE ci.roleid END 
			  AND bc.StageID = CASE WHEN ISNULL(@FilterStageID,0) = 0 THEN bc.StageID ELSE @FilterStageID END
			  AND bc.recommend = @CustID_ByUserName
			  AND NOT EXISTS( SELECT 1 FROM #Exclude WHERE ci.recommend = recommend  AND ci.roleid IN (1,2))
			  AND ci.custid <> @CustID_ByUserName
			  AND bc.StageID <> 4
		ORDER BY bc.StageID, ci.Username

		--> Get data for S4
		INSERT INTO #Cust_ArchiveAccount_Temp(
			 CustID                
			,Username              
			,RoleID              
			,StatusID              
			,StageID          
			,ToBeClearedGivenCredit
			,ClearedGivenCredit    
			,lastlogged                    
			,ClosedDate            
			,DisabledDate          
			,SettingDeletedDate
			,IsWarningTicket 
			,AccountDeletedDate    
		)     
		SELECT bc.CustID,
			   bc.Username, 
			   bc.roleID,
			   5 AS StatusID, --Deleted
			   bc.StageID,
			   NULL AS ToBeClearedGivenCredit,
			   bc.ReducedCredit AS ClearedGivenCredit,
			   bc.lastlogged,
			   bc.ClosedDate,
			   bc.DisabledDate,
			   bc.SettingDeletedDate,
			   0 AS IsWarningTicket,
			   bc.AccountDeletedDate
		FROM Cust_ArchiveAccount bc WITH(NOLOCK)
		WHERE bc.roleid = CASE WHEN ISNULL(@FilterRoleID,0) <> 0 THEN @FilterRoleID ELSE bc.roleid END 
			  AND bc.StageID = CASE WHEN ISNULL(@FilterStageID,0) = 0 THEN bc.StageID ELSE @FilterStageID END
			  AND bc.recommend = @CustID_ByUserName
			  AND bc.custid <> @CustID_ByUserName
			  AND bc.StageID = 4
		ORDER BY bc.Username
	END
	IF @Cust_RoleID = 1
	BEGIN
		INSERT INTO #Exclude(recommend)
		SELECT a.custid
		FROM custInfo a WITH(NOLOCK) 
			INNER JOIN Cust_ArchiveAccount c WITH(NOLOCK) 
				ON a.custid = c.CustID
			INNER JOIN CustProductStatus cps WITH (NOLOCK) ON cps.CustID = a.custid
		WHERE a.custid = @recommend
			AND cps.CloseInfo = 0
		UNION
		SELECT a.custid
		FROM custInfo a WITH(NOLOCK) 
			INNER JOIN Cust_ArchiveAccount c WITH(NOLOCK) 
				ON a.custid = c.CustID
			INNER JOIN custInfo dl WITH(NOLOCK) 
				ON dl.recommend = a.custid AND dl.roleid = 1
		WHERE a.custid = @recommend 
		GROUP BY a.custid
		HAVING COUNT(dl.custid) > MAX(c.TotalDownline)

		INSERT INTO #Warning(recommend)
		SELECT DISTINCT a.custid
		FROM Customer a WITH(NOLOCK) 
			INNER JOIN Cust_ArchiveAccount c WITH(NOLOCK) 
				ON a.custid = c.CustID
			INNER JOIN Customer dl WITH(NOLOCK) 
				ON dl.recommend = a.custid AND dl.roleid = 1
		WHERE a.custid = @recommend 
			AND dl.lastlogged > c.ClosedDate

		IF NOT EXISTS( SELECT 1 FROM #Exclude)
		BEGIN
			INSERT INTO #Cust_ArchiveAccount_Temp(
				 CustID                
				,Username              
				,RoleID              
				,StatusID              
				,StageID          
				,ToBeClearedGivenCredit
				,ClearedGivenCredit    
				,lastlogged                    
				,ClosedDate            
				,DisabledDate          
				,SettingDeletedDate
				,IsWarningTicket     
			)     
			SELECT bc.CustID,
				   ci.Username, 
				   ci.roleID,
				   CASE WHEN ci.Enabled = 0 THEN 4 --Disabled
						ELSE 3 --Closed
				   END AS StatusID,
				   bc.StageID,
				   CASE WHEN bc.StageID = 1 THEN ci.credit
						--ELSE 0 
				   END AS ToBeClearedGivenCredit,
				   CASE WHEN bc.StageID <> 1 THEN bc.ReducedCredit
						--ELSE 0 
				   END AS ClearedGivenCredit,
				   c.lastlogged,
				   bc.ClosedDate,
				   bc.DisabledDate,
				   bc.SettingDeletedDate,
				   IsWarningTicket = CASE WHEN w.recommend IS NOT NULL THEN 1 
										ELSE 0 END
			FROM Cust_ArchiveAccount bc WITH(NOLOCK)
				 INNER JOIN custInfo ci WITH(NOLOCK) ON bc.CustID = ci.custid
				 INNER JOIN Customer c WITH(NOLOCK) ON bc.custid = c.custid
				 LEFT JOIN #Warning w ON ci.recommend = w.recommend
			WHERE ci.roleid = CASE WHEN ISNULL(@FilterRoleID,0) <> 0 THEN @FilterRoleID ELSE ci.roleid END 
				  AND bc.StageID = CASE WHEN ISNULL(@FilterStageID,0) = 0 THEN bc.StageID ELSE @FilterStageID END
				  AND bc.CustID = @CustID_ByUserName
				  AND bc.StageID <> 4
			ORDER BY bc.StageID, ci.Username
		END

		--> Get data for S4
		INSERT INTO #Cust_ArchiveAccount_Temp(
			 CustID                
			,Username              
			,RoleID              
			,StatusID              
			,StageID          
			,ToBeClearedGivenCredit
			,ClearedGivenCredit    
			,lastlogged                    
			,ClosedDate            
			,DisabledDate          
			,SettingDeletedDate
			,IsWarningTicket 
			,AccountDeletedDate    
		)     
		SELECT bc.CustID,
			   bc.Username, 
			   bc.roleID,
			   5 AS StatusID, --Deleted
			   bc.StageID,
			   NULL AS ToBeClearedGivenCredit,
			   bc.ReducedCredit AS ClearedGivenCredit,
			   bc.lastlogged,
			   bc.ClosedDate,
			   bc.DisabledDate,
			   bc.SettingDeletedDate,
			   0 AS IsWarningTicket,
			   bc.AccountDeletedDate
		FROM Cust_ArchiveAccount bc WITH(NOLOCK)
		WHERE bc.roleid = CASE WHEN ISNULL(@FilterRoleID,0) <> 0 THEN @FilterRoleID ELSE bc.roleid END 
			  AND bc.StageID = CASE WHEN ISNULL(@FilterStageID,0) = 0 THEN bc.StageID ELSE @FilterStageID END
			  AND bc.CustID = @CustID_ByUserName
			  AND bc.StageID = 4
		ORDER BY bc.Username
	END
	
	IF @FilterDateType = 0
	BEGIN
		INSERT INTO #Cust_ArchiveAccount(
			 CustID                
			,Username              
			,RoleID              
			,StatusID              
			,StageID          
			,ToBeClearedGivenCredit
			,ClearedGivenCredit    
			,lastlogged                    
			,ClosedDate            
			,DisabledDate          
			,SettingDeletedDate
			,IsWarningTicket 
			,AccountDeletedDate    
		)
		SELECT CustID                
			,Username              
			,RoleID              
			,StatusID              
			,StageID          
			,ToBeClearedGivenCredit
			,ClearedGivenCredit    
			,lastlogged                    
			,ClosedDate            
			,DisabledDate          
			,SettingDeletedDate
			,IsWarningTicket 
			,AccountDeletedDate         
		FROM #Cust_ArchiveAccount_Temp ar
		WHERE	(	ISNULL(ar.ClosedDate,'') BETWEEN @FromDate AND @ToDate
					OR ISNULL(ar.DisabledDate,'') BETWEEN @FromDate AND @ToDate
					OR ISNULL(ar.SettingDeletedDate,'') BETWEEN @FromDate AND @ToDate
					OR ISNULL(ar.AccountDeletedDate,'') BETWEEN @FromDate AND @ToDate
				)
		ORDER BY CASE WHEN @SortType = 1 THEN ar.Username END ASC,
				CASE WHEN @SortType = 2 THEN ar.Username END DESC,
				CASE WHEN @SortType = 3 THEN ar.StageID END ASC,
				CASE WHEN @SortType = 4 THEN ar.StageID END DESC,
				ar.Username ASC
	END
	ELSE 
	IF @FilterDateType IN(1,2,3,4)
	BEGIN
		INSERT INTO #Cust_ArchiveAccount(
			 CustID                
			,Username              
			,RoleID              
			,StatusID              
			,StageID          
			,ToBeClearedGivenCredit
			,ClearedGivenCredit    
			,lastlogged                    
			,ClosedDate            
			,DisabledDate          
			,SettingDeletedDate
			,IsWarningTicket 
			,AccountDeletedDate    
		)
		SELECT CustID                
			,Username              
			,RoleID              
			,StatusID              
			,StageID          
			,ToBeClearedGivenCredit
			,ClearedGivenCredit    
			,lastlogged                    
			,ClosedDate            
			,DisabledDate          
			,SettingDeletedDate
			,IsWarningTicket 
			,AccountDeletedDate         
		FROM #Cust_ArchiveAccount_Temp ar
		WHERE ISNULL(ar.ClosedDate,'') >= CASE WHEN @FilterDateType = 1 THEN @FromDate ELSE ISNULL(ar.ClosedDate,'') END
			AND ISNULL(ar.ClosedDate,'') <= CASE WHEN @FilterDateType = 1 THEN @ToDate ELSE ISNULL(ar.ClosedDate,'') END
			AND ISNULL(ar.DisabledDate,'') >= CASE WHEN @FilterDateType = 2 THEN @FromDate ELSE ISNULL(ar.DisabledDate,'') END
			AND ISNULL(ar.DisabledDate,'') <= CASE WHEN @FilterDateType = 2 THEN @ToDate ELSE ISNULL(ar.DisabledDate,'') END
			AND ISNULL(ar.SettingDeletedDate,'') >= CASE WHEN @FilterDateType = 3 THEN @FromDate ELSE ISNULL(ar.SettingDeletedDate,'') END
			AND ISNULL(ar.SettingDeletedDate,'') <= CASE WHEN @FilterDateType = 3 THEN @ToDate ELSE ISNULL(ar.SettingDeletedDate,'') END
			AND ISNULL(ar.AccountDeletedDate,'') >= CASE WHEN @FilterDateType = 4 THEN @FromDate ELSE ISNULL(ar.AccountDeletedDate,'') END
			AND ISNULL(ar.AccountDeletedDate,'') <= CASE WHEN @FilterDateType = 4 THEN @ToDate ELSE ISNULL(ar.AccountDeletedDate,'') END
		ORDER BY CASE WHEN @SortType = 1 THEN ar.Username END ASC,
				CASE WHEN @SortType = 2 THEN ar.Username END DESC,
				CASE WHEN @SortType = 3 THEN ar.StageID END ASC,
				CASE WHEN @SortType = 4 THEN ar.StageID END DESC,
				ar.Username ASC
	END
	ELSE
	BEGIN
		INSERT INTO #Cust_ArchiveAccount(
			 CustID                
			,Username              
			,RoleID              
			,StatusID              
			,StageID          
			,ToBeClearedGivenCredit
			,ClearedGivenCredit    
			,lastlogged                    
			,ClosedDate            
			,DisabledDate          
			,SettingDeletedDate
			,IsWarningTicket 
			,AccountDeletedDate    
		)
		SELECT CustID                
			,Username              
			,RoleID              
			,StatusID              
			,StageID          
			,ToBeClearedGivenCredit
			,ClearedGivenCredit    
			,lastlogged                    
			,ClosedDate            
			,DisabledDate          
			,SettingDeletedDate
			,IsWarningTicket 
			,AccountDeletedDate         
		FROM #Cust_ArchiveAccount_Temp ar
		ORDER BY CASE WHEN @SortType = 1 THEN ar.Username END ASC,
				CASE WHEN @SortType = 2 THEN ar.Username END DESC,
				CASE WHEN @SortType = 3 THEN ar.StageID END ASC,
				CASE WHEN @SortType = 4 THEN ar.StageID END DESC,
				ar.Username ASC
	END

	SELECT @TotalItems = COUNT(1) 
	FROM #Cust_ArchiveAccount

	SELECT t.CustID
		,Username = ISNULL(ci.Username,ar.Username)
		,RoleID = ISNULL(ci.roleid,ar.RoleID)                           
		,StatusID =  CASE WHEN ci.Enabled = 1 AND cps.CloseInfo = 0 AND cps.SuspendInfo = 0 THEN 1 --Open 
						  WHEN ci.Enabled = 1 AND cps.CloseInfo = 0 AND cps.SuspendInfo > 0 THEN 2 --Suspended 
						  WHEN ci.Enabled = 1 AND cps.CloseInfo > 0 THEN 3 --Closed    
						  WHEN ci.Enabled = 0 THEN 4 --Disabled
						  WHEN ci.custid IS NULL THEN 5 --Deleted
						END         
		,StageID = CASE WHEN cps.CloseInfo > 0 OR ar.StageID > 1 THEN ar.StageID END        
		,ToBeClearedGivenCredit = CASE WHEN ar.StageID > 1 THEN NULL
										WHEN ar.StageID = 1 AND cps.CloseInfo > 0 THEN ci.credit
										ELSE dl.ToBeClearedGivenCredit 
									END
		,ClearedGivenCredit    = ISNULL(CASE WHEN ar.StageID > 1 THEN ar.ReducedCredit
										ELSE dl.ClearedGivenCredit
									END,0)
		,lastlogged       = CASE WHEN ar.StageID = 4 THEN ar.Lastlogged
								ELSE c.lastlogged 
							END             
		,ClosedDate       = CASE WHEN cps.CloseInfo > 0 THEN ar.ClosedDate 
								 WHEN cps.custid IS NULL THEN ar.ClosedDate -- Deleted account
								END     
		,DisabledDate     = ar.DisabledDate      
		,SettingDeletedDate = ar.SettingDeletedDate
		,IsWarningTicket   = 0  
		,RowNumber			= 0
		,AccountDeletedDate = ar.AccountDeletedDate
	FROM (VALUES(@CustID_ByUserName)) t(CustID)
		LEFT JOIN custinfo ci WITH(NOLOCK) ON t.CustID = ci.custid
		LEFT JOIN customer c WITH(NOLOCK) ON t.CustID = c.custid
		LEFT JOIN CustProductStatus cps WITH(NOLOCK) ON t.CustID = cps.custid
		LEFT JOIN Cust_ArchiveAccount ar WITH(NOLOCK) ON t.CustID = ar.custid
		CROSS APPLY (SELECT  SUM (CASE WHEN m.RoleID = @Cust_RoleID - 1 THEN   ISNULL(m.ToBeClearedGivenCredit,0) ELSE 0 END +
								  CASE WHEN @Cust_RoleID = 4 AND m.RoleID = 2 AND m.StageID = 1 AND ISNULL(magar.StageID,0) <> 1 
										THEN ISNULL(m.ToBeClearedGivenCredit,0) ELSE 0 END
								) AS  ToBeClearedGivenCredit
							,SUM (CASE WHEN m.RoleID = @Cust_RoleID - 1 THEN   ISNULL(m.ClearedGivenCredit,0) ELSE 0 END +
								  CASE WHEN @Cust_RoleID = 4 AND m.RoleID = 2 AND m.StageID >= 2 AND ISNULL(magar.StageID,0) < 2 
										THEN ISNULL(m.ClearedGivenCredit,0) ELSE 0 END
								) AS  ClearedGivenCredit        
					 FROM #Cust_ArchiveAccount	m
						INNER JOIN Cust_ArchiveAccount ar1 WITH(NOLOCK) ON m.CustID = ar1.custid
						OUTER APPLY (	SELECT mag.StageID 
										FROM #Cust_ArchiveAccount mag WITH(NOLOCK) 
										WHERE ar1.mrecommend = mag.CustID 
											AND mag.roleid = 3
									) magar
				)dl
	WHERE (@TotalItems > 0 OR (ar.TotalDownline = 0 AND ISNULL(cps.CloseInfo,1) > 0))
		AND ISNULL(@FilterRoleID,0) = 0 AND @Cust_RoleID  <> 1
	UNION ALL
	SELECT  CustID                
		,Username              
		,RoleID              
		,StatusID              
		,StageID          
		,ToBeClearedGivenCredit
		,ClearedGivenCredit    
		,lastlogged                    
		,ClosedDate            
		,DisabledDate          
		,SettingDeletedDate
		,IsWarningTicket     
		,RowNumber 
		,AccountDeletedDate
	FROM #Cust_ArchiveAccount
	WHERE RowNumber BETWEEN @rowstart AND @rowend 
	ORDER BY RowNumber		

	--get yesterday balance
	DECLARE @CustIdList VARCHAR(MAX) = ''

	SELECT @CustIdList = @CustIdList + ',' + CONVERT(VARCHAR,CustID)
	FROM  #Cust_ArchiveAccount
	WHERE RowNumber BETWEEN @rowstart AND @rowend 	
		AND StageID <> 4 -- not get balance for deleted account

	SELECT @CustIdList = STUFF(@CustIdList,1,1,'')

	--IF @TotalItems > 0 AND ISNULL(@FilterRoleID,0) = 0 AND @Cust_RoleID <> 1
	SET @CustIdList = CONVERT( VARCHAR(MAX),@CustID_ByUserName) + ISNULL(',' + @CustIdList,'')

	EXEC DBAGE.bodb02.dbo.Acc_CustomerSelBalanceInfo @CustIdList = @CustIdList

	DROP TABLE #Cust_ArchiveAccount
	DROP TABLE #Cust_ArchiveAccount_Temp
	DROP TABLE #Exclude
	DROP TABLE #Warning
	DROP TABLE #Cust_info
	DROP TABLE #FilterCustByUserName
END
GO


