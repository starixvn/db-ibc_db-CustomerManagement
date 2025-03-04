/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_xnap" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[EAS_AccountType_Upd]
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
	Task : Update account type
	DB: DBCUST/CustDB

	Revisions:  
		- 20230525@Tacy: Ext NAP - Function for Headline to provide customer class based on their knowledge [Redmine:#188025]
		- 20241230@July: Scale Out DBCUST - Apply Inhouse replication for the remaning tables [Redmine: #215627]
	
	Param's Explanation:

	Example:	
*/		
BEGIN
    SET NOCOUNT ON

	DECLARE	  @StartRun		 DATETIME
			, @EndRun		 DATETIME
			, @Duration		 INT
			, @logSpData	 NVARCHAR(MAX)
			, @logSpData_Old NVARCHAR(MAX)=NULL

	IF NOT EXISTS (SELECT 1 FROM Acc_CustType WITH (NOLOCK) WHERE CustID=@CustID)
	BEGIN
		-- Mark account
		EXEC EAS_AccountType_Ins 
			  @UserID=@UserID
			, @CustID=@CustID
			, @TypeID=@TypeID
			, @Remark=@Remark
			, @ErrCode=@ErrCode OUTPUT
			, @ErrMsg=@ErrMsg OUTPUT
			, @IP=@IP	
		
		IF @ErrCode<>0
			RETURN

		RETURN
	END

	SET @StartRun=GETDATE()

	SELECT @logSpData_Old = (
		SELECT CustID AS CustID, 
				TypeID AS TypeID,
				COALESCE (CAST (remark AS NVARCHAR(2000)), SPACE (1)) AS Remark,
				COALESCE (CAST (@IP AS VARCHAR(20)), SPACE (1)) AS IP
		FROM Acc_CustType WITH (NOLOCK) 
		WHERE CustID=@CustID
		FOR XML RAW('Root'))

	BEGIN TRY
		UPDATE ct
		SET TypeID=@TypeID
			,Remark=@Remark
			,RepUpdateTime = dbo.f_GetDateTime2()
		FROM Acc_CustType ct WITH (ROWLOCK, UPDLOCK)
		WHERE CustID=@CustID
	END TRY
	BEGIN CATCH
		SELECT @ErrCode = @@ERROR, @ErrMsg = ERROR_MESSAGE()

		RETURN
	END CATCH

	SELECT @logSpData = (
		SELECT  @CustID AS CustID, 
				@TypeID AS TypeID,
				COALESCE (CAST (@Remark AS NVARCHAR(2000)), SPACE (1)) AS Remark,
				COALESCE (CAST (@IP AS VARCHAR(20)), SPACE (1)) AS IP
		FOR XML RAW('Root'))

	--Write Log:
	SELECT @EndRun	= GETDATE(), @Duration = DATEDIFF(MILLISECOND, @StartRun, @EndRun)
	
	EXEC  Acc_WriteLog_UserLog_RunSP_Wrapper
					@UserID = @UserID,
					@CustID = @CustID,
					@ActionID = 20404,
					@TrackingValue = @LogSPData,
					@TrackingValue2= @logSpData_Old,
					@duration = @Duration
END
GO