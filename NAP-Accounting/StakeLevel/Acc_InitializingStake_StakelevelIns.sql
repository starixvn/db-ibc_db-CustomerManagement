/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_InitializingStake_StakelevelIns] 
	-- Add the parameters for the stored procedure here
	 @InputData	VARCHAR(MAX) = ''
	,@UserID	INT
	,@IP		VARCHAR(50)		= ''
	,@ErrCode	INT = 0				OUTPUT
	,@ErrMsg	NVARCHAR(4000) = '' OUTPUT
AS
/*
	Task : NAP -  Flexible Initializing Stake Level
	DB: DBCUST/CustDB
	Original: 
	Revisions:
		- 20220210@Winfred: NAP -  Flexible Initializing insert Stake Level [Redmine: #167128]
	
	Param's Explanation:
		• @pInputData : 
		<ROOT>
			<BetLimit 
					SportType="1" 
					BetType="1"
					CreditCurrency = "US$, Yen, $US, UT, USD" 
					DepositCurrency = "US$, USDT"
					NewMinBet="1" 
					NewMaxBet="30000" 
					CurMinBet="30000" 
					CurMaxBet="30000" 
					GameGroupID="30000" 
			/>
	</ROOT>
*/
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @xml XML, @StartRun	DATETIME, @EndRun DATETIME, @Duration INT, @logSpData NVARCHAR(MAX)
	DECLARE @NewStakeLevelTbl TABLE (
			RowID				INT IDENTITY (1,1)
			, SportType			SMALLINT
			, BetType			SMALLINT
			, CreditCurrency	VARCHAR(500)
			, DepositCurrency	VARCHAR(500)
			, NewMinBet			DECIMAL(19,8)
			, NewMaxBet			DECIMAL(19,8)
			, CurMinBet			DECIMAL(19,8)
			, CurMaxBet			DECIMAL(19,8)
			, GameGroupID		INT
		)
	
	CREATE TABLE #NewInputDateTbl (
			  RowID			INT 
			, SportType		SMALLINT
			, OrgBetType	SMALLINT
			, BetType		SMALLINT
			, Currency		VARCHAR(50)
			, ExchangeId	INT
			, MinLabel		VARCHAR(50)
			, MaxLabel		VARCHAR(50)
			, NewMinBet		DECIMAL(19,8)
			, NewMaxBet		DECIMAL(19,8)
			, CurMinBet		DECIMAL(19,8)
			, CurMaxBet		DECIMAL(19,8)
			, GameGroupID	INT
			, IsCredit		BIT DEFAULT((0))
			, SettingType	SMALLINT
		)
	
	IF @InputData IS NULL OR @InputData = ''
		RETURN
		
	SELECT	@ErrCode = 0 , @ErrMsg = '' 
	
	SET @StartRun = GETDATE()	
	--Parse XML data
	DECLARE @iDoc INT

	EXEC sp_xml_preparedocument @iDoc OUTPUT
		, @InputData

	INSERT INTO @NewStakeLevelTbl(SportType, BetType, CreditCurrency, DepositCurrency, NewMinBet, NewMaxBet, CurMinBet, CurMaxBet, GameGroupID)
	SELECT SportType, BetType, CreditCurrency, DepositCurrency, NewMinBet, NewMaxBet, CurMinBet, CurMaxBet, GameGroupID
	FROM OPENXML(@iDoc, '/ROOT/BetLimit', 1) WITH (
				SportType			SMALLINT
				, BetType			SMALLINT
				, CreditCurrency	VARCHAR(500)
				, DepositCurrency	VARCHAR(500)
				, NewMinBet			DECIMAL(19,8)
				, NewMaxBet			DECIMAL(19,8)
				, CurMinBet			DECIMAL(19,8)
				, CurMaxBet			DECIMAL(19,8)
				, GameGroupID		INT
			)
	EXEC sp_xml_removedocument @iDoc
	
	INSERT INTO #NewInputDateTbl(RowID, SportType, BetType, Currency, NewMinBet, NewMaxBet, CurMinBet, CurMaxBet, GameGroupID, IsCredit)
	SELECT RowID, SportType, BetType, t.Currency, NewMinBet, NewMaxBet, CurMinBet, CurMaxBet, GameGroupID, 1 AS IsCredit
	FROM @NewStakeLevelTbl nsl
		CROSS APPLY (
				SELECT DISTINCT RTRIM(LTRIM(val)) AS Currency FROM dbo.strSplit(nsl.CreditCurrency, ',')
			) t
	WHERE nsl.CreditCurrency <> ''
	UNION ALL
	SELECT RowID, SportType, BetType, t.Currency, NewMinBet, NewMaxBet, CurMinBet, CurMaxBet, GameGroupID, 0 AS IsCredit 
	FROM @NewStakeLevelTbl nsl
		CROSS APPLY (
				SELECT DISTINCT RTRIM(LTRIM(val)) AS Currency FROM dbo.strSplit(nsl.DepositCurrency, ',')
			) t		
	WHERE nsl.DepositCurrency <> ''
	
	UPDATE a 
	SET a.ExchangeId = CASE WHEN a.IsCredit = 1 AND e.OfferSite IN (0,1) THEN e.ExchangeId
							WHEN a.IsCredit = 0 AND e.OfferSite IN (0,2) THEN e.ExchangeId
						ELSE NULL END
		,a.MinLabel  =  CASE WHEN CAST(NewMinBet AS BIGINT) < NewMinBet 
						THEN REPLACE(RTRIM(REPLACE(NewMinBet, '0', ' ')), ' ', '0') 
						ELSE REPLACE(REPLACE(RTRIM(REPLACE(NewMinBet, '0', ' ')), ' ', '0'),'.','') END 
		,a.MaxLabel  =  CASE WHEN CAST(NewMaxBet AS BIGINT) < NewMaxBet 
						THEN REPLACE(RTRIM(REPLACE(NewMaxBet, '0', ' ')), ' ', '0') 
						ELSE REPLACE(REPLACE(RTRIM(REPLACE(NewMaxBet, '0', ' ')), ' ', '0'),'.','') END 								
	FROM  #NewInputDateTbl a
		INNER JOIN Exchange e WITH(NOLOCK) ON a.Currency = e.currency
	
	UPDATE a 
	SET a.SettingType =  psd.SettingType , a.OrgBetType = psd.BetType	
	FROM  #NewInputDateTbl a
		INNER JOIN ProductSettingDetail psd WITH(NOLOCK) ON a.SportType = psd.SportType
	WHERE a.IsCredit = 1 AND psd.SettingType IN (7, 17, 8)
	
	UPDATE a 
	SET a.SettingType =  ps.SettingType	, a.OrgBetType = psd.BetType
	FROM  #NewInputDateTbl a
		INNER JOIN Dep_ProductSettingDetail psd WITH(NOLOCK) ON a.SportType = psd.SportType
		INNER JOIN Dep_ProductSetting ps WITH(NOLOCK) ON ps.ProductSettingID = psd.ProductSettingID
	WHERE a.IsCredit = 0  AND ps.SettingType IN (7, 8)
	
	-- Credit Group Stake Level
	--INSERT INTO StakeLevel(GameTypeID,ExchangeId,GameGroupID)
	SELECT a.OrgBetType AS GameTypeID,ExchangeId,GameGroupID
	FROM #NewInputDateTbl a 
	WHERE a.IsCredit =  1 AND SettingType IN (8) 
	AND NOT EXISTS( SELECT TOP 1 1 FROM StakeLevel tmp WITH(NOLOCK) 
					WHERE tmp.GameTypeID = a.OrgBetType AND a.ExchangeId = tmp.ExchangeId 
						  AND a.GameGroupID = tmp.GameGroupID)
	ORDER BY a.OrgBetType
	
	;WITH STAKE_TEMP AS (
		SELECT t.StakeLevelID,s.BetType AS GameTypeID,s.MinLabel,s.MaxLabel,s.NewMinBet AS MinStake,s.NewMaxBet AS MaxStake,s.ExchangeId,s.GameGroupID
		FROM #NewInputDateTbl s 
		CROSS APPLY (
			SELECT StakeLevelID  FROM StakeLevel WITH(NOLOCK) WHERE GameTypeID = s.OrgBetType AND ExchangeId = s.ExchangeId AND GameGroupID = s.GameGroupID
		) t
		WHERE s.IsCredit =  1 AND SettingType IN (8)
	)
	--Select * from STAKE_TEMP ORDER BY GameTypeID
	MERGE StakeLevelGroupDetail as g 
	USING STAKE_TEMP s on g.StakeLevelID = s.StakeLevelID AND g.GameTypeID = s.GameTypeID
	WHEN MATCHED THEN UPDATE SET 
						g.MinLabel = s.MinLabel,
						g.MaxLabel = s.MaxLabel,
						g.MinStake =  s.MinStake,
						g.MaxStake =  s.MaxStake
	WHEN NOT MATCHED THEN 
						INSERT (StakeLevelID,GameTypeID,MinLabel,MaxLabel,MinStake,MaxStake)
						VALUES (s.StakeLevelID,s.GameTypeID,s.MinLabel,s.MaxLabel,s.MinStake,s.MaxStake)					
						 ;
	-- Credit Stake Level
	--INSERT INTO StakeLevel(GameTypeID, MinLabel, MaxLabel, MinStake, MaxStake,ExchangeId)
	SELECT a.BetType AS GameTypeID,MinLabel,MaxLabel,NewMinBet,NewMaxBet, ExchangeId
	FROM #NewInputDateTbl a 
	WHERE a.IsCredit =  1 AND SettingType IN (7,17) 
	AND NOT EXISTS( SELECT TOP 1 1 FROM StakeLevel tmp WITH(NOLOCK) 
					WHERE tmp.GameTypeID = a.BetType AND a.ExchangeId = tmp.ExchangeId 
						  AND a.NewMinBet = MinStake AND a.NewMaxBet = MaxStake)
	ORDER BY a.BetType
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	select  *
	--NewMinBet , CHARINDEX('.',MinLabel) AS z, 
	--LEN(MinLabel) as z1 ,
	--CONVERT(VARCHAR(30), CAST(NewMinBet AS DECIMAL(19,0))) as z2 , 
	--CONVERT(float, '0.' + SUBSTRING(MinLabel, CHARINDEX('.',MinLabel) + 1  , LEN(MinLabel)  - CHARINDEX('.',MinLabel))) as z4,
	--CONVERT(VARCHAR(30),CONVERT(float, '0.' + SUBSTRING(MinLabel, CHARINDEX('.',MinLabel) + 1  , LEN(MinLabel)  - CHARINDEX('.',MinLabel)))) as z6,
	--LEN(MinLabel)  - CHARINDEX('.',MinLabel) as z7,
	--SUBSTRING(CONVERT(VARCHAR(30),CONVERT(float, '0.' + SUBSTRING(MinLabel, CHARINDEX('.',MinLabel) + 1, LEN(MinLabel)  - CHARINDEX('.',MinLabel)))), 3,LEN(MinLabel)  - CHARINDEX('.',MinLabel)) as z5
	--,CAST(MinLabel AS DECIMAL(19,0)) as  z6
	--,NewMinBet as z9
	--,CONVERT(VARCHAR(30), CAST(MinLabel AS DECIMAL(19,0))) + CASE WHEN CAST(MinLabel AS DECIMAL(19,0)) < NewMinBet THEN '.' +	
	--SUBSTRING(CONVERT(VARCHAR(30),CONVERT(float, '0.' + SUBSTRING(MinLabel, CHARINDEX('.',MinLabel) + 1, LEN(MinLabel)  - CHARINDEX('.',MinLabel)))), 3,LEN(MinLabel)  - CHARINDEX('.',MinLabel)) ELSE '' END as z8
	--* , CAST(NewMinBet as float) as znew ,
	-- CONVERT(FLOAT,NewMaxBet)  as znewMax,
	-- cast(cast(NewMaxBet as DECIMAL(19,8)) as float) AS MaxLabel
	, CASE WHEN CAST(NewMinBet AS BiGINT) < NewMinBet 
						THEN REPLACE(RTRIM(REPLACE(NewMinBet, '0', ' ')), ' ', '0') 
						ELSE SUBSTRING(REPLACE(RTRIM(REPLACE(NewMinBet, '0', ' ')), ' ', '0'),1,LEN(REPLACE(RTRIM(REPLACE(NewMinBet, '0', ' ')), ' ', '0')) -1) END  as z1
						, REPLACE(RTRIM(REPLACE(NewMinBet, '0', ' ')), ' ', '0')  as z2
						,CAST(NewMinBet AS BiGINT) as z3
						,NewMinBet as z4
		from #NewInputDateTbl order by RowID
		
		
		
	DROP TABLE #NewInputDateTbl
END								