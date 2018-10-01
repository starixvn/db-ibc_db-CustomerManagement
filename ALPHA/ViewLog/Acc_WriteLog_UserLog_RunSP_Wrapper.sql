/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet,bodbExtAccNet,bodbDownlineNet" viewers="vnteam" isFunction="0"></info>*/
USE CustDB
GO

ALTER PROCEDURE [dbo].[Acc_WriteLog_UserLog_RunSP_Wrapper]
		@UserID INT,
		@CustID INT = 0,
		@ActionID INT = NULL,	
		@TrackingValue nvarchar(MAX)= NULL,
		@TrackingValue2 nvarchar(MAX) = NULL,
		@Duration INT = NULL
		
/* 
	Created: 20180924@Elodie
    Task: ViewLog function
    DB: DBCUST/bodb_Licensee

	Revisions:
		- 20180924@Elodie: Migrate bodb_Licensee to DBCUST [Redmine:#99855]

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

	BEGIN TRY
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
			@UserID = @UserID,
			@CustID = @CustID,
			@ActionID = @ActionID,
			@TrackingValue = @TrackingValue,
			@TrackingValue2 = @TrackingValue2,
			@Duration = @Duration
	END TRY
	BEGIN CATCH
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_RunSP 
			@UserID = @UserID,
			@CustID = @CustID,
			@ActionID = @ActionID,
			@TrackingValue = @TrackingValue,
			@TrackingValue2 = @TrackingValue2,
			@Duration = @Duration
	END CATCH			
END
GO

