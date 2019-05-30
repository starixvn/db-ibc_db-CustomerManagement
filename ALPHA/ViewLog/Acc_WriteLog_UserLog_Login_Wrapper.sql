/*<info serverAlias="DBCUST-CustDB" executers="bodbDownlineNetView,bodbDownlineNet" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE Acc_WriteLog_UserLog_Login_Wrapper
    @UserID INT, 
	@RoleID TINYINT,
	@SubAccID INT,
    @ServerID INT,   
    @LoginIP VARCHAR(20)='', 
    @DomainName NVARCHAR(253) = NULL,
    @ActionID int = 0,  
    @Doing VARCHAR(300),
    @BrowserName NVARCHAR(255) = NULL,
    @Platform NVARCHAR(255) = NULL,
    @CountryCode VARCHAR(64) = NULL,
    @Duration INT = NULL,
	@Nickname VARCHAR(50) = NULL
AS  
/*  
	Creator: 20190516@Elodie 
	Task: Insert log when user login
	DB: DBCUST/CustDB
  
	Revisions:  
		- 20190516@Elodie: Insert log when user login
 
	Param's Explanation:  
		• @UserID: main account login.  
		• @ServerID: serverID.  
		• @DomainName: Domain user login.  
		• @LoginIP: IP user login.  
		• @BrowserName: Browser user using.  
		• @Platform: Platform user login. 
		• @CountryCode: CountryCode user login.  
		• @Duration: Time process login
*/  
BEGIN
	SET NOCOUNT ON 
	-- SB Parameters -----
	DECLARE @SB_xml XML, @SB_currentDate DATETIME, @SB_Error BIT = 0
	SET @SB_currentDate = GETDATE()
	-- SB Parameters ----------

	-- Starting: Service Broke code --
	SET @SB_xml = (SELECT	
						@UserID	AS '@UserID'
						, @RoleID AS '@RoleID'
						, @SubAccID	AS '@SubAccID'
						, @ServerID	AS '@ServerID'
						, @LoginIP AS '@IP'
						, @DomainName AS '@DomainName'
						, @SB_currentDate AS '@LogDate'
						, @ActionID	AS '@ActionID'
						, @Doing AS	'@Doing'
						, @BrowserName AS '@BrowserName'
						, @Platform	AS '@Platform'
						, @CountryCode AS '@CountryCode'
						, @Duration	AS '@Duration'
						, @Nickname AS '@Username2'				
					FOR XML PATH ('row')
					)
			
	EXEC bodb_CustomerLog.sb.CustomerLog_SendMessage @xml = @SB_xml, @MessageType='MessageType_CustomerLog_UserLog_Login', @SB_Error = @SB_Error out
	IF @SB_Error = 1 
	BEGIN
		BEGIN TRY
			EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_Login
				@UserID = @UserID, 
				@RoleID = @RoleID, 
				@SubAccID = @SubAccID,
				@ServerID = @ServerID,
				@LoginIP = @LoginIP,
				@DomainName = @DomainName,	
				@ActionID = @ActionID,
				@Doing = @Doing,
				@BrowserName = @BrowserName,
				@Platform = @Platform,
				@CountryCode = @CountryCode,
				@Duration = @Duration,
				@Nickname = @Nickname
		END TRY
		BEGIN CATCH
			EXEC bodb_customerlog.dbo.WriteLog_UserLog_Login
				@UserID = @UserID, 
				@RoleID = @RoleID, 
				@SubAccID = @SubAccID,
				@ServerID = @ServerID,
				@LoginIP = @LoginIP,
				@DomainName = @DomainName,	
				@ActionID = @ActionID,
				@Doing = @Doing,
				@BrowserName = @BrowserName,
				@Platform = @Platform,
				@CountryCode = @CountryCode,
				@Duration = @Duration,
				@Nickname = @Nickname
		END CATCH
	END
END  	

