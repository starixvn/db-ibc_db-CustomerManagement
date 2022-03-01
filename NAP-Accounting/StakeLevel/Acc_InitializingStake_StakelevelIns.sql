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
			, IsCredit		BIT Default((0))
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
	
	INSERT INTO #NewInputDateTbl(RowID, SportType, BetType, Currency, NewMinBet, NewMaxBet, CurMinBet	
								, CurMaxBet, GameGroupID, IsCredit)
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
						ELSE NULL END,
		a.MinLabel	= 	CAST(CAST(NewMinBet AS money) AS VARCHAR(50)),
		a.MaxLabel	=	CONVERT(VARCHAR(20),CONVERT(FLOAT,NewMaxBet)) --NewMaxBet		
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
	
	
	
	
	
	select * , CAST(NewMinBet as float) as znew , CONVERT(FLOAT,NewMaxBet)  as znewMax
		from #NewInputDateTbl order by RowID
		
	DROP TABLE #NewInputDateTbl
END								