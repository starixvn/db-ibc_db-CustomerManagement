/*<info serverAlias="DBCUST-NAP_UserControl" executers="bodbExtAccNet,wsv_xnap" viewers="" isFunction="0"></info>*/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE EAS_WriteLog_UserLog_Login_Wrapper 
	@UserID INT,  
    @LoginIP VARCHAR(50)='', 
	@ActionID int = 0, 
    @DomainName NVARCHAR(253) = NULL,
    @TrackingValue VARCHAR(300),
    @BrowserName NVARCHAR(255) = NULL,
    @Platform NVARCHAR(255) = NULL,
    @CountryCode VARCHAR(64) = NULL,
    @Duration INT = NULL
AS
	/* 
		Created: 20190423@Paul
		Task: 
		DB: DBCUST/NAP_UserControl
	
		Revisions:
			- 20190423@Paul: Migrate bodb_EAS to DBCUST [Redmine:#111865]

		Param's Explaination:    
	*/
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    BEGIN TRY
		EXEC DBLOG.bodb_customerlog.dbo.EAS_WriteLog_UserLog_Login 
			@UserID = @UserID, 		
			@LoginIP = @LoginIP,
			@ActionID = @ActionID,	 
			@TrackingValue = @TrackingValue,
			@Duration = @Duration
	END TRY
	BEGIN CATCH
		EXEC bodb_customerlog.dbo.EAS_WriteLog_UserLog_Login 
			@UserID = @UserID, 		
			@LoginIP = @LoginIP,
			@ActionID = @ActionID,	 
			@TrackingValue = @TrackingValue,
			@Duration = @Duration
	END CATCH
END
GO
