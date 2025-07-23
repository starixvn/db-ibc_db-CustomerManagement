/*<info serverAlias="DBCust-AgencyCashService" executers="wsv_CashService" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CashService_CashPromotionDel]
	@SiteDBGroupID SMALLINT, 
    @PromotionID INT,
	@AgentID    INT,	   
    @SubAccID	INT = 0,
	@IP			VARCHAR(50)	= '',
	@Language	VARCHAR(2)	= 'E',
    @ErrCode    INT = 0 OUTPUT,
    @ErrMsg     NVARCHAR(500) = '' OUTPUT
AS
/*
    Created: 20250707@Johnson
	Task : Remove promotion
	DB: DBCust/AgencyCashService
  
	Revisions:
        - 20250710@Johnson: initial sp [redmine:#232347]

    Parameter's Explanation:    
    @Log= '<ROOT CustID="1" SubAccName="" IP="1.1.1.1" >'
                <Promotion PromotionID="123" Title="Summer Promotion 2025" Type="1" FromDate="2025-07-08" ToDate="2025-07-10" />
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

    UPDATE CashPromotion WITH(ROWLOCK)
    SET IsSoftDeleted = 1,
        ModifiedDate = GETDATE(),
        RepUpdateTime = dbo.f_GetDateTime2()        
    WHERE PromotionID = @PromotionID
      AND SiteDBGroupID = @SiteDBGroupID
      AND AgentID = @AgentID
  
    --START LOG
	DECLARE @TrackingValue NVARCHAR(MAX), @TrackingValue2 NVARCHAR(MAX)
	DECLARE @ActionID INT = 315003
		SET @endRun = GETDATE ()
		SET @DurationTime = datediff (millisecond,@startRun,@endRun)

    SELECT @TrackingValue = '<ROOT CustID="' + CONVERT(VARCHAR(20), @AgentID) 
                            + '" SubAccName="' + CustDB.dbo.f_GetSubUsername(@SubAccID) 
                            + '" IP="' + CONVERT(VARCHAR(50), @IP) + '">'

                            + CAST((SELECT p.PromotionID AS '@PromotionID',
                                    pl.Title AS '@Title',
                                    p.[Type] as '@Type',   
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
            @TrackingValue as TrackingValue2,
            @DurationTime as Duration        
    
END