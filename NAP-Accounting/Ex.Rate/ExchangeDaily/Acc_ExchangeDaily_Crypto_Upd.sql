/*<info serverAlias="DBCUST-CustDB" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Acc_ExchangeDaily_Crypto_Upd
    @File NVARCHAR(MAX),
    @EffectiveDate DATE = NULL,
    @IsCheck BIT,
    @LoginIP VARCHAR(20) = '',
    @UserID INT,
    @ErrCode INT = 0 OUTPUT,
    @ErrMsg NVARCHAR(4000) = '' OUTPUT
AS
/*              
Created: 20221108@Evan            
Task :  NAP»  Ex. Rate»  OANDA Exchange Rate» Import USDT Rate  [Redmine: #177844]       
DB:   DBCUST-CustDB            

Revisions:     
    - 20221108@Evan: Create new SP [Redmine: #177844]    
Param's Explanation:            
 - @Fie:              
  <ROOT><File Currency = "ADA" USDT = "0.468612343423212" /></ROOT>          
*/

BEGIN
    SET NOCOUNT ON;
    
    IF ISNULL(@File, '') = ''
        RETURN;

    -- Check Billing cycle 
    DECLARE @CurrentTime SMALLDATETIME = GETDATE()
    DECLARE @Today SMALLDATETIME = CONVERT(SMALLDATETIME,CAST(@CurrentTime AS DATE)); 
    DECLARE @BillingDate SMALLDATETIME;

    SELECT @BillingDate = CONVERT(DATE,DATEADD(dd,-(DATEPART(dd,@Today)) + 5 ,@Today))
    SELECT @BillingDate = DATEADD(hh,17,@BillingDate)
    
    DECLARE @iDoc INT,
            @StartRun DATETIME,
            @EndRun DATETIME,
            @Duration INT,
            @LogSPData NVARCHAR(MAX),
            @LogSPData_Old NVARCHAR(MAX),
            @RowTotal INT = 0,
            @CurrentRow INT = 0;

    CREATE TABLE #inputTmp
    (
        ID INT IDENTITY(1, 1),
        Currency NVARCHAR(MAX),
        USDT NVARCHAR(MAX),
        MultipliedBy DECIMAL(19,8),
        USDT_After FLOAT,
        ExchangeId INT
    );
    
    BEGIN TRY
        EXEC sp_xml_preparedocument @iDoc OUTPUT, @File;
        INSERT INTO #inputTmp
        (
            Currency,
            USDT
        )
        SELECT  Currency,
                USDT
        FROM
            OPENXML(@iDoc, '/ROOT/File', 1)
            WITH
            (
                Currency NVARCHAR(MAX),
                USDT NVARCHAR(MAX)
            );
        EXEC sp_xml_removedocument @iDoc;
    END TRY
    BEGIN CATCH
        SELECT @ErrCode = ERROR_NUMBER(),
               @ErrMsg = ERROR_MESSAGE();
        RETURN;
    END CATCH;
    
    -- remove empty row          
    DELETE #inputTmp
    WHERE LEN(Currency) = 0
          AND LEN(USDT) = 0
   
    -- update exchangeId
    UPDATE a
    SET a.ExchangeId = e.ExchangeId, 
        a.MultipliedBy = e.MultipliedBy, 
        a.USDT_After = e.MultipliedBy * CASE WHEN ISNUMERIC(USDT) = 1 THEN USDT ELSE NULL END
    FROM #inputTmp a INNER JOIN exchange e WITH(NOLOCK) ON e.currency = a.Currency
    WHERE e.CurrencyType = 1
    
    IF @IsCheck = 1
    BEGIN
        SELECT Currency, USDT, MultipliedBy, USDT_After, ExchangeId  FROM #inputTmp

        IF EXISTS(SELECT TOP 1 1 FROM #inputTmp WHERE ExchangeId IS NULL)
            SELECT @ErrCode = 1001, @ErrMsg = 'Invalid currency';
    END

    ELSE
    BEGIN

        IF EXISTS (SELECT TOP 1 1 FROM #inputTmp WHERE ExchangeId IS NULL)
        BEGIN 
            SELECT @ErrCode = 1001, @ErrMsg = 'Invalid currency';
            RETURN
        END

        IF @EffectiveDate IS NULL
        BEGIN
            SELECT @ErrCode = 1002, @ErrMsg = 'Invalid EffectiveDate';
            RETURN
        END

        IF (@CurrentTime > @BillingDate AND DATEDIFF(MONTH,@EffectiveDate,@Today) > 0 ) OR DATEDIFF(MONTH,@EffectiveDate,@Today) > 1
        BEGIN 
            SELECT  @ErrCode = 1000,
                    @ErrMsg = 'Billing cycle does not belong to ['+CAST(CONVERT(DATE,@EffectiveDate,101) AS VARCHAR(10))+'; '+CAST(CONVERT(DATE,EOMONTH(@EffectiveDate),101) AS VARCHAR(10))+']'
            RETURN
        END

        SELECT @RowTotal = COUNT(*)
        FROM #inputTmp;

        DECLARE @ExchangeDaily_Crypto TABLE (ExchangeId INT, USDT FLOAT)

        WHILE @CurrentRow <> @RowTotal
        BEGIN

            SELECT @CurrentRow = @CurrentRow + 1,
                   @StartRun = GETDATE();
            SELECT @LogSPData_Old = N'<R ExchangeId="' + COALESCE(CAST(e.ExchangeId AS VARCHAR(10)), SPACE(1)) + N'" ' + N'USDT="'
                  + COALESCE(CAST(MAX(e.USDT) AS VARCHAR(10)), SPACE(1))  + N'" ' + N'ExchangeDateFrom="'
                  + COALESCE(CAST(MIN(CONVERT(DATE,e.ExchangeDate,101)) AS VARCHAR(10)), SPACE(1)) + N'" ' + N'ExchangeDateTo="'
                  + COALESCE(CAST(MAX(CONVERT(DATE,e.ExchangeDate,101)) AS VARCHAR(10)), SPACE(1)) + N'" ' + N'LoginIP="'
                  + COALESCE(CAST(@LoginIP AS VARCHAR(20)), SPACE(1)) + N'" />'
            FROM dbo.ExchangeDaily_Crypto e WITH (NOLOCK)
                INNER JOIN #inputTmp i
                    ON i.ExchangeId = e.ExchangeId
            WHERE i.ID = @CurrentRow AND e.ExchangeDate >= @EffectiveDate
            GROUP BY e.ExchangeId
            
            INSERT INTO @ExchangeDaily_Crypto (ExchangeId, USDT)
            SELECT a.ExchangeId, a.USDT 
            FROM ExchangeDaily_Crypto a WITH(NOLOCK) 
                INNER JOIN #inputTmp b ON a.ExchangeId = b.ExchangeId
            WHERE a.ExchangeDate = @Today AND b.ID = @CurrentRow

            BEGIN TRY
                
                UPDATE a
                SET a.USDT = b.USDT_After
                FROM ExchangeDaily_Crypto a WITH(ROWLOCK) 
                    INNER JOIN #inputTmp b ON a.ExchangeId = b.ExchangeId
                WHERE   a.ExchangeDate >= @EffectiveDate
                        AND b.ID = @CurrentRow;
        
            END TRY
            BEGIN CATCH
                SELECT @ErrCode = ERROR_NUMBER(),
                       @ErrMsg = ERROR_MESSAGE();
                
                --Manually rollback
                UPDATE a
                SET a.USDT = b.USDT
                FROM ExchangeDaily_Crypto a WITH(ROWLOCK) 
                    INNER JOIN @ExchangeDaily_Crypto b ON a.ExchangeId = b.ExchangeId
                WHERE   a.ExchangeDate >= @EffectiveDate

                RETURN;
            END CATCH;
            
             SELECT @LogSPData = N'<R ExchangeId="' + COALESCE(CAST(e.ExchangeId AS VARCHAR(10)), SPACE(1)) + N'" ' + N'USDT="'
                  + COALESCE(CAST(MAX(e.USDT) AS VARCHAR(10)), SPACE(1))  + N'" ' + N'ExchangeDateFrom="'
                  + COALESCE(CAST(MIN(CONVERT(DATE,e.ExchangeDate,101)) AS VARCHAR(10)), SPACE(1)) + N'" ' + N'ExchangeDateTo="'
                  + COALESCE(CAST(MAX(CONVERT(DATE,e.ExchangeDate,101)) AS VARCHAR(10)), SPACE(1)) + N'" ' + N'LoginIP="'
                  + COALESCE(CAST(@LoginIP AS VARCHAR(20)), SPACE(1)) + N'" />'
            FROM dbo.ExchangeDaily_Crypto e WITH (NOLOCK)
                INNER JOIN #inputTmp i
                    ON i.ExchangeId = e.ExchangeId
            WHERE i.ID = @CurrentRow AND e.ExchangeDate >= @EffectiveDate
            GROUP BY e.ExchangeId 

            SET @EndRun = GETDATE();
            SET @Duration = DATEDIFF(MILLISECOND, @StartRun, @EndRun);

            EXEC dbo.Acc_WriteLog_UserLog_RunSP_Wrapper @UserID = @UserID,
                                                        @ActionID = 95078,
                                                        @TrackingValue = @LogSPData,
                                                        @TrackingValue2 = @LogSPData_Old,
                                                        @Duration = @Duration;
        END;

    END

    DROP TABLE #inputTmp

END