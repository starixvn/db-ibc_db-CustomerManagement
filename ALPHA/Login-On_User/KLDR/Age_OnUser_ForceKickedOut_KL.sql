/*<info serverAlias="DBONUSER-ON_USER" executers="bodbAdminNet,bodbExtAccNet,bodbDownlineNet, bodbDownlineNetView" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Age_OnUser_ForceKickedout_KL]
	@CustID INT,	
	@roleid TINYINT,		
	@ServerID int = 0,
	@SubAccID INT = 0, 
	@IP VARCHAR(20) = '',
	@Mode VARCHAR(50) = 'ChangePassWord'
AS
/*
	Created: 20190612@Johnson
	Task : force kick out user after upline change pwd [RedmineID: #114566]
	DB: DBONUSER/ON_USER
	Original:

	Revisions:
		- 20190612@Johnson: initial sp [redmine:#114566]
		- 20210824@Elodie: Force log out main and sub account when protection mode is changed [Redmine:#160151]
		- 20231218@Johnson: setup KL DR [redmine: #195700]
	Param's Explanation:
*/
BEGIN
	SET NOCOUNT ON
	
	RETURN
	/*
	IF @Mode = 'ChangePassWord'
	BEGIN
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
			
			IF @@rowcount > 0
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
	END
	ELSE IF @Mode = 'ChangeProtectionMode'
	BEGIN
		IF @RoleId <> 1
		BEGIN
			UPDATE a
			SET iskickedout = 1,
				kickOutReason = 2
			FROM on_user_agent a
				CROSS APPLY(SELECT top (1) oa.*
							FROM dbo.on_user_agent oa WITH (ROWLOCK, UPDLOCK)
							WHERE oa.custid = a.custid AND oa.subaccid = a.subaccid
							ORDER BY on_userid desc
						)t	
			WHERE a.custid = @CustID

			IF @@rowcount > 0
			BEGIN
				SELECT @LogData = 'Kick out reason: Data protection mode has been turned on.'
	
				SET @End = GETDATE()
				SET @Duration = DATEDIFF(millisecond,@Begin,@End)

				EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login 
					@UserID = @CustId, 
					@RoleID = @RoleID, 
					@SubAccID = 0,
					@ServerID = @ServerID,
					@LoginIP = @IP,
					@ActionID = 1331,
					@Doing = @LogData,
					@Duration = @Duration
			END
		END
	END
	ELSE IF @Mode = 'ChangeProtectionModeByLogin'
	BEGIN
		IF @RoleId <> 1
		BEGIN
			UPDATE a
			SET iskickedout = 1,
				kickOutReason = 2
			FROM on_user_agent a
				CROSS APPLY(SELECT top (1) oa.*
							FROM dbo.on_user_agent oa WITH (ROWLOCK, UPDLOCK)
							WHERE oa.custid = a.custid AND oa.subaccid = a.subaccid
							ORDER BY on_userid desc
						)t	
			WHERE a.custid = @CustID AND a.SubAccId <> @SubAccID

			IF @@rowcount > 0
			BEGIN
				SELECT @LogData = 'Kick out reason: Data protection mode has been turned on.'
	
				SET @End = GETDATE()
				SET @Duration = DATEDIFF(millisecond,@Begin,@End)

				EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login 
					@UserID = @CustId, 
					@RoleID = @RoleID, 
					@SubAccID = 0,
					@ServerID = @ServerID,
					@LoginIP = @IP,
					@ActionID = 1331,
					@Doing = @LogData,
					@Duration = @Duration
			END
		END
	END*/
END
GO