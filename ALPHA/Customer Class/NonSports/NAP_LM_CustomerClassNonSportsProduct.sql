/*<info serverAlias="DBAGE-bodb02" executers="bodbAdminNet,bodbLicenseeNet" viewers="" isFunction="0"></info>*/
CREATE PROCEDURE [dbo].[NAP_LM_CustomerClassNonSportsProduct] 
AS
/*
	Created: Winfred
	Date: 20231002
	Task : [NAP CM] Customer Class - Support for Non-Sports
	DB: DBAGE/bodb02
	Original:

	Revisions:
		- 20231002@Winfred: [NAP CM] Customer Class - Support for Non-Sports [RedmineID: #186116]

	Param's Explanation:
	* @Products : "3  : Number Game
					8  : RNG Keno
					18 : RNG Slot
					28 : Lottery
					40 : Table Game
					63 : Sports Lottery
					256  : All"
	Example: exec NAP_LM_CustomerClassNonSportsProduct
*/ 
BEGIN
	SET NOCOUNT ON;
	
	SELECT CAST(ProductID AS smallint) AS ProductID, ProductName
	FROM Products p WITH (NOLOCK) 
	WHERE ProductID IN (3, 8, 18, 28, 40, 63)
END
GO
