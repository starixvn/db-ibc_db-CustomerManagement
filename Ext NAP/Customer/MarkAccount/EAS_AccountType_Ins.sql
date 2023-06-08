/*<info serverAlias="DBCUST-CUSTDB" executers="bodbExtAccNet" viewers="" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[EAS_AccountType_Ins]
	  @UserID	INT
	, @CustID	INT
	, @TypeID	TINYINT
	, @Remark	NVARCHAR(2000)=NULL
	, @ErrCode	INT=0				OUTPUT
	, @ErrMsg	NVARCHAR(200)=''	OUTPUT
	, @IP		VARCHAR(20)=''	
AS
/*
	Creator: 20230525@Tacy  
	Task : Mark account type.
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
	
	BEGIN TRY
		INSERT INTO Acc_CustType (CustID, TypeID, Remark)
		SELECT @CustID, @TypeID, @Remark
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = @@ERROR, @ErrMsg = ERROR_MESSAGE()
		RETURN
	END CATCH

	--Write Log:
	SELECT @logSpData = (
		SELECT  @CustID AS CustID, 
				@TypeID AS TypeID,
				COALESCE (CAST (@Remark AS NVARCHAR(2000)), SPACE (1)) AS Remark,
				COALESCE (CAST (@IP AS VARCHAR(20)), SPACE (1)) AS IP
		FOR XML RAW('Root'))

	SELECT @EndRun	= GETDATE(), @Duration = DATEDIFF(MILLISECOND, @StartRun, @EndRun)
	
	EXEC  Acc_WriteLog_UserLog_RunSP_Wrapper
					@UserID = @UserID,
					@CustID = @CustID,
					@ActionID = 20403,
					@TrackingValue = @LogSPData,
					@duration = @Duration
END
GO