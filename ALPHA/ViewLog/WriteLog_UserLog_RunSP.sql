/*<info serverAlias="DBCUST-bodb_CustomerLog,DBLOG-bodb_CustomerLog" executers="bodbAdminNet,bodbDownlineNet,bodbExtAccNet,bodbDownlineNetView,Dot_Admin,bodbLicenseeNet" viewers="" isFunction="0" isNested="1"></info>*/

ALTER PROCEDURE [dbo].[WriteLog_UserLog_RunSP]
		@UserID INT,
		@CustID INT = 0,
		@SubAccID INT = 0,
		@SPName VARCHAR(50)= NULL, -- USE FOR OLD FORMAT AND WILL REMOVE LATER
		@Doing	VARCHAR(4000) = NULL, --
		@ActionID INT = NULL,	
		@TrackingValue nvarchar(MAX)= NULL,
		@TrackingValue2 nvarchar(MAX) = NULL,
		@Duration INT = NULL,
		@AffectedDownlines VARCHAR(MAX) = NULL		
/* 
	Created:
    Task: ViewLog function 331
    DB: bodb_CustomerLog

	Revisions:
		- 20100102@Lewin: Write xml tracking value to dbo.UserLog_RunSP 	  
		- 20101019@Henry: add one more parameter: @Duration   
		- 20110519@Johnson: add new column TrackingValue2
		- 20190606@Elodie: Apply new structure for CN88's log [Redmine: #113198]
		- 20200218@Elodie: Add multitarget log [Redmine: #127446]

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
			@MultiTarget_LogID BIGINT,
			@LogDate DATETIME = GETDATE()
	CREATE TABLE #AffectedDownlines(CustID INT)

	SELECT @Site = Site FROM bodb02.dbo.Customer WITH (NOLOCK) WHERE custid = @CustID

	IF @Site = 'CN88'
	BEGIN
		INSERT INTO dbo.CS_UserLog_RunSP(UserID, 
										CustID, 
										SubAccID,
										ActionID, 
										TrackingValue,
										TrackingValue2,
										Duration
										)
							  VALUES (	@UserID, 
										@CustID, 
										@SubAccID,
										@ActionId, 
										@TrackingValue,
										@TrackingValue2,
										@Duration
										)
	END
	ELSE
	BEGIN
		INSERT INTO dbo.UserLog_RunSP(	UserID, 
										CustID, 
										SPName,
										Doing,
										ActionID, 
										TrackingValue,
										TrackingValue2,
										Duration
										)
							  VALUES (	@UserID, 
										@CustID, 
										@SPName,
										@Doing,
										@ActionId, 
										@TrackingValue,
										@TrackingValue2,
										@Duration
										)
		
		SET @LogID = SCOPE_IDENTITY()

		IF ISNULL(@AffectedDownlines,'') <> ''
		BEGIN	
			INSERT INTO dbo.UserLog_RunSP_MultiTarget (
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

			INSERT INTO #AffectedDownlines(CustID)
			SELECT CONVERT(INT, Val)
			FROM dbo.f_StringSplit(@AffectedDownlines, ',')
			OPTION(MAXRECURSION 0)

			INSERT INTO dbo.UserLog_RunSP_LogTarget (LogID, CustID, LogDate)
			SELECT @MultiTarget_LogID, CustID, @LogDate
			FROM #AffectedDownlines
		END												
	END
END
