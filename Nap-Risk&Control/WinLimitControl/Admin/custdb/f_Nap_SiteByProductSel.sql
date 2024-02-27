/*<info serverAlias="DBCust-bodb_licensee" selecters="bodbadminNet" viewers="" isFunction="1" isNested="1"></info>*/
CREATE FUNCTION [dbo].[f_Nap_SiteByProductSel]
(@ProductId TINYINT = 0)
RETURNS TABLE
AS
/*
	Created: 20240118@Tacy
	Task: Get site list by product 
	DB: DBCust-bodb_licensee
	
	Revisions:
		- 20240118@Tacy: Create function [RedmineID: #199920]

	Example:
*/
RETURN
	SELECT DISTINCT
			lp.LicenseeId, 
			l.LicenseeName,
			CASE
                WHEN p.ProductID = 14
                THEN 13
                ELSE p.ProductID
            END AS ProductID
	FROM LicenseeProduct3rd lp WITH(NOLOCK)
	INNER JOIN Licensees l WITH(NOLOCK) ON l.LicenseeId = lp.LicenseeId
	CROSS APPLY (SELECT TOP (1) p.Productid 
					FROM Product3rd p WITH (NOLOCK)
					WHERE (p.Productid=@ProductId OR ISNULL(@ProductId,0)=0)
					AND lp.ProductID=CASE WHEN ProductId = 13 THEN 14
										  WHEN p.ProductPrefix LIKE 'VS%' 
											OR p.ProductPrefix='LG' --Virtual Sports
												THEN 5 ELSE p.Productid
									END
					) p
	WHERE l.IsActive=1
GO