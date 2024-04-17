/*<info serverAlias="DBCUST-NAP_UserControl" executers="wsv_xnap" viewers="" isFunction="0"></info>*/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE EAS_WriteLog_UserLog_UserControl_Wrapper
	@CustID INT,
    @TrackingValue NVARCHAR(MAX),
    @UserID INT = NULL,
    @TypeID TINYINT=0,
    @ActionID INT=NULL,
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
		EXEC DBLOG.bodb_CustomerLog.[dbo].[EAS_WriteLog_UserLog_UserControl]
			@CustID = @CustID,
			@TrackingValue = @TrackingValue,
			@UserID = @UserID,
			@TypeID = @TypeID,
			@ActionID = @ActionID,
			@Duration = @Duration
	END TRY
	BEGIN CATCH
		EXEC bodb_CustomerLog.[dbo].[EAS_WriteLog_UserLog_UserControl]
			@CustID = @CustID,
			@TrackingValue = @TrackingValue,
			@UserID = @UserID,
			@TypeID = @TypeID,
			@ActionID = @ActionID,
			@Duration = @Duration
	END CATCH
END
GO
