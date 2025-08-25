/*<info serverAlias="DBCust-AgencyCashService" executers="wsv_CashService" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CashService_CashPromotionIns]
	@SiteDBGroupID SMALLINT, 
	@AgentID    INT,
	@Type       TINYINT=0,
    @Enabled    BIT=0,
    @FromDate   DATE,
    @ToDate DATE,
    @PromotionDetails VARCHAR(MAX),
    @PromotionContents NVARCHAR(MAX),
    @SubAccID	INT = 0,
	@IP			VARCHAR(50)	= '',
	@Language	VARCHAR(2)	= 'E',
    @ErrCode    INT = 0 OUTPUT,
    @ErrMsg     NVARCHAR(500) = '' OUTPUT
AS
/*
    Created: 20250707@Johnson
	Task : Add new promotion
	DB: DBCust/AgencyCashService
  
	Revisions:
        - 20250707@Johnson: initial sp [redmine:#232347]

    Parameter's Explanation:
    -@Type = 1: Rebate on Turnover
    -@PromotionDetails = '
    [{
        "ProductCategoryID": "1",
        "Product": "1",
        "Percentage": 10,
        "MinTO": 1000000,
        "MaxPayout": 500000
    },
    {   
        "ProductCategoryID": "2",
        "Product": "3,28,63",
        "Percentage": 15,
        "MinTO": 2000000,
        "MaxPayout": 1000000
    }]'
    - @PromotionContents = 
    N'[{
        "title": "Summer Promotion 2025",
        "banner": "https://example.com/images/summer-banner.png",
        "language": "en",
        "content": "Welcome to the Summer Promotion 2025! Enjoy great offers when you join today."
    },
    {
        "title": "Khuyến mãi hè 2025",
        "banner": "https://example.com/images/summer-banner.png",
        "language": "vi",
        "content": "Chào mừng bạn đến với chương trình khuyến mãi hè 2025! Nhận ưu đãi hấp dẫn khi tham gia ngay hôm nay."
    }]
    ';    
    @Log= '<ROOT CustID="1" SubAccName="" IP="1.1.1.1">
	<Promotion Type="0" Enabled="0" FromDate="2025-07-08" ToDate="2025-07-10">
		<Details>
			<r ProductCategoryID="1" Product="1" Percentage="10.0000" MinTurnover="1000000.0000" MaxPayout="500000.0000" />
			<r ProductCategoryID="2" Product="3,28,63" Percentage="15.0000" MinTurnover="2000000.0000" MaxPayout="1000000.0000"/>
		</Details>
		<Contents>
			<r Title="Summer Promotion 2025" Language="en" Content="Welcome to the Summer Promotion 2025! Enjoy great offers when you join today."/>
		</Contents>
        </Promotion>
    </ROOT>'
*/    
BEGIN
    SET NOCOUNT ON

    DECLARE 
		@startRun		DATETIME ,
		@endRun		DATETIME ,
		@DurationTime	INT,
        @PromotionID INT
	
	SET @startRun = GETDATE ()
	SELECT @ErrCode = 0 , @ErrMsg = '' 

    --Promotion Contents
    DECLARE @tblPromotionContents TABLE (
        Title NVARCHAR(200),
        Banner VARCHAR(1000),
        Language VARCHAR(10),
        Content NVARCHAR(MAX)
    );

    --Promotion Details for Product List
    DECLARE @tblPromotionDetails TABLE (
        ProductCategoryID TINYINT,
        Product VARCHAR(MAX),
        Percentage SMALLMONEY,
        MinTO MONEY,
        MaxPayout MONEY
    );

    INSERT INTO @tblPromotionDetails (ProductCategoryID, Product, Percentage, MinTO, MaxPayout)
    SELECT 
        [ProductCategoryID],
        [Product],
        [Percentage],
        [MinTO],
        [MaxPayout]
    FROM OPENJSON(@PromotionDetails)
    WITH (
        [ProductCategoryID] TINYINT '$.ProductCategoryID',
        [Product] VARCHAR(MAX) '$.Product',
        [Percentage] SMALLMONEY '$.Percentage',
        [MinTO] MONEY '$.MinTurnover',
        [MaxPayout] MONEY '$.MaxPayout'
    );


    INSERT INTO @tblPromotionContents (Title, Banner, Language, Content)
    SELECT    
        [title],
        [banner],
        [language],
        [content]
    FROM OPENJSON(@PromotionContents)
    WITH (        
        [title] NVARCHAR(200) '$.title',
        [banner] VARCHAR(1000) '$.banner',
        [language] VARCHAR(10) '$.language',
        [content] NVARCHAR(MAX) '$.content'
    );

    IF @Enabled = 1
    BEGIN
        --check if any promotion exists for the same period for any product
        SELECT TOP 1 
            @ErrCode = 100,
            @ErrMsg = N'There is another promotion for the same period.'
        FROM CashPromotion p WITH(NOLOCK)
            INNER JOIN CashPromotionDetail pd WITH(NOLOCK) ON p.PromotionID = pd.PromotionID AND p.SiteDBGroupID = pd.SiteDBGroupID            
        WHERE p.AgentID = @AgentID 
            AND p.Enabled = 1
            AND p.IsSoftDeleted = 0
            AND @FromDate <= p.ToDate 
            AND @ToDate >= p.FromDate          

        IF @ErrCode > 0                                
        RETURN;
    END

    INSERT INTO [dbo].[CashPromotion]
           ([SiteDBGroupID]
           ,[AgentID]
           ,[Type]
           ,[FromDate]
           ,[ToDate]
           ,[Enabled]
           ,[IsSoftDeleted]
           ,[ModifiedDate]
           ,[RepUpdateTime])
    SELECT 
           @SiteDBGroupID,
           @AgentID,
           @Type,
           @FromDate,
           @ToDate,
           @Enabled,
           0,--IsSoftDeleted
           GETDATE(),
           dbo.f_GetDateTime2()  

    SET @PromotionID = SCOPE_IDENTITY();

    INSERT INTO [dbo].[CashPromotionDetail]
           ([PromotionID]
           ,[SiteDBGroupID]
           ,[ProductCategoryID]
           ,[ProductList]
           ,[Percentage]
           ,[MaxPayout]
           ,[MinValue]
           ,[RepUpdateTime])
    SELECT
           @PromotionID,
           @SiteDBGroupID,
           pd.ProductCategoryID,
           pd.Product,
           pd.Percentage,
           pd.MaxPayout,
           pd.MinTO,
           dbo.f_GetDateTime2()
    FROM @tblPromotionDetails pd;

    INSERT INTO [dbo].[CashPromotionLanguage]
           ([PromotionID]
           ,[SiteDBGroupID]
           ,[LanguageCode]
           ,[Title]
           ,[Content]
           ,[Banner]
           ,[RepUpdateTime])
    SELECT
           @PromotionID,    
           @SiteDBGroupID,
           pc.Language,
           pc.Title,
           pc.Content,
           pc.Banner,
           dbo.f_GetDateTime2()
    FROM @tblPromotionContents pc;

    --START LOG
	DECLARE @TrackingValue NVARCHAR(MAX), @TrackingValue2 NVARCHAR(MAX)
	DECLARE @ActionID INT = 315001
		SET @endRun = GETDATE ()
		SET @DurationTime = datediff (millisecond,@startRun,@endRun)

    SELECT @TrackingValue = '<ROOT CustID="' + CONVERT(VARCHAR(20), @AgentID) 
                            + '" SubAccName="' + CustDB.dbo.f_GetSubUsername(@SubAccID) 
                            + '" IP="' + CONVERT(VARCHAR(50), @IP) + '">'
                           
                            + '<Promotion Type="' + CONVERT(VARCHAR(10), @Type) 
                            + '" Enabled="' + CONVERT(VARCHAR(10), @Enabled) 
                            + '" FromDate="' + CONVERT(VARCHAR(10), @FromDate, 120) 
                            + '" ToDate="' + CONVERT(VARCHAR(10), @ToDate, 120) + '">'
                            + CAST((
                                SELECT pd.ProductCategoryID AS '@ProductCategoryID',
                                       pd.Product AS '@Product',
                                       pd.Percentage AS '@Percentage',
                                       pd.MinTO AS '@MinTurnover',
                                       pd.MaxPayout AS '@MaxPayout'
                                FROM @tblPromotionDetails pd
                                FOR XML PATH('r'), ROOT('Details')
                            ) AS NVARCHAR(MAX))
                            + CAST((
                                SELECT pc.Title AS '@Title',                              
                                       pc.Language AS '@Language',
                                       pc.Content AS '@Content'
                                FROM @tblPromotionContents pc
                                FOR XML PATH('r'), ROOT('Contents')
                            ) AS NVARCHAR(MAX))
                            + '</Promotion>' 
                            + '</ROOT>';

    -- Return Data Object
	SELECT @AgentID as UserID, 
            @AgentID as CustID, 
            @ActionID as ActionID, 
            @TrackingValue as TrackingValue, 
            @TrackingValue2 as TrackingValue2,
            @DurationTime as Duration        
    
END