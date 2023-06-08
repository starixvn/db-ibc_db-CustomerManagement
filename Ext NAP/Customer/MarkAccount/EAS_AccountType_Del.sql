/*<info serverAlias="DBCUST-CUSTDB" executers="bodbExtAccNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_AccountType_Del]
	  @UserID	INT
	, @CustID	INT
	, @ErrCode	INT=0				OUTPUT
	, @ErrMsg	NVARCHAR(200)=''	OUTPUT
	, @IP		VARCHAR(20)=''
AS
/*
	Creator: 20230525@Tacy  
	Task : Unmark account
	DB: DBCUST/CustDB

	Revisions:  
		- 20230525@Tacy: Ext NAP - Function for Headline to provide customer class based on their knowledge [Redmine:#188025]
	
	Param's Explanation:

	Example:	
*/		
BEGIN
    SET NOCOUNT ON

	DECLARE	  @StartRun		DATETIME
			, @EndRun		DATETIME
			, @Duration		INT
			, @logSpData	NVARCHAR(MAX)

	SET @StartRun=GETDATE()

	IF NOT EXISTS (SELECT 1 FROM Acc_CustType WITH (NOLOCK) WHERE CustID=@CustID)
		RETURN

	SELECT @logSpData = (
		SELECT CustID,
				COALESCE (CAST (@IP AS VARCHAR(20)), SPACE (1)) AS IP
		FROM Acc_CustType WITH (NOLOCK) 
		WHERE CustID=@CustID
		FOR XML RAW('Root'))
	
	BEGIN TRY
		DELETE FROM Acc_CustType WITH (ROWLOCK)
		WHERE CustID=@CustID
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = @@ERROR, @ErrMsg = ERROR_MESSAGE()
		RETURN
	END CATCH

	--Write Log:
	SELECT @EndRun	= GETDATE(), @Duration = DATEDIFF(MILLISECOND, @StartRun, @EndRun)
	
	EXEC  Acc_WriteLog_UserLog_RunSP_Wrapper
					@UserID = @UserID,
					@CustID = @CustID,
					@ActionID = 20405,
					@TrackingValue = @LogSPData,
					@duration = @Duration
END
GO