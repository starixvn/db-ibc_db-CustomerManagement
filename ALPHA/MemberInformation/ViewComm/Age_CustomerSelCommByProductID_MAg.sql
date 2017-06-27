ALTER PROCEDURE [dbo].[Age_CustomerSelCommByProductID_MAg]
	@ProductID INT,
	@MRecommend INT
AS

/*
	Created: 20151209@Dominic
	Task : Select member commission information for DCS Products
	DB: DBCUST.CustDB
	Revisions: 

*/
BEGIN
	SET NOCOUNT ON
	
	SELECT * INTO #SportBettypeFilter
	FROM dbo.f_CustSetting_SportBetTypeSettingSelect(@ProductID,3)
		
	SELECT 
		ci.closed,
		ci.enabled, 
		isnull(ci.reject,0) as suspended, 
		m.username, 
		m.custid, 
		m.ugroup, 
		m.firstname, 
		m.lastname, 
		ci.credit,
		cs.SportType,
		cs.MasterDiscount * 100 AS MasterDiscount,
		cs.AgentDiscount * 100 AS AgentDiscount,
		cs.PlayerDiscount * 100 AS PlayerDiscount
	FROM 
		customer AS m with (NOLOCK)
		INNER JOIN CustInfo as ci with (NOLOCK) on m.CustID = ci.CustID
		CROSS JOIN #SportBettypeFilter f WITH(NOLOCK)
		INNER JOIN CustDiscount3rd_Member as cs with (NOLOCK) 
				ON m.CustID = cs.CustID
					AND cs.SportType = f.sporttype
					AND cs.BetType = f.BetType
	WHERE m.MRecommend = @MRecommend and m.roleid=1 
	ORDER BY 
		case 
			when isnull(ci.enabled, 0) = 0 then 3 
			when isnull(ci.closed, 0) = 1 then 2 
			when isnull(ci.reject, 0) = 1 then 1 
			else 0 
		end, 
		m.username,
		cs.SportType
END
GO
GRANT EXECUTE ON [dbo].[Age_CustomerSelCommByProductID_MAg] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Age_CustomerSelCommByProductID_MAg] TO [bodbDownlineNetView] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Age_CustomerSelCommByProductID_MAg] TO [vnteam] AS [dbo]