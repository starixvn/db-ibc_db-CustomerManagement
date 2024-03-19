/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet,wsv_nap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_ReferenceSetting_Sel] 
	-- Add the parameters for the stored procedure here
	 @pMutilProductID	VARCHAR(MAX)=''
	,@pMutilSportType	VARCHAR(MAX)=''
	,@pMutilBetType		VARCHAR(MAX)=''
	,@IsLicensee		TINYINT=0
	,@IsLive			BIT=0
	,@ExportData		INT	=	0
	,@PageSize			INT	=	50
	,@PageIndex			INT	=	0
	,@TotalRows 		INT	=	0 OUTPUT
AS
/*
	Task : NAP - New function to manage SportBettypeSettingMatrix table
	DB: DBACC/bodb02
	Original: 
	Revisions:
		- 20230301@Tacy: Create SP [Redmine: #184255] 
		- 20230803@Tacy: NAP - Manage SportBettypeSettingMatrix - Add more fields [Redmine: #192732]
		
	Param's Explanation:
		@IsLicensee				0 : Credit, 1 : Deposit
		@ExportData				0 : Pages, <> 0 : All data
*/
BEGIN
	SET NOCOUNT ON

	IF @pMutilProductID='' OR @pMutilSportType='' OR @pMutilBetType=''
		RETURN

	DECLARE @rowstart	INT,
			@rowend		INT

	SELECT	@RowStart = @PageSize * @PageIndex + 1, 
			@RowEnd = @RowStart + @PageSize - 1 	
	
	CREATE TABLE #ReferenceSettingTbl(
			RealProductID			TINYINT,
			RealProductName			VARCHAR(50),
			DummyProductID			TINYINT,
			DummyProductName		VARCHAR(50),
			SportType				SMALLINT,
			SportName				NVARCHAR(50),
			BetType					INT,
			BettypeName				NVARCHAR(128),

			isLicensee				BIT,
			isLive					BIT,
			Site					VARCHAR(50),
			isActive				BIT,

			SportTypeRefPT			SMALLINT,
			BetTypeRefPT			INT,
			isLivePT				BIT DEFAULT (0),
			TablePT					VARCHAR(50),
			
			SportTypeRefComm		SMALLINT,
			BetTypeRefComm			INT,
			TableComm				VARCHAR(50),
			
			SportTypeRefBetSetting	SMALLINT,
			BetTypeRefBetSetting	INT,
			TableBetSetting			VARCHAR(50),
			
			SporttypeRefWinlossLimit SMALLINT,
			BettypeRefWinlossLimit	 SMALLINT,
			
			TableBettrans			VARCHAR(100)
			
		)

	CREATE TABLE #Bettype (
			Bettype		INT PRIMARY KEY CLUSTERED, 
			Bettypename	NVARCHAR(128)
	)

	CREATE TABLE #Sports(
			SportType SMALLINT PRIMARY KEY CLUSTERED, 
			SportName NVARCHAR(50)
	)

	CREATE TABLE #Products(
			ProductID	SMALLINT PRIMARY KEY CLUSTERED, 
			ProductName NVARCHAR(50)
	)

	INSERT INTO #Products (ProductID, ProductName)
	SELECT ProductID, ProductName
	FROM Products WITH (NOLOCK)
	WHERE Enabled=1

	INSERT INTO #Sports (SportType, SportName)	
	EXEC Acc_SporttypeSel @Mode=1
	
	DELETE FROM #Sports
	WHERE SportType NOT IN (SELECT TRIM(value) val FROM STRING_SPLIT(@pMutilSportType, ','))

	INSERT INTO #Bettype (Bettype, Bettypename)	
	SELECT typeid,typenamee 
	FROM dbo.Bettype WITH(NOLOCK)
	WHERE typeid IN (SELECT TRIM(value) val FROM STRING_SPLIT(@pMutilBetType, ','))

	INSERT INTO #ReferenceSettingTbl 
		(RealProductID, RealProductName, 
		 DummyProductID, DummyProductName,
		 SportType, SportName, BetType, BettypeName,
		 isLicensee, isLive, Site, isActive,
		 SportTypeRefPT, BetTypeRefPT, TablePT, isLivePT,
		 SportTypeRefComm, BetTypeRefComm, TableComm,
		 SportTypeRefBetSetting, BetTypeRefBetSetting, TableBetSetting,
		 SporttypeRefWinlossLimit, BettypeRefWinlossLimit, TableBettrans)
	SELECT DISTINCT
			sm.RealProductID, p.ProductName,	--real
			sm.ProductID, dp.ProductName,		--dummy
			s.SportType, s.SportName,
			b.Bettype, b.Bettypename,
			sm.isLicensee, sm.isLive,
			sm.Site, sm.isActive,
			sm.SportTypeRefPT, sm.BetTypeRefPT, sm.TablePT, sm.isLivePT,
			sm.SportTypeRefComm, sm.BetTypeRefComm, sm.TableComm,
			sm.SportTypeRefBetSetting, sm.BetTypeRefBetSetting, sm.TableBetSetting,
			sm.SporttypeRefWinlossLimit, sm.BettypeRefWinlossLimit,
			sm.TableBettrans
	FROM SportBettypeSettingMatrix sm WITH (NOLOCK)
	INNER JOIN #Products p ON p.ProductID=sm.RealProductId
	INNER JOIN #Sports s ON s.SportType=sm.SportType
	INNER JOIN #Bettype b ON b.Bettype=sm.BetType
	LEFT JOIN #Products dp ON dp.ProductID=sm.ProductID	--dummy
	WHERE @IsLicensee=sm.isLicensee AND @IsLive=sm.isLive
		AND isDeleted=0
		AND sm.RealProductId IN (SELECT TRIM(value) val FROM STRING_SPLIT(@pMutilProductID, ','))

	--ExportData
	IF @ExportData = 1
	BEGIN
		SELECT 
			RealProductID, RealProductName,
			DummyProductID, DummyProductName,
			SportType, SportName,
			Bettype, Bettypename,
			isLicensee, isLive,
			Site, isActive,
			SportTypeRefPT, BetTypeRefPT, TablePT, isLivePT,
			SportTypeRefComm, BetTypeRefComm, TableComm,
			SportTypeRefBetSetting, BetTypeRefBetSetting, TableBetSetting,
			SporttypeRefWinlossLimit, BettypeRefWinlossLimit,
			TableBettrans
		FROM #ReferenceSettingTbl	
	END
	ELSE
	BEGIN
		SELECT @TotalRows = COUNT(1)
		FROM #ReferenceSettingTbl

		SELECT 
			RealProductID, RealProductName,
			DummyProductID, DummyProductName,
			SportType, SportName,
			Bettype, Bettypename,
			isLicensee, isLive,
			Site, isActive,
			SportTypeRefPT, BetTypeRefPT, TablePT, isLivePT,
			SportTypeRefComm, BetTypeRefComm, TableComm,
			SportTypeRefBetSetting, BetTypeRefBetSetting, TableBetSetting,
			SporttypeRefWinlossLimit, BettypeRefWinlossLimit,
			TableBettrans
		FROM (
				SELECT ROW_NUMBER() OVER(ORDER BY RealProductID, SportType, Bettype) rn, *
				FROM #ReferenceSettingTbl
		   )t
		WHERE rn BETWEEN @RowStart AND @RowEnd
	END	

	DROP TABLE #Bettype
	DROP TABLE #Sports
	DROP TABLE #Products
END
GO
