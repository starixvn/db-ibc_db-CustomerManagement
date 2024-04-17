/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,wsv_nap,wsv_lap" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[NAP_LM_CustomerClassNonSportsEnable] 
	  @PolicyID			INT						 
	, @Enable			BIT
	, @UserID			INT
	, @IsTest			TINYINT	
	, @IP				VARCHAR(50)		= ''
	, @ErrCode			TINYINT			= 0		OUTPUT
	, @ErrMsg			NVARCHAR(MAX)	= ''	OUTPUT
AS
/*
	Created: Winfred
	Date: 20231002
	Task : [NAP CM] Customer Class - Support for Non-Sports
	DB: DBCUST/CustDB
	Original:

	Revisions:
		- 20231002@Winfred: [NAP CM] Customer Class - Support for Non-Sports [RedmineID: #186116] 

	Param's Explanation:

	Example: NAP_LM_CustomerClassNonSportsEnable @PolicyID = 15, @Enable = 1 , @ErrCode =0, @ErrMsg = '' , @IP = '11.12.11.10', @UserID = 6, @IsTest = 1
*/ 
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @StartRun	  DATETIME
		, @EndRun		  DATETIME
		, @Duration		  INT
		, @iDoc			  INT
		, @RuleID		  INT
		, @logSpData	  NVARCHAR(MAX)
		, @logSpData_Old   NVARCHAR(MAX)
		, @xml			  XML

	IF 	EXISTS(SELECT TOP 1 1 FROM CustomerClassNonSports a WITH(NOLOCK) WHERE a.IsTest <> @IsTest AND PolicyID = @PolicyID ) 
	BEGIN
		SELECT @ErrCode = 105 , @ErrMsg = 'Cannot update PROD data' 
		RETURN
	END	
		
	UPDATE a	
	SET	  a.Enable  =   @Enable 
		, a.[RepUpdateTime]=sysdatetime()
	FROM CustomerClassNonSports a WITH (ROWLOCK, UPDLOCK)
	WHERE a.PolicyID = @PolicyID

	-- Log new updated data
	SET @xml = (
			SELECT	@PolicyID					AS '@PolicyID',	
					@UserID						AS '@UserID',
					@IP							AS '@IP',
					@Enable						AS '@Enable',
					@IsTest						AS '@IsTest',			
					COALESCE(CAST(@ErrMsg	AS VARCHAR(400)),SPACE(1))	AS '@ErrMsg',
					COALESCE(CAST(@ErrCode	AS VARCHAR(50)),SPACE(1))	AS '@ErrCode'
			FOR XML PATH('R'),
			TYPE
		)
	SET @logSpData_Old = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')
	SET @xml = (
			SELECT	@PolicyID					AS '@PolicyID',		
					@UserID						AS '@UserID',
					@IP							AS '@IP',
					CASE WHEN @Enable = 1 
						THEN 0 ELSE 1 END		AS '@Enable',
					@IsTest						AS '@IsTest',			
					COALESCE(CAST(@ErrMsg	AS VARCHAR(400)),SPACE(1))	AS '@ErrMsg',
					COALESCE(CAST(@ErrCode	AS VARCHAR(50)),SPACE(1))	AS '@ErrCode'
			FOR XML PATH('R'),
			TYPE
		)
	SET @logSpData = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"')

	SELECT @EndRun	= GETDATE(), @Duration = DATEDIFF(MILLISECOND, @StartRun, @EndRun)

	EXEC  Acc_WriteLog_UserLog_RunSP_Wrapper
				@CustID  = @UserID,
				@UserID = @UserID,
				@ActionID = 31918,
				@TrackingValue = @LogSPData,
			    @TrackingValue2 = @logSpData_Old,
				@duration = @Duration
END
GO
