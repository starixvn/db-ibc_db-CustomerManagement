/*<info serverAlias="DBCust-CustDB" executers="wsv_nap,wsv_xnap" isFunction="0"></info>*/
ALTER PROCEDURE [dbo].[Acc_CustomerSelSiteByUserName]
	@username VARCHAR(50) = '',
	@Userid INT=NULL,
	@DeniedList	NVARCHAR(MAX)=NULL
AS 
/*	Created by: [Khoa] 
	Date: 20100130
	Task: Get Site by username
	DB: DBCUST.CustDB

	Revisions:
		- 20150610@Kos: Separate CustDB to DBCUST server (Move SP to DBCUST.CustDB)
		- 20160620@Winnie: #48948 Hide_special_sites_from_unautorized_users
		- 20180808@Helen: DB05.DBPOLICY migration  [Redmine:99462]
		- 20191029@Andy: Include checking special permission for internal admins only [Redmine: 121712]
		- 20240419@Tacy: NAP - Permission controls on real currency [redmineID: #202523]
		- 20240805@Tacy: Remove linked-server/cross-db on NAP_UserControl [redmineID: #208402]
		
	Param's Explanation:
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @tmp TABLE (siteid INT,site NVARCHAR(50), SpecialGroup TINYINT )
	DECLARE @tmpExchange TABLE (exchangeID INT, Currency NVARCHAR(50), OfferSite TINYINT)

	DECLARE @IsInternalAdmin BIT = 0

	IF @Userid IS NOT NULL
		EXEC Acc_CustomerIsInternalAdmin @CustID = @Userid, @IsInternalAdmin = @IsInternalAdmin OUTPUT
		
	IF @IsInternalAdmin = 1 AND ISNULL(@DeniedList,'')<>''
	BEGIN
		--get deny site
		INSERT INTO @tmp (siteid, site, SpecialGroup)
		SELECT vl.[ID], vl.[Name], vl.[Opt]
		FROM OPENJSON(@DeniedList) 
				WITH (  [KeyName]	VARCHAR(30),
						[Value]	NVARCHAR(MAX) AS JSON
					) AS js
		CROSS APPLY OPENJSON (js.[value])
				WITH (  [ID]	INT,
						[Name]	NVARCHAR(30),
						[Opt]	TINYINT
					) AS vl
		WHERE js.[KeyName]='Site'
	
		--get deny currency
		INSERT INTO  @tmpExchange (exchangeID, Currency, OfferSite)
		SELECT vl.[ID], vl.[Name], vl.[Opt]
		FROM OPENJSON(@DeniedList) 
				WITH (  [KeyName]	VARCHAR(30),
						[Value]	NVARCHAR(MAX) AS JSON
					) AS js
		CROSS APPLY OPENJSON (js.[value])
				WITH (  [ID]	INT,
						[Name]	NVARCHAR(30),
						[Opt]	TINYINT
					) AS vl
		WHERE js.[KeyName]='Exchange'
	END
		
	SELECT site, roleid, custid 
	FROM dbo.customer WITH (NOLOCK) 
	WHERE username = @username 
		AND site NOT IN (SELECT site FROM @tmp)
		AND currency NOT IN (SELECT exchangeID FROM @tmpExchange)
END