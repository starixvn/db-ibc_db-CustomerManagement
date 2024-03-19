/*<info serverAlias="DBCUST-CUSTDB" executers="bodbAdminNet,wsv_nap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_UMTool_Configuration_Del_OldData]
	 @UserId		INT = 0
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		VARCHAR(200) = '' OUTPUT
AS
BEGIN
/*
	Created: 20201002@Eden
	Task :  Delete old Data of UMConfig
	DB: DBCUST.CustDB
	Revisions:	
		- 20201002@Eden: Minimize UM Time - Backend UM tool [Redmine: #142142]

	Param's Explanation:   
		
	Examples : 
		DECLARE  @ErrCode	INT = 0 ,@ErrMsg VARCHAR(200) = ''
		EXEC [Acc_UMTool_Configuration_Del_OldData] 
			@UserID			= 8
*/
SET NOCOUNT ON	
	DECLARE @StartRun DATETIME, @EndRun DATETIME, @Duration INT
	SET @StartRun = GETDATE()

	DECLARE @UMConfig TABLE (
		[FunctionType] [tinyint],
		[ProductID] [tinyint] ,
		[SportType] [smallint] ,
		[BetType] [smallint] default 0,
		[IsLive] [bit] default 0,
		[SettingType] [tinyint],
		[SiteID] [int],
		[Currency] [int],
		[SuperID] [int],
		[BeginTime]	[smalldatetime],
		[EndTime] [smalldatetime],
		[ShowTime] [smalldatetime],
		[LockAddingNew]	[bit]
	)

	DELETE c
	OUTPUT deleted.ProductID,deleted.SportType,deleted.BetType,deleted.IsLive,deleted.SettingType,deleted.FunctionType,deleted.SiteID,deleted.Currency,deleted.SuperID,deleted.BeginTime,deleted.EndTime,deleted.ShowTime,deleted.LockAddingNew
	INTO @UMConfig(ProductID,SportType,BetType,IsLive,SettingType,FunctionType,SiteID,Currency,SuperID,BeginTime,EndTime,ShowTime,LockAddingNew)
	FROM  UMConfig c WITH(ROWLOCK)
	WHERE c.EndTime < CONVERT(smalldatetime,GETDATE())

	IF NOT EXISTS( SELECT 1 FROM @UMConfig)
	BEGIN
		--SELECT @ErrCode = 1, 
		--	@ErrMsg = 'Not exists old Data'
		RETURN
	END

	SET @EndRun = GETDATE()
	SET @Duration = DATEDIFF (MILLISECOND, @StartRun, @EndRun)

	DECLARE @LogData VARCHAR(MAX)

	SELECT @LogData = CONVERT( VARCHAR(MAX), 
			(	SELECT   ProductID		AS '@ProductID'
						,SportType		AS '@SportType'
						,BetType		AS '@BetType'
						,IsLive			AS '@IsLive'
						,SettingType	AS '@SettingType'
						,FunctionType	AS '@FunctionType'
						,SiteID			AS '@SiteID'
						,Currency		AS '@Currency'
						,SuperID		AS '@SuperID'
						,BeginTime		AS '@BeginTime'
						,EndTime		AS '@EndTime'
						,ShowTime		AS '@ShowTime'
						,LockAddingNew	AS '@LockAddingNew'
				FROM @UMConfig
				FOR XML PATH('Row'), ROOT ('R'), TYPE)
		)

	--Write log:
	EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
				@UserId				= @UserId,
				@CustId				= 0,
				@ActionId			= 210004,
				@TrackingValue		= @LogData,
				@Duration			= @Duration

END