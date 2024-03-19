/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet,wsv_nap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE dbo.Acc_ReferenceSetting_Del 
	-- Add the parameters for the stored procedure here
	 @InputData	VARCHAR(MAX)	= ''
	,@UserID	INT
	,@IP		VARCHAR(50)		= ''
	,@ErrCode	INT = 0				OUTPUT
	,@ErrMsg	NVARCHAR(4000)	= '' OUTPUT
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
			SportType				SMALLINT,
			BetType					INT,
			IsLicensee				BIT,
			IsLive					BIT,
			Site					VARCHAR(50)
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

		INSERT INTO #NewReferenceSettingTbl(SportType, BetType, IsLicensee, IsLive, Site)
		SELECT	SportType, BetType, IsLicensee, IsLive, 
				CASE WHEN TRIM(Site)='NULL' THEN NULL ELSE TRIM(Site) END Site
		FROM OPENXML(@iDoc, '/ROOT/Setting', 1) WITH (
					SportType					SMALLINT
					, BetType					SMALLINT
					, IsLicensee				BIT
					, IsLive					BIT
					, Site						VARCHAR(50)
				)
		EXEC sp_xml_removedocument @iDoc
	END TRY
	BEGIN CATCH
		SELECT  @ErrCode = ERROR_NUMBER(),@ErrMsg = ERROR_MESSAGE();		
		RETURN
	END CATCH
	
	--DELETE:
	BEGIN TRY
		UPDATE s
		SET s.[RepUpdateTime]=sysdatetime(),
			s.[isDeleted]=1
		FROM SportBettypeSettingMatrix s  WITH (ROWLOCK,UPDLOCK)
		INNER JOIN #NewReferenceSettingTbl t 
			ON t.SportType=s.SportType
			AND t.BetType=s.BetType
			AND t.IsLicensee=s.IsLicensee
			AND t.IsLive=s.IsLive
			AND t.Site=s.Site
	END TRY
	BEGIN CATCH
		SELECT  @ErrCode = ERROR_NUMBER(),@ErrMsg = ERROR_MESSAGE()
		RETURN
	END CATCH
	
	--Write log
	SELECT @EndRun	= GETDATE(), @Duration = DATEDIFF(MILLISECOND, @StartRun, @EndRun)
	DECLARE @NewLog VARCHAR(MAX)
	SET @NewLog = '<Acc_ReferenceSetting_Del IP="'+ COALESCE(CAST(@IP AS VARCHAR(15)),SPACE(1))+'" >'
	SELECT @logSpData = REPLACE(REPLACE(@InputData, '<ROOT>', @NewLog),'/ROOT','/Acc_ReferenceSetting_Del')
	EXEC  Acc_WriteLog_UserLog_RunSP_Wrapper
				@UserID = @UserID,
				@ActionID = 6066,
				@TrackingValue = @LogSPData,
				@duration = @Duration
END						
GO