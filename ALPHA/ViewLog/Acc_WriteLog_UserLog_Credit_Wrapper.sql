/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet,bodbExtAccNet,bodbDownlineNet" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE [dbo].[Acc_WriteLog_UserLog_Credit_Wrapper]
	@UserID INT,
	@CustID INT = 0,
	@Doing VARCHAR(1000),
	@OldValue MONEY = NULL,
	@NewValue MONEY = NULL,
	@IP varchar(15)='',
	@ActionID int = NULL				
/* 
	Created: 20181212@Elodie
    Task: WriteLog function
    DB: DBCUST/CustDB

	Revisions:
		- 20181212@Elodie: Initial SP [Redmine: #105338]

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
		EXEC DBLOG.bodb_CustomerLog.dbo.WriteLog_UserLog_Credit
			@UserID = @UserID,
			@CustID = @CustID,
			@Doing = @Doing,
			@OldValue = @OldValue,
			@NewValue = @NewValue,
			@IP = @IP,
			@ActionID = @ActionID
	END TRY
	BEGIN CATCH
		EXEC bodb_CustomerLog.dbo.WriteLog_UserLog_Credit
			@UserID = @UserID,
			@CustID = @CustID,
			@Doing = @Doing,
			@OldValue = @OldValue,
			@NewValue = @NewValue,
			@IP = @IP,
			@ActionID = @ActionID
	END CATCH			
END
