/*<info serverAlias="DBPOL-NAP_UserControl" executers="wsv_nap" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_DeniedSiteCurrency_Sel]
	@UserID INT,
	@Mode	TINYINT = 0,
	@DeniedList NVARCHAR(MAX) OUTPUT
AS
/*
	Created: 20240723@Tacy
	Task: get denied site/currency list by user
	Database: DBPOL/NAP_UserControl

	Revisions:
		- 20240723@Tacy: Create SP [RedmineId: #208402]

	Param's Explanation:
		@Mode = 0 ~ All (default)
				1 ~ Site
				2 ~ Exchange

		@DeniedList: Json Type  
			'[
				{"KeyName":"Site",
				 "Value":[
							{"ID":1045,"Name":"yUT","Opt":1},
							{"ID":1046,"Name":"y789","Opt":1}
						]
				},
				{"KeyName":"Exchange",
				 "Value":[
							{"ID":1,"Name":"SD$","Opt":0},
							{"ID":2,"Name":"RM",,"Opt":0}
						]
				}
			]'
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @tmp TABLE (ID INT, Name NVARCHAR(50), Opt TINYINT, KeyName VARCHAR(30))

	INSERT INTO  @tmp (ID, Name, Opt, KeyName)
	--get deny site
	SELECT siteid, site, SpecialGroup, 'Site'
	FROM dbo.f_GetDeniedSiteByUser(@Userid)
	WHERE @Mode IN (0,1)
	UNION ALL
	--get deny currency
	SELECT exchangeID, Currency, OfferSite, 'Exchange'
	FROM dbo.f_GetDeniedCurrencyByUser (@Userid)
	WHERE @Mode IN (0,2)

	SELECT @DeniedList = (
				SELECT DISTINCT t.KeyName
				, [Value]= (SELECT ID, Name, Opt FROM @tmp a
							WHERE a.KeyName=t.KeyName
							FOR JSON PATH)
				FROM @tmp t
				FOR JSON PATH
	)
END
GO