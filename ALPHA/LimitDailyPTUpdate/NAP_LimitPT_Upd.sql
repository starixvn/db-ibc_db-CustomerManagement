/*<info serverAlias="DBCUST-CustDB" executers="wsv_nap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_LimitPT_Upd] 
	-- Add the parameters for the stored procedure here
	  @ProductID			TINYINT,
	  @CustID				INT,
	  @Currency				INT,
	  @SiteID				INT,
	  @Type					TINYINT,
	  @LimitNewAccUpdPT		BIT,
	  @UserId				INT,
	  @IP					VARCHAR(15) = '',
	  @ErrCode				INT				= 0		OUTPUT,
	  @ErrMsg				NVARCHAR(MAX)	= ''	OUTPUT
AS
/*
		Task : NAP CM - Limitation to update PT for new member
		DB: DBCUST/CustDB
		Original: 
		Revisions:
			- 20230620@Luke: Limitation to update PT for new member [Redmine: #188950]
			- 20241230@Aries: Scale Out DBCUST - Apply Inhouse replication for the remaning tables [Redmine: #215627]
			- 20250410@Johnson: change datatype for ExchangeID[redmine: #223630]
		Parameter explanation:
		@ErrCode =: 
				0 - succeed 
				1 - This record no longer exists in Limit PT Setting.

		Example: 
		DECLARE @ErrMsg NVARCHAR(MAX),
				@ErrCode TINYINT
		EXEC NAP_LimitPT_Upd
			@ProductID=18,
			@CustID=90704927,
			@Currency=20,
			@SiteID=1,
			@Type=1,
			@LimitNewAccUpdPT = 0,
			@UserId=8,
		SELECT @ErrCode, @ErrMsg
	*/
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @StartRun					DATETIME
			,@EndRun					DATETIME
			,@Duration					INT
			,@ProductName				VARCHAR(50)
			,@UserName					NVARCHAR(50)
			,@site						NVARCHAR(50)
			,@currencyName				NVARCHAR(50)
			,@TypeName					NVARCHAR(50)
			,@SettingStatus				TINYINT
			,@LimitNewAccUpdPT_Old		BIT

	SET @startRun = GETDATE()

	SELECT	@LimitNewAccUpdPT_Old	= ISNULL(LimitNewAccUpdPT,0),
			@SettingStatus			= SettingStatus
	FROM LimitPTDailySetting WITH (NOLOCK)
	WHERE	Type = @Type 
			AND ProductID = @ProductID
			AND (Currency = @Currency OR Currency = 0)
			AND (SiteID = @SiteID OR SiteID = 0)
			AND (CustID = @custid OR CustID = 0)

	IF @@ROWCOUNT = 0
	BEGIN
		SET @ErrCode = 1
		SELECT @ErrMsg = 'This record no longer exists in Limit PT Setting.'
		RETURN
	END

	IF ISNULL(@LimitNewAccUpdPT_Old,0) = ISNULL(@LimitNewAccUpdPT,0)
	BEGIN
		SELECT @ErrMsg = 'No change'
		RETURN
	END

	IF @Type = 1 	
	BEGIN
		SELECT @UserName = username FROM customer WITH(NOLOCK) WHERE custid = @CustID
	END

	IF 	@SiteID = 0
	BEGIN
		SET @site = 'All sites'
	END
	ELSE
	BEGIN
		SELECT @site = site FROM Site WITH(NOLOCK) WHERE siteid = @SiteID
	END

	IF 	@Currency = 0
	BEGIN
		SET @currencyName = 'All currencies'
	END
	ELSE
	BEGIN
		SELECT @currencyName = currency FROM exchange WITH(NOLOCK) WHERE ExchangeId = @Currency
	END

	SELECT @ProductName = ProductName 
	FROM DBACC.bodb02.dbo.Products WITH (NOLOCK)
	WHERE ProductID = @ProductID
	
	SELECT @TypeName = CASE @Type	WHEN 1 THEN 'SMA Line'
									WHEN 2 THEN 'Site'
									WHEN 3 THEN 'Currency'
									WHEN 4 THEN 'Site/Currency' END 
	
	BEGIN TRY
		UPDATE l
		SET  l.LimitNewAccUpdPT = @LimitNewAccUpdPT
			,l.RepUpdateTime = dbo.f_GetDateTime2()
		FROM LimitPTDailySetting l WITH (ROWLOCK, UPDLOCK)
		WHERE	Type = @Type 
				AND ProductID = @ProductID
				AND (Currency = @Currency OR Currency = 0)
				AND (SiteID = @SiteID OR SiteID = 0)
				AND (CustID = @custid OR CustID = 0)
	END TRY
	BEGIN CATCH
		SELECT	@ErrCode	= ERROR_NUMBER(),
				@ErrMsg		= ERROR_MESSAGE()
		RETURN
	END CATCH

	SET @EndRun = GETDATE()
	SET @Duration = DATEDIFF(MILLISECOND, @StartRun, @EndRun)

	DECLARE @LogDataNew NVARCHAR(MAX),
			@LogDataOld NVARCHAr(MAX)
	
	SELECT @LogDataNew =    '<Nap_LimitPT_Upd Product="' + COALESCE(CAST(@ProductName AS VARCHAR(50)), SPACE(1)) + '" ' +
							'IP="' + COALESCE(CAST(@IP AS VARCHAR(50)), SPACE(1)) + '" ' +
							CASE WHEN @Type <> 1 THEN 'Currency="' + COALESCE(CAST(@CurrencyName AS VARCHAR(50)), SPACE(1)) + '" ' ELSE '' END  +
							CASE WHEN @Type <> 1 THEN 'Site="' + COALESCE(CAST(@Site AS VARCHAR(50)), SPACE(1)) + '" ' ELSE '' END +
							'Type="' + COALESCE(CAST(@TypeName AS VARCHAR(50)), SPACE(1)) + '" ' +
							'SettingStatus="' + COALESCE(CAST(CASE @SettingStatus WHEN 0 THEN 'PRO' ELSE 'UAT' END AS VARCHAR(50)), SPACE(1)) + '" ' +
							'LimitNewAccUpdPT="' + COALESCE(CAST(CASE ISNULL(@LimitNewAccUpdPT,0) WHEN 0 THEN 'No' ELSE 'Yes' END AS VARCHAR(3)), SPACE(1)) +  '" ' +
							'ErrMsg="' + COALESCE(CAST(@ErrMsg AS VARCHAR(MAX)), SPACE(1)) + '" ' + 
							'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1)) + '"' +
							' />'

	SELECT @LogDataOld =    '<Nap_LimitPT_Upd Product="' + COALESCE(CAST(@ProductName AS VARCHAR(50)), SPACE(1)) + '" ' +
							'IP="' + COALESCE(CAST(@IP AS VARCHAR(50)), SPACE(1)) + '" ' +
							CASE WHEN @Type <> 1 THEN 'Currency="' + COALESCE(CAST(@CurrencyName AS VARCHAR(50)), SPACE(1)) + '" ' ELSE '' END  +
							CASE WHEN @Type <> 1 THEN 'Site="' + COALESCE(CAST(@Site AS VARCHAR(50)), SPACE(1)) + '" ' ELSE '' END +
							'Type="' + COALESCE(CAST(@TypeName AS VARCHAR(50)), SPACE(1)) + '" ' +
							'SettingStatus="' + COALESCE(CAST(CASE @SettingStatus WHEN 0 THEN 'PRO' ELSE 'UAT' END AS VARCHAR(50)), SPACE(1)) + '" ' +
							'LimitNewAccUpdPT="' + COALESCE(CAST(CASE ISNULL(@LimitNewAccUpdPT_Old,0) WHEN 0 THEN 'No' ELSE 'Yes' END AS VARCHAR(3)), SPACE(1)) +  '" ' +
							'ErrMsg="' + COALESCE(CAST(@ErrMsg AS VARCHAR(MAX)), SPACE(1)) + '" ' + 
							'ErrCode="' + COALESCE(CAST(@ErrCode AS VARCHAR(10)), SPACE(1)) + '"' +
							' />'
	IF @Type = 1 
	BEGIN
		EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
			@CustID = @CustID,
			@UserID = @UserID,
			@ActionID = 478, --update sma line
			@TrackingValue = @LogDataNew,
			@TrackingValue2 = @LogDataOld,
			@Duration = @Duration
	END
	ELSE
	BEGIN
		EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper
			@CustID = @CustID,
			@UserID = @UserID,
			@ActionID = 479, --update site/currency
			@TrackingValue = @LogDataNew,
			@TrackingValue2 = @LogDataOld,
			@Duration = @Duration
	END	
END