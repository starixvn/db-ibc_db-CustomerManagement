/*<info serverAlias="DBCust-AgencyCashService" executers="wsv_CashService" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CashService_CashPromotionUpd]
	@SiteDBGroupID SMALLINT, 
    @PromotionID INT,
	@AgentID    INT,	
    @PromotionContents NVARCHAR(MAX),
    @SubAccID	INT = 0,
	@IP			VARCHAR(50)	= '',
	@Language	VARCHAR(2)	= 'E',
    @ErrCode    INT = 0 OUTPUT,
    @ErrMsg     NVARCHAR(500) = '' OUTPUT
AS
/*
    Created: 20250707@Johnson
	Task : Get all product list for promotion cash service which offered for Site/Currency
	DB: DBCust/AgencyCashService
  
	Revisions:
        - 20250707@Johnson: initial sp [redmine:#232347]
        - 20250825@Johnson: enhance log [redmine:#236435]
    Parameter's Explanation:
    - @PromotionContents = 
    N'[{
        "title": "Summer Promotion 2025",       
        "language": "en",
        "content": "Welcome to the Summer Promotion 2025! Enjoy great offers when you join today."
    },
    {
        "title": "",
        "banner": "",
        "language": "vi",
        "content": ""
    }]
    ';    
    @Log= '<ROOT CustID="1" SubAccName="" IP="1.1.1.1">	
		<Promotion PromotionID="123" >
			<r Title="Summer Promotion 2025" Language="en" Content="Welcome to the Summer Promotion 2025! Enjoy great offers when you join today."/>
		</Promotion>        
    </ROOT>'
*/    
BEGIN
    SET NOCOUNT ON

    DECLARE 
		@startRun		DATETIME ,
		@endRun		DATETIME ,
		@DurationTime	INT
	
	SET @startRun = GETDATE ()
	SELECT @ErrCode = 0 , @ErrMsg = '' 

    --Promotion Contents
    DECLARE @tblPromotionContents TABLE (
        Title NVARCHAR(200),
        Banner VARCHAR(1000),
        Language VARCHAR(10),
        Content NVARCHAR(MAX)
    );

    DECLARE @tblPromotionContents_Old TABLE (
        Title NVARCHAR(200),
        Banner VARCHAR(1000),
        Language VARCHAR(10),
        Content NVARCHAR(MAX)
    );

    INSERT INTO @tblPromotionContents (Title, Banner, Language, Content)
    SELECT    
        ISNULL([title],''),
        ISNULL([banner],''),
        [language],
        ISNULL([content],'')
    FROM OPENJSON(@PromotionContents)
    WITH (        
        [title] NVARCHAR(200) '$.title',
        [banner] VARCHAR(1000) '$.banner',
        [language] VARCHAR(10) '$.language',
        [content] NVARCHAR(MAX) '$.content'
    );

    INSERT INTO @tblPromotionContents_Old (Title, Banner, Language, Content)
    SELECT    
        [title],
        [banner],
        [languageCode],
        [content]
    FROM CashPromotionLanguage WITH (NOLOCK)
    WHERE PromotionID = @PromotionID
      AND SiteDBGroupID = @SiteDBGroupID
      AND LanguageCode IN (SELECT Language FROM @tblPromotionContents);

    IF EXISTS (SELECT 1 FROM @tblPromotionContents 
                WHERE Language <> 'En' 
                    AND Title = ''
                    AND Content = ''
                    AND Banner = '')
    BEGIN
        DELETE CashPromotionLanguage WITH(ROWLOCK)
        OUTPUT DELETED.PromotionID, DELETED.SiteDBGroupID, DELETED.LanguageCode, dbo.f_GetDateTime2()
        INTO CashPromotionLanguage_Del_InHouse(PromotionID, SiteDBGroupID, LanguageCode, RepUpdateTime)
        WHERE PromotionID = @PromotionID
          AND SiteDBGroupID = @SiteDBGroupID
          AND LanguageCode IN (SELECT Language FROM @tblPromotionContents
                                WHERE Language <> 'En' 
                                  AND Title = ''
                                  AND Content = ''
                                  AND Banner = ''
                            );
    END    

    MERGE CashPromotionLanguage AS target
    USING (SELECT * FROM @tblPromotionContents 
            WHERE Title <> ''
                OR Content <> ''
                OR Banner <> '') AS source
        ON target.PromotionID = @PromotionID
        AND target.SiteDBGroupID = @SiteDBGroupID
        AND target.LanguageCode = source.Language
    WHEN MATCHED THEN
        UPDATE SET 
            target.Title = source.Title,
            target.Content = source.Content,
            target.Banner = source.Banner,
            target.RepUpdateTime = dbo.f_GetDateTime2()
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (PromotionID, SiteDBGroupID, LanguageCode, Title, Content, Banner, RepUpdateTime)
        VALUES (@PromotionID, @SiteDBGroupID, source.Language, source.Title, source.Content, source.Banner, dbo.f_GetDateTime2());

    UPDATE CashPromotion WITH(ROWLOCK)
    SET ModifiedDate = GETDATE(),
        RepUpdateTime = dbo.f_GetDateTime2()        
    WHERE PromotionID = @PromotionID
      AND SiteDBGroupID = @SiteDBGroupID
      AND AgentID = @AgentID
  
    --START LOG
	DECLARE @TrackingValue NVARCHAR(MAX), @TrackingValue2 NVARCHAR(MAX)
	DECLARE @ActionID INT = 315002
		SET @endRun = GETDATE ()
		SET @DurationTime = datediff (millisecond,@startRun,@endRun)

    
    INSERT INTO @tblPromotionContents_Old (Title, Banner, Language, Content)
    SELECT    
        '' [title],
        '' [banner],
        [language],
        '' [content]
    FROM @tblPromotionContents
    WHERE Language NOT IN (SELECT language FROM @tblPromotionContents_Old);

    SELECT @TrackingValue = '<ROOT CustID="' + CONVERT(VARCHAR(20), @AgentID) 
                            + '" SubAccName="' + CustDB.dbo.f_GetSubUsername(@SubAccID) 
                            + '" IP="' + CONVERT(VARCHAR(50), @IP) + '">'
                            + '<Promotion PromotionID="' + CONVERT(VARCHAR(20), @PromotionID) +'" >'                           
                            + CAST((
                                SELECT pc.Title AS '@Title',                              
                                       pc.Language AS '@Language',
                                       pc.Content AS '@Content'
                                FROM @tblPromotionContents pc
                                FOR XML PATH('r'), TYPE
                            ) AS NVARCHAR(MAX))
                            + '</Promotion>' 
                            + '</ROOT>';

    SELECT @TrackingValue2 = '<ROOT CustID="' + CONVERT(VARCHAR(20), @AgentID) 
                            + '" SubAccName="' + CustDB.dbo.f_GetSubUsername(@SubAccID) 
                            + '" IP="' + CONVERT(VARCHAR(50), @IP) + '">'
                            + '<Promotion PromotionID="' + CONVERT(VARCHAR(20), @PromotionID) +'" >'                           
                            + CAST((
                                SELECT pc.Title AS '@Title',                              
                                       pc.Language AS '@Language',
                                       pc.Content AS '@Content'
                                FROM @tblPromotionContents_Old pc
                                FOR XML PATH('r'), TYPE
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