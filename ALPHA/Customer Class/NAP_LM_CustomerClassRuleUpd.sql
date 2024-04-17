/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap,wsv_lap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_LM_CustomerClassRuleUpd] 
	@Rules  VARCHAR(MAX)
	, @UserID		INT
	, @IsTest		TINYINT	
	, @IP			VARCHAR(50)		= ''
	, @ErrCode		INT				= 0		OUTPUT
	, @ErrMsg		NVARCHAR(MAX)	= ''	OUTPUT
AS
/*
	Created: Winfred
	Date: 20221209
	Task : [NAP CM] Build Customer Class Management [#180904]
	DB: DBCUST/CustDB
	Original:

	Revisions:
		- 20221209@Winfred: [NAP CM] Build Customer Class Management [RedmineID: #180904] 
		- 20230802@Winfred: [NAP CM] Customer Class - Enhance for CC [RedmineID: #187368] 
		- 20240402@Winfred: [NAP CM] Customer Class - Support to add CC by Sport Detail [199679]

	Param's Explanation:
	* @Rules:
		'<ROOT><r 
				RuleID=1 
				CustomerClass="200" 
				CustomerClassDetail="200" 
				RuleTitle = "Rule 1" 
				SportType = 99  
				IsLive = 1 
				DiffBalanceRatio = 12 
				BetDelay = 5  
				NextBetInterval =6  
				SuperBetInterval = 4 
				SiteBetInterval = 6 
				MinBet = 12  
				MaxBet = 8 
				MaxPerMatch =11 
				RepeatedBets =5  
				SeizeBetTicket = 9  
				DisableParlay = 1  
				PeakHourSpreadAdjustment = 5 
				AgentBetInterval = 6
				LeagueGroupIDs = '111,222,333,444,555'/> 
		</ROOT>'

	Example: NAP_LM_CustomerClassRuleUpd @Rules ='<ROOT><r RuleID=1 CustomerClass="200" CustomerClassDetail="300" RuleTitle = "Rule 1" SportType = 99  IsLive = 1 DiffBalanceRatio = 12 BetDelay = 5  NextBetInterval =6  SuperBetInterval = 4 SiteBetInterval = 6 MinBet = 12  MaxBet = 8 MaxPerMatch =11 RepeatedBets =5  SeizeBetTicket = 9  DisableParlay = 1 PeakHourSpreadAdjustment = 5 AgentBetInterval = 6 LeagueGroupIDs = '111,222,333,444,555'/> </ROOT>' ,@ErrCode =0, @ErrMsg = '' ,  @IP = '11.12.11.10', @UserID = 6
*/ 
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @StartRun	DATETIME
		, @EndRun		DATETIME
		, @Duration		INT
		, @iDoc			INT
		, @logSpData		 NVARCHAR(MAX)
		, @logSpData_Old   NVARCHAR(MAX)
		, @xml			 XML
	
	--Check if XML is null or empty
	IF @Rules IS NULL	OR @Rules = ''
		RETURN
	
	CREATE TABLE #CustomerClassRule( RuleID INT, CustomerClass SMALLINT, CustomerClassDetail SMALLINT, RuleTitle VARCHAR(500),
			SportType SMALLINT, IsLive TINYINT, DiffBalanceRatio DECIMAL(9, 2), BetDelay DECIMAL(9, 2),
			NextBetInterval SMALLINT, SuperBetInterval SMALLINT, SiteBetInterval SMALLINT,
			MinBet INT, MaxBet INT, MaxPerMatch INT, RepeatedBets TINYINT, SeizeBetTicket TINYINT,
			DisableParlay BIT, PeakHourSpreadAdjustment SMALLINT, AgentBetInterval SMALLINT, LeagueGroupIDs VARCHAR(MAX), IsTest TINYINT)
	CREATE TABLE #CustomerClassRule_History( RuleID INT, CustomerClass SMALLINT, CustomerClassDetail SMALLINT, RuleTitle VARCHAR(500),
			SportType SMALLINT, IsLive TINYINT, DiffBalanceRatio DECIMAL(9, 2), BetDelay DECIMAL(9, 2),
			NextBetInterval SMALLINT, SuperBetInterval SMALLINT, SiteBetInterval SMALLINT,
			MinBet INT, MaxBet INT, MaxPerMatch INT, RepeatedBets TINYINT, SeizeBetTicket TINYINT,
			DisableParlay BIT, PeakHourSpreadAdjustment SMALLINT, AgentBetInterval SMALLINT, LeagueGroupIDs VARCHAR(MAX), IsTest TINYINT)
	CREATE TABLE #CustomerClassRuleLeagueGroup_History( RuleID INT, LeagueGroupID SMALLINT)

	BEGIN TRY
		EXECUTE	sp_xml_preparedocument	@iDoc OUTPUT,	@Rules;

		INSERT INTO	#CustomerClassRule (RuleID 					
					 ,	CustomerClass
					 ,	CustomerClassDetail
					 ,	RuleTitle 					    
					 ,	SportType 					
					 ,	IsLive 					
					 ,	DiffBalanceRatio 			    
					 ,	BetDelay 					    
					 ,	NextBetInterval 			
					 ,	SuperBetInterval 			
					 ,	SiteBetInterval 			
					 ,	MinBet 					
					 ,	MaxBet 					
					 ,	MaxPerMatch 				
					 ,	RepeatedBets 				
					 ,	SeizeBetTicket 			
					 ,	DisableParlay 			  
					 ,	PeakHourSpreadAdjustment 
					 ,	AgentBetInterval
					 ,	LeagueGroupIDs 
					 ,	IsTest	)
		SELECT	Data.RuleID 					
			 ,	CASE WHEN Data.CustomerClass = '' THEN null ELSE  CAST(Data.CustomerClass AS SMALLINT) END AS CustomerClass				
			 ,	CASE WHEN Data.CustomerClassDetail = '' THEN null ELSE  CAST(Data.CustomerClassDetail AS SMALLINT) END AS CustomerClassDetail				
			,	CASE WHEN Data.RuleTitle = '' THEN null ELSE  CAST(Data.RuleTitle AS VARCHAR(500)) END AS RuleTitle 					    
			,	CASE WHEN Data.SportType = '' THEN null ELSE  CAST(Data.SportType AS SMALLINT) END AS SportType 					
			,	CASE WHEN Data.IsLive = '' THEN null ELSE  CAST(Data.IsLive AS TINYINT) END AS IsLive  					
			,	CASE WHEN Data.DiffBalanceRatio = '' THEN null ELSE  (CAST(Data.DiffBalanceRatio AS DECIMAL(9,2))/100) + 1 END AS DiffBalanceRatio 			   
			,	CASE WHEN Data.BetDelay = '' THEN null ELSE  (CAST(Data.BetDelay AS DECIMAL(9,2))/100) + 1 END AS BetDelay 					   
			,	CASE WHEN Data.NextBetInterval = '' THEN null ELSE  CAST(Data.NextBetInterval AS SMALLINT) END AS NextBetInterval 			
			,	CASE WHEN Data.SuperBetInterval = '' THEN null ELSE  CAST(Data.SuperBetInterval AS SMALLINT) END AS SuperBetInterval 			
			,	CASE WHEN Data.SiteBetInterval = '' THEN null ELSE  CAST(Data.SiteBetInterval AS SMALLINT) END AS SiteBetInterval 			
			,	CASE WHEN Data.MinBet = '' THEN null ELSE  CAST(Data.MinBet AS INT) END AS MinBet 					
			,	CASE WHEN Data.MaxBet = '' THEN null ELSE  CAST(Data.MaxBet AS INT) END AS MaxBet 					
			,	CASE WHEN Data.MaxPerMatch = '' THEN null ELSE  CAST(Data.MaxPerMatch AS INT) END AS MaxPerMatch 				
			,	CASE WHEN Data.RepeatedBets = '' THEN null ELSE  CAST(Data.RepeatedBets AS TINYINT) END AS RepeatedBets 				
			,	CASE WHEN Data.SeizeBetTicket = '' THEN null ELSE  CAST(Data.SeizeBetTicket AS TINYINT) END AS SeizeBetTicket 			
			,	CASE WHEN Data.DisableParlay = '' THEN null ELSE  CAST(Data.DisableParlay AS BIT) END AS DisableParlay 			 
			,	CASE WHEN Data.PeakHourSpreadAdjustment = '' THEN null ELSE  CAST(Data.PeakHourSpreadAdjustment 	AS SMALLINT)		END AS PeakHourSpreadAdjustment 
			,	CASE WHEN Data.AgentBetInterval = '' THEN null ELse  CAST(Data.AgentBetInterval AS SMALLINT) END AS AgentBetInterval			  
			 ,	Data.LeagueGroupIDs 	   					    
			 ,	@IsTest AS IsTest 
		FROM OPENXML (@iDoc, '/ROOT/r', 1) 
		WITH (
			 RuleID 					INT,       
			 CustomerClass 				VARCHAR(20),   
			 CustomerClassDetail		VARCHAR(20),      
			 RuleTitle 					VARCHAR(500),       
			 SportType 					VARCHAR(20),       
			 IsLive 					VARCHAR(3),       
			 DiffBalanceRatio 			VARCHAR(20),       
			 BetDelay 					VARCHAR(20),       
			 NextBetInterval 			VARCHAR(20),       
			 SuperBetInterval 			VARCHAR(20),       
			 SiteBetInterval 			VARCHAR(20),       
			 MinBet 					VARCHAR(20),       
			 MaxBet 					VARCHAR(20),       
			 MaxPerMatch 				VARCHAR(20),       
			 RepeatedBets 				VARCHAR(20),       
			 SeizeBetTicket 			VARCHAR(20),       
			 DisableParlay 				VARCHAR(1),        
			 PeakHourSpreadAdjustment 	VARCHAR(20),    
			 AgentBetInterval		 	VARCHAR(20), 
			 LeagueGroupIDs				VARCHAR(MAX)
		) AS Data;

		EXECUTE	sp_xml_removedocument	@iDoc;
	END TRY
	BEGIN CATCH
		SELECT  @ErrMsg = N'Invalid XML format'	, @ErrCode = 3 ;		
		RETURN
	END CATCH

	IF 	EXISTS( SELECT TOP 1 1 FROM #CustomerClassRule WHERE ISNULL(RuleID,0) <= 0)	
	BEGIN
		SELECT @ErrCode = 100 , @ErrMsg = 'The Rule title not is existed' 
		RETURN
	END	 

	IF 	EXISTS( SELECT TOP 1 1 FROM #CustomerClassRule WHERE ISNULL( MinBet,0) <> 0 AND ISNULL( MaxBet,0) <> 0 
																	AND ISNULL( MinBet,0) > ISNULL( MaxBet,0) )	
	BEGIN
		SELECT @ErrCode = 101 , @ErrMsg = 'Min Bet must be less than or equal to Max Bet' 
		RETURN
	END	 
	
	IF 	EXISTS( SELECT TOP 1 1 FROM #CustomerClassRule WHERE ISNULL( MinBet,0) <> 0 AND ISNULL( MaxPerMatch,0) <> 0 
																	AND ISNULL( MinBet,0) > ISNULL( MaxPerMatch,0) )	
	BEGIN
		SELECT @ErrCode = 102 , @ErrMsg = 'Min Bet must be less than or equal to Max Per Match' 
		RETURN
	END	 
	
	IF 	EXISTS( SELECT TOP 1 1 FROM #CustomerClassRule WHERE ISNULL( MaxBet,0) <> 0 AND ISNULL( MaxPerMatch,0) <> 0 
																	AND ISNULL( MaxBet,0) > ISNULL( MaxPerMatch,0) )	
	BEGIN
		SELECT @ErrCode = 103 , @ErrMsg = 'Max Bet must be less than or equal to Max Per Match' 
		RETURN
	END	   
	IF 	EXISTS(SELECT TOP 1 1 FROM CustomerClassRule a WITH(NOLOCK)
					INNER JOIN #CustomerClassRule b ON a.RuleID = b.RuleID AND a.IsTest <> @IsTest)
	BEGIN
		SELECT @ErrCode = 105 , @ErrMsg = 'Cannot update PROD data' 
		RETURN
	END	
	IF 	EXISTS(SELECT TOP 1 1 FROM CustomerClassRule a WITH(NOLOCK)
					INNER JOIN #CustomerClassRule b ON a.RuleID <> b.RuleID AND a.RuleTitle = b.RuleTitle)	
	BEGIN
		SELECT @ErrCode = 106 , @ErrMsg = 'The Rule title is existed' 
		RETURN
	END	 

	SELECT @ErrCode = 107, @ErrMsg = 'Rule title ' + ISNULL(a.RuleTitle,'') + ' belongs to ' + ISNULL(d.PolicyTitles,'') + 
			'. Please remove this Rule from its Policy before changing Sport Type' 
	FROM #CustomerClassRule a WITH(NOLOCK)
		CROSS APPLY(
			SELECT STRING_AGG(b.PolicyTitle, ', ') WITHIN GROUP (ORDER BY PolicyTitle)  AS PolicyTitles
			FROM CustomerClassPolicyManagement b WITH(NOLOCK)
				INNER JOIN CustomerClassPolicyRule c WITH(NOLOCK) ON b.PolicyID = c.PolicyID
			WHERE c.RuleID = a.RuleID AND b.SportType <> a.SportType
		) d
	where ISNULL(d.PolicyTitles,'') <> ''

	IF 	@ErrCode = 107
	BEGIN
		RETURN
	END	

	UPDATE a	
	SET a.RuleTitle 				=   b.RuleTitle 				  
		,a.SportType 				=   b.SportType 				
		,a.IsLive 					=   b.IsLive 					
		,a.DiffBalanceRatio 		=   b.DiffBalanceRatio 		  
		,a.BetDelay 				=   b.BetDelay 				  
		,a.NextBetInterval 			=   b.NextBetInterval 			
		,a.SuperBetInterval 		=   b.SuperBetInterval 		
		,a.SiteBetInterval 			=   b.SiteBetInterval 			
		,a.MinBet 					=   b.MinBet 					
		,a.MaxBet 					=   b.MaxBet 					
		,a.MaxPerMatch 				=   b.MaxPerMatch 				
		,a.RepeatedBets 			=   b.RepeatedBets 			
		,a.SeizeBetTicket 			=   b.SeizeBetTicket 			
		,a.DisableParlay 			=   b.DisableParlay 			 
		,a.PeakHourSpreadAdjustment =   b.PeakHourSpreadAdjustment
		,a.AgentBetInterval			=   b.AgentBetInterval
		,a.CustomerClassDetail		=   b.CustomerClassDetail
	OUTPUT	b.RuleID 					
		,	b.CustomerClass 				
		,	deleted.CustomerClassDetail 			
		,	deleted.RuleTitle 					    
		,	deleted.SportType 					
		,	deleted.IsLive 					
		,	deleted.DiffBalanceRatio 			    
		,	deleted.BetDelay 					    
		,	deleted.NextBetInterval 			
		,	deleted.SuperBetInterval 			
		,	deleted.SiteBetInterval 			
		,	deleted.MinBet 					
		,	deleted.MaxBet 					
		,	deleted.MaxPerMatch 				
		,	deleted.RepeatedBets 				
		,	deleted.SeizeBetTicket 			
		,	deleted.DisableParlay 		
		,	deleted.PeakHourSpreadAdjustment 
		,	deleted.AgentBetInterval 			  
		,	deleted.IsTest 
	INTO #CustomerClassRule_History(RuleID 					
			 ,	CustomerClass 						
			 ,	CustomerClassDetail 		
			 ,	RuleTitle 					    
			 ,	SportType 					
			 ,	IsLive 					
			 ,	DiffBalanceRatio 			    
			 ,	BetDelay 					    
			 ,	NextBetInterval 			
			 ,	SuperBetInterval 			
			 ,	SiteBetInterval 			
			 ,	MinBet 					
			 ,	MaxBet 					
			 ,	MaxPerMatch 				
			 ,	RepeatedBets 				
			 ,	SeizeBetTicket 			
			 ,	DisableParlay 			  
			 ,	PeakHourSpreadAdjustment 	
			 ,	AgentBetInterval
			 ,	IsTest )
	FROM CustomerClassRule a WITH (ROWLOCK, UPDLOCK)
		INNER JOIN  #CustomerClassRule b ON a.RuleID = b.RuleID
	
	DELETE FROM CustomerClassRuleLeagueGroup WITH (ROWLOCK)
	OUTPUT	deleted.RuleID,	deleted.LeagueGroupID 
	INTO #CustomerClassRuleLeagueGroup_History(RuleID,	LeagueGroupID )
	WHERE RuleID IN (SELECT RuleID FROM #CustomerClassRule)

	INSERT INTO CustomerClassRuleLeagueGroup(RuleID ,  LeagueGroupID)	
	SELECT a.RuleID ,b.LeagueGroupID 
	FROM #CustomerClassRule a
	CROSS APPLY ( SELECT VALUE AS LeagueGroupID FROM STRING_SPLIT(a.LeagueGroupIDs,',') WHERE VALUE <> '' ) b

	UPDATE a
	SET a.LeagueGroupIDs = c.LeagueGroupIDs
	FROM #CustomerClassRule_History a
	CROSS APPLY(
				SELECT STRING_AGG(CAST(LeagueGroupID AS VARCHAR(20)), ',') WITHIN GROUP (ORDER BY LeagueGroupID)  AS LeagueGroupIDs
					FROM #CustomerClassRuleLeagueGroup_History ps  
					WHERE ps.RuleID = a.RuleID 
			)c

	-- Log new updated data
	SET @xml = (
			SELECT	@UserID						AS '@UserID',				
					@IP							AS '@IP',			
					COALESCE(CAST(@ErrMsg	AS VARCHAR(400)),SPACE(1))	AS '@ErrMsg',
					COALESCE(CAST(@ErrCode	AS VARCHAR(50)),SPACE(1))	AS '@ErrCode',
					(
						SELECT DISTINCT cs.RuleID					AS '@RuleID',
							cs.CustomerClass					AS '@CustomerClass',
							cs.CustomerClassDetail				AS '@CustomerClassDetail',
							cs.RuleTitle						AS '@RuleTitle',
							cs.SportType						AS '@SportType',
							cs.IsLive							AS '@isLive',
							cs.DiffBalanceRatio					AS '@DiffBalanceRatio',
							cs.NextBetInterval					AS '@NextBetInterval',
							cs.SuperBetInterval					AS '@SuperBetInterval',
							cs.SiteBetInterval					AS '@SiteBetInterval',
							cs.MinBet							AS '@MinBet',
							cs.MaxBet							AS '@MaxBet',
							cs.MaxPerMatch						AS '@MaxPerMatch',
							cs.RepeatedBets						AS '@RepeatedBets',
							cs.SeizeBetTicket					AS '@SeizeBetTicket',
							cs.DisableParlay					AS '@DisableParlay',
							cs.PeakHourSpreadAdjustment			AS '@PeakHourSpreadAdjustment',
							cs.AgentBetInterval					AS '@AgentBetInterval',
							cs.LeagueGroupIDs					AS '@LeagueGroupIDs',
							cs.IsTest							AS '@IsTest'	
						FROM	#CustomerClassRule_History AS cs	
						ORDER BY cs.RuleID
						FOR XML PATH('ClassRule'),
						TYPE
					)
			FOR XML PATH('R'),
			TYPE
		)
	SET @logSpData_Old = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')
	SET @xml = (
			SELECT	@UserID						AS '@UserID',				
					@IP							AS '@IP',			
					COALESCE(CAST(@ErrMsg	AS VARCHAR(400)),SPACE(1))	AS '@ErrMsg',
					COALESCE(CAST(@ErrCode	AS VARCHAR(50)),SPACE(1))	AS '@ErrCode',
					(
						SELECT DISTINCT cs.RuleID					AS '@RuleID',
								cs.CustomerClass					AS '@CustomerClass',
								cs.CustomerClassDetail				AS '@CustomerClassDetail',
								cs.RuleTitle						AS '@RuleTitle',
								cs.SportType						AS '@SportType',
								cs.IsLive							AS '@isLive',
								cs.DiffBalanceRatio					AS '@DiffBalanceRatio',
								cs.NextBetInterval					AS '@NextBetInterval',
								cs.SuperBetInterval					AS '@SuperBetInterval',
								cs.SiteBetInterval					AS '@SiteBetInterval',
								cs.MinBet							AS '@MinBet',
								cs.MaxBet							AS '@MaxBet',
								cs.MaxPerMatch						AS '@MaxPerMatch',
								cs.RepeatedBets						AS '@RepeatedBets',
								cs.SeizeBetTicket					AS '@SeizeBetTicket',
								cs.DisableParlay					AS '@DisableParlay',
								cs.PeakHourSpreadAdjustment			AS '@PeakHourSpreadAdjustment',
								cs.AgentBetInterval					AS '@AgentBetInterval',
								cs.LeagueGroupIDs					AS '@LeagueGroupIDs',
								cs.IsTest							AS '@IsTest'	
						FROM	#CustomerClassRule AS cs	
						ORDER BY cs.RuleID
						FOR XML PATH('ClassRule'),
						TYPE
					)
			FOR XML PATH('R'),
			TYPE
		)
	SET @logSpData = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')

	SELECT @EndRun	= GETDATE(), @Duration = DATEDIFF(MILLISECOND, @StartRun, @EndRun)

	EXEC  Acc_WriteLog_UserLog_RunSP_Wrapper
				@CustID  = @UserID,
				@UserID = @UserID,
				@ActionID = 31901,
				@TrackingValue = @LogSPData,
			    @TrackingValue2 = @logSpData_Old,
				@duration = @Duration

END
GO
