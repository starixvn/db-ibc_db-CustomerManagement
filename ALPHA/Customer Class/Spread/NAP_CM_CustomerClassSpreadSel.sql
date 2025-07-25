/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap,wsv_lap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_CM_CustomerClassSpreadSel] 
	  @CustomerClasses 	VARCHAR(MAX)=''
	, @SportTypes		VARCHAR(2000)
	, @Sites 			VARCHAR(MAX)=''
	, @Currencies 		VARCHAR(MAX)=''
	, @Spread 			DECIMAL(4,2)= NULL
	, @IsTest			TINYINT = 0
	, @LeagueGroups		VARCHAR(MAX)=''
	, @LeagueCheck		VARCHAR(MAX)= NULL
	, @Type				SMALLINT = 1
AS
/*
	Created: Winfred
	Date: 20230627
	Task : [NAP CM] Customer Class - Add Spread on rule setting
	DB: DBCUST/CustDB
	Original:

	Revisions:
		- 20230627@Winfred: [NAP CM] Customer Class - Add Spread on rule setting [RedmineID: #187354] 
		- 20240115@Luke: [NAP CM] Customer Class - Spread mng - Set Spread by Sport [Redmine: #195328]
		- 20240314@Winfred: [NAP CM] Customer Class - Grant permission for each Sport type [RedmineID: #199465] 
		- 20250325@Helios: NAP CM - Apply Database Vault [RedmineID: #214797] 
		- 20240612@Winfred: [NAP CM] Customer Class - Add Peak Hour Spread on rule setting [Redmine: #186118]

	Param's Explanation:

	Example: exec NAP_CM_CustomerClassSpreadSel @CustomerClasses = '', @Sites = '0', @Currencies = '0', @Spread = 0, @IsTest = 1
*/ 
BEGIN
	SET NOCOUNT ON;

	CREATE TABLE #CustomerClassSpread(PolicyID INT PRIMARY KEY CLUSTERED, PolicyTitle VARCHAR(500), SportType SMALLINT, Spread DECIMAL(4,2), Enable BIT,IsTest TINYINT, IsLive SMALLINT, CustomerClass VARCHAR(MAX), Sites VARCHAR(MAX), Currencies VARCHAR(MAX), Platforms VARCHAR(MAX), LeagueGroups VARCHAR(MAX),
		LastModifiedUser INT, LastModifiedTime DATETIME)

	CREATE TABLE #Site(SiteID INT, isDeposit BIT)
	CREATE TABLE #Currency(Currency INT)  
	CREATE TABLE #CC(CustomerClass SMALLINT)  
	CREATE TABLE #SportType(SportType SMALLINT)  
	CREATE TABLE #LeagueCheck(LeagueGroupID SMALLINT)  
    CREATE TABLE #LeagueGroup( GroupID SMALLINT, GroupName VARCHAR(200), SportType SMALLINT)         
    CREATE CLUSTERED INDEX  CIX_LeagueGroupTemp ON #LeagueGroup (GroupID, SportType)    
	DECLARE @iDoc INT

	SELECT @CustomerClasses = ISNULL(@CustomerClasses, '')
	
	INSERT INTO #LeagueCheck(LeagueGroupID) 
	SELECT DISTINCT VALUE
	FROM STRING_SPLIT(@LeagueCheck,',') 
	WHERE VALUE <> ''

	INSERT INTO #CC(CustomerClass) 
	SELECT DISTINCT VALUE
	FROM STRING_SPLIT(@CustomerClasses,',') 
	WHERE VALUE <> ''

	INSERT INTO #SportType(SportType) 
	SELECT DISTINCT VALUE
	FROM STRING_SPLIT(ISNULL(@SportTypes,''),',') 
	WHERE VALUE <> ''

	IF @Currencies <> '0'
	BEGIN
		INSERT INTO  #Currency(Currency)
		SELECT e.exchangeid
		FROM exchange e WITH(NOLOCK)
			INNER JOIN STRING_SPLIT(@Currencies,',') a	ON e.ExchangeId = a.value
		WHERE a.VALUE <> ''
	END
	ELSE
	BEGIN
		INSERT INTO  #Currency(Currency)
		SELECT e.exchangeid
		FROM exchange e WITH(NOLOCK)
	END

	IF @Sites <> '0'
	BEGIN
		INSERT INTO #Site(SiteID, isDeposit)  
		SELECT s.siteid, s.isDeposit   
		FROM Site s WITH(NOLOCK)  
			INNER JOIN STRING_SPLIT(@Sites,',') a ON s.siteid = a.value  
		WHERE a.VALUE <> ''
	END
	ELSE
	BEGIN
		INSERT INTO #Site(SiteID, isDeposit)  
		SELECT s.siteid, s.isDeposit   
		FROM Site s WITH(NOLOCK)  
	END

	IF  EXISTS(SELECT TOP 1 1 FROM #Site a WHERE isDeposit = 0)  
	BEGIN  
		INSERT INTO #Site (SiteID) SELECT -1
	END  
  
	IF  EXISTS(SELECT TOP 1 1 FROM #Site a WHERE isDeposit = 1)  
	BEGIN  
		INSERT INTO #Site (SiteID) SELECT -2
	END 

	INSERT INTO #Site (SiteID) SELECT 0
	INSERT INTO #Currency (Currency) SELECT 0

	CREATE CLUSTERED INDEX CIX_Site		ON #Site(SiteID)
	CREATE CLUSTERED INDEX CIX_Currency ON #Currency(Currency)
	CREATE CLUSTERED INDEX CIX_CC		ON #CC(CustomerClass)
	CREATE CLUSTERED INDEX CIX_League	ON #LeagueCheck(LeagueGroupID)
	
	IF @Type = 2
	BEGIN
		--Check if XML is null or empty
		IF @LeagueGroups IS NULL OR @LeagueGroups = ''
			RETURN
	
		EXECUTE	sp_xml_preparedocument	@iDoc OUTPUT, @LeagueGroups;
		INSERT INTO #LeagueGroup(GroupID, GroupName, SportType)
		SELECT	CAST(Data.GroupID AS SMALLINT) AS GroupID				
			,	CASE WHEN Data.GroupName = '' THEN null ELSE CAST(Data.GroupName AS VARCHAR(200)) END AS GroupName 					    
			,	CAST(Data.SportType AS SMALLINT)  AS SportType 
		FROM OPENXML(@iDoc, '/ROOT/r', 1) 
		WITH (     
				GroupID 	 SMALLINT,       
				GroupName 	 VARCHAR(500),       
				SportType 	 VARCHAR(20)
		) AS Data;
		EXECUTE	sp_xml_removedocument @iDoc;
	END
	-- Apply index IX_CustomerClassSpread_Spread
	IF @Spread IS NULL 
	BEGIN
		IF ISNULL(@LeagueCheck,'') = ''
		BEGIN
			INSERT INTO #CustomerClassSpread(PolicyID, PolicyTitle, SportType, Spread, Enable, IsTest, LastModifiedUser, LastModifiedTime, IsLive)  
			SELECT c.PolicyID, PolicyTitle, SportType, Spread, Enable, IsTest, LastModifiedUser, LastModifiedTime, IsLive   
			FROM CustomerClassSpread c WITH(NOLOCK)   
			CROSS APPLY(  SELECT TOP 1 cs.PolicyID
						FROM CustomerClassSpreadClass cs WITH(NOLOCK) 
						WHERE c.PolicyID = cs.PolicyID  
						AND (cs.CustomerClass IN (SELECT CustomerClass FROM #CC) OR @CustomerClasses = '')
						) t1
			CROSS APPLY(  SELECT TOP 1 cm.PolicyID, cm.SportType
						FROM CustomerClassSpreadDetail cm WITH(NOLOCK) 
						WHERE c.PolicyID = cm.PolicyID  
							AND cm.SiteID IN (SELECT SiteID FROM #Site) 
							AND cm.Currency IN (SELECT Currency FROM #Currency)
							AND cm.SportType IN (SELECT SportType FROM #SportType)
						) t2
			WHERE c.IsTest <= @IsTest AND Type = @Type 
			OPTION (RECOMPILE)
		END
		ELSE
		BEGIN
			INSERT INTO #CustomerClassSpread(PolicyID, PolicyTitle, SportType, Spread, Enable, IsTest, LastModifiedUser, LastModifiedTime, IsLive)  
			SELECT c.PolicyID, PolicyTitle, SportType, Spread, Enable, IsTest, LastModifiedUser, LastModifiedTime, IsLive   
			FROM CustomerClassSpread c WITH(NOLOCK)   
			CROSS APPLY( SELECT TOP 1 cs.PolicyID
						FROM CustomerClassSpreadClass cs WITH(NOLOCK) 
						WHERE c.PolicyID = cs.PolicyID  
						AND (cs.CustomerClass IN (SELECT CustomerClass FROM #CC) OR @CustomerClasses = '')
						) t1
			CROSS APPLY( SELECT TOP 1 cm.PolicyID, cm.SportType
						FROM CustomerClassSpreadDetail cm WITH(NOLOCK) 
						WHERE c.PolicyID = cm.PolicyID  
							AND cm.SiteID IN (SELECT SiteID FROM #Site) 
							AND cm.Currency IN (SELECT Currency FROM #Currency)
							AND cm.SportType IN (SELECT SportType FROM #SportType)
						) t2
			CROSS APPLY( SELECT TOP 1 cs.PolicyID
						FROM CustomerClassSpreadLeagueGroup cs WITH(NOLOCK) 
						WHERE c.PolicyID = cs.PolicyID  
						AND (@LeagueCheck = '-1' OR
							1  = CASE WHEN t2.SportType NOT IN (9901, 9902) 
											AND EXISTS (SELECT TOP 1 1 
													FROM #LeagueCheck a 
														INNER JOIN #LeagueGroup b ON a.LeagueGroupID = b.GroupID 
													WHERE SportType IN (0,t2.SportType) AND cs.LeagueGroupID  IN (a.LeagueGroupID,-1) 
													AND 1 = (CASE WHEN t2.SportType = 1 AND a.LeagueGroupID NOT IN (42, 74, 108) THEN 1 
																   WHEN t2.SportType = 2 AND a.LeagueGroupID NOT IN (42) THEN 1 
																   WHEN t2.SportType NOT IN (1,2) THEN 1 
																   ELSE 0 END))
										THEN 1
									  WHEN t2.SportType IN (9901) 
											AND (
												(cs.LeagueGroupID = -1 AND EXISTS (SELECT TOP 1 1 FROM #LeagueCheck WHERE LeagueGroupID IN (42, 74, 108)))
											OR	(cs.LeagueGroupID <> -1 AND cs.LeagueGroupID IN (SELECT LeagueGroupID FROM #LeagueCheck WHERE LeagueGroupID IN (42, 74, 108))) 
											)
										THEN 1
									  WHEN t2.SportType IN (9902) 
											AND (
												(cs.LeagueGroupID = -1 AND EXISTS (SELECT TOP 1 1 FROM #LeagueCheck WHERE LeagueGroupID IN (42)))
											OR	(cs.LeagueGroupID <> -1 AND cs.LeagueGroupID IN (SELECT LeagueGroupID FROM #LeagueCheck WHERE LeagueGroupID IN (42))) 
											)
										THEN 1
								 ELSE 0 END
							)
						) t3
			WHERE c.IsTest <= @IsTest AND Type = @Type 
			OPTION (RECOMPILE)
		END
	END
	ELSE 
	BEGIN
		INSERT INTO #CustomerClassSpread(PolicyID, PolicyTitle, SportType, Spread, Enable, IsTest, LastModifiedUser, LastModifiedTime, IsLive)  
		SELECT c.PolicyID, PolicyTitle, SportType, Spread, Enable, IsTest, LastModifiedUser, LastModifiedTime, IsLive   
		FROM CustomerClassSpread c WITH(NOLOCK)   
		CROSS APPLY(  SELECT TOP 1 cs.PolicyID
					FROM CustomerClassSpreadClass cs WITH(NOLOCK) 
					WHERE c.PolicyID = cs.PolicyID  
						AND (cs.CustomerClass IN (SELECT CustomerClass FROM #CC) OR @CustomerClasses = '')
					) t1
		CROSS APPLY(  SELECT TOP 1 cm.PolicyID, cm.SportType
					FROM CustomerClassSpreadDetail cm WITH(NOLOCK) 
					WHERE c.PolicyID = cm.PolicyID  
						AND cm.SiteID IN (SELECT SiteID FROM #Site) 
						AND cm.Currency IN (SELECT Currency FROM #Currency)
						AND cm.SportType IN (SELECT SportType FROM #SportType)
					) t2
		WHERE c.Spread = @Spread AND c.IsTest <= @IsTest AND Type = @Type 
		OPTION (RECOMPILE)
	END

	UPDATE a  
	SET a.CustomerClass =  c.CustomerClasses ,
		a.Currencies =  cu.Currencies ,
		a.Sites =  s.Sites ,
		a.Platforms =  p.Platforms 
	FROM #CustomerClassSpread a
		CROSS APPLY ( SELECT STRING_AGG(CAST(CustomerClass AS VARCHAR(MAX)), ',') 
						WITHIN GROUP (ORDER BY CustomerClass) CustomerClasses
						FROM(	SELECT DISTINCT CustomerClass
						FROM CustomerClassSpreadClass WITH(NOLOCK) 
						WHERE PolicyID = a.PolicyID) cc) c  
		CROSS APPLY ( SELECT STRING_AGG(CAST(Currency AS VARCHAR(MAX)), ',') 
						WITHIN GROUP (ORDER BY Currency) Currencies
						FROM(	SELECT DISTINCT Currency
						FROM CustomerClassSpreadDetail  WITH(NOLOCK) 
						WHERE PolicyID = a.PolicyID) cc
						) cu 
		CROSS APPLY ( SELECT STRING_AGG(CAST(SiteID AS NVARCHAR(MAX)), ',') 
						WITHIN GROUP (ORDER BY SiteID) Sites
						FROM(	SELECT DISTINCT SiteID
						FROM CustomerClassSpreadDetail  WITH(NOLOCK) 
						WHERE PolicyID = a.PolicyID) cc
						) s 
		CROSS APPLY ( SELECT STRING_AGG(CAST(Platform AS VARCHAR(MAX)), ',') 
						WITHIN GROUP (ORDER BY Platform) Platforms
						FROM(	SELECT DISTINCT Platform
						FROM CustomerClassSpreadDetail  WITH(NOLOCK) 
						WHERE PolicyID = a.PolicyID) cc
						) p 
	IF @Type = 2
	BEGIN
		UPDATE a  
		SET a.LeagueGroups =  c.LeagueGroupIDs 
		FROM #CustomerClassSpread a
			CROSS APPLY (SELECT STRING_AGG(CAST(LeagueGroupID AS NVARCHAR(MAX)), ',') 
									WITHIN GROUP (ORDER BY LeagueGroupID) LeagueGroupIDs
								FROM( SELECT DISTINCT LeagueGroupID
								FROM CustomerClassSpreadLeagueGroup WITH(NOLOCK)
								WHERE PolicyID = a.PolicyID)cc) c 
	END

	SELECT PolicyID, PolicyTitle, SportType, Spread, CustomerClass, Currencies, Sites, Platforms,
		   Enable, IsTest, LastModifiedUser, LastModifiedTime , IsLive, LeagueGroups
	FROM #CustomerClassSpread WITH (NOLOCK)
	ORDER BY Enable DESC, PolicyTitle

	DROP TABLE #CustomerClassSpread
	DROP TABLE #Site, #CC, #Currency , #SportType , #LeagueCheck
END
GO
