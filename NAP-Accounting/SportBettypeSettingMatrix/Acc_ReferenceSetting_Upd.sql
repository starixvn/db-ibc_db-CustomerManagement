/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE dbo.Acc_ReferenceSetting_Upd 
	-- Add the parameters for the stored procedure here
	 @InputData		VARCHAR(MAX)	= ''
	,@IsSingleUpd	BIT				= 0
	,@UserID		INT
	,@IP			VARCHAR(50)		= ''
	,@ErrCode		INT = 0				OUTPUT
	,@ErrMsg		NVARCHAR(4000)	= '' OUTPUT
AS
/*
	Task : NAP - New function to manage SportBettypeSettingMatrix table
	DB: DBACC/bodb02
	Original: 
	Revisions:
		- 20230301@Tacy: Create SP [Redmine: #184255]
		- 20230803@Tacy: NAP - Manage SportBettypeSettingMatrix - Add more fields [Redmine: #192732]

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
					SporttypeRefWinlossLimit=""
					BettypeRefWinlossLimit=""
					RealProductId="1"
					DummyProductId=""
			/>
	</ROOT>
*/
BEGIN
	SET NOCOUNT ON;
	
	IF @InputData=''	RETURN

	DECLARE @StartRun	DATETIME, @EndRun DATETIME, @Duration INT, @logSpData NVARCHAR(MAX)
	DECLARE @MatrixError NVARCHAR(MAX) = '',
			@ValueError NVARCHAR(MAX) = '',
			@ColumnName NVARCHAR(200)


	CREATE TABLE #NewReferenceSettingTbl (
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
			RealProductId			TINYINT,
			DummyProductId			TINYINT
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
											DummyProductId, RealProductId, TableBettrans)
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
				CASE WHEN TableBetSetting IN ('NULL','')		THEN NULL ELSE TableBetSetting			END TableBetSetting, 
			
				CASE WHEN ISNUMERIC(SporttypeRefWinlossLimit)=0	THEN NULL ELSE SporttypeRefWinlossLimit	END SporttypeRefWinlossLimit,
				CASE WHEN ISNUMERIC(BettypeRefWinlossLimit)=0	THEN NULL ELSE BettypeRefWinlossLimit	END BettypeRefWinlossLimit,

				CASE WHEN ISNUMERIC(DummyProductId)=0	THEN NULL ELSE DummyProductId	END DummyProductId,
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
					, RealProductId				TINYINT
					, DummyProductId			VARCHAR(10)
					, TableBettrans				VARCHAR(100)
				)
		EXEC sp_xml_removedocument @iDoc
	END TRY
	BEGIN CATCH
		SELECT  @ErrCode = ERROR_NUMBER(),@ErrMsg = ERROR_MESSAGE();		
		RETURN
	END CATCH
	
	--UPDATE:
	BEGIN TRY
		UPDATE s
		SET s.SportTypeRefPT=CASE WHEN (t.SportTypeRefPT IS NULL AND (t.BetTypeRefPT IS NOT NULL OR t.TablePT IS NOT NULL))
									OR (t.SportTypeRefPT IS NULL AND t.BetTypeRefPT IS NULL AND t.TablePT IS  NULL AND @IsSingleUpd=0)	THEN s.SportTypeRefPT ELSE t.SportTypeRefPT END
			, s.BetTypeRefPT=CASE WHEN (t.BetTypeRefPT IS NULL AND (t.SportTypeRefPT IS NOT NULL OR t.TablePT IS NOT NULL))
									OR (t.BetTypeRefPT IS NULL AND t.SportTypeRefPT IS NULL AND t.TablePT IS NULL AND @IsSingleUpd=0)	THEN s.BetTypeRefPT ELSE t.BetTypeRefPT END
			, s.IsLivePT=t.IsLivePT
			, s.TablePT=CASE WHEN  (t.TablePT IS NULL AND (t.SportTypeRefPT IS NOT NULL OR t.BetTypeRefPT IS NOT NULL))	  
								OR (t.TablePT IS NULL AND t.SportTypeRefPT IS NULL AND t.BetTypeRefPT IS NULL AND @IsSingleUpd=0)		THEN s.TablePT ELSE t.TablePT END

			, s.SportTypeRefComm=CASE WHEN (t.SportTypeRefComm IS NULL AND (t.BetTypeRefComm IS NOT NULL OR t.TableComm IS NOT NULL)) 
										OR (t.SportTypeRefComm IS NULL AND t.BetTypeRefComm IS NULL AND t.TableComm IS NULL AND @IsSingleUpd=0)	THEN s.SportTypeRefComm ELSE t.SportTypeRefComm END
			, s.BetTypeRefComm=CASE WHEN (t.BetTypeRefComm IS NULL AND (t.SportTypeRefComm IS NOT NULL OR t.TableComm IS NOT NULL))
										OR (t.BetTypeRefComm IS NULL AND t.SportTypeRefComm IS NULL AND t.TableComm IS NULL AND @IsSingleUpd=0)	THEN s.BetTypeRefComm ELSE t.BetTypeRefComm END
			, s.TableComm=CASE WHEN (t.TableComm IS NULL AND (t.SportTypeRefComm IS NOT NULL OR t.BetTypeRefComm IS NOT NULL))
								OR (t.TableComm IS NULL AND t.SportTypeRefComm IS NULL AND t.BetTypeRefComm IS NULL AND @IsSingleUpd=0)			THEN s.TableComm ELSE t.TableComm END

			, s.SportTypeRefBetSetting=CASE WHEN (t.SportTypeRefBetSetting IS NULL AND (t.BetTypeRefBetSetting IS NOT NULL OR t.TableBetSetting IS NOT NULL)) 
											OR (t.SportTypeRefBetSetting IS NULL AND t.BetTypeRefBetSetting IS NULL AND t.TableBetSetting IS NULL AND @IsSingleUpd=0)	THEN s.SportTypeRefBetSetting ELSE t.SportTypeRefBetSetting END
			, s.BetTypeRefBetSetting=CASE WHEN (t.BetTypeRefBetSetting IS NULL AND (t.SportTypeRefBetSetting IS NOT NULL OR t.TableBetSetting IS NOT NULL))	
											OR (t.BetTypeRefBetSetting IS NULL AND t.SportTypeRefBetSetting IS NULL AND t.TableBetSetting IS NULL AND @IsSingleUpd=0)	THEN s.BetTypeRefBetSetting ELSE t.BetTypeRefBetSetting END
			, s.TableBetSetting=CASE WHEN (t.TableBetSetting IS NULL AND (t.SportTypeRefBetSetting IS NOT NULL OR t.BetTypeRefBetSetting IS NOT NULL))	
										OR (t.TableBetSetting IS NULL AND t.SportTypeRefBetSetting IS NULL AND t.BetTypeRefBetSetting IS NULL AND @IsSingleUpd=0)		THEN s.TableBetSetting ELSE t.TableBetSetting END

			, s.SporttypeRefWinlossLimit=CASE WHEN (t.SporttypeRefWinlossLimit IS NULL AND t.BettypeRefWinlossLimit IS NOT NULL)			
												OR (t.SporttypeRefWinlossLimit IS NULL AND t.BettypeRefWinlossLimit IS NULL AND @IsSingleUpd=0)		THEN s.SporttypeRefWinlossLimit ELSE t.SporttypeRefWinlossLimit END
			, s.BettypeRefWinlossLimit=CASE WHEN (t.BettypeRefWinlossLimit IS NULL AND t.SporttypeRefWinlossLimit IS NOT NULL)	
											OR (t.BettypeRefWinlossLimit IS NULL AND t.SporttypeRefWinlossLimit IS NULL AND @IsSingleUpd=0) THEN s.BettypeRefWinlossLimit ELSE t.BettypeRefWinlossLimit END

			, s.TableBettrans=t.TableBettrans
			, s.RealProductId=t.RealProductId
			, s.ProductID=t.DummyProductId
			, s.[RepUpdateTime]=sysdatetime()
		FROM SportBettypeSettingMatrix s WITH (ROWLOCK, UPDLOCK)
		INNER JOIN #NewReferenceSettingTbl t 
			ON t.SportType=s.SportType
			AND t.BetType=s.BetType
			AND t.IsLicensee=s.IsLicensee
			AND t.IsLive=s.IsLive
			AND t.Site=s.Site
			AND s.isDeleted=0
	END TRY
	BEGIN CATCH
		SELECT  @ErrCode = ERROR_NUMBER(),@ErrMsg = ERROR_MESSAGE()
		RETURN
	END CATCH
	
	--Write log
	SELECT @EndRun	= GETDATE(), @Duration = DATEDIFF(MILLISECOND, @StartRun, @EndRun)
	DECLARE @NewLog VARCHAR(MAX)
	SET @NewLog = '<Acc_ReferenceSetting_Upd IP="'+ COALESCE(CAST(@IP AS VARCHAR(15)),SPACE(1))+'" >'
	SELECT @logSpData = REPLACE(REPLACE(@InputData, '<ROOT>', @NewLog),'/ROOT','/Acc_ReferenceSetting_Upd')
	EXEC  Acc_WriteLog_UserLog_RunSP_Wrapper
				@UserID = @UserID,
				@ActionID = 6065,
				@TrackingValue = @LogSPData,
				@duration = @Duration
END						
GO