/*<info serverAlias="DBCUST-bodb_CustomerLog,DBLOG-bodb_CustomerLog" executers="bodbAdminNet,bodbDownlineNet,bodbExtAccNet" viewers="" isFunction="0" isNested="1"></info>*/

CREATE PROCEDURE [dbo].[CS_WriteLog_UserLog_RunSP]
	@UserID INT,   
	@CustID	INT,   
	@SubAccID INT,   
	@ActionID INT = 0,  
	@Duration INT = NULL	,
	@TrackingValue NVARCHAR(MAX) = NULL,
	@TrackingValue2 NVARCHAR(MAX) = NULL,
	@AffectedDownlines VARCHAR(MAX) = NULL
AS  
/*  
	Creator: 20190605@Paul
	Task:
	DB: DBCUST-bodb_CustomerLog, DBLOG-bodb_CustomerLog
	Original:   
  
	Revisions:  
		- 20190605@Paul: Insert log when running SP [Redmine: #113198]

	Param's Explanation:  
*/  
  
BEGIN
	SET NOCOUNT ON  

	DECLARE @LogID BIGINT,
			@MultiTarget_LogID BIGINT,
			@LogDate DATETIME = GETDATE()

	CREATE TABLE #AffectedDownlines(CustID INT)
  
	INSERT INTO dbo.CS_UserLog_RunSP(
		UserID,
		LogDate,
		CustID,
		SubAccID,
		ActionID,
		TrackingValue,
		Duration,
		TrackingValue2
    )   
    VALUES( 
		@UserID,  
		@LogDate, 
        @CustID,   
        @SubAccID,   
        @ActionID,   
        @TrackingValue,
		@Duration,
		@TrackingValue2
    )  

	SET @LogID = SCOPE_IDENTITY()

	IF @ActionID = 165004
	BEGIN
		INSERT INTO #AffectedDownlines(CustID)
		SELECT CONVERT(INT, Val)
		FROM dbo.f_StringSplit(@AffectedDownlines, ',')
		OPTION(MAXRECURSION 0)

		INSERT INTO dbo.CS_UserLog_RunSP_MultiTarget (
			UserID,
			LogDate,
			ActionID,
			TrackingValue,
			Duration,
			TrackingValue2,
			MainLogID
		)
		VALUES (
			@UserID, 
			@LogDate,    
			@ActionID,   
			@TrackingValue,
			@Duration,
			@TrackingValue2,
			@LogID
		)

		SET @MultiTarget_LogID = SCOPE_IDENTITY()

		INSERT INTO dbo.CS_UserLog_RunSP_LogTarget (LogID, CustID)
		SELECT @MultiTarget_LogID, CustID
		FROM #AffectedDownlines
	END
END

GO