/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_InitializingGlobal_BetLimitCheck] 
	-- Add the parameters for the stored procedure here
	 @InputData				VARCHAR(MAX)=''
	, @ProductID			TINYINT=0			OUTPUT
	, @NotiCode				INT=0				OUTPUT
	, @NotiMsg				NVARCHAR(4000)=''	OUTPUT
	, @ErrCode				INT=0				OUTPUT
	, @ErrMsg				NVARCHAR(4000)=''	OUTPUT
AS
/*
	Task : NAP - Flexible Initializing Stake Level/Bet Limit
	DB: DBACC/bodb02
	Original: 
	Revisions:
		- 20220210@Winfred: NAP - Flexible Initializing check Stake Level [Redmine: #167128]
		- 20220420@Winfred: Fix setting type 7 get bettype original [Redmine: #171750]
		- 20220705@Tacy: NAP - Flexible Initializing Global Bet Limit [Redmine: #174509]
		- 20220921@Tacy: Add column MaxGameStake [Redmine: #174509]
	
	Param's Explanation:
		• @pInputData : 
		<ROOT>
			<BetLimit 
					SportType="1" 
					BetType="1"
					Site="53"
					CreditCurrency="US$, Yen, $US, UT, USD" 
					DepositCurrency="US$, USDT"
					NewMinBet="1" 
					NewMaxBet="30000" 
					NewMaxPerMatch="0" 
					NewMaxPerBall="0" 
					NewMaxGameStake="0"
					CurMinBet="30000" 
					CurMaxBet="30000" 
					CurMaxPerMatch="0" 
					CurMaxPerBall="0" 
					CurMaxGameStake="0"
					GameGroupID="30000" 
			/>
	</ROOT>
*/
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @xml XML, @ErrBetType VARCHAR(10), @ValueError VARCHAR(500)='', @RowError VARCHAR(200)='', @SportType  SMALLINT , @BetType  SMALLINT 
	DECLARE @NewGlobalTbl TABLE (
			 RowID				INT IDENTITY (1, 1)
			, SportType			SMALLINT
			, BetType			SMALLINT
			, SiteID			INT
			, CreditCurrency	VARCHAR(500)
			, DepositCurrency	VARCHAR(500)
			, NewMinBet			DECIMAL(19,8)
			, NewMaxBet			DECIMAL(19,8)
			, NewMaxPerMatch	DECIMAL(19,8)
			, NewMaxPerBall		DECIMAL(19,8)
			, NewMaxGameStake	DECIMAL(19,8)
			, CurMinBet			DECIMAL(19,8)
			, CurMaxBet			DECIMAL(19,8)
			, CurMaxPerMatch	DECIMAL(19,8)
			, CurMaxPerBall		DECIMAL(19,8)
			, CurMaxGameStake	DECIMAL(19,8)
			, GameGroupID		INT
		)
	
	CREATE TABLE #NewInputDateTbl (
			 RowID				INT 
			, SportType			SMALLINT
			, OrgBetType		SMALLINT
			, BetType			SMALLINT
			, SiteID			INT
			, Currency			VARCHAR(50)
			, ExchangeId		INT
			, NewMinBet			DECIMAL(19,8)
			, NewMaxBet			DECIMAL(19,8)
			, NewMaxPerMatch	DECIMAL(19,8)
			, NewMaxPerBall		DECIMAL(19,8)
			, NewMaxGameStake	DECIMAL(19,8)
			, CurMinBet			DECIMAL(19,8)
			, CurMaxBet			DECIMAL(19,8)
			, CurMaxPerMatch	DECIMAL(19,8)
			, CurMaxPerBall		DECIMAL(19,8)
			, CurMaxGameStake	DECIMAL(19,8)
			, GameGroupID		INT
			, IsCredit			BIT Default((0))
			, SettingType		SMALLINT
			, ProductID		TINYINT
		)
	
	CREATE TABLE #Bettype (typeid INT PRIMARY KEY, typenamee NVARCHAR(128), typedesc NVARCHAR(128))
	CREATE TABLE #Sports(SportType TINYINT PRIMARY KEY, SportName NVARCHAR(50))
	CREATE TABLE #Currency(Currency	VARCHAR(50))
	CREATE TABLE #RowDuplicate(RowIDF INT, RowIDT INT)
	
	IF @InputData IS NULL OR @InputData=''
		RETURN
	
	SELECT	@ErrCode	= 0, @ErrMsg='', @NotiCode=0, @NotiMsg=''
	
	--Parse XML data
	DECLARE @iDoc INT

	EXEC sp_xml_preparedocument @iDoc OUTPUT
		, @InputData

	INSERT INTO @NewGlobalTbl(	SportType, BetType, SiteID, CreditCurrency, DepositCurrency, 
								NewMinBet, NewMaxBet, NewMaxPerMatch, NewMaxPerBall, NewMaxGameStake, 
								CurMinBet, CurMaxBet, CurMaxPerMatch, CurMaxPerBall, CurMaxGameStake, 
								GameGroupID)
	SELECT	SportType, BetType, Site, CreditCurrency, DepositCurrency, 
			CASE WHEN ISNUMERIC(NewMinBet)=0		THEN NULL ELSE NewMinBet		END NewMinBet,
			CASE WHEN ISNUMERIC(NewMaxBet)=0		THEN NULL ELSE NewMaxBet		END NewMaxBet, 
			CASE WHEN ISNUMERIC(NewMaxPerMatch)=0	THEN NULL ELSE NewMaxPerMatch	END NewMaxPerMatch, 
			CASE WHEN ISNUMERIC(NewMaxPerBall)=0	THEN NULL ELSE NewMaxPerBall	END NewMaxPerBall, 
			CASE WHEN ISNUMERIC(NewMaxGameStake)=0	THEN NULL ELSE NewMaxGameStake	END NewMaxGameStake, 
			
			CASE WHEN ISNUMERIC(CurMinBet)=0		THEN NULL ELSE CurMinBet		END CurMinBet,
			CASE WHEN ISNUMERIC(CurMaxBet)=0		THEN NULL ELSE CurMaxBet		END CurMaxBet, 
			CASE WHEN ISNUMERIC(CurMaxPerMatch)=0	THEN NULL ELSE CurMaxPerMatch	END CurMaxPerMatch, 
			CASE WHEN ISNUMERIC(CurMaxPerBall)=0	THEN NULL ELSE CurMaxPerBall	END CurMaxPerBall, 
			CASE WHEN ISNUMERIC(CurMaxGameStake)=0	THEN NULL ELSE CurMaxGameStake	END CurMaxGameStake, 
			
			CASE WHEN ISNUMERIC(GameGroupID)=0 THEN NULL ELSE GameGroupID END GameGroupID
	FROM OPENXML(@iDoc, '/ROOT/BetLimit', 1) WITH (
				 SportType			SMALLINT
				, BetType			SMALLINT
				, Site				INT
				, CreditCurrency	VARCHAR(500)
				, DepositCurrency	VARCHAR(500)
				, NewMinBet			VARCHAR(50)
				, NewMaxBet			VARCHAR(50)
				, NewMaxPerMatch	VARCHAR(50)
				, NewMaxPerBall		VARCHAR(50)
				, NewMaxGameStake	VARCHAR(50)
				, CurMinBet			VARCHAR(50)
				, CurMaxBet			VARCHAR(50)
				, CurMaxPerMatch	VARCHAR(50)
				, CurMaxPerBall		VARCHAR(50)
				, CurMaxGameStake	VARCHAR(50)
				, GameGroupID		VARCHAR(50)
			)
	EXEC sp_xml_removedocument @iDoc

	INSERT INTO #Sports	(SportType, SportName)	
	SELECT SportType, SportName 
	FROM dbo.Sports WITH(NOLOCK)
	
	INSERT INTO #Bettype (typeid, typenamee, typedesc)	
	SELECT typeid, typenamee, typedesc
	FROM dbo.Bettype WITH(NOLOCK)

	SELECT TOP (1)
			@ErrCode=CASE WHEN ISNULL(SportType, '')=''		THEN 131
						 WHEN ISNULL(BetType, '')=''		THEN 132
						 WHEN NewMinBet IS NULL				THEN 133
						 WHEN NewMaxBet IS NULL				THEN 134
						 WHEN (SportType IN (1, 2, 3, 5, 8, 10, 11, 99, --SportsBook
											 161, 164, 168, 202, 199, 220, 222, 169, 175, 217, 218) OR -- Number Game, Happy 5, RNG Keno, Virtual Sports 2, Lottery, Table Game, Sports Lottery, Bitcoin, NG2
						 	 (SportType BETWEEN 180 AND 186)	OR	--Virtual Sports (Inspired)
							 (SportType BETWEEN 213 AND 215)	OR	--NG2
							 (SportType BETWEEN 190 AND 197))		--Virtual Sports 2 (Betradar)
							AND NewMaxPerMatch IS NULL							THEN 135	
						 WHEN SportType=161 AND NewMaxPerBall IS NULL			THEN 136
						 WHEN typedesc='BuyBonus' AND NewMaxGameStake IS NULL	THEN 137

						 WHEN (NOT ((SportType IN (1, 2, 3, 5, 8, 10, 11, 99, 161, 164, 168, 202, 199, 220, 222, 169, 175, 217, 218) OR 
									(SportType BETWEEN 180 AND 186)	OR	
									(SportType BETWEEN 213 AND 215)	OR	
									(SportType BETWEEN 190 AND 197)))
								AND (NewMaxPerMatch IS NOT NULL OR CurMaxPerMatch IS NOT NULL)
							OR (SportType<>161 AND (NewMaxPerBall IS NOT NULL OR CurMaxPerBall IS NOT NULL)))				THEN 138
						 WHEN ISNULL(typedesc,'')<>'BuyBonus' 
							AND (NewMaxGameStake IS NOT NULL OR CurMaxGameStake IS NOT NULL)								THEN 139

						 WHEN (SportType<>161 AND NewMinBet=0)
							OR (NewMinBet=0 AND NOT (NewMaxBet=0 AND NewMaxPerBall=0 AND NewMaxPerMatch=0))					THEN 140 
						 WHEN (SportType<>161 AND NewMaxBet=0)
							OR (NewMaxBet=0 AND NOT (NewMinBet=0 AND NewMaxPerBall=0 AND NewMaxPerMatch=0))					THEN 141
						 WHEN ((SportType IN (1, 2, 3, 5, 8, 10, 11, 99, 164, 168, 202, 199, 220, 222, 169, 175, 217, 218) OR 
							   (SportType BETWEEN 180 AND 186)  OR	
							   (SportType BETWEEN 213 AND 215)  OR	
							   (SportType BETWEEN 190 AND 197)) AND NewMaxPerMatch=0)
							 OR
							 (SportType=161 AND NewMaxPerMatch=0 AND NOT (NewMaxBet=0 AND NewMinBet=0 AND NewMaxPerBall=0)) THEN 142

						 WHEN NewMinBet > NewMaxBet													THEN 143
						 WHEN (SportType IN (1, 2, 3, 5, 8, 10, 11, 99, 161, 164, 168, 202, 199, 220, 222, 169, 175, 217, 218) 
							OR (SportType BETWEEN 180 AND 186)		
							OR (SportType BETWEEN 213 AND 215)		
							OR (SportType BETWEEN 190 AND 197))	
							AND (NewMaxBet > NewMaxPerMatch)										THEN 144	
						 WHEN SportType=161 AND (NewMaxBet > NewMaxPerBall) AND NewMaxPerBall<>0	THEN 145	
						 WHEN SportType=161 AND (NewMaxPerBall > NewMaxPerMatch)					THEN 146

						 WHEN CurMinBet > CurMaxBet													THEN 147
						 WHEN (SportType IN (1, 2, 3, 5, 8, 10, 11, 99, 161, 164, 168, 202, 199, 220, 222, 169, 175, 217, 218) 
							OR (SportType BETWEEN 180 AND 186)		
							OR (SportType BETWEEN 213 AND 215)		
							OR (SportType BETWEEN 190 AND 197))	
							AND CurMaxBet > CurMaxPerMatch											THEN 148	
						 WHEN SportType=161 AND (CurMaxBet > CurMaxPerBall) AND CurMaxPerBall<>0	THEN 149	
						 WHEN SportType=161 AND (CurMaxPerBall > CurMaxPerMatch)					THEN 150

						 WHEN ISNULL(CreditCurrency, '')='' AND 
							  ISNULL(DepositCurrency, '')=''	THEN 122
						 ELSE 131 
					END, 

		 @ErrMsg =	 CASE WHEN ISNULL(SportType, '')=''		THEN 'Row ' + CAST(RowID AS NVARCHAR(50))+ ': The Sport Type is required field.' 
						  WHEN ISNULL(BetType, '')=''		THEN 'Row ' + CAST(RowID AS NVARCHAR(50))+ ': The Bet Type is required field.' 
						  WHEN NewMinBet IS NULL			THEN 'Row ' + CAST(RowID AS NVARCHAR(50))+ ': The New Min Bet is required field.' 
						  WHEN NewMaxBet IS NULL			THEN 'Row ' + CAST(RowID AS NVARCHAR(50))+ ': The New Max Bet is required field.' 
						  WHEN (SportType IN (1, 2, 3, 5, 8, 10, 11, 99, 164, 168, 202, 199, 220, 222, 169, 175, 217, 218) OR 
								(SportType BETWEEN 180 AND 186)	 OR	
								(SportType BETWEEN 213 AND 215)	 OR	
								(SportType BETWEEN 190 AND 197)) AND	
								NewMaxPerMatch IS NULL							THEN 'Row ' + CAST(RowID AS NVARCHAR(50))+ ': The New Max Per Match is required field.' 
						  WHEN SportType=161 AND NewMaxPerBall IS NULL			THEN 'Row ' + CAST(RowID AS NVARCHAR(50))+ ': The New Max Per Ball is a required field.' 
						  WHEN typedesc='BuyBonus' AND NewMaxGameStake IS NULL	THEN 'Row ' + CAST(RowID AS NVARCHAR(50))+ ': The New Max Game Stake is a required field.'
						  
						  WHEN NOT ((SportType IN (1, 2, 3, 5, 8, 10, 11, 99, 161, 164, 168, 202, 199, 220, 222, 169, 175, 217, 218) OR 
						 			(SportType BETWEEN 180 AND 186)	OR	
									(SportType BETWEEN 213 AND 215)	OR	
									(SportType BETWEEN 190 AND 197)))
							AND ((NewMaxPerMatch IS NOT NULL AND NewMaxPerBall IS NOT NULL)
								OR (CurMaxPerMatch IS NOT NULL AND CurMaxPerBall IS NOT NULL))				THEN 'Row ' + CAST(RowID AS NVARCHAR(50))+ ': You input redundant data with the product''s format. Please remove data on Max Per Match and Max Per Ball columns.'
						  WHEN NOT ((SportType IN (1, 2, 3, 5, 8, 10, 11, 99, 161, 164, 168, 202, 199, 220, 222, 169, 175, 217, 218) OR 
						 			(SportType BETWEEN 180 AND 186)	OR	
									(SportType BETWEEN 213 AND 215)	OR	
									(SportType BETWEEN 190 AND 197)))
							AND (NewMaxPerMatch IS NOT NULL	OR CurMaxPerMatch IS NOT NULL)					THEN 'Row ' + CAST(RowID AS NVARCHAR(50))+ ': You input redundant data with the product''s format. Please remove data on Max Per Match column.'
						  WHEN SportType<>161 AND (NewMaxPerBall IS NOT NULL OR CurMaxPerBall IS NOT NULL)	THEN 'Row ' + CAST(RowID AS NVARCHAR(50))+ ': You input redundant data with the product''s format. Please remove data on Max Per Ball column.'
						  WHEN ISNULL(typedesc,'')<>'BuyBonus' 
							AND (NewMaxGameStake IS NOT NULL OR CurMaxGameStake IS NOT NULL)				THEN 'Row ' + CAST(RowID AS NVARCHAR(50))+ ': You input redundant data with the product''s format. Please remove data on Max Game Stake column.'

						  WHEN (SportType<>161 AND NewMinBet=0)
							OR (NewMinBet=0 AND NOT (NewMaxBet=0 AND NewMaxPerBall=0 AND NewMaxPerMatch=0)) THEN 'Row ' + CAST(RowID AS NVARCHAR(50))+ ': The Min Bet must be different from 0.'
						  WHEN (SportType<>161 AND NewMaxBet=0)
							OR (NewMaxBet=0 AND NOT (NewMinBet=0 AND NewMaxPerBall=0 AND NewMaxPerMatch=0)) THEN 'Row ' + CAST(RowID AS NVARCHAR(50))+ ': The Max Bet must be different from 0.'
						  WHEN ((SportType IN (1, 2, 3, 5, 8, 10, 11, 99, 164, 168, 202, 199, 220, 222, 169, 175, 217, 218) OR 
								(SportType BETWEEN 180 AND 186) OR	
								(SportType BETWEEN 213 AND 215) OR	
								(SportType BETWEEN 190 AND 197)) AND NewMaxPerMatch=0)
							OR
								(SportType=161 AND NewMaxPerMatch=0 AND NOT (NewMaxBet=0 AND NewMinBet=0 AND NewMaxPerBall=0))	THEN 'Row ' + CAST(RowID AS NVARCHAR(50))+ ': The Max Per Match must be different from 0.'
						
						  WHEN NewMinBet > NewMaxBet												THEN 'Row ' + CAST(RowID AS NVARCHAR(50))+ ': The New Max Bet must be greater than or equal to the New Min Bet.'
						  WHEN (SportType IN (1, 2, 3, 5, 8, 10, 11, 99, 161, 164, 168, 202, 199, 220, 222, 169, 175, 217, 218) 
							OR (SportType BETWEEN 180 AND 186)		
							OR (SportType BETWEEN 213 AND 215)		
							OR (SportType BETWEEN 190 AND 197))	
							AND (NewMaxBet > NewMaxPerMatch)										THEN 'Row ' + CAST(RowID AS NVARCHAR(50))+ ': The New Max Bet must be less than or equal to the New Max Per Match.'	
						  WHEN SportType=161 AND (NewMaxBet > NewMaxPerBall) AND NewMaxPerBall<>0	THEN 'Row ' + CAST(RowID AS NVARCHAR(50))+ ': The New Max Bet must be less than or equal to the New Max Per Ball.'	
						  WHEN SportType=161 AND (NewMaxPerBall > NewMaxPerMatch)					THEN 'Row ' + CAST(RowID AS NVARCHAR(50))+ ': The New Max Per Ball must be less than or equal to the New Max Per Match.'

						  WHEN CurMinBet > CurMaxBet												THEN 'Row ' + CAST(RowID AS NVARCHAR(50))+ ': The Current Min Bet must be less than or equal to the Current Max Bet.'
						  WHEN (SportType IN (1, 2, 3, 5, 8, 10, 11, 99, 161, 164, 168, 202, 199, 220, 222, 169, 175, 217, 218) 
							OR (SportType BETWEEN 180 AND 186)		
							OR (SportType BETWEEN 213 AND 215)		
							OR (SportType BETWEEN 190 AND 197))	
							AND (CurMaxBet > CurMaxPerMatch)										THEN 'Row ' + CAST(RowID AS NVARCHAR(50))+ ': The Current Max Bet must be less than or equal to the Current Per Match.'	
						  WHEN SportType=161 AND (CurMaxBet > CurMaxPerBall) AND CurMaxPerBall<>0	THEN 'Row ' + CAST(RowID AS NVARCHAR(50))+ ': The Current Max Bet must be less than or equal to the Current Per Ball.'	
						  WHEN SportType=161 AND (CurMaxPerBall > CurMaxPerMatch)					THEN 'Row ' + CAST(RowID AS NVARCHAR(50))+ ': The Current Max Per Ball must be less than or equal to the Current Max Per Match.'

						  WHEN ISNULL(CreditCurrency, '')='' AND 
							   ISNULL(DepositCurrency, '')=''	THEN 'The Currency is required field.' 
						  ELSE '' 
						END 						  
	FROM @NewGlobalTbl tmp
		LEFT JOIN #Bettype b ON b.typeid=tmp.BetType
	WHERE ISNULL(SportType, '')='' OR ISNULL(BetType, '')='' OR NewMinBet IS NULL OR NewMaxBet IS NULL
		OR NewMinBet > NewMaxBet OR CurMinBet > CurMaxBet
		OR
			((SportType IN (1, 2, 3, 5, 8, 10, 11, 99, 161, 164, 168, 202, 199, 220, 222, 169, 175, 217, 218) OR 
			 (SportType BETWEEN 180 AND 186)	OR	
			 (SportType BETWEEN 213 AND 215)	OR	
			 (SportType BETWEEN 190 AND 197))
			AND 
			 (NewMaxPerMatch IS NULL OR NewMaxBet > NewMaxPerMatch OR CurMaxBet > CurMaxPerMatch))
		OR
			(SportType=161 
			AND
			(NewMaxPerBall IS NULL
				OR ((NewMaxBet > NewMaxPerBall) AND NewMaxPerBall<>0) 
				OR (NewMaxPerBall > NewMaxPerMatch) 
				OR ((CurMaxBet > CurMaxPerBall) AND CurMaxPerBall<>0)
				OR (CurMaxPerBall > CurMaxPerMatch)
				OR (NewMinBet=0 AND NOT (NewMaxBet=0 AND NewMaxPerBall=0 AND NewMaxPerMatch=0)) 
				OR (NewMaxBet=0 AND NOT (NewMinBet=0 AND NewMaxPerBall=0 AND NewMaxPerMatch=0)) 
				OR (NewMaxPerMatch=0 AND NOT (NewMaxBet=0 AND NewMinBet=0 AND NewMaxPerBall=0))))	
		OR
			(SportType<>161 
			AND
			(NewMinBet=0 OR NewMaxBet=0 
				OR ((SportType IN (1, 2, 3, 5, 8, 10, 11, 99, 164, 168, 202, 199, 220, 222, 169, 175, 217, 218) OR 
					(SportType BETWEEN 180 AND 186)	OR	
					(SportType BETWEEN 213 AND 215)	OR	
					(SportType BETWEEN 190 AND 197))	
					AND NewMaxPerMatch=0)))	
		OR (NOT ((SportType IN (1, 2, 3, 5, 8, 10, 11, 99, 161, 164, 168, 202, 199, 220, 222, 169, 175, 217, 218) OR 
				(SportType BETWEEN 180 AND 186)	OR	
				(SportType BETWEEN 213 AND 215)	OR	
				(SportType BETWEEN 190 AND 197)))
			AND (NewMaxPerMatch IS NOT NULL OR CurMaxPerMatch IS NOT NULL))
		OR (SportType<>161 AND (NewMaxPerBall IS NOT NULL OR CurMaxPerBall IS NOT NULL))
		OR (typedesc='BuyBonus' AND NewMaxGameStake IS NULL)
		OR (ISNULL(typedesc,'')<>'BuyBonus' AND (NewMaxGameStake IS NOT NULL OR CurMaxGameStake IS NOT NULL))

	IF @ErrCode<>0 RETURN
	
	INSERT INTO #NewInputDateTbl(RowID, SportType, BetType, Currency, 
								NewMinBet, NewMaxBet, NewMaxPerMatch, NewMaxPerBall, NewMaxGameStake, 
								CurMinBet, CurMaxBet, CurMaxPerMatch, CurMaxPerBall, CurMaxGameStake, 
								GameGroupID, IsCredit, SiteID)
	SELECT	RowID, SportType, BetType, t.Currency, 
			NewMinBet, NewMaxBet, NewMaxPerMatch, NewMaxPerBall, NewMaxGameStake, 
			CurMinBet, CurMaxBet, CurMaxPerMatch, CurMaxPerBall, CurMaxGameStake, 
			GameGroupID, 1 AS IsCredit, SiteID
	FROM @NewGlobalTbl nsl
		CROSS APPLY (
				SELECT DISTINCT RTRIM(LTRIM(value)) AS Currency FROM STRING_SPLIT(nsl.CreditCurrency, ',')
			) t
	WHERE nsl.CreditCurrency<>''
	UNION ALL
	SELECT	RowID, SportType, BetType, t.Currency, 
			NewMinBet, NewMaxBet, NewMaxPerMatch, NewMaxPerBall, NewMaxGameStake, 
			CurMinBet, CurMaxBet, CurMaxPerMatch, CurMaxPerBall, CurMaxGameStake, 
			GameGroupID, 0 AS IsCredit, SiteID
	FROM @NewGlobalTbl nsl
		CROSS APPLY (
				SELECT DISTINCT RTRIM(LTRIM(value)) AS Currency FROM STRING_SPLIT(nsl.DepositCurrency, ',')
			) t		
	WHERE nsl.DepositCurrency<>''
	
	--Update: ExchangeId
	UPDATE a 
	SET a.ExchangeId=CASE WHEN a.IsCredit=1 AND e.OfferSite IN (0, 1) THEN e.ExchangeId
							WHEN a.IsCredit=0 AND e.OfferSite IN (0, 2) THEN e.ExchangeId
						ELSE NULL END	
	FROM #NewInputDateTbl a
		INNER JOIN Exchange e WITH(NOLOCK) ON a.Currency=e.currency
	
	--UPDATE: SettingType, BetType, ProductID
	UPDATE a	--CREDIT
	SET a.SettingType= psd.SettingType, a.OrgBetType=psd.BetType, a.ProductID=psd.RealProductId	
	FROM #NewInputDateTbl a
		INNER JOIN ProductSettingDetail psd WITH(NOLOCK) ON a.SportType=psd.SportType
														AND (psd.SettingType=8 OR (psd.SettingType IN (2, 8, 9, 16, 20, 7, 17) AND a.BetType=psd.BetType))
	WHERE a.IsCredit=1 AND psd.SettingType IN (2, 7, 8, 9, 16, 17, 20) AND psd.ProductID NOT IN (1,3,8)
		AND psd.SettingStatus<>2

	UPDATE a	--DEPOSIT
	SET a.SettingType= ps.SettingType, a.OrgBetType=psd.BetType, a.ProductID =ps.ProductID
	FROM #NewInputDateTbl a
		INNER JOIN Dep_ProductSettingDetail psd WITH(NOLOCK) ON a.SportType=psd.SportType
		INNER JOIN Dep_ProductSetting ps WITH(NOLOCK) ON ps.ProductSettingID=psd.ProductSettingID
	WHERE a.IsCredit=0 AND (ps.SettingType = 8 OR (ps.SettingType IN (7, 2, 10, 11, 12) AND a.BetType=psd.BetType))
		AND psd.SettingStatus<>2

	SELECT TOP (1) @ProductID=ProductID, @SportType=SportType, @BetType=OrgBetType FROM #NewInputDateTbl tmp ORDER BY RowID
	IF EXISTS (SELECT TOP 1 1 FROM #NewInputDateTbl WHERE SportType<>@SportType OR (@BetType<>OrgBetType AND SettingType IN (7, 17, 8)))	
	BEGIN
		SELECT @ErrCode=121	
		SELECT TOP(1) @ErrMsg='Row ' + CAST(RowID AS VARCHAR(10)) + ' : You can only upload setting for one product at a time.' 
		FROM #NewInputDateTbl WHERE SportType<>@SportType OR (@BetType<>OrgBetType AND SettingType IN (7, 17, 8))
		ORDER BY RowID 
		RETURN
	END	

	IF EXISTS (SELECT TOP 1 1 FROM #NewInputDateTbl 
				WHERE (IsCredit=1 AND SportType IN (161,164,168,202,1,2,3,5,8,10,11,99)))	
	BEGIN
		SELECT @ErrCode=126	
		SELECT @ErrMsg='Bet Limits of Sportsbook, Number Game, Happy 5 and RNG Keno are not allowed to be imported for Credit sites.' 
		RETURN
	END	

	SELECT TOP(1) @ErrCode=109, @ErrBetType=CAST(tmp.BetType AS VARCHAR(10)), @ValueError=CAST(tmp.BetType AS VARCHAR(200)), @RowError=CAST(tmp.RowID AS VARCHAR(200))
	FROM #NewInputDateTbl tmp
	WHERE NOT EXISTS(SELECT TOP 1 1 FROM #Bettype WHERE typeid= tmp.BetType) OR OrgBetType IS NULL
	IF 	@ErrCode=109			
	BEGIN
		SELECT @ErrMsg='Row ' + @RowError+ ': The Bet Type ' + @ValueError + ' does not exist.' 
		RETURN
	END	
	
	SELECT TOP(1) @ErrCode=108, @ErrBetType=CAST(tmp.BetType AS VARCHAR(10)), @ValueError=CAST(tmp.SportType AS VARCHAR(200)), @RowError=CAST(tmp.RowID AS VARCHAR(200))
	FROM #NewInputDateTbl tmp
	WHERE ISNULL(tmp.SettingType, 0)=0 OR NOT EXISTS(SELECT TOP 1 1 FROM #Sports WHERE SportType= tmp.SportType)
	IF 	@ErrCode=108			
	BEGIN
		SELECT @ErrMsg='Row ' + @RowError+ ': The Sport Type ' + @ValueError + ' does not exist.' 
		RETURN
	END	

	SELECT TOP(1) @ErrCode=110, @ErrBetType=CAST(tmp.BetType AS VARCHAR(10)), @ValueError=CAST(tmp.currency AS VARCHAR(200)), @RowError=CAST(tmp.RowID AS VARCHAR(200))
	FROM #NewInputDateTbl tmp
	WHERE ISNULL(tmp.Currency, '')<>'' AND tmp.IsCredit=1 AND NOT EXISTS(SELECT TOP 1 1 FROM Exchange WITH(NOLOCK) WHERE currency= tmp.Currency AND IsActive=1 AND OfferSite IN (0, 1))
	IF 	@ErrCode=110			
	BEGIN
		SELECT @ErrMsg='Row ' + @RowError+ ': The Credit Currency ' + @ValueError + ' does not exist.' 
		RETURN
	END	
	
	SELECT TOP(1) @ErrCode=111, @ErrBetType=CAST(tmp.BetType AS VARCHAR(10)), @ValueError=CAST(tmp.currency AS VARCHAR(200)), @RowError=CAST(tmp.RowID AS VARCHAR(200))
	FROM #NewInputDateTbl tmp
	WHERE ISNULL(tmp.Currency, '')<>'' AND tmp.IsCredit=0 AND NOT EXISTS(SELECT TOP 1 1 FROM Exchange WITH(NOLOCK) WHERE currency= tmp.Currency AND IsActive=1 AND OfferSite IN (0, 2))
	IF 	@ErrCode=111			
	BEGIN
		SELECT @ErrMsg='Row ' + @RowError+ ': The Deposit Currency ' + @ValueError + ' does not exist.' 
		RETURN
	END
	
	SELECT TOP(1) @ErrCode=124, @ErrBetType=CAST(tmp.BetType AS VARCHAR(10)), @ValueError=CAST(tmp.SiteID AS VARCHAR(200)), @RowError=CAST(tmp.RowID AS VARCHAR(200))
	FROM #NewInputDateTbl tmp
	WHERE tmp.SettingType=7 AND tmp.IsCredit=0 AND (tmp.SiteID=0 OR (tmp.SiteID<>0 
		AND NOT EXISTS(SELECT TOP 1 1 FROM Site WITH(NOLOCK) WHERE siteid= tmp.SiteID AND IsActive=1 AND isLicensee =1 AND isDeposit=1)))
	IF 	@ErrCode=124			
	BEGIN
		SELECT @ErrMsg='Row ' + @RowError+ ': The Site ' + @ValueError + ' does not exist.' 
		RETURN
	END
	
	--Game Group ID
	SELECT TOP(1) @ErrCode=116, @ErrBetType=CAST(tmp.BetType AS VARCHAR(10)), @ValueError=CAST(tmp.GameGroupID AS VARCHAR(200)), @RowError=CAST(tmp.RowID AS VARCHAR(200))
	FROM #NewInputDateTbl tmp
	WHERE tmp.SettingType IN (8) AND ISNULL(tmp.GameGroupID, 0)=0

	IF 	@ErrCode=116			
	BEGIN
		SELECT @ErrMsg='Row ' + @RowError+ ': You input missing data with the product''s format. Please input data on Game Group ID.' 
		RETURN
	END
	
	--MIN BET
	SELECT TOP(1) @ErrCode=117, @ErrBetType=CAST(tmp.BetType AS VARCHAR(10)), @ValueError=CAST(tmp.CurMinBet AS VARCHAR(200)), @RowError=CAST(tmp.RowID AS VARCHAR(200))
	FROM #NewInputDateTbl tmp
	WHERE tmp.SettingType IN (7, 17, 2, 9, 16, 20, 10, 11, 12) AND tmp.CurMinBet IS NULL
		AND (	tmp.CurMaxBet IS NOT NULL
			OR
				(tmp.CurMaxPerMatch IS NOT NULL
				AND
				(SportType IN (1, 2, 3, 5, 8, 10, 11, 99, 161, 164, 168, 202, 199, 220, 222, 169, 175, 217, 218) OR 
				(SportType BETWEEN 180 AND 186)	OR	
				(SportType BETWEEN 213 AND 215)	OR	
				(SportType BETWEEN 190 AND 197))
				)
			OR
				(tmp.CurMaxPerBall IS NOT NULL AND SportType=161)
			)
	IF 	@ErrCode=117			
	BEGIN
		SELECT @ErrMsg='Row ' + @RowError+ ': You input missing data with the product''s format. Please input data on Current Min Bet.' 
		RETURN
	END
	
	--MAX BET
	SELECT TOP(1) @ErrCode=118, @ErrBetType=CAST(tmp.BetType AS VARCHAR(10)), @ValueError=CAST(tmp.CurMaxBet AS VARCHAR(200)), @RowError=CAST(tmp.RowID AS VARCHAR(200))
	FROM #NewInputDateTbl tmp
	WHERE tmp.SettingType IN (7, 17, 2, 9, 16, 20, 10, 11, 12) AND tmp.CurMaxBet IS NULL
		AND (	tmp.CurMinBet IS NOT NULL
			OR
				(tmp.CurMaxPerMatch IS NOT NULL
				AND
				(SportType IN (1, 2, 3, 5, 8, 10, 11, 99, 161, 164, 168, 202, 199, 220, 222, 169, 175, 217, 218) OR 
				(SportType BETWEEN 180 AND 186)	OR	
				(SportType BETWEEN 213 AND 215)	OR	
				(SportType BETWEEN 190 AND 197))
				)
			OR
				(tmp.CurMaxPerBall IS NOT NULL AND SportType=161)
			)
	
	IF 	@ErrCode=118			
	BEGIN
		SELECT @ErrMsg='Row ' + @RowError+ ': You input missing data with the product''s format. Please input data on Current Max Bet.' 
		RETURN
	END

	--MAX PER MATCH
	SELECT TOP(1) @ErrCode=119, @ErrBetType=CAST(tmp.BetType AS VARCHAR(10)), @ValueError=CAST(tmp.CurMaxPerMatch AS VARCHAR(200)), @RowError=CAST(tmp.RowID AS VARCHAR(200))
	FROM #NewInputDateTbl tmp
	WHERE tmp.SettingType IN (2, 9, 16, 20, 10, 11, 12) AND tmp.CurMaxPerMatch IS NULL
		AND
			(SportType IN (1, 2, 3, 5, 8, 10, 11, 99, 161, 164, 168, 202, 199, 220, 222, 169, 175, 217, 218) OR 
			(SportType BETWEEN 180 AND 186)	OR	
			(SportType BETWEEN 213 AND 215)	OR	
			(SportType BETWEEN 190 AND 197))
		AND (tmp.CurMinBet IS NOT NULL OR tmp.CurMaxBet IS NOT NULL)

	IF 	@ErrCode=119			
	BEGIN
		SELECT @ErrMsg='Row ' + @RowError+ ': You input missing data with the product''s format. Please input data on Current Max Per Match.' 
		RETURN
	END

	--MAX PER BALL
	SELECT TOP(1) @ErrCode=120, @ErrBetType=CAST(tmp.BetType AS VARCHAR(10)), @ValueError=CAST(tmp.CurMaxPerBall AS VARCHAR(200)), @RowError=CAST(tmp.RowID AS VARCHAR(200))
	FROM #NewInputDateTbl tmp
	WHERE SportType=161 AND tmp.CurMaxPerBall IS NULL
		AND (tmp.CurMinBet IS NOT NULL OR tmp.CurMaxBet IS NOT NULL OR tmp.CurMaxPerMatch IS NOT NULL)

	IF 	@ErrCode=120			
	BEGIN
		SELECT @ErrMsg='Row ' + @RowError+ ': You input missing data with the product''s format. Please input data on Current Max Per Ball.' 
		RETURN
	END

	--MaxGameStake
	SELECT TOP(1) @ErrCode=127, @ErrBetType=CAST(tmp.BetType AS VARCHAR(10)), @ValueError=CAST(tmp.CurMaxGameStake AS VARCHAR(200)), @RowError=CAST(tmp.RowID AS VARCHAR(200))
	FROM #NewInputDateTbl tmp
		INNER JOIN #Bettype b ON b.typeid=tmp.BetType
	WHERE tmp.SettingType=8 AND b.typedesc='BuyBonus' AND tmp.CurMaxGameStake IS NULL
		AND (tmp.CurMinBet IS NOT NULL OR tmp.CurMaxBet IS NOT NULL)

	IF 	@ErrCode=127			
	BEGIN
		SELECT @ErrMsg='Row ' + @RowError+ ': You input missing data with the product''s format. Please input data on Current Max Game Stake.' 
		RETURN
	END

	-------
	SELECT TOP(1) @ErrCode=112, @ErrBetType=CAST(BetType AS VARCHAR(10))
	, @ValueError=CASE	WHEN SettingType=8 AND b.typedesc='BuyBonus' 
							THEN CAST(tmp.CurMinBet AS VARCHAR(50)) + ' and Current Max Bet: ' + CAST(tmp.CurMaxBet AS VARCHAR(50)) + ' and Current Max Game Stake: ' + CAST(tmp.CurMaxGameStake AS VARCHAR(50))
						WHEN NOT (SportType IN (1, 2, 3, 5, 8, 10, 11, 99, 161, 164, 168, 202, 199, 220, 222, 169, 175, 217, 218) OR 
								(SportType BETWEEN 180 AND 186)	OR	
								(SportType BETWEEN 213 AND 215)	OR	
								(SportType BETWEEN 190 AND 197))
							THEN CAST(tmp.CurMinBet AS VARCHAR(50)) + ' and Current Max Bet: ' + CAST(tmp.CurMaxBet AS VARCHAR(50))
						WHEN SportType=161 
							THEN CAST(tmp.CurMinBet AS VARCHAR(50)) + ' and Current Max Bet: ' + CAST(tmp.CurMaxBet AS VARCHAR(50)) + ' and Current Max Per Ball: ' + CAST(tmp.CurMaxPerBall AS VARCHAR(50)) + ' and Current Max Per Match: ' + CAST(tmp.CurMaxPerMatch AS VARCHAR(50))
						ELSE CAST(tmp.CurMinBet AS VARCHAR(50)) + ' and Current Max Bet: ' + CAST(tmp.CurMaxBet AS VARCHAR(50)) + ' and Current Max Per Match: ' + CAST(tmp.CurMaxPerMatch AS VARCHAR(50))
					END
	, @RowError=CAST(tmp.RowID AS VARCHAR(200))
	FROM #NewInputDateTbl tmp
		LEFT JOIN #Bettype b ON b.typeid=tmp.BetType
	WHERE CurMinBet IS NOT NULL AND 
	(   (IsCredit=1 AND tmp.SettingType IN (7, 17) 
					AND (NOT EXISTS	(SELECT TOP 1 1 FROM StakeLevel WITH(NOLOCK) 
									 WHERE BetType=GameTypeID AND ExchangeId=tmp.ExchangeId AND MinStake=CurMinBet)
						OR NOT EXISTS(SELECT TOP 1 1 FROM StakeLevel WITH(NOLOCK) 
										WHERE BetType=GameTypeID AND ExchangeId=tmp.ExchangeId AND MinStake=CurMinBet AND MaxStake=CurMaxBet)))
	OR   (IsCredit=0 AND tmp.SettingType IN (7) 
					 AND (NOT EXISTS(SELECT TOP 1 1 FROM Dep_StakeLevel WITH(NOLOCK) 
									 WHERE BetType=GameTypeID AND ExchangeId=tmp.ExchangeId AND (MinStake=CurMinBet ))
							OR NOT EXISTS(SELECT TOP 1 1 FROM Dep_StakeLevel WITH(NOLOCK) 
										 WHERE BetType=GameTypeID AND ExchangeId=tmp.ExchangeId AND MinStake=CurMinBet AND MaxStake=CurMaxBet)))
	OR  (IsCredit=1 AND tmp.SettingType IN (2, 9, 16, 20) 
					AND ((NOT EXISTS (SELECT TOP 1 1 FROM ProductBetSetting pbs WITH (NOLOCK)
									  WHERE pbs.Sporttype=tmp.SportType AND pbs.Bettype=tmp.BetType AND pbs.Currency=tmp.ExchangeId 
										AND pbs.MinBet=tmp.CurMinBet AND pbs.MaxBet=tmp.CurMaxBet AND ISNULL(pbs.MaxPerMatch,0)=ISNULL(tmp.CurMaxPerMatch,0)))))
	OR   (IsCredit=0 AND tmp.SettingType IN (2, 10, 11, 12)
					 AND ((NOT EXISTS (SELECT TOP 1 1 FROM Dep_ProductBetSetting pbs WITH (NOLOCK)
											WHERE pbs.Sporttype=tmp.SportType AND pbs.Bettype=tmp.BetType AND pbs.Currency=tmp.ExchangeId 
												AND pbs.MinBet=tmp.CurMinBet AND pbs.MaxBet=tmp.CurMaxBet 
												AND ISNULL(pbs.MaxPerMatch,0)=ISNULL(tmp.CurMaxPerMatch,0) 
												AND ISNULL(pbs.MaxPerBall,0)=ISNULL(tmp.CurMaxPerBall,0)))))
	OR	(IsCredit=1 AND tmp.SettingType=8
					AND (NOT EXISTS	(SELECT TOP 1 1 FROM StakeLevelGroupDetail slg WITH(NOLOCK) 
									 WHERE BetType=GameTypeID AND ExchangeId=tmp.ExchangeId AND b.typedesc='BuyBonus' 
										AND MinStake=CurMinBet AND MaxStake=CurMaxBet AND MaxGameStake=CurMaxGameStake)))
	OR   (IsCredit=0 AND tmp.SettingType=8 
					 AND (NOT EXISTS(SELECT TOP 1 1 FROM Dep_StakeLevelGroupDetail WITH(NOLOCK) 
									 WHERE BetType=GameTypeID AND ExchangeId=tmp.ExchangeId AND b.typedesc='BuyBonus' 
										AND MinStake=CurMinBet AND MaxStake=CurMaxBet AND MaxGameStake=CurMaxGameStake)))
	)

	IF 	@ErrCode=112			
	BEGIN
		SELECT @ErrMsg='Row ' + @RowError+ ': Bet Type ' + @ErrBetType + ' does not have any existing bet limit with Current Min Bet: ' + @ValueError + ' .' 
		RETURN
	END
	
	SELECT TOP(1) @ErrCode=114, @ErrBetType=CAST(tmp.BetType AS VARCHAR(10)), @ValueError=CAST(tmp.GameGroupID AS VARCHAR(200)), @RowError=CAST(tmp.RowID AS VARCHAR(200))
	FROM #NewInputDateTbl tmp
	WHERE tmp.SettingType IN (8) AND NOT EXISTS(SELECT TOP 1 1 FROM GameGroup WITH(NOLOCK) 
												WHERE RefSportType= tmp.SportType AND RefBetType=OrgBetType AND GameGroupID=tmp.GameGroupID
													AND ((tmp.IsCredit=1 AND IsDeposit=0) OR (tmp.IsCredit=0 AND IsDeposit=1)))
	IF 	@ErrCode=114
	BEGIN
		SELECT @ErrMsg='Row ' + @RowError+ ': The Game Group ID ' + @ValueError + ' of bet type ' + @ErrBetType + ' does not exist.' 
		RETURN
	END
	
	SELECT TOP(1) @ErrCode=115, @ErrBetType=CAST(tmp.BetType AS VARCHAR(10))
				, @ValueError=CASE	WHEN SettingType=8 AND b.typedesc='BuyBonus'
										THEN ': The New Min Bet, New Max Bet, New Max Game Stake are the same as The Current Min Bet, the Current Max Bet, and the Current Max Game Stake. Please input another value for the New values again.'
									WHEN NOT (SportType IN (1, 2, 3, 5, 8, 10, 11, 99, 161, 164, 168, 202, 199, 220, 222, 169, 175, 217, 218) OR 
											(SportType BETWEEN 180 AND 186)	OR	
											(SportType BETWEEN 213 AND 215)	OR	
											(SportType BETWEEN 190 AND 197))
										THEN ': The New Min Bet, New Max Bet are the same as The Current Min Bet, and the Current Max Bet. Please input another value for the New values again.'
									WHEN SportType=161 
										THEN ': The New Min Bet, New Max Bet, New Max Per Match, New Max Per Ball are the same as The Current Min Bet, the Current Max Bet, the Current Max Per Match, and the Current Max Per Ball. Please input another value for the New values again.'
									ELSE ': The New Min Bet, New Max Bet, New Max Per Match are the same as The Current Min Bet, the Current Max Bet, and the Current Max Per Match. Please input another value for the New values again.'
								END
				, @RowError=CAST(tmp.RowID AS VARCHAR(200))
	FROM #NewInputDateTbl tmp
		LEFT JOIN #Bettype b ON b.typeid=tmp.BetType
	WHERE (tmp.CurMinBet=NewMinBet AND CurMaxBet=NewMaxBet
			AND NOT (SportType IN (1, 2, 3, 5, 8, 10, 11, 99, 161, 164, 168, 202, 199, 220, 222, 169, 175, 217, 218) OR 
					(SportType BETWEEN 180 AND 186)	OR	
					(SportType BETWEEN 213 AND 215)	OR	
					(SportType BETWEEN 190 AND 197))
			AND NOT (SettingType=8 AND b.typedesc='BuyBonus'))
	OR (tmp.CurMinBet=NewMinBet AND CurMaxBet=NewMaxBet AND CurMaxPerMatch=NewMaxPerMatch AND
		(SportType IN (1, 2, 3, 5, 8, 10, 11, 99, 161, 164, 168, 202, 199, 220, 222, 169, 175, 217, 218) OR 
		(SportType BETWEEN 180 AND 186)	OR	
		(SportType BETWEEN 213 AND 215)	OR	
		(SportType BETWEEN 190 AND 197)))
	OR (tmp.CurMinBet=NewMinBet AND CurMaxBet=NewMaxBet AND CurMaxPerMatch=NewMaxPerMatch AND tmp.CurMaxPerBall=NewMaxPerBall AND SportType=161)
	OR (tmp.CurMinBet=NewMinBet AND CurMaxBet=NewMaxBet AND CurMaxGameStake=NewMaxGameStake AND SettingType=8 AND b.typedesc='BuyBonus')

	IF 	@ErrCode=115			
	BEGIN
		SELECT @ErrMsg='Row ' + @RowError + @ValueError		
		RETURN
	END
	
	--Currency
	INSERT INTO #Currency (Currency)
	SELECT tmp.Currency
	FROM #NewInputDateTbl tmp
	WHERE IsCredit=1 AND NOT EXISTS(SELECT TOP 1 1 FROM StakeLevel WITH(NOLOCK) WHERE GameTypeID=tmp.OrgBetType AND ExchangeId=tmp.ExchangeId)
		AND tmp.SettingType IN (7,8,17)
	UNION 
	SELECT tmp.Currency
	FROM #NewInputDateTbl tmp
	WHERE IsCredit=0 AND NOT EXISTS(SELECT TOP 1 1 FROM Dep_StakeLevel WITH(NOLOCK) WHERE tmp.OrgBetType=GameTypeID AND ExchangeId=tmp.ExchangeId)
		AND tmp.SettingType IN (7,8,17)
	UNION
	SELECT tmp.Currency
	FROM #NewInputDateTbl tmp
	WHERE IsCredit=1 AND NOT EXISTS (SELECT TOP 1 1 FROM ProductBetSetting pbs WITH(NOLOCK) WHERE tmp.Bettype=pbs.Bettype AND tmp.SportType=pbs.Sporttype AND tmp.ExchangeId=pbs.Currency)
		AND tmp.SettingType NOT IN (7,8,17)
	UNION
	SELECT tmp.Currency
	FROM #NewInputDateTbl tmp
	WHERE IsCredit=0 AND NOT EXISTS (SELECT TOP 1 1 FROM Dep_ProductBetSetting pbs WITH(NOLOCK) WHERE tmp.Bettype=pbs.Bettype AND tmp.SportType=pbs.Sporttype AND tmp.ExchangeId=pbs.Currency)
		AND tmp.SettingType NOT IN (7,8,17)

	IF 	EXISTS(	SELECT TOP 1 1 FROM #Currency )			
	BEGIN
		SET @NotiCode=100
		SELECT @NotiMsg='There are new currencies : ' + STUFF((SELECT DISTINCT ',' + CAST(Currency AS NVARCHAR(50))
		FROM #Currency
		FOR XML PATH('')), 1, 1, '')
	END
	
	--RowDuplicate
	INSERT INTO #RowDuplicate(RowIDF, RowIDT)
	SELECT DISTINCT tmp.RowID , ndt.RowID
	FROM #NewInputDateTbl tmp
	LEFT JOIN #Bettype b ON b.typeid=tmp.BetType 
	INNER JOIN #NewInputDateTbl ndt ON tmp.SportType = ndt.SportType AND tmp.BetType = ndt.BetType 
				AND tmp.ExchangeId = ndt.ExchangeId AND tmp.GameGroupID = ndt.GameGroupID AND tmp.IsCredit = ndt.IsCredit
				AND ISNULL(tmp.CurMinBet,0) = ISNULL(ndt.CurMinBet,0) AND ISNULL(tmp.CurMaxBet,0)=ISNULL(ndt.CurMaxBet,0) 
				AND tmp.NewMaxBet = ndt.NewMaxBet AND tmp.NewMinBet = ndt.NewMinBet  
				AND ((tmp.SettingType=8 AND ISNULL(b.typedesc,'') <> 'BuyBonus') OR (tmp.SettingType = 7 AND tmp.SiteID = ndt.SiteID))
	WHERE tmp.RowID < ndt.RowID 
	UNION --MinBet, MaxBet
	SELECT DISTINCT tmp.RowID, ndt.RowID
	FROM #NewInputDateTbl tmp
	INNER JOIN #NewInputDateTbl ndt ON tmp.SportType=ndt.SportType AND tmp.BetType=ndt.BetType 
				AND tmp.ExchangeId=ndt.ExchangeId AND tmp.IsCredit=ndt.IsCredit
				AND ISNULL(tmp.CurMinBet,0)=ISNULL(ndt.CurMinBet,0) AND ISNULL(tmp.CurMaxBet,0)=ISNULL(ndt.CurMaxBet,0)
				AND tmp.NewMaxBet=ndt.NewMaxBet AND tmp.NewMinBet=ndt.NewMinBet  
				AND tmp.SettingType IN (2, 9, 16, 20, 10, 11, 12)
				AND NOT (tmp.SportType IN (1, 2, 3, 5, 8, 10, 11, 99, 161, 164, 168, 202, 199, 220, 222, 169, 175, 217, 218) OR 
						(tmp.SportType BETWEEN 180 AND 186)	OR	
						(tmp.SportType BETWEEN 213 AND 215)	OR	
						(tmp.SportType BETWEEN 190 AND 197))
	WHERE tmp.RowID < ndt.RowID		
	UNION --MinBet, MaxBet, MaxGameStake
	SELECT DISTINCT tmp.RowID, ndt.RowID
	FROM #NewInputDateTbl tmp
	INNER JOIN #Bettype b ON b.typeid=tmp.BetType 
	INNER JOIN #NewInputDateTbl ndt ON tmp.SportType = ndt.SportType AND tmp.BetType = ndt.BetType 
				AND tmp.ExchangeId = ndt.ExchangeId AND tmp.GameGroupID = ndt.GameGroupID AND tmp.IsCredit = ndt.IsCredit
				AND ISNULL(tmp.CurMinBet,0) = ISNULL(ndt.CurMinBet,0) AND ISNULL(tmp.CurMaxBet,0)=ISNULL(ndt.CurMaxBet,0) AND ISNULL(tmp.CurMaxGameStake,0)=ISNULL(ndt.CurMaxGameStake,0)
				AND tmp.NewMaxBet = ndt.NewMaxBet AND tmp.NewMinBet = ndt.NewMinBet AND tmp.NewMaxGameStake=ndt.NewMaxGameStake
				AND (tmp.SettingType=8 AND b.typedesc='BuyBonus')
	WHERE tmp.RowID < ndt.RowID 		
	UNION --MinBet, MaxBet, MaxPerMatch
	SELECT DISTINCT tmp.RowID, ndt.RowID
	FROM #NewInputDateTbl tmp
	INNER JOIN #NewInputDateTbl ndt ON tmp.SportType=ndt.SportType AND tmp.BetType=ndt.BetType 
				AND tmp.ExchangeId=ndt.ExchangeId AND tmp.IsCredit=ndt.IsCredit
				AND ISNULL(tmp.CurMinBet,0)=ISNULL(ndt.CurMinBet,0) AND ISNULL(tmp.CurMaxBet,0)=ISNULL(ndt.CurMaxBet,0) AND ISNULL(tmp.CurMaxPerMatch,0)=ISNULL(ndt.CurMaxPerMatch,0)
				AND tmp.NewMaxBet=ndt.NewMaxBet AND tmp.NewMinBet=ndt.NewMinBet AND tmp.NewMaxPerMatch=ndt.NewMaxPerMatch
				AND tmp.SettingType IN (2, 9, 16, 20, 10, 11, 12)
				AND (tmp.SportType IN (1, 2, 3, 5, 8, 10, 11, 99, 164, 168, 202, 199, 220, 222, 169, 175, 217, 218) OR 
					(tmp.SportType BETWEEN 180 AND 186)	OR	
					(tmp.SportType BETWEEN 213 AND 215)	OR	
					(tmp.SportType BETWEEN 190 AND 197))
	WHERE tmp.RowID < ndt.RowID										
	UNION --MinBet, MaxBet, MaxPerMatch, MaxPerBall
	SELECT DISTINCT tmp.RowID, ndt.RowID
	FROM #NewInputDateTbl tmp
	INNER JOIN #NewInputDateTbl ndt ON tmp.SportType=ndt.SportType AND tmp.BetType=ndt.BetType 
				AND tmp.ExchangeId=ndt.ExchangeId AND tmp.IsCredit=ndt.IsCredit
				AND ISNULL(tmp.CurMinBet,0)=ISNULL(ndt.CurMinBet,0) AND ISNULL(tmp.CurMaxBet,0)=ISNULL(ndt.CurMaxBet,0) AND ISNULL(tmp.CurMaxPerMatch,0)=ISNULL(ndt.CurMaxPerMatch,0) AND ISNULL(tmp.CurMaxPerBall,0)=ISNULL(ndt.CurMaxPerBall,0)
				AND tmp.NewMaxBet=ndt.NewMaxBet AND tmp.NewMinBet=ndt.NewMinBet AND tmp.NewMaxPerMatch=ndt.NewMaxPerMatch AND tmp.NewMaxPerBall=ndt.NewMaxPerBall
	WHERE tmp.RowID < ndt.RowID AND tmp.SportType=161
	
	IF 	EXISTS(	SELECT TOP 1 1 FROM #RowDuplicate )			
	BEGIN
		SET @ErrCode=125
		SELECT @ErrMsg=STUFF((SELECT ', row ' + CAST(RowIDF AS NVARCHAR(50)) + ' - row ' + CAST(RowIDT AS NVARCHAR(50)) 
								FROM #RowDuplicate tmp
								ORDER BY RowIDF
								FOR XML PATH('')), 1, 1, '') + ' : These rows have duplicate data' 
		RETURN
	END	
	
	--EXISTED
	SELECT TOP(1) @ErrCode=123, @ValueError=CAST(KQ.RowID AS VARCHAR(200))
	FROM 
	(	SELECT RowID 
		FROM #NewInputDateTbl a
		WHERE a.IsCredit= 1 AND SettingType IN (2, 7, 9, 16, 17, 20) 
		AND (EXISTS (SELECT TOP 1 1 FROM StakeLevel tmp WITH(NOLOCK) 
					 WHERE tmp.GameTypeID=a.BetType AND a.ExchangeId=tmp.ExchangeId 
						 AND (a.NewMinBet=MinStake AND a.NewMaxBet=MaxStake))
			OR EXISTS (SELECT TOP 1 1 FROM ProductBetSetting pbs WITH(NOLOCK)
						WHERE pbs.Sporttype=a.SportType AND pbs.Bettype=a.BetType AND pbs.Currency=a.ExchangeId
							AND ((MinBet=NewMinBet AND MaxBet=NewMaxBet
									AND NOT (SportType IN (199, 220, 222, 169, 175, 217, 218) OR 
											(SportType BETWEEN 180 AND 186)	OR	
											(SportType BETWEEN 213 AND 215)	OR	
											(SportType BETWEEN 190 AND 197)))
								OR (MinBet=NewMinBet AND MaxBet=NewMaxBet AND MaxPerMatch=NewMaxPerMatch AND
									(SportType IN (199, 220, 222, 169, 175, 217, 218) OR 
									(SportType BETWEEN 180 AND 186)	OR	
									(SportType BETWEEN 213 AND 215)	OR	
									(SportType BETWEEN 190 AND 197)))
							))
			)
		UNION ALL
		SELECT RowID 
		FROM #NewInputDateTbl a
		WHERE a.IsCredit= 0 AND SettingType IN (7, 2, 10, 11, 12) 
				 AND ( EXISTS (SELECT TOP 1 1 FROM Dep_StakeLevel tmp WITH(NOLOCK) 
								 WHERE tmp.GameTypeID=a.BetType AND a.ExchangeId=tmp.ExchangeId 
								 AND a.NewMinBet=MinStake AND a.NewMaxBet=MaxStake AND tmp.SiteID=a.SiteID)
						OR EXISTS (SELECT TOP 1 1 FROM Dep_ProductBetSetting pbs WITH(NOLOCK)
									WHERE pbs.Sporttype=a.SportType AND pbs.Bettype=a.BetType AND pbs.Currency=a.ExchangeId
										AND ((MinBet=NewMinBet AND MaxBet=NewMaxBet
												AND NOT (SportType IN (1, 2, 3, 5, 8, 10, 11, 99, 161, 164, 168, 202, 199, 220, 222, 169, 175, 217, 218) OR 
														(SportType BETWEEN 180 AND 186)	OR	
														(SportType BETWEEN 213 AND 215)	OR	
														(SportType BETWEEN 190 AND 197)))
											OR (MinBet=NewMinBet AND MaxBet=NewMaxBet AND MaxPerMatch=NewMaxPerMatch AND
												(SportType IN (1, 2, 3, 5, 8, 10, 11, 99, 164, 168, 202, 199, 220, 222, 169, 175, 217, 218) OR 
												(SportType BETWEEN 180 AND 186)	OR	
												(SportType BETWEEN 213 AND 215)	OR	
												(SportType BETWEEN 190 AND 197)))
											OR (MinBet=NewMinBet AND MaxBet=NewMaxBet AND MaxPerMatch=NewMaxPerMatch AND MaxPerBall=NewMaxPerBall AND Sporttype=161)
									))
					)
	) KQ
	
	IF 	@ErrCode=123			
	BEGIN
		SELECT @ErrMsg='Row ' + @ValueError + ': This Bet Limit is already existed.' 
		RETURN
	END	
	
	DROP TABLE #Bettype
	DROP TABLE #Sports
	DROP TABLE #NewInputDateTbl
	DROP TABLE #Currency
	DROP TABLE #RowDuplicate
END			
GO