/*<info serverAlias="DBONUSER-ON_USER" executers="bodbDownlineNet,wsv_alp, bodbDownlineNetView,wsv_alpv" viewers="" isFunction="0"></info>*/

ALTER PROCEDURE CS_CheckOut
	@On_UserID int,
	@UserName varchar(30) = NULL,
	@RoleID tinyint = NULL,
	@ServerID int = NULL,
	@Nickname varchar(50) = NULL,
	@Reason NVARCHAR(100) = '{LogOutSuccess}'
AS
/*
	Created: 20190518@Elodie
	Task : Agent logout
	DB: DBONUSER/ON_USER

	Revisions:		
		- 20190422@Elodie: Offer unique nickname for CN88 [Redmine: 112287]
		- 20190606@Elodie: Apply new structure for CN88's log [Redmine: #113198]
		- 20190715@Elodie: Support Chinese log [Redmine:#116317]

	Param's Explanation:
		
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @Begin DATETIME, @End DATETIME, @Duration INT
	Declare @CustID int, @LoginIP varchar(20), @SubAccID int, @LogData nvarchar(200), @Role varchar(20), @db_Username2 VARCHAR(50)

	SET @Begin = GETDATE()
	
	SELECT @CustID = 0 
	SELECT @db_Username2 = NickName FROM dbo.f_CS_GetNickName(@Nickname,1)

	SELECT @CustID = ISNULL(custid,0), @ServerID = isnull(@ServerID,ServerID), @LoginIP = IP, @SubAccID = ISNULL(SubAccID,0)
	FROM On_User_Agent (NOLOCK) 
	WHERE on_userid = @On_UserID

	SELECT @SubAccID = ISNULL(@SubAccID, 0)
	SELECT @LoginIP = ISNULL(@LoginIP, 0)

	--Original:On_UserUpdLogout
	UPDATE On_User_Agent WITH (ROWLOCK, UPDLOCK) 
	SET ServerID = 0
	WHERE on_userid = @On_UserID

	--don't write log for AdminLogin
	IF (@SubAccID <0)
	BEGIN
		RETURN
	END

	SELECT @Role = CASE @RoleID WHEN 0 THEN '{Headline}:' WHEN 1 THEN 'Customer:' WHEN 2 THEN '{Agent}:' WHEN 3 THEN '{MA}:' WHEN 4 THEN '{SMA}:' ELSE 'Unknown:' END  

	SELECT @LogData =  @Role + CASE WHEN isnull(@UserName,'') = '' THEN CAST(@custid AS VARCHAR(30)) ELSE @Username END + ' - ' + @Reason

	-- ***Check Sub-Account***  
	IF @SubAccID > 0  
	BEGIN
		SELECT @Role = CASE @RoleID WHEN 2 THEN '{SubAgent}:' WHEN 3 THEN '{SubMA}:' WHEN 4 THEN '{SubSMA}:' ELSE 'Unknown:' END  
		SELECT @LogData =  @Role + CASE WHEN isnull(@UserName,'') = '' THEN CAST(@custid AS VARCHAR(30)) ELSE @Username END + ' - ' + @Reason
	END

	SET @End = GETDATE()
	SET @Duration = DATEDIFF(millisecond,@Begin,@End)

	EXEC DBLOG.bodb_customerlog.dbo.CS_WriteLog_UserLog_Login
		 @UserID = @CustID, 
		 @RoleID = @RoleID, 
		 @SubAccID = @SubAccID,
		 @ServerID = @ServerID,
		 @LoginIP = @LoginIP,
		 @ActionID = 1330,
		 @Doing = @LogData,
		 @Duration = @Duration,
		 @Nickname = @db_Username2
END
