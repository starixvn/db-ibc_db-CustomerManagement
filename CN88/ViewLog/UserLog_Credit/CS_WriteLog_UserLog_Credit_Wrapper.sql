/*<info serverAlias="DBCUST-CustDB" executers="wsv_nap,bodbDownlineNet,wsv_alp,bodbExtAccNet,wsv_xnap" viewers="" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[CS_WriteLog_UserLog_Credit_Wrapper]
	@UserID INT,
	@CustID INT = 0,
	@SubAccID	INT,
	@Doing VARCHAR(500),
	@OldValue MONEY = NULL,
	@NewValue MONEY = NULL,
	@IP varchar(15)='',
	@ActionID int = NULL				
/* 
	Created: 20190530@Paul
    Task: WriteLog function
    DB: DBCUST/CustDB

	Revisions:
		- 20190530@Paul: Initial SP [Redmine: #113198]
		- 20191010@Elodie: Apply Service Broker [Redmine: #113382]

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

	-- SB Parameters -----
	DECLARE @SB_xml XML, @SB_currentDate DATETIME, @SB_Error BIT = 0
	SET @SB_currentDate = GETDATE()
	-- SB Parameters ----------

	-- Starting: Service Broke code --
	SET @SB_xml = (SELECT	
						@UserID	AS '@UserID'
						, @SubAccID	AS '@SubAccID'
						, @IP AS '@IP'
						, @SB_currentDate AS '@LogDate'
						, @ActionID	AS '@ActionID'
						, @Doing AS	'@Doing'
						, @CustID AS '@CustID'
						, @OldValue	AS '@OldValue'
						, @NewValue AS '@NewValue'			
					FOR XML PATH ('row')
					)
			
	EXEC bodb_CustomerLog.sb.CustomerLog_SendMessage @xml = @SB_xml, @functionName = 'UserLog_Others', @MessageType = 'MessageType_CustomerLog_CS_UserLog_Credit', @SB_Error = @SB_Error OUT
    
	IF @SB_Error = 1 
	BEGIN
		BEGIN TRY
			EXEC DBLOG.bodb_CustomerLog.dbo.CS_WriteLog_UserLog_Credit
				@UserID = @UserID,
				@CustID = @CustID,
				@SubAccID = @SubAccID,
				@Doing = @Doing,
				@OldValue = @OldValue,
				@NewValue = @NewValue,
				@IP = @IP,
				@ActionID = @ActionID
		END TRY
		BEGIN CATCH
			EXEC bodb_CustomerLog.dbo.CS_WriteLog_UserLog_Credit
				@UserID = @UserID,
				@CustID = @CustID,
				@SubAccID = @SubAccID,
				@Doing = @Doing,
				@OldValue = @OldValue,
				@NewValue = @NewValue,
				@IP = @IP,
				@ActionID = @ActionID
		END CATCH			
	END
END


GO


