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
			- 20230508@Luke: Add log when user limit PT update by Site/Currency [Redmine: #186741]
			- 20230620@Luke: Limitation to update PT for new member [Redmine: #188950]

	*/
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @StartRun			DATETIME
		, @EndRun				DATETIME
		, @Duration				INT
		, @ProductName			VARCHAR(50)
		, @logSpData			NVARCHAR(MAX)
		, @site					NVARCHAR(50)
		, @currencyName			NVARCHAR(50)
		, @SettingStatus		TINYINT = 0
		, @TypeName				NVARCHAR(50)
		, @LimitNewAccUpdPT		BIT
	SET @startRun = GETDATE()
	SELECT	@ErrCode	= 0	,	@ErrMsg			= ''	
	
	-- Select ProductName
	SELECT @ProductName = p.ProductName
	FROM DBACC.bodb02.dbo.Products AS p WITH(NOLOCK)
	WHERE p.ProductID = @ProductID

	If 	@SiteID = 0
	BEGIN
		SET @site = 'All sites'
	END
	ELSE
	BEGIN
		SELECT @site = site FROM Site WITH(NOLOCK) WHERE siteid = @SiteID
	END	

	If 	@Currency = 0
	BEGIN
		SET @currencyName = 'All currencies'
	END
	ELSE
	BEGIN
		SELECT @currencyName = currency FROM exchange WITH(NOLOCK) WHERE ExchangeId = @Currency
	END	
		
	IF NOT EXISTS( SELECT TOP 1 1 FROM LimitPTDailySetting t WITH(NOLOCK) 
							  WHERE t.ProductID = @ProductID AND Currency = @Currency AND SiteID = @SiteID AND CustID = @CustID)
	BEGIN
		SELECT @ErrCode = 1 ,
			@ErrMsg = 'The selected rule not exists .'

		RETURN
	END	
	BEGIN TRY
		SELECT @SettingStatus = SettingStatus, @LimitNewAccUpdPT = LimitNewAccUpdPT FROM LimitPTDailySetting t WITH(ROWLOCK,UPDLOCK)
		WHERE CustID = @CustID and ProductID = @ProductID AND SiteID = @SiteID AND Currency = @Currency AND Type  = @Type
		
		DELETE t
		FROM LimitPTDailySetting t WITH(ROWLOCK,UPDLOCK)
		WHERE CustID = @CustID and ProductID = @ProductID AND SiteID = @SiteID AND Currency = @Currency AND Type  = @Type
 	
	END TRY
	BEGIN CATCH
		SELECT  @ErrCode = ERROR_NUMBER(),@ErrMsg = ERROR_MESSAGE()
		RETURN
	END CATCH
	
	SELECT @TypeName = CASE @Type WHEN 1 THEN 'SMA Line' WHEN 2 THEN 'Site'  WHEN 3 THEN 'Currency' WHEN 4 THEN 'Site - Currency' ELSE 'SMA Line' END
								
	
	SELECT @LogSPData = '<NAP_LimitPTDaily_Del Product="'+ COALESCE(CAST(@ProductName AS VARCHAR(50)), SPACE(1)) + '" ' +
	                    'IP="'+ COALESCE(CAST(@IP as VARCHAR(20)),SPACE(1)) + '" ' +
	                    CASE WHEN @Type <> 1 THEN 'Currency="'+ COALESCE(CAST(@currencyName as VARCHAR(50)),SPACE(1)) + '" '  ELSE '' END +
						CASE WHEN @Type <> 1 THEN 'Site="'+ COALESCE(CAST(@site as VARCHAR(50)),SPACE(1)) + '" '   ELSE '' END +
						'Type="'+ COALESCE(CAST(@TypeName as VARCHAR(50)),SPACE(1)) + '" ' +
						'LimitNewAccUpdPT="'+ COALESCE(CAST((CASE WHEN ISNULL(@LimitNewAccUpdPt,0)=0 THEN 'No' ELSE 'Yes' END) AS NVARCHAR(10)),SPACE(1)) + '" ' +
						'SettingStatus="'+ COALESCE(CAST((CASE WHEN @SettingStatus = 0 THEN 'PRO' ELSE 'UAT' END)  as VARCHAR(10)),SPACE(1)) + '" ' +
						'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(400)),space(1)) + '" ' +
						'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" />'
						

	SELECT @EndRun	= GETDATE(), @Duration = DATEDIFF(MILLISECOND, @StartRun, @EndRun)
	IF @Type = 1
	BEGIN
		EXEC  Acc_WriteLog_UserLog_RunSP_Wrapper
			@CustID  = @CustID,
			@UserID = @UserID,
			@ActionID = 471,					--delete by line
			@TrackingValue = @LogSPData,
			@duration = @Duration

	END
	ELSE
	BEGIN
		EXEC  Acc_WriteLog_UserLog_RunSP_Wrapper
			@CustID  = @UserID,
			@UserID = @UserID,
			@ActionID = 474,					--delete by site/currency
			@TrackingValue = @LogSPData,
			@duration = @Duration

	END
	
END
GO
