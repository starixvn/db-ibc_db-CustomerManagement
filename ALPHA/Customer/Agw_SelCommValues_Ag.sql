ALTER PROCEDURE [dbo].[Agw_SelCommValues_Ag]
	@custid int
AS
/*

Created: 20090114@QuiNV
Task: Select commission values of agent
DB: DB05.bodb02
Original:

   Revisions:
	20090522@Lee: Applying Fixed Odds, Tote Meetting
	20090528@Lee: Applying 1x2 Comm
	20090529@Lee: Removing Fixed Odds, Tote Meeting
	20100929@Johnson: get commission for number game
*/
SET NOCOUNT ON

DECLARE @v161discount decimal(9,8)

SELECT @v161discount = max(case when cs.sporttype = 161 then discount else 0 end)
FROM  custsetting3rd cs with (nolock)
WHERE custid = @custid

SELECT  max(case when cs.bettype = 4 and cs.sporttype=1 then cs.discount else 0 end) as discountcs,  
 max(case when cs.bettype = 1 and cs.sporttype=1 then cs.groupa else 0 end) as groupa,  
 max(case when cs.bettype = 1 and cs.sporttype=1 then cs.groupb else 0 end) as groupb,  
 max(case when cs.bettype = 1 and cs.sporttype=1 then cs.groupc else 0 end) as groupc,  
 max(case when cs.bettype = 1 and cs.sporttype=1 then cs.groupd else 0 end) as groupd,  
 max(case when cs.bettype = 5 and cs.sporttype=1 then cs.discount else 0 end) as discountcs1x2,
 @v161discount as discountnumber
FROM custsetting cs with (nolock)
WHERE custid=@custid 

GO
GRANT EXECUTE ON [dbo].[Agw_SelCommValues_Ag] TO [bodbDownlineNet,wsv_alp]
GO


GRANT VIEW DEFINITION ON [dbo].[Agw_SelCommValues_Ag] TO [vnteam]

GO