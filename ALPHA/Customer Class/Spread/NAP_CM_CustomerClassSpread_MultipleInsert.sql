/*<info serverAlias="DBCUST-CUSTDB" executers="wsv_nap" viewers="" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[NAP_CM_CustomerClassSpread_MultipleInsert]
    @DataSpread      NVARCHAR(MAX),
    @IsTest          TINYINT = 0,
    @UserID          INT,
    @Type            TINYINT = 1,
    @IP              VARCHAR(50) = '',
    @ErrCode         INT = 0 OUTPUT,
    @ErrMsg          NVARCHAR(MAX) = '' OUTPUT
AS
/*
	Created: Winfred
	Date: 20250923
	Task : [NAP CM] - Customer - Sportsbook CC Management - Spread Management - Upload Excel File [#236216]
	DB: DBCUST/CustDB
	Original: NAP_CM_CustomerClassSpread_MultipleInsert

	Revisions:
		- 20250923@Winfred: [NAP CM] - Customer - Sportsbook CC Management - Spread Management - Upload Excel File [RedmineID: #236216] 

	Param's Explanation:
	* @DataSpread:
		'[{"PolicyTitle":"U - E-Sports - No099 - IsTest = 1 03:03:20.4666667","SportType":43,"Spread":0.50,"CustomerClass":13,"SiteID":1,"Currency":0,"Platform":2},{"PolicyTitle":"U - E-Sports - No099 - IsTest = 1 03:03:20.4666667","SportType":43,"Spread":0.50,"CustomerClass":200,"SiteID":1,"Currency":0,"Platform":2},{"PolicyTitle":"U - E-Sports - No099 - IsTest = 1 03:03:20.4666667","SportType":43,"Spread":0.50,"CustomerClass":2000,"SiteID":1,"Currency":0,"Platform":2},{"PolicyTitle":"U - E-Sports - No099 - IsTest = 1 03:03:20.4666667","SportType":43,"Spread":0.50,"CustomerClass":13,"SiteID":188,"Currency":0,"Platform":2},{"PolicyTitle":"U - E-Sports - No099 - IsTest = 1 03:03:20.4666667","SportType":43,"Spread":0.50,"CustomerClass":200,"SiteID":188,"Currency":0,"Platform":2},{"PolicyTitle":"U - E-Sports - No099 - IsTest = 1 03:03:20.4666667","SportType":43,"Spread":0.50,"CustomerClass":2000,"SiteID":188,"Currency":0,"Platform":2},{"PolicyTitle":"U - E-Sports - No099 - IsTest = 1 03:03:20.4666667","SportType":43,"Spread":0.50,"CustomerClass":13,"SiteID":329,"Currency":0,"Platform":2},{"PolicyTitle":"U - E-Sports - No099 - IsTest = 1 03:03:20.4666667","SportType":43,"Spread":0.50,"CustomerClass":200,"SiteID":329,"Currency":0,"Platform":2},{"PolicyTitle":"U - E-Sports - No099 - IsTest = 1 03:03:20.4666667","SportType":43,"Spread":0.50,"CustomerClass":2000,"SiteID":329,"Currency":0,"Platform":2}]'
	* @Sites:   "0 : All
				-1 : All site Credit 
				-2 : All site Deposit"
	* @Currencies : 0 : All
	* @Platforms : "0 : All
					1 : Desktop
					2 : Mobile
					3 : APP
					4 : Oddsfeed
					5 : DirectAPI"
	* @Type : "1: Spead
			   2: Peak Hour Spead"
	Example: NAP_CM_CustomerClassSpread_MultipleInsert 
		@DataSpread ='[{"PolicyTitle":"U - E-Sports - No099 - IsTest = 1 03:03:20.4666667","SportType":43,"Spread":0.50,"CustomerClass":13,"SiteID":1,"Currency":0,"Platform":2},{"PolicyTitle":"U - E-Sports - No099 - IsTest = 1 03:03:20.4666667","SportType":43,"Spread":0.50,"CustomerClass":200,"SiteID":1,"Currency":0,"Platform":2},{"PolicyTitle":"U - E-Sports - No099 - IsTest = 1 03:03:20.4666667","SportType":43,"Spread":0.50,"CustomerClass":2000,"SiteID":1,"Currency":0,"Platform":2},{"PolicyTitle":"U - E-Sports - No099 - IsTest = 1 03:03:20.4666667","SportType":43,"Spread":0.50,"CustomerClass":13,"SiteID":188,"Currency":0,"Platform":2},{"PolicyTitle":"U - E-Sports - No099 - IsTest = 1 03:03:20.4666667","SportType":43,"Spread":0.50,"CustomerClass":200,"SiteID":188,"Currency":0,"Platform":2},{"PolicyTitle":"U - E-Sports - No099 - IsTest = 1 03:03:20.4666667","SportType":43,"Spread":0.50,"CustomerClass":2000,"SiteID":188,"Currency":0,"Platform":2},{"PolicyTitle":"U - E-Sports - No099 - IsTest = 1 03:03:20.4666667","SportType":43,"Spread":0.50,"CustomerClass":13,"SiteID":329,"Currency":0,"Platform":2},{"PolicyTitle":"U - E-Sports - No099 - IsTest = 1 03:03:20.4666667","SportType":43,"Spread":0.50,"CustomerClass":200,"SiteID":329,"Currency":0,"Platform":2},{"PolicyTitle":"U - E-Sports - No099 - IsTest = 1 03:03:20.4666667","SportType":43,"Spread":0.50,"CustomerClass":2000,"SiteID":329,"Currency":0,"Platform":2}]' ,@ErrCode =0, @ErrMsg = '',  @IP = '11.12.11.10', @UserID = 6
*/ 
BEGIN
    SET NOCOUNT ON;

    DECLARE
        @logSpData         NVARCHAR(MAX),
        @xml               XML,
        @ActionID          INT,
        @StartRun          DATETIME,
        @EndRun            DATETIME,
        @Duration          INT,
        @MaxPolicyID       INT,
        @STT               INT = 0,
        @PolicyID          INT = 0,
        @Batch             INT = 2000,
        @CustomerClasses   NVARCHAR(MAX) = '';

    SELECT @StartRun = GETDATE();

    -- Check if XML is null or empty
    IF @DataSpread IS NULL OR @DataSpread = ''
        RETURN;

    -- Create temp tables
    CREATE TABLE #CCSpreadImport (
        PolicyTitle VARCHAR(500),
        CustomerClass SMALLINT,
        SportType SMALLINT,
        SiteID INT,
        Currency INT,
        Platform TINYINT,
        Spread DECIMAL(4,2),
        GroupDetail INT,
        PolicyNumber INT,
        IsExist INT DEFAULT(0),
        IsDup INT DEFAULT(0),
        Priority SMALLINT DEFAULT(0),
        STT INT IDENTITY (1,1)
    );

    CREATE TABLE #CCSpread (
        PolicyTitle VARCHAR(500),
        SportType SMALLINT,
        SiteID INT,
        Currency INT,
        Platform TINYINT,
        Spread DECIMAL(4,2),
        PolicyID INT,
        GroupDetail INT,
        PolicyNumber INT,
        CustomerClasses VARCHAR(MAX),
        IsFinished BIT DEFAULT(0)
    );

    CREATE TABLE #CCSpread_Temp (
        PolicyID INT,
        SportType SMALLINT,
        SiteID INT,
        Currency INT,
        Platform TINYINT,
        ID INT
    );

    CREATE CLUSTERED INDEX Cix_CCSpread ON #CCSpreadImport(SiteID, Currency, Platform, SportType, CustomerClass, Spread, PolicyTitle);
    CREATE NONCLUSTERED INDEX IX_CCSpread_CC ON #CCSpreadImport( GroupDetail, IsExist, IsDup, CustomerClass);

    BEGIN TRY
        INSERT INTO #CCSpreadImport (
            PolicyTitle, CustomerClass, SportType, SiteID, Currency, Platform, Spread, Priority, GroupDetail
        )
        SELECT
            PolicyTitle,
            CustomerClass,
            SportType,
            SiteID,
            Currency,
            Platform,
            Spread,
			((CASE SiteID WHEN 0 THEN 300
						  WHEN -1 THEN 200
						  WHEN -2 THEN 100
					ELSE 0 END) +
			(CASE WHEN Currency = 0 THEN 10 ELSE 0 END) +
			(CASE WHEN Platform = 0 THEN 1 ELSE 0 END))
			AS Priority ,
            DENSE_RANK() OVER (ORDER BY PolicyTitle, SportType, Spread, SiteID, Currency, Platform) AS GroupDetail
        FROM OPENJSON(@DataSpread)
        WITH (
            PolicyTitle     VARCHAR(500) '$.PolicyTitle',
            CustomerClass   SMALLINT     '$.CustomerClass',
            SportType       SMALLINT     '$.SportType',
            SiteID          INT          '$.SiteID',
            Currency        INT          '$.Currency',
            Platform        TINYINT      '$.Platform',
            Spread          DECIMAL(4,2) '$.Spread'
        );
    END TRY
    BEGIN CATCH
        SELECT @ErrMsg = N'Invalid import format', @ErrCode = 3;
        RETURN;
    END CATCH

    -- Update Check Duplicate File import and Check data Exists
    UPDATE old
    SET
        old.IsDup = ISNULL(isDup.STT, 0),
        old.IsExist = ISNULL(IsExist.PolicyID, 0)
    FROM #CCSpreadImport old
    OUTER APPLY (
        SELECT TOP 1 b.STT
        FROM #CCSpreadImport b
        WHERE old.STT > b.STT
            AND old.SportType = b.SportType
            AND old.SiteID = b.SiteID
            AND old.Currency = b.Currency
            AND old.Platform = b.Platform
            AND old.CustomerClass = b.CustomerClass
            AND b.Spread = old.Spread
    ) isDup
    OUTER APPLY (
        SELECT TOP 1 sd.PolicyID
        FROM CustomerClassSpreadDetail sd WITH(NOLOCK)
        CROSS APPLY (
            SELECT TOP 1 sc.PolicyID
            FROM CustomerClassSpreadClass sc WITH(NOLOCK)
            WHERE sd.PolicyID = sc.PolicyID AND sc.CustomerClass = old.CustomerClass
        ) b
        CROSS APPLY (
            SELECT TOP 1 ccs.PolicyID
            FROM CustomerClassSpread ccs WITH(NOLOCK)
            WHERE sd.PolicyID = ccs.PolicyID AND ccs.IsTest = @IsTest AND ccs.Enable = 1 AND ccs.Spread = old.Spread
        ) c
        WHERE sd.SiteID = old.SiteID
            AND sd.Currency = old.Currency
            AND sd.Platform = old.Platform
            AND sd.SportType = old.SportType
    ) IsExist;

    -- Group CC
    WITH GroupCC AS (
		SELECT DISTINCT
            PolicyTitle,
            SportType,
            Spread,
            SiteID,
            Currency,
            Platform,
            CustomerClasses,
            DENSE_RANK() OVER ( ORDER BY  Priority, PolicyTitle, SportType, Spread , CustomerClasses) AS GroupCustomerClass
        FROM #CCSpreadImport a
			CROSS APPLY (
				SELECT STRING_AGG(CAST(CustomerClass AS VARCHAR(MAX)), ',') WITHIN GROUP (ORDER BY CustomerClass) CustomerClasses
				FROM (
					SELECT DISTINCT CustomerClass
					FROM #CCSpreadImport WITH(NOLOCK)
					WHERE GroupDetail = a.GroupDetail AND a.IsExist = 0 AND a.IsDup = 0
				) cc
			) c
        WHERE a.IsExist = 0 AND a.IsDup = 0
	),
	NumberedRows AS (
		SELECT 
			PolicyTitle,
			SportType,
			Spread,
			SiteID,
			Currency,
			Platform,
			CustomerClasses,
			GroupCustomerClass,
			ROW_NUMBER() OVER (ORDER BY GroupCustomerClass,SiteID, currency, platform) as RowsNumber
		FROM GroupCC
	),
	GroupCurPlatform AS (
		SELECT DISTINCT
			PolicyTitle,
            SportType,
            Spread,
            SiteID,
            Currency,
            Platform,
            CustomerClasses,
			GroupCustomerClass,
			RowsNumber,
			MIN(RowsNumber) OVER (PARTITION BY GroupCustomerClass, currency, platform) as group_C_P
		FROM NumberedRows
	),
	GroupSitePlatform AS (
		SELECT 
			PolicyTitle,
            SportType,
            Spread,
            SiteID,
            Currency,
            Platform,
            CustomerClasses,
			GroupCustomerClass,
			RowsNumber,
			group_C_P,
			CASE 
				WHEN group_C_P < MIN(group_C_P) OVER (PARTITION BY GroupCustomerClass, SiteID, platform) 
				THEN group_C_P
				ELSE MIN(group_C_P) OVER (PARTITION BY GroupCustomerClass, SiteID, platform)
			END as group_S_P
		FROM GroupCurPlatform
	),
	GroupSiteCur AS (
		SELECT 
			PolicyTitle,
            SportType,
            Spread,
            SiteID,
            Currency,
            Platform,
            CustomerClasses,
			GroupCustomerClass,
			RowsNumber,
			group_C_P,
			group_S_P,
			CASE 
				WHEN group_S_P < MIN(group_S_P) OVER (PARTITION BY GroupCustomerClass, SiteID, currency) 
				THEN group_S_P
				ELSE MIN(group_S_P) OVER (PARTITION BY GroupCustomerClass, SiteID, currency)
			END as group_S_C
		FROM GroupSitePlatform
	),
	FinalGroup AS (
		SELECT 
			PolicyTitle,
            SportType,
            Spread,
            SiteID,
            Currency,
            Platform,
            CustomerClasses,
			GroupCustomerClass,
			MIN(group_S_C) OVER (PARTITION BY GroupCustomerClass, group_S_C) as final_group_root
		FROM GroupSiteCur
	)
	 
	 INSERT INTO #CCSpread (
        PolicyTitle, SportType, Spread, SiteID, Currency, Platform, CustomerClasses, PolicyNumber, GroupDetail
    )
	SELECT 
		PolicyTitle,
		SportType,
		Spread,
		SiteID,
		Currency,
		Platform,
		CustomerClasses,
		PolicyNumber,
		ROW_NUMBER() OVER (PARTITION BY PolicyNumber ORDER BY SiteID, Currency, Platform) AS GroupDetail
	FROM (
		SELECT 
			PolicyTitle,
			SportType,
			Spread,
			SiteID,
			Currency,
			Platform,
			CustomerClasses,
			DENSE_RANK() OVER (ORDER BY final_group_root) as PolicyNumber
		FROM FinalGroup ) KQ
	ORDER BY PolicyNumber, SiteID, currency, platform;
	
    SELECT @MaxPolicyID = MAX(PolicyNumber) FROM #CCSpread;

    WHILE (@STT <= @MaxPolicyID)
    BEGIN
        SET @STT = @STT + 1;

        INSERT INTO CustomerClassSpread (
            PolicyTitle, Spread, Enable, IsTest, LastModifiedUser, LastModifiedTime, IsLive, Type, RepUpdateTime
        )
        SELECT TOP 1
            PolicyTitle,
            Spread,
            1 AS Enable,
            @IsTest AS IsTest,
            @UserID AS LastModifiedUser,
            GETDATE() AS LastModifiedTime,
            0 AS IsLive,
            @Type AS Type,
            [dbo].[f_GetDateTime2]() AS RepUpdateTime
        FROM #CCSpread src
        WHERE src.PolicyNumber = @STT;

        IF @@ROWCOUNT = 0 BREAK;

        SET @PolicyID = SCOPE_IDENTITY();

        UPDATE #CCSpread
        SET PolicyID = @PolicyID, @CustomerClasses = CustomerClasses
        WHERE PolicyNumber = @STT;

        INSERT INTO CustomerClassSpreadClass (PolicyID, CustomerClass, RepUpdateTime, ID)
        SELECT
            @PolicyID AS PolicyID,
            VALUE AS CustomerClass,
            [dbo].[f_GetDateTime2]() AS RepUpdateTime,
            ROW_NUMBER() OVER (ORDER BY VALUE ASC) AS ID
        FROM STRING_SPLIT(@CustomerClasses, ',')
        WHERE VALUE <> '';

        WHILE 0 = 0
        BEGIN
            TRUNCATE TABLE #CCSpread_Temp;

            UPDATE TOP(@Batch) #CCSpread
            SET isFinished = 1
            OUTPUT DELETED.PolicyID, DELETED.SiteID, DELETED.Currency, DELETED.Platform, DELETED.SportType, DELETED.GroupDetail
            INTO #CCSpread_Temp (PolicyID, SiteID, Currency, Platform, SportType, ID)
            WHERE PolicyNumber = @STT AND isFinished = 0;

            IF @@ROWCOUNT = 0 BREAK;

            INSERT INTO CustomerClassSpreadDetail (
                PolicyID, SiteID, Currency, Platform, SportType, RepUpdateTime, ID
            )
            SELECT
                PolicyID,
                SiteID,
                Currency,
                Platform,
                SportType,
                [dbo].[f_GetDateTime2](),
                ID
            FROM #CCSpread_Temp;
        END
    END

    -- Log Action import
    SET @xml = (
        SELECT
            @UserID AS '@UserID',
            @IP AS '@IP',
            @IsTest AS '@IsTest',
            @Type AS '@Type',
            COALESCE(CAST(@ErrMsg AS VARCHAR(400)), SPACE(1)) AS '@ErrMsg',
            COALESCE(CAST(@ErrCode AS VARCHAR(50)), SPACE(1)) AS '@ErrCode',
            (
                SELECT
                    a.PolicyTitle						AS '@PolicyTitle',
                    a.CustomerClass						AS '@CustomerClass',
                    a.SportType							AS '@SportType',
                    a.SiteID							AS '@SiteID',
                    a.Currency							AS '@Currency',
                    a.Platform							AS '@Platform',
                    CONVERT(DECIMAL(20,2), a.Spread)	AS '@Spread',
                    a.IsExist							AS '@IsExist',
                    a.IsDup								AS '@IsDup'
                FROM #CCSpreadImport a
                FOR XML PATH('Data'), TYPE
            )
        FOR XML PATH('R'), TYPE
    );
    SET @logSpData = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"');
    SELECT @EndRun = GETDATE(), @Duration = DATEDIFF(MILLISECOND, @StartRun, @EndRun);

	EXEC Acc_WriteLog_UserLog_RunSP_Wrapper
        @CustID = @UserID,
        @UserID = @UserID,
        @ActionID = 31931,
        @TrackingValue = @logSpData,
        @duration = @Duration;
	
	-- Log Action insert
    SET @xml = (
        SELECT
            @UserID AS '@UserID',
            @IP AS '@IP',
            @IsTest AS '@IsTest',
            @Type AS '@Type',
            COALESCE(CAST(@ErrMsg AS VARCHAR(400)), SPACE(1)) AS '@ErrMsg',
            COALESCE(CAST(@ErrCode AS VARCHAR(50)), SPACE(1)) AS '@ErrCode',
            (
                SELECT
                    a.PolicyID							AS '@PolicyID',
                    a.PolicyTitle						AS '@PolicyTitle',
                    a.CustomerClasses					AS '@CustomerClass',
                    a.SportType							AS '@SportType',
                    a.SiteID							AS '@SiteID',
                    a.Currency							AS '@Currency',
                    a.Platform							AS '@Platform',
                    CONVERT(DECIMAL(20,2), a.Spread)	AS '@Spread'
                FROM #CCSpread a
				WHERE a.PolicyID > 0
                FOR XML PATH('Data'), TYPE
            )
        FOR XML PATH('R'), TYPE
    );
    SET @logSpData = REPLACE(CONVERT(VARCHAR(MAX), @xml), '" />', '"/"');
    SELECT @EndRun = GETDATE(), @Duration = DATEDIFF(MILLISECOND, @StartRun, @EndRun);

    EXEC Acc_WriteLog_UserLog_RunSP_Wrapper
        @CustID = @UserID,
        @UserID = @UserID,
        @ActionID = 31932,
        @TrackingValue = @logSpData,
        @duration = @Duration;

    DROP TABLE #CCSpreadImport;
    DROP TABLE #CCSpread_Temp;
    DROP TABLE #CCSpread;
END
