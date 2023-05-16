/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE dbo.Acc_ReferenceSetting_Ins 
	-- Add the parameters for the stored procedure here
	 @InputData	VARCHAR(MAX)	= ''
	,@UserID	INT
	,@IP		VARCHAR(50)		= ''
	,@ErrCode	INT = 0				OUTPUT
	,@ErrMsg	NVARCHAR(4000)	= '' OUTPUT
AS
/*
	Task : NAP - New function to manage SportBettypeSettingMatrix table
	DB: DBCUST/bodb02
	Original: 

	Revisions:
		- 20230301@Tacy: Create SP [Redmine: #184255]
		
	Param's Explanation:
		 @pInputData : 
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

	DECLARE @StartRun		DATETIME
			, @EndRun		DATETIME
			, @Duration		INT
			, @logSpData	NVARCHAR(MAX)
			, @MatrixError	NVARCHAR(MAX) = ''
			, @ValueError	NVARCHAR(MAX) = ''
			, @ColumnName	NVARCHAR(200)

	CREATE TABLE #NewReferenceSettingTbl  (
			RowID					INT IDENTITY (1,1),
			SportType				SMALLINT,
			BetType					INT,
			IsLicensee				BIT,
			IsLive					BIT,
			Site					VARCHAR(50),
			
			SportTypeRefPT			SMALLINT,
			BetTypeRefPT			INT,
			IsLivePT				BIT DEFAULT (0),
			TablePT					VARCHAR(50),
			
			SportTypeRefComm		SMALLINT,
			BetTypeRefComm			INT,
			TableComm				VARCHAR(50),
			
			SportTypeRefBetSetting	SMALLINT,
			BetTypeRefBetSetting	INT,
			TableBetSetting			VARCHAR(50),
			
			SporttypeRefWinlossLimit SMALLINT,
			BettypeRefWinlossLimit	 SMALLINT,
			
			TableBettrans			VARCHAR(100),
			RealProductId			TINYINT
		)
	
	IF @InputData IS NULL OR @InputData = ''
		RETURN
		
	SELECT	@ErrCode = 0, @ErrMsg = '' 
	
	SET @StartRun = GETDATE()	

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
				
				CASE WHEN ISNUMERIC(SportTypeRefPT)=0	THEN NULL ELSE SportTypeRefPT	END SportTypeRefPT,
				CASE WHEN ISNUMERIC(BetTypeRefPT)=0		THEN NULL ELSE BetTypeRefPT		END BetTypeRefPT, 
				IsLivePT, 
				CASE WHEN TablePT IN ('NULL','')		THEN NULL ELSE TablePT			END TablePT, 
				
				CASE WHEN ISNUMERIC(SportTypeRefComm)=0	THEN NULL ELSE SportTypeRefComm	END SportTypeRefComm, 
				CASE WHEN ISNUMERIC(BetTypeRefComm)=0	THEN NULL ELSE BetTypeRefComm	END BetTypeRefComm, 
				CASE WHEN TableComm IN ('NULL','')		THEN NULL ELSE TableComm		END TableComm, 
			
				CASE WHEN ISNUMERIC(SportTypeRefBetSetting)=0	THEN NULL ELSE SportTypeRefBetSetting	END SportTypeRefBetSetting,
				CASE WHEN ISNUMERIC(BetTypeRefBetSetting)=0		THEN NULL ELSE BetTypeRefBetSetting		END BetTypeRefBetSetting, 
				CASE WHEN TableBetSetting IN ('NULL','')			THEN NULL ELSE TableBetSetting			END TableBetSetting, 
			
				CASE WHEN ISNUMERIC(SporttypeRefWinlossLimit)=0	THEN NULL ELSE SporttypeRefWinlossLimit	END SporttypeRefWinlossLimit,
				CASE WHEN ISNUMERIC(BettypeRefWinlossLimit)=0	THEN NULL ELSE BettypeRefWinlossLimit	END BettypeRefWinlossLimit,

				RealProductId,
				TableBettrans 

		FROM OPENXML(@iDoc, '/ROOT/Setting', 1) WITH (
					SportType					SMALLINT
					, BetType					SMALLINT
					, IsLicensee				BIT
					, IsLive					BIT
					, Site						VARCHAR(50)
					, SportTypeRefPT			VARCHAR(10)
					, BetTypeRefPT				VARCHAR(10)
					, IsLivePT					BIT
					, TablePT					VARCHAR(50)
					, SportTypeRefComm			VARCHAR(10)
					, BetTypeRefComm			VARCHAR(10)
					, TableComm					VARCHAR(50)
					, SportTypeRefBetSetting	VARCHAR(10)
					, BetTypeRefBetSetting		VARCHAR(10)
					, TableBetSetting			VARCHAR(50)
					, SporttypeRefWinlossLimit	VARCHAR(10)
					, BettypeRefWinlossLimit	VARCHAR(10)
					, RealProductId				INT
					, TableBettrans				VARCHAR(100)
				)
		EXEC sp_xml_removedocument @iDoc
	END TRY
	BEGIN CATCH
		SELECT  @ErrCode = ERROR_NUMBER(),@ErrMsg = ERROR_MESSAGE();		
		RETURN
	END CATCH

	--INSERT:
	BEGIN TRY
		INSERT INTO SportBettypeSettingMatrix
				([SportType], [BetType], [IsLicensee], [IsLive], [Site], [isActive], [SportTypeRefPT], [BetTypeRefPT], [IsLivePT], [TablePT], [SportTypeRefComm], [BetTypeRefComm], [TableComm], [SportTypeRefBetSetting], [BetTypeRefBetSetting], [TableBetSetting], [IsLiveComm], [IsLiveBetSetting], [TableBettrans], [SporttypeRefWinlossLimit], [BettypeRefWinlossLimit], [RealProductId])
		SELECT	 [SportType], [BetType], [IsLicensee], [IsLive], [Site], 1,			 [SportTypeRefPT], [BetTypeRefPT], [IsLivePT], [TablePT], [SportTypeRefComm], [BetTypeRefComm], [TableComm], [SportTypeRefBetSetting], [BetTypeRefBetSetting], [TableBetSetting], 0,			0,					[TableBettrans], [SporttypeRefWinlossLimit], [BettypeRefWinlossLimit], [RealProductId]
		FROM #NewReferenceSettingTbl
	END TRY
	BEGIN CATCH
		SELECT  @ErrCode = ERROR_NUMBER(),@ErrMsg = ERROR_MESSAGE()
		RETURN
	END CATCH

	--Write log
	SELECT @EndRun	= GETDATE(), @Duration = DATEDIFF(MILLISECOND, @StartRun, @EndRun)
	DECLARE @NewLog VARCHAR(MAX)
	SET @NewLog = '<Acc_ReferenceSetting_Ins IP="'+ COALESCE(CAST(@IP AS VARCHAR(15)),SPACE(1))+'" >'
	SELECT @logSpData = REPLACE(REPLACE(@InputData, '<ROOT>', @NewLog),'/ROOT','/Acc_ReferenceSetting_Ins')
	EXEC  Acc_WriteLog_UserLog_RunSP_Wrapper
				@UserID = @UserID,
				@ActionID = 6064,
				@TrackingValue = @LogSPData,
				@duration = @Duration
END						
GO