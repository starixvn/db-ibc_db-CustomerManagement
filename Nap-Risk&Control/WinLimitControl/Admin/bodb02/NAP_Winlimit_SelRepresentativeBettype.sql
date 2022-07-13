
/*<info serverAlias="DBTXN-bodb02" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/

ALTER PROC NAP_Winlimit_SelRepresentativeBettype 
	@ProductID INT
AS

/*
	    Creator:	20220518@Robert
	    Task:	#168458 - CWL - Enhance Currency Win Limit Setting page
	    Database:	DBTXN.bodb02 
	
	    Revisions:
		    - 20220518@Robert: #168458 - CWL - Enhance Currency Win Limit Setting page
		
	    Parameter's Explaination:
		    - @Example:			
		
	    Developer's Notes:		
*/

    BEGIN
	   SET NOCOUNT ON;
	   SELECT 
			p.ProductID, 
			p.ProductName, 
			w.BetType
	   FROM dbo.WinLimit_ProductOffer w WITH(NOLOCK)
		   INNER JOIN dbo.Products p WITH(NOLOCK) ON w.ProductID = p.ProductID
	   WHERE w.ProductID = @ProductID;

    END;

    