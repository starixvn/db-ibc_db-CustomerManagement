/*<info serverAlias="DBACC-bodb_ACC" executers="bodbAdminNet" viewers="vnteam" isFunction="0"></info>*/
USE [bodb_ACC]
GO

ALTER PROCEDURE [dbo].[NAP_BetMonitoring_NotifiedCustomerListUpd]
	@CustList VARCHAR(MAX)
AS
/*  
	Creator: Elodie
	Date: 20160705
	Task: Get customer list to send email - [Redmine:#58401]
	DB: DBACC/bodb_ACC
  
	Revisions:  	
	Param's Explanation:  
		- @CustList = '<Notify>
							<row c = "1" s = "1"/>
							<row c = "2" s = "1"/>
						</Notify>'
	Example: EXEC NAP_BetMonitoring_NotifiedCustomerListUpd @CustList = '<Notify>
							<row c = "1" s = "1"/>
							<row c = "2" s = "1"/>
						</Notify>'
*/
BEGIN
	SET NOCOUNT ON

	DECLARE	@DocHandler	INT, @startRun DATETIME, @endRun DATETIME, @duration INT											
	CREATE TABLE #tmpCust (CustID INT, SportType TINYINT)
	CREATE CLUSTERED INDEX CIX_tmpCust ON #tmpCust(CustID,SportType)

	SET	@startRun = GETDATE();  
	
	IF	@CustList <> ''
	BEGIN
		-- For read xml					
		EXECUTE	sp_xml_preparedocument @DocHandler OUTPUT, @CustList

		INSERT INTO	#tmpCust (CustID, SportType)
		SELECT	Data.c
			,	Data.s
		FROM OPENXML (@DocHandler, '/Notify/row', 1) 
		WITH (c INT, s TINYINT) AS Data;

		EXECUTE	sp_xml_removedocument @DocHandler;
		-- end read xml	
	END

	UPDATE his
	SET his.NotifiedStatus = 2
	FROM dbo.BetMonitoring_CustTotalBet_History his WITH (ROWLOCK,UPDLOCK)
		INNER JOIN #tmpCust c ON c.CustID = his.CustID AND c.SportType = his.SportType

	--write log
	CREATE TABLE #log (CustID INT, LogValue	NVARCHAR(MAX), isFinished BIT CONSTRAINT DF_#log_isFinished DEFAULT 0)

	-- Log data for each customer
	DECLARE	@CustID			INT,
			@LogSPData		NVARCHAR(MAX) = '';
	
	INSERT INTO #log(CustID, LogValue, isFinished)
	SELECT	CAST(tv.CustID AS INT)
		,	(	SELECT	s.SportName	AS '@Sport'
					,	1			AS '@NotifiedStatus'
				FOR XML PATH ('NAP_BetMonitoring_NotifiedCustomerListUpd')
			)
		,	0
	FROM #tmpCust AS tv
		INNER JOIN bodb02.dbo.Sports s ON s.SportType = tv.SportType

	SET	@endRun = GETDATE();
	SET	@duration = DATEDIFF(MILLISECOND, @startRun, @endRun);

	WHILE 0 = 0
	BEGIN
	    UPDATE	TOP(1) #log
		SET	isFinished = 1
		,	@CustID = CustID
		,	@LogSPData = LogValue
		WHERE	isFinished = 0;

		IF	@@ROWCOUNT = 0
			BREAK;

		BEGIN TRY
			EXECUTE	DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
						@UserID = 8
					,	@CustID = @CustID
					,	@ActionID = 31401
					,	@TrackingValue = @LogSPData
					,	@Duration = @duration;			
		END TRY
		BEGIN CATCH
			EXECUTE	DBTXN.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP
						@UserID = 8
					,	@CustID = @CustID
					,	@ActionID = 31401
					,	@TrackingValue = @LogSPData
					,	@Duration = @duration;
		END CATCH;
	END;

	DROP TABLE #log;
END
GO