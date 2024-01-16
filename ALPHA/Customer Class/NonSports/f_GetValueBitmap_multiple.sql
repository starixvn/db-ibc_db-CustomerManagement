/*<info serverAlias="DBCust-CustDB,DBTP-bodb02" selecters="" viewers="" isFunction="1"></info>*/
ALTER FUNCTION	dbo.f_GetValueBitmap_multiple (
					@bitmap			BINARY(32)
				,	@ProductsOffer	VARCHAR(MAX)
				)  
RETURNS  TABLE
AS
/*
	Created:	20231002@Winfred
	Database:	DBCust/CustDB,DBTP-bodb02
	Original:	f_CustSetting_ProductStatusSel	
	Revision:
		- 20231002@Winfred: [NAP CM] Customer Class - Support for Non-Sports [RedmineID: #186116] 

	Param's Explanation:
	@ProductsOffer : '3,8,18,28,40,63,256'
*/
	RETURN (SELECT DISTINCT CAST(s.VALUE AS SMALLINT) AS ProductID, t.value AS Offer
			FROM STRING_SPLIT(@ProductsOffer,',') s
				CROSS APPLY ( SELECT CAST(CASE SUBSTRING(@bitmap, 1 + ((s.value - 1) / 8), 1) & POWER(2, (s.value - 1) % 8)
								WHEN 0 THEN 0 ELSE 1 END AS BIT ) value ) t 
			WHERE s.VALUE <> '')
