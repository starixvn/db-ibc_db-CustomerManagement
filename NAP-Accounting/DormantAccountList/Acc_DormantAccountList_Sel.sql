/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,wsv_nap,wsv_alp,wsv_alpv" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_DormantAccountList_Sel] (
	 @CustID			INT = 0
	,@FilterUsername	VARCHAR(30) = NULL
	,@FilterRoleID		TINYINT = NULL
	,@FilterStatusID	TINYINT = 0
	,@PageSize			INT = 50
	,@PageIndex			INT = 1
	,@TotalItems		INT = 0 OUTPUT
)
AS
/*
	Created: 20201201@Eden
	Task : get the dormant downline accounts which are being processed by the archive account process.
	DB: DBCUST/CUSTDB
	Original:

	Revisions:  
		- 20201201@Eden: Alpha Site | Implement Dormant Account List [RedmineID: #144903]
		- 20210505@Tina: Lock account & indirect close account [redmine: #148600]
		- 20210610@Eden: All sites - Dormant SMA Account List [RedmineID: #155969]
		- 20230823@Eden : Archive super level 789y (Stage 3 and Stage 4) [Redmine: #183447]

	Parameter Definition
		-@FilterStatusID:
			0 = All
			3 = Closed
			4 = Disabled
			5 = Deleted

		-@FilterRoleID (Level)
			0 - All 
			3 - Master
			2 - Agent 
			1 - Member

	Example: 
	DECLARE @TotalItems	INT 
	EXEC Acc_DormantAccountList_Sel 
		@CustId = 46773164,
		--@FilterUsername  = 'EdentestS10M11',
		@FilterRoleID    = 0,
		@FilterStatusID	= 0,
		@PageSize	= 50,
		@PageIndex	= 1,
		@TotalItems = @TotalItems OUTPUT
	SELECT @TotalItems
	
	*/
BEGIN
	SET NOCOUNT ON
	DECLARE @RowCount int, @RowStart int, @RowEnd int

	SELECT @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1 

	DECLARE @LoginRoleID TINYINT
	SELECT @LoginRoleID = roleid FROM custinfo WITH(NOLOCK) WHERE custid = @CustID

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

	IF @LoginRoleID = 4
	BEGIN
		INSERT INTO #Exclude(recommend,mrecommend)
		SELECT a.recommend,a.mrecommend
		FROM custInfo a WITH(NOLOCK) 
			INNER JOIN Cust_ArchiveAccount c WITH(NOLOCK) 
				ON a.custid = c.CustID
			INNER JOIN CustProductStatus cps WITH (NOLOCK) ON cps.CustID = a.custid
		WHERE a.srecommend = @CustID AND a.RoleID IN(2,3,4)
			AND cps.CloseInfo = 0
		UNION
		SELECT a.custid,MAX(a.mrecommend) as mrecommend
		FROM custInfo a WITH(NOLOCK) 
			INNER JOIN Cust_ArchiveAccount c WITH(NOLOCK) 
				ON a.custid = c.CustID
			INNER JOIN custInfo dl WITH(NOLOCK) 
				ON dl.recommend = a.custid AND dl.roleid = 1
		WHERE a.srecommend = @CustID 
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
		WHERE a.srecommend = @CustID
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
		WHERE a.srecommend = @CustID 
			AND a.roleid = 2
			AND dl.lastlogged > c.ClosedDate

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
			   --RowNumber = ROW_NUMBER() OVER ( ORDER BY bc.StageID, ci.Username)
		FROM Cust_ArchiveAccount bc WITH(NOLOCK)
			 INNER JOIN custInfo ci WITH(NOLOCK) ON bc.CustID = ci.custid
			 INNER JOIN Customer c WITH(NOLOCK) ON bc.custid = c.custid
			 LEFT JOIN #Warning w ON ci.recommend = w.recommend
			 LEFT JOIN #Warning wm ON ci.custid = wm.mrecommend
		WHERE c.username LIKE CASE WHEN ISNULL(@FilterUsername,'') <> ''  THEN '%' + @FilterUsername + '%'  ELSE c.username END
			  AND ci.roleid = CASE WHEN ISNULL(@FilterRoleID,0) <> 0 THEN @FilterRoleID ELSE ci.roleid END 
			  AND ci.Enabled = CASE WHEN ISNULL(@FilterStatusID,0) = 0 THEN ci.Enabled 
									WHEN @FilterStatusID = 3 THEN 1
									WHEN @FilterStatusID = 4 THEN 0
								END 
			  AND bc.srecommend = @CustID
			  AND NOT EXISTS( SELECT 1 FROM #Exclude WHERE ci.recommend = recommend AND ci.roleid IN (1,2))
			  AND NOT EXISTS( SELECT 1 FROM #Exclude WHERE ci.custid = mrecommend)
			  AND ci.custid <> @CustID
			  AND bc.StageID <> 4
		ORDER BY bc.StageID, ci.Username

		--> Get data for S4
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
		WHERE bc.username LIKE CASE WHEN ISNULL(@FilterUsername,'') <> ''  THEN '%' + @FilterUsername + '%'  ELSE bc.username END
			  AND bc.roleid = CASE WHEN ISNULL(@FilterRoleID,0) <> 0 THEN @FilterRoleID ELSE bc.roleid END 
			  AND ISNULL(@FilterStatusID,0) IN (0,5)
			  AND bc.srecommend = @CustID
			  AND bc.custid <> @CustID
			  AND bc.StageID = 4
		ORDER BY bc.Username

	END
	IF @LoginRoleID = 3
	BEGIN
		INSERT INTO #Exclude(recommend,mrecommend)
		SELECT a.recommend,a.mrecommend
		FROM custInfo a WITH(NOLOCK) 
			INNER JOIN Cust_ArchiveAccount c WITH(NOLOCK) 
				ON a.custid = c.CustID
			INNER JOIN CustProductStatus cps WITH (NOLOCK) ON cps.CustID = a.custid
		WHERE a.mrecommend = @CustID AND a.RoleID IN(2,3)
			AND cps.CloseInfo = 0
		UNION
		SELECT a.custid,MAX(a.mrecommend) as mrecommend
		FROM custInfo a WITH(NOLOCK) 
			INNER JOIN Cust_ArchiveAccount c WITH(NOLOCK) 
				ON a.custid = c.CustID
			INNER JOIN custInfo dl WITH(NOLOCK) 
				ON dl.recommend = a.custid AND dl.roleid = 1
		WHERE a.mrecommend = @CustID 
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
		WHERE a.mrecommend = @CustID 
			AND a.roleid = 2
			AND dl.lastlogged > c.ClosedDate

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
			--,RowNumber
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
			   --RowNumber = ROW_NUMBER() OVER ( ORDER BY bc.StageID, ci.Username)
		FROM Cust_ArchiveAccount bc WITH(NOLOCK)
			 INNER JOIN custInfo ci WITH(NOLOCK) ON bc.CustID = ci.custid
			 INNER JOIN Customer c WITH(NOLOCK) ON bc.custid = c.custid
			 LEFT JOIN #Warning w ON ci.recommend = w.recommend
		WHERE c.username LIKE CASE WHEN ISNULL(@FilterUsername,'') <> ''  THEN '%' + @FilterUsername + '%'  ELSE c.username END
			  AND ci.roleid = CASE WHEN ISNULL(@FilterRoleID,0) <> 0 THEN @FilterRoleID ELSE ci.roleid END 
			  AND ci.Enabled = CASE WHEN ISNULL(@FilterStatusID,0) = 0 THEN ci.Enabled 
									WHEN @FilterStatusID = 3 THEN 1
									WHEN @FilterStatusID = 4 THEN 0
								END 
			  AND bc.mrecommend = @CustID
			  AND NOT EXISTS( SELECT 1 FROM #Exclude WHERE ci.recommend = recommend  AND ci.roleid IN (1,2))
			  AND ci.custid <> @CustID
			  AND bc.StageID <> 4
		ORDER BY bc.StageID, ci.Username

		--> Get data for S4
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
		WHERE bc.username LIKE CASE WHEN ISNULL(@FilterUsername,'') <> ''  THEN '%' + @FilterUsername + '%'  ELSE bc.username END
			  AND bc.roleid = CASE WHEN ISNULL(@FilterRoleID,0) <> 0 THEN @FilterRoleID ELSE bc.roleid END 
			  AND ISNULL(@FilterStatusID,0) IN (0,5)
			  AND bc.mrecommend = @CustID
			  AND bc.custid <> @CustID
			  AND bc.StageID = 4
		ORDER BY bc.Username
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
	FROM (VALUES(@CustID)) t(CustID)
		LEFT JOIN custinfo ci WITH(NOLOCK) ON t.CustID = ci.custid
		LEFT JOIN customer c WITH(NOLOCK) ON t.CustID = c.custid
		LEFT JOIN CustProductStatus cps WITH(NOLOCK) ON t.CustID = cps.custid
		LEFT JOIN Cust_ArchiveAccount ar WITH(NOLOCK) ON t.CustID = ar.custid
		CROSS APPLY (SELECT  SUM (CASE WHEN m.RoleID = @LoginRoleID - 1 THEN   ISNULL(m.ToBeClearedGivenCredit,0) ELSE 0 END +
								  CASE WHEN @LoginRoleID = 4 AND m.RoleID = 2 AND m.StageID = 1 AND ISNULL(magar.StageID,0) <> 1 
										THEN ISNULL(m.ToBeClearedGivenCredit,0) ELSE 0 END
								) AS  ToBeClearedGivenCredit
							,SUM (CASE WHEN m.RoleID = @LoginRoleID - 1 THEN   ISNULL(m.ClearedGivenCredit,0) ELSE 0 END +
								  CASE WHEN @LoginRoleID = 4 AND m.RoleID = 2 AND m.StageID >= 2 AND ISNULL(magar.StageID,0) < 2 
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
		AND ISNULL(@FilterRoleID,0) = 0
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

	--get yesterday balance
	DECLARE @CustIdList VARCHAR(MAX) = ''

	SELECT @CustIdList = @CustIdList + ',' + CONVERT(varchar,CustID)
	FROM  #Cust_ArchiveAccount
	WHERE RowNumber BETWEEN @rowstart AND @rowend 	
		AND StageID <> 4 -- not get balance for deleted account

	SELECT @CustIdList = STUFF(@CustIdList,1,1,'')

	SET @CustIdList = CONVERT( VARCHAR(MAX),@Custid) + ISNULL(',' + @CustIdList,'')

	EXEC DBAGE.bodb02.dbo.Acc_CustomerSelBalanceInfo @CustIdList = @CustIdList
	
	DROP TABLE #Cust_ArchiveAccount
	DROP TABLE #Exclude
	DROP TABLE #Warning
END
GO


