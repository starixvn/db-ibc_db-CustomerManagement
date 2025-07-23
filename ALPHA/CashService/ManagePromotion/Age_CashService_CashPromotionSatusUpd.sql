/*<info serverAlias="DBCust-AgencyCashService" executers="wsv_CashService" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CashService_CashPromotionStatusUpd]
	@SiteDBGroupID SMALLINT, 
    @PromotionID INT,
	@AgentID    INT,
    @Enabled     BIT, -- 0: Inactive, 1: Active	   
    @SubAccID	INT = 0,
	@IP			VARCHAR(50)	= '',
	@Language	VARCHAR(2)	= 'E',
    @ErrCode    INT = 0 OUTPUT,
    @ErrMsg     NVARCHAR(500) = '' OUTPUT
AS
/*
    Created: 20250711@Johnson
	Task : Update promotion status
	DB: DBCust/AgencyCashService
  
	Revisions:
        - 20250711@Johnson: initial sp [redmine:#232347]

    Parameter's Explanation:    
    @Log= '<ROOT CustID="1" SubAccName="" IP="1.1.1.1" >'
                <Promotion PromotionID="123" Title="Summer Promotion 2025" Enabled="1" />
            '</ROOT>'
*/    
BEGIN
    SET NOCOUNT ON

    DECLARE 
		@startRun		DATETIME ,
		@endRun		DATETIME ,
		@DurationTime	INT
	
	SET @startRun = GETDATE ()
	SELECT @ErrCode = 0 , @ErrMsg = '' 
    
    DECLARE @Enabled_Old BIT,
        @FromDate DATE, 
        @ToDate DATE

    SELECT @FromDate = FromDate, @ToDate = ToDate, @Enabled_Old = Enabled
    FROM CashPromotion WITH(NOLOCK)
    WHERE PromotionID = @PromotionID
      AND SiteDBGroupID = @SiteDBGroupID
      AND AgentID = @AgentID
      AND IsSoftDeleted = 0;

    IF @Enabled_Old = @Enabled
        RETURN;

    IF @Enabled = 1
    BEGIN
        IF EXISTS (SElECT TOP 1 1 FROM CashPromotion WITH(NOLOCK)
                   WHERE SiteDBGroupID = @SiteDBGroupID
                     AND AgentID = @AgentID
                     AND IsSoftDeleted = 0
                     AND Enabled = 1
                     AND PromotionID <> @PromotionID
                     AND (FromDate <= @ToDate AND ToDate >= @FromDate))
        BEGIN             
            SELECT @ErrCode = 100, 
               @ErrMsg = 'There is another active promotion for the same period.'
            RETURN
        END      
    END

    UPDATE CashPromotion WITH(ROWLOCK)
    SET Enabled = @Enabled,
        ModifiedDate = GETDATE(),
        RepUpdateTime = dbo.f_GetDateTime2()        
    WHERE PromotionID = @PromotionID
      AND SiteDBGroupID = @SiteDBGroupID
      AND AgentID = @AgentID
  
    --START LOG
	DECLARE @TrackingValue NVARCHAR(MAX), @TrackingValue2 NVARCHAR(MAX)
	DECLARE @ActionID INT = 315004
		SET @endRun = GETDATE ()
		SET @DurationTime = datediff (millisecond,@startRun,@endRun)

    SELECT @TrackingValue = '<ROOT CustID="' + CONVERT(VARCHAR(20), @AgentID) 
                            + '" SubAccName="' + CustDB.dbo.f_GetSubUsername(@SubAccID) 
                            + '" IP="' + CONVERT(VARCHAR(50), @IP) + '">'

                            + CAST((SELECT p.PromotionID AS '@PromotionID',
                                    pl.Title AS '@Title',
                                    @Enabled as '@Enabled',   
                                    p.FromDate as '@FromDate',
                                    p.ToDate as '@ToDate'                                   
                                 FROM CashPromotion p WITH(NOLOCK)
                                    INNER JOIN CashPromotionLanguage pl WITH(NOLOCK)
                                                        ON p.PromotionID = pl.PromotionID
                                                        AND p.SiteDBGroupID = pl.SiteDBGroupID
                                                        AND pl.LanguageCode = 'En'
                                 WHERE p.PromotionID = @PromotionID
                                   AND p.SiteDBGroupID = @SiteDBGroupID
                                   AND p.AgentID = @AgentID                                   
                                 FOR XML PATH('Promotion'), TYPE) AS NVARCHAR(MAX))
                            + '</ROOT>'                    

    SELECT @TrackingValue2 = '<ROOT CustID="' + CONVERT(VARCHAR(20), @AgentID) 
                            + '" SubAccName="' + CustDB.dbo.f_GetSubUsername(@SubAccID) 
                            + '" IP="' + CONVERT(VARCHAR(50), @IP) + '">'

                            + CAST((SELECT p.PromotionID AS '@PromotionID',
                                    pl.Title AS '@Title',
                                    @Enabled_Old as '@Enabled',   
                                    p.FromDate as '@FromDate',
                                    p.ToDate as '@ToDate'                                   
                                 FROM CashPromotion p WITH(NOLOCK)
                                    INNER JOIN CashPromotionLanguage pl WITH(NOLOCK)
                                                        ON p.PromotionID = pl.PromotionID
                                                        AND p.SiteDBGroupID = pl.SiteDBGroupID
                                                        AND pl.LanguageCode = 'En'
                                 WHERE p.PromotionID = @PromotionID
                                   AND p.SiteDBGroupID = @SiteDBGroupID
                                   AND p.AgentID = @AgentID                                   
                                 FOR XML PATH('Promotion'), TYPE) AS NVARCHAR(MAX))
                            + '</ROOT>'                             

    -- Return Data Object
	SELECT @AgentID as UserID, 
            @AgentID as CustID, 
            @ActionID as ActionID, 
            @TrackingValue as TrackingValue, 
            @TrackingValue2 as TrackingValue2,
            @DurationTime as Duration        
    
END