/*<info serverAlias="DBCUST-NAP_UserControl" executers="bodbExtAccNet" viewers="" isFunction="0"></info>*/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE WriteLog_UserLog_RunSP_Wrapper 
	@UserID INT,
	@CustID INT = 0,
	@SPName VARCHAR(50)= NULL,
	@Doing	VARCHAR(4000) = NULL,
	@ActionID INT = NULL,
	@TrackingValue nvarchar(MAX)= NULL,
	@TrackingValue2 nvarchar(MAX) = NULL,
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
		EXEC DBLOG.bodb_customerlog.dbo.WriteLog_UserLog_RunSP 
			@UserID			= @UserID, 
			@CustID			= @CustID,				
			@ActionID		= @ActionID, 
			@TrackingValue	= @TrackingValue, 
			@duration		= @duration
	END TRY
	BEGIN CATCH
		EXEC bodb_customerlog.dbo.WriteLog_UserLog_RunSP 
			@UserID			= @UserID, 
			@CustID			= @CustID,				
			@ActionID		= @ActionID, 
			@TrackingValue	= @TrackingValue, 
			@duration		= @duration
	END CATCH
END
GO
