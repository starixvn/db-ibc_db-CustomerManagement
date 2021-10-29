/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_LimitPTDaily_Ins] 
	-- Add the parameters for the stored procedure here
	  @ProductID			TINYINT,
	  @SportType			SMALLINT,
	  @BetType				SMALLINT,
	  @SMAName				VARCHAR(MAX) = '',
	  @Currency				TINYINT,
	  @SiteID				INT,
	  @MaxCount				TINYINT,
	  @Type					TINYINT,
	  @SettingStatus		TINYINT = 0
	, @UserId				INT = 0 
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
	DECLARE @tblCust TABLE (CustInfo VARCHAR(50), CustID INT )
	
	-- Select ProductName
	SELECT @ProductName = p.ProductName
	FROM DBACC.bodb02.dbo.Products AS p WITH(NOLOCK)
	WHERE p.ProductID = @ProductID
		
	EXEC NAP_UserControl.dbo.NAP_User_CheckPermission 
		@UserId=@userid,
		@SiteKey='CustomerManagement',
		@FunctionKey='LimitDailyPTUpdate',
		@ErrCode=@ErrCode OUTPUT,
		@ErrMsg=@ErrMsg OUTPUT

	IF @ErrCode <> 0
		RETURN
	IF @SMAName <> ''
	BEGIN
		-- get list transId (single + sub-parlay)  
		 INSERT INTO @tblCust (CustInfo)  
		 SELECT DISTINCT LTRIM(RTRIM(val))
		 FROM dbo.f_SplitString(@SMAName, ',')  
		 WHERE val <> ''  
		 OPTION (MAXRECURSION 0)
		-- Update Cust Super 
		UPDATE tc
		SET CustID = ci.CustID
		FROM @tblCust tc
    		INNER JOIN dbo.Customer ci WITH (NOLOCK) ON ci.username = tc.CustInfo 
		WHERE ci.roleid  = 4
		
		-- Update Direct Account 
		UPDATE tc
		SET CustID = ci.CustID
		FROM @tblCust tc
    		INNER JOIN dbo.Customer ci WITH (NOLOCK) ON ci.username = tc.CustInfo 
    		INNER JOIN dbo.Acc_CustDirect cd WITH (NOLOCK) ON ci.custID = cd.custid 
		WHERE ci.roleid  in (2,3)
		
		IF EXISTS( SELECT TOP 1 1 FROM @tblCust t WHERE CustID IS NULL )
		BEGIN
			SELECT @ErrCode = 1 			
			SELECT @ErrMsg = 'The following account(s) are not Super, Direct Master or Direct Agent: ' +  STUFF((SELECT DISTINCT ',' + cast(CustInfo AS VARCHAR(50))
									FROM @tblCust
									WHERE CustID IS NULL
									FOR XML PATH('')), 1, 1, '')
			
			RETURN
		END	
		--exclude the already added accounts from the input accounts
		DELETE tc FROM @tblCust tc 
		INNER JOIN LimitPTDailySetting t  WITH (NOLOCK)  ON tc.CustID = t.CustID 
		WHERE t.ProductID = @ProductID AND t.SportType = @SportType AND  t.BetType =  @BetType AND t.Type = 1
		
		IF EXISTS( SELECT TOP 1 1 FROM @tblCust t )
		BEGIN
			SELECT @ErrCode = 1 			
			SELECT @ErrMsg = 'Invalid account: ' +  @SMAName
			RETURN
		END	
	 END	
	
	IF EXISTS( SELECT TOP 1 1 FROM LimitPTDailySetting t WITH(NOLOCK) 
							  WHERE t.ProductID = @ProductID AND SportType = @SportType
								 AND  BetType =  @BetType AND Currency = @Currency AND SiteID = @SiteID AND Type IN (2,3,4) )
	BEGIN
		SELECT @ErrCode = 1 ,
			@ErrMsg = 'The selected rule exists already.'

		RETURN
	END	
	BEGIN TRY
		IF @Type = 1
		BEGIN
			INSERT INTO LimitPTDailySetting(ProductID,SportType,BetType,CustID,Currency,SiteID,MaxCount,Type,SettingStatus)
			SELECT @ProductID , @SportType,@BetType,t.CustID, @Currency,@SiteID, 2 AS MaxCount, @Type , @SettingStatus
			FROM @tblCust t
		END
		ELSE
		BEGIN
			INSERT INTO LimitPTDailySetting(ProductID,SportType,BetType,CustID,Currency,SiteID,MaxCount,Type,SettingStatus)
			SELECT @ProductID , @SportType,@BetType, 0 AS CustID, @Currency,@SiteID, 2 AS MaxCount, @Type , @SettingStatus
		END 
	END TRY
	BEGIN CATCH
		SELECT  @ErrCode = ERROR_NUMBER(),@ErrMsg = ERROR_MESSAGE()
		RETURN
	END CATCH

	
	SELECT @LogSPData = '<NAP_LimitPTDaily_Ins Product="'+ COALESCE(CAST(@ProductName AS VARCHAR(50)), SPACE(1)) + '" ' +
	                    'IP="'+ COALESCE(CAST(@IP as VARCHAR(20)),SPACE(1)) + '" ' +
						'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(400)),space(1)) + '" ' +
						'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" />'
						

	SELECT @EndRun	= GETDATE(), @Duration = DATEDIFF(MILLISECOND, @StartRun, @EndRun)

	EXEC  Acc_WriteLog_UserLog_RunSP_Wrapper
			@UserID = @UserID,
			@ActionID = 6060,
			@TrackingValue = @LogSPData,
			@duration = @Duration

END
GO
