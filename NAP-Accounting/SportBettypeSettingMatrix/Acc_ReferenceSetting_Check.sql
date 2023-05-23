/*<info serverAlias="DBACC-bodb02" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE dbo.Acc_ReferenceSetting_Check
	-- Add the parameters for the stored procedure here
	 @InputData		VARCHAR(MAX)	= ''
	,@IsNew			BIT				= 1
	,@IsSingleCheck	BIT				= 0
	,@UserID		INT
	,@IP			VARCHAR(50)		= ''
	,@ErrCode		INT				= 0	 OUTPUT
	,@ErrMsg		NVARCHAR(4000)	= '' OUTPUT
AS
/*
	Task : NAP - New function to manage SportBettypeSettingMatrix table
	DB: DBTP/bodb02
	Original: 

	Revisions:
		- 20230301@Tacy: Create SP [Redmine: #184255]
		- 20230522@Tacy: Enhance function - Do not validate Bettype value [Redmine: #184255] 
		
	Param's Explanation:
		* @IsNew : 1 ~ Insert new reference setting
				   0 ~ Update reference setting

		* @IsSingleCheck : 1 ~ Update reference setting by Popup
						   0 ~ Update reference setting by file

		* @InputData : 
			<ROOT>
				<Setting 
						SportType="1"
						BetType="1"
						IsLicensee="0"
						IsLive="1"
						Site="ALL"
						SportTypeRefPT="1"
						BetTypeRefPT="1"
						IsLivePT="1"
						TablePT="CustSetting"
						SportTypeRefComm="1"
						BetTypeRefComm="1"
						TableComm="CustSetting"
						SportTypeRefBetSetting="1"
						BetTypeRefBetSetting="1"
						TableBetSetting="CustSetting"
						TableBettrans="bettrans"
						SporttypeRefWinlossLimit="NULL"
						BettypeRefWinlossLimit="NULL"
						RealProductId="1"
				/>
			</ROOT>
*/
BEGIN
	SET NOCOUNT ON;
	
	IF @InputData=''	RETURN

	DECLARE @MatrixError	NVARCHAR(MAX) = ''
		, @ValueError		NVARCHAR(MAX) = ''
		, @ColumnName		NVARCHAR(200)
		, @LimitValue		BIGINT

	CREATE TABLE #NewReferenceSettingTbl  (
			RowID					INT IDENTITY (1,1),
			SportType				VARCHAR(10),
			BetType					VARCHAR(10),
			IsLicensee				VARCHAR(10),
			IsLive					VARCHAR(1),
			Site					VARCHAR(50),
			
			SportTypeRefPT			VARCHAR(10),
			BetTypeRefPT			VARCHAR(10),
			IsLivePT				VARCHAR(1),
			TablePT					VARCHAR(50),
			
			SportTypeRefComm		VARCHAR(10),
			BetTypeRefComm			VARCHAR(10),
			TableComm				VARCHAR(50),
			
			SportTypeRefBetSetting	VARCHAR(10),
			BetTypeRefBetSetting	VARCHAR(10),
			TableBetSetting			VARCHAR(50),
			
			SporttypeRefWinlossLimit VARCHAR(10),
			BettypeRefWinlossLimit	 VARCHAR(10),
			
			TableBettrans			VARCHAR(100),
			RealProductId			VARCHAR(10)
		)
	
	CREATE TABLE #Bettype (typeid INT , typenamee NVARCHAR(128))
	CREATE TABLE #Sports (SportType INT, SportName VARCHAR(50))
	CREATE TABLE #RefTable (TableType VARCHAR(20), TableName VARCHAR(50), OfferSite TINYINT)
	CREATE TABLE #RowDuplicate(RowID INT)
	
	INSERT INTO #Bettype  (typeid,typenamee)	
	SELECT typeid,typenamee 
	FROM DBACC.bodb02.dbo.Bettype WITH(NOLOCK)
	
	INSERT INTO #Sports  (SportType, SportName)	
	EXEC Acc_SporttypeSel @Mode=1

	INSERT INTO #RefTable (TableType, TableName, OfferSite)
	EXEC Acc_ReferenceSetting_TableSel

	IF @InputData IS NULL OR @InputData = ''
		RETURN
		
	SELECT	@ErrCode = 0, @ErrMsg = '' 
	
	--Parse XML data
	DECLARE @iDoc INT
	BEGIN TRY
		EXEC sp_xml_preparedocument @iDoc OUTPUT
			, @InputData

		INSERT INTO #NewReferenceSettingTbl(SportType, BetType, IsLicensee, IsLive, Site,
											SportTypeRefPT, BetTypeRefPT, IsLivePT, TablePT,
											SportTypeRefComm, BetTypeRefComm, TableComm,
											SportTypeRefBetSetting, BetTypeRefBetSetting, TableBetSetting,
											SporttypeRefWinlossLimit, BettypeRefWinlossLimit,
											RealProductId, TableBettrans)
		SELECT	SportType, BetType, IsLicensee, IsLive, Site,
				SportTypeRefPT, BetTypeRefPT, IsLivePT, TablePT,
				SportTypeRefComm, BetTypeRefComm, TableComm,
				SportTypeRefBetSetting, BetTypeRefBetSetting, TableBetSetting,
				SporttypeRefWinlossLimit, BettypeRefWinlossLimit,
				RealProductId, TableBettrans
		FROM OPENXML(@iDoc, '/ROOT/Setting', 1) WITH (
					SportType					VARCHAR(10)
					, BetType					VARCHAR(10)
					, IsLicensee				VARCHAR(1)
					, IsLive					VARCHAR(1)
					, Site						VARCHAR(50)
					, SportTypeRefPT			VARCHAR(10)
					, BetTypeRefPT				VARCHAR(10)
					, IsLivePT					VARCHAR(1)
					, TablePT					VARCHAR(50)
					, SportTypeRefComm			VARCHAR(10)
					, BetTypeRefComm			VARCHAR(10)
					, TableComm					VARCHAR(50)
					, SportTypeRefBetSetting	VARCHAR(10)
					, BetTypeRefBetSetting		VARCHAR(10)
					, TableBetSetting			VARCHAR(50)
					, SporttypeRefWinlossLimit	VARCHAR(10)
					, BettypeRefWinlossLimit	VARCHAR(10)
					, RealProductId				VARCHAR(10)
					, TableBettrans				VARCHAR(100)
				)
		EXEC sp_xml_removedocument @iDoc
	END TRY
	BEGIN CATCH
		SELECT  @ErrCode = ERROR_NUMBER(),@ErrMsg = ERROR_MESSAGE();		
		RETURN
	END CATCH

	--update NULL data:
	UPDATE t
	SET SportType				= CASE WHEN LEN(SportType)=0				THEN NULL ELSE SportType				END,
		BetType     			= CASE WHEN LEN(BetType)=0					THEN NULL ELSE BetType      			END,
		IsLicensee			 	= CASE WHEN LEN(IsLicensee)=0				THEN NULL ELSE IsLicensee			 	END,
		IsLive     				= CASE WHEN LEN(IsLive)=0					THEN NULL ELSE IsLive      				END,
		Site     				= CASE WHEN LEN(Site)=0						THEN NULL ELSE Site      				END,
		
		SportTypeRefPT			= CASE WHEN LEN(SportTypeRefPT)=0			THEN NULL ELSE SportTypeRefPT		  	END,
		BetTypeRefPT			= CASE WHEN LEN(BetTypeRefPT)=0				THEN NULL ELSE BetTypeRefPT				END,
		IsLivePT     			= CASE WHEN LEN(IsLivePT)=0					THEN NULL ELSE IsLivePT      			END,
		TablePT     			= CASE WHEN LEN(TablePT)=0					THEN NULL ELSE TablePT      			END,
		
		SportTypeRefComm     	= CASE WHEN LEN(SportTypeRefComm)=0			THEN NULL ELSE SportTypeRefComm      	END,
		BetTypeRefComm			= CASE WHEN LEN(BetTypeRefComm)=0			THEN NULL ELSE BetTypeRefComm			END,
		TableComm     			= CASE WHEN LEN(TableComm)=0				THEN NULL ELSE TableComm      			END,
		
		SportTypeRefBetSetting  = CASE WHEN LEN(SportTypeRefBetSetting)=0	THEN NULL ELSE SportTypeRefBetSetting   END,
		BetTypeRefBetSetting	= CASE WHEN LEN(BetTypeRefBetSetting)=0		THEN NULL ELSE BetTypeRefBetSetting		END,
		TableBetSetting     	= CASE WHEN LEN(TableBetSetting)=0			THEN NULL ELSE TableBetSetting      	END,

		SporttypeRefWinlossLimit= CASE WHEN LEN(SporttypeRefWinlossLimit)=0	THEN NULL ELSE SporttypeRefWinlossLimit END,
		BettypeRefWinlossLimit	= CASE WHEN LEN(BettypeRefWinlossLimit)=0	THEN NULL ELSE BettypeRefWinlossLimit   END,
		
		RealProductId			= CASE WHEN LEN(RealProductId)=0			THEN NULL ELSE RealProductId      		END,
		TableBettrans			= CASE WHEN LEN(TableBettrans)=0			THEN NULL ELSE TableBettrans      		END
	FROM #NewReferenceSettingTbl t
	WHERE LEN(SportType)=0 OR LEN(BetType)=0
		OR LEN(IsLicensee)=0 OR LEN(IsLive)=0 OR LEN(Site)=0
		OR LEN(SportTypeRefPT)=0 OR LEN(BetTypeRefPT)=0 OR LEN(IsLivePT)=0 OR LEN(TablePT)=0
		OR LEN(SportTypeRefComm)=0 OR LEN(BetTypeRefComm)=0 OR LEN(TableComm)=0
		OR LEN(SportTypeRefBetSetting)=0 OR LEN(BetTypeRefBetSetting)=0 OR LEN(TableBetSetting)=0
		OR LEN(SporttypeRefWinlossLimit)=0 OR LEN(BettypeRefWinlossLimit)=0 
		OR LEN(RealProductId)=0 OR LEN(TableBettrans)=0
	
	--check: allow Number only
	SELECT TOP (1)
			@MatrixError = CONVERT(VARCHAR(5),RowID),
			@ErrCode=122,
			@ColumnName=CASE  WHEN SportType IS NOT NULL				AND ISNUMERIC(SportType)=0					THEN 'SportType'
							  WHEN BetType IS NOT NULL					AND ISNUMERIC(BetType)=0 					THEN 'BetType'
							  WHEN SportTypeRefPT IS NOT NULL			AND ISNUMERIC(SportTypeRefPT)=0				THEN 'SportTypeRefPT'
							  WHEN BetTypeRefPT IS NOT NULL				AND ISNUMERIC(BetTypeRefPT)=0				THEN 'BetTypeRefPT'
							  WHEN SportTypeRefComm IS NOT NULL			AND ISNUMERIC(SportTypeRefComm)=0			THEN 'SportTypeRefComm'
							  WHEN BetTypeRefComm IS NOT NULL			AND ISNUMERIC(BetTypeRefComm)=0				THEN 'BetTypeRefComm'
							  WHEN SportTypeRefBetSetting IS NOT NULL	AND ISNUMERIC(SportTypeRefBetSetting)=0		THEN 'SportTypeRefBetSetting'
							  WHEN BetTypeRefBetSetting IS NOT NULL		AND ISNUMERIC(BetTypeRefBetSetting)=0		THEN 'BettypeRefWinLossLimit'
							  WHEN SporttypeRefWinLossLimit IS NOT NULL	AND ISNUMERIC(SporttypeRefWinLossLimit)=0	THEN 'BettypeRefWinLossLimit'
							  WHEN BettypeRefWinLossLimit IS NOT NULL	AND ISNUMERIC(BettypeRefWinLossLimit)=0		THEN 'BettypeRefWinLossLimit'
							  WHEN RealProductId IS NOT NULL			AND ISNUMERIC(RealProductId)=0				THEN 'RealProductId'
							  ELSE '' 
						END
	FROM #NewReferenceSettingTbl t
	WHERE  (SportType IS NOT NULL					AND ISNUMERIC(SportType)=0)
		OR (BetType IS NOT NULL						AND ISNUMERIC(BetType)=0)
		OR (SportTypeRefPT IS NOT NULL				AND ISNUMERIC(SportTypeRefPT)=0) 
		OR (BetTypeRefPT IS NOT NULL				AND ISNUMERIC(BetTypeRefPT)=0)
		OR (SportTypeRefComm IS NOT NULL			AND ISNUMERIC(SportTypeRefComm)=0) 
		OR (BetTypeRefComm IS NOT NULL				AND ISNUMERIC(BetTypeRefComm)=0)
		OR (SportTypeRefBetSetting IS NOT NULL		AND ISNUMERIC(SportTypeRefBetSetting)=0) 
		OR (BetTypeRefBetSetting IS NOT NULL		AND ISNUMERIC(BetTypeRefBetSetting)=0)
		OR (SporttypeRefWinLossLimit IS NOT NULL	AND ISNUMERIC(SporttypeRefWinLossLimit)=0) 
		OR (BettypeRefWinLossLimit IS NOT NULL		AND ISNUMERIC(BettypeRefWinLossLimit)=0)
		OR (RealProductId IS NOT NULL				AND ISNUMERIC(RealProductId)=0)

	IF @ErrCode <> 0
	BEGIN
		SELECT @ErrMsg = CASE WHEN @IsSingleCheck=1 
							THEN @ColumnName + ' must be a number. Please check them again!' 
							ELSE 'Row ' + @MatrixError + ': ' + @ColumnName + ' must be a number. Please check them again!'
						END
		RETURN
	END

	--check: required fields.
	SELECT TOP (1)
			@MatrixError = CONVERT(VARCHAR(5),RowID),
			@ErrCode=101,
			@ValueError=' can not be null. Please check them again!',
			@ColumnName=CASE  WHEN SportType IS NULL		THEN 'SportType'
							  WHEN BetType IS NULL 			THEN 'BetType'
							  WHEN IsLicensee IS NULL		THEN 'IsLicensee'
							  WHEN IsLive IS NULL			THEN 'IsLive'
							  WHEN Site IS NULL				THEN 'Site'
							  WHEN IsLivePT IS NULL			THEN 'IsLivePT'
							  WHEN TableBettrans IS NULL	THEN 'TableBettrans'
							  WHEN RealProductId IS NULL	THEN 'RealProductId'
							  ELSE '' 
						END
	FROM #NewReferenceSettingTbl t
	WHERE SportType IS NULL
		OR BetType IS NULL		
		OR IsLicensee IS NULL	
		OR IsLive IS NULL		
		OR Site IS NULL
		OR IsLivePT IS NULL		
		OR TableBettrans IS NULL
		OR RealProductId IS NULL

	IF @ErrCode <> 0
	BEGIN
		SELECT @ErrMsg = 'In row ' + @MatrixError + ', ' + @ColumnName + @ValueError 
		RETURN
	END
	
	--check: SportTypeRef/BetTypeRef/TableRef are NULL
	SELECT TOP (1)
			@ErrCode=123,
			@ValueError=CASE  WHEN (t.SportTypeRefPT IS NULL AND (t.BetTypeRefPT IS NOT NULL OR t.TablePT IS NOT NULL) AND ISNULL(t.SportTypeRefPT,'')<>ISNULL(s.SportTypeRefPT,''))		
								OR (t.BetTypeRefPT IS NULL AND (t.SportTypeRefPT IS NOT NULL OR t.TablePT IS NOT NULL) AND ISNULL(t.BetTypeRefPT,'')<>ISNULL(s.BetTypeRefPT,''))		
								OR (t.TablePT IS NULL AND (t.SportTypeRefPT IS NOT NULL OR t.BetTypeRefPT IS NOT NULL) AND ISNULL(t.TablePT,'')<>ISNULL(s.TablePT,''))		
								-------------------------------------------------------------------------------
								OR (t.SportTypeRefPT IS NOT NULL AND (t.BetTypeRefPT IS NULL OR t.TablePT IS NULL) AND ISNULL(t.SportTypeRefPT,'')<>ISNULL(s.SportTypeRefPT,''))
								OR (t.BetTypeRefPT IS NOT NULL AND (t.SportTypeRefPT IS NULL OR t.TablePT IS NULL) AND ISNULL(t.BetTypeRefPT,'')<>ISNULL(s.BetTypeRefPT,''))
								OR (t.TablePT IS NOT NULL AND (t.SportTypeRefPT IS NULL OR t.BetTypeRefPT IS NULL) AND ISNULL(t.TablePT,'')<>ISNULL(s.TablePT,''))								
								
								THEN 'SportTypeRefPT - BetTypeRefPT - TablePT'

							  WHEN (t.SportTypeRefComm IS NULL AND (t.BetTypeRefComm IS NOT NULL OR t.TableComm IS NOT NULL) AND ISNULL(t.SportTypeRefComm,'')<>ISNULL(s.SportTypeRefComm,''))	
								OR (t.BetTypeRefComm IS NULL AND (t.SportTypeRefComm IS NOT NULL OR t.TableComm IS NOT NULL) AND ISNULL(t.BetTypeRefComm,'')<>ISNULL(s.BetTypeRefComm,''))		
								OR (t.TableComm IS NULL AND (t.SportTypeRefComm IS NOT NULL OR t.BetTypeRefComm IS NOT NULL) AND ISNULL(t.TableComm,'')<>ISNULL(s.TableComm,''))		
								-------------------------------------------------------------------------------
								OR (t.SportTypeRefComm IS NOT NULL AND (t.BetTypeRefComm IS NULL OR t.TableComm IS NULL) AND ISNULL(t.SportTypeRefComm,'')<>ISNULL(s.SportTypeRefComm,''))
								OR (t.BetTypeRefComm IS NOT NULL AND (t.SportTypeRefComm IS NULL OR t.TableComm IS NULL) AND ISNULL(t.BetTypeRefComm,'')<>ISNULL(s.BetTypeRefComm,''))
								OR (t.TableComm IS NOT NULL AND (t.SportTypeRefComm IS NULL OR t.BetTypeRefComm IS NULL) AND ISNULL(t.TableComm,'')<>ISNULL(s.TableComm,''))					
								
								THEN 'SportTypeRefComm - BetTypeRefComm - TableComm'

							  WHEN (t.SportTypeRefBetSetting IS NULL AND (t.BetTypeRefBetSetting IS NOT NULL OR t.TableBetSetting IS NOT NULL) AND ISNULL(t.SportTypeRefBetSetting,'')<>ISNULL(s.SportTypeRefBetSetting,''))	
								OR (t.BetTypeRefBetSetting IS NULL AND (t.SportTypeRefBetSetting IS NOT NULL OR t.TableBetSetting IS NOT NULL) AND ISNULL(t.BetTypeRefBetSetting,'')<>ISNULL(s.BetTypeRefBetSetting,''))		
								OR (t.TableBetSetting IS NULL AND (t.SportTypeRefBetSetting IS NOT NULL OR t.BetTypeRefBetSetting IS NOT NULL) AND ISNULL(t.TableBetSetting,'')<>ISNULL(s.TableBetSetting,''))		
								-------------------------------------------------------------------------------
								OR (t.SportTypeRefBetSetting IS NOT NULL AND (t.BetTypeRefBetSetting IS NULL OR t.TableBetSetting IS NULL) AND ISNULL(t.SportTypeRefBetSetting,'')<>ISNULL(s.SportTypeRefBetSetting,''))
								OR (t.BetTypeRefBetSetting IS NOT NULL AND (t.SportTypeRefBetSetting IS NULL OR t.TableBetSetting IS NULL) AND ISNULL(t.BetTypeRefBetSetting,'')<>ISNULL(s.BetTypeRefBetSetting,''))
								OR (t.TableBetSetting IS NOT NULL AND (t.SportTypeRefBetSetting IS NULL OR t.BetTypeRefBetSetting IS NULL) AND ISNULL(t.TableBetSetting,'')<>ISNULL(s.TableBetSetting,''))	
								
								THEN 'SportTypeRefBetSetting - BetTypeRefBetSetting - TableBetSetting'

							  WHEN (t.SportTypeRefWinlossLimit IS NULL AND t.BetTypeRefWinlossLimit IS NOT NULL AND ISNULL(t.SportTypeRefWinlossLimit,'')<>ISNULL(s.SportTypeRefWinlossLimit,''))	
								OR (t.BetTypeRefWinlossLimit IS NULL AND t.SportTypeRefWinlossLimit IS NOT NULL AND ISNULL(t.BetTypeRefWinlossLimit,'')<>ISNULL(s.BetTypeRefWinlossLimit,''))
								-------------------------------------------------------------------------------
								OR (t.SportTypeRefWinlossLimit IS NOT NULL AND t.BetTypeRefWinlossLimit IS NULL AND ISNULL(t.SportTypeRefWinlossLimit,'')<>ISNULL(s.SportTypeRefWinlossLimit,''))	
								OR (t.BetTypeRefWinlossLimit IS NOT NULL AND t.SportTypeRefWinlossLimit IS NULL AND ISNULL(t.BetTypeRefWinlossLimit,'')<>ISNULL(s.BetTypeRefWinlossLimit,''))
								THEN 'SportTypeRefWinlossLimit - BetTypeRefWinlossLimit'
							  ELSE '' 
						END,
			@ColumnName=CASE  WHEN (t.SportTypeRefPT IS NOT NULL 
								AND (t.BetTypeRefPT IS NULL OR t.TablePT IS NULL) 
								AND ISNULL(t.SportTypeRefPT,'')<>ISNULL(s.SportTypeRefPT,''))	THEN 'SportTypeRefPT'
							  WHEN (t.BetTypeRefPT IS NOT NULL 
								AND (t.SportTypeRefPT IS NULL OR t.TablePT IS NULL) 
								AND ISNULL(t.BetTypeRefPT,'')<>ISNULL(s.BetTypeRefPT,''))		THEN 'BetTypeRefPT'
							  WHEN (t.TablePT IS NOT NULL 
								AND (t.SportTypeRefPT IS NULL OR t.BetTypeRefPT IS NULL) 
								AND ISNULL(t.TablePT,'')<>ISNULL(s.TablePT,''))					THEN 'TablePT'
							  
							  WHEN (t.SportTypeRefPT IS NULL 
								AND (t.BetTypeRefPT IS NOT NULL OR t.TablePT IS NOT NULL) 
								AND ISNULL(t.SportTypeRefPT,'')<>ISNULL(s.SportTypeRefPT,''))	THEN 'SportTypeRefPT'
							  WHEN (t.BetTypeRefPT IS NULL 
								AND (t.SportTypeRefPT IS NOT NULL OR t.TablePT IS NOT NULL) 
								AND ISNULL(t.BetTypeRefPT,'')<>ISNULL(s.BetTypeRefPT,''))		THEN 'BetTypeRefPT'
							  WHEN (t.TablePT IS NULL 
								AND (t.SportTypeRefPT IS NOT NULL OR t.BetTypeRefPT IS NOT NULL) 
								AND ISNULL(t.TablePT,'')<>ISNULL(s.TablePT,''))					THEN 'TablePT'
							  -----------------------------------------------------------------------------------------------------------------
							  
							  WHEN (t.SportTypeRefComm IS NULL 
								AND (t.BetTypeRefComm IS NOT NULL OR t.TableComm IS NOT NULL) 
								AND ISNULL(t.SportTypeRefComm,'')<>ISNULL(s.SportTypeRefComm,''))	THEN 'SportTypeRefComm'
							  WHEN (t.BetTypeRefComm IS NULL 
								AND (t.SportTypeRefComm IS NOT NULL OR t.TableComm IS NOT NULL) 
								AND ISNULL(t.BetTypeRefComm,'')<>ISNULL(s.BetTypeRefComm,''))		THEN 'BetTypeRefComm'
							  WHEN (t.TableComm IS NULL 
								AND (t.SportTypeRefComm IS NOT NULL OR t.BetTypeRefComm IS NOT NULL) 
								AND ISNULL(t.TableComm,'')<>ISNULL(s.TableComm,''))					THEN 'TableComm'

							  WHEN (t.SportTypeRefComm IS NOT NULL 
								AND (t.BetTypeRefComm IS NULL OR t.TableComm IS NULL) 
								AND ISNULL(t.SportTypeRefComm,'')<>ISNULL(s.SportTypeRefComm,''))	THEN 'SportTypeRefComm'
							  WHEN (t.BetTypeRefComm IS NOT NULL 
								AND (t.SportTypeRefComm IS NULL OR t.TableComm IS NULL) 
								AND ISNULL(t.BetTypeRefComm,'')<>ISNULL(s.BetTypeRefComm,''))		THEN 'BetTypeRefComm'
							  WHEN (t.TableComm IS NOT NULL 
								AND (t.SportTypeRefComm IS NULL OR t.BetTypeRefComm IS NULL) 
								AND ISNULL(t.TableComm,'')<>ISNULL(s.TableComm,''))					THEN 'TableComm'
							  -----------------------------------------------------------------------------------------------------------------
							 
							  WHEN (t.SportTypeRefBetSetting IS NOT NULL 
								AND (t.BetTypeRefBetSetting IS NULL OR t.TableBetSetting IS NULL) 
								AND ISNULL(t.SportTypeRefBetSetting,'')<>ISNULL(s.SportTypeRefBetSetting,''))	THEN 'SportTypeRefBetSetting'
							  WHEN (t.BetTypeRefBetSetting IS NOT NULL 
								AND (t.SportTypeRefBetSetting IS NULL OR t.TableBetSetting IS NULL) 
								AND ISNULL(t.BetTypeRefBetSetting,'')<>ISNULL(s.BetTypeRefBetSetting,''))		THEN 'BetTypeRefBetSetting'
							  WHEN (t.TableBetSetting IS NOT NULL 
								AND (t.SportTypeRefBetSetting IS NULL OR t.BetTypeRefBetSetting IS NULL) 
								AND ISNULL(t.TableBetSetting,'')<>ISNULL(s.TableBetSetting,''))					THEN 'TableBetSetting'

							  WHEN (t.SportTypeRefBetSetting IS NULL 
								AND (t.BetTypeRefBetSetting IS NOT NULL OR t.TableBetSetting IS NOT NULL) 
								AND ISNULL(t.SportTypeRefBetSetting,'')<>ISNULL(s.SportTypeRefBetSetting,''))	THEN 'SportTypeRefBetSetting'
							  WHEN (t.BetTypeRefBetSetting IS NULL 
								AND (t.SportTypeRefBetSetting IS NOT NULL OR t.TableBetSetting IS NOT NULL) 
								AND ISNULL(t.BetTypeRefBetSetting,'')<>ISNULL(s.BetTypeRefBetSetting,''))		THEN 'BetTypeRefBetSetting'
							  WHEN (t.TableBetSetting IS NULL 
								AND (t.SportTypeRefBetSetting IS NOT NULL OR t.BetTypeRefBetSetting IS NOT NULL) 
								AND ISNULL(t.TableBetSetting,'')<>ISNULL(s.TableBetSetting,''))					THEN 'TableBetSetting'
							  -----------------------------------------------------------------------------------------------------------------
							  
							  WHEN (t.SportTypeRefWinlossLimit IS NULL 
								AND t.BetTypeRefWinlossLimit IS NOT NULL 
								AND ISNULL(t.SportTypeRefWinlossLimit,'')<>ISNULL(s.SportTypeRefWinlossLimit,''))	THEN 'SportTypeRefWinlossLimit'
							  WHEN (t.BetTypeRefWinlossLimit IS NULL 
								AND t.SportTypeRefWinlossLimit IS NOT NULL 
								AND ISNULL(t.BetTypeRefWinlossLimit,'')<>ISNULL(s.BetTypeRefWinlossLimit,''))		THEN 'BetTypeRefWinlossLimit'
							
							  WHEN (t.SportTypeRefWinlossLimit IS NOT NULL 
								AND t.BetTypeRefWinlossLimit IS NULL 
								AND ISNULL(t.SportTypeRefWinlossLimit,'')<>ISNULL(s.SportTypeRefWinlossLimit,''))	THEN 'SportTypeRefWinlossLimit'
							  WHEN (t.BetTypeRefWinlossLimit IS NOT NULL 
								  AND t.SportTypeRefWinlossLimit IS NULL 
								  AND ISNULL(t.BetTypeRefWinlossLimit,'')<>ISNULL(s.BetTypeRefWinlossLimit,''))		THEN 'BetTypeRefWinlossLimit'
							  ELSE '' 
						END
	FROM #NewReferenceSettingTbl t
	INNER JOIN SportBettypeSettingMatrix s WITH (NOLOCK)
		ON t.SportType=s.SportType
		AND t.BetType=s.BetType
		AND t.IsLicensee=s.isLicensee
		AND t.IsLive=s.isLive
		AND t.Site=s.Site
	WHERE  @IsSingleCheck=1
		AND (  
				(NOT (t.SportTypeRefPT IS NULL AND t.BetTypeRefPT IS NULL AND t.TablePT IS NULL)
				AND NOT (t.SportTypeRefPT IS NOT NULL AND t.BetTypeRefPT IS NOT NULL AND t.TablePT IS NOT NULL)
				AND (ISNULL(t.SportTypeRefPT,'')<>ISNULL(s.SportTypeRefPT,'')
					OR ISNULL(t.BetTypeRefPT,'')<>ISNULL(s.BetTypeRefPT,'')
					OR ISNULL(t.TablePT,'')<>ISNULL(s.TablePT,'')))
			OR (NOT (t.SportTypeRefComm IS NULL AND t.BetTypeRefComm IS NULL AND t.TableComm IS NULL)
				AND NOT (t.SportTypeRefComm IS NOT NULL AND t.BetTypeRefComm IS NOT NULL AND t.TableComm IS NOT NULL)
				AND (ISNULL(t.SportTypeRefComm,'')<>ISNULL(s.SportTypeRefComm,'')
					OR ISNULL(t.BetTypeRefComm,'')<>ISNULL(s.BetTypeRefComm,'')
					OR ISNULL(t.TableComm,'')<>ISNULL(s.TableComm,'')))
			OR (NOT (t.SportTypeRefBetSetting IS NULL AND t.BetTypeRefBetSetting IS NULL AND t.TableBetSetting IS NULL)
				AND NOT (t.SportTypeRefBetSetting IS NOT NULL AND t.BetTypeRefBetSetting IS NOT NULL AND t.TableBetSetting IS NOT NULL)
				AND (ISNULL(t.SportTypeRefBetSetting,'')<>ISNULL(s.SportTypeRefBetSetting,'')
					OR ISNULL(t.BetTypeRefBetSetting,'')<>ISNULL(s.BetTypeRefBetSetting,'')
					OR ISNULL(t.TableBetSetting,'')<>ISNULL(s.TableBetSetting,'')))
			OR (NOT (t.SportTypeRefWinlossLimit IS NULL AND t.BetTypeRefWinlossLimit IS NULL)
				AND NOT (t.SportTypeRefWinlossLimit IS NOT NULL AND t.BetTypeRefWinlossLimit IS NOT NULL)
				AND (ISNULL(t.SportTypeRefWinlossLimit,'')<>ISNULL(s.SportTypeRefWinlossLimit,'')
					OR ISNULL(t.BetTypeRefWinlossLimit,'')<>ISNULL(s.BetTypeRefWinlossLimit,'')))
			)

	IF @ErrCode <> 0
	BEGIN
		SELECT @ErrMsg = 'Can not update ' + @ColumnName + '! These fields ' + @ValueError + ' must be all NULL or all not NULL.'
		RETURN
	END

	--check: Bettype<19999.
	SELECT TOP (1)
			@MatrixError = CONVERT(VARCHAR(5),RowID),
			@ErrCode=103,
			@ValueError=' must be less than 19999',
			@ColumnName=CASE  WHEN BetType >= 19999					THEN 'BetType'
							  WHEN BetTypeRefPT >= 19999			THEN 'BetTypeRefPT'
							  WHEN BetTypeRefComm >= 19999			THEN 'BetTypeRefComm'
							  WHEN BetTypeRefBetSetting >= 19999	THEN 'BetTypeRefBetSetting'
							  WHEN BettypeRefWinlossLimit >= 19999	THEN 'BettypeRefWinlossLimit'
							  ELSE '' 
						END
	FROM #NewReferenceSettingTbl t
	WHERE  BetType >= 19999
		OR BetTypeRefPT >= 19999
		OR BetTypeRefBetSetting >= 19999
		OR BetTypeRefComm >= 19999
		OR BettypeRefWinlossLimit >= 19999 

	IF @ErrCode <> 0
	BEGIN
		SELECT @ErrMsg = CASE WHEN @IsSingleCheck=1 
							THEN @ColumnName + @ValueError
							ELSE 'In row ' + @MatrixError + ', ' + @ColumnName + @ValueError  
						END
		RETURN
	END

	--check: exists Sporttype.
	SELECT TOP (1)
			@MatrixError = CONVERT(VARCHAR(5),RowID),
			@ErrCode=CASE WHEN s.SportType IS NULL													THEN 104
							 WHEN spt.SportType IS NULL AND t.SportTypeRefPT IS NOT NULL			THEN 105
							 WHEN scomm.SportType IS NULL AND t.SportTypeRefComm IS NOT NULL		THEN 106
							 WHEN sbs.SportType IS NULL AND t.SportTypeRefBetSetting IS NOT NULL	THEN 107
							 WHEN swl.SportType IS NULL AND t.SportTypeRefWinlossLimit IS NOT NULL	THEN 108 
							 ELSE 100
						END,
			@ValueError=CASE WHEN s.SportType IS NULL												THEN t.SportType
							 WHEN spt.SportType IS NULL AND t.SportTypeRefPT IS NOT NULL			THEN t.SportTypeRefPT
							 WHEN scomm.SportType IS NULL AND t.SportTypeRefComm IS NOT NULL		THEN t.SportTypeRefComm
							 WHEN sbs.SportType IS NULL AND t.SportTypeRefBetSetting IS NOT NULL	THEN t.SportTypeRefBetSetting
							 WHEN swl.SportType IS NULL AND t.SportTypeRefWinlossLimit IS NOT NULL	THEN t.SportTypeRefWinlossLimit 
							 ELSE ''
						END,
			@ColumnName=CASE WHEN s.SportType IS NULL												THEN 'SportType'
							 WHEN spt.SportType IS NULL AND t.SportTypeRefPT IS NOT NULL			THEN 'SportTypeRefPT'
							 WHEN scomm.SportType IS NULL AND t.SportTypeRefComm IS NOT NULL		THEN 'SportTypeRefComm'
							 WHEN sbs.SportType IS NULL AND t.SportTypeRefBetSetting IS NOT NULL	THEN 'SportTypeRefBetSetting'
							 WHEN swl.SportType IS NULL AND t.SportTypeRefWinlossLimit IS NOT NULL	THEN 'SportTypeRefWinlossLimit'
							 ELSE ''
						END
	FROM #NewReferenceSettingTbl t
	LEFT JOIN #Sports s ON s.SportType=t.SportType
	LEFT JOIN #Sports spt ON spt.SportType=t.SportTypeRefPT
	LEFT JOIN #Sports scomm ON scomm.SportType=t.SportTypeRefComm
	LEFT JOIN #Sports sbs ON sbs.SportType=t.SportTypeRefBetSetting
	LEFT JOIN #Sports swl ON swl.SportType=t.SportTypeRefWinlossLimit
	WHERE s.SportType IS NULL
		OR spt.SportType IS NULL AND t.SportTypeRefPT IS NOT NULL
		OR scomm.SportType IS NULL AND t.SportTypeRefComm IS NOT NULL
		OR sbs.SportType IS NULL AND t.SportTypeRefBetSetting IS NOT NULL
		OR swl.SportType IS NULL AND t.SportTypeRefWinlossLimit IS NOT NULL

	IF @ErrCode <> 0
	BEGIN
		SELECT @ErrMsg = CASE WHEN @IsSingleCheck=1 
							THEN 'The ' + @ColumnName + ' ' + CAST(@ValueError AS VARCHAR) + ' does not exist.'
							ELSE 'In row ' + @MatrixError + ', the ' + @ColumnName + ' ' + CAST(@ValueError AS VARCHAR) + ' does not exist.'
						END
		RETURN
	END

	--check: exists BettypeRef (exclude Bettype, allow to add full range new Product's bettype without validating Bettype). 
	SELECT TOP (1)
			@MatrixError = CONVERT(VARCHAR(5),RowID),
			@ErrCode=CASE --WHEN b.typeid IS NULL													THEN 109
							 WHEN bpt.typeid IS NULL AND t.BetTypeRefPT IS NOT NULL				THEN 110
							 WHEN bcomm.typeid IS NULL AND t.BetTypeRefComm IS NOT NULL			THEN 111
							 WHEN bbs.typeid IS NULL AND t.BetTypeRefBetSetting IS NOT NULL		THEN 112
							 WHEN bwl.typeid IS NULL AND t.BettypeRefWinlossLimit IS NOT NULL	THEN 113 
							 ELSE 100
						END,
			@ValueError=CASE --WHEN b.typeid IS NULL												THEN t.BetType
							 WHEN bpt.typeid IS NULL AND t.BetTypeRefPT IS NOT NULL				THEN t.BetTypeRefPT
							 WHEN bcomm.typeid IS NULL AND t.BetTypeRefComm IS NOT NULL			THEN t.BetTypeRefComm
							 WHEN bbs.typeid IS NULL AND t.BetTypeRefBetSetting IS NOT NULL		THEN t.BetTypeRefBetSetting
							 WHEN bwl.typeid IS NULL AND t.BettypeRefWinlossLimit IS NOT NULL	THEN t.BettypeRefWinlossLimit 
							 ELSE ''
						END,
			@ColumnName=CASE --WHEN b.typeid IS NULL												THEN 'BetType'
							 WHEN bpt.typeid IS NULL AND t.BetTypeRefPT IS NOT NULL				THEN 'BetTypeRefPT'
							 WHEN bcomm.typeid IS NULL AND t.BetTypeRefComm IS NOT NULL			THEN 'BetTypeRefComm'
							 WHEN bbs.typeid IS NULL AND t.BetTypeRefBetSetting IS NOT NULL		THEN 'BetTypeRefBetSetting'
							 WHEN bwl.typeid IS NULL AND t.BettypeRefWinlossLimit IS NOT NULL	THEN 'BettypeRefWinlossLimit'
							 ELSE ''
						END
	FROM #NewReferenceSettingTbl t
--	LEFT JOIN #Bettype b ON b.typeid=t.BetType
	LEFT JOIN #Bettype bpt ON bpt.typeid=t.BetTypeRefPT
	LEFT JOIN #Bettype bcomm ON bcomm.typeid=t.BetTypeRefComm
	LEFT JOIN #Bettype bbs ON bbs.typeid=t.BetTypeRefBetSetting
	LEFT JOIN #Bettype bwl ON bwl.typeid=t.BettypeRefWinlossLimit
	WHERE bpt.typeid IS NULL AND t.BetTypeRefPT IS NOT NULL
		OR bcomm.typeid IS NULL AND t.BetTypeRefComm IS NOT NULL
		OR bbs.typeid IS NULL AND t.BetTypeRefBetSetting IS NOT NULL
		OR bwl.typeid IS NULL AND t.BettypeRefWinlossLimit IS NOT NULL

	IF @ErrCode <> 0
	BEGIN
		SELECT @ErrMsg = CASE WHEN @IsSingleCheck=1
							THEN 'The ' + @ColumnName + ' ' + CAST(@ValueError AS VARCHAR) + ' does not exist.'
							ELSE 'In row ' + @MatrixError + ', the ' + @ColumnName + ' ' + CAST(@ValueError AS VARCHAR) + ' does not exist.'
						END
		RETURN
	END

	--check: valid table name
	SELECT TOP (1)
			@MatrixError = CONVERT(VARCHAR(5),RowID),
			@ErrCode=102,
			@ValueError = 
						CASE WHEN t.TablePT IS NOT NULL AND pt.TableName IS NULL		 THEN TablePT
							 WHEN t.TableComm IS NOT NULL AND c.TableName IS NULL		 THEN TableComm
							 WHEN t.TableBetSetting IS NOT NULL AND bs.TableName IS NULL THEN TableBetSetting
							 WHEN t.TableBettrans IS NOT NULL AND bt.TableName IS NULL	 THEN TableBettrans
							 ELSE ''
						END,
			@ColumnName=CASE WHEN t.TablePT IS NOT NULL AND pt.TableName IS NULL		 THEN 'TablePT'
							 WHEN t.TableComm IS NOT NULL AND c.TableName IS NULL		 THEN 'TableComm'
							 WHEN t.TableBetSetting IS NOT NULL AND bs.TableName IS NULL THEN 'TableBetSetting'
							 WHEN t.TableBettrans IS NOT NULL AND bt.TableName IS NULL	 THEN 'TableBettrans'
							 ELSE ''
						END
	FROM #NewReferenceSettingTbl t
		OUTER APPLY (SELECT TableName, OfferSite FROM #RefTable f WHERE t.TablePT=f.TableName AND f.TableType='TablePT') pt
		OUTER APPLY (SELECT TableName, OfferSite FROM #RefTable f WHERE t.TableComm=f.TableName AND f.TableType='TableComm') c
		OUTER APPLY (SELECT TableName, OfferSite FROM #RefTable f WHERE t.TableBetSetting=f.TableName AND f.TableType='TableBetSetting') bs
		OUTER APPLY (SELECT TableName, OfferSite FROM #RefTable f WHERE t.TableBettrans=f.TableName AND f.TableType='TableBettrans') bt
	WHERE  (t.TablePT IS NOT NULL AND pt.TableName IS NULL)
		OR (t.TableComm IS NOT NULL AND c.TableName IS NULL)
		OR (t.TableBetSetting IS NOT NULL AND bs.TableName IS NULL)
		OR (t.TableBettrans IS NOT NULL AND bt.TableName IS NULL)

	IF @ErrCode <> 0
	BEGIN
		SELECT @ErrMsg = 'In row ' + @MatrixError + ', Invalid ' + @ColumnName + ': ' + @ValueError + '. Please check them again!'
		RETURN
	END

	--check: valid table name & isLicense
	SELECT TOP (1)
			@MatrixError = CONVERT(VARCHAR(5),RowID),
			@ErrCode=120,
			@ValueError = ' can not be ' +
						CASE WHEN t.TablePT IS NOT NULL 
								AND (pt.TableName IS NULL OR pt.OfferSite<>t.IsLicensee)	THEN TablePT
							 WHEN t.TableComm IS NOT NULL 
								AND (c.TableName IS NULL OR c.OfferSite<>t.IsLicensee) 		THEN TableComm
							 WHEN t.TableBetSetting IS NOT NULL 
								AND (bs.TableName IS NULL OR bs.OfferSite<>t.IsLicensee)	THEN TableBetSetting
							 ELSE ''
						END,
			@ColumnName= CONVERT(VARCHAR(1),IsLicensee)
						+ ', so field ' +
						CASE WHEN t.TablePT IS NOT NULL 
								AND (pt.TableName IS NULL OR pt.OfferSite<>t.IsLicensee)	THEN 'TablePT'
							 WHEN t.TableComm IS NOT NULL 
								AND (c.TableName IS NULL OR c.OfferSite<>t.IsLicensee)		THEN 'TableComm'
							 WHEN t.TableBetSetting IS NOT NULL 
								AND (bs.TableName IS NULL OR bs.OfferSite<>t.IsLicensee)	THEN 'TableBetSetting'
							 ELSE ''
						END
	FROM #NewReferenceSettingTbl t
		OUTER APPLY (SELECT TableName, OfferSite FROM #RefTable f WHERE t.TablePT=f.TableName AND f.TableType='TablePT') pt
		OUTER APPLY (SELECT TableName, OfferSite FROM #RefTable f WHERE t.TableComm=f.TableName AND f.TableType='TableComm') c
		OUTER APPLY (SELECT TableName, OfferSite FROM #RefTable f WHERE t.TableBetSetting=f.TableName AND f.TableType='TableBetSetting') bs
	WHERE  (t.TablePT IS NOT NULL AND (pt.TableName IS NULL OR pt.OfferSite<>t.IsLicensee))
		OR (t.TableComm IS NOT NULL AND (c.TableName IS NULL OR c.OfferSite<>t.IsLicensee))
		OR (t.TableBetSetting IS NOT NULL AND (bs.TableName IS NULL OR bs.OfferSite<>t.IsLicensee))

	IF @ErrCode <> 0
	BEGIN
		SELECT @ErrMsg = CASE WHEN @IsSingleCheck=1
							THEN 'isLicensee = ' + @ColumnName + @ValueError + '. Please check them again!'  
							ELSE 'In row ' + @MatrixError + ', isLicensee = ' + @ColumnName + @ValueError + '. Please check them again!'  
						END
		RETURN
	END

	--check: max length
	SELECT TOP(1) 
			@MatrixError = CONVERT(VARCHAR(5),RowID),
			@ErrCode=CASE WHEN LEN(TablePT)			> 50	THEN 114
						  WHEN LEN(TableComm)		> 50	THEN 115
						  WHEN LEN(TableBetSetting)	> 50	THEN 116
						  WHEN LEN(TableBettrans)	> 100	THEN 117
						  ELSE '' 
					END,
			@ValueError = CASE WHEN LEN(TablePT)			> 50	THEN TablePT
							   WHEN LEN(TableComm)			> 50	THEN TableComm
							   WHEN LEN(TableBetSetting)	> 50	THEN TableBetSetting
							   WHEN LEN(TableBettrans)		> 100	THEN TableBettrans
							   ELSE '' 
						END,
			@LimitValue = CASE WHEN LEN(TablePT)			> 50	THEN LEN(TablePT)
							   WHEN LEN(TableComm)			> 50	THEN LEN(TableComm)
							   WHEN LEN(TableBetSetting)	> 50	THEN LEN(TableBetSetting)
							   WHEN LEN(TableBettrans)		> 100	THEN LEN(TableBettrans)
							   ELSE '' 
						END
	FROM #NewReferenceSettingTbl
	WHERE LEN(TablePT)			> 50
		OR LEN(TableComm)		> 50
		OR LEN(TableBetSetting)	> 50
		OR LEN(TableBettrans)	> 100

	IF @ErrCode <> 0
	BEGIN
		SELECT @ErrMsg = 'Row ' + @MatrixError + ' - The values ''' + CAST(@ValueError AS VARCHAR) + ''' is exceeded max length ' + CAST(@LimitValue AS VARCHAR) + '.'
		RETURN
	END
	
	--RowDuplicate
	INSERT INTO #RowDuplicate(RowID)
	SELECT DISTINCT tmp.RowID
	FROM #NewReferenceSettingTbl tmp
	INNER JOIN #NewReferenceSettingTbl ndt 
			ON tmp.SportType = ndt.SportType 
			AND tmp.BetType = ndt.BetType 
			AND tmp.isLicensee = ndt.isLicensee 
			AND tmp.isLive = ndt.isLive 
			AND tmp.Site = ndt.Site 
			AND ndt.RowID>tmp.RowID

	IF EXISTS (SELECT TOP 1 1 FROM #RowDuplicate)		
	BEGIN
		SET @ErrCode=121
		SELECT @ErrMsg='Row ' + STUFF((SELECT ', ' + CAST(RowID AS NVARCHAR(50)) 
										FROM #RowDuplicate tmp
										ORDER BY RowID
										FOR XML PATH('')), 1, 1, '') 
							  + ': SportType - BetType - isLicensee - isLive - Site of rows can not be the same!' 
		RETURN
	END	

	--check: Exists setting
	IF @IsNew=1
	BEGIN
		SELECT TOP (1)
				@MatrixError = CONVERT(VARCHAR(5),RowID),
				@ErrCode=118,
				@ValueError=' have already existed in DB. Can not add this row!'
		FROM #NewReferenceSettingTbl t
		INNER JOIN SportBettypeSettingMatrix sm WITH (NOLOCK) 
				ON t.SportType=sm.SportType
				AND t.BetType=sm.BetType
				AND t.IsLicensee=sm.IsLicensee
				AND t.IsLive=sm.IsLive
				AND t.Site=sm.Site

		IF @ErrCode <> 0
		BEGIN
			SELECT @ErrMsg = 'Row ' + @MatrixError + @ValueError 
			RETURN
		END
	END
	ELSE
	BEGIN
		SELECT TOP (1)
				@MatrixError = CONVERT(VARCHAR(5),RowID),
				@ErrCode=119,
				@ValueError=' do not exist in DB. Can not update!'
		FROM #NewReferenceSettingTbl t
		WHERE NOT EXISTS 
				(SELECT 1 FROM SportBettypeSettingMatrix sm WITH (NOLOCK) 
				 WHERE t.SportType=sm.SportType
					AND t.BetType=sm.BetType
					AND t.IsLicensee=sm.IsLicensee
					AND t.IsLive=sm.IsLive
					AND t.Site=sm.Site)

		IF @ErrCode <> 0
		BEGIN
			SELECT @ErrMsg = 'Row ' + @MatrixError + @ValueError 
			RETURN
		END
	END

	DROP TABLE #NewReferenceSettingTbl, #Bettype, #Sports
END						
GO