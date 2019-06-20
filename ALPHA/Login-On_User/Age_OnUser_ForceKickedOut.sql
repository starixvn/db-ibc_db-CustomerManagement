/*<info serverAlias="DBONUSER-ON_USER" executers="bodbAdminNet,bodbExtAccNet,bodbDownlineNet, bodbDownlineNetView" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_OnUser_ForceKickedout]
	@CustID INT,	
	@roleid TINYINT,		
	@ServerID int = 0,
	@SubAccID INT = 0, 
	@IP VARCHAR(20) = ''
AS
/*
	Created: 20190612@Johnson
	Task : force kick out user after upline change pwd [RedmineID: #114566]
	DB: DBONUSER/ON_USER
	Original:

	Revisions:
		- 20190612@Johnson: initial sp [redmine:#114566]
	Param's Explanation:
*/
BEGIN
	SET NOCOUNT ON
	
	IF @roleid = 1
	BEGIN
		DECLARE @Begin		DATETIME,
				@End		DATETIME,
				@Duration	INT,				
				@LogData 	NVARCHAR(200),
				@rowcount 	INT
				
		SET @Begin = GETDATE()

		DELETE FROM dbo.ON_USER with (rowlock)		
		WHERE custid = @custid
		
		SELECT @rowcount = @@rowcount
			
		-- delete use nickname login user
		DELETE FROM dbo.tmp_Username2 with (rowlock)
		WHERE custid = @custid
		
		IF @rowcount > 0
		BEGIN
			SELECT @LogData = 'Kick out reason: Password has been changed.'
	
			SET @End = GETDATE()
			SET @Duration = DATEDIFF(millisecond,@Begin,@End)
			
			EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login 
				 @UserID = @CustID, 
				 @RoleID = @RoleID, 
				 @SubAccID = 0,
				 @ServerID = @ServerID,
				 @LoginIP = @IP,
				 @ActionID = 1331,
				 @Doing = @LogData,
				 @Duration = @Duration
		END
			 
	END
	ELSE 
	BEGIN
		UPDATE t
		SET iskickedout = 1,
			kickOutReason = 1
		FROM(			
			SELECT top (1) *
			FROM dbo.on_user_agent WITH (ROWLOCK, UPDLOCK)
			WHERE custid = @CustID AND subaccid = @SubAccID
			ORDER BY on_userid desc
		)t			
	END
END
GO