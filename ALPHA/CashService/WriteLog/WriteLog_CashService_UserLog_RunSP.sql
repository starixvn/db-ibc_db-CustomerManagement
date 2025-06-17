/*<info serverAlias="DBCUST-bodb_CustomerLog,DBLOG-bodb_CustomerLog" executers="wsv_CashService,asv_CashService" viewers="" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE WriteLog_CashService_UserLog_RunSP
	@UserID			 INT
    , @CustID			 INT		   = 0
    , @ActionID			 INT		   = NULL
    , @TrackingValue		 NVARCHAR(MAX) = NULL
    , @TrackingValue2		 NVARCHAR(MAX) = NULL
    , @TrackingValueMask	 NVARCHAR(MAX) = NULL
    , @TrackingValueMask2	 NVARCHAR(MAX) = NULL
    , @Duration			 INT		   = NULL	
/* 
    Created: Helios
    Task: ViewLog function 331
    DB: bodb_CustomerLog

	Revisions:
		- 20250321@Helios: Agency Cash Service [Redmine: #223896]     
		- 20250603@Max: Add more account permission [Redmine: #223896]   

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
	DECLARE @Site VARCHAR(10)
	DECLARE @LogID BIGINT,
		 @LogDate DATETIME = GETDATE()
	
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
							@LogDate,
							@CustID,
							@ActionId, 
							@TrackingValue,
							@TrackingValueMask,
							@Duration,
							@TrackingValue2,
							@TrackingValueMask2,
							GETDATE ()					
							)
		
	SET @LogID = SCOPE_IDENTITY()
END
GO