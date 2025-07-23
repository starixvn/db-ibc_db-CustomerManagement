/*<info serverAlias="DBCust-AgencyCashService" executers="wsv_CashService" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CashService_CashPromotionSelByID]
	@SiteDBGroupID SMALLINT,     
	@AgentID    INT,	   
    @PromotionID INT    
AS
/*
    Created: 20250710@Johnson
	Task : Get promotion by PromotionID
	DB: DBCust/AgencyCashService
  
	Revisions:
        - 20250710@Johnson: initial sp [redmine:#232347]

    Parameter's Explanation:    
       
*/    
BEGIN
    SET NOCOUNT ON
       
    SELECT p.PromotionID, p.Type, p.Enabled, p.FromDate, p.ToDate
    FROM CashPromotion p WITH(NOLOCK)        
    WHERE p.SiteDBGroupID = @SiteDBGroupID
        AND p.AgentID = @AgentID
        AND p.PromotionID = @PromotionID
        AND p.IsSoftDeleted = 0

    SELECT PromotionID,ProductCategoryID,ProductList,Percentage,MinValue as MinTO,MaxPayout
    FROM CashPromotionDetail WITH(NOLOCK)
    WHERE PromotionID = @PromotionID
        AND SiteDBGroupID = @SiteDBGroupID

    SELECT LanguageCode as Language, Title, Banner, Content
    FROM CashPromotionLanguage pl WITH(NOLOCK) 
    WHERE pl.PromotionID = @PromotionID
        AND pl.SiteDBGroupID = @SiteDBGroupID        
    
END