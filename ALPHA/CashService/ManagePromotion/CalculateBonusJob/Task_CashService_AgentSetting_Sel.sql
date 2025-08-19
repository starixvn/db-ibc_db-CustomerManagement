/*<info serverAlias="DBCUST-AgencyCashService" executers="wsv_CashService"  viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Task_CashService_AgentSetting_Sel
	@IsTest BIT = 0,		
	@MondayLastWeek	DATE,
	@SundayLastWeek	DATE,
	@AgentPromotion VARCHAR(MAX) OUTPUT
AS 
/*  
	Created By: Elodie
	Created Date: 2025-07-07
	Description: Agency Cash Service - Calculate and add pending bonus transaction for qualified members [Redmine #232347]
	DB: DBCust.AgencyCashService
	
	Revisions:
		- 20250707@Elodie: Initial SP [Redmine: #232347] 

	Param:
		declare @p1 varchar(max)
		exec Task_CashService_AgentSetting_Sel @AgentPromotion=@p1 output,@IsTest=1,@MondayLastWeek='2025-07-14',@SundayLastWeek='2025-07-20'
		select @p1
		
		Output @AgentPromotion
		[
			{
				"PromotionID": 1,
				"SiteDBGroupID": 2,
				"AgentID": 5,
				"FromDate": "2025-07-01",
				"ToDate": "2025-07-31",
				"Details": [
				{
					"ProductCategoryID": 1,
					"ProductList": "1,2",
					"Percentage": 5.00,
					"MaxPayout": 1000.00,
					"MinValue": 50.00
				},
				...
				]
			},
			...
		]
*/  
BEGIN
	SET NOCOUNT ON;
	
	IF @IsTest = 0
	BEGIN
		SELECT @AgentPromotion = (SELECT
									cp.PromotionID,
									cp.SiteDBGroupID,
									cp.AgentID,
									CASE WHEN cp.FromDate > @MondayLastWeek THEN cp.FromDate ELSE @MondayLastWeek END AS FromDate,
									CASE WHEN cp.ToDate < @SundayLastWeek THEN cp.ToDate ELSE @SundayLastWeek END AS ToDate,
									(
										SELECT
											cpd.ProductCategoryID,
											cpd.ProductList,
											cpd.Percentage,
											cpd.MaxPayout,
											cpd.MinValue
										FROM dbo.CashPromotionDetail cpd WITH (NOLOCK) 
										WHERE cpd.PromotionID = cp.PromotionID
										FOR JSON PATH
									) AS Details
								FROM dbo.CashPromotion cp WITH (NOLOCK)	
								WHERE cp.Type = 1 --Rebate on Turnover
									AND IsSoftDeleted = 0
									AND cp.Enabled = 1
									AND NOT (cp.ToDate < @MondayLastWeek OR cp.FromDate > @SundayLastWeek)		   
								FOR JSON PATH
								)
	END
	ELSE
	BEGIN
		SELECT @AgentPromotion = (SELECT
								cp.PromotionID,
								cp.SiteDBGroupID,
								cp.AgentID,
								CASE WHEN cp.FromDate > @MondayLastWeek THEN cp.FromDate ELSE @MondayLastWeek END AS FromDate,
								CASE WHEN cp.ToDate < @SundayLastWeek THEN cp.ToDate ELSE @SundayLastWeek END AS ToDate,
								(
									SELECT
										cpd.ProductCategoryID,
										cpd.ProductList,
										cpd.Percentage,
										cpd.MaxPayout,
										cpd.MinValue
									FROM dbo.CashPromotionDetail cpd WITH (NOLOCK) 
									WHERE cpd.PromotionID = cp.PromotionID
									FOR JSON PATH
								) AS Details
							FROM dbo.CashPromotion cp WITH (NOLOCK)	
								INNER JOIN CustDB.dbo.Custinfo ci WITH (NOLOCK) ON cp.AgentID = ci.CustId	
							WHERE cp.Type = 1 --Rebate on Turnover
								AND IsSoftDeleted = 0
								AND cp.Enabled = 1
								AND NOT (cp.ToDate < @MondayLastWeek OR cp.FromDate > @SundayLastWeek)		   
								AND ci.currency = 20
							FOR JSON PATH
							)	
	END
END
