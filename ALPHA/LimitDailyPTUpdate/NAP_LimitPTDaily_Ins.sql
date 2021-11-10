/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_LimitPTDaily_Ins] 
	-- Add the parameters for the stored procedure here
	  @ProductID			NVARCHAR(MAX) = '',
	  @SMAName				VARCHAR(MAX) = '',
	  @Currency				TINYINT,
	  @SiteID				INT,
	  @Type					TINYINT,
	  @SettingStatus		TINYINT = 0
	, @UserId				INT = 0 
	, @IP					VARCHAR(15) = ''
	, @ErrCode				INT				= 0		OUTPUT
	, @ErrMsg				NVARCHAR(MAX)	= ''	OUTPUT
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
		, @CustID INT
	SET @startRun = GETDATE()
	SELECT	@ErrCode	= 0	,	@ErrMsg			= ''	
	DECLARE @tblCust TABLE (CustInfo VARCHAR(50), CustID INT, IsFinished BIT DEFAULT (0) )
	DECLARE @tblDuplicate TABLE (CustInfo VARCHAR(50), countCust INT )
	CREATE TABLE #Product (ProductID TINYINT PRIMARY KEY ,ProductName VARCHAR(50), IsFinished BIT DEFAULT (0) )
	
	INSERT INTO #Product  (ProductID)	
	SELECT S.val
	FROM dbo.strSplit(@ProductID, ',') S
	
	UPDATE tc
	SET tc.ProductName = p.ProductName
	FROM #Product tc
		INNER JOIN DBACC.bodb02.dbo.Products p WITH(NOLOCK) ON p.ProductID = tc.ProductID 
		
	IF @SMAName <> ''
	BEGIN
		-- get list transId (single + sub-parlay)  
		 INSERT INTO @tblCust (CustInfo)  
		 SELECT LTRIM(RTRIM(val))
		 FROM dbo.f_SplitString(@SMAName, ',')  
		 WHERE val <> ''  
		 OPTION (MAXRECURSION 0)
		 
		IF (SELECT COUNT(CustInfo) FROM @tblCust t) > 500
		BEGIN
			SELECT @ErrCode = 1 			
			SELECT @ErrMsg = 'The function can only support up to 500 accounts per request.'
			RETURN
		END	
		 
		INSERT INTO @tblDuplicate(CustInfo,countCust) 
		SELECT CustInfo,COUNT(CustInfo) AS countCust FROM @tblCust GROUP BY CustInfo HAVING COUNT(CustInfo) > 1
		
		IF EXISTS( SELECT TOP 1 1 FROM @tblDuplicate t )
		BEGIN
			SELECT @ErrCode = 2 			
			SELECT @ErrMsg = 'Duplicated account(s): ' +  STUFF((SELECT DISTINCT ',' + cast(CustInfo AS VARCHAR(50))
									FROM @tblDuplicate
									FOR XML PATH('')), 1, 1, '')
			RETURN
		END	 
		 
		-- Update Cust Super 
		UPDATE tc
		SET CustID = ci.CustID
		FROM @tblCust tc
    		INNER JOIN dbo.Customer ci WITH (NOLOCK) ON ci.username = tc.CustInfo 
		WHERE ci.roleid  = 4 AND ci.custid > 100 AND site <> 'CN88'
				AND NOT EXISTS (SELECT TOP 1 1 FROM Dep_CustSuper WITH (NOLOCK) WHERE custid = ci.custid)
		
		-- Update Direct Account 
		UPDATE tc
		SET CustID = ci.CustID
		FROM @tblCust tc
    		INNER JOIN dbo.Customer ci WITH (NOLOCK) ON ci.username = tc.CustInfo 
    		INNER JOIN dbo.CustDirectAccount cd WITH (NOLOCK) ON ci.custID = cd.custid 
		WHERE ci.roleid  in (2,3)
		
		IF EXISTS( SELECT TOP 1 1 FROM @tblCust t WHERE CustID IS NULL )
		BEGIN
			SELECT @ErrCode = 3 			
			SELECT @ErrMsg = 'The following account(s) are not credit site''s Super, Direct Master or Direct Agent: ' +  STUFF((SELECT DISTINCT ',' + cast(CustInfo AS VARCHAR(50))
									FROM @tblCust
									WHERE CustID IS NULL
									FOR XML PATH('')), 1, 1, '')
			
			RETURN
		END	
		--exclude the already added accounts from the input accounts
		DELETE tc FROM @tblCust tc 
		INNER JOIN LimitPTDailySetting t  WITH (NOLOCK)  ON tc.CustID = t.CustID 
		WHERE t.ProductID IN ( SELECT ProductID FROM #Product) AND t.Type = 1
		
		IF NOT EXISTS( SELECT TOP 1 1 FROM @tblCust t )
		BEGIN
			SELECT @ErrCode = 1 			
			SELECT @ErrMsg = 'The selected rule exists already: ' +  @SMAName
			RETURN
		END	
	 END	
	
	IF EXISTS( SELECT TOP 1 1 FROM LimitPTDailySetting t WITH(NOLOCK) 
							  WHERE t.ProductID IN ( SELECT ProductID FROM #Product) AND Currency = @Currency AND SiteID = @SiteID AND Type IN (2,3,4) )
	BEGIN
		SELECT @ErrCode = 1 ,
			@ErrMsg = 'The selected rule exists already.'

		RETURN
	END	
	BEGIN TRY
		IF @Type = 1
		BEGIN
			INSERT INTO LimitPTDailySetting(ProductID,CustID,Currency,SiteID,MaxCount,Type,SettingStatus)
			SELECT b.ProductID ,t.CustID, @Currency,@SiteID, 2 AS MaxCount, @Type , @SettingStatus
			FROM @tblCust t , #Product b
		END
		ELSE
		BEGIN
			INSERT INTO LimitPTDailySetting(ProductID,CustID,Currency,SiteID,MaxCount,Type,SettingStatus)
			SELECT ProductID , 0 AS CustID, @Currency,@SiteID, 2 AS MaxCount, @Type , @SettingStatus
			FROM #Product
		END 
	END TRY
	BEGIN CATCH
		SELECT  @ErrCode = ERROR_NUMBER(),@ErrMsg = ERROR_MESSAGE()
		RETURN
	END CATCH

	WHILE (1=1)
	BEGIN
		UPDATE TOP (1) #Product
		SET IsFinished = 1, 
			@ProductName = ProductName
		WHERE IsFinished = 0
		
		IF @@ROWCOUNT = 0 BREAK
			
		SELECT @LogSPData = '<NAP_LimitPTDaily_Ins Product="'+ COALESCE(CAST(@ProductName AS VARCHAR(50)), SPACE(1)) + '" ' +
							'IP="'+ COALESCE(CAST(@IP as VARCHAR(20)),SPACE(1)) + '" ' +
							'ErrMsg="'+ coalesce(cast(@ErrMsg as varchar(400)),space(1)) + '" ' +
							'ErrCode="'+ coalesce(cast(@ErrCode as varchar(50)),space(1)) + '" />'
							

		SELECT @EndRun	= GETDATE(), @Duration = DATEDIFF(MILLISECOND, @StartRun, @EndRun)
		IF @Type = 1
		BEGIN
			WHILE (1=1)
			BEGIN
				UPDATE TOP (1) @tblCust
				SET IsFinished = 1, 
					@CustID = custid
				WHERE IsFinished = 0

				IF @@ROWCOUNT = 0 BREAK
				
				EXEC  Acc_WriteLog_UserLog_RunSP_Wrapper
						@CustID  = @CustID,
						@UserID = @UserID,
						@ActionID = 470,
						@TrackingValue = @LogSPData,
						@duration = @Duration
			END
			UPDATE @tblCust  SET IsFinished = 0 
		END
		ELSE
		BEGIN
			EXEC  Acc_WriteLog_UserLog_RunSP_Wrapper
				@CustID  = @UserID,
				@UserID = @UserID,
				@ActionID = 470,
				@TrackingValue = @LogSPData,
				@duration = @Duration
		END
	END 

END
GO
