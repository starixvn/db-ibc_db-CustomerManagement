/*<info serverAlias="DBCust-AgencyCashService" executers="wsv_CashService" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Age_CashService_CashPromotionSel]
	@SiteDBGroupID SMALLINT,     
	@AgentID    INT,	   
    @PromotionType TINYINT =0,
    @Status TINYINT = 0
AS
/*
    Created: 20250710@Johnson
	Task : Get promotion
	DB: DBCust/AgencyCashService
  
	Revisions:
        - 20250710@Johnson: initial sp [redmine:#232347]

    Parameter's Explanation:    
        @PromotionType = 0: All Promotions
        @Status = 0: All, 1: Enabled, 2: Disabled
*/    
BEGIN
    SET NOCOUNT ON
    
    DECLARE @tmpPromotion TABLE(PromotionID INT, 
                                Title NVARCHAR(200),
                                Type TINYINT, 
                                Enabled BIT, 
                                FromDate DATE, 
                                ToDate DATE,                               
                                ModifiedDate DATETIME)

    INSERT INTO @tmpPromotion (PromotionID, Title, Type, Enabled, FromDate, ToDate, ModifiedDate)
    SELECT p.PromotionID, pl.Title, p.Type, p.Enabled, p.FromDate, p.ToDate, p.ModifiedDate
    FROM CashPromotion p WITH(NOLOCK)
        INNER JOIN CashPromotionLanguage pl WITH(NOLOCK) ON p.PromotionID = pl.PromotionID
                                                        AND p.SiteDBGroupID = pl.SiteDBGroupID
                                                        AND pl.LanguageCode = 'En'
    WHERE p.SiteDBGroupID = @SiteDBGroupID
        AND p.AgentID = @AgentID
        AND (@PromotionType = 0 OR p.Type = @PromotionType)
        AND (@Status = 0 OR p.Enabled = CASE WHEN @Status = 1 THEN 1 ELSE 0 END)
        AND p.IsSoftDeleted = 0

    SELECT * FROM @tmpPromotion
    ORDER BY Title ASC

    SELECT PromotionID,ProductCategoryID,ProductList,Percentage,MaxPayout
    FROM CashPromotionDetail WITH(NOLOCK)
    WHERE PromotionID IN (SELECT PromotionID FROM @tmpPromotion)
        AND SiteDBGroupID = @SiteDBGroupID
END