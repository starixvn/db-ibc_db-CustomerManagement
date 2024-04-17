USE bodb02
GO

ALTER PROCEDURE dbo.Agm_CustomerSettingSel_SportsBook
	@Custid int	
AS
/*  
 Created by: Elly  
 Date:20110724
 Original:
 Task: Get setting information of sport book for a custid
 
 DB: DB052.BODB02
  
 History:  
  
 Explanation's Param:  	
*/
BEGIN
	SET NOCOUNT ON
	
	SELECT 
		ci.closed
		,ci.reject AS suspended
	----------commission section---------------------------------------------------------------------------------------
		--comm1: for HDP (on behalf =1), OU, OE
		,v1discount_1=MAX(CASE WHEN cs.bettype=1 AND cs.sporttype=1 THEN cs.discount ELSE 0 END)
		,v1playerdiscount_1=MAX(CASE WHEN cs.bettype=1 AND cs.sporttype=1 THEN cs.playerdiscount ELSE 0 END)
		
		--comm2: for 1x2 (on behalf=5)
		,v1discount_5=MAX(CASE WHEN cs.bettype=5 AND cs.sporttype=1 THEN cs.discount ELSE 0 END)
		,v1playerdiscount_5=MAX(CASE WHEN cs.bettype=5 AND cs.sporttype=1 THEN cs.playerdiscount ELSE 0 END)
		
		--comm3: for other bettypes (on behalf=4)
		,v1discount_4=MAX(CASE WHEN cs.bettype=4 AND cs.sporttype=1 THEN cs.discount ELSE 0 END)
		,v1playerdiscount_4=MAX(CASE WHEN cs.bettype=4 AND cs.sporttype=1 THEN cs.playerdiscount ELSE 0 END)
		
		--Number Game commission
		,v161discount_81=MAX(CASE WHEN cs3rd.bettype=81 AND cs3rd.sporttype=161 THEN cs3rd.discount ELSE 0 END)
		,v161playerdiscount_81=MAX(CASE WHEN cs3rd.bettype=81 AND cs3rd.sporttype=161 THEN cs3rd.playerdiscount ELSE 0 END)		
			
	---------- bet setting section---------------------------------------------------------------------------------------
		--Minbet, maxbet, MaxPerMatch for sportbook
		,v1minbet_1=MAX(CASE WHEN cs.bettype=1 AND cs.sporttype=1 THEN cs.minbet ELSE 0 END)
		,v1maxbet_1=MAX(CASE WHEN cs.bettype=1 AND cs.sporttype=1 THEN cs.maxbet ELSE 0 END)
		,v1maxpermatch_1=ci.MaxPerMatch
		
		--Minbet, maxbet, MaxPerMatch for basketball
		,v2minbet_1=MAX(CASE WHEN cs.bettype=1 AND cs.sporttype=2 THEN cs.minbet ELSE 0 END)
		,v2maxbet_1=MAX(CASE WHEN cs.bettype=1 AND cs.sporttype=2 THEN cs.maxbet ELSE 0 END)
		,v2maxpermatch_1=ci.MaxPerMatch2
		
		--Minbet, maxbet, MaxPerMatch for NumberGame
		,v161minbet_81=MAX(CASE WHEN cs3rd.bettype=81 AND cs3rd.sporttype=161 THEN cs3rd.minbet ELSE 0 END)
		,v161maxbet_81=MAX(CASE WHEN cs3rd.bettype=81 AND cs3rd.sporttype=161 THEN cs3rd.maxbet ELSE 0 END)
		,v161maxpermatch_81=ci.MaxPerMatch161
		--ci.MaxPerBall161		
		
	---------- position taking section---------------------------------------------------------------------------------------
		--PT of soccers (on behalf of HDP)
		,v1apositiontaking_1=MAX(CASE WHEN cs.bettype=1 AND cs.sporttype=1 THEN cs.apositiontaking END)
		
		--PT of basketball (on behalf HDP)
		,v2apositiontaking_1=MAX(CASE WHEN cs.bettype=1 AND cs.sporttype=2 THEN cs.apositiontaking END)
		
		--PT of Number game (on behalf of bettype=81)
		,v161apositiontaking_81=MAX(CASE WHEN cs3rd.bettype=81 AND cs3rd.sporttype=161 THEN cs3rd.apositiontaking END)		
		
	FROM dbo.CustInfo AS ci WITH(NOLOCK)
		INNER JOIN dbo.CustSetting AS cs WITH(NOLOCK) ON cs.CustID=ci.CustID
			AND ci.custid=@CustID
			AND ci.roleid=1		
		INNER JOIN dbo.CustSetting3rd AS cs3rd WITH(NOLOCK) ON cs3rd.CustID=ci.CustID
	GROUP BY ci.closed
			,ci.reject
			,MaxPerMatch
			,MaxPerMatch2
			,MaxPerMatch161
			
	SET NOCOUNT OFF
END
/*
EXEC dbo.Agm_CustomerSettingSel_SportsBook @CustID=1511840
EXEC dbo.Agm_CustomerSettingSel_SportsBook @CustID=1415610
*/

GO
GRANT EXECUTE ON [dbo].Agm_CustomerSettingSel_SportsBook TO [wsv_alp]
GO
GRANT VIEW DEFINITION ON [dbo].Agm_CustomerSettingSel_SportsBook TO [vnteam]


