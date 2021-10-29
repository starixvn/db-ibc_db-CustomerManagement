/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_LimitPTDaily_Del] 
	-- Add the parameters for the stored procedure here
	  @ProductID			TINYINT,
	  @CustID				INT,
	  @Currency				TINYINT,
	  @SiteID				INT,
	  @Type					TINYINT,
	  @UserId				INT = 0 
	, @IP					VARCHAR(15) = ''
	, @ErrCode				INT				= 0		OUTPUT
	, @ErrMsg				NVARCHAR(200)	= ''	OUTPUT
AS
/*
		Task : NAP CM -  Limit Daily PT Update
		DB: DBCUST/CustDB
		Original: 
		Revisions:
			- 20211027@Winfred: NAP CM -  Limit Daily PT Update [Redmine: #162476]
	*/
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @StartRun	DATETIME
		, @EndRun		DATETIME
		, @Duration		INT
		, @ProductName	VARCHAR(50)
		, @logSpData		 NVARCHAR(MAX)
	SET @startRun = GETDATE()
	SELECT	@ErrCode	= 0	,	@ErrMsg			= ''	
	
	-- Select ProductName
	SELECT @ProductName = p.ProductName
	FROM DBACC.bodb02.dbo.Products AS p WITH(NOLOCK)
	WHERE p.ProductID = @ProductID
		
	EXEC NAP_UserControl.dbo.NAP_User_CheckPermission 
		@UserId=@userid,
		@SiteKey='CustomerManagement',
		@FunctionKey='LimitDailyPTDel',
		@ErrCode=@ErrCode OUTPUT,
		@ErrMsg=@ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN

	IF NOT EXISTS( SELECT TOP 1 1 FROM LimitPTDailySetting t WITH(NOLOCK) 
							  WHERE t.ProductID = @ProductID AND Currency = @Currency AND SiteID = @SiteID AND CustID = @CustID)
	BEGIN
		SELECT @ErrCode = 1 ,
			@ErrMsg = 'The selected rule not exists .'

		RETURN
	END	
	BEGIN TRY
		
		DELETE t
		FROM LimitPTDailySetting t WITH(ROWLOCK,UPDLOCK)
		WHERE CustID = @CustID and ProductID = @ProductID AND SiteID = @SiteID AND Currency = @Currency
 	
	END TRY
	BEGIN CATCH
		SELECT  @ErrCode = ERROR_NUMBER(),@ErrMsg = ERROR_MESSAGE()
		RETURN
	END CATCH

	
	SELECT @LogSPData = '<NAP_LimitPTDaily_Del Product="'+ COALESCE(CAST(@ProductName AS VARCHAR(50)), SPACE(1)) + '" ' +
	                    'IP="'+ COALESCE(CAST(@IP as VARCHAR(20)),SPACE(1)) + '" ' +
						'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(400)),space(1)) + '" ' +
						'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" />'
						

	SELECT @EndRun	= GETDATE(), @Duration = DATEDIFF(MILLISECOND, @StartRun, @EndRun)

	EXEC  Acc_WriteLog_UserLog_RunSP_Wrapper
			@UserID = @UserID,
			@ActionID = 471,
			@TrackingValue = @LogSPData,
			@duration = @Duration

END
GO
