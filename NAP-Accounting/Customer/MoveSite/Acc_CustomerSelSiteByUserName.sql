ALTER PROCEDURE [dbo].[Acc_CustomerSelSiteByUserName]
	@username VARCHAR(50) = '',
	@Userid INT=NULL
AS 
/*	Created by: [Khoa] 
	Date: 20100130
	Task: Get Site by username
	DB: DBCUST.CustDB

	Revisions:
		- 20150610@Kos: Separate CustDB to DBCUST server (Move SP to DBCUST.CustDB)
		- 20160620@Winnie: #48948 Hide_special_sites_from_unautorized_users
	Param's Explanation:
*/

BEGIN
	SET NOCOUNT ON
	DECLARE @SearchQuery varchar(1024)
	DECLARE @tmp TABLE (siteid INT,site NVARCHAR(50), SpecialGroup TINYINT )
	DECLARE @tmpUserid VARCHAR(50)

	IF @Userid IS NULL
	BEGIN
	SELECT site, roleid, custid 
	FROM customer WITH (NOLOCK) 
	WHERE username = @username 
	END
	ELSE
	BEGIN
	SELECT @tmpUserid=CAST(@Userid AS VARCHAR(50))
	SELECT @SearchQuery = 'SELECT * 
	FROM OPENQUERY(DBPOLICY, 
	''SELECT siteid , site,SpecialGroup FROM bodb02.dbo.f_GetDeniedSiteByUser( ''''' + @tmpUserid + ''''')'')'

	INSERT INTO  @tmp (siteid , site,SpecialGroup)
	EXECUTE(@SearchQuery)
	
	SELECT site, roleid, custid 
	FROM customer WITH (NOLOCK) 
	WHERE username = @username AND site NOT IN (SELECT site FROM @tmp )
	
	END
END


GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelSiteByUserName] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Acc_CustomerSelSiteByUserName] TO [bodbExtAccNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Acc_CustomerSelSiteByUserName] TO [vnteam]

