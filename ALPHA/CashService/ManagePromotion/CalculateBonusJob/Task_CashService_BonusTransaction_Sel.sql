/*<info serverAlias="DBAGE-bodb02" executers="wsv_CashService"  viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Task_CashService_BonusTransaction_Sel
	@TransDate DATE,
	@SiteDBGroupID TINYINT,
	@MemberBonus VARCHAR(MAX) OUTPUT,
	@MaxCustId INT OUTPUT
AS 
/*  
	Created By: Elodie
	Created Date: 2025-07-07
	Description: Agency Cash Service - Calculate and add pending bonus transaction for qualified members [Redmine #232347]
	DB: DBCust.AgencyCashService
	
	Revisions:
		- 20250707@Elodie: Initial SP [Redmine: #232347] 

	Param:
		exec Task_CashService_BonusTransaction_Sel @TransDate = @TransDate, @SiteDBGroupID = 3, @MemberBonus = @MemberBonus, @MaxCustId = @MaxCustId OUTPUT	
		SELECT @MaxCustId 						
*/  
BEGIN
	SET NOCOUNT ON

	DECLARE @NewMaxCustId INT
	SELECT @NewMaxCustId = MAX(CustId)
	FROM (	SELECT TOP (5000) CustId
			FROM CashPromotionCal WITH (NOLOCK)
			WHERE SiteDBGroupID = @SiteDBGroupID
				AND TransDate = @TransDate
			ORDER BY CustId) AS LatestCust

	SELECT @MemberBonus = (
							SELECT
								CustId,
								AgentId,
								SUM(Bonus) AS Bonus,
								ExtraInfo,
								PromotionID
							FROM CashPromotionCal WITH (NOLOCK)
							WHERE 
								SiteDBGroupID = @SiteDBGroupID
								AND TransDate = @TransDate 
								AND CustId <= @NewMaxCustId AND CustId > @MaxCustId
							GROUP BY CustId, AgentId, ExtraInfo, PromotionID
							FOR JSON PATH)

	SELECT @MaxCustId = @NewMaxCustId
END
