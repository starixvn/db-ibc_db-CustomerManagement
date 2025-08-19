/*<info serverAlias="DBCUST-bodb_CustomerLog,DBLOG-bodb_CustomerLog" executers="wsv_CashService,asv_CashService" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE WriteLog_CashService_UserLog_RunSP
	  @UserID				 INT = NULL
    , @CustID				 INT		   = 0
    , @ActionID				 INT		   = NULL
    , @TrackingValue		 NVARCHAR(MAX) = NULL
    , @TrackingValue2		 NVARCHAR(MAX) = NULL
    , @TrackingValueMask	 NVARCHAR(MAX) = NULL
    , @TrackingValueMask2	 NVARCHAR(MAX) = NULL
    , @Duration				 INT		   = NULL	
	, @LogData_Multiple		 NVARCHAR(MAX)  = NULL
	, @ErrCode				 INT = 0 OUTPUT
	, @ErrMsg				 VARCHAR(250) = '' OUTPUT
/* 
    Created: Helios
    Task: ViewLog function 331
    DB: bodb_CustomerLog

	Revisions:
		- 20250321@Helios: Agency Cash Service [Redmine: #223896]     
		- 20250603@Max: Add more account permission [Redmine: #223896]   
		- 20250805@Eden: Alpha - Agency Cash Service - Sprint 8 [redmine: #235012] 

    Param's Explaination:    	
		- @UserID: UserId perform this action
		- @CustID: 
		- @ActionID: Log action Id
		- @TrackingValue: xml string format
*/
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON   

	----MULTIPLE LOG-----------------
	DECLARE @BatchNum INT = 5000
	DECLARE @tmp_LogData AS TABLE (
		 UserID	INT
		,CustID	INT
		,ActionID INT
		,TrackingValue	VARCHAR(MAX)
		,TrackingValueMask	VARCHAR(MAX)
		,TrackingValue2	VARCHAR(MAX)
		,TrackingValueMask2	VARCHAR(MAX)
		,Duration INT
	)

	DECLARE @tmp_LogData_Batch AS TABLE (
		 UserID	INT
		,CustID	INT
		,ActionID INT
		,TrackingValue	VARCHAR(MAX)
		,TrackingValueMask	VARCHAR(MAX)
		,TrackingValue2	VARCHAR(MAX)
		,TrackingValueMask2	VARCHAR(MAX)
		,Duration INT
	)

	IF ISNULL(@LogData_Multiple,'') <> ''
	BEGIN
		BEGIN TRY
			-- Parse multiple rows from JSON array in @LogData_Multiple and insert each as a row
			INSERT INTO @tmp_LogData(
				UserID, 
				CustID,
				ActionID, 
				TrackingValue,
				TrackingValueMask,
				TrackingValue2,
				TrackingValueMask2,
				Duration	
			)
				SELECT
					TRY_CAST(JSON_VALUE(logItem.value, '$.UserID') AS INT) AS UserID,
					TRY_CAST(JSON_VALUE(logItem.value, '$.CustID') AS INT) AS CustID,
					TRY_CAST(JSON_VALUE(logItem.value, '$.ActionID') AS INT) AS ActionID,
					TRY_CAST(JSON_VALUE(logItem.value, '$.TrackingValue') AS VARCHAR(MAX)) AS TrackingValue,
					TRY_CAST(JSON_VALUE(logItem.value, '$.TrackingValueMask') AS VARCHAR(MAX)) AS TrackingValueMask,
					TRY_CAST(JSON_VALUE(logItem.value, '$.TrackingValue2') AS VARCHAR(MAX)) AS TrackingValue2,
					TRY_CAST(JSON_VALUE(logItem.value, '$.TrackingValueMask2') AS VARCHAR(MAX)) AS TrackingValueMask2,
					TRY_CAST(JSON_VALUE(logItem.value, '$.Duration') AS INT) AS Duration
				FROM OPENJSON(@LogData_Multiple) AS logItem
			
			WHILE 1 = 1
			BEGIN
				DELETE TOP (@BatchNum) t
				OUTPUT 
					Deleted.UserID, 
					Deleted.CustID,
					Deleted.ActionID, 
					Deleted.TrackingValue,
					Deleted.TrackingValueMask,
					Deleted.TrackingValue2,
					Deleted.TrackingValueMask2,
					Deleted.Duration	
				INTO @tmp_LogData_batch(
					UserID, 
					CustID,
					ActionID, 
					TrackingValue,
					TrackingValueMask,
					TrackingValue2,
					TrackingValueMask2,
					Duration	
				)
				FROM @tmp_LogData t

				IF @@ROWCOUNT = 0
					BREAK;
				
				-- Insert UserLog
				INSERT INTO dbo.Cash_UserLog_RunSP (
					UserID, 
					CustID,
					ActionID, 
					TrackingValue,
					TrackingValueMask,
					Duration,
					TrackingValue2,
					TrackingValueMask2,
					LogDate,
					CreatedDate			
				)
				SELECT 
					UserID, 
					CustID,
					ActionID,
					TrackingValue,
					TrackingValueMask,
					Duration,
					TrackingValue2,
					TrackingValueMask2,
					GETDATE(),
					GETDATE()
				FROM @tmp_LogData_Batch
				WHERE ActionID <> 0

				--Insert DBA Log
				INSERT INTO dbo.Cash_UserLog_RunSP_Detail(
					UserID, 
					CustID,
					TrackingValue,
					TrackingValueMask,
					Duration,
					TrackingValue2,
					TrackingValueMask2,
					LogDate	
				)
				SELECT 
					UserID, 
					CustID,
					TrackingValue,
					TrackingValueMask,
					Duration,
					TrackingValue2,
					TrackingValueMask2,
					GETDATE()
				FROM @tmp_LogData_Batch
				WHERE ISNULL(ActionID,0) = 0
			END
		END TRY
		BEGIN CATCH
			-- Handle any errors that occur during the insert
			SELECT @ErrCode = 101,
				@ErrMsg = 'Error inserting log data: ' + ERROR_MESSAGE();
		END CATCH
	END
	ELSE IF @ActionID <> 0
	BEGIN
		INSERT INTO dbo.Cash_UserLog_RunSP	(	
									userid
									, logdate
									, custid
									, ActionID
									, TrackingValue
									, TrackingValueMask
									, Duration
									, TrackingValue2
									, TrackingValueMask2
									, CreatedDate
								)
						VALUES (	@UserID, 
								GETDATE(),
								@CustID,
								@ActionId, 
								@TrackingValue,
								@TrackingValueMask,
								@Duration,
								@TrackingValue2,
								@TrackingValueMask2,
								GETDATE ()					
								)
	END
	ELSE -- Log detail for DBA trace issue only
	BEGIN
		INSERT INTO dbo.Cash_UserLog_RunSP_Detail(	
									  userid
									, logdate
									, custid
									, TrackingValue
									, TrackingValueMask
									, Duration
									, TrackingValue2
									, TrackingValueMask2
				)
		VALUES (
				@UserID, 
				GETDATE(),
				@CustID,
				@TrackingValue,
				@TrackingValueMask,
				@Duration,
				@TrackingValue2,
				@TrackingValueMask2				
				)
	END
	
END
GO