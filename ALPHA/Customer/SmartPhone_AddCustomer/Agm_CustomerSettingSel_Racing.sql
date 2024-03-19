USE bodb02
GO

ALTER PROCEDURE dbo.Agm_CustomerSettingSel_Racing
	@Custid int	
AS
/*  
 Created by: Elly  
 Date:20110724
 Original:
 Task: Get setting information of racing for a custid
 
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
		,v151discount_41=MAX(CASE WHEN cs3rd.bettype=41 AND cs3rd.sporttype=151 THEN cs3rd.discount ELSE 0 END)
		,v151playerdiscount_41=MAX(CASE WHEN cs3rd.bettype=41 AND cs3rd.sporttype=151 THEN cs3rd.playerdiscount ELSE 0 END)
		
	---------- bet setting section---------------------------------------------------------------------------------------
			
		,v151minbet_41=MAX(CASE WHEN cs3rd.bettype=41 AND cs3rd.sporttype=151 THEN cs3rd.minbet ELSE 0 END)
		,v151maxbet_41=MAX(CASE WHEN cs3rd.bettype=41 AND cs3rd.sporttype=151 THEN cs3rd.maxbet ELSE 0 END)
		,v151maxpermatch_41=ci.MaxPerMatch151_OT

	---------- position taking section---------------------------------------------------------------------------------------
		
		,v151apositiontaking_41=MAX(CASE WHEN cs3rd.bettype=41 AND cs3rd.sporttype=151 THEN cs3rd.apositiontaking END)
		
	
	FROM dbo.CustInfo AS ci WITH(NOLOCK)		
		INNER JOIN dbo.CustSetting3rd AS cs3rd WITH(NOLOCK) ON ci.CustID=cs3rd.CustID
			AND ci.custid=@CustID
			AND ci.roleid=1
	GROUP BY ci.closed
			,ci.reject			
			,MaxPerMatch151
			,MaxPerMatch151_OT
			,MaxPerMatch151_AU
			,MaxPerMatch152_UK
			,MaxPerMatch152_AU
			,MaxPerMatch153_AU
			
	SET NOCOUNT OFF
END
/*
EXEC dbo.Agm_CustomerSettingSel_Racing @CustID=1511840
*/

GO
GRANT EXECUTE ON [dbo].Agm_CustomerSettingSel_Racing TO [bodbDownlineNet,wsv_alp]
GO
GRANT VIEW DEFINITION ON [dbo].Agm_CustomerSettingSel_Racing TO [vnteam]


