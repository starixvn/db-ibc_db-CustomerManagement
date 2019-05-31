/*<info serverAlias="DBCUST-bodb_CustomerLog,DBLOG-bodb_CustomerLog" executers="bodbAdminNet,bodbDownlineNet,bodbExtAccNet" viewers="" isFunction="0" isNested="1"></info>*/

CREATE PROCEDURE [dbo].[CS_WriteLog_UserLog_Login]
	@UserID int,   
	@RoleID tinyint,   
	@SubAccID int,   
	@ServerID int,   
	@LoginIP VARCHAR(20)='', 
	@DomainName NVARCHAR(253) = NULL,
	@ActionID int = 0,  
	@Doing VARCHAR(300),
	@BrowserName NVARCHAR(255) = NULL,
	@Platform NVARCHAR(255) = NULL,
	@CountryCode VARCHAR(64) = NULL,
	@Duration INT = NULL	,
	@NickName VARCHAR(50) = NULL	 
AS  
/*  
	Creator: 20190530@Paul
	Task:
	DB: DBCUST-bodb_CustomerLog, DBLOG-bodb_CustomerLog
	Original:   
  
	Revisions:  
		- 20190530@Paul: Insert log when user login [Redmine: #113198]

	Param's Explanation:  
*/  
  
BEGIN
	SET NOCOUNT ON  
  
	INSERT INTO dbo.CS_UserLog_Login(
		UserID,
		RoleID,
		SubAccID,
		ServerID,
		IP,
		ActionID,
		Doing,
		DomainName,
		BrowserName,
		Platform,
		CountryCode,
		Duration,
		username2
    )   
    VALUES( 
		@UserID,   
        ISNULL(@RoleID,0),   
        isnull(@SubAccID,0),   
        @ServerID,  
		@LoginIP,    
        @ActionID,   
        @Doing,
		@DomainName,
		@BrowserName,
		@Platform,
		@CountryCode,
		@Duration ,
		@NickName
    )  
END

GO