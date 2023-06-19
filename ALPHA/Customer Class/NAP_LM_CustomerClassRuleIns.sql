/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,bodbLicenseeNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_LM_CustomerClassRuleIns] 
	@Rules  VARCHAR(MAX)
	, @UserID		INT
	, @IsTest		TINYINT	
	, @IP			VARCHAR(50)		= ''
	, @ErrCode		TINYINT				= 0		OUTPUT
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
		- 20230613@Luke: Option to apply Seize Bet if reach risk balance [Redmine: #187771]

	Param's Explanation:
	* @Rules:
		'<ROOT><r 
				RuleID=1 
				CustomerClass="200" 
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
				SeizeBetAccumulateBal = 0
				EnableParlay = 1 
				PeakHourSpreadAdjustment = 5  
				AgentBetInterval = 6
				LeagueGroupIDs ='1125,1126,1124,1128,1126'/> 
		</ROOT>'

	Example: NAP_LM_CustomerClassRuleIns @Rules ='<ROOT><r RuleID=1 CustomerClass="200" RuleTitle = "Rule 1" SportType = 99  IsLive = 1 DiffBalanceRatio = 12 BetDelay = 5  NextBetInterval =6  SuperBetInterval = 4 SiteBetInterval = 6 MinBet = 12  MaxBet = 8 MaxPerMatch =11 RepeatedBets =5  SeizeBetTicket = 9  SeizeBetAccumulateBal = 0 EnableParlay = 1 PeakHourSpreadAdjustment = 5 AgentBetInterval = 6 LeagueGroupIDs ='1125,1126,1124,1128,1126'/> </ROOT>' ,@ErrCode =0, @ErrMsg = '' ,  @IP = '11.12.11.10', @UserID = 6
*/ 
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @StartRun	  DATETIME
		, @EndRun		  DATETIME
		, @Duration		  INT
		, @iDoc			  INT
		, @RuleID		  INT
		, @STT			  INT
		, @logSpData	  NVARCHAR(MAX)
		, @xml			  XML
	
	--Check if XML is null or empty
	IF @Rules IS NULL OR @Rules = ''
		RETURN
	
	CREATE TABLE #CustomerClassRule( RuleID INT, CustomerClass SMALLINT, RuleTitle VARCHAR(500),
			SportType SMALLINT, IsLive TINYINT, DiffBalanceRatio DECIMAL(9, 2), BetDelay DECIMAL(9, 2),
			NextBetInterval SMALLINT, SuperBetInterval SMALLINT, SiteBetInterval SMALLINT,
			MinBet INT, MaxBet INT, MaxPerMatch INT, RepeatedBets TINYINT, SeizeBetTicket TINYINT, SeizeBetAccumulateBal BIT DEFAULT(0),
			EnableParlay BIT, PeakHourSpreadAdjustment SMALLINT, AgentBetInterval SMALLINT, LeagueGroupIDs VARCHAR(MAX), IsTest TINYINT, Enable BIT DEFAULT(1), 
			isFinished BIT DEFAULT(0), STT INT IDENTITY (1,1))
	BEGIN TRY
		EXECUTE	sp_xml_preparedocument	@iDoc OUTPUT,	@Rules;
		
		INSERT INTO	#CustomerClassRule (CustomerClass 				
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
					 ,	SeizeBetAccumulateBal
					 ,	EnableParlay 		  
					 ,	PeakHourSpreadAdjustment
					 ,	AgentBetInterval
					 ,	LeagueGroupIDs
					 ,	IsTest	) 
		SELECT	CAST(Data.CustomerClass AS SMALLINT) AS CustomerClass				
			,	CASE WHEN Data.RuleTitle = '' THEN null ELse CAST(Data.RuleTitle AS VARCHAR(500)) END AS RuleTitle 					    
			,	 CAST(Data.SportType AS SMALLINT)  AS SportType 					
			,	CASE WHEN Data.IsLive = '' THEN null ELse CAST(Data.IsLive AS TINYINT) END AS IsLive  
			,	CASE WHEN Data.DiffBalanceRatio = '' THEN null ELse (CAST(Data.DiffBalanceRatio AS DECIMAL(9,2))/100) + 1 END AS DiffBalanceRatio 			   
			,	CASE WHEN Data.BetDelay = '' THEN null ELse (CAST(Data.BetDelay AS DECIMAL(9,2))/100) + 1 END AS BetDelay 					   
			,	CASE WHEN Data.NextBetInterval = '' THEN null ELse CAST(Data.NextBetInterval AS SMALLINT) END AS NextBetInterval 			
			,	CASE WHEN Data.SuperBetInterval = '' THEN null ELse CAST(Data.SuperBetInterval AS SMALLINT) END AS SuperBetInterval 			
			,	CASE WHEN Data.SiteBetInterval = '' THEN null ELse CAST(Data.SiteBetInterval AS SMALLINT) END AS SiteBetInterval 			
			,	CASE WHEN Data.MinBet = '' THEN null ELse CAST(Data.MinBet AS INT) END AS MinBet 					
			,	CASE WHEN Data.MaxBet = '' THEN null ELse CAST(Data.MaxBet AS INT) END AS MaxBet 					
			,	CASE WHEN Data.MaxPerMatch = '' THEN null ELse CAST(Data.MaxPerMatch AS INT) END AS MaxPerMatch 				
			,	CASE WHEN Data.RepeatedBets = '' THEN null ELse CAST(Data.RepeatedBets AS TINYINT) END AS RepeatedBets 				
			,	CASE WHEN Data.SeizeBetTicket = '' THEN null ELse CAST(Data.SeizeBetTicket AS TINYINT) END AS SeizeBetTicket
			,	CASE WHEN Data.SeizeBetAccumulateBal = '' THEN 0 ELse CAST(Data.SeizeBetAccumulateBal AS BIT) END AS SeizeBetAccumulateBal
			,	CASE WHEN Data.EnableParlay = '' THEN null ELse CAST(Data.EnableParlay AS BIT) END AS EnableParlay 	 
			,	CASE WHEN Data.PeakHourSpreadAdjustment = '' THEN null ELse CAST(Data.PeakHourSpreadAdjustment AS SMALLINT) END AS PeakHourSpreadAdjustment
			,	CASE WHEN Data.AgentBetInterval = '' THEN null ELse CAST(Data.AgentBetInterval AS SMALLINT) END AS AgentBetInterval
			,	Data.LeagueGroupIDs 				
			,	@IsTest AS IsTest 
		FROM OPENXML(@iDoc, '/ROOT/r', 1) 
		WITH (     
			 CustomerClass 				SMALLINT,       
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
			 SeizeBetAccumulateBal		CHAR(1),
			 EnableParlay 				VARCHAR(1),         
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
	
	IF 	EXISTS( SELECT TOP 1 1 FROM #CustomerClassRule WHERE ISNULL(RuleID,0) <> 0)	
	BEGIN
		SELECT @ErrCode = 100 , @ErrMsg = 'The Rule title is existed' 
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
	
	IF 	EXISTS(SELECT TOP 1 1 FROM #CustomerClassRule a
					INNER JOIN #CustomerClassRule b ON a.RuleTitle = b.RuleTitle
				 WHERE a.STT <> b.STT)	OR EXISTS(SELECT TOP 1 1 FROM CustomerClassRule a  WITH(NOLOCK)
					INNER JOIN #CustomerClassRule b ON a.RuleTitle = b.RuleTitle)
	BEGIN
		SELECT @ErrCode = 104 , @ErrMsg = 'The Rule Title is existed' 
		RETURN
	END	 

	IF 	EXISTS( SELECT TOP 1 1 FROM #CustomerClassRule WHERE ISNULL(LeagueGroupIDs,'') = '')	
	BEGIN
		SELECT @ErrCode = 105 , @ErrMsg = 'The League Group ID is not existed' 
		RETURN
	END	 

	WHILE (1 = 1)
	BEGIN
		UPDATE TOP (1) #CustomerClassRule
		SET isFinished = 1
			,@STT=STT
		WHERE isFinished = 0	
			
		IF @@ROWCOUNT = 0 OR @ErrCode<>0 BREAK 
			
		INSERT INTO CustomerClassRule(
 			CustomerClass 				
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
		,	SeizeBetAccumulateBal
		,	EnableParlay 		  
		,	PeakHourSpreadAdjustment 	
		,	AgentBetInterval
		,	Enable 	
		,	IsTest
		,  LastModifiedUser
		,  LastModifiedTime)	
		SELECT
			CustomerClass 				
			,RuleTitle 					    
			,SportType 					
			,IsLive 					
			,DiffBalanceRatio 			    
			,BetDelay 					    
			,NextBetInterval 			
			,SuperBetInterval 			
			,SiteBetInterval 			
			,MinBet 					
			,MaxBet 					
			,MaxPerMatch 				
			,RepeatedBets 				
			,SeizeBetTicket 
			,SeizeBetAccumulateBal
			,EnableParlay 				  
			,PeakHourSpreadAdjustment 	
			,AgentBetInterval
			,Enable
			,IsTest
			,@UserID
			,GETDATE()
		FROM #CustomerClassRule
		WHERE STT = @STT
		
		SET @RuleID = SCOPE_IDENTITY()
			
		UPDATE #CustomerClassRule SET RuleID  = @RuleID WHERE STT = @STT
			
		INSERT INTO CustomerClassRuleLeagueGroup(RuleID ,  LeagueGroupID)	
		SELECT a.RuleID ,CAST(b.LeagueGroupID  AS SMALLINT) AS LeagueGroupID
		FROM #CustomerClassRule a
		CROSS APPLY ( SELECT VALUE AS LeagueGroupID FROM STRING_SPLIT(a.LeagueGroupIDs,',') WHERE VALUE <> '' ) b
		WHERE STT = @STT

	END	
	-- Log new updated data
	SET @xml = (
			SELECT	@UserID						AS '@UserID',				
					@IP							AS '@IP',		
					COALESCE(CAST(@ErrMsg	AS VARCHAR(400)),SPACE(1))	AS '@ErrMsg',
					COALESCE(CAST(@ErrCode	AS VARCHAR(50)),SPACE(1))	AS '@ErrCode',
					(
						SELECT DISTINCT cs.RuleID					AS '@RuleID',
								cs.CustomerClass					AS '@CustomerClass',
								cs.RuleTitle						AS '@RuleTitle',
								cs.SportType						AS '@SportType',
								cs.IsLive							AS '@IsLive',
								cs.DiffBalanceRatio					AS '@DiffBalanceRatio',
								cs.NextBetInterval					AS '@NextBetInterval',
								cs.SuperBetInterval					AS '@SuperBetInterval',
								cs.SiteBetInterval					AS '@SiteBetInterval',
								cs.MinBet							AS '@MinBet',
								cs.MaxBet							AS '@MaxBet',
								cs.MaxPerMatch						AS '@MaxPerMatch',
								cs.RepeatedBets						AS '@RepeatedBets',
								cs.SeizeBetTicket					AS '@SeizeBetTicket',
								cs.SeizeBetAccumulateBal			AS '@SeizeBetAccumulateBal',
								cs.EnableParlay						AS '@EnableParlay',
								cs.PeakHourSpreadAdjustment			AS '@PeakHourSpreadAdjustment',
								cs.AgentBetInterval					AS '@AgentBetInterval',
								cs.LeagueGroupIDs					AS '@LeagueGroupIDs',
								cs.IsTest							AS '@IsTest',
								cs.Enable							AS '@Enable'	
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
				@ActionID = 31902,
				@TrackingValue = @LogSPData,
				@duration = @Duration

END
GO
